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
    final theme = Theme.of(context);
    final reduced = AppMotion.reduceMotion(context);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLowest,
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
                  color: theme.colorScheme.onSurfaceVariant,
                  letterSpacing: 1.2,
                ),
              ),
              const Spacer(),
              Icon(
                Icons.trending_up,
                size: 18,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Citas completadas por día',
            style: AppTypography.bodySmall.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
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
                  color = theme.colorScheme.primaryContainer;
                } else if (isMax) {
                  color = theme.colorScheme.primary;
                } else {
                  color = theme.colorScheme.surfaceContainerHigh;
                }
                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(right: i == 6 ? 0 : 8),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Align(
                            alignment: Alignment.bottomCenter,
                            child: FractionallySizedBox(
                              heightFactor: data.dailyValues[i].clamp(0.0, 1.0),
                              alignment: Alignment.bottomCenter,
                              child: TweenAnimationBuilder<double>(
                                tween: Tween<double>(
                                  begin: reduced ? 1 : 0,
                                  end: 1,
                                ),
                                duration: reduced
                                    ? Duration.zero
                                    : Duration(milliseconds: 320 + (i * 45)),
                                curve: AppMotion.standard,
                                builder: (context, value, child) => Align(
                                  alignment: Alignment.bottomCenter,
                                  heightFactor: value,
                                  child: child,
                                ),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: color,
                                    borderRadius: BorderRadius.circular(
                                      AppRadius.md,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _labels[i],
                          style: AppTypography.labelSmall.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
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
