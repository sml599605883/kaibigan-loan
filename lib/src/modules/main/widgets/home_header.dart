import 'package:flutter/material.dart';

import '../../../assets/app_assets.dart';
import '../../../navigation_helper.dart';
import '../../../theme/app_colors.dart';

class HomeHeader extends StatelessWidget {
  const HomeHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(
          child: Text(
            'Hi! Welcome',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 30,
              fontWeight: FontWeight.w800,
              height: 1.1,
            ),
          ),
        ),
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: NavigationHelper.toCustomerService<void>,
          child: Image.asset(AppAssets.homeServiceIcon, width: 35, height: 35),
        ),
      ],
    );
  }
}
