import 'package:flutter/material.dart';
import 'package:incident_reporter/core/services/auth_service.dart';
import 'package:incident_reporter/ui/screens/home_screen.dart';
import 'package:incident_reporter/ui/screens/profile_screen.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  final AuthService _authService = AuthService();
  int _index = 0;

  late final List<Widget> _pages = <Widget>[
    const HomeScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (int value) => setState(() => _index = value),
        destinations: const <NavigationDestination>[
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
      floatingActionButton: _index == 1
          ? FloatingActionButton.extended(
              onPressed: () => _authService.logout(),
              icon: const Icon(Icons.logout),
              label: const Text('Logout'),
            )
          : null,
    );
  }
}
