const List<String> idWeekdays = [
  'Senin',
  'Selasa',
  'Rabu',
  'Kamis',
  'Jumat',
  'Sabtu',
  'Minggu',
];

const List<String> idMonths = [
  'Januari',
  'Februari',
  'Maret',
  'April',
  'Mei',
  'Juni',
  'Juli',
  'Agustus',
  'September',
  'Oktober',
  'November',
  'Desember',
];

const List<String> idMonthsShort = [
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

String formatRupiah(int amount) {
  final negative = amount < 0;
  final digits = amount.abs().toString();
  final buffer = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buffer.write('.');
    buffer.write(digits[i]);
  }
  return negative ? '-$buffer' : buffer.toString();
}

String formatRp(int amount) => 'Rp ${formatRupiah(amount)}';

String formatSignedRp(int amount, {required bool isIncome}) {
  final sign = isIncome ? '+ Rp ' : '- Rp ';
  return '$sign${formatRupiah(amount.abs())}';
}

String formatCompactRp(int amount) {
  if (amount >= 1000000) {
    final v = amount / 1000000;
    final text = v == v.roundToDouble() ? v.toInt().toString() : v.toStringAsFixed(2).replaceAll('.', ',').replaceAll(RegExp(r',?0+$'), '');
    return 'Rp $text jt';
  }
  if (amount >= 1000) {
    final v = amount ~/ 1000;
    return 'Rp $v rb';
  }
  return 'Rp $amount';
}

String formatDayLabel(DateTime date, {DateTime? today, bool short = false}) {
  final now = today ?? DateTime.now();
  final dateOnly = DateTime(date.year, date.month, date.day);
  final todayOnly = DateTime(now.year, now.month, now.day);
  final diff = todayOnly.difference(dateOnly).inDays;

  final d = date.day;
  final m = short ? idMonthsShort[date.month - 1] : idMonths[date.month - 1];
  final y = date.year;

  if (diff == 0) return short ? 'Hari ini' : 'Hari ini, $d $m $y';
  if (diff == 1) return short ? 'Kemarin' : 'Kemarin, $d $m $y';
  return short ? '$d $m $y' : '$d $m $y';
}

String formatTime(DateTime date) {
  final h = date.hour.toString().padLeft(2, '0');
  final min = date.minute.toString().padLeft(2, '0');
  return '$h:$min';
}
