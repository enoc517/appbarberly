import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../shared/theme/app_theme.dart';

class ResetPasswordScreen extends StatelessWidget {
  const ResetPasswordScreen({super.key});

  static const String routeName = 'reset_password';
  static const String routePath = '/reset_password';

  @override
  Widget build(BuildContext context) {
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
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.primaryContainer,
                borderRadius: BorderRadius.circular(28),
              ),
              child: const Icon(
                Icons.lock_reset,
                color: Colors.white,
                size: 48,
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'Restablecimiento externo',
              textAlign: TextAlign.center,
              style: AppTypography.headlineMedium.copyWith(
                color: AppColors.onSurface,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Esta pantalla se conserva, pero el cambio de contraseña se realiza desde el enlace enviado por Firebase.',
              textAlign: TextAlign.center,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: FilledButton(
                onPressed: () => GoRouter.of(context).go('/login'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primaryContainer,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: const Text('Volver al inicio de sesión'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
