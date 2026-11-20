import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_colors_extra.dart';
import '../../app/theme/app_theme.dart';
import '../../app/utils/money.dart';
import '../../app/widgets/app_widgets.dart';
import '../../app/widgets/owner_widgets.dart';
import '../orders/order_models.dart';
import '../orders/order_widgets.dart';
import 'customer_detail_controller.dart';

/// true  = the parts of the design that have no real data yet are shown as
///         Marwa designed them (they contain sample text).
/// false = they are hidden, so the screen shows only real information.
const bool _showDesignSamples = false;

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
                      Obx(_buildHeader),
                      SizedBox(height: 14.h),
                      Obx(_buildContactCard),
                      SizedBox(height: 12.h),
                      IntrinsicHeight(child: Obx(_buildStats)),
                      SizedBox(height: 18.h),
                      Obx(_buildAddresses),
                      SizedBox(height: 16.h),
                      Obx(
                        () => SegmentedTabs(
                          labels: controller.tabLabels,
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
                      if (_showDesignSamples) ...[
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
    final isVip = controller.isVip;
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
                text: isVip ? 'VIP Client · Active' : 'Active Customer',
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
                controller.name,
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
                text: controller.customerCode,
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
            value: controller.phoneDisplay,
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
            value: controller.emailDisplay,
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
          if (_showDesignSamples) ...[
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
    final open = controller.openOrders;
    final hidden = controller.hideAmounts.value;
    final owing = controller.balance > 0.004;

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
                  '${controller.lifetimeOrders}',
                  style: TextStyle(
                    fontSize: 24.sp,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textDark,
                  ),
                ),
                if (open > 0) ...[
                  SizedBox(width: 4.w),
                  Padding(
                    padding: EdgeInsets.only(bottom: 4.h),
                    child: Text(
                      '$open open',
                      style: TextStyle(
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w700,
                        color: AppColors.success,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        SizedBox(width: 8.w),
        Expanded(
          child: _StatCard(
            label: 'Total Spent',
            labelTrailing: GestureDetector(
              onTap: controller.toggleAmounts,
              child: Icon(
                hidden
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
                  hidden ? '••••••' : formatCad(controller.totalSpent),
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
        SizedBox(width: 8.w),
        Expanded(
          child: _StatCard(
            label: 'Balance Owing',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  formatCad(controller.balance),
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
                    color: owing ? AppColors.warningBg : AppColors.successBg,
                    borderRadius: BorderRadius.circular(6.r),
                    border: Border.all(
                      color: owing
                          ? AppColorsExtra.warningBorder
                          : AppColorsExtra.successBorder,
                    ),
                  ),
                  child: Text(
                    owing ? 'Owing' : 'Settled',
                    style: TextStyle(
                      fontSize: 9.5.sp,
                      fontWeight: FontWeight.w800,
                      color: owing ? AppColors.warning : AppColors.success,
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
    final address = controller.address;
    final city = controller.city;

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
                            address.isEmpty ? 'No address saved yet' : address,
                            style: TextStyle(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textDark,
                            ),
                          ),
                          SizedBox(height: 2.h),
                          Text(
                            address.isEmpty
                                ? 'Tap + Add to save the delivery address.'
                                : city,
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
        if (_showDesignSamples) ...[
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
      ],
    );
  }

  // ---------------- Tabs ----------------
  Widget _buildWarrantyTab() {
    if (!_showDesignSamples) {
      return const _EmptyCard('Warranty tracking is not available yet.');
    }
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

  /// The real orders of this customer. Tap one to open it.
  Widget _buildOrdersTab() {
    final list = controller.orders;
    if (list.isEmpty) {
      return const _EmptyCard(
        'No orders yet. Tap "Create New Order" to add the first one.',      );
    }
    return Column(
      children: list
          .map(
            (o) => Padding(
              padding: EdgeInsets.only(bottom: 10.h),
              child: GestureDetector(
                onTap: () => controller.onOrderTap(o),
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
                              o.number,
                              style: TextStyle(
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textDark,
                              ),
                            ),
                            SizedBox(height: 2.h),
                            Text(
                              '${o.dateLabel} · ${formatCad(o.total)} CAD',
                              style: TextStyle(
                                  fontSize: 11.5.sp, color: AppColors.grey),
                            ),
                          ],
                        ),
                      ),
                      OrderStatusChip(status: o.status, long: false),
                    ],
                  ),
                ),
              ),
            ),
          )
          .toList(),
    );
  }

  /// The note from the customer form, then the after-sales notes.
  Widget _buildNotesTab() {
    final profileNote = controller.profileNote;
    final notes = controller.notes;
    if (profileNote.isEmpty && notes.isEmpty) {
      return const _EmptyCard(
        'No notes yet. Tap "Log After-Sales Note" to add one.',
      );
    }
    return Column(
      children: [
        if (profileNote.isNotEmpty) _noteCard(profileNote, 'Customer profile'),
        for (final n in notes)
          _noteCard(
            n.text,
            '${n.by.isEmpty ? 'Unknown' : n.by} · ${fmtOrderDate(n.at)}',
          ),
      ],
    );
  }

  Widget _noteCard(String text, String meta) {
    return Padding(
      padding: EdgeInsets.only(bottom: 10.h),
      child: AppCard(
        radius: 18,
        padding: EdgeInsets.all(14.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              text,
              style: TextStyle(
                fontSize: 13.sp,
                height: 1.35,
                fontWeight: FontWeight.w600,
                color: AppColors.textDark,
              ),
            ),
            SizedBox(height: 4.h),
            Text(
              meta,
              style: TextStyle(fontSize: 11.sp, color: AppColors.grey),
            ),
          ],
        ),
      ),
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
                          'Create New Order ',
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

/// Message card for an empty tab.
class _EmptyCard extends StatelessWidget {
  const _EmptyCard(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      radius: 18,
      padding: EdgeInsets.all(14.w),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12.5.sp,
          height: 1.35,
          color: AppColors.grey,
        ),
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