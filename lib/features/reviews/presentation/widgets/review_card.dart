import 'package:flutter/material.dart';

import '../../../../shared/theme/app_theme.dart';
import '../../domain/entities/barbershop_review.dart';

class ReviewCard extends StatelessWidget {
  const ReviewCard({super.key, required this.review, this.dense = false});

  final BarbershopReview review;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final comment = review.comment?.trim() ?? '';

    return Container(
      padding: EdgeInsets.all(dense ? 14 : 16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.12),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Avatar(review: review),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            review.clientSnapshot.name.isEmpty
                                ? 'Cliente'
                                : review.clientSnapshot.name,
                            style: AppTypography.titleSmall,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        _StarRow(rating: review.rating),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      review.serviceSnapshot.name,
                      style: AppTypography.labelSmall.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatDate(review.createdAt),
                      style: AppTypography.labelSmall.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (comment.isNotEmpty && !dense) ...[
            const SizedBox(height: 12),
            Text(
              comment,
              style: AppTypography.bodyMedium.copyWith(
                color: colorScheme.onSurface,
              ),
            ),
          ],
          if (comment.isNotEmpty && dense) ...[
            const SizedBox(height: 10),
            Text(
              comment,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.bodyMedium.copyWith(
                color: colorScheme.onSurface,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.review});

  final BarbershopReview review;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final imageUrl = review.clientSnapshot.imageUrl;
    final name = review.clientSnapshot.name;
    final initial = name.trim().isEmpty ? 'C' : name.trim()[0].toUpperCase();

    return CircleAvatar(
      radius: 22,
      backgroundColor: colorScheme.primaryContainer,
      backgroundImage: imageUrl?.isNotEmpty == true ? NetworkImage(imageUrl!) : null,
      child: imageUrl?.isNotEmpty == true
          ? null
          : Text(
              initial,
              style: AppTypography.labelLarge.copyWith(
                color: colorScheme.onPrimaryContainer,
                fontWeight: FontWeight.w800,
              ),
            ),
    );
  }
}

class _StarRow extends StatelessWidget {
  const _StarRow({required this.rating});

  final int rating;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(
        5,
        (index) => Icon(
          index < rating ? Icons.star_rounded : Icons.star_border_rounded,
          size: 16,
          color: colorScheme.secondary,
        ),
      ),
    );
  }
}

String _formatDate(DateTime value) {
  const months = [
    'ene',
    'feb',
    'mar',
    'abr',
    'may',
    'jun',
    'jul',
    'ago',
    'sep',
    'oct',
    'nov',
    'dic',
  ];
  final day = value.day.toString().padLeft(2, '0');
  final month = months[value.month - 1];
  return '$day $month ${value.year}';
}
