import 'package:flutter/foundation.dart';

/// Resolves the base URL for the Product API across platforms.
///
/// Priority:
///   1. `API_BASE_URL` compile-time variable (via `--dart-define=API_BASE_URL=...`).
///   2. Platform defaults (web/Android emulator -> localhost; physical devices
///      should pass a `--dart-define` with the host machine's LAN IP).
class Environment {
  Environment._();

  static const String _dartDefineKey = 'API_BASE_URL';

  static String get apiBaseUrl {
    const fromDefine = String.fromEnvironment(_dartDefineKey);
    if (fromDefine.isNotEmpty) return fromDefine;

    if (kIsWeb) return 'http://localhost:5148';
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:5148';
    }
    // iOS simulator, macOS, Windows, Linux all expose localhost.
    return 'http://localhost:5148';
  }
}
