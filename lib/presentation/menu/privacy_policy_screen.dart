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
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
          tooltip: 'ফিরে যান',
        ),
        title: const Text(
          'গোপনীয়তা নীতিমালা',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Top App Logo
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 14,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: Padding(
                      padding: const EdgeInsets.all(4.0),
                      child: Image.asset(
                        'assets/icons/pnglogo.png',
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Icon(
                          Icons.eco_rounded,
                          color: AppColors.primary,
                          size: 40,
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

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
                const Text(
                  'সর্বশেষ হালনাগাদ: অক্টোবর ২০২৬ • সংস্করণ ১.০.০',
                  style: TextStyle(
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
                  child: const Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.verified_user_rounded, color: AppColors.primary, size: 26),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'কৃষকের তথ্যের পূর্ণ নিরাপত্তা ও গোপনীয়তা',
                              style: TextStyle(
                                fontSize: 14.5,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primaryDark,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'কৃষি কথা অ্যাপ কৃষকদের আস্থার প্ল্যাটফর্ম। আপনার কোনো ব্যক্তিগত তথ্য বা ফোন নম্বর কখনো কোনো বাণিজ্যিক তৃতীয় পক্ষের কাছে বিক্রি বা শেয়ার করা হয় না।',
                              style: TextStyle(
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

                // Section 1: সংগৃহীত তথ্যাবলী
                _buildPolicyCard(
                  number: '১',
                  title: 'সংগৃহীত তথ্যাবলী',
                  icon: Icons.assignment_outlined,
                  iconColor: const Color(0xFF1565C0),
                  iconBgColor: const Color(0xFFE3F2FD),
                  content:
                      'কৃষকদের সঠিক পরামর্শ ও স্থানীয় সেবা প্রদানের জন্য অ্যাপে নিম্নলিখিত তথ্যগুলো সংগ্রহ করা হয়:',
                  bullets: [
                    'ব্যবহারকারীর নাম: কৃষককে ব্যক্তিগতভাবে সঠিক সম্বোধন ও প্রোফাইল শনাক্তকরণের জন্য।',
                    'মোবাইল নম্বর: ওটিপি (OTP) কোড যাচাইয়ের মাধ্যমে অ্যাকাউন্ট নিরাপত্তা ও সরাসরি যোগাযোগের জন্য।',
                    'লোকেশন (জেলা ও উপজেলা): স্থানীয় সঠিক আবহাওয়া পূর্বাভাস ও মোকামের বাজার দর দেখানোর জন্য।',
                    'পছন্দের ফসল: কৃষকের চাষকৃত ফসল অনুযায়ী উপযুক্ত সার ও বালাইনাশকের সময়োপযোগী নির্দেশনা দিতে।',
                  ],
                ),

                // Section 2: তথ্যের ব্যবহার
                _buildPolicyCard(
                  number: '২',
                  title: 'তথ্যের ব্যবহার',
                  icon: Icons.tune_rounded,
                  iconColor: const Color(0xFF2E7D32),
                  iconBgColor: const Color(0xFFE8F5E9),
                  content:
                      'সংগৃহীত তথ্য কেবলমাত্র কৃষক কল্যাণ ও অ্যাপের কার্যকারিতা বৃদ্ধির উদ্দেশ্যে ব্যবহৃত হয়:',
                  bullets: [
                    'জরুরি দুর্যোগ ও কালবৈশাখী ঝড়ের আবহাওয়ার তাৎক্ষণিক পুশ নোটিফিকেশন প্রদান।',
                    'জমি ও শতক অনুযায়ী ইউরিয়া, টিএসপি, এমওপি সারের সঠিক পরিমাণ হিসাব করা।',
                    'কৃষি কল সেন্টার ১৬১২৩ এবং উপজেলা কৃষি কর্মকর্তাদের সহায়তার সাথে যুক্ত করা।',
                    'অ্যাপের ব্যবহারবান্ধব অভিজ্ঞতা নিশ্চিত ও সমস্যা সমাধানে প্রযুক্তিগত উন্নয়ন।',
                  ],
                ),

                // Section 3: তথ্যের সুরক্ষা ও গোপনীয়তা
                _buildPolicyCard(
                  number: '৩',
                  title: 'তথ্যের সুরক্ষা ও গোপনীয়তা',
                  icon: Icons.shield_outlined,
                  iconColor: const Color(0xFFE65100),
                  iconBgColor: const Color(0xFFFFF3E0),
                  content:
                      'আমরা কঠোর তথ্যের গোপনীয়তা নীতি মেনে চলি এবং ব্যবহারকারীর ডাটা সুরক্ষায় প্রতিশ্রুতিবদ্ধ:',
                  bullets: [
                    'আপনার ডেটা কখনো বিজ্ঞাপন সংস্থা বা বাণিজ্যিক তৃতীয় পক্ষের কাছে হস্তান্তর করা হয় না।',
                    'অ্যাপের ব্যাকগ্রাউন্ডে কোনো অপ্রয়োজনীয় ক্যামেরা, কল বা অবস্থান ট্র্যাকিং চালানো হয় না।',
                    'ব্যবহারকারী যেকোনো সময় তার প্রোফাইল তথ্য হালনাগাদ বা পরিবর্তন করতে পারেন।',
                  ],
                ),

                // Section 4: ফায়ারবেস ও ক্লাউড সিকিউরিটি
                _buildPolicyCard(
                  number: '৪',
                  title: 'ফায়ারবেস ও ক্লাউড সিকিউরিটি',
                  icon: Icons.cloud_done_outlined,
                  iconColor: const Color(0xFF7B1FA2),
                  iconBgColor: const Color(0xFFF3E5F5),
                  content:
                      'কৃষি কথা অ্যাপের সমস্ত রিয়েল-টাইম তথ্য ও অ্যাকাউন্ট গুগল ফায়ারবেস (Firebase Cloud) প্ল্যাটফর্মে পরিচালিত:',
                  bullets: [
                    'Firebase Authentication এর মাধ্যমে নিরাপদ ও এনক্রিপ্টেড ফোন ভেরিফিকেশন ব্যবস্থা।',
                    'Cloud Firestore ডেটাবেসের সিকিউরিটি রুলস দ্বারা ডেটা অ্যাক্সেস কঠোরভাবে নিয়ন্ত্রিত।',
                    'ইন্টারনেট সংযোগ সাময়িক বিচ্ছিন্ন থাকলেও লোকাল অফলাইন ক্যাশিং সুরক্ষার সাথে সংরক্ষিত থাকে।',
                  ],
                ),

                // Section 5: যোগাযোগ ও অভিযোগ প্রতিকার
                _buildPolicyCard(
                  number: '৫',
                  title: 'যোগাযোগ ও অভিযোগ প্রতিকার',
                  icon: Icons.contact_support_outlined,
                  iconColor: const Color(0xFF00897B),
                  iconBgColor: const Color(0xFFE0F2F1),
                  content:
                      'গোপনীয়তা নীতিমালা বা তথ্যের নিরাপত্তা সংক্রান্ত যেকোনো প্রশ্ন বা অভিযোগের ক্ষেত্রে আমাদের সাথে যোগাযোগ করুন:',
                  bullets: [
                    'টোল-ফ্রি হেল্পলাইন: ১৬১২৩ (সরাসরি কৃষি কল সেন্টার, সকাল ৯টা - বিকাল ৫টা)',
                    'ইমেইল সাপোর্ট: support@krishikotha.gov.bd / krishikotha.app@gmail.com',
                    'অফিসিয়াল তত্ত্বাবধান: কৃষি সম্প্রসারণ অধিদপ্তর (DAE), খামারবাড়ি, ঢাকা, বাংলাদেশ',
                  ],
                ),

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

                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
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
          Text(
            content,
            style: const TextStyle(
              fontSize: 13.5,
              color: AppColors.textSecondary,
              height: 1.45,
            ),
          ),

          const SizedBox(height: 10),

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
