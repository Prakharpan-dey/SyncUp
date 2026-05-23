import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/di/core_providers.dart';
import '../data/datasources/feed_remote_datasource.dart';
import '../data/repositories/feed_repository_impl.dart';
import '../domain/repositories/feed_repository.dart';
import '../domain/usecases/get_feed_usecase.dart';
import '../domain/usecases/react_to_feed_usecase.dart';
import '../domain/usecases/comment_on_feed_usecase.dart';

final feedRemoteDataSourceProvider = Provider((ref) =>
    FeedRemoteDataSource(ref.watch(dioClientProvider).dio));

final feedRepositoryProvider = Provider<FeedRepository>((ref) =>
    FeedRepositoryImpl(
      ref.watch(feedRemoteDataSourceProvider),
      ref.watch(connectivityServiceProvider),
    ));

final getFeedUseCaseProvider = Provider((ref) =>
    GetFeedUseCase(ref.watch(feedRepositoryProvider)));

final reactToFeedUseCaseProvider = Provider((ref) =>
    ReactToFeedUseCase(ref.watch(feedRepositoryProvider)));

final commentOnFeedUseCaseProvider = Provider((ref) =>
    CommentOnFeedUseCase(ref.watch(feedRepositoryProvider)));
