import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/di/core_providers.dart';
import 'core/router/app_router.dart';
import 'core/storage/object_box_store.dart';
import 'core/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final objectBoxStore = await ObjectBoxStore.create();
  // TODO: Initialize Firebase
  runApp(ProviderScope(
    overrides: [
      objectBoxStoreProvider.overrideWithValue(objectBoxStore),
    ],
    child: const SyncUpApp(),
  ));
}

class SyncUpApp extends ConsumerWidget {
  const SyncUpApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    return MaterialApp.router(
      title: 'SyncUp',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      routerConfig: router,
    );
  }
}
