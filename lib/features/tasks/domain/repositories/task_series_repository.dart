import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../entities/task_series.dart';

abstract interface class TaskSeriesRepository {
  /// Every series for this user, including inactive ones — generation skips
  /// those, but occurrences already created still point at them.
  Future<Either<Failure, List<TaskSeries>>> getSeries(String userId);

  Future<Either<Failure, TaskSeries>> createSeries(TaskSeries series);

  Future<Either<Failure, TaskSeries>> updateSeries(TaskSeries series);

  /// With [deletePending], the server also deletes the series' pending days;
  /// completed ones stay, detached. Without it, every day is kept.
  Future<Either<Failure, void>> deleteSeries(String seriesId,
      {bool deletePending = false});

  /// Brings the server's copy of [userId]'s repeating rules down to the
  /// device. For a signed-in account only. True when anything changed.
  Future<Either<Failure, bool>> pullFromServer(String userId);
}
