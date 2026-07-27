class ApiConfig {
  // Base URL
  static const String baseUrl = 'https://majacraft.id';

  // API Endpoints
  static const String login = '/api/auth/mobile/login';
  static const String register = '/api/auth/mobile/register';
  static const String googleAuth = '/api/auth/mobile/google';
  static const String profile = '/api/users/me';
  static const String changePassword = '/api/users/change-password';
  static const String products = '/api/products';
  static const String cart = '/api/cart';
  static const String orders = '/api/orders';
  static const String notifications = '/api/notifications';
  static String notificationRead(String id) => '/api/notifications/$id';

  // Google OAuth
  static const String googleWebClientId =
      '1089490083968-mpv497utnj95294vtjid83j8g83i0ooe.apps.googleusercontent.com';

  // Storage keys
  static const String tokenKey = 'auth_token';
  static const String userKey = 'user_data';
}
