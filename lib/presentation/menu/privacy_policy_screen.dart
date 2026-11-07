import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7FAF7),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
          tooltip: 'ফিরে যান',
        ),
        title: const Text(
          'গোপনীয়তা নীতি',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        centerTitle: false,
      ),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('settings')
            .doc('privacy_policy')
            .snapshots(),
        builder: (context, snapshot) {
          final data = snapshot.hasData ? snapshot.data?.data() : null;
          final lastUpdated = data?['last_updated']?.toString() ?? 'সর্বশেষ হালনাগাদ: অক্টোবর ২০২৬ • সংস্করণ ১.০.০';
          final bannerText = data?['banner_text']?.toString() ??
              'কৃষি কথা অ্যাপ কৃষকদের আস্থার প্ল্যাটফর্ম। আপনার কোনো ব্যক্তিগত তথ্য বা ফোন নম্বর কখনো কোনো বাণিজ্যিক তৃতীয় পক্ষের কাছে বিক্রি বা শেয়ার করা হয় না।';
          final customPolicyContent = data?['policy_content']?.toString();

          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            // Extra bottom padding ensures smooth scrolling without overlap from fixed floating navigation bar
            padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 20.0, bottom: 120.0),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 800),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Top App Logo
                    SizedBox(
                      width: 72,
                      height: 72,
                      child: Image.asset(
                        'assets/icons/pnglogo.png',
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => const Icon(
                          Icons.eco_rounded,
                          color: AppColors.primary,
                          size: 48,
                        ),
                      ),
                    ),

                    const SizedBox(height: 14),

                    // Main Title & Subtitle
                    const Text(
                      'কৃষি কথা – গোপনীয়তা ও সুরক্ষা নীতিমালা',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      lastUpdated,
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: AppColors.textMuted,
                        fontWeight: FontWeight.w500,
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Security Highlight Banner
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F5E9),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFC8E6C9)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.verified_user_rounded, color: AppColors.primary, size: 26),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'কৃষকের তথ্যের পূর্ণ নিরাপত্তা ও গোপনীয়তা',
                                  style: TextStyle(
                                    fontSize: 14.5,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primaryDark,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  bannerText,
                                  style: const TextStyle(
                                    fontSize: 12.5,
                                    color: Color(0xFF2E7D32),
                                    height: 1.4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Policy Sections (Dynamic from Firestore or Fallback Defaults)
                    if (customPolicyContent != null && customPolicyContent.trim().isNotEmpty)
                      ..._buildDynamicPolicyContent(customPolicyContent)
                    else
                      ..._buildDefaultPolicySections(),

                    const SizedBox(height: 16),

                    // Footer Note
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        children: [
                          const Text(
                            'কৃষি কথা – Krishi Kotha',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primaryDark,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            'স্মার্ট কৃষিতে কৃষকের সাথে সবসময় • কপিরাইট © ২০২৬ সর্বস্বত্ব সংরক্ষিত',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Extra space at bottom so no overlap occurs even on larger screen density
                    const SizedBox(height: 36),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  /// Parses custom policy content updated by the admin in Firestore
  List<Widget> _buildDynamicPolicyContent(String rawContent) {
    final sectionRegex = RegExp(r'(?:^|\n)(?=([০-৯\d]+[\.\)]\s*))', multiLine: true);
    final rawSections = rawContent.split(sectionRegex).where((s) => s.trim().isNotEmpty).toList();

    if (rawSections.isEmpty) {
      return [_buildFallbackTextCard(rawContent)];
    }

    final icons = [
      Icons.assignment_outlined,
      Icons.tune_rounded,
      Icons.camera_alt_outlined,
      Icons.shield_outlined,
      Icons.cloud_done_outlined,
      Icons.contact_support_outlined,
      Icons.verified_outlined,
      Icons.rule_folder_outlined,
    ];

    final iconColors = [
      const Color(0xFF1565C0),
      const Color(0xFF2E7D32),
      const Color(0xFF00897B),
      const Color(0xFFE65100),
      const Color(0xFF7B1FA2),
      const Color(0xFF0288D1),
      const Color(0xFF43A047),
      const Color(0xFF5E35B1),
    ];

    final iconBgColors = [
      const Color(0xFFE3F2FD),
      const Color(0xFFE8F5E9),
      const Color(0xFFE0F2F1),
      const Color(0xFFFFF3E0),
      const Color(0xFFF3E5F5),
      const Color(0xFFE1F5FE),
      const Color(0xFFE8F8E8),
      const Color(0xFFEDE7F6),
    ];

    final widgets = <Widget>[];

    for (int i = 0; i < rawSections.length; i++) {
      final section = rawSections[i].trim();
      final lines = section.split('\n').map((l) => l.trim()).where((l) => l.isNotEmpty).toList();

      if (lines.isEmpty) continue;

      String header = lines.first;
      String number = (i + 1).toString();
      String title = header;

      final match = RegExp(r'^([০-৯\d]+)[\.\)]\s*(.*)$').firstMatch(header);
      if (match != null) {
        number = match.group(1) ?? (i + 1).toString();
        title = match.group(2) ?? header;
      }

      final contentLines = <String>[];
      final bullets = <String>[];

      for (int j = 1; j < lines.length; j++) {
        final line = lines[j];
        if (line.startsWith('•') || line.startsWith('-') || line.startsWith('*')) {
          bullets.add(line.replaceFirst(RegExp(r'^[•\-\*]\s*'), ''));
        } else {
          contentLines.add(line);
        }
      }

      final content = contentLines.join('\n');
      final iconIdx = i % icons.length;

      widgets.add(
        _buildPolicyCard(
          number: number,
          title: title,
          icon: icons[iconIdx],
          iconColor: iconColors[iconIdx],
          iconBgColor: iconBgColors[iconIdx],
          content: content.isNotEmpty ? content : title,
          bullets: bullets,
        ),
      );
    }

    return widgets;
  }

  Widget _buildFallbackTextCard(String text) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE0E6E0), width: 1.0),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(18),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 13.5,
          color: AppColors.textSecondary,
          height: 1.5,
        ),
      ),
    );
  }

  /// Default 6 policy sections
  List<Widget> _buildDefaultPolicySections() {
    return [
      _buildPolicyCard(
        number: '১',
        title: 'সংগৃহীত তথ্যাবলী ও কৃষকের তথ্য সংগ্রহ',
        icon: Icons.assignment_outlined,
        iconColor: const Color(0xFF1565C0),
        iconBgColor: const Color(0xFFE3F2FD),
        content: 'কৃষকদের সঠিক পরামর্শ ও স্থানীয় কৃষি সেবা প্রদানের জন্য অ্যাপে নিম্নলিখিত তথ্যগুলো সংগ্রহ করা হয়:',
        bullets: const [
          'ব্যবহারকারীর নাম: কৃষককে ব্যক্তিগতভাবে সঠিক সম্বোধন ও প্রোফাইল শনাক্তকরণের জন্য।',
          'মোবাইল নম্বর ও ইমেইল: ওটিপি ও পাসওয়ার্ড যাচাইয়ের মাধ্যমে অ্যাকাউন্ট নিরাপত্তা ও সরাসরি যোগাযোগের জন্য।',
          'লোকেশন (জেলা ও উপজেলা): স্থানীয় সঠিক আবহাওয়া পূর্বাভাস ও মোকামের বাজার দর দেখানোর জন্য।',
          'পছন্দের ফসল: কৃষকের চাষকৃত ফসল অনুযায়ী উপযুক্ত সার ও বালাইনাশকের সময়োপযোগী নির্দেশনা দিতে।',
        ],
      ),
      _buildPolicyCard(
        number: '২',
        title: ' তথ্যের ব্যবহার ও কৃষি সেবা নিশ্চিতকরণ',
        icon: Icons.tune_rounded,
        iconColor: const Color(0xFF2E7D32),
        iconBgColor: const Color(0xFFE8F5E9),
        content: 'সংগৃহীত তথ্য কেবলমাত্র কৃষক কল্যাণ ও অ্যাপের কার্যকারিতা বৃদ্ধির উদ্দেশ্যে ব্যবহৃত হয়:',
        bullets: const [
          'জরুরি দুর্যোগ ও কালবৈশাখী ঝড়ের আবহাওয়ার তাৎক্ষণিক পুশ নোটিফিকেশন প্রদান।',
          'জমি ও শতক অনুযায়ী ইউরিয়া, টিএসপি, এমওপি সারের সঠিক পরিমাণ হিসাব করা।',
          'কৃষি কল সেন্টার ১৬১২৩ এবং উপজেলা কৃষি কর্মকর্তাদের সহায়তার সাথে যুক্ত করা।',
          'অ্যাপের ব্যবহারবান্ধব অভিজ্ঞতা নিশ্চিত ও সমস্যা সমাধানে প্রযুক্তিগত উন্নয়ন।',
        ],
      ),
      _buildPolicyCard(
        number: '৩',
        title: 'ক্যামেরা, অবস্থান ও ছবি ব্যবহারের অনুমতি (KrishiMate AI)',
        icon: Icons.camera_alt_outlined,
        iconColor: const Color(0xFF00897B),
        iconBgColor: const Color(0xFFE0F2F1),
        content: 'রোগবালাই শনাক্তকরণ ও স্থানীয় সেবার জন্য নির্দিষ্ট পারমিশন নেওয়া হয়:',
        bullets: const [
          'ক্যামেরা ও গ্যালারি: "KrishiMate AI" ফিচারে আক্রান্ত ফসলের ছবি তুলে রোগ শনাক্ত ও প্রেসক্রিপশন তৈরির জন্য।',
          'অবস্থান (Location): স্থানীয় আবহাওয়া সতর্কতা ও নিকটের কৃষি বাজার দর নিখুঁতভাবে দেখানোর জন্য।',
          'ব্যাকগ্রাউন্ডে কোনো অপ্রয়োজনীয় ক্যামেরা, কল বা অবস্থান ট্র্যাকিং কখনো চালানো হয় না।',
        ],
      ),
      _buildPolicyCard(
        number: '৪',
        title: 'তথ্যের সুরক্ষা, ডেটা নিরাপত্তা ও গোপনীয়তা',
        icon: Icons.shield_outlined,
        iconColor: const Color(0xFFE65100),
        iconBgColor: const Color(0xFFFFF3E0),
        content: 'আমরা কঠোর তথ্যের গোপনীয়তা নীতি মেনে চলি এবং ব্যবহারকারীর ডাটা সুরক্ষায় প্রতিশ্রুতিবদ্ধ:',
        bullets: const [
          'আপনার ডেটা কখনো বিজ্ঞাপন সংস্থা বা বাণিজ্যিক তৃতীয় পক্ষের কাছে বিক্রি বা হস্তান্তর করা হয় না।',
          'কৃষকের অনুমতি ছাড়া কোনো ব্যক্তিগত তথ্য প্রকাশ করা হয় না।',
          'ব্যবহারকারী যেকোনো সময় তার প্রোফাইল তথ্য হালনাগাদ বা পরিবর্তন করতে পারেন।',
        ],
      ),
      _buildPolicyCard(
        number: '৫',
        title: 'ফায়ারবেস ও ক্লাউড সিকিউরিটি আর্কিটেকচার',
        icon: Icons.cloud_done_outlined,
        iconColor: const Color(0xFF7B1FA2),
        iconBgColor: const Color(0xFFF3E5F5),
        content: 'কৃষি কথা অ্যাপের সমস্ত রিয়েল-টাইম তথ্য ও অ্যাকাউন্ট গুগল ফায়ারবেস (Firebase Cloud) প্ল্যাটফর্মে পরিচালিত:',
        bullets: const [
          'Firebase Authentication এর মাধ্যমে নিরাপদ ও এনক্রিপ্টেড পরিচয় যাচাইকরণ ব্যবস্থা।',
          'Cloud Firestore ডেটাবেসের সিকিউরিটি রুলস দ্বারা কৃষকদের ডেটা অ্যাক্সেস কঠোরভাবে সংরক্ষিত।',
          'ইন্টারনেট সংযোগ সাময়িক বিচ্ছিন্ন থাকলেও লোকাল অফলাইন ক্যাশিং সুরক্ষার সাথে সংরক্ষিত থাকে।',
        ],
      ),
      _buildPolicyCard(
        number: '৬',
        title: 'যোগাযোগ, সহায়তা ও অভিযোগ প্রতিকার',
        icon: Icons.contact_support_outlined,
        iconColor: const Color(0xFF0288D1),
        iconBgColor: const Color(0xFFE1F5FE),
        content: 'গোপনীয়তা নীতিমালা বা তথ্যের নিরাপত্তা সংক্রান্ত যেকোনো প্রশ্ন বা সহায়তার ক্ষেত্রে আমাদের সাথে যোগাযোগ করুন:',
        bullets: const [
          'টোল-ফ্রি হেল্পলাইন: ১৬১২৩ (সরাসরি কৃষি কল সেন্টার, সকাল ৯টা - বিকাল ৫টা)',
          'ইমেইল সাপোর্ট: krishikotha.app@gmail.com',
          'অফিসিয়াল যোগাযোগ: কৃষি সম্প্রসারণ অধিদপ্তর (DAE), খামারবাড়ি, ঢাকা, বাংলাদেশ',
        ],
      ),
    ];
  }

  Widget _buildPolicyCard({
    required String number,
    required String title,
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
    required String content,
    required List<String> bullets,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE0E6E0), width: 1.0),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with Icon & Title
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: iconBgColor,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Icon(icon, color: iconColor, size: 20),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '$number. $title',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Paragraph
          if (content.isNotEmpty)
            Text(
              content,
              style: const TextStyle(
                fontSize: 13.5,
                color: AppColors.textSecondary,
                height: 1.45,
              ),
            ),

          if (bullets.isNotEmpty) const SizedBox(height: 10),

          // Bullet Points
          ...bullets.map(
            (b) => Padding(
              padding: const EdgeInsets.only(bottom: 6.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 6, right: 8),
                    child: Icon(
                      Icons.circle,
                      size: 6,
                      color: AppColors.primary,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      b,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF37474F),
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
