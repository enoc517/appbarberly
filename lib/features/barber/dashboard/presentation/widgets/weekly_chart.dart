import 'package:flutter/material.dart';
import '/../../../shared/motion/app_motion.dart';
import '/../../../shared/theme/app_theme.dart';
import '../../domain/entities/weekly_performance.dart';

class WeeklyChart extends StatelessWidget {
  final WeeklyPerformance data;
  const WeeklyChart({super.key, required this.data});

  static const _labels = ['L', 'M', 'M', 'J', 'V', 'S', 'D'];

  @override
  Widget build(BuildContext context) {
    final reduced = AppMotion.reduceMotion(context);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppRadius.xl),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'RENDIMIENTO SEMANAL',
                style: AppTypography.labelMedium.copyWith(
                  color: AppColors.onSurfaceVariant,
                  letterSpacing: 1.2,
                ),
              ),
              const Spacer(),
              const Icon(
                Icons.trending_up,
                size: 18,
                color: AppColors.onSurfaceVariant,
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 130,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(7, (i) {
                final isToday = i == data.todayIndex;
                final isMax =
                    data.dailyValues[i] ==
                    data.dailyValues.reduce((a, b) => a > b ? a : b);
                Color color;
                if (isToday) {
                  color = AppColors.secondary;
                } else if (isMax) {
                  color = AppColors.primary;
                } else {
                  color = AppColors.surfaceContainerHigh;
                }
                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(right: i == 6 ? 0 : 8),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TweenAnimationBuilder<double>(
                          tween: Tween<double>(
                            begin: reduced ? data.dailyValues[i] : 0,
                            end: data.dailyValues[i],
                          ),
                          duration: reduced
                              ? Duration.zero
                              : Duration(milliseconds: 320 + (i * 45)),
                          curve: AppMotion.standard,
                          builder: (context, value, child) => Container(
                            height: 110 * value,
                            decoration: BoxDecoration(
                              color: color,
                              borderRadius: BorderRadius.circular(AppRadius.md),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _labels[i],
                          style: AppTypography.labelSmall.copyWith(
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}
