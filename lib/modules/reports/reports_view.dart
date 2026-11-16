import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_colors_extra.dart';
import '../../app/utils/money.dart';
import '../../app/widgets/app_widgets.dart';
import '../../app/widgets/chart_widgets.dart';
import '../../app/widgets/owner_widgets.dart';
import '../../app/widgets/page_widgets.dart';
import '../../app/widgets/shared_widgets.dart';
import '../sales/sales_models.dart';
import '../sales/sales_store.dart';
import 'reports_controller.dart';

/// Sales Reports. Lives in the Reports tab of the owner shell, so it does
/// not draw the bottom navigation.
class ReportsView extends GetView<ReportsController> {
  const ReportsView({super.key});

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
                  controller.store.sales.length;
                  final loading = controller.loading.value;
                  final stats = controller.stats;
                  return ListView(
                    padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 16.h),
                    children: [
                      _buildHeader(),
                      SizedBox(height: 14.h),
                      ..._buildFilters(),
                      SizedBox(height: 14.h),
                      if (loading) ...[
                        const SkeletonCard(lines: 5),
                        SizedBox(height: 12.h),
                        const SkeletonCard(height: 150),
                        SizedBox(height: 12.h),
                        const SkeletonCard(lines: 3),
                      ] else if (stats.isEmpty)
                        SectionCard(
                          child: EmptyState(
                            icon: Icons.bar_chart_rounded,
                            message: 'No data for these filters',
                            actionLabel: 'Clear filters',
                            onAction: controller.clearAll,
                          ),
                        )
                      else ...[
                        _buildStatement(stats),
                        SizedBox(height: 12.h),
                        _buildChart(),
                        SizedBox(height: 12.h),
                        _buildTopProducts(),
                        SizedBox(height: 12.h),
                        _buildPaymentTotals(stats),
                      ],
                      SizedBox(height: 12.h),
                      MenuGroup(
                        tiles: [
                          MenuTile(
                            icon: Icons.receipt_long_outlined,
                            title: 'Transactions',
                            subtitle: 'Every invoice with payments & refunds',
                            onTap: controller.onTransactions,
                          ),
                        ],
                      ),
                      SizedBox(height: 12.h),
                      const AuditNote(
                        'PCI-DSS Level 1 Encrypted Showroom Terminal',
                      ),
                    ],
                  );
                }),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 10.h),
                child: PrimaryArrowButton(
                  label: 'Export report',
                  leadingIcon: Icons.download_outlined,
                  onPressed: controller.onExport,
                ),
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
      children: [
        Row(
          children: [
            BackPill(label: 'Home', onTap: controller.onHome),
            Expanded(
              child: Text(
                'Reports',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 22.sp,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textDark,
                ),
              ),
            ),
            CircleIconButton(
              icon: Icons.ios_share,
              iconColor: AppColors.primaryBlue,
              onTap: controller.onExport,
            ),
          ],
        ),
        SizedBox(height: 8.h),
        StatusPill(
          text: 'Surrey Showroom · ${controller.periodText}',
          dot: true,
          fg: AppColors.success,
          bg: AppColorsExtra.chipGrey,
          fontSize: 11,
        ),
      ],
    );
  }

  // ---------------- Filters ----------------
  List<Widget> _buildFilters() {
    final periods = SalesPeriod.values;
    final types = <ProductType?>[null, ...ProductType.values];
    final methods = <PayMethod?>[null, ...PayMethod.values];
    return [
      FilterChipBar(
        options: [
          for (final p in periods)
            FilterOption(
              p == SalesPeriod.custom && controller.period.value == p
                  ? controller.periodText
                  : p.label,
            ),
        ],
        selectedIndex: periods.indexOf(controller.period.value),
        onSelected: (i) => controller.selectPeriod(periods[i]),
      ),
      SizedBox(height: 8.h),
      FilterChipBar(
        options: [
          for (final t in types) FilterOption(t?.label ?? 'All products'),
        ],
        selectedIndex: types.indexOf(controller.type.value),
        onSelected: (i) => controller.selectType(types[i]),
      ),
      SizedBox(height: 8.h),
      Row(
        children: [
          Expanded(
            child: FilterChipBar(
              options: [
                for (final m in methods)
                  FilterOption(m?.label ?? 'All payments'),
              ],
              selectedIndex: methods.indexOf(controller.method.value),
              onSelected: (i) => controller.selectMethod(methods[i]),
            ),
          ),
          if (controller.hasFilters)
            TextButton(
              onPressed: controller.clearAll,
              child: Text(
                'Clear all',
                style: TextStyle(
                  fontSize: 12.5.sp,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primaryBlue,
                ),
              ),
            ),
        ],
      ),
    ];
  }

  // ---------------- Statement ----------------
  Widget _buildStatement(SalesStats s) {
    Widget row(
      String label,
      String value, {
      Color? color,
      bool muted = false,
    }) => Padding(
      padding: EdgeInsets.symmetric(vertical: 5.h),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: muted ? FontWeight.w400 : FontWeight.w500,
                color:
                    color ??
                    AppColors.textDark.withValues(alpha: muted ? 0.65 : 0.85),
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w700,
              color: color ?? AppColors.textDark,
            ),
          ),
        ],
      ),
    );

    final hidden = controller.profitHidden.value;
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Financial summary',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textDark,
                ),
              ),
              SizedBox(width: 6.w),
              Tooltip(
                triggerMode: TooltipTriggerMode.tap,
                showDuration: const Duration(seconds: 4),
                message:
                    'Net = Gross − Discounts − Refunds. '
                    'Taxes are shown separately.',
                child: Icon(
                  Icons.info_outline,
                  size: 18.sp,
                  color: AppColors.grey,
                ),
              ),
            ],
          ),
          SizedBox(height: 10.h),
          row('Gross sales', formatCad(s.gross)),
          row('Discounts', '-${formatCad(s.discounts)}'),
          row('Refunds', '-${formatCad(s.refunds)}', color: AppColors.danger),
          row('Taxes (GST & PST)', formatCad(s.taxes), muted: true),
          SizedBox(height: 8.h),
          const Divider(color: AppColorsExtra.panelBorder),
          SizedBox(height: 10.h),
          const Caption('Net sales'),
          SizedBox(height: 2.h),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    formatCad(s.net),
                    style: TextStyle(
                      fontSize: 30.sp,
                      fontWeight: FontWeight.w800,
                      color: AppColors.deepBlue,
                      letterSpacing: -0.6,
                    ),
                  ),
                ),
              ),
              SizedBox(width: 4.w),
              Text(
                'CAD',
                style: TextStyle(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w700,
                  color: AppColors.grey,
                ),
              ),
            ],
          ),
          SizedBox(height: 10.h),
          const Divider(color: AppColorsExtra.panelBorder),
          SizedBox(height: 8.h),
          Row(
            children: [
              Flexible(
                child: Text(
                  'Estimated profit',
                  style: TextStyle(
                    fontSize: 13.5.sp,
                    color: AppColors.textDark.withValues(alpha: 0.8),
                  ),
                ),
              ),
              SizedBox(width: 4.w),
              GestureDetector(
                onTap: controller.toggleProfit,
                child: Icon(
                  hidden
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  size: 18.sp,
                  color: AppColors.grey,
                ),
              ),
              SizedBox(width: 8.w),
              const Spacer(),
              Flexible(
                flex: 2,
                child: StatusPill(
                  text: hidden ? '\$ ••••' : formatCad(s.profit),
                  fg: AppColors.deepBlue,
                  bg: AppColors.lightBlue,
                  fontSize: 12.5,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ---------------- Chart ----------------
  Widget _buildChart() {
    final buckets = controller.buckets;
    final active = controller.activeBar;
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Sales trend',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w800,
              color: AppColors.textDark,
            ),
          ),
          SizedBox(height: 10.h),
          SegmentedTabs(
            labels: [for (final m in ChartMode.values) m.label],
            selectedIndex: controller.chartMode.value.index,
            onChanged: controller.selectChartMode,
          ),
          SizedBox(height: 12.h),
          BarChart(
            values: [for (final b in buckets) controller.bucketValue(b)],
            labels: [for (final b in buckets) b.label],
            selected: active,
            onSelect: controller.selectBar,
            tooltipOf: controller.tooltipOf,
          ),
        ],
      ),
    );
  }

  // ---------------- Lists ----------------
  Widget _buildTopProducts() {
    final list = controller.topProducts;
    final max = list.isEmpty ? 1.0 : list.first.revenue;
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Top products',
            style: TextStyle(
              fontSize: 15.sp,
              fontWeight: FontWeight.w800,
              color: AppColors.textDark,
            ),
          ),
          for (final p in list) ...[
            SizedBox(height: 12.h),
            Row(
              children: [
                Expanded(
                  child: Text(
                    p.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13.5.sp,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textDark,
                    ),
                  ),
                ),
                SizedBox(width: 8.w),
                Text(
                  '${p.units} units · ',
                  style: TextStyle(fontSize: 12.sp, color: AppColors.grey),
                ),
                Text(
                  formatCad(p.revenue),
                  style: TextStyle(
                    fontSize: 13.5.sp,
                    fontWeight: FontWeight.w800,
                    color: AppColors.deepBlue,
                  ),
                ),
              ],
            ),
            SizedBox(height: 6.h),
            ProgressBar(value: max == 0 ? 0 : p.revenue / max, height: 5),
          ],
        ],
      ),
    );
  }

  Widget _buildPaymentTotals(SalesStats s) {
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Payment-method totals',
            style: TextStyle(
              fontSize: 15.sp,
              fontWeight: FontWeight.w800,
              color: AppColors.textDark,
            ),
          ),
          SizedBox(height: 12.h),
          Row(
            children: [
              for (final m in PayMethod.values) ...[
                if (m != PayMethod.values.first) SizedBox(width: 8.w),
                Expanded(
                  child: Container(
                    padding: EdgeInsets.symmetric(vertical: 12.h),
                    decoration: BoxDecoration(
                      color: AppColorsExtra.panelGrey,
                      borderRadius: BorderRadius.circular(14.r),
                      border: Border.all(color: AppColorsExtra.panelBorder),
                    ),
                    child: Column(
                      children: [
                        Icon(m.icon, size: 18.sp, color: AppColors.deepBlue),
                        SizedBox(height: 4.h),
                        Text(
                          m.label,
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: AppColors.textDark.withValues(alpha: 0.7),
                          ),
                        ),
                        SizedBox(height: 2.h),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            formatCad(s.byMethod[m]!, decimals: 0),
                            style: TextStyle(
                              fontSize: 15.sp,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textDark,
                            ),
                          ),
                        ),
                        Text(
                          '${(s.methodShare(m) * 100).round()}%',
                          style: TextStyle(
                            fontSize: 11.5.sp,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primaryBlue,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
