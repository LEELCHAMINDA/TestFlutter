import 'dart:io';

import 'package:flutter/foundation.dart';

class Environment {
  Environment._();

  static String get apiBaseUrl {
    if (kIsWeb) return 'http://localhost:5148';
    if (Platform.isAndroid) return 'http://10.0.2.2:5148';
    return 'http://localhost:5148';
  }
}
