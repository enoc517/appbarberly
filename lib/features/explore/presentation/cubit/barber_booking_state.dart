import 'package:equatable/equatable.dart';

class BarberBookingState extends Equatable {
  final bool isLoading;
  final String? barberName;
  final List<Map<String, dynamic>> services;
  final Map<int, bool> schedule;
  final List<DateTime> availableDays;
  final Map<String, dynamic>? selectedService;
  final DateTime? selectedDay;
  final String? selectedTime;
  final bool isBooking;
  final String? errorMessage;

  const BarberBookingState({
    this.isLoading = true,
    this.barberName,
    this.services = const [],
    this.schedule = const {},
    this.availableDays = const [],
    this.selectedService,
    this.selectedDay,
    this.selectedTime,
    this.isBooking = false,
    this.errorMessage,
  });

  BarberBookingState copyWith({
    bool? isLoading,
    String? barberName,
    List<Map<String, dynamic>>? services,
    Map<int, bool>? schedule,
    List<DateTime>? availableDays,
    Map<String, dynamic>? selectedService,
    DateTime? selectedDay,
    String? selectedTime,
    bool? isBooking,
    String? errorMessage,
    bool clearSelectedService = false,
    bool clearSelectedDay = false,
    bool clearSelectedTime = false,
  }) {
    return BarberBookingState(
      isLoading: isLoading ?? this.isLoading,
      barberName: barberName ?? this.barberName,
      services: services ?? this.services,
      schedule: schedule ?? this.schedule,
      availableDays: availableDays ?? this.availableDays,
      selectedService: clearSelectedService ? null : (selectedService ?? this.selectedService),
      selectedDay: clearSelectedDay ? null : (selectedDay ?? this.selectedDay),
      selectedTime: clearSelectedTime ? null : (selectedTime ?? this.selectedTime),
      isBooking: isBooking ?? this.isBooking,
      errorMessage: errorMessage,
    );
  }

  bool get canConfirm =>
      selectedService != null && selectedDay != null && selectedTime != null && !isBooking;

  @override
  List<Object?> get props => [
        isLoading,
        barberName,
        services,
        schedule,
        availableDays,
        selectedService,
        selectedDay,
        selectedTime,
        isBooking,
        errorMessage,
      ];
}
