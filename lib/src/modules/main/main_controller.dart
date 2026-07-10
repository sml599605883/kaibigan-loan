import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '../../app_routes.dart';
import '../../core/json/json.dart';
import '../../core/network/api_client.dart';
import '../../core/session/session_store.dart';
import '../../navigation_helper.dart';

class MainController extends GetxController with WidgetsBindingObserver {
  final selectedIndex = 0.obs;
  final banners = <HomeBanner>[].obs;
  final loanProcessItems = <HomeLoanProcessItem>[].obs;
  final orderStatusItems = <HomeOrderStatusItem>[].obs;
  final recommendationItems = <HomeRecommendationItem>[].obs;
  final topLoanCardItems = <HomeTopLoanCardItem>[].obs;

  bool _homeRefreshRequesting = false;
  bool _topHeroApplyRequesting = false;

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
      NavigationHelper.toLogin<void>();
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
      topLoanCardItems.assignAll(HomeTopLoanCardItem.fromHome(response.states));
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

  Future<void> applyTopHeroProduct() async {
    final productId = topLoanCardItems.isEmpty
        ? ''
        : topLoanCardItems.first.productId.trim();
    if (_topHeroApplyRequesting || productId.isEmpty) {
      return;
    }
    _topHeroApplyRequesting = true;
    try {
      await NavigationHelper.applyProductWithFlow(productId);
    } finally {
      _topHeroApplyRequesting = false;
    }
  }
}

class HomeElementType {
  static const banner = 'Moorages';
  static const largeCard = 'CatechisticOverlooking';
  static const smallCard = 'ShivasSurveyings';
  static const processList = 'PROCESS_LIST';
  static const processListObfuscated = 'BottomingSupergene';
  static const productList = 'PRODUCT_LIST';
  static const productListObfuscated = 'SubspecializedReawake';

  const HomeElementType._();
}

class HomeTopLoanCardItem {
  const HomeTopLoanCardItem({
    required this.productId,
    required this.amountRange,
    required this.termInfo,
    required this.loanRate,
    required this.buttonText,
  });

  final String productId;
  final String amountRange;
  final String termInfo;
  final String loanRate;
  final String buttonText;

  static List<HomeTopLoanCardItem> fromHome(Json states) {
    final largeCards = _itemsForType(states, HomeElementType.largeCard);
    final selectedCards = largeCards.isNotEmpty
        ? largeCards
        : _itemsForType(states, HomeElementType.smallCard);
    if (selectedCards.isEmpty) {
      return const <HomeTopLoanCardItem>[];
    }
    return [HomeTopLoanCardItem.fromJson(selectedCards.first)];
  }

  factory HomeTopLoanCardItem.fromJson(Json json) {
    return HomeTopLoanCardItem(
      productId: json['cabdrivers'].stringValue,
      amountRange: json['ghillies'].stringValue,
      termInfo: json['mainlined'].stringValue,
      loanRate: json['pulpit'].stringValue,
      buttonText: json['restless'].stringValue,
    );
  }
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
      final section = sectionValue;
      if (section['commensurate'].stringValue != HomeElementType.banner) {
        continue;
      }
      return section['anchovetta'].listValue
          .map(HomeBanner.fromJson)
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
      final section = sectionValue;
      if (section['commensurate'].stringValue != HomeElementType.largeCard) {
        continue;
      }
      final cards = section['anchovetta'].listValue;
      if (cards.isEmpty) {
        return const <HomeLoanProcessItem>[];
      }
      return cards.first['humpiness'].listValue
          .map(HomeLoanProcessItem.fromJson)
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
    required this.cardStatus,
    required this.actions,
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
  final int cardStatus;
  final List<HomeOrderStatusAction> actions;

  static List<HomeOrderStatusItem> fromHome(Json states) {
    return _itemsForTypes(states, const [
          HomeElementType.processList,
          HomeElementType.processListObfuscated,
        ])
        .map(HomeOrderStatusItem.fromJson)
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
      id: json['cabdrivers'].stringValue,
      productName: json['macromeres'].stringValue,
      productLogo: json['reconverts'].stringValue,
      amount: _displayAmount(json),
      amountText: json['giardias'].stringValue,
      dueDate: _firstText(json, const ['origin_end_time', 'salvo']),
      dateText: json['tallisim'].stringValue,
      statusText: json['fictitiousness'].stringValue,
      buttonText: json['stoles'].stringValue,
      actionUrl: json['dismasts'].stringValue,
      productId: json['geobotanists'].stringValue,
      orderNo: json['dodgy'].stringValue,
      cardStatus: json['cracksmen'].intValue,
      actions: json['briefing'].listValue
          .map(HomeOrderStatusAction.fromJson)
          .where((action) => action.visible && action.text.isNotEmpty)
          .toList(),
    );
  }
}

class HomeOrderStatusAction {
  const HomeOrderStatusAction({
    required this.type,
    required this.text,
    required this.url,
    required this.visible,
  });

  final String type;
  final String text;
  final String url;
  final bool visible;

  factory HomeOrderStatusAction.fromJson(Json json) {
    return HomeOrderStatusAction(
      type: json['commensurate'].stringValue,
      text: json['stoles'].stringValue,
      url: json['dismasts'].stringValue,
      visible: json['unrested'].intValue == 1,
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
    return _itemsForTypes(states, const [
          HomeElementType.productList,
          HomeElementType.productListObfuscated,
        ])
        .map(HomeRecommendationItem.fromJson)
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
      productId: json['geobotanists'].stringValue,
      productName: json['omissible'].stringValue,
      productLogo: json['biontic'].stringValue,
      buttonText: json['restless'].stringValue,
      amountRange: json['ghillies'].stringValue,
      amountRangeDescription: json['geometrically'].stringValue,
      termInfo: json['mainlined'].stringValue,
      termInfoDescription: json['outmarching'].stringValue,
      loanRate: json['pulpit'].stringValue,
      loanRateDescription: json['rescinders'].stringValue,
      linkUrl: json['preattuned'].stringValue,
    );
  }
}

List<Json> _itemsForType(Json states, String type) {
  return _itemsForTypes(states, [type]);
}

List<Json> _itemsForTypes(Json states, List<String> types) {
  for (final sectionValue in states['religiosities'].listValue) {
    final section = sectionValue;
    if (types.contains(section['commensurate'].stringValue)) {
      return section['anchovetta'].listValue;
    }
  }
  return const <Json>[];
}

String _firstText(Json json, List<String> keys) {
  for (final key in keys) {
    final value = json[key].stringValue.trim();
    if (value.isNotEmpty) {
      return value;
    }
  }
  return '';
}

String _displayAmount(Json json) {
  final formattedAmount = json['refiners'].stringValue.trim();
  if (formattedAmount.isNotEmpty) {
    return formattedAmount;
  }
  return _formatPesoAmount(json['ecumenicalism'].stringValue);
}

String _formatPesoAmount(String rawValue) {
  final normalized = rawValue.trim().replaceAll(',', '');
  if (normalized.isEmpty || !RegExp(r'^\d+(\.\d+)?$').hasMatch(normalized)) {
    return rawValue.trim();
  }
  final parts = normalized.split('.');
  final whole = parts.first;
  final decimals = parts.length > 1 ? '.${parts.last}' : '';
  final buffer = StringBuffer();
  for (var index = 0; index < whole.length; index++) {
    if (index > 0 && (whole.length - index) % 3 == 0) {
      buffer.write(',');
    }
    buffer.write(whole[index]);
  }
  return '₱ ${buffer.toString()}$decimals';
}
