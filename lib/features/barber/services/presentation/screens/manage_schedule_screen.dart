import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../../shared/theme/app_theme.dart';
import '../../domain/entities/barber_schedule.dart';
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
          curr is BarberScheduleSaved || curr is BarberScheduleError,
      listener: (context, state) {
        if (state is BarberScheduleSaved) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Horario guardado')),
          );
        }
        if (state is BarberScheduleError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message)),
          );
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
          actions: [
            TextButton(
              onPressed: () => context.read<BarberScheduleCubit>().saveAll(),
              child: const Text('Guardar'),
            ),
          ],
        ),
        body: BlocBuilder<BarberScheduleCubit, BarberScheduleState>(
          builder: (context, state) {
            if (state is BarberScheduleLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            return const _ScheduleList();
          },
        ),
      ),
    );
  }
}

class _TextControllers {
  final TextEditingController startCtrl;
  final TextEditingController endCtrl;
  _TextControllers({required this.startCtrl, required this.endCtrl});
}

class _ScheduleList extends StatefulWidget {
  const _ScheduleList();

  @override
  State<_ScheduleList> createState() => _ScheduleListState();
}

class _ScheduleListState extends State<_ScheduleList> {
  final _controllers = List.generate(
    7,
    (_) => _TextControllers(startCtrl: TextEditingController(), endCtrl: TextEditingController()),
  );
  final _enabled = List<bool>.filled(7, false);
  bool _initialized = false;

  static const _dayNames = [
    'Lunes',
    'Martes',
    'Miércoles',
    'Jueves',
    'Viernes',
    'Sábado',
    'Domingo',
  ];

  @override
  void dispose() {
    for (final c in _controllers) {
      c.startCtrl.dispose();
      c.endCtrl.dispose();
    }
    super.dispose();
  }

  void _initializeFromState(List<BarberSchedule> schedule) {
    if (_initialized) return;
    _initialized = true;
    for (final s in schedule) {
      final i = s.dayOfWeek - 1;
      if (i >= 0 && i < 7) {
        _enabled[i] = s.isActive;
        _controllers[i].startCtrl.text = s.startTime;
        _controllers[i].endCtrl.text = s.endTime;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BarberScheduleCubit, BarberScheduleState>(
      builder: (context, state) {
        if (state is BarberScheduleLoaded) {
          _initializeFromState(state.schedule);
        }

        return ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: 7,
          itemBuilder: (context, index) {
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            _dayNames[index],
                            style: AppTypography.titleMedium.copyWith(
                              color: AppColors.onSurface,
                            ),
                          ),
                        ),
                        Switch(
                          value: _enabled[index],
                          onChanged: (v) {
                            setState(() => _enabled[index] = v);
                            context.read<BarberScheduleCubit>().updateDay(
                              index + 1,
                              isActive: v,
                            );
                          },
                          activeThumbColor: AppColors.secondary,
                        ),
                      ],
                    ),
                    if (_enabled[index]) ...[
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _controllers[index].startCtrl,
                              decoration: const InputDecoration(
                                labelText: 'Inicio',
                                hintText: '08:00',
                              ),
                              onChanged: (v) => context.read<BarberScheduleCubit>().updateDay(
                                index + 1,
                                startTime: v,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextField(
                              controller: _controllers[index].endCtrl,
                              decoration: const InputDecoration(
                                labelText: 'Fin',
                                hintText: '18:00',
                              ),
                              onChanged: (v) => context.read<BarberScheduleCubit>().updateDay(
                                index + 1,
                                endTime: v,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
