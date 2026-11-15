import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_colors_extra.dart';
import '../../app/utils/money.dart';
import '../../app/widgets/app_widgets.dart';
import '../../app/widgets/owner_widgets.dart';
import '../../app/widgets/shared_widgets.dart';
import 'po_form_controller.dart';
import 'po_models.dart';

/// Create Purchase Order / Resume draft.
class PoFormView extends GetView<PoFormController> {
  const PoFormView({super.key});

  @override
  Widget build(BuildContext context) {
    final c = controller;
    return Scaffold(
      body: SoftBackground(
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 0),
                child: Row(
                  children: [
                    BackPill(label: 'Back', onTap: c.onBackPressed),
                    SizedBox(width: 10.w),
                    Expanded(
                      child: Text(
                        c.isEdit ? 'Edit ${c.editing!.number}' : 'New Purchase Order',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 19.sp,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textDark,
                        ),
                      ),
                    ),
                    if (c.isEdit)
                      const StatusPill(
                        text: 'Draft',
                        fg: AppColors.grey,
                        bg: AppColorsExtra.chipGrey,
                        fontSize: 11,
                      ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 16.h),
                  children: [
                    Obx(_buildSupplier),
                    SizedBox(height: 14.h),
                    Obx(_buildItems),
                    SizedBox(height: 14.h),
                    Obx(() => _buildDelivery(context)),
                    SizedBox(height: 14.h),
                    Obx(_buildTotals),
                    SizedBox(height: 14.h),
                    const AuditNote(
                      'Purchase orders are recorded in the audit log',
                      icon: Icons.lock_outline,
                    ),
                  ],
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 10.h),
                child: Column(
                  children: [
                    Obx(() {
                      final err = c.error.value;
                      if (err == null) return const SizedBox.shrink();
                      return Padding(
                        padding: EdgeInsets.only(bottom: 8.h),
                        child: Text(
                          err,
                          style: TextStyle(
                            fontSize: 12.5.sp,
                            fontWeight: FontWeight.w700,
                            color: AppColors.danger,
                          ),
                        ),
                      );
                    }),
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: SoftButton(
                            label: 'Save Draft',
                            icon: Icons.save_outlined,
                            height: 56,
                            radius: 16,
                            fontSize: 14,
                            onTap: c.onSaveDraft,
                          ),
                        ),
                        SizedBox(width: 10.w),
                        Expanded(
                          flex: 3,
                          child: PrimaryArrowButton(
                            label: 'Place Order',
                            leadingIcon: Icons.send_outlined,
                            onPressed: c.onPlaceOrder,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------- Supplier ----------------
  Widget _buildSupplier() {
    final c = controller;
    final selected = c.supplierId.value;
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CardTitle(icon: Icons.factory_outlined, title: 'Supplier'),
          SizedBox(height: 12.h),
          ...c.store.suppliers.map((s) {
            final sel = s.id == selected;
            return GestureDetector(
              onTap: () => c.selectSupplier(s.id),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                margin: EdgeInsets.only(bottom: 8.h),
                padding: EdgeInsets.all(10.w),
                decoration: BoxDecoration(
                  color: sel ? AppColorsExtra.infoBg : AppColors.white,
                  borderRadius: BorderRadius.circular(14.r),
                  border: Border.all(
                    color: sel ? AppColors.primaryBlue : AppColors.border,
                    width: sel ? 1.6 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    InitialsAvatar(initials: s.initials, size: 34),
                    SizedBox(width: 10.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            s.name,
                            style: TextStyle(
                              fontSize: 13.5.sp,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textDark,
                            ),
                          ),
                          Text(
                            '${s.category} · ${s.terms} · Lead ${s.leadDays}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                fontSize: 11.sp, color: AppColors.grey),
                          ),
                        ],
                      ),
                    ),
                    RadioDot(selected: sel),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  // ---------------- Items ----------------
  Widget _buildItems() {
    final c = controller;
    final hasSupplier = c.supplierId.value != null;
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CardTitle(
            icon: Icons.inventory_2_outlined,
            title: 'Items',
            trailing: StatusPill(
              text: '${c.lines.length} lines · ${c.units} units',
              fg: AppColors.deepBlue,
              bg: AppColors.lightBlue,
              fontSize: 11,
            ),
          ),
          SizedBox(height: 12.h),
          if (!hasSupplier)
            Text(
              'Pick a supplier to search their products',
              style: TextStyle(fontSize: 12.5.sp, color: AppColors.grey),
            )
          else ...[
            Container(
              height: 44.h,
              padding: EdgeInsets.symmetric(horizontal: 12.w),
              decoration: BoxDecoration(
                color: AppColorsExtra.panelGrey,
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(color: AppColorsExtra.panelBorder),
              ),
              child: Row(
                children: [
                  Icon(Icons.search, size: 19.sp, color: AppColors.grey),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: TextField(
                      controller: c.searchController,
                      onChanged: c.onSearchChanged,
                      style: TextStyle(
                          fontSize: 13.5.sp, color: AppColors.textDark),
                      decoration: InputDecoration(
                        isDense: true,
                        border: InputBorder.none,
                        hintText: 'Search product or SKU',
                        hintStyle: TextStyle(
                            fontSize: 13.sp, color: AppColors.greyLight),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 8.h),
            ...c.results.map(_resultRow),
            if (c.results.isEmpty)
              Padding(
                padding: EdgeInsets.symmetric(vertical: 6.h),
                child: Text(
                  'No products match',
                  style: TextStyle(fontSize: 12.sp, color: AppColors.grey),
                ),
              ),
            if (c.lines.isNotEmpty) ...[
              SizedBox(height: 8.h),
              const Divider(color: AppColorsExtra.panelBorder),
              SizedBox(height: 10.h),
              ...List.generate(c.lines.length, _lineCard),
            ],
          ],
        ],
      ),
    );
  }

  Widget _resultRow(PoProduct p) {
    return Padding(
      padding: EdgeInsets.only(bottom: 6.h),
      child: Row(
        children: [
          Icon(p.icon, size: 18.sp, color: AppColors.deepBlue),
          SizedBox(width: 8.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  p.name,
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textDark,
                  ),
                ),
                Text(
                  '${p.sku} · ${formatCad(p.unitCost)} / ${p.unit.replaceAll(RegExp(r's$'), '')}',
                  style: TextStyle(fontSize: 11.sp, color: AppColors.grey),
                ),
              ],
            ),
          ),
          SoftButton(
            label: 'Add',
            icon: Icons.add,
            height: 32,
            radius: 16,
            fontSize: 12,
            fg: AppColors.primaryBlue,
            borderColor: AppColorsExtra.infoBorder,
            onTap: () => controller.addProduct(p),
          ),
        ],
      ),
    );
  }

  Widget _lineCard(int i) {
    final c = controller;
    final l = c.lines[i];
    final sizes = c.sizesFor(l);
    return Container(
      margin: EdgeInsets.only(bottom: 10.h),
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36.w,
                height: 36.w,
                decoration: BoxDecoration(
                  color: AppColorsExtra.panelGrey,
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Icon(l.icon, size: 18.sp, color: AppColors.deepBlue),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l.name,
                      style: TextStyle(
                        fontSize: 13.5.sp,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textDark,
                      ),
                    ),
                    Text(
                      l.sku,
                      style: TextStyle(
                        fontSize: 10.5.sp,
                        fontFamily: 'monospace',
                        color: AppColors.grey,
                      ),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () => c.removeLine(i),
                child: Icon(Icons.delete_outline,
                    size: 20.sp, color: AppColors.danger),
              ),
            ],
          ),
          if (sizes.length > 1) ...[
            SizedBox(height: 10.h),
            Wrap(
              spacing: 6.w,
              runSpacing: 6.h,
              children: sizes
                  .map((s) => ChoicePill(
                        label: s,
                        selected: l.size == s,
                        onTap: () => c.selectSize(i, s),
                      ))
                  .toList(),
            ),
          ],
          SizedBox(height: 10.h),
          Row(
            children: [
              _qtyStepper(i, l.qty),
              SizedBox(width: 10.w),
              Expanded(
                child: LabeledInput(
                  controller: c.costControllers[i],
                  hint: '0.00',
                  prefixIcon: Icons.attach_money,
                  suffixText: '/ ${l.unit.replaceAll(RegExp(r's$'), '')}',
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  onChanged: (v) => c.onCostChanged(i, v),
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              'Line total ${formatCad(l.total)}',
              style: TextStyle(
                fontSize: 12.5.sp,
                fontWeight: FontWeight.w700,
                color: AppColors.deepBlue,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _qtyStepper(int i, int q) {
    Widget btn(IconData icon, VoidCallback? onTap) => GestureDetector(
          onTap: onTap,
          child: Container(
            width: 32.w,
            height: 32.w,
            decoration: BoxDecoration(
              color: onTap == null ? AppColorsExtra.panelGrey : AppColors.lightBlue,
              shape: BoxShape.circle,
            ),
            child: Icon(icon,
                size: 16.sp,
                color: onTap == null ? AppColors.greyLight : AppColors.deepBlue),
          ),
        );
    return Row(
      children: [
        btn(Icons.remove, q > 1 ? () => controller.decrement(i) : null),
        SizedBox(
          width: 36.w,
          child: Text(
            '$q',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15.sp,
              fontWeight: FontWeight.w800,
              color: AppColors.textDark,
            ),
          ),
        ),
        btn(Icons.add, () => controller.increment(i)),
      ],
    );
  }

  // ---------------- Delivery ----------------
  Widget _buildDelivery(BuildContext context) {
    final c = controller;
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CardTitle(icon: Icons.event_outlined, title: 'Expected Delivery'),
          SizedBox(height: 12.h),
          GestureDetector(
            onTap: () => c.onPickDatePressed(context),
            child: Container(
              height: 46.h,
              padding: EdgeInsets.symmetric(horizontal: 12.w),
              decoration: BoxDecoration(
                color: AppColorsExtra.panelGrey,
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(color: AppColorsExtra.panelBorder),
              ),
              child: Row(
                children: [
                  Icon(Icons.calendar_month_outlined,
                      size: 18.sp, color: AppColors.primaryBlue),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Text(
                      formatPoDate(c.expected.value),
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textDark,
                      ),
                    ),
                  ),
                  if (c.supplier != null)
                    Text(
                      'Lead ${c.supplier!.leadDays}',
                      style: TextStyle(fontSize: 11.5.sp, color: AppColors.grey),
                    ),
                ],
              ),
            ),
          ),
          SizedBox(height: 12.h),
          LabeledInput(
            controller: c.notesController,
            label: 'Notes for supplier',
            hint: 'e.g. Deliver to rear dock, call 30 min ahead',
            maxLines: 3,
          ),
        ],
      ),
    );
  }

  // ---------------- Totals ----------------
  Widget _buildTotals() {
    final c = controller;
    final style = TextStyle(fontSize: 13.sp, color: AppColors.textDark);
    Widget row(String a, String b) => Padding(
          padding: EdgeInsets.only(bottom: 8.h),
          child: Row(
            children: [Text(a, style: style), const Spacer(), Text(b, style: style)],
          ),
        );
    return SectionCard(
      color: AppColorsExtra.panelGrey,
      borderColor: AppColorsExtra.panelBorder,
      child: Column(
        children: [
          row('Subtotal', '${formatCad(c.subtotal)} CAD'),
          row('GST (5%)', '${formatCad(c.gst)} CAD'),
          const Divider(color: AppColorsExtra.panelBorder),
          SizedBox(height: 8.h),
          Row(
            children: [
              Text(
                'PO Total',
                style: TextStyle(
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textDark,
                ),
              ),
              const Spacer(),
              Text(
                '${formatCad(c.total)} CAD',
                style: TextStyle(
                  fontSize: 19.sp,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primaryBlue,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
