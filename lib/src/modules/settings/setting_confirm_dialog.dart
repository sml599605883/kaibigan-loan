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
    SettingConfirmDialogType.logout => 'Before You Go',
    SettingConfirmDialogType.deleteAccount => 'We’d really miss you.',
  };

  String get _message => switch (type) {
    SettingConfirmDialogType.logout =>
      'Keep your account connected for a smoother experience and quick access to your application details.',
    SettingConfirmDialogType.deleteAccount =>
      'Deleting your account removes all your data, history, and settings forever. This action cannot be undone.',
  };

  String get _confirmText => switch (type) {
    SettingConfirmDialogType.logout => 'Log out anyway',
    SettingConfirmDialogType.deleteAccount => 'Delete Account',
  };

  String get _cancelText => switch (type) {
    SettingConfirmDialogType.logout => 'Stay Logged In',
    SettingConfirmDialogType.deleteAccount => 'Stay Here',
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
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.w),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final fontSize = _fontSizeThatFits(context, constraints);
              return Text(
                label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: textColor,
                  fontSize: fontSize,
                  fontWeight: FontWeight.w700,
                  height: 22 / 18,
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  double _fontSizeThatFits(BuildContext context, BoxConstraints constraints) {
    final maximumFontSize = 18.sp;
    final minimumFontSize = 8.sp;
    final step = 0.5.sp;
    var fontSize = maximumFontSize;
    while (fontSize > minimumFontSize) {
      final painter = TextPainter(
        text: TextSpan(
          text: label,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.w700,
            height: 22 / 18,
          ),
        ),
        maxLines: 2,
        textDirection: Directionality.of(context),
        textScaler: MediaQuery.textScalerOf(context),
      )..layout(maxWidth: constraints.maxWidth);
      final fits =
          !painter.didExceedMaxLines && painter.height <= constraints.maxHeight;
      painter.dispose();
      if (fits) {
        return fontSize;
      }
      fontSize -= step;
    }
    return minimumFontSize;
  }
}
