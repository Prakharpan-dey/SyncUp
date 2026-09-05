import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../entities/task_series.dart';

abstract interface class TaskSeriesRepository {
  /// Every series for this user, including inactive ones — generation skips
  /// those, but occurrences already created still point at them.
  Future<Either<Failure, List<TaskSeries>>> getSeries(String userId);

  Future<Either<Failure, TaskSeries>> createSeries(TaskSeries series);

  Future<Either<Failure, TaskSeries>> updateSeries(TaskSeries series);

  Future<Either<Failure, void>> deleteSeries(String seriesId);
}
