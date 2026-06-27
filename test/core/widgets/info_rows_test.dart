// test/core/widgets/info_rows_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluxy_app/core/theme/tokens.dart';
import 'package:fluxy_app/core/widgets/info_rows.dart';

Widget _host(Widget w) => MaterialApp(home: Scaffold(body: Center(child: w)));

void main() {
  testWidgets('HelperText shows icon + text', (tester) async {
    await tester.pumpWidget(_host(const HelperText(text: 'Não é possível selecionar datas futuras.')));
    expect(find.text('Não é possível selecionar datas futuras.'), findsOneWidget);
    expect(find.byType(Icon), findsOneWidget);
  });

  testWidgets('RequirementRow shows a primary check when satisfied', (tester) async {
    await tester.pumpWidget(_host(const RequirementRow(text: 'Mínimo de 8 caracteres', satisfied: true)));
    final icon = tester.widget<Icon>(find.byType(Icon));
    expect(icon.color, AppColors.onPrimary); // check glyph sits on the primary circle
    expect(find.text('Mínimo de 8 caracteres'), findsOneWidget);
  });
}
