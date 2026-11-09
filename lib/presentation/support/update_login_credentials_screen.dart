import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lottie/lottie.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/bangla_number_converter.dart';
import '../../core/utils/date_formatter.dart';
import '../../core/widgets/app_unified_dialog.dart';
import '../../data/models/user_model.dart';
import '../../data/services/firebase_service.dart';
import '../../providers/auth_provider.dart';
import '../auth/phone_login_screen.dart';

class UpdateLoginCredentialsScreen extends StatefulWidget {
  const UpdateLoginCredentialsScreen({super.key});

  @override
  State<UpdateLoginCredentialsScreen> createState() => _UpdateLoginCredentialsScreenState();
}

class _UpdateLoginCredentialsScreenState extends State<UpdateLoginCredentialsScreen> {
  final TextEditingController _oldIdentifierController = TextEditingController();
  final TextEditingController _newPhoneController = TextEditingController();
  final TextEditingController _newEmailController = TextEditingController();

  final _formKey = GlobalKey<FormState>();

  String? _verifiedUserId;
  String? _verifiedUserName;
  String? _verifiedCurrentPhone;
  String? _verifiedCurrentEmail;

  bool _isSearching = false;
  bool _isUpdating = false;

  bool _isUpdatedSuccess = false;
  String? _successUpdatedId;
  DateTime? _successUpdateTime;

  @override
  void dispose() {
    _oldIdentifierController.dispose();
    _newPhoneController.dispose();
    _newEmailController.dispose();
    super.dispose();
  }

  /// ৩. পুরাতন একাউন্ট যাচাই ও স্বয়ংক্রিয় নাম প্রদর্শন (Auto Account Verification)
  Future<void> _verifyOldAccount() async {
    final input = _oldIdentifierController.text.trim();
    if (input.isEmpty) {
      AppUnifiedDialog.showError(
        context,
        title: 'তথ্য দিন',
        message: 'অনুগ্রহ করে আপনার পুরাতন ফোন নম্বর বা ইমেইল লিখুন।',
      );
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() => _isSearching = true);

    final loadingCtrl = AppUnifiedDialog.showLoading(
      context,
      message: 'তথ্য যাচাই করা হচ্ছে....',
    );

    try {
      DocumentSnapshot<Map<String, dynamic>>? matchedDoc;

      if (input.contains('@')) {
        // ইমেইল দিয়ে অনুসন্ধান
        final emailQuery = await FirebaseFirestore.instance
            .collection('users')
            .where('email', isEqualTo: input.toLowerCase().trim())
            .limit(1)
            .get()
            .timeout(const Duration(seconds: 8));

        if (emailQuery.docs.isNotEmpty) {
          matchedDoc = emailQuery.docs.first;
        }
      } else {
        // মোবাইল নম্বর দিয়ে অনুসন্ধান
        final cleanPhone = input.replaceAll(RegExp(r'[^0-9+]'), '');
        String altPhone = cleanPhone;
        if (cleanPhone.startsWith('+880')) {
          altPhone = cleanPhone.replaceFirst('+88', '');
        } else if (cleanPhone.startsWith('0')) {
          altPhone = '+88$cleanPhone';
        }

        final phoneQuery = await FirebaseFirestore.instance
            .collection('users')
            .where('phone', isEqualTo: cleanPhone)
            .limit(1)
            .get()
            .timeout(const Duration(seconds: 8));

        if (phoneQuery.docs.isNotEmpty) {
          matchedDoc = phoneQuery.docs.first;
        } else if (altPhone != cleanPhone) {
          final altQuery = await FirebaseFirestore.instance
              .collection('users')
              .where('phone', isEqualTo: altPhone)
              .limit(1)
              .get()
              .timeout(const Duration(seconds: 8));

          if (altQuery.docs.isNotEmpty) {
            matchedDoc = altQuery.docs.first;
          }
        }

        // phoneNumber ফিল্ড দিয়ে অতিরিক্ত ফলব্যাক
        if (matchedDoc == null) {
          final pQuery2 = await FirebaseFirestore.instance
              .collection('users')
              .where('phoneNumber', isEqualTo: cleanPhone)
              .limit(1)
              .get()
              .timeout(const Duration(seconds: 8));
          if (pQuery2.docs.isNotEmpty) {
            matchedDoc = pQuery2.docs.first;
          }
        }
      }

      loadingCtrl.dismiss();

      if (matchedDoc != null && matchedDoc.exists) {
        final data = matchedDoc.data() ?? {};
        setState(() {
          _verifiedUserId = matchedDoc!.id;
          _verifiedUserName = data['name'] ?? 'সম্মানিত কৃষক';
          _verifiedCurrentPhone = data['phone'] ?? data['phoneNumber'] ?? '';
          _verifiedCurrentEmail = data['email'] ?? '';
          _isUpdatedSuccess = false;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('স্বাগতম, $_verifiedUserName! আপনার একাউন্ট সফলভাবে পাওয়া গেছে।'),
              backgroundColor: AppColors.primary,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      } else {
        setState(() {
          _verifiedUserId = null;
          _verifiedUserName = null;
          _verifiedCurrentPhone = null;
          _verifiedCurrentEmail = null;
        });

        if (mounted) {
          await AppUnifiedDialog.showError(
            context,
            title: 'একাউন্ট পাওয়া যায়নি',
            message: 'এই নম্বর বা ইমেইলে কোনো একাউন্ট পাওয়া যায়নি!',
          );
        }
      }
    } catch (e) {
      debugPrint('Account verification error: $e');
      loadingCtrl.dismiss();
      if (mounted) {
        await AppUnifiedDialog.showError(
          context,
          title: 'ত্রুটি ঘটেছে',
          message: 'সার্ভারে সংযোগে সমস্যা হয়েছে। ইন্টারনেট সংযোগ পরীক্ষা করে পুনরায় চেষ্টা করুন।',
        );
      }
    } finally {
      loadingCtrl.dismiss();
      if (mounted) {
        setState(() => _isSearching = false);
      }
    }
  }

  /// ৪. নতুন লগইন তথ্য ইনপুট ও ইউনিকনেস ভ্যালিডেশন (Uniqueness Validation)
  /// ৫. ডেটাবেজ আপডেট ও পুরাতন তথ্য বাতিল (Data Synchronization)
  Future<void> _handleConfirmUpdate() async {
    if (_verifiedUserId == null) {
      AppUnifiedDialog.showError(
        context,
        title: 'একাউন্ট যাচাই প্রয়োজন',
        message: 'অনুগ্রহ করে প্রথমে পুরাতন একাউন্ট যাচাই সম্পন্ন করুন।',
      );
      return;
    }

    final newPhone = _newPhoneController.text.trim();
    final newEmail = _newEmailController.text.trim();

    // অন্তত একটি নতুন তথ্য দিতে হবে
    if (newPhone.isEmpty && newEmail.isEmpty) {
      AppUnifiedDialog.showError(
        context,
        title: 'নতুন তথ্য দিন',
        message: 'অনুগ্রহ করে নতুন ফোন নম্বর অথবা নতুন ইমেইল প্রদান করুন।',
      );
      return;
    }

    // ১. ফোন নম্বর ভ্যালিডেশন ও ইউনিকনেস চেক
    String? validatedPhone;
    if (newPhone.isNotEmpty) {
      final cleanPhone = newPhone.replaceAll(RegExp(r'[^0-9]'), '');
      if (cleanPhone.length != 11 || !cleanPhone.startsWith('01')) {
        AppUnifiedDialog.showError(
          context,
          title: 'ভুল মোবাইল নম্বর',
          message: 'সঠিক ১১ ডিজিটের বাংলাদেশী মোবাইল নম্বর দিন (যেমন: 017XXXXXXXX)!',
        );
        return;
      }

      if (cleanPhone == _verifiedCurrentPhone?.replaceAll(RegExp(r'[^0-9]'), '')) {
        AppUnifiedDialog.showError(
          context,
          title: 'একই নম্বর',
          message: 'নতুন নম্বরটি আপনার বর্তমান পুরাতন নম্বরের মতো একই হতে পারবে না! অনুগ্রহ করে ভিন্ন নতুন নম্বর দিন।',
        );
        return;
      }
      validatedPhone = cleanPhone;
    }

    // ২. ইমেইল ভ্যালিডেশন ও ইউনিকনেস চেক
    String? validatedEmail;
    if (newEmail.isNotEmpty) {
      final cleanEmail = newEmail.toLowerCase().trim();
      if (!cleanEmail.contains('@') || !cleanEmail.contains('.')) {
        AppUnifiedDialog.showError(
          context,
          title: 'ভুল ইমেইল এড্রেস',
          message: 'অনুগ্রহ করে একটি সঠিক ইমেইল এড্রেস প্রদান করুন (যেমন: example@gmail.com)।',
        );
        return;
      }

      if (cleanEmail == _verifiedCurrentEmail?.toLowerCase().trim()) {
        AppUnifiedDialog.showError(
          context,
          title: 'একই ইমেইল',
          message: 'নতুন ইমেইলটি আপনার বর্তমান পুরাতন ইমেইলের মতো একই হতে পারবে না! অনুগ্রহ করে ভিন্ন নতুন ইমেইল দিন।',
        );
        return;
      }
      validatedEmail = cleanEmail;
    }

    if (_isUpdating) return;
    setState(() => _isUpdating = true);

    final loadingCtrl = AppUnifiedDialog.showLoading(
      context,
      message: 'তথ্য হালনাগাদ হচ্ছে....',
    );

    try {
      // ৩. ইউনিকনেস সিকিউরিটি চেক: ফায়ারস্টোরে অন্য কোনো একাউন্টে এই ফোন বা ইমেইল আগে থেকেই আছে কিনা
      if (validatedPhone != null) {
        final phoneQuery = await FirebaseFirestore.instance
            .collection('users')
            .where('phone', isEqualTo: validatedPhone)
            .get();

        final existsOther = phoneQuery.docs.any((d) => d.id != _verifiedUserId);
        if (existsOther) {
          loadingCtrl.dismiss();
          if (mounted) {
            await AppUnifiedDialog.showError(
              context,
              title: 'তথ্য ইতোমধ্যে ব্যবহৃত',
              message: 'প্রদত্ত নতুন ফোন নম্বরটি ইতোমধ্যে অন্য একটি একাউন্টে ব্যবহৃত হচ্ছে! অনুগ্রহ করে ভিন্ন তথ্য দিন।',
            );
          }
          return;
        }
      }

      if (validatedEmail != null) {
        final emailQuery = await FirebaseFirestore.instance
            .collection('users')
            .where('email', isEqualTo: validatedEmail)
            .get();

        final existsOther = emailQuery.docs.any((d) => d.id != _verifiedUserId);
        if (existsOther) {
          loadingCtrl.dismiss();
          if (mounted) {
            await AppUnifiedDialog.showError(
              context,
              title: 'তথ্য ইতোমধ্যে ব্যবহৃত',
              message: 'প্রদত্ত নতুন ইমেইলটি ইতোমধ্যে অন্য একটি একাউন্টে ব্যবহৃত হচ্ছে! অনুগ্রহ করে ভিন্ন তথ্য দিন।',
            );
          }
          return;
        }
      }

      // ৪. ফায়ারস্টোর ডেটাবেজ আপডেট ও পুরাতন তথ্য সম্পূর্ণ রিপ্লেস ও বাতিল
      final updateData = <String, dynamic>{
        'updatedAt': FieldValue.serverTimestamp(),
      };

      final List<String> updatedIdentifiers = [];

      if (validatedPhone != null) {
        updateData['phone'] = validatedPhone;
        updateData['phoneNumber'] = validatedPhone;
        updatedIdentifiers.add(validatedPhone);
      }

      if (validatedEmail != null) {
        updateData['email'] = validatedEmail;
        updatedIdentifiers.add(validatedEmail);
      }

      await FirebaseFirestore.instance
          .collection('users')
          .doc(_verifiedUserId)
          .update(updateData);

      // যদি কারেন্ট লগইন ইউজারই এই ইউজার হয়ে থাকেন, লোকাল প্রোভাইডার আপডেট
      try {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        if (authProvider.user != null && authProvider.user!.uid == _verifiedUserId) {
          final updatedUser = authProvider.user!.copyWith(
            phone: validatedPhone ?? authProvider.user!.phone,
            email: validatedEmail ?? authProvider.user!.email,
          );
          authProvider.setUser(updatedUser);
        }
      } catch (_) {}

      loadingCtrl.dismiss();

      // ৬. সফল হালনাগাদ ও ডিজিটাল রিসিপ্ট স্টেট
      if (mounted) {
        setState(() {
          _isUpdatedSuccess = true;
          _successUpdatedId = updatedIdentifiers.join('  •  ');
          _successUpdateTime = DateTime.now();
        });
      }
    } catch (e) {
      debugPrint('Credentials update error: $e');
      loadingCtrl.dismiss();
      if (mounted) {
        await AppUnifiedDialog.showError(
          context,
          title: 'হালনাগাদ ব্যর্থ হয়েছে',
          message: 'একটি অনাকাঙ্ক্ষিত ত্রুটি ঘটেছে। অনুগ্রহ করে পুনরায় চেষ্টা করুন।',
        );
      }
    } finally {
      loadingCtrl.dismiss();
      if (mounted) {
        setState(() => _isUpdating = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8F5),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ================= HEADER & LOTTIE ANIMATION =================
              _buildHeader(context),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 18.0),
                child: _isUpdatedSuccess ? _buildDigitalReceiptCard() : _buildUpdateForm(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// হেডার ও নির্দিষ্ট Lottie অ্যানিমেশন
  Widget _buildHeader(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFF00A86B), // Emerald Green
            Color(0xFF008955),
            Color(0xFF1B5E20),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Color(0x3000A86B),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 22),
          child: Column(
            children: [
              // Top Bar with Back Button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  InkWell(
                    onTap: () => Navigator.of(context).pop(),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.18),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white.withOpacity(0.28), width: 1),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 15),
                          SizedBox(width: 5),
                          Text(
                            'ফিরে যান',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.18),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withOpacity(0.28), width: 1),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.security_rounded, color: Colors.white, size: 14),
                        SizedBox(width: 5),
                        Text(
                          'নিরাপদ হালনাগাদ',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // নির্দিষ্ট Lottie অ্যানিমেশন (Man and robot with computers sitting together in workplace.json)
              SizedBox(
                height: 145,
                child: Lottie.asset(
                  'assets/animation/Man and robot with computers sitting together in workplace.json',
                  fit: BoxFit.contain,
                  repeat: true,
                ),
              ),

              const SizedBox(height: 10),

              const Text(
                'লগইন তথ্য হালনাগাদ',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 21,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'আপনার একাউন্টের ফোন নম্বর বা ইমেইল নিরাপদভাবে পরিবর্তন করুন',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFFE8F5E9),
                  fontSize: 12.5,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// হালনাগাদ ফরম ও একাউন্ট যাচাইকরণ
  Widget _buildUpdateForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ================= STEP 1: পুরাতন একাউন্ট যাচাই =================
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFDCE6DC), width: 1.2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F5E9),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.manage_search_rounded, color: Color(0xFF00A86B), size: 22),
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '১. পুরাতন একাউন্ট যাচাই',
                            style: TextStyle(
                              fontSize: 15.5,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            'আপনার বর্তমান সক্রিয় একাউন্টের ফোন নম্বর বা ইমেইল লিখুন',
                            style: TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),
                const Divider(color: Color(0xFFEFF3EF), height: 1),
                const SizedBox(height: 14),

                const Text(
                  'পুরাতন ফোন নম্বর বা ইমেইল লিখুন',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _oldIdentifierController,
                  keyboardType: TextInputType.emailAddress,
                  style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
                  decoration: InputDecoration(
                    hintText: 'যেমন: 017XXXXXXXX বা user@gmail.com',
                    hintStyle: const TextStyle(color: Color(0xFF9E9E9E), fontSize: 13),
                    filled: true,
                    fillColor: const Color(0xFFF9FAF9),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                    isDense: true,
                    prefixIcon: const Icon(Icons.badge_outlined, color: Color(0xFF00A86B), size: 20),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: Color(0xFFDCE4DC)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: Color(0xFFDCE4DC)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: Color(0xFF00A86B), width: 1.5),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // যাচাই করুন বাটন
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: ElevatedButton.icon(
                    onPressed: _isSearching ? null : _verifyOldAccount,
                    icon: const Icon(Icons.verified_outlined, size: 18),
                    label: const Text(
                      'একাউন্ট যাচাই করুন',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00A86B),
                      foregroundColor: Colors.white,
                      elevation: 1.5,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),

                // ৩. একাউন্ট পাওয়া গেলে স্বয়ংক্রিয় নাম প্রদর্শন (ReadOnly Card)
                if (_verifiedUserId != null && _verifiedUserName != null) ...[
                  const SizedBox(height: 14),
                  StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                    stream: FirebaseFirestore.instance.collection('users').doc(_verifiedUserId).snapshots(),
                    builder: (context, snapshot) {
                      final liveName = snapshot.data?.data()?['name'] ?? _verifiedUserName!;
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F5E9),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFF81C784), width: 1.2),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 38,
                              height: 38,
                              decoration: const BoxDecoration(
                                color: Color(0xFFC8E6C9),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.person_rounded, color: Color(0xFF1B5E20), size: 22),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'যাচাইকৃত ব্যবহারকারীর নাম (অপরিবর্তনীয়)',
                                    style: TextStyle(fontSize: 11, color: Color(0xFF2E7D32), fontWeight: FontWeight.w600),
                                  ),
                                  const SizedBox(height: 1),
                                  Text(
                                    liveName,
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF1B5E20),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFF2E7D32),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.check_circle_rounded, color: Colors.white, size: 12),
                                  SizedBox(width: 4),
                                  Text(
                                    'যাচাইকৃত',
                                    style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 18),

          // ================= STEP 2: নতুন লগইন তথ্য ইনপুট =================
          if (_verifiedUserId != null) ...[
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFDCE6DC), width: 1.2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F5E9),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.lock_reset_rounded, color: Color(0xFF00A86B), size: 22),
                      ),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '২. নতুন লগইন তথ্য নির্ধারণ',
                              style: TextStyle(
                                fontSize: 15.5,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            Text(
                              'নতুন ফোন নম্বর বা নতুন ইমেইল লিখুন (অন্তত একটি পূরণ করুন)',
                              style: TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),
                  const Divider(color: Color(0xFFEFF3EF), height: 1),
                  const SizedBox(height: 14),

                  // নতুন ফোন নম্বর (ঐচ্ছিক)
                  const Text(
                    'নতুন ফোন নম্বর (ঐচ্ছিক)',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _newPhoneController,
                    keyboardType: TextInputType.phone,
                    style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
                    decoration: InputDecoration(
                      hintText: 'নতুন ১১ ডিজিটের মোবাইল নম্বর লিখুন',
                      hintStyle: const TextStyle(color: Color(0xFF9E9E9E), fontSize: 13),
                      filled: true,
                      fillColor: const Color(0xFFF9FAF9),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                      isDense: true,
                      prefixIcon: const Icon(Icons.phone_android_rounded, color: Color(0xFF00A86B), size: 20),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: Color(0xFFDCE4DC)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: Color(0xFFDCE4DC)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: Color(0xFF00A86B), width: 1.5),
                      ),
                    ),
                  ),

                  const SizedBox(height: 14),

                  // নতুন ইমেইল (ঐচ্ছিক)
                  const Text(
                    'নতুন ইমেইল (ঐচ্ছিক)',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _newEmailController,
                    keyboardType: TextInputType.emailAddress,
                    style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
                    decoration: InputDecoration(
                      hintText: 'নতুন @gmail.com এড্রেস লিখুন',
                      hintStyle: const TextStyle(color: Color(0xFF9E9E9E), fontSize: 13),
                      filled: true,
                      fillColor: const Color(0xFFF9FAF9),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                      isDense: true,
                      prefixIcon: const Icon(Icons.alternate_email_rounded, color: Color(0xFF00A86B), size: 20),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: Color(0xFFDCE4DC)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: Color(0xFFDCE4DC)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: Color(0xFF00A86B), width: 1.5),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // হালনাগাদ নিশ্চিত করুন বাটন
                  SizedBox(
                    width: double.infinity,
                    height: 46,
                    child: ElevatedButton.icon(
                      onPressed: _isUpdating ? null : _handleConfirmUpdate,
                      icon: const Icon(Icons.check_circle_outline_rounded, size: 19),
                      label: const Text(
                        'হালনাগাদ নিশ্চিত করুন',
                        style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00A86B),
                        foregroundColor: Colors.white,
                        elevation: 2,
                        shadowColor: const Color(0x3500A86B),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 30),
        ],
      ),
    );
  }

  /// ৬. সফল হালনাগাদ ও ডিজিটাল রিসিপ্ট কার্ড (Success Receipt)
  Widget _buildDigitalReceiptCard() {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFF81C784), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0x1500A86B),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          // অ্যানিমেটেড সবুজ 'টিক' আইকন
          Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5E9),
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFF81C784), width: 2),
            ),
            child: const Center(
              child: Icon(
                Icons.check_rounded,
                color: Color(0xFF2E7D32),
                size: 42,
              ),
            ),
          ),

          const SizedBox(height: 16),

          const Text(
            'লগইন তথ্য সফলভাবে হালনাগাদ হয়েছে!',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18.5,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1B5E20),
            ),
          ),

          const SizedBox(height: 6),

          const Text(
            'আপনার একাউন্টের নতুন লগইন আইডি ডাটাবেজে স্থায়ীভাবে কার্যকর করা হয়েছে। পুরাতন তথ্য স্বয়ংক্রিয়ভাবে বাতিল করা হয়েছে।',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12.5,
              color: Color(0xFF556955),
              height: 1.4,
            ),
          ),

          const SizedBox(height: 20),

          // প্রিমিয়াম ডিজিটাল রিসিপ্ট বক্স
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAF9),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFD8E4D8)),
            ),
            child: Column(
              children: [
                _buildReceiptRow(
                  label: 'ব্যবহারকারীর নাম:',
                  value: _verifiedUserName ?? 'সম্মানিত কৃষক',
                  isBold: true,
                ),
                const Divider(color: Color(0xFFE5EDE5), height: 16),
                _buildReceiptRow(
                  label: 'নতুন লগইন আইডি:',
                  value: _successUpdatedId ?? '',
                  valueColor: const Color(0xFF00A86B),
                  isBold: true,
                ),
                const Divider(color: Color(0xFFE5EDE5), height: 16),
                _buildReceiptRow(
                  label: 'আপডেটের তারিখ ও সময়:',
                  value: _successUpdateTime != null
                      ? BanglaDateFormatter.formatFull(_successUpdateTime!)
                      : 'এইমাত্র',
                  valueColor: const Color(0xFF455A64),
                ),
              ],
            ),
          ),

          const SizedBox(height: 18),

          // সিকিউরিটি নোট (পাসওয়ার্ড গোপন থাকবে)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF8E1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFFFE082)),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline_rounded, color: Color(0xFFE65100), size: 18),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'পরবর্তী সময়ে অ্যাপে প্রবেশের জন্য আপনার এই নতুন তথ্য এবং পূর্বের পাসওয়ার্ড ব্যবহার করুন।',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFBF360C),
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 22),

          // "লগইন পেজে যান" বাটন
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const PhoneLoginScreen()),
                  (route) => false,
                );
              },
              icon: const Icon(Icons.login_rounded, size: 20),
              label: const Text(
                'লগইন পেজে যান',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00A86B),
                foregroundColor: Colors.white,
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReceiptRow({
    required String label,
    required String value,
    Color? valueColor,
    bool isBold = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            color: Color(0xFF546E7A),
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
              color: valueColor ?? AppColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}

