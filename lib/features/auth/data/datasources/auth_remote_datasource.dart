import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../domain/entities/app_user.dart';
import '../models/app_user_model.dart';

abstract class AuthRemoteDatasource {
  Future<AppUserModel> signIn({
    required String email,
    required String password,
  });

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
  })  : _auth = firebaseAuth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

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

    final profile = await _readUserProfile(currentUser.uid);
    if (profile != null) return profile;

    final fallback = AppUserModel.fromFirebaseUser(
      currentUser,
      role: UserRole.client,
      isProfessional: false,
      emailVerified: currentUser.emailVerified,
    );

    await _userDoc(currentUser.uid).set(
      fallback.toMap(includeCreatedAt: true),
      SetOptions(merge: true),
    );

    return fallback;
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

    await _userDoc(user.uid).set(
      model.toMap(includeCreatedAt: true),
      SetOptions(merge: true),
    );

    await user.sendEmailVerification();

    return model;
  }

  @override
  Future<AppUserModel?> getCurrentUser() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    await user.reload();
    final currentUser = _auth.currentUser ?? user;

    final profile = await _readUserProfile(currentUser.uid);
    if (profile != null) return profile;

    final fallback = AppUserModel.fromFirebaseUser(
      currentUser,
      role: UserRole.client,
      isProfessional: false,
      emailVerified: currentUser.emailVerified,
    );

    await _userDoc(currentUser.uid).set(
      fallback.toMap(includeCreatedAt: true),
      SetOptions(merge: true),
    );

    return fallback;
  }

  @override
  Future<void> signOut() {
    return _auth.signOut();
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