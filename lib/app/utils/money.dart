/// 148650 -> $148,650.00 (decimals: 0 -> $148,650).
String formatCad(double v, {int decimals = 2, bool sign = false}) {
  final neg = v < 0;
  final parts = v.abs().toStringAsFixed(decimals).split('.');
  final whole = parts[0].replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
    (m) => ',',
  );
  final frac = decimals > 0 ? '.${parts[1]}' : '';
  final prefix = neg ? '-' : (sign ? '+' : '');
  return '$prefix\$$whole$frac';
}
