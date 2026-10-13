import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../config/api_config.dart';
import '../models/cart_item.dart';
import '../models/order.dart';
import '../models/product.dart';
import 'api_exception.dart';

/// Lapisan tunggal yang komunikasi dengan backend Warung Berkah.
///
/// Seluruh request HTTP project ini harus lewat kelas ini supaya ada satu
/// tempat untuk: menyisipkan token, mem-parse error Laravel, dan mengatur timeout.
class ApiService {
  ApiService({http.Client? client}) : _client = client ?? http.Client();

  /// Sengaja tidak `final`: [_replaceClient] menukar instance ini saat koneksi
  /// pooled ketahuan sudah ditutup tunnel.
  http.Client _client;

  static const _tokenKey = 'auth_token';
  static const _userKey = 'auth_user';

  String? _token;
  String? _cachedUserJson;

  /// Menjamin storage sudah dibaca tepat satu kali per instance.
  Future<void>? _sessionLoad;

  String? get token => _token;
  bool get isAuthenticated => _token != null;

  /* ------------------------------------------------------------------ */
  /* Penyimpanan token                                                  */
  /* ------------------------------------------------------------------ */

  /// Membaca token dari storage saat app dibuka.
  Future<void> restoreSession() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString(_tokenKey);
    _cachedUserJson = prefs.getString(_userKey);
  }

  /// Versi idempoten dari [restoreSession]: aman dipanggil berkali-kali dan
  /// hanya membaca storage sekali.
  Future<void> ensureSessionLoaded() => _sessionLoad ??= restoreSession();

  Future<void> _persistSession(String token, Map<String, dynamic> user) async {
    _token = token;
    _cachedUserJson = jsonEncode(user);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    await prefs.setString(_userKey, _cachedUserJson!);
  }

  Future<void> clearSession() async {
    _token = null;
    _cachedUserJson = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userKey);
  }

  /// Data user dari cache. Sengaja tidak memanggil API, dipakai hanya untuk
  /// menampilkan nama di app bar sebelum profil selesai dimuat.
  Map<String, dynamic>? get cachedUser {
    if (_cachedUserJson == null) return null;
    try {
      return jsonDecode(_cachedUserJson!) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  /* ------------------------------------------------------------------ */
  /* Auth                                                               */
  /* ------------------------------------------------------------------ */

  /// Server bisa dihubungi? Dipakai halaman pengaturan koneksi untuk memeriksa
  /// URL yang baru diketik sebelum disimpan.
  ///
  /// Endpoint publik yang paling ringan dipilih supaya tidak butuh token.
  ///
  /// Status HTTP saja tidak cukup jadi bukti. Tunnel ngrok, captive portal Wi-Fi,
  /// dan beberapa reverse proxy membalas 200 dengan halaman HTML, sehingga
  /// "Tes Koneksi" akan terlihat berhasil padahal katalog tetap gagal dimuat.
  /// Karena itu body-nya juga diperiksa harus berbentuk JSON.
  Future<String> ping() async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/products?per_page=1');

    try {
      // Lewat _dispatch, bukan _client langsung, supaya tes koneksi mengalami
      // percobaan ulang yang sama dengan request katalog.
      final response = await _dispatch('GET', uri, ApiConfig.headers, null);

      if (response.statusCode < 200 || response.statusCode >= 400) {
        return 'Server membalas HTTP ${response.statusCode}. '
            'Pastikan alamat berhenti di host dan port, tanpa /api.';
      }

      // Body JSON yang bisa dibaca = backend Laravel memang ada di ujung tunnel.
      try {
        final decoded = jsonDecode(response.body);
        if (decoded is! Map<String, dynamic>) {
          throw ApiException.badResponse();
        }
      } on FormatException {
        throw _halamanNgrok(response.body);
      } on ApiException {
        rethrow;
      } catch (_) {
        throw ApiException.badResponse();
      }

      return 'Server merespons (HTTP ${response.statusCode}).';
    } on TimeoutException {
      throw ApiException.network(
        url: ApiConfig.baseUrl,
        reason: 'Server tidak merespons dalam ${ApiConfig.timeout.inSeconds} detik.',
      );
    } on SocketException catch (e) {
      throw ApiException.network(url: ApiConfig.baseUrl, reason: e.message);
    } on http.ClientException catch (e) {
      throw ApiException.network(url: ApiConfig.baseUrl, reason: e.message);
    }
  }

  /// Pesan khusus untuk halaman peringatan ngrok.
  ///
  /// Ngrok membalas HTTP 200 dengan `ERR_NGROK_6024` kalau header
  /// `ngrok-skip-browser-warning` tidak ikut dikirim. App sudah mengirimnya
  /// otomatis di [ApiConfig.headers]; kemunculan pesan ini biasanya berarti
  /// alamat yang dipakai bukan tunnel ngrok yang sedang aktif.
  ApiException _halamanNgrok(String body) {
    if (body.contains('ERR_NGROK')) {
      return ApiException(
        'Alamat ini membalas halaman peringatan ngrok, bukan JSON dari backend. '
        'Pastikan tunnel ngrok masih berjalan dan alamatnya masih sama.',
      );
    }
    return ApiException(
      'Server membalas halaman HTML, bukan JSON. Kalau ini captive portal Wi-Fi '
      'atau proxy, coba pakai alamat lain.',
    );
  }

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
    String deviceName = 'flutter',
  }) async {
    final body = await _send(
      'POST',
      '/api/login',
      payload: {'email': email, 'password': password, 'device_name': deviceName},
      authenticated: false,
    );

    final data = body['data'] as Map<String, dynamic>;
    await _persistSession(data['token'] as String, data['user'] as Map<String, dynamic>);

    return data['user'] as Map<String, dynamic>;
  }

  /// Mendaftarkan akun pelanggan baru.
  ///
  /// Server sengaja tidak mengembalikan token: akun baru berstatus
  /// `menunggu` dan baru bisa masuk setelah admin menyetujuinya. Karena itu
  /// [_persistSession] tidak dipanggil di sini, dan nilai balik berupa pesan
  /// dari server, bukan data user yang sudah bisa dipakai.
  Future<String> register({
    required String name,
    required String email,
    required String password,
    required String passwordConfirmation,
    String? phone,
    String? address,
  }) async {
    final body = await _send(
      'POST',
      '/api/register',
      payload: {
        'name': name,
        'email': email,
        'password': password,
        'password_confirmation': passwordConfirmation,
        if (phone != null && phone.isNotEmpty) 'phone': phone,
        if (address != null && address.isNotEmpty) 'address': address,
      },
      authenticated: false,
    );

    return body['message']?.toString() ??
        'Pendaftaran berhasil. Tunggu persetujuan admin sebelum bisa masuk.';
  }

  Future<Map<String, dynamic>> me() async {
    final body = await _send('GET', '/api/me');
    return body['data'] as Map<String, dynamic>;
  }

  Future<void> logout() async {
    try {
      await _send('POST', '/api/logout');
    } on ApiException {
      // Token mungkin sudah invalid di server. Yang penting session lokal
      // tetap bersih supaya user tidak terjebak di layar yang butuh login.
    }
    await clearSession();
  }

  /* ------------------------------------------------------------------ */
  /* Katalog (publik, tidak butuh login)                                 */
  /* ------------------------------------------------------------------ */

  Future<List<Category>> fetchCategories() async {
    final body = await _send('GET', '/api/categories', authenticated: false);
    return _listOf(body).map(Category.fromJson).toList();
  }

  Future<ProductPage> fetchProducts({
    String? search,
    String? categorySlug,
    bool onlyInStock = false,
    int page = 1,
    int perPage = 20,
  }) async {
    final query = <String, String>{
      'page': '$page',
      'per_page': '$perPage',
      if (search != null && search.trim().isNotEmpty) 'cari': search.trim(),
      if (categorySlug != null && categorySlug.isNotEmpty) 'kategori': categorySlug,
      if (onlyInStock) 'stok_tersedia': '1',
    };

    final body = await _send(
      'GET',
      '/api/products',
      query: query,
      authenticated: false,
    );

    return ProductPage(
      products: _listOf(body).map(Product.fromJson).toList(),
      currentPage: _metaInt(body, 'current_page', fallback: 1),
      lastPage: _metaInt(body, 'last_page', fallback: 1),
      total: _metaInt(body, 'total'),
    );
  }

  Future<Product> fetchProduct(int id) async {
    final body = await _send('GET', '/api/products/$id', authenticated: false);
    return Product.fromJson(body['data'] as Map<String, dynamic>);
  }

  /* ------------------------------------------------------------------ */
  /* Pesanan                                                            */
  /* ------------------------------------------------------------------ */

  /// Mengirim keranjang ke server. Server yang menghitung subtotal, ongkir,
  /// dan nomor nota, jadi total di HP tidak pernah bisa berbeda dengan nota.
  Future<Order> checkout({
    required List<CartItem> items,
    required String shippingAddress,
    String? paymentMethod,
    String? note,
    int shippingCost = ApiConfig.defaultShippingCost,
  }) async {
    // Catatan kosong tidak perlu dikirim; Laravel akan menyimpan null bila
    // field tidak ada di payload.
    final trimmedNote = (note == null || note.trim().isEmpty) ? null : note.trim();

    final body = await _send(
      'POST',
      '/api/orders',
      payload: {
        'items': items
            .map((item) => {'product_id': item.product.id, 'qty': item.qty})
            .toList(),
        'shipping_address': shippingAddress,
        'shipping_cost': shippingCost,
        'payment_method': ?paymentMethod,
        'note': ?trimmedNote,
      },
    );

    return Order.fromJson(body['data'] as Map<String, dynamic>);
  }

  Future<OrderPage> fetchOrders({String? status, int page = 1}) async {
    final body = await _send(
      'GET',
      '/api/orders',
      query: {
        'page': '$page',
        'status': ?status,
      },
    );

    return OrderPage(
      orders: _listOf(body).map(Order.fromJson).toList(),
      currentPage: _metaInt(body, 'current_page', fallback: 1),
      lastPage: _metaInt(body, 'last_page', fallback: 1),
      total: _metaInt(body, 'total'),
    );
  }

  Future<Order> cancelOrder(int id) async {
    final body = await _send('POST', '/api/orders/$id/cancel');
    return Order.fromJson(body['data'] as Map<String, dynamic>);
  }

  /* ------------------------------------------------------------------ */
  /* Plumbing                                                           */
  /* ------------------------------------------------------------------ */

  Future<Map<String, dynamic>> _send(
    String method,
    String path, {
    Map<String, String>? query,
    Map<String, dynamic>? payload,
    bool authenticated = true,
  }) async {
    // Token dimuat otomatis di sini, bukan hanya saat app start. Tanpa ini,
    // setiap instance ApiService baru akan diam-diam mengirim request tanpa
    // header Authorization dan dijawab 401.
    if (authenticated) {
      await ensureSessionLoaded();
    }

    if (authenticated && _token == null) {
      throw ApiException.unauthorized();
    }

    final uri = Uri.parse('${ApiConfig.baseUrl}$path').replace(
      queryParameters: (query == null || query.isEmpty) ? null : query,
    );

    final headers = <String, String>{...ApiConfig.headers};
    if (authenticated) headers['Authorization'] = 'Bearer $_token';

    try {
      return _handleResponse(await _dispatch(method, uri, headers, payload));
    } on ApiException {
      rethrow;
    } on TimeoutException {
      throw ApiException.network(
        url: ApiConfig.baseUrl,
        reason: 'Server terlalu lama merespons.',
      );
    } on SocketException catch (e) {
      throw ApiException.network(url: ApiConfig.baseUrl, reason: e.message);
    } on http.ClientException catch (e) {
      throw ApiException.network(url: ApiConfig.baseUrl, reason: e.message);
    }
  }

  /// Mengirim request, dengan satu percobaan ulang untuk GET.
  ///
  /// Kenapa perlu: koneksi yang di-pool oleh [http.Client] ditutup sepihak oleh
  /// tunnel ngrok setelah idle. Request berikutnya yang memakai koneksi sudah
  /// mati itu gagal dengan ClientException, padahal tunnel-nya sehat dan
  /// request kedua akan berhasil kalau memakai koneksi baru. Gejalanya sangat
  /// membingungkan: "Tes Koneksi" berhasil, lalu "Simpan" gagal dengan
  /// "tidak bisa menghubungi server" padahal tidak ada yang berubah.
  ///
  /// Hanya GET yang diulang. POST tidak aman diulang karena bisa membuat pesanan
  /// ganda kalau request-nya sebenarnya sudah sampai ke server.
  Future<http.Response> _dispatch(
    String method,
    Uri uri,
    Map<String, String> headers,
    Map<String, dynamic>? payload,
  ) async {
    try {
      return await _request(method, uri, headers, payload);
    } on SocketException {
      if (method != 'GET') rethrow;
      _replaceClient();
      return await _request(method, uri, headers, payload);
    } on http.ClientException {
      if (method != 'GET') rethrow;
      _replaceClient();
      return await _request(method, uri, headers, payload);
    }
  }

  Future<http.Response> _request(
    String method,
    Uri uri,
    Map<String, String> headers,
    Map<String, dynamic>? payload,
  ) {
    final body = jsonEncode(payload ?? {});
    return switch (method) {
      'GET' => _client.get(uri, headers: headers).timeout(ApiConfig.timeout),
      'POST' =>
        _client.post(uri, headers: headers, body: body).timeout(ApiConfig.timeout),
      'PATCH' =>
        _client.patch(uri, headers: headers, body: body).timeout(ApiConfig.timeout),
      'PUT' =>
        _client.put(uri, headers: headers, body: body).timeout(ApiConfig.timeout),
      _ => throw ArgumentError('Method tidak didukung: $method'),
    };
  }

  /// Membuang client yang connection pool-nya sudah tercemar.
  ///
  /// Socket yang sudah ditutup tunnel akan dipakai lagi oleh client yang sama,
  /// jadi client baru adalah satu-satunya cara mendapatkan koneksi yang benar-benar
  /// baru tanpa me-restart app.
  void _replaceClient() {
    _client.close();
    _client = http.Client();
  }

  Map<String, dynamic> _handleResponse(http.Response response) {
    Map<String, dynamic> body = const {};

    if (response.body.isNotEmpty) {
      try {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic>) {
          body = decoded;
        } else if (response.statusCode >= 200 && response.statusCode < 300) {
          // JSON tapi bukan objek. Katalog harus dibalas objek ber-key `data`,
          // jadi bentuk lain berarti endpoint yang dipanggil bukan endpoint
          // yang hidup.
          throw ApiException.badResponse();
        }
      } on FormatException {
        // Body bukan JSON sama sekali. Tunnel ngrok yang sudah mati dan
        // captive portal di Wi-Fi hotel sama-sama membalas HTTP 200 dengan
        // halaman HTML, jadi pesan khususnya lebih berguna daripada
        // "respons tidak dikenali".
        if (response.statusCode >= 200 && response.statusCode < 300) {
          throw _halamanNgrok(response.body);
        }
      }
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return body;
    }

    throw _buildError(response.statusCode, body);
  }

  ApiException _buildError(int statusCode, Map<String, dynamic> body) {
    final rawErrors = body['errors'];

    final fieldErrors = <String, List<String>>{};
    if (rawErrors is Map<String, dynamic>) {
      rawErrors.forEach((field, value) {
        if (value is List) {
          fieldErrors[field] = value.map((e) => e.toString()).toList();
        } else {
          fieldErrors[field] = [value.toString()];
        }
      });
    }

    final serverMessage = body['message']?.toString();
    final detail = _firstErrorMessage(fieldErrors);

    final message = switch (statusCode) {
      401 => serverMessage ?? 'Sesi Anda habis. Silakan masuk kembali.',
      403 => serverMessage ?? 'Anda tidak punya akses ke data ini.',
      404 => serverMessage ?? 'Data tidak ditemukan.',
      422 => detail ?? serverMessage ?? 'Data yang dikirim belum benar.',
      >= 500 => 'Server sedang bermasalah. Silakan coba beberapa saat lagi.',
      _ => serverMessage ?? 'Terjadi kesalahan (kode $statusCode).',
    };

    return ApiException(
      message,
      statusCode: statusCode,
      fieldErrors: fieldErrors,
    );
  }

  /// Laravel membalas `"(and 1 more error)"` di field `message` saat 422.
  /// Pesan per-field jauh lebih membantu, jadi itu yang diprioritaskan.
  String? _firstErrorMessage(Map<String, List<String>> fieldErrors) {
    for (final messages in fieldErrors.values) {
      if (messages.isNotEmpty) return messages.first;
    }
    return null;
  }

  List<Map<String, dynamic>> _listOf(Map<String, dynamic> body) {
    final data = body['data'];
    if (data is! List) return const [];
    return data.whereType<Map<String, dynamic>>().toList();
  }

  int _metaInt(Map<String, dynamic> body, String key, {int fallback = 0}) {
    final meta = body['meta'];
    if (meta is Map<String, dynamic>) {
      final value = meta[key];
      if (value is int) return value;
      if (value is double) return value.round();
      if (value is String) return int.tryParse(value) ?? fallback;
    }
    return fallback;
  }
}

class ProductPage {
  const ProductPage({
    required this.products,
    required this.currentPage,
    required this.lastPage,
    required this.total,
  });

  final List<Product> products;
  final int currentPage;
  final int lastPage;
  final int total;

  bool get hasNextPage => currentPage < lastPage;
}

class OrderPage {
  const OrderPage({
    required this.orders,
    required this.currentPage,
    required this.lastPage,
    required this.total,
  });

  final List<Order> orders;
  final int currentPage;
  final int lastPage;
  final int total;

  bool get hasNextPage => currentPage < lastPage;
}
