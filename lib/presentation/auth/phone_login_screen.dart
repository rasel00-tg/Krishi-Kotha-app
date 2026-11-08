import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lottie/lottie.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/utils/bangla_number_converter.dart';
import '../../core/widgets/app_warning_dialog.dart';
import '../../core/widgets/app_unified_dialog.dart';
import '../../data/services/biometric_auth_service.dart';
import '../../providers/auth_provider.dart';
import '../menu/privacy_policy_screen.dart';
import '../navigation/main_navigation_screen.dart';
import 'forgot_password_screen.dart';
import 'registration_multi_step_screen.dart';

class PhoneLoginScreen extends StatefulWidget {
  final bool isGatewayForMenu;

  const PhoneLoginScreen({
    super.key,
    this.isGatewayForMenu = false,
  });

  @override
  State<PhoneLoginScreen> createState() => _PhoneLoginScreenState();
}

class _PhoneLoginScreenState extends State<PhoneLoginScreen> {
  // 0 = ইমেইল, 1 = নাম্বার
  int _loginTabIndex = 0;

  final TextEditingController _identifierController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _obscurePassword = true;
  bool _rememberMe = true;
  bool _isIdentifierValid = false;

  static const String _prefRememberKey = 'krishi_kotha_remember_me';
  static const String _prefIdentifierKey = 'krishi_kotha_remembered_identifier';
  static const String _prefLoginModeKey = 'krishi_kotha_login_mode';

  // Constant font styling to fix font stability & jumping
  static const TextStyle _inputTextStyle = TextStyle(
    fontFamily: 'Roboto',
    fontSize: 16.0,
    height: 1.25,
    fontWeight: FontWeight.w500,
    color: AppColors.textPrimary,
  );

  static const StrutStyle _inputStrutStyle = StrutStyle(
    fontFamily: 'Roboto',
    fontSize: 16.0,
    height: 1.25,
    forceStrutHeight: true,
  );

  @override
  void initState() {
    super.initState();
    _loadRememberedData();
    _identifierController.addListener(_onIdentifierChanged);
  }

  @override
  void dispose() {
    _identifierController.removeListener(_onIdentifierChanged);
    _identifierController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _loadRememberedData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final remember = prefs.getBool(_prefRememberKey) ?? true;
      final savedId = prefs.getString(_prefIdentifierKey) ?? '';
      final savedMode = prefs.getInt(_prefLoginModeKey) ?? 0;

      if (mounted) {
        setState(() {
          _rememberMe = remember;
          _loginTabIndex = savedMode;
          if (remember && savedId.isNotEmpty) {
            _identifierController.text = savedId;
            _checkIdentifierValidation(savedId);
          }
        });
      }
    } catch (_) {}
  }

  void _onIdentifierChanged() {
    _checkIdentifierValidation(_identifierController.text.trim());
  }

  void _checkIdentifierValidation(String text) {
    bool isValid = false;

    if (_loginTabIndex == 0) {
      // ইমেইল মোড: অবশ্যই @gmail.com থাকতে হবে
      final lower = text.toLowerCase();
      isValid = lower.endsWith('@gmail.com') &&
          RegExp(r'^[a-zA-Z0-9._%+-]+@gmail\.com$', caseSensitive: false).hasMatch(lower);
    } else {
      // নাম্বার মোড: ১১ ডিজিট এবং ০১ দিয়ে শুরু
      final cleanPhone = text.replaceAll(RegExp(r'[^0-9]'), '');
      isValid = cleanPhone.length == 11 && cleanPhone.startsWith('01');
    }

    if (isValid != _isIdentifierValid) {
      setState(() {
        _isIdentifierValid = isValid;
      });
    }
  }

  Future<void> _submitLogin() async {
    final identifier = _identifierController.text.trim();
    final password = _passwordController.text;

    // ১. আইডেন্টিফায়ার ভ্যালিডেশন ডায়ালগ
    if (identifier.isEmpty) {
      showAppFailureDialog(
        context,
        title: 'লগইন ব্যর্থ হয়েছে!',
        message: _loginTabIndex == 0
            ? 'অনুগ্রহ করে একটি সঠিক @gmail.com জিমেইল এড্রেস লিখুন!'
            : 'অনুগ্রহ করে আপনার ১১ ডিজিটের মোবাইল নম্বর লিখুন!',
      );
      return;
    }

    if (_loginTabIndex == 0) {
      final lower = identifier.toLowerCase();
      if (!lower.endsWith('@gmail.com') ||
          !RegExp(r'^[a-zA-Z0-9._%+-]+@gmail\.com$', caseSensitive: false).hasMatch(lower)) {
        showAppFailureDialog(
          context,
          title: 'লগইন ব্যর্থ হয়েছে!',
          message: 'ইমেইল ফরম্যাট সঠিক নয়! শুধুমাত্র @gmail.com গ্রহণযোগ্য।',
        );
        return;
      }
    } else {
      final clean = identifier.replaceAll(RegExp(r'[^0-9]'), '');
      if (clean.length != 11 || !clean.startsWith('01')) {
        showAppFailureDialog(
          context,
          title: 'লগইন ব্যর্থ হয়েছে!',
          message: 'সঠিক ১১ ডিজিটের বাংলাদেশী মোবাইল নম্বর দিন (যেমন: 017XXXXXXXX)!',
        );
        return;
      }
    }

    // ২. পাসওয়ার্ড ভ্যালিডেশন ডায়ালগ
    if (password.isEmpty) {
      showAppFailureDialog(
        context,
        title: 'লগইন ব্যর্থ হয়েছে!',
        message: 'পাসওয়ার্ড লিখুন!',
      );
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    // Persist Remember Me & Login Mode
    try {
      final prefs = await SharedPreferences.getInstance();
      if (_rememberMe) {
        await prefs.setString(_prefIdentifierKey, identifier);
        await prefs.setBool(_prefRememberKey, true);
        await prefs.setInt(_prefLoginModeKey, _loginTabIndex);
      } else {
        await prefs.remove(_prefIdentifierKey);
        await prefs.setBool(_prefRememberKey, false);
      }
    } catch (_) {}

    // ১. প্রিমিয়াম ব্র্যান্ডেড লগইন লোডিং পপ-আপ
    bool isLoaderShowing = true;
    showDialog(
      context: context,
      barrierDismissible: true, // সেফটি: স্ক্রিন কখনোই যেন পার্মানেন্টলি লক না হয়
      builder: (dialogCtx) => PopScope(
        canPop: false,
        child: MediaQuery.withNoTextScaling(
          child: Dialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            elevation: 12,
            insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 320),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 96,
                      height: 96,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          const SizedBox(
                            width: 96,
                            height: 96,
                            child: CircularProgressIndicator(
                              strokeWidth: 3.5,
                              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                              backgroundColor: Color(0xFFE8F5E9),
                            ),
                          ),
                          SizedBox(
                            width: 60,
                            height: 60,
                            child: Image.asset(
                              'assets/icons/pnglogo.png',
                              fit: BoxFit.contain,
                              errorBuilder: (_, __, ___) => const Icon(
                                Icons.eco_rounded,
                                color: AppColors.primary,
                                size: 48,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'লগইন হচ্ছে....',
                      style: TextStyle(
                        fontSize: 16.5,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'অনুগ্রহ করে অপেক্ষা করুন',
                      style: TextStyle(
                        fontSize: 12.5,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );

    bool success = false;
    String? explicitErrorMessage;

    try {
      String targetEmail = identifier.trim().toLowerCase();

      // যদি মোবাইল নম্বর দিয়ে লগইন করার চেষ্টা হয়, তবে ফায়ারস্টোর থেকে ইমেইল অনুসন্ধান
      if (!identifier.contains('@')) {
        final cleanPhone = identifier.replaceAll(RegExp(r'[^0-9+]'), '');
        String altPhone = cleanPhone;
        if (cleanPhone.startsWith('+880')) {
          altPhone = cleanPhone.replaceFirst('+88', '');
        } else if (cleanPhone.startsWith('0')) {
          altPhone = '+88$cleanPhone';
        }

        final query = await FirebaseFirestore.instance
            .collection('users')
            .where('phone', isEqualTo: cleanPhone)
            .limit(1)
            .get()
            .timeout(const Duration(seconds: 8));

        QuerySnapshot<Map<String, dynamic>> finalQuery = query;
        if (query.docs.isEmpty && altPhone != cleanPhone) {
          finalQuery = await FirebaseFirestore.instance
              .collection('users')
              .where('phone', isEqualTo: altPhone)
              .limit(1)
              .get()
              .timeout(const Duration(seconds: 8));
        }

        if (finalQuery.docs.isEmpty) {
          explicitErrorMessage = 'এই মোবাইল নম্বরে কোনো একাউন্ট পাওয়া যায়নি!';
        } else {
          final foundEmail = (finalQuery.docs.first.data()['email'] as String?)?.trim();
          if (foundEmail == null || foundEmail.isEmpty) {
            explicitErrorMessage = 'এই মোবাইল নম্বরে কোনো একাউন্ট পাওয়া যায়নি!';
          } else {
            targetEmail = foundEmail.toLowerCase();
          }
        }
      }

      if (explicitErrorMessage == null) {
        // ফায়ারবেজ অথেনটিকেশন সাইন-ইন
        final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: targetEmail,
          password: password,
        ).timeout(const Duration(seconds: 12));

        if (credential.user != null) {
          // ফায়ারস্টোর থেকে প্রোফাইল ডাটা লোড ও প্রোভাইডারে সিঙ্ক
          final userDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(credential.user!.uid)
              .get();

          UserModel loggedUser;
          if (userDoc.exists && userDoc.data() != null) {
            loggedUser = UserModel.fromFirestore(userDoc);
          } else {
            loggedUser = UserModel(
              uid: credential.user!.uid,
              name: credential.user!.displayName ?? 'কৃষক ভাই',
              email: credential.user!.email ?? targetEmail,
              phone: identifier.contains('@') ? '' : identifier,
              district: '',
              upazila: '',
              village: '',
              occupation: 'কৃষক',
              preferredCrops: [],
              createdAt: DateTime.now(),
            );
          }

          await authProvider.setUser(loggedUser);
          success = true;
        }
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
        explicitErrorMessage = 'পাসওয়ার্ড ভুল হয়েছে!';
      } else if (e.code == 'user-not-found') {
        explicitErrorMessage = _loginTabIndex == 0
            ? 'এই ইমেইলে কোনো একাউন্ট নেই!'
            : 'এই মোবাইল নম্বরে কোনো একাউন্ট পাওয়া যায়নি!';
      } else if (e.code == 'invalid-email') {
        explicitErrorMessage = 'ইমেইল ফরম্যাট সঠিক নয়!';
      } else if (e.code == 'network-request-failed') {
        explicitErrorMessage = 'ইন্টারনেট সংযোগ চেক করুন এবং পুনরায় চেষ্টা করুন।';
      } else if (e.code == 'too-many-requests') {
        explicitErrorMessage = 'অতিরিক্ত ভুল চেষ্টার কারণে সাময়িকভাবে ব্লক করা হয়েছে। কিছুক্ষণ পর আবার চেষ্টা করুন।';
      } else if (e.code == 'user-disabled') {
        explicitErrorMessage = 'এই একাউন্টটি সাময়িকভাবে নিষ্ক্রিয় রয়েছে।';
      } else {
        explicitErrorMessage = 'আপনার দেওয়া পাসওয়ার্ড সঠিক নয় অথবা একাউন্টটি পাওয়া যায়নি!';
      }
    } catch (e) {
      final str = e.toString().replaceFirst('Exception: ', '');
      if (str.contains('wrong-password') || str.contains('invalid-credential')) {
        explicitErrorMessage = 'পাসওয়ার্ড ভুল হয়েছে!';
      } else if (str.contains('user-not-found')) {
        explicitErrorMessage = _loginTabIndex == 0 ? 'এই ইমেইলে কোনো একাউন্ট নেই!' : 'এই মোবাইল নম্বরে কোনো একাউন্ট পাওয়া যায়নি!';
      } else {
        explicitErrorMessage = str;
      }
    } finally {
      // অপারেশন সফল হোক বা ব্যর্থ, বাধ্যতামূলকভাবে finally ব্লকের ভেতর ডায়ালগ সম্পূর্ণ বন্ধ করা
      if (isLoaderShowing && mounted) {
        if (Navigator.of(context, rootNavigator: true).canPop()) {
          Navigator.of(context, rootNavigator: true).pop();
        }
        isLoaderShowing = false;
      }
    }

    if (!mounted) return;

    if (success) {
      showAppSuccessDialog(
        context,
        title: 'লগইন সফল হয়েছে!',
        message: 'কৃষি কথা অ্যাপে আপনাকে স্বাগতম।',
        onConfirm: () {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
              builder: (_) => const MainNavigationScreen(initialIndex: 0),
            ),
            (route) => false,
          );
        },
      );
    } else {
      final msg = explicitErrorMessage ?? 'পাসওয়ার্ড ভুল হয়েছে!';
      showAppFailureDialog(
        context,
        title: 'লগইন ব্যর্থ হয়েছে!',
        message: msg,
      );
    }
  }

  Future<void> _handleBiometricLogin() async {
    final isEnabled = await BiometricAuthService.isBiometricEnabled();
    if (!isEnabled) {
      if (!mounted) return;
      await AppUnifiedDialog.showWarning(
        context,
        title: 'ফিঙ্গারপ্রিন্ট লগইন সক্রিয় নেই!',
        message: 'নিরাপদে এক ক্লিকে লগইন করতে প্রথমে ইমেইল ও পাসওয়ার্ড দিয়ে প্রবেশ করুন, এরপর মেনু > সেটিংস পেজ থেকে ফিঙ্গারপ্রিন্ট অথেনটিকেশন সক্রিয় করে নিন।',
        buttonText: 'বুঝেছি',
      );
      return;
    }

    if (!mounted) return;
    final verified = await BiometricAuthService.showBiometricScanDialog(
      context,
      title: 'ফিঙ্গারপ্রিন্ট লগইন',
      subtitle: 'লগইন করতে আপনার ফিঙ্গারপ্রিন্ট সেন্সরে আঙুল রাখুন',
    );

    if (verified && mounted) {
      final savedUser = await BiometricAuthService.getSavedBiometricUser();
      if (savedUser != null) {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        final success = await authProvider.loginWithBiometrics(savedUser);
        if (success && mounted) {
          await AppUnifiedDialog.showSuccess(
            context,
            title: 'লগইন সফল!',
            message: 'ফিঙ্গারপ্রিন্ট ভেরিফিকেশন সফল হয়েছে। স্বাগতম!',
            buttonText: 'ঠিক আছে',
          );
          if (mounted) {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
              (route) => false,
            );
          }
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final canGoBack = !widget.isGatewayForMenu && Navigator.canPop(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF7FAF7),
      appBar: canGoBack
          ? AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary, size: 20),
                onPressed: () => Navigator.pop(context),
              ),
            )
          : null,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 22.0, vertical: 20.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // ================= ১. একক শিরোনাম (ONLY "স্বাগতম") =================
                  const Text(
                    'স্বাগতম',
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                      letterSpacing: 0.2,
                    ),
                  ),

                  const SizedBox(height: 14),

                  // ================= লোগো (PLAIN LARGE LOGO: NO CIRCLE, NO SHADOW, NO CONTAINER) =================
                  SizedBox(
                    width: 90,
                    height: 90,
                    child: Image.asset(
                      'assets/icons/pnglogo.png',
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.eco_rounded,
                        size: 76,
                        color: AppColors.primary,
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  // অ্যাপের নাম
                  const Text(
                    'কৃষি কথা',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryDark,
                      letterSpacing: 0.3,
                    ),
                  ),

                  const SizedBox(height: 22),

                  // ================= ৩. প্রিমিয়াম লগইন কার্ড (MODERN LOGIN CARD) =================
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: const Color(0xFFE2E8E2), width: 1.0),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x0C000000),
                          blurRadius: 18,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 22.0, vertical: 24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ================= ২. ইমেইল ও মোবাইল নম্বর টগল বার (2-TAB SEGMENTED BAR) =================
                        Container(
                          height: 46,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFE2E8E2)),
                          ),
                          padding: const EdgeInsets.all(4),
                          child: Row(
                            children: [
                              // ট্যাব ১: ইমেইল
                              Expanded(
                                child: GestureDetector(
                                  onTap: () {
                                    if (_loginTabIndex != 0) {
                                      setState(() {
                                        _loginTabIndex = 0;
                                        _identifierController.clear();
                                        _isIdentifierValid = false;
                                      });
                                      authProvider.clearError();
                                    }
                                  },
                                  behavior: HitTestBehavior.opaque,
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    decoration: BoxDecoration(
                                      color: _loginTabIndex == 0 ? AppColors.primary : Colors.transparent,
                                      borderRadius: BorderRadius.circular(9),
                                      boxShadow: _loginTabIndex == 0
                                          ? [
                                              BoxShadow(
                                                color: AppColors.primary.withOpacity(0.28),
                                                blurRadius: 6,
                                                offset: const Offset(0, 2),
                                              ),
                                            ]
                                          : null,
                                    ),
                                    alignment: Alignment.center,
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.email_outlined,
                                          size: 18,
                                          color: _loginTabIndex == 0 ? Colors.white : AppColors.textSecondary,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          'ইমেইল',
                                          style: TextStyle(
                                            fontSize: 14.5,
                                            fontWeight: FontWeight.bold,
                                            color: _loginTabIndex == 0 ? Colors.white : AppColors.textSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 4),
                              // ট্যাব ২: নাম্বার
                              Expanded(
                                child: GestureDetector(
                                  onTap: () {
                                    if (_loginTabIndex != 1) {
                                      setState(() {
                                        _loginTabIndex = 1;
                                        _identifierController.clear();
                                        _isIdentifierValid = false;
                                      });
                                      authProvider.clearError();
                                    }
                                  },
                                  behavior: HitTestBehavior.opaque,
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    decoration: BoxDecoration(
                                      color: _loginTabIndex == 1 ? AppColors.primary : Colors.transparent,
                                      borderRadius: BorderRadius.circular(9),
                                      boxShadow: _loginTabIndex == 1
                                          ? [
                                              BoxShadow(
                                                color: AppColors.primary.withOpacity(0.28),
                                                blurRadius: 6,
                                                offset: const Offset(0, 2),
                                              ),
                                            ]
                                          : null,
                                    ),
                                    alignment: Alignment.center,
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.phone_android_rounded,
                                          size: 18,
                                          color: _loginTabIndex == 1 ? Colors.white : AppColors.textSecondary,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          'নাম্বার',
                                          style: TextStyle(
                                            fontSize: 14.5,
                                            fontWeight: FontWeight.bold,
                                            color: _loginTabIndex == 1 ? Colors.white : AppColors.textSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 18),

                        // আইডেন্টিফায়ার ফিল্ড (ইমেইল বা নাম্বার ভিত্তিক ডাইনামিক ফিল্ড)
                        Text(
                          _loginTabIndex == 0 ? 'জিমেইল অ্যাড্রেস *' : 'মোবাইল নম্বর (১১ ডিজিট) *',
                          style: const TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 7),
                        TextFormField(
                          key: ValueKey('input_mode_$_loginTabIndex'),
                          controller: _identifierController,
                          keyboardType: _loginTabIndex == 0 ? TextInputType.emailAddress : TextInputType.phone,
                          style: _inputTextStyle,
                          strutStyle: _inputStrutStyle,
                          inputFormatters: _loginTabIndex == 1
                              ? [
                                  FilteringTextInputFormatter.digitsOnly,
                                  LengthLimitingTextInputFormatter(11),
                                ]
                              : [
                                  FilteringTextInputFormatter.deny(RegExp(r'\s')),
                                ],
                          decoration: InputDecoration(
                            isDense: true,
                            hintText: _loginTabIndex == 0 ? 'example@gmail.com' : '01XXXXXXXXX',
                            hintStyle: const TextStyle(
                              fontFamily: 'Roboto',
                              fontSize: 15.0,
                              color: AppColors.textMuted,
                              height: 1.25,
                              fontWeight: FontWeight.normal,
                            ),
                            prefixIcon: Icon(
                              _loginTabIndex == 0 ? Icons.email_outlined : Icons.phone_android_rounded,
                              color: AppColors.primary,
                              size: 22,
                            ),
                            suffixIcon: _isIdentifierValid
                                ? const Padding(
                                    padding: EdgeInsets.only(right: 12.0),
                                    child: Icon(
                                      Icons.check_circle_rounded,
                                      color: Color(0xFF2E7D32),
                                      size: 22,
                                    ),
                                  )
                                : null,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(color: Color(0xFFCFD8DC)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(color: Color(0xFFCFD8DC)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(color: AppColors.primary, width: 1.6),
                            ),
                          ),
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) {
                              return _loginTabIndex == 0
                                  ? 'অনুগ্রহ করে জিমেইল অ্যাড্রেস লিখুন'
                                  : 'অনুগ্রহ করে মোবাইল নম্বর লিখুন';
                            }
                            if (_loginTabIndex == 0) {
                              final text = val.trim().toLowerCase();
                              if (!text.endsWith('@gmail.com') ||
                                  !RegExp(r'^[a-zA-Z0-9._%+-]+@gmail\.com$').hasMatch(text)) {
                                return 'শুধুমাত্র @gmail.com ইমেইল গ্রহণযোগ্য (যেমন: user@gmail.com)';
                              }
                            } else {
                              final clean = val.replaceAll(RegExp(r'[^0-9]'), '');
                              if (clean.length != 11 || !clean.startsWith('01')) {
                                return 'সঠিক ১১ ডিজিটের বাংলাদেশী নম্বর দিন (যেমন: 017XXXXXXXX)';
                              }
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 16),

                        // পাসওয়ার্ড ফিল্ড
                        const Text(
                          'পাসওয়ার্ড *',
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 7),
                        TextFormField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          keyboardType: TextInputType.visiblePassword,
                          style: _inputTextStyle,
                          strutStyle: _inputStrutStyle,
                          decoration: InputDecoration(
                            isDense: true,
                            hintText: 'পাসওয়ার্ড লিখুন...',
                            hintStyle: const TextStyle(
                              fontFamily: 'Roboto',
                              fontSize: 15.0,
                              color: AppColors.textMuted,
                              height: 1.25,
                              fontWeight: FontWeight.normal,
                            ),
                            prefixIcon: const Icon(
                              Icons.lock_outline_rounded,
                              color: AppColors.primary,
                              size: 22,
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                color: AppColors.textMuted,
                                size: 20,
                              ),
                              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(color: Color(0xFFCFD8DC)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(color: Color(0xFFCFD8DC)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(color: AppColors.primary, width: 1.6),
                            ),
                          ),
                          validator: (val) {
                            if (val == null || val.isEmpty) {
                              return 'পাসওয়ার্ড লিখুন';
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 12),

                        // রিমেম্বার মি ও ফরগট পাসওয়ার্ড সারি
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            GestureDetector(
                              onTap: () => setState(() => _rememberMe = !_rememberMe),
                              behavior: HitTestBehavior.opaque,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: Checkbox(
                                      value: _rememberMe,
                                      activeColor: AppColors.primary,
                                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      onChanged: (val) => setState(() => _rememberMe = val ?? false),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  const Text(
                                    'মনে রাখুন',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const ForgotPasswordScreen(),
                                  ),
                                );
                              },
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.zero,
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: const Text(
                                'পাসওয়ার্ড ভুলে গেছেন?',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                          ],
                        ),

                        if (authProvider.errorMessage != null) ...[
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFEBEE),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: const Color(0xFFFFCDD2)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.error_outline_rounded, color: AppColors.alertCritical, size: 16),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    authProvider.errorMessage!,
                                    style: const TextStyle(
                                      color: AppColors.alertCritical,
                                      fontSize: 12.5,
                                    ),
                                  ),
                                ),
                              ],
                              ),
                            ),
                          ],

                          const SizedBox(height: 22),

                        // সাইন-ইন বাটন ও বায়োমেট্রিক বাটন (Sign In & Biometric Buttons)
                        Row(
                          children: [
                            // মূল লগইন বাটন
                            Expanded(
                              child: Container(
                                height: 48,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFF2E7D32), Color(0xFF1B5E20)],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(14),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF2E7D32).withOpacity(0.32),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: ElevatedButton(
                                  onPressed: authProvider.isLoading ? null : _submitLogin,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.transparent,
                                    shadowColor: Colors.transparent,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                  ),
                                  child: authProvider.isLoading
                                      ? const SizedBox(
                                          width: 22,
                                          height: 22,
                                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.2),
                                        )
                                      : const Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Text(
                                              'লগইন করুন',
                                              style: TextStyle(
                                                fontSize: 15.5,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white,
                                              ),
                                            ),
                                            SizedBox(width: 8),
                                            Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 19),
                                          ],
                                        ),
                                ),
                              ),
                            ),

                            const SizedBox(width: 12),

                            // মার্জিত Lottie ফিঙ্গারপ্রিন্ট বাটন
                            Material(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              elevation: 2,
                              shadowColor: const Color(0xFF2E7D32).withOpacity(0.20),
                              child: InkWell(
                                onTap: authProvider.isLoading ? null : _handleBiometricLogin,
                                borderRadius: BorderRadius.circular(14),
                                child: Container(
                                  width: 52,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(color: const Color(0xFF81C784), width: 1.5),
                                    color: const Color(0xFFF1F8E9),
                                  ),
                                  child: Center(
                                    child: Lottie.asset(
                                      'assets/animation/Fingerprint.json',
                                      width: 44,
                                      height: 44,
                                      fit: BoxFit.contain,
                                      repeat: true,
                                      errorBuilder: (context, error, stackTrace) {
                                        debugPrint('Lottie login button error: $error');
                                        return const Icon(
                                          Icons.fingerprint_rounded,
                                          color: Color(0xFF2E7D32),
                                          size: 28,
                                        );
                                      },
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 22),

                  // ================= ৪. নতুন একাউন্ট তৈরি বাটন (CREATE ACCOUNT) =================
                  Column(
                    children: [
                      const Text(
                        'একাউন্ট নেই?',
                        style: TextStyle(
                          fontSize: 13.5,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: OutlinedButton.icon(
                          onPressed: () {
                            authProvider.clearError();
                            Navigator.of(context, rootNavigator: true).push(
                              MaterialPageRoute(
                                builder: (_) => const RegistrationMultiStepScreen(),
                              ),
                            );
                          },
                          icon: const Icon(Icons.person_add_alt_1_rounded, color: AppColors.primary, size: 19),
                          label: const Text(
                            'নতুন একাউন্ট তৈরি করুন',
                            style: TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: AppColors.primary, width: 1.5),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            backgroundColor: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // ================= ফুটার সেকশন: ডায়নামিক অ্যাপ ভার্সন ও গোপনীয়তা নীতি =================
                  StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                    stream: FirebaseFirestore.instance
                        .collection('settings')
                        .doc('app_config')
                        .snapshots(),
                    builder: (context, snapshot) {
                      final appVer = (snapshot.hasData &&
                              snapshot.data?.data() != null &&
                              snapshot.data!.data()!['version'] != null)
                          ? snapshot.data!.data()!['version'].toString()
                          : AppStrings.appVersion;

                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            appVer,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF9E9E9E),
                              fontWeight: FontWeight.w500,
                              letterSpacing: 0.2,
                            ),
                          ),
                          const SizedBox(height: 5),
                          GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const PrivacyPolicyScreen(),
                                ),
                              );
                            },
                            child: const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              child: Text(
                                'গোপনীয় নীতি',
                                style: TextStyle(
                                  fontSize: 13.0,
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w600,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
