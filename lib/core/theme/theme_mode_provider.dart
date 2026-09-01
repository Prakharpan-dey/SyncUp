import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _key = 'theme_mode';

final sharedPrefsProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('Override in ProviderScope');
});

class ThemeModeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() {
    final prefs = ref.watch(sharedPrefsProvider);
    final value = prefs.getString(_key);
    return switch (value) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      'system' => ThemeMode.system,
      // A fresh install opens light rather than following the device. The
      // neobrutalist palette was drawn light-first, and a first run that opens
      // dark on a dark-mode phone is not the introduction we want. Anyone who
      // picks a mode keeps it — this only covers "nothing stored yet".
      _ => ThemeMode.light,
    };
  }

  void toggle() {
    final next = state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    state = next;
    ref.read(sharedPrefsProvider).setString(
        _key, next == ThemeMode.dark ? 'dark' : 'light');
  }

  void setMode(ThemeMode mode) {
    state = mode;
    ref.read(sharedPrefsProvider).setString(_key, switch (mode) {
      ThemeMode.light => 'light',
      ThemeMode.dark => 'dark',
      ThemeMode.system => 'system',
    });
  }
}

final themeModeProvider =
    NotifierProvider<ThemeModeNotifier, ThemeMode>(ThemeModeNotifier.new);
