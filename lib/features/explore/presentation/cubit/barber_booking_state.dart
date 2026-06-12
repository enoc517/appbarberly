import 'package:equatable/equatable.dart';

import '../../../barber/services/domain/entities/barber_schedule.dart';

class BarberBookingState extends Equatable {
  final bool isLoading;
  final String? barberName;
  final String? barberAvatarUrl;
  final List<Map<String, dynamic>> services;
  final Map<int, BarberSchedule> schedule;
  final List<DateTime> availableDays;
  final List<String> availableTimes;
  final Map<String, dynamic>? selectedService;
  final DateTime? selectedDay;
  final String? selectedTime;
  final bool isBooking;
  final bool isLoadingSlots;
  final String? errorMessage;

  const BarberBookingState({
    this.isLoading = true,
    this.barberName,
    this.barberAvatarUrl,
    this.services = const [],
    this.schedule = const {},
    this.availableDays = const [],
    this.availableTimes = const [],
    this.selectedService,
    this.selectedDay,
    this.selectedTime,
    this.isBooking = false,
    this.isLoadingSlots = false,
    this.errorMessage,
  });

  BarberBookingState copyWith({
    bool? isLoading,
    String? barberName,
    String? barberAvatarUrl,
    List<Map<String, dynamic>>? services,
    Map<int, BarberSchedule>? schedule,
    List<DateTime>? availableDays,
    List<String>? availableTimes,
    Map<String, dynamic>? selectedService,
    DateTime? selectedDay,
    String? selectedTime,
    bool? isBooking,
    bool? isLoadingSlots,
    String? errorMessage,
    bool clearSelectedService = false,
    bool clearSelectedDay = false,
    bool clearSelectedTime = false,
  }) {
    return BarberBookingState(
      isLoading: isLoading ?? this.isLoading,
      barberName: barberName ?? this.barberName,
      barberAvatarUrl: barberAvatarUrl ?? this.barberAvatarUrl,
      services: services ?? this.services,
      schedule: schedule ?? this.schedule,
      availableDays: availableDays ?? this.availableDays,
      availableTimes: availableTimes ?? this.availableTimes,
      selectedService: clearSelectedService
          ? null
          : (selectedService ?? this.selectedService),
      selectedDay: clearSelectedDay ? null : (selectedDay ?? this.selectedDay),
      selectedTime: clearSelectedTime
          ? null
          : (selectedTime ?? this.selectedTime),
      isBooking: isBooking ?? this.isBooking,
      isLoadingSlots: isLoadingSlots ?? this.isLoadingSlots,
      errorMessage: errorMessage,
    );
  }

  bool get canConfirm =>
      selectedService != null &&
      selectedDay != null &&
      selectedTime != null &&
      !isBooking;

  @override
  List<Object?> get props => [
    isLoading,
    barberName,
    barberAvatarUrl,
    services,
    schedule,
    availableDays,
    availableTimes,
    selectedService,
    selectedDay,
    selectedTime,
    isBooking,
    isLoadingSlots,
    errorMessage,
  ];
}
