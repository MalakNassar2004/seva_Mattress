import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_colors_extra.dart';
import '../../app/utils/money.dart';
import '../../app/widgets/app_widgets.dart';
import '../../app/widgets/owner_widgets.dart';
import '../../app/widgets/shared_widgets.dart';
import 'po_models.dart';
import 'procurement_store.dart';

/// Result of the Receive Goods sheet.
class ReceiveResult {
  const ReceiveResult({
    required this.order,
    required this.units,
    required this.location,
    this.draft = false,
  });

  /// The PO with the received quantities applied.
  final PurchaseOrder order;

  /// Units added to stock by this receipt.
  final int units;
  final ReceiveLocation location;

  /// true = "Save Progress as Draft" (nothing added to stock yet).
  final bool draft;
}

class ReceiveGoodsController extends GetxController {
  ReceiveGoodsController(this.order);

  final PurchaseOrder order;

  /// Lines still waiting for goods (the checklist).
  late final List<PoLine> pending =
      order.lines.where((l) => !l.complete).toList();

  // ---------------- State ----------------
  /// Received now, per pending line. Starts at the expected quantity.
  late final received = pending.map((l) => l.remaining).toList().obs;
  late final List<TextEditingController> notes =
      pending.map((l) => TextEditingController(text: l.note)).toList();
  final location = ReceiveLocation.warehouse.obs;

  /// Waybill / dock photo (mock file name). null = none attached.
  final attachment = RxnString('waybill_scan_88410.pdf');
  final error = RxnString();

  String get supplierName =>
      ProcurementStore.to.supplier(order.supplierId)?.name ?? '';

  int expected(int i) => pending[i].remaining;
  int diff(int i) => received[i] - expected(i);
  int get totalUnits => received.fold(0, (a, b) => a + b);

  // ---------------- Actions ----------------
  void increment(int i) {
    received[i] = received[i] + 1;
    error.value = null;
  }

  void decrement(int i) {
    if (received[i] > 0) received[i] = received[i] - 1;
    error.value = null;
  }

  void selectLocation(ReceiveLocation l) => location.value = l;

  void onAttachPressed() {
    // TODO(backend): open the camera / file picker and upload the waybill.
    attachment.value = 'waybill_scan_${order.number.split('-').last}.pdf';
  }

  void onRemoveAttachment() => attachment.value = null;

  /// Applies the counts to the PO lines.
  PurchaseOrder _applied() {
    var k = 0;
    final lines = order.lines.map((l) {
      if (l.complete) return l;
      final i = k++;
      return l.copyWith(
        received: l.received + received[i],
        note: notes[i].text.trim(),
      );
    }).toList();
    final allIn = lines.every((l) => l.complete);
    final anyIn = lines.any((l) => l.received > 0);
    return order.copyWith(
      lines: lines,
      status: allIn
          ? PoStatus.received
          : (anyIn ? PoStatus.partial : order.status),
      overdue: allIn ? false : order.overdue,
      receivedOn: allIn ? 'Today' : null,
    );
  }

  void onConfirm() {
    // Every mismatch must be justified.
    for (var i = 0; i < pending.length; i++) {
      if (diff(i) != 0 && notes[i].text.trim().isEmpty) {
        error.value = 'Add a note for ${pending[i].name}';
        return;
      }
    }
    if (totalUnits == 0) {
      error.value = 'Nothing counted yet';
      return;
    }
    Get.back(
      result: ReceiveResult(
        order: _applied(),
        units: totalUnits,
        location: location.value,
      ),
    );
  }

  void onSaveDraft() {
    // TODO(backend): save the counts without moving stock.
    final draftOrder = order.copyWith(
      lines: [
        for (final l in order.lines)
          if (l.complete)
            l
          else
            l.copyWith(note: notes[pending.indexOf(l)].text.trim()),
      ],
    );
    Get.back(
      result: ReceiveResult(
        order: draftOrder,
        units: 0,
        location: location.value,
        draft: true,
      ),
    );
  }

  void onClosePressed() => Get.back();

  @override
  void onClose() {
    for (final n in notes) {
      n.dispose();
    }
    super.onClose();
  }
}

/// Bottom sheet: Receive Goods & Dock Inspection.
class ReceiveGoodsSheet extends GetView<ReceiveGoodsController> {
  const ReceiveGoodsSheet({super.key});

  static Future<ReceiveResult?> open(PurchaseOrder order) async {
    Get.put(ReceiveGoodsController(order));
    final result = await Get.bottomSheet<ReceiveResult>(
      const ReceiveGoodsSheet(),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black54,
    );
    Get.delete<ReceiveGoodsController>();
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final c = controller;
    return SheetFrame(
      heightFactor: 0.92,
      footer: Column(
        mainAxisSize: MainAxisSize.min,
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
          PrimaryArrowButton(
            label: 'Confirm Receiving & Update Stock',
            leadingIcon: Icons.inventory_outlined,
            onPressed: c.onConfirm,
          ),
          SizedBox(height: 10.h),
          SizedBox(
            width: double.infinity,
            child: SoftButton(
              label: 'Save Progress as Draft',
              icon: Icons.save_outlined,
              height: 46,
              fontSize: 14,
              onTap: c.onSaveDraft,
            ),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          SizedBox(height: 14.h),
          _buildSlipCard(),
          SizedBox(height: 16.h),
          _buildLocation(),
          SizedBox(height: 18.h),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Inspection Checklist (${c.pending.length} Items)',
                  style: TextStyle(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textDark,
                  ),
                ),
              ),
              Text(
                'Ordered vs Actual',
                style: TextStyle(
                  fontSize: 11.5.sp,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryBlue,
                ),
              ),
            ],
          ),
          SizedBox(height: 10.h),
          ...List.generate(c.pending.length, _lineCard),
          SizedBox(height: 4.h),
          Obx(_buildAttachment),
          SizedBox(height: 12.h),
          _buildAuditBox(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final c = controller;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                'Receive Goods & Dock Inspection',
                style: TextStyle(
                  fontSize: 19.sp,
                  height: 1.25,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textDark,
                ),
              ),
            ),
            SizedBox(width: 8.w),
            Padding(
              padding: EdgeInsets.only(top: 4.h),
              child: StatusPill(
                text: 'OWNER',
                fg: AppColors.white,
                bg: AppColors.deepBlue,
                fontSize: 10,
                letterSpacing: 0.6,
              ),
            ),
            SizedBox(width: 8.w),
            SheetCloseButton(onTap: c.onClosePressed),
          ],
        ),
        SizedBox(height: 6.h),
        Text.rich(
          TextSpan(children: [
            TextSpan(
              text: 'PO ${c.order.number}',
              style: const TextStyle(
                color: AppColors.primaryBlue,
                fontWeight: FontWeight.w700,
              ),
            ),
            TextSpan(text: '  ·  ${c.supplierName}  ·  '),
            const TextSpan(
              text: 'Surrey Dock',
              style: TextStyle(color: AppColors.primaryBlue),
            ),
          ]),
          style: TextStyle(fontSize: 12.sp, color: AppColors.textDark),
        ),
      ],
    );
  }

  Widget _buildSlipCard() {
    final o = controller.order;
    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: AppColorsExtra.panelGrey,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColorsExtra.panelBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Caption('Purchase order total'),
                    SizedBox(height: 4.h),
                    Text.rich(
                      TextSpan(children: [
                        TextSpan(text: formatCad(o.total)),
                        TextSpan(
                          text: ' CAD',
                          style: TextStyle(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w600,
                            color: AppColors.grey,
                          ),
                        ),
                      ]),
                      style: TextStyle(
                        fontSize: 20.sp,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textDark,
                      ),
                    ),
                  ],
                ),
              ),
              if (o.packingSlip != null)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Caption('Packing slip'),
                    SizedBox(height: 4.h),
                    Text(
                      o.packingSlip!,
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textDark,
                      ),
                    ),
                  ],
                ),
            ],
          ),
          SizedBox(height: 10.h),
          const Divider(color: AppColorsExtra.panelBorder),
          SizedBox(height: 10.h),
          Row(
            children: [
              Icon(Icons.local_shipping_outlined,
                  size: 17.sp, color: AppColors.primaryBlue),
              SizedBox(width: 6.w),
              Expanded(
                child: Text.rich(
                  TextSpan(children: [
                    const TextSpan(
                      text: 'Carrier:  ',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    TextSpan(text: o.carrier ?? 'Supplier truck'),
                  ]),
                  style: TextStyle(fontSize: 12.5.sp, color: AppColors.textDark),
                ),
              ),
              if (o.dockPass != null)
                StatusPill(
                  text: o.dockPass!,
                  icon: Icons.verified_user_outlined,
                  fg: AppColors.textDark,
                  bg: AppColorsExtra.chipGrey,
                  fontSize: 10.5,
                ),
            ],
          ),
          if (o.deliveryNote != null) ...[
            SizedBox(height: 10.h),
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(10.w),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(10.r),
                border: Border.all(color: AppColorsExtra.panelBorder),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.notes, size: 16.sp, color: AppColors.primaryBlue),
                  SizedBox(width: 6.w),
                  Expanded(
                    child: Text.rich(
                      TextSpan(children: [
                        const TextSpan(
                          text: 'Delivery Note: ',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: AppColors.primaryBlue,
                          ),
                        ),
                        TextSpan(text: o.deliveryNote),
                      ]),
                      style: TextStyle(
                        fontSize: 12.sp,
                        height: 1.4,
                        color: AppColors.textDark,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLocation() {
    final c = controller;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.warehouse_outlined,
                size: 17.sp, color: AppColors.deepBlue),
            SizedBox(width: 6.w),
            Expanded(
              child: Text(
                'Target Warehouse Destination',
                style: TextStyle(
                  fontSize: 13.5.sp,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark,
                ),
              ),
            ),
            Text(
              'Location Verified',
              style: TextStyle(
                fontSize: 11.sp,
                fontWeight: FontWeight.w600,
                color: AppColors.primaryBlue,
              ),
            ),
          ],
        ),
        SizedBox(height: 8.h),
        Obx(
          () => Container(
            padding: EdgeInsets.all(4.w),
            decoration: BoxDecoration(
              color: AppColorsExtra.segmentBg,
              borderRadius: BorderRadius.circular(14.r),
            ),
            child: Row(
              children: ReceiveLocation.values.map((l) {
                final sel = c.location.value == l;
                final color = sel ? AppColors.primaryBlue : AppColors.grey;
                return Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => c.selectLocation(l),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: EdgeInsets.symmetric(vertical: 8.h),
                      decoration: BoxDecoration(
                        color: sel ? AppColors.white : Colors.transparent,
                        borderRadius: BorderRadius.circular(11.r),
                        border: sel
                            ? Border.all(color: AppColorsExtra.infoBorder)
                            : null,
                      ),
                      child: Column(
                        children: [
                          Icon(l.icon, size: 16.sp, color: color),
                          SizedBox(height: 3.h),
                          Text(
                            l.label,
                            style: TextStyle(
                              fontSize: 12.sp,
                              fontWeight:
                                  sel ? FontWeight.w800 : FontWeight.w500,
                              color: sel
                                  ? AppColors.primaryBlue
                                  : AppColors.textDark.withValues(alpha: 0.75),
                            ),
                          ),
                          Text(
                            l.note,
                            style: TextStyle(fontSize: 9.5.sp, color: color),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _lineCard(int i) {
    final c = controller;
    final l = c.pending[i];
    return Obx(() {
      final d = c.diff(i);
      final mismatch = d != 0;
      return Container(
        margin: EdgeInsets.only(bottom: 12.h),
        padding: EdgeInsets.all(14.w),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(
            color: mismatch ? AppColorsExtra.amberBorder : AppColors.border,
            width: mismatch ? 1.4 : 1,
          ),
          boxShadow: mismatch
              ? [
                  BoxShadow(
                    color: AppColors.warning.withValues(alpha: 0.12),
                    blurRadius: 10,
                  ),
                ]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44.w,
                  height: 44.w,
                  decoration: BoxDecoration(
                    color: AppColorsExtra.panelGrey,
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(color: AppColorsExtra.panelBorder),
                  ),
                  child: Icon(l.icon, size: 21.sp, color: AppColors.deepBlue),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l.title,
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textDark,
                        ),
                      ),
                      SizedBox(height: 3.h),
                      Text.rich(
                        TextSpan(children: [
                          const TextSpan(text: 'SKU: '),
                          TextSpan(
                            text: l.sku,
                            style: const TextStyle(
                              fontFamily: 'monospace',
                              letterSpacing: 0.4,
                            ),
                          ),
                          const TextSpan(text: ' · Ordered: '),
                          TextSpan(
                            text: '${c.expected(i)} ${l.unit}',
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                        ]),
                        style: TextStyle(
                          fontSize: 11.sp,
                          color: AppColors.textDark.withValues(alpha: 0.8),
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
                Expanded(child: _diffChip(d, l.unit)),
                SizedBox(width: 8.w),
                _stepper(i),
              ],
            ),
            if (mismatch) ...[
              SizedBox(height: 12.h),
              Container(
                padding: EdgeInsets.all(10.w),
                decoration: BoxDecoration(
                  color: AppColorsExtra.amberSoft,
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(color: AppColorsExtra.amberBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Caption(
                      'Discrepancy justification (vendor)',
                      color: AppColorsExtra.amberText,
                    ),
                    SizedBox(height: 6.h),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 10.w),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(10.r),
                        border: Border.all(color: AppColorsExtra.amberBorder),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: c.notes[i],
                              onChanged: (_) => c.error.value = null,
                              style: TextStyle(
                                fontSize: 12.5.sp,
                                color: AppColors.textDark,
                              ),
                              decoration: InputDecoration(
                                isDense: true,
                                border: InputBorder.none,
                                contentPadding:
                                    EdgeInsets.symmetric(vertical: 10.h),
                                hintText: d < 0
                                    ? 'e.g. ${-d} units backordered by vendor, arriving Oct 30'
                                    : 'e.g. Vendor sent $d extra, keep and invoice',
                                hintStyle: TextStyle(
                                  fontSize: 12.sp,
                                  color: AppColors.greyLight,
                                ),
                              ),
                            ),
                          ),
                          Icon(Icons.edit_note,
                              size: 18.sp, color: AppColorsExtra.amberText),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      );
    });
  }

  Widget _diffChip(int d, String unit) {
    if (d == 0) {
      return const Align(
        alignment: Alignment.centerLeft,
        child: StatusPill(
          text: 'Full Quantity Received',
          icon: Icons.check,
          fg: AppColors.success,
          bg: AppColorsExtra.successSoft,
          border: AppColorsExtra.successBorder,
          fontSize: 11,
        ),
      );
    }
    final short = d < 0;
    return Align(
      alignment: Alignment.centerLeft,
      child: StatusPill(
        text: short ? 'Short by ${-d} $unit' : 'Over by $d $unit',
        icon: Icons.warning_amber_rounded,
        fg: short ? AppColorsExtra.amberText : AppColors.primaryBlue,
        bg: short ? AppColorsExtra.amberSoft : AppColorsExtra.infoBg,
        border: short ? AppColorsExtra.amberBorder : AppColorsExtra.infoBorder,
        fontSize: 11,
      ),
    );
  }

  Widget _stepper(int i) {
    final c = controller;
    final q = c.received[i];
    Widget btn(IconData icon, VoidCallback? onTap) => GestureDetector(
          onTap: onTap,
          child: Container(
            width: 34.w,
            height: 34.w,
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(10.r),
              border: Border.all(color: AppColors.border),
            ),
            child: Icon(icon,
                size: 18.sp,
                color: onTap == null ? AppColors.greyLight : AppColors.textDark),
          ),
        );
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: AppColorsExtra.panelGrey,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          btn(Icons.remove, q > 0 ? () => c.decrement(i) : null),
          SizedBox(
            width: 40.w,
            child: Text(
              '$q',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 17.sp,
                fontWeight: FontWeight.w800,
                color: AppColors.textDark,
              ),
            ),
          ),
          btn(Icons.add, () => c.increment(i)),
        ],
      ),
    );
  }

  Widget _buildAttachment() {
    final c = controller;
    final file = c.attachment.value;
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: AppColorsExtra.panelGrey,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColorsExtra.panelBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.attachment, size: 16.sp, color: AppColors.deepBlue),
              SizedBox(width: 6.w),
              Expanded(
                child: Text.rich(
                  TextSpan(children: [
                    const TextSpan(text: 'WAYBILL & DOCK PHOTO '),
                    TextSpan(
                      text: file == null ? '(Optional)' : 'ATTACHED',
                    ),
                    if (file != null)
                      const TextSpan(
                        text: '  1 File (Encrypted)',
                        style: TextStyle(color: AppColors.primaryBlue),
                      ),
                  ]),
                  style: TextStyle(
                    fontSize: 11.sp,
                    letterSpacing: 0.3,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark.withValues(alpha: 0.85),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 10.h),
          if (file == null)
            SizedBox(
              width: double.infinity,
              child: SoftButton(
                label: 'Attach Invoice or Waybill',
                icon: Icons.add_a_photo_outlined,
                height: 44,
                fg: AppColors.primaryBlue,
                onTap: c.onAttachPressed,
              ),
            )
          else
            Container(
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  Container(
                    width: 38.w,
                    height: 38.w,
                    decoration: BoxDecoration(
                      color: AppColors.lightBlue,
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                    child: Icon(Icons.picture_as_pdf_outlined,
                        size: 20.sp, color: AppColors.deepBlue),
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          file,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textDark,
                          ),
                        ),
                        Text(
                          '1.4 MB · ${c.order.carrier ?? 'Driver'} Signed Dock Bill',
                          style: TextStyle(
                            fontSize: 11.sp,
                            color: AppColors.textDark.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 6.w),
                  Column(
                    children: [
                      SoftButton(
                        label: '+ Retake',
                        icon: Icons.photo_camera_outlined,
                        height: 32,
                        radius: 10,
                        fontSize: 11.5,
                        fg: AppColors.primaryBlue,
                        onTap: c.onAttachPressed,
                      ),
                      GestureDetector(
                        onTap: c.onRemoveAttachment,
                        child: Padding(
                          padding: EdgeInsets.only(top: 4.h),
                          child: Text(
                            'Remove',
                            style: TextStyle(
                              fontSize: 11.sp,
                              color: AppColors.danger,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAuditBox() {
    final c = controller;
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: AppColorsExtra.panelGrey,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: AppColorsExtra.panelBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.assignment_turned_in_outlined,
              size: 16.sp, color: AppColors.deepBlue),
          SizedBox(width: 8.w),
          Expanded(
            child: Text.rich(
              TextSpan(children: [
                const TextSpan(
                  text: 'This receiving entry will immediately increment '
                      'on-hand stock and log discrepancy ',
                ),
                TextSpan(
                  text: c.order.number,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark,
                  ),
                ),
                const TextSpan(text: ' in the immutable audit log with Owner ID '),
                const TextSpan(
                  text: '#OWN-001',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryBlue,
                  ),
                ),
                const TextSpan(text: '.'),
              ]),
              style: TextStyle(
                fontSize: 11.sp,
                height: 1.45,
                color: AppColors.textDark.withValues(alpha: 0.75),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
