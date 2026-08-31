import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../network/auth_interceptor.dart';
import '../network/dio_client.dart';
import '../storage/object_box_store.dart';
import '../sync/connectivity_service.dart';
import '../sync/sync_manager.dart';

// --- Secure Storage ---
final secureStorageProvider = Provider<FlutterSecureStorage>((ref) {
  return const FlutterSecureStorage();
});

// --- Auth Interceptor ---
final authInterceptorProvider = Provider<AuthInterceptor>((ref) {
  return AuthInterceptor(ref.watch(secureStorageProvider));
});

// --- Dio Client ---
final dioClientProvider = Provider<DioClient>((ref) {
  return DioClient(authInterceptor: ref.watch(authInterceptorProvider));
});

// --- ObjectBox Store (override in main.dart ProviderScope) ---
final objectBoxStoreProvider = Provider<ObjectBoxStore>((ref) {
  throw UnimplementedError('Must be overridden in ProviderScope');
});

// --- Connectivity ---
final connectivityServiceProvider = Provider<ConnectivityService>((ref) {
  final service = ConnectivityService();
  ref.onDispose(() => service.dispose());
  return service;
});

// --- Sync Manager ---
final syncManagerProvider = Provider<SyncManager>((ref) {
  final manager = SyncManager(
    ref.watch(objectBoxStoreProvider),
    ref.watch(connectivityServiceProvider),
    ref.watch(dioClientProvider).dio,
    ref.watch(secureStorageProvider),
  );
  ref.onDispose(() => manager.dispose());
  return manager;
});
