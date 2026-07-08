import 'package:flutter/material.dart';

import '../../../assets/app_assets.dart';
import '../../../theme/app_colors.dart';
import '../../../utils/screen_adapter.dart';

class CertificationPromptBanner extends StatelessWidget {
  const CertificationPromptBanner({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52.h,
      margin: EdgeInsets.symmetric(horizontal: 20.w),
      padding: EdgeInsets.fromLTRB(5.w, 4.h, 25.w, 4.h),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            AppColors.certificationPromptStart,
            AppColors.certificationPromptEnd,
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(10.r),
      ),
      child: Row(
        children: [
          Image.asset(
            AppAssets.certificationPromptIcon,
            width: 42.w,
            height: 44.h,
            fit: BoxFit.contain,
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Text(
              message,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: AppColors.certificationPromptText,
                fontSize: 12.sp,
                fontWeight: FontWeight.w400,
                height: 16 / 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
