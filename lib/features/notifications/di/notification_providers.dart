import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/di/core_providers.dart';
import '../../../core/notifications/notification_service.dart';
import '../../../core/notifications/notification_permission_handler.dart';
import '../../../core/notifications/push_service.dart';
import '../data/datasources/notification_remote_datasource.dart';
import '../data/repositories/notification_repository_impl.dart';
import '../domain/repositories/notification_repository.dart';
import '../domain/usecases/mark_notification_read_usecase.dart';

final notificationServiceProvider = Provider((ref) => NotificationService());

final notificationPermissionHandlerProvider = Provider((ref) =>
    NotificationPermissionHandler(
      ref.watch(secureStorageProvider),
      ref.watch(notificationServiceProvider),
      // Registers the FCM token once the user says yes; read lazily so this
      // provider does not depend on the push service at construction time.
      () => ref.read(pushServiceProvider).requestPermissionAndRegister(),
    ));

final notificationRemoteDataSourceProvider = Provider((ref) =>
    NotificationRemoteDataSource(ref.watch(dioClientProvider).dio));

final notificationRepositoryProvider =
    Provider<NotificationRepository>((ref) => NotificationRepositoryImpl(
          ref.watch(notificationRemoteDataSourceProvider),
          ref.watch(connectivityServiceProvider),
        ));

final markNotificationReadUseCaseProvider = Provider((ref) =>
    MarkNotificationReadUseCase(ref.watch(notificationRepositoryProvider)));
