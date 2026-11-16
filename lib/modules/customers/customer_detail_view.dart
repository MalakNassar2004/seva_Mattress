import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_colors_extra.dart';
import '../../app/theme/app_theme.dart';
import '../../app/widgets/app_widgets.dart';
import '../../app/widgets/owner_widgets.dart';
import 'customer_detail_controller.dart';

class CustomerDetailView extends GetView<CustomerDetailController> {
  const CustomerDetailView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SoftBackground(
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 16.h),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(),
                      SizedBox(height: 14.h),
                      _buildContactCard(),
                      SizedBox(height: 12.h),
                      _buildStats(),
                      SizedBox(height: 18.h),
                      _buildAddresses(),
                      SizedBox(height: 16.h),
                      Obx(
                        () => SegmentedTabs(
                          labels: CustomerDetailController.tabLabels,
                          selectedIndex: controller.tabIndex.value,
                          onChanged: controller.selectTab,
                          style: SegmentedStyle.soft,
                        ),
                      ),
                      SizedBox(height: 12.h),
                      Obx(() {
                        switch (controller.tabIndex.value) {
                          case 0:
                            return _buildOrdersTab();
                          case 1:
                            return _buildNotesTab();
                          default:
                            return _buildWarrantyTab();
                        }
                      }),
                      SizedBox(height: 14.h),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.lock_outline,
                              size: 12.sp, color: AppColors.grey),
                          SizedBox(width: 5.w),
                          Text(
                            'PCI-DSS Level 1 Encrypted · Store Terminal #04',
                            style: TextStyle(
                              fontSize: 10.5.sp,
                              fontWeight: FontWeight.w600,
                              color: AppColors.grey,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              _buildBottomActions(),
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
            WhitePill(
              onTap: controller.onBackPressed,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.chevron_left,
                      size: 22.sp, color: AppColors.primaryBlue),
                  SizedBox(width: 2.w),
                  Text(
                    'Customers',
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w700,
                      color: AppColors.deepBlue,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: 8.w),
            Expanded(
              child: StatusPill(
                text: 'VIP Client · Active',
                dot: true,
                fg: AppColors.success,
                bg: AppColors.successBg,
                border: AppColorsExtra.successBorder,
                fontSize: 11,
                maxLines: 2,
              ),
            ),
            SizedBox(width: 8.w),
            GestureDetector(
              onTap: controller.onEditPressed,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(20.r),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.edit_outlined,
                        size: 15.sp, color: AppColors.primaryBlue),
                    SizedBox(width: 5.w),
                    Text(
                      'Edit',
                      style: TextStyle(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryBlue,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(width: 8.w),
            CircleIconButton(
              icon: Icons.more_vert,
              onTap: controller.onMorePressed,
            ),
          ],
        ),
        SizedBox(height: 14.h),
        Row(
          children: [
            Flexible(
              child: Text(
                CustomerDetailController.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 26.sp,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textDark,
                ),
              ),
            ),
            const Spacer(),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
              decoration: BoxDecoration(
                color: AppColors.lightBlue,
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Text(
                'OWNER VIEW',
                style: TextStyle(
                  fontSize: 9.5.sp,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.4,
                  color: AppColors.deepBlue,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 2.h),
        Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: CustomerDetailController.customerId,
                style: TextStyle(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primaryBlue,
                ),
              ),
              TextSpan(
                text: '  •  Surrey Flagship  •  CAD Currency',
                style: TextStyle(fontSize: 12.sp, color: AppColors.grey),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ---------------- Contact card ----------------
  Widget _buildContactCard() {
    return AppCard(
      radius: 24,
      padding: EdgeInsets.all(14.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _contactRow(
            icon: Icons.phone_outlined,
            label: 'Primary Mobile',
            value: CustomerDetailController.phone,
            actions: [
              _ActionPill(
                icon: Icons.phone_outlined,
                label: 'Call',
                bg: AppColors.lightBlue,
                fg: AppColors.primaryBlue,
                onTap: controller.onCallPressed,
              ),
              SizedBox(width: 6.w),
              _ActionPill(
                icon: Icons.chat_bubble_outline,
                label: 'SMS',
                bg: AppColorsExtra.chipGrey,
                fg: AppColors.textDark,
                onTap: controller.onSmsPressed,
              ),
            ],
          ),
          Padding(
            padding: EdgeInsets.symmetric(vertical: 10.h),
            child: const Divider(),
          ),
          _contactRow(
            icon: Icons.mail_outline,
            label: 'Personal Email',
            value: CustomerDetailController.email,
            actions: [
              _ActionPill(
                icon: Icons.mail_outline,
                label: 'Email',
                bg: AppColors.lightBlue,
                fg: AppColors.primaryBlue,
                onTap: controller.onEmailPressed,
              ),
            ],
          ),
          Padding(
            padding: EdgeInsets.symmetric(vertical: 10.h),
            child: const Divider(),
          ),
          Wrap(
            spacing: 8.w,
            runSpacing: 8.h,
            children: [
              StatusPill(
                text: 'VIP Store Account',
                fg: AppColors.deepBlue,
                bg: AppColors.lightBlue,
              ),
              StatusPill(
                text: 'Preferred Delivery: Weekends',
                fg: AppColors.textDark,
                bg: AppColorsExtra.chipGrey,
              ),
              StatusPill(
                text: 'Credit Approved',
                icon: Icons.check,
                fg: AppColors.success,
                bg: AppColors.successBg,
                border: AppColorsExtra.successBorder,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _contactRow({
    required IconData icon,
    required String label,
    required String value,
    required List<Widget> actions,
  }) {
    return Row(
      children: [
        Container(
          width: 44.w,
          height: 44.w,
          decoration: BoxDecoration(
            color: AppColors.lightBlue,
            borderRadius: BorderRadius.circular(14.r),
          ),
          child: Icon(icon, size: 21.sp, color: AppColors.deepBlue),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 11.sp, color: AppColors.grey),
              ),
              SizedBox(height: 1.h),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textDark,
                ),
              ),
            ],
          ),
        ),
        SizedBox(width: 8.w),
        ...actions,
      ],
    );
  }

  // ---------------- Stats ----------------
  Widget _buildStats() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: _StatCard(
            label: 'Lifetime Orders',
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '3',
                  style: TextStyle(
                    fontSize: 24.sp,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textDark,
                  ),
                ),
                SizedBox(width: 4.w),
                Padding(
                  padding: EdgeInsets.only(bottom: 4.h),
                  child: Text(
                    'Active',
                    style: TextStyle(
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w700,
                      color: AppColors.success,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        SizedBox(width: 8.w),
        Expanded(
          child: Obx(
            () => _StatCard(
              label: 'Total Spent',
              labelTrailing: GestureDetector(
                onTap: controller.toggleAmounts,
                child: Icon(
                  controller.hideAmounts.value
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  size: 15.sp,
                  color: AppColors.grey,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    controller.hideAmounts.value
                        ? '••••••'
                        : '\$5,847.00',
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textDark,
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    'CAD',
                    style: TextStyle(fontSize: 10.sp, color: AppColors.grey),
                  ),
                ],
              ),
            ),
          ),
        ),
        SizedBox(width: 8.w),
        Expanded(
          child: _StatCard(
            label: 'Balance Owing',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '\$0.00',
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textDark,
                  ),
                ),
                SizedBox(height: 3.h),
                Container(
                  padding:
                      EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                  decoration: BoxDecoration(
                    color: AppColors.successBg,
                    borderRadius: BorderRadius.circular(6.r),
                    border: Border.all(color: AppColorsExtra.successBorder),
                  ),
                  child: Text(
                    'Settled',
                    style: TextStyle(
                      fontSize: 9.5.sp,
                      fontWeight: FontWeight.w800,
                      color: AppColors.success,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ---------------- Addresses ----------------
  Widget _buildAddresses() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Delivery Addresses',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w800,
                color: AppColors.textDark,
              ),
            ),
            GestureDetector(
              onTap: controller.onAddAddressPressed,
              child: Text(
                '+ Add',
                style: TextStyle(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryBlue,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 10.h),
        // Default address: blue accent bar on the left.
        Container(
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(18.r),
            boxShadow: AppShadows.soft,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18.r),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(width: 4.w, color: AppColors.primaryBlue),
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.all(14.w),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              StatusPill(
                                text: 'Default Delivery',
                                icon: Icons.check,
                                fg: AppColors.deepBlue,
                                bg: AppColors.lightBlue,
                                fontSize: 11,
                              ),
                              const Spacer(),
                              Icon(Icons.local_shipping_outlined,
                                  size: 18.sp, color: AppColors.greyLight),
                            ],
                          ),
                          SizedBox(height: 8.h),
                          Text(
                            '14288 72 Ave, Surrey, BC V3W 2R3',
                            style: TextStyle(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textDark,
                            ),
                          ),
                          SizedBox(height: 2.h),
                          Text(
                            'Single family home · Master bedroom 2nd floor · Gate code #4820',
                            style: TextStyle(
                              fontSize: 11.5.sp,
                              height: 1.3,
                              color: AppColors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        SizedBox(height: 10.h),
        Container(
          padding: EdgeInsets.all(14.w),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(18.r),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    StatusPill(
                      text: 'Secondary · Cabin',
                      fg: AppColors.textDark,
                      bg: AppColorsExtra.chipGrey,
                      fontSize: 11,
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      'Unit 402 - 15210 Pacific Ave, White Rock, BC',
                      style: TextStyle(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textDark,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      'Freight elevator booking required with concierge.',
                      style: TextStyle(
                        fontSize: 11.5.sp,
                        color: AppColors.primaryBlue.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right,
                  size: 20.sp, color: AppColors.greyLight),
            ],
          ),
        ),
      ],
    );
  }

  // ---------------- Tabs ----------------
  Widget _buildWarrantyTab() {
    return AppCard(
      radius: 22,
      padding: EdgeInsets.all(16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: StatusPill(
                    text: 'Active (Expires Oct 2034)',
                    dot: true,
                    fg: AppColors.success,
                    bg: AppColors.successBg,
                    border: AppColorsExtra.successBorder,
                    fontSize: 10.5,
                  ),
                ),
              ),
              Container(
                width: 40.w,
                height: 40.w,
                decoration: BoxDecoration(
                  color: AppColors.successBg,
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(color: AppColorsExtra.successBorder),
                ),
                child: Icon(Icons.verified_user_outlined,
                    size: 22.sp, color: AppColors.success),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Text(
            '10-Year Master Comfort Warranty',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w800,
              color: AppColors.textDark,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            'Seva Hybrid Luxury Queen',
            style: TextStyle(
              fontSize: 13.sp,
              fontWeight: FontWeight.w700,
              color: AppColors.primaryBlue,
            ),
          ),
          SizedBox(height: 2.h),
          Text(
            'SKU: MAT-SEV-HYB-QN · SN: #SEVA-884920',
            style: TextStyle(fontSize: 11.sp, color: AppColors.grey),
          ),
          SizedBox(height: 12.h),
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(14.w),
            decoration: BoxDecoration(
              color: AppColorsExtra.panelGrey,
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(color: AppColorsExtra.panelBorder),
            ),
            child: Text(
              'Customer registered mattress protector on delivery. Verified '
              'certified organic latex core. 100-night comfort guarantee valid '
              'through Jan 26, 2025.',
              style: TextStyle(
                fontSize: 12.5.sp,
                height: 1.45,
                color: AppColors.textDark.withValues(alpha: 0.85),
              ),
            ),
          ),
          SizedBox(height: 10.h),
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
            decoration: BoxDecoration(
              color: AppColorsExtra.panelGrey,
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Row(
              children: [
                Icon(Icons.shield_outlined,
                    size: 15.sp, color: AppColors.danger),
                SizedBox(width: 8.w),
                // TODO(backend): real author and date of the note.
                Text(
                  'Logged by Sara Lee (Cashier) · Jan 26, 2025',
                  style: TextStyle(fontSize: 11.sp, color: AppColors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// TODO(design): replace with the real Orders tab design.
  Widget _buildOrdersTab() {
    const orders = [
      ('SM-10485', 'Oct 12, 2025', '\$2,899.00 CAD', 'Delivered'),
      ('SM-10311', 'Aug 03, 2025', '\$1,899.00 CAD', 'Delivered'),
      ('SM-10102', 'May 21, 2025', '\$1,049.00 CAD', 'Delivered'),
    ];
    return Column(
      children: orders
          .map(
            (o) => Padding(
              padding: EdgeInsets.only(bottom: 10.h),
              child: AppCard(
                radius: 18,
                padding: EdgeInsets.all(14.w),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            o.$1,
                            style: TextStyle(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textDark,
                            ),
                          ),
                          SizedBox(height: 2.h),
                          Text(
                            '${o.$2} · ${o.$3}',
                            style: TextStyle(
                                fontSize: 11.5.sp, color: AppColors.grey),
                          ),
                        ],
                      ),
                    ),
                    StatusPill(
                      text: o.$4,
                      icon: Icons.check_circle,
                      fg: AppColors.success,
                      bg: AppColors.successBg,
                      border: AppColorsExtra.successBorder,
                    ),
                  ],
                ),
              ),
            ),
          )
          .toList(),
    );
  }

  /// TODO(design): replace with the real Notes tab design.
  Widget _buildNotesTab() {
    const notes = [
      ('Prefers weekend deliveries only.', 'Sara Lee · Oct 12, 2025'),
      ('Gate code changed to #4820.', 'Marcus Vance · Aug 03, 2025'),
    ];
    return Column(
      children: notes
          .map(
            (n) => Padding(
              padding: EdgeInsets.only(bottom: 10.h),
              child: AppCard(
                radius: 18,
                padding: EdgeInsets.all(14.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      n.$1,
                      style: TextStyle(
                        fontSize: 13.sp,
                        height: 1.35,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textDark,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      n.$2,
                      style: TextStyle(fontSize: 11.sp, color: AppColors.grey),
                    ),
                  ],
                ),
              ),
            ),
          )
          .toList(),
    );
  }

  // ---------------- Bottom actions ----------------
  Widget _buildBottomActions() {
    return Container(
      padding: EdgeInsets.fromLTRB(16.w, 10.h, 16.w, 10.h),
      decoration: BoxDecoration(
        color: AppColors.white.withValues(alpha: 0.92),
        border: const Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: 56.h,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28.r),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryBlue.withValues(alpha: 0.28),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Material(
              color: AppColors.primaryBlue,
              borderRadius: BorderRadius.circular(28.r),
              child: InkWell(
                onTap: controller.onCreateOrderPressed,
                borderRadius: BorderRadius.circular(28.r),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20.w),
                  child: Row(
                    children: [
                      Icon(Icons.add_shopping_cart_outlined,
                          size: 22.sp, color: AppColors.white),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: Text(
                          'Create New Order / Quote',
                          style: TextStyle(
                            fontSize: 15.sp,
                            fontWeight: FontWeight.w800,
                            color: AppColors.white,
                          ),
                        ),
                      ),
                      Icon(Icons.arrow_forward,
                          size: 20.sp, color: AppColors.white),
                    ],
                  ),
                ),
              ),
            ),
          ),
          SizedBox(height: 10.h),
          SizedBox(
            width: double.infinity,
            height: 46.h,
            child: OutlinedButton.icon(
              onPressed: controller.onLogNotePressed,
              icon: Icon(Icons.edit_note, size: 20.sp, color: AppColors.textDark),
              label: Text(
                'Log After-Sales Note',
                style: TextStyle(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark,
                ),
              ),
              style: OutlinedButton.styleFrom(
                backgroundColor: AppColors.white,
                side: const BorderSide(color: AppColors.border),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14.r),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionPill extends StatelessWidget {
  const _ActionPill({
    required this.icon,
    required this.label,
    required this.bg,
    required this.fg,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color bg;
  final Color fg;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 9.h),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(14.r),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14.sp, color: fg),
            SizedBox(width: 4.w),
            Text(
              label,
              style: TextStyle(
                fontSize: 12.sp,
                fontWeight: FontWeight.w800,
                color: fg,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.child,
    this.labelTrailing,
  });

  final String label;
  final Widget child;
  final Widget? labelTrailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(18.r),
        boxShadow: AppShadows.soft,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10.5.sp,
                    fontWeight: FontWeight.w700,
                    color: AppColors.grey,
                  ),
                ),
              ),
              if (labelTrailing != null) ...[
                SizedBox(width: 4.w),
                labelTrailing!,
              ],
            ],
          ),
          SizedBox(height: 8.h),
          child,
        ],
      ),
    );
  }
}
