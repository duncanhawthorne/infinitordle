import 'package:infinitordle/helper.dart';
import 'package:infinitordle/constants.dart';
import 'package:infinitordle/globals.dart';
import 'package:infinitordle/google_logic.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Save {
  Future<void> loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    google.setgUser(prefs.getString('gUser') ?? gUserDefault);
    google.setgUserIcon(prefs.getString('gUserIcon') ?? gUserIconDefault);
    p(["loadUser", google.getgUser(), google.getgUserIcon()]);
  }

  Future<void> saveUser() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('gUser', google.getgUser());
    await prefs.setString('gUserIcon', google.getgUserIcon());
    p(["saveUser", google.getgUser(), google.getgUserIcon()]);
  }

  Future<void> loadKeys() async {
    final prefs = await SharedPreferences.getInstance();
    String gameEncoded = "";

    if (!google.signedIn()) {
      //load from local save
      gameEncoded = prefs.getString('game') ?? "";
    } else {
      //load from firebase
      gameEncoded = "";
      final docRef = db.collection("states").doc(google.getgUser());
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
    if (google.signedIn()) {
      // Create a new user with a first and last name
      final dhState = <String, dynamic>{"data": state};
      db
          .collection("states")
          .doc(google.getgUser())
          .set(dhState)
          // ignore: avoid_print
          .onError((e, _) => print("Error writing document: $e"));
    }
  }

  String firebasePull(snapshot) {
    String snapshotCurrent = "";
    snapshot.data!.docs
        .map((DocumentSnapshot document) {
          if (document.id == google.getgUser()) {
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


