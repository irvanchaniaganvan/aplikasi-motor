String formatNumber(int value) {
  final negative = value < 0;
  final digits = value.abs().toString();
  final groups = <String>[];
  for (var end = digits.length; end > 0; end -= 3) {
    final start = end - 3 < 0 ? 0 : end - 3;
    groups.insert(0, digits.substring(start, end));
  }
  final joined = groups.join('.');
  return negative ? '-$joined' : joined;
}

String formatKm(int value) => '${formatNumber(value)} km';

String? requiredNumber(String? value, String message) {
  final number = int.tryParse(value?.trim() ?? '');
  if (number == null || number < 0) return message;
  return null;
}
