import 'webview_bridge_constants.dart';
import 'webview_bridge_models.dart';

typedef WebViewRiskReporter =
    Future<void> Function({
      required String productId,
      required String orderNo,
      required int startTimeSeconds,
    });
typedef WebViewUrlHandler = Future<void> Function(String url);
typedef WebViewExternalUrlHandler = Future<bool> Function(Uri uri);
typedef WebViewSignedParamsBuilder =
    Future<Map<String, dynamic>> Function(String path);
typedef WebViewRetryOrder = Future<String> Function(String orderNo);
typedef WebViewChangeAccount =
    Future<String?> Function({
      required String productId,
      required String orderNo,
    });
typedef WebViewErrorPresenter = Future<void> Function(String message);
typedef WebViewAsyncAction = Future<void> Function();

class WebViewBridgeDispatcher {
  const WebViewBridgeDispatcher({
    this.reportRisk,
    this.openExternalUri,
    this.navigateInternalUri,
    this.openInNewWebView,
    this.reloadOrOpenInWebView,
    this.closePage,
    this.backToHome,
    this.requestAppReview,
    this.buildSignedParams,
    this.retryOrder,
    this.changeAccount,
    this.showLoading,
    this.dismissLoading,
    this.showError,
  });

  final WebViewRiskReporter? reportRisk;
  final WebViewExternalUrlHandler? openExternalUri;
  final WebViewUrlHandler? navigateInternalUri;
  final WebViewUrlHandler? openInNewWebView;
  final WebViewUrlHandler? reloadOrOpenInWebView;
  final Future<void> Function()? closePage;
  final Future<void> Function()? backToHome;
  final Future<void> Function()? requestAppReview;
  final WebViewSignedParamsBuilder? buildSignedParams;
  final WebViewRetryOrder? retryOrder;
  final WebViewChangeAccount? changeAccount;
  final WebViewAsyncAction? showLoading;
  final WebViewAsyncAction? dismissLoading;
  final WebViewErrorPresenter? showError;

  Future<WebViewBridgeResult> dispatch(WebViewBridgeRequest request) async {
    try {
      switch (request.action) {
        case WebViewBridgeActionNames.uploadRiskLoan:
          return await _reportRisk(request);
        case WebViewBridgeActionNames.openExternalBrowser:
          return await _openExternalBrowser(request);
        case WebViewBridgeActionNames.openScheme:
          return await _openScheme(request);
        case WebViewBridgeActionNames.closePage:
          await closePage?.call();
          return WebViewBridgeResult.success();
        case WebViewBridgeActionNames.backToHome:
          await backToHome?.call();
          return WebViewBridgeResult.success();
        case WebViewBridgeActionNames.toGrade:
          await requestAppReview?.call();
          return WebViewBridgeResult.success();
        case WebViewBridgeActionNames.requestCommonParams:
          return await _requestCommonParams(request);
        case WebViewBridgeActionNames.retryOrder:
          return await _retryOrder(request);
        case WebViewBridgeActionNames.changeAccount:
          return await _changeAccount(request);
        default:
          return WebViewBridgeResult.failure(
            'Unsupported action: ${request.action}',
            code: -2,
          );
      }
    } catch (error) {
      final message = error.toString().trim();
      final resolvedMessage = message.isEmpty
          ? 'Unable to complete action'
          : message;
      await showError?.call(resolvedMessage);
      return WebViewBridgeResult.failure(resolvedMessage);
    }
  }

  Future<WebViewBridgeResult> _reportRisk(WebViewBridgeRequest request) async {
    final productId = _readValue(request, const <String>[
      'seamounts',
      'productId',
    ]);
    if (productId.isEmpty) {
      return WebViewBridgeResult.failure('Missing productId');
    }
    await reportRisk?.call(
      productId: productId,
      orderNo: _readValue(request, const <String>['chattinesses', 'orderNo']),
      startTimeSeconds: DateTime.now().millisecondsSinceEpoch ~/ 1000,
    );
    return WebViewBridgeResult.success();
  }

  Future<WebViewBridgeResult> _openExternalBrowser(
    WebViewBridgeRequest request,
  ) async {
    final uri = _readUri(request);
    if (uri == null) {
      return WebViewBridgeResult.failure('Invalid url');
    }
    final opened = await openExternalUri?.call(uri) ?? false;
    return opened
        ? WebViewBridgeResult.success()
        : WebViewBridgeResult.failure('Unable to open external browser');
  }

  Future<WebViewBridgeResult> _openScheme(WebViewBridgeRequest request) async {
    final rawUrl = _readUrl(request);
    final uri = Uri.tryParse(rawUrl);
    if (uri == null || rawUrl.isEmpty) {
      return WebViewBridgeResult.failure('Invalid scheme');
    }
    if (uri.scheme == 'http' || uri.scheme == 'https') {
      await openInNewWebView?.call(rawUrl);
      return WebViewBridgeResult.success();
    }
    if (uri.scheme == 'ph') {
      await navigateInternalUri?.call(rawUrl);
      return WebViewBridgeResult.success();
    }
    final opened = await openExternalUri?.call(uri) ?? false;
    return opened
        ? WebViewBridgeResult.success()
        : WebViewBridgeResult.failure('Unable to open scheme');
  }

  Future<WebViewBridgeResult> _requestCommonParams(
    WebViewBridgeRequest request,
  ) async {
    final path = request.rawDataString;
    if (path.isEmpty) {
      return WebViewBridgeResult.failure('Missing path');
    }
    final params = await buildSignedParams?.call(path);
    if (params == null) {
      return WebViewBridgeResult.failure('Common params are unavailable');
    }
    return WebViewBridgeResult.success(params);
  }

  Future<WebViewBridgeResult> _retryOrder(WebViewBridgeRequest request) async {
    final orderNo = _readValue(request, const <String>[
      'chattinesses',
      'orderNo',
    ]);
    if (orderNo.isEmpty) {
      return WebViewBridgeResult.failure('Missing orderNo');
    }
    await showLoading?.call();
    try {
      final url = await retryOrder?.call(orderNo) ?? '';
      if (url.trim().isEmpty) {
        return WebViewBridgeResult.failure('Missing retry result url');
      }
      await reloadOrOpenInWebView?.call(url.trim());
      return WebViewBridgeResult.success();
    } finally {
      await dismissLoading?.call();
    }
  }

  Future<WebViewBridgeResult> _changeAccount(
    WebViewBridgeRequest request,
  ) async {
    final productId = request.data['seamounts']?.toString().trim() ?? '';
    final orderNo = request.data['chattinesses']?.toString().trim() ?? '';
    if (productId.isEmpty || orderNo.isEmpty) {
      return WebViewBridgeResult.failure('Missing account information');
    }
    final redirectUrl = await changeAccount?.call(
      productId: productId,
      orderNo: orderNo,
    );
    if (redirectUrl == null) {
      return WebViewBridgeResult.failure('Account change was canceled');
    }
    if (redirectUrl.trim().isEmpty) {
      return WebViewBridgeResult.failure('Missing account change result url');
    }
    await reloadOrOpenInWebView?.call(redirectUrl.trim());
    return WebViewBridgeResult.success();
  }

  String _readValue(WebViewBridgeRequest request, List<String> keys) {
    for (final key in keys) {
      final value = request.data[key]?.toString().trim() ?? '';
      if (value.isNotEmpty) {
        return value;
      }
    }
    return '';
  }

  String _readUrl(WebViewBridgeRequest request) {
    final mapped = _readValue(request, const <String>['url', 'scheme']);
    return mapped.isNotEmpty ? mapped : request.rawDataString;
  }

  Uri? _readUri(WebViewBridgeRequest request) {
    final rawUrl = _readUrl(request);
    return rawUrl.isEmpty ? null : Uri.tryParse(rawUrl);
  }
}
