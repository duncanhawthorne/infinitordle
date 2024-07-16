// ignore: depend_on_referenced_packages
import 'package:flutter/material.dart';

import 'card_colors.dart';
import 'card_flips.dart';
import 'firebase.dart';
import 'game_logic.dart';
import 'google_logic.dart';
import 'saves.dart';
import 'screen.dart';
import 'src/title_fix_stub.dart'
    if (dart.library.js_interop) 'src/title_fix_web.dart';

final Game game = Game();
final Save save = Save();
final Flips flips = Flips();
final CardColors cardColors = CardColors();
final Screen screen = Screen();
final G g = G();
final FireBase fBase = FireBase();

void p(var x) {
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
