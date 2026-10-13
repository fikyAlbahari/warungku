import 'package:flutter/material.dart';

/// Warna aplikasi. Semua warna yang dipakai UI dikumpulkan di sini supaya
/// tidak ada hex warna liar yang tersebar di tiap halaman.
class AppColors {
  const AppColors._();

  /// Hijau-teal sebagai warna utama: Francois Fresh hijau sudah dipakai di
  /// logo, jadi warna yang sama dipakai untuk tombol dan state aktif.
  static const Color primary = Color(0xFF0F766E);
  static const Color primaryDark = Color(0xFF115E59);
  static const Color primarySoft = Color(0xFFE3F1EF);

  /// Amber hanya untuk penekanan sekunder (badge keranjang, stok menipis).
  static const Color accent = Color(0xFFF59E0B);
  static const Color accentSoft = Color(0xFFFEF3C7);

  static const Color danger = Color(0xFFDC2626);
  static const Color dangerSoft = Color(0xFFFEE2E2);
  static const Color success = Color(0xFF16A34A);
  static const Color successSoft = Color(0xFFDCFCE7);
  static const Color info = Color(0xFF2563EB);
  static const Color infoSoft = Color(0xFFDBEAFE);

  /// Latar halaman dibedakan dari kartu putih supaya isi tidak terlihat datar.
  static const Color surface = Color(0xFFF6F7F9);
  static const Color surfaceAlt = Color(0xFFEEF1F4);
  static const Color card = Colors.white;

  static const Color textPrimary = Color(0xFF111827);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textTertiary = Color(0xFF9AA3AF);
  static const Color outline = Color(0xFFE5E7EB);

  /// Warna penutup headline besar. Teal pekat dipakai untuk tombol dan chip
  /// aktif, sementara teks besar ditutup abu tua agar kontrasnya tetap aman
  /// di atas latar terang.
  static const Color ink = Color(0xFF0B1220);
}

/// Gradien yang dipakai bersama supaya blok besar di beberapa halaman terasa
/// berasal dari satu sumber, bukan tiap layar membuat gradasinya sendiri.
class AppGradients {
  const AppGradients._();

  /// Hero di beranda dan header halaman masuk.
  static const LinearGradient hero = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF14B8A6), Color(0xFF0F766E), Color(0xFF0B4F4A)],
    stops: [0, 0.55, 1],
  );

  /// Blok solid untuk tombol utama yang butuh kedalaman lebih.
  static const LinearGradient primary = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF14958C), Color(0xFF0F766E)],
  );

  /// Latar login: jauh lebih lembut dari hero supaya form di depannya tetap
  /// jadi fokus mata.
  static const LinearGradient login = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFF0FAF8), Color(0xFFE6F2F0), Color(0xFFF6F7F9)],
    stops: [0, 0.55, 1],
  );
}

/// Radius konsisten. Kartu besar dan sudut membulat adalah ciri tampilan
/// modern; semua widget memakai nilai dari sini, bukan angka sendiri.
class AppRadius {
  const AppRadius._();

  static const double card = 24;
  static const double hero = 28;
  static const double field = 16;
  static const double button = 16;
  static const double tile = 18;
  static const double pill = 999;
}

/// Jarak antarbagian halaman. Pakai kelipatan 4 supaya ritme antar kartu
/// dan judul seksinya terasa rata.
class AppSpacing {
  const AppSpacing._();

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;

  static const EdgeInsets screen = EdgeInsets.fromLTRB(16, 16, 16, 24);
}

/// Bayangan lembut menggantikan garis hitam tipis. Garis penuh membuat
/// tampilan berat, jadi kartu hanya dibedakan lewat bayangan dan warna.
class AppShadows {
  const AppShadows._();

  /// Bayangan kartu katalog: sangat tipis dan jauh, bukan garis tebal.
  /// Kesan "mengambang" modern datang dari bayangan lebar dengan offset kecil,
  /// bukan dari garis tepi yang gelap.
  static const List<BoxShadow> card = [
    BoxShadow(
      color: Color(0x0A0B1220),
      blurRadius: 24,
      offset: Offset(0, 8),
    ),
    BoxShadow(
      color: Color(0x05111827),
      blurRadius: 3,
      offset: Offset(0, 1),
    ),
  ];

  static const List<BoxShadow> lifted = [
    BoxShadow(
      color: Color(0x1A0B1220),
      blurRadius: 32,
      offset: Offset(0, 14),
    ),
  ];

  /// Bayangan untuk nav bar melayang di atas konten.
  static const List<BoxShadow> nav = [
    BoxShadow(
      color: Color(0x0F0B1220),
      blurRadius: 28,
      offset: Offset(0, -4),
    ),
  ];
}

ThemeData buildAppTheme() {
  const colorScheme = ColorScheme(
    brightness: Brightness.light,
    primary: AppColors.primary,
    onPrimary: Colors.white,
    primaryContainer: AppColors.primarySoft,
    onPrimaryContainer: AppColors.primaryDark,
    secondary: AppColors.accent,
    onSecondary: Colors.white,
    secondaryContainer: AppColors.accentSoft,
    onSecondaryContainer: Color(0xFF92400E),
    tertiary: AppColors.info,
    onTertiary: Colors.white,
    tertiaryContainer: AppColors.infoSoft,
    onTertiaryContainer: Color(0xFF1E40AF),
    error: AppColors.danger,
    onError: Colors.white,
    errorContainer: AppColors.dangerSoft,
    onErrorContainer: Color(0xFF991B1B),
    surface: AppColors.card,
    onSurface: AppColors.textPrimary,
    onSurfaceVariant: AppColors.textSecondary,
    surfaceContainerLowest: Colors.white,
    surfaceContainerLow: Color(0xFFFBFBFC),
    surfaceContainer: AppColors.surface,
    surfaceContainerHigh: AppColors.surfaceAlt,
    surfaceContainerHighest: Color(0xFFE6EAEE),
    outline: AppColors.outline,
    outlineVariant: Color(0xFFEDF0F2),
    shadow: Color(0x1A111827),
    scrim: Color(0x66111827),
    inverseSurface: Color(0xFF1F2937),
    onInverseSurface: Colors.white,
    inversePrimary: Color(0xFF7FD3C9),
  );

  final base = ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: AppColors.surface,
    splashFactory: InkSparkle.splashFactory,
  );

  return base.copyWith(
    // AppBar sekarang putih seperti halaman, bukan blok warna penuh. Judul
    // thicken dan ada garis tipis di bawah saat konten digulir.
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.card,
      foregroundColor: AppColors.textPrimary,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      iconTheme: const IconThemeData(color: AppColors.textPrimary),
      titleTextStyle: const TextStyle(
        color: AppColors.textPrimary,
        fontSize: 19,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.4,
      ),
    ),

    // NavigationBar tidak dipakai: beranda memakai bottom nav kustom yang
    // melayang. Tema ini hanya menjaga agar halaman lain yang punya
    // NavigationBar bawaan tidak terlihat asing.
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: AppColors.card,
      surfaceTintColor: Colors.transparent,
      indicatorColor: AppColors.primarySoft,
      elevation: 0,
      height: 66,
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
    ),
    cardTheme: CardThemeData(
      color: AppColors.card,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        // Gradien, bukan warna solid: tombol utama jadi terasa sebagai satu
        // elemen yang menonjol tanpa harus memakai warna lebih terang.
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        minimumSize: const Size(0, 56),
        padding: const EdgeInsets.symmetric(horizontal: 22),
        elevation: 0,
        textStyle: const TextStyle(
          fontSize: 15.5,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.1,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.button),
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primary,
        minimumSize: const Size(0, 52),
        side: const BorderSide(color: AppColors.primary, width: 1.4),
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.button),
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.primary,
        textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      // Isian form tidak lagi putih di atas latar putih: warnaAbu sangat
      // terang memisahkannya dari kartu tanpa perlu garis tepi.
      fillColor: AppColors.card,
      isDense: false,
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
      border: _fieldBorder(AppColors.outline),
      enabledBorder: _fieldBorder(AppColors.outline),
      focusedBorder: _fieldBorder(AppColors.primary, width: 1.8),
      errorBorder: _fieldBorder(AppColors.danger),
      focusedErrorBorder: _fieldBorder(AppColors.danger, width: 1.6),
      labelStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 14.5),
      hintStyle: const TextStyle(color: AppColors.textTertiary, fontSize: 14.5),
      prefixIconColor: AppColors.textTertiary,
      suffixIconColor: AppColors.textTertiary,
      floatingLabelStyle: const TextStyle(
        color: AppColors.primary,
        fontWeight: FontWeight.w600,
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: AppColors.card,
      selectedColor: AppColors.primary,
      side: const BorderSide(color: AppColors.outline),
      labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
      shape: const StadiumBorder(),
      showCheckmark: false,
    ),
    dividerTheme: const DividerThemeData(
      color: AppColors.outline,
      thickness: 1,
      space: 1,
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: AppColors.card,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      titleTextStyle: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: const Color(0xFF1F2937),
      contentTextStyle: const TextStyle(
        color: Colors.white,
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.tile),
      ),
      insetPadding: const EdgeInsets.all(16),
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: AppColors.primary,
      strokeWidth: 2.5,
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.button),
      ),
    ),
    popupMenuTheme: PopupMenuThemeData(
      color: AppColors.card,
      surfaceTintColor: Colors.transparent,
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.tile),
      ),
    ),
    textTheme: base.textTheme.apply(
      bodyColor: AppColors.textPrimary,
      displayColor: AppColors.textPrimary,
    ),
  );
}

OutlineInputBorder _fieldBorder(Color color, {double width = 1}) {
  return OutlineInputBorder(
    borderRadius: BorderRadius.circular(AppRadius.field),
    borderSide: BorderSide(color: color, width: width),
  );
}