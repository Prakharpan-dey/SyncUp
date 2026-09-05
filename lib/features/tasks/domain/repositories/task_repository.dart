import 'package:fpdart/fpdart.dart' hide Task;
import '../../../../core/error/failures.dart';
import '../entities/task.dart';

abstract interface class TaskRepository {
  Future<Either<Failure, List<Task>>> getTasksForToday(String userId);
  Future<Either<Failure, List<Task>>> getUpcomingTasks(String userId);
  Future<Either<Failure, Task>> createTask(Task task);

  /// Writes a batch of generated occurrences in one local write, queueing each
  /// for upload rather than pushing them individually.
  Future<Either<Failure, List<Task>>> createOccurrences(List<Task> tasks);

  /// Which of [ids] already exist locally. Synchronous: ObjectBox reads are.
  Set<String> existingTaskIds(Iterable<String> ids);
  Future<Either<Failure, Task>> updateTask(Task task);
  Future<Either<Failure, Task>> toggleCompletion(Task task);
  Future<Either<Failure, void>> deleteTask(String taskId);
}