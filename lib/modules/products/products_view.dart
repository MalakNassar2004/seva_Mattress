import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_theme.dart';
import '../../app/widgets/app_widgets.dart';
import 'product_item.dart';
import 'products_controller.dart';

/// Inventory tab of the Owner shell. The bottom navigation is drawn by the
/// shell (OwnerShellView), not here.
class ProductsView extends GetView<ProductsController> {
  const ProductsView({super.key});

  @override
  Widget build(BuildContext context) {
    Get.put(ProductsController());

    return Scaffold(
      body: SoftBackground(
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              Expanded(
                child: CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(child: _buildHeader()),
                    Obx(() {
                      final items = controller.products;
                      if (items.isEmpty) {
                        return SliverToBoxAdapter(child: _buildEmpty());
                      }
                      return SliverPadding(
                        padding: EdgeInsets.symmetric(horizontal: 16.w),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, i) => Padding(
                              padding: EdgeInsets.only(bottom: 12.h),
                              child: _SwipeCard(
                                key: ValueKey(items[i].sku),
                                onEdit: () => controller.onEditProduct(items[i]),
                                onDelete: () => _showDeleteSheet(items[i]),
                                child: _buildCard(items[i]),
                              ),
                            ),
                            childCount: items.length,
                          ),
                        ),
                      );
                    }),
                    SliverToBoxAdapter(child: _buildSwipeHint()),
                  ],
                ),
              ),
              _buildAddButton(),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------- Header ----------------
  Widget _buildHeader() {
    return Padding(
      padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 0),
      child: Column(
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
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
                decoration: BoxDecoration(
                  color: const Color(0xFFE3E9F3),
                  borderRadius: BorderRadius.circular(20.r),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.lock, size: 11.sp, color: AppColors.deepBlue),
                    SizedBox(width: 5.w),
                    Text(
                      'SEVA SLEEP POS',
                      style: TextStyle(
                        fontSize: 10.sp,
                        letterSpacing: 0.6,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF4B5B75),
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: controller.onFilterPressed,
                child: Container(
                  width: 40.w,
                  height: 40.w,
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    shape: BoxShape.circle,
                    boxShadow: AppShadows.small,
                  ),
                  child: Icon(Icons.tune,
                      size: 20.sp, color: AppColors.primaryBlue),
                ),
              ),
            ],
          ),
          SizedBox(height: 18.h),
          Row(
            children: [
              Text(
                'Products',
                style: TextStyle(
                  fontSize: 28.sp,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textDark,
                ),
              ),
              const Spacer(),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: AppColors.lightBlue,
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Text(
                  'CAD',
                  style: TextStyle(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w800,
                    color: AppColors.deepBlue,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          Row(
            children: [
              Container(
                width: 7.w,
                height: 7.w,
                decoration: const BoxDecoration(
                  color: AppColors.success,
                  shape: BoxShape.circle,
                ),
              ),
              SizedBox(width: 6.w),
              Text(
                'Surrey Flagship Catalogue · ${ProductsController.totalSkus} SKUs',
                style: TextStyle(fontSize: 11.sp, color: AppColors.grey),
              ),
            ],
          ),
          SizedBox(height: 14.h),
          _buildSearch(),
          SizedBox(height: 14.h),
          _buildCategoryChips(),
          SizedBox(height: 14.h),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 4.w),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Obx(
                  () => Text(
                    'Showing ${controller.products.length} of ${ProductsController.totalSkus} items',
                    style: TextStyle(fontSize: 11.sp, color: AppColors.grey),
                  ),
                ),
                GestureDetector(
                  onTap: _showSortSheet,
                  child: Obx(
                    () => Row(
                      children: [
                        Text(
                          'Sort: ${controller.sortLabel.value}',
                          style: TextStyle(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primaryBlue,
                          ),
                        ),
                        Icon(Icons.keyboard_arrow_down,
                            size: 16.sp, color: AppColors.primaryBlue),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 12.h),
        ],
      ),
    );
  }

  Widget _buildSearch() {
    return Container(
      height: 50.h,
      padding: EdgeInsets.symmetric(horizontal: 14.w),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadows.small,
      ),
      child: Row(
        children: [
          Icon(Icons.search, size: 22.sp, color: AppColors.grey),
          SizedBox(width: 10.w),
          Expanded(
            child: TextField(
              onChanged: controller.onSearchChanged,
              style: TextStyle(fontSize: 14.sp, color: AppColors.textDark),
              decoration: InputDecoration(
                isDense: true,
                border: InputBorder.none,
                hintText: 'Search product, SKU, model or size...',
                hintStyle:
                    TextStyle(fontSize: 13.sp, color: AppColors.greyLight),
              ),
            ),
          ),
          Icon(Icons.qr_code_scanner, size: 22.sp, color: AppColors.grey),
        ],
      ),
    );
  }

  Widget _buildCategoryChips() {
    return SizedBox(
      height: 38.h,
      // Read the observable here (not inside the lazy itemBuilder) so Obx
      // registers it.
      child: Obx(() {
        final selectedIndex = controller.selectedCategory.value;
        return ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: controller.categories.length,
          separatorBuilder: (_, _) => SizedBox(width: 8.w),
          itemBuilder: (context, i) {
            final c = controller.categories[i];
            final selected = selectedIndex == i;
            return GestureDetector(
              onTap: () => controller.selectCategory(i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: selected ? AppColors.primaryBlue : AppColors.white,
                  borderRadius: BorderRadius.circular(20.r),
                  border: Border.all(
                    color: selected ? AppColors.primaryBlue : AppColors.border,
                  ),
                ),
                child: Text(
                  '${c.label} (${c.count})',
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                    color: selected ? AppColors.white : AppColors.textDark,
                  ),
                ),
              ),
            );
          },
        );
      }),
    );
  }

  // ---------------- Product card ----------------
  Widget _buildCard(ProductItem p) {
    return GestureDetector(
      onTap: () => controller.onEditProduct(p),
      child: Container(
        padding: EdgeInsets.all(14.w),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(22.r),
          boxShadow: AppShadows.soft,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildThumb(p),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          p.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 15.sp,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textDark,
                          ),
                        ),
                      ),
                      _buildMenu(p),
                    ],
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    'Model: ${p.model} · SKU: ${p.sku}',
                    style: TextStyle(
                      fontSize: 11.sp,
                      height: 1.35,
                      color: AppColors.grey,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  const Divider(),
                  SizedBox(height: 8.h),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _StatusChip(status: p.status, units: p.units),
                            if (p.customSize) ...[
                              SizedBox(height: 6.h),
                              Container(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 10.w, vertical: 5.h),
                                decoration: BoxDecoration(
                                  color: AppColors.lightBlue,
                                  borderRadius: BorderRadius.circular(20.r),
                                ),
                                child: Text(
                                  'Custom size available',
                                  style: TextStyle(
                                    fontSize: 11.sp,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.deepBlue,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      SizedBox(width: 8.w),
                      Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: formatMoney(p.price),
                              style: TextStyle(
                                fontSize: 18.sp,
                                fontWeight: FontWeight.w800,
                                color: AppColors.primaryBlue,
                              ),
                            ),
                            TextSpan(
                              text: '  CAD',
                              style: TextStyle(
                                fontSize: 10.sp,
                                fontWeight: FontWeight.w500,
                                color: AppColors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (p.reorderPo != null) ...[
                    SizedBox(height: 8.h),
                    Row(
                      children: [
                        Icon(Icons.local_shipping_outlined,
                            size: 15.sp, color: AppColors.warning),
                        SizedBox(width: 6.w),
                        Text(
                          'Reorder placed (PO ${p.reorderPo})',
                          style: TextStyle(
                            fontSize: 11.sp,
                            fontStyle: FontStyle.italic,
                            color: AppColors.grey,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThumb(ProductItem p) {
    final isOut = p.status == StockStatus.out;
    final isPillow = p.kind == ProductKind.pillow;

    final Color bg;
    final Color fg;
    if (isOut) {
      bg = AppColors.dangerBg;
      fg = AppColors.danger;
    } else if (isPillow) {
      bg = AppColors.successBg;
      fg = AppColors.success;
    } else {
      bg = AppColors.lightBlue;
      fg = AppColors.primaryBlue;
    }

    final Color dot = p.status == StockStatus.inStock
        ? AppColors.success
        : p.status == StockStatus.low
            ? AppColors.warning
            : AppColors.danger;

    return SizedBox(
      width: 52.w,
      height: 52.w,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(14.r),
            ),
            alignment: Alignment.center,
            child: Icon(
              isPillow ? Icons.airline_seat_flat : Icons.bed_outlined,
              size: 26.sp,
              color: fg,
            ),
          ),
          Positioned(
            right: -2.w,
            bottom: -2.w,
            child: Container(
              width: 11.w,
              height: 11.w,
              decoration: BoxDecoration(
                color: dot,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.white, width: 2),
              ),
            ),
          ),
          if (p.customSize)
            Positioned(
              right: -4.w,
              top: -4.w,
              child: Container(
                width: 17.w,
                height: 17.w,
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.white, width: 1.5),
                ),
                child: Icon(Icons.straighten,
                    size: 9.sp, color: AppColors.white),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMenu(ProductItem p) {
    return PopupMenuButton<String>(
      padding: EdgeInsets.zero,
      iconSize: 20.sp,
      icon: Icon(Icons.more_vert, size: 20.sp, color: AppColors.greyLight),
      color: AppColors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14.r)),
      onSelected: (v) {
        if (v == 'edit') controller.onEditProduct(p);
        if (v == 'delete') _showDeleteSheet(p);
      },
      itemBuilder: (_) => const [
        PopupMenuItem(value: 'edit', child: Text('Edit')),
        PopupMenuItem(value: 'delete', child: Text('Delete')),
      ],
    );
  }

  Widget _buildSwipeHint() {
    return Padding(
      padding: EdgeInsets.only(top: 4.h, bottom: 14.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.touch_app_outlined, size: 14.sp, color: AppColors.grey),
          SizedBox(width: 6.w),
          Text(
            'Swipe left on any item to Edit or Delete',
            style: TextStyle(fontSize: 11.sp, color: AppColors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 32.w, vertical: 48.h),
      child: Column(
        children: [
          Container(
            width: 72.w,
            height: 72.w,
            decoration: const BoxDecoration(
              color: AppColors.lightBlue,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.inventory_2_outlined,
                size: 32.sp, color: AppColors.primaryBlue),
          ),
          SizedBox(height: 16.h),
          Text(
            'No products yet. Add your first product.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
              color: AppColors.textDark,
            ),
          ),
        ],
      ),
    );
  }

  // ---------------- Add button ----------------
  Widget _buildAddButton() {
    return Padding(
      padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 10.h),
      child: Container(
        height: 56.h,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18.r),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryBlue.withOpacity(0.28),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Material(
          color: AppColors.primaryBlue,
          borderRadius: BorderRadius.circular(18.r),
          child: InkWell(
            onTap: controller.onAddProductPressed,
            borderRadius: BorderRadius.circular(18.r),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: Row(
                children: [
                  Icon(Icons.add_circle_outline,
                      size: 24.sp, color: AppColors.white),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: Text(
                      'Add Product',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w800,
                        color: AppColors.white,
                      ),
                    ),
                  ),
                  Text(
                    'New SKU',
                    style: TextStyle(
                      fontSize: 11.sp,
                      color: AppColors.white.withOpacity(0.85),
                    ),
                  ),
                  SizedBox(width: 10.w),
                  Container(
                    width: 32.w,
                    height: 32.w,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.white.withOpacity(0.2),
                    ),
                    child: Icon(Icons.arrow_forward,
                        size: 18.sp, color: AppColors.white),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ---------------- Bottom sheets ----------------
  void _showSortSheet() {
    Get.bottomSheet(
      _SheetContainer(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Sort products',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.w800,
                color: AppColors.textDark,
              ),
            ),
            SizedBox(height: 8.h),
            ...ProductsController.sortOptions.map(
              (o) => Obx(() {
                final selected = controller.sortLabel.value == o;
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    o,
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
                      color: selected
                          ? AppColors.primaryBlue
                          : AppColors.textDark,
                    ),
                  ),
                  trailing: selected
                      ? const Icon(Icons.check_circle,
                          color: AppColors.primaryBlue)
                      : null,
                  onTap: () {
                    controller.selectSort(o);
                    Get.back();
                  },
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteSheet(ProductItem p) {
    Get.bottomSheet(
      _SheetContainer(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56.w,
              height: 56.w,
              decoration: const BoxDecoration(
                color: AppColors.dangerBg,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.delete_outline,
                  size: 28.sp, color: AppColors.danger),
            ),
            SizedBox(height: 14.h),
            Text(
              'Delete product?',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.w800,
                color: AppColors.textDark,
              ),
            ),
            SizedBox(height: 6.h),
            Text(
              'This removes the product from the catalogue. Past sales are kept.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13.sp,
                height: 1.35,
                color: AppColors.grey,
              ),
            ),
            SizedBox(height: 6.h),
            Text(
              p.name,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13.sp,
                fontWeight: FontWeight.w700,
                color: AppColors.textDark,
              ),
            ),
            SizedBox(height: 20.h),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 50.h,
                    child: OutlinedButton(
                      onPressed: () => Get.back(),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.border),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14.r),
                        ),
                      ),
                      child: Text(
                        'Cancel',
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textDark,
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: SizedBox(
                    height: 50.h,
                    child: ElevatedButton(
                      onPressed: () {
                        controller.deleteProduct(p);
                        Get.back();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.danger,
                        foregroundColor: AppColors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14.r),
                        ),
                      ),
                      child: Text(
                        'Delete',
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 12.h),
            Text(
              'This action is recorded in the audit log',
              style: TextStyle(fontSize: 11.sp, color: AppColors.greyLight),
            ),
          ],
        ),
      ),
    );
  }
}

class _SheetContainer extends StatelessWidget {
  const _SheetContainer({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 24.h),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28.r)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40.w,
              height: 4.h,
              margin: EdgeInsets.only(bottom: 16.h),
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(4.r),
              ),
            ),
            child,
          ],
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status, required this.units});

  final StockStatus status;
  final int units;

  @override
  Widget build(BuildContext context) {
    final Color fg;
    final Color bg;
    final String label;
    switch (status) {
      case StockStatus.inStock:
        fg = AppColors.success;
        bg = AppColors.successBg;
        label = 'In stock ($units units)';
        break;
      case StockStatus.low:
        fg = AppColors.warning;
        bg = AppColors.warningBg;
        label = 'Low stock ($units units)';
        break;
      case StockStatus.out:
        fg = AppColors.danger;
        bg = AppColors.dangerBg;
        label = 'Out of stock ($units units)';
        break;
    }
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6.w,
            height: 6.w,
            decoration: BoxDecoration(color: fg, shape: BoxShape.circle),
          ),
          SizedBox(width: 5.w),
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11.sp,
                fontWeight: FontWeight.w700,
                color: fg,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Card that reveals Edit / Delete when swiped to the left.
class _SwipeCard extends StatefulWidget {
  const _SwipeCard({
    super.key,
    required this.child,
    required this.onEdit,
    required this.onDelete,
  });

  final Widget child;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  State<_SwipeCard> createState() => _SwipeCardState();
}

class _SwipeCardState extends State<_SwipeCard> {
  double _dx = 0;
  bool _dragging = false;

  double get _max => 144.w;

  void _close() => setState(() => _dx = 0);

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        if (_dx != 0)
          Positioned.fill(
            child: Align(
              alignment: Alignment.centerRight,
              child: SizedBox(
                width: _max,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(22.r),
                  child: Row(
                    children: [
                      Expanded(
                        child: _SwipeAction(
                          color: AppColors.primaryBlue,
                          icon: Icons.edit_outlined,
                          label: 'Edit',
                          onTap: () {
                            _close();
                            widget.onEdit();
                          },
                        ),
                      ),
                      Expanded(
                        child: _SwipeAction(
                          color: AppColors.danger,
                          icon: Icons.delete_outline,
                          label: 'Delete',
                          onTap: () {
                            _close();
                            widget.onDelete();
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        GestureDetector(
          onHorizontalDragUpdate: (d) => setState(() {
            _dragging = true;
            _dx = (_dx + d.delta.dx).clamp(-_max, 0.0);
          }),
          onHorizontalDragEnd: (_) => setState(() {
            _dragging = false;
            _dx = _dx < -_max / 2 ? -_max : 0;
          }),
          child: AnimatedContainer(
            duration:
                _dragging ? Duration.zero : const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            transform: Matrix4.translationValues(_dx, 0, 0),
            child: widget.child,
          ),
        ),
      ],
    );
  }
}

class _SwipeAction extends StatelessWidget {
  const _SwipeAction({
    required this.color,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final Color color;
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        color: color,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 22.sp, color: AppColors.white),
            SizedBox(height: 4.h),
            Text(
              label,
              style: TextStyle(
                fontSize: 11.sp,
                fontWeight: FontWeight.w700,
                color: AppColors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
