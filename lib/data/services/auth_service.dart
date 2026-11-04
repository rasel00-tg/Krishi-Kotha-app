import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import 'firebase_service.dart';

class AuthService {
  FirebaseAuth? get _auth => FirebaseService.isFirebaseInitialized ? FirebaseAuth.instance : null;
  FirebaseFirestore? get _firestore => FirebaseService.isFirebaseInitialized ? FirebaseFirestore.instance : null;

  static const String _prefUserKey = 'krishi_kotha_cached_user';
  UserModel? _currentUser;
  String? _verificationId;

  UserModel? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;
  bool get isGuest => _currentUser == null || (_currentUser?.uid.startsWith('guest_') ?? true);
  bool get isLoggedIn => _currentUser != null && !_currentUser!.uid.startsWith('guest_');

  /// Loads locally stored user profile on app start
  Future<UserModel?> loadCachedUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userJson = prefs.getString(_prefUserKey);
      if (userJson != null) {
        final map = jsonDecode(userJson) as Map<String, dynamic>;
        _currentUser = UserModel(
          uid: map['uid'] as String,
          name: map['name'] as String? ?? 'কৃষক ভাই',
          email: map['email'] as String? ?? '',
          phone: map['phone'] as String? ?? '',
          district: map['district'] as String? ?? '',
          upazila: map['upazila'] as String? ?? '',
          village: map['village'] as String? ?? '',
          occupation: map['occupation'] as String? ?? 'কৃষক',
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
      'email': user.email,
      'phone': user.phone,
      'district': user.district,
      'upazila': user.upazila,
      'village': user.village,
      'occupation': user.occupation,
      'preferred_crops': user.preferredCrops,
      'createdAt': user.createdAt.toIso8601String(),
    };
    await prefs.setString(_prefUserKey, jsonEncode(map));
  }

  /// Registers user with Email & Password, creates user profile in Firestore
  Future<UserModel> registerWithEmailAndPassword({
    required String email,
    required String password,
    required String phone,
    required String name,
    required String district,
    required String upazila,
    required String village,
    required String occupation,
  }) async {
    final cleanEmail = email.trim().toLowerCase();
    final cleanPhone = phone.trim().replaceAll(RegExp(r'[^0-9+]'), '');
    String altPhone = cleanPhone;
    if (cleanPhone.startsWith('+880')) {
      altPhone = cleanPhone.replaceFirst('+88', '');
    } else if (cleanPhone.startsWith('0')) {
      altPhone = '+88$cleanPhone';
    }

    if (!FirebaseService.isFirebaseInitialized || _auth == null || _firestore == null) {
      throw Exception('সার্ভারের সাথে সংযোগ স্থাপন করা সম্ভব হয়নি। অনুগ্রহ করে ইন্টারনেট সংযোগ পরীক্ষা করুন।');
    }

    // ১. ক্লাউড ফায়ারস্টোরের users কালেকশনে ডুপ্লিকেট জিমেইল বা মোবাইল নম্বর চেক (Single Account Policy)
    try {
      final emailQuery = await _firestore!
          .collection('users')
          .where('email', isEqualTo: cleanEmail)
          .limit(1)
          .get();
      if (emailQuery.docs.isNotEmpty) {
        throw Exception('এই জিমেইল অথবা মোবাইল নম্বর দিয়ে ইতোমধ্যে একটি একাউন্ট খোলা রয়েছে!');
      }

      final phoneQuery = await _firestore!
          .collection('users')
          .where('phone', isEqualTo: cleanPhone)
          .limit(1)
          .get();
      if (phoneQuery.docs.isNotEmpty) {
        throw Exception('এই জিমেইল অথবা মোবাইল নম্বর দিয়ে ইতোমধ্যে একটি একাউন্ট খোলা রয়েছে!');
      }

      if (altPhone != cleanPhone) {
        final altPhoneQuery = await _firestore!
            .collection('users')
            .where('phone', isEqualTo: altPhone)
            .limit(1)
            .get();
        if (altPhoneQuery.docs.isNotEmpty) {
          throw Exception('এই জিমেইল অথবা মোবাইল নম্বর দিয়ে ইতোমধ্যে একটি একাউন্ট খোলা রয়েছে!');
        }
      }
    } catch (e) {
      if (e is Exception && e.toString().contains('ইতোমধ্যে একটি একাউন্ট খোলা রয়েছে')) {
        rethrow;
      }
    }

    // ২. খাঁটি ফায়ারবেস অথেন্টিকেশন দিয়ে অ্যাকাউন্ট তৈরি
    try {
      final credential = await _auth!.createUserWithEmailAndPassword(
        email: cleanEmail,
        password: password,
      );
      final firebaseUser = credential.user!;

      try {
        await firebaseUser.updateDisplayName(name.trim());
      } catch (_) {}

      final user = UserModel(
        uid: firebaseUser.uid,
        name: name.trim().isEmpty ? 'কৃষক ভাই' : name.trim(),
        email: cleanEmail,
        phone: cleanPhone,
        district: district.trim().isEmpty ? 'বগুড়া' : district.trim(),
        upazila: upazila.trim().isEmpty ? 'শেরপুর' : upazila.trim(),
        village: village.trim(),
        occupation: occupation.trim().isEmpty ? 'কৃষক' : occupation.trim(),
        preferredCrops: [],
        createdAt: DateTime.now(),
      );

      // ৩. ফায়ারস্টোরের আসল users কালেকশনে সংরক্ষিত করা
      await _firestore!.collection('users').doc(firebaseUser.uid).set(user.toMap());
      await _cacheUser(user);
      _currentUser = user;
      return user;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        throw Exception('এই জিমেইল অথবা মোবাইল নম্বর দিয়ে ইতোমধ্যে একটি একাউন্ট খোলা রয়েছে!');
      } else if (e.code == 'weak-password') {
        throw Exception('পাসওয়ার্ডটি অন্তত ৬ অক্ষরের বা আরও শক্তিশালী হতে হবে।');
      } else if (e.code == 'invalid-email') {
        throw Exception('সঠিক ও বৈধ ইমেইল ঠিকানা প্রদান করুন।');
      } else if (e.message != null) {
        throw Exception(e.message!);
      }
      throw Exception('রেজিস্ট্রেশন সম্পন্ন করা যায়নি।');
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('রেজিস্ট্রেশনে সমস্যা: $e');
    }
  }

  /// Dual Identifier Login (Email or Mobile) + Password
  Future<UserModel> loginWithIdentifierAndPassword({
    required String identifier,
    required String password,
  }) async {
    final cleanId = identifier.trim();

    if (!FirebaseService.isFirebaseInitialized || _auth == null || _firestore == null) {
      throw Exception('সার্ভারের সাথে সংযোগ স্থাপন করা সম্ভব হয়নি। অনুগ্রহ করে ইন্টারনেট সংযোগ পরীক্ষা করুন।');
    }

    try {
      String targetEmail;

      if (cleanId.contains('@')) {
        // Direct Email Login
        targetEmail = cleanId.toLowerCase();
      } else {
        // Mobile Number lookup in Firestore users collection
        final cleanPhone = cleanId.replaceAll(RegExp(r'[^0-9+]'), '');
        String altPhone = cleanPhone;
        if (cleanPhone.startsWith('+880')) {
          altPhone = cleanPhone.replaceFirst('+88', '');
        } else if (cleanPhone.startsWith('0')) {
          altPhone = '+88$cleanPhone';
        }

        var query = await _firestore!
            .collection('users')
            .where('phone', isEqualTo: cleanPhone)
            .limit(1)
            .get();

        if (query.docs.isEmpty && altPhone != cleanPhone) {
          query = await _firestore!
              .collection('users')
              .where('phone', isEqualTo: altPhone)
              .limit(1)
              .get();
        }

        if (query.docs.isEmpty) {
          throw Exception('আপনার দেওয়া পাসওয়ার্ড সঠিক নয় অথবা একাউন্টটি পাওয়া যায়নি!');
        }

        final docData = query.docs.first.data();
        final foundEmail = (docData['email'] as String?)?.trim();
        if (foundEmail == null || foundEmail.isEmpty) {
          throw Exception('আপনার দেওয়া পাসওয়ার্ড সঠিক নয় অথবা একাউন্টটি পাওয়া যায়নি!');
        }
        targetEmail = foundEmail.toLowerCase();
      }

      // Live Firebase Authentication
      final credential = await _auth!.signInWithEmailAndPassword(
        email: targetEmail,
        password: password,
      );
      final firebaseUser = credential.user!;

      // Retrieve full user profile from Firestore users collection
      final userDoc = await _firestore!.collection('users').doc(firebaseUser.uid).get();
      UserModel user;
      if (userDoc.exists && userDoc.data() != null) {
        user = UserModel.fromFirestore(userDoc);
      } else {
        user = UserModel(
          uid: firebaseUser.uid,
          name: firebaseUser.displayName ?? 'কৃষক ভাই',
          email: firebaseUser.email ?? targetEmail,
          phone: cleanId.contains('@') ? '' : cleanId,
          district: 'বগুড়া',
          upazila: 'শেরপুর',
          village: '',
          occupation: 'কৃষক',
          preferredCrops: [],
          createdAt: DateTime.now(),
        );
        await _firestore!.collection('users').doc(firebaseUser.uid).set(user.toMap());
      }

      await _cacheUser(user);
      _currentUser = user;
      return user;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'wrong-password' ||
          e.code == 'invalid-credential' ||
          e.code == 'user-not-found' ||
          e.code == 'invalid-email') {
        throw Exception('আপনার দেওয়া পাসওয়ার্ড সঠিক নয় অথবা একাউন্টটি পাওয়া যায়নি!');
      } else if (e.code == 'user-disabled') {
        throw Exception('এই একাউন্টটি সাময়িকভাবে নিষ্ক্রিয় রয়েছে।');
      } else {
        throw Exception('আপনার দেওয়া পাসওয়ার্ড সঠিক নয় অথবা একাউন্টটি পাওয়া যায়নি!');
      }
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('আপনার দেওয়া পাসওয়ার্ড সঠিক নয় অথবা একাউন্টটি পাওয়া যায়নি!');
    }
  }

  /// Sends password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    final cleanEmail = email.trim().toLowerCase();
    if (!FirebaseService.isFirebaseInitialized || _auth == null) {
      throw Exception('সার্ভারের সাথে সংযোগ স্থাপন করা সম্ভব হয়নি। অনুগ্রহ করে ইন্টারনেট সংযোগ পরীক্ষা করুন।');
    }

    try {
      await _auth!.sendPasswordResetEmail(email: cleanEmail);
    } on FirebaseAuthException catch (e) {
      String banglaError = 'পাসওয়ার্ড রিসেট ইমেইল পাঠানো যায়নি।';
      if (e.code == 'user-not-found') {
        banglaError = 'এই ইমেইল ঠিকানার কোনো নিবন্ধিত একাউন্ট পাওয়া যায়নি।';
      } else if (e.code == 'invalid-email') {
        banglaError = 'সঠিক ও বৈধ ইমেইল ঠিকানা প্রদান করুন।';
      } else if (e.message != null) {
        banglaError = e.message!;
      }
      throw Exception(banglaError);
    } catch (e) {
      throw Exception('ত্রুটি: $e');
    }
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
