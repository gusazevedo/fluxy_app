// test/core/widgets/app_text_field_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluxy_app/core/theme/tokens.dart';
import 'package:fluxy_app/core/widgets/app_text_field.dart';

Widget _host(Widget w) => MaterialApp(home: Scaffold(body: Center(child: w)));

BoxDecoration _boxOf(WidgetTester t) =>
    t.widget<Container>(find.descendant(of: find.byType(AppTextField), matching: find.byType(Container)).first).decoration as BoxDecoration;

void main() {
  testWidgets('renders label and accepts input', (tester) async {
    final c = TextEditingController();
    await tester.pumpWidget(_host(AppTextField(label: 'Email', controller: c)));
    expect(find.text('Email'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'a@b.co');
    expect(c.text, 'a@b.co');
  });

  testWidgets('error state shows message and expense-colored border', (tester) async {
    await tester.pumpWidget(_host(const AppTextField(label: 'Email', errorText: 'E-mail inválido')));
    expect(find.text('E-mail inválido'), findsOneWidget);
    expect((_boxOf(tester).border as Border).top.color, AppColors.expense);
  });

  testWidgets('PasswordField obscures and toggles visibility', (tester) async {
    await tester.pumpWidget(_host(const PasswordField(label: 'Senha')));
    expect(tester.widget<TextField>(find.byType(TextField)).obscureText, true);
    await tester.tap(find.byIcon(Icons.visibility_outlined));
    await tester.pump();
    expect(tester.widget<TextField>(find.byType(TextField)).obscureText, false);
  });
}
