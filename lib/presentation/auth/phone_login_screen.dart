import 'package:flutter/material.dart';
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
  final TextEditingController _identifierController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _obscurePassword = true;
  bool _rememberMe = true;
  bool _isIdentifierValid = false;

  static const String _prefRememberKey = 'krishi_kotha_remember_me';
  static const String _prefIdentifierKey = 'krishi_kotha_remembered_identifier';

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
      if (mounted) {
        setState(() {
          _rememberMe = remember;
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
    // Check if input is valid Email or valid BD Phone Number
    final isEmail = text.contains('@') && text.contains('.');
    final cleanPhone = text.replaceAll(RegExp(r'[^0-9]'), '');
    final isPhone = (cleanPhone.length == 11 && cleanPhone.startsWith('01')) ||
        (cleanPhone.length == 13 && cleanPhone.startsWith('8801')) ||
        cleanPhone.length >= 10;

    final isValid = isEmail || isPhone;
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

    // Persist Remember Me
    try {
      final prefs = await SharedPreferences.getInstance();
      if (_rememberMe) {
        await prefs.setString(_prefIdentifierKey, identifier);
        await prefs.setBool(_prefRememberKey, true);
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
                                  'নিবন্ধিত ইমেইলে পাসওয়ার্ড রিসেট লিংক পাঠানো হবে',
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
                        'আপনার নিবন্ধিত ইমেইল অ্যাড্রেস *',
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
                        style: const TextStyle(fontSize: 15),
                        decoration: InputDecoration(
                          hintText: 'example@gmail.com',
                          prefixIcon: const Icon(Icons.email_outlined, color: AppColors.primary, size: 22),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return 'অনুগ্রহ করে ইমেইল ঠিকানা দিন';
                          }
                          if (!val.contains('@') || !val.contains('.')) {
                            return 'সঠিক ইমেইল ফরম্যাট দিন';
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
                                          'আপনার ইমেইলে একটি অফিসিয়াল পাসওয়ার্ড রিসেট লিঙ্ক পাঠানো হয়েছে। ইনবক্স চেক করে নতুন পাসওয়ার্ড নির্ধারণ করুন।',
                                        ),
                                        backgroundColor: AppColors.primary,
                                        duration: Duration(seconds: 5),
                                        behavior: SnackBarBehavior.floating,
                                      ),
                                    );
                                  } else {
                                    setModalState(() {
                                      isSending = false;
                                      resetError = authProvider.errorMessage ?? 'রিসেট লিংক পাঠাতে সমস্যা হয়েছে।';
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
                  // ================= ১. শীর্ষে সম্ভাষণ (TOP GREETING) =================
                  const Text(
                    'স্বাগতম!',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                      letterSpacing: 0.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'চালিয়ে যেতে লগইন করুন',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14.5,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ================= ২. মাঝে ব্র্যান্ডিং (BRAND LOGO & APP NAME) =================
                  Container(
                    width: 82,
                    height: 82,
                    decoration: BoxDecoration(
                      color: AppColors.primaryContainer,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.primaryLight, width: 2.5),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.14),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(10.0),
                        child: Image.asset(
                          'assets/icons/pnglogo.png',
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => const Icon(
                            Icons.eco_rounded,
                            size: 46,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  const Text(
                    'কৃষি কথা',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryDark,
                      letterSpacing: 0.3,
                    ),
                  ),

                  const SizedBox(height: 24),

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
                        // আইডেন্টিফায়ার ফিল্ড (Username / Email / Mobile)
                        const Text(
                          'ইমেইল বা মোবাইল নম্বর *',
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 7),
                        TextFormField(
                          controller: _identifierController,
                          keyboardType: TextInputType.emailAddress,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                          decoration: InputDecoration(
                            hintText: 'ইমেইল বা মোবাইল নম্বর দিন...',
                            hintStyle: const TextStyle(
                              fontSize: 14,
                              color: AppColors.textMuted,
                              fontWeight: FontWeight.normal,
                            ),
                            prefixIcon: const Icon(
                              Icons.email_outlined,
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
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
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
                              return 'অনুগ্রহ করে ইমেইল বা মোবাইল নম্বর লিখুন';
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
                          style: const TextStyle(
                            fontSize: 15,
                          ),
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
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
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
