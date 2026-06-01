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
    final theme = Theme.of(context);
    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: theme.colorScheme.surfaceContainerHighest,
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.15),
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
                errorBuilder: (_, _, _) => _fallbackIcon(theme),
              )
            : _fallbackIcon(theme),
      ),
    );
  }

  Widget _fallbackIcon(ThemeData theme) {
    return Container(
      color: theme.colorScheme.primaryContainer,
      child: Icon(
        Icons.person_rounded,
        color: theme.colorScheme.onPrimaryContainer,
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
    final theme = Theme.of(context);
    final displayName = userName.trim().isEmpty ? 'Usuario' : userName.trim();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Buen día,',
          style: AppTypography.labelMedium.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        Text(
          displayName,
          style: AppTypography.titleMedium.copyWith(
            color: theme.colorScheme.onSurface,
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
    final theme = Theme.of(context);
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Material(
          color: theme.colorScheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(AppRadius.md),
          child: InkWell(
            borderRadius: BorderRadius.circular(AppRadius.md),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Icon(
                Icons.notifications_outlined,
                color: theme.colorScheme.onSurface,
                size: 22,
              ),
            ),
          ),
        ),
        Positioned(
          top: 8,
          right: 8,
          child: Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: theme.colorScheme.secondary,
              shape: BoxShape.circle,
            ),
          ),
        ),
      ],
    );
  }
}
