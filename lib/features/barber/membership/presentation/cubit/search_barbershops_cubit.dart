import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/usecases/search_barbershops.dart';
import '../../domain/usecases/send_membership_request.dart';
import 'search_barbershops_state.dart';

class SearchBarbershopsCubit extends Cubit<SearchBarbershopsState> {
  final SearchBarbershops _searchBarbershops;
  final SendMembershipRequest _sendMembershipRequest;

  SearchBarbershopsCubit({
    required SearchBarbershops searchBarbershops,
    required SendMembershipRequest sendMembershipRequest,
  }) : _searchBarbershops = searchBarbershops,
       _sendMembershipRequest = sendMembershipRequest,
       super(const SearchBarbershopsInitial());

  Future<void> search(String query, {double radiusKm = 10.0}) async {
    emit(const SearchBarbershopsLoading());
    final result = await _searchBarbershops(
      SearchBarbershopsParams(query: query, radiusKm: radiusKm),
    );
    emit(
      result.when(
        ok: (shops) => SearchBarbershopsLoaded(shops),
        fail: (f) => SearchBarbershopsError(f.message),
      ),
    );
  }

  Future<void> sendRequest(SendMembershipRequestParams params) async {
    final result = await _sendMembershipRequest(params);
    emit(
      result.when(
        ok: (request) => MembershipRequestSent(request.barbershopName),
        fail: (f) => SearchBarbershopsError(f.message),
      ),
    );
  }
}
