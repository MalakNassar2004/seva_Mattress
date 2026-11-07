import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:seva_mattress/data/services/app_lock_service.dart';
import 'package:seva_mattress/data/services/auth_service.dart';
import 'package:seva_mattress/modules/auth/lock_view.dart';
import 'package:seva_mattress/modules/auth/login_view.dart';

/// Locks the app with Face ID whenever it goes to the background
/// (phone locked, switched to another app) while a session is active.
class AppLockController extends GetxController with WidgetsBindingObserver {
  static const int maxFailedAttempts = 3;

  final _lockService = AppLockService();
  final _authService = AuthService();

  final message = 'Use Face ID to continue.'.obs;

  bool _active = false;
  bool _lockShown = false;
  bool _busy = false;
  int _failedAttempts = 0;

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    super.onClose();
  }

  /// Call when the user is fully signed in (after the SMS code).
  void activate() => _active = true;

  /// Call on logout.
  void deactivate() {
    _active = false;
    _lockShown = false;
    _failedAttempts = 0;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_active) return;
    if (state == AppLifecycleState.paused) {
      _showLock();
    } else if (state == AppLifecycleState.resumed && _lockShown) {
      unlock();
    }
  }

  void _showLock() {
    if (_lockShown) return;
    _lockShown = true;
    _failedAttempts = 0;
    message.value = 'Use Face ID to continue.';
    Get.to(
      () => const LockView(),
      transition: Transition.noTransition,
      popGesture: false,
    );
  }

  Future<void> unlock() async {
    if (_busy || !_lockShown) return;
    _busy = true;
    final result = await _lockService.authenticate();
    _busy = false;

    switch (result) {
      case UnlockResult.success:
        _failedAttempts = 0;
        _lockShown = false;
        Get.back();
        break;
      case UnlockResult.failed:
        _failedAttempts++;
        if (_failedAttempts >= maxFailedAttempts) {
          await signOutAndExit();
        } else {
          message.value = 'Face ID did not match. Please try again.';
        }
        break;
      case UnlockResult.canceled:
        message.value = 'Tap the button to unlock with Face ID.';
        break;
      case UnlockResult.lockedOut:
      case UnlockResult.unavailable:
        await signOutAndExit();
        break;
    }
  }

  /// Signs out of Firebase and returns to the login screen.
  Future<void> signOutAndExit() async {
    deactivate();
    await _authService.logout();
    Get.offAll(() => const LoginView());
  }
}