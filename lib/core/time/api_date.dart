String _twoDigits(int n) => n.toString().padLeft(2, '0');

String apiDateToString(DateTime d) => '${d.year}-${_twoDigits(d.month)}-${_twoDigits(d.day)}';

DateTime parseApiDate(String s) {
  final p = s.split('-').map(int.parse).toList();
  return DateTime(p[0], p[1], p[2]);
}

bool isFuture(DateTime d) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final day = DateTime(d.year, d.month, d.day);
  return day.isAfter(today);
}
