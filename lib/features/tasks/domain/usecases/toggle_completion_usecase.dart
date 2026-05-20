import 'package:fpdart/fpdart.dart' hide Task;
import '../../../../core/error/failures.dart';
import '../entities/task.dart';
import '../repositories/task_repository.dart';

class ToggleCompletionUseCase {
  final TaskRepository _repo;
  ToggleCompletionUseCase(this._repo);

  Future<Either<Failure, Task>> call(Task task) async {
    return _repo.toggleCompletion(task);
  }
}
