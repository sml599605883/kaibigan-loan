import 'package:flutter_test/flutter_test.dart';
import 'package:kaibigan_loan/src/modules/webview/webview_page.dart';

void main() {
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
