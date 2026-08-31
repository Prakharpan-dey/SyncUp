import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Builds the human-readable name shown on the "Devices" screen.
///
/// Purely cosmetic — it helps someone recognise which row is their old phone
/// before signing it out. Nothing is authorised on the strength of it, so a
/// best-effort guess is fine and a failure is never worth surfacing.
class DeviceLabelService {
  final DeviceInfoPlugin _plugin;

  /// Resolved once and reused: the platform channel round-trip is not free, and
  /// the answer cannot change while the app is running.
  String? _cached;

  DeviceLabelService([DeviceInfoPlugin? plugin])
      : _plugin = plugin ?? DeviceInfoPlugin();

  /// e.g. "Pixel 8 Pro · Android 15", or null if it cannot be determined.
  Future<String?> resolve() async {
    if (_cached != null) return _cached;

    try {
      final label = await _read();
      if (label == null || label.isEmpty) return null;
      // The column is varchar(120); trim rather than let the request 422.
      _cached = label.length > 120 ? label.substring(0, 120) : label;
      return _cached;
    } catch (e) {
      debugPrint('DeviceLabelService: could not resolve device name: $e');
      return null;
    }
  }

  Future<String?> _read() async {
    if (kIsWeb) {
      final web = await _plugin.webBrowserInfo;
      final browser = web.browserName.name;
      return browser.isEmpty ? 'Web browser' : 'Web · $browser';
    }

    if (Platform.isAndroid) {
      final a = await _plugin.androidInfo;
      // `model` alone is often a code name ("Pixel 8 Pro" vs "husky"), so pair
      // it with the marketing brand when they differ.
      final brand = a.brand.trim();
      final model = a.model.trim();
      final name = model.toLowerCase().startsWith(brand.toLowerCase())
          ? model
          : '$brand $model'.trim();
      return '$name · Android ${a.version.release}';
    }

    if (Platform.isIOS) {
      final i = await _plugin.iosInfo;
      // utsname.machine is an identifier like "iPhone16,2"; `name` is what the
      // owner actually called the device, which is friendlier here.
      return '${i.name} · iOS ${i.systemVersion}';
    }

    return null;
  }
}

final deviceLabelServiceProvider = Provider<DeviceLabelService>(
  (ref) => DeviceLabelService(),
);
