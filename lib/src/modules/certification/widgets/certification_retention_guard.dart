import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../widgets/retention_popup.dart';

class CertificationRetentionGuard {
  CertificationRetentionGuard._();

  static RetentionPopupPresenter presenter = _defaultPresenter;

  static void resetPresenter() {
    presenter = _defaultPresenter;
  }

  static Future<void> handleBack({
    required String type,
    required String productId,
    required VoidCallback onDefaultBack,
    RetentionPopupPresenter? presenter,
  }) async {
    final shown = await (presenter ?? CertificationRetentionGuard.presenter)(
      type: type,
      productId: productId,
      onExit: onDefaultBack,
    );
    if (!shown) {
      onDefaultBack();
    }
  }

  static VoidCallback backHandler({
    required String type,
    required String productId,
  }) {
    return () {
      unawaited(
        handleBack(
          type: type,
          productId: productId,
          onDefaultBack: () => Get.back<void>(),
        ),
      );
    };
  }

  static Future<bool> _defaultPresenter({
    required String type,
    required String productId,
    required VoidCallback onExit,
  }) {
    return RetentionPopup.show(
      type: type,
      productId: productId,
      onExit: onExit,
    );
  }
}
