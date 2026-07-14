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
}
