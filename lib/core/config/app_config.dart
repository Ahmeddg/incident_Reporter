class AppConfig {
  // Default to demo mode so the app can run without external systems.
  // Set DEMO_MODE=false at runtime to use real Keycloak/API integrations.
  static const bool demoMode =
      bool.fromEnvironment('DEMO_MODE', defaultValue: true);

  // Use --dart-define to override these per target/device.
  // Android emulator defaults are kept for convenience.
  static const String keycloakDiscoveryUrl = String.fromEnvironment(
    'KEYCLOAK_DISCOVERY_URL',
    defaultValue:
        'http://10.0.2.2:8080/realms/ems-command-center/.well-known/openid-configuration',
  );

  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:8081',
  );

  static const String chatbotBaseUrl = String.fromEnvironment(
    'CHATBOT_BASE_URL',
    defaultValue: 'http://localhost:3000',
  );
}
