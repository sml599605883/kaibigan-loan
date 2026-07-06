import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '../../app_routes.dart';
import '../../core/json/json.dart';
import '../../core/network/api_client.dart';
import '../../core/session/session_store.dart';

class MainController extends GetxController with WidgetsBindingObserver {
  final selectedIndex = 0.obs;
  final banners = <HomeBanner>[].obs;
  final loanProcessItems = <HomeLoanProcessItem>[].obs;
  final orderStatusItems = <HomeOrderStatusItem>[].obs;
  final recommendationItems = <HomeRecommendationItem>[].obs;

  bool _homeRefreshRequesting = false;

  ApiClient get _apiClient => ApiClient.instance;

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

  Future<void> selectTab(int index) async {
    if (selectedIndex.value == index) {
      return;
    }
    if (index != 0 && !await SessionStore.instance.isLoggedIn()) {
      await Get.toNamed<void>(AppRoutes.login);
      return;
    }
    selectedIndex.value = index;
    requestHomeDataIfVisible();
  }

  void returnToHomeTab() {
    selectedIndex.value = 0;
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
      orderStatusItems.assignAll(HomeOrderStatusItem.fromHome(response.states));
      recommendationItems.assignAll(
        HomeRecommendationItem.fromHome(response.states),
      );
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
  static const processList = 'PROCESS_LIST';
  static const productList = 'PRODUCT_LIST';

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

class HomeOrderStatusItem {
  const HomeOrderStatusItem({
    required this.id,
    required this.productName,
    required this.productLogo,
    required this.amount,
    required this.amountText,
    required this.dueDate,
    required this.dateText,
    required this.statusText,
    required this.buttonText,
    required this.actionUrl,
    required this.productId,
    required this.orderNo,
  });

  final String id;
  final String productName;
  final String productLogo;
  final String amount;
  final String amountText;
  final String dueDate;
  final String dateText;
  final String statusText;
  final String buttonText;
  final String actionUrl;
  final String productId;
  final String orderNo;

  static List<HomeOrderStatusItem> fromHome(Json states) {
    return _itemsForType(states, HomeElementType.processList)
        .map((value) => HomeOrderStatusItem.fromJson(Json(value)))
        .where(
          (item) =>
              item.productName.isNotEmpty ||
              item.amount.isNotEmpty ||
              item.dueDate.isNotEmpty,
        )
        .toList();
  }

  factory HomeOrderStatusItem.fromJson(Json json) {
    return HomeOrderStatusItem(
      id: _firstString(json, const ['cabdrivers', 'id']),
      productName: _firstString(json, const [
        'macromeres',
        'scolloped',
        'omissible',
        'productName',
      ]),
      productLogo: _firstString(json, const [
        'reconverts',
        'biontic',
        'productLogo',
      ]),
      amount: _firstString(json, const ['ecumenicalism', 'pyknoses', 'amount']),
      amountText: _firstString(json, const ['giardias', 'amount_text']),
      dueDate: _firstString(json, const ['origin_end_time', 'salvo', 'date']),
      dateText: _firstString(json, const ['tallisim', 'date_text']),
      statusText: _firstString(json, const [
        'fictitiousness',
        'primogenitor',
        'status',
      ]),
      buttonText: _firstString(json, const ['stoles', 'button_text']),
      actionUrl: _firstString(json, const [
        'dismasts',
        'bloomeries',
        'preattuned',
      ]),
      productId: _firstString(json, const ['geobotanists']),
      orderNo: _firstString(json, const ['dodgy']),
    );
  }
}

class HomeRecommendationItem {
  const HomeRecommendationItem({
    required this.productId,
    required this.productName,
    required this.productLogo,
    required this.buttonText,
    required this.amountRange,
    required this.amountRangeDescription,
    required this.termInfo,
    required this.termInfoDescription,
    required this.loanRate,
    required this.loanRateDescription,
    required this.linkUrl,
  });

  final String productId;
  final String productName;
  final String productLogo;
  final String buttonText;
  final String amountRange;
  final String amountRangeDescription;
  final String termInfo;
  final String termInfoDescription;
  final String loanRate;
  final String loanRateDescription;
  final String linkUrl;

  static List<HomeRecommendationItem> fromHome(Json states) {
    return _itemsForType(states, HomeElementType.productList)
        .map((value) => HomeRecommendationItem.fromJson(Json(value)))
        .where(
          (item) =>
              item.productName.isNotEmpty ||
              item.amountRange.isNotEmpty ||
              item.productId.isNotEmpty,
        )
        .toList();
  }

  factory HomeRecommendationItem.fromJson(Json json) {
    return HomeRecommendationItem(
      productId: _firstString(json, const ['geobotanists']),
      productName: _firstString(json, const [
        'omissible',
        'scolloped',
        'productName',
      ]),
      productLogo: _firstString(json, const ['biontic', 'productLogo']),
      buttonText: _firstString(json, const ['restless', 'buttonText']),
      amountRange: _firstString(json, const [
        'ghillies',
        'pyknoses',
        'amountRange',
      ]),
      amountRangeDescription: _firstString(json, const [
        'geometrically',
        'amountRangeDes',
      ]),
      termInfo: _firstString(json, const ['mainlined', 'overextend']),
      termInfoDescription: _firstString(json, const [
        'outmarching',
        'termInfoDes',
      ]),
      loanRate: _firstString(json, const ['pulpit', 'agonizing']),
      loanRateDescription: _firstString(json, const [
        'rescinders',
        'loanRateDes',
      ]),
      linkUrl: _firstString(json, const ['preattuned', 'bloomeries']),
    );
  }
}

List<dynamic> _itemsForType(Json states, String type) {
  for (final sectionValue in states['religiosities'].listValue) {
    final section = Json(sectionValue);
    if (section['commensurate'].stringValue == type) {
      return section['anchovetta'].listValue;
    }
  }
  return const <dynamic>[];
}

String _firstString(Json json, List<String> keys) {
  for (final key in keys) {
    final value = json[key].stringValue;
    if (value.isNotEmpty) {
      return value;
    }
  }
  return '';
}
