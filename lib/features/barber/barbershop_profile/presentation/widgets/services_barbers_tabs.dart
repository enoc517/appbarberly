import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../shared/motion/app_motion.dart';
import '../../../../../shared/theme/app_theme.dart';
import '../bloc/booking/booking_cubit.dart';
import '../bloc/booking/booking_state.dart';

class ServicesBarbersTabs extends StatelessWidget {
  const ServicesBarbersTabs({super.key});

  @override
  Widget build(BuildContext context) {
    final activeTab = context.select<BookingCubit, ProfileTab>(
      (c) => c.state.activeTab,
    );
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainer,
          borderRadius: BorderRadius.circular(AppRadius.xl),
        ),
        child: Row(
          children: [
            _TabButton(
              label: 'Servicios',
              selected: activeTab == ProfileTab.services,
              onTap: () =>
                  context.read<BookingCubit>().changeTab(ProfileTab.services),
            ),
            _TabButton(
              label: 'Barberos',
              selected: activeTab == ProfileTab.barbers,
              onTap: () =>
                  context.read<BookingCubit>().changeTab(ProfileTab.barbers),
            ),
          ],
        ),
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _TabButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: AppPressable(
        onTap: onTap,
        child: AnimatedContainer(
          duration: AppMotion.fast,
          curve: AppMotion.standard,
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.surfaceContainerLowest
                : Colors.transparent,
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: AppTypography.titleSmall.copyWith(
              color: selected ? AppColors.onSurface : AppColors.outline,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}
