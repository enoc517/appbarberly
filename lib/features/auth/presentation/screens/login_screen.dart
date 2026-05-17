import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/auth_route_resolver.dart';
import '../../../../shared/motion/app_motion.dart';
import '../../../../shared/theme/app_theme.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();
    context.read<AuthBloc>().add(
      AuthSignInRequested(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final width = size.width;
    final isWide = width >= 900;
    final isCompact = width < 390 || size.height < 720;
    final isLoading = context.select(
      (AuthBloc bloc) => bloc.state.status == AuthStatus.loading,
    );

    return BlocListener<AuthBloc, AuthState>(
      listenWhen: (prev, curr) => prev.status != curr.status,
      listener: (context, state) {
        if (state.status == AuthStatus.emailVerificationPending) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Debes verificar tu correo antes de continuar'),
            ),
          );
          Future.delayed(const Duration(milliseconds: 700), () {
            if (context.mounted) context.go('/verify-email');
          });
          return;
        }

        if (state.status == AuthStatus.authenticated) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Sesión iniciada correctamente')),
          );
          Future.delayed(const Duration(milliseconds: 700), () {
            if (context.mounted) {
              context.go(routeForAuthenticatedUser(state.user));
            }
          });
          return;
        }

        if (state.status == AuthStatus.googleRoleSelection) {
          context.go('/google-role');
          return;
        }

        if (state.status == AuthStatus.failure && state.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.errorMessage!)),
          );
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Stack(
            children: [
              Positioned(
                top: -90,
                right: -80,
                child: _GlowCircle(
                  size: 240,
                  color: AppColors.primaryContainer.withValues(alpha: 0.04),
                ),
              ),
              Positioned(
                bottom: -120,
                left: -100,
                child: _GlowCircle(
                  size: 280,
                  color: AppColors.secondaryContainer.withValues(alpha: 0.03),
                ),
              ),
              Positioned.fill(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final horizontalPadding = isCompact ? 16.0 : 24.0;
                    final verticalPadding = isCompact ? 16.0 : 28.0;
                    final minContentHeight =
                        constraints.maxHeight - (verticalPadding * 2);

                    return SingleChildScrollView(
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      padding: EdgeInsets.symmetric(
                        horizontal: horizontalPadding,
                        vertical: verticalPadding,
                      ),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            maxWidth: 1120,
                            minHeight: minContentHeight > 0 ? minContentHeight : 0,
                          ),
                          child: Align(
                            alignment: isWide ? Alignment.center : Alignment.topCenter,
                            child: isWide
                                ? Row(
                                    children: [
                                      Expanded(
                                        child: AppFadeSlideIn(
                                          child: _BrandPanel(theme: Theme.of(context)),
                                        ),
                                      ),
                                      const SizedBox(width: 32),
                                      Expanded(
                                        child: AppFadeSlideIn(
                                          delay: AppMotion.delay(1),
                                          child: _LoginCard(
                                            isLoading: isLoading,
                                            isCompact: isCompact,
                                            formKey: _formKey,
                                            emailController: _emailController,
                                            passwordController: _passwordController,
                                            obscurePassword: _obscurePassword,
                                            onTogglePassword: () {
                                              setState(() {
                                                _obscurePassword = !_obscurePassword;
                                              });
                                            },
                                            onSubmit: _submit,
                                            onGoRegister: () => context.go('/register'),
                                          ),
                                        ),
                                      ),
                                    ],
                                  )
                                : Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      AppFadeSlideIn(
                                        child: _BrandHeader(isCompact: isCompact),
                                      ),
                                      SizedBox(height: isCompact ? 18 : 28),
                                      AppFadeSlideIn(
                                        delay: AppMotion.delay(1),
                                        child: _LoginCard(
                                          isLoading: isLoading,
                                          isCompact: isCompact,
                                          formKey: _formKey,
                                          emailController: _emailController,
                                          passwordController: _passwordController,
                                          obscurePassword: _obscurePassword,
                                          onTogglePassword: () {
                                            setState(() {
                                              _obscurePassword = !_obscurePassword;
                                            });
                                          },
                                          onSubmit: _submit,
                                          onGoRegister: () => context.go('/register'),
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LoginCard extends StatelessWidget {
  const _LoginCard({
    required this.isLoading,
    required this.isCompact,
    required this.formKey,
    required this.emailController,
    required this.passwordController,
    required this.obscurePassword,
    required this.onTogglePassword,
    required this.onSubmit,
    required this.onGoRegister,
  });

  final bool isLoading;
  final bool isCompact;
  final GlobalKey<FormState> formKey;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final bool obscurePassword;
  final VoidCallback onTogglePassword;
  final VoidCallback onSubmit;
  final VoidCallback onGoRegister;

  @override
  Widget build(BuildContext context) {
    final cardPadding = isCompact ? 20.0 : 28.0;
    final titleGap = isCompact ? 26.0 : 36.0;
    final fieldGap = isCompact ? 20.0 : 24.0;
    final socialGap = isCompact ? 18.0 : 24.0;

    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxWidth: 560),
      padding: EdgeInsets.all(cardPadding),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(isCompact ? 26 : 32),
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
            Text(
              'Bienvenido de nuevo',
              style: AppTypography.headlineMedium.copyWith(
                fontSize: isCompact ? 25 : null,
                color: AppColors.onSurface,
              ),
            ),
            SizedBox(height: titleGap),
            _EmailField(controller: emailController, isCompact: isCompact),
            SizedBox(height: fieldGap),
            _PasswordField(
              controller: passwordController,
              obscurePassword: obscurePassword,
              onTogglePassword: onTogglePassword,
              isCompact: isCompact,
            ),
            SizedBox(height: socialGap),
            _SubmitButton(
              isLoading: isLoading,
              onSubmit: onSubmit,
              isCompact: isCompact,
            ),
            SizedBox(height: isCompact ? 14 : 20),
            _RegisterLink(onGoRegister: onGoRegister, isCompact: isCompact),
          ],
        ),
      ),
    );
  }
}

class _EmailField extends StatelessWidget {
  final TextEditingController controller;
  final bool isCompact;
  const _EmailField({required this.controller, required this.isCompact});

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.emailAddress,
      decoration: InputDecoration(
        labelText: 'Correo electrónico',
        hintText: 'ejemplo@correo.com',
        prefixIcon: const Icon(Icons.email_outlined),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(isCompact ? 18 : 20),
        ),
      ),
      validator: (value) {
        final text = value?.trim() ?? '';
        if (text.isEmpty) return 'Por favor ingresa tu correo';
        if (!RegExp(r'^[\w\-.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(text)) {
          return 'Ingresa un correo válido';
        }
        return null;
      },
    );
  }
}

class _PasswordField extends StatelessWidget {
  final TextEditingController controller;
  final bool obscurePassword;
  final VoidCallback onTogglePassword;
  final bool isCompact;
  const _PasswordField({
    required this.controller,
    required this.obscurePassword,
    required this.onTogglePassword,
    required this.isCompact,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscurePassword,
      decoration: InputDecoration(
        labelText: 'Contraseña',
        hintText: '••••••••',
        prefixIcon: const Icon(Icons.lock_outline_rounded),
        suffixIcon: IconButton(
          icon: Icon(obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined),
          onPressed: onTogglePassword,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(isCompact ? 18 : 20),
        ),
      ),
      validator: (value) {
        final text = value?.trim() ?? '';
        if (text.isEmpty) return 'Por favor ingresa tu contraseña';
        if (text.length < 6) return 'La contraseña debe tener al menos 6 caracteres';
        return null;
      },
    );
  }
}

class _SubmitButton extends StatelessWidget {
  final bool isLoading;
  final VoidCallback onSubmit;
  final bool isCompact;
  const _SubmitButton({
    required this.isLoading,
    required this.onSubmit,
    required this.isCompact,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: isCompact ? 50 : 56,
      child: FilledButton(
        onPressed: isLoading ? null : onSubmit,
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primaryContainer,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(isCompact ? 18 : 20),
          ),
        ),
        child: isLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Text(
                'Iniciar sesión',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
      ),
    );
  }
}

class _RegisterLink extends StatelessWidget {
  final VoidCallback onGoRegister;
  final bool isCompact;
  const _RegisterLink({required this.onGoRegister, required this.isCompact});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: TextButton(
        onPressed: onGoRegister,
        child: Text(
          '¿No tienes cuenta? Regístrate',
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _BrandHeader extends StatelessWidget {
  final bool isCompact;
  const _BrandHeader({required this.isCompact});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(Icons.content_cut_rounded, size: isCompact ? 48 : 64, color: AppColors.primary),
        const SizedBox(height: 12),
        Text(
          'Barberly',
          style: AppTypography.displaySmall.copyWith(
            fontSize: isCompact ? 32 : null,
            color: AppColors.onSurface,
          ),
        ),
      ],
    );
  }
}

class _BrandPanel extends StatelessWidget {
  final ThemeData theme;
  const _BrandPanel({required this.theme});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.content_cut_rounded, size: 96, color: AppColors.primary),
        const SizedBox(height: 24),
        Text(
          'Barberly',
          style: AppTypography.displayMedium.copyWith(color: AppColors.onSurface),
        ),
        const SizedBox(height: 12),
        Text(
          'Tu plataforma de gestión para barberías',
          style: AppTypography.bodyLarge.copyWith(color: AppColors.onSurfaceVariant),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _GlowCircle extends StatelessWidget {
  final double size;
  final Color color;
  const _GlowCircle({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
      ),
    );
  }
}
