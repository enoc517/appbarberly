import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:barberly/shared/motion/app_motion.dart';
import 'package:barberly/core/router/auth_route_resolver.dart';

import '../bloc/welcome_bloc.dart';
import '../bloc/welcome_event.dart';
import '../bloc/welcome_state.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<WelcomeBloc>().add(const WelcomeStarted());
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<WelcomeBloc, WelcomeState>(
      listenWhen: (prev, curr) => prev.status != curr.status,
      listener: (context, state) {
        switch (state.status) {
          case WelcomeStatus.goToLogin:
            context.go('/login');
            break;
          case WelcomeStatus.goToHome:
            context.go(routeForAuthenticatedUser(state.user));
            break;
          case WelcomeStatus.goToVerifyEmail:
            context.go('/verify-email');
            break;
          default:
            break;
        }
      },
      child: Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF1A2A20), Color(0xFF0F1C2C), Color(0xFF050D16)],
            ),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AppFadeSlideIn(
                  offset: const Offset(0, 0.04),
                  child: Image.asset(
                    'assets/logos/logo2.png',
                    width: MediaQuery.of(context).size.width * 0.6,
                    errorBuilder: (context, error, stackTrace) {
                      return const Text('ERROR CARGANDO IMAGEN');
                    },
                  ),
                ),
                const SizedBox(height: 40),
                const AppFadeSlideIn(
                  delay: Duration(milliseconds: 120),
                  offset: Offset(0, 0.03),
                  child: CircularProgressIndicator(color: Colors.white),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
