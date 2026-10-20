import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import 'firebase_service.dart';

class AuthService {
  final FirebaseAuth? _auth = FirebaseService.isFirebaseInitialized ? FirebaseAuth.instance : null;
  final FirebaseFirestore? _firestore = FirebaseService.isFirebaseInitialized ? FirebaseFirestore.instance : null;

  static const String _prefUserKey = 'krishi_kotha_cached_user';
  UserModel? _currentUser;
  String? _verificationId;

  UserModel? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;
  bool get isGuest => _currentUser?.uid.startsWith('guest_') ?? false;

  /// Loads locally stored user profile on app start
  Future<UserModel?> loadCachedUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userJson = prefs.getString(_prefUserKey);
      if (userJson != null) {
        final map = jsonDecode(userJson) as Map<String, dynamic>;
        _currentUser = UserModel(
          uid: map['uid'] as String,
          name: map['name'] as String,
          phone: map['phone'] as String,
          district: map['district'] as String,
          upazila: map['upazila'] as String,
          preferredCrops: List<String>.from(map['preferred_crops'] ?? []),
          createdAt: DateTime.tryParse(map['createdAt'] as String? ?? '') ?? DateTime.now(),
        );
        return _currentUser;
      }
    } catch (e) {
      debugPrint('Error loading cached user: $e');
    }
    return null;
  }

  /// Sends OTP to the farmer's mobile number
  Future<void> sendOtp({
    required String phoneNumber,
    required Function(String verificationId) onCodeSent,
    required Function(String errorMessage) onError,
  }) async {
    if (!FirebaseService.isFirebaseInitialized || _auth == null) {
      // Offline / Demo fallback: Mock OTP verification ID
      _verificationId = 'mock_verification_${DateTime.now().millisecondsSinceEpoch}';
      onCodeSent(_verificationId!);
      return;
    }

    try {
      // Ensure BD country code prefix
      String formattedPhone = phoneNumber.trim();
      if (!formattedPhone.startsWith('+880')) {
        if (formattedPhone.startsWith('0')) {
          formattedPhone = '+88$formattedPhone';
        } else {
          formattedPhone = '+880$formattedPhone';
        }
      }

      await _auth.verifyPhoneNumber(
        phoneNumber: formattedPhone,
        timeout: const Duration(seconds: 60),
        verificationCompleted: (PhoneAuthCredential credential) async {
          await _signInWithCredential(credential, phoneNumber);
        },
        verificationFailed: (FirebaseAuthException e) {
          onError(e.message ?? 'ওটিপি পাঠাতে সমস্যা হয়েছে। পুনরায় চেষ্টা করুন।');
        },
        codeSent: (String verificationId, int? resendToken) {
          _verificationId = verificationId;
          onCodeSent(verificationId);
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          _verificationId = verificationId;
        },
      );
    } catch (e) {
      onError(e.toString());
    }
  }

  /// Verifies entered OTP code
  Future<UserModel> verifyOtp({
    required String smsCode,
    required String phoneNumber,
    String? verificationId,
  }) async {
    final effectiveVerificationId = verificationId ?? _verificationId ?? '';

    if (!FirebaseService.isFirebaseInitialized || _auth == null || effectiveVerificationId.startsWith('mock_')) {
      // Demo / Mock sign-in
      final user = UserModel(
        uid: 'user_${phoneNumber.replaceAll(RegExp(r'[^0-9]'), '')}',
        name: 'শ্রদ্ধেয় কৃষক ভাই',
        phone: phoneNumber,
        district: 'বগুড়া',
        upazila: 'শেরপুর',
        preferredCrops: ['বোরো ধান', 'আলু'],
        createdAt: DateTime.now(),
      );
      await _cacheUser(user);
      _currentUser = user;
      return user;
    }

    final credential = PhoneAuthProvider.credential(
      verificationId: effectiveVerificationId,
      smsCode: smsCode,
    );
    return await _signInWithCredential(credential, phoneNumber);
  }

  Future<UserModel> _signInWithCredential(PhoneAuthCredential credential, String phone) async {
    final userCredential = await _auth!.signInWithCredential(credential);
    final firebaseUser = userCredential.user!;

    // Check if user document already exists in Firestore
    final userDoc = await _firestore!.collection('users').doc(firebaseUser.uid).get();
    UserModel user;
    if (userDoc.exists) {
      user = UserModel.fromFirestore(userDoc);
    } else {
      user = UserModel(
        uid: firebaseUser.uid,
        name: 'কৃষক ভাই',
        phone: phone,
        district: 'ঢাকা',
        upazila: '',
        preferredCrops: [],
        createdAt: DateTime.now(),
      );
      await _firestore.collection('users').doc(firebaseUser.uid).set(user.toMap());
    }

    await _cacheUser(user);
    _currentUser = user;
    return user;
  }

  /// Guest / Browse mode
  Future<UserModel> loginAsGuest() async {
    final guestUser = UserModel(
      uid: 'guest_${DateTime.now().millisecondsSinceEpoch}',
      name: 'অতিথি কৃষক',
      phone: '০১XXXXXXXXX',
      district: 'বগুড়া',
      upazila: 'শেরপুর',
      preferredCrops: ['বোরো ধান', 'আলু'],
      createdAt: DateTime.now(),
    );
    await _cacheUser(guestUser);
    _currentUser = guestUser;
    return guestUser;
  }

  /// Saves updated profile information to Firestore and local cache
  Future<void> updateProfile({
    required String name,
    required String district,
    required String upazila,
    required List<String> preferredCrops,
  }) async {
    if (_currentUser == null) return;

    final updated = _currentUser!.copyWith(
      name: name,
      district: district,
      upazila: upazila,
      preferredCrops: preferredCrops,
    );

    if (FirebaseService.isFirebaseInitialized && _firestore != null && !isGuest) {
      await _firestore.collection('users').doc(updated.uid).set(updated.toMap(), SetOptions(merge: true));
    }

    await _cacheUser(updated);
    _currentUser = updated;
  }

  Future<void> _cacheUser(UserModel user) async {
    final prefs = await SharedPreferences.getInstance();
    final map = {
      'uid': user.uid,
      'name': user.name,
      'phone': user.phone,
      'district': user.district,
      'upazila': user.upazila,
      'preferred_crops': user.preferredCrops,
      'createdAt': user.createdAt.toIso8601String(),
    };
    await prefs.setString(_prefUserKey, jsonEncode(map));
  }

  Future<void> signOut() async {
    if (FirebaseService.isFirebaseInitialized && _auth != null) {
      await _auth.signOut();
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefUserKey);
    _currentUser = null;
  }
}
