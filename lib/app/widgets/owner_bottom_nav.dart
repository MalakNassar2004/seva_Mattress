import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

/// Floating bottom navigation used by all Owner screens.
/// Tabs: Home, Orders, Inventory, Reports, More.
class OwnerBottomNav extends StatelessWidget {
  const OwnerBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.moreBadge = 0,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;

  /// Pending approvals count shown on the More tab (0 hides the badge).
  final int moreBadge;

  static const List<(IconData, String)> _items = [
    (Icons.storefront_outlined, 'Home'),
    (Icons.receipt_long_outlined, 'Orders'),
    (Icons.inventory_2_outlined, 'Inventory'),
    (Icons.bar_chart_rounded, 'Reports'),
    (Icons.more_horiz, 'More'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.fromLTRB(16.w, 0, 16.w, 8.h),
      padding: EdgeInsets.all(6.w),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(24.r),
        boxShadow: AppShadows.soft,
      ),
      child: Row(
        children: List.generate(_items.length, (i) {
          final active = i == currentIndex;
          final item = _items[i];
          final showBadge = i == 4 && moreBadge > 0;
          return Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => onTap(i),
              child: Container(
                height: 52.h,
                decoration: BoxDecoration(
                  color: active ? AppColors.lightBlue : Colors.transparent,
                  borderRadius: BorderRadius.circular(18.r),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Icon(
                          item.$1,
                          size: 22.sp,
                          color: active ? AppColors.deepBlue : AppColors.grey,
                        ),
                        if (showBadge)
                          Positioned(
                            right: -8.w,
                            top: -4.h,
                            child: Container(
                              width: 14.w,
                              height: 14.w,
                              alignment: Alignment.center,
                              decoration: const BoxDecoration(
                                color: AppColors.danger,
                                shape: BoxShape.circle,
                              ),
                              child: Text(
                                '$moreBadge',
                                style: TextStyle(
                                  fontSize: 9.sp,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      item.$2,
                      style: TextStyle(
                        fontSize: 10.5.sp,
                        fontWeight: active ? FontWeight.w800 : FontWeight.w500,
                        color: active ? AppColors.deepBlue : AppColors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
