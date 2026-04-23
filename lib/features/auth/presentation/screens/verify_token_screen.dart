import 'package:barberly/features/auth/presentation/widget/verify_token_form.dart';
import 'package:barberly/shared/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class VerifyTokenScreen extends StatelessWidget {
  const VerifyTokenScreen({super.key});

  static const String routeName = 'verify_token';
  static const String routePath = '/verify_token';

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
          onPressed: () => GoRouter.of(context).go('/login'),
        ),        
        centerTitle: true,
      ),
      body: const SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.0),
          child: VerifyTokenForm(),
        ),
      ),
    );
  }
}
