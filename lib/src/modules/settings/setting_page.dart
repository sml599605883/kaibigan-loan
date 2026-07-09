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
    return Scaffold(
      backgroundColor: AppColors.tabBackground,
      body: SafeArea(
        bottom: false,
        child: SizedBox.expand(
          child: Padding(
            padding: EdgeInsets.fromLTRB(20.w, 16.h, 14.w, 20.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const _SettingHeader(),
                SizedBox(height: 76.h),
                const _AppIdentity(),
                SizedBox(height: 45.h),
                const _InfoPanel(),
                const Spacer(),
                _SettingActionButton(
                  label: 'Deactivate Account',
                  foregroundColor: AppColors.settingDeactivateText,
                  backgroundColor: AppColors.tabBackground,
                  borderColor: AppColors.settingDeactivateBorder,
                  fontWeight: FontWeight.w400,
                  onTap: () => _deactivateAccount(context),
                ),
                SizedBox(height: 10.h),
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
  const _SettingHeader();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 24.h,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(20.r),
                onTap: Get.back<void>,
                child: SizedBox(
                  width: 48.w,
                  height: 40.h,
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
              fontSize: 20.sp,
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
  const _AppIdentity();

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
        SizedBox(height: 13.h),
        Text(
          'Kaibigan Loan',
          maxLines: 1,
          style: TextStyle(
            color: AppColors.ordersTitleText,
            fontSize: 20.sp,
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
  const _InfoPanel();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(right: 6.w),
      padding: EdgeInsets.all(10.w),
      decoration: BoxDecoration(
        color: AppColors.settingInfoPanel,
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Column(
        children: [
          const _InfoRow(label: 'Website', value: SettingPage._website),
          SizedBox(height: 10.h),
          const _InfoRow(label: 'E-mail', value: SettingPage._email),
          SizedBox(height: 10.h),
          const _InfoRow(label: 'Version', value: SettingPage._version),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 43.h,
      padding: EdgeInsets.fromLTRB(19.w, 0, 20.w, 0),
      decoration: BoxDecoration(
        color: AppColors.tabBackground,
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Row(
        children: [
          Text(
            label,
            maxLines: 1,
            style: TextStyle(
              color: AppColors.settingLabelText,
              fontSize: 16.sp,
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
                fontSize: 16.sp,
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
    return Padding(
      padding: EdgeInsets.only(left: 37.w, right: 42.w),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(25.r),
          onTap: onTap,
          child: Ink(
            height: 52.h,
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(25.r),
              border: borderColor == null
                  ? null
                  : Border.all(color: borderColor!, width: 1.w),
            ),
            child: Center(
              child: Text(
                label,
                maxLines: 1,
                style: TextStyle(
                  color: foregroundColor,
                  fontSize: 18.sp,
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
