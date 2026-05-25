import 'package:flutter/material.dart';

import 'core/router/app_router.dart';
import 'shared/theme/app_theme.dart';

/// Root application widget.
///
/// Applies the Celestial Tailor theme and wires up GoRouter.
class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Barberly',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      routerConfig: AppRouter.router,
    );
  }
}
