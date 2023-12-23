import 'package:google_sign_in/google_sign_in.dart';
import 'package:infinitordle/helper.dart';
import 'package:infinitordle/constants.dart';

//gID defined in secrets.dart, not included in repo
//in format XXXXXX.apps.googleusercontent.com
import 'package:infinitordle/secrets.dart';

class Google {
  GoogleSignIn googleSignIn = GoogleSignIn(
    //gID defined in secrets.dart, not included in repo
    //in format XXXXXX.apps.googleusercontent.com
    clientId: gID,
    scopes: <String>[
      'email',
    ],
  );

  var gUser = "JoeBloggs";
  var gUserIcon = "JoeBloggs";

  bool signedIn() {
    return gUser != gUserDefault;
  }

  String getUser() {
    return gUser;
  }

  void setUser(g) {
    gUser = g;
  }

  String getUserIcon() {
    return gUserIcon;
  }

  void setUserIcon(gui) {
    gUserIcon = gui;
  }

  Future<void> signIn() async {
    p("gSignIn()");
    if (gOn) {
      if (debugFakeLogin) {
        gUser = gUserFakeLogin;
        await save.saveUser();
        await save.loadKeys();
      } else {
        GoogleSignInAccount? user;

        await googleSignIn.signInSilently();
        user = googleSignIn.currentUser;

        if (user == null) {
          //if sign in silently didn't work
          await googleSignIn.signIn();
          user = googleSignIn.currentUser;
        }

        if (user != null) {
          gUser = user.email;
          if (user.photoUrl != null) {
            gUserIcon = user.photoUrl ?? gUserIconDefault;
          }
          await save.saveUser();
          await save.loadKeys();
        }
      }
    }
  }

  Future<void> signOut() async {
    if (gOn) {
      if (debugFakeLogin) {
      } else {
        try {
          await googleSignIn.disconnect();
        } catch (e) {
          p(e);
        }
      }
      gUser = gUserDefault;
      await save.saveUser();
      game.resetBoard();
      await save.loadKeys();
    }
  }
}
