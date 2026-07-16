import 'package:flutter_test/flutter_test.dart';
import 'package:kaibigan_loan/src/modules/webview/webview_page.dart';

void main() {
  test('does not use a stale WebView controller after page disposal', () {
    final controller = Object();

    expect(
      canUseActiveWebViewController(
        mounted: false,
        activeController: controller,
        controller: controller,
      ),
      isFalse,
    );
    expect(
      canUseActiveWebViewController(
        mounted: true,
        activeController: Object(),
        controller: controller,
      ),
      isFalse,
    );
    expect(
      canUseActiveWebViewController(
        mounted: true,
        activeController: controller,
        controller: controller,
      ),
      isTrue,
    );
  });

  test('allows only supported schemes inside the WebView', () {
    expect(isInlineWebViewScheme('https'), isTrue);
    expect(isInlineWebViewScheme('http'), isTrue);
    expect(isInlineWebViewScheme('about'), isTrue);
    expect(isInlineWebViewScheme('tel'), isFalse);
  });

  test('closes Flutter route only without WebView history', () {
    expect(shouldCloseWebView(canGoBack: true), isFalse);
    expect(shouldCloseWebView(canGoBack: false), isTrue);
  });

  test('extracts retention product id only from Jalaps seamounts URL', () {
    expect(
      jalapsRetentionProductId(
        'https://h5.example.test/Jalaps/confirm?seamounts=product-5',
      ),
      'product-5',
    );
    expect(
      jalapsRetentionProductId(
        'https://h5.example.test/other?seamounts=product-5',
      ),
      isEmpty,
    );
    expect(
      jalapsRetentionProductId('https://h5.example.test/Jalaps/confirm'),
      isEmpty,
    );
  });

  test('Jalaps back retention requests type 5 and forwards exit', () async {
    final calls = <Map<String, String>>[];
    var exitCount = 0;

    final shown = await showJalapsBackRetention(
      rawUrl: 'https://h5.example.test/jalaps/confirm?seamounts=product-6',
      onExit: () => exitCount++,
      presenter: ({required type, required productId, required onExit}) async {
        calls.add({'type': type, 'productId': productId});
        onExit();
        return true;
      },
    );

    expect(shown, isTrue);
    expect(calls, [
      {'type': '5', 'productId': 'product-6'},
    ]);
    expect(exitCount, 1);
  });
}
