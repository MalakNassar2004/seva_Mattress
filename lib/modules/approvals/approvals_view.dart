import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_colors_extra.dart';
import '../../app/theme/app_theme.dart';
import '../../app/utils/dates.dart';
import '../../app/utils/money.dart';
import '../../app/widgets/app_widgets.dart';
import '../../app/widgets/owner_bottom_nav.dart';
import '../../app/widgets/owner_widgets.dart';
import '../../app/widgets/page_widgets.dart';
import '../../app/widgets/shared_widgets.dart';
import '../owner_shell/owner_shell_controller.dart';
import 'approval_models.dart';
import 'approvals_controller.dart';

/// Approvals & Overrides (owner).
class ApprovalsView extends GetView<ApprovalsController> {
  const ApprovalsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SoftBackground(
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              Expanded(
                child: Obx(() {
                  controller.store.requests.length;
                  final list = controller.visible;
                  return ListView(
                    padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 16.h),
                    children: [
                      _buildHeader(),
                      SizedBox(height: 14.h),
                      SegmentedTabs(
                        labels: [
                          'Pending (${controller.countFor(ApprovalStatus.pending)})',
                          'Approved (${controller.countFor(ApprovalStatus.approved)})',
                          'Rejected (${controller.countFor(ApprovalStatus.rejected)})',
                        ],
                        selectedIndex: controller.tab.value,
                        onChanged: controller.selectTab,
                      ),
                      SizedBox(height: 12.h),
                      const AuditNote(
                        'All approval decisions are logged with your name and time',
                      ),
                      SizedBox(height: 12.h),
                      if (list.isEmpty)
                        SectionCard(
                          child: EmptyState(
                            icon: Icons.task_alt,
                            message: switch (controller.status) {
                              ApprovalStatus.pending =>
                                'All caught up. No pending approvals.',
                              ApprovalStatus.approved =>
                                'No approved requests yet.',
                              ApprovalStatus.rejected =>
                                'No rejected requests.',
                            },
                          ),
                        ),
                      for (final r in list)
                        Padding(
                          padding: EdgeInsets.only(bottom: 12.h),
                          child: _RequestCard(
                            request: r,
                            onTap: () => controller.onOpen(r),
                            onApprove: () => controller.onApprove(r),
                            onReject: () => controller.onReject(r),
                          ),
                        ),
                    ],
                  );
                }),
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

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            BackPill(label: 'Back', onTap: controller.onBackPressed),
            SizedBox(width: 8.w),
            const Spacer(),
            const StatusPill(
              text: 'CAD (\$)',
              fg: AppColors.deepBlue,
              bg: AppColors.lightBlue,
              fontSize: 12,
            ),
          ],
        ),
        SizedBox(height: 14.h),
        const PageTitle(
          title: 'Approvals & Overrides',
          subtitle: 'Surrey Flagship · Owner clearance',
        ),
      ],
    );
  }
}

class _RequestCard extends StatelessWidget {
  const _RequestCard({
    required this.request,
    required this.onTap,
    required this.onApprove,
    required this.onReject,
  });

  final ApprovalRequest request;
  final VoidCallback onTap;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  @override
  Widget build(BuildContext context) {
    final r = request;
    final (fg, bg, border) = r.type.colors;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(14.w),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(color: AppColors.border),
          boxShadow: AppShadows.small,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Flexible(
                  child: StatusPill(
                    text: r.type.label,
                    icon: r.type.icon,
                    fg: fg,
                    bg: bg,
                    border: border,
                    fontSize: 11,
                  ),
                ),
                SizedBox(width: 6.w),
                Text(
                  formatCad(r.amount),
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textDark,
                  ),
                ),
                const Spacer(),
                Text(
                  formatAgo(r.time),
                  style: TextStyle(fontSize: 11.5.sp, color: AppColors.grey),
                ),
              ],
            ),
            SizedBox(height: 12.h),
            Row(
              children: [
                InitialsAvatar(initials: r.initials, size: 38),
                SizedBox(width: 10.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${r.requester} · ${r.role}',
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textDark,
                        ),
                      ),
                      Text(
                        r.terminal,
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: AppColors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  r.saleRef,
                  style: TextStyle(
                    fontSize: 12.5.sp,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryBlue,
                  ),
                ),
              ],
            ),
            SizedBox(height: 10.h),
            const Divider(color: AppColorsExtra.panelBorder),
            SizedBox(height: 10.h),
            if (r.isPriceChange) _priceBox(r) else _itemBox(r),
            SizedBox(height: 10.h),
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(10.w),
              decoration: BoxDecoration(
                color: AppColorsExtra.panelGrey,
                borderRadius: BorderRadius.circular(10.r),
                border: const Border(
                  left: BorderSide(color: AppColors.deepBlue, width: 3),
                ),
              ),
              child: Text(
                '“${r.reason}”',
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12.5.sp,
                  height: 1.4,
                  fontStyle: FontStyle.italic,
                  color: AppColors.textDark.withValues(alpha: 0.8),
                ),
              ),
            ),
            SizedBox(height: 12.h),
            if (r.status == ApprovalStatus.pending)
              Row(
                children: [
                  Expanded(
                    child: SoftButton(
                      label: 'Reject',
                      icon: Icons.close,
                      height: 46,
                      radius: 14,
                      fontSize: 14,
                      fg: AppColors.danger,
                      borderColor: AppColorsExtra.dangerBorder,
                      onTap: onReject,
                    ),
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: SoftButton(
                      label: 'Approve',
                      icon: Icons.check,
                      filled: true,
                      height: 46,
                      radius: 14,
                      fontSize: 14,
                      onTap: onApprove,
                    ),
                  ),
                ],
              )
            else
              _decision(r),
          ],
        ),
      ),
    );
  }

  Widget _itemBox(ApprovalRequest r) => Container(
    width: double.infinity,
    padding: EdgeInsets.all(10.w),
    decoration: BoxDecoration(
      color: AppColorsExtra.panelGrey,
      borderRadius: BorderRadius.circular(10.r),
    ),
    child: Row(
      children: [
        Icon(Icons.bed_outlined, size: 17.sp, color: AppColors.grey),
        SizedBox(width: 8.w),
        Expanded(
          child: Text(
            r.item,
            style: TextStyle(
              fontSize: 13.5.sp,
              fontWeight: FontWeight.w600,
              color: AppColors.textDark,
            ),
          ),
        ),
      ],
    ),
  );

  Widget _priceBox(ApprovalRequest r) {
    final om = r.originalMargin!;
    final pm = r.projectedMargin!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          r.item,
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.w800,
            color: AppColors.textDark,
          ),
        ),
        SizedBox(height: 8.h),
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(10.w),
          decoration: BoxDecoration(
            color: AppColorsExtra.panelGrey,
            borderRadius: BorderRadius.circular(10.r),
          ),
          child: Wrap(
            spacing: 8.w,
            runSpacing: 6.h,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                formatCad(r.originalPrice!),
                style: TextStyle(
                  fontSize: 13.5.sp,
                  color: AppColors.greyLight,
                  decoration: TextDecoration.lineThrough,
                ),
              ),
              Icon(Icons.arrow_forward, size: 14.sp, color: AppColors.grey),
              Text(
                formatCad(r.requestedPrice!),
                style: TextStyle(
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w800,
                  color: AppColors.deepBlue,
                ),
              ),
              StatusPill(
                text:
                    'Margin ${om.toStringAsFixed(0)}% → '
                    '${pm.toStringAsFixed(0)}% '
                    '(${(pm - om).toStringAsFixed(1)}%)',
                fg: AppColors.danger,
                bg: AppColorsExtra.dangerSoft,
                fontSize: 10.5,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _decision(ApprovalRequest r) {
    final approved = r.status == ApprovalStatus.approved;
    return Row(
      children: [
        Icon(
          approved ? Icons.check_circle : Icons.cancel,
          size: 17.sp,
          color: approved ? AppColors.success : AppColors.danger,
        ),
        SizedBox(width: 6.w),
        Expanded(
          child: Text(
            '${approved ? 'Approved' : 'Rejected'} by Owner'
            '${r.decidedAt == null ? '' : ' · ${formatAgo(r.decidedAt!)}'}'
            '${r.decisionNote == null ? '' : ' · ${r.decisionNote}'}',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12.5.sp,
              fontWeight: FontWeight.w600,
              color: AppColors.textDark.withValues(alpha: 0.8),
            ),
          ),
        ),
      ],
    );
  }
}
