import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';

import '../../../../../shared/motion/app_motion.dart';
import '../../../../../shared/theme/app_theme.dart';
import '../../domain/repositories/barbershop_management_repository.dart';
import '../cubit/barbershop_management_cubit.dart';
import '../cubit/barbershop_management_state.dart';
import '../utils/barbershop_form_validator.dart';
import '../widgets/location_picker.dart';

class CreateBarbershopScreen extends StatefulWidget {
  final String userId;
  final String userName;

  const CreateBarbershopScreen({
    super.key,
    required this.userId,
    required this.userName,
  });

  @override
  State<CreateBarbershopScreen> createState() => _CreateBarbershopScreenState();
}

class _CreateBarbershopScreenState extends State<CreateBarbershopScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _imageUrlController = TextEditingController();

  double _selectedLat = 8.6135;
  double _selectedLng = -82.9585;

  final List<String> _tags = [];
  String _currentTag = '';

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  void _addTag(String tag) {
    final trimmed = tag.trim();
    if (trimmed.isNotEmpty && !_tags.contains(trimmed)) {
      setState(() {
        _tags.add(trimmed);
        _currentTag = '';
      });
    }
  }

  void _removeTag(String tag) {
    setState(() => _tags.remove(tag));
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_tags.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Agrega al menos una etiqueta')),
      );
      return;
    }

    FocusScope.of(context).unfocus();

    final params = CreateBarbershopParams(
      ownerId: widget.userId,
      ownerName: widget.userName,
      name: _nameController.text.trim(),
      phone: _phoneController.text.trim(),
      address: _addressController.text.trim(),
      lat: _selectedLat,
      lng: _selectedLng,
      imageUrl: _imageUrlController.text.trim(),
      tags: List<String>.from(_tags),
    );

    context.read<BarbershopManagementCubit>().create(params);
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<BarbershopManagementCubit, BarbershopManagementState>(
      listener: (context, state) {
        if (state is BarbershopCreated) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Barbería creada exitosamente')),
          );
          context.go('/panel');
        }
        if (state is BarbershopManagementError) {
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
            'Crear barbería',
            style: AppTypography.titleLarge.copyWith(
              color: AppColors.onSurface,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 640),
                child: AppFadeSlideIn(
                  child: _FormCard(
                    formKey: _formKey,
                    nameController: _nameController,
                    phoneController: _phoneController,
                    addressController: _addressController,
                    imageUrlController: _imageUrlController,
                    selectedLat: _selectedLat,
                    selectedLng: _selectedLng,
                    tags: _tags,
                    currentTag: _currentTag,
                    onSubmit: _submit,
                    onAddTag: _addTag,
                    onRemoveTag: _removeTag,
                    onCurrentTagChanged: (value) {
                      setState(() => _currentTag = value);
                    },
                    onLocationSelected: (location) {
                      setState(() {
                        _selectedLat = location.latitude;
                        _selectedLng = location.longitude;
                      });
                    },
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FormCard extends StatelessWidget {
  const _FormCard({
    required this.formKey,
    required this.nameController,
    required this.phoneController,
    required this.addressController,
    required this.imageUrlController,
    required this.selectedLat,
    required this.selectedLng,
    required this.tags,
    required this.currentTag,
    required this.onSubmit,
    required this.onAddTag,
    required this.onRemoveTag,
    required this.onCurrentTagChanged,
    required this.onLocationSelected,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController nameController;
  final TextEditingController phoneController;
  final TextEditingController addressController;
  final TextEditingController imageUrlController;
  final double selectedLat;
  final double selectedLng;
  final List<String> tags;
  final String currentTag;
  final VoidCallback onSubmit;
  final ValueChanged<String> onAddTag;
  final ValueChanged<String> onRemoveTag;
  final ValueChanged<String> onCurrentTagChanged;
  final ValueChanged<LatLng> onLocationSelected;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BarbershopManagementCubit, BarbershopManagementState>(
      buildWhen: (prev, curr) => curr is BarbershopManagementLoading,
      builder: (context, state) {
        final isSubmitting = state is BarbershopManagementLoading;

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(32),
            boxShadow: [
              BoxShadow(
                color: AppColors.ambientShadow,
                blurRadius: 32,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Form(
            key: formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _SectionTitle(text: 'Información general'),
                const SizedBox(height: 20),
                const _FieldLabel(text: 'Nombre de la barbería'),
                const SizedBox(height: 8),
                _TextField(
                  controller: nameController,
                  hintText: 'Ej. Imperio Barbershop',
                  prefixIcon: Icons.storefront_rounded,
                  validator: BarbershopFormValidator.validateName,
                ),
                const SizedBox(height: 18),
                const _FieldLabel(text: 'Teléfono'),
                const SizedBox(height: 8),
                _TextField(
                  controller: phoneController,
                  hintText: '+506 8000 0000',
                  keyboardType: TextInputType.phone,
                  prefixIcon: Icons.phone_rounded,
                  validator: BarbershopFormValidator.validatePhone,
                ),
                const SizedBox(height: 18),
                const _FieldLabel(text: 'Dirección'),
                const SizedBox(height: 8),
                _TextField(
                  controller: addressController,
                  hintText: 'Av. Central, Ciudad Neily',
                  prefixIcon: Icons.location_on_rounded,
                  maxLines: 2,
                  validator: BarbershopFormValidator.validateAddress,
                ),
                const SizedBox(height: 18),
                const _FieldLabel(text: 'URL de la imagen'),
                const SizedBox(height: 8),
                _TextField(
                  controller: imageUrlController,
                  hintText: 'https://...',
                  prefixIcon: Icons.image_rounded,
                  keyboardType: TextInputType.url,
                ),
                const SizedBox(height: 28),
                LocationPicker(
                  initialLocation: LatLng(selectedLat, selectedLng),
                  onLocationSelected: onLocationSelected,
                ),
                const SizedBox(height: 28),
                const _SectionTitle(text: 'Etiquetas'),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: _TextField(
                        hintText: 'Ej. fade, barba, clásico',
                        prefixIcon: Icons.label_rounded,
                        onSubmitted: onAddTag,
                        onChanged: onCurrentTagChanged,
                      ),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      height: 52,
                      child: ElevatedButton(
                        onPressed: () => onAddTag(currentTag),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryContainer,
                          foregroundColor: AppColors.onPrimary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppRadius.xl),
                          ),
                        ),
                        child: const Text('Agregar'),
                      ),
                    ),
                  ],
                ),
                if (tags.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: tags.map((tag) {
                      return Chip(
                        label: Text(
                          tag,
                          style: AppTypography.labelMedium.copyWith(
                            color: AppColors.onPrimary,
                          ),
                        ),
                        backgroundColor: AppColors.primaryContainer,
                        deleteIcon: Icon(
                          Icons.close_rounded,
                          size: 16,
                          color: AppColors.onPrimary.withValues(alpha: 0.8),
                        ),
                        onDeleted: () => onRemoveTag(tag),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.full),
                        ),
                        side: BorderSide.none,
                      );
                    }).toList(),
                  ),
                ],
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: isSubmitting ? null : onSubmit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryContainer,
                      foregroundColor: AppColors.onPrimary,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.xl),
                      ),
                    ),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: isSubmitting
                          ? Row(
                              key: const ValueKey('loading'),
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppColors.onPrimary,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                const Text(
                                  'Creando barbería...',
                                  style: TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            )
                          : const Row(
                              key: ValueKey('idle'),
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Crear barbería',
                                  style: TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                SizedBox(width: 10),
                                Icon(Icons.add_rounded, size: 22),
                              ],
                            ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: AppTypography.titleLarge.copyWith(
        color: AppColors.onSurface,
        fontWeight: FontWeight.w800,
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: AppTypography.labelLarge.copyWith(
        color: AppColors.onSurfaceVariant,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.1,
      ),
    );
  }
}

class _TextField extends StatelessWidget {
  const _TextField({
    required this.hintText,
    required this.prefixIcon,
    this.controller,
    this.keyboardType,
    this.validator,
    this.maxLines = 1,
    this.onSubmitted,
    this.onChanged,
  });

  final TextEditingController? controller;
  final String hintText;
  final IconData prefixIcon;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final int maxLines;
  final ValueChanged<String>? onSubmitted;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: false,
      keyboardType: keyboardType,
      validator: validator,
      maxLines: maxLines,
      onFieldSubmitted: onSubmitted,
      onChanged: onChanged,
      style: AppTypography.bodyLarge.copyWith(
        color: AppColors.onSurface,
        fontWeight: FontWeight.w600,
      ),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: AppTypography.bodyLarge.copyWith(
          color: AppColors.outline,
          fontWeight: FontWeight.w500,
        ),
        filled: true,
        fillColor: AppColors.surfaceContainerHighest,
        prefixIcon: Icon(prefixIcon, color: AppColors.outline),
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
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
          borderSide: BorderSide.none,
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.xl),
          borderSide: BorderSide.none,
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.xl),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
