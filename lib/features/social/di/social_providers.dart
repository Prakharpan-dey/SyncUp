import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/di/core_providers.dart';
import '../data/datasources/social_remote_datasource.dart';
import '../data/repositories/social_repository_impl.dart';
import '../domain/repositories/social_repository.dart';
import '../domain/usecases/search_users_usecase.dart';
import '../domain/usecases/send_friend_request_usecase.dart';
import '../domain/usecases/manage_friend_request_usecase.dart';
import '../domain/usecases/create_group_usecase.dart';

final socialRemoteDataSourceProvider = Provider((ref) =>
    SocialRemoteDataSource(ref.watch(dioClientProvider).dio));

final socialRepositoryProvider = Provider<SocialRepository>((ref) =>
    SocialRepositoryImpl(
      ref.watch(socialRemoteDataSourceProvider),
      ref.watch(connectivityServiceProvider),
    ));

final searchUsersUseCaseProvider = Provider((ref) =>
    SearchUsersUseCase(ref.watch(socialRepositoryProvider)));

final sendFriendRequestUseCaseProvider = Provider((ref) =>
    SendFriendRequestUseCase(ref.watch(socialRepositoryProvider)));

final manageFriendRequestUseCaseProvider = Provider((ref) =>
    ManageFriendRequestUseCase(ref.watch(socialRepositoryProvider)));

final createGroupUseCaseProvider = Provider((ref) =>
    CreateGroupUseCase(ref.watch(socialRepositoryProvider)));
