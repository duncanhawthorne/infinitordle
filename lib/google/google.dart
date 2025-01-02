import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:logging/logging.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../app_structure.dart';
import '../constants.dart';
import '../google/src/sign_in_button/mobile.dart';
import '../secrets.dart';

/// The type of the onClick callback for the (mobile) Sign In Button.
//typedef HandleSignInFn = Future<void> Function();

const bool _debugFakeLogin = false;
const String _gUserFakeLogin = "joebloggs@gmail.com";

final bool gOn = googleOnReal &&
    !(defaultTargetPlatform == TargetPlatform.windows && !kIsWeb);

class G {
  G() {
    _startGoogleAccountChangeListener();
    _loadUser();
  }

  static final Logger _log = Logger('GG');

  static const bool _newLoginButtons = false;

  void forceResetUserTo(String x) {
    _log.info("force reset gUser from $gUser to $x");
    _gUser = x;
    _saveUserToFilesystem(gUser, _gUserIcon);
  }

  Widget signInRow(BuildContext context) {
    return ValueListenableBuilder<String>(
        valueListenable: gUserNotifier,
        builder: (BuildContext context, String stringText, Widget? child) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Text(!signedIn
                  ? (_newLoginButtons && kIsWeb ? "" : "Sign in?")
                  : appTitle),
              Tooltip(
                  message: !signedIn ? "Sign in" : "Sign out",
                  child: loginLogoutWidget(context, 25, _color)),
            ],
          );
        });
  }

  Future<void> showLogoutConfirmationScreen(BuildContext context) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: bg,
          surfaceTintColor: bg,
          title: const Text("Sign out?"),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.pop(context, 'Cancel');
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                _signOutAndExtractDetails();
                Navigator.pop(context, 'OK');
                //Navigator.pop(context, 'OK');
              },
              child: const Text('Sign out', style: TextStyle(color: red)),
            ),
          ],
        );
      },
    );
  }

  bool get signedIn => gUser != _gUserDefault;

  String get gUser => gUserNotifier.value;

  set _gUser(String g) =>
      <void>{_log.info("gUserChanged $g"), gUserNotifier.value = g};

  double _iconWidth = 1;
  Color _color = Colors.white;

  Widget loginLogoutWidget(
      BuildContext context, double iconWidth, Color color) {
    _iconWidth = iconWidth;
    _color = color;
    return !gOn
        ? const SizedBox.shrink()
        : ValueListenableBuilder<String>(
            valueListenable: gUserNotifier,
            builder: (BuildContext context, String audioOn, Widget? child) {
              return !signedIn ? _loginButton(context) : _logoutButton(context);
            });
  }

  Widget _loginButton(BuildContext context) {
    const bool newLoginButtons = false;
    return newLoginButtons
        // ignore: dead_code
        ? _platformAdaptiveSignInButton(context)
        : lockStyleSignInButton(context);
  }

  Widget lockStyleSignInButton(BuildContext context) {
    return IconButton(
      iconSize: _iconWidth,
      icon: Icon(Icons.lock, color: _color),
      onPressed: () {
        _signInSilentlyThenDirectly();
      },
    );
  }

  Widget _platformAdaptiveSignInButton(BuildContext context) {
    // different buttons depending on web or mobile. See sign_in_button folder
    return buildSignInButton(
        onPressed:
            _signInDirectly, //relevant on web only, else uses separate code
        context: context,
        g: this);
  }

  static const bool _requireLogoutConfirm = true;
  Widget _logoutButton(BuildContext context) {
    return IconButton(
      iconSize: _iconWidth,
      icon: _gUserIcon == _gUserIconDefault
          ? Icon(Icons.face_outlined, color: _color)
          : CircleAvatar(
              radius: _iconWidth / 2,
              backgroundImage: NetworkImage(_gUserIcon)),
      onPressed: () {
        if (_requireLogoutConfirm) {
          showLogoutConfirmationScreen(context);
          focusNode.requestFocus();
        } else {
          _signOutAndExtractDetails();
        }
      },
    );
  }

  GoogleSignIn googleSignIn = GoogleSignIn(
    //gID defined in secrets.dart, not included in repo
    //in format XXXXXX.apps.googleusercontent.com
    clientId: gID,
    scopes: <String>[
      'email',
    ],
  );

  Future<List<String>> _loadUserFromFilesystem() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String gUser = prefs.getString('gUser') ?? _gUserDefault;
    final String gUserIcon = prefs.getString('gUserIcon') ?? _gUserIconDefault;
    _log.fine("loadUser $gUser");
    return <String>[gUser, gUserIcon];
  }

  Future<void> _saveUserToFilesystem(String gUser, String gUserIcon) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('gUser', gUser);
    await prefs.setString('gUserIcon', gUserIcon);
    _log.fine("saveUser $gUser");
  }

  static const String _gUserDefault = "JoeBloggs";
  static const String _gUserIconDefault = "JoeBloggs";

  GoogleSignInAccount? _user;

  ValueNotifier<String> gUserNotifier = ValueNotifier<String>("JoeBloggs");
  String _gUserIcon = "JoeBloggs";

  Future<void> _loadUser() async {
    final List<String> tmp = await _loadUserFromFilesystem();
    _gUser = tmp[0];
    _gUserIcon = tmp[1];
  }

  void _startGoogleAccountChangeListener() {
    if (gOn) {
      googleSignIn.onCurrentUserChanged
          .listen((GoogleSignInAccount? account) async {
        _log.info("gUser changed");
        _user = account;
        if (_user != null) {
          _log.fine("login successful $_user");
          await _successfulLoginExtractDetails();
        } else {
          _log.fine("logout");
          await _logoutExtractDetails();
        }
      });
    }
  }

  // ignore: unused_element
  Future<void> _signInSilently() async {
    if (gOn) {
      await googleSignIn.signInSilently();
      await _successfulLoginExtractDetails();
    }
  }

  Future<void> _signInDirectly() async {
    _log.fine("webSignIn()");
    if (gOn) {
      try {
        if (_debugFakeLogin) {
          await _debugLoginExtractDetails();
        } else {
          await googleSignIn.signIn();
          await _successfulLoginExtractDetails();
        }
      } catch (e) {
        _log.severe("signInDirectly $e");
      }
    }
  }

  Future<void> _signOut() async {
    if (gOn) {
      if (_debugFakeLogin) {
      } else {
        try {
          await googleSignIn.disconnect();
          await _logoutExtractDetails();
        } catch (e) {
          _log.severe("signOut $e");
        }
      }
      //logoutExtractDetails(); //now handled by listener
    }
  }

  Future<void> _signInSilentlyThenDirectly() async {
    _log.fine("mobileSignIn()");
    if (gOn) {
      if (_debugFakeLogin) {
        await _debugLoginExtractDetails();
      } else {
        await googleSignIn.signInSilently();
        _user = googleSignIn.currentUser;

        if (_user == null) {
          //if sign in silently didn't work
          await googleSignIn.signIn();
          _user = googleSignIn.currentUser;
        }
        await _successfulLoginExtractDetails();
      }
    }
  }

  Future<void> _successfulLoginExtractDetails() async {
    if (_user != null) {
      _log.fine("login extract details");
      _gUser = _user!.email;
      if (_user!.photoUrl != null) {
        _gUserIcon = _user!.photoUrl ?? _gUserIconDefault;
      }
      await _saveUserToFilesystem(gUser, _gUserIcon);
      _log.fine("gUser = $gUser");
    }
  }

  Future<void> _debugLoginExtractDetails() async {
    _log.fine("debugLoginExtractDetails");
    assert(_debugFakeLogin);
    _gUser = _gUserFakeLogin;
    await _saveUserToFilesystem(gUser, _gUserIcon);
    _log.fine("gUser = $gUser");
  }

  Future<void> _logoutExtractDetails() async {
    _log.fine("logout extract details");
    _gUser = _gUserDefault;
    assert(!signedIn);
    await _saveUserToFilesystem(gUser, _gUserIcon);
    _log.fine("gUser =$gUser");
  }

  Future<void> _signOutAndExtractDetails() async {
    _log.fine("sign out and extract details");
    if (gOn) {
      await _signOut();
      await _logoutExtractDetails();
    }
  }
}

final G g = G();
