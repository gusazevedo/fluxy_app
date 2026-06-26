// test/core/time/api_date_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:fluxy_app/core/time/api_date.dart';

void main() {
  test('formats to YYYY-MM-DD zero-padded', () {
    expect(apiDateToString(DateTime(2026, 6, 5)), '2026-06-05');
  });
  test('parses YYYY-MM-DD', () {
    final d = parseApiDate('2026-06-21');
    expect([d.year, d.month, d.day], [2026, 6, 21]);
  });
  test('isFuture true only after today', () {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    expect(isFuture(tomorrow), true);
    expect(isFuture(DateTime.now()), false);
  });
}
