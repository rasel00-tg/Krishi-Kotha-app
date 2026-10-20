import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/widgets/custom_app_bar.dart';
import '../../core/widgets/custom_button.dart';
import '../../core/utils/bangla_number_converter.dart';
import '../../providers/auth_provider.dart';
import 'profile_setup_screen.dart';

class OtpVerificationScreen extends StatefulWidget {
  final String phoneNumber;

  const OtpVerificationScreen({
    super.key,
    required this.phoneNumber,
  });

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final TextEditingController _otpController = TextEditingController();

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  void _verify() async {
    final code = _otpController.text.trim();
    if (code.length < 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('অনুগ্রহ করে সঠিক কোড দিন')),
      );
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.verifyOtp(code, widget.phoneNumber);
    if (success && mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const ProfileSetupScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const CustomAppBar(title: 'ওটিপি যাচাই'),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.mark_email_read_outlined,
                  size: 48,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'যাচাইকরণ কোড লিখুন',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'আপনার মোবাইল নম্বর ${BanglaNumberConverter.toBangla(widget.phoneNumber)} এ একটি ওটিপি কোড পাঠানো হয়েছে',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 15,
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 32),

              // OTP Input Field
              Card(
                elevation: 1.5,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: const BorderSide(color: AppColors.border),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      TextField(
                        controller: _otpController,
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        maxLength: 6,
                        style: const TextStyle(
                          fontSize: 28,
                          letterSpacing: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryDark,
                        ),
                        decoration: const InputDecoration(
                          counterText: '',
                          hintText: '• • • • • •',
                          hintStyle: TextStyle(
                            fontSize: 24,
                            letterSpacing: 10,
                            color: AppColors.textMuted,
                          ),
                        ),
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
                        text: AppStrings.verifyOtp,
                        onPressed: _verify,
                        isLoading: authProvider.isLoading,
                        icon: Icons.check_circle_outline,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),
              TextButton.icon(
                onPressed: () {
                  authProvider.sendOtp(widget.phoneNumber, () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('পুনরায় কোড পাঠানো হয়েছে')),
                    );
                  });
                },
                icon: const Icon(Icons.refresh_rounded, color: AppColors.primary),
                label: const Text(
                  AppStrings.resendOtp,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
