import 'transaction.dart';

/// One page of the keyset-paginated `GET /transactions` response.
///
/// [nextCursor] is `null` when there are no more results; otherwise it is the
/// opaque cursor to resend as `?cursor=` for the following page.
class TransactionsPage {
  const TransactionsPage({required this.items, required this.nextCursor});

  final List<Transaction> items;
  final String? nextCursor;
}
