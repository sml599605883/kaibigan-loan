import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../theme/app_colors.dart';
import '../../utils/screen_adapter.dart';
import 'main_controller.dart';
import 'widgets/home_header.dart';
import 'widgets/loan_card.dart';
import 'widgets/loan_process_section.dart';
import 'widgets/order_status_section.dart';
import 'widgets/promo_banner.dart';
import 'widgets/recommendation_section.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<MainController>();
    return RefreshIndicator(
      color: AppColors.appBackground,
      backgroundColor: AppColors.tabBackground,
      onRefresh: controller.requestHomeDataIfVisible,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 28, 16, 96),
        children: [
          const HomeHeader(),
          Obx(() {
            final topCard = controller.topLoanCardItems.isEmpty
                ? null
                : controller.topLoanCardItems.first;
            return LoanCard(
              onApply: controller.applyTopHeroProduct,
              productName: topCard?.productName ?? '',
              productLogo: topCard?.productLogo ?? '',
              amountRange: topCard?.amountRange ?? '',
              amountRangeDescription: topCard?.amountRangeDescription ?? '',
              termInfo: topCard?.termInfo ?? '',
              termInfoDescription: topCard?.termInfoDescription ?? '',
              loanRate: topCard?.loanRate ?? '',
              loanRateDescription: topCard?.loanRateDescription ?? '',
              loanTermOptions:
                  topCard?.loanTermOptions ?? const <HomeLoanTermOption>[],
              buttonText: topCard?.buttonText ?? '',
            );
          }),
          SizedBox(height: 20.h),
          const PromoBanner(),
          Obx(
            () => controller.banners.isEmpty
                ? const SizedBox.shrink()
                : SizedBox(
                    key: const ValueKey('home_promo_bottom_gap'),
                    height: 20.h,
                  ),
          ),
          const OrderStatusSection(),
          Obx(
            () => controller.orderStatusItems.isEmpty
                ? const SizedBox.shrink()
                : SizedBox(
                    key: const ValueKey('home_order_status_bottom_gap'),
                    height: 20.h,
                  ),
          ),
          const RecommendationSection(),
          Obx(
            () => controller.recommendationItems.isEmpty
                ? const SizedBox.shrink()
                : SizedBox(
                    key: const ValueKey('home_recommendation_bottom_gap'),
                    height: 12.h,
                  ),
          ),
          const LoanProcessSection(),
        ],
      ),
    );
  }
}
