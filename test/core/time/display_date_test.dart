import 'package:flutter_test/flutter_test.dart';
import 'package:fluxy_app/core/time/display_date.dart';

void main() {
  final now = DateTime(2026, 6, 30, 15, 0);

  test('today → Hoje', () {
    expect(dayLabel(DateTime(2026, 6, 30), now: now), 'Hoje');
  });

  test('yesterday → Ontem', () {
    expect(dayLabel(DateTime(2026, 6, 29), now: now), 'Ontem');
  });

  test('same year → day + short month, no year', () {
    expect(dayLabel(DateTime(2026, 6, 1), now: now), '1 jun');
    expect(dayLabel(DateTime(2026, 1, 15), now: now), '15 jan');
  });

  test('other year → includes the year', () {
    expect(dayLabel(DateTime(2025, 12, 31), now: now), '31 dez 2025');
  });
}
