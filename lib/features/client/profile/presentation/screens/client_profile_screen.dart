import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../../shared/motion/app_motion.dart';
import '../../../../../shared/theme/app_theme.dart';
import '../../../../../shared/widgets/image_picker_sheet.dart';
import '../../../../../shared/widgets/theme_selector.dart';
import '../cubit/client_profile_cubit.dart';

class ClientProfileScreen extends StatelessWidget {
  const ClientProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ClientProfileCubit, ClientProfileState>(
      buildWhen: (prev, curr) =>
          prev.isLoading != curr.isLoading ||
          prev.userName != curr.userName ||
          prev.userEmail != curr.userEmail ||
          prev.userPhone != curr.userPhone ||
          prev.profileImageUrl != curr.profileImageUrl,
      builder: (context, state) {
        if (state.isLoading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        return _ProfileContent(
          userName: state.userName,
          userEmail: state.userEmail,
          userPhone: state.userPhone,
          profileImageUrl: state.profileImageUrl,
        );
      },
    );
  }
}

class _ProfileContent extends StatelessWidget {
  final String userName;
  final String userEmail;
  final String? userPhone;
  final String? profileImageUrl;

  const _ProfileContent({
    required this.userName,
    required this.userEmail,
    this.userPhone,
    this.profileImageUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
          children: [
            AppFadeSlideIn(
              child: _ProfileHeader(
                userName: userName,
                userEmail: userEmail,
                userPhone: userPhone,
                profileImageUrl: profileImageUrl,
              ),
            ),
            const SizedBox(height: 22),
            const AppFadeSlideIn(child: ThemeSelector()),
            const SizedBox(height: 22),
            AppFadeSlideIn(
              delay: AppMotion.delay(1),
              child: _ProfileAction(
                icon: Icons.edit_outlined,
                title: 'Editar perfil',
                onTap: () => _showEditProfileSheet(context),
              ),
            ),
            const SizedBox(height: 10),
            AppFadeSlideIn(
              delay: AppMotion.delay(2),
              child: _ProfileAction(
                icon: Icons.location_on_outlined,
                title: 'Direcciones',
                onTap: () {},
              ),
            ),
            const SizedBox(height: 10),
            AppFadeSlideIn(
              delay: AppMotion.delay(3),
              child: _ProfileAction(
                icon: Icons.credit_card_outlined,
                title: 'Métodos de pago',
                onTap: () {},
              ),
            ),
            const SizedBox(height: 10),
            AppFadeSlideIn(
              delay: AppMotion.delay(4),
              child: _ProfileAction(
                icon: Icons.notifications_outlined,
                title: 'Notificaciones',
                onTap: () {},
              ),
            ),
            const SizedBox(height: 10),
            AppFadeSlideIn(
              delay: AppMotion.delay(5),
              child: _ProfileAction(
                icon: Icons.help_outline_rounded,
                title: 'Ayuda y soporte',
                onTap: () {},
              ),
            ),
            const SizedBox(height: 16),
            AppFadeSlideIn(
              delay: AppMotion.delay(6),
              child: _LogoutButton(
                onTap: () async {
                  final shouldLogout = await _confirmLogout(context);
                  if (shouldLogout != true || !context.mounted) return;

                  await context.read<ClientProfileCubit>().logout();
                  if (context.mounted) context.go('/login');
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<bool?> _confirmLogout(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Cerrar sesión'),
        content: const Text('¿Seguro que querés cerrar esta sesión?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Cerrar sesión'),
          ),
        ],
      ),
    );
  }

  void _showEditProfileSheet(BuildContext context) {
    final cubit = context.read<ClientProfileCubit>();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => _EditProfileSheet(
        cubit: cubit,
        userName: userName,
        userPhone: userPhone,
        profileImageUrl: profileImageUrl,
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  final String userName;
  final String userEmail;
  final String? userPhone;
  final String? profileImageUrl;

  const _ProfileHeader({
    required this.userName,
    required this.userEmail,
    this.userPhone,
    this.profileImageUrl,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppRadius.xl),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => _showImagePicker(context),
            child: Stack(
              children: [
                CircleAvatar(
                  radius: 35,
                  backgroundColor: theme.colorScheme.primary,
                  backgroundImage: profileImageUrl != null
                      ? NetworkImage(profileImageUrl!)
                      : null,
                  child: profileImageUrl == null
                      ? Icon(
                          Icons.person,
                          color: theme.colorScheme.onPrimary,
                          size: 35,
                        )
                      : null,
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.camera_alt,
                      size: 16,
                      color: theme.colorScheme.onPrimary,
                    ),
                  ),
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
                  userName,
                  style: AppTypography.headlineSmall.copyWith(
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  userEmail,
                  style: AppTypography.bodyMedium.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                if (userPhone != null && userPhone!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    userPhone!,
                    style: AppTypography.bodySmall.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showImagePicker(BuildContext context) async {
    final image = await showModalBottomSheet<XFile>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => const ImagePickerSheet(),
    );

    if (image != null && context.mounted) {
      await context.read<ClientProfileCubit>().saveProfile(imageFile: image);
    }
  }
}

class _ProfileAction extends StatelessWidget {
  const _ProfileAction({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: theme.colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        child: ListTile(
          leading: Icon(icon, color: theme.colorScheme.primary),
          title: Text(
            title,
            style: AppTypography.titleSmall.copyWith(
              color: theme.colorScheme.onSurface,
            ),
          ),
          trailing: Icon(
            Icons.chevron_right_rounded,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.xl),
          ),
          onTap: onTap,
        ),
      ),
    );
  }
}

class _LogoutButton extends StatelessWidget {
  final VoidCallback onTap;
  const _LogoutButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: const Icon(Icons.logout_rounded),
      label: const Text('Cerrar sesión'),
    );
  }
}

class _EditProfileSheet extends StatefulWidget {
  final ClientProfileCubit cubit;
  final String userName;
  final String? userPhone;
  final String? profileImageUrl;

  const _EditProfileSheet({
    required this.cubit,
    required this.userName,
    this.userPhone,
    this.profileImageUrl,
  });

  @override
  State<_EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends State<_EditProfileSheet> {
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  XFile? _selectedImage;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.userName);
    _phoneController = TextEditingController(text: widget.userPhone ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return BlocProvider.value(
      value: widget.cubit,
      child: BlocBuilder<ClientProfileCubit, ClientProfileState>(
        builder: (context, state) {
          return Container(
            padding: EdgeInsets.only(
              left: 24,
              right: 24,
              top: 24,
              bottom: MediaQuery.of(context).viewInsets.bottom + 24,
            ),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerLowest,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.outlineVariant,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Editar perfil',
                    style: AppTypography.titleLarge.copyWith(
                      color: theme.colorScheme.onSurface,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 24),
                  GestureDetector(
                    onTap: _pickImage,
                    child: Stack(
                      children: [
                        CircleAvatar(
                          radius: 50,
                          backgroundColor: theme.colorScheme.primary,
                          backgroundImage: _selectedImage != null
                              ? FileImage(File(_selectedImage!.path))
                              : widget.profileImageUrl != null
                              ? NetworkImage(widget.profileImageUrl!)
                              : null,
                          child:
                              _selectedImage == null &&
                                  widget.profileImageUrl == null
                              ? Icon(
                                  Icons.person,
                                  color: theme.colorScheme.onPrimary,
                                  size: 50,
                                )
                              : null,
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.camera_alt,
                              size: 20,
                              color: theme.colorScheme.onPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: 'Nombre',
                      prefixIcon: const Icon(Icons.person_outline),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadius.xl),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      labelText: 'Teléfono',
                      prefixIcon: const Icon(Icons.phone_outlined),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadius.xl),
                      ),
                    ),
                  ),
                  if (state.updateError != null) ...[
                    const SizedBox(height: 16),
                    Text(
                      state.updateError!,
                      style: AppTypography.bodySmall.copyWith(
                        color: theme.colorScheme.error,
                      ),
                    ),
                  ],
                  if (state.phoneError != null) ...[
                    const SizedBox(height: 16),
                    Text(
                      state.phoneError!,
                      style: AppTypography.bodySmall.copyWith(
                        color: theme.colorScheme.error,
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: state.isUpdating
                              ? null
                              : () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: const Text('Cancelar'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: state.isUpdating ? null : _save,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: state.isUpdating
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text('Guardar'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
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

  Future<void> _save() async {
    await widget.cubit.saveProfile(
      fullName: _nameController.text.trim(),
      phone: _phoneController.text.trim(),
      imageFile: _selectedImage,
    );

    final state = widget.cubit.state;
    if (mounted && state.updateError == null && state.phoneError == null) {
      Navigator.pop(context);
    }
  }
}
