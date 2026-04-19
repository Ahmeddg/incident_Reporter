import 'package:flutter/material.dart';
import 'package:incident_reporter/core/services/auth_service.dart';
import 'package:incident_reporter/ui/screens/app_shell.dart';
import 'package:incident_reporter/ui/screens/login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final authService = AuthService();
  await authService.init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();

    return MaterialApp(
      title: 'Incident Reporter',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF667EEA)),
        useMaterial3: true,
        fontFamily: 'Inter', // Assuming standard font fallback
      ),
      home: ValueListenableBuilder<bool>(
        valueListenable: authService.isAuthenticated,
        builder: (context, isAuthenticated, child) {
          if (isAuthenticated) {
            return const AppShell();
          } else {
            return const LoginScreen();
          }
        },
      ),
    );
  }
}
