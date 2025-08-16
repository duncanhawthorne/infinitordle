import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'wordlist.dart';

//Debug
const bool cheatMode = kDebugMode && false;

//Branding
const String appTitle = "infinitordle";
const String appTitle1 = cheatMode ? "cheat" : "infinit";
const String appTitle3 = "rdle";

const Color bg = Color(0xff222222);
const Color grey = Color(0xff555555);
const Color white = Colors.white;
const MaterialColor green = Colors.green;
const MaterialColor amber = Colors.amber;
const MaterialColor red = Colors.red;
const Color transp = Colors.transparent;

//Game design
const int numBoards = 4; //must be divisible by 2
const int numRowsPerBoard = 8; // originally 5 + number of boards, i.e. 9
const int cols = 5; //number of letters in a word
const bool infMode = true;
const double boardSpacer = 8;

const String kBackspace = "<";
const String kEnter = ">";
const String kNonKey = " ";

//Helper text
const List<String> keyboardList = kKbdList;

//Animations
const bool _noAnimations = false;
const int _slowDownFactor = cheatMode ? 1 : 1;
const int _durMult = _noAnimations ? 0 : 1 * _slowDownFactor;
const int delayMult = _noAnimations ? 0 : 1 * _slowDownFactor;
const int gradualRevealDelayTime = delayMult * 150;
const int slideTime = _durMult * 200;
const int flipTime = _durMult * 500;

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
