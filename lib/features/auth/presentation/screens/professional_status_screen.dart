import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../shared/theme/app_theme.dart';
import '../../domain/entities/app_user.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';

class ProfessionalStatusScreen extends StatefulWidget {
  const ProfessionalStatusScreen({super.key});

  @override
  State<ProfessionalStatusScreen> createState() =>
      _ProfessionalStatusScreenState();
}

class _ProfessionalStatusScreenState extends State<ProfessionalStatusScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<AuthBloc>().add(const AuthLoadCurrentUserRequested());
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AuthBloc>().state;
    final status = state.user?.professionalStatus ?? ProfessionalStatus.pending;
    final isRejected = status == ProfessionalStatus.rejected;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Container(
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(32),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.ambientShadow,
                      blurRadius: 32,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 76,
                      height: 76,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isRejected
                            ? AppColors.errorContainer
                            : AppColors.surfaceContainer,
                      ),
                      child: Icon(
                        isRejected
                            ? Icons.assignment_late_outlined
                            : Icons.hourglass_top_rounded,
                        color: isRejected
                            ? AppColors.onErrorContainer
                            : AppColors.primaryContainer,
                        size: 34,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      isRejected
                          ? 'Solicitud no aprobada'
                          : 'Perfil de barbero en revisión',
                      textAlign: TextAlign.center,
                      style: AppTypography.headlineSmall.copyWith(
                        color: AppColors.onSurface,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      isRejected
                          ? 'Tu solicitud profesional no fue aprobada. Puedes seguir usando Barberly como cliente y volver a solicitar revisión más adelante.'
                          : 'Estamos revisando tu solicitud profesional. Mientras tanto puedes seguir usando Barberly como cliente.',
                      textAlign: TextAlign.center,
                      style: AppTypography.bodyLarge.copyWith(
                        color: AppColors.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 28),
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.primaryContainer,
                          foregroundColor: AppColors.onPrimary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppRadius.xl),
                          ),
                        ),
                        onPressed: () => context.go('/explorar'),
                        child: const Text('Explorar como cliente'),
                      ),
                    ),
                    if (isRejected) ...[
                      const SizedBox(height: 12),
                      Text(
                        'La re-solicitud se habilitará desde el perfil cuando el panel admin esté listo.',
                        textAlign: TextAlign.center,
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                    ],
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
