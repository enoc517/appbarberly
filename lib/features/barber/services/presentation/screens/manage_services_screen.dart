import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../../shared/motion/app_motion.dart';
import '../../../../../shared/theme/app_theme.dart';
import '../../../../../shared/widgets/app_toast.dart';
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
          AppToast.success(context, 'Servicio agregado');
          context.read<BarberServicesCubit>().reload();
        } else if (state is BarberServiceUpdated) {
          AppToast.success(context, 'Servicio actualizado');
          context.read<BarberServicesCubit>().reload();
        } else if (state is BarberServiceDeleted) {
          AppToast.info(context, 'Servicio eliminado');
          context.read<BarberServicesCubit>().reload();
        } else if (state is BarberServicesError) {
          AppToast.error(context, state.message);
        }
      },
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => context.pop(),
          ),
          title: Text(
            'Mis servicios',
            style: AppTypography.titleLarge.copyWith(
              color: Theme.of(context).colorScheme.onSurface,
              fontWeight: FontWeight.w700,
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.add_rounded),
              onPressed: () => _showServiceBottomSheet(context),
            ),
          ],
        ),
        body: BlocBuilder<BarberServicesCubit, BarberServicesState>(
          builder: (context, state) {
            if (state is BarberServicesLoading) {
              return Center(
                child: CircularProgressIndicator(
                  color: Theme.of(context).colorScheme.primary,
                ),
              );
            }
            if (state is BarberServicesLoaded) {
              if (state.services.isEmpty) {
                return _EmptyServicesState(
                  onAddPressed: () => _showServiceBottomSheet(context),
                );
              }
              return _ServicesListView(services: state.services);
            }
            return const SizedBox.shrink();
          },
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _showServiceBottomSheet(context),
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Theme.of(context).colorScheme.onPrimary,
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
          icon: const Icon(Icons.add_rounded),
          label: Text(
            'Agregar',
            style: AppTypography.labelLarge.copyWith(
              color: Theme.of(context).colorScheme.onPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }

  void _showServiceBottomSheet(BuildContext context, {BarberService? service}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => BlocProvider.value(
        value: context.read<BarberServicesCubit>(),
        child: _ServiceBottomSheet(service: service),
      ),
    );
  }
}

class _ServicesListView extends StatelessWidget {
  final List<BarberService> services;
  const _ServicesListView({required this.services});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
      itemCount: services.length,
      itemBuilder: (context, index) {
        final svc = services[index];
        return AppFadeSlideIn(
          delay: AppMotion.delay(index + 1),
          child: _ServiceCard(service: svc, index: index),
        );
      },
    );
  }
}

class _ServiceCard extends StatelessWidget {
  final BarberService service;
  final int index;
  const _ServiceCard({required this.service, required this.index});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final categoryStyle = _categoryStyle(service.category, theme);
    final isCombo = service.category == 'combo';

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Dismissible(
        key: Key(service.id),
        direction: DismissDirection.endToStart,
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 24),
          decoration: BoxDecoration(
            color: theme.colorScheme.secondary,
            borderRadius: BorderRadius.circular(AppRadius.xl),
          ),
          child: const Icon(
            Icons.delete_rounded,
            color: Colors.white,
            size: 28,
          ),
        ),
        confirmDismiss: (_) async {
          return await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  backgroundColor: theme.colorScheme.surfaceContainerLowest,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.xl),
                  ),
                  title: Text(
                    'Eliminar servicio',
                    style: AppTypography.titleMedium.copyWith(
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  content: Text(
                    '¿Estás seguro de eliminar "${service.name}"?',
                    style: AppTypography.bodyMedium.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: Text(
                        'Cancelar',
                        style: AppTypography.labelLarge.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      child: Text(
                        'Eliminar',
                        style: AppTypography.labelLarge.copyWith(
                          color: theme.colorScheme.secondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ) ??
              false;
        },
        onDismissed: (_) {
          context.read<BarberServicesCubit>().deleteService(service.id);
        },
        child: Material(
          color: theme.colorScheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(AppRadius.xl),
          elevation: 0,
          child: InkWell(
            borderRadius: BorderRadius.circular(AppRadius.xl),
            onTap: () => _showServiceBottomSheet(context, service: service),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: categoryStyle.bgColor,
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                    ),
                    child: Icon(
                      categoryStyle.icon,
                      color: categoryStyle.iconColor,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                service.name,
                                style: AppTypography.titleMedium.copyWith(
                                  color: theme.colorScheme.onSurface,
                                  fontWeight: FontWeight.w700,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (isCombo)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.secondary.withValues(
                                    alpha: 0.15,
                                  ),
                                  borderRadius: BorderRadius.circular(
                                    AppRadius.full,
                                  ),
                                ),
                                child: Text(
                                  'COMBO',
                                  style: AppTypography.labelSmall.copyWith(
                                    color: theme.colorScheme.secondary,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          service.description.isNotEmpty
                              ? service.description
                              : 'Sin descripción',
                          style: AppTypography.bodySmall.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: categoryStyle.bgColor,
                                borderRadius: BorderRadius.circular(
                                  AppRadius.full,
                                ),
                              ),
                              child: Text(
                                categoryStyle.label,
                                style: AppTypography.labelSmall.copyWith(
                                  color: categoryStyle.iconColor,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            _InfoChip(
                              icon: Icons.schedule_rounded,
                              text: '${service.durationMinutes} min',
                            ),
                            const SizedBox(width: 8),
                            _InfoChip(
                              icon: Icons.attach_money_rounded,
                              text: '₡${service.price.toStringAsFixed(0)}',
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: theme.colorScheme.onSurfaceVariant.withValues(
                      alpha: 0.5,
                    ),
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showServiceBottomSheet(BuildContext context, {BarberService? service}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => BlocProvider.value(
        value: context.read<BarberServicesCubit>(),
        child: _ServiceBottomSheet(service: service),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String text;
  const _InfoChip({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: theme.colorScheme.onSurfaceVariant),
        const SizedBox(width: 3),
        Text(
          text,
          style: AppTypography.labelSmall.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _EmptyServicesState extends StatelessWidget {
  final VoidCallback onAddPressed;
  const _EmptyServicesState({required this.onAddPressed});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer.withValues(
                  alpha: 0.3,
                ),
                borderRadius: BorderRadius.circular(AppRadius.xl),
              ),
              child: Icon(
                Icons.content_cut_rounded,
                size: 40,
                color: theme.colorScheme.primaryContainer,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Sin servicios todavía',
              style: AppTypography.titleLarge.copyWith(
                color: theme.colorScheme.onSurface,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Agregá los servicios que ofrecés para que tus clientes puedan reservar.',
              textAlign: TextAlign.center,
              style: AppTypography.bodyMedium.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: onAddPressed,
              style: FilledButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: theme.colorScheme.onPrimary,
                padding: const EdgeInsets.symmetric(
                  horizontal: 28,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.xl),
                ),
              ),
              icon: const Icon(Icons.add_rounded),
              label: Text(
                'Agregar mi primer servicio',
                style: AppTypography.labelLarge.copyWith(
                  color: theme.colorScheme.onPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ServiceBottomSheet extends StatefulWidget {
  final BarberService? service;
  const _ServiceBottomSheet({this.service});

  @override
  State<_ServiceBottomSheet> createState() => _ServiceBottomSheetState();
}

class _ServiceBottomSheetState extends State<_ServiceBottomSheet> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _descCtrl;
  late final TextEditingController _priceCtrl;
  late final TextEditingController _durationCtrl;
  late String _category;
  bool _isSubmitting = false;

  List<_CategoryOption> _categories(ThemeData theme) => [
    _CategoryOption(
      'corte',
      'Corte',
      Icons.content_cut_rounded,
      theme.colorScheme.primary,
    ),
    _CategoryOption(
      'barba',
      'Barba',
      Icons.face_rounded,
      theme.colorScheme.secondary,
    ),
    _CategoryOption(
      'combo',
      'Combo',
      Icons.star_rounded,
      const Color(0xFFFF8C00),
    ),
    _CategoryOption(
      'tratamiento',
      'Tratamiento',
      Icons.spa_rounded,
      const Color(0xFF00A693),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.service?.name ?? '');
    _descCtrl = TextEditingController(text: widget.service?.description ?? '');
    _priceCtrl = TextEditingController(
      text: widget.service != null ? widget.service!.price.toString() : '',
    );
    _durationCtrl = TextEditingController(
      text: widget.service != null
          ? widget.service!.durationMinutes.toString()
          : kDefaultServiceDurationMinutes.toString(),
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

  void _save(BuildContext ctx) {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      AppToast.error(ctx, 'El nombre es requerido');
      return;
    }

    setState(() => _isSubmitting = true);

    final cubit = ctx.read<BarberServicesCubit>();
    final price = double.tryParse(_priceCtrl.text) ?? 0;
    final duration = int.tryParse(_durationCtrl.text.trim());

    if (duration == null) {
      setState(() => _isSubmitting = false);
      AppToast.error(ctx, 'La duración debe ser un número válido');
      return;
    }

    if (duration < kMinServiceDurationMinutes ||
        duration > kMaxServiceDurationMinutes) {
      setState(() => _isSubmitting = false);
      AppToast.error(
        ctx,
        'La duración debe estar entre $kMinServiceDurationMinutes y $kMaxServiceDurationMinutes minutos',
      );
      return;
    }

    if (widget.service == null) {
      cubit.addService(
        name: name,
        description: _descCtrl.text.trim(),
        price: price,
        durationMinutes: duration,
        category: _category,
      );
    } else {
      cubit.updateService(
        serviceId: widget.service!.id,
        name: name,
        description: _descCtrl.text.trim(),
        price: price,
        durationMinutes: duration,
        category: _category,
      );
    }
    Navigator.pop(ctx);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;
    final categories = _categories(theme);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLowest,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(bottom: bottomPadding),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.outline.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    widget.service == null
                        ? 'Nuevo servicio'
                        : 'Editar servicio',
                    style: AppTypography.titleLarge.copyWith(
                      color: theme.colorScheme.onSurface,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(
                      Icons.close_rounded,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                'Nombre del servicio',
                style: AppTypography.labelLarge.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 8),
              _StyledTextField(
                controller: _nameCtrl,
                hintText: 'Ej. Corte fade clásico',
                prefixIcon: Icons.content_cut_rounded,
              ),
              const SizedBox(height: 16),
              Text(
                'Descripción (opcional)',
                style: AppTypography.labelLarge.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 8),
              _StyledTextField(
                controller: _descCtrl,
                hintText: 'Describe tu servicio...',
                prefixIcon: Icons.notes_rounded,
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Precio (CRC)',
                          style: AppTypography.labelLarge.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.8,
                          ),
                        ),
                        const SizedBox(height: 8),
                        _StyledTextField(
                          controller: _priceCtrl,
                          hintText: '2500',
                          prefixIcon: Icons.attach_money_rounded,
                          keyboardType: TextInputType.number,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Duración (min)',
                          style: AppTypography.labelLarge.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.8,
                          ),
                        ),
                        const SizedBox(height: 8),
                        _StyledTextField(
                          controller: _durationCtrl,
                          hintText: kDefaultServiceDurationMinutes.toString(),
                          prefixIcon: Icons.schedule_rounded,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(3),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                'Categoría',
                style: AppTypography.labelLarge.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: categories.map((cat) {
                  final isSelected = _category == cat.value;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _category = cat.value),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? cat.color.withValues(alpha: 0.15)
                              : theme.colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(AppRadius.lg),
                          border: Border.all(
                            color: isSelected ? cat.color : Colors.transparent,
                            width: 1.5,
                          ),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              cat.icon,
                              color: isSelected
                                  ? cat.color
                                  : theme.colorScheme.onSurfaceVariant,
                              size: 20,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              cat.label,
                              style: AppTypography.labelSmall.copyWith(
                                color: isSelected
                                    ? cat.color
                                    : theme.colorScheme.onSurfaceVariant,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: FilledButton(
                  onPressed: _isSubmitting ? null : () => _save(context),
                  style: FilledButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: theme.colorScheme.onPrimary,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.xl),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        widget.service == null
                            ? Icons.add_rounded
                            : Icons.check_rounded,
                        size: 22,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        widget.service == null
                            ? 'Agregar servicio'
                            : 'Guardar cambios',
                        style: AppTypography.labelLarge.copyWith(
                          color: theme.colorScheme.onPrimary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

class _StyledTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final IconData prefixIcon;
  final TextInputType? keyboardType;
  final int maxLines;
  final List<TextInputFormatter>? inputFormatters;

  const _StyledTextField({
    required this.controller,
    required this.hintText,
    required this.prefixIcon,
    this.keyboardType,
    this.maxLines = 1,
    this.inputFormatters,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      inputFormatters: inputFormatters,
      style: AppTypography.bodyLarge.copyWith(
        color: theme.colorScheme.onSurface,
        fontWeight: FontWeight.w600,
      ),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: AppTypography.bodyLarge.copyWith(
          color: theme.colorScheme.outline,
          fontWeight: FontWeight.w500,
        ),
        filled: true,
        fillColor: theme.colorScheme.surfaceContainerHighest,
        prefixIcon: Icon(
          prefixIcon,
          color: theme.colorScheme.outline,
          size: 20,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.xl),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.xl),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.xl),
          borderSide: BorderSide(color: theme.colorScheme.primary, width: 1.5),
        ),
      ),
    );
  }
}

class _CategoryOption {
  final String value;
  final String label;
  final IconData icon;
  final Color color;
  const _CategoryOption(this.value, this.label, this.icon, this.color);
}

_CategoryStyle _categoryStyle(String category, ThemeData theme) {
  switch (category) {
    case 'corte':
      return _CategoryStyle(
        label: 'Corte',
        icon: Icons.content_cut_rounded,
        bgColor: theme.colorScheme.primary.withValues(alpha: 0.12),
        iconColor: theme.colorScheme.primary,
      );
    case 'barba':
      return _CategoryStyle(
        label: 'Barba',
        icon: Icons.face_rounded,
        bgColor: theme.colorScheme.secondary.withValues(alpha: 0.12),
        iconColor: theme.colorScheme.secondary,
      );
    case 'combo':
      return _CategoryStyle(
        label: 'Combo',
        icon: Icons.star_rounded,
        bgColor: const Color(0xFFFF8C00).withValues(alpha: 0.12),
        iconColor: const Color(0xFFFF8C00),
      );
    case 'tratamiento':
      return _CategoryStyle(
        label: 'Tratamiento',
        icon: Icons.spa_rounded,
        bgColor: const Color(0xFF00A693).withValues(alpha: 0.12),
        iconColor: const Color(0xFF00A693),
      );
    default:
      return _CategoryStyle(
        label: category,
        icon: Icons.content_cut_rounded,
        bgColor: theme.colorScheme.surfaceContainerHighest,
        iconColor: theme.colorScheme.onSurfaceVariant,
      );
  }
}

class _CategoryStyle {
  final String label;
  final IconData icon;
  final Color bgColor;
  final Color iconColor;
  const _CategoryStyle({
    required this.label,
    required this.icon,
    required this.bgColor,
    required this.iconColor,
  });
}
