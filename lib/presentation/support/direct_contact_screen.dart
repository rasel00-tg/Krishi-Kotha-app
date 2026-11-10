import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lottie/lottie.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/app_colors.dart';
import '../../core/widgets/app_unified_dialog.dart';

/// ১. "সরাসরি যোগাযোগ" স্বতন্ত্র নতুন ফুল-স্ক্রিন পেজ
class DirectContactScreen extends StatelessWidget {
  const DirectContactScreen({super.key});

  void _showFeatureNotAvailableDialog(BuildContext context) {
    AppUnifiedDialog.showWarning(
      context,
      title: 'এই ফিচারটি এখনো চালু হয়নি',
      message: 'এই ফিচারটি এখনো চালু হয়নি। সংশ্লিষ্ট কর্তৃপক্ষ শীঘ্রই এই যোগাযোগ চ্যানেলটি চালু করবে।',
      buttonText: 'বুঝেছি',
    );
  }

  Future<void> _handleCall(BuildContext context, String? phone) async {
    if (phone == null || phone.trim().isEmpty) {
      _showFeatureNotAvailableDialog(context);
      return;
    }
    final cleanPhone = phone.replaceAll(RegExp(r'[^0-9+]'), '');
    if (cleanPhone.isEmpty) {
      _showFeatureNotAvailableDialog(context);
      return;
    }
    final uri = Uri.parse('tel:$cleanPhone');
    try {
      final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!launched) {
        await launchUrl(uri);
      }
    } catch (_) {
      try {
        await launchUrl(uri);
      } catch (_) {
        if (context.mounted) _showFeatureNotAvailableDialog(context);
      }
    }
  }

  Future<void> _handleWhatsApp(BuildContext context, String? phone) async {
    if (phone == null || phone.trim().isEmpty) {
      _showFeatureNotAvailableDialog(context);
      return;
    }
    var cleanNumber = phone.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleanNumber.isEmpty) {
      _showFeatureNotAvailableDialog(context);
      return;
    }
    // আন্তর্জাতিক কোড নিশ্চিতকরণ (যেমন: 01xxxxxxxxx হলে 8801xxxxxxxxx)
    if (cleanNumber.startsWith('01')) {
      cleanNumber = '88$cleanNumber';
    }

    final whatsappUri = Uri.parse('whatsapp://send?phone=$cleanNumber');
    final webUri = Uri.parse('https://wa.me/$cleanNumber');

    try {
      final launched = await launchUrl(whatsappUri, mode: LaunchMode.externalApplication);
      if (!launched) {
        await launchUrl(webUri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {
      try {
        await launchUrl(webUri, mode: LaunchMode.externalApplication);
      } catch (_) {
        if (context.mounted) _showFeatureNotAvailableDialog(context);
      }
    }
  }

  Future<void> _handleEmail(BuildContext context, String? email) async {
    if (email == null || email.trim().isEmpty) {
      _showFeatureNotAvailableDialog(context);
      return;
    }
    final cleanEmail = email.trim();
    if (!cleanEmail.contains('@')) {
      _showFeatureNotAvailableDialog(context);
      return;
    }
    final uri = Uri(
      scheme: 'mailto',
      path: cleanEmail,
      queryParameters: {'subject': 'কৃষি কথা সহায়তা'},
    );
    try {
      final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!launched) {
        await launchUrl(uri);
      }
    } catch (_) {
      try {
        await launchUrl(uri);
      } catch (_) {
        if (context.mounted) _showFeatureNotAvailableDialog(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8F5),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 40.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ================= 1. EMERALD HEADER & CONTACT LOTTIE =================
            _buildHeader(context),

            // ================= 2. LIVE CONTACT CHANNELS (STREAMBUILDER) =================
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
              child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                stream: FirebaseFirestore.instance.collection('app_settings').doc('support_contact').snapshots(),
                builder: (context, snapshot) {
                  final settings = snapshot.data?.data();
                  final hotlinePhone = settings?['hotline_phone']?.toString().trim();
                  final hotlineTitle = settings?['hotline_title']?.toString().trim();
                  final whatsappPhone = settings?['whatsapp_phone']?.toString().trim();
                  final whatsappTitle = settings?['whatsapp_title']?.toString().trim();
                  final emailAddress = settings?['email_address']?.toString().trim();
                  final emailTitle = settings?['email_title']?.toString().trim();

                  final isHotlineActive = hotlinePhone != null && hotlinePhone.isNotEmpty;
                  final isWhatsappActive = whatsappPhone != null && whatsappPhone.isNotEmpty;
                  final isEmailActive = emailAddress != null && emailAddress.isNotEmpty;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Section Header
                      const Text(
                        'যোগাযোগ মাধ্যম নির্বাচন করুন',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'যে কোনো চ্যানেলে এক ক্লিকে সংশ্লিষ্ট কর্মকর্তা বা সাপোর্ট টিমের সাথে যুক্ত হোন',
                        style: TextStyle(
                          fontSize: 12.5,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 18),

                      // ৩. আধুনিক প্রিমিয়াম আইকন বাটন সারি (Modern Compact Icon Buttons Row - Centered)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFFE4EDE4), width: 1.2),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.03),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // 1. কল আইকন বাটন
                            _buildChannelIconButton(
                              context: context,
                              label: (hotlineTitle != null && hotlineTitle.isNotEmpty) ? hotlineTitle : 'হটলাইন কল',
                              icon: Icons.phone_in_talk_rounded,
                              gradientColors: const [Color(0xFF00A86B), Color(0xFF008955)],
                              iconColor: Colors.white,
                              isActive: isHotlineActive,
                              onTap: () => _handleCall(context, hotlinePhone),
                            ),

                            const SizedBox(width: 18),

                            // 2. হোয়াটসঅ্যাপ আইকন বাটন
                            _buildChannelIconButton(
                              context: context,
                              label: (whatsappTitle != null && whatsappTitle.isNotEmpty) ? whatsappTitle : 'হোয়াটসঅ্যাপ',
                              icon: Icons.chat_bubble_rounded,
                              gradientColors: const [Color(0xFF25D366), Color(0xFF1EBE5D)],
                              iconColor: Colors.white,
                              isActive: isWhatsappActive,
                              onTap: () => _handleWhatsApp(context, whatsappPhone),
                            ),

                            const SizedBox(width: 18),

                            // 3. ইমেইল আইকন বাটন
                            _buildChannelIconButton(
                              context: context,
                              label: (emailTitle != null && emailTitle.isNotEmpty) ? emailTitle : 'ইমেইল ডেস্ক',
                              icon: Icons.mail_rounded,
                              gradientColors: const [Color(0xFF00897B), Color(0xFF00695C)],
                              iconColor: Colors.white,
                              isActive: isEmailActive,
                              onTap: () => _handleEmail(context, emailAddress),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // চ্যানেলের লাইভ তথ্য ওভারভিউ কার্ড
                      _buildLiveInfoCard(
                        hotlineTitle: hotlineTitle,
                        hotlinePhone: hotlinePhone,
                        whatsappTitle: whatsappTitle,
                        whatsappPhone: whatsappPhone,
                        emailTitle: emailTitle,
                        emailAddress: emailAddress,
                        onCall: () => _handleCall(context, hotlinePhone),
                        onWhatsApp: () => _handleWhatsApp(context, whatsappPhone),
                        onEmail: () => _handleEmail(context, emailAddress),
                      ),

                      const SizedBox(height: 18),

                      // হেল্পডেস্ক সহায়িকা নোটিশ
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F5E9),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFA5D6A7), width: 1),
                        ),
                        child: const Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.verified_user_rounded, color: Color(0xFF2E7D32), size: 20),
                            SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'জরুরি কৃষি সেবা প্রতিশ্রুতি',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF1B5E20),
                                    ),
                                  ),
                                  SizedBox(height: 3),
                                  Text(
                                    'কৃষকদের তাৎক্ষণিক সেবা নিশ্চিত করতে আমাদের টিম প্রস্তুত রয়েছে। সরকারি কার্যদিবসে সরাসরি হটলাইন সেবা সক্রিয় থাকে।',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF2E7D32),
                                      height: 1.35,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// ২. সম্পূর্ণ পরিষ্কার সাদা হেডার ও বড় Lottie অ্যানিমেশন ('assets/animation/contact.json')
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
              // Top Action Row with Back Button & Badge
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
                        Icon(Icons.support_agent_rounded, color: Color(0xFF00A86B), size: 15),
                        SizedBox(width: 5),
                        Text(
                          'সরাসরি যোগাযোগ',
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

              const SizedBox(height: 14),

              // নির্দিষ্ট Lottie অ্যানিমেশন: 'assets/animation/contact.json' (উচ্চতা ও প্রস্থ ২০০ পিক্সেল - বড়, স্পষ্ট ও দৃষ্টিনন্দন)
              Center(
                child: SizedBox(
                  width: 200,
                  height: 200,
                  child: Lottie.asset(
                    'assets/animation/contact.json',
                    width: 200,
                    height: 200,
                    fit: BoxFit.contain,
                    repeat: true,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 90,
                        height: 90,
                        decoration: const BoxDecoration(
                          color: Color(0xFFE8F5E9),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.headset_mic_rounded, color: Color(0xFF00A86B), size: 48),
                      );
                    },
                  ),
                ),
              ),

              const SizedBox(height: 12),

              const Center(
                child: Text(
                  'সরাসরি যোগাযোগ ও সহায়তা',
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
                  'সরকারি কর্মকর্তা ও বিশেষজ্ঞ দলের সাথে যেকোনো প্রয়োজনে সরাসরি যোগাযোগ করুন',
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

  /// আধুনিক ও প্রিমিয়াম আইকন বাটন উইজেট
  Widget _buildChannelIconButton({
    required BuildContext context,
    required String label,
    required IconData icon,
    required List<Color> gradientColors,
    required Color iconColor,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 86,
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: gradientColors,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: gradientColors.first.withOpacity(0.35),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Icon(icon, color: iconColor, size: 26),
                  ),
                ),
                Positioned(
                  right: -2,
                  bottom: -2,
                  child: Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: isActive ? const Color(0xFF00E676) : const Color(0xFFB0BEC5),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// লাইভ ডিটেইলস ইনফো কার্ড
  Widget _buildLiveInfoCard({
    required String? hotlineTitle,
    required String? hotlinePhone,
    required String? whatsappTitle,
    required String? whatsappPhone,
    required String? emailTitle,
    required String? emailAddress,
    required VoidCallback onCall,
    required VoidCallback onWhatsApp,
    required VoidCallback onEmail,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE4EDE4), width: 1.1),
      ),
      child: Column(
        children: [
          _buildInfoRow(
            icon: Icons.phone_in_talk_rounded,
            iconColor: const Color(0xFF00A86B),
            title: (hotlineTitle != null && hotlineTitle.isNotEmpty) ? hotlineTitle : 'কৃষি কল সেন্টার',
            value: (hotlinePhone != null && hotlinePhone.isNotEmpty) ? hotlinePhone : 'এখনো নম্বর যুক্ত করা হয়নি',
            actionText: 'কল করুন',
            actionColor: const Color(0xFF00A86B),
            onAction: onCall,
          ),
          const Divider(height: 1, color: Color(0xFFF1F5F1)),
          _buildInfoRow(
            icon: Icons.chat_bubble_rounded,
            iconColor: const Color(0xFF25D366),
            title: (whatsappTitle != null && whatsappTitle.isNotEmpty) ? whatsappTitle : 'হোয়াটসঅ্যাপ হেল্পলাইন',
            value: (whatsappPhone != null && whatsappPhone.isNotEmpty) ? whatsappPhone : 'এখনো নম্বর যুক্ত করা হয়নি',
            actionText: 'চ্যাট করুন',
            actionColor: const Color(0xFF25D366),
            onAction: onWhatsApp,
          ),
          const Divider(height: 1, color: Color(0xFFF1F5F1)),
          _buildInfoRow(
            icon: Icons.email_rounded,
            iconColor: const Color(0xFF00897B),
            title: (emailTitle != null && emailTitle.isNotEmpty) ? emailTitle : 'অফিসিয়াল ইমেইল ডেস্ক',
            value: (emailAddress != null && emailAddress.isNotEmpty) ? emailAddress : 'এখনো ইমেইল যুক্ত করা হয়নি',
            actionText: 'ইমেইল পাঠান',
            actionColor: const Color(0xFF00897B),
            onAction: onEmail,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String value,
    required String actionText,
    required Color actionColor,
    required VoidCallback onAction,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 12,
                    color: value.contains('যুক্ত করা হয়নি') ? Colors.orange.shade800 : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          InkWell(
            onTap: onAction,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: actionColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: actionColor.withOpacity(0.3), width: 1),
              ),
              child: Text(
                actionText,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.bold,
                  color: actionColor,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

