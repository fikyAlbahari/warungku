/// Error yang bisa muncul dari ApiService.
///
/// Semua error dari server sudah diterjemahkan jadi pesan yang layak dibaca
/// pengguna, sehingga UI tidak pernah menampilkan JSON mentah atau
/// "Exception: ..." yang membingungkan.
class ApiException implements Exception {
  ApiException(this.message, {this.statusCode, this.fieldErrors = const {}});

  /// Server tidak bisa dihubungi (HP offline, WiFi beda, alamat salah, server mati).
  ///
  /// [url] dan [reason] sengaja ikut ditampilkan. Kegagalan koneksi hampir
  /// selalu soal alamat server, bukan soal akun, jadi pesan yang menyebut
  /// host yang dipakai jauh lebih berguna daripada "periksa internet".
  factory ApiException.network({String? url, String? reason}) {
    final target = (url == null || url.isEmpty) ? '' : ' ($url)';
    final penyebab = (reason == null || reason.trim().isEmpty)
        ? 'Tidak ada jawaban dari server.'
        : '${reason.trim()}.';
    return ApiException(
      'Tidak bisa menghubungi server$target. $penyebab '
      'Periksa WiFi, pastikan backend sedang hidup, lalu atur Alamat Server.',
    );
  }

  /// Server tidak menjawab dalam batas waktu.
  factory ApiException.timeout() => ApiException(
    'Server terlalu lama merespons. Silakan coba lagi.',
  );

  /// Respons tidak bisa dibaca sebagai JSON.
  factory ApiException.badResponse() => ApiException(
    'Respons server tidak valid. Coba muat ulang aplikasi.',
  );

  /// 401: token hilang, kadaluarsa, atau belum login.
  factory ApiException.unauthorized([String? message]) => ApiException(
    message ?? 'Sesi Anda habis. Silakan masuk kembali.',
    statusCode: 401,
  );

  final String message;
  final int? statusCode;

  /// Isi `errors` dari Laravel untuk invalidasi per-field, mis.
  /// `{'shipping_address': ['Alamat pengiriman wajib diisi.']}`
  final Map<String, List<String>> fieldErrors;

  bool get isUnauthorized => statusCode == 401;

  /// Pesan pertama untuk sebuah field, atau null jika field itu valid.
  String? errorFor(String field) {
    final messages = fieldErrors[field];
    if (messages == null || messages.isEmpty) return null;
    return messages.first;
  }

  @override
  String toString() => message;
}