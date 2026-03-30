import 'package:logging/logging.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'firebase_saves.dart';
import 'google/google.dart';

/// Core game IO for Infinitordle.
class GameIO {
  GameIO({required this.onDataLoadedCallback}) {
    _userChangeListener();
  }

  static final Logger _log = Logger('GI');

  final void Function(String) onDataLoadedCallback;

  final List<String> _recentSnapshotsCache = <String>[];

  /// Loads game state from a Firebase snapshot.
  void _loadFirebaseSnapshot(String? snapshotCurrentOrNull) {
    _log.info("loadFirebaseSnapshot");
    if (snapshotCurrentOrNull == null) {
      return;
    }
    final String snapshotCurrent = snapshotCurrentOrNull;
    if (g.signedIn && !_recentSnapshotsCache.contains(snapshotCurrent)) {
      onDataLoadedCallback.call(snapshotCurrent);
      _recentSnapshotsCache.add(snapshotCurrent);
      if (_recentSnapshotsCache.length > 5) {
        _recentSnapshotsCache.removeAt(0);
      }
    }
  }

  /// Listens to user auth changes to reload state.
  void _userChangeListener() {
    _loadFromFirebaseOrFilesystem(); //initial
    g.gUserNotifier.addListener(() {
      _loadFromFirebaseOrFilesystem();
      fBase.firebaseChangeListener(g.gUser, callback: _loadFirebaseSnapshot);
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
    onDataLoadedCallback.call(gameEncoded);
  }

  /// Saves state to local shared preferences and Firebase if possible.
  Future<void> saveToFirebaseAndFilesystem(String gameEncoded) async {
    // save locally
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('game', gameEncoded);

    // if possible save to firebase
    if (fBase.firebaseOn && g.signedIn) {
      await fBase.firebasePush(g, gameEncoded);
    }
  }
}
