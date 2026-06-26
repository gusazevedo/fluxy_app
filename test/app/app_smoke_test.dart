// test/app/app_smoke_test.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluxy_app/app/app.dart';

void main() {
  testWidgets('FluxyApp boots into the login placeholder (unauthenticated)', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: FluxyApp()));
    await tester.pumpAndSettle();
    expect(find.text('Login (spec 02)'), findsOneWidget);
  });
}
