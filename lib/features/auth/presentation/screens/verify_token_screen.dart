import 'package:barberly/features/auth/presentation/widget/verify_token_form.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class VerifyTokenScreen extends StatelessWidget {
  const VerifyTokenScreen({super.key});

  static const String routeName = 'verify_token';
  static const String routePath = '/verify_token';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new,
            color: theme.colorScheme.onSurface,
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
