import '../../domain/entities/membership_request.dart';

sealed class MembershipRequestsState {
  const MembershipRequestsState();
}

class MembershipRequestsInitial extends MembershipRequestsState {
  const MembershipRequestsInitial();
}

class MembershipRequestsLoading extends MembershipRequestsState {
  const MembershipRequestsLoading();
}

class MembershipRequestsLoaded extends MembershipRequestsState {
  final List<MembershipRequest> requests;
  const MembershipRequestsLoaded(this.requests);
}

class MembershipRequestsError extends MembershipRequestsState {
  final String message;
  const MembershipRequestsError(this.message);
}

class MembershipRequestReviewed extends MembershipRequestsState {
  final MembershipRequest request;
  const MembershipRequestReviewed(this.request);
}
