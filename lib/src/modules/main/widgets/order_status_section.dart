import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../theme/app_colors.dart';
import '../../../utils/screen_adapter.dart';
import '../../widgets/section_title.dart';
import '../main_controller.dart';

class OrderStatusSection extends StatelessWidget {
  const OrderStatusSection({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<MainController>();
    return Obx(() {
      final items = controller.orderStatusItems.toList(growable: false);
      if (items.isEmpty) {
        return const SizedBox.shrink();
      }
      return Column(
        key: const ValueKey('home_order_status_section'),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppSectionTitle(title: 'Order Status'),
          SizedBox(height: 20.h),
          _OrderStatusCard(item: items.first),
        ],
      );
    });
  }
}

class _OrderStatusCard extends StatelessWidget {
  const _OrderStatusCard({required this.item});

  final HomeOrderStatusItem item;

  @override
  Widget build(BuildContext context) {
    final style = _OrderStatusStyle.resolve(item.cardStatus);
    final actions = _resolveActions(item, style);
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.tabBackground,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: style.borderColor),
      ),
      child: Column(
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: _ProductBadge(item: item),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(39.w, 10.h, 36.w, 14.h),
            child: Row(
              children: [
                Expanded(
                  child: _StatusValuePanel(
                    value: item.amount,
                    label: item.amountText.isEmpty
                        ? 'Loan Amount'
                        : item.amountText,
                    valueColor: AppColors.ordersTitleText,
                    backgroundColor: style.valueBackground,
                    badgeBackground: style.badgeBackground,
                    badgeTextColor: style.badgeTextColor,
                    alignEnd: false,
                  ),
                ),
                SizedBox(width: 22.w),
                Expanded(
                  child: _StatusValuePanel(
                    value: item.dueDate,
                    label: item.dateText.isEmpty ? 'Due Date' : item.dateText,
                    valueColor: style.dateValueColor,
                    badgeText: item.statusText,
                    badgeBackground: style.badgeBackground,
                    badgeTextColor: style.badgeTextColor,
                    backgroundColor: style.valueBackground,
                    alignEnd: true,
                  ),
                ),
              ],
            ),
          ),
          Container(height: 1, color: style.borderColor),
          _ActionBar(actions: actions, style: style),
        ],
      ),
    );
  }
}

class _ProductBadge extends StatelessWidget {
  const _ProductBadge({required this.item});

  final HomeOrderStatusItem item;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 37.h,
      constraints: BoxConstraints(minWidth: 106.w),
      padding: EdgeInsets.symmetric(horizontal: 14.w),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [AppColors.ordersYellow, AppColors.ordersYellowEnd],
        ),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20.r),
          topRight: Radius.circular(20.r),
          bottomRight: Radius.circular(20.r),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _Logo(imageUrl: item.productLogo, size: 16.w),
          SizedBox(width: 5.w),
          Text(
            item.productName.isEmpty ? 'App Name' : item.productName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: AppColors.ordersTitleText,
              fontSize: 12.sp,
              fontWeight: FontWeight.w800,
              height: 14 / 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusValuePanel extends StatelessWidget {
  const _StatusValuePanel({
    required this.value,
    required this.label,
    required this.valueColor,
    required this.backgroundColor,
    required this.alignEnd,
    required this.badgeBackground,
    required this.badgeTextColor,
    this.badgeText = '',
  });

  final String value;
  final String label;
  final Color valueColor;
  final Color backgroundColor;
  final bool alignEnd;
  final String badgeText;
  final Color badgeBackground;
  final Color badgeTextColor;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          height: 92.h,
          padding: EdgeInsets.symmetric(horizontal: 10.w),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(10.r),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: alignEnd
                ? CrossAxisAlignment.end
                : CrossAxisAlignment.start,
            children: [
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  value,
                  maxLines: 1,
                  style: TextStyle(
                    color: valueColor,
                    fontSize: 20.sp,
                    fontWeight: FontWeight.w800,
                    height: 24 / 20,
                  ),
                ),
              ),
              SizedBox(height: 2.h),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: AppColors.ordersMutedText,
                  fontSize: 12.sp,
                  height: 14 / 12,
                ),
              ),
            ],
          ),
        ),
        if (badgeText.isNotEmpty)
          Positioned(
            top: -14.h,
            right: 9.w,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 7.w, vertical: 2.h),
              decoration: BoxDecoration(
                color: badgeBackground,
                borderRadius: BorderRadius.circular(20.r),
              ),
              child: Text(
                badgeText,
                style: TextStyle(
                  color: badgeTextColor,
                  fontSize: 12.sp,
                  height: 14 / 12,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _ActionBar extends StatelessWidget {
  const _ActionBar({required this.actions, required this.style});

  final List<HomeOrderStatusAction> actions;
  final _OrderStatusStyle style;

  @override
  Widget build(BuildContext context) {
    if (actions.isEmpty) {
      return SizedBox(height: 48.h);
    }
    return SizedBox(
      height: 48.h,
      child: Row(
        children: [
          for (var index = 0; index < actions.length; index++) ...[
            Expanded(
              child: Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 6.w),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      actions[index].text,
                      maxLines: 1,
                      style: TextStyle(
                        color: index == 0 && actions.length > 1
                            ? style.secondaryActionTextColor
                            : style.primaryActionTextColor,
                        fontSize: actions.length > 1 ? 14.sp : 16.sp,
                        fontWeight: FontWeight.w800,
                        height: 18 / 16,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            if (index != actions.length - 1)
              Container(width: 1, height: 48.h, color: style.borderColor),
          ],
        ],
      ),
    );
  }
}

class _Logo extends StatelessWidget {
  const _Logo({required this.imageUrl, required this.size});

  final String imageUrl;
  final double size;

  @override
  Widget build(BuildContext context) {
    final placeholder = Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        color: AppColors.tabBackground,
        shape: BoxShape.circle,
      ),
    );
    if (imageUrl.isEmpty) {
      return placeholder;
    }
    return ClipOval(
      child: Image.network(
        imageUrl,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => placeholder,
      ),
    );
  }
}

List<HomeOrderStatusAction> _resolveActions(
  HomeOrderStatusItem item,
  _OrderStatusStyle style,
) {
  final deliveredActions = item.actions.take(2).toList(growable: false);
  if (deliveredActions.isNotEmpty) {
    return deliveredActions;
  }
  final fallbackText = item.buttonText.trim();
  if (fallbackText.isNotEmpty) {
    return [
      HomeOrderStatusAction(
        type: 'fallback',
        text: fallbackText,
        url: item.actionUrl,
        visible: true,
      ),
    ];
  }
  return [
    HomeOrderStatusAction(
      type: style.fallbackActionType,
      text: style.fallbackActionText,
      url: item.actionUrl,
      visible: true,
    ),
  ];
}

class _OrderStatusStyle {
  const _OrderStatusStyle({
    required this.borderColor,
    required this.valueBackground,
    required this.dateValueColor,
    required this.badgeBackground,
    required this.badgeTextColor,
    required this.primaryActionTextColor,
    required this.secondaryActionTextColor,
    required this.fallbackActionType,
    required this.fallbackActionText,
  });

  final Color borderColor;
  final Color valueBackground;
  final Color dateValueColor;
  final Color badgeBackground;
  final Color badgeTextColor;
  final Color primaryActionTextColor;
  final Color secondaryActionTextColor;
  final String fallbackActionType;
  final String fallbackActionText;

  static _OrderStatusStyle resolve(int status) {
    switch (status) {
      case 1:
      case 4:
        return const _OrderStatusStyle(
          borderColor: AppColors.ordersCardBorder,
          valueBackground: AppColors.ordersDateBlueBackground,
          dateValueColor: AppColors.ordersTitleText,
          badgeBackground: AppColors.ordersBlueTag,
          badgeTextColor: AppColors.tabBackground,
          primaryActionTextColor: AppColors.ordersTitleText,
          secondaryActionTextColor: AppColors.ordersTitleText,
          fallbackActionType: 'detail',
          fallbackActionText: 'Details',
        );
      case 5:
        return const _OrderStatusStyle(
          borderColor: AppColors.ordersDateRedBackground,
          valueBackground: AppColors.ordersDateRedBackground,
          dateValueColor: AppColors.ordersTitleText,
          badgeBackground: AppColors.ordersOrangeEnd,
          badgeTextColor: AppColors.ordersStatusRed,
          primaryActionTextColor: AppColors.ordersRedText,
          secondaryActionTextColor: AppColors.ordersOrangeEnd,
          fallbackActionType: 'change',
          fallbackActionText: 'Change Account',
        );
      case 2:
      case 3:
      case 6:
      default:
        return const _OrderStatusStyle(
          borderColor: AppColors.ordersDateRedBackground,
          valueBackground: AppColors.ordersDateRedBackground,
          dateValueColor: AppColors.ordersRedText,
          badgeBackground: AppColors.ordersOrangeEnd,
          badgeTextColor: AppColors.ordersStatusRed,
          primaryActionTextColor: AppColors.ordersRedText,
          secondaryActionTextColor: AppColors.ordersOrangeEnd,
          fallbackActionType: 'repay',
          fallbackActionText: 'Repay',
        );
    }
  }
}
