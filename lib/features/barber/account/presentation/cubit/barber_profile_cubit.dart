import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

class BarberProfileState extends Equatable {
  final bool isLoading;
  final String userName;
  final String userEmail;
  final String? errorMessage;

  const BarberProfileState({
    this.isLoading = true,
    this.userName = '',
    this.userEmail = '',
    this.errorMessage,
  });

  BarberProfileState copyWith({
    bool? isLoading,
    String? userName,
    String? userEmail,
    String? errorMessage,
  }) {
    return BarberProfileState(
      isLoading: isLoading ?? this.isLoading,
      userName: userName ?? this.userName,
      userEmail: userEmail ?? this.userEmail,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [isLoading, userName, userEmail, errorMessage];
}

class BarberProfileCubit extends Cubit<BarberProfileState> {
  BarberProfileCubit() : super(const BarberProfileState());

  Future<void> loadData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      emit(const BarberProfileState(
        isLoading: false,
        userName: '',
        userEmail: '',
      ));
      return;
    }

    emit(state.copyWith(isLoading: true, errorMessage: null));

    try {
      final db = FirebaseFirestore.instance;
      final userDoc = await db.collection('users').doc(user.uid).get();
      final data = userDoc.data();

      emit(state.copyWith(
        isLoading: false,
        userName: user.displayName ?? data?['fullName'] ?? 'Barbero',
        userEmail: user.email ?? '',
      ));
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        userName: user.displayName ?? 'Barbero',
        userEmail: user.email ?? '',
      ));
    }
  }

  Future<void> logout() async {
    await FirebaseAuth.instance.signOut();
  }
}
