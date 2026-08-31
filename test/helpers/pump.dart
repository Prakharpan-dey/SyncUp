import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:syncup/core/theme/app_theme.dart';

/// Mounts a widget with the app's real theme.
///
/// The theme matters: the neobrutalist widgets read `Theme.of(context)` for
/// their text styles and `Theme.of(context).brightness` to pick colours, so
/// pumping under a bare MaterialApp would exercise a different widget than the
/// one that ships.
///
/// Overrides are supplied as a [ProviderContainer] rather than a list, because
/// Riverpod 3 does not export the `Override` type — a list literal only infers
/// at the call site, so it cannot cross a function boundary. Building the
/// container in the test also lets it read providers back afterwards.
Future<void> pumpApp(
  WidgetTester tester,
  Widget child, {
  ProviderContainer? container,
}) async {
  await tester.pumpWidget(
    _scope(
      container,
      MaterialApp(theme: AppTheme.light, home: Scaffold(body: child)),
    ),
  );
  await tester.pump();
}

/// Mounts a full screen — one that supplies its own Scaffold.
Future<void> pumpScreen(
  WidgetTester tester,
  Widget screen, {
  ProviderContainer? container,
}) async {
  await tester.pumpWidget(
    _scope(container, MaterialApp(theme: AppTheme.light, home: screen)),
  );
  await tester.pump();
}

Widget _scope(ProviderContainer? container, Widget child) =>
    container == null
        ? ProviderScope(child: child)
        : UncontrolledProviderScope(container: container, child: child);
