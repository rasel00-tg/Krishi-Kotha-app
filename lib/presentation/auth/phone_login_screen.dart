import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/utils/bangla_number_converter.dart';
import '../../core/widgets/app_warning_dialog.dart';
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
      showAppWarningDialog(
        context,
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
        showAppWarningDialog(
          context,
          message: 'শুধুমাত্র বৈধ @gmail.com জিমেইল এড্রেস গ্রহণযোগ্য (যেমন: user@gmail.com)!',
        );
        return;
      }
    } else {
      final clean = identifier.replaceAll(RegExp(r'[^0-9]'), '');
      if (clean.length != 11 || !clean.startsWith('01')) {
        showAppWarningDialog(
          context,
          message: 'সঠিক ১১ ডিজিটের বাংলাদেশী মোবাইল নম্বর দিন (যেমন: 017XXXXXXXX)!',
        );
        return;
      }
    }

    // ২. পাসওয়ার্ড ভ্যালিডেশন ডায়ালগ
    if (password.isEmpty) {
      showAppWarningDialog(
        context,
        message: 'অনুগ্রহ করে আপনার অ্যাকাউন্টের পাসওয়ার্ড লিখুন!',
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

    // ১. ইন্টারেক্টিভ নন-ডিসমিসিবল কাস্টম লোডিং ডায়ালগ (Login Loading Dialog)
    bool isLoaderShowing = true;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) => PopScope(
        canPop: false,
        child: Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          elevation: 6,
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 22, vertical: 22),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 32,
                  height: 32,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                  ),
                ),
                SizedBox(width: 18),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'লগইন হচ্ছে...',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      SizedBox(height: 3),
                      Text(
                        'অনুগ্রহ করে অপেক্ষা করুন',
                        style: TextStyle(
                          fontSize: 12.5,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    bool success = false;
    String? explicitErrorMessage;

    try {
      success = await authProvider.loginWithIdentifierAndPassword(
        identifier: identifier,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
        explicitErrorMessage = 'আপনার দেওয়া পাসওয়ার্ড সঠিক নয়!';
      } else if (e.code == 'user-not-found') {
        explicitErrorMessage = _loginTabIndex == 0
            ? 'এই জিমেইল এড্রেসে কোনো একাউন্ট পাওয়া যায়নি!'
            : 'এই মোবাইল নম্বরে কোনো একাউন্ট পাওয়া যায়নি!';
      } else if (e.code == 'invalid-email') {
        explicitErrorMessage = 'জিমেইল এড্রেসটি সঠিক নয়!';
      } else if (e.code == 'network-request-failed') {
        explicitErrorMessage = 'ইন্টারনেট সংযোগ চেক করুন এবং পুনরায় চেষ্টা করুন।';
      } else if (e.code == 'too-many-requests') {
        explicitErrorMessage = 'অতিরিক্ত ভুল চেষ্টার কারণে সাময়িকভাবে ব্লক করা হয়েছে। কিছুক্ষণ পর আবার চেষ্টা করুন।';
      } else if (e.code == 'user-disabled') {
        explicitErrorMessage = 'এই একাউন্টটি সাময়িকভাবে নিষ্ক্রিয় রয়েছে।';
      } else {
        explicitErrorMessage = e.message ?? 'আপনার দেওয়া পাসওয়ার্ড সঠিক নয় অথবা একাউন্টটি পাওয়া যায়নি!';
      }
    } catch (e) {
      explicitErrorMessage = e.toString().replaceFirst('Exception: ', '');
    } finally {
      // লোডিং ডায়ালগ সাথে সাথে ডিসমিস/পপ নিশ্চিত করা
      if (isLoaderShowing && mounted) {
        Navigator.of(context, rootNavigator: true).pop();
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
              builder: (_) => const MainNavigationScreen(initialIndex: 4),
            ),
            (route) => false,
          );
        },
      );
    } else {
      final msg = explicitErrorMessage ?? authProvider.errorMessage ?? 'আপনার দেওয়া পাসওয়ার্ড সঠিক নয় অথবা একাউন্টটি পাওয়া যায়নি!';
      showAppWarningDialog(
        context,
        title: 'ব্যর্থ হয়েছে!',
        message: msg,
      );
    }
  }

  void _openForgotGmailDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (dialogCtx) => _ForgotGmailDialog(
        onGmailRecovered: (recoveredEmail) {
          setState(() {
            _loginTabIndex = 0;
            _identifierController.text = recoveredEmail;
            _isIdentifierValid = true;
          });
        },
      ),
    );
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
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _loginTabIndex == 0 ? 'জিমেইল অ্যাড্রেস *' : 'মোবাইল নম্বর (১১ ডিজিট) *',
                              style: const TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            TextButton(
                              onPressed: () => _openForgotGmailDialog(context),
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.zero,
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: const Text(
                                'জিমেইল ভুলে গেছেন?',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                          ],
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
                                ],
                              ),
                            ),
                          ],

                          const SizedBox(height: 22),

                        // সাইন-ইন বাটন (Sign In Button)
                        Container(
                          width: double.infinity,
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
                          InkWell(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const PrivacyPolicyScreen(),
                                ),
                              );
                            },
                            borderRadius: BorderRadius.circular(6),
                            child: const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              child: Text(
                                'গোপনীয়তা নীতি',
                                style: TextStyle(
                                  fontSize: 12.5,
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

/// ২ ও ৩. "জিমেইল ভুলে গেছেন?" ডায়ালগ মডিউল ও ১ ঘণ্টার রেট-লিমিট পাসওয়ার্ড রিসেট
class _ForgotGmailDialog extends StatefulWidget {
  final ValueChanged<String>? onGmailRecovered;

  const _ForgotGmailDialog({this.onGmailRecovered});

  @override
  State<_ForgotGmailDialog> createState() => _ForgotGmailDialogState();
}

class _ForgotGmailDialogState extends State<_ForgotGmailDialog> {
  final TextEditingController _phoneController = TextEditingController();
  bool _isSearching = false;
  bool _isSendingReset = false;
  String? _foundFullEmail;
  String? _maskedEmail;
  String? _userDocId;
  int? _cooldownRemainingMinutes;
  String? _errorMessage;

  static const TextStyle _dialogInputTextStyle = TextStyle(
    fontFamily: 'Roboto',
    fontSize: 15.0,
    height: 1.25,
    fontWeight: FontWeight.w500,
    color: AppColors.textPrimary,
  );

  static const StrutStyle _dialogInputStrutStyle = StrutStyle(
    fontFamily: 'Roboto',
    fontSize: 15.0,
    height: 1.25,
    forceStrutHeight: true,
  );

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  // ইমেইলের মাঝখানের ৪-৫টি অক্ষর মাস্কিং (****) করা
  String _maskEmail(String email) {
    final clean = email.trim().toLowerCase();
    final atIndex = clean.indexOf('@');
    if (atIndex <= 1) return clean;
    final namePart = clean.substring(0, atIndex);
    final domainPart = clean.substring(atIndex);

    if (namePart.length <= 2) {
      return '${namePart[0]}****$domainPart';
    } else if (namePart.length <= 4) {
      return '${namePart[0]}****${namePart[namePart.length - 1]}$domainPart';
    } else {
      final prefix = namePart.substring(0, 2);
      final suffix = namePart.substring(namePart.length - 1);
      return '$prefix****$suffix$domainPart';
    }
  }

  Future<void> _searchGmailByPhone() async {
    final phone = _phoneController.text.trim();
    final cleanPhone = phone.replaceAll(RegExp(r'[^0-9]'), '');

    if (cleanPhone.length != 11 || !cleanPhone.startsWith('01')) {
      setState(() {
        _errorMessage = 'সঠিক ১১ ডিজিটের বাংলাদেশী মোবাইল নম্বর লিখুন (যেমন: 017XXXXXXXX)';
      });
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() {
      _isSearching = true;
      _errorMessage = null;
      _foundFullEmail = null;
      _maskedEmail = null;
      _cooldownRemainingMinutes = null;
    });

    try {
      final altPhone = '+88$cleanPhone';
      QuerySnapshot<Map<String, dynamic>> query = await FirebaseFirestore.instance
          .collection('users')
          .where('phone', isEqualTo: cleanPhone)
          .limit(1)
          .get()
          .timeout(const Duration(seconds: 8));

      if (query.docs.isEmpty) {
        query = await FirebaseFirestore.instance
            .collection('users')
            .where('phone', isEqualTo: altPhone)
            .limit(1)
            .get()
            .timeout(const Duration(seconds: 8));
      }

      if (query.docs.isEmpty) {
        if (mounted) {
          setState(() {
            _isSearching = false;
            _errorMessage = 'এই মোবাইল নম্বরে কোনো নিবন্ধিত একাউন্ট পাওয়া যায়নি!';
          });
        }
        return;
      }

      final doc = query.docs.first;
      final data = doc.data();
      final email = (data['email'] as String?)?.trim();

      if (email == null || email.isEmpty) {
        if (mounted) {
          setState(() {
            _isSearching = false;
            _errorMessage = 'এই একাউন্টে কোনো নিবন্ধিত জিমেইল যুক্ত নেই!';
          });
        }
        return;
      }

      // ১ ঘণ্টার কঠোর রেট-লিমিট (Rate Limiting) যাচাই
      int? remainingMinutes;
      final lastResetRaw = data['lastPasswordReset'];
      DateTime? lastReset;
      if (lastResetRaw is Timestamp) {
        lastReset = lastResetRaw.toDate();
      } else if (lastResetRaw is String) {
        lastReset = DateTime.tryParse(lastResetRaw);
      }

      if (lastReset != null) {
        final diff = DateTime.now().difference(lastReset);
        if (diff.inMinutes < 60) {
          remainingMinutes = 60 - diff.inMinutes;
        }
      }

      if (mounted) {
        setState(() {
          _isSearching = false;
          _foundFullEmail = email;
          _maskedEmail = _maskEmail(email);
          _userDocId = doc.id;
          _cooldownRemainingMinutes = remainingMinutes;
          _errorMessage = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSearching = false;
          _errorMessage = 'তথ্য অনুসন্ধানে সমস্যা হয়েছে। অনুগ্রহ করে ইন্টারনেট সংযোগ চেক করুন।';
        });
      }
    }
  }

  Future<void> _sendPasswordResetEmail() async {
    if (_foundFullEmail == null || _userDocId == null) return;

    if (_cooldownRemainingMinutes != null && _cooldownRemainingMinutes! > 0) {
      final bnMin = BanglaNumberConverter.toBangla(_cooldownRemainingMinutes.toString());
      showAppWarningDialog(
        context,
        title: 'অপেক্ষা করুন!',
        message: 'আপনি সম্প্রতি পাসওয়ার্ড রিসেট লিংক পাঠিয়েছেন। নতুন রিকোয়েস্টের জন্য অনুগ্রহ করে আরো $bnMin মিনিট অপেক্ষা করুন।',
      );
      return;
    }

    setState(() {
      _isSendingReset = true;
    });

    try {
      // Firebase Auth দিয়ে সরাসরি পাসওয়ার্ড রিসেট লিংক প্রেরণ
      await FirebaseAuth.instance.sendPasswordResetEmail(email: _foundFullEmail!);

      // ফায়ারস্টোরে টাইমস্ট্যাম্প সংরক্ষণ
      await FirebaseFirestore.instance.collection('users').doc(_userDocId!).update({
        'lastPasswordReset': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      setState(() {
        _isSendingReset = false;
        _cooldownRemainingMinutes = 60;
      });

      final recovered = _foundFullEmail!;
      final masked = _maskedEmail ?? recovered;

      Navigator.pop(context); // ডায়ালগ ক্লোজ

      widget.onGmailRecovered?.call(recovered);

      if (context.mounted) {
        showAppSuccessDialog(
          context,
          title: 'রিসেট লিঙ্ক পাঠানো হয়েছে!',
          message: 'আপনার ($masked) জিমেইল ঠিকানায় অফিশিয়াল পাসওয়ার্ড রিসেট লিংক পাঠানো হয়েছে। ইনবক্স চেক করে নতুন পাসওয়ার্ড নির্ধারণ করুন।',
        );
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) setState(() => _isSendingReset = false);
      if (!context.mounted) return;
      String errMsg = 'পাসওয়ার্ড রিসেট ইমেইল পাঠানো সম্ভব হয়নি।';
      if (e.code == 'user-not-found') {
        errMsg = 'এই জিমেইল ঠিকানায় কোনো একাউন্ট পাওয়া যায়নি!';
      } else if (e.code == 'too-many-requests') {
        errMsg = 'অতিরিক্ত চেষ্টার কারণে সাময়িকভাবে ব্লক করা হয়েছে। কিছুক্ষণ পর চেষ্টা করুন।';
      } else if (e.code == 'network-request-failed') {
        errMsg = 'ইন্টারনেট সংযোগ চেক করুন এবং পুনরায় চেষ্টা করুন।';
      }
      showAppWarningDialog(context, title: 'ব্যর্থ হয়েছে!', message: errMsg);
    } catch (e) {
      if (mounted) setState(() => _isSendingReset = false);
      if (!context.mounted) return;
      showAppWarningDialog(context, title: 'ব্যর্থ হয়েছে!', message: 'ত্রুটি ঘটেছে: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      elevation: 8,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header Row with Close Icon
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F5E9),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.mark_email_unread_rounded, color: AppColors.primary, size: 22),
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        'জিমেইল পুনরুদ্ধার',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryDark,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: AppColors.textSecondary, size: 22),
                    onPressed: () => Navigator.pop(context),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              const Text(
                'আপনার একাউন্টে ব্যবহৃত ১১ ডিজিটের মোবাইল নম্বরটি লিখুন:',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                  height: 1.35,
                ),
              ),

              const SizedBox(height: 12),

              // Mobile Number Input Field
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                style: _dialogInputTextStyle,
                strutStyle: _dialogInputStrutStyle,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(11),
                ],
                decoration: InputDecoration(
                  isDense: true,
                  hintText: '01XXXXXXXXX',
                  hintStyle: const TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: 15.0,
                    color: AppColors.textMuted,
                    height: 1.25,
                  ),
                  prefixIcon: const Icon(Icons.phone_android_rounded, color: AppColors.primary, size: 22),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
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
              ),

              const SizedBox(height: 12),

              // Search Button
              SizedBox(
                height: 44,
                child: ElevatedButton.icon(
                  onPressed: _isSearching ? null : _searchGmailByPhone,
                  icon: _isSearching
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Icon(Icons.search_rounded, color: Colors.white, size: 19),
                  label: Text(
                    _isSearching ? 'অনুসন্ধান চলছে...' : 'জিমেইল খুঁজুন',
                    style: const TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 1,
                  ),
                ),
              ),

              // Error Box
              if (_errorMessage != null) ...[
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFEBEE),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFFFCDD2)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline_rounded, color: AppColors.alertCritical, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(
                            fontSize: 12.5,
                            color: AppColors.alertCritical,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // Found Email Result Box
              if (_foundFullEmail != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F8F1),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFA5D6A7), width: 1.2),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.check_circle_rounded, color: Color(0xFF2E7D32), size: 18),
                          SizedBox(width: 6),
                          Text(
                            'নিবন্ধিত জিমেইল পাওয়া গেছে:',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1B5E20),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFC8E6C9)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.email_outlined, color: AppColors.primary, size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _maskedEmail ?? '',
                                style: const TextStyle(
                                  fontSize: 15.5,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1B5E20),
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                            const Icon(Icons.lock_outline_rounded, color: AppColors.textMuted, size: 16),
                          ],
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'নিরাপত্তার স্বার্থে ইমেইলের মাঝের অক্ষরগুলো গোপন রাখা হয়েছে।',
                        style: TextStyle(
                          fontSize: 11.5,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                // Rate limiting Cooldown warning OR Send Reset Email Button
                if (_cooldownRemainingMinutes != null && _cooldownRemainingMinutes! > 0) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF8E1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFFFE082)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.timer_outlined, color: Color(0xFFF57C00), size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'আপনি সম্প্রতি পাসওয়ার্ড রিসেট লিঙ্ক পাঠিয়েছেন। নতুন রিকোয়েস্ট পাঠাতে আরো ${BanglaNumberConverter.toBangla(_cooldownRemainingMinutes.toString())} মিনিট অপেক্ষা করতে হবে।',
                            style: const TextStyle(
                              fontSize: 12.5,
                              color: Color(0xFFE65100),
                              fontWeight: FontWeight.w600,
                              height: 1.35,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  Container(
                    height: 46,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF2E7D32), Color(0xFF1B5E20)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF2E7D32).withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: ElevatedButton.icon(
                      onPressed: _isSendingReset ? null : _sendPasswordResetEmail,
                      icon: _isSendingReset
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : const Icon(Icons.send_rounded, color: Colors.white, size: 18),
                      label: Text(
                        _isSendingReset ? 'লিঙ্ক পাঠানো হচ্ছে...' : 'পাসওয়ার্ড রিসেট মেইল পাঠান',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }
}
