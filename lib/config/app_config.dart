class AppConfig {
  static const String clientKey = String.fromEnvironment(
    'CLIENT',
    defaultValue: 'fratheli',
  );

  static const String webBase = String.fromEnvironment(
    'WEB_BASE',
    defaultValue: 'https://frathelicafe.com.br',
  );

  static const String apiBase = String.fromEnvironment(
    'API_BASE',
    defaultValue: 'https://frathelicafe.com.br/api',
  );

  static String get freightQuote => '$webBase/cotacao_frete.php';
  static String get paymentPage => '$webBase/pagamento_order.html';
  static String paymentUrl(String orderCode) => '$paymentPage?orderId=$orderCode';

  static String get login => '$apiBase/auth/login.php';
  static String get register => '$apiBase/auth/register.php';
  static String get accountMe => '$apiBase/account/me.php';
  static String get profileGet => '$apiBase/account/profile_get.php';
  static String get profileUpsert => '$apiBase/account/profile_upsert.php';
  static String get changePassword => '$apiBase/account/change_password.php';
  static String get updateUser => '$apiBase/account/update_user.php';
  static String get orderCreate => '$apiBase/orders/create.php';
  static String get orderCreateExternal => '$apiBase/orders/create_external.php';
  static String get orderGet => '$apiBase/orders/get.php';
  static String get orderList => '$apiBase/orders/list.php';

  static const String productBase = String.fromEnvironment(
    'PRODUCT_BASE',
    defaultValue: 'https://smapps.16mb.com/fratheli/app/products',
  );

  static String get catalog => '$productBase/get_products.php';
  static String get pricings => 'https://smapps.16mb.com/fratheli/app/pricings_data.php';

  static const String whatsappPhone = String.fromEnvironment(
    'WHATSAPP_PHONE',
    defaultValue: '5527999999999',
  );
}
