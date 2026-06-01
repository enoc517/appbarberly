import 'dart:io';
import 'dart:convert';
import 'dart:async';

import 'package:barberly/core/datasources/cloudinary_datasource.dart';
import 'package:barberly/core/datasources/user_validation_datasource.dart';
import 'package:barberly/core/theme/theme_cubit.dart';
import 'package:barberly/features/auth/domain/entities/app_user.dart';
import 'package:barberly/features/auth/domain/repositories/auth_repository.dart';
import 'package:barberly/features/auth/domain/usecases/get_current_user.dart';
import 'package:barberly/features/auth/domain/usecases/sign_out.dart';
import 'package:barberly/features/auth/domain/usecases/update_user_profile.dart';
import 'package:barberly/features/barber/account/presentation/cubit/barber_profile_cubit.dart';
import 'package:barberly/features/barber/account/presentation/screens/barber_account_screen.dart';
import 'package:barberly/features/client/profile/presentation/cubit/client_profile_cubit.dart';
import 'package:barberly/features/client/profile/presentation/screens/client_profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';

void main() {
  setUpAll(() {
    HttpOverrides.global = _TestHttpOverrides();
  });

  tearDownAll(() {
    HttpOverrides.global = null;
  });

  testWidgets('client profile avatar repaints after successful image save', (
    tester,
  ) async {
    final repository = _FakeAuthRepository(_clientUser());
    final uploader = _FakeImageUploader('https://cdn.test/client-avatar.jpg');
    final cubit = ClientProfileCubit(
      getCurrentUser: GetCurrentUserUseCase(repository),
      signOut: SignOutUseCase(repository),
      updateUserProfile: UpdateUserProfileUseCase(repository),
      imageUploader: uploader,
      userValidationDatasource: _FakeUserValidationDatasource(),
    );
    addTearDown(cubit.close);

    await _pumpClientProfile(tester, cubit);
    await cubit.loadData();
    await tester.pumpAndSettle();

    expect(_headerAvatar(tester).backgroundImage, isNull);

    await cubit.saveProfile(imageFile: XFile('client.jpg'));
    await tester.pumpAndSettle();

    expect(
      _headerAvatar(tester).backgroundImage,
      NetworkImage(uploader.nextUrl),
    );
  });

  testWidgets('barber profile avatar repaints after successful image save', (
    tester,
  ) async {
    final repository = _FakeAuthRepository(_barberUser());
    final uploader = _FakeImageUploader('https://cdn.test/barber-avatar.jpg');
    final cubit = BarberProfileCubit(
      getCurrentUser: GetCurrentUserUseCase(repository),
      signOut: SignOutUseCase(repository),
      updateUserProfile: UpdateUserProfileUseCase(repository),
      imageUploader: uploader,
      userValidationDatasource: _FakeUserValidationDatasource(),
    );
    addTearDown(cubit.close);

    await _pumpBarberProfile(tester, cubit);
    await cubit.loadData();
    await tester.pumpAndSettle();

    expect(_headerAvatar(tester).backgroundImage, isNull);

    await cubit.saveProfile(imageFile: XFile('barber.jpg'));
    await tester.pumpAndSettle();

    expect(
      _headerAvatar(tester).backgroundImage,
      NetworkImage(uploader.nextUrl),
    );
  });
}

Future<void> _pumpClientProfile(
  WidgetTester tester,
  ClientProfileCubit cubit,
) async {
  await tester.pumpWidget(
    MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => ThemeCubit()),
        BlocProvider.value(value: cubit),
      ],
      child: const MaterialApp(home: ClientProfileScreen()),
    ),
  );
}

Future<void> _pumpBarberProfile(
  WidgetTester tester,
  BarberProfileCubit cubit,
) async {
  await tester.pumpWidget(
    MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => ThemeCubit()),
        BlocProvider.value(value: cubit),
      ],
      child: const MaterialApp(home: BarberAccountScreen()),
    ),
  );
}

CircleAvatar _headerAvatar(WidgetTester tester) {
  return tester.widget<CircleAvatar>(
    find.byWidgetPredicate(
      (widget) => widget is CircleAvatar && widget.radius == 35,
    ),
  );
}

AppUser _clientUser() {
  return const AppUser(
    id: 'u-client',
    email: 'client@test.com',
    fullName: 'Client',
    role: UserRole.client,
    isProfessional: false,
    professionalStatus: ProfessionalStatus.none,
    emailVerified: true,
  );
}

AppUser _barberUser() {
  return const AppUser(
    id: 'u-barber',
    email: 'barber@test.com',
    fullName: 'Barber',
    role: UserRole.barber,
    isProfessional: true,
    professionalStatus: ProfessionalStatus.approved,
    emailVerified: true,
  );
}

class _FakeImageUploader implements ImageUploadDatasource {
  _FakeImageUploader(this.nextUrl);

  final String nextUrl;

  @override
  Future<String> uploadImage({
    required File file,
    required String folder,
    required String publicId,
  }) async {
    return nextUrl;
  }
}

class _FakeUserValidationDatasource implements UserValidationSource {
  @override
  Future<bool> isPhoneRegistered(String phone, {String? excludeUserId}) async {
    return false;
  }
}

class _FakeAuthRepository implements AuthRepository {
  _FakeAuthRepository(this.currentUser);

  AppUser currentUser;

  @override
  Future<AppUser?> getCurrentUser() async => currentUser;

  @override
  Future<void> updateUserProfile({
    required String uid,
    String? fullName,
    String? phone,
    String? profileImageUrl,
  }) async {
    currentUser = currentUser.copyWith(
      fullName: fullName,
      phone: phone,
      profileImageUrl: profileImageUrl,
    );
  }

  @override
  Future<AppUser> finalizeGoogleSignUp({required bool isProfessional}) async {
    return currentUser;
  }

  @override
  Future<void> sendEmailVerification() async {}

  @override
  Future<AppUser> signIn({required String email, required String password}) {
    return Future.value(currentUser);
  }

  @override
  Future<void> signOut() async {}

  @override
  Future<AppUser> signUp({
    required String fullName,
    required String phone,
    required String email,
    required String password,
    required bool isProfessional,
  }) async {
    return currentUser;
  }

  @override
  Future<AppUser?> signInWithGoogle() async => currentUser;
}

class _TestHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) => _TestHttpClient();
}

class _TestHttpClient implements HttpClient {
  @override
  bool autoUncompress = true;

  @override
  Future<HttpClientRequest> getUrl(Uri url) async => _TestHttpClientRequest();

  @override
  void close({bool force = false}) {}

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _TestHttpClientRequest implements HttpClientRequest {
  @override
  Future<HttpClientResponse> close() async => _TestHttpClientResponse();

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _TestHttpClientResponse extends Stream<List<int>>
    implements HttpClientResponse {
  static final _transparentPng = base64Decode(
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAF'
    'gwJ/l7Q4LgAAAABJRU5ErkJggg==',
  );

  @override
  int get statusCode => HttpStatus.ok;

  @override
  int get contentLength => _transparentPng.length;

  @override
  HttpClientResponseCompressionState get compressionState =>
      HttpClientResponseCompressionState.notCompressed;

  @override
  StreamSubscription<List<int>> listen(
    void Function(List<int> event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    return Stream<List<int>>.fromIterable([_transparentPng]).listen(
      onData,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
  }

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
