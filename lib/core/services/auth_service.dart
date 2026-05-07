import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_appauth/flutter_appauth.dart';
import 'package:get/get.dart';
import 'package:incident_reporter/core/config/app_config.dart';
import 'package:incident_reporter/core/services/secure_storage_service.dart';
// Conditional import: web implementation when running in browser.
import 'web_oidc_auth_stub.dart' if (dart.library.html) 'web_oidc_auth_web.dart'
    as web_oidc;
import 'package:http/http.dart' as http;
import 'package:jwt_decoder/jwt_decoder.dart';

class AuthService extends GetxService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  static AuthService get instance => Get.find<AuthService>();

  final FlutterAppAuth _appAuth = const FlutterAppAuth();
  final SecureStorageService _storage = SecureStorageService();
  final RxBool isAuthenticated = false.obs;
  final RxBool isAuthenticating = false.obs;
  final RxString authErrorMessage = ''.obs;
  final RxString userId = ''.obs;

  String? _cachedToken;
  String? get cachedToken => _cachedToken;

  static const List<String> _scopes = [
    'openid',
    'profile',
    'email',
    'offline_access',
  ];

  Future<void> init() async {
    // If running on web and a login redirect returned a code, complete it.
    if (kIsWeb && web_oidc.isWebOidcSupported) {
      try {
        final webResult = await web_oidc.completeWebOidcLogin(
          clientId: AppConfig.keycloakClientId,
          redirectUri: AppConfig.keycloakRedirectUri,
          discoveryUrl: AppConfig.keycloakDiscoveryUrl,
        );
        if (webResult != null) {
          authErrorMessage.value = '';
          await _storage.saveTokens(
            accessToken: webResult.accessToken,
            refreshToken: webResult.refreshToken,
            idToken: webResult.idToken,
          );
          _setAuthStateFromToken(webResult.accessToken);
          return;
        }
      } catch (error) {
        debugPrint('Web OIDC completion failed: $error');
        await logout();
        authErrorMessage.value = _describeWebAuthFailure(
          error,
          prefix:
              'Keycloak login completed, but the browser could not exchange the authorization code for a token.',
        );
        return;
      }
    }

    final token = await getValidToken();
    _setAuthStateFromToken(token);
  }

  Future<bool> login() async {
    isAuthenticating.value = true;

    try {
      if (kIsWeb && web_oidc.isWebOidcSupported) {
        authErrorMessage.value = '';
        // Start the web OIDC login flow (will redirect the browser).
        await web_oidc.startWebOidcLogin(
          clientId: AppConfig.keycloakClientId,
          redirectUri: AppConfig.keycloakRedirectUri,
          discoveryUrl: AppConfig.keycloakDiscoveryUrl,
        );
        return true;
      }
      final AuthorizationTokenResponse result =
          await _appAuth.authorizeAndExchangeCode(
        AuthorizationTokenRequest(
          AppConfig.keycloakClientId,
          AppConfig.keycloakRedirectUri,
          discoveryUrl: AppConfig.keycloakDiscoveryUrl,
          scopes: _scopes,
          allowInsecureConnections: false,
          promptValues: const ['login'],
        ),
      );

      debugPrint('Authorization result: $result');

      if (result.accessToken == null) {
        await logout();
        authErrorMessage.value = 'Keycloak did not return an access token.';
        return false;
      }

      authErrorMessage.value = '';
      await _storage.saveTokens(
        accessToken: result.accessToken!,
        refreshToken: result.refreshToken,
        idToken: result.idToken,
      );
      _setAuthStateFromToken(result.accessToken);
      return true;
    } catch (error) {
      debugPrint('Keycloak login failed: $error');
      await logout();
      authErrorMessage.value = _describeWebAuthFailure(
        error,
        prefix: 'Login failed.',
      );
      return false;
    } finally {
      isAuthenticating.value = false;
    }
  }

  Future<String?> getValidToken() async {
    final accessToken = await _storage.getAccessToken();
    if (accessToken == null) {
      return null;
    }
    if (!JwtDecoder.isExpired(accessToken)) {
      return accessToken;
    }
    final refreshToken = await _storage.getRefreshToken();
    if (refreshToken == null) {
      await logout();
      return null;
    }

    // On web, perform token refresh using HTTP POST to token endpoint.
    if (kIsWeb) {
      try {
        final discoveryResp =
            await http.get(Uri.parse(AppConfig.keycloakDiscoveryUrl));
        if (discoveryResp.statusCode < 200 || discoveryResp.statusCode >= 300) {
          throw StateError('Could not load discovery');
        }
        final Map<String, dynamic> discovery =
            jsonDecode(discoveryResp.body) as Map<String, dynamic>;
        final Uri tokenEndpoint =
            Uri.parse(discovery['token_endpoint'] as String);

        final http.Response tokenResp = await http.post(
          tokenEndpoint,
          headers: <String, String>{
            'Content-Type': 'application/x-www-form-urlencoded'
          },
          body: <String, String>{
            'grant_type': 'refresh_token',
            'client_id': AppConfig.keycloakClientId,
            'refresh_token': refreshToken,
          },
        );

        if (tokenResp.statusCode < 200 || tokenResp.statusCode >= 300) {
          throw StateError('Token refresh failed: ${tokenResp.body}');
        }

        final Map<String, dynamic> tokenBody =
            jsonDecode(tokenResp.body) as Map<String, dynamic>;
        final String newAccess = tokenBody['access_token'] as String;
        final String? newRefresh = tokenBody['refresh_token'] as String?;
        final String? idToken = tokenBody['id_token'] as String?;

        await _storage.saveTokens(
          accessToken: newAccess,
          refreshToken: newRefresh ?? refreshToken,
          idToken: idToken,
        );
        _setAuthStateFromToken(newAccess);
        return newAccess;
      } catch (error) {
        debugPrint('Web token refresh failed: $error');
        await logout();
        return null;
      }
    }

    // Fallback for mobile/native: use flutter_appauth to refresh
    try {
      final TokenResponse response = await _appAuth.token(
        TokenRequest(
          AppConfig.keycloakClientId,
          AppConfig.keycloakRedirectUri,
          discoveryUrl: AppConfig.keycloakDiscoveryUrl,
          refreshToken: refreshToken,
          scopes: _scopes,
          allowInsecureConnections: false,
        ),
      );

      if (response.accessToken == null) {
        await logout();
        return null;
      }

      await _storage.saveTokens(
        accessToken: response.accessToken!,
        refreshToken: response.refreshToken ?? refreshToken,
        idToken: response.idToken,
      );
      _setAuthStateFromToken(response.accessToken);
      return response.accessToken;
    } catch (error) {
      debugPrint('Token refresh failed: $error');
      await logout();
      return null;
    }
  }

  Future<void> logout() async {
    await _storage.clearTokens();
    isAuthenticated.value = false;
    _cachedToken = null;
    authErrorMessage.value = '';
    userId.value = '';
    isAuthenticated.value = false;
  }

  void _setAuthStateFromToken(String? token) {
    _cachedToken = token;
    isAuthenticated.value = token != null;

    if (token == null) {
      userId.value = '';
      return;
    }

    try {
      final Map<String, dynamic> decoded = JwtDecoder.decode(token);
      userId.value = (decoded['sub'] as String?) ?? '';
    } catch (_) {
      userId.value = '';
    }
  }

  String _describeWebAuthFailure(Object error, {required String prefix}) {
    final String details = error.toString().trim();
    if (details.isEmpty) {
      return '$prefix Check Keycloak Web Origins and Valid Redirect URIs for the current app origin.';
    }

    return '$prefix $details';
  }
}
