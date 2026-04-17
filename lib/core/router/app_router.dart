import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

// ── Features ─────────────────────────────────────────────
import '../../features/welcome/presentation/screens/welcome_screen.dart';
import '../../features/welcome/presentation/bloc/welcome_bloc.dart';

// ── Router ───────────────────────────────────────────────
class AppRouter {
  AppRouter._();

  // ── Route paths ────────────────────────────────────────
  static const String welcome = '/';
  static const String login = '/login';
  static const String dashboard = '/dashboard';
  static const String home = '/home';
  static const String register = '/register';

  // ── Router instance ────────────────────────────────────
  static final GoRouter router = GoRouter(
    initialLocation: welcome,
    debugLogDiagnostics: true,

    routes: [
      // ── Welcome (Splash inteligente) ───────────────────
      GoRoute(
        path: welcome,
        name: 'welcome',
        builder: (context, state) => BlocProvider(
          create: (_) => WelcomeBloc(),
          child: const WelcomeScreen(),
        ),
      ),

      // ── Login ─────────────────────────────────────────
      GoRoute(
        path: login,
        name: 'login',
        builder: (context, state) => const _PlaceholderScreen(title: 'Login'),
      ),
      GoRoute(
        path: register,
        name: 'register',
        builder: (context, state) =>
            const _PlaceholderScreen(title: 'Register'),
      ),
      // ── Dashboard (barber) ────────────────────────────
      GoRoute(
        path: dashboard,
        name: 'dashboard',
        builder: (context, state) =>
            const _PlaceholderScreen(title: 'Dashboard'),
      ),

      // ── Home (client) ─────────────────────────────────
      GoRoute(
        path: home,
        name: 'home',
        builder: (context, state) => const _PlaceholderScreen(title: 'Home'),
      ),
    ],
  );
}

// ── Placeholder temporal ─────────────────────────────────
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
