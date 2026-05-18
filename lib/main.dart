import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // TODO: Initialize ObjectBox store
  // TODO: Initialize Firebase
  runApp(const ProviderScope(child: SyncUpApp()));
}

class SyncUpApp extends ConsumerWidget {
  const SyncUpApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // final router = ref.watch(appRouterProvider);
    return MaterialApp(
      title: 'SyncUp',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      home: const Scaffold(
        body: Center(child: Text('SyncUp — Phase 1 Complete ✓')),
      ),
    );
  }
}
