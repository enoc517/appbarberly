import 'package:flutter/material.dart';
import 'package:barberly/shared/motion/app_motion.dart';
import 'package:barberly/shared/theme/app_theme.dart';
import 'package:barberly/features/explore/presentation/bloc/service_model.dart';

class ServiceCard extends StatelessWidget {
  final ServiceModel service;
  final bool isCompact;
  final VoidCallback? onTap;

  const ServiceCard({
    super.key,
    required this.service,
    this.isCompact = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AppPressable(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(AppRadius.xl),
          // Tonal layering ambient shadow
          boxShadow: [
            BoxShadow(
              color: AppColors.onSurface.withValues(alpha: 0.06),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _ServiceImage(service: service, isCompact: isCompact),
                _ServiceInfo(service: service, isCompact: isCompact),
              ],
            ),
            // "Ear silhouette" notch for NEW status (top-right)
            if (service.isNew)
              Positioned(top: 0, right: 12, child: _EarNotchBadge()),
          ],
        ),
      ),
    );
  }
}

class _ServiceImage extends StatelessWidget {
  final ServiceModel service;
  final bool isCompact;
  const _ServiceImage({required this.service, required this.isCompact});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.only(
        topLeft: Radius.circular(AppRadius.xl),
        topRight: Radius.circular(AppRadius.xl),
      ),
      child: Stack(
        children: [
          SizedBox(
            height: isCompact ? 96 : 120,
            width: double.infinity,
            child: Image.network(
              service.imageUrl,
              fit: BoxFit.cover,
              loadingBuilder: (_, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Container(
                  color: AppColors.surfaceContainerHighest,
                  child: Center(
                    child: CircularProgressIndicator(
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded /
                                loadingProgress.expectedTotalBytes!
                          : null,
                      strokeWidth: 2,
                      color: AppColors.primaryContainer,
                    ),
                  ),
                );
              },
              errorBuilder: (context, error, stackTrace) => Container(
                color: AppColors.surfaceContainerHighest,
                child: Icon(
                  Icons.content_cut_rounded,
                  color: AppColors.onSurfaceVariant,
                  size: 32,
                ),
              ),
            ),
          ),
          // Availability overlay
          if (!service.isAvailable)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.onSurface.withValues(alpha: 0.55),
                ),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerLowest,
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                    child: Text(
                      'No disponible',
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ServiceInfo extends StatelessWidget {
  final ServiceModel service;
  final bool isCompact;
  const _ServiceInfo({required this.service, required this.isCompact});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(isCompact ? 8 : 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            service.name,
            style: AppTypography.titleSmall.copyWith(
              color: AppColors.onSurface,
              fontWeight: FontWeight.w700,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: isCompact ? 2 : 2),
          Text(
            service.shopName,
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: isCompact ? 4 : 8),
          Row(
            children: [
              Icon(Icons.star_rounded, size: 14, color: AppColors.tertiary),
              const SizedBox(width: 3),
              Text(
                service.rating.toStringAsFixed(1),
                style: AppTypography.labelMedium.copyWith(
                  color: AppColors.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                ' (${service.reviewCount})',
                style: AppTypography.labelSmall.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
              ),
              const Spacer(),
              Icon(
                Icons.location_on_outlined,
                size: 13,
                color: AppColors.onSurfaceVariant,
              ),
              const SizedBox(width: 2),
              Text(
                service.distance,
                style: AppTypography.labelSmall.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
              ),
            ],
          ),
          SizedBox(height: isCompact ? 4 : 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  service.price,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.titleSmall.copyWith(
                    color: AppColors.primaryContainer,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              if (service.isAvailable) const SizedBox(width: 6),
              if (service.isAvailable)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primaryContainer.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: Text(
                    'Disponible',
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.primaryContainer,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Semi-circle "ear notch" badge – signature Stitch & Style motif.
class _EarNotchBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ClipPath(
      clipper: _SemiCircleClipper(),
      child: Container(
        width: 28,
        height: 16,
        color: AppColors.secondary,
        alignment: Alignment.center,
        child: Text(
          'NEW',
          style: AppTypography.labelSmall.copyWith(
            color: AppColors.onPrimary,
            fontSize: 7,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }
}

class _SemiCircleClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(0, 0, size.width, size.height),
          Radius.circular(size.width / 2),
        ),
      );
    return path;
  }

  @override
  bool shouldReclip(_) => false;
}
