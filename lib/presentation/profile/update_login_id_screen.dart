import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lottie/lottie.dart';
import '../../core/constants/app_colors.dart';
import '../../core/widgets/app_unified_dialog.dart';
import '../../core/widgets/app_warning_dialog.dart';
import '../../core/utils/bangla_number_converter.dart';
import '../../core/utils/date_formatter.dart';
import '../../providers/auth_provider.dart';

class UpdateLoginIdScreen extends StatefulWidget {
  const UpdateLoginIdScreen({super.key});

  @override
  State<UpdateLoginIdScreen> createState() => _UpdateLoginIdScreenState();
}

class _UpdateLoginIdScreenState extends State<UpdateLoginIdScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _newPhoneController = TextEditingController();
  final TextEditingController _newEmailController = TextEditingController();

  bool _isSubmitting = false;
  Stream<QuerySnapshot<Map<String, dynamic>>>? _cachedRequestsStream;
  String? _cachedRequestsUid;

  Stream<QuerySnapshot<Map<String, dynamic>>> _getRequestsStream(String uid) {
    if (_cachedRequestsStream == null || _cachedRequestsUid != uid) {
      _cachedRequestsUid = uid;
      _cachedRequestsStream = FirebaseFirestore.instance
          .collection('login_update_requests')
          .where('userId', isEqualTo: uid)
          .limit(10)
          .snapshots();
    }
    return _cachedRequestsStream!;
  }

  @override
  void dispose() {
    _newPhoneController.dispose();
    _newEmailController.dispose();
    super.dispose();
  }

  String _toBn(String str) {
    return BanglaNumberConverter.toBangla(str);
  }

  /// ফোন নম্বর স্ট্যান্ডার্ডাইজেশন হেল্পার (+৮৮ প্রিফিক্স বাদ দিয়ে পিওর ১১ ডিজিট রিটার্ন করে)
  String _normalizePhone(String phone) {
    var digits = phone.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.startsWith('880')) {
      digits = digits.substring(2);
    } else if (digits.startsWith('88') && digits.length > 11) {
      digits = digits.substring(2);
    }
    return digits;
  }

  /// দুটি ফোন নম্বর একই কি না তা ফরম্যাট নির্বিশেষে নিখুঁতভাবে যাচাই
  bool _isSamePhone(String p1, String p2) {
    final n1 = _normalizePhone(p1);
    final n2 = _normalizePhone(p2);
    if (n1.isEmpty || n2.isEmpty) return false;
    return n1 == n2;
  }

  /// নতুন পেন্ডিং অ্যানিমেশন সাকসেস ডায়ালগ (Native Theme-Matched App Dialog)
  Future<void> _showPendingSuccessDialog(BuildContext context) async {
    if (!mounted) return;
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) {
        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, result) {
            if (didPop) return;
            Navigator.of(dialogCtx).pop();
          },
          child: Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
            backgroundColor: Colors.white,
            elevation: 10,
            insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Lottie Pending Animation inside Themed Circle Container
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F8F1),
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFFC8E6C9), width: 2),
                    ),
                    padding: const EdgeInsets.all(8),
                    child: Center(
                      child: Lottie.asset(
                        'assets/animation/pending.json',
                        repeat: true,
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(
                            Icons.check_circle_rounded,
                            color: Color(0xFF00A86B),
                            size: 60,
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'আবেদন সফল হয়েছে!',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1B5E20),
                      letterSpacing: 0.2,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'আপনার আবেদনটি সফলভাবে জমা হয়েছে এবং অনুমোদনের জন্য অপেক্ষমাণ আছে।',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13.5,
                      color: AppColors.textSecondary,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 22),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.of(dialogCtx).pop();
                      },
                      icon: const Icon(Icons.check_rounded, size: 20),
                      label: const Text(
                        'ঠিক আছে',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.3,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00A86B),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showWarningSnackBar(String message) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.info_outline_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFFE65100),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  Future<void> _submitRequest({
    required String activeUid,
    required String userName,
    required String currentPhone,
    required String currentEmail,
  }) async {
    final cleanNewPhone = _newPhoneController.text.trim();
    final cleanNewEmail = _newEmailController.text.trim().toLowerCase();

    // ১. Empty Field Validation (খালি ডেটা চেক):
    // সাবমিট বাটনে ক্লিক করার সাথে সাথে চেক করো ইমেইল এবং ফোন নাম্বারের টেক্সটফিল্ড দুটি সম্পূর্ণ খালি কি না।
    // যদি কোনো একটি ফিল্ড খালি থাকে, তবে সাবমিট ব্লক করে দাও এবং অ্যাপের গ্লোবাল পপআপের মাধ্যমে মেসেজ দেখাও:
    // "দয়া করে ইমেইল এবং ফোন নাম্বার উভয়ই প্রদান করুন।"
    if (cleanNewPhone.isEmpty || cleanNewEmail.isEmpty) {
      showAppWarningDialog(
        context,
        title: 'সতর্কবার্তা',
        message: 'দয়া করে ইমেইল এবং ফোন নাম্বার উভয়ই প্রদান করুন।',
      );
      return;
    }

    // ফিল্ডের ফরম্যাট ভ্যালিডেশন (সঠিক ফরম্যাট নিশ্চিতকরণ)
    if (!_formKey.currentState!.validate()) return;
    if (_isSubmitting) return;

    final cleanCurrentPhone = currentPhone.trim();
    final cleanCurrentEmail = currentEmail.trim().toLowerCase();

    // ২. Current Data Check (বর্তমান ডেটা চেক - লোকাল ও ফায়ারবেস Auth থেকে):
    // ইউজারের বর্তমান প্রোফাইলে যে ইমেইল এবং ফোন নাম্বার সেভ করা আছে, তার সাথে ইনপুট করা নতুন ডেটা মিলিয়ে দেখো।
    // যদি ইউজার তার বর্তমান ইমেইল বা বর্তমান ফোন নাম্বারই আবার ইনপুট হিসেবে দেয়, তবে সাথে সাথে সাবমিট ব্লক করে
    // পপআপে হুবহু এই মেসেজটি দেখাও: "আপনি বর্তমান প্রোফাইলে ব্যবহৃত তথ্য দিয়েছেন। অনুগ্রহ করে নতুন তথ্য দিন।"
    final fbUser = FirebaseAuth.instance.currentUser;
    final fbPhone = (fbUser?.phoneNumber ?? '').trim();
    final fbEmail = (fbUser?.email ?? '').trim().toLowerCase();

    final isSameAsCurrentPhone = (cleanCurrentPhone.isNotEmpty &&
            (_isSamePhone(cleanNewPhone, cleanCurrentPhone) || cleanNewPhone == cleanCurrentPhone)) ||
        (fbPhone.isNotEmpty &&
            (_isSamePhone(cleanNewPhone, fbPhone) || cleanNewPhone == fbPhone));

    final isSameAsCurrentEmail = (cleanCurrentEmail.isNotEmpty && cleanNewEmail == cleanCurrentEmail) ||
        (fbEmail.isNotEmpty && cleanNewEmail == fbEmail);

    if (isSameAsCurrentPhone || isSameAsCurrentEmail) {
      showAppWarningDialog(
        context,
        title: 'সতর্কবার্তা',
        message: 'আপনি বর্তমান প্রোফাইলে ব্যবহৃত তথ্য দিয়েছেন। অনুগ্রহ করে নতুন তথ্য দিন।',
      );
      return;
    }

    setState(() => _isSubmitting = true);
    FocusScope.of(context).unfocus();

    final loadingCtrl = AppUnifiedDialog.showLoading(
      context,
      message: 'তথ্য যাচাই করা হচ্ছে...',
      barrierDismissible: false,
    );

    bool isSuccess = false;
    String? warningPopupMessage;
    String? errorPopupMessage;

    try {
      final firestore = FirebaseFirestore.instance;

      // ২.১ ফায়ারস্টোর ডেটাবেসে ইউজারের বর্তমান প্রোফাইল ডেটার সাথেও মিলিয়ে দেখা (অতিরিক্ত সতর্কতা)
      if (activeUid.isNotEmpty && activeUid != 'guest_user') {
        try {
          final userDoc = await firestore.collection('users').doc(activeUid).get();
          if (userDoc.exists) {
            final uData = userDoc.data() ?? {};
            final dbPhone = (uData['phone'] ?? uData['phoneNumber'] ?? '').toString().trim();
            final dbEmail = (uData['email'] ?? '').toString().trim().toLowerCase();

            if ((dbPhone.isNotEmpty && (_isSamePhone(cleanNewPhone, dbPhone) || cleanNewPhone == dbPhone)) ||
                (dbEmail.isNotEmpty && cleanNewEmail == dbEmail)) {
              warningPopupMessage = 'আপনি বর্তমান প্রোফাইলে ব্যবহৃত তথ্য দিয়েছেন। অনুগ্রহ করে নতুন তথ্য দিন।';
              return;
            }
          }
        } catch (e) {
          debugPrint('Notice checking user doc in firestore: $e');
        }
      }

      // ০. সার্ভার সাইড চেক: যদি ইতিমধ্যেই কোনো পেন্ডিং রিকোয়েস্ট থাকে তবে ব্লক করা
      final existingPending = await firestore
          .collection('login_update_requests')
          .where('userId', isEqualTo: activeUid)
          .where('status', isEqualTo: 'pending')
          .limit(1)
          .get();

      if (existingPending.docs.isNotEmpty) {
        warningPopupMessage = 'আপনার একটি রিকোয়েস্ট বর্তমানে অপেক্ষমাণ (Pending) রয়েছে। এটি অনুমোদন বা বাতিল না হওয়া পর্যন্ত আপনি নতুন কোনো রিকোয়েস্ট করতে পারবেন না।';
        return;
      }

      // ৩. Firebase Unique Check (আলাদা আলাদা ইউনিক চেক):
      // ৩.১ ইমেইল চেক: ইনপুট দেওয়া নতুন ইমেইলটি অন্য কোনো ইউজারের অ্যাকাউন্টে ব্যবহৃত হচ্ছে কি না
      final emailQuery = await firestore
          .collection('users')
          .where('email', isEqualTo: cleanNewEmail)
          .limit(1)
          .get();

      if (emailQuery.docs.isNotEmpty && emailQuery.docs.first.id != activeUid) {
        warningPopupMessage = 'এই ইমেইলটি ইতিমধ্যে ব্যবহৃত হচ্ছে।';
        return;
      }

      // ৩.২ ফোন নম্বর চেক: ইনপুট দেওয়া নতুন ফোন নাম্বারটি অন্য কারো আছে কি না
      bool isPhoneTaken = false;
      final phoneVariants = <String>{
        cleanNewPhone,
        if (cleanNewPhone.startsWith('01')) '+88$cleanNewPhone',
        if (cleanNewPhone.startsWith('01')) '88$cleanNewPhone',
      };

      for (final variant in phoneVariants) {
        final q1 = await firestore
            .collection('users')
            .where('phone', isEqualTo: variant)
            .limit(1)
            .get();
        if (q1.docs.isNotEmpty && q1.docs.first.id != activeUid) {
          isPhoneTaken = true;
          break;
        }

        final q2 = await firestore
            .collection('users')
            .where('phoneNumber', isEqualTo: variant)
            .limit(1)
            .get();
        if (q2.docs.isNotEmpty && q2.docs.first.id != activeUid) {
          isPhoneTaken = true;
          break;
        }
      }

      if (isPhoneTaken) {
        warningPopupMessage = 'এই ফোন নাম্বারটি ইতিমধ্যে ব্যবহৃত হচ্ছে।';
        return;
      }

      // ৪. সাকসেস সাবমিট: সমস্ত ভ্যালিডেশন সফলভাবে পাস করার পরেই রিকোয়েস্টটি ফায়ারবেসে সাবমিট করা
      final requestId = 'req_${DateTime.now().millisecondsSinceEpoch}';
      final requestData = {
        'requestId': requestId,
        'id': requestId,
        'userId': activeUid,
        'userName': userName,
        'currentPhone': currentPhone,
        'currentEmail': currentEmail,
        'newPhone': cleanNewPhone,
        'newEmail': cleanNewEmail,
        'status': 'pending', // 'pending', 'accepted', 'rejected'
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'adminNote': '',
      };

      await firestore.collection('login_update_requests').doc(requestId).set(requestData);

      _newPhoneController.clear();
      _newEmailController.clear();
      isSuccess = true;
    } catch (e) {
      debugPrint('Error submitting login ID update request: $e');
      if (e is String) {
        errorPopupMessage = e;
      } else {
        errorPopupMessage = 'একটি অনাকাঙ্ক্ষিত ত্রুটি ঘটেছে। আপনার ইন্টারনেট সংযোগ পরীক্ষা করে পুনরায় চেষ্টা করুন।';
      }
    } finally {
      // টাচ লক প্রতিরোধে লোডিং ডায়ালগ নিরাপদভাবে ডিসমিস করা
      loadingCtrl.dismiss();
      AppUnifiedDialog.safeDismissLoading(context);
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }

    if (!mounted) return;

    if (warningPopupMessage != null) {
      await Future.delayed(const Duration(milliseconds: 100));
      if (!mounted) return;
      showAppWarningDialog(
        context,
        title: 'সতর্কবার্তা',
        message: warningPopupMessage,
      );
    } else if (isSuccess) {
      await Future.delayed(const Duration(milliseconds: 150));
      if (!mounted) return;
      await _showPendingSuccessDialog(context);
    } else if (errorPopupMessage != null) {
      await Future.delayed(const Duration(milliseconds: 100));
      if (!mounted) return;
      showAppWarningDialog(
        context,
        title: 'ত্রুটি',
        message: errorPopupMessage,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final fbUser = FirebaseAuth.instance.currentUser;
    final user = authProvider.user;

    final activeUid = fbUser?.uid ?? user?.uid ?? '';
    final userName = user?.name ?? fbUser?.displayName ?? 'সম্মানিত কৃষক';
    final currentPhone = user?.phone ?? fbUser?.phoneNumber ?? '';
    final currentEmail = user?.email ?? fbUser?.email ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFFF7FAF7),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary, size: 19),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'লগইন আইডি আপডেট',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 17,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: activeUid.isEmpty
            ? (authProvider.isLoading
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(color: AppColors.primary),
                        SizedBox(height: 12),
                        Text(
                          'তথ্য যাচাই করা হচ্ছে...',
                          style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  )
                : _buildRequestFormView(
                    activeUid: 'guest_user',
                    userName: userName,
                    currentPhone: currentPhone,
                    currentEmail: currentEmail,
                  ))
            : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: _getRequestsStream(activeUid),
                builder: (context, snapshot) {
                  // ফ্লিকারিং প্রতিরোধ: ফায়ারস্টোর ডেটা আসার পূর্ব মুহূর্ত পর্যন্ত সেন্ট্রালাইজড লোডার প্রদর্শিত হবে
                  if (snapshot.connectionState == ConnectionState.waiting || !snapshot.hasData) {
                    return const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(color: AppColors.primary),
                          SizedBox(height: 12),
                          Text(
                            'তথ্য যাচাই করা হচ্ছে...',
                            style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    );
                  }

                  if (snapshot.hasError) {
                    debugPrint('Login update requests stream error: ${snapshot.error}');
                    return _buildRequestFormView(
                      activeUid: activeUid,
                      userName: userName,
                      currentPhone: currentPhone,
                      currentEmail: currentEmail,
                    );
                  }

                  final docs = snapshot.data?.docs ?? [];
                  // Check if any request is currently pending
                  QueryDocumentSnapshot<Map<String, dynamic>>? pendingDoc;
                  for (final d in docs) {
                    if (d.data()['status'] == 'pending') {
                      pendingDoc = d;
                      break;
                    }
                  }

                  // If user has an active pending request, show the dedicated Pending View!
                  if (pendingDoc != null) {
                    return _buildPendingStateView(pendingDoc.data());
                  }

                  // Otherwise, show the Request Form
                  return _buildRequestFormView(
                    activeUid: activeUid,
                    userName: userName,
                    currentPhone: currentPhone,
                    currentEmail: currentEmail,
                  );
                },
              ),
      ),
    );
  }

  /// ১. পেন্ডিং স্টেট স্ক্রিন (Lottie Animation: pending.json)
  Widget _buildPendingStateView(Map<String, dynamic> data) {
    final newPhone = data['newPhone']?.toString() ?? '';
    final newEmail = data['newEmail']?.toString() ?? '';
    final currentPhone = data['currentPhone']?.toString() ?? '';
    final currentEmail = data['currentEmail']?.toString() ?? '';
    final ts = data['createdAt'];
    DateTime date = DateTime.now();
    if (ts is Timestamp) {
      date = ts.toDate();
    }

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Column(
        children: [
          const SizedBox(height: 10),

          // Lottie Pending Animation
          Center(
            child: SizedBox(
              width: 170,
              height: 170,
              child: Lottie.asset(
                'assets/animation/pending.json',
                repeat: true,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => Container(
                  width: 120,
                  height: 120,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFFF3E0),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.hourglass_top_rounded, size: 55, color: Color(0xFFE65100)),
                ),
              ),
            ),
          ),

          const SizedBox(height: 14),

          const Text(
            'আপনার রিকোয়েস্টটি পেন্ডিং অবস্থায় আছে',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18.5,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1B5E20),
            ),
          ),

          const SizedBox(height: 8),

          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'আপনার একটি রিকোয়েস্ট বর্তমানে অপেক্ষমাণ (Pending) রয়েছে। এটি অনুমোদন বা বাতিল না হওয়া পর্যন্ত আপনি নতুন কোনো রিকোয়েস্ট করতে পারবেন না।',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
                height: 1.45,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Request Summary Card
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE4EDE4), width: 1.2),
              boxShadow: const [
                BoxShadow(color: Color(0x06000000), blurRadius: 10, offset: Offset(0, 3)),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'রিকোয়েস্টের বিস্তারিত তথ্য',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF3E0),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFFFB74D)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.schedule_rounded, size: 13, color: Color(0xFFE65100)),
                          SizedBox(width: 4),
                          Text(
                            'পেন্ডিং',
                            style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Color(0xFFE65100)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const Divider(height: 24, color: Color(0xFFF0F4F0)),

                _buildInfoRow('আবেদনের তারিখ:', DateFormatter.formatRelativeBangla(date)),
                const SizedBox(height: 10),
                _buildInfoRow('পূর্বের মোবাইল:', currentPhone.isNotEmpty ? currentPhone : 'প্রযোজ্য নয়', isPhone: true),
                const SizedBox(height: 10),
                _buildInfoRow('নতুন মোবাইল:', newPhone, isHighlight: true, isPhone: true),
                const SizedBox(height: 10),
                _buildInfoRow('পূর্বের ইমেইল:', currentEmail.isNotEmpty ? currentEmail : 'প্রযোজ্য নয়'),
                const SizedBox(height: 10),
                _buildInfoRow('নতুন ইমেইল:', newEmail, isHighlight: true),
              ],
            ),
          ),

          const SizedBox(height: 32),

          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00A86B),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: const Text('ঠিক আছে, ফিরে যান', style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isHighlight = false, bool isPhone = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 110,
          child: Text(
            label,
            style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isHighlight ? FontWeight.bold : FontWeight.w600,
              color: isHighlight ? const Color(0xFF1B5E20) : AppColors.textPrimary,
              fontFamily: isPhone ? 'Roboto' : null,
              fontFeatures: isPhone ? const [FontFeature.tabularFigures()] : null,
              letterSpacing: isPhone ? 1.5 : null,
            ),
          ),
        ),
      ],
    );
  }

  /// ২. নতুন রিকোয়েস্ট সাবমিশন ফর্ম
  Widget _buildRequestFormView({
    required String activeUid,
    required String userName,
    required String currentPhone,
    required String currentEmail,
  }) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Current Account Info Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE4EDE4), width: 1.1),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F5E9),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.person_pin_rounded, color: Color(0xFF00A86B), size: 20),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              userName,
                              style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                            ),
                            const Text(
                              'বর্তমান নির্ধারিত লগইন আইডি',
                              style: TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 20, color: Color(0xFFF0F4F0)),
                  Row(
                    children: [
                      const Icon(Icons.phone_android_rounded, size: 15, color: Color(0xFF00A86B)),
                      const SizedBox(width: 6),
                      const Text(
                        'মোবাইল: ',
                        style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                      ),
                      Text(
                        currentPhone.isNotEmpty ? currentPhone : "অনুপলব্ধ",
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                          fontFamily: 'Roboto',
                          fontFeatures: [FontFeature.tabularFigures()],
                          letterSpacing: 1.5,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.email_outlined, size: 15, color: Color(0xFF00A86B)),
                      const SizedBox(width: 6),
                      Text('ইমেইল: ${currentEmail.isNotEmpty ? currentEmail : "যুক্ত করা হয়নি"}',
                          style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            const Text(
              'নতুন তথ্য পূরণ করুন',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 4),
            const Text(
              'আপনার নতুন মোবাইল নম্বর ও ইমেইল ঠিকানা নিচে লিখুন। এডমিন যাচাই করে পরিবর্তন সম্পন্ন করবে।',
              style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary, height: 1.4),
            ),

            const SizedBox(height: 18),

            // Field 1: New Phone
            const Text(
              'নতুন মোবাইল নম্বর *',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 6),
            TextFormField(
              controller: _newPhoneController,
              keyboardType: TextInputType.phone,
              style: const TextStyle(
                fontSize: 14.5,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
                fontFamily: 'Roboto',
                fontFeatures: [FontFeature.tabularFigures()],
                letterSpacing: 1.5,
              ),
              strutStyle: const StrutStyle(
                fontFamily: 'Roboto',
                fontSize: 14.5,
                height: 1.25,
                forceStrutHeight: true,
              ),
              decoration: InputDecoration(
                hintText: '01XXXXXXXXX',
                hintStyle: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textMuted,
                  fontFamily: 'Roboto',
                  fontFeatures: [FontFeature.tabularFigures()],
                  letterSpacing: 1.5,
                ),
                prefixIcon: const Icon(Icons.phone_android_rounded, size: 20, color: Color(0xFF00A86B)),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE4EDE4))),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE4EDE4))),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF00A86B), width: 1.5)),
              ),
              validator: (val) {
                if (val == null || val.trim().isEmpty) {
                  return 'নতুন মোবাইল নম্বর প্রদান করুন';
                }
                final clean = val.trim().replaceAll(RegExp(r'[^0-9]'), '');
                if (clean.length != 11 || !clean.startsWith('01')) {
                  return 'সঠিক ১১ ডিজিটের মোবাইল নম্বর দিন (উদা: 01712345678)';
                }
                return null;
              },
            ),

            const SizedBox(height: 18),

            // Field 2: New Email
            const Text(
              'নতুন ইমেইল অ্যাড্রেস *',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 6),
            TextFormField(
              controller: _newEmailController,
              keyboardType: TextInputType.emailAddress,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
                fontFamily: 'Roboto',
              ),
              decoration: InputDecoration(
                hintText: 'newemail@gmail.com',
                hintStyle: const TextStyle(fontSize: 13, color: AppColors.textMuted, fontFamily: 'Roboto'),
                prefixIcon: const Icon(Icons.email_outlined, size: 20, color: Color(0xFF00A86B)),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE4EDE4))),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE4EDE4))),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF00A86B), width: 1.5)),
              ),
              validator: (val) {
                if (val == null || val.trim().isEmpty) {
                  return 'নতুন ইমেইল অ্যাড্রেস প্রদান করুন';
                }
                final email = val.trim();
                if (!email.contains('@') || !email.contains('.')) {
                  return 'সঠিক ইমেইল ফরম্যাট দিন (উদা: farmer@gmail.com)';
                }
                return null;
              },
            ),

            const SizedBox(height: 20),

            // Security Notice Banner
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F8F1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFC8E6C9)),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline_rounded, color: Color(0xFF2E7D32), size: 18),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'আপনার একাউন্টের সর্বোচ্চ নিরাপত্তা নিশ্চিত করতে যেকোনো পরিবর্তন এডমিন প্যানেল থেকে সতর্কতার সাথে যাচাই করে গৃহীত হবে।',
                      style: TextStyle(fontSize: 11.5, color: Color(0xFF1B5E20), height: 1.35),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            // Submit Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isSubmitting
                    ? null
                    : () => _submitRequest(
                          activeUid: activeUid,
                          userName: userName,
                          currentPhone: currentPhone,
                          currentEmail: currentEmail,
                        ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00A86B),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 1,
                ),
                child: _isSubmitting
                    ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.send_rounded, size: 18),
                          SizedBox(width: 8),
                          Text(
                            'রিকোয়েস্ট পাঠান',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, letterSpacing: 0.3),
                          ),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

