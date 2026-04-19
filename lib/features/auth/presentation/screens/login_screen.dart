import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../shared/theme/app_theme.dart';

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

    // TODO: Conectar con AuthBloc / use case de login.
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Login pendiente de integración')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isWide = width >= 900;
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
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
            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 28,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1120),
                  child: isWide
                      ? Row(
                          children: [
                            Expanded(
                              child: _BrandPanel(theme: Theme.of(context)),
                            ),
                            const SizedBox(width: 32),
                            Expanded(
                              child: _LoginCard(
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
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const _BrandHeader(),
                            const SizedBox(height: 28),
                            _LoginCard(
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
                          ],
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoginCard extends StatelessWidget {
  const _LoginCard({
    required this.formKey,
    required this.emailController,
    required this.passwordController,
    required this.obscurePassword,
    required this.onTogglePassword,
    required this.onSubmit,
    required this.onGoRegister,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final bool obscurePassword;
  final VoidCallback onTogglePassword;
  final VoidCallback onSubmit;
  final VoidCallback onGoRegister;

  Future<bool> _showConfirmPasswordChange(BuildContext context) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('¿Deseas cambiar tu contraseña?'),
            content: const Text(
              'Esta acción te llevará a la pantalla de restablecimiento.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false), // Retorna false
                child: const Text('Cancelar'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true), // Retorna true
                child: const Text('Sí, continuar'),
              ),
            ],
          ),
        ) ??
        false; // El ?? false es por si el usuario cierra el diálogo tocando fuera de él
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxWidth: 560),
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
            Text(
              'Bienvenido de nuevo',
              style: AppTypography.headlineMedium.copyWith(
                color: AppColors.onSurface,
                fontWeight: FontWeight.w800,
                height: 1.1,
              ),
            ),
            const SizedBox(height: 36),
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
            const SizedBox(height: 24),
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
                  // Esperamos la respuesta del diálogo
                  final bool confirmacion = await _showConfirmPasswordChange(
                    context,
                  );
                  if (confirmacion) {                   
                    GoRouter.of(context).go('/reset-password');
                  }
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
                onPressed: onSubmit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryContainer, // #0F1C2C
                  foregroundColor: AppColors.onPrimary,
                  elevation: 0,
                  shadowColor: AppColors.primaryContainer.withValues(
                    alpha: 0.18,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.xl),
                  ),
                ),
                child: const Row(
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
            const SizedBox(height: 28),
            Row(
              children: [
                Expanded(
                  child: Divider(
                    height: 1,
                    color: AppColors.outlineVariant.withValues(alpha: 0.35),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    'O inicia sesión con',
                    style: AppTypography.labelLarge.copyWith(
                      color: AppColors.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
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
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: _SocialButton(
                    label: 'Google',
                    icon: Image.asset(
                      'assets/icons/google.png',
                      width: 22,
                      height: 22,
                      errorBuilder: (_, __, ___) => Icon(
                        Icons.g_mobiledata_rounded,
                        size: 28,
                        color: AppColors.onSurface,
                      ),
                    ),
                    onPressed: () {
                      // TODO: Google sign-in.
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _SocialButton(
                    label: 'Apple',
                    icon: Icon(
                      Icons.apple_rounded,
                      size: 24,
                      color: AppColors.onSurface,
                    ),
                    onPressed: () {
                      // TODO: Apple sign-in.
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 22),
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
  const _BrandHeader();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset('assets/logos/logo4.png', height: 110, fit: BoxFit.contain),

        const SizedBox(height: 8),
        Text(
          'Una experiencia única',
          textAlign: TextAlign.center,
          style: AppTypography.bodyLarge.copyWith(
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
    return SizedBox(
      height: 56,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: AppColors.surfaceContainer,
          side: BorderSide(
            color: AppColors.outlineVariant.withValues(alpha: 0.45),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            icon,
            const SizedBox(width: 12),
            Text(
              label,
              style: AppTypography.labelLarge.copyWith(
                color: AppColors.onSurface,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
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
