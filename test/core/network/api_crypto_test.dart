import 'package:flutter_test/flutter_test.dart';
import 'package:kaibigan_loan/src/core/network/api_crypto.dart';

void main() {
  test('matches Sapat Cash AES-CBC encryption semantics', () {
    final crypto = ApiCrypto(
      key: '01b908d5324a7aec',
      iv: '8b3ff39d90da32c6',
    );

    expect(crypto.encryptText('payload'), 'jy0OHVp9UNxkNzaPhi7bcQ==');

    expect(() => crypto.encryptText(''), throwsA(isA<RangeError>()));
  });
}
