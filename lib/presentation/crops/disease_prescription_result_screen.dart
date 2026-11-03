import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../data/models/disease_diagnosis_result.dart';
import '../../data/services/disease_detection_service.dart';
import '../../data/services/prescription_pdf_service.dart';

class DiseasePrescriptionResultScreen extends StatelessWidget {
  final DiseaseDiagnosisResult result;

  const DiseasePrescriptionResultScreen({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DiseaseDiagnosisResult?>(
      stream: DiseaseDetectionService.instance.getPrescriptionLiveStream(result.id),
      initialData: result,
      builder: (context, snapshot) {
        final data = snapshot.data ?? result;

        return Scaffold(
          backgroundColor: const Color(0xFFF9FBF9),
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0.5,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary, size: 20),
              onPressed: () => Navigator.pop(context),
            ),
            title: const Text(
              'KrishiMate AI পরামর্শ ও সমাধান',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
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
              // মূল স্ক্রলেবল কনটেন্ট (ফুল-উইথ রেসপনসিভ এজ-টু-এজ ভিউ, নিচে ১২০px প্যাডিং)
              SingleChildScrollView(
                padding: const EdgeInsets.only(left: 6.0, right: 6.0, top: 10.0, bottom: 120.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (data.isNonAgri) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFFDE7),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: const Color(0xFFFFF59D), width: 1.2),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.info_outline_rounded, color: Color(0xFFF57F17), size: 22),
                                SizedBox(width: 8),
                                Text(
                                  'শুধুমাত্র কৃষি ও উদ্ভিদ সংরক্ষণ সেবা',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFFE65100),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(
                              data.nonAgriMessage ??
                                  "প্রিয় কৃষক ভাই, 'কৃষি কথা' অ্যাপের এই সেবাটি শুধুমাত্র আপনার ফসল, শাকসবজি, ফলমূল ও উদ্ভিদের যাবতীয় রোগবালাই শনাক্তকরণ ও কৃষি পরামর্শ প্রদানের জন্য তৈরি করা হয়েছে। অনুগ্রহ করে আপনার ফসলের কোনো সমস্যা বা আক্রান্ত পাতার ছবি ও লক্ষণ নিয়ে প্রশ্ন করুন। আমরা আপনাকে সঠিক সমাধান দিতে সদা প্রস্তুত।",
                              style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFF4E342E),
                                height: 1.45,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ] else ...[
                      // ৩.১ আপনার প্রশ্ন / লক্ষণ
                      Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(bottom: 14),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F8E9),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFC8E6C9), width: 1.2),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.help_outline_rounded, size: 17, color: Color(0xFF2E7D32)),
                                SizedBox(width: 7),
                                Text(
                                  'আপনার প্রশ্ন / লক্ষণ:',
                                  style: TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF1B5E20),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              data.userSymptoms?.isNotEmpty == true
                                  ? data.userSymptoms!
                                  : (data.localImagePath != null ? 'আক্রান্ত পাতার ছবি সংযুক্ত করে পরামর্শ চাওয়া হয়েছিল।' : 'লক্ষণ বিশ্লেষণ'),
                              style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFF2E3D2F),
                                fontWeight: FontWeight.w600,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // ৩.২ KrishiMate AI এর বিশ্লেষণ ও পরামর্শ
                      _buildSectionHeader(
                        icon: Icons.psychology_rounded,
                        iconColor: const Color(0xFF2E7D32),
                        title: 'KrishiMate AI এর বিশ্লেষণ ও পরামর্শ:',
                      ),
                      const SizedBox(height: 10),

                      // ১. শীর্ষ রোগ ও ফসলের ওভারভিউ কার্ড
                      _buildHeroDiseaseCard(data),

                      const SizedBox(height: 18),

                      // ২. রোগের কারণ ও লক্ষণসমূহ
                      _buildSectionHeader(
                        icon: Icons.checklist_rounded,
                        iconColor: const Color(0xFF0288D1),
                        title: 'রোগের কারণ ও দৃশ্যমান লক্ষণসমূহ',
                      ),
                      const SizedBox(height: 8),
                      _buildCausesAndSymptomsCard(data),

                      const SizedBox(height: 20),

                      // ৩. জরুরি চিকিৎসা ও প্রতিকার
                      _buildSectionHeader(
                        icon: Icons.medical_services_rounded,
                        iconColor: const Color(0xFF2E7D32),
                        title: 'জরুরি চিকিৎসা ও প্রতিকার',
                      ),
                      const SizedBox(height: 8),

                      // ৩.১ জৈব ও প্রাকৃতিক প্রতিকার (ঘরোয়া সহজ সমাধান)
                      _buildOrganicCuresCard(data),

                      const SizedBox(height: 12),

                      // ৩.২ সঠিক রাসায়নিক কীটনাশক/ছত্রাকনাশক ও প্রয়োগের অনুপাত
                      _buildChemicalCuresCard(data),

                      const SizedBox(height: 20),

                      // ৪. ভবিষ্যৎ সুরক্ষায় করণীয় ও পরিচর্যা টিপস
                      _buildSectionHeader(
                        icon: Icons.shield_rounded,
                        iconColor: const Color(0xFF7B1FA2),
                        title: 'ভবিষ্যৎ সুরক্ষায় করণীয় ও পরিচর্যা টিপস',
                      ),
                      const SizedBox(height: 8),
                      _buildPrecautionCard(data),

                      if (data.emergencyWarning != null && data.emergencyWarning!.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        _buildEmergencyWarningCard(data.emergencyWarning!),
                      ],
                    ],
                  ],
                ),
              ),

              // ৫. পেজের নিচে ফিক্সড "প্রেসক্রিপশন ডাউনলোড / শেয়ার করুন" এবং "নতুন করে শনাক্ত করুন" বাটন
              _buildFixedBottomActionBar(context, data),
            ],
          ),
        );
      },
    );
  }

  // ১. শীর্ষ রোগ ও ফসলের ওভারভিউ কার্ড
  Widget _buildHeroDiseaseCard(DiseaseDiagnosisResult data) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFE8F5E9), Color(0xFFF1F8E9)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFC8E6C9), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2E7D32).withOpacity(0.08),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // যদি ছবি থাকে তবে থাম্বনেইল
              if (data.localImagePath != null && File(data.localImagePath!).existsSync()) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Image.file(
                    File(data.localImagePath!),
                    width: 70,
                    height: 70,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: 14),
              ] else ...[
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: const Color(0xFF2E7D32),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF2E7D32).withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.eco_rounded, color: Colors.white, size: 30),
                ),
                const SizedBox(width: 14),
              ],

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2E7D32),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'আক্রান্ত ফসল: ${data.plantName}',
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      data.diseaseName,
                      style: const TextStyle(
                        fontSize: 17.5,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF1B5E20),
                        height: 1.25,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),
          const Divider(height: 1, color: Color(0xFFC8E6C9)),
          const SizedBox(height: 12),

          Row(
            children: [
              // নির্ভুলতার মাত্রা
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFA5D6A7)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.verified_rounded, color: Color(0xFF2E7D32), size: 16),
                    const SizedBox(width: 5),
                    Text(
                      'সম্ভাব্য নির্ভুলতা: ${data.confidence}',
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1B5E20),
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              const Text(
                'ভেরিফাইড ডিজিটাল প্রেসক্রিপশন',
                style: TextStyle(
                  fontSize: 11,
                  color: Color(0xFF388E3C),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // সেকশন হেডার উইজেট
  Widget _buildSectionHeader({
    required IconData icon,
    required Color iconColor,
    required String title,
  }) {
    return Row(
      children: [
        Icon(icon, color: iconColor, size: 19),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  // ২. রোগের কারণ ও লক্ষণ কার্ড
  Widget _buildCausesAndSymptomsCard(DiseaseDiagnosisResult data) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE0E0E0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: data.causesAndSymptoms.map((point) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 4.0),
                  child: Icon(Icons.lens, size: 6, color: Color(0xFF0288D1)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    point,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF37474F),
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  // ৩.১ জৈব ও প্রাকৃতিক প্রতিকার (ঘরোয়া সহজ সমাধান)
  Widget _buildOrganicCuresCard(DiseaseDiagnosisResult data) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F8E9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFC5E1A5), width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.eco_rounded, color: Color(0xFF2E7D32), size: 18),
              SizedBox(width: 8),
              Text(
                'জৈব ও প্রাকৃতিক প্রতিকার (ঘরোয়া সমাধান)',
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1B5E20),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...data.organicCures.map((cure) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.check_circle_rounded, size: 16, color: Color(0xFF2E7D32)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      cure,
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: Color(0xFF263238),
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // ৩.২ সঠিক রাসায়নিক কীটনাশক/ছত্রাকনাশক ও প্রয়োগের অনুপাত
  Widget _buildChemicalCuresCard(DiseaseDiagnosisResult data) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFFE082), width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.science_rounded, color: Color(0xFFE65100), size: 18),
              SizedBox(width: 8),
              Text(
                'অনুমোদিত রাসায়নিক কীটনাশক/ছত্রাকনাশক ও সঠিক ডোজ',
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFFBF360C),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...data.chemicalCures.map((chem) {
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFFFE082)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    chem.name,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFFD84315),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.scale_rounded, size: 14, color: Color(0xFFE65100)),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'মাত্রা: ${chem.dosage}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF37474F),
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (chem.instruction.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        const Icon(Icons.info_outline_rounded, size: 14, color: Color(0xFF757575)),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            chem.instruction,
                            style: const TextStyle(
                              fontSize: 11.5,
                              color: Color(0xFF546E7A),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // ৪. ভবিষ্যৎ সুরক্ষায় করণীয় ও পরিচর্যা টিপস
  Widget _buildPrecautionCard(DiseaseDiagnosisResult data) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE0E0E0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: data.precautionAndCare.map((tip) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.arrow_right_rounded, color: Color(0xFF7B1FA2), size: 18),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    tip,
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: Color(0xFF37474F),
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  // জরুরি সতর্কতা ব্যানার
  Widget _buildEmergencyWarningCard(String warning) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFEBEE),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFFCDD2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.warning_amber_rounded, color: Color(0xFFC62828), size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              warning,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFFB71C1C),
                fontWeight: FontWeight.w700,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ৫. ফিক্সড বটম অ্যাকশন বার
  Widget _buildFixedBottomActionBar(BuildContext context, DiseaseDiagnosisResult data) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.96),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Row(
            children: [
              // নতুন করে শনাক্ত করুন বাটন
              Expanded(
                flex: 2,
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.pop(context),
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

