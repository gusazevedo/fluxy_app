// test/app/auth_routing_test.dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:fluxy_app/app/router.dart';
import 'package:fluxy_app/core/session/session_status.dart';
import 'package:fluxy_app/core/storage/token_storage.dart';
import 'package:fluxy_app/features/auth/data/auth_repository.dart';
import 'package:fluxy_app/features/auth/domain/auth_user.dart';
import 'package:fluxy_app/features/auth/presentation/auth_controller.dart';
import 'package:mocktail/mocktail.dart';

class _MockRepo extends Mock implements AuthRepository {}

class _FakeStorage implements TokenStorage {
  String? access;
  String? refresh;
  @override
  Future<void> save({required String access, required String refresh}) async {}
  @override
  Future<String?> readAccess() async => access;
  @override
  Future<String?> readRefresh() async => refresh;
  @override
  Future<void> clear() async {
    access = null;
    refresh = null;
  }
}

AuthUser _user({bool verified = true}) => AuthUser(
      id: 'u1', email: 'a@b.co', firstName: 'M', lastName: 'C',
      emailVerified: verified, createdAt: DateTime.utc(2026, 1, 1),
    );

// Mirror the main.dart composition: derive sessionStatus from the real controller.
List<Override> _overrides(_MockRepo repo, _FakeStorage storage) => [
      authRepositoryProvider.overrideWithValue(repo),
      tokenStorageProvider.overrideWithValue(storage),
      sessionStatusProvider.overrideWith(
          (ref) => sessionStatusFromAuth(ref.watch(authControllerProvider))),
    ];

Future<String> _bootAndPath(WidgetTester tester, ProviderContainer c) async {
  final router = c.read(routerProvider);
  await tester.pumpWidget(UncontrolledProviderScope(
    container: c,
    child: MaterialApp.router(routerConfig: router),
  ));
  await tester.pumpAndSettle();
  return router.routerDelegate.currentConfiguration.uri.path;
}

void main() {
  testWidgets('no token → boots through splash to /login', (tester) async {
    final repo = _MockRepo();
    final c = ProviderContainer(overrides: _overrides(repo, _FakeStorage()));
    addTearDown(c.dispose);
    expect(await _bootAndPath(tester, c), '/login');
  });

  testWidgets('valid token + verified user → shell at /', (tester) async {
    final repo = _MockRepo();
    when(() => repo.me()).thenAnswer((_) async => _user());
    final c = ProviderContainer(
        overrides: _overrides(repo, _FakeStorage()..access = 'acc'));
    addTearDown(c.dispose);
    expect(await _bootAndPath(tester, c), '/');
  });

  testWidgets('valid token + unverified user → /verify-email', (tester) async {
    final repo = _MockRepo();
    when(() => repo.me()).thenAnswer((_) async => _user(verified: false));
    final c = ProviderContainer(
        overrides: _overrides(repo, _FakeStorage()..access = 'acc'));
    addTearDown(c.dispose);
    expect(await _bootAndPath(tester, c), '/verify-email');
  });

  testWidgets('shows the splash while auth state is unknown (bootstrap pending)',
      (tester) async {
    final repo = _MockRepo();
    final pending = Completer<AuthUser>(); // me() never completes → stays unknown
    when(() => repo.me()).thenAnswer((_) => pending.future);
    final c = ProviderContainer(
        overrides: _overrides(repo, _FakeStorage()..access = 'acc'));
    addTearDown(c.dispose);
    final router = c.read(routerProvider);
    await tester.pumpWidget(UncontrolledProviderScope(
      container: c,
      child: MaterialApp.router(routerConfig: router),
    ));
    await tester.pump(); // redirect runs; bootstrap still in-flight

    expect(find.byType(SplashScreen), findsOneWidget);
    expect(router.routerDelegate.currentConfiguration.uri.path, '/splash');
  });
}
