import '../../../domain/entities/barber.dart';
import '../../../domain/entities/service.dart';
import '../../../domain/entities/time_slot.dart';

enum ProfileTab { services, barbers }
enum BookingStatus { idle, submitting, success, failure }

class BookingState {
  final ProfileTab activeTab;
  final Service? selectedService;
  final DateTime selectedDay;
  final TimeSlot? selectedSlot;
  final Barber? selectedBarber;
  final BookingStatus status;
  final String? errorMessage;

  const BookingState({
    this.activeTab = ProfileTab.services,
    this.selectedService,
    required this.selectedDay,
    this.selectedSlot,
    this.selectedBarber,
    this.status = BookingStatus.idle,
    this.errorMessage,
  });

  bool get canConfirm =>
      selectedService != null &&
      selectedSlot != null &&
      selectedBarber != null &&
      status != BookingStatus.submitting;

  BookingState copyWith({
    ProfileTab? activeTab,
    Service? selectedService,
    DateTime? selectedDay,
    TimeSlot? selectedSlot,
    Barber? selectedBarber,
    BookingStatus? status,
    String? errorMessage,
    bool clearSlot = false,
    bool clearError = false,
  }) {
    return BookingState(
      activeTab: activeTab ?? this.activeTab,
      selectedService: selectedService ?? this.selectedService,
      selectedDay: selectedDay ?? this.selectedDay,
      selectedSlot: clearSlot ? null : (selectedSlot ?? this.selectedSlot),
      selectedBarber: selectedBarber ?? this.selectedBarber,
      status: status ?? this.status,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}