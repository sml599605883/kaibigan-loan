import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../navigation_helper.dart';
import '../../../theme/app_colors.dart';
import '../../../utils/screen_adapter.dart';
import '../../widgets/section_title.dart';
import '../main_controller.dart';

class RecommendationSection extends StatelessWidget {
  const RecommendationSection({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<MainController>();
    return Obx(() {
      final items = controller.recommendationItems.toList(growable: false);
      if (items.isEmpty) {
        return const SizedBox.shrink();
      }
      return Column(
        key: const ValueKey('home_recommendation_section'),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppSectionTitle(title: 'Recommendation'),
          SizedBox(height: 16.h),
          ...items.map(
            (item) => Padding(
              padding: EdgeInsets.only(bottom: 16.h),
              child: _RecommendationCard(item: item),
            ),
          ),
        ],
      );
    });
  }
}

class _RecommendationCard extends StatelessWidget {
  const _RecommendationCard({required this.item});

  final HomeRecommendationItem item;

  @override
  Widget build(BuildContext context) {
    final buttonText = item.buttonText.isEmpty ? 'Apply Now' : item.buttonText;
    final canApply = item.productId.isNotEmpty && item.canApply;
    return GestureDetector(
      key: ValueKey('home_recommendation_${item.productId}'),
      behavior: HitTestBehavior.opaque,
      onTap: canApply
          ? () => NavigationHelper.applyProduct(item.productId)
          : null,
      child: SizedBox(
        height: 105.h,
        child: Stack(
          children: [
            Positioned(
              top: 11.h,
              right: 0,
              child: Container(
                width: 168.w,
                height: 83.h,
                alignment: Alignment.centerRight,
                padding: EdgeInsets.only(right: 12.w),
                decoration: BoxDecoration(
                  color: canApply
                      ? null
                      : AppColors.recommendationButtonDisabled,
                  gradient: canApply
                      ? const LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          colors: [
                            AppColors.ordersYellow,
                            AppColors.ordersYellowEnd,
                          ],
                        )
                      : null,
                  borderRadius: BorderRadius.circular(20.r),
                ),
                child: SizedBox(
                  width: 72.w,
                  child: Text(
                    buttonText,
                    maxLines: 2,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.ordersActionBlueText,
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w800,
                      height: 19 / 16,
                    ),
                  ),
                ),
              ),
            ),
            Positioned.fill(
              right: 77.w,
              child: Container(
                padding: EdgeInsets.fromLTRB(20.w, 10.h, 16.w, 10.h),
                decoration: BoxDecoration(
                  color: AppColors.tabBackground,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20.r),
                    bottomLeft: Radius.circular(20.r),
                    topRight: Radius.circular(8.r),
                    bottomRight: Radius.circular(8.r),
                  ),
                  border: Border.all(color: AppColors.ordersCardBorder),
                ),
                child: Row(
                  children: [
                    Expanded(child: _ProductSummary(item: item)),
                    SizedBox(width: 12.w),
                    SizedBox(
                      width: 130.w,
                      child: Column(
                        children: [
                          _InfoPill(
                            value: item.termInfo,
                            label: item.termInfoDescription.isEmpty
                                ? 'Loan Term'
                                : item.termInfoDescription,
                          ),
                          SizedBox(height: 10.h),
                          _InfoPill(
                            value: item.loanRate,
                            label: item.loanRateDescription.isEmpty
                                ? 'Interest rate'
                                : item.loanRateDescription,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProductSummary extends StatelessWidget {
  const _ProductSummary({required this.item});

  final HomeRecommendationItem item;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ProductBadge(item: item),
        const Spacer(),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            item.amountRange,
            maxLines: 1,
            style: TextStyle(
              color: AppColors.ordersTitleText,
              fontSize: 26.sp,
              fontWeight: FontWeight.w800,
              height: 31 / 26,
            ),
          ),
        ),
        Text(
          item.amountRangeDescription.isEmpty
              ? 'Available up to'
              : item.amountRangeDescription,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: AppColors.ordersLightText,
            fontSize: 14.sp,
            height: 17 / 14,
          ),
        ),
      ],
    );
  }
}

class _ProductBadge extends StatelessWidget {
  const _ProductBadge({required this.item});

  final HomeRecommendationItem item;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 26.h,
      constraints: BoxConstraints(minWidth: 94.w),
      padding: EdgeInsets.symmetric(horizontal: 7.w),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [AppColors.ordersYellow, AppColors.ordersYellowEnd],
        ),
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _Logo(imageUrl: item.productLogo, size: 16.w),
          SizedBox(width: 5.w),
          Flexible(
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

class _InfoPill extends StatelessWidget {
  const _InfoPill({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppColors.ordersDateBlueBackground,
          borderRadius: BorderRadius.circular(7.r),
        ),
        padding: EdgeInsets.symmetric(horizontal: 8.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                maxLines: 1,
                style: TextStyle(
                  color: AppColors.ordersTitleText,
                  fontSize: 14.sp,
                ),
              ),
            ),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: AppColors.homeProcessInactiveText,
                fontSize: 10.sp,
                height: 12 / 10,
              ),
            ),
          ],
        ),
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
