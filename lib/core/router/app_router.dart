import 'package:barberly/features/auth/presentation/screens/register_screen.dart';
import 'package:barberly/features/auth/presentation/screens/verify_token_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

// ── Features ─────────────────────────────────────────────
import '../../features/welcome/presentation/screens/welcome_screen.dart';
import '../../features/welcome/presentation/bloc/welcome_bloc.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import 'package:barberly/features/auth/presentation/screens/forgot_password_screen.dart';
import '../../features/auth/presentation/screens/reset_password_screen.dart';
import 'package:barberly/features/auth/presentation/bloc/password_recovery_bloc.dart';

// ── Router ───────────────────────────────────────────────
class AppRouter {
  AppRouter._();

  // ── Route paths ────────────────────────────────────────
  static const String welcome = '/';
  static const String login = '/login';
  static const String dashboard = '/dashboard';
  static const String home = '/home';
  static const String register = '/register';
  static const String forgot_password = '/forgot_password';
  static const String verify_token = '/verify_token';
  static const String reset_password = '/reset_password';

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
        builder: (context, state) => const LoginScreen(),
      ),

      // ── Register ───────────────────────────────────────
      GoRoute(
        path: register,
        name: 'register',
        builder: (context, state) => const RegisterScreen(),
      ),

      ShellRoute(
        builder: (context, state, child) {
          // Este provider envuelve a los 3 hijos y mantiene los datos (email, token)
          return BlocProvider(
            create: (context) => PasswordRecoveryBloc(),
            child: child,
          );
        },
        routes: [
          GoRoute(
            path: forgot_password,
            name: 'forgot_password',
            builder: (context, state) => const ForgotPasswordScreen(),
          ),
          GoRoute(
            path: verify_token,
            name: 'verify_token',
            builder: (context, state) => const VerifyTokenScreen(),
          ),
          GoRoute(
            path: reset_password,
            name: 'reset_password',
            builder: (context, state) => const ResetPasswordScreen(),
          ),
        ],
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
