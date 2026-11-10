import 'package:flutter/material.dart';
import '../data/models/user_model.dart';
import '../data/services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  UserModel? _user;
  bool _isLoading = false;
  String? _errorMessage;
  String? _verificationId;

  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get verificationId => _verificationId;
  bool get isAuthenticated => _user != null;
  bool get isGuest => _user == null || (_user?.uid.startsWith('guest_') ?? true);
  bool get isLoggedIn => _user != null && !_user!.uid.startsWith('guest_');

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  Future<void> setUser(UserModel user) async {
    _user = user;
    _isLoading = false;
    _errorMessage = null;
    await _authService.cacheUser(user);
    notifyListeners();
  }

  AuthProvider() {
    _initUser();
  }

  Future<void> _initUser() async {
    _isLoading = true;
    notifyListeners();
    try {
      _user = await _authService.loadCachedUser();
    } catch (e) {
      debugPrint('Auth init cached user load error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> sendOtp(String phoneNumber, VoidCallback onSuccess) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    await _authService.sendOtp(
      phoneNumber: phoneNumber,
      onCodeSent: (vId) {
        _verificationId = vId;
        _isLoading = false;
        notifyListeners();
        onSuccess();
      },
      onError: (msg) {
        _errorMessage = msg;
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  Future<bool> verifyOtp(String smsCode, String phoneNumber) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _user = await _authService.verifyOtp(
        smsCode: smsCode,
        phoneNumber: phoneNumber,
        verificationId: _verificationId,
      );
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'ওটিপি যাচাই ব্যর্থ হয়েছে। সঠিক কোড দিন।';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> loginAsGuest() async {
    _isLoading = true;
    notifyListeners();
    _user = await _authService.loginAsGuest();
    _isLoading = false;
    notifyListeners();
  }

  Future<void> updateProfile({
    required String name,
    required String district,
    required String upazila,
    required List<String> preferredCrops,
  }) async {
    _isLoading = true;
    notifyListeners();

    await _authService.updateProfile(
      name: name,
      district: district,
      upazila: upazila,
      preferredCrops: preferredCrops,
    );

    _user = _authService.currentUser;
    _isLoading = false;
    notifyListeners();
  }

  Future<bool> registerWithEmailAndPassword({
    required String email,
    required String password,
    required String phone,
    required String name,
    required String district,
    required String upazila,
    required String village,
    required String occupation,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _user = await _authService.registerWithEmailAndPassword(
        email: email,
        password: password,
        phone: phone,
        name: name,
        district: district,
        upazila: upazila,
        village: village,
        occupation: occupation,
      );
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> loginWithIdentifierAndPassword({
    required String identifier,
    required String password,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _user = await _authService.loginWithIdentifierAndPassword(
        identifier: identifier,
        password: password,
      );
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> sendPasswordResetEmail(String email) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _authService.sendPasswordResetEmail(email);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> loginWithBiometrics(UserModel user) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _user = user;
      await _authService.cacheUser(user);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> signOut() async {
    await _authService.signOut();
    _user = null;
    notifyListeners();
  }
}
