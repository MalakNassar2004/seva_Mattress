import 'dart:async';

import 'package:get/get.dart';
import 'package:seva_mattress/data/repositories/approval_rules_repository.dart';
import 'package:seva_mattress/data/repositories/company_repository.dart';
import 'package:seva_mattress/data/repositories/notification_prefs_repository.dart';
import 'package:seva_mattress/data/services/notification_types.dart';
import 'package:seva_mattress/data/services/session_service.dart';
import '../../app/routes/app_routes.dart';
import '../../app/widgets/shared_widgets.dart';
import '../owner_shell/owner_nav.dart';
import 'notifications_sheet.dart';
import 'payment_methods_sheet.dart';
import 'security_sheet.dart';
import 'settings_store.dart';
import 'store_profile_sheet.dart';
import 'taxes_sheet.dart';

/// Settings main screen (owner). Opened from the More tab.
/// The store profile, the tax rates, the payment methods, the security
/// settings, the notifications and the approval rules are live from
/// Firestore (settings/...).
class SettingsController extends GetxController {
  final store = SettingsStore.to;

  final _company = CompanyRepository();
  final _prefs = NotificationPrefsRepository();
  final _rules = ApprovalRulesRepository();

  /// The store settings shown on the tiles.
  final company = CompanyInfo.defaults.obs;

  /// The notifications that are on (everything until the owner changes it).
  final notificationsOn = <String>{...NotificationTypes.allIds}.obs;

  StreamSubscription<CompanyInfo>? _sub;
  StreamSubscription<Set<String>>? _prefsSub;
  StreamSubscription<ApprovalRules>? _rulesSub;

  @override
  void onInit() {
    super.onInit();
    _sub = _company.watch().listen(
      (c) => company.value = c,
      // Not readable: the tiles keep showing the defaults.
      onError: (Object _) {},
    );
    _prefsSub = _prefs.watch().listen(
      (on) => notificationsOn.assignAll(on),
      onError: (Object _) {},
    );
    // The approval rules are shared with the Approval rules screen through
    // the store.
    _rulesSub = _rules.watch().listen(
      (r) => store.approvalRules.value = r,
      onError: (Object _) {},
    );
  }

  @override
  void onClose() {
    _sub?.cancel();
    _prefsSub?.cancel();
    _rulesSub?.cancel();
    super.onClose();
  }

  Future<bool> _isOwner() async {
    try {
      final user = await SessionService().loadCurrentUser();
      return user?.isOwner ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Owner check + fresh load, then the sheet. Shows a toast on failure.
  Future<void> _openOwnerSheet({
    required String what,
    required Future<bool?> Function(CompanyInfo current) open,
    required String savedMessage,
  }) async {
    if (!await _isOwner()) {
      showDarkToast(
        'Only the owner can change the $what',
        trailing: '',
        info: true,
      );
      return;
    }

    final CompanyInfo current;
    try {
      current = await _company.loadStrict();
    } catch (_) {
      showDarkToast('Could not load the $what', trailing: '', info: true);
      return;
    }

    final saved = await open(current);
    if (saved == true) showDarkToast(savedMessage);
  }

  // ---------------- Actions ----------------
   void onRunBackup() => showDarkToast(
        'Automatic backups start with the paid Firebase plan',
        trailing: '',
        info: true,
      );

  /// Receipts: the invoice text (thank you and terms) is part of the store
  /// profile.
  Future<void> onReceiptsPressed() => onStoreProfilePressed();

  Future<void> onStoreProfilePressed() => _openOwnerSheet(
        what: 'store profile',
        open: StoreProfileSheet.open,
        savedMessage: 'Store profile saved',
      );

  Future<void> onTaxesPressed() => _openOwnerSheet(
        what: 'tax rates',
        open: TaxesSheet.open,
        savedMessage: 'Tax rates saved',
      );

  Future<void> onPaymentMethodsPressed() => _openOwnerSheet(
        what: 'payment methods',
        open: PaymentMethodsSheet.open,
        savedMessage: 'Payment methods saved',
      );

  Future<void> onSecurityPressed() => _openOwnerSheet(
        what: 'security settings',
        open: SecuritySheet.open,
        savedMessage: 'Security settings saved',
      );

  /// Notifications: only the owner can change them.
  Future<void> onNotificationsPressed() async {
    if (!await _isOwner()) {
      showDarkToast(
        'Only the owner can change the notifications',
        trailing: '',
        info: true,
      );
      return;
    }

    final Set<String> current;
    try {
      current = await _prefs.loadStrict();
    } catch (_) {
      showDarkToast(
        'Could not load the notifications',
        trailing: '',
        info: true,
      );
      return;
    }

    final saved = await NotificationsSheet.open(current);
    if (saved == true) showDarkToast('Notifications saved');
  }

  // ---------------- Navigation ----------------
  void onApprovalRulesPressed() => Get.toNamed(AppRoutes.approvalRules);

  /// Sub-screens that are not designed yet.
  // TODO(design): Receipts sub-screen.
  void onNotDesigned(String name) =>
      showDarkToast('$name settings are coming soon', trailing: '', info: true);

  void onBackPressed() => Get.back();
  void onNavTap(int index) => OwnerNav.goToTab(index);
}