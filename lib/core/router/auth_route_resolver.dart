import 'package:barberly/features/auth/domain/entities/app_user.dart';

String routeForAuthenticatedUser(AppUser? user) {
  return switch (user?.professionalStatus) {
    ProfessionalStatus.pending ||
    ProfessionalStatus.rejected => '/professional-status',
    ProfessionalStatus.approved when user?.role == UserRole.barber => '/panel',
    _ => '/explorar',
  };
}
