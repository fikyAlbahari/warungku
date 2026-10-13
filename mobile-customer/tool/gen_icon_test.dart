// Generator ikon aplikasi (bukan test sesungguhnya).
//
// Menjalankan:  flutter test tool/gen_icon_test.dart
//              dart run flutter_launcher_icons
//
// Menghasilkan tiga gambar di assets/icon:
//  - app_icon.png            : ikon launcher (full square)
//  - app_icon_background.png : latar adaptive (gradien brand)
//  - app_icon_foreground.png : foreground adaptive (zona aman)
//
// Desain: badge lingkaran putih di tengah latar gradien teal, memuat tulisan
// "Warung" di atas dan "Nara" di bawah sebagai identitas merek, ditutup garis
// aksen amber. Huruf memakai font tebal dari sistem karena lingkungan
// `flutter test` tidak memuat font asli (teks default tampil sebagai kotak).

import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

const double _size = 1024;
const int _kanvas = 1024;

const _gradien = [
  Color(0xFF14B8A6),
  Color(0xFF0F766E),
  Color(0xFF0B4F4A),
];
const _stops = [0.0, 0.55, 1.0];

// Nama family font yang dimuat dari sistem pada runtime generator.
const String _familyFont = 'MerekIkon';

// Zona aman adaptive (tidak terpotong masker)
const double _foregroundScale = 0.78;

void main() {
  testWidgets('render app icon png', (tester) async {
    await tester.runAsync(() async {
      await _muatFont();

      await _tulis(
        'assets/icon/app_icon.png',
        _render(background: true, contentScale: 1.0),
      );
      await _tulis(
        'assets/icon/app_icon_background.png',
        _render(background: true, contentScale: null),
      );
      await _tulis(
        'assets/icon/app_icon_foreground.png',
        _render(background: false, contentScale: _foregroundScale),
      );
    });
  });
}

/// Muat font tebal dari sistem supaya glyph tidak jadi kotak di `flutter test`.
///
/// Daftar kandidat menutupi Windows, macOS, dan distro Linux umum, sehingga
/// generator tetap jalan di mesin pengembang yang berbeda.
Future<void> _muatFont() async {
  const kandidat = <String>[
    r'C:\Windows\Fonts\arialbd.ttf',
    r'C:\Windows\Fonts\segoeuib.ttf',
    '/System/Library/Fonts/Supplemental/Arial Bold.ttf',
    '/Library/Fonts/Arial Bold.ttf',
    '/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf',
    '/usr/share/fonts/truetype/liberation/LiberationSans-Bold.ttf',
  ];

  for (final path in kandidat) {
    final file = File(path);
    if (!file.existsSync()) continue;

    final loader = FontLoader(_familyFont)
      ..addFont(Future<ByteData>.value((await file.readAsBytes()).buffer.asByteData()));
    await loader.load();
    return;
  }

  // ignore: avoid_print
  print('PERINGATAN: font tebal sistem tidak ditemukan; teks ikon bisa jadi kotak.');
}

Future<void> _tulis(String path, Future<ui.Image> image) async {
  final img = await image;
  final data = await img.toByteData(format: ui.ImageByteFormat.png);
  final file = File(path);
  await file.parent.create(recursive: true);
  await file.writeAsBytes(data!.buffer.asUint8List());
  // ignore: avoid_print
  print('tertulis: ${file.absolute.path} (${data.lengthInBytes} byte)');
}

Future<ui.Image> _render({
  required bool background,
  required double? contentScale,
}) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);

  if (background) {
    _gambarLatar(canvas);
  }

  if (contentScale != null) {
    if (contentScale != 1.0) {
      final half = _size / 2;
      canvas.translate(half, half);
      canvas.scale(contentScale);
      canvas.translate(-half, -half);
    }
    _gambarIsi(canvas);
  }

  final picture = recorder.endRecording();
  return picture.toImage(_kanvas, _kanvas);
}

void _gambarLatar(Canvas canvas) {
  final rect = Rect.fromLTWH(0, 0, _size, _size);
  canvas.drawRect(
    rect,
    Paint()
      ..shader = ui.Gradient.linear(
        rect.topLeft,
        rect.bottomRight,
        _gradien,
        _stops,
      ),
  );

  // Cahaya lembut supaya latar tidak datar.
  canvas.drawCircle(
    Offset(_size * 0.20, _size * 0.16),
    _size * 0.36,
    Paint()..color = Colors.white.withValues(alpha: 0.07),
  );
  canvas.drawCircle(
    Offset(_size * 0.85, _size * 0.84),
    _size * 0.30,
    Paint()..color = const Color(0xFFF59E0B).withValues(alpha: 0.10),
  );
}

void _gambarIsi(Canvas canvas) {
  // Lingkaran badge putih di tengah sebagai kanvas tulisan.
  final pusat = Offset(_size * 0.50, _size * 0.50);
  final radius = _size * 0.300;

  canvas.drawCircle(
    pusat + Offset(_size * 0.014, _size * 0.022),
    radius,
    Paint()..color = const Color(0xFF115E59).withValues(alpha: 0.25),
  );
  canvas.drawCircle(pusat, radius, Paint()..color = Colors.white);

  // Identitas merek di dalam badge.
  _gambarTeks(
    canvas,
    'Warung',
    ukuran: _size * 0.085,
    pusatY: _size * 0.452,
    warna: const Color(0xFF0F766E),
    spasi: _size * 0.010,
  );
  _gambarTeks(
    canvas,
    'Nara',
    ukuran: _size * 0.165,
    pusatY: _size * 0.565,
    warna: const Color(0xFF115E59),
  );

  // Garis aksen amber di bawah tulisan.
  final aksen = Rect.fromCenter(
    center: Offset(_size * 0.50, _size * 0.660),
    width: _size * 0.200,
    height: _size * 0.020,
  );
  canvas.drawRRect(
    RRect.fromRectAndRadius(aksen, Radius.circular(_size * 0.05)),
    Paint()..color = const Color(0xFFF59E0B),
  );
}

void _gambarTeks(
  Canvas canvas,
  String teks, {
  required double ukuran,
  required double pusatY,
  required Color warna,
  double spasi = 0,
}) {
  final painter = TextPainter(
    text: TextSpan(
      text: teks,
      style: TextStyle(
        fontFamily: _familyFont,
        fontSize: ukuran,
        fontWeight: FontWeight.w800,
        color: warna,
        letterSpacing: spasi,
        height: 1.0,
      ),
    ),
    textDirection: TextDirection.ltr,
    textAlign: TextAlign.center,
  )..layout();

  painter.paint(
    canvas,
    Offset((_size - painter.width) / 2, pusatY - painter.height / 2),
  );
}
