import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_ios_web_touch_override/flutter_ios_web_touch_override.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_structure.dart';
import 'constants.dart';
import 'firebase_saves.dart';
import 'game_logic.dart';
import 'helper.dart';
import 'src/workarounds.dart';

Future<void> main() async {
  //debugRepaintRainbowEnabled = true;
  //debugProfileBuildsEnabled = true;
  //debugProfileBuildsEnabledUserWidgets = true;
  //debugProfileLayoutsEnabled = true;
  //debugProfilePaintsEnabled = true;

  WidgetsFlutterBinding.ensureInitialized();
  Future<Null>.delayed(const Duration(milliseconds: 1000 * 5), () {
    FlutterNativeSplash.remove(); //Hack, but makes sure removed shortly after starting
  });

  unawaited(fBase.initialize());

  setupGlobalLogger();

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(statusBarColor: bg),
  );
  fixTitlePerm();

  blockTouchDefault(true);
  runApp(const InfinitordleApp());
}

class InfinitordleApp extends StatelessWidget {
  const InfinitordleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: appTitle,
      navigatorKey: navigatorKey,
      theme: ThemeData(
        primaryColor: bg,
        //ios pwa status bar color
        useMaterial3: true,
        scaffoldBackgroundColor: bg,
        colorScheme: ColorScheme.fromSeed(
          seedColor: bg,
          brightness: Brightness.dark,
        ),
        //fontFamily:
        //    '-apple-system', //https://github.com/flutter/flutter/issues/93140
        fontFamily: GoogleFonts.roboto().fontFamily,
        appBarTheme: const AppBarTheme(
          backgroundColor: bg,
          foregroundColor: bg,
        ),
      ),
      home: const Infinitordle(),
    );
  }
}

class Infinitordle extends StatefulWidget {
  const Infinitordle({super.key});

  @override
  State<Infinitordle> createState() => _InfinitordleState();
}

class _InfinitordleState extends State<Infinitordle> {
  @override
  void initState() {
    super.initState();
    game.initiateBoard();
  }

  @override
  Widget build(BuildContext context) {
    return infinitordleWidget();
  }
}
