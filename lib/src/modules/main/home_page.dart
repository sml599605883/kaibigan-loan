import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../app_routes.dart';
import '../../assets/app_assets.dart';
import '../../theme/app_colors.dart';
import '../widgets/page_panel.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 120),
      children: [
        const Text(
          'Kaibigan Loan',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 28,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 16),
        PagePanel(
          title: 'Find a suitable loan offer',
          subtitle: 'A simple entry page managed by GetX routes.',
          asset: AppAssets.featurePrimary,
          onTap: () => Get.toNamed(AppRoutes.detail),
        ),
        const SizedBox(height: 16),
        Image.asset(AppAssets.complianceLogos),
      ],
    );
  }
}
