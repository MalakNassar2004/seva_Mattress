import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../app/config/feature_flags.dart';
import '../../app/widgets/app_widgets.dart';
import '../../app/widgets/coming_soon_view.dart';
import '../../app/widgets/owner_bottom_nav.dart';
import '../home/home_view.dart';
import '../inventory/inventory_view.dart';
import '../more/more_view.dart';
import '../orders/orders_view.dart';
import '../reports/reports_view.dart';
import 'owner_shell_controller.dart';

/// Owner app shell: five tabs kept alive in an IndexedStack, with the
/// floating bottom navigation drawn once here.
///
/// A tab whose section is not connected yet (see FeatureFlags) shows a
/// "coming soon" page, so the client never sees demo numbers.
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
                      FeatureFlags.home
                          ? const HomeView()
                          : const ComingSoonView(title: 'Home'),
                      FeatureFlags.orders
                          ? const OrdersView()
                          : const ComingSoonView(title: 'Orders'),
                      const InventoryView(),
                      FeatureFlags.reports
                          ? const ReportsView()
                          : const ComingSoonView(title: 'Reports'),
                      const MoreView(),
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