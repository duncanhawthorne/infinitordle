import 'dart:core';

import 'package:flutter/services.dart';

import 'workarounds_stub.dart'
    if (dart.library.js_interop) 'workarounds_web.dart';

/// Sets the system status bar color.
void setStatusBarColor(Color color) {
  SystemChrome.setSystemUIOverlayStyle(
    SystemUiOverlayStyle(
      statusBarColor: color, // Status bar color
    ),
  );
}

/// Applies a workaround for a bug in Flutter on iOS web regarding page titles.
void fixTitlePerm() {
  // to workaround a bug in flutter on ios web
  titleFixPermReal();
}

/// Returns the gesture inset height, providing a workaround for iOS web layout issues.
double gestureInset() {
  // to workaround a bug in flutter on ios web
  return gestureInsetReal(); //either from web or stub depending on platform
}
