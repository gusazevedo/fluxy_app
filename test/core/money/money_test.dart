// test/core/money/money_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:fluxy_app/core/money/money.dart';

void main() {
  test('fromMajor rounds to integer cents', () {
    expect(Money.fromMajor(10.999).cents, 1100); // sub-cent rounds up
    expect(Money.fromMajor(10.991).cents, 1099); // sub-cent rounds down
    expect(Money.fromMajor(3240).cents, 324000);
  });

  test('format renders BRL pt-BR', () {
    expect(Money(324000).format(), 'R\$ 3.240,00');
    expect(Money(34000).format(), 'R\$ 340,00');
  });

  test('format renders absolute value for negative cents', () {
    expect(Money(-324000).format(), 'R\$ 3.240,00');
  });

  test('formatSigned applies + for income and - for expense', () {
    expect(Money(510000).formatSigned(false), '+R\$ 5.100,00');
    expect(Money(120000).formatSigned(true), '-R\$ 1.200,00');
  });

  test('isNegative reflects sign', () {
    expect(Money(-100).isNegative, true);
    expect(Money(100).isNegative, false);
  });
}
