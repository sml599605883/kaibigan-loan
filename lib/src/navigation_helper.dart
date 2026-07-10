import 'dart:developer';

import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';

import 'app_routes.dart';
import 'core/json/json.dart';
import 'core/network/api_client.dart';
import 'core/network/api_exception.dart';
import 'core/report/report_manager.dart';
import 'core/report/report_models.dart';
import 'core/report/report_native_bridge.dart';
import 'core/session/product_detail_cache.dart';
import 'core/session/session_store.dart';
import 'modules/main/main_controller.dart';
import 'modules/orders/order_list_models.dart';
import 'utils/app_toast.dart';

typedef RawTargetLauncher = Future<bool> Function(Uri uri);
typedef NavigationLogger = void Function(String message);
typedef LocationAccessChecker = Future<bool> Function();
typedef LocationReporter = Future<void> Function();
typedef NativeLocationLoader = Future<ReportLocation?> Function();
typedef LocationServiceStatusProvider = Future<ServiceStatus> Function();
typedef LocationPermissionStatusProvider = Future<PermissionStatus> Function();
typedef LocationPermissionRequester = Future<PermissionStatus> Function();
typedef AppSettingsOpener = Future<bool> Function();
typedef PermissionPromptPresenter =
    Future<bool> Function({
      required String title,
      required String content,
      required String cancelText,
      required String confirmText,
    });

enum _LocationPermissionAction {
  proceed,
  requestPermission,
  openServicePrompt,
  openSettingsPrompt,
}

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
  static LocationAccessChecker locationAccessChecker =
      defaultLocationAccessChecker;
  static LocationReporter locationReporter = defaultLocationReporter;
  static NativeLocationLoader nativeLocationLoader =
      defaultNativeLocationLoader;
  static LocationServiceStatusProvider locationServiceStatusProvider =
      defaultLocationServiceStatusProvider;
  static LocationPermissionStatusProvider locationPermissionStatusProvider =
      defaultLocationPermissionStatusProvider;
  static LocationPermissionRequester locationPermissionRequester =
      defaultLocationPermissionRequester;
  static PermissionPromptPresenter permissionPromptPresenter =
      defaultPermissionPromptPresenter;
  static AppSettingsOpener appSettingsOpener = defaultAppSettingsOpener;

  static Future<bool> defaultRawTargetLauncher(Uri uri) {
    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  static Future<bool> openExternalUri(Uri uri) {
    return rawTargetLauncher(uri);
  }

  static void defaultLogger(String message) {
    log(message, name: 'NavigationHelper');
  }

  static Future<bool> defaultLocationAccessChecker() async {
    final location = await nativeLocationLoader();
    if (location != null && location.isValid) {
      return true;
    }

    final serviceStatus = await locationServiceStatusProvider();
    final permissionStatus = await locationPermissionStatusProvider();
    final permissionAction = _resolveLocationPermissionAction(
      serviceStatus: serviceStatus,
      permissionStatus: permissionStatus,
    );
    if (permissionAction == _LocationPermissionAction.proceed) {
      return true;
    }
    if (permissionAction == _LocationPermissionAction.openServicePrompt) {
      await AppToast.dismissLoading();
      final goToService = await permissionPromptPresenter(
        title: 'GPS is Off',
        content:
            'It looks like your GPS is off. Please enable location services to complete the verification process.',
        cancelText: 'Cancel',
        confirmText: 'Settings',
      );
      if (goToService) {
        await appSettingsOpener();
        return false;
      }
      return true;
    }

    if (permissionAction == _LocationPermissionAction.requestPermission) {
      final requestStatus = await locationPermissionRequester();
      if (requestStatus.isGranted || requestStatus.isLimited) {
        return true;
      }
      if (!requestStatus.isPermanentlyDenied && !requestStatus.isRestricted) {
        return false;
      }
    }

    await AppToast.dismissLoading();
    final goToSettings = await permissionPromptPresenter(
      title: 'Location Required',
      content:
          'Identity verification cannot be completed without your location. Please allow access in settings.',
      cancelText: 'Cancel',
      confirmText: 'Enable',
    );
    if (goToSettings) {
      await appSettingsOpener();
      return false;
    }
    return true;
  }

  static Future<ReportLocation?> defaultNativeLocationLoader() {
    return MethodChannelReportNativeBridge().getLocation();
  }

  static Future<ServiceStatus> defaultLocationServiceStatusProvider() {
    return Permission.locationWhenInUse.serviceStatus;
  }

  static Future<PermissionStatus> defaultLocationPermissionStatusProvider() {
    return Permission.locationWhenInUse.status;
  }

  static Future<PermissionStatus> defaultLocationPermissionRequester() {
    return Permission.locationWhenInUse.request();
  }

  static Future<bool> defaultPermissionPromptPresenter({
    required String title,
    required String content,
    required String cancelText,
    required String confirmText,
  }) async {
    final context = Get.context;
    if (context == null || !context.mounted) {
      return false;
    }
    return await showCupertinoDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (dialogContext) {
            return CupertinoAlertDialog(
              title: Text(title),
              content: Text(content),
              actions: [
                CupertinoDialogAction(
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                  child: Text(cancelText),
                ),
                CupertinoDialogAction(
                  onPressed: () => Navigator.of(dialogContext).pop(true),
                  isDefaultAction: true,
                  child: Text(confirmText),
                ),
              ],
            );
          },
        ) ??
        false;
  }

  static Future<bool> defaultAppSettingsOpener() {
    return openAppSettings();
  }

  static _LocationPermissionAction _resolveLocationPermissionAction({
    required ServiceStatus serviceStatus,
    required PermissionStatus permissionStatus,
  }) {
    if (serviceStatus != ServiceStatus.enabled) {
      return _LocationPermissionAction.openServicePrompt;
    }
    if (permissionStatus.isGranted || permissionStatus.isLimited) {
      return _LocationPermissionAction.proceed;
    }
    if (permissionStatus.isPermanentlyDenied || permissionStatus.isRestricted) {
      return _LocationPermissionAction.openSettingsPrompt;
    }
    return _LocationPermissionAction.requestPermission;
  }

  static Future<void> defaultLocationReporter() {
    return ReportManager.instance.reportNativeLocation();
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
      case AppRoutes.mineOrderList:
        return toMineOrderList<T>();
      case AppRoutes.certificationIdentity:
        return toCertificationIdentity<T>();
      case AppRoutes.certificationFace:
        return toCertificationFace<T>();
      case AppRoutes.certificationPersonalInfo:
        return toCertificationPersonalInfo<T>();
      case AppRoutes.certificationWorkInfo:
        return toCertificationWorkInfo<T>();
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
      await _cacheProductDetail(response.states);
      toDetail<void>(arguments: response.states.rawMapValue);
    });
  }

  static Future<void> continueProductDetailFlow(String productId) async {
    final normalizedProductId = productId.trim();
    if (normalizedProductId.isEmpty) {
      return;
    }
    await _runApiNavigation(() async {
      final response = await ApiClient.instance.productDetail(
        geobotanists: normalizedProductId,
      );
      await _cacheProductDetail(response.states);
      await _handleProductDetailFlow(response.states);
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
      await _applyProductNavigation(normalizedProductId, succumbs: succumbs);
    });
  }

  static Future<void> applyProductWithFlow(
    String productId, {
    String succumbs = '0',
  }) async {
    final normalizedProductId = productId.trim();
    if (normalizedProductId.isEmpty) {
      return;
    }

    await AppToast.showLoading();
    try {
      if (!await SessionStore.instance.isLoggedIn()) {
        await AppToast.dismissLoading();
        toLogin<void>();
        return;
      }
      if (!await locationAccessChecker()) {
        await AppToast.dismissLoading();
        return;
      }
      await AppToast.showLoading();
      try {
        await locationReporter();
      } catch (error) {
        logger('location report before apply failed: $error');
      }
      await _applyProductNavigation(normalizedProductId, succumbs: succumbs);
      await AppToast.dismissLoading();
    } catch (error) {
      await AppToast.error(ApiErrorMessage.resolve(error));
    }
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
      toWebView<void>(url: webUri.toString());
    }
  }

  static Future<T?>? toSetting<T extends Object?>() {
    return _toNamedIfNotCurrent<T>(AppRoutes.setting);
  }

  static Future<T?>? toWebView<T extends Object?>({
    required String url,
    String? title,
  }) {
    final uri = _resolveWebUri(url);
    if (uri == null) {
      return null;
    }
    return Get.toNamed<T>(
      AppRoutes.webView,
      arguments: <String, dynamic>{'url': uri.toString(), 'title': title},
    );
  }

  static Future<T?>? toMineOrderList<T extends Object?>({
    OrderListStatus initialStatus = OrderListStatus.all,
  }) {
    return Get.toNamed<T>(
      AppRoutes.mineOrderList,
      arguments: {'initialStatus': initialStatus.code},
    );
  }

  static Future<T?>? toCertificationIdentity<T extends Object?>({
    String? productId,
  }) {
    final arguments = productId == null || productId.trim().isEmpty
        ? null
        : <String, String>{'geobotanists': productId.trim()};
    return Get.toNamed<T>(
      AppRoutes.certificationIdentity,
      arguments: arguments,
    );
  }

  static Future<T?>? toCertificationFace<T extends Object?>({
    String? productId,
  }) {
    final arguments = productId == null || productId.trim().isEmpty
        ? null
        : <String, String>{'geobotanists': productId.trim()};
    return Get.toNamed<T>(AppRoutes.certificationFace, arguments: arguments);
  }

  static Future<T?>? toCertificationPersonalInfo<T extends Object?>({
    String? productId,
  }) {
    final arguments = productId == null || productId.trim().isEmpty
        ? null
        : <String, String>{'geobotanists': productId.trim()};
    return Get.toNamed<T>(
      AppRoutes.certificationPersonalInfo,
      arguments: arguments,
    );
  }

  static Future<T?>? toCertificationWorkInfo<T extends Object?>({
    String? productId,
  }) {
    final arguments = productId == null || productId.trim().isEmpty
        ? null
        : <String, String>{'geobotanists': productId.trim()};
    return Get.toNamed<T>(
      AppRoutes.certificationWorkInfo,
      arguments: arguments,
    );
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
      await AppToast.error(ApiErrorMessage.resolve(error));
    }
  }

  static Future<void> _applyProductNavigation(
    String productId, {
    required String succumbs,
  }) async {
    final response = await ApiClient.instance.productApply(
      geobotanists: productId,
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
      geobotanists: productId,
    );
    await _cacheProductDetail(detailResponse.states);
    toDetail<void>(arguments: detailResponse.states.rawMapValue);
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
    await _cacheProductDetail(response.states);
    await _handleProductDetailFlow(response.states);
  }

  static Future<void> _cacheProductDetail(Json productDetail) async {
    if (!Get.isRegistered<SessionStore>()) {
      return;
    }
    await SessionStore.instance.saveProductDetailCache(
      ProductDetailCache.fromJson(productDetail.value),
    );
  }

  static Future<void> _handleProductDetailFlow(Json productDetail) async {
    final rawDetail = productDetail.rawMapValue;
    final cachedDetail = Get.isRegistered<SessionStore>()
        ? SessionStore.instance.productDetailCache()
        : null;
    final product = productDetail['sensitized'];
    final nextStepCode = _firstNonEmpty(
      cachedDetail?.nextStep['taskType']?.toString(),
      productDetail['grinner']['unconfusing'].stringValue,
    );
    if (nextStepCode.isNotEmpty) {
      final productId = _firstNonEmpty(
        cachedDetail?.productid,
        product['cabdrivers'].stringValue,
      );
      _handleProductDetailNextStep(nextStepCode, productId);
      return;
    }

    if (productDetail['threats'].intValue == 200) {
      final orderNo = _firstNonEmpty(
        cachedDetail?.orderNo,
        product['chattinesses'].stringValue,
      );
      if (orderNo.isNotEmpty) {
        final redirect = await ApiClient.instance.orderRedirect(
          dodgy: orderNo,
          ecumenicalism: _firstNonEmpty(
            cachedDetail?.amount,
            product['ecumenicalism'].stringValue,
          ),
          desertifying: _firstNonEmpty(
            cachedDetail?.term,
            product['desertifying'].stringValue,
          ),
          tythes: _firstNonEmpty(
            cachedDetail?.termType,
            product['tythes'].stringValue,
          ),
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

  static void _handleProductDetailNextStep(String rawCode, String productId) {
    final routeKey = _productDetailAuthStepCodes[rawCode.trim()];
    if (routeKey == 'public') {
      toCertificationIdentity<void>(productId: productId);
      return;
    }
    if (routeKey == 'face') {
      toCertificationFace<void>(productId: productId);
      return;
    }
    if (routeKey == 'personal') {
      toCertificationPersonalInfo<void>(productId: productId);
      return;
    }
    if (routeKey == 'work') {
      toCertificationWorkInfo<void>(productId: productId);
      return;
    }
    logger(
      'product detail next step: code=$rawCode, routeKey=${routeKey ?? 'unknown'}, productId=$productId',
    );
  }

  static String _firstNonEmpty(String? primary, String fallback) {
    final normalizedPrimary = primary?.trim() ?? '';
    if (normalizedPrimary.isNotEmpty) {
      return normalizedPrimary;
    }
    return fallback.trim();
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
      case AppRoutes.mineOrderList:
      case 'orderList':
      case 'mineOrderList':
      case 'LoanList':
        return AppRoutes.mineOrderList;
      case AppRoutes.certificationFace:
      case 'face':
      case 'Vesicated':
        return AppRoutes.certificationFace;
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
