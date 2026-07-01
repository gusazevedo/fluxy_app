// test/app/transactions_routing_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluxy_app/app/router.dart';
import 'package:fluxy_app/core/session/session_status.dart';
import 'package:fluxy_app/features/categories/data/categories_repository.dart';
import 'package:fluxy_app/features/categories/domain/category.dart';
import 'package:fluxy_app/features/transactions/data/transactions_repository.dart';
import 'package:fluxy_app/features/transactions/domain/transactions_page.dart';
import 'package:fluxy_app/features/transactions/presentation/screens/transactions_screen.dart';
import 'package:mocktail/mocktail.dart';

class _MockTxRepo extends Mock implements TransactionsRepository {}

class _MockCatRepo extends Mock implements CategoriesRepository {}

void main() {
  testWidgets('authenticated /transactions renders the real TransactionsScreen',
      (tester) async {
    final tx = _MockTxRepo();
    final cat = _MockCatRepo();
    when(() => tx.list(kind: null, categoryId: null, from: null, to: null))
        .thenAnswer(
            (_) async => const TransactionsPage(items: [], nextCursor: null));
    when(() => cat.list(includeArchived: true))
        .thenAnswer((_) async => const <Category>[]);

    final c = ProviderContainer(overrides: [
      sessionStatusProvider.overrideWith((ref) => SessionStatus.authenticated),
      transactionsRepositoryProvider.overrideWithValue(tx),
      categoriesRepositoryProvider.overrideWithValue(cat),
    ]);
    addTearDown(c.dispose);
    final router = c.read(routerProvider);

    await tester.pumpWidget(UncontrolledProviderScope(
      container: c,
      child: MaterialApp.router(routerConfig: router),
    ));
    await tester.pumpAndSettle();

    router.go('/transactions');
    await tester.pumpAndSettle();

    expect(find.byType(TransactionsScreen), findsOneWidget);
  });
}
