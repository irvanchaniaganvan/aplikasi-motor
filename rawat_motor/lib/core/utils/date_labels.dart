const _shortMonthNames = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'Mei',
  'Jun',
  'Jul',
  'Agu',
  'Sep',
  'Okt',
  'Nov',
  'Des',
];

String shortMonthName(int month) => _shortMonthNames[month - 1];

String formatShortDate(DateTime date) =>
    '${date.day} ${shortMonthName(date.month)} ${date.year}';
