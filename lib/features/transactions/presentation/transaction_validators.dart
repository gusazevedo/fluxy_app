// lib/features/transactions/presentation/transaction_validators.dart
import 'transactions_strings.dart';

/// Parses a user-typed amount into positive cents, or `null` if unparseable.
/// Accepts pt-BR style input: `1.234,56` → 123456, `12,5` → 1250, `12` → 1200.
int? parseAmountToCents(String raw) {
  var s = raw.trim();
  if (s.isEmpty) return null;
  s = s.replaceAll(RegExp(r'[^\d,.]'), '');
  if (s.isEmpty) return null;
  // With a comma present, treat '.' as thousands and ',' as the decimal mark.
  if (s.contains(',')) {
    s = s.replaceAll('.', '').replaceAll(',', '.');
  }
  final value = double.tryParse(s);
  if (value == null) return null;
  return (value * 100).round();
}

/// Formats stored cents back into an editable pt-BR string (`1234` → `12,34`).
String centsToInput(int cents) =>
    (cents / 100).toStringAsFixed(2).replaceAll('.', ',');

String? amountError(String raw) {
  if (raw.trim().isEmpty) return TransactionsStrings.amountRequired;
  final cents = parseAmountToCents(raw);
  if (cents == null) return TransactionsStrings.amountInvalid;
  if (cents <= 0) return TransactionsStrings.amountInvalid;
  return null;
}

String? categoryError(String? categoryId) =>
    (categoryId == null || categoryId.isEmpty)
        ? TransactionsStrings.categoryRequired
        : null;

String? descriptionError(String raw) =>
    raw.trim().length > 280 ? TransactionsStrings.descriptionTooLong : null;
