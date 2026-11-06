import 'dart:async';

import 'package:get/get.dart';

import '../../app/routes/app_routes.dart';

/// UI state only. Backend wiring is marked with TODO(backend).
class PinController extends GetxController {
  static const int pinLength = 4;
  static const int resendSeconds = 60;

  final pin = ''.obs;
  final secondsLeft = resendSeconds.obs;

  Timer? _timer;

  @override
  void onInit() {
    super.onInit();
    _startTimer();
  }

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

  void onNumberPressed(String number) {
    if (pin.value.length >= pinLength) return;
    pin.value += number;
    if (pin.value.length == pinLength) {
      // TODO(backend): verify the PIN with pin.value first; only open the
      // Owner shell when it is valid.
      Get.offAllNamed(AppRoutes.owner);
    }
  }

  void onDeletePressed() {
    if (pin.value.isEmpty) return;
    pin.value = pin.value.substring(0, pin.value.length - 1);
  }

  void onChangeUserPressed() {
    // PIN is normally opened from Login, so going back returns there.
    if (Get.previousRoute == AppRoutes.login) {
      Get.back();
    } else {
      Get.offAllNamed(AppRoutes.login);
    }
  }

  void onRequestOtpPressed() {
    if (secondsLeft.value > 0) return;
    // TODO(backend): request a new OTP via SMS
    _startTimer();
  }

  @override
  void onClose() {
    _timer?.cancel();
    super.onClose();
  }
}