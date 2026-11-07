import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/bangla_number_converter.dart';
import '../../core/widgets/app_warning_dialog.dart';
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

  // ফিক্সড ও অপরিবর্তনশীল ফন্ট স্টাইল (টাইপিংয়ের সময় কোনো ঝাঁকুনি বা সাইজ পরিবর্তন হবে না)
  static const TextStyle _inputTextStyle = TextStyle(
    fontSize: 15.0,
    height: 1.2,
    fontWeight: FontWeight.normal,
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
    final email = _emailController.text.trim().toLowerCase();

    // কাস্টম লোগোযুক্ত অ্যালার্ট ডায়ালগ ভ্যালিডেশন
    if (email.isEmpty) {
      showAppWarningDialog(
        context,
        message: 'অনুগ্রহ করে আপনার নিবন্ধিত @gmail.com জিমেইল এড্রেসটি লিখুন!',
      );
      return;
    }

    if (!email.endsWith('@gmail.com') ||
        !RegExp(r'^[a-zA-Z0-9._%+-]+@gmail\.com$', caseSensitive: false).hasMatch(email)) {
      showAppWarningDialog(
        context,
        message: 'শুধুমাত্র বৈধ @gmail.com জিমেইল এড্রেস গ্রহণযোগ্য (যেমন: user@gmail.com)!',
      );
      return;
    }

    // ১ ঘণ্টার কঠোর রেট-লিমিট (Rate Limiting) যাচাই
    try {
      final query = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: email)
          .limit(1)
          .get()
          .timeout(const Duration(seconds: 6));

      if (query.docs.isNotEmpty) {
        final docData = query.docs.first.data();
        final lastResetRaw = docData['lastPasswordReset'];
        DateTime? lastReset;
        if (lastResetRaw is Timestamp) {
          lastReset = lastResetRaw.toDate();
        } else if (lastResetRaw is String) {
          lastReset = DateTime.tryParse(lastResetRaw);
        }
        if (lastReset != null) {
          final diff = DateTime.now().difference(lastReset);
          if (diff.inMinutes < 60) {
            final remainingMin = 60 - diff.inMinutes;
            final bnMin = BanglaNumberConverter.toBangla(remainingMin.toString());
            showAppWarningDialog(
              context,
              title: 'অপেক্ষা করুন!',
              message: 'আপনি সম্প্রতি পাসওয়ার্ড রিসেট লিংক পাঠিয়েছেন। নতুন রিকোয়েস্ট পাঠাতে আরো $bnMin মিনিট অপেক্ষা করতে হবে।',
            );
            return;
          }
        }
      }
    } catch (_) {}

    setState(() => _isSending = true);

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.sendPasswordResetEmail(email);

    if (!mounted) return;
    setState(() => _isSending = false);

    if (success) {
      // ফায়ারস্টোরে টাইমস্ট্যাম্প সংরক্ষণ
      try {
        final query = await FirebaseFirestore.instance
            .collection('users')
            .where('email', isEqualTo: email)
            .limit(1)
            .get();
        if (query.docs.isNotEmpty) {
          await FirebaseFirestore.instance.collection('users').doc(query.docs.first.id).update({
            'lastPasswordReset': FieldValue.serverTimestamp(),
          });
        }
      } catch (_) {}
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 55,
                height: 55,
                child: Image.asset('assets/icons/pnglogo.png', fit: BoxFit.contain),
              ),
              const SizedBox(height: 12),
              const Text(
                'রিসেট লিঙ্ক পাঠানো হয়েছে',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary),
              ),
              const SizedBox(height: 8),
              const Text(
                'আপনার জিমেইলে একটি অফিশিয়াল পাসওয়ার্ড রিসেট লিঙ্ক পাঠানো হয়েছে। ইনবক্স চেক করে নতুন পাসওয়ার্ড নির্ধারণ করুন।',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: AppColors.textPrimary, height: 1.4),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 44,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('ঠিক আছে', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      );
    } else {
      showAppWarningDialog(
        context,
        message: authProvider.errorMessage ?? 'রিসেট লিঙ্ক পাঠাতে সমস্যা হয়েছে। অনুগ্রহ করে সঠিক জিমেইল দিয়ে পুনরায় চেষ্টা করুন।',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'পাসওয়ার্ড রিসেট',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
          tooltip: 'ফিরে যান',
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 10),

                // ================= লোগো (NO CONTAINER, NO BORDER, NO SHADOW) =================
                Center(
                  child: SizedBox(
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
                ),

                const SizedBox(height: 12),

                // হেডিং
                const Center(
                  child: Text(
                    'পাসওয়ার্ড রিসেট',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                const Center(
                  child: Text(
                    'আপনার নিবন্ধিত জিমেইল এড্রেস লিখুন, একটি পাসওয়ার্ড রিসেট লিঙ্ক পাঠানো হবে',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13.5,
                      color: AppColors.textSecondary,
                      height: 1.35,
                    ),
                  ),
                ),

                const SizedBox(height: 30),

                // ইনপুট ফিল্ড (Full-Width Edge-to-Edge)
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
                    isDense: true,
                    hintText: 'example@gmail.com',
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
                ),

                const SizedBox(height: 28),

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

                const SizedBox(height: 24),

                // Back to Login Link
                Center(
                  child: TextButton.icon(
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
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
