import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mobile_customer/providers/cart_provider.dart';
import 'package:mobile_customer/providers/checkout_draft_provider.dart';
import 'package:mobile_customer/providers/auth_provider.dart';
import 'package:mobile_customer/providers/catalog_provider.dart';
import 'package:mobile_customer/screens/login_page.dart';
import 'package:mobile_customer/screens/pesanan_saya_page.dart';
import 'package:mobile_customer/widgets/product_card.dart';
import 'package:mobile_customer/services/api_exception.dart';
import 'package:mobile_customer/services/api_service.dart';
import 'package:mobile_customer/models/product.dart';
import 'package:mobile_customer/theme.dart';
import 'package:mobile_customer/utils/currency.dart';
import 'package:provider/provider.dart';

Product _produk({int id = 1, int harga = 15000, int stok = 10, String unit = 'kg'}) {
  return Product(
    id: id,
    name: 'Beras Pandan Wangi',
    priceJual: harga,
    stock: stok,
    unit: unit,
  );
}

void main() {
  group('formatRupiah', () {
    test('memisahkan ribuan dengan titik', () {
      expect(formatRupiah(0), 'Rp 0');
      expect(formatRupiah(1000), 'Rp 1.000');
      expect(formatRupiah(15500), 'Rp 15.500');
      expect(formatRupiah(1250000), 'Rp 1.250.000');
    });

    test('menampilkan nilai negatif dengan tanda minus', () {
      expect(formatRupiah(-1500), '-Rp 1.500');
    });

    test('bisa tanpa prefix Rp', () {
      expect(formatRupiah(15500, withPrefix: false), '15.500');
    });
  });

  group('CartProvider', () {
    test('menambah produk baru ke keranjang', () {
      final cart = CartProvider();
      cart.add(_produk(stok: 5), qty: 2);

      expect(cart.isNotEmpty, isTrue);
      expect(cart.totalQty, 2);
      expect(cart.items.single.subtotal, 30000);
    });

    test('menambah produk yang sama menggabungkan qty, bukan baris baru', () {
      final cart = CartProvider();
      cart.add(_produk(stok: 5), qty: 2);
      cart.add(_produk(stok: 5), qty: 3);

      expect(cart.items.length, 1);
      expect(cart.items.single.qty, 5);
    });

    test('menolak produk stok habis', () {
      final cart = CartProvider();
      cart.add(_produk(stok: 0));

      expect(cart.isEmpty, isTrue);
    });

    test('decrease menghapus baris saat qty mencapai 0', () {
      final cart = CartProvider();
      cart.add(_produk(stok: 5), qty: 1);
      cart.decrease(1);

      expect(cart.isEmpty, isTrue);
    });

    test('setQty 0 menghapus baris', () {
      final cart = CartProvider();
      cart.add(_produk(stok: 5), qty: 3);
      cart.setQty(1, 0);

      expect(cart.isEmpty, isTrue);
    });

    test('mendeteksi qty yang melebihi stok', () {
      final cart = CartProvider();
      cart.add(_produk(stok: 2), qty: 5);

      expect(cart.itemsExceedingStock.length, 1);
      expect(cart.items.single.exceedsStock, isTrue);
    });

    test('ongkir nol saat keranjang kosong', () {
      final cart = CartProvider();
      expect(cart.shippingCost, 0);
      expect(cart.total, 0);
    });

    test('clear mengosongkan keranjang', () {
      final cart = CartProvider();
      cart.add(_produk(stok: 5), qty: 2);
      cart.clear();

      expect(cart.isEmpty, isTrue);
      expect(cart.totalQty, 0);
    });
  });

  testWidgets('ProductCatalog menampilkan memuat tanpa error', (tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => CartProvider(),
        child: MaterialApp(
          theme: buildAppTheme(),
          home: const Scaffold(body: Text('Warung Berkah')),
        ),
      ),
    );

    expect(find.text('Warung Berkah'), findsOneWidget);
  });

  group('CheckoutDraftProvider', () {
    test('membayar satu produk tidak menyentuh keranjang', () {
      final cart = CartProvider();
      final draft = CheckoutDraftProvider();

      cart.add(_produk(id: 1, stok: 5), qty: 2);
      draft.startWithProduct(_produk(id: 2, stok: 5));

      expect(draft.totalQty, 1);
      expect(draft.items.single.product.id, 2);
      // Keranjang harus tetap apa adanya supaya badge tidak naik sendiri.
      expect(cart.totalQty, 2);
      expect(cart.items.single.product.id, 1);
    });

    test('membayar dari keranjang menyalin isi keranjang', () {
      final cart = CartProvider();
      final draft = CheckoutDraftProvider();

      cart.add(_produk(id: 1, stok: 5), qty: 2);
      draft.startFromCart(cart.items);

      expect(draft.totalQty, 2);
      expect(draft.isFromCart, isTrue);

      // Mengubah jumlah di pembayaran tidak boleh mengubah keranjang.
      draft.add(_produk(id: 1, stok: 5));
      expect(cart.totalQty, 2);
    });

    test('draft dari katalog ditandai bukan dari keranjang', () {
      final draft = CheckoutDraftProvider();
      draft.startWithProduct(_produk(stok: 5));

      expect(draft.isFromCart, isFalse);
    });

    test('mulai dari katalog membuang isi draft sebelumnya', () {
      final draft = CheckoutDraftProvider();
      draft.add(_produk(id: 1, stok: 5), qty: 3);
      draft.startWithProduct(_produk(id: 2, stok: 5));

      expect(draft.items.length, 1);
      expect(draft.items.single.product.id, 2);
    });

    test('ongkir nol saat draft kosong', () {
      final draft = CheckoutDraftProvider();
      expect(draft.shippingCost, 0);
      expect(draft.total, 0);
    });
  });

  group('LoginPage', () {
    void useIphoneLikeSize(WidgetTester tester) {
      // Ukuran layar mengikuti HP samsung yang dipakai untuk uji manual.
      tester.view.physicalSize = const Size(1080, 2340);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
    }

    Widget buildLogin(AuthProvider auth) {
      return ChangeNotifierProvider<AuthProvider>.value(
        value: auth,
        child: MaterialApp(
          theme: buildAppTheme(),
          home: const LoginPage(),
        ),
      );
    }

    testWidgets('menampilkan form, daftar, dan tautan server', (tester) async {
      useIphoneLikeSize(tester);

      await tester.pumpWidget(buildLogin(AuthProvider(ApiService())));
      await tester.pumpAndSettle();

      expect(find.text('Masuk ke Akunmu'), findsOneWidget);
      expect(find.text('Email'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
      expect(find.text('Masuk'), findsOneWidget);
      expect(find.text('Daftar Akun Baru'), findsOneWidget);
      expect(find.text('Atur alamat server'), findsOneWidget);
    });

    testWidgets('gagal masuk menampilkan pop-up SweetAlert2', (tester) async {
      useIphoneLikeSize(tester);

      await tester.pumpWidget(buildLogin(_AuthWithError()));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byType(TextFormField).at(0),
        'andi@mail.test',
      );
      await tester.enterText(
        find.byType(TextFormField).at(1),
        'password123',
      );
      await tester.tap(find.text('Masuk'));
      await tester.pumpAndSettle();

      // Kegagalan masuk tidak lagi mengisi banner di halaman: ditampilkan
      // sebagai pop-up ala SweetAlert2 di tengah layar.
      expect(find.text('Gagal Masuk'), findsOneWidget);
      expect(find.text('Email atau kata sandi salah.'), findsOneWidget);
      // Halaman login tetap utuh di belakang pop-up, jadi field tidak harus
      // diisi ulang dari nol.
      expect(find.text('Password'), findsOneWidget);
    });
  });

  group('CatalogProvider', () {
    test('kegagalan katalog tidak dihapus oleh sukses memuat kategori',
        () async {
      // dulu kedua request ini berbagi satu field error. Kategori yang selesai
      // belakangan menghapus pesan gagalnya, sehingga katalog yang gagal dimuat
      // ditampilkan sebagai "Belum ada produk".
      final catalog = CatalogProvider(
        _ApiPalingGagal(kategoriGagal: false, produkGagal: true),
      );

      await catalog.loadCategories();
      await catalog.loadProducts();

      expect(catalog.error, 'Produk gagal dimuat.');
      expect(catalog.categoriesError, isNull);
      expect(catalog.products, isEmpty);
    });

    test('kegagalan kategori tidak menutupi katalog yang berhasil', () async {
      final catalog = CatalogProvider(
        _ApiPalingGagal(kategoriGagal: true, produkGagal: false),
      );

      await catalog.loadCategories();
      await catalog.loadProducts();

      expect(catalog.categoriesError, 'Kategori gagal dimuat.');
      expect(catalog.error, isNull);
    });
  });

  group('ProductCard', () {
    Future<void> pumpCard(
      WidgetTester tester,
      Product product, {
      CartProvider? cart,
      bool isLoggedIn = true,
      VoidCallback? onRequireLogin,
    }) async {
      await tester.pumpWidget(
        ChangeNotifierProvider<CartProvider>.value(
          value: cart ?? CartProvider(),
          child: MaterialApp(
            theme: buildAppTheme(),
            home: Scaffold(
              body: Center(
                child: SizedBox(
                  width: 170,
                  height: 268,
                  child: ProductCard(
                    product: product,
                    onOpenCheckout: () {},
                    isLoggedIn: isLoggedIn,
                    onRequireLogin: onRequireLogin ?? () {},
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('tombol keranjang menambah satu barang per ketukan',
        (tester) async {
      final cart = CartProvider();
      await pumpCard(tester, _produk(id: 1, stok: 5), cart: cart);

      // Ikon saja, tanpa teks: di grid 2 kolom teks "Keranjang" memakan ruang
      // lebih besar dari yang ia sumbangkan.
      expect(find.text('Keranjang'), findsNothing);
      expect(find.byIcon(Icons.add_shopping_cart_rounded), findsOneWidget);

      await tester.tap(find.byIcon(Icons.add_shopping_cart_rounded));
      await tester.pumpAndSettle();
      expect(cart.qtyOf(1), 1);

      // Ketuk lagi di tempat yang sama: tombolnya tidak bergeser.
      await tester.tap(find.byIcon(Icons.add_shopping_cart_rounded));
      await tester.pumpAndSettle();
      expect(cart.qtyOf(1), 2);
    });

    testWidgets('tombol keranjang tetap ada setelah barang masuk',
        (tester) async {
      final cart = CartProvider();
      await pumpCard(tester, _produk(id: 1, stok: 5), cart: cart);

      await tester.tap(find.byIcon(Icons.add_shopping_cart_rounded));
      await tester.pumpAndSettle();

      // Kartu tidak berubah bentuk: tombol keranjang tetap utuh dan tidak ada
      // penghitung [-] [+] di kartu. Menambah/mengurangi jumlah hanya lewat
      // halaman Keranjang.
      expect(find.byIcon(Icons.add_shopping_cart_rounded), findsOneWidget);
      expect(find.byIcon(Icons.add_rounded), findsNothing);
      expect(find.byIcon(Icons.remove_rounded), findsNothing);
    });

    testWidgets('seluruh permukaan tombol keranjang menambah barang',
        (tester) async {
      // Regresi: dulu area sentuh tombol hanya selebar ikon di tengah. Ketukan
      // di tepi kapsul jatuh ke InkWell kartu, sehingga "klik keranjang"
      // membuka halaman pembayaran padahal harusnya masuk keranjang.
      final cart = CartProvider();
      var checkoutDibuka = 0;

      await tester.pumpWidget(
        ChangeNotifierProvider<CartProvider>.value(
          value: cart,
          child: MaterialApp(
            theme: buildAppTheme(),
            home: Scaffold(
              body: Center(
                child: SizedBox(
                  width: 170,
                  height: 268,
                  child: ProductCard(
                    product: _produk(id: 1, stok: 5),
                    onOpenCheckout: () => checkoutDibuka++,
                    isLoggedIn: true,
                    onRequireLogin: () {},
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      final center = tester.getCenter(
        find.byIcon(Icons.add_shopping_cart_rounded),
      );

      await tester.tapAt(center - const Offset(70, 0));
      await tester.pumpAndSettle();
      expect(cart.qtyOf(1), 1);
      expect(checkoutDibuka, 0);

      await tester.tapAt(center + const Offset(70, 0));
      await tester.pumpAndSettle();
      expect(cart.qtyOf(1), 2);
      expect(checkoutDibuka, 0);
    });

    testWidgets('produk habis tidak punya tombol keranjang', (tester) async {
      final cart = CartProvider();
      await pumpCard(tester, _produk(id: 1, stok: 0), cart: cart);

      expect(find.text('Stok Habis'), findsOneWidget);
      expect(find.text('Tidak tersedia'), findsOneWidget);
      expect(find.byIcon(Icons.add_shopping_cart_rounded), findsNothing);

      await tester.tap(find.byType(ProductCard));
      await tester.pumpAndSettle();
      expect(cart.isEmpty, isTrue);
    });

    testWidgets('pengunjung belum masuk cuma bisa melihat produk',
        (tester) async {
      final cart = CartProvider();
      var dimintaMasuk = 0;
      await pumpCard(
        tester,
        _produk(id: 1, stok: 5),
        cart: cart,
        isLoggedIn: false,
        onRequireLogin: () => dimintaMasuk++,
      );

      // Tidak ada jalan ke keranjang maupun pembayaran tanpa akun.
      expect(find.byIcon(Icons.add_shopping_cart_rounded), findsNothing);
      expect(find.byIcon(Icons.lock_outline_rounded), findsOneWidget);
      expect(find.text('Masuk untuk beli'), findsOneWidget);

      await tester.tap(find.text('Masuk untuk beli'));
      await tester.pumpAndSettle();
      expect(dimintaMasuk, 1);
      expect(cart.isEmpty, isTrue);

      // Ketukan kartu juga mengarah ke login, bukan ke pembayaran.
      await tester.tap(find.byType(ProductCard));
      await tester.pumpAndSettle();
      expect(dimintaMasuk, 2);
      expect(cart.isEmpty, isTrue);
    });

    testWidgets('stok menipis ditandai berbeda dari stok aman', (tester) async {
      // `isNearOut` hanya menyala di stok 1-5, jadi 3 dan 40 menutup kedua
      // sisi ambang itu.
      await pumpCard(tester, _produk(id: 1, stok: 3, unit: 'pcs'));
      expect(find.text('Sisa 3 pcs'), findsOneWidget);

      await pumpCard(tester, _produk(id: 2, stok: 40, unit: 'pcs'));
      expect(find.text('40 pcs'), findsOneWidget);
      expect(find.text('Sisa 40 pcs'), findsNothing);
    });
  });

  group('OrderListProvider', () {
    test('reset membuang pesanan akun sebelumnya', () async {
      final orders = OrderListProvider(_ApiPalingGagal());
      await orders.load();

      orders.markCancelled(1); // memastikan ada state sebelum di-reset
      orders.reset();

      expect(orders.orders, isEmpty);
      expect(orders.error, isNull);
      expect(orders.hasNextPage, isFalse);
    });

    test('reset ikut menghapus pesan gagal yang masih menempel', () async {
      final orders = OrderListProvider(_ApiPalingGagal(pesananGagal: true));
      await orders.load();
      expect(orders.error, 'Pesanan gagal dimuat.');

      orders.reset();

      expect(orders.error, isNull);
    });
  });

  group('PesananSayaPage', () {
    testWidgets('membuka halaman pesanan tanpa setState saat build',
        (tester) async {
      // Regresi: initState dahulu memanggil load() yang secara sinkron memicu
      // notifyListeners() saat route masih dibangun oleh Navigator, yang
      // melempar "setState() or markNeedsBuild() called during build".
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(
              create: (_) => OrderListProvider(_ApiPalingGagal()),
            ),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => Center(
                  child: TextButton(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const PesananSayaPage(),
                      ),
                    ),
                    child: const Text('Buka Pesanan'),
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Buka Pesanan'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();

      expect(find.text('Pesanan Saya'), findsOneWidget);
      expect(find.text('Belum ada pesanan'), findsOneWidget);
    });
  });

  group('AuthProvider.logout', () {
    test('membersihkan sesi sehingga isLoggedIn jadi false', () async {
      SharedPreferences.setMockInitialValues({
        'auth_token': 'token-lama',
        'auth_user': '{"id":1,"name":"Andi","email":"andi@mail.test"}',
      });

      final auth = AuthProvider(ApiService());
      await auth.bootstrap();
      expect(auth.isLoggedIn, isTrue);
      expect(auth.displayName, 'Andi');

      await auth.logout();

      expect(auth.isLoggedIn, isFalse);
      expect(auth.user, isNull);
    });

    test('tetap membersihkan sesi lokal walau server tidak bisa dihubungi',
        () async {
      SharedPreferences.setMockInitialValues({
        'auth_token': 'token-lama',
        'auth_user': '{"id":1,"name":"Andi","email":"andi@mail.test"}',
      });

      // ApiService dengan base URL yang pasti tidak ada: logout harus tetap
      // jadi berhasil secara lokal. Kalau tidak, satu server down membuat
      // pelanggan terjebak login.
      final auth = AuthProvider(ApiService(client: _ClientGagal()));
      await auth.bootstrap();
      expect(auth.isLoggedIn, isTrue);

      await auth.logout();

      expect(auth.isLoggedIn, isFalse);
    });
  });
}

/// Client HTTP yang selalu gagal, untuk menguji jalur error tanpa jaringan.
class _ClientGagal extends http.BaseClient {
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    throw const SocketException('Koneksi ditolak');
  }
}

/// ApiService yang perilakunya ditentukan test, tanpa jaringan.
class _ApiPalingGagal extends ApiService {
  _ApiPalingGagal({
    this.kategoriGagal = false,
    this.produkGagal = false,
    this.pesananGagal = false,
  });

  final bool kategoriGagal;
  final bool produkGagal;
  final bool pesananGagal;

  @override
  Future<List<Category>> fetchCategories() async {
    if (kategoriGagal) throw ApiException('Kategori gagal dimuat.');
    return const [];
  }

  @override
  Future<ProductPage> fetchProducts({
    String? search,
    String? categorySlug,
    bool onlyInStock = false,
    int page = 1,
    int perPage = 20,
  }) async {
    if (produkGagal) throw ApiException('Produk gagal dimuat.');

    return ProductPage(
      products: const [],
      currentPage: 1,
      lastPage: 1,
      total: 0,
    );
  }

  @override
  Future<OrderPage> fetchOrders({String? status, int page = 1}) async {
    if (pesananGagal) throw ApiException('Pesanan gagal dimuat.');

    return OrderPage(
      orders: const [],
      currentPage: 1,
      lastPage: 1,
      total: 0,
    );
  }
}

/// AuthProvider dengan pesan error yang sudah ditentukan.
///
/// Dipakai supaya test bisa memeriksa tampilan banner tanpa benar-benar
/// menembak server.
class _AuthWithError extends AuthProvider {
  _AuthWithError() : super(ApiService());

  @override
  String? get error => 'Email atau kata sandi salah.';
}
