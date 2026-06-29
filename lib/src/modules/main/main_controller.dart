import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '../../app_routes.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_endpoints.dart';

class MainController extends GetxController with WidgetsBindingObserver {
  final selectedIndex = 0.obs;

  bool _homeRefreshRequesting = false;

  ApiClient get _apiClient => Get.find<ApiClient>();

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void onReady() {
    super.onReady();
    requestHomeDataIfVisible();
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    super.onClose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      requestHomeDataIfVisible();
    }
  }

  void selectTab(int index) {
    if (selectedIndex.value == index) {
      return;
    }
    selectedIndex.value = index;
    requestHomeDataIfVisible();
  }

  void onRouteChanged() {
    requestHomeDataIfVisible();
  }

  Future<void> requestHomeDataIfVisible() async {
    if (!_isHomeVisible || _homeRefreshRequesting) {
      return;
    }
    _homeRefreshRequesting = true;
    try {
      await _apiClient.get(ApiEndpoints.homePage);
      await _apiClient.get(ApiEndpoints.dialog);
    } catch (_) {
      // Home refresh failures must not block the home page.
    } finally {
      _homeRefreshRequesting = false;
    }
  }

  bool get _isHomeVisible {
    final route = Get.currentRoute;
    return selectedIndex.value == 0 &&
        (route.isEmpty || route == AppRoutes.main);
  }
}
