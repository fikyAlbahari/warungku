import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config/api_config.dart';
import '../providers/catalog_provider.dart';
import '../services/api_exception.dart';
import '../services/api_service.dart';
import '../theme.dart';
import '../widgets/app_card.dart';

/// Halaman untuk mengatur alamat backend tanpa harus build ulang aplikasi.
///
/// HP Android asli tidak bisa memakai `localhost` maupun `10.0.2.2` seperti
/// emulator. Tanpa halaman ini, satu-satunya cara adalah
/// `flutter run --dart-define=API_BASE_URL=...` yang mudah terlewat dan
/// gejalanya hanya "tidak bisa masuk" padahal password sudah benar.
class ServerSettingsPage extends StatefulWidget {
  const ServerSettingsPage({super.key});

  @override
  State<ServerSettingsPage> createState() => _ServerSettingsPageState();
}

class _ServerSettingsPageState extends State<ServerSettingsPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _urlController;

  bool _busy = false;
  String? _result;
  bool _resultIsError = false;

  @override
  void initState() {
    super.initState();
    _urlController = TextEditingController(text: ApiConfig.baseUrl);
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  void _showResult(String message, {bool isError = false}) {
    if (!mounted) return;
    setState(() {
      _result = message;
      _resultIsError = isError;
    });
  }

  /// Menguji URL yang diketik tanpa menyimpannya dan tanpa mengubah alamat
  /// yang sedang dipakai, supaya kesalahan ketik tidak merusak sesi berjalan.
  Future<void> _test() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() {
      _busy = true;
      _result = null;
    });

    final api = context.read<ApiService>();

    try {
      final message = await ApiConfig.withBaseUrl(
        _urlController.text,
        api.ping,
      );
      _showResult(message);
    } on ApiException catch (e) {
      _showResult(e.message, isError: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// Menyimpan URL lalu menyegarkan katalog supaya perubahan langsung terlihat
  /// tanpa restart app.
  ///
  /// Alamat baru diuji dulu sebelum disimpan. Versi sebelumnya langsung
  /// memanggil [ApiConfig.saveBaseUrl] lalu ping, sehingga alamat yang gagal
  /// tes tetap tertulis di SharedPreferences dan app terus menembak host mati
  /// sampai user membuka halaman ini lagi. Menyimpan di akhir membuat kegagalan
  /// ping berarti app kembali ke alamat lama yang masih bekerja.
  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() {
      _busy = true;
      _result = null;
    });

    final api = context.read<ApiService>();
    final catalog = context.read<CatalogProvider>();
    final candidate = _urlController.text.trim();

    var tersimpan = false;

    try {
      await ApiConfig.withBaseUrl(candidate, api.ping);

      if (!mounted) return;

      await ApiConfig.saveBaseUrl(candidate);
      tersimpan = true;

      await catalog.loadCategories();
      await catalog.loadProducts(refresh: true);

      _showResult('Alamat server disimpan: ${ApiConfig.baseUrl}');
    } on ApiException catch (e) {
      _showResult(
        '${e.message}\n\nAlamat tidak disimpan. App masih memakai '
        '${ApiConfig.baseUrl}.',
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
          // Kalau gagal tes, isian dibiarkan seperti yang diketik user supaya
          // bisa langsung diperbaiki. Kalau berhasil, isian diselaraskan dengan
          // bentuk final yang benar-benar tersimpan (mis. slash dibuang).
          if (tersimpan) _urlController.text = ApiConfig.baseUrl;
        });
      }
    }
  }

  /// Membuang alamat yang disimpan. Katalog juga dimuat ulang karena alamat
/// aktif ikut berubah, sama seperti saat menyimpan.
Future<void> _reset() async {
    setState(() {
      _busy = true;
      _result = null;
    });

    try {
      await ApiConfig.resetBaseUrl();

      if (!mounted) return;

      final catalog = context.read<CatalogProvider>();
      await catalog.loadCategories();
      await catalog.loadProducts(refresh: true);

      _showResult('Kembali ke bawaan: ${ApiConfig.baseUrl}');
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
          _urlController.text = ApiConfig.baseUrl;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Koneksi Server')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const InfoBanner(
                icon: Icons.wifi_tethering,
                color: Color(0xFFB45309),
                background: AppColors.accentSoft,
                message: 'HP asli tidak bisa memakai localhost atau 10.0.2.2. '
                    'Isi alamat IP PC yang menjalankan backend, contoh '
                    'http://192.168.10.57:8000. HP dan PC harus terhubung WiFi '
                    'yang sama.',
              ),
              const SizedBox(height: 10),
              // Alamat ngrok juga sah, tapi perilakunya berbeda: tidak butuh
              // Wi-Fi yang sama dan alamatnya berganti tiap tunnel diulang.
              const InfoBanner(
                icon: Icons.public,
                color: AppColors.textSecondary,
                background: AppColors.surfaceAlt,
                message: 'Butuh akses dari luar jaringan? Pakai tunnel ngrok: '
                    'jalankan `ngrok http 8000` di PC yang menjalankan backend, '
                    'lalu isi alamat https://xxx.ngrok-free.app di sini. Tunnel '
                    'punya kuota dan alamatnya berubah tiap kali dijalankan '
                    'ulang.',
              ),
              const SizedBox(height: 24),

              const SectionHeading('Pilihan cepat'),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final option in ApiConfig.suggestions)
                    ActionChip(
                      label: Text('${option.label} · ${option.url}'),
                      avatar: const Icon(Icons.bolt, size: 16),
                      backgroundColor: AppColors.card,
                      side: const BorderSide(color: AppColors.outline),
                      onPressed: _busy
                          ? null
                          : () => setState(() {
                                _urlController.text = option.url;
                                _result = null;
                              }),
                    ),
                ],
              ),
              const SizedBox(height: 24),

              // Alamat yang benar-benar sedang dipakai ditampilkan terpisah
              // dari isian, supaya user bisa membandingkan kandidat yang diketik
              // dengan alamat aktif tanpa harus mengingatnya.
              _StatusAlamatAktif(controller: _urlController),
              const SizedBox(height: 16),

              TextFormField(
                controller: _urlController,
                autocorrect: false,
                keyboardType: TextInputType.url,
                decoration: const InputDecoration(
                  labelText: 'Alamat server',
                  hintText: 'http://192.168.10.57:8000',
                  prefixIcon: Icon(Icons.dns_outlined),
                ),
                validator: (value) {
                  final url = (value ?? '').trim();
                  if (url.isEmpty) return 'Alamat server wajib diisi.';
                  if (url.contains(' ')) {
                    return 'Alamat tidak boleh mengandung spasi.';
                  }

                  final parsed = Uri.tryParse(
                    url.startsWith('http') ? url : 'http://$url',
                  );
                  if (parsed == null ||
                      parsed.host.isEmpty ||
                      !parsed.host.contains('.')) {
                    return 'Alamat harus punya host yang valid, contoh '
                        'http://192.168.10.57:8000 atau https://tunnel.dev';
                  }
                  // Port hanya wajib untuk alamat tanpa scheme default. Tunnel
                  // ngrok selalu https tanpa port eksplisit, jadi sebelumnya
                  // alamat itu ditolak although sebenarnya bisa dipakai.
                  if (!url.startsWith('http') && !parsed.hasPort) {
                    return 'Alamat tanpa http:// wajib menyebut port, contoh 192.168.10.57:8000';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 6),
              Text(
                'Tidak perlu menulis /api di akhir. Boleh pakai http://IP:port '
                'untuk IP LAN, atau https://...ngrok-free.app untuk tunnel ngrok.',
                style: const TextStyle(
                  fontSize: 12,
                  height: 1.4,
                  color: AppColors.textSecondary,
                ),
              ),
              // Build dengan --dart-define punya bawaan sendiri yang perlu
              // disebut, supaya user tahu asal alamatnya dan urutan prioritasnya.
              if (ApiConfig.hasDartDefine) ...[
                const SizedBox(height: 6),
                Text(
                  'Build ini punya bawaan dari --dart-define: '
                  '${ApiConfig.dartDefineBaseUrl}. Alamat yang disimpan di sini '
                  'tetap dipakai dan mengalahkannya.',
                  style: const TextStyle(
                    fontSize: 12,
                    height: 1.4,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
              const SizedBox(height: 16),

              if (_result != null) ...[
                InfoBanner(
                  icon: _resultIsError
                      ? Icons.error_outline
                      : Icons.check_circle_outline,
                  color: _resultIsError ? AppColors.danger : AppColors.success,
                  background: _resultIsError
                      ? AppColors.dangerSoft
                      : AppColors.successSoft,
                  message: _result!,
                ),
                const SizedBox(height: 16),
              ],

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _busy ? null : _test,
                      icon: const Icon(Icons.wifi_tethering, size: 18),
                      label: const Text('Tes Koneksi'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: _busy ? null : _save,
                      icon: const Icon(Icons.save_outlined, size: 18),
                      label: const Text('Simpan'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              TextButton(
                onPressed: _busy ? null : _reset,
                child: const Text('Kembalikan ke bawaan'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Menampilkan alamat yang sedang aktif beserta asalnya.
///
/// Dibaca lewat [ApiConfig.baseUrlChanges] karena `ApiConfig` bersifat statis
/// dan perubahan URL tidak melewati Provider.
class _StatusAlamatAktif extends StatelessWidget {
  const _StatusAlamatAktif({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller,
      builder: (context, typed, _) {
        return ValueListenableBuilder<String>(
          valueListenable: ApiConfig.baseUrlChanges,
          builder: (context, activeUrl, _) => _build(activeUrl, typed.text),
        );
      },
    );
  }

  Widget _build(String activeUrl, String typedText) {
    final candidate = typedText.trim();
    final berbedaDenganAktif =
        candidate.isNotEmpty && candidate != activeUrl;

    return AppCard(
      color: AppColors.surfaceAlt,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.link, size: 15, color: AppColors.textSecondary),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Sedang dipakai (${ApiConfig.activeBaseUrlSource})',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          SelectableText(
            activeUrl,
            style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600),
          ),
          if (berbedaDenganAktif) ...[
            const SizedBox(height: 8),
            Text(
              'Alamat di bawah ini berbeda dari yang aktif. Tekan Simpan untuk '
              'memakainya seterusnya.',
              style: TextStyle(fontSize: 11.5, height: 1.4, color: AppColors.textSecondary),
            ),
          ],
        ],
      ),
    );
  }
}