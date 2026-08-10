import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SecurityCryptoService {
  SecurityCryptoService._();

  static final SecurityCryptoService instance = SecurityCryptoService._();

  static const _keyName = 'hepatovita_data_key_v1';
  static const _textPrefix = 'enc:v1:';
  static const _blobPrefix = 'HVBK1:';

  final AesGcm _aesGcm = AesGcm.with256bits();

  Future<String> encryptText(String plainText) async {
    final key = await _loadOrCreateKey();
    final nonce = _randomBytes(12);
    final secretBox = await _aesGcm.encrypt(
      utf8.encode(plainText),
      secretKey: key,
      nonce: nonce,
    );

    return '$_textPrefix${base64Encode(secretBox.nonce)}:${base64Encode(secretBox.cipherText)}:${base64Encode(secretBox.mac.bytes)}';
  }

  Future<String> decryptText(String encryptedText) async {
    if (!encryptedText.startsWith(_textPrefix)) {
      return encryptedText;
    }

    final payload = encryptedText.substring(_textPrefix.length);
    final parts = payload.split(':');
    if (parts.length != 3) {
      throw const FormatException('Invalid encrypted text payload.');
    }

    final nonce = base64Decode(parts[0]);
    final cipherText = base64Decode(parts[1]);
    final macBytes = base64Decode(parts[2]);

    final key = await _loadOrCreateKey();
    final clearBytes = await _aesGcm.decrypt(
      SecretBox(
        cipherText,
        nonce: nonce,
        mac: Mac(macBytes),
      ),
      secretKey: key,
    );
    return utf8.decode(clearBytes);
  }

  Future<Uint8List> encryptBytes(Uint8List bytes) async {
    final key = await _loadOrCreateKey();
    final nonce = _randomBytes(12);
    final secretBox = await _aesGcm.encrypt(
      bytes,
      secretKey: key,
      nonce: nonce,
    );

    final envelope = '$_blobPrefix${base64Encode(secretBox.nonce)}:${base64Encode(secretBox.cipherText)}:${base64Encode(secretBox.mac.bytes)}';
    return Uint8List.fromList(utf8.encode(envelope));
  }

  Future<Uint8List> decryptBytes(Uint8List encryptedBytes) async {
    final text = utf8.decode(encryptedBytes, allowMalformed: false);
    if (!text.startsWith(_blobPrefix)) {
      throw const FormatException('Backup file is not encrypted with HepatoVita format.');
    }

    final payload = text.substring(_blobPrefix.length);
    final parts = payload.split(':');
    if (parts.length != 3) {
      throw const FormatException('Invalid encrypted backup payload.');
    }

    final nonce = base64Decode(parts[0]);
    final cipherText = base64Decode(parts[1]);
    final macBytes = base64Decode(parts[2]);

    final key = await _loadOrCreateKey();
    final clearBytes = await _aesGcm.decrypt(
      SecretBox(
        cipherText,
        nonce: nonce,
        mac: Mac(macBytes),
      ),
      secretKey: key,
    );

    return Uint8List.fromList(clearBytes);
  }

  Future<SecretKey> _loadOrCreateKey() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_keyName);
    if (stored != null) {
      return SecretKey(base64Decode(stored));
    }

    final keyBytes = _randomBytes(32);
    await prefs.setString(_keyName, base64Encode(keyBytes));
    return SecretKey(keyBytes);
  }

  Uint8List _randomBytes(int length) {
    final rng = Random.secure();
    final values = List<int>.generate(length, (_) => rng.nextInt(256));
    return Uint8List.fromList(values);
  }
}
