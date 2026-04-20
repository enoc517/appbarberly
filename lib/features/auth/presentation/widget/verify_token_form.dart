import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../../shared/theme/app_theme.dart';

class VerifyTokenForm extends StatefulWidget {
  const VerifyTokenForm({super.key});

  @override
  State<VerifyTokenForm> createState() => _VerifyTokenFormState();
}

class _VerifyTokenFormState extends State<VerifyTokenForm> {
  final _formKey = GlobalKey<FormState>();
  final _tokenController = TextEditingController();

  @override
  void dispose() {
    _tokenController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          const SizedBox(height: 40),
          // Badge visual: Icono de escudo o mensaje basado en tu diseño
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.primaryContainer,
              borderRadius: BorderRadius.circular(28),
            ),
            child: const Icon(
              Icons.mark_email_read_outlined,
              color: Colors.white,
              size: 48,
            ),
          ),
          const SizedBox(height: 32),
          Text(
            'Verificar Código',
            style: AppTypography.headlineMedium.copyWith(
              fontWeight: FontWeight.w800,
              color: AppColors.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Hemos enviado un código de seguridad a tu correo. Por favor, ingrésalo a continuación para continuar.',
            textAlign: TextAlign.center,
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 48),

          // Input de Token (Optimizado para números)
          TextFormField(
            controller: _tokenController,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            style: AppTypography.headlineSmall.copyWith(
              letterSpacing: 12,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(
                6,
              ), // Supongamos código de 6 dígitos
            ],
            decoration: const InputDecoration(
              labelText: 'Código de Verificación',
              floatingLabelAlignment: FloatingLabelAlignment.center,
              hintText: '000000',
              prefixIcon: Icon(Icons.verified_user_outlined),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) return 'Ingresa el código';
              if (value.length < 6) return 'El código debe tener 6 dígitos';
              return null;
            },
          ),

          const SizedBox(height: 24),

          // Reenviar código (UX adicional)
          TextButton(
            onPressed: () {
              // Lógica para reenviar correo mediante BLoC
            },
            child: Text(
              '¿No recibiste el código? Reenviar',
              style: AppTypography.labelLarge.copyWith(
                color: AppColors.secondary,
              ),
            ),
          ),

          const SizedBox(height: 32),

          // Botón de Verificación - Conduce al cambio de contraseña
          SizedBox(
            width: double.infinity,
            height: 58,
            child: FilledButton(
              onPressed: () {
                GoRouter.of(context).go('/reset_password');
                /*if (_formKey.currentState!.validate()) {
                  // FLUJO: Aquí el BLoC valida el token con el backend
                  // Si es exitoso, navegamos a la pantalla final
                  GoRouter.of(context).go('/reset_password');
                }*/
              },
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primaryContainer,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Verificar',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(width: 10),
                  Icon(Icons.check_circle_outline, size: 18),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
