// test/core/widgets/segmented_toggle_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluxy_app/core/widgets/segmented_toggle.dart';

void main() {
  testWidgets('renders all segments and reports taps by index', (tester) async {
    int? tapped;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SegmentedToggle(
          segments: const ['Despesa', 'Receita'],
          selectedIndex: 0,
          onChanged: (i) => tapped = i,
        ),
      ),
    ));

    expect(find.text('Despesa'), findsOneWidget);
    expect(find.text('Receita'), findsOneWidget);

    await tester.tap(find.text('Receita'));
    expect(tapped, 1);
  });
}
