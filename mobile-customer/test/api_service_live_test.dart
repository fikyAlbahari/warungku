@Tags(['live'])
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mobile_customer/models/cart_item.dart';
import 'package:mobile_customer/services/api_exception.dart';
import 'package:mobile_customer/services/api_service.dart';

/// Test integrasi yang memanggil backend Laravel sungguhan.
///
/// Dilewati otomatis kalau server tidak hidup, supaya `flutter test` tetap
/// hijau di laptop yang belum menjalankan backend.
///
/// Jalankan server dulu:
///   cd backend-web && php artisan serve
/// lalu jalankan test ini:
///   flutter test --tags live
const _baseUrl = 'http://127.0.0.1:8000';

Future<bool> _serverHidup() async {
  final client = HttpClient()..connectionTimeout = const Duration(seconds: 3);
  try {
    final response = await client
        .getUrl(Uri.parse('$_baseUrl/api/products?per_page=1'))
        .then((r) => r.close())
        .timeout(const Duration(seconds: 5));
    await response.transform(utf8.decoder).join();
    return response.statusCode == 200;
  } catch (_) {
    return false;
  } finally {
    client.close(force: true);
  }
}

void main() {
  late ApiService api;
  var backendMati = false;

  setUpAll(() async {
    // Sengaja TIDAK memanggil TestWidgetsFlutterBinding.ensureInitialized().
    // Binding itu memasang HttpOverrides yang memblokir semua request HTTP
    // dan membalas 400, sehingga test ini tidak akan pernah bisa menghubungi
    // backend sungguhan.
    //
    // setMockInitialValues() cukup, karena ia hanya menukar
    // SharedPreferencesStorePlatform ke storage in-memory tanpa platform channel.
    SharedPreferences.setMockInitialValues({});

    backendMati = !await _serverHidup();
    if (backendMati) {
      // ignore: avoid_print
      print('[live] Backend tidak jalan di $_baseUrl, test dilewati.');
    }
  });

  setUp(() {
    api = ApiService();
  });

  /// Mengembalikan true kalau test ini harus dilewati.
  ///
  /// Dipakai sebagai guard di dalam body test, bukan sebagai argumen `skip:`,
  /// karena `skip` dievaluasi saat registrasi test, yaitu sebelum `setUpAll`
  /// sempat tahu apakah backend hidup.
  bool lewatiKalauBackendMati() {
    if (!backendMati) return false;
    markTestSkipped('Backend tidak jalan di $_baseUrl');
    return true;
  }

  test('katalog publik bisa diambil tanpa login', () async {
    if (lewatiKalauBackendMati()) return;

    final categories = await api.fetchCategories();

    expect(categories, isNotEmpty);
    expect(categories.first.id, greaterThan(0));
    expect(categories.first.name, isNotEmpty);
  });

  test('daftar produk ter-paginate dan field-nya lengkap', () async {
    if (lewatiKalauBackendMati()) return;

    final page = await api.fetchProducts(perPage: 5);

    expect(page.products.length, lessThanOrEqualTo(5));
    expect(page.currentPage, 1);
    expect(page.lastPage, greaterThanOrEqualTo(1));
    expect(page.total, greaterThan(0));

    final produk = page.products.first;
    expect(produk.id, greaterThan(0));
    expect(produk.name, isNotEmpty);
    expect(produk.priceJual, greaterThan(0));
    expect(produk.unit, isNotEmpty);
  });

  test('filter kategori hanya mengembalikan produk kategori itu', () async {
    if (lewatiKalauBackendMati()) return;

    final semua = await api.fetchProducts(perPage: 100);
    final target = semua.products.first.category;
    expect(target, isNotNull, reason: 'produk seed harus punya kategori');

    final hasil = await api.fetchProducts(
      categorySlug: target!.slug,
      perPage: 100,
    );

    expect(hasil.products, isNotEmpty);
    for (final produk in hasil.products) {
      expect(produk.category?.slug, target.slug);
    }
  });

  test('pencarian hanya mengembalikan produk yang cocok', () async {
    if (lewatiKalauBackendMati()) return;

    final hasil = await api.fetchProducts(search: 'beras', perPage: 100);

    for (final produk in hasil.products) {
      expect(
        produk.name.toLowerCase(),
        contains('beras'),
        reason: 'produk "${produk.name}" tidak cocok pencarian "beras"',
      );
    }
  });

  test('endpoint terproteksi ditolak saat belum login', () async {
    if (lewatiKalauBackendMati()) return;

    // Jangan andalkan urutan test: pastikan storage benar-benar kosong.
    await api.clearSession();
    expect(api.isAuthenticated, isFalse);

    await expectLater(
      api.fetchOrders(),
      throwsA(
        isA<ApiException>().having(
          (e) => e.isUnauthorized,
          'isUnauthorized',
          isTrue,
        ),
      ),
    );
  });

  test('login dengan password salah memberi pesan yang terbaca', () async {
    if (lewatiKalauBackendMati()) return;

    Object? error;
    try {
      await api.login(email: 'andi@mail.test', password: 'password-salah');
    } catch (e) {
      error = e;
    }

    expect(error, isA<ApiException>());
    expect((error as ApiException).message, isNotEmpty);
    expect(error.message.toLowerCase(), isNot(contains('exception')));
    expect(api.isAuthenticated, isFalse);
  });

  test('login berhasil lalu checkout membuat pesanan pending', () async {
    if (lewatiKalauBackendMati()) return;

    final user = await api.login(
      email: 'andi@mail.test',
      password: 'password123',
      deviceName: 'test-live',
    );

    expect(user['role'], 'pelanggan');
    expect(api.isAuthenticated, isTrue);

    final page = await api.fetchProducts(perPage: 3);
    final produk = page.products.firstWhere((p) => p.stock > 0);

    // Salinan keranjang, sama seperti yang dilakukan CartProvider sebelum kirim.
    final items = [CartItem(product: produk, qty: 2)];

    final order = await api.checkout(
      items: items,
      shippingAddress: 'Jl. Uji Integrasi No. 1, Bandung',
      paymentMethod: 'qris',
      note: 'test integrasi flutter',
    );

    expect(order.orderNumber, startsWith('WBRK-'));
    expect(order.status, 'pending');
    expect(order.items.length, 1);
    expect(order.items.first.productName, produk.name);
    // Harga di nota harus sama dengan harga katalog saat pesanan dibuat.
    expect(order.items.first.price, produk.priceJual);
    expect(order.subtotal + order.shippingCost, order.total);

    // Pesanan baru harus langsung muncul di riwayat.
    final riwayat = await api.fetchOrders();
    expect(
      riwayat.orders.any((o) => o.orderNumber == order.orderNumber),
      isTrue,
    );

    // Batalkan supaya test tidak meninggalkan data yang membingungkan.
    final dibatalkan = await api.cancelOrder(order.id);
    expect(dibatalkan.status, 'dibatalkan');
  });

  test('checkout tanpa alamat gagal dengan error per-field', () async {
    if (lewatiKalauBackendMati()) return;

    await api.login(
      email: 'bunga@mail.test',
      password: 'password123',
      deviceName: 'test-live',
    );

    final page = await api.fetchProducts(perPage: 1);

    Object? error;
    try {
      await api.checkout(
        items: [CartItem(product: page.products.first, qty: 1)],
        shippingAddress: '',
      );
    } catch (e) {
      error = e;
    }

    expect(error, isA<ApiException>());
    final apiError = error as ApiException;
    expect(apiError.statusCode, 422);
    expect(apiError.errorFor('shipping_address'), isNotNull);
  });

  test('token dari storage dipakai instance ApiService yang baru dibuat', () async {
    if (lewatiKalauBackendMati()) return;

    await api.login(
      email: 'candra@mail.test',
      password: 'password123',
      deviceName: 'test-live',
    );

    // Simulasi restart aplikasi: objek baru, storage sama.
    final setelahRestart = ApiService();
    expect(setelahRestart.isAuthenticated, isFalse,
        reason: 'token memang hanya tersedia setelah storage dibaca');

    // ensureSessionLoaded() dipanggil sendiri oleh _send, jadi pemanggil
    // tidak perlu ingat memanggil restoreSession() lebih dulu.
    final user = await setelahRestart.me();

    expect(user['email'], 'candra@mail.test');
    expect(setelahRestart.isAuthenticated, isTrue);
  });

  test('pendaftaran tidak memberi token dan login ditolak sampai disetujui', () async {
    if (lewatiKalauBackendMati()) return;

    // Email unik per run supaya test bisa diulang tanpa bentrok dengan data lama.
    final email = 'daftar-${DateTime.now().millisecondsSinceEpoch}@mail.test';

    final pesan = await api.register(
      name: 'Pelanggan Uji',
      email: email,
      password: 'password123',
      passwordConfirmation: 'password123',
    );

    expect(pesan.toLowerCase(), contains('menunggu'));
    // Ini yang paling penting: pendaftaran tidak boleh leaving user-nya login.
    // Kalau register ikut menyimpan token, akun yang belum diperiksa admin
    // bisa langsung membuat pesanan.
    expect(api.isAuthenticated, isFalse);

    Object? error;
    try {
      await api.login(email: email, password: 'password123');
    } catch (e) {
      error = e;
    }

    expect(error, isA<ApiException>());
    final apiError = error as ApiException;
    expect(apiError.statusCode, 422);
    expect(apiError.message.toLowerCase(), contains('belum disetujui'));
    expect(api.isAuthenticated, isFalse);
  });

  test('logout membersihkan token sehingga endpoint terproteksi menolak', () async {
    if (lewatiKalauBackendMati()) return;

    await api.login(
      email: 'andi@mail.test',
      password: 'password123',
      deviceName: 'test-live',
    );
    expect(api.isAuthenticated, isTrue);

    await api.logout();
    expect(api.isAuthenticated, isFalse);

    await expectLater(
      api.fetchOrders(),
      throwsA(
        isA<ApiException>().having(
          (e) => e.isUnauthorized,
          'isUnauthorized',
          isTrue,
        ),
      ),
    );
  });
}
