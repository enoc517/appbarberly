import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../../shared/motion/app_motion.dart';
import '../../../../../shared/theme/app_theme.dart';
import '../cubit/barber_profile_cubit.dart';

class BarberAccountScreen extends StatelessWidget {
  const BarberAccountScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => BarberProfileCubit()..loadData(),
      child: const _BarberAccountView(),
    );
  }
}

class _BarberAccountView extends StatelessWidget {
  const _BarberAccountView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: BlocBuilder<BarberProfileCubit, BarberProfileState>(
        buildWhen: (prev, curr) => prev.isLoading != curr.isLoading,
        builder: (context, state) {
          if (state.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          return _ProfileContent(
            userName: state.userName,
            userEmail: state.userEmail,
          );
        },
      ),
    );
  }
}

class _ProfileContent extends StatelessWidget {
  final String userName;
  final String userEmail;
  const _ProfileContent({required this.userName, required this.userEmail});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
        children: [
          AppFadeSlideIn(
            child: _ProfileHeader(
              userName: userName,
              userEmail: userEmail,
            ),
          ),
          const SizedBox(height: 32),
          AppFadeSlideIn(
            delay: AppMotion.delay(1),
            child: _LogoutButton(
              onTap: () async {
                await context.read<BarberProfileCubit>().logout();
                if (context.mounted) context.go('/login');
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  final String userName;
  final String userEmail;
  const _ProfileHeader({required this.userName, required this.userEmail});

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
              Text(
                userName,
                style: AppTypography.headlineSmall,
              ),
              const SizedBox(height: 4),
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
