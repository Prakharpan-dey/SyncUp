import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/di/core_providers.dart';
import '../data/datasources/task_remote_datasource.dart';
import '../data/repositories/task_repository_impl.dart';
import '../domain/repositories/task_repository.dart';
import '../domain/usecases/create_task_usecase.dart';
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