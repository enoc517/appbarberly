import 'package:flutter/material.dart';
import '../../../../../shared/theme/app_theme.dart';

class DaySelector extends StatelessWidget {
  final List<DateTime> days;
  final DateTime selected;
  final ValueChanged<DateTime> onSelect;

  const DaySelector({
    super.key,
    required this.days,
    required this.selected,
    required this.onSelect,
  });

  static const _weekdayAbbr = ['LUN', 'MAR', 'MIE', 'JUE', 'VIE', 'SAB', 'DOM'];

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(days.length, (i) {
        final d = days[i];
        final isSel = _isSameDay(d, selected);
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: i == days.length - 1 ? 0 : 8),
            child: GestureDetector(
              onTap: () => onSelect(d),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color:
                      isSel ? AppColors.primary : AppColors.surfaceContainer,
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                ),
                child: Column(
                  children: [
                    Text(
                      _weekdayAbbr[d.weekday - 1],
                      style: AppTypography.labelSmall.copyWith(
                        color: isSel
                            ? AppColors.onPrimary
                            : AppColors.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      d.day.toString(),
                      style: AppTypography.titleMedium.copyWith(
                        color: isSel
                            ? AppColors.onPrimary
                            : AppColors.onSurface,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }),
    );
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}