import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_colors_extra.dart';
import '../../app/theme/app_theme.dart';
import '../../app/utils/money.dart';
import '../../app/widgets/app_widgets.dart';
import '../../app/widgets/owner_widgets.dart';
import 'inventory_controller.dart';
import 'inventory_models.dart';

/// Inventory & Stock (owner). Lives in the Inventory tab of the owner shell,
/// so it does not draw the bottom navigation itself. Its controller is
/// registered by OwnerShellBinding.
class InventoryView extends GetView<InventoryController> {
  const InventoryView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SoftBackground(
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 16.h),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(),
                      SizedBox(height: 16.h),
                      _buildSummary(),
                      SizedBox(height: 16.h),
                      Obx(
                        () => SegmentedTabs(
                          labels: [
                            'Stock (${controller.liveProductCount.value})',
                            'Movements',
                            'Low Stock (${controller.lowTabCount})',
                          ],
                          selectedIndex: controller.tabIndex.value,
                          onChanged: controller.selectTab,
                        ),
                      ),
                      SizedBox(height: 14.h),
                      Obx(() {
                        final tab = controller.tabIndex.value;
                        if (tab == InventoryController.movementsTab) {
                          return _buildMovementsTab();
                        }
                        // Stock and Low Stock share the same list. The key
                        // gives every tab its own (empty) search box.
                        return KeyedSubtree(
                          key: ValueKey('stock-$tab'),
                          child: _buildStockTab(),
                        );
                      }),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 12.h),
                child: PrimaryArrowButton(
                  label: 'Adjust Stock',
                  leadingIcon: Icons.tune,
                  onPressed: controller.onAdjustStockPressed,
                ),
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
            WhitePill(
              onTap: controller.onBackPressed,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.chevron_left,
                      size: 22.sp, color: AppColors.primaryBlue),
                  SizedBox(width: 2.w),
                  Text(
                    'Inventory',
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w700,
                      color: AppColors.deepBlue,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: 10.w),
            Expanded(
              child: Align(
                alignment: Alignment.centerLeft,
                child: StatusPill(
                  text: 'Surrey Flagship · Owner View',
                  dot: true,
                  fg: AppColors.deepBlue,
                  bg: AppColors.lightBlue,
                  border: AppColorsExtra.infoBorder,
                  fontSize: 11,
                ),
              ),
            ),
            CircleIconButton(
              icon: Icons.ios_share,
              onTap: controller.onSharePressed,
            ),
          ],
        ),
        SizedBox(height: 16.h),
        Row(
          children: [
            Expanded(
              child: Text(
                'Inventory & Stock',
                style: TextStyle(
                  fontSize: 26.sp,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textDark,
                ),
              ),
            ),
            // TODO(design): temporary link to the Products catalogue.
            GestureDetector(
              onTap: controller.onProductsPressed,
              child: Text(
                'Products ›',
                style: TextStyle(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryBlue,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 2.h),
        Text(
          'Surrey Warehouse & Showroom Floor',
          style: TextStyle(fontSize: 12.sp, color: AppColors.grey),
        ),
      ],
    );
  }

  // ---------------- Summary card ----------------
  Widget _buildSummary() {
    return AppCard(
      radius: 24,
      padding: EdgeInsets.all(16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total Inventory\nValue',
                      style: TextStyle(
                        fontSize: 13.sp,
                        height: 1.3,
                        fontWeight: FontWeight.w600,
                        color: AppColors.grey,
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Padding(
                      padding: EdgeInsets.only(top: 2.h),
                      child: Obx(
                        () => GestureDetector(
                          onTap: controller.toggleAmounts,
                          child: Icon(
                            controller.hideAmounts.value
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            size: 18.sp,
                            color: AppColors.greyLight,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 8.w),
              Flexible(
                child: Container(
                  padding:
                      EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
                  decoration: BoxDecoration(
                    color: AppColorsExtra.segmentBg,
                    borderRadius: BorderRadius.circular(14.r),
                    border: Border.all(color: AppColorsExtra.panelBorder),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.lock, size: 12.sp, color: AppColors.deepBlue),
                      SizedBox(width: 5.w),
                      Flexible(
                        child: Text(
                          'COST BASIS · OWNER ONLY',
                          style: TextStyle(
                            fontSize: 9.5.sp,
                            height: 1.25,
                            letterSpacing: 0.4,
                            fontWeight: FontWeight.w800,
                            color: AppColors.deepBlue,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Flexible(
                child: Obx(() {
                  // Only the owner sees the value (it is based on costs).
                  final String text = !controller.canViewCost.value
                      ? '—'
                      : controller.hideAmounts.value
                          ? '•••••••'
                          : formatCad(controller.liveTotalValue.value);
                  return FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      text,
                      style: TextStyle(
                        fontSize: 30.sp,
                        fontWeight: FontWeight.w800,
                        color: AppColors.deepBlue,
                      ),
                    ),
                  );
                }),
              ),
              SizedBox(width: 6.w),
              Text(
                'CAD',
                style: TextStyle(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w600,
                  color: AppColors.grey,
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          const Divider(),
          SizedBox(height: 12.h),
          Obx(
            () => Row(
              children: [
                Expanded(
                  child: _StatTile(
                    value: '${controller.liveActiveUnits.value}',
                    label: 'Active units',
                    bg: AppColorsExtra.panelGrey,
                    border: AppColorsExtra.panelBorder,
                    valueColor: AppColors.textDark,
                    labelColor: AppColors.grey,
                  ),
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: _StatTile(
                    value: '${controller.liveLowStock.value}',
                    label: 'Low Stock',
                    bg: AppColors.warningBg,
                    border: AppColorsExtra.warningBorder,
                    valueColor: AppColors.warning,
                    labelColor: AppColorsExtra.amber,
                  ),
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: _StatTile(
                    value: '${controller.liveOutOfStock.value}',
                    label: 'Out of Stock',
                    bg: AppColors.dangerBg,
                    border: AppColorsExtra.dangerBorder,
                    valueColor: AppColors.danger,
                    labelColor: AppColors.danger,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------- Stock tab (also used by Low Stock) ----------------
  Widget _buildStockTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        OwnerSearchField(
          hint: 'Search SKU, model, serial...',
          onChanged: controller.onSearchChanged,
          onScan: controller.onScanPressed,
        ),
        SizedBox(height: 12.h),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Obx(
            () => Row(
              children: List.generate(InventoryController.categories.length, (i) {
                final selected = controller.categoryIndex.value == i;
                return Padding(
                  padding: EdgeInsets.only(right: 8.w),
                  child: GestureDetector(
                    onTap: () => controller.selectCategory(i),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: EdgeInsets.symmetric(
                          horizontal: 16.w, vertical: 9.h),
                      decoration: BoxDecoration(
                        color:
                            selected ? AppColors.textDark : AppColors.white,
                        borderRadius: BorderRadius.circular(20.r),
                        border: Border.all(
                          color:
                              selected ? AppColors.textDark : AppColors.border,
                        ),
                      ),
                      child: Text(
                        InventoryController.categories[i],
                        style: TextStyle(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w700,
                          color:
                              selected ? AppColors.white : AppColors.textDark,
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
        SizedBox(height: 14.h),
        Obx(() {
          if (controller.items.isEmpty) return _buildEmptyStock();
          return Column(
            children: controller.items
                .map(
                  (it) => Padding(
                    padding: EdgeInsets.only(bottom: 12.h),
                    child: _buildStockCard(it),
                  ),
                )
                .toList(),
          );
        }),
      ],
    );
  }

  /// Shown when the list is empty. Called inside an Obx, so the observables
  /// read here are tracked.
  Widget _buildEmptyStock() {
    if (controller.isLoading.value) {
      return Padding(
        padding: EdgeInsets.symmetric(vertical: 40.h),
        child: const Center(child: CircularProgressIndicator()),
      );
    }
    final String message;
    if (controller.loadError.value != null) {
      message = 'Could not load the stock. Check your connection.';
    } else if (controller.liveProductCount.value == 0) {
      message = 'No products yet. Add products from the Products page.';
    } else if (controller.tabIndex.value == InventoryController.lowTab) {
      message = 'Nothing is running low on stock.';
    } else {
      message = 'No products match your search.';
    }
    return _InfoCard(
      icon: Icons.inventory_2_outlined,
      title: 'No items',
      message: message,
    );
  }

  Widget _buildStockCard(StockItem it) {
    final level = it.level;
    final Color fg = level == StockLevel.ok
        ? AppColors.success
        : level == StockLevel.low
            ? AppColors.warning
            : AppColors.danger;
    final Color pillBg = level == StockLevel.ok
        ? AppColors.successBg
        : level == StockLevel.low
            ? AppColors.warningBg
            : AppColors.dangerBg;
    final Color? border = level == StockLevel.low
        ? AppColorsExtra.warningBorder
        : level == StockLevel.out
            ? AppColorsExtra.dangerBorder
            : null;

    // Cost and value are owner-only, and only when a cost was saved.
    final showCost = controller.canViewCost.value && it.cost > 0;
    final costText = showCost ? formatCad(it.cost, decimals: 0) : '—';
    final valueText = showCost ? '${formatCad(it.value, decimals: 0)} CAD' : '—';

    return GestureDetector(
      onTap: () => controller.onItemTap(it),
      child: Container(
        padding: EdgeInsets.all(14.w),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(20.r),
          border: border == null ? null : Border.all(color: border, width: 1.2),
          boxShadow: AppShadows.soft,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    it.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textDark,
                    ),
                  ),
                ),
                SizedBox(width: 8.w),
                StatusPill(
                  text: '${it.units} units',
                  dot: true,
                  fg: fg,
                  bg: pillBg,
                  border: level == StockLevel.ok
                      ? AppColorsExtra.successBorder
                      : border,
                ),
              ],
            ),
            SizedBox(height: 3.h),
            Text(
              'SKU: ${it.sku}',
              style: TextStyle(
                fontSize: 11.sp,
                fontFamily: 'monospace',
                color: AppColors.grey,
              ),
            ),
            SizedBox(height: 10.h),
            if (level == StockLevel.out)
              Container(
                width: double.infinity,
                padding:
                    EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
                decoration: BoxDecoration(
                  color: AppColorsExtra.dangerSoft,
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(color: AppColorsExtra.dangerBorder),
                ),
                child: Row(
                  children: [
                    Icon(Icons.local_shipping_outlined,
                        size: 16.sp, color: AppColors.danger),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: Text(
                        it.reorderStatus ??
                            'Out of stock · no reorder placed yet',
                        style: TextStyle(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w700,
                          color: AppColors.danger,
                        ),
                      ),
                    ),
                  ],
                ),
              )
            else ...[
              _buildLocationBox(it),
              SizedBox(height: 10.h),
              Row(
                children: [
                  Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: 'Cost: ',
                          style: TextStyle(
                              fontSize: 12.sp, color: AppColors.grey),
                        ),
                        TextSpan(
                          text: costText,
                          style: TextStyle(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textDark,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  if (level == StockLevel.low && it.threshold != null)
                    Container(
                      padding: EdgeInsets.symmetric(
                          horizontal: 10.w, vertical: 5.h),
                      decoration: BoxDecoration(
                        color: AppColors.warningBg,
                        borderRadius: BorderRadius.circular(8.r),
                        border:
                            Border.all(color: AppColorsExtra.warningBorder),
                      ),
                      child: Text(
                        'Reorder threshold: ${it.threshold}',
                        style: TextStyle(
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w800,
                          color: AppColorsExtra.amber,
                        ),
                      ),
                    )
                  else
                    Text(
                      'Value: $valueText',
                      style: TextStyle(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primaryBlue,
                      ),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLocationBox(StockItem it) {
    final low = it.level == StockLevel.low;
    final textColor = low ? AppColorsExtra.amber : AppColors.grey;
    final valueColor = low ? AppColorsExtra.amber : AppColors.textDark;

    Widget part(IconData icon, String label, String value, String? note) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (it.showLocationIcons) ...[
            Icon(icon, size: 15.sp, color: AppColors.grey),
            SizedBox(width: 5.w),
          ],
          Flexible(
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: '$label: ',
                    style: TextStyle(fontSize: 11.5.sp, color: textColor),
                  ),
                  TextSpan(
                    text: note == null ? value : '$value $note',
                    style: TextStyle(
                      fontSize: 11.5.sp,
                      fontWeight: FontWeight.w800,
                      color: valueColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 9.h),
      decoration: BoxDecoration(
        color: low ? AppColorsExtra.warningSoft : AppColorsExtra.panelGrey,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: low ? AppColorsExtra.warningBorder : AppColorsExtra.panelBorder,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: part(Icons.warehouse_outlined, 'Surrey Warehouse',
                  '${it.warehouse}', null),
            ),
          ),
          Container(
            width: 1,
            height: 18.h,
            margin: EdgeInsets.symmetric(horizontal: 6.w),
            color: low ? AppColorsExtra.warningBorder : AppColors.border,
          ),
          Expanded(
            child: Align(
              alignment: Alignment.centerRight,
              child: part(Icons.storefront_outlined, 'Showroom',
                  '${it.showroom}', it.showroomNote),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------- Movements tab ----------------
  Widget _buildMovementsTab() {
    return Obx(() {
      if (!controller.canViewCost.value) {
        return const _InfoCard(
          icon: Icons.lock_outline,
          title: 'Owner only',
          message: 'Only the owner can see the movement history.',
        );
      }
      if (controller.movementsError.value != null) {
        return const _InfoCard(
          icon: Icons.error_outline,
          title: 'Could not load',
          message: 'Could not load the movements. Check your connection.',
        );
      }
      final list = controller.movements;
      if (list.isEmpty) {
        return const _InfoCard(
          icon: Icons.swap_vert,
          title: 'No movements yet',
          message: 'Every change of stock will appear here.',
        );
      }
      return Column(
        children: list
            .map(
              (m) => Padding(
                padding: EdgeInsets.only(bottom: 12.h),
                child: _MovementCard(movement: m),
              ),
            )
            .toList(),
      );
    });
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.value,
    required this.label,
    required this.bg,
    required this.border,
    required this.valueColor,
    required this.labelColor,
  });

  final String value;
  final String label;
  final Color bg;
  final Color border;
  final Color valueColor;
  final Color labelColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 10.h),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: border),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 22.sp,
              fontWeight: FontWeight.w800,
              color: valueColor,
            ),
          ),
          SizedBox(height: 1.h),
          Text(
            label,
            style: TextStyle(
              fontSize: 11.sp,
              fontWeight: FontWeight.w500,
              color: labelColor,
            ),
          ),
        ],
      ),
    );
  }
}

/// One stock movement (a row of the audit log).
class _MovementCard extends StatelessWidget {
  const _MovementCard({required this.movement});

  final StockMovement movement;

  static const List<String> _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  String _when(DateTime t) {
    final local = t.toLocal();
    final hour = local.hour % 12 == 0 ? 12 : local.hour % 12;
    final minute = local.minute.toString().padLeft(2, '0');
    final period = local.hour < 12 ? 'AM' : 'PM';
    return '${_months[local.month - 1]} ${local.day} · $hour:$minute $period';
  }

  @override
  Widget build(BuildContext context) {
    final m = movement;
    final d = m.delta;
    final Color fg = d > 0
        ? AppColors.success
        : d < 0
            ? AppColors.danger
            : AppColors.grey;
    final Color bg = d > 0
        ? AppColors.successBg
        : d < 0
            ? AppColors.dangerBg
            : AppColorsExtra.panelGrey;
    final deltaText = d > 0 ? '+$d' : '$d';

    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: AppShadows.soft,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  m.productName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textDark,
                  ),
                ),
              ),
              SizedBox(width: 8.w),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: BorderRadius.circular(20.r),
                ),
                child: Text(
                  deltaText,
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w800,
                    color: fg,
                  ),
                ),
              ),
            ],
          ),
          if (m.sku.isNotEmpty) ...[
            SizedBox(height: 3.h),
            Text(
              'SKU: ${m.sku}',
              style: TextStyle(
                fontSize: 11.sp,
                fontFamily: 'monospace',
                color: AppColors.grey,
              ),
            ),
          ],
          SizedBox(height: 8.h),
          Text(
            '${m.locationLabel} · ${m.reason}',
            style: TextStyle(
              fontSize: 12.sp,
              fontWeight: FontWeight.w600,
              color: AppColors.textDark,
            ),
          ),
          SizedBox(height: 2.h),
          Text(
            '${m.from} → ${m.to} units',
            style: TextStyle(
              fontSize: 12.sp,
              fontWeight: FontWeight.w800,
              color: AppColors.primaryBlue,
            ),
          ),
          if (m.note.isNotEmpty) ...[
            SizedBox(height: 4.h),
            Text(
              'Note: ${m.note}',
              style: TextStyle(fontSize: 11.sp, color: AppColors.grey),
            ),
          ],
          SizedBox(height: 8.h),
          const Divider(),
          SizedBox(height: 6.h),
          Row(
            children: [
              Icon(Icons.person_outline, size: 14.sp, color: AppColors.grey),
              SizedBox(width: 4.w),
              Expanded(
                child: Text(
                  m.actor.isEmpty ? 'Unknown' : m.actor,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 11.sp, color: AppColors.grey),
                ),
              ),
              Text(
                _when(m.at),
                style: TextStyle(fontSize: 11.sp, color: AppColors.grey),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Message card for empty / unavailable states.
class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 24.h),
        child: Column(
          children: [
            Container(
              width: 56.w,
              height: 56.w,
              decoration: const BoxDecoration(
                color: AppColors.lightBlue,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 26.sp, color: AppColors.primaryBlue),
            ),
            SizedBox(height: 12.h),
            Text(
              title,
              style: TextStyle(
                fontSize: 15.sp,
                fontWeight: FontWeight.w800,
                color: AppColors.textDark,
              ),
            ),
            SizedBox(height: 4.h),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12.sp, color: AppColors.grey),
              ),
            ),
          ],
        ),
      ),
    );
  }
}