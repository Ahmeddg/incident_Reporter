import 'package:flutter/foundation.dart';

class AppConfig {
  // Default to real integrations. Set DEMO_MODE=true to run without
  // external Keycloak/API services.

  // Use --dart-define to override these per target/device.
  static const String _keycloakDiscoveryUrlFromEnv = String.fromEnvironment(
    'KEYCLOAK_DISCOVERY_URL',
    defaultValue: '',
  );

  static const String keycloakClientId = String.fromEnvironment(
    'KEYCLOAK_CLIENT_ID',
    defaultValue: 'emscommandcenter',
  );

  static const String _keycloakRedirectUriFromEnv = String.fromEnvironment(
    'KEYCLOAK_REDIRECT_URI',
    defaultValue: '',
  );

  static const String _apiBaseUrlFromEnv = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: '',
  );

  static const String _websocketUrlFromEnv = String.fromEnvironment(
    'WEBSOCKET_URL',
    defaultValue: '',
  );

  static const String _chatbotBaseUrlFromEnv = String.fromEnvironment(
    'CHATBOT_BASE_URL',
    defaultValue: '',
  );

  static String get keycloakDiscoveryUrl => _resolveUrl(
      _keycloakDiscoveryUrlFromEnv,
      'http://$_hostForWebDefaults:18080/auth/realms/camunda-platform/.well-known/openid-configuration');

  static String get keycloakRedirectUri {
    if (_keycloakRedirectUriFromEnv.trim().isNotEmpty) {
      return _keycloakRedirectUriFromEnv;
    }
    if (kIsWeb) {
      return Uri.base.resolve('/').toString();
    }
    return 'http://localhost:5000/';
  }

  static String get apiBaseUrl =>
      _resolveUrl(_apiBaseUrlFromEnv, 'http://$_hostForWebDefaults:8081');

  static String get websocketUrl => _resolveUrl(
      _websocketUrlFromEnv, 'ws://$_hostForWebDefaults:8081/ws-native');

  static String get chatbotBaseUrl =>
      _resolveUrl(_chatbotBaseUrlFromEnv, 'http://$_hostForWebDefaults:3000');

  static String get _hostForWebDefaults {
    if (!kIsWeb) {
      return 'localhost';
    }

    final String host = Uri.base.host;
    if (host.isEmpty) {
      return 'localhost';
    }
    return host;
  }

  static String _resolveUrl(String valueFromEnv, String fallbackValue) {
    if (valueFromEnv.trim().isNotEmpty) {
      return valueFromEnv;
    }
    return fallbackValue;
  }
}
