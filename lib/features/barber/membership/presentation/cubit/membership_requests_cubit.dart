import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/usecases/get_pending_requests.dart';
import '../../domain/usecases/review_membership_request.dart';
import 'membership_requests_state.dart';

class MembershipRequestsCubit extends Cubit<MembershipRequestsState> {
  final GetPendingRequests _getPendingRequests;
  final ReviewMembershipRequest _reviewMembershipRequest;

  MembershipRequestsCubit({
    required GetPendingRequests getPendingRequests,
    required ReviewMembershipRequest reviewMembershipRequest,
  }) : _getPendingRequests = getPendingRequests,
       _reviewMembershipRequest = reviewMembershipRequest,
       super(const MembershipRequestsInitial());

  Future<void> load(String barbershopId) async {
    emit(const MembershipRequestsLoading());
    final result = await _getPendingRequests(barbershopId);
    emit(result.when(
      ok: (requests) => MembershipRequestsLoaded(requests),
      fail: (f) => MembershipRequestsError(f.message),
    ));
  }

  Future<void> review(ReviewMembershipRequestParams params) async {
    final result = await _reviewMembershipRequest(params);
    emit(result.when(
      ok: (request) => MembershipRequestReviewed(request),
      fail: (f) => MembershipRequestsError(f.message),
    ));
  }
}
