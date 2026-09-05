import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'firebase_options.dart';
import 'core/di/core_providers.dart';
import 'core/router/app_router.dart';
import 'core/notifications/notification_service.dart';
import 'core/notifications/push_service.dart';
import 'core/router/deep_link_handler.dart';
import 'core/storage/object_box_store.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_mode_provider.dart';
import 'features/auth/presentation/viewmodels/auth_viewmodel.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final objectBoxStore = await ObjectBoxStore.create();
  final prefs = await SharedPreferences.getInstance();

  // Guarded so a missing or malformed google-services.json degrades to "no push
  // notifications" rather than a launch crash. Everything else in the app works
  // without Firebase.
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    // Must be registered before runApp: Android spins up a separate isolate for
    // pushes that arrive while the app is dead, and it needs this entry point.
    FirebaseMessaging.onBackgroundMessage(firebaseBackgroundHandler);

  } catch (e) {
    debugPrint('Firebase unavailable, push notifications disabled: $e');
  }

  // Outside the Firebase guard on purpose. This creates the notification
  // channel and loads the timezone database that scheduled task reminders need,
  // neither of which involves Firebase — when it lived inside the try, a
  // malformed google-services.json took local reminders down along with push.
  //
  // The channel is created at launch rather than on first use because FCM only
  // files a backgrounded push on the channel named in the manifest if that
  // channel already exists, and the first push can arrive before the app has
  // shown a notification of its own.
  try {
    await NotificationService().initialize();
  } catch (e) {
    debugPrint('Local notifications unavailable: $e');
  }

  runApp(ProviderScope(
    overrides: [
      objectBoxStoreProvider.overrideWithValue(objectBoxStore),
      sharedPrefsProvider.overrideWithValue(prefs),
    ],
    child: const SyncUpApp(),
  ));
}

class SyncUpApp extends ConsumerStatefulWidget {
  const SyncUpApp({super.key});

  @override
  ConsumerState<SyncUpApp> createState() => _SyncUpAppState();
}

class _SyncUpAppState extends ConsumerState<SyncUpApp> {
  DeepLinkHandler? _deepLinks;

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      await ref.read(authInterceptorProvider).loadToken();
      await ref
          .read(authViewModelProvider.notifier)
          .checkAuthStatus();

      // Started after auth resolves so the router's redirect sees the real
      // state — otherwise an invite link would bounce to sign-in.
      if (!mounted) return;
      _deepLinks = DeepLinkHandler(ref.read(appRouterProvider))..init();

      // Registering the push token needs a signed-in account to attach it to.
      // No-ops for guests and when permission has not been granted yet.
      if (ref.read(authViewModelProvider).status == AuthStatus.authenticated) {
        unawaited(ref.read(pushServiceProvider).start());
      }
    });

    // A user who signs in later still needs their device registered.
    ref.listenManual(authViewModelProvider, (previous, next) {
      final justSignedIn = previous?.status != AuthStatus.authenticated &&
          next.status == AuthStatus.authenticated;
      if (justSignedIn) {
        unawaited(ref.read(pushServiceProvider).start());
      }
    });
  }

  @override
  void dispose() {
    _deepLinks?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(appRouterProvider);
    final themeMode = ref.watch(themeModeProvider);
    return MaterialApp.router(
      title: 'SyncUp',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      routerConfig: router,
    );
  }
}
