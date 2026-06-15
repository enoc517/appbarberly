import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../../shared/theme/app_theme.dart';
import '../../../../../shared/motion/app_motion.dart';
import '../../../../../shared/widgets/app_toast.dart';
import '../../domain/entities/membership_request.dart';
import '../../domain/usecases/review_membership_request.dart';
import '../cubit/membership_requests_cubit.dart';
import '../cubit/membership_requests_state.dart';

class MembershipRequestsScreen extends StatefulWidget {
  final String barbershopId;
  final String reviewerId;

  const MembershipRequestsScreen({
    super.key,
    required this.barbershopId,
    required this.reviewerId,
  });

  @override
  State<MembershipRequestsScreen> createState() =>
      _MembershipRequestsScreenState();
}

class _MembershipRequestsScreenState extends State<MembershipRequestsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.barbershopId.isNotEmpty) {
        context.read<MembershipRequestsCubit>().load(widget.barbershopId);
      }
    });
  }

  @override
  void didUpdateWidget(covariant MembershipRequestsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.barbershopId != widget.barbershopId &&
        widget.barbershopId.isNotEmpty) {
      context.read<MembershipRequestsCubit>().load(widget.barbershopId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Solicitudes pendientes',
          style: AppTypography.titleLarge.copyWith(
            color: theme.colorScheme.onSurface,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: BlocConsumer<MembershipRequestsCubit, MembershipRequestsState>(
        listener: (context, state) {
          if (state is MembershipRequestReviewed) {
            final approved =
                state.request.status == MembershipRequestStatus.approved;
            AppToast.success(
              context,
              approved ? 'Solicitud aprobada' : 'Solicitud rechazada',
            );
            context.read<MembershipRequestsCubit>().load(widget.barbershopId);
          }
          if (state is MembershipRequestsError) {
            AppToast.error(context, state.message);
          }
        },
        builder: (context, state) {
          if (state is MembershipRequestsLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is MembershipRequestsLoaded) {
            if (state.requests.isEmpty) {
              return Center(
                child: AppFadeSlideIn(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.inbox_rounded,
                        size: 64,
                        color: theme.colorScheme.outline,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No hay solicitudes pendientes',
                        style: AppTypography.titleMedium.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: state.requests.length,
              itemBuilder: (context, index) {
                final request = state.requests[index];
                return _RequestCard(
                  request: request,
                  onApprove: () {
                    context.read<MembershipRequestsCubit>().review(
                      ReviewMembershipRequestParams(
                        requestId: request.id,
                        barbershopId: widget.barbershopId,
                        approve: true,
                        reviewedBy: widget.reviewerId,
                      ),
                    );
                  },
                  onReject: () {
                    context.read<MembershipRequestsCubit>().review(
                      ReviewMembershipRequestParams(
                        requestId: request.id,
                        barbershopId: widget.barbershopId,
                        approve: false,
                        reviewedBy: widget.reviewerId,
                      ),
                    );
                  },
                );
              },
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }
}

class _RequestCard extends StatelessWidget {
  const _RequestCard({
    required this.request,
    required this.onApprove,
    required this.onReject,
  });

  final MembershipRequest request;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: theme.colorScheme.surfaceContainerHighest,
                  ),
                  child: Icon(
                    Icons.person_rounded,
                    color: theme.colorScheme.outline,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        request.barberName,
                        style: AppTypography.titleMedium.copyWith(
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        request.barberEmail,
                        style: AppTypography.bodySmall.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: onApprove,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primaryContainer,
                      foregroundColor: theme.colorScheme.onPrimaryContainer,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                    ),
                    child: const Text('Aprobar'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: onReject,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: theme.colorScheme.secondary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                      side: BorderSide(
                        color: theme.colorScheme.secondary.withValues(
                          alpha: 0.3,
                        ),
                      ),
                    ),
                    child: const Text('Rechazar'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
