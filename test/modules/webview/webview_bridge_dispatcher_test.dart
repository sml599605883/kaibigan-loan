import 'package:flutter_test/flutter_test.dart';
import 'package:kaibigan_loan/src/modules/webview/webview_bridge_constants.dart';
import 'package:kaibigan_loan/src/modules/webview/webview_bridge_dispatcher.dart';
import 'package:kaibigan_loan/src/modules/webview/webview_bridge_models.dart';

void main() {
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
    'reserved account change returns an explicit unavailable result',
    () async {
      final dispatcher = WebViewBridgeDispatcher();

      final result = await dispatcher.dispatch(
        _request(
          WebViewBridgeActionNames.changeAccount,
          const <String, dynamic>{},
        ),
      );

      expect(result.code, -3);
      expect(result.message, 'Account change is not available');
    },
  );

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
