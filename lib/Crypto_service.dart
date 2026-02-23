import 'dart:convert';
import 'dart:math';
import 'package:cryptography/cryptography.dart';

class CryptoService {
  static final _pbkdf2 = Pbkdf2(
    macAlgorithm: Hmac.sha256(),
    iterations: 150000,
    bits: 256,
  );

  static final _aes = AesGcm.with256bits();

  /// Derive encryption key from password
  static Future<SecretKey> deriveKey(String password, List<int> salt) async {
    return await _pbkdf2.deriveKey(
      secretKey: SecretKey(utf8.encode(password)),
      nonce: salt,
    );
  }

  /// Encrypt message
  static Future<String> encrypt(String message, SecretKey key) async {
    final nonce = _generateNonce(12);

    final secretBox = await _aes.encrypt(
      utf8.encode(message),
      secretKey: key,
      nonce: nonce,
    );

    final combined = nonce +
        secretBox.cipherText +
        secretBox.mac.bytes;

    return base64Encode(combined);
  }

  /// Decrypt message
  static Future<String> decrypt(String encrypted, SecretKey key) async {
    final bytes = base64Decode(encrypted);

    final nonce = bytes.sublist(0, 12);
    final mac = Mac(bytes.sublist(bytes.length - 16));
    final cipherText = bytes.sublist(12, bytes.length - 16);

    final secretBox = SecretBox(
      cipherText,
      nonce: nonce,
      mac: mac,
    );

    final clearText = await _aes.decrypt(
      secretBox,
      secretKey: key,
    );

    return utf8.decode(clearText);
  }

  static List<int> _generateNonce(int length) {
    final rnd = Random.secure();
    return List<int>.generate(length, (_) => rnd.nextInt(256));
  }
}
