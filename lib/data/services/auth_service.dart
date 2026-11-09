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

    if (!FirebaseService.isFirebaseInitialized || _auth == null || effectiveVerificationId.isEmpty || effectiveVerificationId.startsWith('mock_')) {
      throw Exception('সার্ভারের সাথে সংযোগ স্থাপন করা সম্ভব হয়নি। অনুগ্রহ করে ইন্টারনেট সংযোগ পরীক্ষা করুন।');
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
        name: firebaseUser.displayName ?? 'কৃষক ভাই',
        phone: phone,
        district: '',
        upazila: '',
        preferredCrops: [],
        createdAt: DateTime.now(),
      );
      await _firestore!.collection('users').doc(firebaseUser.uid).set(user.toMap());
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
      phone: '',
      district: '',
      upazila: '',
      village: '',
      occupation: 'কৃষক',
      preferredCrops: [],
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

  Future<void> cacheUser(UserModel user) async {
    await _cacheUser(user);
    _currentUser = user;
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
      final userMap = user.toMap();
      userMap['password'] = password;
      userMap['failedAttempts'] = 0;
      userMap['lockUntil'] = null;
      await _firestore!.collection('users').doc(firebaseUser.uid).set(userMap);
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
      String targetEmail = cleanId.toLowerCase();
      DocumentSnapshot<Map<String, dynamic>>? matchedUserDoc;

      // ১. মোবাইল নম্বর বা ইমেইল দিয়ে ফায়ারস্টোর থেকে অ্যাকাউন্ট অনুসন্ধান
      if (!cleanId.contains('@')) {
        final cleanPhone = cleanId.replaceAll(RegExp(r'[^0-9+]'), '');
        String altPhone = cleanPhone;
        if (cleanPhone.startsWith('+880')) {
          altPhone = cleanPhone.replaceFirst('+88', '');
        } else if (cleanPhone.startsWith('0')) {
          altPhone = '+88$cleanPhone';
        }

        QuerySnapshot<Map<String, dynamic>> query;
        try {
          query = await _firestore!
              .collection('users')
              .where('phone', isEqualTo: cleanPhone)
              .limit(1)
              .get()
              .timeout(const Duration(seconds: 8));

          if (query.docs.isEmpty && altPhone != cleanPhone) {
            query = await _firestore!
                .collection('users')
                .where('phone', isEqualTo: altPhone)
                .limit(1)
                .get()
                .timeout(const Duration(seconds: 8));
          }
        } catch (_) {
          throw Exception('এই মোবাইল নম্বরে কোনো একাউন্ট পাওয়া যায়নি!');
        }

        if (query.docs.isEmpty) {
          throw Exception('এই মোবাইল নম্বরে কোনো একাউন্ট পাওয়া যায়নি!');
        }

        matchedUserDoc = query.docs.first;
        final docData = matchedUserDoc.data();
        final foundEmail = (docData?['email'] as String?)?.trim();
        if (foundEmail == null || foundEmail.isEmpty) {
          throw Exception('এই মোবাইল নম্বরে কোনো একাউন্ট পাওয়া যায়নি!');
        }
        targetEmail = foundEmail.toLowerCase();
      } else {
        if (_firestore != null) {
          try {
            final emailQuery = await _firestore!
                .collection('users')
                .where('email', isEqualTo: targetEmail)
                .limit(1)
                .get()
                .timeout(const Duration(seconds: 8));
            if (emailQuery.docs.isNotEmpty) {
              matchedUserDoc = emailQuery.docs.first;
            }
          } catch (_) {}
        }
      }

      // ২. ভুল পাসওয়ার্ডে একাউন্ট লক আছে কিনা তা সবার আগে যাচাই
      if (matchedUserDoc != null && matchedUserDoc.exists) {
        final uData = matchedUserDoc.data() ?? {};
        final dynamic rawLockUntil = uData['lockUntil'];
        DateTime? lockDate;
        if (rawLockUntil is Timestamp) {
          lockDate = rawLockUntil.toDate();
        } else if (rawLockUntil is String) {
          lockDate = DateTime.tryParse(rawLockUntil);
        }

        if (lockDate != null && DateTime.now().isBefore(lockDate)) {
          final diff = lockDate.difference(DateTime.now());
          final remainingMinutes = diff.inMinutes + (diff.inSeconds % 60 > 0 ? 1 : 0);
          final remBn = _toBn(remainingMinutes > 0 ? remainingMinutes.toString() : '১');
          throw Exception('১০ বার ভুল তথ্য দেওয়ায় আপনার একাউন্ট ১ ঘণ্টার জন্য সাময়িক লক করা হয়েছে। আনলক হতে আর $remBn মিনিট বাকি আছে অথবা এডমিনের সাথে যোগাযোগ করুন।');
        }
      }

      // ৩. ডাটাবেজ পাসওয়ার্ড ভিত্তিক ডাইনামিক ভ্যালিডেশন
      final uData = matchedUserDoc?.data() ?? {};
      final dbPassword = (uData['password'] as String?)?.trim();
      final cleanPass = password.trim();

      bool authSuccess = false;
      if (dbPassword != null && dbPassword.isNotEmpty) {
        authSuccess = (dbPassword == cleanPass);
      } else {
        try {
          final credential = await _auth!.signInWithEmailAndPassword(
            email: targetEmail,
            password: cleanPass,
          ).timeout(const Duration(seconds: 10));
          if (credential.user != null) {
            authSuccess = true;
          }
        } catch (_) {
          authSuccess = false;
        }
      }

      if (authSuccess) {
        // সফল লগইন: প্রোফাইল লোড ও failedAttempts রিসেট
        final userDoc = matchedUserDoc ?? await _firestore!.collection('users').doc(_auth!.currentUser?.uid).get();
        UserModel user;
        if (userDoc.exists && userDoc.data() != null) {
          user = UserModel.fromFirestore(userDoc);
        } else {
          user = UserModel(
            uid: userDoc.id,
            name: _auth!.currentUser?.displayName ?? 'কৃষক ভাই',
            email: _auth!.currentUser?.email ?? targetEmail,
            phone: cleanId.contains('@') ? '' : cleanId,
            district: '',
            upazila: '',
            village: '',
            occupation: 'কৃষক',
            preferredCrops: [],
            createdAt: DateTime.now(),
          );
        }

        // ফায়ারস্টোরে 'password' সিঙ্ক ও সিকিউরিটি কাউন্টার রিসেট
        try {
          await _firestore!.collection('users').doc(userDoc.id).update({
            'password': cleanPass,
            'failedAttempts': 0,
            'lockUntil': null,
            'tempAdminPassword': FieldValue.delete(),
            'updatedAt': FieldValue.serverTimestamp(),
          });
        } catch (_) {}

        // Firebase Auth ব্যাকগ্রাউন্ড সিঙ্ক
        try {
          if (_auth!.currentUser == null) {
            try {
              await _auth!.signInWithEmailAndPassword(
                email: targetEmail,
                password: cleanPass,
              ).timeout(const Duration(seconds: 5));
            } catch (_) {}
          } else {
            try {
              await _auth!.currentUser!.updatePassword(cleanPass);
            } catch (_) {}
          }
        } catch (_) {}

        await _cacheUser(user);
        _currentUser = user;
        return user;
      } else {
        // পাসওয়ার্ড ভুল: failedAttempts কাউন্টার আপডেট
        if (matchedUserDoc != null && matchedUserDoc.exists) {
          final uData = matchedUserDoc.data() ?? {};
          final currentAttempts = ((uData['failedAttempts'] as num?)?.toInt() ?? 0) + 1;

          if (currentAttempts >= 10) {
            final lockTime = DateTime.now().add(const Duration(hours: 1));
            try {
              await _firestore!.collection('users').doc(matchedUserDoc.id).update({
                'failedAttempts': currentAttempts,
                'lockUntil': Timestamp.fromDate(lockTime),
                'updatedAt': FieldValue.serverTimestamp(),
              });
            } catch (_) {}
            throw Exception('১০ বার ভুল তথ্য দেওয়ায় আপনার একাউন্ট ১ ঘণ্টার জন্য সাময়িক লক করা হয়েছে। আনলক হতে আর ৬০ মিনিট বাকি আছে অথবা এডমিনের সাথে যোগাযোগ করুন।');
          } else {
            try {
              await _firestore!.collection('users').doc(matchedUserDoc.id).update({
                'failedAttempts': currentAttempts,
                'updatedAt': FieldValue.serverTimestamp(),
              });
            } catch (_) {}
            final remaining = 10 - currentAttempts;
            final remBn = _toBn(remaining.toString());
            throw Exception('আপনার দেওয়া পাসওয়ার্ড সঠিক নয়! আর $remBn বার ভুল দিলে একাউন্টটি ১ ঘণ্টার জন্য লক হয়ে যাবে।');
          }
        }
        throw Exception('আপনার দেওয়া পাসওয়ার্ড সঠিক নয়!');
      }
      } else if (e.code == 'user-not-found') {
        throw Exception(cleanId.contains('@')
            ? 'এই জিমেইল এড্রেসে কোনো একাউন্ট পাওয়া যায়নি!'
            : 'এই মোবাইল নম্বরে কোনো একাউন্ট পাওয়া যায়নি!');
      } else if (e.code == 'invalid-email') {
        throw Exception('জিমেইল এড্রেসটি সঠিক নয়!');
      } else if (e.code == 'network-request-failed') {
        throw Exception('ইন্টারনেট সংযোগ চেক করুন এবং পুনরায় চেষ্টা করুন।');
      } else if (e.code == 'too-many-requests') {
        throw Exception('অতিরিক্ত ভুল চেষ্টার কারণে সাময়িকভাবে ব্লক করা হয়েছে। কিছুক্ষণ পর আবার চেষ্টা করুন।');
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

  String _toBn(String s) {
    const eng = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
    const bng = ['০', '১', '২', '৩', '৪', '৫', '৬', '৭', '৮', '৯'];
    for (int i = 0; i < eng.length; i++) {
      s = s.replaceAll(eng[i], bng[i]);
    }
    return s;
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
