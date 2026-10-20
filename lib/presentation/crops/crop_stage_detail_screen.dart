import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants/app_colors.dart';
import '../../core/widgets/custom_app_bar.dart';
import '../../data/models/crop_model.dart';

class CropStageDetailScreen extends StatelessWidget {
  final String cropId;
  final String cropName;
  final String? stageTitle;
  final String? fullDescription;
  final String? irrigation;
  final String? fertilizer;
  final int stageIndex;
  final int stageNumber;
  final CropStage? initialStage;

  const CropStageDetailScreen({
    super.key,
    this.cropId = '',
    this.cropName = 'ফসলের গাইড',
    this.stageTitle,
    this.fullDescription,
    this.irrigation,
    this.fertilizer,
    this.stageIndex = 0,
    this.stageNumber = 1,
    this.initialStage,
  });

  String _toBengaliDigits(int number) {
    const bengaliDigits = ['০', '১', '২', '৩', '৪', '৫', '৬', '৭', '৮', '৯'];
    return number.toString().split('').map((char) {
      final index = int.tryParse(char);
      return index != null ? bengaliDigits[index] : char;
    }).join();
  }

  @override
  Widget build(BuildContext context) {
    final defaultTitle = (stageTitle != null && stageTitle!.trim().isNotEmpty)
        ? stageTitle!.trim()
        : (initialStage != null && initialStage!.stageName.trim().isNotEmpty)
            ? initialStage!.stageName.trim()
            : 'ধাপ ${_toBengaliDigits(stageNumber)}';

    final defaultDesc = (fullDescription != null && fullDescription!.trim().isNotEmpty)
        ? fullDescription!.trim()
        : (initialStage != null && initialStage!.description.trim().isNotEmpty)
            ? initialStage!.description.trim()
            : 'বিস্তারিত তথ্য উপলব্ধ নেই';

    final defaultIrrigation = (irrigation != null && irrigation!.trim().isNotEmpty)
        ? irrigation!.trim()
        : (initialStage?.irrigation ?? '');

    final defaultFertilizer = (fertilizer != null && fertilizer!.trim().isNotEmpty)
        ? fertilizer!.trim()
        : (initialStage?.fertilizer ?? '');

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: CustomAppBar(
        title: 'ধাপের বিস্তারিত বিবরণ',
        subtitle: cropName.isNotEmpty ? cropName : 'চাষাবাদ গাইড',
        showBackButton: true,
        onBackPressed: () => Navigator.of(context).pop(),
      ),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: cropId.isNotEmpty
            ? FirebaseFirestore.instance.collection('crops').doc(cropId).snapshots()
            : const Stream.empty(),
        builder: (context, snapshot) {
          String activeTitle = defaultTitle;
          String activeDesc = defaultDesc;
          String activeIrrigation = defaultIrrigation;
          String activeFertilizer = defaultFertilizer;

          if (snapshot.hasData && snapshot.data != null && snapshot.data!.exists) {
            final data = snapshot.data!.data();
            if (data != null && data['stages'] != null) {
              final stages = CropModel.parseStages(data['stages']);
              if (stageIndex >= 0 && stageIndex < stages.length) {
                final st = stages[stageIndex];
                if (st.stageName.trim().isNotEmpty) activeTitle = st.stageName.trim();
                if (st.description.trim().isNotEmpty) activeDesc = st.description.trim();
                if (st.irrigation.trim().isNotEmpty) activeIrrigation = st.irrigation.trim();
                if (st.fertilizer.trim().isNotEmpty) activeFertilizer = st.fertilizer.trim();
              }
            }
          }

          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Header Card: Crop Name & Step Badge
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: Colors.black.withOpacity(0.06)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.03),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: AppColors.primaryContainer,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.eco_rounded,
                                  size: 14,
                                  color: AppColors.primary,
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  cropName.isNotEmpty ? cropName : 'ফসলের গাইড',
                                  style: const TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primaryDark,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F8E9),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: const Color(0xFFA5D6A7)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: const [
                                Icon(Icons.check_circle_outline, size: 13, color: AppColors.primary),
                                SizedBox(width: 4),
                                Text(
                                  'ভেরিফাইড গাইডলাইন',
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.primaryDark,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Container(
                            width: 38,
                            height: 38,
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Color(0xFF2E7D32), Color(0xFF1B5E20)],
                              ),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                _toBengaliDigits(stageNumber),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'ধাপ ${_toBengaliDigits(stageNumber)}',
                                  style: const TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.primary,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  activeTitle,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.textPrimary,
                                    height: 1.25,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Main Content Card: Full Un-truncated Description
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: Colors.black.withOpacity(0.06)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.03),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: const [
                          Icon(Icons.menu_book_rounded, size: 20, color: AppColors.primary),
                          SizedBox(width: 8),
                          Text(
                            'সম্পূর্ণ বিবরণ ও দিকনির্দেশনা',
                            style: TextStyle(
                              fontSize: 15.5,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      const Divider(height: 1, color: Color(0xFFEEEEEE)),
                      const SizedBox(height: 16),

                      SelectableText(
                        activeDesc,
                        style: const TextStyle(
                          fontSize: 15,
                          height: 1.7,
                          color: Color(0xFF2C3E50),
                          letterSpacing: 0.15,
                        ),
                      ),
                    ],
                  ),
                ),

                // Irrigation Card
                if (activeIrrigation.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE1F5FE),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: const Color(0xFF81D4FA).withOpacity(0.7)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: const [
                            Icon(Icons.water_drop_rounded, size: 20, color: Color(0xFF0288D1)),
                            SizedBox(width: 8),
                            Text(
                              'সেচ ব্যবস্থাপনা',
                              style: TextStyle(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF01579B),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        SelectableText(
                          activeIrrigation,
                          style: const TextStyle(
                            fontSize: 14,
                            height: 1.6,
                            color: Color(0xFF0277BD),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // Fertilizer Card
                if (activeFertilizer.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F5E9),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: const Color(0xFFA5D6A7).withOpacity(0.7)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: const [
                            Icon(Icons.science_rounded, size: 20, color: Color(0xFF2E7D32)),
                            SizedBox(width: 8),
                            Text(
                              'সার প্রয়োগ ও পুষ্টি ব্যবস্থাপনা',
                              style: TextStyle(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF1B5E20),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        SelectableText(
                          activeFertilizer,
                          style: const TextStyle(
                            fontSize: 14,
                            height: 1.6,
                            color: Color(0xFF2E7D32),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 24),

                // Back / Close Button
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.arrow_back_rounded, size: 18, color: Colors.white),
                    label: const Text(
                      'ফিরে যান',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 0,
                    ),
                  ),
                ),

                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }
}
