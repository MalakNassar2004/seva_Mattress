import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../app/theme/app_colors.dart';
import '../../app/widgets/app_widgets.dart';
import '../../app/widgets/owner_bottom_nav.dart';
import '../inventory/inventory_view.dart';
import '../orders/orders_view.dart';
import 'owner_shell_controller.dart';

/// Owner app shell: five tabs kept alive in an IndexedStack, with the
/// floating bottom navigation drawn once here.
class OwnerShellView extends GetView<OwnerShellController> {
  const OwnerShellView({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final index = controller.currentIndex.value;
      return PopScope(
        // Android back on another tab goes to Home first; on Home it exits.
        canPop: index == OwnerShellController.homeTab,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) controller.changeTab(OwnerShellController.homeTab);
        },
        child: Scaffold(
          body: SoftBackground(
            child: Column(
              children: [
                Expanded(
                  child: IndexedStack(
                    index: index,
                    children: [
                      const _PlaceholderTab(
                        name: 'Home',
                        icon: Icons.storefront_outlined,
                      ),
                      const OrdersView(),
                      const InventoryView(),
                      const _PlaceholderTab(
                        name: 'Reports',
                        icon: Icons.bar_chart_rounded,
                      ),
                      // TODO(design): replace with the real More menu.
                      _PlaceholderTab(
                        name: 'More',
                        icon: Icons.more_horiz,
                        actions: [
                          ('Customers', controller.onCustomersPressed),
                          ('Deliveries', controller.onDeliveriesPressed),
                          ('Suppliers', controller.onSuppliersPressed),
                          ('Staff', controller.onStaffPressed),
                          ('Purchase Orders', controller.onPurchaseOrdersPressed),
                        ],
                      ),
                    ],
                  ),
                ),
                OwnerBottomNav(
                  currentIndex: index,
                  moreBadge: OwnerShellController.moreBadge,
                  onTap: controller.changeTab,
                ),
              ],
            ),
          ),
        ),
      );
    });
  }
}

/// Temporary page for tabs whose screens are not built yet. An optional
/// button links to pages that are already built.
class _PlaceholderTab extends StatelessWidget {
  const _PlaceholderTab({
    required this.name,
    required this.icon,
    this.actions = const [],
  });

  final String name;
  final IconData icon;
  /// Links to pages that are already built: (label, onTap).
  final List<(String, VoidCallback)> actions;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SoftBackground(
        child: SafeArea(
          bottom: false,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 72.w,
                  height: 72.w,
                  decoration: const BoxDecoration(
                    color: AppColors.lightBlue,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: 32.sp, color: AppColors.primaryBlue),
                ),
                SizedBox(height: 16.h),
                Text(
                  '$name screen coming soon',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textDark,
                  ),
                ),
                if (actions.isNotEmpty) SizedBox(height: 12.h),
                for (final a in actions) ...[
                  TextButton(
                    onPressed: a.$2,
                    child: Text(
                      '${a.$1} ›',
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryBlue,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
