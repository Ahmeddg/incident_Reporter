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

bool get isWebOidcSupported => false;

Future<WebOidcResult?> completeWebOidcLogin({
  required String clientId,
  required String redirectUri,
  required String discoveryUrl,
}) async {
  return null;
}

Future<void> startWebOidcLogin({
  required String clientId,
  required String redirectUri,
  required String discoveryUrl,
}) async {}
