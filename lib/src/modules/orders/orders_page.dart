import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../utils/screen_adapter.dart';
import 'order_list_models.dart';
import 'order_list_widgets.dart';

class OrdersPage extends StatefulWidget {
  const OrdersPage({super.key});

  @override
  State<OrdersPage> createState() => _OrdersPageState();
}

class _OrdersPageState extends State<OrdersPage> {
  static const _orders = <OrderListItem>[
    OrderListItem(
      productName: 'App Name',
      amountText: '₱ 20,000',
      statusText: 'Overdue',
      dateValue: '2026/05/13',
      dateLabel: 'Due Date',
      actionText: 'Repay\nNow',
    ),
    OrderListItem(
      productName: 'App Name',
      amountText: '₱ 20,000',
      statusText: 'Outstanding',
      dateValue: '2026/05/13',
      dateLabel: 'Due Date',
      actionText: 'Repay\nNow',
    ),
    OrderListItem(
      productName: 'App Name',
      amountText: '₱ 20,000',
      statusText: 'Outstanding',
      dateValue: '2026/05/13',
      dateLabel: 'Due Date',
      actionText: 'Details',
    ),
    OrderListItem(
      productName: 'App Name',
      amountText: '₱ 20,000',
      statusText: 'Outstanding',
      dateValue: '2026/05/13',
      dateLabel: 'Due Date',
      actionText: 'Details',
    ),
  ];

  var _selectedStatus = OrderListStatus.all;

  List<OrderListItem> get _visibleOrders {
    if (_selectedStatus == OrderListStatus.all) {
      return _orders;
    }
    return _orders
        .where((order) => order.statusText == _selectedStatus.label)
        .toList();
  }

  void _selectStatus(OrderListStatus status) {
    if (_selectedStatus == status) {
      return;
    }
    setState(() {
      _selectedStatus = status;
    });
  }

  Future<void> _refreshOrders() async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    if (!mounted) {
      return;
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final screen = ScreenAdapter.of(context);
    final visibleOrders = _visibleOrders;

    return ColoredBox(
      color: AppColors.appBackground,
      child: RefreshIndicator(
        color: AppColors.ordersTabActiveText,
        backgroundColor: AppColors.tabBackground,
        onRefresh: _refreshOrders,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: screen.edgeInsetsFromLTRB(20, 24, 20, 132),
          children: [
            const _OrdersHeader(),
            SizedBox(height: screen.h(23)),
            OrderListTabs(
              selectedStatus: _selectedStatus,
              onStatusSelected: _selectStatus,
              style: OrderListTabsStyle.tabbar,
            ),
            SizedBox(height: screen.h(31)),
            if (visibleOrders.isEmpty)
              const _OrdersEmptyState()
            else
              for (final order in visibleOrders) ...[
                OrderListRow(item: order),
                SizedBox(height: screen.h(10)),
              ],
          ],
        ),
      ),
    );
  }
}

class _OrdersEmptyState extends StatelessWidget {
  const _OrdersEmptyState();

  @override
  Widget build(BuildContext context) {
    final screen = ScreenAdapter.of(context);

    return SizedBox(
      height: screen.h(220),
      child: Center(
        child: Text(
          'No orders yet',
          style: TextStyle(
            color: AppColors.ordersTabInactiveText,
            fontSize: screen.sp(16),
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _OrdersHeader extends StatelessWidget {
  const _OrdersHeader();

  @override
  Widget build(BuildContext context) {
    final screen = ScreenAdapter.of(context);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Hi! Welcome',
          style: TextStyle(
            color: AppColors.ordersHeaderText,
            fontSize: screen.sp(22),
            fontWeight: FontWeight.w700,
            height: 26 / 22,
          ),
        ),
        Container(
          width: screen.w(35),
          height: screen.h(35),
          decoration: BoxDecoration(
            color: AppColors.ordersActionBlueText.withValues(alpha: 0.9),
            borderRadius: screen.borderRadiusAll(10),
          ),
          child: Icon(
            Icons.chat_bubble_outline_rounded,
            color: AppColors.tabBackground,
            size: screen.r(24),
          ),
        ),
      ],
    );
  }
}
