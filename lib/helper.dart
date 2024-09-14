// ignore: depend_on_referenced_packages
import 'package:flutter/material.dart';

import 'src/title_fix_stub.dart'
    if (dart.library.js_interop) 'src/title_fix_web.dart';

void debug(var x) {
  debugPrint("///// A ${DateTime.now()} ${x ?? "null"}");
}

void fixTitlePersistent() {
  for (int i = 0; i < 2; i++) {
    Future.delayed(Duration(seconds: i), () {
      fixTitle();
    });
  }
}

void fixTitle() {
  fixTitleReal(); //either from web or stub
}

double gestureInset() {
  // to workaround a bug in flutter on ios web
  return gestureInsetReal(); //either from web or stub depending on platform
}
