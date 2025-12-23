class AppConfig {
  // cliente atual (pode vir de --dart-define)
  static const String clientKey = String.fromEnvironment('CLIENT', defaultValue: 'fratheli');

  static const String apiBase = String.fromEnvironment(
    'API_BASE',
    defaultValue: 'https://frathelicafe.com.br',
  );

  // endpoints
  static String get freightQuote => '$apiBase/cotacao_frete.php';
  static String get checkout => '$apiBase/checkout.php';
  static String get catalog => '$apiBase/catalog.json';

  // outros itens que variam por cliente
  static const String whatsappPhone = String.fromEnvironment(
    'WHATSAPP_PHONE',
    defaultValue: '5527999999999',
  );
}
