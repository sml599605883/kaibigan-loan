import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/network/api_client.dart';
import '../../theme/app_colors.dart';
import '../../utils/app_toast.dart';
import '../../utils/screen_adapter.dart';

typedef RetentionPopupPresenter =
    Future<bool> Function({
      required String type,
      required String productId,
      required VoidCallback onExit,
    });

class RetentionPopup {
  RetentionPopup._();

  static const exitButtonKey = Key('retentionPopupExitButton');
  static const continueButtonKey = Key('retentionPopupContinueButton');

  static Future<bool> show({
    required String type,
    required String productId,
    required VoidCallback onExit,
    ApiClient? apiClient,
  }) async {
    final normalizedType = type.trim();
    final normalizedProductId = productId.trim();
    if (normalizedType.isEmpty || normalizedProductId.isEmpty) {
      return false;
    }

    var ownsLoading = true;
    await AppToast.showLoading();
    try {
      final response = await (apiClient ?? ApiClient.instance).retainPopup(
        bellyache: normalizedType,
        seamounts: normalizedProductId,
      );
      final dialog = response.states['misaligned'];
      final imageUrl = dialog['bloomeries'].stringValue.trim();
      await AppToast.dismissLoading();
      ownsLoading = false;
      if (imageUrl.isEmpty) {
        return false;
      }
      final exitText = dialog['ensanguine'].stringValue.trim();
      final continueText = dialog['sleeved'].stringValue.trim();
      await Get.dialog<void>(
        RetentionPopupContent(
          imageUrl: imageUrl,
          exitText: exitText.isEmpty ? 'Exit' : exitText,
          continueText: continueText.isEmpty ? 'Continue' : continueText,
          onExit: onExit,
        ),
        barrierColor: AppColors.uploadMethodBarrier,
        transitionDuration: Duration.zero,
      );
      return true;
    } catch (error) {
      if (ownsLoading) {
        await AppToast.dismissLoading();
      }
      debugPrint('Retention popup request failed: $error');
      return false;
    }
  }
}

class RetentionPopupContent extends StatelessWidget {
  const RetentionPopupContent({
    super.key,
    required this.imageUrl,
    required this.exitText,
    required this.continueText,
    required this.onExit,
  });

  static const _designWidth = 315.0;
  static const _designHeight = 412.0;

  final String imageUrl;
  final String exitText;
  final String continueText;
  final VoidCallback onExit;

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.sizeOf(context);
    final width = math.min(315.w, screenSize.width - 32.w);
    final height = width * (_designHeight / _designWidth);
    return Center(
      child: SizedBox(
        width: width,
        height: height,
        child: Stack(
          children: [
            Positioned.fill(
              child: Image.network(
                imageUrl,
                fit: BoxFit.fill,
                errorBuilder: (_, _, _) => const SizedBox.shrink(),
              ),
            ),
            Positioned(
              left: 25.w,
              right: 25.w,
              bottom: 17.h,
              child: Row(
                children: [
                  Expanded(
                    child: _RetentionPopupButton(
                      key: RetentionPopup.exitButtonKey,
                      label: exitText,
                      backgroundColor: AppColors.settingDeactivateBorder,
                      textColor: AppColors.certificationTitleText,
                      onTap: () {
                        Get.back<void>();
                        onExit();
                      },
                    ),
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: _RetentionPopupButton(
                      key: RetentionPopup.continueButtonKey,
                      label: continueText,
                      backgroundColor: AppColors.certificationTabActive,
                      textColor: AppColors.certificationSubmitText,
                      onTap: Get.back<void>,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RetentionPopupButton extends StatelessWidget {
  const _RetentionPopupButton({
    super.key,
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
        height: 48.h,
        alignment: Alignment.center,
        padding: EdgeInsets.symmetric(horizontal: 8.w),
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
          ),
        ),
      ),
    );
  }
}
