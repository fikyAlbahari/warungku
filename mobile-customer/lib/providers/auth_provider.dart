import 'package:flutter/foundation.dart';

import '../services/api_exception.dart';
import '../services/api_service.dart';

/// Menyimpan status login. Token disimpan di ApiService, provider ini hanya
/// menjadi "pandangan" untuk widget.
class AuthProvider extends ChangeNotifier {
  AuthProvider(this._api);

  final ApiService _api;

  bool _initializing = true;
  bool _loading = false;
  String? _error;

  Map<String, dynamic>? _user;

  /// True selama app memeriksa token yang tersimpan, agar UI tidak sempat
  /// menampilkan halaman login lalu langsung_replace dengan beranda.
  bool get isInitializing => _initializing;

  bool get isLoading => _loading;

  String? get error => _error;

  bool get isLoggedIn => _api.isAuthenticated;

  Map<String, dynamic>? get user => _user;

  String get displayName => (_user?['name'] ?? 'Pelanggan').toString();

  String? get savedAddress => _user?['address']?.toString();

  Future<void> bootstrap() async {
    await _api.restoreSession();

    if (_api.isAuthenticated) {
      _user = _api.cachedUser;
      // Token hasil cache bisa saja sudah kadaluarsa. Cek diam-diam supaya
      // sesi yang salah tidak baru ketahuan saat menekan tombol checkout.
      unawaitedRefresh();
    }

    _initializing = false;
    notifyListeners();
  }

  void unawaitedRefresh() {
    me().catchError((_) => _user);
  }

  Future<bool> login({required String email, required String password}) async {
    _setLoading(true);

    try {
      _user = await _api.login(email: email, password: password);
      _error = null;
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Mendaftarkan akun baru.
  ///
  /// Mengembalikan pesan sukses dari server, atau `null` kalau gagal
  /// ([error] sudah diisi). Pendaftaran tidak sekaligus login: akunnya masih
  /// menunggu persetujuan admin, jadi [_user] sengaja tidak diisi di sini.
  Future<String?> register({
    required String name,
    required String email,
    required String password,
    required String passwordConfirmation,
    String? phone,
    String? address,
  }) async {
    _setLoading(true);

    try {
      final message = await _api.register(
        name: name,
        email: email,
        password: password,
        passwordConfirmation: passwordConfirmation,
        phone: phone,
        address: address,
      );
      _error = null;
      return message;
    } on ApiException catch (e) {
      _error = e.message;
      return null;
    } finally {
      _setLoading(false);
    }
  }

  Future<Map<String, dynamic>?> me() async {
    try {
      final data = await _api.me();
      _user = data;
      notifyListeners();
      return data;
    } on ApiException catch (e) {
      // 401 berarti token benar-benar tidak berlaku: keluarkan user sepenuhnya.
      if (e.isUnauthorized) {
        await _api.clearSession();
        _user = null;
        notifyListeners();
      }
      return null;
    }
  }

  Future<void> logout() async {
    await _api.logout();
    _user = null;
    _error = null;
    notifyListeners();
  }

  void clearError() {
    if (_error == null) return;
    _error = null;
    notifyListeners();
  }

  void _setLoading(bool value) {
    _loading = value;
    _error = null;
    notifyListeners();
  }
}
