import '../../../barbershop_management/domain/entities/barbershop.dart';

sealed class SearchBarbershopsState {
  const SearchBarbershopsState();
}

class SearchBarbershopsInitial extends SearchBarbershopsState {
  const SearchBarbershopsInitial();
}

class SearchBarbershopsLoading extends SearchBarbershopsState {
  const SearchBarbershopsLoading();
}

class SearchBarbershopsLoaded extends SearchBarbershopsState {
  final List<Barbershop> barbershops;
  const SearchBarbershopsLoaded(this.barbershops);
}

class SearchBarbershopsError extends SearchBarbershopsState {
  final String message;
  const SearchBarbershopsError(this.message);
}

class MembershipRequestSent extends SearchBarbershopsState {
  final String barbershopName;
  const MembershipRequestSent(this.barbershopName);
}
