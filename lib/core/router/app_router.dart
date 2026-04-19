import 'package:barberly/features/auth/presentation/screens/register_screen.dart';
import 'package:barberly/features/barber/dashboard/data/datasources/dashboard_mock_datasource.dart';
import 'package:barberly/features/barber/dashboard/data/repositories/dashboard_repository_impl.dart';
import 'package:barberly/features/barber/dashboard/domain/usecases/get_dashboard_data.dart';
import 'package:barberly/features/barber/dashboard/presentation/bloc/dashboard_cubit.dart';
import 'package:barberly/features/barber/dashboard/presentation/screens/dashboard_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

// ── Features ─────────────────────────────────────────────
import '../../features/welcome/presentation/screens/welcome_screen.dart';
import '../../features/welcome/presentation/bloc/welcome_bloc.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/barber/barbershop_profile/presentation/screens/perfil_barberia_screen.dart';
import '../../shared/widgets/main_shell.dart';
import '../../features/barber/barbershop_profile/data/datasources/barbershop_mock_datasource.dart';
import '../../features/barber/barbershop_profile/data/repositories/barbershop_repository_impl.dart';
import '../../features/barber/barbershop_profile/domain/usecases/confirm_booking.dart';
import '../../features/barber/barbershop_profile/domain/usecases/get_barbershop.dart';
import '../../features/barber/barbershop_profile/presentation/bloc/barbershop_profile/barbershop_profile_cubit.dart';
import '../../features/barber/barbershop_profile/presentation/bloc/booking/booking_cubit.dart';

// ── Router ───────────────────────────────────────────────
class AppRouter {
  AppRouter._();

  // ── Route paths ────────────────────────────────────────
  static const String welcome = '/';
  static const String login = '/login';
  static const String dashboard = '/dashboard';
  static const String home = '/home';
  static const String register = '/register';
  static const String perfilBarberia = '/perfil-barberia';

// ── Rutas dentro del shell (con bottom nav) ────────────
  static const String explorar = '/explorar';
  static const String citas = '/citas';
  static const String panel = '/panel';
  static const String perfil = '/perfil';

  // Helper: ruta completa para navegar
  static const String perfilBarberiaFull = '/perfil/perfil-barberia';

  // ── Router instance ────────────────────────────────────
  static final GoRouter router = GoRouter(
    initialLocation: explorar,
    debugLogDiagnostics: true,

    routes: [
      // ── Welcome ──────────────────────────────────────
      GoRoute(
        path: welcome,
        name: 'welcome',
        builder: (context, state) => BlocProvider(
          create: (_) => WelcomeBloc(),
          child: const WelcomeScreen(),
        ),
      ),

      // ── Login ────────────────────────────────────────
      GoRoute(
        path: login,
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),

      // ── Register ─────────────────────────────────────
      GoRoute(
        path: register,
        name: 'register',
        builder: (context, state) => const RegisterScreen(),
      ),

      // ── Shell con bottom nav ─────────────────────────
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            MainShell(navigationShell: navigationShell),
        branches: [
          // Branch 0: EXPLORAR
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: explorar,
                name: 'explorar',
                builder: (context, state) =>
                    const _PlaceholderScreen(title: 'Explorar'),
              ),
            ],
          ),

          // Branch 1: CITAS
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: citas,
                name: 'citas',
                builder: (context, state) =>
                    const _PlaceholderScreen(title: 'Citas'),
              ),
            ],
          ),

          // Branch 2: PANEL
StatefulShellBranch(
  routes: [
    GoRoute(
      path: panel,
      name: 'panel',
      builder: (context, state) {
        final ds = DashboardMockDataSource();
        final repo = DashboardRepositoryImpl(ds);
        final useCase = GetDashboardData(repo);
        return BlocProvider(
          create: (_) => DashboardCubit(useCase)..load('barber-1'),
          child: const DashboardScreen(),
        );
      },
    ),
  ],
),

          // Branch 3: PERFIL
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: perfil,
                name: 'perfil',
                builder: (context, state) {
                  // Service locator "pobre" — cuando integres get_it, se mueve allá.
                  final dataSource = BarbershopMockDataSource();
                  final repository = BarbershopRepositoryImpl(dataSource);
                  final getBarbershop = GetBarbershop(repository);
                  final confirmBooking = ConfirmBooking(repository);

                  final today = DateTime.now();
                  final startOfToday = DateTime(today.year, today.month, today.day);

                  return MultiBlocProvider(
                    providers: [
                      BlocProvider(
                        create: (_) => BarbershopProfileCubit(getBarbershop)
                          ..load('shop-1'),
                      ),
                      BlocProvider(
                        create: (_) => BookingCubit(
                          confirmBooking: confirmBooking,
                          barbershopId: 'shop-1',
                          initialDay: startOfToday,
                        ),
                      ),
                    ],
                    child: const PerfilBarberiaScreen(),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    ],
  );
}


// ── Placeholder temporal ─────────────────────────────────
class _PlaceholderScreen extends StatelessWidget {
  const _PlaceholderScreen({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text(
          '$title — Próximamente',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
      ),
    );
  }
}
