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
  State<BarbershopManagementScreen> createState() =>
      _BarbershopManagementScreenState();
}

class _BarbershopManagementScreenState
    extends State<BarbershopManagementScreen> {
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
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        bottom: false,
        child:
            BlocBuilder<
              BarbershopManagementHubCubit,
              BarbershopManagementHubState
            >(
              buildWhen: (prev, curr) =>
                  prev.isLoading != curr.isLoading ||
                  prev.hasBarbershop != curr.hasBarbershop ||
                  prev.barbershopName != curr.barbershopName ||
                  prev.isOwner != curr.isOwner,
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
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.storefront_rounded,
              size: 72,
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 20),
            Text(
              'No tienes barbería asignada',
              style: AppTypography.titleLarge.copyWith(
                color: theme.colorScheme.onSurface,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Crea tu propia barbería o únete a una existente para empezar a gestionar tu negocio.',
              textAlign: TextAlign.center,
              style: AppTypography.bodyMedium.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 32),
            AppFadeSlideIn(
              delay: AppMotion.delay(1),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () =>
                      context.push('/cuenta-barbero/crear-barberia'),
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Crear mi barbería'),
                  style: FilledButton.styleFrom(
                    backgroundColor: theme.colorScheme.primaryContainer,
                    foregroundColor: theme.colorScheme.onPrimaryContainer,
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
                  onPressed: () =>
                      context.go('/cuenta-barbero/buscar-barberias'),
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
          child: _HubHeader(barbershopName: barbershopName, isOwner: isOwner),
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
            icon: Icons.notifications_rounded,
            title: 'Notificaciones',
            subtitle: 'Revisa novedades de citas y penalizaciones',
            onTap: () => context.push('/notificaciones'),
          ),
        ),
        const SizedBox(height: 8),
        AppFadeSlideIn(
          delay: AppMotion.delay(3),
          child: _HubAction(
            icon: Icons.request_quote_rounded,
            title: 'Penalizaciones pendientes',
            subtitle: 'Clientes con cancelaciones tardías por resolver',
            onTap: () => context.push('/cuenta-barbero/penalizaciones'),
          ),
        ),
        const SizedBox(height: 8),
        AppFadeSlideIn(
          delay: AppMotion.delay(4),
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
            delay: AppMotion.delay(5),
            child: _HubAction(
              icon: Icons.edit_rounded,
              title: 'Editar información',
              subtitle: 'Actualiza datos, ubicación e imagen de tu barbería',
              onTap: () => context.push('/cuenta-barbero/editar-barberia'),
            ),
          ),
          const SizedBox(height: 8),
          AppFadeSlideIn(
            delay: AppMotion.delay(6),
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
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary,
        borderRadius: BorderRadius.circular(AppRadius.xl),
      ),
      child: Row(
        children: [
          Icon(Icons.storefront_rounded, color: theme.colorScheme.onPrimary),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  barbershopName ?? 'Mi barbería',
                  style: AppTypography.titleLarge.copyWith(
                    color: theme.colorScheme.onPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isOwner ? 'Dueño' : 'Barbero',
                  style: AppTypography.bodySmall.copyWith(
                    color: theme.colorScheme.onPrimary.withValues(alpha: 0.7),
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
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surfaceContainerLowest,
      borderRadius: BorderRadius.circular(AppRadius.xl),
      child: ListTile(
        leading: Icon(icon, color: theme.colorScheme.primary),
        title: Text(
          title,
          style: AppTypography.titleSmall.copyWith(
            color: theme.colorScheme.onSurface,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: AppTypography.bodySmall.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
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
