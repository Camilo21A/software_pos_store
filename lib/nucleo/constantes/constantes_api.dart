class ConstantesApi {
  static const String baseUrl = 'http://10.0.2.2:8000/api';
// 10.0.2.2 = localhost de tu PC visto desde el emulador Android

  static const String loginUrl     = '$baseUrl/auth/login/';
  static const String logoutUrl    = '$baseUrl/auth/logout/';
  static const String tiendasUrl   = '$baseUrl/auth/tiendas/';         // ← nuevo
  static String toggleTiendaUrl(int id) => '$baseUrl/auth/tiendas/$id/toggle/'; // ← nuevo
}
