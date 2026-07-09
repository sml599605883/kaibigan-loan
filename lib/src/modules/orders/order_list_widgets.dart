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
          if (index != OrderListStatus.values.length - 1) SizedBox(width: 5.w),
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
        borderRadius: BorderRadius.circular(5.r),
        onTap: onTap,
        child: Ink(
          height: 30.h,
          decoration: BoxDecoration(
            color: selected ? selectedBackground : inactiveBackground,
            borderRadius: BorderRadius.circular(5.r),
          ),
          child: Center(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                status.label,
                maxLines: 1,
                style: TextStyle(
                  color: selected ? selectedTextColor : inactiveTextColor,
                  fontSize: 12.sp,
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
    final actionText = item.actionText.isEmpty ? 'Details' : item.actionText;

    return SizedBox(
      height: 105.h,
      child: Row(
        children: [
          Expanded(child: _OrderCard(item: item)),
          _OrderActionButton(text: actionText, isRepay: item.isRepayAction),
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
    return Container(
      height: 105.h,
      padding: EdgeInsets.fromLTRB(12.w, 10.h, 11.w, 10.h),
      decoration: BoxDecoration(
        color: AppColors.tabBackground,
        border: Border.all(color: AppColors.ordersCardBorder),
        borderRadius: BorderRadius.horizontal(
          left: Radius.circular(20.r),
          right: Radius.circular(8.r),
        ),
      ),
      child: Row(
        children: [
          Expanded(child: _OrderAmountBlock(item: item)),
          SizedBox(width: 5.w),
          SizedBox(
            width: 101.w,
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
    final productName = item.productName.isEmpty
        ? 'App Name'
        : item.productName;
    final amountText = item.amountText.isEmpty ? '--' : item.amountText;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _AppNameTag(productName: productName),
        SizedBox(height: 8.h),
        SizedBox(
          height: 31.h,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.center,
            child: Text(
              amountText,
              maxLines: 1,
              style: TextStyle(
                color: AppColors.ordersTitleText,
                fontSize: 26.sp,
                fontWeight: FontWeight.w700,
                height: 31 / 26,
              ),
            ),
          ),
        ),
        Center(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              'Loan Amount',
              maxLines: 1,
              style: TextStyle(
                color: AppColors.ordersLightText,
                fontSize: 14.sp,
                fontWeight: FontWeight.w400,
                height: 17 / 14,
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
    return Container(
      width: double.infinity,
      height: 26.h,
      padding: EdgeInsets.fromLTRB(5.w, 5.h, 5.w, 5.h),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [AppColors.ordersYellow, AppColors.ordersYellowEnd],
        ),
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Row(
        children: [
          Container(
            width: 16.w,
            height: 16.h,
            decoration: const BoxDecoration(
              color: AppColors.tabBackground,
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(width: 4.w),
          Expanded(
            child: Text(
              productName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: AppColors.ordersTitleText,
                fontSize: 12.sp,
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
      padding: EdgeInsets.only(top: 4.h, bottom: 1.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: Container(
              height: 19.h,
              padding: EdgeInsets.symmetric(horizontal: 5.w),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: statusBackground,
                borderRadius: BorderRadius.circular(20.r),
              ),
              child: Text(
                statusText,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: statusTextColor,
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w400,
                  height: 14 / 12,
                ),
              ),
            ),
          ),
          Container(
            width: 101.w,
            height: 44.h,
            padding: EdgeInsets.only(top: 7.h),
            decoration: BoxDecoration(
              color: dateBackground,
              borderRadius: BorderRadius.circular(7.r),
            ),
            child: Column(
              children: [
                Text(
                  dateValue,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: dateTextColor,
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w700,
                    height: 17 / 14,
                  ),
                ),
                SizedBox(height: 3.h),
                Text(
                  dateLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.ordersLightText,
                    fontSize: 10.sp,
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
    return Container(
      width: 77.w,
      height: 83.h,
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
        borderRadius: BorderRadius.horizontal(right: Radius.circular(20.r)),
      ),
      alignment: Alignment.center,
      child: Text(
        text,
        textAlign: TextAlign.center,
        maxLines: 3,
        style: TextStyle(
          color: isRepay
              ? AppColors.tabBackground
              : AppColors.ordersActionBlueText,
          fontSize: 16.sp,
          fontWeight: FontWeight.w700,
          height: 19 / 16,
        ),
      ),
    );
  }
}

class MineOrderEmptyState extends StatelessWidget {
  const MineOrderEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: 138.h),
      child: Column(
        children: [
          Image.asset(
            AppAssets.mineOrderEmpty,
            width: 181.w,
            height: 158.h,
            fit: BoxFit.contain,
          ),
          SizedBox(height: 21.h),
          Text(
            'No information available',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.ordersTitleText,
              fontSize: 14.sp,
              fontWeight: FontWeight.w400,
              height: 18 / 14,
            ),
          ),
        ],
      ),
    );
  }
}
