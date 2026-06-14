import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../features/auth/data/datasources/auth_remote_datasource.dart';
import '../../features/auth/data/datasources/password_recovery_remote_datasource.dart';
import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/auth/data/repositories/password_recovery_repository_impl.dart';
import '../../features/auth/domain/usecases/finalize_google_sign_up.dart';
import '../../features/auth/domain/usecases/get_current_user.dart';
import '../../features/auth/domain/usecases/send_password_reset_email.dart';
import '../../features/auth/domain/usecases/sign_in.dart';
import '../../features/auth/domain/usecases/sign_in_with_google.dart';
import '../../features/auth/domain/usecases/sign_out.dart';
import '../../features/auth/domain/usecases/sign_up.dart';
import '../../features/auth/domain/usecases/update_user_profile.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/auth/presentation/bloc/password_recovery_bloc.dart';
import '../../features/barber/barbershop_management/data/datasources/barbershop_management_remote_datasource.dart';
import '../../features/barber/barbershop_management/data/repositories/barbershop_management_repository_impl.dart';
import '../../features/barber/barbershop_management/data/repositories/barbershop_hub_repository_impl.dart';
import '../../features/barber/barbershop_management/domain/usecases/create_barbershop.dart';
import '../../features/barber/barbershop_management/domain/usecases/get_barbershop_by_owner.dart';
import '../../features/barber/barbershop_management/domain/usecases/update_barbershop.dart';
import '../../features/barber/barbershop_management/presentation/cubit/barbershop_management_cubit.dart';
import '../../features/barber/barbershop_management/presentation/cubit/barbershop_management_hub_cubit.dart';
import '../../features/barber/membership/data/datasources/membership_remote_datasource.dart';
import '../../features/barber/membership/data/repositories/membership_repository_impl.dart';
import '../../features/barber/membership/domain/usecases/get_barbershop_members.dart';
import '../../features/barber/membership/domain/usecases/get_pending_requests.dart';
import '../../features/barber/membership/domain/usecases/leave_barbershop.dart';
import '../../features/barber/membership/domain/usecases/review_membership_request.dart';
import '../../features/barber/membership/domain/usecases/search_barbershops.dart';
import '../../features/barber/membership/domain/usecases/send_membership_request.dart';
import '../../features/barber/membership/presentation/cubit/membership_requests_cubit.dart';
import '../../features/barber/membership/presentation/cubit/search_barbershops_cubit.dart';
import '../../features/barber/penalties/data/repositories/firestore_penalties_repository.dart';
import '../../features/barber/penalties/presentation/cubit/penalties_cubit.dart';
import '../../features/barber/services/data/datasources/barber_services_remote_datasource.dart';
import '../../features/barber/services/data/repositories/barber_services_repository_impl.dart';
import '../../features/barber/services/domain/usecases/add_service.dart';
import '../../features/barber/services/domain/usecases/delete_service.dart';
import '../../features/barber/services/domain/usecases/get_barber_schedule.dart';
import '../../features/barber/services/domain/usecases/get_barber_services.dart';
import '../../features/barber/services/domain/usecases/set_schedule.dart';
import '../../features/barber/services/domain/usecases/update_service.dart';
import '../../features/barber/services/presentation/cubit/barber_schedule_cubit.dart';
import '../../features/barber/services/presentation/cubit/barber_services_cubit.dart';
import '../../features/bookings/data/repositories/firestore_bookings_repository.dart';
import '../../features/bookings/domain/entities/booking.dart';
import '../../features/client/bookings/presentation/bloc/client_bookings_cubit.dart';
import '../../features/client/favorites/data/repositories/firestore_favorites_repository.dart';
import '../../features/client/favorites/presentation/bloc/favorites_cubit.dart';
import '../../features/client/favorites/domain/repositories/favorites_repository.dart';
import '../../features/explore/data/repositories/explore_repository_impl.dart';
import '../../features/explore/data/repositories/barbershop_detail_repository_impl.dart';
import '../../features/explore/data/repositories/barber_booking_repository_impl.dart';
import '../../features/explore/domain/repositories/explore_repository.dart';
import '../../features/explore/domain/repositories/barbershop_detail_repository.dart';
import '../../features/explore/domain/repositories/barber_booking_repository.dart';
import '../../features/reviews/data/repositories/firestore_reviews_repository.dart';
import '../../features/reviews/domain/repositories/reviews_repository.dart';
import '../../features/reviews/presentation/cubit/barbershop_reviews_cubit.dart';
import '../../features/explore/presentation/bloc/explore_bloc.dart';
import '../../features/explore/presentation/cubit/barbershop_detail_cubit.dart';
import '../../features/explore/presentation/cubit/barber_booking_cubit.dart';
import '../../features/notifications/data/repositories/firestore_notifications_repository.dart';
import '../../features/notifications/presentation/cubit/notifications_cubit.dart';
import '../../features/barber/dashboard/data/repositories/firestore_dashboard_repository.dart';
import '../../features/barber/dashboard/domain/usecases/get_dashboard_data.dart';
import '../../features/barber/dashboard/presentation/bloc/dashboard_cubit.dart';
import '../../features/barber/account/presentation/cubit/barber_profile_cubit.dart';
import '../../features/client/profile/presentation/cubit/client_profile_cubit.dart';
import '../../features/barber/agenda/presentation/bloc/barber_agenda_cubit.dart';
import '../../features/welcome/presentation/bloc/welcome_bloc.dart';
import '../datasources/cloudinary_datasource.dart';
import '../datasources/user_validation_datasource.dart';
import '../events/barbershop_event_bus.dart';
import '../theme/theme_cubit.dart';

class AppDependencies {
  AppDependencies._();

  static final FirebaseAuth firebaseAuth = FirebaseAuth.instance;
  static final FirebaseFirestore firestore = FirebaseFirestore.instance;
  static final GoogleSignIn googleSignIn = GoogleSignIn(
    scopes: const ['email'],
  );

  static final BarbershopEventBus barbershopEventBus =
      BarbershopEventBus.instance;

  static final ThemeCubit themeCubit = ThemeCubit();

  static final CloudinaryDatasource cloudinaryDatasource = CloudinaryDatasource(
    cloudName: 'ducfjckca',
    uploadPreset: 'mediaflows',
  );

  static final UserValidationDatasource userValidationDatasource =
      UserValidationDatasource(firestore: firestore);

  // Auth
  static final AuthRemoteDatasource authDatasource = AuthRemoteDatasourceImpl(
    firebaseAuth: firebaseAuth,
    firestore: firestore,
    googleSignIn: googleSignIn,
  );

  static final AuthRepositoryImpl authRepository = AuthRepositoryImpl(
    authDatasource,
  );
  static final GetCurrentUserUseCase getCurrentUserUseCase =
      GetCurrentUserUseCase(authRepository);
  static final SignInUseCase signInUseCase = SignInUseCase(authRepository);
  static final SignInWithGoogleUseCase signInWithGoogleUseCase =
      SignInWithGoogleUseCase(authRepository);
  static final FinalizeGoogleSignUpUseCase finalizeGoogleSignUpUseCase =
      FinalizeGoogleSignUpUseCase(authRepository);
  static final SignUpUseCase signUpUseCase = SignUpUseCase(authRepository);
  static final SignOutUseCase signOutUseCase = SignOutUseCase(authRepository);
  static final UpdateUserProfileUseCase updateUserProfileUseCase =
      UpdateUserProfileUseCase(authRepository);

  // Password Recovery
  static final PasswordRecoveryRemoteDatasource passwordRecoveryDatasource =
      PasswordRecoveryRemoteDatasourceImpl(firebaseAuth: firebaseAuth);
  static final PasswordRecoveryRepositoryImpl passwordRecoveryRepository =
      PasswordRecoveryRepositoryImpl(passwordRecoveryDatasource);
  static final SendPasswordResetEmailUseCase sendPasswordResetEmailUseCase =
      SendPasswordResetEmailUseCase(passwordRecoveryRepository);

  // Barbershop Management
  static final BarbershopManagementRemoteDatasource
  barbershopManagementDatasource = BarbershopManagementRemoteDatasourceImpl(
    firestore: firestore,
  );
  static final BarbershopManagementRepositoryImpl
  barbershopManagementRepository = BarbershopManagementRepositoryImpl(
    barbershopManagementDatasource,
  );
  static final CreateBarbershop createBarbershopUseCase = CreateBarbershop(
    barbershopManagementRepository,
  );
  static final UpdateBarbershop updateBarbershopUseCase = UpdateBarbershop(
    barbershopManagementRepository,
  );
  static final GetBarbershopByOwner getBarbershopByOwnerUseCase =
      GetBarbershopByOwner(barbershopManagementRepository);

  // Barbershop Hub
  static final BarbershopHubRepositoryImpl barbershopHubRepository =
      BarbershopHubRepositoryImpl(firestore: firestore);

  // Membership
  static final MembershipRemoteDatasource membershipDatasource =
      MembershipRemoteDatasourceImpl(firestore: firestore);
  static final MembershipRepositoryImpl membershipRepository =
      MembershipRepositoryImpl(membershipDatasource);
  static final SearchBarbershops searchBarbershopsUseCase = SearchBarbershops(
    membershipRepository,
  );
  static final SendMembershipRequest sendMembershipRequestUseCase =
      SendMembershipRequest(membershipRepository);
  static final GetPendingRequests getPendingRequestsUseCase =
      GetPendingRequests(membershipRepository);
  static final ReviewMembershipRequest reviewMembershipRequestUseCase =
      ReviewMembershipRequest(membershipRepository);
  static final GetBarbershopMembers getBarbershopMembersUseCase =
      GetBarbershopMembers(membershipRepository);
  static final LeaveBarbershop leaveBarbershopUseCase = LeaveBarbershop(
    membershipRepository,
  );

  // Explore
  static final ExploreRepository exploreRepository = ExploreRepositoryImpl(
    firestore: firestore,
  );

  static final ReviewsRepository reviewsRepository = FirestoreReviewsRepository(
    firestore: firestore,
  );
  // Explore — Barbershop Detail & Barber Booking
  static final BarbershopDetailRepository barbershopDetailRepository =
      BarbershopDetailRepositoryImpl(
        firestore: firestore,
        reviewsRepository: reviewsRepository,
      );
  static final BarberBookingRepository barberBookingRepository =
      BarberBookingRepositoryImpl(firestore: firestore);
  static final FavoritesRepository favoritesRepository =
      FirestoreFavoritesRepository(firestore: firestore);

  static BarbershopReviewsCubit buildBarbershopReviewsCubit(
    String barbershopId,
  ) {
    return BarbershopReviewsCubit(
      barbershopId: barbershopId,
      repository: reviewsRepository,
    );
  }

  // Notifications
  static final FirestoreNotificationsRepository notificationsRepository =
      FirestoreNotificationsRepository(firestore: firestore);

  // Services & Schedule
  static final BarberServicesRemoteDatasource barberServicesDatasource =
      BarberServicesRemoteDatasourceImpl(firestore: firestore);
  static final BarberServicesRepositoryImpl barberServicesRepository =
      BarberServicesRepositoryImpl(barberServicesDatasource);
  static final GetBarberServices getBarberServicesUseCase = GetBarberServices(
    barberServicesRepository,
  );
  static final AddService addServiceUseCase = AddService(
    barberServicesRepository,
  );
  static final UpdateService updateServiceUseCase = UpdateService(
    barberServicesRepository,
  );
  static final DeleteService deleteServiceUseCase = DeleteService(
    barberServicesRepository,
  );
  static final GetBarberSchedule getBarberScheduleUseCase = GetBarberSchedule(
    barberServicesRepository,
  );
  static final SetSchedule setScheduleUseCase = SetSchedule(
    barberServicesRepository,
  );

  // Factories
  static AuthBloc buildAuthBloc() {
    return AuthBloc(
      signInUseCase: signInUseCase,
      signUpUseCase: signUpUseCase,
      signInWithGoogleUseCase: signInWithGoogleUseCase,
      finalizeGoogleSignUpUseCase: finalizeGoogleSignUpUseCase,
      signOutUseCase: signOutUseCase,
      getCurrentUserUseCase: getCurrentUserUseCase,
    );
  }

  static BarbershopManagementCubit buildBarbershopManagementCubit() {
    return BarbershopManagementCubit(
      createBarbershop: createBarbershopUseCase,
      updateBarbershop: updateBarbershopUseCase,
      getBarbershopByOwner: getBarbershopByOwnerUseCase,
      imageUploader: cloudinaryDatasource,
      eventBus: barbershopEventBus,
    );
  }

  static BarbershopManagementHubCubit buildBarbershopManagementHubCubit() {
    return BarbershopManagementHubCubit(
      eventBus: barbershopEventBus,
      repository: barbershopHubRepository,
      userId: firebaseAuth.currentUser?.uid ?? '',
    );
  }

  static PasswordRecoveryBloc buildPasswordRecoveryBloc() {
    return PasswordRecoveryBloc(
      sendPasswordResetEmailUseCase: sendPasswordResetEmailUseCase,
    );
  }

  static WelcomeBloc buildWelcomeBloc() {
    return WelcomeBloc(getCurrentUserUseCase: getCurrentUserUseCase);
  }

  static BarberProfileCubit buildBarberProfileCubit() {
    return BarberProfileCubit(
      getCurrentUser: getCurrentUserUseCase,
      signOut: signOutUseCase,
      updateUserProfile: updateUserProfileUseCase,
      imageUploader: cloudinaryDatasource,
      userValidationDatasource: userValidationDatasource,
    );
  }

  static ClientProfileCubit buildClientProfileCubit() {
    return ClientProfileCubit(
      getCurrentUser: getCurrentUserUseCase,
      signOut: signOutUseCase,
      updateUserProfile: updateUserProfileUseCase,
      imageUploader: cloudinaryDatasource,
      userValidationDatasource: userValidationDatasource,
    );
  }

  static ExploreBloc buildExploreBloc() {
    return ExploreBloc(
      repository: exploreRepository,
      getCurrentUserUseCase: getCurrentUserUseCase,
    );
  }

  static BarbershopDetailCubit buildBarbershopDetailCubit(String shopId) {
    return BarbershopDetailCubit(
      shopId: shopId,
      userId: getCurrentUserId(),
      repository: barbershopDetailRepository,
      favoritesRepository: favoritesRepository,
    );
  }

  static BarberBookingCubit buildBarberBookingCubit({
    required String shopId,
    required String barberId,
    String? clientId,
    Booking? rescheduleBooking,
  }) {
    return BarberBookingCubit(
      shopId: shopId,
      barberId: barberId,
      clientId: clientId,
      rescheduleBooking: rescheduleBooking,
      repository: barberBookingRepository,
      favoritesRepository: favoritesRepository,
      eventBus: barbershopEventBus,
    );
  }

  static ClientBookingsCubit buildClientBookingsCubit(String userId) {
    return ClientBookingsCubit(
      repository: FirestoreBookingsRepository(firestore: firestore),
      reviewsRepository: reviewsRepository,
      clientId: userId,
      eventBus: barbershopEventBus,
    )..watch();
  }

  static FavoritesCubit buildFavoritesCubit(String userId) {
    return FavoritesCubit(repository: favoritesRepository, userId: userId)
      ..watch();
  }

  static DashboardCubit buildDashboardCubit(String userId) {
    final repo = FirestoreDashboardRepository(
      firestore: firestore,
      userId: userId,
    );
    final useCase = GetDashboardData(repo);
    return DashboardCubit(getData: useCase, eventBus: barbershopEventBus)
      ..load(userId);
  }

  static BarberAgendaCubit buildBarberAgendaCubit(String userId) {
    return BarberAgendaCubit(
      bookingsRepository: FirestoreBookingsRepository(firestore: firestore),
      firestore: firestore,
      getBarberSchedule: getBarberScheduleUseCase,
      userId: userId,
      eventBus: barbershopEventBus,
    )..load();
  }

  static SearchBarbershopsCubit buildSearchBarbershopsCubit() {
    return SearchBarbershopsCubit(
      searchBarbershops: searchBarbershopsUseCase,
      sendMembershipRequest: sendMembershipRequestUseCase,
    );
  }

  static MembershipRequestsCubit buildMembershipRequestsCubit() {
    return MembershipRequestsCubit(
      getPendingRequests: getPendingRequestsUseCase,
      reviewMembershipRequest: reviewMembershipRequestUseCase,
    );
  }

  static BarberServicesCubit buildBarberServicesCubit() {
    return BarberServicesCubit(
      getBarberServices: getBarberServicesUseCase,
      addService: addServiceUseCase,
      updateService: updateServiceUseCase,
      deleteService: deleteServiceUseCase,
    );
  }

  static BarberScheduleCubit buildBarberScheduleCubit() {
    return BarberScheduleCubit(
      getBarberSchedule: getBarberScheduleUseCase,
      setSchedule: setScheduleUseCase,
    );
  }

  static PenaltiesCubit buildPenaltiesCubit(String barbershopId) {
    return PenaltiesCubit(
      repository: FirestorePenaltiesRepository(firestore: firestore),
      barbershopId: barbershopId,
    )..watch();
  }

  static NotificationsCubit buildNotificationsCubit(String userId) {
    return NotificationsCubit(
      repository: notificationsRepository,
      userId: userId,
    )..watch();
  }

  static Future<String> getCurrentBarbershopId(String userId) async {
    if (userId.isEmpty) return '';
    final doc = await firestore.collection('users').doc(userId).get();
    final data = doc.data();
    return data?['barbershopId'] as String? ?? '';
  }

  static String? getCurrentUserId() => firebaseAuth.currentUser?.uid;
  static String? getCurrentUserName() => firebaseAuth.currentUser?.displayName;
  static String? getCurrentUserEmail() => firebaseAuth.currentUser?.email;
}
