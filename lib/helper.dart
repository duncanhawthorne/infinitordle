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
    if (dart.library.js_interop) 'title_fix_web.dart';

Game game = Game();
Save save = Save();
Flips flips = Flips();
CardColors cardColors = CardColors();
Screen screen = Screen();
Google g = Google();
FireBase fBase = FireBase();

void p(var x) {
  debugPrint("///// A ${DateTime.now()} ${x ?? "null"}");
}

void fixTitle() {
  fixTitleReal(); //either from web or stub
}
