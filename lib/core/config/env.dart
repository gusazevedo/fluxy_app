class AppConfig {
  static const String baseUrl = String.fromEnvironment(
    'FLUXY_BASE_URL',
    defaultValue: 'https://3rgdjd69sa.execute-api.us-east-1.amazonaws.com',
  );
  static const String currencyCode =
      String.fromEnvironment('FLUXY_CURRENCY', defaultValue: 'BRL');
  static const String locale =
      String.fromEnvironment('FLUXY_LOCALE', defaultValue: 'pt_BR');
}
