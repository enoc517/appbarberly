import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../shared/motion/app_motion.dart';
import '../../../../../shared/widgets/app_toast.dart';
import '../../domain/entities/barbershop.dart';
import '../bloc/barbershop_profile/barbershop_profile_cubit.dart';
import '../bloc/barbershop_profile/barbershop_profile_state.dart';
import '../bloc/booking/booking_cubit.dart';
import '../bloc/booking/booking_state.dart';
import '../widgets/agenda_card.dart';
import '../widgets/barbers_list.dart';
import '../widgets/barbershop_header.dart';
import '../widgets/barbershop_hero.dart';
import '../widgets/barbershop_map.dart';
import '../widgets/service_card.dart';
import '../widgets/services_barbers_tabs.dart';

class PerfilBarberiaScreen extends StatelessWidget {
  const PerfilBarberiaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: BlocListener<BookingCubit, BookingState>(
        listenWhen: (p, c) => p.status != c.status,
        listener: _onBookingStatus,
        child: SafeArea(
          bottom: false,
          child: BlocBuilder<BarbershopProfileCubit, BarbershopProfileState>(
            builder: (context, state) => switch (state) {
              BarbershopProfileLoading() => const Center(
                child: CircularProgressIndicator(),
              ),
              BarbershopProfileError(:final message) => _ErrorView(
                message: message,
              ),
              BarbershopProfileLoaded(:final barbershop) => _Content(
                barbershop: barbershop,
              ),
            },
          ),
        ),
      ),
    );
  }

  void _onBookingStatus(BuildContext context, BookingState s) {
    if (s.status == BookingStatus.success) {
      AppToast.success(context, 'Reserva confirmada ✓');
    } else if (s.status == BookingStatus.failure) {
      AppToast.error(context, s.errorMessage ?? 'Error al reservar');
    }
  }
}

class _Content extends StatelessWidget {
  final Barbershop barbershop;
  const _Content({required this.barbershop});

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        const SliverToBoxAdapter(
          child: AppFadeSlideIn(child: BarbershopHeader()),
        ),
        SliverToBoxAdapter(
          child: AppFadeSlideIn(
            delay: AppMotion.stagger,
            child: BarbershopHero(barbershop: barbershop, onCheckIn: () {}),
          ),
        ),
        const SliverToBoxAdapter(
          child: AppFadeSlideIn(
            delay: Duration(milliseconds: 140),
            child: ServicesBarbersTabs(),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          sliver: BlocBuilder<BookingCubit, BookingState>(
            buildWhen: (p, c) =>
                p.activeTab != c.activeTab ||
                p.selectedBarber != c.selectedBarber,
            builder: (context, state) {
              if (state.activeTab == ProfileTab.services) {
                return SliverList.separated(
                  itemCount: barbershop.services.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 12),
                  itemBuilder: (_, i) {
                    return ServiceCard(
                      service: barbershop.services[i],
                      onReserve: () => context
                          .read<BookingCubit>()
                          .selectService(barbershop.services[i]),
                    );
                  },
                );
              }
              return SliverToBoxAdapter(
                child: AppFadeSlideIn(
                  offset: const Offset(0, 0.04),
                  child: BarbersList(
                    barbers: barbershop.barbers,
                    selected: state.selectedBarber,
                    onSelect: context.read<BookingCubit>().selectBarber,
                  ),
                ),
              );
            },
          ),
        ),
        SliverToBoxAdapter(
          child: AppFadeSlideIn(
            delay: AppMotion.delay(2),
            child: AgendaCard(barbershop: barbershop),
          ),
        ),
        const SliverToBoxAdapter(
          child: AppFadeSlideIn(
            delay: Duration(milliseconds: 210),
            child: BarbershopMap(),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 24)),
      ],
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  const _ErrorView({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(message, textAlign: TextAlign.center),
      ),
    );
  }
}
