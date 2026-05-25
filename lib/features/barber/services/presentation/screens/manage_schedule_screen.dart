import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../../shared/theme/app_theme.dart';
import '../../../../../shared/widgets/app_toast.dart';

import '../cubit/barber_schedule_cubit.dart';
import '../cubit/barber_schedule_state.dart';

class ManageScheduleScreen extends StatelessWidget {
  final String barbershopId;
  final String barberId;

  const ManageScheduleScreen({
    super.key,
    required this.barbershopId,
    required this.barberId,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: context.read<BarberScheduleCubit>()..load(barbershopId, barberId),
      child: const _ManageScheduleView(),
    );
  }
}

class _ManageScheduleView extends StatelessWidget {
  const _ManageScheduleView();

  @override
  Widget build(BuildContext context) {
    return BlocListener<BarberScheduleCubit, BarberScheduleState>(
      listenWhen: (prev, curr) =>
          curr is BarberScheduleDaysSaved || curr is BarberScheduleError,
      listener: (context, state) {
        if (state is BarberScheduleDaysSaved) {
          final label = _daysLabel(state.daysSaved);
          AppToast.success(context, 'Horario de $label actualizado');
        }
        if (state is BarberScheduleError) {
          AppToast.error(context, state.message);
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => context.pop(),
          ),
          title: Text(
            'Mi horario',
            style: AppTypography.titleLarge.copyWith(
              color: AppColors.onSurface,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        body: BlocBuilder<BarberScheduleCubit, BarberScheduleState>(
          builder: (context, state) {
            if (state is BarberScheduleLoading) {
              return const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              );
            }
            if (state is BarberScheduleLoaded) {
              return const _ScheduleContent();
            }
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  String _daysLabel(List<int> days) {
    final names = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];
    final selected = days.map((d) => names[d - 1]).toList();
    if (selected.length == 1) return selected.first;
    if (selected.length == 2) return '${selected[0]} y ${selected[1]}';
    if (selected.length <= 5) {
      final copy = List<String>.from(selected);
      final last = copy.removeLast();
      return '${copy.join(', ')} y $last';
    }
    return '${selected.length} días';
  }
}

class _ScheduleContent extends StatelessWidget {
  const _ScheduleContent();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _DaySelector(),
          const SizedBox(height: 24),
          const _TimeForm(),
          const SizedBox(height: 28),
          const _ApplyButton(),
          const SizedBox(height: 32),
          const _SchedulePreview(),
        ],
      ),
    );
  }
}

class _DaySelector extends StatelessWidget {
  const _DaySelector();

  static const _dayInitials = ['L', 'M', 'X', 'J', 'V', 'S', 'D'];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Días',
          style: AppTypography.labelLarge.copyWith(
            color: AppColors.onSurfaceVariant,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(7, (index) {
            final day = index + 1;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: _DayChip(day: day, label: _dayInitials[index]),
            );
          }),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _PresetButton(
              label: 'Todos',
              onPressed: () =>
                  context.read<BarberScheduleCubit>().selectPreset([1, 2, 3, 4, 5, 6, 7]),
            ),
            const SizedBox(width: 8),
            _PresetButton(
              label: 'Semana',
              onPressed: () =>
                  context.read<BarberScheduleCubit>().selectPreset([1, 2, 3, 4, 5]),
            ),
            const SizedBox(width: 8),
            _PresetButton(
              label: 'Finde',
              onPressed: () => context.read<BarberScheduleCubit>().selectPreset([6, 7]),
            ),
          ],
        ),
      ],
    );
  }
}

class _DayChip extends StatelessWidget {
  final int day;
  final String label;
  const _DayChip({required this.day, required this.label});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BarberScheduleCubit, BarberScheduleState>(
      buildWhen: (prev, curr) =>
          curr is BarberScheduleLoaded &&
          (prev is! BarberScheduleLoaded ||
              prev.selectedDays != curr.selectedDays),
      builder: (context, state) {
        final selected =
            state is BarberScheduleLoaded && state.selectedDays.contains(day);

        return GestureDetector(
          onTap: () => context.read<BarberScheduleCubit>().toggleDay(day),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: selected ? AppColors.secondary : AppColors.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(
                color: selected ? AppColors.secondary : Colors.transparent,
                width: 2,
              ),
            ),
            child: Center(
              child: Text(
                label,
                style: AppTypography.labelLarge.copyWith(
                  color: selected ? Colors.white : AppColors.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _PresetButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  const _PresetButton({required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        backgroundColor: AppColors.surfaceContainerHighest,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.full)),
      ),
      child: Text(
        label,
        style: AppTypography.labelMedium.copyWith(
          color: AppColors.onSurfaceVariant,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _TimeForm extends StatelessWidget {
  const _TimeForm();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BarberScheduleCubit, BarberScheduleState>(
      buildWhen: (prev, curr) =>
          curr is BarberScheduleLoaded &&
          (prev is! BarberScheduleLoaded ||
              prev.pendingStartTime != curr.pendingStartTime ||
              prev.pendingEndTime != curr.pendingEndTime),
      builder: (context, state) {
        if (state is! BarberScheduleLoaded) return const SizedBox.shrink();

        final pendingStart = state.pendingStartTime;
        final pendingEnd = state.pendingEndTime;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _TimeField(
              label: 'Apertura',
              value: pendingStart ?? '',
              onTap: () => _showTimePicker(context, isStart: true),
            ),
            const SizedBox(height: 12),
            _TimeField(
              label: 'Cierre',
              value: pendingEnd ?? '',
              onTap: () => _showTimePicker(context, isStart: false),
            ),
            if (pendingStart != null && pendingEnd != null) ...[
              if (!_isValid(pendingStart, pendingEnd))
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    'La hora de cierre debe ser posterior a la de apertura',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.secondary,
                    ),
                  ),
                ),
            ],
          ],
        );
      },
    );
  }

  bool _isValid(String start, String end) {
    return _toMinutes(end) > _toMinutes(start);
  }

  int _toMinutes(String time12h) {
    final clean = time12h.trim().toUpperCase();
    final isPM = clean.contains('PM');
    final parts = clean.replaceAll(RegExp(r'[APM\s]'), '').split(':');
    var hour = int.tryParse(parts[0]) ?? 0;
    final minute = parts.length > 1 ? (int.tryParse(parts[1]) ?? 0) : 0;
    if (isPM && hour != 12) hour += 12;
    if (!isPM && hour == 12) hour = 0;
    return hour * 60 + minute;
  }

  void _showTimePicker(BuildContext context, {required bool isStart}) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _TimePickerSheet(
        isStart: isStart,
        onSelected: (time12h) {
          final cubit = context.read<BarberScheduleCubit>();
          if (isStart) {
            cubit.setPendingTimes(time12h, cubit.pendingEndTime);
          } else {
            cubit.setPendingTimes(cubit.pendingStartTime, time12h);
          }
          Navigator.pop(ctx);
        },
      ),
    );
  }
}

class _TimeField extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback onTap;
  const _TimeField({required this.label, required this.value, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTypography.labelLarge.copyWith(
            color: AppColors.onSurfaceVariant,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 8),
        Material(
          color: AppColors.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(AppRadius.xl),
          child: InkWell(
            borderRadius: BorderRadius.circular(AppRadius.xl),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
              child: Row(
                children: [
                  Icon(Icons.access_time_rounded, color: AppColors.outline, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      value.isEmpty ? 'Seleccionar' : value,
                      style: AppTypography.bodyLarge.copyWith(
                        color: value.isEmpty ? AppColors.outline : AppColors.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Icon(Icons.unfold_more_rounded, color: AppColors.onSurfaceVariant, size: 20),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ApplyButton extends StatelessWidget {
  const _ApplyButton();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BarberScheduleCubit, BarberScheduleState>(
      buildWhen: (prev, curr) =>
          curr is BarberScheduleLoaded &&
          (prev is! BarberScheduleLoaded ||
              prev.selectedDays != curr.selectedDays ||
              prev.pendingStartTime != curr.pendingStartTime ||
              prev.pendingEndTime != curr.pendingEndTime ||
              prev.schedule.length != curr.schedule.length),
      builder: (context, state) {
        if (state is! BarberScheduleLoaded) return const SizedBox.shrink();
        final selectedCount = state.selectedDays.length;
        final startTime = state.pendingStartTime;
        final endTime = state.pendingEndTime;
        final canApply = selectedCount > 0 &&
            startTime != null &&
            endTime != null &&
            _isValid(startTime, endTime);

        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: double.infinity,
          height: 56,
          child: FilledButton(
            onPressed: canApply
                ? () => context.read<BarberScheduleCubit>().saveDays()
                : null,
            style: FilledButton.styleFrom(
              backgroundColor:
                  canApply ? AppColors.primary : AppColors.surfaceContainerHighest,
              foregroundColor: canApply ? AppColors.onPrimary : AppColors.outline,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.xl)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.check_rounded,
                  size: 22,
                  color: canApply ? AppColors.onPrimary : AppColors.outline,
                ),
                const SizedBox(width: 8),
                Text(
                  selectedCount > 0
                      ? 'Aplicar a $selectedCount ${selectedCount == 1 ? 'día' : 'días'}'
                      : 'Seleccioná los días',
                  style: AppTypography.labelLarge.copyWith(
                    color: canApply ? AppColors.onPrimary : AppColors.outline,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  bool _isValid(String start, String end) {
    return _toMinutes(end) > _toMinutes(start);
  }

  int _toMinutes(String time12h) {
    final clean = time12h.trim().toUpperCase();
    final isPM = clean.contains('PM');
    final parts = clean.replaceAll(RegExp(r'[APM\s]'), '').split(':');
    var hour = int.tryParse(parts[0]) ?? 0;
    final minute = parts.length > 1 ? (int.tryParse(parts[1]) ?? 0) : 0;
    if (isPM && hour != 12) hour += 12;
    if (!isPM && hour == 12) hour = 0;
    return hour * 60 + minute;
  }
}

class _SchedulePreview extends StatelessWidget {
  const _SchedulePreview();

  static const _dayInitials = ['L', 'M', 'X', 'J', 'V', 'S', 'D'];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Mi horario',
          style: AppTypography.labelLarge.copyWith(
            color: AppColors.onSurfaceVariant,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 12),
        BlocBuilder<BarberScheduleCubit, BarberScheduleState>(
          builder: (context, state) {
            if (state is! BarberScheduleLoaded) return const SizedBox.shrink();

            return Container(
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(AppRadius.xl),
              ),
              child: Column(
                children: List.generate(7, (index) {
                  final day = index + 1;
                  final schedule = state.schedule[day];
                  final isActive = schedule?.isActive ?? false;
                  final start = schedule?.startTime ?? '';
                  final end = schedule?.endTime ?? '';

                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      border: index < 6
                          ? Border(
                              bottom: BorderSide(
                                color: AppColors.outline.withValues(alpha: 0.1),
                              ),
                            )
                          : null,
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: isActive
                                ? AppColors.primary.withValues(alpha: 0.12)
                                : AppColors.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(AppRadius.sm),
                          ),
                          child: Center(
                            child: Text(
                              _dayInitials[index],
                              style: AppTypography.labelMedium.copyWith(
                                color: isActive ? AppColors.primary : AppColors.onSurfaceVariant,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            isActive ? _formatSchedule(start, end) : 'Día libre',
                            style: AppTypography.bodyMedium.copyWith(
                              color: isActive ? AppColors.onSurface : AppColors.outline,
                              fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                            ),
                          ),
                        ),
                        Icon(
                          isActive ? Icons.check_circle_rounded : Icons.circle_outlined,
                          color: isActive ? AppColors.primary : AppColors.outline.withValues(alpha: 0.4),
                          size: 18,
                        ),
                      ],
                    ),
                  );
                }),
              ),
            );
          },
        ),
      ],
    );
  }

  String _formatSchedule(String start24, String end24) {
    if (start24.isEmpty || end24.isEmpty) return '—';
    return '${_to12h(start24)} – ${_to12h(end24)}';
  }

  String _to12h(String time24) {
    if (time24.isEmpty) return '—';
    final parts = time24.split(':');
    var hour = int.tryParse(parts[0]) ?? 0;
    final minute = parts.length > 1 ? (int.tryParse(parts[1]) ?? 0) : 0;
    final isPM = hour >= 12;
    if (hour == 0) hour = 12;
    if (hour > 12) hour -= 12;
    final minStr = minute == 0 ? '00' : minute.toString().padLeft(2, '0');
    return '$hour:$minStr ${isPM ? 'PM' : 'AM'}';
  }
}

class _TimePickerSheet extends StatefulWidget {
  final bool isStart;
  final ValueChanged<String> onSelected;

  const _TimePickerSheet({required this.isStart, required this.onSelected});

  @override
  State<_TimePickerSheet> createState() => _TimePickerSheetState();
}

class _TimePickerSheetState extends State<_TimePickerSheet> {
  late DateTime _selectedTime;

  @override
  void initState() {
    super.initState();
    _selectedTime = DateTime(2024, 1, 1, 9, 0);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
            child: Column(
              children: [
                Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.outline.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  widget.isStart ? 'Hora de apertura' : 'Hora de cierre',
                  style: AppTypography.titleMedium.copyWith(
                    color: AppColors.onSurface,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 200,
            child: CupertinoDatePicker(
              mode: CupertinoDatePickerMode.time,
              use24hFormat: false,
              initialDateTime: _selectedTime,
              onDateTimeChanged: (DateTime newTime) {
                _selectedTime = newTime;
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 28),
            child: Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.xl)),
                    ),
                    child: Text(
                      'Cancelar',
                      style: AppTypography.labelLarge.copyWith(color: AppColors.onSurfaceVariant),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: () {
                      final hour = _selectedTime.hour;
                      final minute = _selectedTime.minute;
                      final isPM = hour >= 12;
                      var displayHour = hour;
                      if (hour == 0) displayHour = 12;
                      if (hour > 12) displayHour = hour - 12;

                      final time12h =
                          '${displayHour.toString()}:${minute.toString().padLeft(2, '0')} ${isPM ? 'PM' : 'AM'}';
                      widget.onSelected(time12h);
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.onPrimary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.xl)),
                    ),
                    child: Text(
                      'Aceptar',
                      style: AppTypography.labelLarge.copyWith(
                        color: AppColors.onPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
