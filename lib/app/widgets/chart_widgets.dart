import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../theme/app_colors.dart';
import '../theme/app_colors_extra.dart';

/// Charts shared by Home and Reports, drawn with the app colors so every
/// chart looks the same.

/// Small blue line with a soft fill and a dot on the last point.
class Sparkline extends StatelessWidget {
  const Sparkline({super.key, required this.values, this.height = 56});

  final List<double> values;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height.h,
      width: double.infinity,
      child: CustomPaint(painter: _SparkPainter(values)),
    );
  }
}

class _SparkPainter extends CustomPainter {
  _SparkPainter(this.values);

  final List<double> values;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.length < 2) return;
    final maxV = values.reduce((a, b) => a > b ? a : b);
    final minV = values.reduce((a, b) => a < b ? a : b);
    final span = (maxV - minV) == 0 ? 1 : maxV - minV;
    final dx = size.width / (values.length - 1);
    Offset pt(int i) => Offset(
      i * dx,
      size.height - 4 - (values[i] - minV) / span * (size.height - 10),
    );

    final line = Path()..moveTo(pt(0).dx, pt(0).dy);
    for (var i = 1; i < values.length; i++) {
      final p0 = pt(i - 1);
      final p1 = pt(i);
      final mid = (p0.dx + p1.dx) / 2;
      line.cubicTo(mid, p0.dy, mid, p1.dy, p1.dx, p1.dy);
    }
    final fill = Path.from(line)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    canvas.drawPath(
      fill,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.primaryBlue.withValues(alpha: 0.18),
            AppColors.primaryBlue.withValues(alpha: 0),
          ],
        ).createShader(Offset.zero & size),
    );
    canvas.drawPath(
      line,
      Paint()
        ..color = AppColors.primaryBlue
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2
        ..strokeCap = StrokeCap.round,
    );
    final last = pt(values.length - 1);
    canvas.drawCircle(last, 5, Paint()..color = AppColors.white);
    canvas.drawCircle(
      last,
      5,
      Paint()
        ..color = AppColors.primaryBlue
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(_SparkPainter old) => old.values != values;
}

/// One segment of a [StackedBar].
class BarSegment {
  const BarSegment(this.value, this.color);

  final double value;
  final Color color;
}

/// Single horizontal bar split into colored segments (payment methods).
class StackedBar extends StatelessWidget {
  const StackedBar({super.key, required this.segments, this.height = 12});

  final List<BarSegment> segments;
  final double height;

  @override
  Widget build(BuildContext context) {
    final total = segments.fold<double>(0, (a, s) => a + s.value);
    return ClipRRect(
      borderRadius: BorderRadius.circular(height.r),
      child: SizedBox(
        height: height.h,
        child: total == 0
            ? const ColoredBox(color: AppColorsExtra.progressTrack)
            : Row(
                children: [
                  for (final s in segments)
                    if (s.value > 0)
                      Expanded(
                        flex: (s.value / total * 1000).round().clamp(1, 1000),
                        child: Container(
                          margin: EdgeInsets.only(right: 2.w),
                          color: s.color,
                        ),
                      ),
                ],
              ),
      ),
    );
  }
}

/// Vertical bar chart. Tapping a bar selects it: the selected bar turns
/// primary blue and shows [tooltipOf] above it.
class BarChart extends StatelessWidget {
  const BarChart({
    super.key,
    required this.values,
    required this.labels,
    required this.selected,
    required this.onSelect,
    required this.tooltipOf,
    this.height = 170,
  });

  final List<double> values;
  final List<String> labels;
  final int? selected;
  final ValueChanged<int> onSelect;
  final String Function(int) tooltipOf;
  final double height;

  @override
  Widget build(BuildContext context) {
    final maxV = values.fold<double>(0, (a, b) => b > a ? b : a);
    final n = values.length;
    return SizedBox(
      height: height.h,
      child: LayoutBuilder(
        builder: (context, c) {
          final slot = c.maxWidth / n;
          final barW = (slot * 0.62).clamp(4.0, 34.0);
          final chartH = c.maxHeight - 64.h;
          return Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(
                top: 30.h,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    for (var i = 0; i < n; i++)
                      SizedBox(
                        width: slot,
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () => onSelect(i),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                width: barW,
                                height: maxV == 0
                                    ? 3
                                    : (values[i] / maxV * chartH).clamp(
                                        3.0,
                                        chartH,
                                      ),
                                decoration: BoxDecoration(
                                  color: i == selected
                                      ? AppColors.primaryBlue
                                      : AppColors.lightBlue,
                                  borderRadius: BorderRadius.circular(8.r),
                                ),
                              ),
                              SizedBox(height: 6.h),
                              Text(
                                labels[i],
                                maxLines: 1,
                                overflow: TextOverflow.clip,
                                style: TextStyle(
                                  fontSize: 10.5.sp,
                                  fontWeight: i == selected
                                      ? FontWeight.w800
                                      : FontWeight.w500,
                                  color: i == selected
                                      ? AppColors.primaryBlue
                                      : AppColors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              if (selected != null && selected! < n)
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: Align(
                    alignment: Alignment(
                      n == 1 ? 0 : -1 + 2 * selected! / (n - 1),
                      0,
                    ),
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 10.w,
                        vertical: 5.h,
                      ),
                      decoration: BoxDecoration(
                        color: AppColorsExtra.toastDark,
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Text(
                        tooltipOf(selected!),
                        style: TextStyle(
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w700,
                          color: AppColors.white,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
