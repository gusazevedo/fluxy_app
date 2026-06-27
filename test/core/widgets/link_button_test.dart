import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluxy_app/core/theme/tokens.dart';
import 'package:fluxy_app/core/widgets/link_button.dart';

Widget _host(Widget w) => MaterialApp(home: Scaffold(body: Center(child: w)));

void main() {
  testWidgets('LinkButton renders primary-colored label and taps', (tester) async {
    var taps = 0;
    await tester.pumpWidget(_host(LinkButton(label: 'Esqueci minha senha', onPressed: () => taps++)));
    final txt = tester.widget<Text>(find.text('Esqueci minha senha'));
    expect(txt.style!.color, AppColors.primary);
    await tester.tap(find.text('Esqueci minha senha'));
    expect(taps, 1);
  });

  testWidgets('InlineLink shows leading + action; only the action taps', (tester) async {
    var taps = 0;
    await tester.pumpWidget(_host(InlineLink(leading: 'Não tem conta?', action: 'Cadastre-se', onPressed: () => taps++)));
    expect(find.textContaining('Não tem conta?'), findsOneWidget);

    final action = tester.widget<Text>(find.text('Cadastre-se'));
    expect(action.style!.color, AppColors.textPrimary);

    await tester.tap(find.textContaining('Não tem conta?'));
    expect(taps, 0);
    await tester.tap(find.text('Cadastre-se'));
    expect(taps, 1);
  });
}
