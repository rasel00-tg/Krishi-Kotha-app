import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:lottie/lottie.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/date_formatter.dart';
import '../../core/widgets/app_unified_dialog.dart';
import '../../data/models/support_ticket_model.dart';
import '../../data/services/firebase_service.dart';
import '../../providers/auth_provider.dart';
import '../../providers/support_provider.dart';
import 'update_login_credentials_screen.dart';

class SupportContactScreen extends StatefulWidget {
  const SupportContactScreen({super.key});

  @override
  State<SupportContactScreen> createState() => _SupportContactScreenState();
}

class _SupportContactScreenState extends State<SupportContactScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _detailsController = TextEditingController();

  final List<String> _subjects = [
    'লগইন তথ্য হালনাগাদ',
    'একাউন্ট সমস্যা',
    'ফসলের রোগ সংক্রান্ত জিজ্ঞাসা',
    'টেকনিক্যাল সমস্যা',
    'সাধারণ পরামর্শ',
    'অন্যান্য',
  ];

  late String _selectedSubject;
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
    // Default to 'একাউন্ট সমস্যা' so the standard form is ready
    _selectedSubject = 'একাউন্ট সমস্যা';
  }

  @override
  void dispose() {
    _detailsController.dispose();
    super.dispose();
  }

  // ==================== TICKET SUBMISSION ====================
  Future<void> _handleSubmitTicket() async {
    final message = _detailsController.text.trim();
    if (message.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('অনুগ্রহ করে আপনার সমস্যা বা পরামর্শের বিবরণ লিখুন।'),
          backgroundColor: AppColors.alertWarning,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);

    final loadingCtrl = AppUnifiedDialog.showLoading(
      context,
      message: 'বার্তা পাঠানো হচ্ছে....',
    );

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final fbUser = FirebaseAuth.instance.currentUser;
      final user = authProvider.user;

      final authorId = user?.uid ?? fbUser?.uid ?? 'guest_user';
      final authorName = user?.name ?? fbUser?.displayName ?? 'সম্মানিত কৃষক';
      final authorPhone = user?.phone ?? fbUser?.phoneNumber ?? '';
      final authorEmail = user?.email ?? fbUser?.email ?? '';
      final district = (user?.district != null && user!.district.isNotEmpty) ? user.district : 'বগুড়া';
      final upazila = (user?.upazila != null && user!.upazila.isNotEmpty) ? user.upazila : 'সদর';

      final ticketId = 'ticket_${DateTime.now().millisecondsSinceEpoch}';

      final ticketData = {
        'ticketId': ticketId,
        'authorId': authorId,
        'authorName': authorName,
        'authorPhone': authorPhone,
        if (authorEmail.isNotEmpty) 'authorEmail': authorEmail,
        'district': district,
        'upazila': upazila,
        'subject': _selectedSubject,
        'details': message,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
        'timestamp': FieldValue.serverTimestamp(),
      };

      if (FirebaseService.isFirebaseInitialized) {
        await FirebaseFirestore.instance.collection('support_tickets').doc(ticketId).set(ticketData);
      } else {
        final supportProvider = Provider.of<SupportProvider>(context, listen: false);
        await supportProvider.submitTicket(
          authorId: authorId,
          authorName: authorName,
          authorPhone: authorPhone,
          authorEmail: authorEmail,
          district: district,
          upazila: upazila,
          subject: _selectedSubject,
          details: message,
        );
      }

      loadingCtrl.dismiss();

      if (mounted) {
        await AppUnifiedDialog.showSuccess(
          context,
          title: 'বার্তা সফলভাবে গৃহীত হয়েছে!',
          message: 'আপনার বার্তা সফলভাবে গৃহীত হয়েছে! আমাদের সাপোর্ট টিম দ্রুত আপনার সাথে যোগাযোগ করবে।',
          buttonText: 'ঠিক আছে',
        );

        _detailsController.clear();
        setState(() {
          _selectedSubject = 'একাউন্ট সমস্যা';
        });
      }
    } catch (e) {
      debugPrint('Error submitting support ticket: $e');
      loadingCtrl.dismiss();

      if (mounted) {
        await AppUnifiedDialog.showError(
          context,
          title: 'বার্তা পাঠানো সম্ভব হয়নি',
          message: 'একটি অনাকাঙ্ক্ষিত ত্রুটি ঘটেছে। আপনার ইন্টারনেট সংযোগ পরীক্ষা করে পুনরায় চেষ্টা করুন।',
          buttonText: 'আবার চেষ্টা করুন',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  // ==================== EXTERNAL LAUNCHERS & NOTIFICATION ====================
  void _showFeatureNotAvailableDialog() {
    AppUnifiedDialog.showWarning(
      context,
      title: 'এই ফিচারটি এখনো চালু হয়নি',
      message: 'কর্তৃপক্ষ শীঘ্রই এই যোগাযোগ চ্যানেলটি চালু করবে। যেকোনো সহায়তার জন্য নিচের ফর্ম থেকে আমাদের ইন-অ্যাপ বার্তা পাঠান।',
      buttonText: 'বুঝেছি',
    );
  }

  Future<void> _launchCall(String? phone) async {
    if (phone == null || phone.trim().isEmpty) {
      _showFeatureNotAvailableDialog();
      return;
    }
    final cleanPhone = phone.replaceAll(RegExp(r'[^0-9+]'), '');
    final uri = Uri.parse('tel:$cleanPhone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      _showFeatureNotAvailableDialog();
    }
  }

  Future<void> _launchWhatsApp(String? phone) async {
    if (phone == null || phone.trim().isEmpty) {
      _showFeatureNotAvailableDialog();
      return;
    }
    final cleanPhone = phone.replaceAll(RegExp(r'[^0-9]'), '');
    final uri = Uri.parse('https://wa.me/$cleanPhone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      _showFeatureNotAvailableDialog();
    }
  }

  Future<void> _launchEmail(String? email) async {
    if (email == null || email.trim().isEmpty) {
      _showFeatureNotAvailableDialog();
      return;
    }
    final uri = Uri.parse('mailto:$email?subject=কৃষি কথা সহায়তা অনুসন্ধান');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      _showFeatureNotAvailableDialog();
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final supportProvider = Provider.of<SupportProvider>(context);
    final user = authProvider.user;
    final currentUserId = user?.uid ?? FirebaseAuth.instance.currentUser?.uid ?? 'guest_user';

    return Scaffold(
      backgroundColor: const Color(0xFFF6F8F5),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        // Generous bottom padding to ensure smooth scroll above fixed bottom navbar
        padding: const EdgeInsets.only(bottom: kBottomNavigationBarHeight + 64.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ================= 1. EMERALD GREEN HEADER (NATURAL SCROLL) =================
            _buildEmeraldHeader(context),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ================= 2. LIVE ACTION CARDS (Call, WhatsApp, Email) =================
                  StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                    stream: FirebaseFirestore.instance.collection('app_settings').doc('support_contact').snapshots(),
                    builder: (context, snapshot) {
                      final settings = snapshot.data?.data();
                      return Column(
                        children: [
                          _buildCallCenterCard(settings),
                          const SizedBox(height: 10),
                          _buildWhatsAppCard(settings),
                          const SizedBox(height: 10),
                          _buildEmailCard(settings),
                        ],
                      );
                    },
                  ),

                  const SizedBox(height: 24),

                  // ================= 3. IN-APP SUPPORT FORM =================
                  _buildInAppTicketForm(),

                  const SizedBox(height: 24),

                  // ================= 4. REAL-TIME USER TICKETS SHORTCUT STREAM =================
                  _buildTicketsHistorySection(supportProvider, currentUserId),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 1. সিগনেচার এমারেল্ড গ্রিন কার্ভড হেডার (Enlarged Lottie Animation 150x150, Natural Scroll)
  Widget _buildEmeraldHeader(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFF00A86B), // Vivid Emerald Green
            Color(0xFF008955),
            Color(0xFF1B5E20), // Deep Forest Green
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Color(0x3500A86B),
            blurRadius: 18,
            offset: Offset(0, 8),
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
              // Top Action Bar with Back Button and 24/7 Pill
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // ফিরে যান ব্যাক বাটন
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

                  // ২৪/৭ সাপোর্ট পিল
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
                        Icon(Icons.headset_mic_rounded, color: Colors.white, size: 14),
                        SizedBox(width: 5),
                        Text(
                          '২৪/৭ সাপোর্ট সেন্টার',
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

              // Prominent Lottie Animation (150x150)
              Center(
                child: SizedBox(
                  width: 150,
                  height: 150,
                  child: Lottie.asset(
                    'assets/animation/Connect with us.json',
                    fit: BoxFit.contain,
                    repeat: true,
                  ),
                ),
              ),

              const SizedBox(height: 10),

              const Center(
                child: Text(
                  'কৃষি সহায়তা ও সাপোর্ট সেন্টার',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.3,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              const Center(
                child: Text(
                  'আপনার যেকোনো সমস্যা বা পরামর্শের জন্য আমরা পাশে আছি',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFFE8F5E9),
                    fontSize: 12.5,
                    height: 1.3,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// ক) কৃষি কল সেন্টার ও হটলাইন (Direct Call from Live Settings)
  Widget _buildCallCenterCard(Map<String, dynamic>? settings) {
    final title = settings?['hotline_title']?.toString().trim();
    final phone = settings?['hotline_phone']?.toString().trim();
    final displayTitle = (title != null && title.isNotEmpty) ? title : 'কৃষি কল সেন্টার (১৬১২৩)';
    final displaySubtitle = (phone != null && phone.isNotEmpty) ? phone : 'সরাসরি সরকারি কর্মকর্তাদের সাথে কথা বলুন';

    return _buildActionCard(
      icon: Icons.phone_in_talk_rounded,
      iconBg: const Color(0xFFE8F5E9),
      iconColor: const Color(0xFF00A86B),
      title: displayTitle,
      subtitle: displaySubtitle,
      badgeText: 'কল করুন',
      badgeBg: const Color(0xFF00A86B),
      onTap: () => _launchCall(phone ?? '16123'),
    );
  }

  /// খ) হোয়াটসঅ্যাপ সাপোর্ট (WhatsApp Chat from Live Settings)
  Widget _buildWhatsAppCard(Map<String, dynamic>? settings) {
    final title = settings?['whatsapp_title']?.toString().trim();
    final phone = settings?['whatsapp_phone']?.toString().trim();
    final displayTitle = (title != null && title.isNotEmpty) ? title : 'হোয়াটসঅ্যাপ সাপোর্ট';
    final displaySubtitle = (phone != null && phone.isNotEmpty) ? phone : 'তাৎক্ষণিক চ্যাট ও দ্রুত পরামর্শ সেবা পেতে মেসেজ দিন';

    return _buildActionCard(
      icon: Icons.chat_bubble_outline_rounded,
      iconBg: const Color(0xFFE8F8F0),
      iconColor: const Color(0xFF25D366),
      title: displayTitle,
      subtitle: displaySubtitle,
      badgeText: 'চ্যাট করুন',
      badgeBg: const Color(0xFF25D366),
      onTap: () => _launchWhatsApp(phone),
    );
  }

  /// গ) ইমেইল সহায়তা (Direct Email from Live Settings)
  Widget _buildEmailCard(Map<String, dynamic>? settings) {
    final title = settings?['email_title']?.toString().trim();
    final email = settings?['email_address']?.toString().trim();
    final displayTitle = (title != null && title.isNotEmpty) ? title : 'ইমেইল সহায়তা';
    final displaySubtitle = (email != null && email.isNotEmpty) ? email : 'support@krishikotha.gov.bd';

    return _buildActionCard(
      icon: Icons.email_outlined,
      iconBg: const Color(0xFFE0F2F1),
      iconColor: const Color(0xFF00897B),
      title: displayTitle,
      subtitle: displaySubtitle,
      badgeText: 'ইমেইল পাঠান',
      badgeBg: const Color(0xFF00897B),
      onTap: () => _launchEmail(email),
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    required String subtitle,
    required String badgeText,
    required Color badgeBg,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE3EAE3), width: 1.2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: iconBg,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 11.5,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: badgeBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                badgeText,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11.5,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// ৩. অ্যাপের ভেতর সাপোর্ট টিকিট / মেসেজ ফর্ম
  Widget _buildInAppTicketForm() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFDCE6DC), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Form Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.edit_note_rounded, color: Color(0xFF00A86B), size: 22),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'আপনার অভিযোগ ও পরামর্শ লিখে পাঠিয়ে দিন',
                        style: TextStyle(
                          fontSize: 15.5,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        'সমস্যা বা পরামর্শ লিখে পাঠালে সাপোর্ট টিম দ্রুত ব্যবস্থা নেবে',
                        style: TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),
            const Divider(color: Color(0xFFEFF3EF), height: 1),
            const SizedBox(height: 16),

            // বিষয়ের ড্রপডাউন (Subject Dropdown)
            const Text(
              'সমস্যা বা বিষয়ের ক্যাটাগরি',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF9FAF9),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFDCE4DC)),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedSubject,
                  isExpanded: true,
                  icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF00A86B)),
                  borderRadius: BorderRadius.circular(16),
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                  items: _subjects.map((String subject) {
                    final isUpdate = subject == 'লগইন তথ্য হালনাগাদ';
                    return DropdownMenuItem<String>(
                      value: subject,
                      child: Row(
                        children: [
                          Icon(
                            isUpdate ? Icons.manage_accounts_rounded : Icons.label_important_outline_rounded,
                            size: 16,
                            color: isUpdate ? const Color(0xFF00A86B) : const Color(0xFF00A86B),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              subject,
                              style: TextStyle(
                                fontWeight: isUpdate ? FontWeight.bold : FontWeight.w600,
                                color: isUpdate ? const Color(0xFF007945) : AppColors.textPrimary,
                              ),
                            ),
                          ),
                          if (isUpdate)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE8F5E9),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                'আলাদা পেজ',
                                style: TextStyle(fontSize: 10, color: Color(0xFF00A86B), fontWeight: FontWeight.bold),
                              ),
                            ),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (String? val) {
                    if (val != null) {
                      if (val == 'লগইন তথ্য হালনাগাদ') {
                        // ২. "লগইন তথ্য হালনাগাদ" নির্বাচন করলে সাথে সাথে স্বতন্ত্র ফুল-স্ক্রিন পেজে নেভিগেশন
                        Navigator.of(context, rootNavigator: true).push(
                          MaterialPageRoute(builder: (_) => const UpdateLoginCredentialsScreen()),
                        );
                      } else {
                        setState(() {
                          _selectedSubject = val;
                        });
                      }
                    }
                  },
                ),
              ),
            ),

            const SizedBox(height: 16),

            // সমস্যার বিস্তারিত বিবরণ (Multi-line Details)
            const Text(
              'সমস্যার বিস্তারিত বিবরণ',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            TextFormField(
              controller: _detailsController,
              minLines: 3,
              maxLines: 5,
              style: _lockedInputStyle,
              decoration: InputDecoration(
                hintText: 'আপনার সমস্যা, প্রশ্ন বা পরামর্শের বিস্তারিত এখানে লিখুন...',
                hintStyle: const TextStyle(color: Color(0xFF9E9E9E), fontSize: 13),
                filled: true,
                fillColor: const Color(0xFFF9FAF9),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                isDense: true,
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

            const SizedBox(height: 18),

            // মেসেজ পাঠান সাবমিট বাটন
            SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton.icon(
                onPressed: _isSubmitting ? null : _handleSubmitTicket,
                icon: const Icon(Icons.send_rounded, size: 18),
                label: const Text(
                  'মেসেজ পাঠান',
                  style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00A86B),
                  foregroundColor: Colors.white,
                  elevation: 2,
                  shadowColor: const Color(0x4000A86B),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// ৪. "আপনার পূর্ববর্তী বার্তা ও সাপোর্ট স্ট্যাটাস" কম্প্যাক্ট শর্টকাট লিস্ট ও বিস্তারিত পপ-আপ মডাল
  Widget _buildTicketsHistorySection(SupportProvider provider, String userId) {
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
        StreamBuilder<List<SupportTicketModel>>(
          stream: provider.getUserTicketsStream(userId),
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

            final tickets = snapshot.data ?? [];
            if (tickets.isEmpty) {
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
                      'আপনার কোনো পূর্ববর্তী বার্তা নেই',
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
              itemCount: tickets.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final ticket = tickets[index];
                final isAnswered = ticket.status == 'answered' || ticket.status == 'resolved';
                final isRejected = ticket.status == 'rejected';

                return InkWell(
                  onTap: () => _showTicketDetailModal(context, ticket),
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
                                ticket.subject,
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
                                    DateFormatter.formatRelativeBangla(ticket.timestamp),
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

                        // ছোট স্ট্যাটাস ব্যাজ
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

  /// বিস্তারিত দেখার ইন্টারেকশন (Popup Details Modal)
  void _showTicketDetailModal(BuildContext context, SupportTicketModel ticket) {
    final isAnswered = ticket.status == 'answered' || ticket.status == 'resolved';
    final isRejected = ticket.status == 'rejected';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Drag Handle
                Center(
                  child: Container(
                    width: 44,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Modal Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            ticket.subject,
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
                                DateFormatter.formatBanglaDateTime(ticket.timestamp),
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
                        isAnswered ? 'গৃহীত (সমাধান)' : (isRejected ? 'বাতিলকৃত' : 'অপেক্ষমাণ'),
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
                    ticket.details,
                    style: const TextStyle(
                      fontSize: 13.5,
                      color: AppColors.textPrimary,
                      height: 1.45,
                    ),
                  ),
                ),

                // Admin / Officer Reply or Action
                if (isAnswered && ticket.officerReply != null && ticket.officerReply!.isNotEmpty) ...[
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
                              ticket.officerName != null && ticket.officerName!.isNotEmpty
                                  ? '${ticket.officerName} এর উত্তর:'
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
                          ticket.officerReply!,
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
                      ticket.officerReply ?? 'তথ্য অসম্পূর্ণ বা অনুপযুক্ত হওয়ায় টিকিটটি বাতিল করা হয়েছে।',
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFFC62828),
                        height: 1.4,
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 20),

                // Close Button
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00A86B),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'বন্ধ করুন',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
