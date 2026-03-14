import '../config/app_config.dart';

class ApiConstants {
  const ApiConstants._();

  // This should match the laptop IP when the app runs on a real Android phone.
  // Update `AppConfig.localNetworkBaseUrl` or pass `--dart-define=API_BASE_URL=...`
  // before deploying to a physical device.
  static String get baseUrl => AppConfig.apiBaseUrl;
}
