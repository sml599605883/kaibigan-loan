import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:kaibigan_loan/src/app_routes.dart';
import 'package:kaibigan_loan/src/assets/app_assets.dart';
import 'package:kaibigan_loan/src/core/client/client_bridge.dart';
import 'package:kaibigan_loan/src/core/json/json.dart';
import 'package:kaibigan_loan/src/core/network/api_client.dart';
import 'package:kaibigan_loan/src/core/network/api_config.dart';
import 'package:kaibigan_loan/src/core/network/api_exception.dart';
import 'package:kaibigan_loan/src/core/network/api_response.dart';
import 'package:kaibigan_loan/src/core/report/report_cache.dart';
import 'package:kaibigan_loan/src/core/report/report_manager.dart';
import 'package:kaibigan_loan/src/core/report/report_models.dart';
import 'package:kaibigan_loan/src/core/report/report_native_bridge.dart';
import 'package:kaibigan_loan/src/core/report/report_network.dart';
import 'package:kaibigan_loan/src/core/session/product_detail_cache.dart';
import 'package:kaibigan_loan/src/core/session/session_store.dart';
import 'package:kaibigan_loan/src/modules/certification/certification_bind_card_page.dart';
import 'package:kaibigan_loan/src/theme/app_colors.dart';
import 'package:kaibigan_loan/src/utils/app_toast.dart';

void main() {
  late _FakeApiClient apiClient;
  late _FakeToastPresenter toastPresenter;

  test('uses semantic bind card suggestion assets', () {
    expect(
      AppAssets.certificationBindCardSuggestionBubble,
      'assets/certification_bind_card_suggestion_bubble.png',
    );
    expect(
      AppAssets.certificationBindCardSuggestionClose,
      'assets/certification_bind_card_suggestion_close.png',
    );
  });

  setUp(() {
    Get.testMode = true;
    apiClient = _FakeApiClient();
    toastPresenter = _FakeToastPresenter();
    Get.put<ApiClient>(apiClient);
    Get.put<SessionStore>(SessionStore.memory());
    AppToast.presenter = toastPresenter;
  });

  tearDown(() {
    AppToast.presenter = const EasyLoadingToastPresenter();
    Get.reset();
  });

  testWidgets('loads only returned bind card groups', (tester) async {
    apiClient.states = _bindCardStates();

    await _pumpPage(tester, apiClient: apiClient, arguments: _arguments());
    await tester.pumpAndSettle();

    expect(apiClient.productIds, ['product-bind']);
    expect(find.text('E-wallet'), findsOneWidget);
    expect(find.text('Bank'), findsOneWidget);
    expect(find.text('Cash Pickup'), findsNothing);
    expect(
      find.byKey(const Key('bindCardField_wallet_number')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('bindCardProgress')), findsOneWidget);
    expect(
      (tester.widget<Image>(find.byKey(const Key('bindCardProgress'))).image
              as AssetImage)
          .assetName,
      AppAssets.certificationBindCardProgress,
    );
  });

  testWidgets('preserves group input state across tab switches', (
    tester,
  ) async {
    apiClient.states = _bindCardStates();
    await _pumpPage(tester, apiClient: apiClient, arguments: _arguments());
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('bindCardField_wallet_number')),
      '09171234567',
    );
    await tester.tap(find.byKey(const Key('bindCardTab_bank')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('bindCardField_account_number')),
      '1234567890',
    );
    await tester.tap(find.byKey(const Key('bindCardTab_wallet')));
    await tester.pumpAndSettle();

    expect(find.text('09171234567'), findsOneWidget);
    await tester.tap(find.byKey(const Key('bindCardTab_bank')));
    await tester.pumpAndSettle();
    expect(find.text('1234567890'), findsOneWidget);
  });

  testWidgets('enum sheet selects normalized value and display label', (
    tester,
  ) async {
    apiClient.states = _bindCardStates();
    await _pumpPage(tester, apiClient: apiClient, arguments: _arguments());
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('bindCardTab_bank')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('bindCardField_bank_code')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Metro Bank'));
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();

    expect(find.text('Metro Bank'), findsOneWidget);
    await tester.tap(find.byKey(const Key('bindCardTab_wallet')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('bindCardTab_bank')));
    await tester.pumpAndSettle();
    expect(find.text('Metro Bank'), findsOneWidget);
  });

  testWidgets('bind card option content centers until label needs ellipsis', (
    tester,
  ) async {
    const shortLabel = 'GCash';
    const noLogoLabel = 'Maya';
    const longLabel =
        'This payment provider name is intentionally too long for the row';
    apiClient.states = _optionLayoutStates(
      shortLabel: shortLabel,
      noLogoLabel: noLogoLabel,
      longLabel: longLabel,
    );
    await _pumpPage(tester, apiClient: apiClient, arguments: _arguments());
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('bindCardField_provider')));
    await tester.pumpAndSettle();

    final shortRow = find.byKey(const Key('bindCardOptionRow_0'));
    final shortContent = find.byKey(const Key('bindCardOptionContent_0'));
    final shortRowRect = tester.getRect(shortRow);
    final shortContentRect = tester.getRect(shortContent);
    final shortLogoRect = tester.getRect(
      find.descendant(of: shortContent, matching: find.byType(Image)),
    );
    final shortTextRect = tester.getRect(
      find.descendant(of: shortContent, matching: find.text(shortLabel)),
    );
    final shortVisibleCenter = (shortLogoRect.left + shortTextRect.right) / 2;
    expect(shortContentRect.width, lessThan(shortRowRect.width));
    expect(shortContentRect.center.dx, closeTo(shortRowRect.center.dx, 0.5));
    expect(shortVisibleCenter, closeTo(shortRowRect.center.dx, 0.5));

    final noLogoRow = find.byKey(const Key('bindCardOptionRow_1'));
    final noLogoContent = find.byKey(const Key('bindCardOptionContent_1'));
    final noLogoRowRect = tester.getRect(noLogoRow);
    final noLogoContentRect = tester.getRect(noLogoContent);
    expect(noLogoContentRect.width, lessThan(noLogoRowRect.width));
    expect(noLogoContentRect.center.dx, closeTo(noLogoRowRect.center.dx, 0.5));
    expect(
      find.descendant(of: noLogoContent, matching: find.byType(Image)),
      findsNothing,
    );

    final longRow = find.byKey(const Key('bindCardOptionRow_2'));
    final longContent = find.byKey(const Key('bindCardOptionContent_2'));
    final longTextFinder = find.descendant(
      of: longContent,
      matching: find.text(longLabel),
    );
    final longText = tester.widget<Text>(longTextFinder);
    final longRowRect = tester.getRect(longRow);
    final longContentRect = tester.getRect(longContent);
    final longTextRect = tester.getRect(longTextFinder);
    expect(longText.maxLines, 1);
    expect(longText.overflow, TextOverflow.ellipsis);
    expect(longContentRect.left, greaterThanOrEqualTo(longRowRect.left));
    expect(longContentRect.right, lessThanOrEqualTo(longRowRect.right));
    expect(longTextRect.left, greaterThanOrEqualTo(longRowRect.left));
    expect(longTextRect.right, lessThanOrEqualTo(longRowRect.right));

    final longLogo = find.descendant(
      of: longContent,
      matching: find.byType(Image),
    );
    expect(longLogo, findsOneWidget);
    expect(tester.getSize(longLogo), const Size(30, 30));
    expect(tester.takeException(), isNull);
  });

  testWidgets('bind card option row blank space remains tappable', (
    tester,
  ) async {
    const noLogoLabel = 'Maya';
    apiClient.states = _optionLayoutStates(
      shortLabel: 'GCash',
      noLogoLabel: noLogoLabel,
      longLabel:
          'This payment provider name is intentionally too long for the row',
    );
    await _pumpPage(tester, apiClient: apiClient, arguments: _arguments());
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('bindCardField_provider')));
    await tester.pumpAndSettle();

    final optionRowRect = tester.getRect(
      find.byKey(const Key('bindCardOptionRow_1')),
    );
    final optionContentRect = tester.getRect(
      find.byKey(const Key('bindCardOptionContent_1')),
    );
    final blankSpacePoint = Offset(
      optionRowRect.left + 2,
      optionRowRect.center.dy,
    );
    expect(blankSpacePoint.dx, lessThan(optionContentRect.left));

    await tester.tapAt(blankSpacePoint);
    await tester.pump();
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();

    expect(find.text(noLogoLabel), findsOneWidget);
  });

  testWidgets('text field displays initial value instead of display value', (
    tester,
  ) async {
    apiClient.states = _initialValueStates();
    await _pumpPage(tester, apiClient: apiClient, arguments: _arguments());
    await tester.pumpAndSettle();

    final firstName = tester.widget<TextField>(
      find.byKey(const Key('bindCardField_zips')),
    );
    expect(firstName.controller!.text, 'Shown Name');
    expect(find.text('Suggested Name'), findsNothing);
  });

  testWidgets('focused empty bind card field shows suggestion bubble', (
    tester,
  ) async {
    apiClient.states = _suggestionStates();
    await _pumpPage(tester, apiClient: apiClient, arguments: _arguments());
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('bindCardSuggestionBubble')), findsNothing);

    await tester.tap(find.byKey(const Key('bindCardField_firstName')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('bindCardSuggestionBubble')), findsOneWidget);
    expect(find.text('John'), findsOneWidget);
  });

  testWidgets('suggestion bubble sizes to content within field', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    const shortSuggestion = 'J';
    const mediumSuggestion = 'Michael Santos';
    const longSuggestion =
        'This suggestion is intentionally too long for the payment field';
    apiClient.states = _suggestionVisualStates(
      shortSuggestion: shortSuggestion,
      mediumSuggestion: mediumSuggestion,
      longSuggestion: longSuggestion,
    );
    await _pumpPage(tester, apiClient: apiClient, arguments: _arguments());
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('bindCardField_shortName')));
    await tester.pump();
    final bubble = find.byKey(const Key('bindCardSuggestionBubble'));
    final shortWidth = tester.getSize(bubble).width;
    expect(shortWidth, greaterThanOrEqualTo(44));
    expect(shortWidth, lessThan(104));
    expect(tester.getSize(bubble).height, 40);

    final images = tester
        .widgetList<Image>(
          find.descendant(of: bubble, matching: find.byType(Image)),
        )
        .toList();
    expect(
      images
          .map((image) => image.image)
          .whereType<AssetImage>()
          .map((image) => image.assetName),
      containsAll(<String>[
        AppAssets.certificationBindCardSuggestionBubble,
        AppAssets.certificationBindCardSuggestionClose,
      ]),
    );
    final closeImage = find.descendant(
      of: find.byKey(const Key('bindCardSuggestionClose')),
      matching: find.byWidgetPredicate(
        (widget) =>
            widget is Image &&
            widget.image is AssetImage &&
            (widget.image as AssetImage).assetName ==
                AppAssets.certificationBindCardSuggestionClose,
      ),
    );
    expect(tester.getSize(closeImage), const Size(12, 12));
    expect(
      tester.getSize(find.byKey(const Key('bindCardSuggestionClose'))),
      const Size(24, 24),
    );
    expect(
      tester.getSemantics(find.byKey(const Key('bindCardSuggestionClose'))),
      matchesSemantics(label: 'Close suggestion', isButton: true),
    );
    final shortText = tester.widget<Text>(find.text(shortSuggestion));
    expect(shortText.maxLines, 1);
    expect(shortText.overflow, TextOverflow.ellipsis);
    expect(shortText.style?.color, AppColors.certificationSubmitText);
    expect(shortText.style?.fontSize, 16);
    expect(shortText.style?.fontWeight, FontWeight.w600);

    await tester.tap(find.byKey(const Key('bindCardField_mediumName')));
    await tester.pump();
    final mediumWidth = tester.getSize(bubble).width;
    expect(mediumWidth, greaterThan(shortWidth));

    await tester.tap(find.byKey(const Key('bindCardField_longName')));
    await tester.pump();
    final longBubbleRect = tester.getRect(bubble);
    final longFieldRect = tester.getRect(
      find.byKey(const Key('bindCardField_longName')),
    );
    expect(longBubbleRect.width, lessThanOrEqualTo(310));
    expect(longBubbleRect.left, greaterThanOrEqualTo(longFieldRect.left));
    expect(longBubbleRect.right, lessThanOrEqualTo(longFieldRect.right));
    expect(longFieldRect.right - longBubbleRect.right, closeTo(25, 0.01));
    expect(
      tester.widget<Text>(find.text(longSuggestion)).overflow,
      TextOverflow.ellipsis,
    );
    await tester.tap(find.byKey(const Key('bindCardSuggestionClose')));
    await tester.pump();
    expect(_textFieldValue(tester, 'shortName'), isEmpty);
    expect(_textFieldValue(tester, 'mediumName'), isEmpty);
    expect(_textFieldValue(tester, 'longName'), isEmpty);
    expect(tester.takeException(), isNull);
    semantics.dispose();
  });

  testWidgets('suggestion fills eligible empty fields in selected group', (
    tester,
  ) async {
    apiClient.states = _suggestionStates();
    await _pumpPage(tester, apiClient: apiClient, arguments: _arguments());
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('bindCardField_firstName')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('bindCardSuggestionBubble')));
    await tester.pumpAndSettle();

    expect(_textFieldValue(tester, 'firstName'), 'John');
    expect(_textFieldValue(tester, 'middleName'), 'Michael');
    expect(_textFieldValue(tester, 'lastName'), 'Doe');
    expect(_textFieldValue(tester, 'optionalNote'), isEmpty);

    await tester.tap(find.byKey(const Key('bindCardTab_bank')));
    await tester.pumpAndSettle();
    expect(_textFieldValue(tester, 'account_number'), isEmpty);
  });

  testWidgets('suggestion stays hidden for ineligible bind card fields', (
    tester,
  ) async {
    apiClient.states = _suggestionStates();
    await _pumpPage(tester, apiClient: apiClient, arguments: _arguments());
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('bindCardSuggestionBubble')), findsNothing);

    await tester.tap(find.byKey(const Key('bindCardField_lastName')));
    await tester.pump();
    expect(find.byKey(const Key('bindCardSuggestionBubble')), findsNothing);

    await tester.tap(find.byKey(const Key('bindCardField_optionalNote')));
    await tester.pump();
    expect(find.byKey(const Key('bindCardSuggestionBubble')), findsNothing);

    await tester.tap(find.byKey(const Key('bindCardField_channelCode')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('bindCardSuggestionBubble')), findsNothing);
  });

  testWidgets('closed suggestion reopens after entering and clearing text', (
    tester,
  ) async {
    apiClient.states = _suggestionStates();
    await _pumpPage(tester, apiClient: apiClient, arguments: _arguments());
    await tester.pumpAndSettle();

    final firstName = find.byKey(const Key('bindCardField_firstName'));
    await tester.tap(firstName);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('bindCardSuggestionClose')));
    await tester.pump();
    expect(find.byKey(const Key('bindCardSuggestionBubble')), findsNothing);

    await tester.tap(find.byKey(const Key('bindCardField_optionalNote')));
    await tester.tap(firstName);
    await tester.pump();
    expect(find.byKey(const Key('bindCardSuggestionBubble')), findsNothing);

    await tester.enterText(firstName, 'A');
    await tester.enterText(firstName, '');
    await tester.pump();

    expect(find.byKey(const Key('bindCardSuggestionBubble')), findsOneWidget);
    expect(find.text('John'), findsOneWidget);
  });

  testWidgets('switching bind card groups clears bubble and preserves values', (
    tester,
  ) async {
    apiClient.states = _suggestionStates();
    await _pumpPage(tester, apiClient: apiClient, arguments: _arguments());
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('bindCardField_firstName')),
      'Alice',
    );
    await tester.tap(find.byKey(const Key('bindCardField_middleName')));
    await tester.pump();
    expect(find.byKey(const Key('bindCardSuggestionBubble')), findsOneWidget);

    await tester.tap(find.byKey(const Key('bindCardTab_bank')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('bindCardSuggestionBubble')), findsNothing);
    await tester.enterText(
      find.byKey(const Key('bindCardField_account_number')),
      '999',
    );

    await tester.tap(find.byKey(const Key('bindCardTab_wallet')));
    await tester.pumpAndSettle();
    expect(_textFieldValue(tester, 'firstName'), 'Alice');
    expect(find.byKey(const Key('bindCardSuggestionBubble')), findsNothing);

    await tester.tap(find.byKey(const Key('bindCardTab_bank')));
    await tester.pumpAndSettle();
    expect(_textFieldValue(tester, 'account_number'), '999');
  });

  testWidgets('enum initial value displays matched label and submits value', (
    tester,
  ) async {
    apiClient.states = _initialValueStates();
    apiClient.productDetailStates = {'wofuller': 'stay on bind card'};
    await _pumpPage(tester, apiClient: apiClient, arguments: _arguments());
    await tester.pumpAndSettle();

    expect(find.text('Union Bank'), findsOneWidget);
    expect(find.text('UBP'), findsNothing);

    await tester.tap(find.byKey(const Key('bindCardSubmit')));
    await tester.pumpAndSettle();

    expect(apiClient.saveRequests.single['bladers'], 'UBP');
  });

  testWidgets('opening enum sheet dismisses active text keyboard', (
    tester,
  ) async {
    apiClient.states = _bindCardStates();
    await _pumpPage(tester, apiClient: apiClient, arguments: _arguments());
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('bindCardField_wallet_number')));
    await tester.pump();
    expect(tester.testTextInput.isVisible, isTrue);

    await tester.tap(find.byKey(const Key('bindCardTab_bank')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('bindCardField_bank_code')));
    await tester.pumpAndSettle();

    expect(tester.testTextInput.isVisible, isFalse);
  });

  testWidgets('enum sheet scrolls a later initial selection into view', (
    tester,
  ) async {
    apiClient.states = _bindCardStates(optionCount: 7, initialBankValue: '6');
    await _pumpPage(tester, apiClient: apiClient, arguments: _arguments());
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('bindCardTab_bank')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('bindCardField_bank_code')));
    await tester.pumpAndSettle();

    final scrollable = tester.state<ScrollableState>(
      find.descendant(
        of: find.byKey(const Key('bindCardOptionList')),
        matching: find.byType(Scrollable),
      ),
    );
    expect(scrollable.position.pixels, greaterThan(0));
    expect(
      find.descendant(
        of: find.byKey(const Key('bindCardOptionList')),
        matching: find.text('Bank 6'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('back target and method tabs expose accessible semantics', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    apiClient.states = _bindCardStates();
    await _pumpPage(tester, apiClient: apiClient, arguments: _arguments());
    await tester.pumpAndSettle();

    expect(find.byTooltip('Back'), findsOneWidget);
    expect(tester.getSize(find.byTooltip('Back')), const Size(48, 48));
    expect(
      tester.getSemantics(find.byKey(const Key('bindCardTab_wallet'))),
      matchesSemantics(
        label: 'E-wallet',
        hasSelectedState: true,
        isButton: true,
        isSelected: true,
      ),
    );
    semantics.dispose();
  });

  testWidgets('large text scale keeps header title visible without overflow', (
    tester,
  ) async {
    apiClient.states = _bindCardStates();
    await _pumpPage(
      tester,
      apiClient: apiClient,
      arguments: _arguments(),
      textScaler: const TextScaler.linear(2),
    );
    await tester.pumpAndSettle();

    expect(find.text('Identity verification'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('disposed page ignores pending bank info response', (
    tester,
  ) async {
    final response = Completer<ApiResponse>();
    apiClient.pendingResponse = response;
    await _pumpPage(tester, apiClient: apiClient, arguments: _arguments());
    await tester.pump();

    Get.back<void>();
    await tester.pumpAndSettle();
    response.complete(
      ApiResponse(code: 0, message: 'success', states: Json(_bindCardStates())),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });

  testWidgets('API error displays Retry and reloads', (tester) async {
    apiClient.error = ApiBusinessException('offline');
    await _pumpPage(tester, apiClient: apiClient, arguments: _arguments());
    await tester.pumpAndSettle();

    expect(find.text('offline'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
    apiClient.error = null;
    apiClient.states = _bindCardStates();
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();

    expect(apiClient.productIds, ['product-bind', 'product-bind']);
    expect(find.text('E-wallet'), findsOneWidget);
  });

  testWidgets('empty groups displays exact empty text', (tester) async {
    apiClient.states = {'enthrones': []};
    await _pumpPage(tester, apiClient: apiClient, arguments: _arguments());
    await tester.pumpAndSettle();

    expect(find.text('No payment methods available'), findsOneWidget);
  });

  testWidgets('missing product ID makes no call and keeps stable UI', (
    tester,
  ) async {
    await _pumpPage(tester, apiClient: apiClient, arguments: const {});
    await tester.pumpAndSettle();

    expect(apiClient.productIds, isEmpty);
    expect(find.text('No payment methods available'), findsOneWidget);
  });

  testWidgets('does not throw or overflow at reference and narrow viewports', (
    tester,
  ) async {
    apiClient.states = _bindCardStates();
    await _pumpPage(tester, apiClient: apiClient, arguments: _arguments());
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    await _pumpPage(
      tester,
      apiClient: apiClient,
      arguments: _arguments(),
      size: const Size(320, 700),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('required empty field shows server placeholder without saving', (
    tester,
  ) async {
    apiClient.states = _submissionStates(emptyFirstName: true);
    await _pumpPage(tester, apiClient: apiClient, arguments: _arguments());
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('bindCardSubmit')));
    await tester.pumpAndSettle();

    expect(toastPresenter.messages, ['Enter your first name']);
    expect(toastPresenter.errors, isEmpty);
    expect(apiClient.saveRequests, isEmpty);
  });

  testWidgets(
    'different account entries follow the server submission contract',
    (tester) async {
      apiClient.states = _submissionStates(
        initialCardNo: '09170000000',
        initialConfirmCardNo: '09171111111',
      );
      await _pumpPage(tester, apiClient: apiClient, arguments: _arguments());
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('bindCardSubmit')));
      await tester.pumpAndSettle();

      expect(toastPresenter.messages, isEmpty);
      expect(apiClient.saveRequests, hasLength(1));
    },
  );

  testWidgets('submits documented string fields once', (tester) async {
    apiClient.states = _submissionStates();
    apiClient.productDetailStates = {'wofuller': 'stay on bind card'};
    final saveResponse = Completer<ApiResponse>();
    apiClient.pendingSaveResponse = saveResponse;
    await _pumpPage(tester, apiClient: apiClient, arguments: _arguments());
    await tester.pumpAndSettle();

    await _fillSubmissionForm(tester);
    final submit = find.byKey(const Key('bindCardSubmit'));
    await tester.tap(submit);
    await tester.pump();
    await tester.tap(submit);
    await tester.pump();

    expect(apiClient.saveRequests, [
      {
        'geobotanists': 'product-bind',
        'heirship': 'wallet',
        'bladers': '6',
        'zips': 'Jane',
        'acreage': '',
        'coinable': 'Doe',
        'flabby': '09171234567',
        'rapt': '09171234567',
      },
    ]);
    expect(tester.widget<ElevatedButton>(submit).onPressed, isNull);
    expect(toastPresenter.loadingMessages, [null]);

    saveResponse.complete(
      ApiResponse(code: 0, message: 'saved', states: Json(null)),
    );
    await tester.pumpAndSettle();

    expect(apiClient.productDetailIds, ['product-bind']);
    expect(toastPresenter.loadingMessages, [null, null]);
    expect(toastPresenter.dismissCount, 2);
  });

  testWidgets('account change binds and assigns the new payment method', (
    tester,
  ) async {
    apiClient.states = _submissionStates();
    apiClient.saveResponse = ApiResponse(
      code: 0,
      message: 'saved',
      states: Json({'smokehouse': 'bind-new'}),
    );
    apiClient.changeOrderAccountStates = {
      'preinserting': 'https://example.test/account-changed',
    };
    await _pumpPage(
      tester,
      apiClient: apiClient,
      arguments: <String, dynamic>{
        'geobotanists': 'product-bind',
        'dodgy': 'ORDER001',
        'isAccountChange': true,
      },
    );
    await tester.pumpAndSettle();

    await _fillSubmissionForm(tester);
    await tester.tap(find.byKey(const Key('bindCardSubmit')));
    await tester.pumpAndSettle();

    expect(apiClient.changeOrderAccountRequests, [
      {'dodgy': 'ORDER001', 'smokehouse': 'bind-new'},
    ]);
    expect(Get.currentRoute, AppRoutes.webView);
    expect(Get.arguments, <String, dynamic>{
      'url': 'https://example.test/account-changed',
      'title': null,
    });
    expect(apiClient.productDetailIds, isEmpty);
  });

  testWidgets('account change liveness uses the route order number', (
    tester,
  ) async {
    apiClient.states = _submissionStates();
    apiClient.saveResponses.addAll([
      ApiResponse(code: 20000, message: 'verify', states: Json(null)),
      ApiResponse(
        code: 0,
        message: 'saved',
        states: Json({'smokehouse': 'bind-live'}),
      ),
    ]);
    apiClient.faceTokenStates = _validFaceTokenStates();
    apiClient.changeOrderAccountStates = {
      'preinserting': 'https://example.test/live-account-changed',
    };
    await _pumpPage(
      tester,
      apiClient: apiClient,
      arguments: <String, dynamic>{
        'geobotanists': 'product-bind',
        'dodgy': 'ORDER-ROUTE',
        'isAccountChange': true,
      },
      showTrustDecisionLiveness: (_) async => _livenessSuccess(),
    );
    await tester.pumpAndSettle();

    await _fillSubmissionForm(tester);
    await tester.tap(find.byKey(const Key('bindCardSubmit')));
    await tester.pumpAndSettle();

    expect(apiClient.faceTokenRequests, [
      const _FaceTokenRequest(dodgy: 'ORDER-ROUTE', commensurate: '1'),
    ]);
    expect(apiClient.changeOrderAccountRequests, [
      {'dodgy': 'ORDER-ROUTE', 'smokehouse': 'bind-live'},
    ]);
    expect(Get.currentRoute, AppRoutes.webView);
    expect(Get.arguments, <String, dynamic>{
      'url': 'https://example.test/live-account-changed',
      'title': null,
    });
  });

  testWidgets('dismisses owned loading when disposed during save', (
    tester,
  ) async {
    apiClient.states = _submissionStates();
    final saveResponse = Completer<ApiResponse>();
    apiClient.pendingSaveResponse = saveResponse;
    await _pumpPage(tester, apiClient: apiClient, arguments: _arguments());
    await tester.pumpAndSettle();

    await _fillSubmissionForm(tester);
    await tester.tap(find.byKey(const Key('bindCardSubmit')));
    await tester.pump();

    expect(toastPresenter.loadingMessages, [null]);
    Get.back<void>();
    await tester.pumpAndSettle();
    expect(find.byType(CertificationBindCardPage), findsNothing);

    saveResponse.complete(
      ApiResponse(code: 0, message: 'saved', states: Json(null)),
    );
    for (var index = 0; index < 3; index++) {
      await tester.pump();
    }

    expect(toastPresenter.dismissCount, 1);
    expect(apiClient.productDetailIds, isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets('normal success reports risk scene 8', (tester) async {
    final reportManager = _RecordingReportManager();
    Get.put<ReportManager>(reportManager);
    apiClient.states = _submissionStates();
    apiClient.productDetailStates = {'wofuller': 'stay on bind card'};
    await _pumpPage(tester, apiClient: apiClient, arguments: _arguments());
    await tester.pumpAndSettle();

    await _fillSubmissionForm(tester);
    await tester.tap(find.byKey(const Key('bindCardSubmit')));
    for (var index = 0; index < 5; index++) {
      await tester.pump();
    }

    expect(reportManager.riskReports, hasLength(1));
    expect(reportManager.riskReports.single['productId'], 'product-bind');
    expect(reportManager.riskReports.single['sceneType'], '8');
    expect(reportManager.riskReports.single['startTimeSeconds'], isA<int>());
  });

  testWidgets('save failure shows resolved error and re-enables submit', (
    tester,
  ) async {
    apiClient.states = _submissionStates();
    apiClient.saveError = ApiBusinessException('save failed');
    await _pumpPage(tester, apiClient: apiClient, arguments: _arguments());
    await tester.pumpAndSettle();

    await _fillSubmissionForm(tester);
    final submit = find.byKey(const Key('bindCardSubmit'));
    await tester.tap(submit);
    await tester.pumpAndSettle();

    expect(toastPresenter.errors, ['save failed']);
    expect(apiClient.productDetailIds, isEmpty);
    expect(tester.widget<ElevatedButton>(submit).onPressed, isNotNull);
    expect(find.byKey(const Key('bindCardSubmit')), findsOneWidget);
  });

  testWidgets('resubmits documented liveness fields after code 20000', (
    tester,
  ) async {
    apiClient.states = _submissionStates();
    apiClient.saveResponses.addAll([
      ApiResponse(code: 20000, message: 'verify', states: Json(null)),
      ApiResponse(code: 0, message: 'saved', states: Json(null)),
    ]);
    apiClient.faceTokenStates = {
      'dwarfishly': '200',
      'thatches': 'license-1',
      'clevises': '7',
    };
    await SessionStore.instance.saveProductDetailCache(_productDetailCache());
    final reportManager = _RecordingReportManager();
    Get.put<ReportManager>(reportManager);
    var launchedLicense = '';
    await _pumpPage(
      tester,
      apiClient: apiClient,
      arguments: _arguments(),
      showTrustDecisionLiveness: (license) async {
        launchedLicense = license;
        return _livenessSuccess();
      },
    );
    await tester.pumpAndSettle();

    await _fillSubmissionForm(tester);
    await tester.tap(find.byKey(const Key('bindCardSubmit')));
    await tester.pumpAndSettle();

    expect(apiClient.faceTokenRequests, [
      const _FaceTokenRequest(dodgy: 'ORDER001', commensurate: '1'),
    ]);
    expect(launchedLicense, 'license-1');
    expect(apiClient.saveRequests, hasLength(2));
    expect(apiClient.saveRequests[1], {
      ...apiClient.saveRequests.first,
      'clevises': '7',
      'scolloped': 'live-1',
      'arrests': 'license-1',
    });
    expect(apiClient.productDetailIds, ['product-bind']);
    expect(reportManager.riskReports, hasLength(1));
    expect(toastPresenter.loadingMessages, [null, null, null]);
    expect(toastPresenter.dismissCount, 3);
  });

  testWidgets('missing order skips liveness verification', (tester) async {
    apiClient.states = _submissionStates();
    apiClient.saveResponses.add(
      ApiResponse(code: 20000, message: 'verify', states: Json(null)),
    );
    await _pumpPage(tester, apiClient: apiClient, arguments: _arguments());
    await tester.pumpAndSettle();

    await _fillSubmissionForm(tester);
    await tester.tap(find.byKey(const Key('bindCardSubmit')));
    await tester.pumpAndSettle();

    expect(apiClient.faceTokenRequests, isEmpty);
    expect(apiClient.saveRequests, hasLength(1));
    expect(toastPresenter.errors, [
      'Missing order information for liveness verification',
    ]);
  });

  testWidgets('token failure and missing license stop liveness verification', (
    tester,
  ) async {
    apiClient.states = _submissionStates();
    apiClient.saveResponses.add(
      ApiResponse(code: 20000, message: 'verify', states: Json(null)),
    );
    apiClient.faceTokenStates = {'dwarfishly': '500', 'rail': 'token denied'};
    await SessionStore.instance.saveProductDetailCache(_productDetailCache());
    await _pumpPage(tester, apiClient: apiClient, arguments: _arguments());
    await tester.pumpAndSettle();

    await _fillSubmissionForm(tester);
    await tester.tap(find.byKey(const Key('bindCardSubmit')));
    await tester.pumpAndSettle();

    expect(apiClient.saveRequests, hasLength(1));
    expect(toastPresenter.errors, ['token denied']);
  });

  testWidgets('missing token license stops liveness verification', (
    tester,
  ) async {
    apiClient.states = _submissionStates();
    apiClient.saveResponses.add(
      ApiResponse(code: 20000, message: 'verify', states: Json(null)),
    );
    apiClient.faceTokenStates = {'dwarfishly': '200', 'clevises': '7'};
    await SessionStore.instance.saveProductDetailCache(_productDetailCache());
    await _pumpPage(tester, apiClient: apiClient, arguments: _arguments());
    await tester.pumpAndSettle();

    await _fillSubmissionForm(tester);
    await tester.tap(find.byKey(const Key('bindCardSubmit')));
    await tester.pumpAndSettle();

    expect(apiClient.saveRequests, hasLength(1));
    expect(toastPresenter.errors, ['Failed to get face token']);
  });

  testWidgets('unsupported face type stops liveness verification', (
    tester,
  ) async {
    apiClient.states = _submissionStates();
    apiClient.saveResponses.add(
      ApiResponse(code: 20000, message: 'verify', states: Json(null)),
    );
    apiClient.faceTokenStates = {
      'dwarfishly': '200',
      'thatches': 'license-1',
      'clevises': '11',
    };
    await SessionStore.instance.saveProductDetailCache(_productDetailCache());
    await _pumpPage(tester, apiClient: apiClient, arguments: _arguments());
    await tester.pumpAndSettle();

    await _fillSubmissionForm(tester);
    await tester.tap(find.byKey(const Key('bindCardSubmit')));
    await tester.pumpAndSettle();

    expect(apiClient.saveRequests, hasLength(1));
    expect(toastPresenter.errors, ['Unsupported liveness verification type']);
  });

  testWidgets('native liveness failure stops resubmission', (tester) async {
    apiClient.states = _submissionStates();
    apiClient.saveResponses.add(
      ApiResponse(code: 20000, message: 'verify', states: Json(null)),
    );
    apiClient.faceTokenStates = _validFaceTokenStates();
    await SessionStore.instance.saveProductDetailCache(_productDetailCache());
    await _pumpPage(
      tester,
      apiClient: apiClient,
      arguments: _arguments(),
      showTrustDecisionLiveness: (_) async => _livenessFailure('native failed'),
    );
    await tester.pumpAndSettle();

    await _fillSubmissionForm(tester);
    await tester.tap(find.byKey(const Key('bindCardSubmit')));
    await tester.pumpAndSettle();

    expect(apiClient.saveRequests, hasLength(1));
    expect(toastPresenter.errors, ['native failed']);
  });

  testWidgets('native liveness failure uses the fallback message', (
    tester,
  ) async {
    apiClient.states = _submissionStates();
    apiClient.saveResponses.add(
      ApiResponse(code: 20000, message: 'verify', states: Json(null)),
    );
    apiClient.faceTokenStates = _validFaceTokenStates();
    await SessionStore.instance.saveProductDetailCache(_productDetailCache());
    await _pumpPage(
      tester,
      apiClient: apiClient,
      arguments: _arguments(),
      showTrustDecisionLiveness: (_) async => _livenessFailure(''),
    );
    await tester.pumpAndSettle();

    await _fillSubmissionForm(tester);
    await tester.tap(find.byKey(const Key('bindCardSubmit')));
    await tester.pumpAndSettle();

    expect(apiClient.saveRequests, hasLength(1));
    expect(toastPresenter.errors, ['Liveness verification failed']);
  });

  testWidgets('empty liveness ID stops resubmission', (tester) async {
    apiClient.states = _submissionStates();
    apiClient.saveResponses.add(
      ApiResponse(code: 20000, message: 'verify', states: Json(null)),
    );
    apiClient.faceTokenStates = _validFaceTokenStates();
    await SessionStore.instance.saveProductDetailCache(_productDetailCache());
    await _pumpPage(
      tester,
      apiClient: apiClient,
      arguments: _arguments(),
      showTrustDecisionLiveness: (_) async => _livenessSuccess(livenessId: ''),
    );
    await tester.pumpAndSettle();

    await _fillSubmissionForm(tester);
    await tester.tap(find.byKey(const Key('bindCardSubmit')));
    await tester.pumpAndSettle();

    expect(apiClient.saveRequests, hasLength(1));
    expect(toastPresenter.errors, ['Liveness verification failed']);
  });

  testWidgets('second code 20000 stops without another liveness loop', (
    tester,
  ) async {
    apiClient.states = _submissionStates();
    apiClient.saveResponses.addAll([
      ApiResponse(code: 20000, message: 'verify', states: Json(null)),
      ApiResponse(code: 20000, message: 'verify again', states: Json(null)),
    ]);
    apiClient.faceTokenStates = _validFaceTokenStates();
    await SessionStore.instance.saveProductDetailCache(_productDetailCache());
    await _pumpPage(
      tester,
      apiClient: apiClient,
      arguments: _arguments(),
      showTrustDecisionLiveness: (_) async => _livenessSuccess(),
    );
    await tester.pumpAndSettle();

    await _fillSubmissionForm(tester);
    await tester.tap(find.byKey(const Key('bindCardSubmit')));
    await tester.pumpAndSettle();

    expect(apiClient.saveRequests, hasLength(2));
    expect(apiClient.faceTokenRequests, hasLength(1));
    expect(apiClient.productDetailIds, isEmpty);
    expect(toastPresenter.errors, ['Liveness verification was not accepted']);
  });

  testWidgets('second save exception resolves error and closes loading', (
    tester,
  ) async {
    apiClient.states = _submissionStates();
    apiClient.saveResponses.add(
      ApiResponse(code: 20000, message: 'verify', states: Json(null)),
    );
    apiClient.throwOnSaveCall = 2;
    apiClient.faceTokenStates = _validFaceTokenStates();
    await SessionStore.instance.saveProductDetailCache(_productDetailCache());
    await _pumpPage(
      tester,
      apiClient: apiClient,
      arguments: _arguments(),
      showTrustDecisionLiveness: (_) async => _livenessSuccess(),
    );
    await tester.pumpAndSettle();

    await _fillSubmissionForm(tester);
    await tester.tap(find.byKey(const Key('bindCardSubmit')));
    await tester.pumpAndSettle();

    expect(apiClient.saveRequests, hasLength(2));
    expect(toastPresenter.errors, ['save failed']);
    expect(toastPresenter.dismissCount, 2);
  });

  testWidgets('disposal during token request closes loading', (tester) async {
    apiClient.states = _submissionStates();
    apiClient.saveResponses.add(
      ApiResponse(code: 20000, message: 'verify', states: Json(null)),
    );
    final tokenResponse = Completer<ApiResponse>();
    apiClient.pendingFaceTokenResponse = tokenResponse;
    await SessionStore.instance.saveProductDetailCache(_productDetailCache());
    var nativeCalls = 0;
    await _pumpPage(
      tester,
      apiClient: apiClient,
      arguments: _arguments(),
      showTrustDecisionLiveness: (_) async {
        nativeCalls += 1;
        return _livenessSuccess();
      },
    );
    await tester.pumpAndSettle();

    await _fillSubmissionForm(tester);
    await tester.tap(find.byKey(const Key('bindCardSubmit')));
    await tester.pump();
    Get.back<void>();
    await tester.pumpAndSettle();
    tokenResponse.complete(_faceTokenResponse());
    await tester.pump();
    await tester.pump();

    expect(nativeCalls, 0);
    expect(apiClient.saveRequests, hasLength(1));
    expect(toastPresenter.dismissCount, 1);
  });

  testWidgets('disposal during native liveness does not resubmit', (
    tester,
  ) async {
    apiClient.states = _submissionStates();
    apiClient.saveResponses.add(
      ApiResponse(code: 20000, message: 'verify', states: Json(null)),
    );
    apiClient.faceTokenStates = _validFaceTokenStates();
    await SessionStore.instance.saveProductDetailCache(_productDetailCache());
    final livenessResult = Completer<TrustDecisionLivenessResult>();
    await _pumpPage(
      tester,
      apiClient: apiClient,
      arguments: _arguments(),
      showTrustDecisionLiveness: (_) => livenessResult.future,
    );
    await tester.pumpAndSettle();

    await _fillSubmissionForm(tester);
    await tester.tap(find.byKey(const Key('bindCardSubmit')));
    await tester.pump();
    Get.back<void>();
    await tester.pumpAndSettle();
    livenessResult.complete(_livenessSuccess());
    await tester.pump();
    await tester.pump();

    expect(apiClient.saveRequests, hasLength(1));
    expect(toastPresenter.dismissCount, 1);
  });

  testWidgets('disposal during second save closes retry loading', (
    tester,
  ) async {
    apiClient.states = _submissionStates();
    apiClient.saveResponses.add(
      ApiResponse(code: 20000, message: 'verify', states: Json(null)),
    );
    apiClient.faceTokenStates = _validFaceTokenStates();
    final retryResponse = Completer<ApiResponse>();
    apiClient.pendingSecondSaveResponse = retryResponse;
    await SessionStore.instance.saveProductDetailCache(_productDetailCache());
    await _pumpPage(
      tester,
      apiClient: apiClient,
      arguments: _arguments(),
      showTrustDecisionLiveness: (_) async => _livenessSuccess(),
    );
    await tester.pumpAndSettle();

    await _fillSubmissionForm(tester);
    await tester.tap(find.byKey(const Key('bindCardSubmit')));
    for (var index = 0; index < 3; index++) {
      await tester.pump();
    }
    expect(apiClient.saveRequests, hasLength(2));
    Get.back<void>();
    await tester.pumpAndSettle();
    retryResponse.complete(
      ApiResponse(code: 0, message: 'saved', states: Json(null)),
    );
    await tester.pump();
    await tester.pump();

    expect(apiClient.productDetailIds, isEmpty);
    expect(toastPresenter.dismissCount, 2);
  });
}

Future<void> _fillSubmissionForm(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('bindCardField_bladers')));
  await tester.pumpAndSettle();
  await tester.tap(find.text('GCash').last);
  await tester.tap(find.text('Done'));
  await tester.pumpAndSettle();
  await tester.enterText(find.byKey(const Key('bindCardField_zips')), ' Jane ');
  await tester.enterText(
    find.byKey(const Key('bindCardField_coinable')),
    ' Doe ',
  );
  await tester.enterText(
    find.byKey(const Key('bindCardField_flabby')),
    ' 09171234567 ',
  );
  await tester.enterText(
    find.byKey(const Key('bindCardField_rapt')),
    '09171234567',
  );
}

String _textFieldValue(WidgetTester tester, String saveKey) {
  return tester
      .widget<TextField>(find.byKey(Key('bindCardField_$saveKey')))
      .controller!
      .text;
}

Future<void> _pumpPage(
  WidgetTester tester, {
  required _FakeApiClient apiClient,
  required Object? arguments,
  BindCardLivenessLauncher? showTrustDecisionLiveness,
  Size size = const Size(375, 812),
  TextScaler textScaler = TextScaler.noScaling,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  const routeName = AppRoutes.certificationBindCard;
  await tester.pumpWidget(
    GetMaterialApp(
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(textScaler: textScaler),
        child: child!,
      ),
      initialRoute: '/',
      getPages: [
        GetPage(name: '/', page: () => const SizedBox()),
        GetPage(
          name: routeName,
          page: () => CertificationBindCardPage(
            apiClient: apiClient,
            showTrustDecisionLiveness: showTrustDecisionLiveness,
          ),
        ),
        GetPage(
          name: AppRoutes.webView,
          page: () => const SizedBox(key: Key('webViewPageStub')),
        ),
      ],
    ),
  );
  await tester.pumpAndSettle();
  Get.toNamed<Object?>(routeName, arguments: arguments);
  await tester.pump();
}

Map<String, String> _arguments() => {'geobotanists': ' product-bind '};

ProductDetailCache _productDetailCache() => const ProductDetailCache(
  amount: '',
  productid: '',
  orderNo: ' ORDER001 ',
  orderId: '',
  term: '',
  termType: '',
  note: {},
  nextStep: {},
);

Map<String, dynamic> _validFaceTokenStates() => {
  'dwarfishly': '200',
  'thatches': 'license-1',
  'clevises': '7',
};

ApiResponse _faceTokenResponse() => ApiResponse(
  code: 0,
  message: 'token ready',
  states: Json(_validFaceTokenStates()),
);

TrustDecisionLivenessResult _livenessSuccess({String livenessId = 'live-1'}) =>
    TrustDecisionLivenessResult(
      success: true,
      code: 0,
      message: '',
      image: '',
      sequenceId: '',
      livenessId: livenessId,
      raw: const {},
    );

TrustDecisionLivenessResult _livenessFailure(String message) =>
    TrustDecisionLivenessResult(
      success: false,
      code: -1,
      message: message,
      image: '',
      sequenceId: '',
      livenessId: '',
      raw: const {},
    );

Map<String, dynamic> _bindCardStates({
  int optionCount = 1,
  String initialBankValue = '7',
}) => {
  'mourningly': 'Choose your payment method',
  'pollywogs': 'Details must match your identity',
  'enthrones': [
    {
      'primogenitor': 'E-wallet',
      'commensurate': 'wallet',
      'enthrones': [
        {
          'primogenitor': 'Wallet number',
          'griding': 'wallet_number',
          'suppletive': 'Enter wallet number',
          'prognosticator': 'Foxfishes',
          'solonets': '09170000000',
        },
      ],
    },
    {
      'primogenitor': 'Bank',
      'commensurate': 'bank',
      'enthrones': [
        {
          'primogenitor': 'Bank name',
          'griding': 'bank_code',
          'suppletive': 'Choose your bank',
          'prognosticator': 'Metallike',
          'solonets': initialBankValue,
          'whackers': optionCount > 1 ? 'Bank $initialBankValue' : 'Old Bank',
          'metallurgists': optionCount > 1
              ? List.generate(
                  optionCount,
                  (index) => {
                    'commensurate': index,
                    'unwits': 'Bank $index',
                    'bondmen': 0,
                  },
                )
              : [
                  {
                    'commensurate': 8,
                    'unwits': 'Metro Bank',
                    'vocalically': 'https://api.example.com/metro.png',
                    'bondmen': 0,
                  },
                ],
        },
        {
          'primogenitor': 'Account number',
          'griding': 'account_number',
          'suppletive': 'Enter account number',
          'prognosticator': 'Foxfishes',
        },
      ],
    },
  ],
};

Map<String, dynamic> _optionLayoutStates({
  required String shortLabel,
  required String noLogoLabel,
  required String longLabel,
}) => {
  'enthrones': [
    {
      'primogenitor': 'E-wallet',
      'commensurate': 'wallet',
      'enthrones': [
        {
          'primogenitor': 'Provider',
          'griding': 'provider',
          'suppletive': 'Choose a provider',
          'prognosticator': 'Metallike',
          'metallurgists': [
            {
              'commensurate': 'short',
              'unwits': shortLabel,
              'vocalically': 'https://api.example.com/short.png',
            },
            {'commensurate': 'no-logo', 'unwits': noLogoLabel},
            {
              'commensurate': 'long',
              'unwits': longLabel,
              'vocalically': 'https://api.example.com/long.png',
            },
          ],
        },
      ],
    },
  ],
};

Map<String, dynamic> _suggestionStates() => {
  'enthrones': [
    {
      'primogenitor': 'E-wallet',
      'commensurate': 'wallet',
      'enthrones': [
        {
          'primogenitor': 'Channel',
          'griding': 'channelCode',
          'suppletive': 'Choose a channel',
          'prognosticator': 'Metallike',
          'whackers': 'GCash',
          'metallurgists': [
            {'commensurate': 'gcash', 'unwits': 'GCash'},
          ],
        },
        {
          'primogenitor': 'First name',
          'griding': 'firstName',
          'suppletive': 'Enter your first name',
          'prognosticator': 'Foxfishes',
          'whackers': 'John',
        },
        {
          'primogenitor': 'Middle name',
          'griding': 'middleName',
          'suppletive': 'Enter your middle name',
          'prognosticator': 'Foxfishes',
          'whackers': 'Michael',
        },
        {
          'primogenitor': 'Last name',
          'griding': 'lastName',
          'suppletive': 'Enter your last name',
          'prognosticator': 'Foxfishes',
          'solonets': 'Doe',
          'whackers': 'Smith',
        },
        {
          'primogenitor': 'Optional note',
          'griding': 'optionalNote',
          'suppletive': 'Enter a note',
          'prognosticator': 'Foxfishes',
        },
      ],
    },
    {
      'primogenitor': 'Bank',
      'commensurate': 'bank',
      'enthrones': [
        {
          'primogenitor': 'Account number',
          'griding': 'account_number',
          'suppletive': 'Enter account number',
          'prognosticator': 'Foxfishes',
          'whackers': '1234567890',
        },
      ],
    },
  ],
};

Map<String, dynamic> _suggestionVisualStates({
  required String shortSuggestion,
  required String mediumSuggestion,
  required String longSuggestion,
}) => {
  'enthrones': [
    {
      'primogenitor': 'E-wallet',
      'commensurate': 'wallet',
      'enthrones': [
        {
          'primogenitor': 'Short name',
          'griding': 'shortName',
          'suppletive': 'Enter a short name',
          'prognosticator': 'Foxfishes',
          'whackers': shortSuggestion,
        },
        {
          'primogenitor': 'Medium name',
          'griding': 'mediumName',
          'suppletive': 'Enter a medium name',
          'prognosticator': 'Foxfishes',
          'whackers': mediumSuggestion,
        },
        {
          'primogenitor': 'Long name',
          'griding': 'longName',
          'suppletive': 'Enter a long name',
          'prognosticator': 'Foxfishes',
          'whackers': longSuggestion,
        },
      ],
    },
  ],
};

Map<String, dynamic> _submissionStates({
  bool emptyFirstName = false,
  String initialCardNo = '',
  String initialConfirmCardNo = '',
}) => {
  'enthrones': [
    {
      'primogenitor': 'E-wallet',
      'commensurate': 'wallet',
      'enthrones': [
        {
          'primogenitor': 'Channel',
          'griding': 'bladers',
          'suppletive': 'Choose a channel',
          'prognosticator': 'Metallike',
          'hairbreadth': 0,
          'solonets': 6,
          'whackers': 'GCash',
          'metallurgists': [
            {'commensurate': 6, 'unwits': 'GCash', 'bondmen': 0},
          ],
        },
        {
          'primogenitor': 'First name',
          'griding': 'zips',
          'suppletive': 'Enter your first name',
          'prognosticator': 'Foxfishes',
          'hairbreadth': 0,
          if (!emptyFirstName) 'solonets': 'Jane',
        },
        {
          'primogenitor': 'Middle name',
          'griding': 'acreage',
          'suppletive': '',
          'prognosticator': 'Foxfishes',
          'hairbreadth': 1,
        },
        {
          'primogenitor': 'Last name',
          'griding': 'coinable',
          'suppletive': 'Enter your last name',
          'prognosticator': 'Foxfishes',
          'hairbreadth': 0,
          'solonets': 'Doe',
        },
        {
          'primogenitor': 'Account number',
          'griding': 'flabby',
          'suppletive': 'Enter account number',
          'prognosticator': 'Foxfishes',
          'hairbreadth': 0,
          'solonets': initialCardNo.isEmpty ? '09171234567' : initialCardNo,
        },
        {
          'primogenitor': 'Confirm account number',
          'griding': 'rapt',
          'suppletive': 'Confirm account number',
          'prognosticator': 'Foxfishes',
          'hairbreadth': 0,
          'solonets': initialConfirmCardNo.isEmpty
              ? '09171234567'
              : initialConfirmCardNo,
        },
        {
          'primogenitor': 'Funny Loan field',
          'griding': 'bank_code',
          'suppletive': 'Ignore this field',
          'prognosticator': 'Foxfishes',
          'hairbreadth': 0,
          'solonets': 'must-not-submit',
        },
      ],
    },
  ],
};

Map<String, dynamic> _initialValueStates() => {
  'enthrones': [
    {
      'primogenitor': 'Bank',
      'commensurate': '2',
      'enthrones': [
        {
          'primogenitor': 'Bank',
          'griding': 'bladers',
          'suppletive': 'Choose a bank',
          'prognosticator': 'Metallike',
          'hairbreadth': 0,
          'solonets': 'UBP',
          'whackers': 'Suggested Bank',
          'metallurgists': [
            {'commensurate': 'BDO', 'unwits': 'Banco de Oro'},
            {'commensurate': 'UBP', 'unwits': 'Union Bank'},
          ],
        },
        {
          'primogenitor': 'First name',
          'griding': 'zips',
          'suppletive': 'First name',
          'prognosticator': 'Foxfishes',
          'hairbreadth': 0,
          'solonets': 'Shown Name',
          'whackers': 'Suggested Name',
        },
        {
          'primogenitor': 'Middle name',
          'griding': 'acreage',
          'prognosticator': 'Foxfishes',
          'hairbreadth': 1,
        },
        {
          'primogenitor': 'Last name',
          'griding': 'coinable',
          'prognosticator': 'Foxfishes',
          'hairbreadth': 0,
          'solonets': 'Doe',
        },
        {
          'primogenitor': 'Account number',
          'griding': 'flabby',
          'prognosticator': 'Foxfishes',
          'hairbreadth': 0,
          'solonets': '09171234567',
        },
        {
          'primogenitor': 'Confirm account number',
          'griding': 'rapt',
          'prognosticator': 'Foxfishes',
          'hairbreadth': 0,
          'solonets': '09171234567',
        },
      ],
    },
  ],
};

class _FakeApiClient extends ApiClient {
  _FakeApiClient() : super(ApiConfig(), dio: Dio());

  final productIds = <String>[];
  final productDetailIds = <String>[];
  final saveRequests = <Map<String, String>>[];
  final faceTokenRequests = <_FaceTokenRequest>[];
  final changeOrderAccountRequests = <Map<String, String>>[];
  final saveResponses = <ApiResponse>[];
  Map<String, dynamic> states = <String, dynamic>{};
  Map<String, dynamic> productDetailStates = <String, dynamic>{};
  Map<String, dynamic> changeOrderAccountStates = <String, dynamic>{};
  Object? error;
  Object? saveError;
  Completer<ApiResponse>? pendingResponse;
  Completer<ApiResponse>? pendingSaveResponse;
  Completer<ApiResponse>? pendingSecondSaveResponse;
  Completer<ApiResponse>? pendingFaceTokenResponse;
  ApiResponse? saveResponse;
  Map<String, dynamic> faceTokenStates = const {};
  int? throwOnSaveCall;

  @override
  Future<ApiResponse> bankInfo({required String geobotanists}) async {
    productIds.add(geobotanists);
    final requestError = error;
    if (requestError != null) {
      throw requestError;
    }
    final pending = pendingResponse;
    if (pending != null) {
      return pending.future;
    }
    return ApiResponse(code: 0, message: 'success', states: Json(states));
  }

  @override
  Future<ApiResponse> saveBankInfo({
    required String geobotanists,
    required String heirship,
    required String bladers,
    required String zips,
    required String acreage,
    required String coinable,
    required String flabby,
    required String rapt,
    String clevises = '',
    String scolloped = '',
    String arrests = '',
  }) async {
    saveRequests.add({
      'geobotanists': geobotanists,
      'heirship': heirship,
      'bladers': bladers,
      'zips': zips,
      'acreage': acreage,
      'coinable': coinable,
      'flabby': flabby,
      'rapt': rapt,
      if (clevises.isNotEmpty) 'clevises': clevises,
      if (scolloped.isNotEmpty) 'scolloped': scolloped,
      if (arrests.isNotEmpty) 'arrests': arrests,
    });
    if (throwOnSaveCall == saveRequests.length) {
      throw ApiBusinessException('save failed');
    }
    final requestError = saveError;
    if (requestError != null) {
      throw requestError;
    }
    final pending = pendingSaveResponse;
    if (pending != null) {
      return pending.future;
    }
    if (saveRequests.length == 2 && pendingSecondSaveResponse != null) {
      return pendingSecondSaveResponse!.future;
    }
    if (saveResponses.isNotEmpty) {
      return saveResponses.removeAt(0);
    }
    return saveResponse ??
        ApiResponse(code: 0, message: 'saved', states: Json(null));
  }

  @override
  Future<ApiResponse> changeOrderAccount({
    required String dodgy,
    required String smokehouse,
  }) async {
    changeOrderAccountRequests.add({'dodgy': dodgy, 'smokehouse': smokehouse});
    return ApiResponse(
      code: 0,
      message: 'changed',
      states: Json(changeOrderAccountStates),
    );
  }

  @override
  Future<ApiResponse> getFaceToken({
    required String dodgy,
    required String commensurate,
  }) async {
    faceTokenRequests.add(
      _FaceTokenRequest(dodgy: dodgy, commensurate: commensurate),
    );
    final pending = pendingFaceTokenResponse;
    if (pending != null) {
      return pending.future;
    }
    return ApiResponse(
      code: 0,
      message: 'token ready',
      states: Json(faceTokenStates),
    );
  }

  @override
  Future<ApiResponse> productDetail({required String geobotanists}) async {
    productDetailIds.add(geobotanists);
    return ApiResponse(
      code: 0,
      message: 'success',
      states: Json(productDetailStates),
    );
  }
}

class _FaceTokenRequest {
  const _FaceTokenRequest({required this.dodgy, required this.commensurate});

  final String dodgy;
  final String commensurate;

  @override
  bool operator ==(Object other) =>
      other is _FaceTokenRequest &&
      other.dodgy == dodgy &&
      other.commensurate == commensurate;

  @override
  int get hashCode => Object.hash(dodgy, commensurate);
}

class _FakeToastPresenter implements ToastPresenter {
  final messages = <String>[];
  final errors = <String>[];
  final loadingMessages = <String?>[];
  int dismissCount = 0;

  @override
  Future<void> dismissLoading() async {
    dismissCount += 1;
  }

  @override
  Future<void> show(String message, {required bool isError}) async {
    if (isError) {
      errors.add(message);
      dismissCount += 1;
      return;
    }
    messages.add(message);
  }

  @override
  Future<void> showLoading(String? message) async {
    loadingMessages.add(message);
  }
}

class _RecordingReportManager extends ReportManager {
  _RecordingReportManager()
    : super(
        cache: _FakeReportCache(),
        nativeBridge: _FakeReportNativeBridge(),
        network: _FakeReportNetwork(),
      );

  final riskReports = <Map<String, Object>>[];

  @override
  Future<void> reportRiskBehavior({
    required String productId,
    required String sceneType,
    required String orderNo,
    required int startTimeSeconds,
  }) async {
    riskReports.add({
      'productId': productId,
      'sceneType': sceneType,
      'orderNo': orderNo,
      'startTimeSeconds': startTimeSeconds,
    });
  }
}

class _FakeReportCache implements ReportCache {
  @override
  Future<void> clearSessionReportState() async {}
  @override
  Future<String> getAttributionLastStatus() async => '';
  @override
  Future<String> getLastMarketSignature() async => '';
  @override
  Future<String> getLastPushToken() async => '';
  @override
  Future<int> getLoginAt() async => 0;
  @override
  Future<ReportLocation?> getLocation() async => null;
  @override
  Future<bool> isAttributionInitialized() async => false;
  @override
  Future<bool> isLoggedIn() async => false;
  @override
  Future<bool> markAppOpened() async => false;
  @override
  Future<void> saveLocation(ReportLocation location) async {}
  @override
  Future<void> setAttributionInitialized(bool value) async {}
  @override
  Future<void> setAttributionLastStatus(String value) async {}
  @override
  Future<void> setLastMarketSignature(String signature) async {}
  @override
  Future<void> setLastPushToken(String token) async {}
  @override
  Future<void> setLoginAt(int millis) async {}
}

class _FakeReportNativeBridge implements ReportNativeBridge {
  @override
  Future<NativeDeviceSnapshot> getDeviceSnapshot() async =>
      const NativeDeviceSnapshot();
  @override
  Future<ReportLocation?> getLocation() async => null;
  @override
  Future<String> getPushToken() async => '';
  @override
  Future<String> getTrackingStatus() async => '';
  @override
  Future<void> initializeAttribution(String token) async {}
  @override
  Stream<Json> nativeEvents() => const Stream<Json>.empty();
  @override
  Future<String> requestNotificationPermission() async => '';
  @override
  Future<String> requestTrackingPermission() async => '';
}

class _FakeReportNetwork implements ReportNetwork {
  @override
  Future<void> reportContacts(String encryptedPayload) async {}
  @override
  Future<void> reportDeviceInfo(String encryptedPayload) async {}
  @override
  Future<void> reportFaceResult(FaceReportPayload payload) async {}
  @override
  Future<Json> reportGoogleMarket({
    required String idfv,
    required String idfa,
  }) async => Json(null);
  @override
  Future<void> reportLocation(ReportLocation location) async {}
  @override
  Future<void> reportPushToken(String token) async {}
  @override
  Future<void> reportRiskBehavior(Map<String, dynamic> payload) async {}
}
