import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../theme/app_colors.dart';
import '../../utils/screen_adapter.dart';
import '../widgets/setting_popup_background.dart';

enum SettingConfirmDialogType { logout, deleteAccount }

class SettingConfirmDialog extends StatelessWidget {
  const SettingConfirmDialog({
    super.key,
    required this.type,
    required this.onConfirm,
  });

  final SettingConfirmDialogType type;
  final VoidCallback onConfirm;

  String get _title => switch (type) {
    SettingConfirmDialogType.logout => 'Stay Signed In',
    SettingConfirmDialogType.deleteAccount => 'Delete Your Account?',
  };

  String get _message => switch (type) {
    SettingConfirmDialogType.logout =>
      'Staying logged in ensures you can access funds in seconds whenever you need them.',
    SettingConfirmDialogType.deleteAccount =>
      'Deleting your account will remove your loan records and current benefits.',
  };

  String get _confirmText => switch (type) {
    SettingConfirmDialogType.logout => 'Logout',
    SettingConfirmDialogType.deleteAccount => 'Delete',
  };

  String get _cancelText => switch (type) {
    SettingConfirmDialogType.logout => 'Cancel',
    SettingConfirmDialogType.deleteAccount => 'Keep',
  };

  @override
  Widget build(BuildContext context) {
    return SettingPopupBackground(
      child: Stack(
        children: [
          Positioned(
            top: 141.w,
            left: 27.w,
            right: 27.w,
            child: Text(
              _title,
              maxLines: 1,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.ordersTitleText,
                fontSize: 22.sp,
                fontWeight: FontWeight.w700,
                height: 1,
              ),
            ),
          ),
          Positioned(
            top: 199.w,
            left: 27.w,
            right: 27.w,
            height: 60.w,
            child: Center(
              child: Text(
                _message,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.settingValueText,
                  fontSize: 16.sp,
                  height: 20 / 16,
                ),
              ),
            ),
          ),
          Positioned(
            left: 27.w,
            right: 27.w,
            bottom: 17.w,
            height: 48.w,
            child: Row(
              children: [
                Expanded(
                  child: _SettingPopupButton(
                    label: _confirmText,
                    backgroundColor: AppColors.settingDeactivateBorder,
                    textColor: AppColors.settingPopupSecondaryText,
                    onTap: () {
                      Get.back<void>();
                      onConfirm();
                    },
                  ),
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: _SettingPopupButton(
                    label: _cancelText,
                    backgroundColor: AppColors.appBackground,
                    textColor: AppColors.tabBackground,
                    onTap: Get.back<void>,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingPopupButton extends StatelessWidget {
  const _SettingPopupButton({
    required this.label,
    required this.backgroundColor,
    required this.textColor,
    required this.onTap,
  });

  final String label;
  final Color backgroundColor;
  final Color textColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(24.r),
        ),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: textColor,
            fontSize: 18.sp,
            fontWeight: FontWeight.w700,
            height: 22 / 18,
          ),
        ),
      ),
    );
  }
}
