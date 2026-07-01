import 'package:flutter_test/flutter_test.dart';
import 'package:fluxy_app/features/transactions/presentation/transaction_validators.dart';
import 'package:fluxy_app/features/transactions/presentation/transactions_strings.dart';

void main() {
  group('parseAmountToCents', () {
    test('plain integer → cents', () {
      expect(parseAmountToCents('12'), 1200);
    });
    test('pt-BR decimal comma', () {
      expect(parseAmountToCents('12,34'), 1234);
      expect(parseAmountToCents('0,5'), 50);
    });
    test('thousands dot + decimal comma', () {
      expect(parseAmountToCents('1.234,56'), 123456);
    });
    test('currency symbol and spaces are ignored', () {
      expect(parseAmountToCents(r'R$ 9,99'), 999);
    });
    test('empty / junk → null', () {
      expect(parseAmountToCents(''), isNull);
      expect(parseAmountToCents('abc'), isNull);
    });
  });

  test('centsToInput round-trips through parseAmountToCents', () {
    expect(centsToInput(1234), '12,34');
    expect(parseAmountToCents(centsToInput(1234)), 1234);
  });

  group('amountError', () {
    test('empty → required', () {
      expect(amountError(''), TransactionsStrings.amountRequired);
    });
    test('zero / negative → invalid', () {
      expect(amountError('0'), TransactionsStrings.amountInvalid);
      expect(amountError('0,00'), TransactionsStrings.amountInvalid);
    });
    test('positive → null', () {
      expect(amountError('12,34'), isNull);
    });
  });

  group('categoryError', () {
    test('null / empty → required', () {
      expect(categoryError(null), TransactionsStrings.categoryRequired);
      expect(categoryError(''), TransactionsStrings.categoryRequired);
    });
    test('set → null', () {
      expect(categoryError('c1'), isNull);
    });
  });

  group('descriptionError', () {
    test('over 280 chars → too long', () {
      expect(descriptionError('a' * 281), TransactionsStrings.descriptionTooLong);
    });
    test('within limit → null', () {
      expect(descriptionError('a' * 280), isNull);
      expect(descriptionError(''), isNull);
    });
  });
}
