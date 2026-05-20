import 'package:fpdart/fpdart.dart' hide Task;
import 'package:uuid/uuid.dart';
import '../../../../core/error/failures.dart';
import '../entities/task.dart';
import '../repositories/task_repository.dart';

class CreateTaskUseCase {
  final TaskRepository _repo;
  CreateTaskUseCase(this._repo);

  Future<Either<Failure, Task>> call({
    required String userId, required String title,
    String? description, DateTime? dueDate,
    TaskPriority priority = TaskPriority.medium,
    List<String> tags = const [],
  }) async {
    if (title.trim().isEmpty) return const Left(ValidationFailure('Title required'));
    final task = Task(
      id: const Uuid().v4(), userId: userId, title: title.trim(),
      description: description, dueDate: dueDate, priority: priority,
      tags: tags, createdAt: DateTime.now(), updatedAt: DateTime.now(),
    );
    return _repo.createTask(task);
  }
}