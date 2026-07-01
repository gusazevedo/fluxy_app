// lib/core/time/display_date.dart
//
// Human-readable day labels for grouping (pt-BR). A small month table avoids
// pulling in intl date-symbol initialization for a non-default locale.

const List<String> _monthsShort = [
  'jan', 'fev', 'mar', 'abr', 'mai', 'jun',
  'jul', 'ago', 'set', 'out', 'nov', 'dez',
];

DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

/// A section header label for [date]: `Hoje`, `Ontem`, `30 jun`, or
/// `30 jun 2025` when the year differs from [now] (defaults to today).
String dayLabel(DateTime date, {DateTime? now}) {
  final today = _dateOnly(now ?? DateTime.now());
  final day = _dateOnly(date);
  final diff = today.difference(day).inDays;
  if (diff == 0) return 'Hoje';
  if (diff == 1) return 'Ontem';
  final base = '${day.day} ${_monthsShort[day.month - 1]}';
  return day.year == today.year ? base : '$base ${day.year}';
}
