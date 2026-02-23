import 'dart:convert';
import 'dart:math';
import 'package:cryptography/cryptography.dart';

class PasswordService {
  static final Pbkdf2 _pbkdf2 = Pbkdf2(
    macAlgorithm: Hmac.sha256(),
    iterations: 100000,
    bits: 256,
  );

  static Future<Map<String, String>> hashPassword(String password) async {
    final salt = _randomBytes(16);

    final key = await _pbkdf2.deriveKey(
      secretKey: SecretKey(utf8.encode(password)),
      nonce: salt,
    );

    final hash = await key.extractBytes();

    return {
      'password_salt': base64Encode(salt),
      'password_hash': base64Encode(hash),
    };
  }

  static Future<bool> verifyPassword(
      String password,
      String salt,
      String storedHash,
      ) async {
    final key = await _pbkdf2.deriveKey(
      secretKey: SecretKey(utf8.encode(password)),
      nonce: base64Decode(salt),
    );

    final hash = base64Encode(await key.extractBytes());
    return hash == storedHash;
  }

  // =========================
  // CHAT ENCRYPTION
  // =========================
  static final AesGcm _cipher = AesGcm.with256bits();

  static Future<SecretKey> sessionKeyFromUsers(
      String userA,
      String userB,
      ) async {
    final combined =
    userA.compareTo(userB) < 0 ? userA + userB : userB + userA;

    final digest = await Sha256().hash(utf8.encode(combined));
    return SecretKey(digest.bytes);
  }

  static Future<String> encryptMessage(
      String message,
      SecretKey key,
      ) async {
    final nonce = _randomBytes(12);

    final box = await _cipher.encrypt(
      utf8.encode(message),
      secretKey: key,
      nonce: nonce,
    );

    return base64Encode([...nonce, ...box.cipherText, ...box.mac.bytes]);
  }

  static Future<String> decryptMessage(
      String encrypted,
      SecretKey key,
      ) async {
    try {
      final data = base64Decode(encrypted);

      final nonce = data.sublist(0, 12);
      final cipherText = data.sublist(12, data.length - 16);
      final macBytes = data.sublist(data.length - 16);

      final box = SecretBox(
        cipherText,
        nonce: nonce,
        mac: Mac(macBytes),
      );

      final clear = await _cipher.decrypt(box, secretKey: key);
      return utf8.decode(clear);
    } catch (_) {
      return '';
    }
  }

  static List<int> _randomBytes(int len) {
    final r = Random.secure();
    return List<int>.generate(len, (_) => r.nextInt(256));
  }
}