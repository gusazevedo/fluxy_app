// test/core/widgets/async_views_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluxy_app/core/widgets/async_views.dart';
import 'package:fluxy_app/core/widgets/primary_button.dart';

Widget _host(Widget w) => MaterialApp(home: Scaffold(body: w));

void main() {
  testWidgets('AppLoader shows a spinner', (tester) async {
    await tester.pumpWidget(_host(const AppLoader()));
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('AppEmptyView shows the message', (tester) async {
    await tester.pumpWidget(_host(const AppEmptyView(message: 'Nenhuma transação')));
    expect(find.text('Nenhuma transação'), findsOneWidget);
  });

  testWidgets('AppErrorView shows message and retry fires', (tester) async {
    var retried = 0;
    await tester.pumpWidget(_host(AppErrorView(message: 'Algo deu errado', onRetry: () => retried++)));
    expect(find.text('Algo deu errado'), findsOneWidget);
    expect(find.byType(PrimaryButton), findsOneWidget);
    await tester.tap(find.text('Tentar novamente'));
    expect(retried, 1);
  });
}
