import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_colors_extra.dart';
import '../../app/utils/dates.dart';
import '../../app/widgets/owner_widgets.dart';
import '../../app/widgets/shared_widgets.dart';
import 'audit_models.dart';
import 'audit_widgets.dart';

/// Bottom sheet: details of one audit event (device, network, location).
/// Read-only, so it has no controller.
class AuditEventSheet extends StatelessWidget {
  const AuditEventSheet({super.key, required this.event});

  final AuditEvent event;

  static Future<void> open(AuditEvent event) => Get.bottomSheet<void>(
    AuditEventSheet(event: event),
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black54,
  );

  @override
  Widget build(BuildContext context) {
    final e = event;
    return SheetFrame(
      footer: SizedBox(
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
              Flexible(
                child: StatusPill(
                  text: 'READ-ONLY AUDIT EVENT · #${e.id}',
                  icon: Icons.lock,
                  fg: AppColors.deepBlue,
                  bg: AppColors.lightBlue,
                  fontSize: 10.5,
                  letterSpacing: 0.4,
                ),
              ),
              SizedBox(width: 8.w),
              const Spacer(),
              SheetCloseButton(onTap: Get.back),
            ],
          ),
          SizedBox(height: 12.h),
          Text(
            'Event Details',
            style: TextStyle(
              fontSize: 22.sp,
              fontWeight: FontWeight.w800,
              color: AppColors.textDark,
              letterSpacing: -0.3,
            ),
          ),
          SizedBox(height: 2.h),
          Text(
            'Recorded at ${e.location}',
            style: TextStyle(fontSize: 12.5.sp, color: AppColors.grey),
          ),
          SizedBox(height: 14.h),
          _buildPrimary(),
          SizedBox(height: 12.h),
          _buildDevice(),
          if (e.note != null) ...[SizedBox(height: 12.h), _buildNote()],
          SizedBox(height: 14.h),
          const AuditNote(
            'Immutable record · Cannot be modified or deleted',
            icon: Icons.verified_user_outlined,
          ),
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

  Widget _buildPrimary() {
    final e = event;
    return _box(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Caption('Primary event'),
          SizedBox(height: 6.h),
          Text(
            e.sentence,
            style: TextStyle(
              fontSize: 17.sp,
              fontWeight: FontWeight.w800,
              height: 1.3,
              color: AppColors.textDark,
            ),
          ),
          if (e.newValue != null) ...[
            SizedBox(height: 10.h),
            AuditValueChip(event: e),
          ],
          SizedBox(height: 12.h),
          const Divider(color: AppColorsExtra.panelBorder),
          SizedBox(height: 12.h),
          Row(
            children: [
              AuditAvatar(event: e, size: 40),
              SizedBox(width: 10.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${e.actor} · ${e.actorRole}',
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textDark,
                      ),
                    ),
                    if (e.employeeId != null)
                      Text(
                        'Employee #${e.employeeId}',
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: AppColors.grey,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 10.h),
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 9.h),
            decoration: BoxDecoration(
              color: AppColorsExtra.panelGrey,
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Row(
              children: [
                Icon(Icons.schedule, size: 16.sp, color: AppColors.primaryBlue),
                SizedBox(width: 8.w),
                Expanded(
                  child: Text(
                    formatFull(e.time),
                    style: TextStyle(
                      fontSize: 12.5.sp,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textDark,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDevice() {
    final e = event;
    return _box(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CardTitle(
            icon: Icons.verified_user_outlined,
            title: 'Device & Location',
          ),
          SizedBox(height: 6.h),
          _detail(Icons.tablet_mac_outlined, 'Device', e.device),
          _detail(Icons.lan_outlined, 'Network', e.network),
          _detail(
            Icons.place_outlined,
            'Location',
            '${e.location}\n${e.address}',
          ),
          _detail(
            Icons.fingerprint,
            'Authorization',
            e.authorization,
            valueColor: AppColors.primaryBlue,
          ),
          _detail(
            Icons.tag,
            'Ledger hash',
            e.hash,
            trailing: GestureDetector(
              onTap: () async {
                await Clipboard.setData(ClipboardData(text: e.hash));
                showDarkToast('Hash copied');
              },
              child: Padding(
                padding: EdgeInsets.only(left: 6.w),
                child: Icon(
                  Icons.copy_rounded,
                  size: 16.sp,
                  color: AppColors.grey,
                ),
              ),
            ),
            mono: true,
          ),
        ],
      ),
    );
  }

  Widget _detail(
    IconData icon,
    String label,
    String value, {
    Color valueColor = AppColors.textDark,
    Widget? trailing,
    bool mono = false,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 10.h),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColorsExtra.panelBorder)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 17.sp, color: AppColors.grey),
          SizedBox(width: 8.w),
          SizedBox(
            width: 92.w,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12.5.sp,
                fontWeight: FontWeight.w600,
                color: AppColors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 12.5.sp,
                height: 1.35,
                fontWeight: FontWeight.w700,
                fontFamily: mono ? 'monospace' : null,
                color: valueColor,
              ),
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }

  Widget _buildNote() {
    return _box(
      color: AppColorsExtra.panelGrey,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.notes, size: 18.sp, color: AppColors.grey),
          SizedBox(width: 10.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Caption('Notes'),
                SizedBox(height: 4.h),
                Text(
                  event.note!,
                  style: TextStyle(
                    fontSize: 12.5.sp,
                    height: 1.4,
                    color: AppColors.textDark.withValues(alpha: 0.85),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
