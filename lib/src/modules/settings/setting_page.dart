import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../assets/app_assets.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_exception.dart';
import '../../core/session/session_store.dart';
import '../main/main_controller.dart';
import '../../theme/app_colors.dart';
import '../../utils/app_toast.dart';
import '../../utils/screen_adapter.dart';

class SettingPage extends StatelessWidget {
  const SettingPage({super.key});

  static const _website = 'XXXXXXXXXXXXXXX';
  static const _email = 'XXXXXXX';
  static const _version = 'V1.1.1';

  @override
  Widget build(BuildContext context) {
    final screen = ScreenAdapter.of(context);

    return Scaffold(
      backgroundColor: AppColors.tabBackground,
      body: SafeArea(
        bottom: false,
        child: SizedBox.expand(
          child: Padding(
            padding: screen.edgeInsetsFromLTRB(20, 16, 14, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _SettingHeader(screen: screen),
                SizedBox(height: screen.h(76)),
                _AppIdentity(screen: screen),
                SizedBox(height: screen.h(45)),
                _InfoPanel(screen: screen),
                const Spacer(),
                _SettingActionButton(
                  label: 'Deactivate Account',
                  foregroundColor: AppColors.settingDeactivateText,
                  backgroundColor: AppColors.tabBackground,
                  borderColor: AppColors.settingDeactivateBorder,
                  fontWeight: FontWeight.w400,
                  onTap: () => _deactivateAccount(context),
                ),
                SizedBox(height: screen.h(10)),
                _SettingActionButton(
                  label: 'Logout',
                  foregroundColor: AppColors.tabBackground,
                  backgroundColor: AppColors.appBackground,
                  fontWeight: FontWeight.w700,
                  onTap: () => _logout(context),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static Future<void> _logout(BuildContext context) async {
    var shouldDismissLoading = true;
    try {
      await AppToast.showLoading();
      await ApiClient.instance.logout();
      await SessionStore.instance.clearPersistent();
      await SessionStore.instance.clearCache();
      if (context.mounted) {
        _returnToHomeTab();
        Get.back<void>();
      }
    } catch (error) {
      await AppToast.show(ApiErrorMessage.resolve(error));
      shouldDismissLoading = false;
    } finally {
      if (shouldDismissLoading) {
        await AppToast.dismissLoading();
      }
    }
  }

  static Future<void> _deactivateAccount(BuildContext context) async {
    var shouldDismissLoading = true;
    try {
      await AppToast.showLoading();
      await ApiClient.instance.userDelete();
      await SessionStore.instance.clearPersistent();
      await SessionStore.instance.clearCache();
      if (context.mounted) {
        _returnToHomeTab();
        Get.back<void>();
      }
    } catch (error) {
      await AppToast.show(ApiErrorMessage.resolve(error));
      shouldDismissLoading = false;
    } finally {
      if (shouldDismissLoading) {
        await AppToast.dismissLoading();
      }
    }
  }

  static void _returnToHomeTab() {
    if (Get.isRegistered<MainController>()) {
      Get.find<MainController>().returnToHomeTab();
    }
  }
}

class _SettingHeader extends StatelessWidget {
  const _SettingHeader({required this.screen});

  final ScreenAdapter screen;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: screen.h(24),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: screen.borderRadiusAll(20),
                onTap: Get.back<void>,
                child: SizedBox(
                  width: screen.w(48),
                  height: screen.h(40),
                  child: Image.asset(
                    AppAssets.loginBack,
                    color: AppColors.ordersTitleText,
                    width: 24.w,
                    height: 24.h,
                  ),
                ),
              ),
            ),
          ),
          Text(
            'Setting',
            maxLines: 1,
            style: TextStyle(
              color: AppColors.ordersTitleText,
              fontSize: screen.sp(20),
              fontWeight: FontWeight.w700,
              height: 24 / 20,
              letterSpacing: 0.07756407558917999,
            ),
          ),
        ],
      ),
    );
  }
}

class _AppIdentity extends StatelessWidget {
  const _AppIdentity({required this.screen});

  final ScreenAdapter screen;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ClipOval(
          child: Image.asset(
            AppAssets.settingLogo,
            fit: BoxFit.cover,
            width: 88.w,
            height: 88.h,
          ),
        ),
        SizedBox(height: screen.h(13)),
        Text(
          'Kaibigan Loan',
          maxLines: 1,
          style: TextStyle(
            color: AppColors.ordersTitleText,
            fontSize: screen.sp(20),
            fontWeight: FontWeight.w700,
            height: 24 / 20,
            letterSpacing: 0.07756407558917999,
          ),
        ),
      ],
    );
  }
}

class _InfoPanel extends StatelessWidget {
  const _InfoPanel({required this.screen});

  final ScreenAdapter screen;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: screen.edgeInsetsOnly(right: 6),
      padding: screen.edgeInsetsAll(10),
      decoration: BoxDecoration(
        color: AppColors.settingInfoPanel,
        borderRadius: screen.borderRadiusAll(20),
      ),
      child: Column(
        children: [
          _InfoRow(
            screen: screen,
            label: 'Website',
            value: SettingPage._website,
          ),
          SizedBox(height: screen.h(10)),
          _InfoRow(screen: screen, label: 'E-mail', value: SettingPage._email),
          SizedBox(height: screen.h(10)),
          _InfoRow(
            screen: screen,
            label: 'Version',
            value: SettingPage._version,
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.screen,
    required this.label,
    required this.value,
  });

  final ScreenAdapter screen;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: screen.h(43),
      padding: screen.edgeInsetsFromLTRB(19, 0, 20, 0),
      decoration: BoxDecoration(
        color: AppColors.tabBackground,
        borderRadius: screen.borderRadiusAll(20),
      ),
      child: Row(
        children: [
          Text(
            label,
            maxLines: 1,
            style: TextStyle(
              color: AppColors.settingLabelText,
              fontSize: screen.sp(16),
              fontWeight: FontWeight.w400,
              height: 19 / 16,
            ),
          ),
          Expanded(
            child: Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.right,
              style: TextStyle(
                color: AppColors.settingValueText,
                fontSize: screen.sp(16),
                fontWeight: FontWeight.w400,
                height: 19 / 16,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingActionButton extends StatelessWidget {
  const _SettingActionButton({
    required this.label,
    required this.foregroundColor,
    required this.backgroundColor,
    required this.fontWeight,
    required this.onTap,
    this.borderColor,
  });

  final String label;
  final Color foregroundColor;
  final Color backgroundColor;
  final Color? borderColor;
  final FontWeight fontWeight;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final screen = ScreenAdapter.of(context);

    return Padding(
      padding: screen.edgeInsetsOnly(left: 37, right: 42),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: screen.borderRadiusAll(25),
          onTap: onTap,
          child: Ink(
            height: screen.h(52),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: screen.borderRadiusAll(25),
              border: borderColor == null
                  ? null
                  : Border.all(color: borderColor!, width: screen.w(1)),
            ),
            child: Center(
              child: Text(
                label,
                maxLines: 1,
                style: TextStyle(
                  color: foregroundColor,
                  fontSize: screen.sp(18),
                  fontWeight: fontWeight,
                  height: 22 / 18,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
