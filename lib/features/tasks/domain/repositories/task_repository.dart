import 'package:fpdart/fpdart.dart' hide Task;
import '../../../../core/error/failures.dart';
import '../entities/task.dart';

abstract interface class TaskRepository {
  Future<Either<Failure, List<Task>>> getTasksForToday(String userId);
  Future<Either<Failure, List<Task>>> getUpcomingTasks(String userId);
  Future<Either<Failure, Task>> createTask(Task task);
  Future<Either<Failure, Task>> updateTask(Task task);
  Future<Either<Failure, Task>> toggleCompletion(Task task);
  Future<Either<Failure, void>> deleteTask(String taskId);
}