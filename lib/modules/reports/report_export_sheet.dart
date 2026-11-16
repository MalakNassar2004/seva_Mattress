import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../app/theme/app_colors.dart';
import '../../app/widgets/app_widgets.dart';
import '../../app/widgets/page_widgets.dart';
import '../../app/widgets/shared_widgets.dart';
import '../audit/audit_models.dart';
import '../audit/audit_store.dart';
import '../exports/export_models.dart';

/// Bottom sheet: export the current report as PDF, CSV or Excel.
class ReportExportSheet extends StatefulWidget {
  const ReportExportSheet({
    super.key,
    required this.title,
    required this.periodText,
  });

  final String title;
  final String periodText;

  static Future<void> open({
    required String title,
    required String periodText,
  }) => Get.bottomSheet<void>(
    ReportExportSheet(title: title, periodText: periodText),
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black54,
  );

  @override
  State<ReportExportSheet> createState() => _ReportExportSheetState();
}

class _ReportExportSheetState extends State<ReportExportSheet> {
  ExportFormat _format = ExportFormat.pdf;

  void _export() {
    // TODO(backend): POST /reports/export and download the file.
    AuditStore.to.record(
      action: AuditAction.export,
      sentence: 'Exported ${widget.title}',
      newValue: '${_format.label} · ${widget.periodText}',
    );
    Get.back();
    showDarkToast('${widget.title} exported as ${_format.label}');
  }

  @override
  Widget build(BuildContext context) {
    return SheetFrame(
      footer: PrimaryArrowButton(
        label: 'Export ${_format.label}',
        leadingIcon: Icons.download_outlined,
        onPressed: _export,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Export report',
                  style: TextStyle(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textDark,
                  ),
                ),
              ),
              SheetCloseButton(onTap: Get.back),
            ],
          ),
          SizedBox(height: 4.h),
          Text(
            '${widget.title} · ${widget.periodText}',
            style: TextStyle(fontSize: 12.5.sp, color: AppColors.grey),
          ),
          SizedBox(height: 14.h),
          for (final f in ExportFormat.values) ...[
            SelectCard(
              icon: f.icon,
              title: f.label,
              subtitle: f.subtitle,
              selected: f == _format,
              onTap: () => setState(() => _format = f),
            ),
            SizedBox(height: 8.h),
          ],
          SizedBox(height: 6.h),
          const InfoBanner(
            icon: Icons.shield_outlined,
            child: Text(
              'This export will be recorded in the audit log with your name '
              'and time.',
            ),
          ),
          SizedBox(height: 4.h),
        ],
      ),
    );
  }
}
