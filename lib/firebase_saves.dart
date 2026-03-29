import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:google_user/google_user.dart';
import 'package:logging/logging.dart';

import 'firebase_options.dart';
import 'google/google.dart';

/// Manages Firebase services, including Firestore for cloud saves and Analytics.
class FBase {
  FBase() {
    //unawaited(fBase.initialize());
  }

  /// Indicates if Firebase is enabled for the current platform.
  final bool firebaseOn =
      firebaseOnReal &&
      !(defaultTargetPlatform == TargetPlatform.windows && !kIsWeb);
  late final bool fbAnalytics = firebaseOn && true;

  static const String _userSaves = "states";
  static const String _data = "data";

  static final Logger _log = Logger('FB');

  FirebaseFirestore? _db;

  FirebaseAnalytics? analytics;

  /// Initializes Firebase and its sub-services if [firebaseOn] is true.
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

  /// Pushes the current game state to Firebase Firestore for the signed-in user.
  Future<void> firebasePush(G g, dynamic state) async {
    await initialize();
    if (firebaseOn && g.signedIn) {
      final Map<String, dynamic> dhState = <String, dynamic>{_data: state};
      await _db!
          .collection(_userSaves)
          .doc(g.gUser)
          .set(dhState)
          .onError((Object? e, _) => _log.severe("Error writing document: $e"));
    }
  }

  /// Pulls the game state from Firebase Firestore for the signed-in user.
  Future<String> firebasePull(G g) async {
    await initialize();
    String gameEncoded = "";
    if (firebaseOn && g.signedIn) {
      final DocumentReference<Map<String, dynamic>> docRef = _db!
          .collection(_userSaves)
          .doc(g.gUser);
      await docRef.get().then((DocumentSnapshot<dynamic> doc) {
        final Map<String, dynamic> gameEncodedTmp =
            doc.data() as Map<String, dynamic>;
        gameEncoded = gameEncodedTmp[_data];
      }, onError: (dynamic e) => _log.severe("Error getting document: $e"));
    }
    return gameEncoded;
  }

  /// Sets up a real-time listener for changes to the user's game state in Firestore.
  Future<void> firebaseChangeListener(
    String userId, {
    required Function callback,
  }) async {
    await initialize();
    if (fBase.firebaseOn) {
      // ignore: always_specify_types
      StreamSubscription? listener;
      listener = _db!.collection(_userSaves).doc(userId).snapshots().listen((
        DocumentSnapshot<Map<String, dynamic>> snapshot,
      ) {
        //userId is fixed for the duration of listener
        if (g.gUser != userId) {
          listener!.cancel();
          return;
        }
        String? snapshotCurrentOrNull;
        final Map<String, dynamic>? userDocument = snapshot.data();
        if (userDocument != null) {
          snapshotCurrentOrNull = userDocument[_data];
        }
        callback(snapshotCurrentOrNull);
      });
    }
  }
}

/// Global instance of [FBase] to be used across the app.
final FBase fBase = FBase();
