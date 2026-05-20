import 'package:fpdart/fpdart.dart' hide Task;
import '../../../../core/error/failures.dart';
import '../entities/task.dart';
import '../repositories/task_repository.dart';

class GetTasksUseCase {
  final TaskRepository _repo;
  GetTasksUseCase(this._repo);

  Future<Either<Failure, List<Task>>> todayTasks(String userId) async {
    return _repo.getTasksForToday(userId);
  }

  Future<Either<Failure, List<Task>>> upcomingTasks(String userId) async {
    return _repo.getUpcomingTasks(userId);
  }
}
