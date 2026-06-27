// test/core/widgets/otp_code_input_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluxy_app/core/widgets/otp_code_input.dart';

Widget _host(Widget w) => MaterialApp(home: Scaffold(body: Center(child: w)));

void main() {
  testWidgets('renders 6 boxes and reports the assembled code', (tester) async {
    String code = '';
    String? completed;
    await tester.pumpWidget(_host(OtpCodeInput(
      onChanged: (v) => code = v,
      onCompleted: (v) => completed = v,
    )));
    expect(find.byType(TextField), findsNWidgets(6));

    final fields = find.byType(TextField);
    for (var i = 0; i < 6; i++) {
      await tester.enterText(fields.at(i), '${i + 1}');
      await tester.pump();
    }
    expect(code, '123456');
    expect(completed, '123456');
  });

  testWidgets('onCompleted does not fire until every box is filled', (tester) async {
    String code = '';
    var completedCalls = 0;
    await tester.pumpWidget(_host(OtpCodeInput(
      onChanged: (v) => code = v,
      onCompleted: (_) => completedCalls++,
    )));
    final fields = find.byType(TextField);
    for (var i = 0; i < 5; i++) {
      await tester.enterText(fields.at(i), '${i + 1}');
      await tester.pump();
    }
    expect(code, '12345');
    expect(completedCalls, 0);

    await tester.enterText(fields.at(5), '6');
    await tester.pump();
    expect(code, '123456');
    expect(completedCalls, 1);
  });

  testWidgets('pasting the full code into one box distributes the digits', (tester) async {
    String code = '';
    String? completed;
    await tester.pumpWidget(_host(OtpCodeInput(
      onChanged: (v) => code = v,
      onCompleted: (v) => completed = v,
    )));
    await tester.enterText(find.byType(TextField).first, '123456');
    await tester.pump();
    expect(code, '123456');
    expect(completed, '123456');
    for (final d in ['1', '2', '3', '4', '5', '6']) {
      expect(find.text(d), findsOneWidget);
    }
  });

  testWidgets('clearing a box shrinks the assembled code (backspace path)', (tester) async {
    String code = '';
    await tester.pumpWidget(_host(OtpCodeInput(onChanged: (v) => code = v)));
    final fields = find.byType(TextField);
    for (var i = 0; i < 6; i++) {
      await tester.enterText(fields.at(i), '${i + 1}');
      await tester.pump();
    }
    expect(code, '123456');

    await tester.enterText(fields.at(5), '');
    await tester.pump();
    expect(code, '12345');
  });
}
