// test/core/widgets/primary_button_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluxy_app/core/theme/tokens.dart';
import 'package:fluxy_app/core/widgets/primary_button.dart';

Widget _host(Widget w) => MaterialApp(home: Scaffold(body: Center(child: w)));

void main() {
  testWidgets('tap fires onPressed', (tester) async {
    var taps = 0;
    await tester.pumpWidget(_host(PrimaryButton(label: 'Entrar', onPressed: () => taps++)));
    await tester.tap(find.text('Entrar'));
    expect(taps, 1);
  });

  testWidgets('disabled (onPressed null) does not fire and drops the 3D shadow', (tester) async {
    await tester.pumpWidget(_host(const PrimaryButton(label: 'Entrar', onPressed: null)));
    await tester.tap(find.text('Entrar'), warnIfMissed: false);
    // resting shadow uses primaryPressed; disabled removes it
    final deco = tester.widget<AnimatedContainer>(find.byType(AnimatedContainer)).decoration as BoxDecoration;
    expect(deco.boxShadow == null || deco.boxShadow!.isEmpty, true);
  });

  testWidgets('loading shows a spinner and blocks taps', (tester) async {
    var taps = 0;
    await tester.pumpWidget(_host(PrimaryButton(label: 'Entrar', loading: true, onPressed: () => taps++)));
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Entrar'), findsNothing);
    await tester.tap(find.byType(PrimaryButton), warnIfMissed: false);
    expect(taps, 0);
  });

  testWidgets('enabled button carries the green fill and offset shadow', (tester) async {
    await tester.pumpWidget(_host(PrimaryButton(label: 'Entrar', onPressed: () {})));
    final deco = tester.widget<AnimatedContainer>(find.byType(AnimatedContainer)).decoration as BoxDecoration;
    expect(deco.color, AppColors.primary);
    expect(deco.boxShadow!.first.color, AppColors.primaryPressed);
    expect(deco.boxShadow!.first.offset, const Offset(0, 4));
    expect(deco.boxShadow!.first.blurRadius, 0);
  });
}
