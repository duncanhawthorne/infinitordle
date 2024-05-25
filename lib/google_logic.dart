import 'package:google_sign_in/google_sign_in.dart';
import 'package:infinitordle/helper.dart';
import 'package:infinitordle/constants.dart';
import 'package:flutter/material.dart';

import 'app_structure.dart';
import 'src/sign_in_button.dart';
import 'dart:async';


//gID defined in secrets.dart, not included in repo
//in format XXXXXX.apps.googleusercontent.com
import 'package:infinitordle/secrets.dart';

/// The type of the onClick callback for the (mobile) Sign In Button.
//typedef HandleSignInFn = Future<void> Function();


Widget lockStyleSignInButton(context) {
  return IconButton(
    iconSize: 25,
    icon: const Icon(Icons.lock_outlined),
    onPressed: () {
      g.signInDirectly(); //signInSilentlyThenDirectly();
      try {
        Navigator.pop(context!, 'OK');
        focusNode.requestFocus();
      }
      catch(e) {
        p("No pop");
      }
    },
  );
}

class Google {
  GoogleSignIn googleSignIn = GoogleSignIn(
    //gID defined in secrets.dart, not included in repo
    //in format XXXXXX.apps.googleusercontent.com
    clientId: gID,
    scopes: <String>[
      'email',
    ],
  );

  GoogleSignInAccount? _user;

  var gUser = "JoeBloggs";
  var gUserIcon = "JoeBloggs";

  void startGoogleAccountChangeListener() {
    googleSignIn.onCurrentUserChanged
        .listen((GoogleSignInAccount? account) async {
      _user = account;
      if (_user != null) {
        p(["login successful", _user]);
        successfulLoginExtractDetails();
      }
      else {
        p(["logout"]);
        logoutExtractDetails();
      }
    });
  }

  void signInSilently() {
    if (gOn) {
      googleSignIn.signInSilently();
    }
  }

  Future<void> signInDirectly() async {
    p("webSignIn()");
    if (gOn) {
      try {
        if (debugFakeLogin) {
          debugLoginExtractDetails();
        } else {
          await googleSignIn.signIn();
        }
      } catch (error) {
        p(error);
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
      //logoutExtractDetails(); //now handled by listener
    }
  }

  Future<void> signInSilentlyThenDirectly() async {
    p("mobileSignIn()");
    if (gOn) {
      if (debugFakeLogin) {
        debugLoginExtractDetails();
      } else {
        await googleSignIn.signInSilently();
        _user = googleSignIn.currentUser;

        if (_user == null) {
          //if sign in silently didn't work
          await googleSignIn.signIn();
          _user = googleSignIn.currentUser;
        }
        successfulLoginExtractDetails();
      }
    }
  }

  void successfulLoginExtractDetails() async {
    p("login extract details");
    if (_user != null) {
      gUser = _user!.email;
      if (_user!.photoUrl != null) {
        gUserIcon = _user!.photoUrl ?? gUserIconDefault;
      }
      await save.saveUser();
      await save.loadKeys();
    }
  }

  void debugLoginExtractDetails() async {
    p("debugLoginExtractDetails");
    assert(debugFakeLogin);
    gUser = gUserFakeLogin;
    await save.saveUser();
    await save.loadKeys();
  }

  void logoutExtractDetails() async {
    p("logout extract details");
    gUser = gUserDefault;
    await save.saveUser();
    game.resetBoard();
    await save.loadKeys();
  }

  Future<void> signOutAndExtractDetails() async {
    p("sign out and extract details");
    if (gOn) {
      await signOut();
      logoutExtractDetails();
    }
  }

  Widget platformAdaptiveSignInButton(context) {
    // different buttons depending on web or mobile. See sign_in_button folder
    return buildSignInButton(
        onPressed: signInDirectly, //relevant on web only, else uses separate code
        context: context);
  }

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
}
