import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../app/config/feature_flags.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_colors_extra.dart';
import '../../app/widgets/app_widgets.dart';
import '../../app/widgets/owner_widgets.dart';
import '../../app/widgets/page_widgets.dart';
import '../../app/widgets/shared_widgets.dart';
import '../owner_shell/owner_shell_controller.dart';
import 'more_controller.dart';

/// More tab (owner menu). Lives in the owner shell, so it does not draw the
/// bottom navigation. Sections that are not connected yet are hidden (see
/// FeatureFlags).
class MoreView extends GetView<MoreController> {
  const MoreView({super.key});

  @override
  Widget build(BuildContext context) {
    final showBusiness = FeatureFlags.customers ||
        FeatureFlags.suppliers ||
        FeatureFlags.purchaseOrders ||
        FeatureFlags.deliveries;
    final showPeople = FeatureFlags.staff || FeatureFlags.permissions;
    final showControl = FeatureFlags.approvals ||
        FeatureFlags.exports ||
        FeatureFlags.auditLog ||
        FeatureFlags.settings;

    return Scaffold(
      body: SoftBackground(
        child: SafeArea(
          bottom: false,
          child: ListView(
            padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 20.h),
            children: [
              _buildTopBar(),
              SizedBox(height: 16.h),
              const PageTitle(
                title: 'More',
                subtitle: 'Store Operations, Administration & Control',
              ),
              SizedBox(height: 14.h),
              _buildProfileCard(),
              if (showBusiness) ...[
                SizedBox(height: 22.h),
                const SectionHeading('Business'),
                MenuGroup(
                  tiles: [
                    if (FeatureFlags.customers)
                      MenuTile(
                        icon: Icons.people_outline,
                        title: 'Customers',
                        subtitle: 'Accounts, warranty tracking & notes',
                        onTap: controller.onCustomers,
                      ),
                    if (FeatureFlags.suppliers)
                      MenuTile(
                        icon: Icons.inventory_2_outlined,
                        title: 'Suppliers',
                        subtitle: 'Vendors, terms & purchase ledger',
                        onTap: controller.onSuppliers,
                      ),
                    if (FeatureFlags.purchaseOrders)
                      MenuTile(
                        icon: Icons.receipt_long_outlined,
                        title: 'Purchase Orders',
                        subtitle: 'Open orders, incoming freight & receiving',
                        onTap: controller.onPurchaseOrders,
                      ),
                    if (FeatureFlags.deliveries)
                      MenuTile(
                        icon: Icons.local_shipping_outlined,
                        title: 'Deliveries',
                        subtitle: 'Dispatch, driver routes & proof of delivery',
                        onTap: controller.onDeliveries,
                      ),
                  ],
                ),
              ],
              if (showPeople) ...[
                SizedBox(height: 22.h),
                const SectionHeading('People'),
                _buildPeopleGroup(),
              ],
              if (showControl) ...[
                SizedBox(height: 22.h),
                const SectionHeading('Control'),
                _buildControlGroup(),
              ],
              SizedBox(height: 22.h),
              SizedBox(
                width: double.infinity,
                child: SoftButton(
                  label: 'Switch user',
                  icon: Icons.lock_outline,
                  height: 52,
                  radius: 16,
                  fontSize: 14.5,
                  onTap: controller.onSwitchUser,
                ),
              ),
              SizedBox(height: 6.h),
              Center(
                child: TextButton.icon(
                  onPressed: controller.onSignOut,
                  icon: Icon(
                    Icons.logout,
                    size: 18.sp,
                    color: AppColors.danger,
                  ),
                  label: Text(
                    'Sign out',
                    style: TextStyle(
                      fontSize: 14.5.sp,
                      fontWeight: FontWeight.w800,
                      color: AppColors.danger,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// People group. The Staff tile shows live counts, so it needs an Obx;
  /// without it an Obx would have nothing to watch and throw.
  Widget _buildPeopleGroup() {
    final permissionsTile = MenuTile(
      icon: Icons.admin_panel_settings_outlined,
      title: 'Permissions',
      subtitle: 'Access tiers, limits & sensitive actions',
      onTap: controller.onPermissions,
    );

    if (!FeatureFlags.staff) {
      return MenuGroup(tiles: [permissionsTile]);
    }
    return Obx(
      () => MenuGroup(
        tiles: [
          MenuTile(
            icon: Icons.badge_outlined,
            title: 'Staff',
            subtitle: '${controller.staffCount} team members, '
                '${controller.onShiftCount} on shift now',
            onTap: controller.onStaff,
          ),
          if (FeatureFlags.permissions) permissionsTile,
        ],
      ),
    );
  }

  /// Control group. Only the Approvals tile is reactive (pending badge).
  Widget _buildControlGroup() {
    final exportsTile = MenuTile(
      icon: Icons.download_outlined,
      title: 'Exports',
      subtitle: 'Sales, inventory & customer reports',
      onTap: controller.onExports,
    );
    final auditTile = MenuTile(
      icon: Icons.history,
      title: 'Audit Log',
      subtitle: 'Read-only history of sensitive actions',
      onTap: controller.onAuditLog,
    );
    final settingsTile = MenuTile(
      icon: Icons.settings_outlined,
      title: 'Settings',
      subtitle: 'Store profile, taxes, payments, approval rules',
      onTap: controller.onSettings,
    );

    if (!FeatureFlags.approvals) {
      return MenuGroup(
        tiles: [
          if (FeatureFlags.exports) exportsTile,
          if (FeatureFlags.auditLog) auditTile,
          if (FeatureFlags.settings) settingsTile,
        ],
      );
    }
    return Obx(
      () => MenuGroup(
        tiles: [
          MenuTile(
            icon: Icons.verified_user_outlined,
            title: 'Approvals',
            subtitle: 'Discounts, refunds & voids waiting for you',
            trailing: OwnerShellController.moreBadge == 0
                ? null
                : StatusPill(
                    text: '${OwnerShellController.moreBadge} pending',
                    fg: AppColors.white,
                    bg: AppColors.danger,
                    fontSize: 10.5,
                  ),
            onTap: controller.onApprovals,
          ),
          if (FeatureFlags.exports) exportsTile,
          if (FeatureFlags.auditLog) auditTile,
          if (FeatureFlags.settings) settingsTile,
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return Row(
      children: [
        const Flexible(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: BrandBadge(),
          ),
        ),
      ],
    );
  }

  Widget _buildProfileCard() {
    return Obx(
      () => SectionCard(
        child: Column(
          children: [
            Row(
              children: [
                InitialsAvatar(
                  initials: controller.initials,
                  size: 56,
                  bg: AppColors.deepBlue,
                  fg: AppColors.white,
                  dotColor: AppColors.success,
                ),
                SizedBox(width: 14.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              controller.displayName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 20.sp,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textDark,
                              ),
                            ),
                          ),
                          if (controller.roleLabel.isNotEmpty) ...[
                            SizedBox(width: 8.w),
                            StatusPill(
                              text: controller.roleLabel,
                              fg: AppColors.deepBlue,
                              bg: AppColors.lightBlue,
                              fontSize: 10,
                              letterSpacing: 0.5,
                            ),
                          ],
                        ],
                      ),
                      SizedBox(height: 3.h),
                      Text(
                        MoreController.storeName,
                        style: TextStyle(
                          fontSize: 13.sp,
                          color: AppColors.textDark.withValues(alpha: 0.75),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 12.h),
            const Divider(color: AppColorsExtra.panelBorder),
            SizedBox(height: 10.h),
            Row(
              children: [
                Icon(Icons.mail_outline, size: 15.sp, color: AppColors.grey),
                SizedBox(width: 6.w),
                Expanded(
                  child: Text(
                    controller.userEmail.value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: AppColors.textDark.withValues(alpha: 0.7),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}