import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../utils/screen_adapter.dart';

class OrdersPage extends StatefulWidget {
  const OrdersPage({super.key});

  @override
  State<OrdersPage> createState() => _OrdersPageState();
}

class _OrdersPageState extends State<OrdersPage> {
  static const _tabs = <String>[
    'All order',
    'Outstanding',
    'Overdue',
    'Settled',
  ];

  static const _orders = <_OrderCardData>[
    _OrderCardData(
      status: 'Overdue',
      actionText: 'Repay\nNow',
      overdue: true,
      actionType: _OrderActionType.repay,
    ),
    _OrderCardData(
      status: 'Outstanding',
      actionText: 'Repay\nNow',
      overdue: true,
      actionType: _OrderActionType.repay,
    ),
    _OrderCardData(
      status: 'Outstanding',
      actionText: 'Details',
      actionType: _OrderActionType.details,
    ),
    _OrderCardData(
      status: 'Outstanding',
      actionText: 'Details',
      actionType: _OrderActionType.details,
    ),
  ];

  var _selectedTabIndex = 0;

  List<_OrderCardData> get _visibleOrders {
    final selectedTab = _tabs[_selectedTabIndex];
    if (selectedTab == 'All order') {
      return _orders;
    }
    return _orders.where((order) => order.status == selectedTab).toList();
  }

  void _selectTab(int index) {
    if (_selectedTabIndex == index) {
      return;
    }
    setState(() {
      _selectedTabIndex = index;
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
            _OrdersTabs(
              tabs: _tabs,
              selectedIndex: _selectedTabIndex,
              onTabSelected: _selectTab,
            ),
            SizedBox(height: screen.h(31)),
            if (visibleOrders.isEmpty)
              const _OrdersEmptyState()
            else
              for (final order in visibleOrders) ...[
                _OrderRow(data: order),
                SizedBox(height: screen.h(10)),
              ],
          ],
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

class _OrdersTabs extends StatelessWidget {
  const _OrdersTabs({
    required this.tabs,
    required this.selectedIndex,
    required this.onTabSelected,
  });

  final List<String> tabs;
  final int selectedIndex;
  final ValueChanged<int> onTabSelected;

  @override
  Widget build(BuildContext context) {
    final screen = ScreenAdapter.of(context);

    return Row(
      children: [
        for (var index = 0; index < tabs.length; index++) ...[
          Expanded(
            child: _OrderTab(
              label: tabs[index],
              selected: index == selectedIndex,
              onTap: () => onTabSelected(index),
            ),
          ),
          if (index != tabs.length - 1) SizedBox(width: screen.w(5)),
        ],
      ],
    );
  }
}

class _OrderTab extends StatelessWidget {
  const _OrderTab({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final screen = ScreenAdapter.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: screen.borderRadiusAll(5),
        onTap: onTap,
        child: Ink(
          height: screen.h(30),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.tabBackground
                : AppColors.ordersTabInactive,
            borderRadius: screen.borderRadiusAll(5),
          ),
          child: Center(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                label,
                maxLines: 1,
                style: TextStyle(
                  color: selected
                      ? AppColors.ordersTabActiveText
                      : AppColors.ordersTabInactiveText,
                  fontSize: screen.sp(12),
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                  height: 18 / 12,
                ),
              ),
            ),
          ),
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

class _OrderCardData {
  const _OrderCardData({
    required this.status,
    required this.actionText,
    required this.actionType,
    this.overdue = false,
  });

  final String status;
  final String actionText;
  final _OrderActionType actionType;
  final bool overdue;
}

enum _OrderActionType { repay, details }

class _OrderRow extends StatelessWidget {
  const _OrderRow({required this.data});

  final _OrderCardData data;

  @override
  Widget build(BuildContext context) {
    final screen = ScreenAdapter.of(context);

    return SizedBox(
      height: screen.h(105),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            right: 0,
            top: screen.h(11),
            child: _OrderActionButton(data: data),
          ),
          _OrderCard(data: data),
        ],
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({required this.data});

  final _OrderCardData data;

  @override
  Widget build(BuildContext context) {
    final screen = ScreenAdapter.of(context);

    return Container(
      width: screen.w(258),
      height: screen.h(105),
      padding: screen.edgeInsetsFromLTRB(12, 10, 11, 10),
      decoration: BoxDecoration(
        color: AppColors.tabBackground,
        border: Border.all(color: AppColors.ordersCardBorder),
        borderRadius: BorderRadius.horizontal(
          left: Radius.circular(screen.r(20)),
          right: Radius.circular(screen.r(8)),
        ),
      ),
      child: Row(
        children: [
          SizedBox(width: screen.w(100), child: const _OrderAmountBlock()),
          const Spacer(),
          SizedBox(
            width: screen.w(101),
            child: _OrderStatusBlock(data: data),
          ),
        ],
      ),
    );
  }
}

class _OrderAmountBlock extends StatelessWidget {
  const _OrderAmountBlock();

  @override
  Widget build(BuildContext context) {
    final screen = ScreenAdapter.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _AppNameTag(),
        SizedBox(height: screen.h(8)),
        SizedBox(
          height: screen.h(31),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              '₱ 20,000',
              maxLines: 1,
              style: TextStyle(
                color: AppColors.ordersTitleText,
                fontSize: screen.sp(26),
                fontWeight: FontWeight.w700,
                height: 31 / 26,
              ),
            ),
          ),
        ),
        Transform.translate(
          offset: Offset(screen.w(10), screen.h(-1)),
          child: SizedBox(
            width: screen.w(90),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                'Loan Amount',
                maxLines: 1,
                style: TextStyle(
                  color: AppColors.ordersLightText,
                  fontSize: screen.sp(14),
                  fontWeight: FontWeight.w400,
                  height: 17 / 14,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _AppNameTag extends StatelessWidget {
  const _AppNameTag();

  @override
  Widget build(BuildContext context) {
    final screen = ScreenAdapter.of(context);

    return Container(
      width: screen.w(94),
      height: screen.h(26),
      padding: screen.edgeInsetsFromLTRB(7, 5, 8, 5),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [AppColors.ordersYellow, AppColors.ordersYellowEnd],
        ),
        borderRadius: screen.borderRadiusAll(20),
      ),
      child: Row(
        children: [
          Container(
            width: screen.w(16),
            height: screen.h(16),
            decoration: const BoxDecoration(
              color: AppColors.tabBackground,
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(width: screen.w(4)),
          Expanded(
            child: Text(
              'App Name',
              maxLines: 1,
              overflow: TextOverflow.clip,
              style: TextStyle(
                color: AppColors.ordersTitleText,
                fontSize: screen.sp(12),
                fontWeight: FontWeight.w700,
                height: 14 / 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OrderStatusBlock extends StatelessWidget {
  const _OrderStatusBlock({required this.data});

  final _OrderCardData data;

  @override
  Widget build(BuildContext context) {
    final screen = ScreenAdapter.of(context);
    final statusBackground = data.overdue
        ? AppColors.ordersOrangeStart
        : AppColors.ordersBlueTag;
    final statusTextColor = data.overdue
        ? AppColors.ordersStatusRed
        : AppColors.tabBackground;
    final dateBackground = data.overdue
        ? AppColors.ordersDateRedBackground
        : AppColors.ordersDateBlueBackground;
    final dateTextColor = data.status == 'Overdue'
        ? AppColors.ordersRedText
        : AppColors.ordersTitleText;

    return Padding(
      padding: screen.edgeInsetsOnly(top: 4, bottom: 1),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: Container(
              height: screen.h(19),
              padding: screen.edgeInsetsSymmetric(horizontal: 7),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: statusBackground,
                borderRadius: screen.borderRadiusAll(20),
              ),
              child: Text(
                data.status,
                maxLines: 1,
                style: TextStyle(
                  color: statusTextColor,
                  fontSize: screen.sp(12),
                  fontWeight: FontWeight.w400,
                  height: 14 / 12,
                ),
              ),
            ),
          ),
          Container(
            width: screen.w(101),
            height: screen.h(44),
            padding: screen.edgeInsetsOnly(top: 7),
            decoration: BoxDecoration(
              color: dateBackground,
              borderRadius: screen.borderRadiusAll(7),
            ),
            child: Column(
              children: [
                Text(
                  '2026/05/13',
                  maxLines: 1,
                  style: TextStyle(
                    color: dateTextColor,
                    fontSize: screen.sp(14),
                    fontWeight: FontWeight.w700,
                    height: 17 / 14,
                  ),
                ),
                SizedBox(height: screen.h(3)),
                Text(
                  'Due Date',
                  maxLines: 1,
                  style: TextStyle(
                    color: AppColors.ordersLightText,
                    fontSize: screen.sp(10),
                    fontWeight: FontWeight.w400,
                    height: 12 / 10,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OrderActionButton extends StatelessWidget {
  const _OrderActionButton({required this.data});

  final _OrderCardData data;

  @override
  Widget build(BuildContext context) {
    final screen = ScreenAdapter.of(context);
    final isRepay = data.actionType == _OrderActionType.repay;

    return SizedBox(
      width: screen.w(168),
      height: screen.h(83),
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: isRepay
              ? const LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    AppColors.ordersOrangeStart,
                    AppColors.ordersOrangeEnd,
                  ],
                )
              : const LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [AppColors.ordersYellow, AppColors.ordersYellowEnd],
                ),
          borderRadius: screen.borderRadiusAll(20),
        ),
        child: Align(
          alignment: const Alignment(0.76, 0),
          child: Text(
            data.actionText,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isRepay
                  ? AppColors.tabBackground
                  : AppColors.ordersActionBlueText,
              fontSize: screen.sp(16),
              fontWeight: FontWeight.w700,
              height: 19 / 16,
            ),
          ),
        ),
      ),
    );
  }
}
