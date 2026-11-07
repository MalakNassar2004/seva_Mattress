import 'package:flutter/foundation.dart';

enum OtpSendResult { sent, failed }

enum OtpVerifyResult { success, wrongCode, expired, failed }

/// Sends and verifies the SMS code. Screens only talk to this interface.
abstract class OtpService {
  /// Debug builds use the fake service. Release builds use the real one,
  /// so the fake can never ship by accident.
  factory OtpService() =>
      kDebugMode ? FakeOtpService() : FirebaseOtpService();

  /// Sends (or re-sends) an SMS code to the signed-in employee.
  Future<OtpSendResult> sendCode();

  Future<OtpVerifyResult> verifyCode(String code);
}

/// Development only: no SMS is sent, no cost. Accepts [testCode].
class FakeOtpService implements OtpService {
  static const String testCode = '123456';

  @override
  Future<OtpSendResult> sendCode() async {
    await Future.delayed(const Duration(milliseconds: 600));
    debugPrint('FAKE OTP: use code $testCode');
    return OtpSendResult.sent;
  }

  @override
  Future<OtpVerifyResult> verifyCode(String code) async {
    await Future.delayed(const Duration(milliseconds: 400));
    return code == testCode
        ? OtpVerifyResult.success
        : OtpVerifyResult.wrongCode;
  }
}

/// TODO(otp-real): implement with Firebase SMS multi-factor on the day
/// Blaze is enabled. Until then it FAILS CLOSED: nobody gets through.
class FirebaseOtpService implements OtpService {
  @override
  Future<OtpSendResult> sendCode() async => OtpSendResult.failed;

  @override
  Future<OtpVerifyResult> verifyCode(String code) async =>
      OtpVerifyResult.failed;
}