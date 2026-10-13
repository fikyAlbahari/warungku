import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Konfigurasi alamat backend Warung Berkah.
///
/// Urutan prioritas nilai base URL:
///  1. Nilai sementara dari [withBaseUrl] (hanya selama satu proses probe).
///  2. Nilai yang disimpan user lewat halaman "Koneksi Server".
///  3. `--dart-define=API_BASE_URL=...` (untuk build/CI).
///  4. Default per platform.
///
/// Nilai user berada di atas `--dart-define` dengan sengaja: kalau tidak, satu
/// Simpan di halaman pengaturan akan dilupakan begitu app dibuka ulang dan
/// `--dart-define` yang salah untuk jaringan itu kembali dipakai.
///
/// Default per platform penting untuk dipahami:
///
///  - Android Emulator : 10.0.2.2 adalah "localhost" milik PC host.
///  - iOS Simulator    : memakai localhost biasa.
///  - HP Android/iPhone ASLI : TIDAK bisa memakai 10.0.2.2 maupun localhost.
///    Harus memakai IP LAN PC, misal http://192.168.10.57:8000. Karena itu
///    default Android sengaja memakai IP LAN PC dan bisa dikoreksi user lewat
///    [saveBaseUrl] tanpa perlu build ulang.
class ApiConfig {
  const ApiConfig._();

  static const String _prefsKey = 'api_base_url';

  static const String _override = String.fromEnvironment('API_BASE_URL');

  static String? _savedBaseUrl;

  static String? _tempBaseUrl;

  static String _activeBaseUrl = _resolve();

  /// Default per platform tanpa melihat nilai yang tersimpan.
  ///
  /// Android memakai IP LAN PC, bukan 10.0.2.2, karena 10.0.2.2 hanya bermakna
  /// di dalam emulator.
  static String _platformDefault() {
    if (Platform.isAndroid) return suggestionForPhysicalDevice;
    return 'http://localhost:8000';
  }

  static String _fallbackBaseUrl() {
    if (_override.isNotEmpty) return _normalize(_override);
    return _platformDefault();
  }

  /// Sumber kebenaran tunggal untuk `_activeBaseUrl`, dipakai setiap kali nilai
  /// bisa berubah. Menyatukannya di sini mencegah `load()`, `saveBaseUrl()`, dan
  /// `resetBaseUrl()` punya urutan prioritas yang berbeda-beda.
  static String _resolve() {
    final temp = _tempBaseUrl;
    if (temp != null) return temp;
    final saved = _savedBaseUrl;
    if (saved != null) return saved;
    return _fallbackBaseUrl();
  }

  /// Host dan port PC ini yang dipakai HP asli saat sedang di Wi-Fi yang sama.
  static const String suggestionForPhysicalDevice = 'http://192.168.10.57:8000';

  /// Apakah build ini membawa `--dart-define=API_BASE_URL`.
  ///
  /// Halaman pengaturan memakainya untuk memberi tahu user bahwa ada nilai
  /// bawaan dari build yang bisa ditimpa.
  static bool get hasDartDefine => _override.isNotEmpty;

  /// Alamat dari `--dart-define`, atau null kalau build ini tidak memilikinya.
  static String? get dartDefineBaseUrl =>
      _override.isEmpty ? null : _normalize(_override);

  /// Opsi cepat untuk halaman pengaturan koneksi.
  ///
  /// Tunnel ngrok tidak punya quick pick karena alamatnya berubah setiap kali
  /// `ngrok http 8000` dijalankan ulang. Yang perlu dicatat: tunnel ngrok punya
  /// kuota dan bisa hilang, jadi alamat ini bukan pengganti IP LAN untuk pemakaian
  /// harian.
  static List<({String label, String url, String hint})> get suggestions => [
        (label: 'PC ini (Wi-Fi)', url: suggestionForPhysicalDevice, hint: 'HP Android asli'),
        (label: 'Emulator Android', url: 'http://10.0.2.2:8000', hint: 'Android Emulator'),
        (label: 'iOS Simulator', url: 'http://localhost:8000', hint: 'Simulator iPhone'),
      ];

  /// Alamat server yang sedang dipakai. Selalu berakhiran tanpa slash.
  static String get baseUrl => _activeBaseUrl;

  /// Berubah setiap kali [baseUrl] berubah, dipakai widget yang perlu rebuild
  /// tanpa harus menyimpan state-nya sendiri.
  ///
  /// [ApiConfig] adalah kelas statis, jadi perubahan di sini tidak menambah
  /// listener lewat Provider. Notifier ini adalah cara paling murah untuk
  /// menyiarkan perubahannya ke UI.
  static final ValueNotifier<String> baseUrlChanges =
      ValueNotifier<String>(_activeBaseUrl);

  static void _publish() {
    if (baseUrlChanges.value != _activeBaseUrl) {
      baseUrlChanges.value = _activeBaseUrl;
    }
  }

  static bool get isUsingSavedValue => _savedBaseUrl != null;

  /// Asal [baseUrl] sekarang: simpanan user, `--dart-define`, atau default.
  static String get activeBaseUrlSource {
    if (_tempBaseUrl != null) return 'sedang diuji';
    if (_savedBaseUrl != null) return 'disimpan';
    if (_override.isNotEmpty) return 'build (--dart-define)';
    return 'bawaan';
  }

  /// Membaca URL yang pernah disimpan user. Wajib dipanggil sekali sebelum
  /// app mulai mengirim request.
  static Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_prefsKey);
    _savedBaseUrl = (saved == null || saved.trim().isEmpty) ? null : _normalize(saved);
    _setActive(_resolve());
  }

  /// Menyimpan URL baru dan langsung mengaktifkannya di proses ini.
  ///
  /// Melempar [ArgumentError] kalau [url] kosong setelah dirapikan, supaya
  /// alamat kosong tidak diam-diam tersimpan sebagai nilai default per platform
  /// dan jejak kesalahan ketik user hilang.
  static Future<void> saveBaseUrl(String url) async {
    final normalized = _normalizeForStorage(url);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, normalized);
    _savedBaseUrl = normalized;
    _setActive(_resolve());
  }

  /// Membuang URL yang disimpan dan kembali ke default per platform.
  static Future<void> resetBaseUrl() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefsKey);
    _savedBaseUrl = null;
    _setActive(_resolve());
  }

  /// Menjalankan [action] memakai base URL dari [url] tanpa menyentuh storage.
  ///
  /// Dipakai tombol "Tes Koneksi": alamat hasil ketikan bisa diuji tanpa
  /// disimpan permanen, jadi alamat yang salah tidak ikut menimpa alamat yang
  /// sedang bekerja. Nilai sebelumnya dipulihkan apa pun hasilnya, termasuk saat
  /// [action] melempar exception.
  ///
  /// Sengaja tidak men-[saveBaseUrl]: probe harus bebas efek samping.
  static Future<T> withBaseUrl<T>(String url, Future<T> Function() action) async {
    final previous = _activeBaseUrl;
    final previousTemp = _tempBaseUrl;
    _tempBaseUrl = _normalize(url);
    _setActive(_resolve());
    try {
      return await action();
    } finally {
      _tempBaseUrl = previousTemp;
      _setActive(previous);
    }
  }

  /// Satu-satunya penulis `_activeBaseUrl`, supaya perubahan selalu ikut
  /// disiarkan lewat [baseUrlChanges].
  static void _setActive(String value) {
    _activeBaseUrl = value;
    _publish();
  }

  /// Menerjemahkan input mentah user menjadi URL yang aman dipakai.
  ///
  /// Menambahkan `http://` bila belum ada, membuang spasi, dan menghapus
  /// slash di akhir supaya `http://host:8000/` dan `http://host:8000`
  /// tidak menghasilkan `//api/login`.
  static String _normalize(String raw) {
    var url = raw.trim();
    if (url.isEmpty) return _fallbackBaseUrl();
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      url = 'http://$url';
    }
    while (url.endsWith('/')) {
      url = url.substring(0, url.length - 1);
    }
    return url;
  }

  /// Versi [_normalize] untuk nilai yang akan disimpan permanen.
  ///
  /// Bedanya hanya pada input kosong: [_normalize] mengembalikan default per
  /// platform karena juga dipakai untuk menghitung nilai fallback internal,
  /// sedangkan penyimpanan harus menolak input kosong daripada diam-diam
  /// menuliskan host yang tidak pernah diketik user.
  static String _normalizeForStorage(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError.value(raw, 'url', 'Alamat server tidak boleh kosong.');
    }
    return _normalize(trimmed);
  }

  static const Duration timeout = Duration(seconds: 30);

  /// Header wajib agar Laravel membalas JSON, bukan HTML.
  static const Map<String, String> jsonHeaders = {
    'Accept': 'application/json',
    'Content-Type': 'application/json',
  };

  /// Host dari tunnel ngrok. Lewat domain ini, backend bisa dijangkau dari mana
  /// saja tanpa HP dan PC harus satu Wi-Fi.
  static const String _ngrokDomain = 'ngrok';

  /// Apakah [baseUrl] menunjuk ke tunnel ngrok.
  ///
  /// Dipakai untuk menambahkan header yang menonaktifkan halaman peringatan
  /// browser ngrok. Tanpa itu ngrok membalas HTTP 200 berisi teks
  /// `ERR_NGROK_6024` sebagai ganti JSON, sehingga gejalanya menyesatkan:
  /// server kelihatan hidup tapi katalog tetap gagal dimuat.
  static bool get isNgrokTunnel =>
      baseUrl.contains(_ngrokDomain) ||
      (dartDefineBaseUrl?.contains(_ngrokDomain) ?? false);

  /// Header yang benar-benar dikirim ke server.
  ///
  /// Selain header JSON, otomatis menyertakan
  /// `ngrok-skip-browser-warning` saat alamat aktif berupa tunnel ngrok.
  static Map<String, String> get headers => {
        ...jsonHeaders,
        if (isNgrokTunnel) 'ngrok-skip-browser-warning': '1',
      };

  /// Ongkos kirim default. Nilainya dikirim ke server, bukan dihitung di HP,
  /// supaya total di nota dan dashboard admin selalu sama.
  static const int defaultShippingCost = 5000;
}