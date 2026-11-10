import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lottie/lottie.dart';
import '../../core/constants/app_colors.dart';

/// ২. "সাধারণ জিজ্ঞাসা (FAQs)" স্বতন্ত্র ফুল-স্ক্রিন পেজ
class FaqScreen extends StatelessWidget {
  const FaqScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8F5),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 50.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ================= 1. WHITE HEADER & FAQS LOTTIE ANIMATION =================
            _buildHeader(context),

            // ================= 2. REAL-TIME FAQS LIST (STREAMBUILDER) =================
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'সচরাচর জিজ্ঞাসিত প্রশ্নাবলি',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'যেকোনো প্রশ্নে ট্যাপ করে বিস্তারিত উত্তর ও সমাধান দেখুন',
                    style: TextStyle(
                      fontSize: 12.5,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 16),

                  StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                    stream: FirebaseFirestore.instance.collection('faqs').snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 40.0),
                            child: CircularProgressIndicator(color: Color(0xFF00A86B)),
                          ),
                        );
                      }

                      if (snapshot.hasError) {
                        return Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0xFFFFCDD2)),
                          ),
                          child: const Center(
                            child: Text(
                              'প্রশ্নোত্তর লোড করতে সমস্যা হয়েছে। অনুগ্রহ করে ইন্টারনেট সংযোগ পরীক্ষা করুন।',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Color(0xFFD32F2F), fontSize: 13),
                            ),
                          ),
                        );
                      }

                      final docs = snapshot.data?.docs ?? [];

                      if (docs.isEmpty) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 36),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFE4EDE4), width: 1.2),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 52,
                                height: 52,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE8F5E9),
                                  borderRadius: BorderRadius.circular(26),
                                ),
                                child: const Icon(Icons.help_outline_rounded, color: Color(0xFF00A86B), size: 28),
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                'বর্তমানে কোনো প্রশ্নোত্তর যুক্ত নেই',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'সংশ্লিষ্ট কর্তৃপক্ষ শীঘ্রই সাধারণ জিজ্ঞাসাসমূহ এখানে যুক্ত করবেন।',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 12.5,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      // Sort in memory by order or timestamp
                      final sortedDocs = List<QueryDocumentSnapshot<Map<String, dynamic>>>.from(docs);
                      sortedDocs.sort((a, b) {
                        final dataA = a.data();
                        final dataB = b.data();
                        final orderA = (dataA['order'] is num) ? (dataA['order'] as num) : 99999;
                        final orderB = (dataB['order'] is num) ? (dataB['order'] as num) : 99999;
                        if (orderA != orderB) {
                          return orderA.compareTo(orderB);
                        }
                        final timeA = dataA['createdAt'];
                        final timeB = dataB['createdAt'];
                        if (timeA is Timestamp && timeB is Timestamp) {
                          return timeB.compareTo(timeA);
                        }
                        return 0;
                      });

                      // ৩. রেফারেন্স ছবির স্টাইলে একর্ডিয়ন (ExpansionTile / Accordion) লিস্ট
                      return ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: sortedDocs.length,
                        itemBuilder: (context, index) {
                          final data = sortedDocs[index].data();
                          final question = (data['question'] ?? '').toString().trim();
                          final answer = (data['answer'] ?? '').toString().trim();

                          return _buildFaqAccordionCard(
                            context: context,
                            question: question,
                            answer: answer,
                            index: index,
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// ১. হেডার ও FAQs Lottie অ্যানিমেশন ('assets/animation/FAQs.json')
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
                        Icon(Icons.quiz_rounded, color: Color(0xFF00A86B), size: 15),
                        SizedBox(width: 5),
                        Text(
                          'সাধারণ জিজ্ঞাসা',
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

              const SizedBox(height: 12),

              // নির্দিষ্ট Lottie অ্যানিমেশন: 'assets/animation/FAQs.json' (উচ্চতা ১৪০-১৬০ পিক্সেল)
              Center(
                child: SizedBox(
                  height: 150,
                  width: 150,
                  child: Lottie.asset(
                    'assets/animation/FAQs.json',
                    fit: BoxFit.contain,
                    repeat: true,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 80,
                        height: 80,
                        decoration: const BoxDecoration(
                          color: Color(0xFFE8F5E9),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.help_center_rounded, color: Color(0xFF00A86B), size: 44),
                      );
                    },
                  ),
                ),
              ),

              const SizedBox(height: 10),

              const Center(
                child: Text(
                  'সাধারণ জিজ্ঞাসা (FAQs)',
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
                  'কৃষি কথা অ্যাপ ব্যবহারের নিয়ম ও সাধারণ প্রশ্নের সরাসরি সমাধান',
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

  /// ৩. রেফারেন্স ছবির স্টাইলে একর্ডিয়ন (ExpansionTile / Accordion) কার্ড
  Widget _buildFaqAccordionCard({
    required BuildContext context,
    required String question,
    required String answer,
    required int index,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 5.0),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FBF9), // হালকা গ্রে/সফট অফ-হোয়াইট ব্যাকগ্রাউন্ড
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE4EDE4), width: 1.1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(
          dividerColor: Colors.transparent, // ডিফল্ট বর্ডার লাইন রিমুভ
        ),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          shape: const Border(),
          collapsedShape: const Border(),
          title: Text(
            question,
            style: const TextStyle(
              fontSize: 14.5,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
              height: 1.35,
            ),
          ),
          trailing: Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5E9),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.keyboard_arrow_down_rounded,
              color: Color(0xFF00A86B),
              size: 22,
            ),
          ),
          children: [
            // উত্তরের ওপরে সূক্ষ্ম ডিভাইডার লাইন
            const Divider(height: 18, thickness: 1, color: Color(0xFFE8EFE8)),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                answer,
                textAlign: TextAlign.left,
                style: const TextStyle(
                  fontSize: 13.5,
                  color: Color(0xFF4A5568),
                  height: 1.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

