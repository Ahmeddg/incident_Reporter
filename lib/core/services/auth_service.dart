import 'package:flutter/foundation.dart';
import 'package:flutter_appauth/flutter_appauth.dart';
import 'package:incident_reporter/core/config/app_config.dart';
import 'package:incident_reporter/core/services/secure_storage_service.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final FlutterAppAuth _appAuth = const FlutterAppAuth();
  final SecureStorageService _storage = SecureStorageService();

  // Configuration
  // Note: For Android emulators, use 10.0.2.2 instead of localhost
  final String _clientId = 'emscommandcenter';
  final String _redirectUri = 'http://localhost:8080/auth.html';
  final String _discoveryUrl = AppConfig.keycloakDiscoveryUrl;

  final ValueNotifier<bool> isAuthenticated = ValueNotifier<bool>(false);

  Future<void> init() async {
    final token = await _storage.getAccessToken();
    isAuthenticated.value = token != null;
  }

  Future<bool> login() async {
    if (AppConfig.demoMode) {
      await _storage.saveTokens(
        accessToken: 'demo-access-token',
        refreshToken: 'demo-refresh-token',
        idToken: 'demo-id-token',
      );
      isAuthenticated.value = true;
      return true;
    }

    try {
      final AuthorizationTokenResponse result =
          await _appAuth.authorizeAndExchangeCode(
        AuthorizationTokenRequest(
          _clientId,
          _redirectUri,
          discoveryUrl: _discoveryUrl,
          scopes: ['openid', 'profile', 'email'],
          allowInsecureConnections: true,
        ),
      );

      if (result.accessToken != null) {
        await _storage.saveTokens(
          accessToken: result.accessToken!,
          refreshToken: result.refreshToken,
          idToken: result.idToken,
        );
        isAuthenticated.value = true;
        return true;
      }
    } catch (e) {
      debugPrint('Login error: $e');
    }
    return false;
  }

  Future<void> logout() async {
    await _storage.clearTokens();
    isAuthenticated.value = false;
  }

  Future<String?> getValidToken() async {
    // Basic implementation: return stored token.
    return await _storage.getAccessToken();
  }
}
