# AGENTS.md

## Project Overview

Flutter app (barberly) for booking barbershop appointments. Firebase backend with Auth, Firestore, and Google Sign-in. Clean Architecture with feature-based modules.

## Key Commands

- `flutter run` — run the app
- `flutter build apk --debug` — build Android debug APK
- `flutter analyze` — run static analysis (the only lint/typecheck step; no separate typecheck command)

## Architecture

- **Clean Architecture**: each feature has `domain/` (entities, repositories interfaces, usecases), `data/` (models, datasources, repository implementations), `presentation/` (screens, widgets, bloc/cubit).
- **Entry point**: `lib/main.dart` → `lib/app.dart` → `lib/core/router/app_router.dart`
- **DI**: Manual static factory class `AppDependencies` in `lib/core/di/app_dependencies.dart`. All bloc/cubit creation goes through factory methods here.
- **State management**: `flutter_bloc` — screens receive pre-built blocs via `BlocProvider`. BLoCs for complex auth flows; Cubits for feature-specific state.

## Navigation

`GoRouter` with a `StatefulShellRoute.indexedStack` for the bottom navigation bar. The shell renders all 8 branches but screens are role-gated at runtime.

Route params are accessed via `state.pathParameters` inside `GoRoute.builder` closures.

## Firebase Setup

- `lib/firebase_options.dart` holds `DefaultFirebaseOptions.currentPlatform`.
- Android requires `android/app/google-services.json`; iOS requires `ios/Runner/GoogleService-Info.plist`.
- Missing config files cause `Firebase.initializeApp` to throw at runtime.

## Assets

Three asset directories in `pubspec.yaml`: `assets/images/`, `assets/icons/`, `assets/logos/`.

## Testing

No test files exist (`test/` is empty). Use `flutter_test` (dev dependency present). Prefer widget tests for UI, unit tests for cubits/usecases.

## Key Dependencies

| Package | Version | Purpose |
|---|---|---|
| firebase_core | ^4.6.0 | Firebase init |
| firebase_auth | ^6.3.0 | Auth |
| cloud_firestore | ^6.2.0 | Database |
| flutter_bloc | ^9.1.1 | State management |
| go_router | ^17.2.0 | Navigation |
| equatable | ^2.0.3 | Value equality |
| google_sign_in | ^6.2.2 | Google OAuth |
| geoflutterfire_plus | ^0.0.34 | Geolocation queries |
| geolocator | ^13.0.2 | GPS access |
| flutter_map | ^7.0.2 | OpenStreetMap |
| latlong2 | ^0.9.1 | Lat/lng utilities |
