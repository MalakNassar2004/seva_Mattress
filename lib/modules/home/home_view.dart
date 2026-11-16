import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_colors_extra.dart';
import '../../app/theme/app_theme.dart';
import '../../app/utils/dates.dart';
import '../../app/widgets/app_widgets.dart';
import '../../app/widgets/chart_widgets.dart';
import '../../app/widgets/owner_widgets.dart';
import '../../app/widgets/page_widgets.dart';
import '../../app/widgets/shared_widgets.dart';
import '../audit/audit_models.dart';
import '../sales/sales_models.dart';
import '../sales/sales_store.dart';
import 'home_controller.dart';

/// Owner Home (dashboard). Lives in the Home tab of the owner shell, so it
/// does not draw the bottom navigation.
class HomeView extends GetView<HomeController> {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SoftBackground(
        child: SafeArea(
          bottom: false,
          child: Obx(() {
            // Touch the stores so totals refresh after refunds / approvals.
            controller.sales.sales.length;
            controller.approvals.requests.length;
            controller.audit.events.length;
            final loading = controller.loading.value;
            final stats = controller.stats;
            return ListView(
              padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 20.h),
              children: [
                _buildHeader(),
                SizedBox(height: 14.h),
                SegmentedTabs(
                  labels: [for (final p in HomeController.periods) p.label],
                  selectedIndex: HomeController.periods.indexOf(
                    controller.period.value,
                  ),
                  onChanged: controller.selectPeriod,
                  style: SegmentedStyle.soft,
                ),
                if (!controller.online.value) ...[
                  SizedBox(height: 12.h),
                  OfflineBanner(onRetry: controller.onRetry),
                ],
                SizedBox(height: 14.h),
                if (loading)
                  ..._skeleton()
                else if (stats.isEmpty)
                  SectionCard(
                    child: EmptyState(
                      icon: Icons.point_of_sale_outlined,
                      message: switch (controller.period.value) {
                        SalesPeriod.today => 'No sales yet today',
                        SalesPeriod.week => 'No sales this week',
                        _ => 'No sales this month',
                      },
                    ),
                  )
                else ...[
                  _buildHero(stats),
                  SizedBox(height: 12.h),
                  _buildKpis(stats),
                ],
                if (!loading) ...[
                  SizedBox(height: 14.h),
                  _buildAttention(),
                  if (!stats.isEmpty) ...[
                    SizedBox(height: 14.h),
                    _buildPayments(stats),
                  ],
                  SizedBox(height: 14.h),
                  _buildQuickActions(),
                  SizedBox(height: 14.h),
                  _buildRecent(),
                ],
                SizedBox(height: 14.h),
                const AuditNote('PCI-DSS Level 1 Encrypted · Seva POS'),
              ],
            );
          }),
        ),
      ),
    );
  }

  List<Widget> _skeleton() => [
    const SkeletonCard(height: 120),
    SizedBox(height: 12.h),
    Row(
      children: [
        const Expanded(child: SkeletonCard(lines: 2)),
        SizedBox(width: 10.w),
        const Expanded(child: SkeletonCard(lines: 2)),
      ],
    ),
    SizedBox(height: 12.h),
    const SkeletonCard(lines: 3),
  ];

  // ---------------- Header ----------------
  Widget _buildHeader() {
    final hidden = controller.hidden.value;
    return Row(
      children: [
        const InitialsAvatar(initials: 'OW', size: 46),
        SizedBox(width: 12.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                controller.greeting,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 17.sp,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textDark,
                ),
              ),
              SizedBox(height: 4.h),
              const StatusPill(
                text: 'Surrey Store',
                dot: true,
                fg: AppColors.success,
                bg: AppColors.white,
                border: AppColors.border,
                fontSize: 11,
              ),
            ],
          ),
        ),
        CircleIconButton(
          icon: hidden
              ? Icons.visibility_off_outlined
              : Icons.visibility_outlined,
          onTap: controller.toggleHidden,
        ),
        SizedBox(width: 8.w),
        Stack(
          clipBehavior: Clip.none,
          children: [
            CircleIconButton(
              icon: Icons.notifications_none,
              onTap: controller.onApprovals,
            ),
            if (controller.approvals.pendingCount > 0)
              Positioned(
                right: 9.w,
                top: 9.w,
                child: Container(
                  width: 9.w,
                  height: 9.w,
                  decoration: BoxDecoration(
                    color: AppColors.danger,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.white, width: 1.5),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  // ---------------- Hero ----------------
  Widget _buildHero(SalesStats s) {
    final pct = controller.changePct;
    final up = (pct ?? 0) >= 0;
    final spark = controller.spark;
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(child: Caption('Net sales (CAD)')),
              if (pct != null)
                StatusPill(
                  text:
                      '${up ? '▲' : '▼'} ${pct.abs().toStringAsFixed(1)}% '
                      '${controller.period.value.compareLabel}',
                  fg: up ? AppColors.success : AppColors.danger,
                  bg: up
                      ? AppColorsExtra.successSoft
                      : AppColorsExtra.dangerSoft,
                  border: up
                      ? AppColorsExtra.successBorder
                      : AppColorsExtra.dangerBorder,
                  fontSize: 11,
                ),
            ],
          ),
          SizedBox(height: 6.h),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              controller.money(s.net),
              style: TextStyle(
                fontSize: 32.sp,
                fontWeight: FontWeight.w800,
                color: AppColors.deepBlue,
                letterSpacing: -0.8,
              ),
            ),
          ),
          SizedBox(height: 2.h),
          Text(
            '${s.sales} sales · ${s.units} units',
            style: TextStyle(
              fontSize: 12.sp,
              color: AppColors.textDark.withValues(alpha: 0.7),
            ),
          ),
          if (spark.length > 1) ...[
            SizedBox(height: 12.h),
            Sparkline(values: spark),
          ],
        ],
      ),
    );
  }

  // ---------------- KPIs ----------------
  Widget _buildKpis(SalesStats s) {
    final m = controller.money;
    final tiles = [
      _KpiTile(
        icon: Icons.shopping_bag_outlined,
        label: 'Gross Sales',
        value: m(s.gross),
        sub: '${s.units} units sold',
      ),
      _KpiTile(
        icon: Icons.undo,
        label: 'Refunds',
        value: s.refunds == 0 ? m(0) : '-${m(s.refunds)}',
        sub: '${s.refundCount} refund${s.refundCount == 1 ? '' : 's'}',
        danger: true,
      ),
      _KpiTile(
        icon: Icons.local_offer_outlined,
        label: 'Discounts',
        value: m(s.discounts),
        sub: 'Promos & overrides',
      ),
      _KpiTile(
        icon: Icons.account_balance_outlined,
        label: 'Taxes Collected',
        value: m(s.taxes),
        sub: 'GST 5% + PST 7%',
      ),
      _KpiTile(
        icon: Icons.credit_card,
        label: 'Payments Collected',
        value: m(s.collected),
        sub: 'Card, cash & other',
      ),
      _KpiTile(
        icon: Icons.schedule,
        label: 'Balances Owing',
        value: m(s.owing),
        sub: 'Deposits & layaways',
        warning: s.owing > 0,
      ),
    ];
    return Column(
      children: [
        for (var i = 0; i < tiles.length; i += 2) ...[
          if (i > 0) SizedBox(height: 10.h),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: tiles[i]),
                SizedBox(width: 10.w),
                Expanded(child: tiles[i + 1]),
              ],
            ),
          ),
        ],
      ],
    );
  }

  // ---------------- Needs your attention ----------------
  Widget _buildAttention() {
    final pending = controller.approvals.pendingCount;
    final low = controller.lowStockCount;
    final failed = controller.failedDeliveries;
    final rows = <Widget>[
      if (pending > 0)
        _AttentionRow(
          badge: '$pending',
          title: '$pending approval${pending == 1 ? '' : 's'} pending',
          subtitle: 'Refunds, discounts and price changes',
          fg: AppColors.primaryBlue,
          bg: AppColors.lightBlue,
          onTap: controller.onApprovals,
        ),
      if (low > 0)
        _AttentionRow(
          badge: '$low',
          title: '$low low-stock product${low == 1 ? '' : 's'}',
          subtitle: 'Below reorder threshold or out of stock',
          fg: AppColorsExtra.amberText,
          bg: AppColorsExtra.amberSoft,
          onTap: controller.onLowStock,
        ),
      if (failed > 0)
        _AttentionRow(
          badge: '$failed',
          title: '$failed failed deliver${failed == 1 ? 'y' : 'ies'}',
          subtitle: 'Reschedule or contact the customer',
          fg: AppColors.danger,
          bg: AppColorsExtra.dangerSoft,
          onTap: controller.onFailedDeliveries,
        ),
    ];
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _cardTitle(
            'Needs your attention',
            badge: rows.isEmpty ? null : '${rows.length}',
          ),
          SizedBox(height: 10.h),
          if (rows.isEmpty)
            Text(
              'All clear. Nothing needs you right now.',
              style: TextStyle(fontSize: 13.sp, color: AppColors.grey),
            )
          else
            for (var i = 0; i < rows.length; i++) ...[
              if (i > 0) SizedBox(height: 8.h),
              rows[i],
            ],
        ],
      ),
    );
  }

  Widget _cardTitle(String text, {String? badge, Widget? trailing}) => Row(
    children: [
      Flexible(
        child: Text(
          text,
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.w800,
            color: AppColors.deepBlue,
          ),
        ),
      ),
      if (badge != null) ...[
        SizedBox(width: 8.w),
        StatusPill(
          text: badge,
          fg: AppColors.deepBlue,
          bg: AppColors.lightBlue,
          fontSize: 11,
        ),
      ],
      if (trailing != null) ...[const Spacer(), trailing],
    ],
  );

  // ---------------- Payment methods ----------------
  Widget _buildPayments(SalesStats s) {
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _cardTitle(
            'Payment methods',
            trailing: Text(
              'CAD split',
              style: TextStyle(fontSize: 11.5.sp, color: AppColors.grey),
            ),
          ),
          SizedBox(height: 14.h),
          StackedBar(
            segments: [
              for (final m in PayMethod.values)
                BarSegment(s.byMethod[m]!, m.color),
            ],
          ),
          SizedBox(height: 12.h),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final m in PayMethod.values)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 8.w,
                            height: 8.w,
                            decoration: BoxDecoration(
                              color: m.color,
                              shape: BoxShape.circle,
                            ),
                          ),
                          SizedBox(width: 5.w),
                          Flexible(
                            child: Text(
                              '${m.label} '
                              '(${(s.methodShare(m) * 100).round()}%)',
                              style: TextStyle(
                                fontSize: 12.sp,
                                color: AppColors.textDark.withValues(
                                  alpha: 0.75,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 3.h),
                      Text(
                        controller.money(s.byMethod[m]!),
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textDark,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  // ---------------- Quick actions ----------------
  Widget _buildQuickActions() {
    Widget action(IconData icon, String label, VoidCallback onTap) => Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Column(
          children: [
            Container(
              width: 52.w,
              height: 52.w,
              decoration: BoxDecoration(
                color: AppColors.lightBlue,
                shape: BoxShape.circle,
                border: Border.all(color: AppColorsExtra.infoBorder),
              ),
              child: Icon(icon, size: 22.sp, color: AppColors.deepBlue),
            ),
            SizedBox(height: 6.h),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
                color: AppColors.textDark,
              ),
            ),
          ],
        ),
      ),
    );

    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Caption('Quick actions'),
          SizedBox(height: 12.h),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              action(
                Icons.add_box_outlined,
                'Add Product',
                controller.onAddProduct,
              ),
              action(
                Icons.person_add_alt_1_outlined,
                'Add Employee',
                controller.onAddEmployee,
              ),
              action(Icons.post_add, 'Create PO', controller.onCreatePo),
              action(Icons.download_outlined, 'Export', controller.onExport),
            ],
          ),
        ],
      ),
    );
  }

  // ---------------- Recent activity ----------------
  Widget _buildRecent() {
    final events = controller.recent;
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _cardTitle(
            'Recent activity',
            trailing: GestureDetector(
              onTap: controller.onAuditLog,
              child: Text(
                'View all',
                style: TextStyle(
                  fontSize: 12.5.sp,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryBlue,
                ),
              ),
            ),
          ),
          SizedBox(height: 6.h),
          if (events.isEmpty)
            Padding(
              padding: EdgeInsets.symmetric(vertical: 8.h),
              child: Text(
                'No activity yet.',
                style: TextStyle(fontSize: 13.sp, color: AppColors.grey),
              ),
            ),
          for (final e in events) _activityRow(e),
        ],
      ),
    );
  }

  Widget _activityRow(AuditEvent e) {
    final (fg, _, _) = e.action.chipColors;
    final who = e.isOwner ? 'Owner' : '${e.actor} (${e.actorRole})';
    return Padding(
      padding: EdgeInsets.only(top: 10.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(top: 5.h),
            child: Container(
              width: 8.w,
              height: 8.w,
              decoration: BoxDecoration(
                color: e.action == AuditAction.login ? AppColors.greyLight : fg,
                shape: BoxShape.circle,
              ),
            ),
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: who,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: AppColors.deepBlue,
                        ),
                      ),
                      TextSpan(text: ' · ${e.sentence}'),
                    ],
                  ),
                  style: TextStyle(
                    fontSize: 13.sp,
                    height: 1.35,
                    color: AppColors.textDark,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  '${formatAgo(e.time)} · ${e.terminal}',
                  style: TextStyle(fontSize: 11.5.sp, color: AppColors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _KpiTile extends StatelessWidget {
  const _KpiTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.sub,
    this.danger = false,
    this.warning = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final String sub;
  final bool danger;
  final bool warning;

  @override
  Widget build(BuildContext context) {
    final Color valueColor = danger
        ? AppColors.danger
        : warning
        ? AppColorsExtra.amberText
        : AppColors.textDark;
    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: danger ? AppColorsExtra.dangerSoft : AppColors.white,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(
          color: danger ? AppColorsExtra.dangerBorder : AppColors.border,
        ),
        boxShadow: AppShadows.small,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconBox(
                icon,
                size: 34,
                bg: danger ? AppColors.dangerBg : AppColors.lightBlue,
                fg: danger ? AppColors.danger : AppColors.deepBlue,
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 12.5.sp,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textDark.withValues(alpha: 0.8),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 10.h),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.w800,
                color: valueColor,
              ),
            ),
          ),
          SizedBox(height: 2.h),
          Text(
            sub,
            style: TextStyle(fontSize: 11.sp, color: AppColors.grey),
          ),
        ],
      ),
    );
  }
}

class _AttentionRow extends StatelessWidget {
  const _AttentionRow({
    required this.badge,
    required this.title,
    required this.subtitle,
    required this.fg,
    required this.bg,
    required this.onTap,
  });

  final String badge;
  final String title;
  final String subtitle;
  final Color fg;
  final Color bg;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColorsExtra.panelGrey,
      borderRadius: BorderRadius.circular(14.r),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14.r),
        child: Container(
          padding: EdgeInsets.all(12.w),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14.r),
            border: Border.all(color: AppColorsExtra.panelBorder),
          ),
          child: Row(
            children: [
              Container(
                width: 34.w,
                height: 34.w,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Text(
                  badge,
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w800,
                    color: fg,
                  ),
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textDark,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: AppColors.textDark.withValues(alpha: 0.65),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                size: 20.sp,
                color: AppColors.greyLight,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
