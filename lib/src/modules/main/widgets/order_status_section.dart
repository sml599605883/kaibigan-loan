import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../theme/app_colors.dart';
import '../../../utils/screen_adapter.dart';
import '../../widgets/section_title.dart';
import '../main_controller.dart';

typedef _OrderStatusActionTap =
    void Function(HomeOrderStatusItem item, HomeOrderStatusAction action);

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
          _OrderStatusCarousel(
            items: items,
            onTap: controller.handleOrderStatusTap,
            onActionTap: controller.handleOrderStatusButtonTap,
          ),
        ],
      );
    });
  }
}

class _OrderStatusCarousel extends StatefulWidget {
  const _OrderStatusCarousel({
    required this.items,
    required this.onTap,
    required this.onActionTap,
  });

  final List<HomeOrderStatusItem> items;
  final ValueChanged<HomeOrderStatusItem> onTap;
  final _OrderStatusActionTap onActionTap;

  @override
  State<_OrderStatusCarousel> createState() => _OrderStatusCarouselState();
}

class _OrderStatusCarouselState extends State<_OrderStatusCarousel> {
  late PageController _pageController;
  Timer? _timer;
  int _initialPage = 0;

  @override
  void initState() {
    super.initState();
    _resetController();
    _startTimer();
  }

  @override
  void didUpdateWidget(covariant _OrderStatusCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.items.length != widget.items.length) {
      _timer?.cancel();
      _pageController.dispose();
      _resetController();
      _startTimer();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _resetController() {
    _initialPage = widget.items.length > 1 ? widget.items.length * 1000 : 0;
    _pageController = PageController(initialPage: _initialPage);
  }

  void _startTimer() {
    if (widget.items.length < 2) {
      return;
    }
    _timer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (!mounted || !_pageController.hasClients) {
        return;
      }
      final currentPage = _pageController.page?.round() ?? _initialPage;
      _pageController.animateToPage(
        currentPage + 1,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: SizedBox(
        key: const ValueKey('home_order_status_carousel'),
        height: 154.h,
        child: PageView.builder(
          controller: _pageController,
          itemCount: widget.items.length == 1 ? 1 : null,
          itemBuilder: (context, pageIndex) {
            final item = widget.items[pageIndex % widget.items.length];
            return Padding(
              padding: EdgeInsets.only(top: 12.h),
              child: _OrderStatusCard(
                item: item,
                onTap: () => widget.onTap(item),
                onActionTap: (action) => widget.onActionTap(item, action),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _OrderStatusCard extends StatelessWidget {
  const _OrderStatusCard({
    required this.item,
    required this.onTap,
    required this.onActionTap,
  });

  final HomeOrderStatusItem item;
  final VoidCallback onTap;
  final ValueChanged<HomeOrderStatusAction> onActionTap;

  @override
  Widget build(BuildContext context) {
    final style = _OrderStatusStyle.resolve(item.cardStatus);
    final actions = _resolveActions(item, style);
    return SizedBox(
      key: const ValueKey('home_order_status_card'),
      width: double.infinity,
      height: 142.h,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.tabBackground,
                borderRadius: BorderRadius.circular(20.r),
                border: Border.all(color: style.borderColor),
              ),
            ),
          ),
          Column(
            children: [
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: onTap,
                child: SizedBox(
                  height: 101.h,
                  child: Stack(
                    children: [
                      Positioned(
                        top: 32.h,
                        left: 25.w,
                        right: 24.w,
                        child: Row(
                          children: [
                            Expanded(
                              child: _StatusValuePanel(
                                key: const ValueKey(
                                  'home_order_status_amount_panel',
                                ),
                                value: item.amount,
                                label: item.amountText.isEmpty
                                    ? 'Loan Amount'
                                    : item.amountText,
                                valueColor: AppColors.ordersTitleText,
                                backgroundColor: style.valueBackground,
                                badgeBackground: style.badgeBackground,
                                badgeGradient: style.badgeGradient,
                                badgeTextColor: style.badgeTextColor,
                                alignEnd: false,
                              ),
                            ),
                            SizedBox(width: 14.w),
                            Expanded(
                              child: _StatusValuePanel(
                                key: const ValueKey(
                                  'home_order_status_date_panel',
                                ),
                                value: item.dueDate,
                                label: item.dateText.isEmpty
                                    ? 'Due Date'
                                    : item.dateText,
                                valueColor: style.dateValueColor,
                                badgeText: item.statusText,
                                badgeBackground: style.badgeBackground,
                                badgeGradient: style.badgeGradient,
                                badgeTextColor: style.badgeTextColor,
                                backgroundColor: style.valueBackground,
                                alignEnd: true,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        child: Container(height: 1, color: style.borderColor),
                      ),
                    ],
                  ),
                ),
              ),
              _ActionBar(
                actions: actions,
                style: style,
                onTap: onTap,
                onActionTap: onActionTap,
              ),
            ],
          ),
          Positioned(
            top: -12.h,
            left: 0,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onTap,
              child: _ProductBadge(item: item),
            ),
          ),
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
      key: const ValueKey('home_order_status_product_badge'),
      height: 37.h,
      constraints: BoxConstraints(maxWidth: 200.w),
      padding: EdgeInsets.symmetric(horizontal: 14.w),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [AppColors.ordersBadgeStart, AppColors.ordersYellowEnd],
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
          Flexible(
            fit: FlexFit.loose,
            child: Text(
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
          ),
        ],
      ),
    );
  }
}

class _StatusValuePanel extends StatelessWidget {
  const _StatusValuePanel({
    super.key,
    required this.value,
    required this.label,
    required this.valueColor,
    required this.backgroundColor,
    required this.alignEnd,
    required this.badgeBackground,
    required this.badgeGradient,
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
  final Gradient? badgeGradient;
  final Color badgeTextColor;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          height: 58.h,
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
            top: -15.h,
            right: 9.w,
            child: Container(
              height: 19.h,
              padding: EdgeInsets.symmetric(horizontal: 7.w),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: badgeGradient == null ? badgeBackground : null,
                gradient: badgeGradient,
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
  const _ActionBar({
    required this.actions,
    required this.style,
    required this.onTap,
    required this.onActionTap,
  });

  final List<HomeOrderStatusAction> actions;
  final _OrderStatusStyle style;
  final VoidCallback onTap;
  final ValueChanged<HomeOrderStatusAction> onActionTap;

  @override
  Widget build(BuildContext context) {
    if (actions.isEmpty) {
      return SizedBox(
        key: const ValueKey('home_order_status_action_bar'),
        height: 41.h,
      );
    }
    return SizedBox(
      key: const ValueKey('home_order_status_action_bar'),
      height: 41.h,
      child: Row(
        children: [
          for (var index = 0; index < actions.length; index++) ...[
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _tapForAction(actions[index]),
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
                          height: actions.length > 1 ? 18 / 14 : 18 / 16,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            if (index != actions.length - 1)
              Container(width: 1, height: 41.h, color: style.borderColor),
          ],
        ],
      ),
    );
  }

  VoidCallback? _tapForAction(HomeOrderStatusAction action) {
    switch (action.type.trim().toLowerCase()) {
      case 'detail':
      case 'fallback':
      case 'repay':
        return onTap;
      case 'retry':
      case 'change':
        return () => onActionTap(action);
      default:
        return null;
    }
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
        url: '',
        visible: true,
      ),
    ];
  }
  return [
    HomeOrderStatusAction(
      type: style.fallbackActionType,
      text: style.fallbackActionText,
      url: '',
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
    required this.badgeGradient,
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
  final Gradient? badgeGradient;
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
          badgeGradient: null,
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
          badgeGradient: LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [AppColors.ordersOrangeStart, AppColors.ordersOrangeEnd],
          ),
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
          badgeGradient: LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [AppColors.ordersOrangeStart, AppColors.ordersOrangeEnd],
          ),
          badgeTextColor: AppColors.ordersStatusRed,
          primaryActionTextColor: AppColors.ordersRedText,
          secondaryActionTextColor: AppColors.ordersOrangeEnd,
          fallbackActionType: 'repay',
          fallbackActionText: 'Repay',
        );
    }
  }
}
