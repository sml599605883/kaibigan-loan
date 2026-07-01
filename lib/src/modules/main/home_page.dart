import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../theme/app_colors.dart';
import '../../utils/screen_adapter.dart';
import 'main_controller.dart';
import 'widgets/home_header.dart';
import 'widgets/loan_card.dart';
import 'widgets/loan_process_section.dart';
import 'widgets/promo_banner.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: AppColors.appBackground,
      backgroundColor: AppColors.tabBackground,
      onRefresh: () => Get.find<MainController>().requestHomeDataIfVisible(),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 28, 16, 96),
        children: [
          const HomeHeader(),
          const LoanCard(),
          SizedBox(height: 20.h),
          const PromoBanner(),
          SizedBox(height: 28.h),
          const LoanProcessSection(),
        ],
      ),
    );
  }
}
