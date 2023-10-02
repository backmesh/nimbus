import 'package:flutter/foundation.dart';

class Logger {
  static debug(Object? obj) {
    if (kReleaseMode) return;
    print(obj);
  }

  static debugMany(List<Object?> obj) {
    if (kReleaseMode) return;
    for (var o in obj) {
      print(o);
    }
  }
}
