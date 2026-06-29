import 'package:encrypt/encrypt.dart';

class ApiCrypto {
  ApiCrypto({required String key, required String iv})
    : _key = Key.fromUtf8(key.padRight(32).substring(0, 32)),
      _iv = IV.fromUtf8(iv.padRight(16).substring(0, 16));

  final Key _key;
  final IV _iv;

  String encryptText(String plainText) {
    if (plainText.isEmpty) {
      return '';
    }
    return Encrypter(
      AES(_key, mode: AESMode.cbc),
    ).encrypt(plainText, iv: _iv).base64;
  }

  String decryptText(String cipherText) {
    if (cipherText.isEmpty) {
      return '';
    }
    return Encrypter(
      AES(_key, mode: AESMode.cbc),
    ).decrypt64(cipherText, iv: _iv);
  }
}
