import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failures.dart';
import '../repositories/notification_repository.dart';

class MarkNotificationReadUseCase {
  final NotificationRepository _repo;
  MarkNotificationReadUseCase(this._repo);

  Future<Either<Failure, void>> call(String notificationId) {
    if (notificationId.trim().isEmpty) {
      return Future.value(
          const Left(ValidationFailure('Invalid notification ID')));
    }
    return _repo.markAsRead(notificationId);
  }
}
