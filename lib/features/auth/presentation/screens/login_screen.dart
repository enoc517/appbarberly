import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

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
            if (context.mounted) {
              context.go('/verify-email');
            }
          });
          return;
        }

        if (state.status == AuthStatus.authenticated) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Sesión iniciada correctamente')),
          );

          Future.delayed(const Duration(milliseconds: 700), () {
            if (context.mounted) {
              context.go('/explorar');
            }
          });
        }

        if (state.status == AuthStatus.googleRoleSelection) {
          context.go('/google-role');
          return;
        }

        if (state.status == AuthStatus.failure && state.errorMessage != null) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(state.errorMessage!)));
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
                            minHeight: minContentHeight > 0
                                ? minContentHeight
                                : 0,
                          ),
                          child: Align(
                            alignment: isWide
                                ? Alignment.center
                                : Alignment.topCenter,
                            child: isWide
                                ? Row(
                                    children: [
                                      Expanded(
                                        child: _BrandPanel(
                                          theme: Theme.of(context),
                                        ),
                                      ),
                                      const SizedBox(width: 32),
                                      Expanded(
                                        child: _LoginCard(
                                          isLoading: isLoading,
                                          isCompact: isCompact,
                                          formKey: _formKey,
                                          emailController: _emailController,
                                          passwordController:
                                              _passwordController,
                                          obscurePassword: _obscurePassword,
                                          onTogglePassword: () {
                                            setState(() {
                                              _obscurePassword =
                                                  !_obscurePassword;
                                            });
                                          },
                                          onSubmit: _submit,
                                          onGoRegister: () =>
                                              context.go('/register'),
                                        ),
                                      ),
                                    ],
                                  )
                                : Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      _BrandHeader(isCompact: isCompact),
                                      SizedBox(height: isCompact ? 18 : 28),
                                      _LoginCard(
                                        isLoading: isLoading,
                                        isCompact: isCompact,
                                        formKey: _formKey,
                                        emailController: _emailController,
                                        passwordController: _passwordController,
                                        obscurePassword: _obscurePassword,
                                        onTogglePassword: () {
                                          setState(() {
                                            _obscurePassword =
                                                !_obscurePassword;
                                          });
                                        },
                                        onSubmit: _submit,
                                        onGoRegister: () =>
                                            context.go('/register'),
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
                fontWeight: FontWeight.w800,
                height: 1.1,
              ),
            ),
            SizedBox(height: titleGap),
            const _FieldLabel(text: 'Correo electrónico'),
            const SizedBox(height: 10),
            _TextField(
              controller: emailController,
              hintText: 'tu@ejemplo.com',
              keyboardType: TextInputType.emailAddress,
              prefixIcon: Icons.mail_outline_rounded,
              validator: (value) {
                final text = value?.trim() ?? '';
                if (text.isEmpty) return 'Ingresa tu correo electrónico';
                if (!text.contains('@')) return 'Ingresa un correo válido';
                return null;
              },
            ),
            SizedBox(height: fieldGap),
            const _FieldLabel(text: 'Contraseña'),
            const SizedBox(height: 10),
            _TextField(
              controller: passwordController,
              hintText: '••••••••',
              obscureText: obscurePassword,
              prefixIcon: Icons.lock_outline_rounded,
              suffixIcon: IconButton(
                onPressed: onTogglePassword,
                icon: Icon(
                  obscurePassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                ),
              ),
              validator: (value) {
                final text = value ?? '';
                if (text.isEmpty) return 'Ingresa tu contraseña';
                if (text.length < 6) {
                  return 'La contraseña debe tener al menos 6 caracteres';
                }
                return null;
              },
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () async {
                  GoRouter.of(context).go('/forgot_password');
                },
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.secondary,
                  padding: EdgeInsets.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  '¿Olvidaste tu contraseña?',
                  style: AppTypography.labelLarge.copyWith(
                    color: AppColors.secondary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: isLoading ? null : onSubmit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryContainer,
                  foregroundColor: AppColors.onPrimary,
                  elevation: 0,
                  shadowColor: AppColors.primaryContainer.withValues(
                    alpha: 0.18,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.xl),
                  ),
                ),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: isLoading
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
                              'Ingresando...',
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
                              'Entrar',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            SizedBox(width: 10),
                            Icon(Icons.login_rounded, size: 22),
                          ],
                        ),
                ),
              ),
            ),
            SizedBox(height: isCompact ? 22 : 28),
            _SocialDivider(isCompact: isCompact),
            SizedBox(height: socialGap),
            _SocialButtons(isCompact: isCompact),
            SizedBox(height: isCompact ? 18 : 22),
            Center(
              child: Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                alignment: WrapAlignment.center,
                children: [
                  Text(
                    '¿Aún no eres parte del equipo? ',
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  GestureDetector(
                    onTap: onGoRegister,
                    child: Text(
                      'Registrarse',
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.onSurface,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BrandHeader extends StatelessWidget {
  const _BrandHeader({required this.isCompact});

  final bool isCompact;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset(
          'assets/logos/logo4.png',
          height: isCompact ? 86 : 110,
          fit: BoxFit.contain,
        ),
        SizedBox(height: isCompact ? 6 : 8),
        Text(
          'Una experiencia única',
          textAlign: TextAlign.center,
          style:
              (isCompact ? AppTypography.bodyMedium : AppTypography.bodyLarge)
                  .copyWith(
                    color: AppColors.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
        ),
      ],
    );
  }
}

class _BrandPanel extends StatelessWidget {
  const _BrandPanel({required this.theme});

  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 680,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(36),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.surface, AppColors.surfaceContainerLow],
        ),
        border: Border.all(
          color: AppColors.outlineVariant.withValues(alpha: 0.6),
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -40,
            right: -20,
            child: _GlowCircle(
              size: 190,
              color: AppColors.primaryContainer.withValues(alpha: 0.04),
            ),
          ),
          Positioned(
            bottom: -70,
            left: -50,
            child: _GlowCircle(
              size: 260,
              color: AppColors.secondaryContainer.withValues(alpha: 0.03),
            ),
          ),
          Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/logos/logo4.png',
                    height: 140,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Una experiencia única',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontSize: 18,
                      color: AppColors.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SocialDivider extends StatelessWidget {
  const _SocialDivider({required this.isCompact});

  final bool isCompact;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Divider(
            height: 1,
            color: AppColors.outlineVariant.withValues(alpha: 0.35),
          ),
        ),
        Flexible(
          flex: 0,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: isCompact ? 8 : 12),
            child: Text(
              isCompact ? 'O continúa con' : 'O inicia sesión con',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.labelLarge.copyWith(
                fontSize: isCompact ? 13 : null,
                color: AppColors.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        Expanded(
          child: Divider(
            height: 1,
            color: AppColors.outlineVariant.withValues(alpha: 0.35),
          ),
        ),
      ],
    );
  }
}

class _SocialButtons extends StatelessWidget {
  const _SocialButtons({required this.isCompact});

  final bool isCompact;

  @override
  Widget build(BuildContext context) {
    final googleButton = _SocialButton(
      label: 'Google',
      icon: Image.asset(
        'assets/icons/google.png',
        width: 24,
        height: 24,
        errorBuilder: (_, _, _) => Icon(
          Icons.g_mobiledata_rounded,
          size: 30,
          color: AppColors.onSurface,
        ),
      ),
      onPressed: () {
        context.read<AuthBloc>().add(const AuthSignInWithGoogleRequested());
      },
    );

    final appleButton = _SocialButton(
      label: 'Apple',
      icon: Icon(Icons.apple_rounded, size: 28, color: AppColors.onSurface),
      onPressed: () {
        // TODO: Apple sign-in.
      },
    );

    return SizedBox(
      width: double.infinity,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          googleButton,
          SizedBox(width: isCompact ? 14 : 18),
          appleButton,
        ],
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
      ),
    );
  }
}

class _TextField extends StatelessWidget {
  const _TextField({
    required this.controller,
    required this.hintText,
    required this.prefixIcon,
    this.obscureText = false,
    this.keyboardType,
    this.suffixIcon,
    this.validator,
  });

  final TextEditingController controller;
  final String hintText;
  final IconData prefixIcon;
  final bool obscureText;
  final TextInputType? keyboardType;
  final Widget? suffixIcon;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      validator: validator,
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
        suffixIcon: suffixIcon,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 18,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(22),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(22),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(22),
          borderSide: BorderSide(color: AppColors.primaryContainer, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(22),
          borderSide: const BorderSide(color: Colors.redAccent, width: 1.2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(22),
          borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
        ),
      ),
    );
  }
}

class _SocialButton extends StatelessWidget {
  const _SocialButton({
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  final String label;
  final Widget icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: label,
      child: Semantics(
        button: true,
        label: 'Continuar con $label',
        child: SizedBox.square(
          dimension: 56,
          child: OutlinedButton(
            onPressed: onPressed,
            style: OutlinedButton.styleFrom(
              backgroundColor: AppColors.surfaceContainer,
              padding: EdgeInsets.zero,
              side: BorderSide(
                color: AppColors.outlineVariant.withValues(alpha: 0.45),
              ),
              shape: const CircleBorder(),
            ),
            child: Center(child: icon),
          ),
        ),
      ),
    );
  }
}

class _GlowCircle extends StatelessWidget {
  const _GlowCircle({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }
}
