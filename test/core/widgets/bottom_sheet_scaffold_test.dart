// test/core/widgets/bottom_sheet_scaffold_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluxy_app/core/widgets/bottom_sheet_scaffold.dart';

void main() {
  testWidgets('shows title and child; opens via showFluxySheet', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Builder(builder: (context) {
          return Center(
            child: ElevatedButton(
              onPressed: () => showFluxySheet(context, title: 'Nova transação', child: const Text('corpo')),
              child: const Text('open'),
            ),
          );
        }),
      ),
    ));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.text('Nova transação'), findsOneWidget);
    expect(find.text('corpo'), findsOneWidget);
  });

  testWidgets('a tall child scrolls instead of overflowing', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: BottomSheetScaffold(
          title: 'Lista longa',
          child: Column(
            children: List.generate(60, (i) => SizedBox(height: 40, child: Text('linha $i'))),
          ),
        ),
      ),
    ));
    await tester.pumpAndSettle();
    // No RenderFlex overflow exception, and the scroll view is present.
    expect(tester.takeException(), isNull);
    expect(find.byType(SingleChildScrollView), findsOneWidget);
    expect(find.text('linha 0'), findsOneWidget);
    // The last row is off-screen but reachable by scrolling.
    await tester.scrollUntilVisible(find.text('linha 59'), 200);
    expect(find.text('linha 59'), findsOneWidget);
  });
}
