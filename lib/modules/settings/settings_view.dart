import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:seva_mattress/data/services/app_lock_settings.dart';
import 'package:seva_mattress/data/services/notification_types.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_colors_extra.dart';
import '../../app/widgets/app_widgets.dart';
import '../../app/widgets/owner_bottom_nav.dart';
import '../../app/widgets/owner_widgets.dart';
import '../../app/widgets/page_widgets.dart';
import '../../app/widgets/shared_widgets.dart';
import '../owner_shell/owner_shell_controller.dart';
import 'settings_controller.dart';

/// 500 -> "5%", 725 -> "7.25%".
String _pct(int bp) =>
    bp % 100 == 0 ? '${bp ~/ 100}%' : '${(bp / 100).toStringAsFixed(2)}%';

/// Settings main screen (owner). Opened from the More tab.
class SettingsView extends GetView<SettingsController> {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SoftBackground(
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 16.h),
                  children: [
                    _buildHeader(),
                    SizedBox(height: 14.h),
                    _buildBackupCard(),
                    SizedBox(height: 20.h),
                    const SectionHeading('Store'),
                    Obx(_buildStoreGroup),
                    SizedBox(height: 20.h),
                    const SectionHeading('Policies & Security'),
                    Obx(_buildPolicyGroup),
                    SizedBox(height: 16.h),
                    const AuditNote(
                      'All configuration changes are recorded in the audit '
                      'log',
                    ),
                  ],
                ),
              ),
              OwnerBottomNav(
                currentIndex: OwnerShellController.moreTab,
                moreBadge: OwnerShellController.moreBadge,
                onTap: controller.onNavTap,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------- Header ----------------
  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            BackPill(label: 'More', onTap: controller.onBackPressed),
            SizedBox(width: 8.w),
            const Spacer(),
          ],
        ),
        SizedBox(height: 14.h),
        const PageTitle(
          title: 'Settings',
          subtitle: 'Store settings, security and notifications',
        ),
      ],
    );
  }

  // ---------------- Backups ----------------
  Widget _buildBackupCard() {
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const IconBox(Icons.cloud_done_outlined),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Backups',
                      style: TextStyle(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textDark,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      'Your data is stored in the cloud (Firestore). '
                      'Automatic backups need the paid Firebase plan.',
                      style: TextStyle(
                        fontSize: 12.sp,
                        height: 1.35,
                        color: AppColors.textDark.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          const Divider(color: AppColorsExtra.panelBorder),
          SizedBox(height: 12.h),
          Row(
            children: [
              const Expanded(
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: StatusPill(
                    text: 'Automatic backup: not active yet',
                    icon: Icons.info_outline,
                    fg: AppColors.grey,
                    bg: AppColorsExtra.chipGrey,
                    fontSize: 11,
                  ),
                ),
              ),
              SizedBox(width: 8.w),
              SoftButton(
                label: 'Run backup now',
                icon: Icons.sync,
                height: 38,
                radius: 12,
                fontSize: 12.5,
                fg: AppColors.deepBlue,
                onTap: controller.onRunBackup,
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ---------------- Groups ----------------
  Widget _buildStoreGroup() {
    final c = controller.company.value;
    final profileLine = [c.name, c.address, c.phone]
        .where((s) => s.trim().isNotEmpty)
        .join(' · ');
    return MenuGroup(
      tiles: [
        MenuTile(
          icon: Icons.storefront_outlined,
          title: 'Store profile',
          subtitle: profileLine,
          onTap: controller.onStoreProfilePressed,
        ),
        MenuTile(
          icon: Icons.percent,
          title: 'Taxes',
          subtitle: 'GST ${_pct(c.gstBp)} + PST ${_pct(c.pstBp)}',
          badge: StatusPill(
            text: '${_pct(c.gstBp + c.pstBp)} total',
            fg: AppColorsExtra.amberText,
            bg: AppColorsExtra.amberSoft,
            border: AppColorsExtra.amberBorder,
            fontSize: 10,
          ),
          onTap: controller.onTaxesPressed,
        ),
        MenuTile(
          icon: Icons.credit_card,
          title: 'Payment methods',
          subtitle: c.paymentMethods.join(' · '),
          badge: StatusPill(
            text: '${c.paymentMethods.length} enabled',
            fg: AppColors.deepBlue,
            bg: AppColors.lightBlue,
            fontSize: 10,
          ),
          onTap: controller.onPaymentMethodsPressed,
        ),
        MenuTile(
          icon: Icons.receipt_outlined,
          title: 'Receipts',
          subtitle: 'Invoice PDF · email · thank-you and terms text',
          onTap: controller.onReceiptsPressed,
        ),
      ],
    );
  }

  Widget _buildPolicyGroup() {
    final rules = controller.store.approvalRules.value;
    final c = controller.company.value;
    final lock = c.lockMinutes == 0
        ? 'asks every time the app comes back'
        : 'asks after ${AppLockSettings.label(c.lockMinutes)} away';
    final onCount = controller.notificationsOn.length;
    final total = NotificationTypes.all.length;
    return MenuGroup(
      tiles: [
        MenuTile(
          icon: Icons.verified_user_outlined,
          title: 'Approval rules',
          subtitle:
              'Refunds above \$${rules.refundLimit.toStringAsFixed(0)}, '
              'cashier discount up to ${rules.maxCashierDiscount}%, price gates',
          badge: StatusPill(
            text: '${rules.activeCount} active',
            fg: AppColors.deepBlue,
            bg: AppColors.lightBlue,
            fontSize: 10,
          ),
          onTap: controller.onApprovalRulesPressed,
        ),
        MenuTile(
          icon: Icons.lock_outline,
          title: 'Security',
          subtitle: 'Face ID lock · $lock',
          onTap: controller.onSecurityPressed,
        ),
        MenuTile(
          icon: Icons.notifications_none,
          title: 'Notifications',
          subtitle: 'Payment & delivery reminders, order alerts',
          badge: StatusPill(
            text: '$onCount of $total on',
            fg: AppColors.deepBlue,
            bg: AppColors.lightBlue,
            fontSize: 10,
          ),
          onTap: controller.onNotificationsPressed,
        ),
      ],
    );
  }
}