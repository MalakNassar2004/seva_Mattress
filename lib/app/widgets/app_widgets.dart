import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

/// Shared screen background (Login, PIN, Forgot Password).
/// Near-white base with two soft blue glows measured from the reference:
/// a bigger one in the top-left corner and a lighter one on the right side.
class SoftBackground extends StatelessWidget {
  const SoftBackground({super.key, required this.child});

  final Widget child;

  static const Color _base = AppColors.background; // #F8FAFC-ish base

  /// One circular glow. [cx], [cy], [r] are in a 390px-wide design space and
  /// get scaled to the real screen width.
  Widget _glow({
    required double scale,
    required double cx,
    required double cy,
    required double r,
    required List<Color> colors,
    required List<double> stops,
  }) {
    return Positioned(
      left: (cx - r) * scale,
      top: (cy - r) * scale,
      width: 2 * r * scale,
      height: 2 * r * scale,
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(colors: colors, stops: stops),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final fade = _base.withOpacity(0.0);

    return LayoutBuilder(
      builder: (context, constraints) {
        final scale = constraints.maxWidth / 390;
        return Stack(
          fit: StackFit.expand,
          clipBehavior: Clip.hardEdge,
          children: [
            const ColoredBox(color: Color(0xFFF7F9FB)),
            // Top-left glow (stronger blue, fades out by ~230px).
            _glow(
              scale: scale,
              cx: 60,
              cy: 60,
              r: 235,
              colors: [
                const Color(0xFFE0EAFC),
                const Color(0xFFE2EBFC),
                const Color(0xFFEDF3FC),
                fade,
              ],
              stops: const [0.0, 0.4, 0.75, 1.0],
            ),
            // Right-side glow (lighter, cut by the screen edge).
            _glow(
              scale: scale,
              cx: 335,
              cy: 325,
              r: 165,
              colors: [
                const Color(0xFFEDF2FC),
                const Color(0xFFEEF3FC),
                const Color(0xFFF3F6FB),
                fade,
              ],
              stops: const [0.0, 0.5, 0.8, 1.0],
            ),
            child,
          ],
        );
      },
    );
  }
}

/// The SEVA logo (transparent PNG) with a text fallback.
class AppLogo extends StatelessWidget {
  const AppLogo({super.key, this.width, this.height});

  final double? width;
  final double? height;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/logo.png',
      width: width,
      height: height,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.high,
      errorBuilder: (context, error, stackTrace) => Text(
        'SEVA',
        style: TextStyle(
          fontSize: 28.sp,
          fontWeight: FontWeight.w900,
          color: AppColors.primaryBlue,
          letterSpacing: 6,
        ),
      ),
    );
  }
}

/// White rounded surface with a soft shadow.
class AppCard extends StatelessWidget {
  const AppCard({super.key, required this.child, this.padding, this.radius});

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double? radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding ?? EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(radius ?? 22.r),
        boxShadow: AppShadows.soft,
      ),
      child: child,
    );
  }
}

/// Small white pill (used for the back button and the logo badge).
class WhitePill extends StatelessWidget {
  const WhitePill({super.key, required this.child, this.onTap});

  final Widget child;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(30.r),
      elevation: 0,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(30.r),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30.r),
            boxShadow: AppShadows.small,
          ),
          child: child,
        ),
      ),
    );
  }
}

/// Label row above a field: bold label on the left, optional widget on the right.
class FieldLabel extends StatelessWidget {
  const FieldLabel({super.key, required this.label, this.trailing});

  final String label;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 6.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12.sp,
              fontWeight: FontWeight.w700,
              color: AppColors.textDark,
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

/// Rounded outlined input with a leading icon and an optional trailing widget.
class AppField extends StatelessWidget {
  const AppField({
    super.key,
    required this.controller,
    required this.prefixIcon,
    this.hint,
    this.obscureText = false,
    this.suffix,
    this.keyboardType,
  });

  final TextEditingController controller;
  final IconData prefixIcon;
  final String? hint;
  final bool obscureText;
  final Widget? suffix;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48.h,
      padding: EdgeInsets.symmetric(horizontal: 14.w),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Icon(prefixIcon, size: 20.sp, color: AppColors.grey),
          SizedBox(width: 10.w),
          Expanded(
            child: TextField(
              controller: controller,
              obscureText: obscureText,
              keyboardType: keyboardType,
              style: TextStyle(
                fontSize: 15.sp,
                color: AppColors.textDark,
                letterSpacing: obscureText ? 2 : 0,
              ),
              decoration: InputDecoration(
                isDense: true,
                border: InputBorder.none,
                hintText: hint,
                hintStyle: TextStyle(fontSize: 14.sp, color: AppColors.greyLight),
              ),
            ),
          ),
          if (suffix != null) suffix!,
        ],
      ),
    );
  }
}

/// Main blue button: optional icon on the left, label, arrow badge on the right.
class PrimaryArrowButton extends StatelessWidget {
  const PrimaryArrowButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.leadingIcon,
  });

  final String label;
  final VoidCallback onPressed;
  final IconData? leadingIcon;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56.h,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16.r),
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
        borderRadius: BorderRadius.circular(16.r),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(16.r),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            child: Row(
              children: [
                if (leadingIcon != null) ...[
                  Icon(leadingIcon, size: 22.sp, color: AppColors.white),
                  SizedBox(width: 10.w),
                ],
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w700,
                      color: AppColors.white,
                    ),
                  ),
                ),
                Container(
                  width: 32.w,
                  height: 32.w,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.white.withOpacity(0.2),
                  ),
                  child: Icon(
                    Icons.arrow_forward,
                    size: 18.sp,
                    color: AppColors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Brand lockup: small blue rounded square with the "S" glyph, followed by
/// "SEVA MATTRESS" and the "POINT OF SALE - PREMIUM" tagline.
class BrandBadge extends StatelessWidget {
  const BrandBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 28.w,
          height: 28.w,
          padding: EdgeInsets.all(6.w),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8.r),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF1F87F5), Color(0xFF0A5FC4)],
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryBlue.withOpacity(0.25),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: ColorFiltered(
            colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
            child: Image.asset(
              'assets/images/logo.png',
              fit: BoxFit.contain,
              filterQuality: FilterQuality.high,
              errorBuilder: (context, error, stackTrace) => Center(
                child: Text(
                  'S',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ),
        SizedBox(width: 8.w),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: 'SEVA ',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF12294D),
                    ),
                  ),
                  TextSpan(
                    text: 'MATTRESS',
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF2E86E6),
                    ),
                  ),
                ],
              ),
              style: TextStyle(fontSize: 12.5.sp, height: 1.1),
            ),
            SizedBox(height: 2.h),
            Text(
              'POINT OF SALE · PREMIUM',
              style: TextStyle(
                fontSize: 5.5.sp,
                letterSpacing: 1.4,
                fontWeight: FontWeight.w700,
                color: AppColors.greyLight,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Face ID style glyph: corner brackets, eyes, nose and smile.
class FaceIdIcon extends StatelessWidget {
  const FaceIdIcon({super.key, this.size = 24, this.color = AppColors.deepBlue});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.square(size),
      painter: _FaceIdPainter(color),
    );
  }
}

class _FaceIdPainter extends CustomPainter {
  _FaceIdPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = w * 0.075;

    final m = w * 0.08; // margin
    final l = w * 0.26; // bracket length
    final r = w * 0.12; // corner radius
    final e = w - m;

    // Four corner brackets.
    canvas.drawPath(
      Path()
        ..moveTo(m, m + l)
        ..lineTo(m, m + r)
        ..quadraticBezierTo(m, m, m + r, m)
        ..lineTo(m + l, m),
      paint,
    );
    canvas.drawPath(
      Path()
        ..moveTo(e - l, m)
        ..lineTo(e - r, m)
        ..quadraticBezierTo(e, m, e, m + r)
        ..lineTo(e, m + l),
      paint,
    );
    canvas.drawPath(
      Path()
        ..moveTo(m, e - l)
        ..lineTo(m, e - r)
        ..quadraticBezierTo(m, e, m + r, e)
        ..lineTo(m + l, e),
      paint,
    );
    canvas.drawPath(
      Path()
        ..moveTo(e - l, e)
        ..lineTo(e - r, e)
        ..quadraticBezierTo(e, e, e, e - r)
        ..lineTo(e, e - l),
      paint,
    );

    // Eyes.
    canvas.drawLine(Offset(w * 0.36, w * 0.38), Offset(w * 0.36, w * 0.45), paint);
    canvas.drawLine(Offset(w * 0.64, w * 0.38), Offset(w * 0.64, w * 0.45), paint);

    // Nose.
    canvas.drawPath(
      Path()
        ..moveTo(w * 0.5, w * 0.38)
        ..lineTo(w * 0.5, w * 0.55)
        ..quadraticBezierTo(w * 0.5, w * 0.59, w * 0.45, w * 0.58),
      paint,
    );

    // Smile.
    canvas.drawPath(
      Path()
        ..moveTo(w * 0.36, w * 0.67)
        ..quadraticBezierTo(w * 0.5, w * 0.77, w * 0.64, w * 0.67),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _FaceIdPainter old) => old.color != color;
}