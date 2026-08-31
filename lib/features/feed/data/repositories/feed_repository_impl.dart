import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/sync/connectivity_service.dart';
import '../../domain/entities/feed_item.dart';
import '../../domain/repositories/feed_repository.dart';
import '../datasources/feed_remote_datasource.dart';
import '../models/feed_item_dto.dart';

class FeedRepositoryImpl implements FeedRepository {
  final FeedRemoteDataSource _remote;
  final ConnectivityService _connectivity;

  FeedRepositoryImpl(this._remote, this._connectivity);

  /// Convert exceptions to user-friendly failures
  Failure _mapError(Object e) {
    if (e is DioException) {
      switch (e.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          return const ServerFailure(
              'Server is not reachable. Please try again later.');
        case DioExceptionType.connectionError:
          return const NetworkFailure(
              'Cannot connect to the server');
        default:
          final statusCode = e.response?.statusCode;
          final message =
              e.response?.data?['message'] ?? 'Something went wrong';
          return ServerFailure(message.toString(), statusCode: statusCode);
      }
    }
    return ServerFailure(e.toString());
  }

  @override
  Future<Either<Failure, ({List<FeedItem> items, String? nextCursor})>>
      getFeed({
    required String tab,
    String? cursor,
    int limit = 20,
  }) async {
    if (!_connectivity.isOnline) {
      return const Left(
          NetworkFailure('Connect to the internet to view your feed'));
    }
    try {
      final data =
          await _remote.getFeed(tab: tab, cursor: cursor, limit: limit);
      final items = (data['items'] as List? ?? [])
          .map((j) =>
              FeedItemDto.fromJson(j as Map<String, dynamic>).toDomain())
          .toList();
      final nextCursor = data['next_cursor'] as String?;
      return Right((items: items, nextCursor: nextCursor));
    } catch (e) {
      // On timeout/no-backend, return empty feed instead of error
      if (e is DioException &&
          (e.type == DioExceptionType.connectionTimeout ||
           e.type == DioExceptionType.connectionError)) {
        return const Right((items: <FeedItem>[], nextCursor: null));
      }
      return Left(_mapError(e));
    }
  }

  @override
  Future<Either<Failure, ({bool reacted, int count})>> react(
      String feedItemId, String emoji) async {
    if (!_connectivity.isOnline) {
      return const Left(
          NetworkFailure('Connect to the internet to react'));
    }
    try {
      final data = await _remote.react(feedItemId, emoji);
      return Right((
        reacted: data['reacted'] as bool? ?? true,
        count: data['reaction_count'] as int? ?? 0,
      ));
    } catch (e) {
      return Left(_mapError(e));
    }
  }
}
