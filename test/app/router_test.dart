// test/app/router_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluxy_app/app/router.dart';
import 'package:fluxy_app/core/session/session_status.dart';

void main() {
  testWidgets('unauthenticated lands on /login', (tester) async {
    final container = ProviderContainer(overrides: [
      sessionStatusProvider.overrideWith((ref) => SessionStatus.unauthenticated),
    ]);
    addTearDown(container.dispose);
    final router = container.read(routerProvider);
    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(routerConfig: router),
    ));
    await tester.pumpAndSettle();
    expect(router.routerDelegate.currentConfiguration.uri.path, '/login');
  });

  testWidgets('authenticated lands on / (Início)', (tester) async {
    final container = ProviderContainer(overrides: [
      sessionStatusProvider.overrideWith((ref) => SessionStatus.authenticated),
    ]);
    addTearDown(container.dispose);
    final router = container.read(routerProvider);
    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(routerConfig: router),
    ));
    await tester.pumpAndSettle();
    expect(router.routerDelegate.currentConfiguration.uri.path, '/');
  });
}
