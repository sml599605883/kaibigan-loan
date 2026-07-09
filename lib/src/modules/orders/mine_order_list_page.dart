import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../assets/app_assets.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_exception.dart';
import '../../navigation_helper.dart';
import '../../theme/app_colors.dart';
import '../../utils/screen_adapter.dart';
import 'order_list_models.dart';
import 'order_list_widgets.dart';

class MineOrderListPage extends StatefulWidget {
  const MineOrderListPage({super.key});

  @override
  State<MineOrderListPage> createState() => _MineOrderListPageState();
}

class _MineOrderListPageState extends State<MineOrderListPage> {
  late OrderListStatus _selectedStatus;
  var _items = const <OrderListItem>[];
  var _loading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _selectedStatus = OrderListStatus.fromCode(_initialStatusCode());
    _loadOrders();
  }

  String? _initialStatusCode() {
    final arguments = Get.arguments;
    if (arguments is Map) {
      return arguments['initialStatus']?.toString();
    }
    return null;
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
        _items = parseOrderListItems(response.states);
        _loading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _items = const <OrderListItem>[];
        _loading = false;
        _errorMessage = ApiErrorMessage.resolve(error);
      });
    }
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

  Future<void> _refreshOrders() {
    return _loadOrders();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.ordersBackground,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.ordersTabActiveText,
          backgroundColor: AppColors.tabBackground,
          onRefresh: _refreshOrders,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.fromLTRB(20.w, 13.w, 14.w, 100.h),
            children: [
              const _MineOrderHeader(),
              SizedBox(height: 24.h),
              OrderListTabs(
                selectedStatus: _selectedStatus,
                onStatusSelected: _selectStatus,
              ),
              if (_loading)
                const _MineOrderLoadingState()
              else if (_errorMessage != null)
                _MineOrderErrorState(
                  message: _errorMessage!,
                  onRetry: _loadOrders,
                )
              else if (_items.isEmpty)
                const MineOrderEmptyState()
              else ...[
                SizedBox(height: 31.h),
                for (final item in _items) ...[
                  OrderListRow(item: item),
                  SizedBox(height: 10.h),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _MineOrderHeader extends StatelessWidget {
  const _MineOrderHeader();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 24.h,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(20.r),
                onTap: NavigationHelper.back,
                child: SizedBox(
                  width: 32.w,
                  height: 32.h,
                  child: Center(
                    child: Image.asset(
                      AppAssets.loginBack,
                      width: 23.w,
                      height: 20.h,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Text(
            'Loan List',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.ordersTitleText,
              fontSize: 20.sp,
              fontWeight: FontWeight.w700,
              height: 24 / 20,
              letterSpacing: 0.07756407558917999,
            ),
          ),
        ],
      ),
    );
  }
}

class _MineOrderLoadingState extends StatelessWidget {
  const _MineOrderLoadingState();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: 138.h),
      child: const Center(
        child: CircularProgressIndicator(color: AppColors.ordersTabActiveText),
      ),
    );
  }
}

class _MineOrderErrorState extends StatelessWidget {
  const _MineOrderErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: 138.h, left: 24.w, right: 24.w),
      child: Column(
        children: [
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.ordersTitleText,
              fontSize: 14.sp,
              fontWeight: FontWeight.w400,
              height: 18 / 14,
            ),
          ),
          SizedBox(height: 16.h),
          TextButton(
            onPressed: onRetry,
            child: Text(
              'Retry',
              style: TextStyle(
                color: AppColors.ordersTabActiveText,
                fontSize: 14.sp,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
