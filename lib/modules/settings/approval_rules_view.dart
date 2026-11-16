import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../app/theme/app_colors.dart';
import '../../app/utils/money.dart';
import '../../app/widgets/app_widgets.dart';
import '../../app/widgets/owner_widgets.dart';
import '../../app/widgets/page_widgets.dart';
import '../../app/widgets/shared_widgets.dart';
import 'approval_rules_controller.dart';

/// Settings › Approval rules.
class ApprovalRulesView extends GetView<ApprovalRulesController> {
  const ApprovalRulesView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SoftBackground(
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 16.h),
                  children: [
                    _buildHeader(),
                    SizedBox(height: 14.h),
                    InfoBanner(
                      icon: Icons.shield_outlined,
                      child: Text.rich(
                        TextSpan(
                          children: [
                            const TextSpan(
                              text:
                                  'Rules apply instantly on every register. '
                                  'Actions over a limit trigger an ',
                            ),
                            TextSpan(
                              text: 'owner approval prompt',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                color: AppColors.deepBlue,
                                fontSize: 13.sp,
                              ),
                            ),
                            const TextSpan(text: '.'),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 14.h),
                    Obx(_buildRefundCard),
                    SizedBox(height: 14.h),
                    Obx(_buildDiscountCard),
                    SizedBox(height: 14.h),
                    Obx(_buildToggles),
                    SizedBox(height: 16.h),
                    const AuditNote(
                      'Rule changes are recorded under Owner PIN #OWN-001',
                    ),
                  ],
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(16.w, 6.h, 16.w, 10.h),
                child: Column(
                  children: [
                    PrimaryArrowButton(
                      label: 'Save',
                      leadingIcon: Icons.save_outlined,
                      onPressed: controller.onSave,
                    ),
                    SizedBox(height: 8.h),
                    SizedBox(
                      width: double.infinity,
                      child: SoftButton(
                        label: 'Reset to defaults',
                        height: 44,
                        radius: 14,
                        onTap: controller.onResetDefaults,
                      ),
                    ),
                  ],
                ),
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
            BackPill(label: 'Settings', onTap: controller.onBackPressed),
            SizedBox(width: 8.w),
            const Spacer(),
            const Flexible(
              flex: 4,
              child: StatusPill(
                text: 'Owner Security Clearance',
                icon: Icons.shield,
                fg: AppColors.deepBlue,
                bg: AppColors.lightBlue,
                fontSize: 11,
              ),
            ),
          ],
        ),
        SizedBox(height: 14.h),
        const PageTitle(
          title: 'Approval Rules',
          subtitle: 'Manager & Cashier Governance · Policy Thresholds',
        ),
      ],
    );
  }

  Widget _ruleCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Widget child,
    required String footnote,
  }) {
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IconBox(icon),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 15.5.sp,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textDark,
                      ),
                    ),
                    SizedBox(height: 3.h),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12.sp,
                        height: 1.35,
                        color: AppColors.textDark.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 14.h),
          child,
          SizedBox(height: 10.h),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.info_outline, size: 15.sp, color: AppColors.grey),
              SizedBox(width: 6.w),
              Expanded(
                child: Text(
                  footnote,
                  style: TextStyle(
                    fontSize: 11.5.sp,
                    height: 1.35,
                    color: AppColors.grey,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRefundCard() {
    final v = controller.refundLimit.value;
    return _ruleCard(
      icon: Icons.currency_exchange,
      title: 'Refund needs approval above',
      subtitle: 'Refunds over this amount need a manager or owner PIN.',
      footnote:
          'Approvals are requested on the register or by push '
          'notification to the owner.',
      child: ValueStepper(
        current: v,
        value: formatCad(v),
        unit: 'CAD',
        onMinus: controller.refundMinus,
        onPlus: controller.refundPlus,
        presets: ApprovalRulesController.refundPresets,
        presetLabel: (p) => '\$${p.toInt()}',
        onPreset: controller.setRefund,
      ),
    );
  }

  Widget _buildDiscountCard() {
    final v = controller.maxDiscount.value;
    return _ruleCard(
      icon: Icons.percent,
      title: 'Maximum cashier discount',
      subtitle:
          'Highest discount a cashier can give on a line item or '
          'bundle without approval.',
      footnote:
          'Larger discounts need a manager PIN; staff-specific limits '
          'are set in the Permissions Manager.',
      child: ValueStepper(
        current: v,
        value: '$v%',
        unit: 'LIMIT',
        onMinus: controller.discountMinus,
        onPlus: controller.discountPlus,
        presets: ApprovalRulesController.discountPresets,
        presetLabel: (p) => '${p.toInt()}%',
        onPreset: controller.setDiscount,
      ),
    );
  }

  Widget _buildToggles() {
    Widget divider() => Padding(
      padding: EdgeInsets.symmetric(vertical: 12.h),
      child: const Divider(),
    );
    return SectionCard(
      child: Column(
        children: [
          SwitchRow(
            title: 'Require approval for price changes',
            subtitle:
                'Cashiers cannot change a unit price at checkout '
                'without approval.',
            value: controller.priceChangeApproval.value,
            onChanged: controller.togglePriceChange,
          ),
          divider(),
          SwitchRow(
            title: 'Require approval for voids',
            subtitle:
                'Removing a scanned item from the basket needs a '
                'manager PIN.',
            value: controller.voidApproval.value,
            onChanged: controller.toggleVoid,
          ),
          divider(),
          SwitchRow(
            title: 'Allow manager self-approval',
            subtitle:
                'Shift leads can approve their own actions up to '
                '\$500 when working alone.',
            value: controller.managerSelfApproval.value,
            onChanged: controller.toggleSelfApproval,
          ),
        ],
      ),
    );
  }
}
