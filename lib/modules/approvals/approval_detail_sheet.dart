import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_colors_extra.dart';
import '../../app/utils/dates.dart';
import '../../app/utils/money.dart';
import '../../app/widgets/owner_widgets.dart';
import '../../app/widgets/page_widgets.dart';
import '../../app/widgets/shared_widgets.dart';
import 'approval_models.dart';

/// What the owner chose in the detail sheet.
class ApprovalDecision {
  const ApprovalDecision(this.approve, this.note);

  final bool approve;
  final String? note;
}

/// Bottom sheet: review one override request (sale snapshot, price
/// comparison with margin impact, justification, optional owner note).
class ApprovalDetailSheet extends StatefulWidget {
  const ApprovalDetailSheet({super.key, required this.request});

  final ApprovalRequest request;

  static Future<ApprovalDecision?> open(ApprovalRequest r) =>
      Get.bottomSheet<ApprovalDecision>(
        ApprovalDetailSheet(request: r),
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        barrierColor: Colors.black54,
      );

  @override
  State<ApprovalDetailSheet> createState() => _ApprovalDetailSheetState();
}

class _ApprovalDetailSheetState extends State<ApprovalDetailSheet> {
  final _note = TextEditingController();
  bool _costVisible = false;

  ApprovalRequest get _r => widget.request;
  bool get _pending => _r.status == ApprovalStatus.pending;

  String? get _noteText => _note.text.trim().isEmpty ? null : _note.text.trim();

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SheetFrame(
      heightFactor: 0.9,
      footer: _pending
          ? Row(
              children: [
                Expanded(
                  child: SoftButton(
                    label: 'Reject',
                    icon: Icons.close,
                    height: 52,
                    radius: 16,
                    fontSize: 14.5,
                    fg: AppColors.danger,
                    borderColor: AppColorsExtra.dangerBorder,
                    onTap: () =>
                        Get.back(result: ApprovalDecision(false, _noteText)),
                  ),
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: SoftButton(
                    label: 'Approve',
                    icon: Icons.check,
                    filled: true,
                    height: 52,
                    radius: 16,
                    fontSize: 14.5,
                    onTap: () =>
                        Get.back(result: ApprovalDecision(true, _noteText)),
                  ),
                ),
              ],
            )
          : SizedBox(
              width: double.infinity,
              child: SoftButton(
                label: 'Close',
                height: 50,
                radius: 16,
                fontSize: 14.5,
                onTap: Get.back,
              ),
            ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Review request',
                      style: TextStyle(
                        fontSize: 21.sp,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textDark,
                      ),
                    ),
                    Text(
                      'Req #${_r.id} · ${_r.terminal}',
                      style: TextStyle(
                        fontSize: 12.5.sp,
                        color: AppColors.grey,
                      ),
                    ),
                  ],
                ),
              ),
              SheetCloseButton(onTap: Get.back),
            ],
          ),
          SizedBox(height: 14.h),
          const InfoBanner(
            icon: Icons.shield_outlined,
            child: Text(
              'This decision is recorded in the audit log with your name, '
              'time and device.',
            ),
          ),
          SizedBox(height: 14.h),
          _buildSnapshot(),
          SizedBox(height: 12.h),
          if (_r.isPriceChange) _buildPriceComparison() else _buildAmount(),
          SizedBox(height: 16.h),
          const Caption('Justification'),
          SizedBox(height: 8.h),
          _quote(_r.reason),
          SizedBox(height: 16.h),
          if (_pending)
            LabeledInput(
              controller: _note,
              label: 'Owner note (optional)',
              hint: 'Visible in the audit log',
              maxLines: 3,
            )
          else
            _buildDecision(),
          SizedBox(height: 4.h),
        ],
      ),
    );
  }

  Widget _box({required Widget child, Color color = AppColors.white}) =>
      Container(
        width: double.infinity,
        padding: EdgeInsets.all(14.w),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: AppColors.border),
        ),
        child: child,
      );

  Widget _buildSnapshot() {
    return _box(
      color: AppColorsExtra.panelGrey,
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
                    const Caption(
                      'Sale snapshot',
                      color: AppColors.primaryBlue,
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      _r.item,
                      style: TextStyle(
                        fontSize: 17.sp,
                        fontWeight: FontWeight.w800,
                        height: 1.25,
                        color: AppColors.textDark,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      _r.saleRef,
                      style: TextStyle(
                        fontSize: 12.5.sp,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryBlue,
                      ),
                    ),
                  ],
                ),
              ),
              IconBox(_r.type.icon),
            ],
          ),
          SizedBox(height: 10.h),
          const Divider(color: AppColorsExtra.panelBorder),
          SizedBox(height: 10.h),
          Row(
            children: [
              if (_r.customer != null) ...[
                Icon(Icons.person_outline, size: 15.sp, color: AppColors.grey),
                SizedBox(width: 4.w),
                Flexible(
                  child: Text(
                    _r.customer!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12.5.sp,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textDark,
                    ),
                  ),
                ),
                SizedBox(width: 12.w),
              ],
              Icon(Icons.badge_outlined, size: 15.sp, color: AppColors.grey),
              SizedBox(width: 4.w),
              Flexible(
                child: Text(
                  '${_r.requester} · ${formatAgo(_r.time)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12.5.sp, color: AppColors.grey),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPriceComparison() {
    final orig = _r.originalPrice!;
    final req = _r.requestedPrice!;
    final drop = orig - req;
    final om = _r.originalMargin!;
    final pm = _r.projectedMargin!;
    final healthy = pm >= 50;
    return _box(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(child: Caption('Price comparison (CAD)')),
              StatusPill(
                text:
                    '-${formatCad(drop)} '
                    '(${(drop / orig * 100).toStringAsFixed(1)}% off)',
                fg: AppColors.danger,
                bg: AppColorsExtra.dangerSoft,
                fontSize: 10.5,
              ),
            ],
          ),
          SizedBox(height: 10.h),
          Container(
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: AppColorsExtra.panelGrey,
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _priceCol('Original', formatCad(orig), strike: true),
                ),
                Container(width: 1, height: 36.h, color: AppColors.border),
                SizedBox(width: 12.w),
                Expanded(
                  child: _priceCol('Requested', formatCad(req), blue: true),
                ),
              ],
            ),
          ),
          SizedBox(height: 12.h),
          Row(
            children: [
              Text(
                'Unit cost: ',
                style: TextStyle(fontSize: 12.5.sp, color: AppColors.grey),
              ),
              Text(
                _costVisible ? formatCad(_r.unitCost!) : '\$ ••••',
                style: TextStyle(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textDark,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => setState(() => _costVisible = !_costVisible),
                child: Icon(
                  _costVisible
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  size: 19.sp,
                  color: AppColors.grey,
                ),
              ),
            ],
          ),
          SizedBox(height: 10.h),
          Row(
            children: [
              Expanded(child: _marginTile('Original margin', om, orig)),
              SizedBox(width: 8.w),
              Expanded(
                child: _marginTile('Projected margin', pm, req, blue: true),
              ),
            ],
          ),
          SizedBox(height: 10.h),
          StatusPill(
            text:
                '${(pm - om).toStringAsFixed(1)}% margin impact · '
                '${healthy ? 'Above' : 'Below'} 50% threshold',
            icon: healthy
                ? Icons.verified_outlined
                : Icons.warning_amber_rounded,
            fg: healthy ? AppColors.success : AppColorsExtra.amberText,
            bg: healthy ? AppColorsExtra.successSoft : AppColorsExtra.amberSoft,
            border: healthy
                ? AppColorsExtra.successBorder
                : AppColorsExtra.amberBorder,
            fontSize: 11,
          ),
        ],
      ),
    );
  }

  Widget _priceCol(
    String label,
    String value, {
    bool strike = false,
    bool blue = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11.5.sp,
            fontWeight: FontWeight.w600,
            color: blue ? AppColors.primaryBlue : AppColors.grey,
          ),
        ),
        SizedBox(height: 2.h),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            value,
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.w800,
              color: strike ? AppColors.greyLight : AppColors.textDark,
              decoration: strike ? TextDecoration.lineThrough : null,
            ),
          ),
        ),
      ],
    );
  }

  Widget _marginTile(
    String label,
    double pct,
    double price, {
    bool blue = false,
  }) {
    final profit = price - _r.unitCost!;
    return Container(
      padding: EdgeInsets.all(10.w),
      decoration: BoxDecoration(
        color: AppColorsExtra.panelGrey,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColorsExtra.panelBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 11.5.sp, color: AppColors.grey),
          ),
          Text(
            '${pct.toStringAsFixed(1)}%',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.w800,
              color: blue ? AppColors.deepBlue : AppColors.textDark,
            ),
          ),
          Text(
            _costVisible ? '(${formatCad(profit)})' : '',
            style: TextStyle(fontSize: 11.sp, color: AppColors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildAmount() {
    final (fg, bg, border) = _r.type.colors;
    return _box(
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Caption(_r.type.label),
                SizedBox(height: 4.h),
                Text(
                  formatCad(_r.amount),
                  style: TextStyle(
                    fontSize: 24.sp,
                    fontWeight: FontWeight.w800,
                    color: AppColors.deepBlue,
                  ),
                ),
              ],
            ),
          ),
          StatusPill(
            text: _r.saleRef,
            fg: fg,
            bg: bg,
            border: border,
            fontSize: 11,
          ),
        ],
      ),
    );
  }

  Widget _quote(String text) => Container(
    width: double.infinity,
    padding: EdgeInsets.all(12.w),
    decoration: BoxDecoration(
      color: AppColorsExtra.panelGrey,
      borderRadius: BorderRadius.circular(12.r),
      border: const Border(
        left: BorderSide(color: AppColors.deepBlue, width: 3),
      ),
    ),
    child: Text(
      '“$text”',
      style: TextStyle(
        fontSize: 13.sp,
        height: 1.4,
        fontStyle: FontStyle.italic,
        color: AppColors.textDark.withValues(alpha: 0.85),
      ),
    ),
  );

  Widget _buildDecision() {
    final approved = _r.status == ApprovalStatus.approved;
    return _box(
      color: approved ? AppColorsExtra.successSoft : AppColorsExtra.dangerSoft,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            approved ? Icons.check_circle : Icons.cancel,
            size: 20.sp,
            color: approved ? AppColors.success : AppColors.danger,
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${approved ? 'Approved' : 'Rejected'} by Owner · '
                  '${_r.decidedAt == null ? '' : formatWhen(_r.decidedAt!)}',
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark,
                  ),
                ),
                if (_r.decisionNote != null) ...[
                  SizedBox(height: 4.h),
                  Text(
                    _r.decisionNote!,
                    style: TextStyle(
                      fontSize: 12.5.sp,
                      color: AppColors.textDark.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
