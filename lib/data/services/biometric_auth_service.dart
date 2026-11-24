import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import 'package:local_auth/error_codes.dart' as auth_error;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';

/// বায়োমেট্রিক যাচাই ফলাফল মডেল
class BiometricVerifyResult {
  final bool success;
  final String? errorMessage;
  final bool isNotEnrolled;

  const BiometricVerifyResult({
    required this.success,
    this.errorMessage,
    this.isNotEnrolled = false,
  });
}

/// সংরক্ষিত সিকিউর বায়োমেট্রিক ক্রেডেনশিয়াল মডেল
class BiometricCredentials {
  final String uid;
  final String identifier; // email or phone
  final String password;
  final String provider;
  final UserModel? userModel;

  const BiometricCredentials({
    required this.uid,
    required this.identifier,
    required this.password,
    required this.provider,
    this.userModel,
  });
}

/// নেটিভ বায়োমেট্রিক ও সিকিউর স্টোরেজ অথেনটিকেশন সার্ভিস (local_auth + FlutterSecureStorage)
class BiometricAuthService {
  BiometricAuthService._();

  static final LocalAuthentication _localAuth = LocalAuthentication();
  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  // Secure Storage Keys (Never cleared on normal logout!)
  static const String _secEnabledKey = 'kk_biometric_enabled';
  static const String _secUidKey = 'kk_biometric_uid';
  static const String _secIdentifierKey = 'kk_biometric_identifier';
  static const String _secPasswordKey = 'kk_biometric_password';
  static const String _secProviderKey = 'kk_biometric_provider';
  static const String _secUserDataKey = 'kk_biometric_user_data';

  // Pending login credentials cached during normal sign-in so Settings toggle binds seamlessly
  static const String _secPendingIdentifierKey = 'kk_pending_login_identifier';
  static const String _secPendingPasswordKey = 'kk_pending_login_password';
  static const String _secPendingProviderKey = 'kk_pending_login_provider';

  // Legacy SharedPreferences fallback key for quick UI state check
  static const String _prefBiometricEnabledKey = 'krishi_kotha_biometric_enabled';

  /// চেক করে বায়োমেট্রিক লগইন পূর্বে সক্রিয় করা আছে কি না
  static Future<bool> isBiometricEnabled() async {
    try {
      if (!kIsWeb) {
        final secVal = await _secureStorage.read(key: _secEnabledKey);
        if (secVal != null) {
          return secVal == 'true';
        }
      }
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_prefBiometricEnabledKey) ?? false;
    } catch (e) {
      debugPrint('isBiometricEnabled notice: $e');
      return false;
    }
  }

  /// ডিভাইস বায়োমেট্রিক বা ডিভাইস লক সাপোর্ট চেক (isDeviceSupported || canCheckBiometrics)
  static Future<bool> isDeviceBiometricAvailable() async {
    if (kIsWeb) return false;
    try {
      final bool isSupported = await _localAuth.isDeviceSupported();
      final bool canCheck = await _localAuth.canCheckBiometrics;
      return isSupported || canCheck;
    } catch (e) {
      debugPrint('isDeviceBiometricAvailable error: $e');
      return false;
    }
  }

  static Future<bool> canCheckBiometrics() async {
    return isDeviceBiometricAvailable();
  }

  static Future<bool> isDeviceSupported() async {
    return isDeviceBiometricAvailable();
  }

  /// সাধারণ লগইনের সময় ক্রেডেনশিয়াল নিরাপদে ক্যাশ করে রাখে
  static Future<void> cacheLoginCredentials({
    required String identifier,
    required String password,
    String provider = 'email',
  }) async {
    if (kIsWeb) return;
    try {
      await _secureStorage.write(key: _secPendingIdentifierKey, value: identifier.trim());
      await _secureStorage.write(key: _secPendingPasswordKey, value: password);
      await _secureStorage.write(key: _secPendingProviderKey, value: provider);
    } catch (e) {
      debugPrint('cacheLoginCredentials notice: $e');
    }
  }

  /// পেন্ডিং বা সেভ করা পাসওয়ার্ড আছে কি না চেক করে
  static Future<Map<String, String>?> getCachedLoginCredentials() async {
    if (kIsWeb) return null;
    try {
      final id = await _secureStorage.read(key: _secPendingIdentifierKey);
      final pw = await _secureStorage.read(key: _secPendingPasswordKey);
      final prov = await _secureStorage.read(key: _secPendingProviderKey);
      if (id != null && id.isNotEmpty && pw != null && pw.isNotEmpty) {
        return {
          'identifier': id,
          'password': pw,
          'provider': prov ?? 'email',
        };
      }
    } catch (_) {}
    return null;
  }

  /// সম্পূর্ণ ডিভাইস বায়োমেট্রিক (Fingerprint / Face ID / Device PIN-Pattern) প্রমট চালায়
  static Future<BiometricVerifyResult> authenticateDevice({
    required String reason,
  }) async {
    if (kIsWeb) {
      return const BiometricVerifyResult(
        success: false,
        errorMessage: 'ওয়েব ব্রাউজারে নেটিভ বায়োমেট্রিক উপলব্ধ নয়।',
      );
    }
    try {
      final bool available = await isDeviceBiometricAvailable();
      if (!available) {
        return const BiometricVerifyResult(
          success: false,
          isNotEnrolled: true,
          errorMessage: 'আপনার ডিভাইসে বায়োমেট্রিক বা স্ক্রিন লক সেট করা নেই। অনুগ্রহ করে ফোনের সেটিংস থেকে ফিঙ্গারপ্রিন্ট বা স্ক্রিন লক চালু করুন।',
        );
      }

      final bool didAuthenticate = await _localAuth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          biometricOnly: false, // Fingerprint, Face ID এবং Device PIN/Pattern সব সাপোর্ট করবে
          stickyAuth: true,
          useErrorDialogs: true,
        ),
      );

      if (didAuthenticate) {
        return const BiometricVerifyResult(success: true);
      } else {
        return const BiometricVerifyResult(
          success: false,
          errorMessage: 'বায়োমেট্রিক যাচাইকরণ বাতিল বা ব্যর্থ হয়েছে।',
        );
      }
    } on PlatformException catch (e) {
      debugPrint('Biometric PlatformException: ${e.code} - ${e.message}');
      if (e.code == auth_error.notEnrolled || e.code == auth_error.passcodeNotSet) {
        return const BiometricVerifyResult(
          success: false,
          isNotEnrolled: true,
          errorMessage: 'ফোনে কোনো ফিঙ্গারপ্রিন্ট বা স্ক্রিন লক সেট করা নেই। অনুগ্রহ করে ডিভাইস সেটিংস থেকে লক সেট করুন।',
        );
      } else if (e.code == auth_error.notAvailable) {
        return const BiometricVerifyResult(
          success: false,
          errorMessage: 'এই ডিভাইসে বায়োমেট্রিক হার্ডওয়্যার উপলব্ধ নয়।',
        );
      } else if (e.code == auth_error.lockedOut || e.code == auth_error.permanentlyLockedOut) {
        return const BiometricVerifyResult(
          success: false,
          errorMessage: 'অতিরিক্ত ভুল চেষ্টার কারণে বায়োমেট্রিক সাময়িকভাবে লক হয়েছে। ফোনের পাসওয়ার্ড দিয়ে আনলক করুন।',
        );
      }
      return BiometricVerifyResult(
        success: false,
        errorMessage: 'বায়োমেট্রিক যাচাইয়ে সমস্যা হয়েছে (${e.code})।',
      );
    } catch (e) {
      debugPrint('Biometric authenticate error: $e');
      return const BiometricVerifyResult(
        success: false,
        errorMessage: 'বায়োমেট্রিক যাচাই করা সম্ভব হয়নি। আবার চেষ্টা করুন।',
      );
    }
  }

  /// সংরক্ষিত বায়োমেট্রিক ক্রেডেনশিয়াল লোড করে
  static Future<BiometricCredentials?> getSavedBiometricCredentials() async {
    try {
      final enabled = await isBiometricEnabled();
      if (!enabled) return null;

      if (!kIsWeb) {
        final uid = await _secureStorage.read(key: _secUidKey);
        final identifier = await _secureStorage.read(key: _secIdentifierKey);
        final password = await _secureStorage.read(key: _secPasswordKey);
        final provider = await _secureStorage.read(key: _secProviderKey) ?? 'email';
        final userJson = await _secureStorage.read(key: _secUserDataKey);

        UserModel? model;
        if (userJson != null && uid != null) {
          try {
            model = UserModel.fromMap(jsonDecode(userJson) as Map<String, dynamic>, uid);
          } catch (_) {}
        }

        if (uid != null && uid.isNotEmpty) {
          return BiometricCredentials(
            uid: uid,
            identifier: identifier ?? '',
            password: password ?? '',
            provider: provider,
            userModel: model,
          );
        }
      }
    } catch (e) {
      debugPrint('Error getting saved biometric credentials: $e');
    }
    return null;
  }

  /// Legacy compatibility helper
  static Future<UserModel?> getSavedBiometricUser() async {
    final creds = await getSavedBiometricCredentials();
    return creds?.userModel;
  }

  /// সেটিংস পেজ থেকে বায়োমেট্রিক অথেনটিকেশন সক্রিয় করে FlutterSecureStorage-এ সংরক্ষণ
  static Future<void> enableBiometrics({
    required String phone,
    required String uid,
    required Map<String, dynamic> userData,
    String? identifier,
    String? password,
    String provider = 'email',
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefBiometricEnabledKey, true);

    if (!kIsWeb) {
      final pending = await getCachedLoginCredentials();
      final finalIdentifier = (identifier != null && identifier.isNotEmpty)
          ? identifier.trim()
          : (pending?['identifier'] ?? (userData['email']?.toString().isNotEmpty == true ? userData['email'].toString() : phone.trim()));
      final finalPassword = (password != null && password.isNotEmpty)
          ? password
          : (pending?['password'] ?? '');
      final finalProvider = (pending?['provider'] ?? provider);

      await _secureStorage.write(key: _secEnabledKey, value: 'true');
      await _secureStorage.write(key: _secUidKey, value: uid.trim());
      await _secureStorage.write(key: _secIdentifierKey, value: finalIdentifier);
      if (finalPassword.isNotEmpty) {
        await _secureStorage.write(key: _secPasswordKey, value: finalPassword);
      }
      await _secureStorage.write(key: _secProviderKey, value: finalProvider);
      await _secureStorage.write(key: _secUserDataKey, value: jsonEncode(userData));
    }
  }

  /// বায়োমেট্রিক অথেনটিকেশন নিষ্ক্রিয় ও সিকিউর ক্রেডেনশিয়াল মুছে ফেলে
  static Future<void> disableBiometrics() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefBiometricEnabledKey, false);

    if (!kIsWeb) {
      await _secureStorage.write(key: _secEnabledKey, value: 'false');
      await _secureStorage.delete(key: _secUidKey);
      await _secureStorage.delete(key: _secIdentifierKey);
      await _secureStorage.delete(key: _secPasswordKey);
      await _secureStorage.delete(key: _secProviderKey);
      await _secureStorage.delete(key: _secUserDataKey);
    }
  }

  /// নেটিভ বায়োমেট্রিক ডায়ালগ চালানোর ইউনিফাইড মেথড (আসল local_auth ব্যবহার করে)
  static Future<bool> showBiometricScanDialog(
    BuildContext context, {
    required String title,
    required String subtitle,
  }) async {
    final result = await authenticateDevice(reason: subtitle.isNotEmpty ? subtitle : title);
    return result.success;
  }
}
