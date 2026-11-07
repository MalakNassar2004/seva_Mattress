import 'package:local_auth/local_auth.dart';

enum UnlockResult { success, failed, canceled, lockedOut, unavailable }

/// Thin wrapper around local_auth (v3 API). No UI here.
class AppLockService {
  final LocalAuthentication _auth = LocalAuthentication();

  /// true = Face ID / Touch ID only. Set to false to also allow the
  /// device passcode as a fallback.
  static const bool biometricOnly = true;

  Future<bool> isAvailable() async {
    try {
      final supported = await _auth.isDeviceSupported();
      final canCheck = await _auth.canCheckBiometrics;
      return supported && canCheck;
    } catch (_) {
      return false;
    }
  }

  Future<UnlockResult> authenticate({
    String reason = 'Unlock Seva Mattress',
  }) async {
    try {
      final ok = await _auth.authenticate(
        localizedReason: reason,
        biometricOnly: biometricOnly,
      );
      return ok ? UnlockResult.success : UnlockResult.failed;
    } on LocalAuthException catch (e) {
      if (e.code == LocalAuthExceptionCode.userCanceled) {
        return UnlockResult.canceled;
      }
      if (e.code == LocalAuthExceptionCode.temporaryLockout ||
          e.code == LocalAuthExceptionCode.biometricLockout) {
        return UnlockResult.lockedOut;
      }
      if (e.code == LocalAuthExceptionCode.noBiometricHardware ||
          e.code == LocalAuthExceptionCode.noBiometricsEnrolled ||
          e.code == LocalAuthExceptionCode.noCredentialsSet) {
        return UnlockResult.unavailable;
      }
      return UnlockResult.failed;
    } catch (_) {
      return UnlockResult.failed;
    }
  }
}