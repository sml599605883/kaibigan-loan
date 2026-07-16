import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../navigation_helper.dart';
import '../../theme/app_colors.dart';
import '../../utils/screen_adapter.dart';
import '../widgets/setting_popup_background.dart';
import 'home_popup_data.dart';

typedef HomePopupExternalOpener = Future<bool> Function(Uri uri);
typedef HomePopupInAppOpener = void Function(String url);

class HomePopup {
  HomePopup._();

  static const upgradeButtonKey = Key('homePopupUpgradeButton');
  static const marketingImageKey = Key('homePopupMarketingImage');

  static Future<bool> show(
    HomePopupData data, {
    HomePopupExternalOpener? externalOpener,
    HomePopupInAppOpener? inAppOpener,
  }) async {
    if (!data.shouldShow) {
      return false;
    }

    await Get.dialog<void>(
      data.type == HomePopupType.appUpgrade
          ? UpgradePopupContent(data: data, externalOpener: externalOpener)
          : MarketingPopupContent(data: data, inAppOpener: inAppOpener),
      barrierColor: AppColors.settingPopupBarrier,
      barrierDismissible: true,
      transitionDuration: Duration.zero,
    );
    return true;
  }
}

class UpgradePopupContent extends StatelessWidget {
  const UpgradePopupContent({
    super.key,
    required this.data,
    this.externalOpener,
  });

  final HomePopupData data;
  final HomePopupExternalOpener? externalOpener;

  @override
  Widget build(BuildContext context) {
    return SettingPopupBackground(
      child: Stack(
        children: [
          Positioned(
            top: 135.w,
            left: 33.w,
            right: 33.w,
            child: Text(
              'New version released',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.ordersTitleText,
                fontSize: 22.sp,
                fontWeight: FontWeight.w700,
                height: 1,
              ),
            ),
          ),
          if (data.displayVersion.isNotEmpty)
            Positioned(
              top: 173.w,
              left: 33.w,
              right: 33.w,
              child: Text(
                data.displayVersion,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.settingValueText,
                  fontSize: 16.sp,
                  fontStyle: FontStyle.italic,
                  fontWeight: FontWeight.w700,
                  height: 20 / 16,
                ),
              ),
            ),
          Positioned(
            top: 207.w,
            left: 33.w,
            right: 33.w,
            height: 60.w,
            child: Text(
              data.content,
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
          Positioned(
            left: 41.w,
            right: 41.w,
            bottom: 17.w,
            height: 48.w,
            child: GestureDetector(
              key: HomePopup.upgradeButtonKey,
              behavior: HitTestBehavior.opaque,
              onTap: () => _openExternalTarget(
                data.targetUrl,
                externalOpener: externalOpener,
              ),
              child: Container(
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.appBackground,
                  borderRadius: BorderRadius.circular(24.r),
                ),
                child: Text(
                  'Update Now',
                  style: TextStyle(
                    color: AppColors.tabBackground,
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w700,
                    height: 22 / 18,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class MarketingPopupContent extends StatelessWidget {
  const MarketingPopupContent({
    super.key,
    required this.data,
    this.inAppOpener,
  });

  final HomePopupData data;
  final HomePopupInAppOpener? inAppOpener;

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.sizeOf(context);
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: screenSize.width - 48.w,
          maxHeight: screenSize.height - 96.h,
        ),
        child: SingleChildScrollView(
          child: GestureDetector(
            key: HomePopup.marketingImageKey,
            behavior: HitTestBehavior.opaque,
            onTap: () => _openInAppTarget(data.targetUrl, inAppOpener),
            child: Image.network(
              data.imageUrl,
              fit: BoxFit.fitWidth,
              errorBuilder: (_, _, _) => const SizedBox.shrink(),
            ),
          ),
        ),
      ),
    );
  }
}

Future<void> _openExternalTarget(
  String rawUrl, {
  HomePopupExternalOpener? externalOpener,
}) async {
  final uri = Uri.tryParse(rawUrl.trim());
  if (uri == null || !uri.hasScheme) {
    return;
  }
  Get.back<void>();
  await (externalOpener ?? NavigationHelper.defaultRawTargetLauncher)(uri);
}

void _openInAppTarget(String rawUrl, HomePopupInAppOpener? inAppOpener) {
  final url = rawUrl.trim();
  if (url.isEmpty) {
    return;
  }
  Get.back<void>();
  if (inAppOpener != null) {
    inAppOpener(url);
    return;
  }
  NavigationHelper.toWebView<void>(url: url);
}
