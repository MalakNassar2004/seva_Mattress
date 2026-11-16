import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../app/widgets/app_widgets.dart';
import '../../app/widgets/owner_bottom_nav.dart';
import '../home/home_view.dart';
import '../inventory/inventory_view.dart';
import '../more/more_view.dart';
import '../orders/orders_view.dart';
import '../reports/reports_view.dart';
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
                    children: const [
                      HomeView(),
                      OrdersView(),
                      InventoryView(),
                      ReportsView(),
                      MoreView(),
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
