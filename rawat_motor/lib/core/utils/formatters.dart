String formatKm(int value) {
  final digits = value.toString();
  final groups = <String>[];
  for (var end = digits.length; end > 0; end -= 3) {
    final start = end - 3 < 0 ? 0 : end - 3;
    groups.insert(0, digits.substring(start, end));
  }
  return '${groups.join('.')} km';
}

String? requiredNumber(String? value, String message) {
  final number = int.tryParse(value?.trim() ?? '');
  if (number == null || number < 0) return message;
  return null;
}
