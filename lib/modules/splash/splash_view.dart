import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'splash_controller.dart';

class SplashView extends GetView<SplashController> {
  const SplashView({super.key});

  static const _blueDark = Color(0xFF1E5AA8);

  @override
  Widget build(BuildContext context) {
    Get.put(SplashController());

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          const _MeshBackground(),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TweenAnimationBuilder<double>(
                  duration: const Duration(milliseconds: 1600),
                  tween: Tween(begin: 0.9, end: 1.0),
                  curve: Curves.easeOutCubic,
                  builder: (context, value, child) {
                    return Transform.scale(
                      scale: value,
                      child: Opacity(
                        opacity: ((value - 0.9) / 0.1).clamp(0.0, 1.0),
                        child: child,
                      ),
                    );
                  },
                  child: Image.asset(
                    'assets/images/logo.png',
                    width: 300.w,
                    fit: BoxFit.contain,
                    filterQuality: FilterQuality.high,
                    errorBuilder: (context, error, stackTrace) => Text(
                      'SEVA',
                      style: TextStyle(
                        fontSize: 60.sp,
                        fontWeight: FontWeight.w900,
                        color: _blueDark,
                        letterSpacing: 10,
                      ),
                    ),
                  ),
                ),
                // Only shown when there is no internet.
                Obx(
                      () => controller.speed.value == NetSpeed.offline
                      ? Padding(
                    padding: EdgeInsets.only(top: 28.h),
                    child: Column(
                      children: [
                        Text(
                          'No internet connection',
                          style: TextStyle(
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w500,
                            color: _blueDark,
                          ),
                        ),
                        TextButton(
                          onPressed: controller.retry,
                          child: Text(
                            'Retry',
                            style: TextStyle(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w700,
                              color: _blueDark,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Soft mesh-style background: near-white at the top, light sky blue in the
/// middle, deeper blue glowing from the bottom-left corner, and a light cyan
/// glow at the bottom-right.
class _MeshBackground extends StatelessWidget {
  const _MeshBackground();

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Base: white-ish top fading into light blue.
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFFEDF8FE), Color(0xFFD3EFFD), Color(0xFFBFE5FA)],
              stops: [0.0, 0.4, 1.0],
            ),
          ),
        ),
        // Cyan glow on the left side.
        _glow(const Alignment(-1.1, 0.0), 1.0, const Color(0xFF8FD3F4), 0.85),
        // Light cyan glow at the bottom-right.
        _glow(const Alignment(1.1, 1.05), 0.95, const Color(0xFFA9DDF5), 0.9),
        // Deep blue glow from the bottom-left corner.
        _glow(const Alignment(-1.1, 1.1), 1.25, const Color(0xFF4574BA), 1.0),
      ],
    );
  }

  Widget _glow(Alignment center, double radius, Color color, double opacity) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: center,
          radius: radius,
          colors: [
            color.withOpacity(opacity),
            color.withOpacity(opacity * 0.45),
            color.withOpacity(0.0),
          ],
          stops: const [0.0, 0.5, 1.0],
        ),
      ),
    );
  }
}