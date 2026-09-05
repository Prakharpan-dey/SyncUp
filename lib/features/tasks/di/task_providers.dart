import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/di/core_providers.dart';
import '../data/datasources/task_remote_datasource.dart';
import '../data/datasources/task_series_remote_datasource.dart';
import '../data/repositories/task_repository_impl.dart';
import '../data/repositories/task_series_repository_impl.dart';
import '../domain/repositories/task_repository.dart';
import '../domain/repositories/task_series_repository.dart';
import '../../../core/notifications/notification_service.dart';
import '../domain/services/task_notification_scheduler.dart';
import '../domain/usecases/create_task_usecase.dart';
import '../domain/usecases/generate_occurrences_usecase.dart';
import '../domain/usecases/get_tasks_usecase.dart';
import '../domain/usecases/toggle_completion_usecase.dart';

final taskRemoteDataSourceProvider = Provider((ref) =>
  TaskRemoteDataSource(ref.watch(dioClientProvider).dio));

final taskRepositoryProvider = Provider<TaskRepository>((ref) =>
  TaskRepositoryImpl(
    ref.watch(taskRemoteDataSourceProvider),
    ref.watch(objectBoxStoreProvider),
    ref.watch(syncManagerProvider),
    ref.watch(connectivityServiceProvider),
  ));

final createTaskUseCaseProvider = Provider((ref) =>
  CreateTaskUseCase(ref.watch(taskRepositoryProvider)));

final getTasksUseCaseProvider = Provider((ref) =>
  GetTasksUseCase(ref.watch(taskRepositoryProvider)));

final toggleCompletionUseCaseProvider = Provider((ref) =>
  ToggleCompletionUseCase(ref.watch(taskRepositoryProvider)));
final taskSeriesRemoteDataSourceProvider = Provider((ref) =>
  TaskSeriesRemoteDataSource(ref.watch(dioClientProvider).dio));

final taskSeriesRepositoryProvider = Provider<TaskSeriesRepository>((ref) =>
  TaskSeriesRepositoryImpl(
    ref.watch(taskSeriesRemoteDataSourceProvider),
    ref.watch(objectBoxStoreProvider),
    ref.watch(syncManagerProvider),
    ref.watch(connectivityServiceProvider),
  ));

final generateOccurrencesUseCaseProvider = Provider((ref) =>
  GenerateOccurrencesUseCase(
    ref.watch(taskRepositoryProvider),
    ref.watch(taskSeriesRepositoryProvider),
  ));

final taskNotificationSchedulerProvider = Provider((ref) =>
  TaskNotificationScheduler(NotificationService()));
