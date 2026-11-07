import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// Which input an error belongs to.
enum AuthField { email, password, general }

class AuthFailure {
  final AuthField field;
  final String message;
  const AuthFailure(this.field, this.message);
}

/// All Firebase Auth calls live here. Screens never talk to Firebase directly.
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  static bool _googleInitialized = false;

  User? get currentUser => _auth.currentUser;

  Future<void> _ensureGoogleInitialized() async {
    if (_googleInitialized) return;
    await GoogleSignIn.instance.initialize();
    _googleInitialized = true;
  }

  /// Returns null on success, or an [AuthFailure] describing what went wrong.
  Future<AuthFailure?> login(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      return null;
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'invalid-email':
          return const AuthFailure(
            AuthField.email,
            'Please enter a valid email address.',
          );
        // Wrong email and wrong password get the SAME message on purpose,
        // so nobody can discover which emails are registered.
        case 'invalid-credential':
        case 'wrong-password':
        case 'user-not-found':
          return const AuthFailure(
            AuthField.general,
            'Incorrect email or password.',
          );
        case 'user-disabled':
          return const AuthFailure(
            AuthField.general,
            'This account has been disabled. Contact your manager.',
          );
        case 'too-many-requests':
          return const AuthFailure(
            AuthField.general,
            'Too many attempts. Please try again later.',
          );
        case 'network-request-failed':
          return const AuthFailure(
            AuthField.general,
            'No internet connection.',
          );
        default:
          return const AuthFailure(
            AuthField.general,
            'Something went wrong. Please try again.',
          );
      }
    } catch (_) {
      return const AuthFailure(
        AuthField.general,
        'Something went wrong. Please try again.',
      );
    }
  }

  /// Google sign-in. Only accounts that already exist (created by the owner)
  /// may sign in. Returns null on success, or an [AuthFailure].
  /// If the user just closes the Google sheet, the failure has an EMPTY
  /// message: the screen should show nothing in that case.
  Future<AuthFailure?> signInWithGoogle() async {
    const notRegistered = AuthFailure(
      AuthField.general,
      'This Google account is not registered. Contact your manager.',
    );
    try {
      await _ensureGoogleInitialized();
      final googleUser = await GoogleSignIn.instance.authenticate();
      final idToken = googleUser.authentication.idToken;
      if (idToken == null) {
        return const AuthFailure(
          AuthField.general,
          'Google sign-in failed. Please try again.',
        );
      }

      final credential = GoogleAuthProvider.credential(idToken: idToken);
      final result = await _auth.signInWithCredential(credential);

      // Safety net: if Firebase created a brand-new account, this person is
      // not an employee. Remove the account and sign out.
      if (result.additionalUserInfo?.isNewUser ?? false) {
        try {
          await result.user?.delete();
        } catch (_) {}
        await logout();
        return notRegistered;
      }
      return null;
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) {
        return const AuthFailure(AuthField.general, '');
      }
      return const AuthFailure(
        AuthField.general,
        'Google sign-in failed. Please try again.',
      );
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        // New account creation is disabled in the console.
        case 'admin-restricted-operation':
          return notRegistered;
        case 'account-exists-with-different-credential':
          return const AuthFailure(
            AuthField.general,
            'This email uses a different sign-in method. Use your password.',
          );
        case 'user-disabled':
          return const AuthFailure(
            AuthField.general,
            'This account has been disabled. Contact your manager.',
          );
        case 'too-many-requests':
          return const AuthFailure(
            AuthField.general,
            'Too many attempts. Please try again later.',
          );
        case 'network-request-failed':
          return const AuthFailure(
            AuthField.general,
            'No internet connection.',
          );
        default:
          return const AuthFailure(
            AuthField.general,
            'Google sign-in failed. Please try again.',
          );
      }
    } catch (_) {
      return const AuthFailure(
        AuthField.general,
        'Google sign-in failed. Please try again.',
      );
    }
  }

  Future<String?> sendPasswordReset(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
      return null;
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'invalid-email':
          return 'Please enter a valid email address.';
        case 'network-request-failed':
          return 'No internet connection.';
        case 'too-many-requests':
          return 'Too many attempts. Please try again later.';
        // 'user-not-found' is deliberately treated as success so nobody can
        // discover which emails are registered.
        case 'user-not-found':
          return null;
        default:
          return 'Something went wrong. Please try again.';
      }
    } catch (_) {
      return 'Something went wrong. Please try again.';
    }
  }

  Future<void> logout() async {
    try {
      if (_googleInitialized) await GoogleSignIn.instance.signOut();
    } catch (_) {}
    await _auth.signOut();
  }
}