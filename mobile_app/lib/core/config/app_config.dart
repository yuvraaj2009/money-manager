enum ApiEnvironment {
  localhost,
  androidEmulator,
  localNetwork,
  production,
}

class AppConfig {
  const AppConfig._();

  static const String localhostBaseUrl = 'http://localhost:8000';
  static const String androidEmulatorBaseUrl = 'http://10.0.2.2:8000';

  // For a real Android phone, this must match the laptop IPv4 address that
  // is running FastAPI on the same Wi-Fi or LAN as the phone.
  static const String localNetworkBaseUrl = 'http://192.168.0.101:8000';

  static const String productionBaseUrl = 'https://api.example.com';

  static const String _environmentName = String.fromEnvironment(
    'API_ENV',
    defaultValue: 'localNetwork',
  );

  static const String _baseUrlOverride = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: '',
  );

  static ApiEnvironment get apiEnvironment {
    switch (_environmentName) {
      case 'localhost':
        return ApiEnvironment.localhost;
      case 'androidEmulator':
        return ApiEnvironment.androidEmulator;
      case 'production':
        return ApiEnvironment.production;
      case 'localNetwork':
      default:
        return ApiEnvironment.localNetwork;
    }
  }

  static String get apiBaseUrl {
    if (_baseUrlOverride.isNotEmpty) {
      return _baseUrlOverride;
    }

    switch (apiEnvironment) {
      case ApiEnvironment.localhost:
        return localhostBaseUrl;
      case ApiEnvironment.androidEmulator:
        return androidEmulatorBaseUrl;
      case ApiEnvironment.production:
        return productionBaseUrl;
      case ApiEnvironment.localNetwork:
        return localNetworkBaseUrl;
    }
  }
}
