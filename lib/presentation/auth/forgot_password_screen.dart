import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/auth_provider.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final TextEditingController _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _isSending = false;
  String? _errorMessage;

  static const TextStyle _inputTextStyle = TextStyle(
    fontSize: 15.0,
    height: 1.2,
    fontWeight: FontWeight.w500,
    color: AppColors.textPrimary,
  );

  static const StrutStyle _inputStrutStyle = StrutStyle(
    fontSize: 15.0,
    height: 1.2,
    forceStrutHeight: true,
  );

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submitReset() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSending = true;
      _errorMessage = null;
    });

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final email = _emailController.text.trim().toLowerCase();

    final success = await authProvider.sendPasswordResetEmail(email);

    if (!mounted) return;

    if (success) {
      setState(() => _isSending = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'আপনার জিমেইলে একটি অফিশিয়াল পাসওয়ার্ড রিসেট লিঙ্ক পাঠানো হয়েছে। ইনবক্স চেক করে নতুন পাসওয়ার্ড নির্ধারণ করুন।',
          ),
          backgroundColor: AppColors.primary,
          duration: Duration(seconds: 5),
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.pop(context);
    } else {
      setState(() {
        _isSending = false;
        _errorMessage = authProvider.errorMessage ?? 'রিসেট লিঙ্ক পাঠাতে সমস্যা হয়েছে। পুনরায় চেষ্টা করুন।';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7FAF7),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.symmetric(horizontal: 22.0, vertical: 12.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // ================= লোগো (NO CONTAINER, NO BORDER, NO SHADOW) =================
                  SizedBox(
                    width: 80,
                    height: 80,
                    child: Image.asset(
                      'assets/icons/pnglogo.png',
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.eco_rounded,
                        size: 70,
                        color: AppColors.primary,
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // হেডিং: "পাসওয়ার্ড রিসেট"
                  const Text(
                    'পাসওয়ার্ড রিসেট',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                      letterSpacing: 0.2,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'আপনার নিবন্ধিত জিমেইল এড্রেস লিখুন, একটি পাসওয়ার্ড রিসেট লিঙ্ক পাঠানো হবে',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13.5,
                      color: AppColors.textSecondary,
                      height: 1.35,
                    ),
                  ),

                  const SizedBox(height: 26),

                  // ফর্ম কার্ড
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
                    padding: const EdgeInsets.symmetric(horizontal: 22.0, vertical: 26.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'আপনার নিবন্ধিত জিমেইল এড্রেস *',
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          style: _inputTextStyle,
                          strutStyle: _inputStrutStyle,
                          decoration: InputDecoration(
                            hintText: 'example@gmail.com',
                            hintStyle: const TextStyle(
                              fontSize: 14,
                              color: AppColors.textMuted,
                            ),
                            prefixIcon: const Icon(
                              Icons.email_outlined,
                              color: AppColors.primary,
                              size: 22,
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
                            if (val == null || val.trim().isEmpty) {
                              return 'অনুগ্রহ করে জিমেইল এড্রেস লিখুন';
                            }
                            final email = val.trim().toLowerCase();
                            if (!email.endsWith('@gmail.com') ||
                                !RegExp(r'^[a-zA-Z0-9._%+-]+@gmail\.com$').hasMatch(email)) {
                              return 'শুধুমাত্র @gmail.com ইমেইল ঠিকানা গ্রহণযোগ্য (যেমন: user@gmail.com)';
                            }
                            return null;
                          },
                        ),

                        if (_errorMessage != null) ...[
                          const SizedBox(height: 14),
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
                                    _errorMessage!,
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

                        const SizedBox(height: 24),

                        // চওড়া "রিসেট লিঙ্ক পাঠান" বাটন
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
                            onPressed: _isSending ? null : _submitReset,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                            child: _isSending
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.2),
                                  )
                                : const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        'রিসেট লিঙ্ক পাঠান',
                                        style: TextStyle(
                                          fontSize: 15.5,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                      SizedBox(width: 8),
                                      Icon(Icons.send_rounded, color: Colors.white, size: 18),
                                    ],
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 22),

                  // Back to Login Link
                  TextButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back_rounded, size: 18, color: AppColors.primary),
                    label: const Text(
                      'লগইন পেজে ফিরে যান',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
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
