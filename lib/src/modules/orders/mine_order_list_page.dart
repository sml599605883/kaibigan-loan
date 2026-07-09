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
    final screen = ScreenAdapter.of(context);

    return Scaffold(
      backgroundColor: AppColors.ordersBackground,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.ordersTabActiveText,
          backgroundColor: AppColors.tabBackground,
          onRefresh: _refreshOrders,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: screen.edgeInsetsFromLTRB(20, 33, 14, 100),
            children: [
              const _MineOrderHeader(),
              SizedBox(height: screen.h(24)),
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
                SizedBox(height: screen.h(31)),
                for (final item in _items) ...[
                  OrderListRow(item: item),
                  SizedBox(height: screen.h(10)),
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
    final screen = ScreenAdapter.of(context);

    return SizedBox(
      height: screen.h(24),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: screen.borderRadiusAll(20),
                onTap: NavigationHelper.back,
                child: SizedBox(
                  width: screen.w(32),
                  height: screen.h(32),
                  child: Center(
                    child: Image.asset(
                      AppAssets.loginBack,
                      width: screen.w(23),
                      height: screen.h(20),
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
              fontSize: screen.sp(20),
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
    final screen = ScreenAdapter.of(context);

    return Padding(
      padding: screen.edgeInsetsOnly(top: 138),
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
    final screen = ScreenAdapter.of(context);

    return Padding(
      padding: screen.edgeInsetsOnly(top: 138, left: 24, right: 24),
      child: Column(
        children: [
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.ordersTitleText,
              fontSize: screen.sp(14),
              fontWeight: FontWeight.w400,
              height: 18 / 14,
            ),
          ),
          SizedBox(height: screen.h(16)),
          TextButton(
            onPressed: onRetry,
            child: Text(
              'Retry',
              style: TextStyle(
                color: AppColors.ordersTabActiveText,
                fontSize: screen.sp(14),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
