// lib/core/money/money.dart
import 'package:intl/intl.dart';
import '../config/env.dart';

class Money {
  final int cents;
  const Money(this.cents);

  factory Money.fromMajor(num major) => Money((major * 100).round());

  double get major => cents / 100;
  bool get isNegative => cents < 0;

  static final NumberFormat _fmt = NumberFormat.currency(
    locale: AppConfig.locale,
    symbol: r'R$',
    decimalDigits: 2,
  );

  /// Absolute, symbol-prefixed: `R$ 3.240,00`.
  /// Normalizes any non-breaking space (U+00A0) to a regular ASCII space.
  String format() => _fmt.format(major.abs()).replaceAll(' ', ' ');

  /// `+R$ 5.100,00` (income) or `-R$ 1.200,00` (expense).
  String formatSigned(bool isExpense) => '${isExpense ? '-' : '+'}${format()}';

  @override
  bool operator ==(Object other) => other is Money && other.cents == cents;
  @override
  int get hashCode => cents.hashCode;
}
