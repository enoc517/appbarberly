import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../domain/entities/app_user.dart';
import '../models/app_user_model.dart';

AppUserModel reconstructAuthProfile(
  AppUserModel profile, {
  required bool emailVerified,
}) {
  return AppUserModel(
    id: profile.id,
    email: profile.email,
    fullName: profile.fullName,
    phone: profile.phone,
    profileImageUrl: profile.profileImageUrl,
    role: profile.role,
    isProfessional: profile.isProfessional,
    professionalStatus: profile.professionalStatus,
    emailVerified: emailVerified,
    barbershopId: profile.barbershopId,
    activeBookingId: profile.activeBookingId,
    activeBookingStatus: profile.activeBookingStatus,
  );
}

abstract class AuthRemoteDatasource {
  Future<AppUserModel> signIn({
    required String email,
    required String password,
  });

  Future<AppUserModel?> signInWithGoogle();

  Future<AppUserModel> finalizeGoogleSignUp({required bool isProfessional});

  Future<AppUserModel> signUp({
    required String fullName,
    required String phone,
    required String email,
    required String password,
    required bool isProfessional,
  });

  Future<AppUserModel?> getCurrentUser();

  Future<void> signOut();

  Future<void> sendEmailVerification();

  Future<void> updateUserProfile({
    required String uid,
    String? fullName,
    String? phone,
    String? profileImageUrl,
  });
}

class AuthRemoteDatasourceImpl implements AuthRemoteDatasource {
  AuthRemoteDatasourceImpl({
    FirebaseAuth? firebaseAuth,
    FirebaseFirestore? firestore,
    GoogleSignIn? googleSignIn,
  }) : _auth = firebaseAuth ?? FirebaseAuth.instance,
       _firestore = firestore ?? FirebaseFirestore.instance,
       _googleSignIn = googleSignIn ?? GoogleSignIn(scopes: const ['email']);

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final GoogleSignIn _googleSignIn;

  CollectionReference<Map<String, dynamic>> get _usersCollection =>
      _firestore.collection('users');

  CollectionReference<Map<String, dynamic>>
  get _professionalRequestsCollection =>
      _firestore.collection('professional_requests');

  DocumentReference<Map<String, dynamic>> _userDoc(String uid) =>
      _usersCollection.doc(uid);

  @override
  Future<AppUserModel> signIn({
    required String email,
    required String password,
  }) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    final user = credential.user;
    if (user == null) {
      throw FirebaseAuthException(
        code: 'user-not-found',
        message: 'No se pudo obtener el usuario.',
      );
    }

    await user.reload();
    final currentUser = _auth.currentUser ?? user;
    final verified = currentUser.emailVerified;

    final profile = await _readUserProfile(currentUser.uid);
    if (profile != null) {
      final updatedProfile = reconstructAuthProfile(
        profile,
        emailVerified: verified,
      );

      if (profile.emailVerified != verified) {
        await _userDoc(currentUser.uid).set({
          'emailVerified': verified,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }

      return updatedProfile;
    }

    final fallback = AppUserModel.fromFirebaseUser(
      currentUser,
      role: UserRole.client,
      isProfessional: false,
      professionalStatus: ProfessionalStatus.none,
      emailVerified: verified,
    );

    await _userDoc(
      currentUser.uid,
    ).set(fallback.toMap(includeCreatedAt: true), SetOptions(merge: true));

    return fallback;
  }

  @override
  Future<AppUserModel?> signInWithGoogle() async {
    final googleUser = await _googleSignIn.signIn();
    if (googleUser == null) {
      throw FirebaseAuthException(
        code: 'google-sign-in-cancelled',
        message: 'El usuario canceló el inicio de sesión con Google.',
      );
    }

    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    final authCredential = await _auth.signInWithCredential(credential);
    final user = authCredential.user;
    if (user == null) {
      throw FirebaseAuthException(
        code: 'user-not-found',
        message: 'No se pudo obtener el usuario de Google.',
      );
    }

    final profile = await _readUserProfile(user.uid);
    if (profile == null) return null;

    if (!profile.emailVerified) {
      await _userDoc(user.uid).set({
        'emailVerified': true,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }

    return reconstructAuthProfile(profile, emailVerified: true);
  }

  @override
  Future<AppUserModel> finalizeGoogleSignUp({
    required bool isProfessional,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw FirebaseAuthException(
        code: 'user-not-found',
        message: 'No hay usuario autenticado con Google.',
      );
    }

    final model = AppUserModel.fromFirebaseUser(
      user,
      role: UserRole.client,
      isProfessional: isProfessional,
      professionalStatus: isProfessional
          ? ProfessionalStatus.pending
          : ProfessionalStatus.none,
      emailVerified: true,
    );

    await _userDoc(
      user.uid,
    ).set(model.toMap(includeCreatedAt: true), SetOptions(merge: true));

    if (isProfessional) {
      await _createProfessionalRequest(model);
    }

    return model;
  }

  @override
  Future<AppUserModel> signUp({
    required String fullName,
    required String phone,
    required String email,
    required String password,
    required bool isProfessional,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    final user = credential.user;
    if (user == null) {
      throw FirebaseAuthException(
        code: 'user-not-found',
        message: 'No se pudo crear el usuario.',
      );
    }

    await user.updateDisplayName(fullName.trim());

    final model = AppUserModel(
      id: user.uid,
      email: email.trim(),
      fullName: fullName.trim(),
      phone: phone.trim(),
      role: UserRole.client,
      isProfessional: isProfessional,
      professionalStatus: isProfessional
          ? ProfessionalStatus.pending
          : ProfessionalStatus.none,
      emailVerified: user.emailVerified,
    );

    await _userDoc(
      user.uid,
    ).set(model.toMap(includeCreatedAt: true), SetOptions(merge: true));

    if (isProfessional) {
      await _createProfessionalRequest(model);
    }

    await user.sendEmailVerification();

    return model;
  }

  @override
  Future<AppUserModel?> getCurrentUser() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    await user.reload();
    final currentUser = _auth.currentUser ?? user;
    final verified = currentUser.emailVerified;

    final profile = await _readUserProfile(currentUser.uid);
    if (profile != null) {
      final updatedProfile = reconstructAuthProfile(
        profile,
        emailVerified: verified,
      );

      if (profile.emailVerified != verified) {
        await _userDoc(currentUser.uid).set({
          'emailVerified': verified,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }

      return updatedProfile;
    }

    final fallback = AppUserModel.fromFirebaseUser(
      currentUser,
      role: UserRole.client,
      isProfessional: false,
      professionalStatus: ProfessionalStatus.none,
      emailVerified: verified,
    );

    await _userDoc(
      currentUser.uid,
    ).set(fallback.toMap(includeCreatedAt: true), SetOptions(merge: true));

    return fallback;
  }

  @override
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }

  @override
  Future<void> sendEmailVerification() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw FirebaseAuthException(
        code: 'user-not-found',
        message: 'No hay usuario autenticado para enviar verificación.',
      );
    }

    await user.sendEmailVerification();
  }

  Future<AppUserModel?> _readUserProfile(String uid) async {
    final snapshot = await _userDoc(uid).get();
    if (!snapshot.exists) return null;

    return AppUserModel.fromMap(
      snapshot.id,
      snapshot.data() ?? <String, dynamic>{},
    );
  }

  @override
  Future<void> updateUserProfile({
    required String uid,
    String? fullName,
    String? phone,
    String? profileImageUrl,
  }) async {
    final updates = <String, dynamic>{
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (fullName != null) updates['fullName'] = fullName;
    if (phone != null) updates['phone'] = phone;
    if (profileImageUrl != null) updates['profileImageUrl'] = profileImageUrl;

    await _userDoc(uid).set(updates, SetOptions(merge: true));
  }

  Future<void> _createProfessionalRequest(AppUserModel user) async {
    await _professionalRequestsCollection.add({
      'userId': user.id,
      'email': user.email,
      'fullName': user.fullName,
      'phone': user.phone,
      'status': ProfessionalStatus.pending.name,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'reviewedAt': null,
      'reviewedBy': null,
      'reviewNote': null,
    });
  }
}
