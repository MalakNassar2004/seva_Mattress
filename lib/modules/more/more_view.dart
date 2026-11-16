import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_colors_extra.dart';
import '../../app/widgets/app_widgets.dart';
import '../../app/widgets/owner_widgets.dart';
import '../../app/widgets/page_widgets.dart';
import '../../app/widgets/shared_widgets.dart';
import '../owner_shell/owner_shell_controller.dart';
import 'more_controller.dart';

/// More tab (owner menu). Lives in the owner shell, so it does not draw the
/// bottom navigation.
class MoreView extends GetView<MoreController> {
  const MoreView({super.key});

  @override
  Widget build(BuildContext context) {
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
              SizedBox(height: 22.h),
              const SectionHeading('Business'),
              MenuGroup(
                tiles: [
                  MenuTile(
                    icon: Icons.people_outline,
                    title: 'Customers',
                    subtitle: 'Accounts, warranty tracking & notes',
                    onTap: controller.onCustomers,
                  ),
                  MenuTile(
                    icon: Icons.inventory_2_outlined,
                    title: 'Suppliers',
                    subtitle: 'Vendors, terms & purchase ledger',
                    onTap: controller.onSuppliers,
                  ),
                  MenuTile(
                    icon: Icons.receipt_long_outlined,
                    title: 'Purchase Orders',
                    subtitle: 'Open orders, incoming freight & receiving',
                    onTap: controller.onPurchaseOrders,
                  ),
                  MenuTile(
                    icon: Icons.local_shipping_outlined,
                    title: 'Deliveries',
                    subtitle: 'Dispatch, driver routes & proof of delivery',
                    onTap: controller.onDeliveries,
                  ),
                ],
              ),
              SizedBox(height: 22.h),
              const SectionHeading('People'),
              Obx(
                () => MenuGroup(
                  tiles: [
                    MenuTile(
                      icon: Icons.badge_outlined,
                      title: 'Staff',
                      subtitle:
                          '${controller.staffCount} team members, '
                          '${controller.onShiftCount} on shift now',
                      onTap: controller.onStaff,
                    ),
                    MenuTile(
                      icon: Icons.admin_panel_settings_outlined,
                      title: 'Permissions',
                      subtitle: 'Access tiers, limits & sensitive actions',
                      onTap: controller.onPermissions,
                    ),
                  ],
                ),
              ),
              SizedBox(height: 22.h),
              const SectionHeading('Control'),
              MenuGroup(
                tiles: [
                  MenuTile(
                    icon: Icons.verified_user_outlined,
                    title: 'Approvals',
                    subtitle: 'Discounts, refunds & voids waiting for you',
                    trailing: const StatusPill(
                      text: '${OwnerShellController.moreBadge} pending',
                      fg: AppColors.white,
                      bg: AppColors.danger,
                      fontSize: 10.5,
                    ),
                    onTap: controller.onApprovals,
                  ),
                  MenuTile(
                    icon: Icons.download_outlined,
                    title: 'Exports',
                    subtitle: 'Sales, inventory & customer reports',
                    onTap: controller.onExports,
                  ),
                  MenuTile(
                    icon: Icons.history,
                    title: 'Audit Log',
                    subtitle: 'Read-only history of sensitive actions',
                    onTap: controller.onAuditLog,
                  ),
                  MenuTile(
                    icon: Icons.settings_outlined,
                    title: 'Settings',
                    subtitle: 'Store profile, taxes, payments, approval rules',
                    onTap: controller.onSettings,
                  ),
                ],
              ),
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
    );
  }

  Widget _buildProfileCard() {
    return SectionCard(
      child: Column(
        children: [
          Row(
            children: [
              const InitialsAvatar(
                initials: MoreController.ownerInitials,
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
                        Text(
                          'Owner',
                          style: TextStyle(
                            fontSize: 20.sp,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textDark,
                          ),
                        ),
                        SizedBox(width: 8.w),
                        const StatusPill(
                          text: 'OWNER',
                          fg: AppColors.deepBlue,
                          bg: AppColors.lightBlue,
                          fontSize: 10,
                          letterSpacing: 0.5,
                        ),
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
              Icon(Icons.place_outlined, size: 15.sp, color: AppColors.grey),
              SizedBox(width: 6.w),
              Expanded(
                child: Text(
                  MoreController.storeAddress,
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: AppColors.textDark.withValues(alpha: 0.7),
                  ),
                ),
              ),
              Text(
                'PIN ${MoreController.ownerPin}',
                style: TextStyle(
                  fontSize: 11.5.sp,
                  fontWeight: FontWeight.w600,
                  color: AppColors.grey,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
