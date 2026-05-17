import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../../shared/motion/app_motion.dart';
import '../../../../../shared/theme/app_theme.dart';
import '../cubit/barber_account_cubit.dart';
import '../cubit/barber_account_state.dart';

class BarberAccountScreen extends StatelessWidget {
  const BarberAccountScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => BarberAccountCubit()..loadData(),
      child: const _BarberAccountView(),
    );
  }
}

class _BarberAccountView extends StatelessWidget {
  const _BarberAccountView();

  @override
  Widget build(BuildContext context) {
    return BlocListener<BarberAccountCubit, BarberAccountState>(
      listenWhen: (prev, curr) => prev.errorMessage != curr.errorMessage,
      listener: (context, state) {
        if (state.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.errorMessage!)),
          );
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: BlocBuilder<BarberAccountCubit, BarberAccountState>(
          buildWhen: (prev, curr) => prev.isLoading != curr.isLoading,
          builder: (context, state) {
            if (state.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            return const _AccountContent();
          },
        ),
      ),
    );
  }
}

class _AccountContent extends StatelessWidget {
  const _AccountContent();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BarberAccountCubit, BarberAccountState>(
      builder: (context, state) {
        return SafeArea(
          bottom: false,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
            children: [
              AppFadeSlideIn(
                child: _AccountHeader(
                  userName: state.userName ?? 'Barbero',
                  userEmail: state.userEmail ?? '',
                ),
              ),
              const SizedBox(height: 16),
              if (state.hasBarbershop)
                AppFadeSlideIn(
                  delay: AppMotion.delay(1),
                  child: _BarbershopCard(
                    shopName: state.barbershopName != null ? 'Mi barbería' : 'Sin nombre',
                    role: state.isOwner ? 'Dueño' : 'Barbero',
                  ),
                ),
              const SizedBox(height: 16),
              if (!state.hasBarbershop) ...[
                AppFadeSlideIn(
                  delay: AppMotion.delay(1),
                  child: _AccountAction(
                    icon: Icons.storefront_rounded,
                    title: 'Crear mi barbería',
                    onTap: () => context.go('/cuenta-barbero/crear-barberia'),
                  ),
                ),
                const SizedBox(height: 8),
                AppFadeSlideIn(
                  delay: AppMotion.delay(2),
                  child: _AccountAction(
                    icon: Icons.search_rounded,
                    title: 'Buscar barberías para unirme',
                    onTap: () => context.go('/cuenta-barbero/buscar-barberias'),
                  ),
                ),
              ],
              if (state.hasBarbershop && state.isOwner) ...[
                AppFadeSlideIn(
                  delay: AppMotion.delay(1),
                  child: _AccountAction(
                    icon: Icons.people_rounded,
                    title: 'Solicitudes pendientes',
                    onTap: () => context.go('/cuenta-barbero/solicitudes'),
                  ),
                ),
              ],
              if (state.hasBarbershop) ...[
                const SizedBox(height: 8),
                AppFadeSlideIn(
                  delay: AppMotion.delay(2),
                  child: _AccountAction(
                    icon: Icons.spa_rounded,
                    title: 'Mis servicios',
                    onTap: () => context.go('/cuenta-barbero/mis-servicios'),
                  ),
                ),
                const SizedBox(height: 8),
                AppFadeSlideIn(
                  delay: AppMotion.delay(3),
                  child: _AccountAction(
                    icon: Icons.schedule_rounded,
                    title: 'Mi horario',
                    onTap: () => context.go('/cuenta-barbero/mi-horario'),
                  ),
                ),
                if (!state.isOwner) ...[
                  const SizedBox(height: 8),
                  AppFadeSlideIn(
                    delay: AppMotion.delay(4),
                    child: _AccountAction(
                      icon: Icons.exit_to_app_rounded,
                      title: 'Salir de la barbería',
                      onTap: () => _showLeaveDialog(context),
                      destructive: true,
                    ),
                  ),
                ],
              ],
              const SizedBox(height: 24),
              AppFadeSlideIn(
                delay: AppMotion.delay(5),
                child: _LogoutButton(
                  onTap: () async {
                    await context.read<BarberAccountCubit>().logout();
                    if (context.mounted) context.go('/login');
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showLeaveDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Salir de la barbería'),
        content: const Text(
          'Tus citas futuras serán canceladas. ¿Confirmas?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.secondary),
            onPressed: () {
              Navigator.pop(ctx);
              context.read<BarberAccountCubit>().leaveBarbershop();
            },
            child: const Text('Salir'),
          ),
        ],
      ),
    );
  }
}

class _AccountHeader extends StatelessWidget {
  final String userName;
  final String userEmail;
  const _AccountHeader({required this.userName, required this.userEmail});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const CircleAvatar(
          radius: 30,
          backgroundColor: AppColors.primary,
          child: Icon(Icons.content_cut_rounded, color: AppColors.onPrimary),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(userName, style: AppTypography.headlineSmall),
              const SizedBox(height: 2),
              Text(
                userEmail,
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _BarbershopCard extends StatelessWidget {
  final String shopName;
  final String role;
  const _BarbershopCard({required this.shopName, required this.role});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(AppRadius.xl),
      ),
      child: Row(
        children: [
          const Icon(Icons.storefront_rounded, color: AppColors.secondary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Mi barbería',
                  style: AppTypography.titleSmall.copyWith(
                    color: AppColors.onPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Rol: $role',
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

class _AccountAction extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final bool destructive;
  const _AccountAction({
    required this.icon,
    required this.title,
    required this.onTap,
    this.destructive = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        child: ListTile(
          leading: Icon(
            icon,
            color: destructive ? AppColors.secondary : AppColors.primary,
          ),
          title: Text(
            title,
            style: AppTypography.titleSmall.copyWith(
              color: destructive ? AppColors.secondary : AppColors.onSurface,
            ),
          ),
          trailing: const Icon(Icons.chevron_right_rounded),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.xl),
          ),
          onTap: onTap,
        ),
      ),
    );
  }
}

class _LogoutButton extends StatelessWidget {
  final VoidCallback onTap;
  const _LogoutButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: const Icon(Icons.logout_rounded),
      label: const Text('Cerrar sesión'),
    );
  }
}
