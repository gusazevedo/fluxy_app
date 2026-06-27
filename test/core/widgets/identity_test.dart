// test/core/widgets/identity_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluxy_app/core/theme/tokens.dart';
import 'package:fluxy_app/core/widgets/identity.dart';

Widget _host(Widget w) => MaterialApp(home: Scaffold(body: Center(child: w)));

void main() {
  testWidgets('AppBackButton taps', (tester) async {
    var taps = 0;
    await tester.pumpWidget(_host(AppBackButton(onPressed: () => taps++)));
    await tester.tap(find.byType(AppBackButton));
    expect(taps, 1);
  });

  testWidgets('Avatar shows uppercased initials', (tester) async {
    await tester.pumpWidget(_host(const Avatar(firstName: 'Marina', lastName: 'Costa')));
    expect(find.text('MC'), findsOneWidget);
  });

  testWidgets('Avatar handles empty/whitespace names without crashing', (tester) async {
    // Single name -> one initial.
    await tester.pumpWidget(_host(const Avatar(firstName: 'Marina', lastName: '')));
    expect(find.text('M'), findsOneWidget);

    await tester.pumpWidget(_host(const Avatar(firstName: '', lastName: 'Costa')));
    expect(find.text('C'), findsOneWidget);

    // Whitespace-only -> treated as empty, renders a blank (no exception).
    await tester.pumpWidget(_host(const Avatar(firstName: '  ', lastName: '  ')));
    expect(find.text(''), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('FluxyLogo renders the primary dot on a surface tile', (tester) async {
    await tester.pumpWidget(_host(const FluxyLogo()));
    expect(find.byType(FluxyLogo), findsOneWidget);
    // The centered dot is a circular Container filled with the primary color.
    final dot = tester.widgetList<Container>(find.byType(Container)).firstWhere(
          (c) => c.decoration is BoxDecoration &&
              (c.decoration as BoxDecoration).color == AppColors.primary &&
              (c.decoration as BoxDecoration).shape == BoxShape.circle,
        );
    expect(dot, isNotNull);
  });
}
