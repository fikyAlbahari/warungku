import 'package:flutter/material.dart';

import '../theme.dart';

/// Lencana kecil untuk status dan metadata.
///
/// Dipakai buat "Tersisa 3 kg", "Menunggu", "Disetujui", dan sejenisnya.
/// Bentuknya kapsul penuh supaya sekilas terbaca sebagai label, bukan teks
/// yang ikut mengalir di paragraf.
class AppPill extends StatelessWidget {
  const AppPill(
    this.label, {
    super.key,
    this.color = AppColors.primary,
    this.background,
    this.icon,
    this.dense = false,
  });

  final String label;
  final Color color;
  final Color? background;
  final IconData? icon;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: dense ? 8 : 10,
        vertical: dense ? 3 : 5,
      ),
      decoration: BoxDecoration(
        color: background ?? color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: dense ? 11 : 13, color: color),
            SizedBox(width: dense ? 3 : 5),
          ],
          // Teks dibuat fleksibel dengan ellipsis. Lencana dipakai di tempat
          // yang lebarnya bisa sempit (grid 2 kolom), dan label seperti
          // "Tidak tersedia" bersama ikon sudah melebihi lebar itu.
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: dense ? 10.5 : 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.1,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Kartu dasar aplikasi.
///
/// Semua blok besar di aplikasi ini memakai widget ini supaya keliling, bayangan,
/// dan ketebalan garis selalu sama. `onTap` dipakai untuk kartu yang bisa diketuk;
/// tanpa `onTap` kartu tetap bisa diberi `padding` sendiri.
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(16),
    this.color,
    this.borderRadius,
    this.border,
    this.shadows,
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final Color? color;
  final BorderRadius? borderRadius;
  final BoxBorder? border;
  final List<BoxShadow>? shadows;

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? BorderRadius.circular(AppRadius.card);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: color ?? AppColors.card,
        borderRadius: radius,
        border: border,
        boxShadow: shadows ?? AppShadows.card,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: radius,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          borderRadius: radius,
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

/// Judul bagian dengan aksi opsional di kanan.
///
/// `eyebrow` adalah teks kecil berwarna primer di atas judul. Pola ini
/// dipakai berulang di halaman beranda supaya beberapa bagian terlihat berasal
/// dari satu sistem, bukan setiap widget improvisasi sendiri.
class SectionHeading extends StatelessWidget {
  /// [title] dibuat posisional supaya penulisan ringkas di halaman yang sudah
  /// banyak, seperti `const SectionHeading('Rincian Pesanan')`.
  const SectionHeading(
    this.title, {
    super.key,
    this.eyebrow,
    this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String? eyebrow;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (eyebrow != null) ...[
                Text(
                  eyebrow!,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.9,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 4),
              ],
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.4,
                  color: AppColors.textPrimary,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 3),
                Text(
                  subtitle!,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ],
          ),
        ),
        if (actionLabel != null && onAction != null)
          TextButton(
            onPressed: onAction,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              minimumSize: const Size(0, 36),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(actionLabel!),
          ),
      ],
    );
  }
}

/// Baris informasi dengan ikon di kiri, untuk daftar aturan atau ringkasan.
///
/// Bedanya dengan [DetailRow]: di sini nilai bisa panjang dan bisa berupa
/// teks warna apa pun, sementara DetailRow mengasumsikan nilai pendek di
/// kanan. Dua komponen ini sengaja dipisah supaya tidak ada teks panjang yang
/// membuat kolom kanan sempit.
class InfoRow extends StatelessWidget {
  const InfoRow({
    super.key,
    required this.icon,
    required this.title,
    required this.body,
    this.iconColor = AppColors.primary,
    this.iconBackground,
  });

  final IconData icon;
  final String title;
  final String body;
  final Color iconColor;
  final Color? iconBackground;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconBackground ?? iconColor.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(AppRadius.field - 4),
            ),
            child: Icon(icon, size: 18, color: iconColor),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  body,
                  style: const TextStyle(
                    fontSize: 13,
                    height: 1.45,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Panel informasi untuk pesan penting: error koneksi, akun menunggu verifikasi,
/// atau pengumuman dari toko.
///
/// Disediakan `action` supaya pesan error bisa langsung membawa pengguna ke
/// tempat perbaikannya, tanpa harus menebak dari teks saja.
class InfoBanner extends StatelessWidget {
  const InfoBanner({
    super.key,
    required this.message,
    required this.icon,
    this.color = AppColors.info,
    this.background,
    this.action,
  });

  final String message;
  final IconData icon;
  final Color color;
  final Color? background;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: background ?? color.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(AppRadius.tile),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 19, color: color),
              const SizedBox(width: AppSpacing.sm + 2),
              Expanded(
                child: Text(
                  message,
                  style: TextStyle(
                    fontSize: 13.5,
                    height: 1.45,
                    fontWeight: FontWeight.w500,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
          if (action != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Align(alignment: Alignment.centerLeft, child: action),
          ],
        ],
      ),
    );
  }
}

/// Baris label-nilai untuk ringkasan biaya dan detail pesanan.
///
/// Nilainya selalu pendek dan angka atau kata singkat, jadi ditampilkan rata
/// kanan. Untuk teks panjang gunakan [InfoRow].
class DetailRow extends StatelessWidget {
  const DetailRow(
    this.label,
    this.value, {
    super.key,
    this.emphasize = false,
  });

  final String label;
  final String value;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      fontSize: emphasize ? 16 : 13.5,
      fontWeight: emphasize ? FontWeight.w700 : FontWeight.w500,
      color: emphasize ? AppColors.textPrimary : AppColors.textSecondary,
    );

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: style),
        const SizedBox(width: AppSpacing.md),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: TextStyle(
              fontSize: emphasize ? 17 : 13.5,
              fontWeight: FontWeight.w700,
              color: emphasize ? AppColors.primary : AppColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}