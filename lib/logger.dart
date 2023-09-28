import 'package:flutter/foundation.dart';

class Logger {
  static debug(Object? obj) {
    if (!kReleaseMode) print(obj);
  }
}
