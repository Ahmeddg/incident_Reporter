import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:incident_reporter/core/services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final AuthService _authService = AuthService();
  bool _isLoading = false;

  Future<void> _handleLogin() async {
    setState(() => _isLoading = true);
    final success = await _authService.login();
    setState(() => _isLoading = false);

    if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Authentication failed.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: <Color>[
              Color(0xFF0B2E36),
              Color(0xFF16697A),
              Color(0xFFF6F8FA),
            ],
            stops: <double>[0, 0.58, 0.58],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const Icon(
                      Icons.health_and_safety_rounded,
                      size: 54,
                      color: Colors.white,
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      'Incident Reporter',
                      style: TextStyle(
                        fontSize: 34,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Secure responder access for emergency reporting and live incident tracking.',
                      style: TextStyle(
                        height: 1.4,
                        color: Color(0xFFD6EFF2),
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 36),
                    Container(
                      padding: const EdgeInsets.all(22),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFE1E7EC)),
                        boxShadow: const <BoxShadow>[
                          BoxShadow(
                            color: Color(0x1A102027),
                            blurRadius: 24,
                            offset: Offset(0, 12),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          const Row(
                            children: <Widget>[
                              Icon(
                                Icons.verified_user_outlined,
                                color: Color(0xFF16697A),
                              ),
                              SizedBox(width: 10),
                              Text(
                                'Sign in with SSO',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Keycloak verifies your identity before opening protected incident tools.',
                            style: TextStyle(color: Color(0xFF5E6A72)),
                          ),
                          const SizedBox(height: 24),
                          Obx(() {
                            final String message =
                                _authService.authErrorMessage.value;
                            if (message.isEmpty) {
                              return const SizedBox.shrink();
                            }

                            return Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFF3F1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: const Color(0xFFF2B8B5),
                                ),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  const Icon(
                                    Icons.error_outline_rounded,
                                    color: Color(0xFFC23934),
                                    size: 20,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      message,
                                      style: const TextStyle(
                                        color: Color(0xFF7A1F1B),
                                        height: 1.35,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            height: 54,
                            child: ElevatedButton.icon(
                              onPressed: _isLoading ? null : _handleLogin,
                              icon: _isLoading
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Icon(Icons.login_rounded),
                              label: const Text('Authorize Access'),
                            ),
                          ),
                          const SizedBox(height: 14),
                          const Row(
                            children: <Widget>[
                              Icon(
                                Icons.lock_outline_rounded,
                                size: 16,
                                color: Color(0xFF637381),
                              ),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Protected by Single Sign-On',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF637381),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
