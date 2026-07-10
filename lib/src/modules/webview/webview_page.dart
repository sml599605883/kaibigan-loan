import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:get/get.dart';

import '../../core/network/api_client.dart';
import '../../core/network/api_signature.dart';
import '../../core/report/report_manager.dart';
import '../../navigation_helper.dart';
import '../../theme/app_colors.dart';
import '../../utils/app_toast.dart';
import 'webview_bridge_constants.dart';
import 'webview_bridge_dispatcher.dart';
import 'webview_bridge_models.dart';

bool isInlineWebViewScheme(String scheme) => switch (scheme.toLowerCase()) {
  'http' || 'https' || 'about' || 'data' || 'javascript' || 'file' => true,
  _ => false,
};

bool shouldCloseWebView({required bool canGoBack}) => !canGoBack;

class WebViewPage extends StatefulWidget {
  const WebViewPage({super.key, required this.initialUrl, this.initialTitle});

  final String initialUrl;
  final String? initialTitle;

  @override
  State<WebViewPage> createState() => _WebViewPageState();
}

class _WebViewPageState extends State<WebViewPage> with WidgetsBindingObserver {
  InAppWebViewController? _controller;
  bool _loading = true;
  bool _loadFailed = false;
  bool _appForeground = true;
  bool _bridgeEnabled = false;
  late final WebViewBridgeDispatcher _dispatcher;
  late String _title;

  Uri? get _initialUri => Uri.tryParse(widget.initialUrl.trim());

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _title = widget.initialTitle?.trim().isNotEmpty == true
        ? widget.initialTitle!.trim()
        : 'Details';
    _dispatcher = WebViewBridgeDispatcher(
      reportRisk:
          ({required productId, required orderNo, required startTimeSeconds}) {
            return ReportManager.instance.reportRiskBehavior(
              productId: productId,
              orderNo: orderNo,
              sceneType: '10',
              startTimeSeconds: startTimeSeconds,
            );
          },
      openExternalUri: NavigationHelper.openExternalUri,
      navigateInternalUri: NavigationHelper.navigateRawTarget,
      openInNewWebView: (url) async {
        NavigationHelper.toWebView(url: url);
      },
      reloadOrOpenInWebView: _reloadOrOpenInWebView,
      closePage: () async => Get.back<void>(),
      backToHome: () async => NavigationHelper.offAllToMain<void>(),
      buildSignedParams: (path) {
        return ApiSignature(
          ApiClient.instance.config,
        ).buildSignedQuery(path: path);
      },
      retryOrder: (orderNo) async {
        final response = await ApiClient.instance.originalCardRetry(
          chattinesses: orderNo,
        );
        return response.states['bloomeries'].stringValue.trim();
      },
      showError: AppToast.error,
    );
  }

  @override
  void dispose() {
    _appForeground = false;
    _syncBridgeState();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _appForeground = state == AppLifecycleState.resumed;
    _syncBridgeState();
  }

  void _syncBridgeState() {
    final controller = _controller;
    if (controller == null || _appForeground == _bridgeEnabled) {
      return;
    }
    if (_appForeground) {
      controller.addJavaScriptHandler(
        handlerName: WebViewBridgeHandlerNames.channel,
        callback: _handleBridgeCall,
      );
      _bridgeEnabled = true;
      return;
    }
    controller.removeJavaScriptHandler(
      handlerName: WebViewBridgeHandlerNames.channel,
    );
    _bridgeEnabled = false;
  }

  Future<dynamic> _handleBridgeCall(List<dynamic> arguments) async {
    if (!_appForeground || !mounted) {
      return WebViewBridgeResult.failure('WebView is inactive').toJson();
    }
    final raw = arguments.isEmpty ? null : arguments.first;
    final request = raw is String
        ? WebViewBridgeRequest.fromRawMessage(raw)
        : WebViewBridgeRequest.fromRawObject(raw);
    final result = await _dispatcher.dispatch(request);
    if (request.expectsCallback) {
      final callback = <String, dynamic>{
        'callbackId': request.callbackId,
        'result': result.toJson(),
      };
      await _controller?.evaluateJavascript(
        source:
            'window.${WebViewBridgeHandlerNames.channel}.handleMessage(${WebViewBridgeResult.success(callback).encode()});',
      );
    }
    return result.toJson();
  }

  Future<void> _reloadOrOpenInWebView(String rawUrl) async {
    final uri = Uri.tryParse(rawUrl.trim());
    final controller = _controller;
    if (uri == null || controller == null) {
      return;
    }
    final currentUri = await controller.getUrl();
    if (currentUri?.toString().trim() == uri.toString()) {
      await controller.reload();
      return;
    }
    await controller.loadUrl(urlRequest: URLRequest(url: WebUri.uri(uri)));
  }

  Future<void> _handleBackPressed() async {
    final controller = _controller;
    if (!mounted) {
      return;
    }
    if (controller == null) {
      Get.back<void>();
      return;
    }
    final canGoBack = await controller.canGoBack();
    if (shouldCloseWebView(canGoBack: canGoBack)) {
      Get.back<void>();
      return;
    }
    await controller.goBack();
  }

  Future<NavigationActionPolicy> _handleNavigation(
    InAppWebViewController controller,
    NavigationAction action,
  ) async {
    final uri = action.request.url;
    if (uri == null) {
      return NavigationActionPolicy.CANCEL;
    }
    if (isInlineWebViewScheme(uri.scheme)) {
      return NavigationActionPolicy.ALLOW;
    }
    await NavigationHelper.openExternalUri(uri);
    return NavigationActionPolicy.CANCEL;
  }

  Future<void> _retry() async {
    final uri = _initialUri;
    final controller = _controller;
    if (uri == null || controller == null) {
      return;
    }
    setState(() {
      _loading = true;
      _loadFailed = false;
    });
    await controller.loadUrl(urlRequest: URLRequest(url: WebUri.uri(uri)));
  }

  @override
  Widget build(BuildContext context) {
    final uri = _initialUri;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          unawaited(_handleBackPressed());
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.webViewBackground,
        appBar: AppBar(
          backgroundColor: AppColors.webViewBackground,
          foregroundColor: AppColors.webViewTitleText,
          elevation: 0,
          title: Text(_title),
          leading: IconButton(
            onPressed: _handleBackPressed,
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
          ),
        ),
        body: uri == null
            ? const _WebViewLoadFailed(message: 'Invalid page address')
            : _loadFailed
            ? _WebViewLoadFailed(onRetry: _retry)
            : Stack(
                children: <Widget>[
                  InAppWebView(
                    initialUrlRequest: URLRequest(url: WebUri.uri(uri)),
                    initialSettings: InAppWebViewSettings(
                      javaScriptEnabled: true,
                      useShouldOverrideUrlLoading: true,
                      useHybridComposition: true,
                      isInspectable: kDebugMode,
                      mixedContentMode:
                          MixedContentMode.MIXED_CONTENT_NEVER_ALLOW,
                    ),
                    onWebViewCreated: (controller) {
                      _controller = controller;
                      _syncBridgeState();
                    },
                    shouldOverrideUrlLoading: _handleNavigation,
                    onPermissionRequest: (controller, request) async {
                      return PermissionResponse(
                        resources: request.resources,
                        action: PermissionResponseAction.DENY,
                      );
                    },
                    onLoadStart: (controller, url) {
                      if (mounted) {
                        setState(() {
                          _loading = true;
                          _loadFailed = false;
                        });
                      }
                    },
                    onLoadStop: (controller, url) {
                      if (mounted) {
                        setState(() => _loading = false);
                      }
                    },
                    onReceivedError: (controller, request, error) {
                      if (mounted) {
                        setState(() {
                          _loading = false;
                          _loadFailed = true;
                        });
                      }
                    },
                    onTitleChanged: (controller, title) {
                      final normalized = title?.trim() ?? '';
                      if (mounted && normalized.isNotEmpty) {
                        setState(() => _title = normalized);
                      }
                    },
                  ),
                  if (_loading)
                    const Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      child: LinearProgressIndicator(
                        minHeight: 2,
                        color: AppColors.webViewProgress,
                      ),
                    ),
                ],
              ),
      ),
    );
  }
}

class _WebViewLoadFailed extends StatelessWidget {
  const _WebViewLoadFailed({
    this.message = 'Page failed to load',
    this.onRetry,
  });

  final String message;
  final Future<void> Function()? onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Icon(
              Icons.wifi_off_rounded,
              color: AppColors.webViewErrorText,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: const TextStyle(color: AppColors.webViewTitleText),
            ),
            if (onRetry != null) ...<Widget>[
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => unawaited(onRetry!()),
                style: TextButton.styleFrom(
                  backgroundColor: AppColors.webViewRetryBackground,
                ),
                child: const Text('Retry'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
