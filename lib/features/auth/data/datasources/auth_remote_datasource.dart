import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../domain/entities/app_user.dart';
import '../models/app_user_model.dart';

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
      final updatedProfile = AppUserModel(
        id: profile.id,
        email: profile.email,
        fullName: profile.fullName,
        phone: profile.phone,
        role: profile.role,
        isProfessional: profile.isProfessional,
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

    return AppUserModel(
      id: profile.id,
      email: profile.email,
      fullName: profile.fullName,
      phone: profile.phone,
      role: profile.role,
      isProfessional: profile.isProfessional,
      emailVerified: true,
    );
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

    final role = isProfessional ? UserRole.barber : UserRole.client;
    final model = AppUserModel.fromFirebaseUser(
      user,
      role: role,
      isProfessional: isProfessional,
      emailVerified: true,
    );

    await _userDoc(
      user.uid,
    ).set(model.toMap(includeCreatedAt: true), SetOptions(merge: true));

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

    final role = isProfessional ? UserRole.barber : UserRole.client;

    await user.updateDisplayName(fullName.trim());

    final model = AppUserModel(
      id: user.uid,
      email: email.trim(),
      fullName: fullName.trim(),
      phone: phone.trim(),
      role: role,
      isProfessional: isProfessional,
      emailVerified: user.emailVerified,
    );

    await _userDoc(
      user.uid,
    ).set(model.toMap(includeCreatedAt: true), SetOptions(merge: true));

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
      final updatedProfile = AppUserModel(
        id: profile.id,
        email: profile.email,
        fullName: profile.fullName,
        phone: profile.phone,
        role: profile.role,
        isProfessional: profile.isProfessional,
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
}
