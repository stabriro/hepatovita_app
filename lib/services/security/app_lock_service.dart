import 'dart:convert';
import 'dart:math';

import 'package:cryptography/cryptography.dart';
import 'package:flutter/foundation.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppLockService {
  AppLockService._();

  static final AppLockService instance = AppLockService._();

  static const _pinHashKey = 'hepatovita_pin_hash_v1';
  static const _biometricEnabledKey = 'hepatovita_biometric_enabled_v1';
  static const _recoveryCodeHashKey = 'hepatovita_recovery_code_hash_v1';

  final LocalAuthentication _localAuth = LocalAuthentication();

  Future<bool> hasPin() async {
    final prefs = await SharedPreferences.getInstance();
    final pinHash = prefs.getString(_pinHashKey);
    return pinHash != null && pinHash.isNotEmpty;
  }

  Future<void> setPin(String pin) async {
    final pinHash = await _hashPin(pin);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_pinHashKey, pinHash);
  }

  Future<bool> verifyPin(String pin) async {
    final prefs = await SharedPreferences.getInstance();
    final storedHash = prefs.getString(_pinHashKey);
    if (storedHash == null || storedHash.isEmpty) {
      return false;
    }

    final incomingHash = await _hashPin(pin);
    return storedHash == incomingHash;
  }

  Future<void> setBiometricEnabled(bool enabled) {
    return SharedPreferences.getInstance().then(
      (prefs) => prefs.setBool(_biometricEnabledKey, enabled),
    );
  }

  Future<bool> isBiometricEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_biometricEnabledKey) ?? false;
  }

  Future<bool> canUseBiometrics() async {
    try {
      if (kIsWeb) {
        return false;
      }
      final canCheck = await _localAuth.canCheckBiometrics;
      final supported = await _localAuth.isDeviceSupported();
      return canCheck && supported;
    } catch (_) {
      return false;
    }
  }

  Future<bool> authenticateWithBiometrics() async {
    try {
      if (!await canUseBiometrics()) {
        return false;
      }

        return _localAuth.authenticate(
          localizedReason: 'Authenticate to open Itmain',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
          useErrorDialogs: true,
        ),
      );
    } catch (_) {
      return false;
    }
  }

  Future<String> rotateRecoveryCode() async {
    final code = _generateRecoveryCode();
    final codeHash = await _hashRecoveryCode(code);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_recoveryCodeHashKey, codeHash);
    return code;
  }

  Future<bool> hasRecoveryCode() async {
    final prefs = await SharedPreferences.getInstance();
    final storedHash = prefs.getString(_recoveryCodeHashKey);
    return storedHash != null && storedHash.isNotEmpty;
  }

  Future<bool> verifyRecoveryCode(String code) async {
    final prefs = await SharedPreferences.getInstance();
    final storedHash = prefs.getString(_recoveryCodeHashKey);
    if (storedHash == null || storedHash.isEmpty) {
      return false;
    }

    final incomingHash = await _hashRecoveryCode(code);
    return storedHash == incomingHash;
  }

  Future<String> _hashPin(String pin) async {
    final hash = await Sha256().hash(utf8.encode('hepatovita::$pin'));
    return base64Encode(hash.bytes);
  }

  Future<String> _hashRecoveryCode(String code) async {
    final normalized = code.trim().toUpperCase();
    final hash = await Sha256().hash(utf8.encode('hepatovita-recovery::$normalized'));
    return base64Encode(hash.bytes);
  }

  String _generateRecoveryCode() {
    final rng = Random.secure();
    final groups = List<String>.generate(3, (_) {
      final value = rng.nextInt(10000);
      return value.toString().padLeft(4, '0');
    });
    return groups.join('-');
  }
}
