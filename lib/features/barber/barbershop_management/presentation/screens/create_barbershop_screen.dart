import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';

import '../../../../../core/di/app_dependencies.dart';
import '../../../../../shared/motion/app_motion.dart';
import '../../../../../shared/theme/app_theme.dart';
import '../../../../../shared/widgets/app_toast.dart';
import '../../../../../shared/widgets/image_picker_sheet.dart';
import '../../domain/entities/barbershop.dart';
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
  final _tagController = TextEditingController();

  double _selectedLat = 8.6135;
  double _selectedLng = -82.9585;

  final List<String> _tags = [];
  String _currentTag = '';
  XFile? _selectedImage;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _tagController.dispose();
    super.dispose();
  }

  void _addTag(String tag) {
    final trimmed = tag.trim();
    if (trimmed.isNotEmpty && !_tags.contains(trimmed)) {
      setState(() {
        _tags.add(trimmed);
        _currentTag = '';
        _tagController.clear();
      });
    }
  }

  void _removeTag(String tag) {
    setState(() => _tags.remove(tag));
  }

  Future<void> _pickImage() async {
    final image = await showModalBottomSheet<XFile>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => const ImagePickerSheet(),
    );

    if (image != null) {
      setState(() => _selectedImage = image);
    }
  }

  void _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_tags.isEmpty) {
      AppToast.info(context, 'Agrega al menos una etiqueta');
      return;
    }

    FocusScope.of(context).unfocus();

    String? imageUrl;
    if (_selectedImage != null) {
      try {
        imageUrl = await AppDependencies.cloudinaryDatasource.uploadImage(
          file: File(_selectedImage!.path),
          folder: 'barbershops',
          publicId: '${widget.userId}/barbershop',
        );
      } catch (e) {
        if (mounted) {
          AppToast.error(context, 'Error al subir imagen: ${e.toString()}');
        }
        return;
      }
    }

    final params = CreateBarbershopParams(
      ownerId: widget.userId,
      ownerName: widget.userName,
      name: _nameController.text.trim(),
      phone: _phoneController.text.trim(),
      address: _addressController.text.trim(),
      lat: _selectedLat,
      lng: _selectedLng,
      imageUrl: imageUrl ?? '',
      tags: List<String>.from(_tags),
    );

    if (mounted) {
      context.read<BarbershopManagementCubit>().create(params);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<BarbershopManagementCubit, BarbershopManagementState>(
      listener: (context, state) {
        if (state is BarbershopCreated) {
          AppToast.success(context, 'Barbería creada exitosamente');
          context.pop();
        }
        if (state is BarbershopManagementError) {
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
            'Crear barbería',
            style: AppTypography.titleLarge.copyWith(
              color: Theme.of(context).colorScheme.onSurface,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: EdgeInsets.fromLTRB(
                24,
                28,
                24,
                28 + MediaQuery.viewInsetsOf(context).bottom,
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 640),
                child: AppFadeSlideIn(
                  child: _FormCard(
                    formKey: _formKey,
                    nameController: _nameController,
                    phoneController: _phoneController,
                    addressController: _addressController,
                    tagController: _tagController,
                    selectedLat: _selectedLat,
                    selectedLng: _selectedLng,
                    tags: _tags,
                    currentTag: _currentTag,
                    selectedImage: _selectedImage,
                    existingImageUrl: null,
                    submitLabel: 'Crear barbería',
                    submittingLabel: 'Creando barbería...',
                    submitIcon: Icons.add_rounded,
                    onSubmit: _submit,
                    onAddTag: _addTag,
                    onRemoveTag: _removeTag,
                    onPickImage: _pickImage,
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

class EditBarbershopScreen extends StatefulWidget {
  const EditBarbershopScreen({super.key, required this.userId});

  final String userId;

  @override
  State<EditBarbershopScreen> createState() => _EditBarbershopScreenState();
}

class _EditBarbershopScreenState extends State<EditBarbershopScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _tagController = TextEditingController();

  Barbershop? _barbershop;
  double _selectedLat = 8.6135;
  double _selectedLng = -82.9585;
  final List<String> _tags = [];
  String _currentTag = '';
  XFile? _selectedImage;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<BarbershopManagementCubit>().load(widget.userId);
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _tagController.dispose();
    super.dispose();
  }

  void _populate(Barbershop shop) {
    if (_initialized) return;
    _barbershop = shop;
    _nameController.text = shop.name;
    _phoneController.text = shop.phone;
    _addressController.text = shop.address;
    _selectedLat = shop.lat;
    _selectedLng = shop.lng;
    _tags
      ..clear()
      ..addAll(shop.tags);
    _initialized = true;
  }

  void _addTag(String tag) {
    final trimmed = tag.trim();
    if (trimmed.isNotEmpty && !_tags.contains(trimmed)) {
      setState(() {
        _tags.add(trimmed);
        _currentTag = '';
        _tagController.clear();
      });
    }
  }

  void _removeTag(String tag) {
    setState(() => _tags.remove(tag));
  }

  Future<void> _pickImage() async {
    final image = await showModalBottomSheet<XFile>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => const ImagePickerSheet(),
    );

    if (image != null) {
      setState(() => _selectedImage = image);
    }
  }

  void _submit() async {
    final shop = _barbershop;
    if (shop == null) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_tags.isEmpty) {
      AppToast.info(context, 'Agrega al menos una etiqueta');
      return;
    }

    FocusScope.of(context).unfocus();

    String? imageUrl;
    if (_selectedImage != null) {
      try {
        imageUrl = await AppDependencies.cloudinaryDatasource.uploadImage(
          file: File(_selectedImage!.path),
          folder: 'barbershops',
          publicId: '${widget.userId}/barbershop',
        );
      } catch (e) {
        if (mounted) {
          AppToast.error(context, 'Error al subir imagen: ${e.toString()}');
        }
        return;
      }
    }

    final params = UpdateBarbershopParams(
      id: shop.id,
      name: _nameController.text.trim(),
      phone: _phoneController.text.trim(),
      address: _addressController.text.trim(),
      lat: _selectedLat,
      lng: _selectedLng,
      imageUrl: imageUrl,
      tags: List<String>.from(_tags),
    );

    if (mounted) {
      context.read<BarbershopManagementCubit>().update(params);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return BlocConsumer<BarbershopManagementCubit, BarbershopManagementState>(
      listener: (context, state) {
        if (state is BarbershopLoaded && state.barbershop != null) {
          setState(() => _populate(state.barbershop!));
        }
        if (state is BarbershopUpdated) {
          AppToast.success(context, 'Barbería actualizada');
          context.pop();
        }
        if (state is BarbershopManagementError) {
          AppToast.error(context, state.message);
        }
      },
      builder: (context, state) {
        final isLoading = state is BarbershopManagementLoading && !_initialized;
        final isMissing = state is BarbershopLoaded && state.barbershop == null;

        return Scaffold(
          backgroundColor: theme.scaffoldBackgroundColor,
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded),
              onPressed: () => context.pop(),
            ),
            title: Text(
              'Editar barbería',
              style: AppTypography.titleLarge.copyWith(
                color: theme.colorScheme.onSurface,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          body: SafeArea(
            child: Center(
              child: isLoading
                  ? const CircularProgressIndicator()
                  : isMissing
                  ? Text(
                      'No se encontró la barbería',
                      style: AppTypography.bodyLarge.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    )
                  : SingleChildScrollView(
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      padding: EdgeInsets.fromLTRB(
                        24,
                        28,
                        24,
                        28 + MediaQuery.viewInsetsOf(context).bottom,
                      ),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 640),
                        child: AppFadeSlideIn(
                          child: _FormCard(
                            formKey: _formKey,
                            nameController: _nameController,
                            phoneController: _phoneController,
                            addressController: _addressController,
                            tagController: _tagController,
                            selectedLat: _selectedLat,
                            selectedLng: _selectedLng,
                            tags: _tags,
                            currentTag: _currentTag,
                            selectedImage: _selectedImage,
                            existingImageUrl: _barbershop?.imageUrl,
                            submitLabel: 'Guardar cambios',
                            submittingLabel: 'Guardando cambios...',
                            submitIcon: Icons.save_rounded,
                            onSubmit: _submit,
                            onAddTag: _addTag,
                            onRemoveTag: _removeTag,
                            onPickImage: _pickImage,
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
        );
      },
    );
  }
}

class _FormCard extends StatelessWidget {
  const _FormCard({
    required this.formKey,
    required this.nameController,
    required this.phoneController,
    required this.addressController,
    required this.tagController,
    required this.selectedLat,
    required this.selectedLng,
    required this.tags,
    required this.currentTag,
    required this.selectedImage,
    required this.existingImageUrl,
    required this.submitLabel,
    required this.submittingLabel,
    required this.submitIcon,
    required this.onSubmit,
    required this.onAddTag,
    required this.onRemoveTag,
    required this.onPickImage,
    required this.onCurrentTagChanged,
    required this.onLocationSelected,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController nameController;
  final TextEditingController phoneController;
  final TextEditingController addressController;
  final TextEditingController tagController;
  final double selectedLat;
  final double selectedLng;
  final List<String> tags;
  final String currentTag;
  final XFile? selectedImage;
  final String? existingImageUrl;
  final String submitLabel;
  final String submittingLabel;
  final IconData submitIcon;
  final VoidCallback onSubmit;
  final ValueChanged<String> onAddTag;
  final ValueChanged<String> onRemoveTag;
  final VoidCallback onPickImage;
  final ValueChanged<String> onCurrentTagChanged;
  final ValueChanged<LatLng> onLocationSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return BlocBuilder<BarbershopManagementCubit, BarbershopManagementState>(
      buildWhen: (prev, curr) => curr is BarbershopManagementLoading,
      builder: (context, state) {
        final isSubmitting = state is BarbershopManagementLoading;

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(32),
            boxShadow: [
              BoxShadow(
                color: theme.shadowColor,
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
                const _FieldLabel(text: 'Imagen de la barbería'),
                const SizedBox(height: 8),
                _ImagePicker(
                  selectedImage: selectedImage,
                  existingImageUrl: existingImageUrl,
                  onPick: onPickImage,
                ),
                const SizedBox(height: 28),
                LocationPicker(
                  initialLocation: LatLng(selectedLat, selectedLng),
                  onLocationSelected: onLocationSelected,
                ),
                const SizedBox(height: 28),
                const _SectionTitle(text: 'Etiquetas'),
                const SizedBox(height: 20),
                if (tags.isNotEmpty) ...[
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: tags.map((tag) {
                      return Chip(
                        label: Text(
                          tag,
                          style: AppTypography.labelMedium.copyWith(
                            color: theme.colorScheme.onPrimaryContainer,
                          ),
                        ),
                        backgroundColor: theme.colorScheme.primaryContainer,
                        deleteIcon: Icon(
                          Icons.close_rounded,
                          size: 16,
                          color: theme.colorScheme.onPrimaryContainer
                              .withValues(alpha: 0.8),
                        ),
                        onDeleted: () => onRemoveTag(tag),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.full),
                        ),
                        side: BorderSide.none,
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                ],
                Row(
                  children: [
                    Expanded(
                      child: _TextField(
                        controller: tagController,
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
                          backgroundColor: theme.colorScheme.primaryContainer,
                          foregroundColor: theme.colorScheme.onPrimaryContainer,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppRadius.xl),
                          ),
                        ),
                        child: const Text('Agregar'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: isSubmitting ? null : onSubmit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primaryContainer,
                      foregroundColor: theme.colorScheme.onPrimaryContainer,
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
                                    color: theme.colorScheme.onPrimaryContainer,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  submittingLabel,
                                  style: TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            )
                          : Row(
                              key: ValueKey('idle'),
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  submitLabel,
                                  style: const TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Icon(submitIcon, size: 22),
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

class _ImagePicker extends StatelessWidget {
  const _ImagePicker({
    required this.selectedImage,
    required this.existingImageUrl,
    required this.onPick,
  });

  final XFile? selectedImage;
  final String? existingImageUrl;
  final VoidCallback onPick;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onPick,
      child: Container(
        height: 150,
        width: double.infinity,
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(AppRadius.xl),
          border: Border.all(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
            width: 2,
          ),
        ),
        child: selectedImage != null
            ? Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadius.xl),
                    child: Image.file(
                      File(selectedImage!.path),
                      width: double.infinity,
                      height: 150,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.edit,
                        size: 20,
                        color: theme.colorScheme.onPrimary,
                      ),
                    ),
                  ),
                ],
              )
            : existingImageUrl?.isNotEmpty == true
            ? Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadius.xl),
                    child: Image.network(
                      existingImageUrl!,
                      width: double.infinity,
                      height: 150,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          _ImagePlaceholder(theme: theme),
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.edit,
                        size: 20,
                        color: theme.colorScheme.onPrimary,
                      ),
                    ),
                  ),
                ],
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.add_photo_alternate_outlined,
                    size: 48,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Agregar imagen',
                    style: AppTypography.bodyMedium.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _ImagePlaceholder extends StatelessWidget {
  const _ImagePlaceholder({required this.theme});

  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: theme.colorScheme.surfaceContainerHighest,
      child: Icon(
        Icons.storefront_rounded,
        size: 48,
        color: theme.colorScheme.onSurfaceVariant,
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      text,
      style: AppTypography.titleLarge.copyWith(
        color: theme.colorScheme.onSurface,
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
    final theme = Theme.of(context);
    return Text(
      text,
      style: AppTypography.labelLarge.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
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
    final theme = Theme.of(context);
    return TextFormField(
      controller: controller,
      obscureText: false,
      keyboardType: keyboardType,
      validator: validator,
      maxLines: maxLines,
      onFieldSubmitted: onSubmitted,
      onChanged: onChanged,
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
        prefixIcon: Icon(prefixIcon, color: theme.colorScheme.outline),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 18,
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
