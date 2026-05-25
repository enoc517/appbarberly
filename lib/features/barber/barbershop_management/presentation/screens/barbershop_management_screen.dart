import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../../shared/motion/app_motion.dart';
import '../../../../../shared/theme/app_theme.dart';
import '../cubit/barbershop_management_hub_cubit.dart';
import '../cubit/barbershop_management_hub_state.dart';

class BarbershopManagementScreen extends StatefulWidget {
  const BarbershopManagementScreen({super.key});

  @override
  State<BarbershopManagementScreen> createState() => _BarbershopManagementScreenState();
}

class _BarbershopManagementScreenState extends State<BarbershopManagementScreen> {
  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: context.read<BarbershopManagementHubCubit>(),
      child: const _BarbershopManagementView(),
    );
  }
}

class _BarbershopManagementView extends StatelessWidget {
  const _BarbershopManagementView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: BlocBuilder<BarbershopManagementHubCubit, BarbershopManagementHubState>(
          buildWhen: (prev, curr) =>
              prev.isLoading != curr.isLoading ||
              prev.hasBarbershop != curr.hasBarbershop,
          builder: (context, state) {
            if (state.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (!state.hasBarbershop) {
              return const _NoBarbershopView();
            }
            return _ManagementHubView(
              barbershopName: state.barbershopName,
              isOwner: state.isOwner,
            );
          },
        ),
      ),
    );
  }
}

class _NoBarbershopView extends StatelessWidget {
  const _NoBarbershopView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.storefront_rounded,
              size: 72,
              color: AppColors.onSurfaceVariant.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 20),
            Text(
              'No tienes barbería asignada',
              style: AppTypography.titleLarge.copyWith(
                color: AppColors.onSurface,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Crea tu propia barbería o únete a una existente para empezar a gestionar tu negocio.',
              textAlign: TextAlign.center,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 32),
            AppFadeSlideIn(
              delay: AppMotion.delay(1),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () => context.push('/cuenta-barbero/crear-barberia'),
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Crear mi barbería'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primaryContainer,
                    foregroundColor: AppColors.onPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.xl),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            AppFadeSlideIn(
              delay: AppMotion.delay(2),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => context.go('/cuenta-barbero/buscar-barberias'),
                  icon: const Icon(Icons.search_rounded),
                  label: const Text('Buscar barberías para unirme'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.xl),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ManagementHubView extends StatelessWidget {
  final String? barbershopName;
  final bool isOwner;
  const _ManagementHubView({this.barbershopName, required this.isOwner});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
      children: [
        AppFadeSlideIn(
          child: _HubHeader(
            barbershopName: barbershopName,
            isOwner: isOwner,
          ),
        ),
        const SizedBox(height: 24),
        AppFadeSlideIn(
          delay: AppMotion.delay(1),
          child: _HubAction(
            icon: Icons.spa_rounded,
            title: 'Mis servicios',
            subtitle: 'Gestiona los servicios que ofreces',
            onTap: () => context.push('/cuenta-barbero/mis-servicios'),
          ),
        ),
        const SizedBox(height: 8),
        AppFadeSlideIn(
          delay: AppMotion.delay(2),
          child: _HubAction(
            icon: Icons.schedule_rounded,
            title: 'Mi horario',
            subtitle: 'Configura tu disponibilidad semanal',
            onTap: () => context.push('/cuenta-barbero/mi-horario'),
          ),
        ),
        if (isOwner) ...[
          const SizedBox(height: 8),
          AppFadeSlideIn(
            delay: AppMotion.delay(3),
            child: _HubAction(
              icon: Icons.people_rounded,
              title: 'Solicitudes pendientes',
              subtitle: 'Revisa quién quiere unirse a tu barbería',
              onTap: () => context.push('/cuenta-barbero/solicitudes'),
            ),
          ),
        ],
      ],
    );
  }
}

class _HubHeader extends StatelessWidget {
  final String? barbershopName;
  final bool isOwner;
  const _HubHeader({this.barbershopName, required this.isOwner});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(AppRadius.xl),
      ),
      child: Row(
        children: [
          const Icon(Icons.storefront_rounded, color: AppColors.secondary),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  barbershopName ?? 'Mi barbería',
                  style: AppTypography.titleLarge.copyWith(
                    color: AppColors.onPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isOwner ? 'Dueño' : 'Barbero',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.onPrimary.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HubAction extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  const _HubAction({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surfaceContainerLowest,
      borderRadius: BorderRadius.circular(AppRadius.xl),
      child: ListTile(
        leading: Icon(icon, color: AppColors.primary),
        title: Text(
          title,
          style: AppTypography.titleSmall.copyWith(
            color: AppColors.onSurface,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.onSurfaceVariant,
          ),
        ),
        trailing: const Icon(Icons.chevron_right_rounded),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.xl),
        ),
        onTap: onTap,
      ),
    );
  }
}
