import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../app/theme/app_colors.dart';
import '../../app/widgets/shared_widgets.dart';
import 'audit_models.dart';

/// "old → new" chip colored by the action type. Shows only the new value
/// (with the action icon) when there is no old value.
class AuditValueChip extends StatelessWidget {
  const AuditValueChip({super.key, required this.event});

  final AuditEvent event;

  @override
  Widget build(BuildContext context) {
    final e = event;
    final (fg, bg, border) = e.action.chipColors;
    final style = TextStyle(
      fontSize: 11.5.sp,
      fontWeight: FontWeight.w700,
      color: fg,
    );
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 9.w, vertical: 5.h),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: border),
      ),
      child: Text.rich(
        TextSpan(
          children: [
            if (e.oldValue != null) ...[
              TextSpan(text: e.oldValue),
              WidgetSpan(
                alignment: PlaceholderAlignment.middle,
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 5.w),
                  child: Icon(Icons.arrow_forward, size: 13.sp, color: fg),
                ),
              ),
            ] else
              WidgetSpan(
                alignment: PlaceholderAlignment.middle,
                child: Padding(
                  padding: EdgeInsets.only(right: 5.w),
                  child: Icon(e.action.icon, size: 13.sp, color: fg),
                ),
              ),
            TextSpan(text: e.newValue),
          ],
        ),
        style: style,
      ),
    );
  }
}

/// Avatar of the person who did the action. The owner gets a solid
/// dark-blue avatar so owner actions stand out.
class AuditAvatar extends StatelessWidget {
  const AuditAvatar({super.key, required this.event, this.size = 42});

  final AuditEvent event;
  final double size;

  @override
  Widget build(BuildContext context) {
    return InitialsAvatar(
      initials: event.actorInitials,
      size: size,
      bg: event.isOwner ? AppColors.deepBlue : AppColors.lightBlue,
      fg: event.isOwner ? AppColors.white : AppColors.deepBlue,
    );
  }
}
