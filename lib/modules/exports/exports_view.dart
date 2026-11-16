import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_colors_extra.dart';
import '../../app/theme/app_theme.dart';
import '../../app/utils/dates.dart';
import '../../app/widgets/app_widgets.dart';
import '../../app/widgets/owner_bottom_nav.dart';
import '../../app/widgets/owner_widgets.dart';
import '../../app/widgets/page_widgets.dart';
import '../../app/widgets/shared_widgets.dart';
import '../owner_shell/owner_shell_controller.dart';
import 'export_models.dart';
import 'exports_controller.dart';

/// Data Exports (owner). Opened from the More tab.
class ExportsView extends GetView<ExportsController> {
  const ExportsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SoftBackground(
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 16.h),
                  children: [
                    _buildHeader(),
                    SizedBox(height: 14.h),
                    Obx(_buildBuilderCard),
                    SizedBox(height: 22.h),
                    Obx(_buildHistory),
                    SizedBox(height: 4.h),
                    const AuditNote(
                      'Every export is recorded in the audit log',
                    ),
                  ],
                ),
              ),
              OwnerBottomNav(
                currentIndex: OwnerShellController.moreTab,
                moreBadge: OwnerShellController.moreBadge,
                onTap: controller.onNavTap,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------- Header ----------------
  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            BackPill(label: 'More', onTap: controller.onBackPressed),
            SizedBox(width: 8.w),
            const Spacer(),
            const StatusPill(
              text: 'PCI-DSS L1',
              icon: Icons.lock,
              fg: AppColors.deepBlue,
              bg: AppColors.white,
              border: AppColors.border,
              fontSize: 11,
            ),
          ],
        ),
        SizedBox(height: 14.h),
        const PageTitle(
          title: 'Exports',
          subtitle: 'Store reports & ledger backups · CAD',
          trailing: StatusPill(
            text: 'OWNER PRIVILEGE',
            icon: Icons.verified_user_outlined,
            fg: AppColorsExtra.amberText,
            bg: AppColorsExtra.amberSoft,
            border: AppColorsExtra.amberBorder,
            fontSize: 10.5,
            letterSpacing: 0.4,
          ),
        ),
      ],
    );
  }

  // ---------------- Builder ----------------
  Widget _buildBuilderCard() {
    final ds = controller.dataset.value;
    final fmt = controller.format.value;
    final range = controller.range.value;
    final busy = controller.generating.value;

    Widget step(String text, {Widget? trailing}) => Padding(
      padding: EdgeInsets.only(bottom: 10.h),
      child: Row(
        children: [
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 15.sp,
                fontWeight: FontWeight.w800,
                color: AppColors.textDark,
              ),
            ),
          ),
          ?trailing,
        ],
      ),
    );

    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          step('1. Dataset'),
          for (final d in ExportDataset.values) ...[
            SelectCard(
              icon: d.icon,
              title: d.label,
              subtitle: d.subtitle,
              selected: d == ds,
              onTap: () => controller.selectDataset(d),
            ),
            SizedBox(height: 8.h),
          ],
          SizedBox(height: 8.h),
          const Divider(color: AppColorsExtra.panelBorder),
          SizedBox(height: 14.h),
          step('2. Format'),
          Row(
            children: [
              for (final f in ExportFormat.values) ...[
                if (f != ExportFormat.values.first) SizedBox(width: 8.w),
                Expanded(
                  child: _FormatTile(
                    format: f,
                    selected: f == fmt,
                    onTap: () => controller.selectFormat(f),
                  ),
                ),
              ],
            ],
          ),
          SizedBox(height: 18.h),
          step('3. Date range'),
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
            decoration: BoxDecoration(
              color: AppColorsExtra.panelGrey,
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(color: AppColorsExtra.panelBorder),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.calendar_today_outlined,
                  size: 17.sp,
                  color: AppColors.primaryBlue,
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: Text(
                    controller.rangeText,
                    style: TextStyle(
                      fontSize: 13.5.sp,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textDark,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 10.h),
          Wrap(
            spacing: 8.w,
            runSpacing: 8.h,
            children: [
              for (final r in ExportRange.values)
                ChoicePill(
                  label: r.label,
                  icon: r == ExportRange.custom ? Icons.edit_calendar : null,
                  selected: r == range,
                  onTap: () => controller.selectRange(r),
                ),
            ],
          ),
          if (ds.sensitive) ...[
            SizedBox(height: 14.h),
            const WarningNote(
              'Includes sensitive financial or customer information. '
              'This export is recorded in the audit log.',
            ),
          ],
          SizedBox(height: 16.h),
          Opacity(
            opacity: busy ? 0.6 : 1,
            child: PrimaryArrowButton(
              label: busy ? 'Generating…' : 'Generate export',
              leadingIcon: Icons.download_outlined,
              onPressed: controller.onGenerate,
            ),
          ),
        ],
      ),
    );
  }

  // ---------------- History ----------------
  Widget _buildHistory() {
    final list = controller.history;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeading('Export history (${list.length})'),
        for (final r in list)
          Padding(
            padding: EdgeInsets.only(bottom: 12.h),
            child: _HistoryCard(record: r),
          ),
      ],
    );
  }
}

class _FormatTile extends StatelessWidget {
  const _FormatTile({
    required this.format,
    required this.selected,
    required this.onTap,
  });

  final ExportFormat format;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final fg = selected ? AppColors.white : AppColors.textDark;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: EdgeInsets.symmetric(vertical: 12.h),
        decoration: BoxDecoration(
          color: selected ? AppColors.primaryBlue : AppColorsExtra.panelGrey,
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(
            color: selected
                ? AppColors.primaryBlue
                : AppColorsExtra.panelBorder,
          ),
          boxShadow: selected ? AppShadows.small : null,
        ),
        child: Column(
          children: [
            Icon(format.icon, size: 22.sp, color: fg),
            SizedBox(height: 4.h),
            Text(
              format.label,
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w800,
                color: fg,
              ),
            ),
            Text(
              format.subtitle,
              style: TextStyle(
                fontSize: 10.5.sp,
                color: selected
                    ? AppColors.white.withValues(alpha: 0.8)
                    : AppColors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  const _HistoryCard({required this.record});

  final ExportRecord record;

  @override
  Widget build(BuildContext context) {
    final r = record;
    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadows.small,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconBox(r.format.icon, size: 40),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  r.fileName,
                  style: TextStyle(
                    fontSize: 14.5.sp,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textDark,
                  ),
                ),
                SizedBox(height: 4.h),
                _line(Icons.person_outline, '${r.by} (${r.role})'),
                _line(Icons.devices_outlined, r.device),
                _line(
                  Icons.schedule,
                  '${formatWhen(r.time)} · ${r.size} · ${r.records} records',
                ),
              ],
            ),
          ),
          SizedBox(width: 8.w),
          StatusPill(
            text: r.format.label,
            fg: AppColors.deepBlue,
            bg: AppColors.lightBlue,
            fontSize: 10.5,
          ),
        ],
      ),
    );
  }

  Widget _line(IconData icon, String text) => Padding(
    padding: EdgeInsets.only(top: 3.h),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(top: 1.h),
          child: Icon(icon, size: 13.sp, color: AppColors.grey),
        ),
        SizedBox(width: 5.w),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 12.sp,
              height: 1.3,
              color: AppColors.textDark.withValues(alpha: 0.7),
            ),
          ),
        ),
      ],
    ),
  );
}
