import 'package:flutter/material.dart';

import '../../assets/app_assets.dart';
import '../../theme/app_colors.dart';
import '../../utils/screen_adapter.dart';

class AppSectionTitle extends StatelessWidget {
  const AppSectionTitle({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title,
          style: TextStyle(
            color: AppColors.ordersHeaderText,
            fontSize: 18.sp,
            fontWeight: FontWeight.w700,
            height: 22 / 18,
          ),
        ),
        SizedBox(width: 22.w),
        Flexible(
          child: Image.asset(
            AppAssets.titleLine,
            width: 84.w,
            height: 8.h,
            fit: BoxFit.fill,
            alignment: Alignment.centerLeft,
          ),
        ),
      ],
    );
  }
}
