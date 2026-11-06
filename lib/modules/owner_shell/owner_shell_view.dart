import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../app/theme/app_colors.dart';
import '../../app/widgets/app_widgets.dart';
import '../../app/widgets/owner_bottom_nav.dart';
import '../products/products_view.dart';
import 'owner_shell_controller.dart';

/// Owner app shell: five tabs kept alive in an IndexedStack, with the
/// floating bottom navigation drawn once here.
class OwnerShellView extends GetView<OwnerShellController> {
  const OwnerShellView({super.key});

  @override
  Widget build(BuildContext context) {
    Get.put(OwnerShellController());

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
                    children: const [
                      _PlaceholderTab(
                        name: 'Home',
                        icon: Icons.storefront_outlined,
                      ),
                      _PlaceholderTab(
                        name: 'Orders',
                        icon: Icons.receipt_long_outlined,
                      ),
                      ProductsView(),
                      _PlaceholderTab(
                        name: 'Reports',
                        icon: Icons.bar_chart_rounded,
                      ),
                      _PlaceholderTab(
                        name: 'More',
                        icon: Icons.more_horiz,
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

/// Temporary page for tabs whose screens are not built yet.
class _PlaceholderTab extends StatelessWidget {
  const _PlaceholderTab({required this.name, required this.icon});

  final String name;
  final IconData icon;

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
              ],
            ),
          ),
        ),
      ),
    );
  }
}
