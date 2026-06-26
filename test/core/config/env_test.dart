import 'package:flutter_test/flutter_test.dart';
import 'package:fluxy_app/core/config/env.dart';

void main() {
  test('AppConfig exposes BRL/pt_BR defaults and the AWS base URL', () {
    expect(AppConfig.currencyCode, 'BRL');
    expect(AppConfig.locale, 'pt_BR');
    expect(AppConfig.baseUrl,
        'https://3rgdjd69sa.execute-api.us-east-1.amazonaws.com');
  });
}
