import 'package:flutter/material.dart';
import '../../../../../shared/theme/app_theme.dart';

class BarbershopHeader extends StatelessWidget {
  const BarbershopHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: const Icon(Icons.cut, color: AppColors.onPrimary, size: 18),
          ),
          const SizedBox(width: 10),
          Text('Barberly', style: AppTypography.titleLarge),
          const Spacer(),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.notifications_outlined),
          ),
        ],
      ),
    );
  }
}