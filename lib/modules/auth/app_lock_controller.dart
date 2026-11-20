import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:seva_mattress/app/routes/app_routes.dart';
import 'package:seva_mattress/data/repositories/company_repository.dart';
import 'package:seva_mattress/data/services/app_lock_service.dart';
import 'package:seva_mattress/data/services/app_lock_settings.dart';
import 'package:seva_mattress/data/services/auth_service.dart';
import 'package:seva_mattress/data/services/reminder_service.dart';
import 'package:seva_mattress/modules/auth/lock_view.dart';

/// Locks the app with Face ID whenever it goes to the background
/// (phone locked, switched to another app) while a session is active.
/// If the phone comes back within the time the owner chose in Settings >
/// Security, the lock opens without asking for Face ID.
/// It also starts the payment and delivery reminders after sign-in, and
/// stops them on sign out.
class AppLockController extends GetxController with WidgetsBindingObserver {
  static const int maxFailedAttempts = 3;

  final _lockService = AppLockService();
  final _authService = AuthService();

  final message = 'Use Face ID to continue.'.obs;

  bool _active = false;
  bool _lockShown = false;
  bool _busy = false;
  int _failedAttempts = 0;
  DateTime? _pausedAt;

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
  void activate() {
    _active = true;
    // Reads the security settings chosen by the owner (it applies itself).
    CompanyRepository().load();
    // Payment and delivery reminders on this phone.
    ReminderService.to.start();
  }

  /// Call on logout.
  void deactivate() {
    _active = false;
    _lockShown = false;
    _failedAttempts = 0;
    _pausedAt = null;
    // Nothing is scheduled for a signed-out phone.
    ReminderService.to.stop();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_active) return;
    if (state == AppLifecycleState.paused) {
      _pausedAt = DateTime.now();
      _showLock();
    } else if (state == AppLifecycleState.resumed && _lockShown) {
      final since = _pausedAt;
      final grace = AppLockSettings.graceMinutes;
      final backSoon = grace > 0 &&
          since != null &&
          DateTime.now().difference(since) < Duration(minutes: grace);
      if (backSoon) {
        _dismissWithoutFaceId();
      } else {
        unlock();
      }
    }
  }

  void _showLock() {
    if (_lockShown) return;
    _lockShown = true;
    _failedAttempts = 0;
    message.value = 'Use Face ID to continue.';
    // The lock screen needs no binding: this controller is permanent.
    Get.to(
      () => const LockView(),
      transition: Transition.noTransition,
      popGesture: false,
    );
  }

  /// Back within the allowed time: close the lock screen, no Face ID.
  void _dismissWithoutFaceId() {
    if (_busy || !_lockShown) return;
    _failedAttempts = 0;
    _lockShown = false;
    _pausedAt = null;
    Get.back();
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
        _pausedAt = null;
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

  /// Signs out of Firebase and returns to the login screen. It uses the
  /// named route so the login binding registers the controller.
  Future<void> signOutAndExit() async {
    deactivate();
    await _authService.logout();
    Get.offAllNamed(AppRoutes.login);
  }
}