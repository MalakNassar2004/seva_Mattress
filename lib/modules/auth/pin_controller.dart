import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:seva_mattress/data/services/otp_service.dart';
import 'package:seva_mattress/data/services/session_service.dart';
import 'package:seva_mattress/modules/auth/app_lock_controller.dart';
import '../../app/routes/app_routes.dart';

/// OTP screen logic. SMS sending/verification goes through OtpService.
/// After the code is verified, the employee is sent to the screen that
/// matches his role.
class PinController extends GetxController {
  static const int pinLength = 6;
  static const int resendSeconds = 60;
  static const int maxWrongAttempts = 5;

  final _otp = OtpService();

  // ---------------- State ----------------
  final pin = ''.obs;
  final secondsLeft = resendSeconds.obs;
  final isBusy = false.obs;

  Timer? _timer;
  int _wrongAttempts = 0;

  @override
  void onInit() {
    super.onInit();
    // No Face ID lock while the user is on the code screen: they may need
    // to leave the app to read the SMS.
    Get.find<AppLockController>().deactivate();
    _startTimer();
    _sendCode();
  }

  @override
  void onClose() {
    _timer?.cancel();
    super.onClose();
  }

  // Resend countdown.
  String get timerText {
    final m = (secondsLeft.value ~/ 60).toString().padLeft(2, '0');
    final s = (secondsLeft.value % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  void _startTimer() {
    _timer?.cancel();
    secondsLeft.value = resendSeconds;
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (secondsLeft.value > 0) {
        secondsLeft.value--;
      } else {
        t.cancel();
      }
    });
  }

  Future<void> _sendCode() async {
    final result = await _otp.sendCode();
    if (result == OtpSendResult.failed) {
      _showMessage(
        'Code not sent',
        'Could not send the SMS code. Please try again.',
      );
    } else if (kDebugMode) {
      _showMessage('Test mode', 'Use code ${FakeOtpService.testCode}');
    }
  }

  // ---------------- Actions ----------------
  void onNumberPressed(String number) {
    if (isBusy.value || pin.value.length >= pinLength) return;
    pin.value += number;
    if (pin.value.length == pinLength) _verify();
  }

  void onDeletePressed() {
    if (isBusy.value || pin.value.isEmpty) return;
    pin.value = pin.value.substring(0, pin.value.length - 1);
  }

  Future<void> onRequestOtpPressed() async {
    if (secondsLeft.value > 0 || isBusy.value) return;
    pin.value = '';
    _startTimer();
    await _sendCode();
  }

  Future<void> _verify() async {
    isBusy.value = true;
    final result = await _otp.verifyCode(pin.value);

    if (result == OtpVerifyResult.success) {
      // Stay busy so no more input is accepted.
      await _onVerified();
      return;
    }

    isBusy.value = false;
    pin.value = '';

    switch (result) {
      case OtpVerifyResult.wrongCode:
        _wrongAttempts++;
        if (_wrongAttempts >= maxWrongAttempts) {
          await Get.find<AppLockController>().signOutAndExit();
          _showMessage(
            'Signed out',
            'Too many wrong codes. Please sign in again.',
          );
        } else {
          _showMessage('Wrong code', 'The code is incorrect. Please try again.');
        }
        break;
      case OtpVerifyResult.expired:
        _showMessage('Code expired', 'Please request a new code.');
        break;
      case OtpVerifyResult.failed:
      case OtpVerifyResult.success:
        _showMessage(
          'Verification failed',
          'Something went wrong. Please try again.',
        );
        break;
    }
  }

  /// The code is correct: find out who the employee is and open the screen
  /// that matches his role.
  Future<void> _onVerified() async {
    _timer?.cancel();

    final lock = Get.find<AppLockController>();

    AppUser? user;
    try {
      user = await SessionService().loadCurrentUser();
    } catch (_) {
      // Could not read the employee profile (usually no connection).
      isBusy.value = false;
      pin.value = '';
      _startTimer();
      _showMessage(
        'Connection problem',
        'Could not load your account. Please try again.',
      );
      return;
    }

    if (user == null || !user.active) {
      await lock.signOutAndExit();
      _showMessage(
        'No access',
        'This account is not an active employee account. Contact your manager.',
      );
      return;
    }

    switch (user.role) {
      case 'owner':
      case 'manager':
        // The Face ID lock starts only now, after the SMS code is verified.
        lock.activate();
        // TODO(roles): the manager gets his own limited screens later. For
        // now he opens the Owner shell and the Firestore rules limit him.
        Get.offAllNamed(AppRoutes.owner);
        break;
      default:
        // warehouse / cashier / delivery screens are not built yet.
        await lock.signOutAndExit();
        _showMessage(
          'Not available yet',
          'The screens for your role (${user.role}) are not ready yet.',
        );
    }
  }

  // ---------------- Navigation ----------------
  /// "Change User": sign out and go back to the login screen.
  Future<void> onChangeUserPressed() =>
      Get.find<AppLockController>().signOutAndExit();

  void _showMessage(String title, String message) {
    Get.snackbar(
      title,
      message,
      snackPosition: SnackPosition.TOP,
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
    );
  }
}