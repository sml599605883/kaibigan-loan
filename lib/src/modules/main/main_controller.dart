import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '../../app_routes.dart';
import '../../core/json/json.dart';
import '../../core/network/api_client.dart';

class MainController extends GetxController with WidgetsBindingObserver {
  final selectedIndex = 0.obs;
  final banners = <HomeBanner>[].obs;
  final loanProcessItems = <HomeLoanProcessItem>[].obs;

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
      final response = await _apiClient.homePage();
      banners.assignAll(HomeBanner.fromHome(response.states));
      loanProcessItems.assignAll(HomeLoanProcessItem.fromHome(response.states));
      await _apiClient.dialog(loungy: 1);
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

  Future<void> handleBannerTap(HomeBanner banner) async {
    if (banner.id.isEmpty || banner.linkUrl.isEmpty) {
      return;
    }
    try {
      await _apiClient.bannerClickRecord(mesial: banner.id);
    } catch (_) {
      // Banner click reporting must not interrupt the tap interaction.
    }
  }
}

class HomeElementType {
  static const banner = 'Moorages';
  static const largeCard = 'CatechisticOverlooking';

  const HomeElementType._();
}

class HomeBanner {
  const HomeBanner({
    required this.id,
    required this.imageUrl,
    required this.linkUrl,
  });

  final String id;
  final String imageUrl;
  final String linkUrl;

  static List<HomeBanner> fromHome(Json states) {
    for (final sectionValue in states['religiosities'].listValue) {
      final section = Json(sectionValue);
      if (section['commensurate'].stringValue != HomeElementType.banner) {
        continue;
      }
      return section['anchovetta'].listValue
          .map((value) => HomeBanner.fromJson(Json(value)))
          .where((banner) => banner.imageUrl.isNotEmpty)
          .toList();
    }
    return const <HomeBanner>[];
  }

  factory HomeBanner.fromJson(Json json) {
    return HomeBanner(
      id: json['cabdrivers'].stringValue,
      imageUrl: json['centerlines'].stringValue,
      linkUrl: json['bloomeries'].stringValue,
    );
  }
}

class HomeLoanProcessItem {
  const HomeLoanProcessItem({
    required this.title,
    required this.amount,
    required this.selected,
  });

  final String title;
  final String amount;
  final bool selected;

  static List<HomeLoanProcessItem> fromHome(Json states) {
    for (final sectionValue in states['religiosities'].listValue) {
      final section = Json(sectionValue);
      if (section['commensurate'].stringValue != HomeElementType.largeCard) {
        continue;
      }
      final cards = section['anchovetta'].listValue;
      if (cards.isEmpty) {
        return const <HomeLoanProcessItem>[];
      }
      return Json(cards.first)['humpiness'].listValue
          .map((value) => HomeLoanProcessItem.fromJson(Json(value)))
          .where((item) => item.title.isNotEmpty || item.amount.isNotEmpty)
          .toList();
    }
    return const <HomeLoanProcessItem>[];
  }

  factory HomeLoanProcessItem.fromJson(Json json) {
    return HomeLoanProcessItem(
      title: json['primogenitor'].stringValue,
      amount: json['pyknoses'].stringValue,
      selected: json['vixenish'].intValue == 1,
    );
  }
}
