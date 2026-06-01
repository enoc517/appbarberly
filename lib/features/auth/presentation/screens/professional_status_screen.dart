import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../shared/theme/app_theme.dart';
import '../../domain/entities/app_user.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_state.dart';

class ProfessionalStatusScreen extends StatelessWidget {
  const ProfessionalStatusScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        final theme = Theme.of(context);
        final status =
            state.user?.professionalStatus ?? ProfessionalStatus.pending;
        final isRejected = status == ProfessionalStatus.rejected;

        return Scaffold(
          backgroundColor: theme.scaffoldBackgroundColor,
          body: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 28,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 560),
                  child: Container(
                    padding: const EdgeInsets.all(28),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerLowest,
                      borderRadius: BorderRadius.circular(32),
                      boxShadow: [
                        BoxShadow(
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.06,
                          ),
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
                                ? theme.colorScheme.errorContainer
                                : theme.colorScheme.surfaceContainer,
                          ),
                          child: Icon(
                            isRejected
                                ? Icons.assignment_late_outlined
                                : Icons.hourglass_top_rounded,
                            color: isRejected
                                ? theme.colorScheme.onErrorContainer
                                : theme.colorScheme.primaryContainer,
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
                            color: theme.colorScheme.onSurface,
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
                            color: theme.colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 28),
                        SizedBox(
                          width: double.infinity,
                          height: 54,
                          child: FilledButton(
                            style: FilledButton.styleFrom(
                              backgroundColor:
                                  theme.colorScheme.primaryContainer,
                              foregroundColor:
                                  theme.colorScheme.onPrimaryContainer,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  AppRadius.xl,
                                ),
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
                              color: theme.colorScheme.onSurfaceVariant,
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
      },
    );
  }
}
