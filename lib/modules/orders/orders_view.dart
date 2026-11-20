import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_colors_extra.dart';
import '../../app/theme/app_theme.dart';
import '../../app/utils/money.dart';
import '../../app/widgets/app_widgets.dart';
import '../../app/widgets/owner_widgets.dart';
import '../../app/widgets/shared_widgets.dart';
import 'order_models.dart';
import 'order_widgets.dart';
import 'orders_controller.dart';

/// Orders & Quotes (owner). Lives in the Orders tab of the owner shell, so it
/// does not draw the bottom navigation. Its controller is registered by
/// OwnerShellBinding.
/// /// false = Quotes are hidden (they are not built yet). Set to true to show
/// the Orders | Quotes switch again.
const bool _quotesEnabled = false;
class OrdersView extends GetView<OrdersController> {
  const OrdersView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SoftBackground(
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 0),
                child: Column(
                  children: [
                    _buildHeader(),
                    SizedBox(height: 14.h),
                                        if (_quotesEnabled) ...[
                      Obx(_buildSegment),
                      SizedBox(height: 12.h),
                    ],
                  ],
                ),
              ),
              Obx(_buildFilters),
              SizedBox(height: 4.h),
              const Divider(height: 1, color: AppColorsExtra.panelBorder),
              Expanded(
                child: Obx(
                  () => ListView(
                    padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 16.h),
                    children: [
                      if (controller.segment.value ==
                          OrdersController.ordersSegment)
                        ..._ordersList()
                      else
                        ..._quotesList(),
                      SizedBox(height: 6.h),
                      const AuditNote(
                        'PCI-DSS Level 1 Encrypted Showroom Terminal · Surrey BC',
                        icon: Icons.verified_user,
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 12.h),
                child: PrimaryArrowButton(
                  label: 'Create Order',
                  leadingIcon: Icons.add_circle,
                  onPressed: controller.onCreatePressed,
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
            BackPill(label: 'Home', onTap: controller.onBackPressed),
            SizedBox(width: 10.w),
            Expanded(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
'Orders',                  style: TextStyle(
                    fontSize: 24.sp,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textDark,
                    letterSpacing: -0.4,
                  ),
                ),
              ),
            ),
            SizedBox(width: 8.w),
            CircleIconButton(
              icon: Icons.search,
              onTap: controller.onSearchPressed,
            ),
            SizedBox(width: 8.w),
            CircleIconButton(
              icon: Icons.tune,
              onTap: controller.onFiltersPressed,
            ),
          ],
        ),
        SizedBox(height: 10.h),
        Row(
          children: [
            Icon(Icons.storefront, size: 15.sp, color: AppColors.deepBlue),
            SizedBox(width: 6.w),
            Expanded(
              child: Text(
                'Surrey Flagship Store · CAD Currency',
                style: TextStyle(
                  fontSize: 12.5.sp,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textDark,
                ),
              ),
            ),
            const StatusPill(
              text: 'POS Online',
              dot: true,
              fg: AppColors.success,
              bg: AppColorsExtra.successSoft,
              border: AppColorsExtra.successBorder,
              fontSize: 11,
            ),
          ],
        ),
      ],
    );
  }

  // ---------------- Orders | Quotes ----------------
  Widget _buildSegment() {
    final selected = controller.segment.value;
    final tabs = [
      ('Orders', controller.totalOrders.value),
      ('Quotes', controller.totalQuotes.value),
    ];
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: AppColorsExtra.segmentBg,
        borderRadius: BorderRadius.circular(18.r),
      ),
      child: Row(
        children: List.generate(tabs.length, (i) {
          final active = i == selected;
          return Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => controller.selectSegment(i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                height: 40.h,
                decoration: BoxDecoration(
                  color: active ? AppColors.primaryBlue : Colors.transparent,
                  borderRadius: BorderRadius.circular(14.r),
                  boxShadow: active
                      ? [
                          BoxShadow(
                            color: AppColors.primaryBlue.withValues(alpha: 0.25),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      tabs[i].$1,
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w700,
                        color: active ? AppColors.white : AppColors.textDark,
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Container(
                      padding: EdgeInsets.symmetric(
                          horizontal: 8.w, vertical: 2.h),
                      decoration: BoxDecoration(
                        color: active
                            ? AppColors.white.withValues(alpha: 0.22)
                            : AppColors.white,
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                      child: Text(
                        '${tabs[i].$2}',
                        style: TextStyle(
                          fontSize: 11.5.sp,
                          fontWeight: FontWeight.w700,
                          color: active ? AppColors.white : AppColors.grey,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  // ---------------- Filter chips ----------------
  Widget _buildFilters() {
    final isOrders = controller.segment.value == OrdersController.ordersSegment;
    final List<Widget> chips;
    if (isOrders) {
      final sel = controller.statusFilterIndex.value;
      chips = List.generate(OrdersController.statusFilters.length, (i) {
        final s = OrdersController.statusFilters[i];
        if (s == null) {
          return ChoicePill(
            label: 'All',
count: '(${controller.totalOrders.value})',
            selected: sel == i,
            onTap: () => controller.selectStatusFilter(i),
          );
        }
        return ChoicePill(
          label: s.label,
count: '${controller.statusCounts[s] ?? 0}',
          dotColor: s.icon == null ? s.fg : null,
          icon: s.icon,
          selected: sel == i,
          onTap: () => controller.selectStatusFilter(i),
        );
      });
    } else {
      final sel = controller.quoteFilterIndex.value;
      chips = List.generate(OrdersController.quoteFilters.length, (i) {
        final s = OrdersController.quoteFilters[i];
        return ChoicePill(
          label: s?.label ?? 'All',
          count: s == null
              ? '(${controller.quotes.length})'
              : '${controller.quotes.where((q) => q.status == s).length}',
          selected: sel == i,
          onTap: () => controller.selectQuoteFilter(i),
        );
      });
    }
    return SizedBox(
      height: 40.h,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 2.h),
        itemCount: chips.length,
        separatorBuilder: (_, _) => SizedBox(width: 8.w),
        itemBuilder: (_, i) => chips[i],
      ),
    );
  }

  // ---------------- Lists ----------------
  List<Widget> _ordersList() {
    final list = controller.visibleOrders;
    if (list.isEmpty) {
      return [
        const _EmptyState(
          icon: Icons.receipt_long_outlined,
          text: 'No orders with this status',
        ),
      ];
    }
    return list
        .map((o) => Padding(
              padding: EdgeInsets.only(bottom: 14.h),
              child: _OrderCard(
                order: o,
                onTap: () => controller.onOrderTap(o),
              ),
            ))
        .toList();
  }

  List<Widget> _quotesList() {
    final list = controller.visibleQuotes;
    if (list.isEmpty) {
      return [
        const _EmptyState(
          icon: Icons.request_quote_outlined,
          text: 'No quotes here yet',
        ),
      ];
    }
    return list
        .map((q) => Padding(
              padding: EdgeInsets.only(bottom: 14.h),
              child: QuoteCard(
                quote: q,
                onSend: () => controller.onQuoteSend(q),
                onEdit: () => controller.onQuoteEdit(q),
                onConvert: () => _confirmConvert(q),
              ),
            ))
        .toList();
  }

  void _confirmConvert(QuoteItem q) {
    Get.dialog(
      AlertDialog(
        backgroundColor: AppColors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.r),
        ),
        title: Text(
          'Convert to order?',
          style: TextStyle(fontSize: 17.sp, fontWeight: FontWeight.w800),
        ),
        content: Text(
          '${q.number} for ${q.customer} (${formatCad(q.total)} CAD) will '
          'become a new order. You can record the deposit next.',
          style: TextStyle(fontSize: 13.5.sp, color: AppColors.grey),
        ),
        actions: [
          TextButton(
            onPressed: Get.back,
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primaryBlue,
            ),
            onPressed: () {
              Get.back();
              controller.onConvertToOrder(q);
            },
            child: const Text('Convert'),
          ),
        ],
      ),
    );
  }
}

// ---------------- Order card ----------------
class _OrderCard extends StatelessWidget {
  const _OrderCard({required this.order, required this.onTap});

  final OrderItem order;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(22.r),
          border: Border.all(color: AppColors.border),
          boxShadow: AppShadows.soft,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _TitleBlock(
                    number: order.number,
                    product: order.product,
                    customer: order.customer,
                    city: order.city,
                  ),
                ),
                Container(
                  width: 32.w,
                  height: 32.w,
                  decoration: const BoxDecoration(
                    color: Color(0xFFF1F4F8),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.chevron_right,
                      size: 20.sp, color: AppColors.textDark),
                ),
              ],
            ),
            SizedBox(height: 10.h),
            Wrap(
              spacing: 8.w,
              runSpacing: 8.h,
              children: [
                OrderStatusChip(status: order.status),
                if (order.isCustom) const CustomBadge(),
                // A delivery window sits next to the status chip.
                if (order.dateIsWindow) _dateChip(),
              ],
            ),
            // A due date sits on its own line, aligned right.
            if (!order.dateIsWindow) ...[
              SizedBox(height: 8.h),
              Align(alignment: Alignment.centerRight, child: _dateChip()),
            ],
            SizedBox(height: 12.h),
            if (order.status == OrderStatus.cancelled)
              _cancelledPanel()
            else
              PaidProgressPanel(total: order.total, paid: order.paid),
            SizedBox(height: 12.h),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(order.footerIcon,
                    size: 15.sp, color: order.footerIconColor),
                SizedBox(width: 5.w),
                Expanded(
                  child: Text(
                    order.footerText,
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: AppColors.textDark.withValues(alpha: 0.8),
                    ),
                  ),
                ),
                if (order.footerRight != null) ...[
                  SizedBox(width: 8.w),
                  Flexible(
                    child: Text(
                      order.footerRight!,
                      textAlign: order.footerRightAccent
                          ? TextAlign.start
                          : TextAlign.end,
                      style: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: order.footerRightAccent
                            ? FontWeight.w700
                            : FontWeight.w400,
                        color: order.footerRightAccent
                            ? AppColors.primaryBlue
                            : AppColors.grey,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _dateChip() => StatusPill(
        text: order.dateLabel,
        icon: order.dateIsWindow ? Icons.schedule : Icons.calendar_today_outlined,
        fg: AppColors.textDark,
        bg: AppColorsExtra.chipGrey,
        fontSize: 11.5,
      );

  Widget _cancelledPanel() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: AppColorsExtra.dangerSoft,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: AppColorsExtra.dangerBorder),
      ),
      child: Text(
        'Order total ${formatCad(order.total)} CAD · nothing collected',
        style: TextStyle(
          fontSize: 12.5.sp,
          fontWeight: FontWeight.w600,
          color: AppColors.danger,
        ),
      ),
    );
  }
}

/// "#ORD-10892 • Custom Queen Hybrid" + customer line.
class _TitleBlock extends StatelessWidget {
  const _TitleBlock({
    required this.number,
    required this.product,
    required this.customer,
    required this.city,
  });

  final String number;
  final String product;
  final String customer;
  final String city;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text.rich(
          TextSpan(children: [
            TextSpan(
              text: number,
              style: const TextStyle(color: AppColors.deepBlue),
            ),
            const TextSpan(
              text: '  •  ',
              style: TextStyle(color: AppColors.greyLight),
            ),
            TextSpan(text: product),
          ]),
          style: TextStyle(
            fontSize: 12.5.sp,
            fontWeight: FontWeight.w700,
            color: AppColors.textDark,
          ),
        ),
        SizedBox(height: 5.h),
        Row(
          children: [
            Icon(Icons.person_outline, size: 15.sp, color: AppColors.grey),
            SizedBox(width: 4.w),
            Flexible(
              child: Text.rich(
                TextSpan(children: [
                  TextSpan(
                    text: customer,
                    style: TextStyle(
                      fontSize: 14.5.sp,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textDark,
                    ),
                  ),
                  TextSpan(
                    text: ' · $city',
                    style: TextStyle(fontSize: 12.5.sp, color: AppColors.grey),
                  ),
                ]),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ---------------- Quote card ----------------
class QuoteCard extends StatelessWidget {
  const QuoteCard({
    super.key,
    required this.quote,
    required this.onSend,
    required this.onEdit,
    required this.onConvert,
  });

  final QuoteItem quote;
  final VoidCallback onSend;
  final VoidCallback onEdit;
  final VoidCallback onConvert;

  @override
  Widget build(BuildContext context) {
    final expiring = quote.status == QuoteStatus.expiring;
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(22.r),
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadows.soft,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _TitleBlock(
                  number: quote.number,
                  product: quote.product,
                  customer: quote.customer,
                  city: quote.city,
                ),
              ),
              SizedBox(width: 8.w),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Estimated Total',
                    style: TextStyle(
                      fontSize: 11.5.sp,
                      color: AppColors.textDark.withValues(alpha: 0.75),
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    formatCad(quote.total),
                    style: TextStyle(
                      fontSize: 21.sp,
                      fontWeight: FontWeight.w800,
                      color: AppColors.deepBlue,
                    ),
                  ),
                  Text(
                    'CAD',
                    style: TextStyle(
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w600,
                      color: AppColors.grey,
                    ),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              StatusPill(
                text: 'Valid until ${quote.validUntil}',
                icon: Icons.event_outlined,
                fg: expiring ? AppColors.danger : AppColors.textDark,
                bg: expiring ? AppColorsExtra.dangerSoft : AppColorsExtra.chipGrey,
                border: expiring ? AppColorsExtra.dangerBorder : null,
                fontSize: 11.5,
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: Text(
                  quote.note,
                  style: TextStyle(fontSize: 12.sp, color: AppColors.grey),
                ),
              ),
            ],
          ),
          if (quote.status == QuoteStatus.draft) ...[
            SizedBox(height: 8.h),
            const StatusPill(
              text: 'Draft · not sent yet',
              icon: Icons.edit_note,
              fg: AppColors.grey,
              bg: AppColorsExtra.panelGrey,
              border: AppColorsExtra.panelBorder,
              fontSize: 11,
            ),
          ],
          SizedBox(height: 14.h),
          Row(
            children: [
              SoftButton(
                label: 'Send',
                icon: Icons.send_outlined,
                onTap: onSend,
              ),
              SizedBox(width: 8.w),
              SoftButton(
                label: 'Edit',
                icon: Icons.edit_outlined,
                onTap: onEdit,
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: SoftButton(
                  label: 'Convert to Order',
                  icon: Icons.add_shopping_cart,
                  filled: true,
                  onTap: onConvert,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 40.h),
      child: Column(
        children: [
          Container(
            width: 64.w,
            height: 64.w,
            decoration: const BoxDecoration(
              color: AppColors.lightBlue,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 28.sp, color: AppColors.primaryBlue),
          ),
          SizedBox(height: 12.h),
          Text(
            text,
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
              color: AppColors.grey,
            ),
          ),
        ],
      ),
    );
  }
}
