import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_colors_extra.dart';
import '../../app/utils/money.dart';
import '../../app/widgets/owner_widgets.dart';
import '../../app/widgets/shared_widgets.dart';
import 'order_models.dart';

/// Status chip for an order (dot for In Production, icon for the others).
class OrderStatusChip extends StatelessWidget {
  const OrderStatusChip({super.key, required this.status, this.long = true});

  final OrderStatus status;
  final bool long;

  @override
  Widget build(BuildContext context) {
    return StatusPill(
      text: long ? status.cardLabel : status.label,
      fg: status.fg,
      bg: status.bg,
      border: status.border,
      icon: status.icon,
      dot: status.icon == null,
      fontSize: 12,
    );
  }
}

/// "Custom Build" badge.
class CustomBadge extends StatelessWidget {
  const CustomBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return const StatusPill(
      text: 'Custom Build',
      fg: AppColors.primaryBlue,
      bg: AppColors.lightBlue,
      border: AppColorsExtra.infoBorder,
      icon: Icons.build,
      fontSize: 12,
    );
  }
}

/// Grey panel with "Paid $X of $Y CAD", a progress bar and the balance.
class PaidProgressPanel extends StatelessWidget {
  const PaidProgressPanel({
    super.key,
    required this.total,
    required this.paid,
  });

  final double total;
  final double paid;

  @override
  Widget build(BuildContext context) {
    final balance = (total - paid).clamp(0, double.infinity).toDouble();
    final full = balance <= 0.004;
    final ratio = total == 0 ? 0.0 : (paid / total).clamp(0.0, 1.0);
    final pct = (ratio * 100).round();
    final base = TextStyle(fontSize: 13.sp, color: AppColors.textDark);

    return Container(
      padding: EdgeInsets.fromLTRB(14.w, 12.h, 14.w, 12.h),
      decoration: BoxDecoration(
        color: AppColorsExtra.panelGrey,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: AppColorsExtra.panelBorder),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text.rich(
                  full
                      ? TextSpan(children: [
                          const TextSpan(text: 'Paid in Full · '),
                          TextSpan(
                            text: '${formatCad(total)} CAD',
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                        ])
                      : TextSpan(children: [
                          const TextSpan(text: 'Paid '),
                          TextSpan(
                            text: formatCad(paid),
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                          TextSpan(text: ' of ${formatCad(total)} CAD'),
                        ]),
                  style: base.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
              if (full) ...[
                Icon(Icons.check_circle_outline,
                    size: 15.sp, color: AppColors.success),
                SizedBox(width: 3.w),
              ],
              Text(
                '$pct%',
                style: TextStyle(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w800,
                  color: full ? AppColors.success : AppColors.primaryBlue,
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          ProgressBar(
            value: ratio,
            color: full ? AppColors.success : AppColors.primaryBlue,
          ),
          SizedBox(height: 12.h),
          Row(
            children: [
              Expanded(
                child: Text(
                  full ? 'Balance:' : 'Balance owing:',
                  style: base.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              Text(
                '${formatCad(balance)} CAD',
                style: TextStyle(
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w800,
                  color: full ? AppColors.success : AppColorsExtra.amberText,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
