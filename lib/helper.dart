// ignore: depend_on_referenced_packages
import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';

final Logger _globalLog = Logger('GL');

void logGlobal(dynamic x) {
  _globalLog.info(x);
}

void setupGlobalLogger() {
  Logger.root.level = (kDebugMode) ? Level.FINE : Level.INFO;
  //logging.hierarchicalLoggingEnabled = true;
  Logger.root.onRecord.listen((LogRecord record) {
    final String time =
        "${DateTime.now().minute}:${DateTime.now().second}.${DateTime.now().millisecond}";
    final String message = '$time ${record.loggerName} ${record.message}';
    debugPrint(message);
  });
}
