import 'package:flutter/material.dart';

import '../../core/network/api_client.dart';
import '../../core/network/api_exception.dart';
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
  var _selectedStatus = OrderListStatus.all;
  var _orders = const <OrderListItem>[];
  var _loading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  void _selectStatus(OrderListStatus status) {
    if (_selectedStatus == status) {
      return;
    }
    setState(() {
      _selectedStatus = status;
    });
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });
    try {
      final response = await ApiClient.instance.orderList(
        mummies: _selectedStatus.code,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _orders = parseOrderListItems(response.states);
        _loading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _orders = const <OrderListItem>[];
        _loading = false;
        _errorMessage = ApiErrorMessage.resolve(error);
      });
    }
  }

  Future<void> _refreshOrders() {
    return _loadOrders();
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.appBackground,
      child: RefreshIndicator(
        color: AppColors.ordersTabActiveText,
        backgroundColor: AppColors.tabBackground,
        onRefresh: _refreshOrders,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.fromLTRB(20.w, 24.h, 20.w, 132.h),
          children: [
            const _OrdersHeader(),
            SizedBox(height: 23.h),
            OrderListTabs(
              selectedStatus: _selectedStatus,
              onStatusSelected: _selectStatus,
              style: OrderListTabsStyle.tabbar,
            ),
            SizedBox(height: 31.h),
            if (_loading)
              const _OrdersLoadingState()
            else if (_errorMessage != null)
              _OrdersErrorState(message: _errorMessage!, onRetry: _loadOrders)
            else if (_orders.isEmpty)
              const _OrdersEmptyState()
            else
              for (final order in _orders) ...[
                OrderListRow(item: order),
                SizedBox(height: 10.h),
              ],
          ],
        ),
      ),
    );
  }
}

class _OrdersLoadingState extends StatelessWidget {
  const _OrdersLoadingState();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 220.h,
      child: const Center(
        child: CircularProgressIndicator(color: AppColors.tabBackground),
      ),
    );
  }
}

class _OrdersErrorState extends StatelessWidget {
  const _OrdersErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 220.h,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.w),
              child: Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.tabBackground,
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w400,
                  height: 18 / 14,
                ),
              ),
            ),
            SizedBox(height: 12.h),
            TextButton(
              onPressed: onRetry,
              child: Text(
                'Retry',
                style: TextStyle(
                  color: AppColors.ordersYellow,
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
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
    return SizedBox(
      height: 220.h,
      child: Center(
        child: Text(
          'No orders yet',
          style: TextStyle(
            color: AppColors.ordersTabInactiveText,
            fontSize: 16.sp,
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
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Hi! Welcome',
          style: TextStyle(
            color: AppColors.ordersHeaderText,
            fontSize: 22.sp,
            fontWeight: FontWeight.w700,
            height: 26 / 22,
          ),
        ),
        Container(
          width: 35.w,
          height: 35.h,
          decoration: BoxDecoration(
            color: AppColors.ordersActionBlueText.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(10.r),
          ),
          child: Icon(
            Icons.chat_bubble_outline_rounded,
            color: AppColors.tabBackground,
            size: 24.r,
          ),
        ),
      ],
    );
  }
}
