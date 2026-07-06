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
    final buttonText = item.buttonText.isEmpty ? 'Repay' : item.buttonText;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.tabBackground,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: AppColors.ordersCardBorder),
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
                    alignEnd: false,
                  ),
                ),
                SizedBox(width: 22.w),
                Expanded(
                  child: _StatusValuePanel(
                    value: item.dueDate,
                    label: item.dateText.isEmpty ? 'Due Date' : item.dateText,
                    valueColor: AppColors.ordersRedText,
                    badgeText: item.statusText,
                    alignEnd: true,
                  ),
                ),
              ],
            ),
          ),
          Container(height: 1, color: AppColors.ordersCardBorder),
          SizedBox(
            height: 48.h,
            child: Center(
              child: Text(
                buttonText,
                style: TextStyle(
                  color: AppColors.ordersRedText,
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w800,
                  height: 18 / 16,
                ),
              ),
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
    required this.alignEnd,
    this.badgeText = '',
  });

  final String value;
  final String label;
  final Color valueColor;
  final bool alignEnd;
  final String badgeText;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          height: 92.h,
          padding: EdgeInsets.symmetric(horizontal: 10.w),
          decoration: BoxDecoration(
            color: AppColors.ordersDateRedBackground,
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
                gradient: const LinearGradient(
                  colors: [
                    AppColors.ordersOrangeStart,
                    AppColors.ordersOrangeEnd,
                  ],
                ),
                borderRadius: BorderRadius.circular(20.r),
              ),
              child: Text(
                badgeText,
                style: TextStyle(
                  color: AppColors.ordersStatusRed,
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
