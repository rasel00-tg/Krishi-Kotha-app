import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/widgets/custom_button.dart';
import '../../providers/auth_provider.dart';
import '../navigation/main_navigation_screen.dart';
import 'registration_multi_step_screen.dart';

class PhoneLoginScreen extends StatefulWidget {
  const PhoneLoginScreen({super.key});

  @override
  State<PhoneLoginScreen> createState() => _PhoneLoginScreenState();
}

class _PhoneLoginScreenState extends State<PhoneLoginScreen> {
  final TextEditingController _identifierController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _identifierController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submitLogin() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final identifier = _identifierController.text.trim();
    final password = _passwordController.text;

    final success = await authProvider.loginWithIdentifierAndPassword(
      identifier: identifier,
      password: password,
    );

    if (success && mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
      );
    }
  }

  void _onGuestMode() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await authProvider.loginAsGuest();
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
      );
    }
  }

  /// Forgot password bottom sheet / dialog
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
                      CustomButton(
                        text: 'রিসেট লিঙ্ক পাঠান',
                        isLoading: isSending,
                        icon: Icons.send_rounded,
                        onPressed: () async {
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

    return Scaffold(
      backgroundColor: AppColors.background,
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
                  // Logo / App Icon Badge
                  Container(
                    width: 96,
                    height: 96,
                    decoration: BoxDecoration(
                      color: AppColors.primaryContainer,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.primaryLight, width: 2.5),
                      boxShadow: const [
                        BoxShadow(
                          color: AppColors.cardShadow,
                          blurRadius: 16,
                          offset: Offset(0, 6),
                        )
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Image.asset(
                          'assets/icons/pnglogo.png',
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => const Icon(
                            Icons.eco_rounded,
                            size: 56,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Title & Tagline
                  const Text(
                    AppStrings.appName,
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryDark,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    AppStrings.appTagline,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Card for Input
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: const BorderSide(color: AppColors.border, width: 1),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(22.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'লগইন করুন',
                            style: TextStyle(
                              fontSize: 19,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'আপনার নিবন্ধিত ইমেইল বা মোবাইল নম্বর দিয়ে প্রবেশ করুন',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Dual Identifier Input (Email or Mobile)
                          const Text(
                            'ইমেইল বা মোবাইল নম্বর *',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                          ),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _identifierController,
                            keyboardType: TextInputType.text,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                            decoration: InputDecoration(
                              hintText: 'user@gmail.com অথবা ০১৭১XXXXXXX',
                              hintStyle: const TextStyle(
                                fontSize: 14,
                                color: AppColors.textMuted,
                              ),
                              prefixIcon: const Icon(Icons.person_outline_rounded, color: AppColors.primary, size: 22),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            validator: (val) {
                              if (val == null || val.trim().isEmpty) {
                                return 'অনুগ্রহ করে ইমেইল বা মোবাইল নম্বর লিখুন';
                              }
                              return null;
                            },
                          ),

                          const SizedBox(height: 16),

                          // Password Input
                          const Text(
                            'পাসওয়ার্ড *',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                          ),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            style: const TextStyle(
                              fontSize: 15,
                            ),
                            decoration: InputDecoration(
                              hintText: '••••••••',
                              prefixIcon: const Icon(Icons.lock_outline_rounded, color: AppColors.primary, size: 22),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                  color: AppColors.textMuted,
                                  size: 20,
                                ),
                                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                              ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            validator: (val) {
                              if (val == null || val.isEmpty) {
                                return 'পাসওয়ার্ড লিখুন';
                              }
                              return null;
                            },
                          ),

                          // Forgot Password Button
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: _showForgotPasswordDialog,
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 0),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: const Text(
                                'পাসওয়ার্ড ভুলে গেছেন?',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                          ),

                          if (authProvider.errorMessage != null) ...[
                            const SizedBox(height: 10),
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

                          const SizedBox(height: 20),
                          CustomButton(
                            text: 'লগইন করুন',
                            onPressed: _submitLogin,
                            isLoading: authProvider.isLoading,
                            icon: Icons.login_rounded,
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 18),

                  // Create New Account Button -> 2-Step Registration
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.primaryLight, width: 1.2),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x08000000),
                          blurRadius: 8,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () {
                          authProvider.clearError();
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const RegistrationMultiStepScreen(),
                            ),
                          );
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Icon(Icons.person_add_alt_1_rounded, color: AppColors.primary, size: 20),
                              SizedBox(width: 8),
                              Text(
                                'নতুন অ্যাকাউন্ট খুলুন (সাইন-আপ)',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Guest / Browse Mode
                  CustomButton(
                    text: AppStrings.guestLogin,
                    onPressed: _onGuestMode,
                    isOutlined: true,
                    icon: Icons.travel_explore_rounded,
                  ),

                  const SizedBox(height: 24),
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
