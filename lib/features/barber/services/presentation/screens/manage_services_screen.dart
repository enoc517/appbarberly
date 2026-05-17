import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../../shared/motion/app_motion.dart';
import '../../../../../shared/theme/app_theme.dart';
import '../../domain/entities/barber_service.dart';
import '../cubit/barber_services_cubit.dart';
import '../cubit/barber_services_state.dart';

class ManageServicesScreen extends StatelessWidget {
  final String barbershopId;
  final String barberId;

  const ManageServicesScreen({
    super.key,
    required this.barbershopId,
    required this.barberId,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: context.read<BarberServicesCubit>()..load(barbershopId, barberId),
      child: const _ManageServicesView(),
    );
  }
}

class _ManageServicesView extends StatelessWidget {
  const _ManageServicesView();

  @override
  Widget build(BuildContext context) {
    return BlocListener<BarberServicesCubit, BarberServicesState>(
      listenWhen: (prev, curr) =>
          curr is BarberServiceAdded ||
          curr is BarberServiceUpdated ||
          curr is BarberServiceDeleted ||
          curr is BarberServicesError,
      listener: (context, state) {
        if (state is BarberServiceAdded) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Servicio agregado')),
          );
          context.read<BarberServicesCubit>().reload();
        } else if (state is BarberServiceUpdated) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Servicio actualizado')),
          );
          context.read<BarberServicesCubit>().reload();
        } else if (state is BarberServiceDeleted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Servicio eliminado')),
          );
          context.read<BarberServicesCubit>().reload();
        } else if (state is BarberServicesError) {
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
            'Mis servicios',
            style: AppTypography.titleLarge.copyWith(
              color: AppColors.onSurface,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => _showServiceDialog(context),
          backgroundColor: AppColors.primaryContainer,
          child: const Icon(Icons.add_rounded, color: AppColors.onPrimary),
        ),
        body: BlocBuilder<BarberServicesCubit, BarberServicesState>(
          builder: (context, state) {
            if (state is BarberServicesLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state is BarberServicesLoaded) {
              if (state.services.isEmpty) {
                return Center(
                  child: AppFadeSlideIn(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.spa_rounded, size: 64, color: AppColors.outline),
                        const SizedBox(height: 16),
                        Text(
                          'No tienes servicios',
                          style: AppTypography.titleMedium.copyWith(
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Presiona + para agregar',
                          style: AppTypography.bodyMedium.copyWith(
                            color: AppColors.outline,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }
              return ListView.builder(
                padding: const EdgeInsets.all(20),
                itemCount: state.services.length,
                itemBuilder: (context, index) {
                  final svc = state.services[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      title: Text(
                        svc.name,
                        style: AppTypography.titleMedium.copyWith(
                          color: AppColors.onSurface,
                        ),
                      ),
                      subtitle: Text(
                        '${svc.category} — ₡${svc.price.toStringAsFixed(0)} — ${svc.durationMinutes}min',
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                      trailing: PopupMenuButton<String>(
                        onSelected: (action) {
                          if (action == 'edit') {
                            _showServiceDialog(context, service: svc);
                          } else if (action == 'delete') {
                            context.read<BarberServicesCubit>().deleteService(svc.id);
                          }
                        },
                        itemBuilder: (_) => const [
                          PopupMenuItem(value: 'edit', child: Text('Editar')),
                          PopupMenuItem(value: 'delete', child: Text('Eliminar')),
                        ],
                      ),
                    ),
                  );
                },
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  void _showServiceDialog(BuildContext context, {BarberService? service}) {
    showDialog(
      context: context,
      builder: (ctx) => _ServiceFormDialog(service: service),
    );
  }
}

class _ServiceFormDialog extends StatefulWidget {
  final BarberService? service;
  const _ServiceFormDialog({this.service});

  @override
  State<_ServiceFormDialog> createState() => _ServiceFormDialogState();
}

class _ServiceFormDialogState extends State<_ServiceFormDialog> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _descCtrl;
  late final TextEditingController _priceCtrl;
  late final TextEditingController _durationCtrl;
  late String _category;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.service?.name ?? '');
    _descCtrl = TextEditingController(text: widget.service?.description ?? '');
    _priceCtrl = TextEditingController(
      text: widget.service != null ? widget.service!.price.toString() : '',
    );
    _durationCtrl = TextEditingController(
      text: widget.service != null ? widget.service!.durationMinutes.toString() : '',
    );
    _category = widget.service?.category ?? 'corte';
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _priceCtrl.dispose();
    _durationCtrl.dispose();
    super.dispose();
  }

  void _save() {
    final cubit = context.read<BarberServicesCubit>();
    final price = double.tryParse(_priceCtrl.text) ?? 0;
    final duration = int.tryParse(_durationCtrl.text) ?? 30;

    if (widget.service == null) {
      cubit.addService(
        name: _nameCtrl.text,
        description: _descCtrl.text,
        price: price,
        durationMinutes: duration,
        category: _category,
      );
    } else {
      cubit.updateService(
        serviceId: widget.service!.id,
        name: _nameCtrl.text,
        description: _descCtrl.text,
        price: price,
        durationMinutes: duration,
        category: _category,
      );
    }
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.service == null ? 'Nuevo servicio' : 'Editar servicio'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameCtrl,
              decoration: const InputDecoration(labelText: 'Nombre'),
            ),
            TextField(
              controller: _descCtrl,
              decoration: const InputDecoration(labelText: 'Descripción'),
              maxLines: 2,
            ),
            TextField(
              controller: _priceCtrl,
              decoration: const InputDecoration(labelText: 'Precio (CRC)'),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: _durationCtrl,
              decoration: const InputDecoration(labelText: 'Duración (min)'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _category,
              decoration: const InputDecoration(labelText: 'Categoría'),
              items: const [
                DropdownMenuItem(value: 'corte', child: Text('Corte')),
                DropdownMenuItem(value: 'barba', child: Text('Barba')),
                DropdownMenuItem(value: 'combo', child: Text('Combo')),
                DropdownMenuItem(value: 'tratamiento', child: Text('Tratamiento')),
              ],
              onChanged: (v) {
                if (v != null) setState(() => _category = v);
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _save,
          child: const Text('Guardar'),
        ),
      ],
    );
  }
}
