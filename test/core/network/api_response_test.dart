import 'package:flutter_test/flutter_test.dart';
import 'package:kaibigan_loan/src/core/network/api_exception.dart';
import 'package:kaibigan_loan/src/core/network/api_response.dart';

void main() {
  group('ApiResponse', () {
    test('parses obfuscated response shell and accepts both success codes', () {
      final first = ApiResponse.fromRaw({
        'griding': 0,
        'organizational': 'success',
        'fas': {'value': 1},
      });
      final stringZero = ApiResponse.fromRaw({
        'griding': '00',
        'organizational': '',
        'fas': {'value': 2},
      });
      final third = ApiResponse.fromRaw({
        'griding': '20000',
        'organizational': '',
        'fas': {'value': 3},
      });

      expect(first.isSuccess, isTrue);
      expect(first.code, 0);
      expect(first.states['value'].intValue, 1);
      expect(stringZero.isSuccess, isTrue);
      expect(stringZero.code, 0);
      expect(stringZero.states['value'].intValue, 2);
      expect(third.isSuccess, isTrue);
      expect(third.code, 20000);
      expect(third.states['value'].intValue, 3);
    });

    test('degrades non object responses into controlled business errors', () {
      final response = ApiResponse.fromRaw(['bad']);

      expect(response.code, ApiResponse.invalidFormatCode);
      expect(response.isSuccess, isFalse);
      expect(response.message, 'Invalid response format');
    });

    test('throws business exception for non success response', () {
      final response = ApiResponse.fromRaw({
        'griding': 400,
        'organizational': 'bad request',
        'fas': {},
      });

      expect(
        () => response.ensureSuccess(),
        throwsA(
          isA<ApiBusinessException>().having(
            (error) => error.message,
            'message',
            'bad request',
          ),
        ),
      );
    });
  });
}
