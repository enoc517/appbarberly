import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/welcome/presentation/screens/welcome_screen.dart';

/// Centralised route definitions for the application.
///
/// New features simply register their routes here.
class AppRouter {
  AppRouter._();

  // ── Route paths ───────────────────────────────────────────────────────────
  static const String welcome = '/';
  static const String login = '/login';
  static const String dashboard = '/dashboard';
  static const String home = '/home';

  // ── Router instance ───────────────────────────────────────────────────────
  static final GoRouter router = GoRouter(
    initialLocation: welcome,
    debugLogDiagnostics: true,
    routes: [
      GoRoute(
        path: welcome,
        name: 'welcome',
        builder: (context, state) => const WelcomeScreen(),
      ),
      // Placeholder routes — screens will be implemented in future phases.
      GoRoute(
        path: login,
        name: 'login',
        builder: (context, state) => const _PlaceholderScreen(title: 'Login'),
      ),
      GoRoute(
        path: dashboard,
        name: 'dashboard',
        builder: (context, state) =>
            const _PlaceholderScreen(title: 'Dashboard'),
      ),
      GoRoute(
        path: home,
        name: 'home',
        builder: (context, state) => const _PlaceholderScreen(title: 'Home'),
      ),
    ],
  );
}

/// Temporary placeholder for routes not yet implemented.
class _PlaceholderScreen extends StatelessWidget {
  const _PlaceholderScreen({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text(
          '$title — Próximamente',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
      ),
    );
  }
}
