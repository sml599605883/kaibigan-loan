import 'dart:async';

import 'package:get/get.dart' as getx;

import '../session/session_store.dart';
import 'report_manager.dart';

class RiskReportScene {
  const RiskReportScene._();

  static int nowSeconds() => DateTime.now().millisecondsSinceEpoch ~/ 1000;

  static void report({
    required String productId,
    required String sceneType,
    required int startTimeSeconds,
    String? orderNo,
  }) {
    final normalizedProductId = productId.trim();
    final normalizedSceneType = sceneType.trim();
    if (normalizedSceneType.isEmpty) {
      return;
    }
    if (!getx.Get.isRegistered<ReportManager>()) {
      return;
    }
    unawaited(
      ReportManager.instance
          .reportRiskBehavior(
            productId: normalizedProductId,
            sceneType: normalizedSceneType,
            orderNo: _firstNonEmpty(orderNo, _cachedOrderNo()),
            startTimeSeconds: startTimeSeconds,
          )
          .catchError((_) {}),
    );
  }

  static String _cachedOrderNo() {
    if (!getx.Get.isRegistered<SessionStore>()) {
      return '';
    }
    return SessionStore.instance.productDetailCache()?.orderNo.trim() ?? '';
  }

  static String _firstNonEmpty(String? primary, String fallback) {
    final normalized = primary?.trim() ?? '';
    return normalized.isNotEmpty ? normalized : fallback.trim();
  }
}
