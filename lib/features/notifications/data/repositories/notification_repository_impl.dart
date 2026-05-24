import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/sync/connectivity_service.dart';
import '../../domain/entities/app_notification.dart';
import '../../domain/repositories/notification_repository.dart';
import '../datasources/notification_remote_datasource.dart';
import '../models/app_notification_dto.dart';

class NotificationRepositoryImpl implements NotificationRepository {
  final NotificationRemoteDataSource _remote;
  final ConnectivityService _connectivity;

  NotificationRepositoryImpl(this._remote, this._connectivity);

  Failure _mapError(Object e) {
    if (e is DioException) {
      switch (e.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
        case DioExceptionType.connectionError:
          return const ServerFailure(
              'Server is not reachable. Please try again later.');
        default:
          final message =
              e.response?.data?['message'] ?? 'Something went wrong';
          return ServerFailure(message.toString(),
              statusCode: e.response?.statusCode);
      }
    }
    return ServerFailure(e.toString());
  }

  @override
  Future<Either<Failure, List<AppNotification>>> getNotifications() async {
    try {
      final data = await _remote.getNotifications();
      return Right(
          data.map((j) => AppNotificationDto.fromJson(j).toDomain()).toList());
    } catch (e) {
      if (e is DioException) return const Right([]);
      return Left(_mapError(e));
    }
  }

  @override
  Future<Either<Failure, void>> markAsRead(String notificationId) async {
    if (!_connectivity.isOnline) {
      return const Left(NetworkFailure('Connect to the internet'));
    }
    try {
      await _remote.markAsRead(notificationId);
      return const Right(null);
    } catch (e) {
      return Left(_mapError(e));
    }
  }

  @override
  Future<Either<Failure, void>> markAllAsRead() async {
    if (!_connectivity.isOnline) {
      return const Left(NetworkFailure('Connect to the internet'));
    }
    try {
      await _remote.markAllAsRead();
      return const Right(null);
    } catch (e) {
      return Left(_mapError(e));
    }
  }

  @override
  Future<Either<Failure, int>> getUnreadCount() async {
    try {
      final count = await _remote.getUnreadCount();
      return Right(count);
    } catch (e) {
      if (e is DioException) return const Right(0);
      return Left(_mapError(e));
    }
  }
}
