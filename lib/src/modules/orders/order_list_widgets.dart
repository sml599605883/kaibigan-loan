import 'package:flutter/material.dart';

import '../../assets/app_assets.dart';
import '../../theme/app_colors.dart';
import '../../utils/screen_adapter.dart';
import 'order_list_models.dart';

enum OrderListTabsStyle { mine, tabbar }

class OrderListTabs extends StatelessWidget {
  const OrderListTabs({
    super.key,
    required this.selectedStatus,
    required this.onStatusSelected,
    this.style = OrderListTabsStyle.mine,
  });

  final OrderListStatus selectedStatus;
  final ValueChanged<OrderListStatus> onStatusSelected;
  final OrderListTabsStyle style;

  @override
  Widget build(BuildContext context) {
    final screen = ScreenAdapter.of(context);

    return Row(
      children: [
        for (var index = 0; index < OrderListStatus.values.length; index++) ...[
          Expanded(
            child: _OrderTab(
              status: OrderListStatus.values[index],
              selected: OrderListStatus.values[index] == selectedStatus,
              style: style,
              onTap: () => onStatusSelected(OrderListStatus.values[index]),
            ),
          ),
          if (index != OrderListStatus.values.length - 1)
            SizedBox(width: screen.w(5)),
        ],
      ],
    );
  }
}

class _OrderTab extends StatelessWidget {
  const _OrderTab({
    required this.status,
    required this.selected,
    required this.style,
    required this.onTap,
  });

  final OrderListStatus status;
  final bool selected;
  final OrderListTabsStyle style;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final screen = ScreenAdapter.of(context);
    final selectedBackground = style == OrderListTabsStyle.tabbar
        ? AppColors.tabBackground
        : AppColors.ordersTabActiveText;
    final inactiveBackground = style == OrderListTabsStyle.tabbar
        ? AppColors.ordersTabInactive
        : AppColors.settingInfoPanel;
    final selectedTextColor = style == OrderListTabsStyle.tabbar
        ? AppColors.ordersTabActiveText
        : AppColors.ordersYellow;
    final inactiveTextColor = style == OrderListTabsStyle.tabbar
        ? AppColors.ordersTabInactiveText
        : AppColors.settingDeactivateText;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: screen.borderRadiusAll(5),
        onTap: onTap,
        child: Ink(
          height: screen.h(30),
          decoration: BoxDecoration(
            color: selected ? selectedBackground : inactiveBackground,
            borderRadius: screen.borderRadiusAll(5),
          ),
          child: Center(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                status.label,
                maxLines: 1,
                style: TextStyle(
                  color: selected ? selectedTextColor : inactiveTextColor,
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

class OrderListRow extends StatelessWidget {
  const OrderListRow({super.key, required this.item});

  final OrderListItem item;

  @override
  Widget build(BuildContext context) {
    final screen = ScreenAdapter.of(context);
    final actionText = item.actionText.isEmpty ? 'Details' : item.actionText;

    return SizedBox(
      height: screen.h(105),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            right: 0,
            top: screen.h(11),
            child: _OrderActionButton(
              text: actionText,
              isRepay: item.isRepayAction,
            ),
          ),
          _OrderCard(item: item),
        ],
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({required this.item});

  final OrderListItem item;

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
          SizedBox(
            width: screen.w(116),
            child: _OrderAmountBlock(item: item),
          ),
          const Spacer(),
          SizedBox(
            width: screen.w(101),
            child: _OrderStatusBlock(item: item),
          ),
        ],
      ),
    );
  }
}

class _OrderAmountBlock extends StatelessWidget {
  const _OrderAmountBlock({required this.item});

  final OrderListItem item;

  @override
  Widget build(BuildContext context) {
    final screen = ScreenAdapter.of(context);
    final productName = item.productName.isEmpty
        ? 'App Name'
        : item.productName;
    final amountText = item.amountText.isEmpty ? '--' : item.amountText;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _AppNameTag(productName: productName),
        SizedBox(height: screen.h(8)),
        SizedBox(
          height: screen.h(31),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              amountText,
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
  const _AppNameTag({required this.productName});

  final String productName;

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
              productName,
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
  const _OrderStatusBlock({required this.item});

  final OrderListItem item;

  @override
  Widget build(BuildContext context) {
    final screen = ScreenAdapter.of(context);
    final statusText = item.statusText.isEmpty ? '--' : item.statusText;
    final dateValue = item.dateValue.isEmpty ? '--' : item.dateValue;
    final dateLabel = item.dateLabel.isEmpty ? 'Due Date' : item.dateLabel;
    final statusBackground = item.isOverdue
        ? AppColors.ordersOrangeStart
        : AppColors.ordersBlueTag;
    final statusTextColor = item.isOverdue
        ? AppColors.ordersStatusRed
        : AppColors.tabBackground;
    final dateBackground = item.isOverdue
        ? AppColors.ordersDateRedBackground
        : AppColors.ordersDateBlueBackground;
    final dateTextColor = item.isOverdue
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
                statusText,
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
                  dateValue,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: dateTextColor,
                    fontSize: screen.sp(14),
                    fontWeight: FontWeight.w700,
                    height: 17 / 14,
                  ),
                ),
                SizedBox(height: screen.h(3)),
                Text(
                  dateLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
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
  const _OrderActionButton({required this.text, required this.isRepay});

  final String text;
  final bool isRepay;

  @override
  Widget build(BuildContext context) {
    final screen = ScreenAdapter.of(context);

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
            text,
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

class MineOrderEmptyState extends StatelessWidget {
  const MineOrderEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    final screen = ScreenAdapter.of(context);

    return Padding(
      padding: screen.edgeInsetsOnly(top: 138),
      child: Column(
        children: [
          Image.asset(
            AppAssets.mineOrderEmpty,
            width: screen.w(181),
            height: screen.h(158),
            fit: BoxFit.contain,
          ),
          SizedBox(height: screen.h(21)),
          Text(
            'No information available',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.ordersTitleText,
              fontSize: screen.sp(14),
              fontWeight: FontWeight.w400,
              height: 18 / 14,
            ),
          ),
        ],
      ),
    );
  }
}
