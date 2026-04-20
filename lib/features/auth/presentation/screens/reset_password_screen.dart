import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '/../../../shared/theme/app_theme.dart';
// Asegúrate de que esta ruta apunte a tu nuevo bloc unificado
import '../bloc/password_recovery_bloc.dart';

class ResetPasswordScreen extends StatelessWidget {
  const ResetPasswordScreen({super.key});

  static const String routeName = 'reset_password';
  static const String routePath = '/reset_password';

  @override
  Widget build(BuildContext context) {
    // IMPORTANTE: Ya no creamos el BlocProvider aquí.
    // Esta vista asume que el PasswordRecoveryBloc se está proveyendo
    // desde el enrutador (GoRouter) para mantener la memoria de los 3 pasos.
    return const _ResetPasswordView();
  }
}

class _ResetPasswordView extends StatefulWidget {
  const _ResetPasswordView();

  @override
  State<_ResetPasswordView> createState() => _ResetPasswordViewState();
}

class _ResetPasswordViewState extends State<_ResetPasswordView> {
  final _formKey = GlobalKey<FormState>();
  final _passController = TextEditingController();
  final _confirmPassController = TextEditingController();

  @override
  void dispose() {
    _passController.dispose();
    _confirmPassController.dispose();
    super.dispose();
  }

  // Vista emergente de confirmación
  void _showConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (confirmContext) => AlertDialog(
        title: Text(
          '¿Actualizar contraseña?',
          style: AppTypography.headlineSmall.copyWith(
            color: AppColors.onSurface,
          ),
        ),
        content: const Text(
          'Se cerrarán todas las sesiones activas una vez que realices este cambio para asegurar tu cuenta.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(confirmContext),
            child: Text('Cancelar', style: TextStyle(color: AppColors.outline)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primaryContainer,
            ),
            onPressed: () {
              Navigator.pop(confirmContext);
              // Cambiamos el evento al nuevo NewPasswordSubmitted
              context.read<PasswordRecoveryBloc>().add(
                NewPasswordSubmitted(
                  newPassword: _passController.text,
                  confirmPassword: _confirmPassController.text,
                ),
              );
            },
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: AppColors.onSurface,
            size: 20,
          ),
          onPressed: () => context
              .pop(), // Mejor context.pop() para retroceder al token si es necesario
        ),
        centerTitle: true,
      ),
      // Cambiamos a PasswordRecoveryBloc y State
      body: BlocListener<PasswordRecoveryBloc, PasswordRecoveryState>(
        listener: (context, state) {
          // Validamos contra el nuevo enum RecoveryStatus
          if (state.status == RecoveryStatus.success) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Contraseña actualizada con éxito')),
            );
            context.go('/login');
          }
          if (state.status == RecoveryStatus.error) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.errorMessage ?? 'Error al actualizar'),
              ),
            );
          }
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 20),
                // Badge visual
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.primaryContainer,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: const Icon(
                    Icons.lock_reset,
                    color: Colors.white,
                    size: 40,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Nueva Contraseña',
                  style: AppTypography.headlineMedium.copyWith(
                    color: AppColors.onSurface,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Asegúrate de que sea una contraseña segura que no uses en otros sitios.',
                  textAlign: TextAlign.center,
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 40),

                // Campo Nueva Contraseña
                _buildPasswordField(
                  controller: _passController,
                  label: 'Contraseña',
                  isNew: true,
                ),
                const SizedBox(height: 16),

                // Campo Confirmar Contraseña
                _buildPasswordField(
                  controller: _confirmPassController,
                  label: 'Confirmar Contraseña',
                  isNew: false,
                ),

                const SizedBox(height: 40),

                // Botón de Acción
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child:
                      BlocBuilder<PasswordRecoveryBloc, PasswordRecoveryState>(
                        builder: (context, state) {
                          return FilledButton(
                            onPressed: state.isLoading
                                ? null
                                : () {
                                    if (_formKey.currentState!.validate()) {
                                      _showConfirmationDialog(context);
                                    }
                                  },
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.primaryContainer,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                            child: state.isLoading
                                ? const CircularProgressIndicator(
                                    color: Colors.white,
                                  )
                                : Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: const [
                                      Text(
                                        'Actualizar Contraseña',
                                        style: TextStyle(fontSize: 16),
                                      ),
                                      SizedBox(width: 8),
                                      Icon(Icons.arrow_forward, size: 20),
                                    ],
                                  ),
                          );
                        },
                      ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required bool isNew,
  }) {
    return BlocBuilder<PasswordRecoveryBloc, PasswordRecoveryState>(
      buildWhen: (p, c) => isNew
          ? p.isPasswordObscured != c.isPasswordObscured
          : p.isConfirmPasswordObscured != c.isConfirmPasswordObscured,
      builder: (context, state) {
        final isObscured = isNew
            ? state.isPasswordObscured
            : state.isConfirmPasswordObscured;

        return TextFormField(
          controller: controller,
          obscureText: isObscured,
          style: AppTypography.bodyLarge,
          decoration: InputDecoration(
            labelText: label,
            prefixIcon: const Icon(Icons.vpn_key_outlined),
            suffixIcon: IconButton(
              icon: Icon(isObscured ? Icons.visibility_off : Icons.visibility),
              onPressed: () {
                // Actualizado a los nuevos eventos
                context.read<PasswordRecoveryBloc>().add(
                  isNew
                      ? PasswordVisibilityToggled()
                      : ConfirmPasswordVisibilityToggled(),
                );
              },
            ),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Este campo es requerido';
            }
            if (value.length < 8) return 'Mínimo 8 caracteres';
            if (!isNew && value != _passController.text) {
              return 'Las contraseñas no coinciden';
            }
            return null;
          },
        );
      },
    );
  }
}
