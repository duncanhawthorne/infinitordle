import 'package:google_sign_in/google_sign_in.dart';

const gID =
    '[REDACTED].apps.googleusercontent.com';

GoogleSignIn googleSignIn = GoogleSignIn(
  clientId: gID,
  scopes: <String>[
    'email',
  ],
);
