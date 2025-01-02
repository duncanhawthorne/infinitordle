import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';

import 'firebase_options.dart';
import 'game_logic.dart';
import 'google/google.dart';

class FBase {
  FBase() {
    //unawaited(fBase.initialize());
  }

  final bool firebaseOn = firebaseOnReal &&
      !(defaultTargetPlatform == TargetPlatform.windows && !kIsWeb);
  late final bool fbAnalytics = firebaseOn && true;

  static const String _userSaves = "states";
  static const String data = "data";

  static final Logger _log = Logger('FB');

  FirebaseFirestore? get db => _db;
  FirebaseFirestore? _db;

  FirebaseAnalytics? analytics;

  Future<void> initialize() async {
    if (firebaseOn) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      if (fbAnalytics) {
        analytics = FirebaseAnalytics.instance;
      }
      _db = FirebaseFirestore.instance;
    } else {
      _log.info("Off");
    }
  }

  Future<void> firebasePush(G g, dynamic state) async {
    await initialize();
    if (firebaseOn && g.signedIn) {
      final Map<String, dynamic> dhState = <String, dynamic>{data: state};
      await _db!
          .collection(_userSaves)
          .doc(g.gUser)
          .set(dhState)
          .onError((Object? e, _) => _log.severe("Error writing document: $e"));
    }
  }

  Future<String> firebasePull(G g) async {
    await initialize();
    String gameEncoded = "";
    if (firebaseOn && g.signedIn) {
      final DocumentReference<Map<String, dynamic>> docRef =
          _db!.collection(_userSaves).doc(g.gUser);
      await docRef.get().then(
        (DocumentSnapshot<dynamic> doc) {
          final Map<String, dynamic> gameEncodedTmp =
              doc.data() as Map<String, dynamic>;
          gameEncoded = gameEncodedTmp[data];
        },
        onError: (dynamic e) => _log.severe("Error getting document: $e"),
      );
    }
    return gameEncoded;
  }

  Future<void> firebaseChangeListener(String userId) async {
    if (fBase.firebaseOn) {
      await fBase.initialize();
      // ignore: always_specify_types
      StreamSubscription? listener;
      listener = fBase.db!
          .collection(_userSaves)
          .doc(userId)
          .snapshots()
          .listen((DocumentSnapshot<Map<String, dynamic>> snapshot) {
        //useId is fixed for the duration of listener
        if (g.gUser != userId) {
          listener!.cancel();
          return;
        }
        game.loadFirebaseSnapshot(snapshot.data());
      });
    }
  }
}

final FBase fBase = FBase();
