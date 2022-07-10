// ignore_for_file: prefer_interpolation_to_compose_strings

import 'package:infinitordle/helper.dart';
import 'package:infinitordle/constants.dart';
import 'package:infinitordle/secrets.dart';
import 'package:google_sign_in/google_sign_in.dart';

GoogleSignInAccount? currentUser;

Future<void> initalSignIn() async {
  googleSignIn.onCurrentUserChanged.listen((GoogleSignInAccount? account) {
    currentUser = account;
  });
  await googleSignIn.signInSilently();
}

Future<void> handleSignIn() async {
  await _handleSignInReal();
  await _handleSignInReal();
}

Future<void> _handleSignInReal() async {
  p("_handleSignInReal()");
  if (fakeLogin) {
    // ignore: avoid_print
    p("fakelogin");
    gUser = "X";
  } else {
    //print("real");
    try {
      p("try");
      p("gUser" + gUser);
      // ignore: await_only_futures
      await googleSignIn.onCurrentUserChanged
          .listen((GoogleSignInAccount? account) {
        currentUser = account;
      });
      await googleSignIn.signIn();
      googleSignIn.onCurrentUserChanged.listen((GoogleSignInAccount? account) {
        currentUser = account;
      });
      final GoogleSignInAccount? user = currentUser;
      if (user != null) {
        gUser = user.email;
      }
      p("gUser" + gUser);
    } catch (error) {
      p(error);
    }
  }
  await saveUser();
  await loadKeys();
  initiateFlipState();
}

Future<void> handleSignOut() async {
  //print("signout");
  if (fakeLogin) {
  } else {
    await googleSignIn.disconnect();
  }
  gUser = gUserDefault;
  //print(gUser);
  await saveUser();
  resetBoardReal(true);
  await loadKeys();
  initiateFlipState();
}
