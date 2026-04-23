import 'package:barberly/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:barberly/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:barberly/features/auth/domain/usecases/get_current_user.dart';
import 'package:barberly/features/auth/domain/usecases/send_email_verification.dart';
import 'package:barberly/features/auth/domain/usecases/sign_in.dart';
import 'package:barberly/features/auth/domain/usecases/sign_out.dart';
import 'package:barberly/features/auth/domain/usecases/sign_up.dart';
import 'package:barberly/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:barberly/features/auth/presentation/bloc/auth_event.dart';
import 'package:barberly/features/auth/presentation/screens/login_screen.dart';
import 'package:barberly/features/auth/presentation/screens/register_screen.dart';
import 'package:barberly/features/auth/presentation/screens/verify_email_screen.dart';
import 'package:barberly/features/barber/barbershop_profile/data/datasources/barbershop_mock_datasource.dart';
import 'package:barberly/features/barber/barbershop_profile/data/repositories/barbershop_repository_impl.dart';
import 'package:barberly/features/barber/barbershop_profile/domain/usecases/confirm_booking.dart';
import 'package:barberly/features/barber/barbershop_profile/domain/usecases/get_barbershop.dart';
import 'package:barberly/features/barber/barbershop_profile/presentation/bloc/barbershop_profile/barbershop_profile_cubit.dart';
import 'package:barberly/features/barber/barbershop_profile/presentation/bloc/booking/booking_cubit.dart';
import 'package:barberly/features/barber/barbershop_profile/presentation/screens/perfil_barberia_screen.dart';
import 'package:barberly/features/barber/dashboard/data/datasources/dashboard_mock_datasource.dart';
import 'package:barberly/features/barber/dashboard/data/repositories/dashboard_repository_impl.dart';
import 'package:barberly/features/barber/dashboard/domain/usecases/get_dashboard_data.dart';
import 'package:barberly/features/barber/dashboard/presentation/bloc/dashboard_cubit.dart';
import 'package:barberly/features/barber/dashboard/presentation/screens/dashboard_screen.dart';
import 'package:barberly/features/welcome/presentation/bloc/welcome_bloc.dart';
import 'package:barberly/features/welcome/presentation/screens/welcome_screen.dart';
import 'package:barberly/shared/widgets/main_shell.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class AppRouter {
  AppRouter._();

  // ── Route paths ────────────────────────────────────────
  static const String welcome = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String dashboard = '/dashboard';
  static const String home = '/home';
  static const String perfilBarberia = '/perfil-barberia';

  // ── Rutas dentro del shell (con bottom nav) ────────────
  static const String explorar = '/explorar';
  static const String citas = '/citas';
  static const String panel = '/panel';
  static const String perfil = '/perfil';

  // Ruta completa si luego la usas desde navegación anidada.
  static const String perfilBarberiaFull = '/perfil/perfil-barberia';

  // ── Firebase / Auth stack ──────────────────────────────
  static final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static final AuthRemoteDatasource _authDatasource = AuthRemoteDatasourceImpl(
    firebaseAuth: _firebaseAuth,
    firestore: _firestore,
  );

  static final AuthRepositoryImpl _authRepository = AuthRepositoryImpl(
    _authDatasource,
  );

  static final GetCurrentUserUseCase _getCurrentUserUseCase =
      GetCurrentUserUseCase(_authRepository);

  static AuthBloc _buildAuthBloc() {
    return AuthBloc(
      signInUseCase: _signInUseCase,
      signUpUseCase: _signUpUseCase,
      signOutUseCase: _signOutUseCase,
      getCurrentUserUseCase: _getCurrentUserUseCase,
      sendEmailVerificationUseCase: _sendEmailVerificationUseCase,
    );
  }

  static final SignInUseCase _signInUseCase = SignInUseCase(_authRepository);
  static final SignUpUseCase _signUpUseCase = SignUpUseCase(_authRepository);
  static final SignOutUseCase _signOutUseCase = SignOutUseCase(_authRepository);
  static final SendEmailVerificationUseCase _sendEmailVerificationUseCase =
      SendEmailVerificationUseCase(_authRepository);

  static final GoRouter router = GoRouter(
    initialLocation: welcome,
    debugLogDiagnostics: true,
    routes: [
      GoRoute(
        path: welcome,
        name: 'welcome',
        builder: (context, state) => BlocProvider(
          create: (_) =>
              WelcomeBloc(getCurrentUserUseCase: _getCurrentUserUseCase),
          child: const WelcomeScreen(),
        ),
      ),
      GoRoute(
        path: login,
        name: 'login',
        builder: (context, state) => BlocProvider(
          create: (_) => _buildAuthBloc(),
          child: const LoginScreen(),
        ),
      ),
      GoRoute(
        path: register,
        name: 'register',
        builder: (context, state) => BlocProvider(
          create: (_) => _buildAuthBloc(),
          child: const RegisterScreen(),
        ),
      ),
      GoRoute(
        path: '/verify-email',
        name: 'verify-email',
        builder: (context, state) => BlocProvider(
          create: (_) => _buildAuthBloc()..add(const AuthLoadCurrentUserRequested()),
          child: const VerifyEmailScreen(),
        ),
      ),
      // ── Shell con bottom nav ─────────────────────────────
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
                  final dataSource = BarbershopMockDataSource();
                  final repository = BarbershopRepositoryImpl(dataSource);
                  final getBarbershop = GetBarbershop(repository);
                  final confirmBooking = ConfirmBooking(repository);

                  final today = DateTime.now();
                  final startOfToday = DateTime(
                    today.year,
                    today.month,
                    today.day,
                  );

                  return MultiBlocProvider(
                    providers: [
                      BlocProvider(
                        create: (_) =>
                            BarbershopProfileCubit(getBarbershop)
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
