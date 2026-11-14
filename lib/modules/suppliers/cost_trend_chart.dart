import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../app/theme/app_colors.dart';
import 'supplier_models.dart';

/// Small single-series bar chart of monthly unit cost.
/// One hue: past months in light blue, the selected month in primary blue
/// with its value labeled above. A month without purchases is left empty.
/// Tap a bar to see its value.
class CostTrendChart extends StatelessWidget {
  const CostTrendChart({
    super.key,
    required this.points,
    required this.selected,
    required this.onSelect,
    this.height = 96,
  });

  final List<CostPoint> points;
  final int selected;
  final ValueChanged<int> onSelect;
  final double height;

  @override
  Widget build(BuildContext context) {
    final values = points.map((p) => p.value).whereType<double>();
    if (values.isEmpty) return const SizedBox.shrink();
    final max = values.reduce((a, b) => a > b ? a : b);
    final min = values.reduce((a, b) => a < b ? a : b);
    // Bars start a bit under the lowest month so small changes stay visible,
    // the same way the design shows them.
    final floor = (min - (max - min) * 1.5).clamp(0, min * 0.9).toDouble();

    return Column(
      children: [
        SizedBox(
          height: height.h + 22.h,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(points.length, (i) {
              final p = points[i];
              final active = i == selected;
              final ratio = p.value == null
                  ? 0.0
                  : ((p.value! - floor) / (max - floor)).clamp(0.12, 1.0);
              return Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => onSelect(i),
                  child: Padding(
                    // 2px+ surface gap between bars.
                    padding: EdgeInsets.symmetric(horizontal: 3.w),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (active && p.value != null)
                          Container(
                            margin: EdgeInsets.only(bottom: 4.h),
                            padding: EdgeInsets.symmetric(
                                horizontal: 5.w, vertical: 2.h),
                            decoration: BoxDecoration(
                              color: AppColors.deepBlue,
                              borderRadius: BorderRadius.circular(4.r),
                            ),
                            child: FittedBox(
                              child: Text(
                                '\$${p.value!.toStringAsFixed(2)}',
                                style: TextStyle(
                                  fontSize: 9.5.sp,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.white,
                                ),
                              ),
                            ),
                          ),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          height: height.h * ratio,
                          decoration: BoxDecoration(
                            color: p.value == null
                                ? Colors.transparent
                                : (active
                                    ? AppColors.primaryBlue
                                    : AppColors.glowBlue),
                            borderRadius: BorderRadius.vertical(
                              top: Radius.circular(4.r),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
        Container(height: 1, color: AppColors.border),
        SizedBox(height: 6.h),
        Row(
          children: List.generate(points.length, (i) {
            final active = i == selected;
            return Expanded(
              child: Text(
                points[i].month,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 10.5.sp,
                  fontWeight: active ? FontWeight.w800 : FontWeight.w600,
                  color: active ? AppColors.textDark : AppColors.grey,
                ),
              ),
            );
          }),
        ),
      ],
    );
  }
}
