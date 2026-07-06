import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';

import '../theme/app_colors.dart';

abstract final class AppToast {
  static ToastPresenter presenter = const EasyLoadingToastPresenter();

  static Future<void> show(String message) {
    return presenter.show(message, isError: false);
  }

  static Future<void> error(String message) {
    return presenter.show(message, isError: true);
  }

  static Future<void> showLoading([String? message]) {
    return presenter.showLoading(message);
  }

  static Future<void> dismissLoading() {
    return presenter.dismissLoading();
  }
}

abstract interface class ToastPresenter {
  Future<void> show(String message, {required bool isError});

  Future<void> showLoading(String? message);

  Future<void> dismissLoading();
}

class EasyLoadingToastPresenter implements ToastPresenter {
  const EasyLoadingToastPresenter();

  @override
  Future<void> show(String message, {required bool isError}) {
    if (message.trim().isEmpty) {
      return EasyLoading.dismiss();
    }
    if (isError) {
      return EasyLoading.showError(message, dismissOnTap: true);
    }
    return EasyLoading.showToast(
      message,
      dismissOnTap: true,
      toastPosition: EasyLoadingToastPosition.center,
    );
  }

  @override
  Future<void> showLoading(String? message) {
    return EasyLoading.show(
      status: message,
      dismissOnTap: false,
      maskType: EasyLoadingMaskType.clear,
    );
  }

  @override
  Future<void> dismissLoading() {
    return EasyLoading.dismiss();
  }
}

void configureAppToast() {
  EasyLoading.instance
    ..loadingStyle = EasyLoadingStyle.custom
    ..indicatorType = EasyLoadingIndicatorType.ring
    ..backgroundColor = AppColors.loginTitleText
    ..indicatorColor = AppColors.loginAgreementText
    ..progressColor = AppColors.loginAgreementText
    ..textColor = AppColors.loginAgreementText
    ..maskColor = Colors.transparent
    ..fontSize = 14
    ..radius = 8
    ..displayDuration = const Duration(seconds: 2);
}
