import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
//firebase_options.dart as per direct download from google, not included in repo
import 'firebase_options.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:infinitordle/app_structure.dart';
import 'package:infinitordle/helper.dart';
import 'package:infinitordle/constants.dart';
import 'package:infinitordle/popup_screens.dart';
import 'package:google_fonts/google_fonts.dart';

Future<void> main() async {
  //debugRepaintRainbowEnabled = true;
  //debugProfileBuildsEnabled = true;
  //debugProfileBuildsEnabledUserWidgets = true;
  //debugProfileLayoutsEnabled = true;
  //debugProfilePaintsEnabled = true;

  WidgetsFlutterBinding.ensureInitialized();
  Future.delayed(const Duration(milliseconds: 1000 * 5), () {
    FlutterNativeSplash
        .remove(); //Hack, but makes sure removed shortly after starting
  });

  if (fbOn) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    if (fbAnalytics) {
      analytics = FirebaseAnalytics.instance;
    }
    db = FirebaseFirestore.instance;
  }
  runApp(const InfinitordleApp());
}

class InfinitordleApp extends StatelessWidget {
  const InfinitordleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: appTitle,
      theme: ThemeData(
        useMaterial3: m3,
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
  initState() {
    super.initState();

    //Hack to make these functions available globally
    ssFunctionList.add(ss);
    showResetScreenFunctionList.add(showResetConfirmScreen);

    game.initiateBoard();
    save.loadUser();
    save.loadKeys();
  }

  void ss() {
    try {
      setState(() {});
    } catch (e) {
      p(["SS error ", e.toString()]);
    }
  }

  Future<void> showResetConfirmScreen() async {
    showResetConfirmScreenReal(context);
  }

  @override
  Widget build(BuildContext context) {
    screen.detectAndUpdateForScreenSize(context);
    return infinitordleWidget();
  }
}
