import 'package:flutter_test/flutter_test.dart';
import 'package:kaibigan_loan/src/modules/webview/webview_bridge_constants.dart';
import 'package:kaibigan_loan/src/modules/webview/webview_bridge_dispatcher.dart';
import 'package:kaibigan_loan/src/modules/webview/webview_bridge_models.dart';

void main() {
  test('uses the documented H5 action names', () {
    expect(
      WebViewBridgeActionNames.uploadRiskLoan,
      'kaibigan_loan_TAAlKuFPyTVAexW',
    );
    expect(
      WebViewBridgeActionNames.openExternalBrowser,
      'kaibigan_loan_I6SZup98Aee801D',
    );
    expect(
      WebViewBridgeActionNames.openScheme,
      'kaibigan_loan_2rMMZjOR10rkmxP',
    );
    expect(WebViewBridgeActionNames.closePage, 'kaibigan_loan_cmag9tFa527yie7');
    expect(
      WebViewBridgeActionNames.backToHome,
      'kaibigan_loan_6FBoMqtSpneEbkM',
    );
    expect(WebViewBridgeActionNames.toGrade, 'kaibigan_loan_x2xWItx6A1zrRnI');
    expect(
      WebViewBridgeActionNames.retryOrder,
      'kaibigan_loan_zludGTQUWOfJiDD',
    );
    expect(
      WebViewBridgeActionNames.changeAccount,
      'kaibigan_loan_tG1ScTBB2N4bouJ',
    );
    expect(
      WebViewBridgeActionNames.requestCommonParams,
      'kaibigan_loan_WFWkobV9cU2jiDg',
    );
  });

  test('opens HTTP scheme in a new app WebView', () async {
    String? openedUrl;
    final dispatcher = WebViewBridgeDispatcher(
      openInNewWebView: (url) async => openedUrl = url,
    );

    final result = await dispatcher.dispatch(
      _request(WebViewBridgeActionNames.openScheme, <String, dynamic>{
        'url': 'https://example.test/order?id=1',
      }),
    );

    expect(result.code, 0);
    expect(openedUrl, 'https://example.test/order?id=1');
  });

  test('opens non-HTTP scheme through controlled navigation', () async {
    String? navigatedTarget;
    final dispatcher = WebViewBridgeDispatcher(
      navigateInternalUri: (target) async => navigatedTarget = target,
    );

    final result = await dispatcher.dispatch(
      _request(WebViewBridgeActionNames.openScheme, <String, dynamic>{
        'url': 'ph://kaibigan-loan/ios/orderList',
      }),
    );

    expect(result.code, 0);
    expect(navigatedTarget, 'ph://kaibigan-loan/ios/orderList');
  });

  test('opens system schemes through the external launcher', () async {
    Uri? openedUri;
    final dispatcher = WebViewBridgeDispatcher(
      openExternalUri: (uri) async {
        openedUri = uri;
        return true;
      },
    );

    final result = await dispatcher.dispatch(
      _request(WebViewBridgeActionNames.openScheme, <String, dynamic>{
        'url': 'tel:+639171234567',
      }),
    );

    expect(result.code, 0);
    expect(openedUri, Uri.parse('tel:+639171234567'));
  });

  test('returns common params through a callback dependency', () async {
    final dispatcher = WebViewBridgeDispatcher(
      buildSignedParams: (path) async => <String, dynamic>{
        'path': path,
        'signature': 'signed',
      },
    );

    final result = await dispatcher.dispatch(
      const WebViewBridgeRequest(
        action: WebViewBridgeActionNames.requestCommonParams,
        callbackId: 'callback-1',
        data: <String, dynamic>{},
        rawData: '/plater/dodgy',
      ),
    );

    expect(result.code, 0);
    expect(result.data, <String, dynamic>{
      'path': '/plater/dodgy',
      'signature': 'signed',
    });
  });

  test(
    'opens account selection with the H5 product and order fields',
    () async {
      String? selectedProductId;
      String? selectedOrderNo;
      String? openedUrl;
      final dispatcher = WebViewBridgeDispatcher(
        changeAccount: ({required productId, required orderNo}) async {
          selectedProductId = productId;
          selectedOrderNo = orderNo;
          return 'https://example.test/changed-account';
        },
        reloadOrOpenInWebView: (url) async => openedUrl = url,
      );

      final result = await dispatcher.dispatch(
        _request(
          WebViewBridgeActionNames.changeAccount,
          const <String, dynamic>{
            'seamounts': 'product-1',
            'chattinesses': 'ORDER001',
          },
        ),
      );

      expect(result.code, 0);
      expect(selectedProductId, 'product-1');
      expect(selectedOrderNo, 'ORDER001');
      expect(openedUrl, 'https://example.test/changed-account');
    },
  );

  test('reads H5 risk and retry payload fields', () async {
    String? riskProductId;
    String? riskOrderNo;
    String? retriedOrderNo;
    String? loadedUrl;
    var loadingCount = 0;
    var dismissCount = 0;
    final dispatcher = WebViewBridgeDispatcher(
      reportRisk:
          ({
            required productId,
            required orderNo,
            required startTimeSeconds,
          }) async {
            riskProductId = productId;
            riskOrderNo = orderNo;
          },
      retryOrder: (orderNo) async {
        retriedOrderNo = orderNo;
        return 'https://example.test/retry';
      },
      reloadOrOpenInWebView: (url) async => loadedUrl = url,
      showLoading: () async => loadingCount++,
      dismissLoading: () async => dismissCount++,
    );

    final riskResult = await dispatcher.dispatch(
      _request(WebViewBridgeActionNames.uploadRiskLoan, const <String, dynamic>{
        'seamounts': 'product-2',
        'chattinesses': 'ORDER002',
      }),
    );
    final retryResult = await dispatcher.dispatch(
      _request(WebViewBridgeActionNames.retryOrder, const <String, dynamic>{
        'chattinesses': 'ORDER003',
      }),
    );

    expect(riskResult.code, 0);
    expect(riskProductId, 'product-2');
    expect(riskOrderNo, 'ORDER002');
    expect(retryResult.code, 0);
    expect(retriedOrderNo, 'ORDER003');
    expect(loadedUrl, 'https://example.test/retry');
    expect(loadingCount, 1);
    expect(dismissCount, 1);
  });

  test('retry dismisses loading and reports request failure', () async {
    var dismissCount = 0;
    String? shownError;
    final dispatcher = WebViewBridgeDispatcher(
      retryOrder: (_) async => throw StateError('retry failed'),
      showLoading: () async {},
      dismissLoading: () async => dismissCount++,
      showError: (message) async => shownError = message,
    );

    final result = await dispatcher.dispatch(
      _request(WebViewBridgeActionNames.retryOrder, const <String, dynamic>{
        'chattinesses': 'ORDER004',
      }),
    );

    expect(result.code, -1);
    expect(dismissCount, 1);
    expect(shownError, contains('retry failed'));
  });

  test('rejects unsupported actions', () async {
    final result = await WebViewBridgeDispatcher().dispatch(
      _request('unknown-action', const <String, dynamic>{}),
    );

    expect(result.code, -2);
    expect(result.message, 'Unsupported action: unknown-action');
  });
}

WebViewBridgeRequest _request(String action, Map<String, dynamic> data) {
  return WebViewBridgeRequest(
    action: action,
    callbackId: '',
    data: data,
    rawData: data,
  );
}
