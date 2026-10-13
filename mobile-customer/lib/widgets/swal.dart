import 'dart:async';

import 'package:flutter/material.dart';

import '../theme.dart';

/// Jenis ikon khas SweetAlert2.
enum SwalIkon { success, error, warning, info, question, loading }

/// Pop-up dan toast ala SweetAlert2 (web) untuk Flutter.
///
/// Sebelumnya notifikasi di app ini memakai `SnackBar` dan `AlertDialog`
/// bawaan Material. Keduanya berfungsi, tapi tampilannya berbeda dari panel
/// web yang memakai SweetAlert2: di sana pop-up tampil di tengah dengan ikon
/// lingkaran berwarna, dan pesan ringkas muncul sebagai toast di pojok kanan
/// atas. Kelas ini meniru dua bentuk itu agar HP dan web terasa satu keluarga.
class Swal {
  const Swal._();

  /// Warna tombol konfirmasi: sama dengan `bg-teal-600` di panel web.
  static const Color _confirm = Color(0xFF0D9488);

  /// Warna tombol konfirmasi untuk aksi merusak (`berbahaya`): rose-600.
  static const Color _danger = Color(0xFFE11D48);

  /// Latar belakang gelap SweetAlert2: rgba(0,0,0,.6).
  static const Color _backdrop = Color(0x99000000);

  // ---------------------------------------------------------------------------
  // Modal di tengah layar
  // ---------------------------------------------------------------------------

  /// Modal sukses dengan centang hijau. Mengembalikan saat ditutup.
  static Future<void> sukses(
    BuildContext context, {
    String? judul,
    required String pesan,
  }) =>
      _dialog<void>(
        context,
        builder: (dialogContext) => _SwalPopup(
          ikon: SwalIkon.success,
          judul: judul ?? 'Sukses',
          pesan: pesan,
          actions: [_tombolTutup(dialogContext, 'Oke')],
        ),
      );

  /// Modal peringatan dengan ikon kuning.
  static Future<void> peringatan(
    BuildContext context, {
    String? judul,
    required String pesan,
  }) =>
      _dialog<void>(
        context,
        builder: (dialogContext) => _SwalPopup(
          ikon: SwalIkon.warning,
          judul: judul ?? 'Perhatian',
          pesan: pesan,
          actions: [_tombolTutup(dialogContext, 'Mengerti')],
        ),
      );

  /// Modal informasi dengan ikon biru.
  static Future<void> info(
    BuildContext context, {
    String? judul,
    required String pesan,
  }) =>
      _dialog<void>(
        context,
        builder: (dialogContext) => _SwalPopup(
          ikon: SwalIkon.info,
          judul: judul ?? 'Informasi',
          pesan: pesan,
          actions: [_tombolTutup(dialogContext, 'Oke')],
        ),
      );

  /// Modal galat dengan ikon merah. Pesan biasanya datang dari server.
  static Future<void> gagal(
    BuildContext context, {
    String? judul,
    required String pesan,
  }) =>
      _dialog<void>(
        context,
        builder: (dialogContext) => _SwalPopup(
          ikon: SwalIkon.error,
          judul: judul ?? 'Terjadi Kesalahan',
          pesan: pesan,
          actions: [_tombolTutup(dialogContext, 'Mengerti')],
        ),
      );

  /// Modal untuk daftar galat validasi (satu poin per baris).
  static Future<void> gagalDaftar(
    BuildContext context, {
    required List<String> daftar,
    String judul = 'Data belum dapat disimpan',
  }) =>
      _dialog<void>(
        context,
        builder: (dialogContext) => _SwalPopup(
          ikon: SwalIkon.error,
          judul: judul,
          daftar: daftar,
          actions: [_tombolTutup(dialogContext, 'Mengerti')],
        ),
      );

  /// Dialog konfirmasi. Mengembalikan `true` bila tombol konfirmasi ditekan.
  ///
  /// Tata letak tombol meniru SweetAlert2: tombol batal di kiri, tombol
  /// konfirmasi di kanan. Aksi merusak ([berbahaya]) mengecat tombol
  /// konfirmasi merah, seperti tombol "Hapus" di panel web.
  static Future<bool> konfirmasi(
    BuildContext context, {
    required String judul,
    String pesan = '',
    String teksYa = 'Ya, lanjutkan',
    String teksTidak = 'Batal',
    SwalIkon ikon = SwalIkon.warning,
    bool berbahaya = false,
  }) async {
    final hasil = await _dialog<bool>(
      context,
      builder: (dialogContext) => _SwalPopup(
        ikon: ikon,
        judul: judul,
        pesan: pesan,
        actions: [
          _SwalButton(
            label: teksTidak,
            variant: _SwalButtonVariant.cancel,
            onPressed: () => Navigator.of(dialogContext).pop(false),
          ),
          _SwalButton(
            label: teksYa,
            variant: berbahaya
                ? _SwalButtonVariant.danger
                : _SwalButtonVariant.confirm,
            onPressed: () => Navigator.of(dialogContext).pop(true),
          ),
        ],
      ),
    );
    return hasil ?? false;
  }

  /// Modal tanpa tombol untuk proses panjang (mis. mengirim pesanan).
  ///
  /// Tutup dari pemanggil dengan `Navigator.of(context, rootNavigator: true).pop()`.
  static Future<void> muat(
    BuildContext context, {
    String? judul,
    String pesan = 'Memuat...',
  }) =>
      _dialog<void>(
        context,
        barrierDismissible: false,
        builder: (_) => _SwalPopup(ikon: SwalIkon.loading, judul: judul, pesan: pesan),
      );

  // ---------------------------------------------------------------------------
  // Toast di pojok kanan atas
  // ---------------------------------------------------------------------------

  /// Toast ringkas yang menghilang sendiri, analog `Swal.mixin({ toast: true })`
  /// di web. Muncul dari kanan atas dan punya garis progres di bawahnya.
  static void toast(
    BuildContext context,
    String pesan, {
    SwalIkon ikon = SwalIkon.info,
    Duration durasi = const Duration(milliseconds: 3500),
  }) {
    final overlay = Overlay.of(context, rootOverlay: true);
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => _SwalToast(
        ikon: ikon,
        pesan: pesan,
        durasi: durasi,
        onClose: () => entry.remove(),
      ),
    );
    overlay.insert(entry);
  }

  static void toastSukses(BuildContext context, String pesan) =>
      toast(context, pesan, ikon: SwalIkon.success);

  static void toastInfo(BuildContext context, String pesan) =>
      toast(context, pesan, ikon: SwalIkon.info);

  static void toastPeringatan(BuildContext context, String pesan) =>
      toast(context, pesan, ikon: SwalIkon.warning);

  static void toastGagal(BuildContext context, String pesan) =>
      toast(context, pesan, ikon: SwalIkon.error);

  // ---------------------------------------------------------------------------
  // Internals
  // ---------------------------------------------------------------------------

  static Future<T?> _dialog<T>(
    BuildContext context, {
    required WidgetBuilder builder,
    bool barrierDismissible = true,
  }) {
    return showGeneralDialog<T>(
      context: context,
      barrierDismissible: barrierDismissible,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      barrierColor: _backdrop,
      // SweetAlert2 membesarkan pop-up dari dalam dengan sedikit overshoot.
      transitionDuration: const Duration(milliseconds: 200),
      transitionBuilder: (context, animation, secondary, child) {
        final scale = CurvedAnimation(parent: animation, curve: Curves.easeOutBack);
        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.7, end: 1).animate(scale),
            alignment: Alignment.center,
            child: child,
          ),
        );
      },
      pageBuilder: (context, animation, secondary) => builder(context),
    );
  }

  static Widget _tombolTutup(BuildContext context, String label) => _SwalButton(
    label: label,
    variant: _SwalButtonVariant.confirm,
    onPressed: () => Navigator.of(context).pop(),
  );
}

/// Pop-up modal ala SweetAlert2: kartu putih membulat berisi ikon, judul,
/// teks/daftar, lalu sederet tombol di bawah.
class _SwalPopup extends StatelessWidget {
  const _SwalPopup({
    required this.ikon,
    this.judul,
    this.pesan = '',
    this.actions = const [],
    this.daftar,
  });

  final SwalIkon ikon;
  final String? judul;
  final String pesan;
  final List<String>? daftar;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Container(
            padding: const EdgeInsets.fromLTRB(24, 22, 24, 18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: AppShadows.lifted,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _SwalIcon(ikon),
                if (judul != null && judul!.isNotEmpty) ...[
                  const SizedBox(height: 18),
                  Text(
                    judul!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      height: 1.25,
                      color: Color(0xFF595959),
                    ),
                  ),
                ],
                if (pesan.isNotEmpty || daftar != null) ...[
                  const SizedBox(height: 10),
                  _SwalBody(pesan: pesan, daftar: daftar),
                ],
                if (actions.isNotEmpty) ...[
                  const SizedBox(height: 22),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      for (var i = 0; i < actions.length; i++) ...[
                        if (i > 0) const SizedBox(width: 8),
                        actions[i],
                      ],
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Isi tengah pop-up: teks biasa atau daftar poin (untuk galat validasi).
class _SwalBody extends StatelessWidget {
  const _SwalBody({required this.pesan, required this.daftar});

  final String pesan;
  final List<String>? daftar;

  @override
  Widget build(BuildContext context) {
    final itemStyle = const TextStyle(
      fontSize: 14,
      height: 1.5,
      color: Color(0xFF545454),
    );

    if (daftar == null) {
      return Text(pesan, textAlign: TextAlign.center, style: itemStyle);
    }

    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 200),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final item in daftar!)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('•  ', style: itemStyle),
                    Expanded(child: Text(item, style: itemStyle)),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

enum _SwalButtonVariant { confirm, cancel, danger }

/// Tombol pop-up bergaya SweetAlert2.
///
/// Konfirmasi teal solid (sama dengan `bg-teal-600` di web), batal abu sangat
/// terang, dan varian berbahaya merah rose seperti tombol hapus di web.
class _SwalButton extends StatelessWidget {
  const _SwalButton({
    required this.label,
    required this.onPressed,
    required this.variant,
  });

  final String label;
  final VoidCallback onPressed;
  final _SwalButtonVariant variant;

  @override
  Widget build(BuildContext context) {
    final (foreground, background) = switch (variant) {
      _SwalButtonVariant.confirm => (Colors.white, Swal._confirm),
      _SwalButtonVariant.danger => (Colors.white, Swal._danger),
      _SwalButtonVariant.cancel => (
          const Color(0xFF334155),
          const Color(0xFFF1F5F9),
        ),
    };

    return Material(
      color: background,
      borderRadius: BorderRadius.circular(8),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onPressed,
        child: Container(
          constraints: const BoxConstraints(minWidth: 92),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 11),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: foreground,
            ),
          ),
        ),
      ),
    );
  }
}

/// Ikon lingkaran berwarna khas SweetAlert2, digambar sendiri supaya bentuk
/// garisnya sama dengan web (bukan ikon Material yang penuh).
class _SwalIcon extends StatelessWidget {
  const _SwalIcon(this.ikon, {this.size = 84});

  final SwalIkon ikon;
  final double size;

  static Color warna(SwalIkon ikon) => switch (ikon) {
    SwalIkon.success => const Color(0xFFA5DC86),
    SwalIkon.error => const Color(0xFFF27474),
    SwalIkon.warning => const Color(0xFFF8BB86),
    SwalIkon.info => const Color(0xFF3FC3EE),
    SwalIkon.question => const Color(0xFF87ADBD),
    SwalIkon.loading => Swal._confirm,
  };

  @override
  Widget build(BuildContext context) {
    if (ikon == SwalIkon.loading) {
      return SizedBox(
        width: size,
        height: size,
        child: CircularProgressIndicator(
          strokeWidth: 6,
          color: Swal._confirm,
          backgroundColor: const Color(0xFFE5E7EB),
        ),
      );
    }

    final color = warna(ikon);
    final isQuestion = ikon == SwalIkon.question;

    final ikonGambar = SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _SwalIconPainter(ikon),
        child: isQuestion
            ? Center(
                child: Text(
                  '?',
                  style: TextStyle(
                    fontSize: size * 0.45,
                    height: 1,
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                ),
              )
            : null,
      ),
    );
    return Center(child: ikonGambar);
  }
}

/// Pelukis ikon SweetAlert2. Gambar memakai koordinat kotak 84 lalu diskalakan
/// ke ukuran apa pun, jadi komponen yang sama dipakai pop-up dan toast.
class _SwalIconPainter extends CustomPainter {
  const _SwalIconPainter(this.ikon);

  final SwalIkon ikon;

  static const double _box = 84;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / _box, size.height / _box);

    final strokePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 7
      ..color = _SwalIcon.warna(ikon);

    final ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..color = _SwalIcon.warna(ikon);

    // Lingkaran luar selalu digambar, kecuali status loading.
    if (ikon != SwalIkon.loading) {
      canvas.drawCircle(const Offset(42, 42), 39, ringPaint);
    }

    switch (ikon) {
      case SwalIkon.success:
        final garis = Path()
          ..moveTo(16, 49)
          ..lineTo(31, 64)
          ..lineTo(66, 30);
        canvas.drawPath(garis, strokePaint);
      case SwalIkon.error:
        canvas.drawLine(const Offset(27, 27), const Offset(57, 57), strokePaint);
        canvas.drawLine(const Offset(57, 27), const Offset(27, 57), strokePaint);
      case SwalIkon.warning:
        canvas.drawLine(const Offset(42, 26), const Offset(42, 52), strokePaint);
        canvas.drawCircle(
          const Offset(42, 64),
          4.5,
          Paint()..color = _SwalIcon.warna(ikon),
        );
      case SwalIkon.info:
        canvas.drawCircle(
          const Offset(42, 28),
          4.5,
          Paint()..color = _SwalIcon.warna(ikon),
        );
        canvas.drawLine(const Offset(42, 38), const Offset(42, 54), strokePaint);
      case SwalIkon.question:
        break; // tanda tanya digambar sebagai teks di lapisan depan.
      case SwalIkon.loading:
        break;
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(_SwalIconPainter oldDelegate) => oldDelegate.ikon != ikon;
}

/// Toast ala SweetAlert2: menyelinap dari kanan, tinggal sesaat sambil
/// menampilkan garis progres, lalu menghilang ke kanan.
class _SwalToast extends StatefulWidget {
  const _SwalToast({
    required this.ikon,
    required this.pesan,
    required this.durasi,
    required this.onClose,
  });

  final SwalIkon ikon;
  final String pesan;
  final Duration durasi;
  final VoidCallback onClose;

  @override
  State<_SwalToast> createState() => _SwalToastState();
}

class _SwalToastState extends State<_SwalToast>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.durasi,
  )..forward();

  late final Animation<double> _masuk = CurvedAnimation(
    parent: _controller,
    curve: const Interval(0, 0.1, curve: Curves.easeOutCubic),
  );

  late final Animation<double> _keluar = CurvedAnimation(
    parent: _controller,
    curve: const Interval(0.9, 1, curve: Curves.easeInCubic),
  );

  @override
  void initState() {
    super.initState();
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) widget.onClose();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.paddingOf(context).top;

    return Positioned(
      top: topInset + 10,
      right: 12,
      left: 12,
      child: IgnorePointer(
        child: Center(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              final masuk = _masuk.value;
              final keluar = _keluar.value;
              final geser = (1 - masuk) * 80 + keluar * 80;

              return Opacity(
                opacity: masuk * (1 - keluar),
                child: Transform.translate(
                  offset: Offset(geser, 0),
                  child: child,
                ),
              );
            },
            child: _KartuToast(
              ikon: widget.ikon,
              pesan: widget.pesan,
              prosentase: _controller,
            ),
          ),
        ),
      ),
    );
  }
}

class _KartuToast extends StatelessWidget {
  const _KartuToast({
    required this.ikon,
    required this.pesan,
    required this.prosentase,
  });

  final SwalIkon ikon;
  final String pesan;
  final Animation<double> prosentase;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 340),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: AppShadows.lifted,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 14, 10),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _SwalIcon(ikon, size: 32),
                const SizedBox(width: 10),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 240),
                  child: Text(
                    pesan,
                    style: const TextStyle(
                      fontSize: 13.5,
                      height: 1.3,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          LayoutBuilder(
            builder: (context, constraints) => SizedBox(
              height: 3,
              child: LinearProgressIndicator(
                value: prosentase.value,
                valueColor: AlwaysStoppedAnimation(_SwalIcon.warna(ikon)),
                backgroundColor: const Color(0x14000000),
                minHeight: 3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}