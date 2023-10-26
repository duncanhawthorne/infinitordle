import 'package:infinitordle/helper.dart';
import 'package:infinitordle/constants.dart';
import 'package:infinitordle/globals.dart';
import 'package:infinitordle/google_logic.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Save {
  Future<void> loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    g.setUser(prefs.getString('gUser') ?? gUserDefault);
    g.setUserIcon(prefs.getString('gUserIcon') ?? gUserIconDefault);
    p(["loadUser", g.getUser(), g.getUserIcon()]);
  }

  Future<void> saveUser() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('gUser', g.getUser());
    await prefs.setString('gUserIcon', g.getUserIcon());
    p(["saveUser", g.getUser(), g.getUserIcon()]);
  }

  Future<void> loadKeys() async {
    final prefs = await SharedPreferences.getInstance();
    String gameEncoded = "";

    if (!g.signedIn()) {
      //load from local save
      gameEncoded = prefs.getString('game') ?? "";
    } else {
      //load from firebase
      gameEncoded = "";
      final docRef = db.collection("states").doc(g.getUser());
      await docRef.get().then(
        (DocumentSnapshot doc) {
          final gameEncodedTmp = doc.data() as Map<String, dynamic>;
          gameEncoded = gameEncodedTmp["data"];
        },
        // ignore: avoid_print
        onError: (e) => print("Error getting document: $e"),
      );
    }
    game.loadFromEncodedState(gameEncoded);
    //var ss = globalFunctions[0];
    ss(); //GLOBALSS
  }

  Future<void> saveKeys() async {
    saveOrLoadKeysCountCache++;
    String gameEncoded = game.getEncodeCurrentGameState();
    //p(["SAVE keys",gameEncoded]);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('game', gameEncoded);

    firebasePush(gameEncoded);
  }

  Future<void> firebasePush(state) async {
    if (g.signedIn()) {
      // Create a new user with a first and last name
      final dhState = <String, dynamic>{"data": state};
      db
          .collection("states")
          .doc(g.getUser())
          .set(dhState)
          // ignore: avoid_print
          .onError((e, _) => print("Error writing document: $e"));
    }
  }

  String firebasePull(snapshot) {
    String snapshotCurrent = "";
    snapshot.data!.docs
        .map((DocumentSnapshot document) {
          if (document.id == g.getUser()) {
            Map<String, dynamic> dataTmpQ =
                document.data() as Map<String, dynamic>;
            snapshotCurrent = dataTmpQ["data"].toString();
            return null;
          }
        })
        .toList()
        .cast();
    return snapshotCurrent;
  }
}
