

import 'package:flutter/cupertino.dart';
import 'package:logging/logging.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'firebase_saves.dart';
import 'game_state.dart';
import 'google/google.dart';

/// Core game IO for Infinitordle.
class GameIO extends ChangeNotifier {
  GameIO() {
    _userChangeListener();
  }

  static final Logger _log = Logger('GS');

  final List<String> _recentSnapshotsCache = <String>[];

  /// Loads game state from a Firebase snapshot.
  void loadFirebaseSnapshot(String? snapshotCurrentOrNull) {
    _log.info("loadFirebaseSnapshot");
    if (snapshotCurrentOrNull != null) {
      final String snapshotCurrent = snapshotCurrentOrNull;
      if (g.signedIn && !_recentSnapshotsCache.contains(snapshotCurrent)) {
        if (snapshotCurrent != gameS.getEncodeCurrentGameState()) {
          gameS.loadFromEncodedState(snapshotCurrent);
        }
        _recentSnapshotsCache.add(snapshotCurrent);
        if (_recentSnapshotsCache.length > 5) {
          _recentSnapshotsCache.removeAt(0);
        }
      }
    }
  }

  /// Listens to user auth changes to reload state.
  void _userChangeListener() {
    _loadFromFirebaseOrFilesystem(); //initial
    g.gUserNotifier.addListener(() {
      _loadFromFirebaseOrFilesystem();
      fBase.firebaseChangeListener(g.gUser, callback: loadFirebaseSnapshot);
    });
  }

  /// Loads state from either Firebase or local shared preferences.
  Future<void> _loadFromFirebaseOrFilesystem() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    String gameEncoded = "";

    if (!fBase.firebaseOn || !g.signedIn) {
      // load from local save
      gameEncoded = prefs.getString('game') ?? "";
    } else {
      // load from firebase
      gameEncoded = await fBase.firebasePull(g);
    }
    gameS.loadFromEncodedState(gameEncoded);
  }

  /// Saves state to local shared preferences and Firebase if possible.
  Future<void> saveToFirebaseAndFilesystem() async {
    final String gameEncoded = gameS.getEncodeCurrentGameState();

    // save locally
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('game', gameEncoded);

    // if possible save to firebase
    if (fBase.firebaseOn && g.signedIn) {
      await fBase.firebasePush(g, gameEncoded);
    }
  }

}

/// Global singleton instance of [GameIO].
final GameIO gameI = GameIO();