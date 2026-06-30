// test/app/categories_routing_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluxy_app/app/router.dart';
import 'package:fluxy_app/core/session/session_status.dart';
import 'package:fluxy_app/features/categories/data/categories_repository.dart';
import 'package:fluxy_app/features/categories/domain/category.dart';
import 'package:fluxy_app/features/categories/presentation/screens/categories_screen.dart';
import 'package:mocktail/mocktail.dart';

class _MockRepo extends Mock implements CategoriesRepository {}

void main() {
  testWidgets('authenticated /categories renders the real CategoriesScreen',
      (tester) async {
    final repo = _MockRepo();
    when(() => repo.list(kind: CategoryKind.expense, includeArchived: false))
        .thenAnswer((_) async => const <Category>[]);

    final c = ProviderContainer(overrides: [
      sessionStatusProvider.overrideWith((ref) => SessionStatus.authenticated),
      categoriesRepositoryProvider.overrideWithValue(repo),
    ]);
    addTearDown(c.dispose);
    final router = c.read(routerProvider);

    await tester.pumpWidget(UncontrolledProviderScope(
      container: c,
      child: MaterialApp.router(routerConfig: router),
    ));
    await tester.pumpAndSettle();

    router.go('/categories');
    await tester.pumpAndSettle();

    expect(find.byType(CategoriesScreen), findsOneWidget);
  });
}
