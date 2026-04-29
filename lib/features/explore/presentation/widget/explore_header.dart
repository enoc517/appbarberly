import 'package:flutter/material.dart';
import 'package:barberly/shared/theme/app_theme.dart';

class ExploreHeader extends StatelessWidget {
  final String userName;
  final String? avatarUrl;
  final VoidCallback onNotificationTap;

  const ExploreHeader({
    super.key,
    required this.userName,
    this.avatarUrl,
    required this.onNotificationTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _Avatar(url: avatarUrl),
        const SizedBox(width: 12),
        Expanded(child: _Greeting(userName: userName)),
        _NotificationButton(onTap: onNotificationTap),
      ],
    );
  }
}

class _Avatar extends StatelessWidget {
  final String? url;
  const _Avatar({this.url});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.surfaceContainerHighest,
        // Ghost border fallback (15% opacity outline_variant)
        boxShadow: [
          BoxShadow(
            color: AppColors.outlineVariant.withOpacity(0.15),
            blurRadius: 0,
            spreadRadius: 1.5,
          ),
        ],
      ),
      child: ClipOval(
        child: url != null
            ? Image.network(
                url!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _fallbackIcon(),
              )
            : _fallbackIcon(),
      ),
    );
  }

  Widget _fallbackIcon() {
    return Container(
      color: AppColors.primaryContainer,
      child: const Icon(
        Icons.person_rounded,
        color: AppColors.onPrimary,
        size: 24,
      ),
    );
  }
}

class _Greeting extends StatelessWidget {
  final String userName;
  const _Greeting({required this.userName});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Buen día,',
          style: AppTypography.labelMedium.copyWith(
            color: AppColors.onSurfaceVariant,
          ),
        ),
        Text(
          userName,
          style: AppTypography.titleMedium.copyWith(
            color: AppColors.onSurface,
            fontWeight: FontWeight.w700,
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

class _NotificationButton extends StatelessWidget {
  final VoidCallback onTap;
  const _NotificationButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Material(
          color: AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(AppRadius.md),
          child: InkWell(
            borderRadius: BorderRadius.circular(AppRadius.md),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Icon(
                Icons.notifications_outlined,
                color: AppColors.onSurface,
                size: 22,
              ),
            ),
          ),
        ),
        // Notification dot
        Positioned(
          top: 8,
          right: 8,
          child: Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: AppColors.secondary,
              shape: BoxShape.circle,
            ),
          ),
        ),
      ],
    );
  }
}
