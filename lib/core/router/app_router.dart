// lib/core/router/app_router.dart
// ===========================================================================

// Flutter & External Packages
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

// Shared
import 'package:barberly/shared/widgets/main_shell.dart';

// Core DI
import 'package:barberly/core/di/app_dependencies.dart';

// Features: Auth
import 'package:barberly/features/auth/presentation/screens/forgot_password_screen.dart';
import 'package:barberly/features/auth/presentation/screens/google_role_screen.dart';
import 'package:barberly/features/auth/presentation/screens/login_screen.dart';
import 'package:barberly/features/auth/presentation/screens/professional_status_screen.dart';
import 'package:barberly/features/auth/presentation/screens/register_screen.dart';
import 'package:barberly/features/auth/presentation/screens/verify_email_screen.dart';

// Features: Client
import 'package:barberly/features/client/bookings/presentation/screens/client_bookings_screen.dart';
import 'package:barberly/features/client/favorites/presentation/screens/favorites_screen.dart';
import 'package:barberly/features/client/profile/presentation/screens/client_profile_screen.dart';

// Features: Barber (Account / Agenda)
import 'package:barberly/features/barber/account/presentation/screens/barber_account_screen.dart';
import 'package:barberly/features/barber/agenda/presentation/screens/barber_agenda_screen.dart';

// Features: Barber (Barbershop Management)
import 'package:barberly/features/barber/barbershop_management/presentation/screens/create_barbershop_screen.dart';
import 'package:barberly/features/barber/barbershop_management/presentation/screens/barbershop_management_screen.dart';

// Features: Barber (Dashboard)
import 'package:barberly/features/barber/dashboard/presentation/screens/dashboard_screen.dart';

// Features: Barber (Membership)
import 'package:barberly/features/barber/membership/presentation/screens/search_barbershops_screen.dart';
import 'package:barberly/features/barber/membership/presentation/screens/membership_requests_screen.dart';
import 'package:barberly/features/barber/penalties/presentation/screens/penalties_screen.dart';

// Features: Barber (Services & Schedule)
import 'package:barberly/features/barber/services/presentation/screens/manage_services_screen.dart';
import 'package:barberly/features/barber/services/presentation/screens/manage_schedule_screen.dart';

// Features: Explore
import 'package:barberly/features/explore/presentation/screens/explore_screen.dart';
import 'package:barberly/features/explore/presentation/screens/barbershop_detail_screen.dart';
import 'package:barberly/features/explore/presentation/screens/barber_booking_screen.dart';

// Features: Notifications
import 'package:barberly/features/notifications/presentation/screens/notifications_screen.dart';

// Features: Welcome
import 'package:barberly/features/welcome/presentation/screens/welcome_screen.dart';

class AppRouter {
  AppRouter._();

  // ── Route paths ─────────────────────────────────────────────────────────────
  static const String welcome = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String verifyEmail = '/verify-email';
  static const String googleRole = '/google-role';
  static const String professionalStatus = '/professional-status';
  static const String explorar = '/explorar';
  static const String citas = '/citas';
  static const String favoritos = '/favoritos';
  static const String perfil = '/perfil';
  static const String panel = '/panel';
  static const String agenda = '/agenda';
  static const String barberia = '/barberia';
  static const String cuentaBarbero = '/cuenta-barbero';
  static const String crearBarberia = '/crear-barberia';
  static const String forgotPassword = '/forgot_password';
  static const String notifications = '/notificaciones';

  // ── Auth guard helpers ───────────────────────────────────────────────────────
  static bool _isProtectedRoute(String path) {
    const protected = [
      explorar,
      citas,
      favoritos,
      perfil,
      panel,
      agenda,
      barberia,
      cuentaBarbero,
      notifications,
    ];
    for (final p in protected) {
      if (path == p || path.startsWith('$p/')) return true;
    }
    return false;
  }

  // ── Router ───────────────────────────────────────────────────────────────────
  static final GoRouter router = GoRouter(
    initialLocation: welcome,
    debugLogDiagnostics: true,
    redirect: (context, state) {
      final path = state.uri.path;
      if (!_isProtectedRoute(path)) return null;

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return login;
      if (!user.emailVerified) return verifyEmail;
      return null;
    },
    routes: [
      GoRoute(
        path: welcome,
        name: 'welcome',
        builder: (context, state) => BlocProvider(
          create: (_) => AppDependencies.buildWelcomeBloc(),
          child: const WelcomeScreen(),
        ),
      ),
      GoRoute(
        path: login,
        name: 'login',
        builder: (context, state) => BlocProvider(
          create: (_) => AppDependencies.buildAuthBloc(),
          child: const LoginScreen(),
        ),
      ),
      GoRoute(
        path: register,
        name: 'register',
        builder: (context, state) => BlocProvider(
          create: (_) => AppDependencies.buildAuthBloc(),
          child: const RegisterScreen(),
        ),
      ),
      GoRoute(
        path: verifyEmail,
        name: 'verify-email',
        builder: (context, state) => BlocProvider(
          create: (_) => AppDependencies.buildAuthBloc(),
          child: const VerifyEmailScreen(),
        ),
      ),
      GoRoute(
        path: googleRole,
        name: 'google-role',
        builder: (context, state) => BlocProvider(
          create: (_) => AppDependencies.buildAuthBloc(),
          child: const GoogleRoleScreen(),
        ),
      ),
      GoRoute(
        path: professionalStatus,
        name: 'professional-status',
        builder: (context, state) => BlocProvider(
          create: (_) => AppDependencies.buildAuthBloc(),
          child: const ProfessionalStatusScreen(),
        ),
      ),

      // ── Password recovery shell ──────────────────────────────────────────────
      ShellRoute(
        builder: (context, state, child) => BlocProvider(
          create: (_) => AppDependencies.buildPasswordRecoveryBloc(),
          child: child,
        ),
        routes: [
          GoRoute(
            path: forgotPassword,
            name: 'forgotPassword',
            builder: (context, state) => const ForgotPasswordScreen(),
          ),
        ],
      ),

      // ── Client-facing barbershop routes ────────────────────────────────────────
      GoRoute(
        path: '/barberia/:shopId',
        name: 'barbershopDetail',
        builder: (context, state) {
          final shopId = state.pathParameters['shopId'] ?? '';
          return BlocProvider(
            create: (_) =>
                AppDependencies.buildBarbershopDetailCubit(shopId)..loadData(),
            child: const BarbershopDetailScreen(),
          );
        },
        routes: [
          GoRoute(
            path: 'barbero/:barberId',
            name: 'barberBooking',
            builder: (context, state) {
              final shopId = state.pathParameters['shopId'] ?? '';
              final barberId = state.pathParameters['barberId'] ?? '';
              final clientId = AppDependencies.getCurrentUserId();
              return BlocProvider(
                create: (_) => AppDependencies.buildBarberBookingCubit(
                  shopId: shopId,
                  barberId: barberId,
                  clientId: clientId,
                )..loadData(),
                child: const BarberBookingScreen(),
              );
            },
          ),
        ],
      ),

      GoRoute(
        path: notifications,
        name: 'notifications',
        builder: (context, state) {
          final userId = AppDependencies.getCurrentUserId() ?? '';
          return BlocProvider(
            create: (_) => AppDependencies.buildNotificationsCubit(userId),
            child: const NotificationsScreen(),
          );
        },
      ),

      // ── Shell con bottom nav por rol ─────────────────────────────────────────
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            MainShell(navigationShell: navigationShell),
        branches: [
          // Branch 0: CLIENTE / EXPLORAR
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: explorar,
                name: 'explorar',
                builder: (context, state) => BlocProvider(
                  create: (_) => AppDependencies.buildExploreBloc(),
                  child: const ExploreScreen(),
                ),
              ),
            ],
          ),

          // Branch 1: CLIENTE / CITAS
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: citas,
                name: 'citas',
                builder: (context, state) {
                  final userId = AppDependencies.getCurrentUserId() ?? '';
                  return BlocProvider(
                    create: (_) =>
                        AppDependencies.buildClientBookingsCubit(userId),
                    child: const ClientBookingsScreen(),
                  );
                },
              ),
            ],
          ),

          // Branch 2: CLIENTE / FAVORITOS
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: favoritos,
                name: 'favoritos',
                builder: (context, state) {
                  final userId = AppDependencies.getCurrentUserId() ?? '';
                  return BlocProvider(
                    create: (_) => AppDependencies.buildFavoritesCubit(userId),
                    child: const FavoritesScreen(),
                  );
                },
              ),
            ],
          ),

          // Branch 3: CLIENTE / PERFIL
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: perfil,
                name: 'perfil',
                builder: (context, state) => BlocProvider(
                  create: (_) =>
                      AppDependencies.buildClientProfileCubit()..loadData(),
                  child: const ClientProfileScreen(),
                ),
              ),
            ],
          ),

          // Branch 4: BARBERO / PANEL
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: panel,
                name: 'panel',
                builder: (context, state) {
                  final userId = AppDependencies.getCurrentUserId() ?? '';
                  return BlocProvider(
                    create: (_) => AppDependencies.buildDashboardCubit(userId),
                    child: const DashboardScreen(),
                  );
                },
              ),
            ],
          ),

          // Branch 5: BARBERO / AGENDA
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: agenda,
                name: 'agenda',
                builder: (context, state) {
                  final userId = AppDependencies.getCurrentUserId() ?? '';
                  return BlocProvider(
                    create: (_) =>
                        AppDependencies.buildBarberAgendaCubit(userId),
                    child: const BarberAgendaScreen(),
                  );
                },
              ),
            ],
          ),

          // Branch 6: BARBERO / BARBERIA (Hub de gestión)
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: barberia,
                name: 'barberia',
                builder: (context, state) {
                  return BlocProvider(
                    create: (_) =>
                        AppDependencies.buildBarbershopManagementHubCubit(),
                    child: const BarbershopManagementScreen(),
                  );
                },
              ),
            ],
          ),

          // Branch 7: BARBERO / PERFIL
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: cuentaBarbero,
                name: 'cuentaBarbero',
                builder: (context, state) => BlocProvider(
                  create: (_) =>
                      AppDependencies.buildBarberProfileCubit()..loadData(),
                  child: const BarberAccountScreen(),
                ),
                routes: [
                  GoRoute(
                    path: 'crear-barberia',
                    name: 'crearBarberia',
                    builder: (context, state) {
                      final userId = AppDependencies.getCurrentUserId() ?? '';
                      final userName =
                          AppDependencies.getCurrentUserName() ?? '';
                      return BlocProvider(
                        create: (_) =>
                            AppDependencies.buildBarbershopManagementCubit(),
                        child: CreateBarbershopScreen(
                          userId: userId,
                          userName: userName,
                        ),
                      );
                    },
                  ),
                  GoRoute(
                    path: 'editar-barberia',
                    name: 'editarBarberia',
                    builder: (context, state) {
                      final userId = AppDependencies.getCurrentUserId() ?? '';
                      return BlocProvider(
                        create: (_) =>
                            AppDependencies.buildBarbershopManagementCubit(),
                        child: EditBarbershopScreen(userId: userId),
                      );
                    },
                  ),
                  GoRoute(
                    path: 'buscar-barberias',
                    name: 'buscarBarberias',
                    builder: (context, state) {
                      final userId = AppDependencies.getCurrentUserId() ?? '';
                      final userName =
                          AppDependencies.getCurrentUserName() ?? '';
                      final userEmail =
                          AppDependencies.getCurrentUserEmail() ?? '';
                      return BlocProvider(
                        create: (_) =>
                            AppDependencies.buildSearchBarbershopsCubit(),
                        child: SearchBarbershopsScreen(
                          barberId: userId,
                          barberName: userName,
                          barberEmail: userEmail,
                        ),
                      );
                    },
                  ),
                  GoRoute(
                    path: 'solicitudes',
                    name: 'solicitudes',
                    builder: (context, state) {
                      final userId = AppDependencies.getCurrentUserId() ?? '';
                      return FutureBuilder<String>(
                        future: AppDependencies.getCurrentBarbershopId(userId),
                        builder: (context, snapshot) {
                          final barbershopId = snapshot.data ?? '';
                          return BlocProvider(
                            create: (_) =>
                                AppDependencies.buildMembershipRequestsCubit(),
                            child: MembershipRequestsScreen(
                              barbershopId: barbershopId,
                              reviewerId: userId,
                            ),
                          );
                        },
                      );
                    },
                  ),
                  GoRoute(
                    path: 'penalizaciones',
                    name: 'penalizaciones',
                    builder: (context, state) {
                      final userId = AppDependencies.getCurrentUserId() ?? '';
                      return FutureBuilder<String>(
                        future: AppDependencies.getCurrentBarbershopId(userId),
                        builder: (context, snapshot) {
                          final barbershopId = snapshot.data ?? '';
                          return BlocProvider(
                            create: (_) => AppDependencies.buildPenaltiesCubit(
                              barbershopId,
                            ),
                            child: const PenaltiesScreen(),
                          );
                        },
                      );
                    },
                  ),
                  GoRoute(
                    path: 'mis-servicios',
                    name: 'misServicios',
                    builder: (context, state) {
                      final userId = AppDependencies.getCurrentUserId() ?? '';
                      return FutureBuilder<String>(
                        future: AppDependencies.getCurrentBarbershopId(userId),
                        builder: (context, snapshot) {
                          final barbershopId = snapshot.data ?? '';
                          return BlocProvider(
                            create: (_) =>
                                AppDependencies.buildBarberServicesCubit(),
                            child: ManageServicesScreen(
                              barbershopId: barbershopId,
                              barberId: userId,
                            ),
                          );
                        },
                      );
                    },
                  ),
                  GoRoute(
                    path: 'mi-horario',
                    name: 'miHorario',
                    builder: (context, state) {
                      final userId = AppDependencies.getCurrentUserId() ?? '';
                      return FutureBuilder<String>(
                        future: AppDependencies.getCurrentBarbershopId(userId),
                        builder: (context, snapshot) {
                          final barbershopId = snapshot.data ?? '';
                          return BlocProvider(
                            create: (_) =>
                                AppDependencies.buildBarberScheduleCubit(),
                            child: ManageScheduleScreen(
                              barbershopId: barbershopId,
                              barberId: userId,
                            ),
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ],
  );
}
