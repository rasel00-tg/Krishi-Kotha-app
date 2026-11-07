import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/utils/bangla_number_converter.dart';
import '../../core/widgets/app_warning_dialog.dart';

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
    fontFamily: 'Roboto',
    fontSize: 15.0,
    height: 1.25,
    fontWeight: FontWeight.normal,
    color: AppColors.textPrimary,
  );

  static const StrutStyle _inputStrutStyle = StrutStyle(
    fontFamily: 'Roboto',
    fontSize: 15.0,
    height: 1.25,
    forceStrutHeight: true,
  );

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _openForgotGmailDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (dialogCtx) => _ForgotGmailDialog(
        onGmailRecovered: (recoveredEmail) {
          setState(() {
            _emailController.text = recoveredEmail;
          });
        },
      ),
    );
  }

  Future<void> _submitReset() async {
    final email = _emailController.text.trim().toLowerCase();

    // ১. জিমেইল ফরম্যাট ভ্যালিডেশন
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

    FocusScope.of(context).unfocus();

    // ৪. ক্যাটাগরিভিত্তিক স্টেপ লোডিং ইন্ডিকেটর ডায়ালগ (Category-based Step Loading Dialog)
    final ValueNotifier<String> stepTitleNotifier = ValueNotifier<String>('তথ্য যাচাই করা হচ্ছে.....');
    bool isLoaderShowing = true;
    showDialog(
      context: context,
      barrierDismissible: true, // সেফটি: কোনো অবস্থাতেই যেন স্ক্রিন আনরেসপনসিভ হয়ে আটকে না থাকে
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
                                Icons.lock_reset_rounded,
                                color: AppColors.primary,
                                size: 48,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    ValueListenableBuilder<String>(
                      valueListenable: stepTitleNotifier,
                      builder: (context, title, _) {
                        return AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          child: Text(
                            title,
                            key: ValueKey(title),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 16.5,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                              letterSpacing: 0.3,
                            ),
                          ),
                        );
                      },
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

    bool isSuccess = false;
    String? explicitErrorMessage;
    String? explicitErrorTitle;

    try {
      // ধাপ ১: জিমেইল অস্তিত্ব যাচাইকরণ (Firestore Pre-Validation)
      final userQuery = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: email)
          .limit(1)
          .get()
          .timeout(const Duration(seconds: 8));

      // ক) একাউন্ট না পাওয়া গেলে:
      if (userQuery.docs.isEmpty) {
        explicitErrorTitle = 'একাউন্ট পাওয়া যায়নি!';
        explicitErrorMessage = 'এই জিমেইলে কোনো একাউন্ট পাওয়া যায়নি। অনুগ্রহ করে সঠিক জিমেইল দিন অথবা মোবাইল নম্বর দিয়ে খুঁজে নিন।';
        return;
      }

      final userDoc = userQuery.docs.first;
      final docData = userDoc.data();

      // খ) ১ ঘণ্টার কঠোর রেট-লিমিট (Rate Limiting) যাচাই
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
          explicitErrorTitle = 'রিকোয়েস্ট বাতিল করা হয়েছে';
          explicitErrorMessage = 'রিকোয়েস্ট বাতিল করা হয়েছে। আপনি প্রতি ঘণ্টায় ১ বার রিকোয়েস্ট পাঠাতে পারবেন। পুনরায় চেষ্টা করতে আর $bnMin মিনিট অপেক্ষা করুন।';
          return;
        }
      }

      // ধাপ ২: স্বয়ংক্রিয়ভাবে টেক্সট পরিবর্তন - "রিসেট লিংক পাঠানো হচ্ছে....."
      stepTitleNotifier.value = 'রিসেট লিংক পাঠানো হচ্ছে.....';
      await Future.delayed(const Duration(milliseconds: 400));

      // একাউন্ট বৈধ এবং কুলডাউন শেষ: Firebase Auth পাসওয়ার্ড রিসেট ইমেইল প্রেরণ
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);

      // ফায়ারস্টোরে টাইমস্ট্যাম্প সংরক্ষণ
      await FirebaseFirestore.instance.collection('users').doc(userDoc.id).update({
        'lastPasswordReset': FieldValue.serverTimestamp(),
      });

      isSuccess = true;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        explicitErrorTitle = 'একাউন্ট পাওয়া যায়নি!';
        explicitErrorMessage = 'এই জিমেইলে কোনো একাউন্ট পাওয়া যায়নি। অনুগ্রহ করে সঠিক জিমেইল দিন অথবা মোবাইল নম্বর দিয়ে খুঁজে নিন।';
      } else if (e.code == 'too-many-requests') {
        explicitErrorTitle = 'অপেক্ষা করুন!';
        explicitErrorMessage = 'অতিরিক্ত চেষ্টার কারণে সাময়িকভাবে ব্লক করা হয়েছে। কিছুক্ষণ পর চেষ্টা করুন।';
      } else if (e.code == 'network-request-failed') {
        explicitErrorTitle = 'নেটওয়ার্ক ত্রুটি';
        explicitErrorMessage = 'ইন্টারনেট সংযোগ চেক করুন এবং পুনরায় চেষ্টা করুন।';
      } else {
        explicitErrorTitle = 'ব্যর্থ হয়েছে!';
        explicitErrorMessage = 'পাসওয়ার্ড রিসেট ইমেইল পাঠানো সম্ভব হয়নি।';
      }
    } catch (e) {
      explicitErrorTitle = 'ত্রুটি';
      explicitErrorMessage = 'ত্রুটি ঘটেছে: $e';
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

    if (isSuccess) {
      // গ) সফল হলে: সবুজ অ্যানিমেটেড টিক (✓) চিহ্নসহ সাকসেস পপ-আপ
      showAppSuccessDialog(
        context,
        title: 'রিসেট লিঙ্ক পাঠানো হয়েছে!',
        message: 'পাসওয়ার্ড রিসেট লিংক সফলভাবে আপনার ইমেইলে পাঠানো হয়েছে।',
        autoDismiss: false,
        onConfirm: () {
          if (mounted) Navigator.pop(context);
        },
      );
    } else if (explicitErrorMessage != null) {
      showAppWarningDialog(
        context,
        title: explicitErrorTitle ?? 'সতর্কবার্তা',
        message: explicitErrorMessage,
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

                const SizedBox(height: 28),

                // ১. "পাসওয়ার্ড ভুলে গেছেন?" পেজে "জিমেইল ভুলে গেছেন?" বাটন ও ইনপুট ফিল্ড
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'আপনার নিবন্ধিত জিমেইল এড্রেস *',
                      style: TextStyle(
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
                      fontFamily: 'Roboto',
                      fontSize: 14.5,
                      color: AppColors.textMuted,
                      height: 1.25,
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

                const SizedBox(height: 30),

                // রিয়েল-টাইম ডেটা স্ট্রিম (StreamBuilder)
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

                    return Text(
                      appVer,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF9E9E9E),
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.2,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// ১ ও ৩. "পাসওয়ার্ড ভুলে গেছেন?" স্ক্রিনের কাস্টম "জিমেইল ভুলে গেছেন?" ডায়ালগ
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

  // ইমেইলের প্রথম ৩টি ও শেষের ৪টি অক্ষর দৃশ্যমান রেখে মাঝখানের সমস্ত অক্ষর মাস্কিং (****) করা
  String _maskEmail(String email) {
    final clean = email.trim().toLowerCase();
    final atIndex = clean.indexOf('@');
    if (atIndex <= 1) return clean;
    final namePart = clean.substring(0, atIndex);
    final domainPart = clean.substring(atIndex);

    if (namePart.length > 7) {
      final prefix = namePart.substring(0, 3);
      final suffix = namePart.substring(namePart.length - 4);
      return '$prefix****$suffix$domainPart';
    } else if (namePart.length > 4) {
      final prefix = namePart.substring(0, 2);
      final suffix = namePart.substring(namePart.length - 2);
      return '$prefix****$suffix$domainPart';
    } else if (namePart.length > 2) {
      return '${namePart[0]}****${namePart[namePart.length - 1]}$domainPart';
    } else {
      return '${namePart[0]}****$domainPart';
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
          _errorMessage = 'তথ্য অনুসন্ধানে সমস্যা হয়েছে। অনুগ্রহ করে ইন্টারনেট সংযোগ চেক করুন।';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSearching = false;
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
          message: 'আপনার ($masked) জিমেইল ঠিকানায় অফিশিয়াল পাসওয়ার্ড রিসেট লিংক পাঠানো হয়েছে। ইনবক্স অথবা স্প্যাম ফোল্ডার চেক করুন।',
          autoDismiss: false,
        );
      }
    } on FirebaseAuthException catch (e) {
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
      if (!context.mounted) return;
      showAppWarningDialog(context, title: 'ব্যর্থ হয়েছে!', message: 'ত্রুটি ঘটেছে: $e');
    } finally {
      if (mounted) {
        setState(() => _isSendingReset = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      elevation: 10,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 26),
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

              // Found Email Result Box (Modern, Spacious & Encrypted Verification Badge)
              if (_foundFullEmail != null) ...[
                const SizedBox(height: 18),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F8F1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFA5D6A7), width: 1.2),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x0A000000),
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.check_circle_rounded, color: Color(0xFF2E7D32), size: 19),
                          SizedBox(width: 8),
                          Text(
                            'নিবন্ধিত জিমেইল পাওয়া গেছে:',
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1B5E20),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFC8E6C9)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.email_outlined, color: AppColors.primary, size: 20),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                _maskedEmail ?? '',
                                style: const TextStyle(
                                  fontSize: 16.5,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1B5E20),
                                  letterSpacing: 0.6,
                                ),
                              ),
                            ),
                            const Icon(Icons.lock_rounded, color: Color(0xFF2E7D32), size: 18),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      // আধুনিক ও প্রফেশনাল ব্যাজ/ইনফো ট্যাগ
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F5E9),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFFA5D6A7)),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('🔒', style: TextStyle(fontSize: 12)),
                            SizedBox(width: 5),
                            Text(
                              'এনক্রিপ্টেড অ্যাকাউন্ট ভেরিফিকেশন',
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1B5E20),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 7),
                      const Text(
                        'আপনার নিবন্ধিত ইমেইলটি শনাক্ত করা হয়েছে। পাসওয়ার্ড পুনরুদ্ধারে এগিয়ে যান।',
                        style: TextStyle(
                          fontSize: 12.0,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF2E7D32),
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                // অপশন ২: সরাসরি রিসেট ইমেইল পাঠানো অথবা ১ ঘণ্টার কুলডাউন ওয়ার্নিং
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
