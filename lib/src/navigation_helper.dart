import 'dart:developer';

import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

import 'app_routes.dart';
import 'core/json/json.dart';
import 'core/network/api_client.dart';
import 'core/network/api_exception.dart';
import 'modules/main/main_controller.dart';
import 'utils/app_toast.dart';

typedef RawTargetLauncher = Future<bool> Function(Uri uri);
typedef NavigationLogger = void Function(String message);

class NavigationHelper {
  NavigationHelper._();

  static const _appScheme = 'ph';
  static const _appSchemeHost = 'kaibigan-loan';
  static const _appSchemePlatform = 'ios';
  static const Map<String, String> _productDetailAuthStepCodes =
      <String, String>{
        'public': 'public',
        'MistermEncystment': 'public',
        'face': 'face',
        'Vesicated': 'face',
        'personal': 'personal',
        'Penalization': 'personal',
        'work': 'work',
        'Suppressive': 'work',
        'ext': 'ext',
        'Liri': 'ext',
        'bank': 'bank',
        'CocoShorting': 'bank',
      };

  static RawTargetLauncher rawTargetLauncher = defaultRawTargetLauncher;
  static NavigationLogger logger = defaultLogger;

  static Future<bool> defaultRawTargetLauncher(Uri uri) {
    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  static void defaultLogger(String message) {
    log(message, name: 'NavigationHelper');
  }

  static void back<T extends Object?>({T? result}) {
    Get.back<T>(result: result);
  }

  static Future<T?>? toLogin<T extends Object?>() {
    return _toNamedIfNotCurrent<T>(AppRoutes.login);
  }

  static Future<T?>? toNamed<T extends Object?>(String routeName) {
    switch (routeName) {
      case AppRoutes.login:
        return toLogin<T>();
      case AppRoutes.detail:
        return toDetail<T>();
      case AppRoutes.setting:
        return toSetting<T>();
      case AppRoutes.main:
        return offAllToMain<T>();
      default:
        return null;
    }
  }

  static Future<T?>? toDetail<T extends Object?>({Object? arguments}) {
    return Get.toNamed<T>(AppRoutes.detail, arguments: arguments);
  }

  static Future<void> toProductDetail(String productId) async {
    final normalizedProductId = productId.trim();
    if (normalizedProductId.isEmpty) {
      return;
    }
    await _runApiNavigation(() async {
      final response = await ApiClient.instance.productDetail(
        geobotanists: normalizedProductId,
      );
      toDetail<void>(arguments: response.states.rawMapValue);
    });
  }

  static Future<void> applyProduct(
    String productId, {
    String succumbs = '0',
  }) async {
    final normalizedProductId = productId.trim();
    if (normalizedProductId.isEmpty) {
      return;
    }
    await _runApiNavigation(() async {
      final response = await ApiClient.instance.productApply(
        geobotanists: normalizedProductId,
        succumbs: succumbs,
      );
      final applyStates = response.states;
      final rawTarget = applyStates['bloomeries'].stringValue.trim();
      if (rawTarget.isNotEmpty) {
        await navigateRawTarget(rawTarget, arguments: applyStates.rawMapValue);
        return;
      }
      if (applyStates['threats'].intValue != 200) {
        final message = applyStates['wofuller'].stringValue.trim();
        if (message.isNotEmpty) {
          await AppToast.show(message);
        }
        return;
      }
      final detailResponse = await ApiClient.instance.productDetail(
        geobotanists: normalizedProductId,
      );
      toDetail<void>(arguments: detailResponse.states.rawMapValue);
    });
  }

  static Future<void> navigateRawTarget(
    String rawTarget, {
    Object? arguments,
  }) async {
    final target = rawTarget.trim();
    if (target.isEmpty) {
      return;
    }

    final routeName = _routeForRawTarget(target);
    if (routeName != null) {
      if (routeName == AppRoutes.detail) {
        await _toProductDetailFromTarget(target, arguments: arguments);
        return;
      }
      toNamed<void>(routeName);
      return;
    }

    final webUri = _resolveWebUri(target);
    if (webUri != null) {
      await rawTargetLauncher(webUri);
    }
  }

  static Future<T?>? toSetting<T extends Object?>() {
    return _toNamedIfNotCurrent<T>(AppRoutes.setting);
  }

  static Future<T?>? offAllToMain<T extends Object?>() {
    if (Get.isRegistered<MainController>()) {
      Get.find<MainController>().returnToHomeTab();
    }
    return Get.offAllNamed<T>(AppRoutes.main);
  }

  static Future<T?>? _toNamedIfNotCurrent<T extends Object?>(String routeName) {
    if (Get.currentRoute == routeName) {
      return null;
    }
    return Get.toNamed<T>(routeName);
  }

  static Future<void> _runApiNavigation(Future<void> Function() action) async {
    await AppToast.showLoading();
    try {
      await action();
      await AppToast.dismissLoading();
    } catch (error) {
      await AppToast.dismissLoading();
      await AppToast.error(ApiErrorMessage.resolve(error));
    }
  }

  static Future<void> _toProductDetailFromTarget(
    String rawTarget, {
    Object? arguments,
  }) async {
    final productId = _productIdFromTarget(rawTarget).trim();
    if (productId.isEmpty) {
      return;
    }
    final response = await ApiClient.instance.productDetail(
      geobotanists: productId,
    );
    await _handleProductDetailFlow(response.states);
  }

  static Future<void> _handleProductDetailFlow(Json productDetail) async {
    final rawDetail = productDetail.rawMapValue;
    final nextStepCode = productDetail['grinner']['unconfusing'].stringValue
        .trim();
    if (nextStepCode.isNotEmpty) {
      _handleProductDetailNextStep(nextStepCode, rawDetail);
      return;
    }

    if (productDetail['threats'].intValue == 200) {
      final product = productDetail['sensitized'];
      final orderNo = product['chattinesses'].stringValue.trim();
      if (orderNo.isNotEmpty) {
        final redirect = await ApiClient.instance.orderRedirect(
          dodgy: orderNo,
          ecumenicalism: product['ecumenicalism'].stringValue,
          desertifying: product['desertifying'].stringValue,
          tythes: product['tythes'].stringValue,
        );
        final redirectTarget = redirect.states['bloomeries'].stringValue.trim();
        if (redirectTarget.isNotEmpty) {
          await navigateRawTarget(redirectTarget, arguments: rawDetail);
          return;
        }
      }
    }

    final message = productDetail['wofuller'].stringValue.trim();
    if (message.isNotEmpty) {
      await AppToast.show(message);
      return;
    }
    toDetail<void>(
      arguments: rawDetail.isEmpty ? productDetail.value : rawDetail,
    );
  }

  static String _productIdFromTarget(String rawTarget) {
    final uri = Uri.tryParse(rawTarget.trim());
    if (uri == null) {
      return '';
    }
    return (uri.queryParameters['geobotanists'] ??
            uri.queryParameters['productId'] ??
            uri.queryParameters['cohabiter'] ??
            '')
        .trim();
  }

  static void _handleProductDetailNextStep(
    String rawCode,
    Map<String, dynamic> productDetail,
  ) {
    final routeKey = _productDetailAuthStepCodes[rawCode.trim()];
    final productId = Json(
      productDetail,
    )['sensitized']['cabdrivers'].stringValue.trim();
    logger(
      'product detail next step: code=$rawCode, routeKey=${routeKey ?? 'unknown'}, productId=$productId',
    );
  }

  static String? _routeForRawTarget(String rawTarget) {
    final target = rawTarget.trim();
    if (target.isEmpty) {
      return null;
    }
    final directRoute = _routeNameForAlias(target);
    if (directRoute != null) {
      return directRoute;
    }

    final uri = Uri.tryParse(target);
    if (uri == null) {
      return null;
    }
    if (_isAppScheme(uri)) {
      for (final candidate in uri.pathSegments.reversed) {
        if (candidate == _appSchemePlatform) {
          continue;
        }
        final routeName = _routeNameForAlias(candidate.trim());
        if (routeName != null) {
          return routeName;
        }
      }
      return null;
    }
    final page = uri.queryParameters['appPage'] ?? uri.queryParameters['page'];
    if (page != null && page.trim().isNotEmpty) {
      return _routeNameForAlias(page.trim());
    }
    return null;
  }

  static String? _routeNameForAlias(String rawAlias) {
    switch (rawAlias) {
      case AppRoutes.main:
      case 'main':
      case 'Peacefulnesses':
        return AppRoutes.main;
      case AppRoutes.login:
      case 'login':
      case 'ImpleadExpositing':
        return AppRoutes.login;
      case AppRoutes.detail:
      case 'detail':
      case 'productDetail':
      case 'AlderwomenProtozoology':
        return AppRoutes.detail;
      case AppRoutes.setting:
      case 'setting':
      case 'AmoxicillinHistamines':
        return AppRoutes.setting;
    }
    return null;
  }

  static bool _isAppScheme(Uri uri) {
    return uri.scheme == _appScheme &&
        uri.host == _appSchemeHost &&
        uri.pathSegments.isNotEmpty &&
        uri.pathSegments.first == _appSchemePlatform;
  }

  static Uri? _resolveWebUri(String rawTarget) {
    final uri = Uri.tryParse(rawTarget.trim());
    if (uri == null) {
      return null;
    }
    if (uri.scheme == 'http' || uri.scheme == 'https') {
      return uri;
    }
    return null;
  }
}
