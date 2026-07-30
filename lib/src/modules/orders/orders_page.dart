import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/network/api_client.dart';
import '../../core/network/api_exception.dart';
import '../../navigation_helper.dart';
import '../../theme/app_colors.dart';
import '../../utils/screen_adapter.dart';
import '../main/main_controller.dart';
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
  VoidCallback? _unregisterOrdersRefresher;

  @override
  void initState() {
    super.initState();
    if (Get.isRegistered<MainController>()) {
      _unregisterOrdersRefresher = Get.find<MainController>()
          .registerOrdersRefresher(_refreshOrders);
    }
    _loadOrders();
  }

  @override
  void dispose() {
    _unregisterOrdersRefresher?.call();
    super.dispose();
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

  Future<void> _handleOrderTap(OrderListItem item) async {
    if (item.redirectTarget.isNotEmpty) {
      await NavigationHelper.navigateRawTarget(item.redirectTarget);
      return;
    }
    await NavigationHelper.applyProductWithFlow(item.productId);
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
            Text(
              'Hi! Welcome',
              style: TextStyle(
                color: AppColors.ordersHeaderText,
                fontSize: 22.sp,
                fontWeight: FontWeight.w700,
                height: 26 / 22,
              ),
            ),
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
                OrderListRow(item: order, onTap: () => _handleOrderTap(order)),
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
