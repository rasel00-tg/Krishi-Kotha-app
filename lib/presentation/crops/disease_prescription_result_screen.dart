import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../data/models/disease_diagnosis_result.dart';
import '../../data/services/disease_detection_service.dart';
import '../../data/services/prescription_pdf_service.dart';

/// ২. বিস্তারিত পেজ (No Container, Full Screen Plain View)
/// সম্পূর্ণ পরিষ্কার, এজ-টু-এজ স্ক্রিন ফিট এবং পড়া সহজ ডিজাইন
class DiseasePrescriptionResultScreen extends StatelessWidget {
  final DiseaseDiagnosisResult result;

  const DiseasePrescriptionResultScreen({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    // প্রযুক্তিগত শর্ত: Firestore StreamBuilder বজায় রাখা হয়েছে
    return StreamBuilder<DiseaseDiagnosisResult?>(
      stream: DiseaseDetectionService.instance.getPrescriptionLiveStream(result.id),
      initialData: result,
      builder: (context, snapshot) {
        // ১. হিস্ট্রি থেকে পূর্ণাঙ্গ ডেটা লোড: লাইভ আপডেট পাওয়া গেলে তা ব্যবহার করবে, অন্যথায় পাস হওয়া মডেল
        final live = snapshot.data;
        final data = (live != null && (live.causesAndSymptoms.isNotEmpty || live.organicCures.isNotEmpty || live.chemicalCures.isNotEmpty))
            ? live
            : result;

        return Scaffold(
          backgroundColor: const Color(0xFFF9FBF9),
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0.5,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary, size: 20),
              onPressed: () => Navigator.maybePop(context),
            ),
            title: const Text(
              'KrishiMate AI পরামর্শ ও সমাধান',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1B5E20),
              ),
            ),
            actions: [
              IconButton(
                tooltip: 'শেয়ার করুন',
                icon: const Icon(Icons.share_rounded, color: Color(0xFF2E7D32)),
                onPressed: () => PrescriptionPdfService.shareOrDownloadPrescription(context, data),
              ),
              IconButton(
                tooltip: 'প্রিন্ট / ডাউনলোড',
                icon: const Icon(Icons.print_rounded, color: Color(0xFF2E7D32)),
                onPressed: () => PrescriptionPdfService.printPrescription(context, data),
              ),
              const SizedBox(width: 4),
            ],
          ),
          body: Stack(
            children: [
              // ফুল স্ক্রিন এজ-টু-এজ প্লেইন ভিউ (কোনো জটিল নেস্টেড বক্স ফ্রেম বা সাইড কন্টেইনার নেই)
              SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 12.0).copyWith(bottom: 110.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ১. ব্যবহারকারীর সম্পূর্ণ প্রশ্ন ("আপনার প্রশ্ন:")
                    _buildUserQuestionSection(data),

                    const SizedBox(height: 18),

                    // ২. KrishiMate AI এর সম্পূর্ণ উত্তর ("KrishiMate AI এর পরামর্শ:")
                    _buildAiAdviceSection(data),
                  ],
                ),
              ),

              // পেজের নিচে ফিক্সড অ্যাকশন বার (নতুন করে শনাক্ত ও পরামর্শ ডাউনলোড/শেয়ার)
              _buildFixedBottomActionBar(context, data),
            ],
          ),
        );
      },
    );
  }

  /// ১. ব্যবহারকারীর সম্পূর্ণ প্রশ্ন সেকশন ("আপনার প্রশ্ন:")
  Widget _buildUserQuestionSection(DiseaseDiagnosisResult data) {
    final queryText = data.userSymptoms?.isNotEmpty == true
        ? data.userSymptoms!
        : (data.causesAndSymptoms.isNotEmpty
            ? data.causesAndSymptoms.first
            : data.diseaseName);

    final hasLocalImage = data.localImagePath != null &&
        data.localImagePath!.isNotEmpty &&
        File(data.localImagePath!).existsSync();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // শিরোনাম: "আপনার প্রশ্ন:"
        const Row(
          children: [
            Icon(Icons.help_outline_rounded, color: Color(0xFF2E7D32), size: 20),
            SizedBox(width: 8),
            Text(
              'আপনার প্রশ্ন:',
              style: TextStyle(
                fontSize: 16.5,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1B5E20),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // সম্পূর্ণ টেক্সট (বড়, চওড়া ও সহজে পড়ার মতো)
        Text(
          queryText,
          style: const TextStyle(
            fontSize: 14.5,
            fontWeight: FontWeight.w600,
            color: Color(0xFF263238),
            height: 1.45,
          ),
        ),

        // ছবি থাকলে ফুল প্রিভিউ
        if (hasLocalImage) ...[
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Image.file(
              File(data.localImagePath!),
              width: double.infinity,
              maxHeight: 280,
              fit: BoxFit.cover,
            ),
          ),
        ] else if (data.imageUrl != null && data.imageUrl!.isNotEmpty) ...[
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Image.network(
              data.imageUrl!,
              width: double.infinity,
              maxHeight: 280,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const SizedBox(),
            ),
          ),
        ],

        const SizedBox(height: 14),
        const Divider(color: Color(0xFFE0E0E0), height: 1.2),
      ],
    );
  }

  /// ২. KrishiMate AI এর সম্পূর্ণ উত্তর সেকশন ("KrishiMate AI এর পরামর্শ:")
  Widget _buildAiAdviceSection(DiseaseDiagnosisResult data) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // শিরোনাম: "KrishiMate AI এর পরামর্শ:"
        const Row(
          children: [
            Icon(Icons.psychology_rounded, color: Color(0xFF2E7D32), size: 22),
            SizedBox(width: 8),
            Text(
              'KrishiMate AI এর পরামর্শ:',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1B5E20),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // ফসলের নাম ও চিহ্নিত রোগ ব্যানার (Edge-to-Edge Plain View)
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFE8F5E9), Color(0xFFF1F8E9)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFC8E6C9), width: 1.2),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2E7D32),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'আক্রান্ত ফসল: ${data.plantName}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  Text(
                    'নির্ভুলতা: ${data.confidence}',
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF2E7D32),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                data.diseaseName,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF1B5E20),
                  height: 1.25,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // ১. প্রধান লক্ষণ ও ক্ষতির মাত্রা
        if (data.causesAndSymptoms.isNotEmpty) ...[
          const Row(
            children: [
              Icon(Icons.checklist_rounded, size: 18, color: Color(0xFF0288D1)),
              SizedBox(width: 8),
              Text(
                'প্রধান লক্ষণ ও ক্ষতির মাত্রা:',
                style: TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0288D1),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ...data.causesAndSymptoms.map((point) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 3.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 6.0),
                  child: Icon(Icons.circle, size: 6, color: Color(0xFF0288D1)),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    point,
                    style: const TextStyle(
                      fontSize: 13.5,
                      color: Color(0xFF37474F),
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          )),
          const SizedBox(height: 14),
        ],

        // ২. তাৎক্ষণিক জৈব সমাধান (ঘরোয়া উপায়)
        if (data.organicCures.isNotEmpty) ...[
          const Row(
            children: [
              Icon(Icons.eco_rounded, size: 18, color: Color(0xFF2E7D32)),
              SizedBox(width: 8),
              Text(
                'তাৎক্ষণিক জৈব সমাধান (ঘরোয়া উপায়):',
                style: TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1B5E20),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ...data.organicCures.map((cure) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 3.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 6.0),
                  child: Icon(Icons.circle, size: 6, color: Color(0xFF2E7D32)),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    cure,
                    style: const TextStyle(
                      fontSize: 13.5,
                      color: Color(0xFF2E3D2F),
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          )),
          const SizedBox(height: 14),
        ],

        // ৩. অনুমোদিত রাসায়নিক বালাইনাশক ও ব্যবহারের সঠিক মাত্রা (ডোজ)
        if (data.chemicalCures.isNotEmpty) ...[
          const Row(
            children: [
              Icon(Icons.science_rounded, size: 18, color: Color(0xFFBF360C)),
              SizedBox(width: 8),
              Text(
                'অনুমোদিত রাসায়নিক বালাইনাশক ও মাত্রা:',
                style: TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFFBF360C),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...data.chemicalCures.map((chem) => Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFBEA),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFFFE082), width: 1.0),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        chem.name,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFFBF360C),
                        ),
                      ),
                    ),
                    if (chem.dosage.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFEBEE),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          chem.dosage,
                          style: const TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFFC62828),
                          ),
                        ),
                      ),
                  ],
                ),
                if (chem.instruction.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    chem.instruction,
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: Color(0xFF5D4037),
                      height: 1.35,
                    ),
                  ),
                ],
              ],
            ),
          )),
          const SizedBox(height: 14),
        ],

        // ৪. প্রতিরোধমূলক সতর্কতা ও পরিচর্যা
        if (data.precautionAndCare.isNotEmpty) ...[
          const Row(
            children: [
              Icon(Icons.shield_outlined, size: 18, color: Color(0xFF7B1FA2)),
              SizedBox(width: 8),
              Text(
                'ভবিষ্যৎ সুরক্ষায় প্রতিরোধমূলক পরিচর্যা:',
                style: TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF7B1FA2),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ...data.precautionAndCare.map((tip) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 3.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 6.0),
                  child: Icon(Icons.circle, size: 6, color: Color(0xFF7B1FA2)),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    tip,
                    style: const TextStyle(
                      fontSize: 13.5,
                      color: Color(0xFF37474F),
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          )),
          const SizedBox(height: 14),
        ],

        // জরুরি সতর্কতা (যদি থাকে)
        if (data.emergencyWarning != null && data.emergencyWarning!.isNotEmpty) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFFFEBEE),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFFFCDD2), width: 1.2),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.warning_amber_rounded, color: Color(0xFFD32F2F), size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    data.emergencyWarning!,
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFFC62828),
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  /// পেজের নিচে ফিক্সড অ্যাকশন বার (নতুন করে শনাক্ত ও ডাউনলোড/শেয়ার বাটন)
  Widget _buildFixedBottomActionBar(BuildContext context, DiseaseDiagnosisResult data) {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.96),
          border: const Border(top: BorderSide(color: Color(0xFFE8F5E9), width: 1.2)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Row(
            children: [
              // নতুন করে শনাক্ত করুন বাটন (হিস্ট্রি পেজে স্ট্যাক অনুযায়ী পপ হয়ে ফিরে আসবে)
              Expanded(
                flex: 2,
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.maybePop(context),
                  icon: const Icon(Icons.refresh_rounded, size: 17, color: Color(0xFF2E7D32)),
                  label: const Text(
                    'নতুন করে শনাক্ত',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF2E7D32),
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFF2E7D32), width: 1.4),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    padding: const EdgeInsets.symmetric(vertical: 13),
                  ),
                ),
              ),

              const SizedBox(width: 10),

              // প্রেসক্রিপশন ডাউনলোড / শেয়ার বাটন
              Expanded(
                flex: 3,
                child: Container(
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
                        color: const Color(0xFF2E7D32).withOpacity(0.35),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ElevatedButton.icon(
                    onPressed: () => PrescriptionPdfService.shareOrDownloadPrescription(context, data),
                    icon: const Icon(Icons.download_rounded, color: Colors.white, size: 18),
                    label: const Text(
                      'পরামর্শ ডাউনলোড ও শেয়ার',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
