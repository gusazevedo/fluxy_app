// test/core/widgets/category_icon_chip_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluxy_app/core/theme/tokens.dart';
import 'package:fluxy_app/core/widgets/category_icon_chip.dart';

void main() {
  testWidgets('expense chip uses the expense color; income uses primary',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: Column(children: [
          CategoryIconChip(isExpense: true),
          CategoryIconChip(isExpense: false),
        ]),
      ),
    ));

    final icons = tester.widgetList<Icon>(find.byType(Icon)).toList();
    expect(icons[0].color, AppColors.expense);
    expect(icons[1].color, AppColors.primary);
  });
}
