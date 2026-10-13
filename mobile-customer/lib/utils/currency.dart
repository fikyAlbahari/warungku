/// Format angka ala Indonesia: 15000 -> "Rp 15.000"
String formatRupiah(num value, {bool withPrefix = true}) {
  final isNegative = value < 0;
  final digits = value.abs().round().toString();
  final buffer = StringBuffer();

  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buffer.write('.');
    buffer.write(digits[i]);
  }

  final prefix = isNegative ? '-Rp ' : 'Rp ';
  return withPrefix ? '$prefix$buffer' : '${isNegative ? '-' : ''}$buffer';
}
