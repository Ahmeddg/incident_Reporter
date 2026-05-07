// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:convert';
import 'dart:html' as html;
import 'dart:math';

import 'package:http/http.dart' as http;

class WebOidcResult {
  const WebOidcResult({
    required this.accessToken,
    this.refreshToken,
    this.idToken,
  });

  final String accessToken;
  final String? refreshToken;
  final String? idToken;
}

bool get isWebOidcSupported => true;

Future<WebOidcResult?> completeWebOidcLogin({
  required String clientId,
  required String redirectUri,
  required String discoveryUrl,
}) async {
  final Uri currentUri = Uri.parse(html.window.location.href);
  final String? code = currentUri.queryParameters['code'];
  if (code == null || code.isEmpty) {
    return null;
  }

  try {
    final String? expectedState = html.window.localStorage['oidc_state'];
    final String? actualState = currentUri.queryParameters['state'];
    if (expectedState == null || expectedState != actualState) {
      throw StateError('Invalid login state returned from Keycloak.');
    }

    final Map<String, dynamic> discovery = await _loadDiscovery(discoveryUrl);
    final Uri tokenEndpoint = Uri.parse(discovery['token_endpoint'] as String);
    late final http.Response response;
    try {
      response = await http.post(
        tokenEndpoint,
        headers: const <String, String>{
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: <String, String>{
          'grant_type': 'authorization_code',
          'client_id': clientId,
          'redirect_uri': redirectUri,
          'code': code,
        },
      );
    } on http.ClientException catch (error) {
      final String origin = html.window.location.origin;
      throw StateError(
        'OIDC token exchange could not reach $tokenEndpoint from origin $origin. '
        'This is usually a CORS/Web Origins issue in Keycloak. '
        'Ensure the client allows this origin and redirect URI. Original error: $error',
      );
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw StateError('Keycloak token exchange failed: ${response.body}');
    }

    final Map<String, dynamic> tokenBody =
        jsonDecode(response.body) as Map<String, dynamic>;
    return WebOidcResult(
      accessToken: tokenBody['access_token'] as String,
      refreshToken: tokenBody['refresh_token'] as String?,
      idToken: tokenBody['id_token'] as String?,
    );
  } finally {
    // Always clear callback query params so the app does not endlessly retry
    // a failed token exchange on every page load.
    html.window.localStorage.remove('oidc_state');
    final Uri cleanUri =
        currentUri.replace(queryParameters: <String, String>{});
    html.window.history
        .replaceState(null, html.document.title, cleanUri.toString());
  }
}

Future<void> startWebOidcLogin({
  required String clientId,
  required String redirectUri,
  required String discoveryUrl,
}) async {
  final Map<String, dynamic> discovery = await _loadDiscovery(discoveryUrl);
  final String state = _randomString(32);
  html.window.localStorage['oidc_state'] = state;

  final Uri authorizationEndpoint =
      Uri.parse(discovery['authorization_endpoint'] as String);
  final Uri authorizationUri = authorizationEndpoint.replace(
    queryParameters: <String, String>{
      'client_id': clientId,
      'redirect_uri': redirectUri,
      'response_type': 'code',
      'scope': 'openid profile email',
      'state': state,
    },
  );

  html.window.location.assign(authorizationUri.toString());
}

Future<Map<String, dynamic>> _loadDiscovery(String discoveryUrl) async {
  final http.Response response = await http.get(Uri.parse(discoveryUrl));
  if (response.statusCode < 200 || response.statusCode >= 300) {
    throw StateError('Could not load Keycloak discovery: ${response.body}');
  }
  return jsonDecode(response.body) as Map<String, dynamic>;
}

String _randomString(int length) {
  const String alphabet =
      'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
  final Random random = Random.secure();
  return List<String>.generate(
    length,
    (_) => alphabet[random.nextInt(alphabet.length)],
  ).join();
}
