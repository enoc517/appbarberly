import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../shared/theme/app_theme.dart';
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
            context.go('/home');
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
                // Logo
                Image.asset(
                  'assets/logos/logo2.png',
                  width: MediaQuery.of(context).size.width * 0.6,
                  errorBuilder: (context, error, stackTrace) {
                    return const Text('ERROR CARGANDO IMAGEN');
                  },
                ),

                const SizedBox(height: 40),

                // Loader
                const CircularProgressIndicator(color: Colors.white),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
