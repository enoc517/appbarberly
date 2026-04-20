import 'package:barberly/features/auth/presentation/widget/forgot_password_form.dart';
import 'package:barberly/shared/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../bloc/password_recovery_bloc.dart'; // Reutilizamos el bloc de auth o creas uno específico

class ForgotPasswordScreen extends StatelessWidget {
  const ForgotPasswordScreen({super.key});

  static const String routeName = 'forgot_password';
  static const String routePath = '/forgot_password';

  @override
  Widget build(BuildContext context) {
    // Nota: Aquí podrías usar un ForgotPasswordBloc si prefieres separar lógica de token/reset
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: AppColors.onSurface,
            size: 20,
          ),
          onPressed: () => GoRouter.of(context).go('/login'),
        ),
        centerTitle: true,
      ),
      body: const SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.0),
          child: ForgotPasswordForm(),
        ),
      ),
    );
  }
}
