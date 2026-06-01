import 'package:flutter/material.dart';
import '../../../../../shared/theme/app_theme.dart';
import '../../../../../shared/widgets/dotted_border_container.dart';
import '../../domain/entities/time_slot.dart';

class TimeSlotGrid extends StatelessWidget {
  final List<TimeSlot> slots;
  final TimeSlot? selected;
  final ValueChanged<TimeSlot> onSelect;
  final VoidCallback onJoinWaitlist;

  const TimeSlotGrid({
    super.key,
    required this.slots,
    required this.selected,
    required this.onSelect,
    required this.onJoinWaitlist,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: slots.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 3.2,
      ),
      itemBuilder: (_, i) {
        final slot = slots[i];
        if (slot.isWaitlist) {
          return DottedBorderContainer(
            onTap: onJoinWaitlist,
            child: Container(
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                'Unirse a lista de espera',
                style: AppTypography.labelMedium.copyWith(
                  color: theme.colorScheme.secondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          );
        }
        return _SlotChip(
          slot: slot,
          selected: selected == slot,
          onTap: () => onSelect(slot),
        );
      },
    );
  }
}

class _SlotChip extends StatelessWidget {
  final TimeSlot slot;
  final bool selected;
  final VoidCallback onTap;

  const _SlotChip({
    required this.slot,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final enabled = slot.isAvailable;
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? theme.colorScheme.primary : theme.colorScheme.surfaceContainer,
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        child: Text(
          _formatTime(slot.startTime),
          style: AppTypography.labelLarge.copyWith(
            color: !enabled
                ? theme.colorScheme.outline
                : selected
                    ? theme.colorScheme.onPrimary
                    : theme.colorScheme.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime t) {
    final h = t.hour > 12 ? t.hour - 12 : (t.hour == 0 ? 12 : t.hour);
    final ampm = t.hour >= 12 ? 'PM' : 'AM';
    final mm = t.minute.toString().padLeft(2, '0');
    return '${h.toString().padLeft(2, '0')}:$mm $ampm';
  }
}