import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_colors_extra.dart';
import '../../app/utils/dates.dart';
import '../../app/widgets/app_widgets.dart';
import '../../app/widgets/owner_bottom_nav.dart';
import '../../app/widgets/owner_widgets.dart';
import '../../app/widgets/page_widgets.dart';
import '../../app/widgets/shared_widgets.dart';
import '../owner_shell/owner_shell_controller.dart';
import 'settings_controller.dart';
import 'settings_store.dart';

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
                    Obx(_buildBackupCard),
                    SizedBox(height: 20.h),
                    const SectionHeading('Store'),
                    Obx(_buildStoreGroup),
                    SizedBox(height: 20.h),
                    const SectionHeading('Policies & Security'),
                    Obx(_buildPolicyGroup),
                    SizedBox(height: 16.h),
                    const AuditNote(
                      'All configuration changes are logged under Owner PIN '
                      '#OWN-001',
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
            const StatusPill(
              text: 'PCI-DSS L1',
              icon: Icons.lock,
              fg: AppColors.deepBlue,
              bg: AppColors.white,
              border: AppColors.border,
              fontSize: 11,
            ),
          ],
        ),
        SizedBox(height: 14.h),
        const PageTitle(
          title: 'Settings',
          subtitle: 'Store Operations & Terminal Governance · Surrey, BC',
        ),
      ],
    );
  }

  // ---------------- Backups ----------------
  Widget _buildBackupCard() {
    final s = controller.store;
    final busy = s.backingUp.value;
    final ok = s.lastBackupOk.value;
    final mins = DateTime.now().difference(s.lastBackup.value).inMinutes;
    final when = mins < 1
        ? 'just now'
        : mins < 60
        ? '${mins}m ago'
        : formatWhen(s.lastBackup.value);
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
                      'Automatic cloud ledger backup every hour',
                      style: TextStyle(
                        fontSize: 12.sp,
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
              Expanded(
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: StatusPill(
                    text: ok
                        ? 'Last backup: success · $when'
                        : 'Last backup failed · $when',
                    icon: ok ? Icons.check_circle : Icons.error_outline,
                    fg: ok ? AppColors.success : AppColors.danger,
                    bg: ok
                        ? AppColorsExtra.successSoft
                        : AppColorsExtra.dangerSoft,
                    border: ok
                        ? AppColorsExtra.successBorder
                        : AppColorsExtra.dangerBorder,
                    fontSize: 11,
                  ),
                ),
              ),
              SizedBox(width: 8.w),
              SoftButton(
                label: busy ? 'Backing up…' : 'Run backup now',
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
    final online = controller.store.terminalOnline.value;
    return MenuGroup(
      tiles: [
        MenuTile(
          icon: Icons.storefront_outlined,
          title: 'Store profile',
          subtitle:
              '${SettingsStore.storeName} · ${SettingsStore.storeAddress}'
              ' · ${SettingsStore.storePhone}',
          badge: const StatusPill(
            text: 'Logo set',
            fg: AppColors.grey,
            bg: AppColorsExtra.chipGrey,
            fontSize: 10,
          ),
          onTap: () => controller.onNotDesigned('Store profile'),
        ),
        MenuTile(
          icon: Icons.percent,
          title: 'Taxes',
          subtitle:
              'GST ${SettingsStore.gst.toStringAsFixed(0)}% + '
              'PST ${SettingsStore.pst.toStringAsFixed(0)}% (BC)',
          badge: StatusPill(
            text:
                '${(SettingsStore.gst + SettingsStore.pst).toStringAsFixed(0)}'
                '% total',
            fg: AppColorsExtra.amberText,
            bg: AppColorsExtra.amberSoft,
            border: AppColorsExtra.amberBorder,
            fontSize: 10,
          ),
          onTap: () => controller.onNotDesigned('Tax'),
        ),
        MenuTile(
          icon: Icons.credit_card,
          title: 'Payment methods',
          subtitle: 'Cash · Card terminal · Other (gift card, e-transfer)',
          badge: StatusPill(
            text: online ? 'Terminal online' : 'Terminal offline',
            dot: true,
            fg: online ? AppColors.success : AppColors.danger,
            bg: online ? AppColorsExtra.successSoft : AppColorsExtra.dangerSoft,
            border: online
                ? AppColorsExtra.successBorder
                : AppColorsExtra.dangerBorder,
            fontSize: 10,
          ),
          onTap: () => controller.onNotDesigned('Payment'),
        ),
        MenuTile(
          icon: Icons.receipt_outlined,
          title: 'Receipts',
          subtitle: 'Thermal 80mm print, email & SMS receipts, footer text',
          onTap: () => controller.onNotDesigned('Receipt'),
        ),
      ],
    );
  }

  Widget _buildPolicyGroup() {
    final rules = controller.store.approvalRules.value;
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
          subtitle:
              'Session timeout ${SettingsStore.autoLockMinutes} min · '
              'PIN required · Biometrics on',
          onTap: () => controller.onNotDesigned('Security'),
        ),
        MenuTile(
          icon: Icons.notifications_none,
          title: 'Notifications',
          subtitle:
              'Low-stock alert when stock ≤ '
              '${SettingsStore.lowStockThreshold} units',
          onTap: () => controller.onNotDesigned('Notification'),
        ),
      ],
    );
  }
}
