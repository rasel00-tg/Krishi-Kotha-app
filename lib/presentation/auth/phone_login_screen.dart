import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/widgets/custom_button.dart';
import '../../providers/auth_provider.dart';
import 'otp_verification_screen.dart';
import '../navigation/main_navigation_screen.dart';

class PhoneLoginScreen extends StatefulWidget {
  const PhoneLoginScreen({super.key});

  @override
  State<PhoneLoginScreen> createState() => _PhoneLoginScreenState();
}

class _PhoneLoginScreenState extends State<PhoneLoginScreen> {
  final TextEditingController _phoneController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      final phone = _phoneController.text.trim();
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      authProvider.sendOtp(phone, () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => OtpVerificationScreen(phoneNumber: phone),
          ),
        );
      });
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

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Logo / App Icon Badge
                  Container(
                    width: 100,
                    height: 100,
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
                            size: 58,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Title & Tagline
                  const Text(
                    AppStrings.appName,
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryDark,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    AppStrings.appTagline,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 36),

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
                            AppStrings.loginTitle,
                            style: TextStyle(
                              fontSize: 19,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            AppStrings.loginSubtitle,
                            style: TextStyle(
                              fontSize: 14,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 22),

                          // Phone Input
                          TextFormField(
                            controller: _phoneController,
                            keyboardType: TextInputType.phone,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                            ),
                            decoration: InputDecoration(
                              prefixIcon: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                margin: const EdgeInsets.only(right: 8),
                                decoration: const BoxDecoration(
                                  border: Border(right: BorderSide(color: AppColors.border)),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      '🇧🇩 +880',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              hintText: '১৭১XXXXXXX',
                              hintStyle: const TextStyle(
                                fontSize: 16,
                                color: AppColors.textMuted,
                                letterSpacing: 0.5,
                              ),
                            ),
                            validator: (val) {
                              if (val == null || val.trim().isEmpty) {
                                return 'অনুগ্রহ করে মোবাইল নম্বর লিখুন';
                              }
                              final clean = val.replaceAll(RegExp(r'[^0-9]'), '');
                              if (clean.length < 10) {
                                return 'সঠিক ১১ ডিজিটের মোবাইল নম্বর দিন';
                              }
                              return null;
                            },
                          ),

                          if (authProvider.errorMessage != null) ...[
                            const SizedBox(height: 12),
                            Text(
                              authProvider.errorMessage!,
                              style: const TextStyle(
                                color: AppColors.alertCritical,
                                fontSize: 13,
                              ),
                            ),
                          ],

                          const SizedBox(height: 24),
                          CustomButton(
                            text: AppStrings.sendOtp,
                            onPressed: _submit,
                            isLoading: authProvider.isLoading,
                            icon: Icons.sms_outlined,
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Guest / Browse Mode
                  CustomButton(
                    text: AppStrings.guestLogin,
                    onPressed: _onGuestMode,
                    isOutlined: true,
                    icon: Icons.travel_explore_rounded,
                  ),

                  const SizedBox(height: 28),
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
