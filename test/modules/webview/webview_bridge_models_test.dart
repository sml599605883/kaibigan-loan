import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:kaibigan_loan/src/modules/webview/webview_bridge_models.dart';

void main() {
  group('WebViewBridgeRequest', () {
    test('parses action callback and JSON string payload', () {
      final request = WebViewBridgeRequest.fromRawMessage(
        '{"action":"action-1","callbackId":"cb-1",'
        '"payload":"{\\"orderNo\\":\\"ORDER-1\\"}"}',
      );

      expect(request.action, 'action-1');
      expect(request.callbackId, 'cb-1');
      expect(request.data, <String, dynamic>{'orderNo': 'ORDER-1'});
      expect(request.expectsCallback, isTrue);
    });

    test('uses empty values for malformed messages', () {
      final request = WebViewBridgeRequest.fromRawMessage('not-json');

      expect(request.action, isEmpty);
      expect(request.callbackId, isEmpty);
      expect(request.data, isEmpty);
      expect(request.expectsCallback, isFalse);
    });
  });

  group('WebViewBridgeResult', () {
    test('encodes stable callback structure', () {
      final result = WebViewBridgeResult.success(<String, dynamic>{
        'value': 'ok',
      });

      expect(jsonDecode(result.encode()), <String, dynamic>{
        'code': 0,
        'message': 'success',
        'data': <String, dynamic>{'value': 'ok'},
      });
    });
  });
}
