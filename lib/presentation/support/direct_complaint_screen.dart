import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lottie/lottie.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/date_formatter.dart';
import '../../core/widgets/app_unified_dialog.dart';
import '../../data/services/firebase_service.dart';
import '../../providers/auth_provider.dart';
import '../../providers/support_provider.dart';
import 'update_login_credentials_screen.dart';

/// ৩. "সরাসরি সাপোর্টে অভিযোগ জানান" স্বতন্ত্র নতুন ফুল-স্ক্রিন পেজ
class DirectComplaintScreen extends StatefulWidget {
  const DirectComplaintScreen({super.key});

  @override
  State<DirectComplaintScreen> createState() => _DirectComplaintScreenState();
}

class _DirectComplaintScreenState extends State<DirectComplaintScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _detailsController = TextEditingController();

  final List<String> _categories = [
    'একাউন্ট সমস্যা',
    'ফসলের রোগ সংক্রান্ত জিজ্ঞাসা',
    'টেকনিক্যাল সমস্যা',
    'সাধারণ পরামর্শ',
    'লগইন তথ্য হালনাগাদ',
    'অন্যান্য',
  ];

  String? _selectedCategory;
  bool _isSubmitting = false;

  // Locked typography for input fields to prevent font jumping / scaling
  static const TextStyle _lockedInputStyle = TextStyle(
    fontSize: 15,
    height: 1.25,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.5,
    fontFeatures: [FontFeature.tabularFigures()],
    color: AppColors.textPrimary,
  );

  @override
  void initState() {
    super.initState();
    // ফিল্ডের প্রাথমিক ভ্যালু (initialValue / TextEditingController text) সম্পূর্ণ খালি (Empty) থাকবে
    _nameController.text = '';
    _addressController.text = '';
    _detailsController.text = '';
    _selectedCategory = null;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _detailsController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmitComplaint() async {
    if (!_formKey.currentState!.validate()) return;
    if (_isSubmitting) return;

    setState(() => _isSubmitting = true);

    final loadingCtrl = AppUnifiedDialog.showLoading(
      context,
      message: 'অভিযোগ পাঠানো হচ্ছে....',
    );

    bool isSuccess = false;
    String? errorMessage;

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final fbUser = FirebaseAuth.instance.currentUser;
      final user = authProvider.user;

      final currentUserId = fbUser?.uid ?? user?.uid ?? 'guest_user';
      final authorPhone = user?.phone ?? fbUser?.phoneNumber ?? '';
      final authorEmail = user?.email ?? fbUser?.email ?? '';

      // Fallback district/upazila if needed
      String district = user?.district ?? '';
      String upazila = user?.upazila ?? '';
      final fullAddress = _addressController.text.trim();

      if (district.isEmpty) {
        district = 'বাংলাদেশ';
      }
      if (upazila.isEmpty) {
        upazila = 'সদর';
      }

      final senderName = _nameController.text.trim().isNotEmpty
          ? _nameController.text.trim()
          : (user?.name ?? fbUser?.displayName ?? 'কৃষক ভাই');

      final ticketId = 'ticket_${DateTime.now().millisecondsSinceEpoch}';

      final ticketData = {
        'ticketId': ticketId,
        'userId': currentUserId,
        'authorId': currentUserId,
        'userName': senderName,
        'authorName': senderName,
        'userPhone': authorPhone,
        'authorPhone': authorPhone,
        if (authorEmail.isNotEmpty) 'userEmail': authorEmail,
        if (authorEmail.isNotEmpty) 'authorEmail': authorEmail,
        'district': district,
        'upazila': upazila,
        'address': fullAddress,
        'category': _selectedCategory!,
        'subject': _selectedCategory!,
        'message': _detailsController.text.trim(),
        'details': _detailsController.text.trim(),
        'status': 'pending',
        'adminReply': '',
        'officerReply': '',
        'reply': '',
        'createdAt': FieldValue.serverTimestamp(),
        'timestamp': FieldValue.serverTimestamp(),
      };

      if (FirebaseService.isFirebaseInitialized) {
        await FirebaseFirestore.instance.collection('support_tickets').doc(ticketId).set(ticketData);
      } else {
        final supportProvider = Provider.of<SupportProvider>(context, listen: false);
        await supportProvider.submitTicket(
          authorId: authorId,
          authorName: _nameController.text.trim(),
          authorPhone: authorPhone,
          authorEmail: authorEmail,
          district: district,
          upazila: upazila,
          subject: _selectedCategory!,
          details: _detailsController.text.trim(),
        );
      }

      isSuccess = true;
    } catch (e) {
      debugPrint('Error submitting support complaint: $e');
      errorMessage = 'একটি অনাকাঙ্ক্ষিত ত্রুটি ঘটেছে। আপনার ইন্টারনেট সংযোগ পরীক্ষা করে পুনরায় চেষ্টা করুন।';
    } finally {
      // ১. গ্যারান্টিড মোডাল ব্যারিয়ার ও লোডার ডিসমিসাল
      loadingCtrl.dismiss();
      AppUnifiedDialog.safeDismissLoading(context);
      if (context.mounted && Navigator.of(context, rootNavigator: true).canPop()) {
        try {
          Navigator.of(context, rootNavigator: true).pop();
        } catch (_) {}
      }
      // ২. পয়েন্টার ও সাবমিট স্টেট সাথে সাথে আনলক
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }

    // ৩. লোডার সম্পূর্ণ বন্ধ হওয়ার পর ক্লিকেবল ডায়ালগ প্রদর্শন
    if (isSuccess && mounted) {
      _nameController.clear();
      _addressController.clear();
      _detailsController.clear();
      setState(() {
        _selectedCategory = null;
      });

      await AppUnifiedDialog.showSuccess(
        context,
        title: 'অভিযোগ সফলভাবে গৃহীত হয়েছে!',
        message: 'আপনার অভিযোগ বা মতামত সফলভাবে গৃহীত হয়েছে। আমাদের সাপোর্ট টিম দ্রুত এটি পর্যালোচনা করে প্রয়োজনীয় ব্যবস্থা গ্রহণ করবে।',
        buttonText: 'ঠিক আছে',
      );
    } else if (errorMessage != null && mounted) {
      await AppUnifiedDialog.showError(
        context,
        title: 'অভিযোগ পাঠানো সম্ভব হয়নি',
        message: errorMessage,
        buttonText: 'আবার চেষ্টা করুন',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;
    final currentUserId = user?.uid ?? FirebaseAuth.instance.currentUser?.uid ?? 'guest_user';

    return Scaffold(
      backgroundColor: const Color(0xFFF6F8F5),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 50.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ================= 1. WHITE HEADER WITH CHAT LOTTIE ANIMATION =================
            _buildHeader(context),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ================= 2. COMPLAINT & FEEDBACK FORM =================
                  _buildFormCard(context),

                  const SizedBox(height: 24),

                  // ================= 3. REAL-TIME USER TICKETS HISTORY =================
                  _buildTicketsHistorySection(context, currentUserId),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// ১. সিগনেচার পিওর হোয়াইট হেডার ও Chat Lottie অ্যানিমেশন (১৩০-১৫০px)
  Widget _buildHeader(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Action Row with Back Button and Badge
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  InkWell(
                    onTap: () => Navigator.of(context).pop(),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF4F6F4),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE2E8E2), width: 1),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary, size: 15),
                          SizedBox(width: 5),
                          Text(
                            'ফিরে যান',
                            style: TextStyle(
                              color: AppColors.textPrimary,
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
                      color: const Color(0xFFE8F5E9),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFA5D6A7), width: 1),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.rate_review_rounded, color: Color(0xFF00A86B), size: 15),
                        SizedBox(width: 5),
                        Text(
                          'সরাসরি অভিযোগ ও মতামত',
                          style: TextStyle(
                            color: Color(0xFF1B5E20),
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              // Chat.json Lottie Animation (140x140px, loop)
              Center(
                child: SizedBox(
                  width: 140,
                  height: 140,
                  child: Lottie.asset(
                    'assets/animation/Chat.json',
                    fit: BoxFit.contain,
                    repeat: true,
                  ),
                ),
              ),

              const SizedBox(height: 8),

              const Center(
                child: Text(
                  'সরাসরি সাপোর্টে অভিযোগ জানান',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.3,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              const Center(
                child: Text(
                  'আপনার যেকোনো সমস্যা, মতামত বা অভিযোগ জানাতে নিচের তথ্যগুলো পূরণ করুন',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12.5,
                    height: 1.35,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// ২. অভিযোগ ও মতামত ইনপুট ফর্ম কার্ড (খালি ফিল্ড ও প্রোপার প্লেসহোল্ডার)
  Widget _buildFormCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFDCE6DC), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Title & Instruction
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.edit_note_rounded,
                    color: Color(0xFF00A86B),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'অভিযোগের বিবরণ পূরণ করুন',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        'তথ্যগুলো নির্ভুলভাবে লিখুন যেন দ্রুত সমাধান দেওয়া সম্ভব হয়',
                        style: TextStyle(
                          fontSize: 11.5,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),
            const Divider(color: Color(0xFFEFF3EF), height: 1),
            const SizedBox(height: 16),

            // ================= 1. NAME FIELD =================
            _buildFieldLabel('আপনার পুরো নাম'),
            const SizedBox(height: 6),
            TextFormField(
              controller: _nameController,
              style: _lockedInputStyle,
              decoration: _inputDecoration(
                hintText: 'আপনার পুরো নাম লিখুন *',
                prefixIcon: Icons.person_outline_rounded,
              ),
              validator: (val) {
                if (val == null || val.trim().isEmpty) {
                  return 'অনুগ্রহ করে এই ঘরটি পূরণ করুন';
                }
                return null;
              },
            ),

            const SizedBox(height: 16),

            // ================= 2. ADDRESS FIELD =================
            _buildFieldLabel('আপনার ঠিকানা (জেলা, উপজেলা, গ্রাম)'),
            const SizedBox(height: 6),
            TextFormField(
              controller: _addressController,
              style: _lockedInputStyle,
              decoration: _inputDecoration(
                hintText: 'আপনার জেলা, উপজেলা ও গ্রামের ঠিকানা দিন *',
                prefixIcon: Icons.location_on_outlined,
              ),
              validator: (val) {
                if (val == null || val.trim().isEmpty) {
                  return 'অনুগ্রহ করে এই ঘরটি পূরণ করুন';
                }
                return null;
              },
            ),

            const SizedBox(height: 16),

            // ================= 3. CATEGORY DROPDOWN =================
            _buildFieldLabel('সমস্যা বা সেবার ধরন / ক্যাটাগরি'),
            const SizedBox(height: 6),
            FormField<String>(
              initialValue: _selectedCategory,
              validator: (val) {
                if (_selectedCategory == null || _selectedCategory!.trim().isEmpty) {
                  return 'অনুগ্রহ করে এই ঘরটি পূরণ করুন';
                }
                return null;
              },
              builder: (state) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFF9FAF9),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: state.hasError ? const Color(0xFFE53935) : const Color(0xFFDCE4DC),
                          width: state.hasError ? 1.4 : 1.2,
                        ),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedCategory,
                          hint: const Text(
                            'সমস্যার বিষয় নির্বাচন করুন *',
                            style: TextStyle(
                              fontSize: 13.5,
                              color: AppColors.textHint,
                              fontWeight: FontWeight.normal,
                            ),
                          ),
                          isExpanded: true,
                          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF00A86B)),
                          borderRadius: BorderRadius.circular(16),
                          style: _lockedInputStyle,
                          items: _categories.map((String cat) {
                            final isUpdate = cat == 'লগইন তথ্য হালনাগাদ';
                            return DropdownMenuItem<String>(
                              value: cat,
                              child: Row(
                                children: [
                                  Icon(
                                    isUpdate ? Icons.manage_accounts_rounded : Icons.label_important_outline_rounded,
                                    size: 18,
                                    color: const Color(0xFF00A86B),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      cat,
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: isUpdate ? const Color(0xFF007945) : AppColors.textPrimary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                          onChanged: (String? val) {
                            setState(() {
                              _selectedCategory = val;
                            });
                            state.didChange(val);

                            if (val == 'লগইন তথ্য হালনাগাদ') {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: const Text('লগইন তথ্য হালনাগাদের জন্য আলাদা ফর্ম পেজও রয়েছে।'),
                                  action: SnackBarAction(
                                    label: 'পেজে যান',
                                    textColor: Colors.amberAccent,
                                    onPressed: () {
                                      Navigator.of(context, rootNavigator: true).push(
                                        MaterialPageRoute(builder: (_) => const UpdateLoginCredentialsScreen()),
                                      );
                                    },
                                  ),
                                  behavior: SnackBarBehavior.floating,
                                  duration: const Duration(seconds: 4),
                                ),
                              );
                            }
                          },
                        ),
                      ),
                    ),
                    if (state.hasError) ...[
                      const SizedBox(height: 6),
                      Padding(
                        padding: const EdgeInsets.only(left: 12),
                        child: Text(
                          state.errorText ?? 'অনুগ্রহ করে এই ঘরটি পূরণ করুন',
                          style: const TextStyle(
                            color: Color(0xFFE53935),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ],
                );
              },
            ),

            // If login credentials update selected, show quick shortcut banner
            if (_selectedCategory == 'লগইন তথ্য হালনাগাদ') ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFA5D6A7), width: 1),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline_rounded, color: Color(0xFF00A86B), size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'লগইন তথ্য (মোবাইল/পাসওয়ার্ড) পরিবর্তন',
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1B5E20),
                            ),
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'নিরাপদ ভেরিফিকেশনের মাধ্যমে লগইন তথ্য পরিবর্তনের জন্য ডেডিকেটেড পেজ ব্যবহার করুন।',
                            style: TextStyle(fontSize: 11, color: Color(0xFF2E7D32)),
                          ),
                          const SizedBox(height: 6),
                          InkWell(
                            onTap: () {
                              Navigator.of(context, rootNavigator: true).push(
                                MaterialPageRoute(builder: (_) => const UpdateLoginCredentialsScreen()),
                              );
                            },
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'লগইন তথ্য হালনাগাদ পেজে যান',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF00A86B),
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                                SizedBox(width: 4),
                                Icon(Icons.arrow_forward_rounded, size: 14, color: Color(0xFF00A86B)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 16),

            // ================= 4. DETAILS MULTILINE =================
            _buildFieldLabel('অভিযোগ বা মতামতের বিস্তারিত বিবরণ'),
            const SizedBox(height: 6),
            TextFormField(
              controller: _detailsController,
              minLines: 4,
              maxLines: 6,
              style: _lockedInputStyle,
              decoration: _inputDecoration(
                hintText: 'আপনার অভিযোগ বা সমস্যার বিস্তারিত এখানে লিখুন *',
                prefixIcon: Icons.notes_rounded,
                isMultiline: true,
              ),
              validator: (val) {
                if (val == null || val.trim().isEmpty) {
                  return 'অনুগ্রহ করে এই ঘরটি পূরণ করুন';
                }
                return null;
              },
            ),

            const SizedBox(height: 24),

            // ================= 5. SUBMIT BUTTON =================
            InkWell(
              onTap: _isSubmitting ? null : _handleSubmitComplaint,
              borderRadius: BorderRadius.circular(14),
              child: Container(
                height: 50,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFF00A86B), // Vivid Emerald Green
                      Color(0xFF008955),
                      Color(0xFF1B5E20), // Deep Forest Green
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF00A86B).withOpacity(0.35),
                      blurRadius: 12,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.send_rounded, color: Colors.white, size: 18),
                    SizedBox(width: 8),
                    Text(
                      'মেসেজ পাঠান',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.2,
                      ),
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

  /// ৩. "পূর্ববর্তী বার্তা ও সাপোর্ট স্ট্যাটাস" কম্প্যাক্ট শর্টকাট লিস্ট ও মডাল
  Widget _buildTicketsHistorySection(BuildContext context, String currentUserId) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.history_rounded, size: 20, color: Color(0xFF00A86B)),
            SizedBox(width: 8),
            Text(
              'আপনার পূর্ববর্তী বার্তা ও সাপোর্ট স্ট্যাটাস',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance
              .collection('support_tickets')
              .where('userId', isEqualTo: currentUserId)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
              return Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE4EDE4)),
                ),
                child: const Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF00A86B)),
                      ),
                      SizedBox(width: 12),
                      Text('পূর্ববর্তী বার্তা লোড হচ্ছে...', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                    ],
                  ),
                ),
              );
            }

            final allDocs = snapshot.data?.docs ?? [];
            final userDocs = List<QueryDocumentSnapshot<Map<String, dynamic>>>.from(allDocs);

            // ইন-মেমোরি ডিসেন্ডিং টাইমস্ট্যাম্প অনুযায়ী সাজানো
            userDocs.sort((a, b) {
              final tA = a.data()['createdAt'] ?? a.data()['timestamp'];
              final tB = b.data()['createdAt'] ?? b.data()['timestamp'];
              final dateA = (tA is Timestamp) ? tA.toDate() : DateTime.fromMillisecondsSinceEpoch(0);
              final dateB = (tB is Timestamp) ? tB.toDate() : DateTime.fromMillisecondsSinceEpoch(0);
              return dateB.compareTo(dateA);
            });

            if (userDocs.isEmpty) {
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 22),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE4EDE4)),
                ),
                child: Column(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: const BoxDecoration(
                        color: Color(0xFFF1F8F1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.inbox_rounded, color: Color(0xFF00A86B), size: 26),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'আপনার কোনো পূর্ববর্তী সাপোর্ট হিস্ট্রি নেই',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'যেকোনো সহায়তার জন্য উপরের ফর্ম থেকে নির্দ্বিধায় মেসেজ পাঠাতে পারেন।',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              );
            }

            // কম্প্যাক্ট শর্টকাট লিস্ট
            return ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: userDocs.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final doc = userDocs[index];
                final data = doc.data();
                final subject = data['category']?.toString() ?? data['subject']?.toString() ?? 'সহায়তা অনুসন্ধান';
                final status = data['status']?.toString() ?? 'pending';
                final ts = data['createdAt'] ?? data['timestamp'];
                final date = (ts is Timestamp) ? ts.toDate() : DateTime.now();

                final isAnswered = status == 'answered' || status == 'resolved' || status == 'accepted';
                final isRejected = status == 'closed' || status == 'rejected';

                return InkWell(
                  onTap: () => _showTicketDetailModal(context, data),
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isAnswered
                            ? const Color(0xFFA5D6A7)
                            : (isRejected ? const Color(0xFFFFCDD2) : const Color(0xFFE4EDE4)),
                        width: 1.1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.02),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        // আইকন
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: isAnswered
                                ? const Color(0xFFE8F5E9)
                                : (isRejected ? const Color(0xFFFFEBEE) : const Color(0xFFF1F8F1)),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            isAnswered
                                ? Icons.mark_email_read_outlined
                                : (isRejected ? Icons.mail_lock_outlined : Icons.mail_outline_rounded),
                            color: isAnswered
                                ? const Color(0xFF00A86B)
                                : (isRejected ? const Color(0xFFD32F2F) : const Color(0xFF00A86B)),
                            size: 19,
                          ),
                        ),
                        const SizedBox(width: 12),

                        // বিষয় ও তারিখ
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                subject,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  const Icon(Icons.schedule_rounded, size: 12, color: Color(0xFF8D99AE)),
                                  const SizedBox(width: 4),
                                  Text(
                                    DateFormatter.formatRelativeBangla(date),
                                    style: const TextStyle(
                                      fontSize: 11.5,
                                      color: Color(0xFF8D99AE),
                                      fontFeatures: [FontFeature.tabularFigures()],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),

                        // ছোট স্ট্যাটাস ব্যাজ: অপেক্ষমাণ / গৃহীত / বাতিল
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: isAnswered
                                ? const Color(0xFFE8F5E9)
                                : (isRejected ? const Color(0xFFFFEBEE) : const Color(0xFFFFF3E0)),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            isAnswered ? 'গৃহীত' : (isRejected ? 'বাতিল' : 'অপেক্ষমাণ'),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: isAnswered
                                  ? const Color(0xFF2E7D32)
                                  : (isRejected ? const Color(0xFFC62828) : const Color(0xFFE65100)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Icon(Icons.chevron_right_rounded, size: 20, color: Color(0xFFB0BEC5)),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }

  /// বিস্তারিত পপ-আপ মডাল
  void _showTicketDetailModal(BuildContext context, Map<String, dynamic> ticket) {
    final status = ticket['status']?.toString() ?? 'pending';
    final isAnswered = status == 'answered' || status == 'resolved' || status == 'accepted';
    final isRejected = status == 'closed' || status == 'rejected';
    final ts = ticket['createdAt'] ?? ticket['timestamp'];
    final date = (ts is Timestamp) ? ts.toDate() : DateTime.now();
    final senderName = (ticket['userName'] ?? ticket['authorName'] ?? 'কৃষক ভাই').toString();
    final senderPhone = (ticket['userPhone'] ?? ticket['authorPhone'] ?? '').toString();
    final subject = (ticket['category'] ?? ticket['subject'] ?? 'সহায়তা অনুসন্ধান').toString();
    final details = (ticket['message'] ?? ticket['details'] ?? 'কোনো বিবরণ নেই').toString();
    final replyText = (ticket['adminReply'] ?? ticket['officerReply'] ?? ticket['reply'] ?? ticket['rejectionReason'] ?? '').toString().trim();

    showDialog(
      context: context,
      useRootNavigator: true,
      builder: (dialogCtx) => Dialog(
        backgroundColor: Colors.white,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            subject,
                            style: const TextStyle(
                              fontSize: 16.5,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Row(
                            children: [
                              const Icon(Icons.schedule_rounded, size: 13, color: Color(0xFF8D99AE)),
                              const SizedBox(width: 4),
                              Text(
                                DateFormatter.formatBanglaDateTime(date),
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF8D99AE),
                                  fontFeatures: [FontFeature.tabularFigures()],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    // Status Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: isAnswered
                            ? const Color(0xFFE8F5E9)
                            : (isRejected ? const Color(0xFFFFEBEE) : const Color(0xFFFFF3E0)),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isAnswered
                              ? const Color(0xFFA5D6A7)
                              : (isRejected ? const Color(0xFFFFCDD2) : const Color(0xFFFFE0B2)),
                        ),
                      ),
                      child: Text(
                        isAnswered ? 'গৃহীত (সমাধান)' : (isRejected ? 'বাতিল' : 'অপেক্ষমাণ'),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isAnswered
                              ? const Color(0xFF2E7D32)
                              : (isRejected ? const Color(0xFFC62828) : const Color(0xFFE65100)),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 14),
                const Divider(height: 1, color: Color(0xFFEFF3EF)),
                const SizedBox(height: 14),

                // Sender Info Badge
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F8F1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFE4EDE4)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.person_outline_rounded, size: 16, color: Color(0xFF00A86B)),
                      const SizedBox(width: 6),
                      Text(
                        senderName.isNotEmpty ? senderName : 'কৃষক ভাই',
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      if (senderPhone.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        Text('•', style: TextStyle(color: Colors.grey.shade400)),
                        const SizedBox(width: 8),
                        const Icon(Icons.phone_outlined, size: 14, color: Color(0xFF00A86B)),
                        const SizedBox(width: 4),
                        Text(
                          senderPhone,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // User's Original Message
                const Text(
                  'আপনার প্রেরিত বার্তা / অভিযোগ:',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9FAF9),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE4EDE4)),
                  ),
                  child: Text(
                    details,
                    style: const TextStyle(
                      fontSize: 13.5,
                      color: AppColors.textPrimary,
                      height: 1.45,
                    ),
                  ),
                ),

                // Admin / Officer Reply or Action
                if (isAnswered && replyText.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  const Text(
                    'কর্মকর্তার পদক্ষেপ ও পরামর্শ:',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1B5E20),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F8F1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFC8E6C9)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.check_circle_rounded, size: 15, color: Color(0xFF00A86B)),
                            const SizedBox(width: 6),
                            Text(
                              ticket['officerName'] != null && ticket['officerName'].toString().isNotEmpty
                                  ? '${ticket['officerName']} এর উত্তর:'
                                  : 'সাপোর্ট টিমের উত্তর:',
                              style: const TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1B5E20),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          replyText,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF2E7D32),
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ] else if (isRejected) ...[
                  const SizedBox(height: 14),
                  const Text(
                    'বাতিলের কারণ / নোট:',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFFC62828),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFEBEE),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFFFCDD2)),
                    ),
                    child: Text(
                      replyText.isNotEmpty
                          ? replyText
                          : 'আপনার অনুরোধটি সংশ্লিষ্ট নীতিমালার সাথে সামঞ্জস্যপূর্ণ না হওয়ায় বাতিল করা হয়েছে।',
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFFC62828),
                        height: 1.4,
                      ),
                    ),
                  ),
                ] else ...[
                  const SizedBox(height: 14),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF8E1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFFFE082)),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.hourglass_top_rounded, size: 18, color: Color(0xFFF57F17)),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'আপনার বার্তাটি বর্তমানে আমাদের সাপোর্ট টিম পর্যালোচনা করছে। দ্রুত সমাধান জানানো হবে।',
                            style: TextStyle(fontSize: 12, color: Color(0xFF7F4E00), height: 1.35),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 20),

                // Close Button
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(dialogCtx).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00A86B),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: const Text('ঠিক আছে', style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFieldLabel(String label) {
    return Row(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(width: 4),
        const Text(
          '*',
          style: TextStyle(
            color: Color(0xFFE53935),
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  InputDecoration _inputDecoration({
    required String hintText,
    required IconData prefixIcon,
    bool isMultiline = false,
  }) {
    return InputDecoration(
      isDense: true,
      hintText: hintText,
      hintStyle: const TextStyle(
        fontSize: 13.5,
        color: AppColors.textHint,
        fontWeight: FontWeight.normal,
      ),
      filled: true,
      fillColor: const Color(0xFFF9FAF9),
      prefixIcon: isMultiline
          ? Padding(
              padding: const EdgeInsets.only(bottom: 60),
              child: Icon(prefixIcon, color: const Color(0xFF00A86B), size: 20),
            )
          : Icon(prefixIcon, color: const Color(0xFF00A86B), size: 20),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFDCE4DC), width: 1.2),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFDCE4DC), width: 1.2),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF00A86B), width: 1.6),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE53935), width: 1.2),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE53935), width: 1.6),
      ),
    );
  }
}
