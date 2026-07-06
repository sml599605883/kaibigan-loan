import 'package:flutter/material.dart';

import '../../assets/app_assets.dart';
import '../../theme/app_colors.dart';
import '../../utils/screen_adapter.dart';

class AppSectionTitle extends StatelessWidget {
  const AppSectionTitle({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final screen = ScreenAdapter.of(context);

    return Row(
      children: [
        Text(
          title,
          style: TextStyle(
            color: AppColors.ordersHeaderText,
            fontSize: screen.sp(18),
            fontWeight: FontWeight.w700,
            height: 22 / 18,
          ),
        ),
        SizedBox(width: screen.w(22)),
        Flexible(
          child: Image.asset(
            AppAssets.titleLine,
            width: screen.w(84),
            height: screen.h(8),
            fit: BoxFit.fill,
            alignment: Alignment.centerLeft,
          ),
        ),
      ],
    );
  }
}
