import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../providers/auth_provider.dart';
import '../navigation/main_navigation_screen.dart';
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
    fontSize: 16,
    height: 1.25,
    fontWeight: FontWeight.w500,
    color: AppColors.textPrimary,
  );

  static const StrutStyle _inputStrutStyle = StrutStyle(
    fontSize: 16,
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
    if (!_formKey.currentState!.validate()) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final identifier = _identifierController.text.trim();
    final password = _passwordController.text;

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

    final success = await authProvider.loginWithIdentifierAndPassword(
      identifier: identifier,
      password: password,
    );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('স্বাগতম! সফলভাবে লগইন সম্পন্ন হয়েছে।'),
          backgroundColor: AppColors.primary,
          duration: Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );

      if (!widget.isGatewayForMenu) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (_) => const MainNavigationScreen(initialIndex: 4),
          ),
          (route) => false,
        );
      }
    }
  }

  /// Forgot password bottom sheet dialog
  void _showForgotPasswordDialog() {
    final resetEmailController = TextEditingController();
    final resetFormKey = GlobalKey<FormState>();
    bool isSending = false;
    String? resetError;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (bottomSheetContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(bottomSheetContext).viewInsets.bottom,
              ),
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                child: Form(
                  key: resetFormKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(
                        child: Container(
                          width: 44,
                          height: 4,
                          decoration: BoxDecoration(
                            color: const Color(0xFFE0E0E0),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE8F5E9),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.lock_reset_rounded, color: AppColors.primary, size: 24),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'পাসওয়ার্ড পুনরুদ্ধার',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                Text(
                                  'নিবন্ধিত জিমেইলে পাসওয়ার্ড রিসেট লিঙ্ক পাঠানো হবে',
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
                      const SizedBox(height: 20),
                      const Text(
                        'আপনার নিবন্ধিত জিমেইল অ্যাড্রেস *',
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: resetEmailController,
                        keyboardType: TextInputType.emailAddress,
                        style: _inputTextStyle,
                        strutStyle: _inputStrutStyle,
                        decoration: InputDecoration(
                          hintText: 'example@gmail.com',
                          prefixIcon: const Icon(Icons.email_outlined, color: AppColors.primary, size: 22),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return 'অনুগ্রহ করে জিমেইল ঠিকানা দিন';
                          }
                          final email = val.trim().toLowerCase();
                          if (!email.endsWith('@gmail.com') ||
                              !RegExp(r'^[a-zA-Z0-9._%+-]+@gmail\.com$').hasMatch(email)) {
                            return 'শুধুমাত্র বৈধ @gmail.com ইমেইল ঠিকানা দিন';
                          }
                          return null;
                        },
                      ),
                      if (resetError != null) ...[
                        const SizedBox(height: 10),
                        Text(
                          resetError!,
                          style: const TextStyle(color: AppColors.alertCritical, fontSize: 13),
                        ),
                      ],
                      const SizedBox(height: 24),
                      SizedBox(
                        height: 48,
                        child: ElevatedButton.icon(
                          onPressed: isSending
                              ? null
                              : () async {
                                  if (!resetFormKey.currentState!.validate()) return;
                                  setModalState(() {
                                    isSending = true;
                                    resetError = null;
                                  });
                                  final authProvider = Provider.of<AuthProvider>(context, listen: false);
                                  final ok = await authProvider.sendPasswordResetEmail(resetEmailController.text.trim());
                                  if (ok) {
                                    Navigator.pop(bottomSheetContext);
                                    ScaffoldMessenger.of(this.context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'আপনার জিমেইলে একটি অফিশিয়াল পাসওয়ার্ড রিসেট লিঙ্ক পাঠানো হয়েছে। ইনবক্স চেক করে নতুন পাসওয়ার্ড নির্ধারণ করুন।',
                                        ),
                                        backgroundColor: AppColors.primary,
                                        duration: Duration(seconds: 5),
                                        behavior: SnackBarBehavior.floating,
                                      ),
                                    );
                                  } else {
                                    setModalState(() {
                                      isSending = false;
                                      resetError = authProvider.errorMessage ?? 'রিসেট লিঙ্ক পাঠাতে সমস্যা হয়েছে।';
                                    });
                                  }
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          icon: isSending
                              ? const SizedBox.shrink()
                              : const Icon(Icons.send_rounded, color: Colors.white, size: 18),
                          label: isSending
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                )
                              : const Text(
                                  'রিসেট লিঙ্ক পাঠান',
                                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                                ),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
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
                            hintText: _loginTabIndex == 0 ? 'example@gmail.com' : '01XXXXXXXXX',
                            hintStyle: const TextStyle(
                              fontSize: 14,
                              color: AppColors.textMuted,
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
                          style: _inputTextStyle,
                          strutStyle: _inputStrutStyle,
                          decoration: InputDecoration(
                            hintText: 'পাসওয়ার্ড লিখুন...',
                            hintStyle: const TextStyle(
                              fontSize: 14,
                              color: AppColors.textMuted,
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
                              onPressed: _showForgotPasswordDialog,
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
                            Navigator.push(
                              context,
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

                  // Footer info
                  const Text(
                    'কৃষি তথ্য সার্ভিস (AIS) ও কৃষি সম্প্রসারণ অধিদপ্তর সমর্থিত',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textMuted,
                    ),
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
