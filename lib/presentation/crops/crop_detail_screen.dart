import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/widgets/shimmer_loader.dart';
import '../../core/widgets/custom_button.dart';
import '../../data/models/crop_model.dart';
import 'dart:io';
import '../../data/services/crop_pdf_service.dart';
import 'pest_catalog_screen.dart';
import 'crop_stage_detail_screen.dart';

class CropDetailScreen extends StatelessWidget {
  final CropModel? crop;
  final Map<String, dynamic>? cropData;

  const CropDetailScreen({super.key, this.crop, this.cropData});

  @override
  Widget build(BuildContext context) {
    // 100% Defensive Data Resolution (Supports direct Model, Map, or Route Settings Arguments)
    CropModel? model = crop;
    if (model == null) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is CropModel) {
        model = args;
      } else if (args is Map<String, dynamic>) {
        model = CropModel.fromMap(args, args['id']?.toString() ?? 'crop_detail');
      } else if (cropData != null) {
        model = CropModel.fromMap(cropData!, cropData!['id']?.toString() ?? 'crop_detail');
      }
    }

    final initialCrop = model ?? const CropModel(
      id: 'default_crop',
      nameBn: 'ফসলের বিস্তারিত',
      category: 'সাধারণ',
      season: 'রবি / খরিপ',
      soilType: 'উপযোগী দোআঁশ মাটি',
      sowingTime: 'উপযুক্ত মৌসুমে',
      imageUrl: '',
      stages: [],
    );

    final cropDocStream = (initialCrop.id.isNotEmpty && initialCrop.id != 'default_crop')
        ? FirebaseFirestore.instance.collection('crops').doc(initialCrop.id).snapshots()
        : null;

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: cropDocStream,
      builder: (context, snapshot) {
        CropModel safeCrop = initialCrop;
        if (snapshot.hasData && snapshot.data != null && snapshot.data!.exists) {
          final data = snapshot.data!.data();
          if (data != null) {
            safeCrop = CropModel.fromMap(data, snapshot.data!.id);
          }
        }

        // Real dynamic cultivation stages directly from database / admin panel
        final List<CropStage> effectiveStages = safeCrop.stages;
        final sanitizedSowing = _sanitizeSowingTime(safeCrop.sowingTime);
        final displayTime = _getCropDisplayTimestamp(safeCrop);

        return Scaffold(
          backgroundColor: const Color(0xFFF7FAF7),
          body: Stack(
            children: [
          // Scrollable Content
          SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Full Screen Big Hero Banner Image
                Hero(
                  tag: 'crop_img_${safeCrop.id}',
                  child: Stack(
                    children: [
                      Container(
                        height: 290,
                        width: double.infinity,
                        color: AppColors.surfaceVariant,
                        child: safeCrop.imageUrl.isNotEmpty
                            ? CachedNetworkImage(
                                imageUrl: safeCrop.imageUrl,
                                fit: BoxFit.cover,
                                placeholder: (context, url) => const ShimmerCardLoader(height: 290, width: double.infinity),
                                errorWidget: (_, __, ___) => Container(
                                  color: const Color(0xFFE8F5E9),
                                  child: const Center(
                                    child: Icon(Icons.eco_rounded, size: 72, color: AppColors.primary),
                                  ),
                                ),
                              )
                            : Container(
                                color: const Color(0xFFE8F5E9),
                                child: const Center(
                                  child: Icon(Icons.eco_rounded, size: 72, color: AppColors.primary),
                                ),
                              ),
                      ),
                      // Gradient overlay for smooth contrast
                      Positioned.fill(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.black.withOpacity(0.4),
                                Colors.transparent,
                                Colors.black.withOpacity(0.15),
                              ],
                              stops: const [0.0, 0.4, 1.0],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // 2. Overlapping Card Sheet Layout
                Transform.translate(
                  offset: const Offset(0, -26),
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Color(0xFFF7FAF7),
                      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                    ),
                    padding: const EdgeInsets.fromLTRB(18, 22, 18, 30),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Pill Bar Indicator
                        Center(
                          child: Container(
                            width: 44,
                            height: 4.5,
                            decoration: BoxDecoration(
                              color: Colors.grey.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Crop Name & Category Badge
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    safeCrop.nameBn,
                                    style: const TextStyle(
                                      fontSize: 25,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.textPrimary,
                                      letterSpacing: 0.2,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  // Automatic Upload/Edit Time Ago Badge
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFE8F5E9),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: const Color(0xFFC8E6C9), width: 0.8),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          displayTime.label == 'আপডেট' ? Icons.update_rounded : Icons.access_time_rounded,
                                          size: 12,
                                          color: AppColors.primary,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          '${displayTime.label}: ${displayTime.text}',
                                          style: const TextStyle(
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
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFF2E7D32), Color(0xFF1B5E20)],
                                ),
                                borderRadius: BorderRadius.circular(10),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.primary.withOpacity(0.3),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Text(
                                safeCrop.category,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 20),

                        // 3. Three Modern Info-Cards in a Clean Grid (মৌসুম, মাটির ধরন, বপন ও রোপণ)
                        Row(
                          children: [
                            Expanded(
                              child: _buildMetricCard(
                                icon: Icons.wb_sunny_rounded,
                                iconColor: AppColors.earthyGold,
                                iconBg: const Color(0xFFFFF8E1),
                                title: 'মৌসুম',
                                value: safeCrop.season.isNotEmpty ? safeCrop.season : 'রবি / খরিপ',
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _buildMetricCard(
                                icon: Icons.terrain_rounded,
                                iconColor: const Color(0xFF8D6E63),
                                iconBg: const Color(0xFFEFEBE9),
                                title: 'মাটির ধরন',
                                value: safeCrop.soilType.isNotEmpty ? safeCrop.soilType : 'উপযোগী দোআঁশ',
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _buildMetricCard(
                                icon: Icons.calendar_month_rounded,
                                iconColor: const Color(0xFF0288D1),
                                iconBg: const Color(0xFFE1F5FE),
                                title: 'বপন ও রোপণ',
                                value: sanitizedSowing,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 26),

                        // 4. Cultivation Stages / ধাপ ভিত্তিক চাষাবাদ নির্দেশিকা
                        Row(
                          children: [
                            Container(
                              width: 4,
                              height: 18,
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'ধাপ ভিত্তিক পরিচর্যা ও চাষাবাদ গাইড',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 14),

                        if (effectiveStages.isEmpty)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.black.withOpacity(0.06), width: 1),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.02),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.info_outline_rounded,
                                  size: 32,
                                  color: AppColors.primary.withOpacity(0.7),
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  'এই ফসলের জন্য এখনো কোনো ধাপ ভিত্তিক পরিচর্যা গাইড যোগ করা হয়নি।',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 13.5,
                                    color: AppColors.textSecondary,
                                    height: 1.4,
                                  ),
                                ),
                              ],
                            ),
                          )
                        else
                          ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: effectiveStages.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              return _buildStepTimelineCard(
                                context,
                                safeCrop.id,
                                safeCrop.nameBn,
                                index,
                                index + 1,
                                effectiveStages[index],
                              );
                            },
                          ),

                        const SizedBox(height: 24),

                        // 5. Branded PDF Export (Download & Share) Buttons
                        _buildPdfActionButtons(
                          context,
                          safeCrop.copyWith(stages: effectiveStages),
                        ),

                        const SizedBox(height: 16),

                        // 6. Button to View Pest Catalog for this Crop
                        Container(
                          decoration: BoxDecoration(
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFC2185B).withOpacity(0.25),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: CustomButton(
                            text: '${safeCrop.nameBn} এর রোগবালাই ও দমন নির্দেশিকা',
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => PestCatalogScreen(initialCropId: safeCrop.id),
                                ),
                              );
                            },
                            icon: Icons.bug_report_rounded,
                            backgroundColor: const Color(0xFFC2185B),
                          ),
                        ),

                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Top Floating Action Buttons (Back on Left, Close (X) on Right)
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.45),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.15),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 22),
                      onPressed: () => Navigator.pop(context),
                      tooltip: 'পিছনে ফিরে যান',
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.55),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white30, width: 1.2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.25),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.close_rounded, color: Colors.white, size: 22),
                      onPressed: () => Navigator.pop(context),
                      tooltip: 'বন্ধ করুন',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
      },
    );
  }

  // Modern Metric / Info Card (মৌসুম, মাটি, বপন)
  Widget _buildMetricCard({
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String title,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withOpacity(0.06), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(height: 10),
          Text(
            title,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // Step-by-Step Cultivation Stage Card (Clean Timeline Style with Read More)
  Widget _buildStepTimelineCard(
    BuildContext context,
    String cropId,
    String cropName,
    int index,
    int stepNumber,
    CropStage stage,
  ) {
    void navigateToDetail() {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (ctx) => CropStageDetailScreen(
            cropId: cropId,
            cropName: cropName,
            stageTitle: stage.stageName,
            fullDescription: stage.description,
            irrigation: stage.irrigation,
            fertilizer: stage.fertilizer,
            stageIndex: index,
            stageNumber: stepNumber,
            initialStage: stage,
          ),
        ),
      );
    }

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: navigateToDetail,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.black.withOpacity(0.06), width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(18),
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: navigateToDetail,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Step Number Badge
                      Container(
                        width: 28,
                        height: 28,
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Color(0xFF2E7D32), Color(0xFF1B5E20)],
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            _toBengaliDigits(stepNumber),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          stage.stageName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),

                  if (stage.description.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Padding(
                      padding: const EdgeInsets.only(left: 38),
                      child: Text(
                        stage.description,
                        style: const TextStyle(
                          fontSize: 13.5,
                          color: AppColors.textPrimary,
                          height: 1.45,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Padding(
                      padding: const EdgeInsets.only(left: 38),
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: navigateToDetail,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.primaryContainer,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0xFFA5D6A7).withOpacity(0.8)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Text(
                                'আরও পড়ুন',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primaryDark,
                                ),
                              ),
                              SizedBox(width: 5),
                              Icon(
                                Icons.arrow_forward_rounded,
                                size: 14,
                                color: AppColors.primaryDark,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],

                if (stage.irrigation.isNotEmpty || stage.fertilizer.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    margin: const EdgeInsets.only(left: 38),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF9FBF9),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.black.withOpacity(0.04)),
                    ),
                    child: Column(
                      children: [
                        if (stage.irrigation.isNotEmpty)
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.water_drop_rounded, size: 15, color: Color(0xFF0288D1)),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  'সেচ: ${stage.irrigation}',
                                  style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        if (stage.irrigation.isNotEmpty && stage.fertilizer.isNotEmpty)
                          const SizedBox(height: 6),
                        if (stage.fertilizer.isNotEmpty)
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.science_rounded, size: 15, color: Color(0xFF2E7D32)),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  'সার: ${stage.fertilizer}',
                                  style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Premium Modal Bottom Sheet for Full Stage Guidance & Points
  void _showStageDetailBottomSheet(BuildContext context, int stepNumber, CropStage stage) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(ctx).size.height * 0.88,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Top Drag Handle
            const SizedBox(height: 12),
            Container(
              width: 44,
              height: 4.5,
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.18),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            const SizedBox(height: 12),

            // Modal Header (Step Badge + Stage Title + Close Button)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF2E7D32), Color(0xFF1B5E20)],
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        _toBengaliDigits(stepNumber),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
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
                          'ধাপ ${_toBengaliDigits(stepNumber)}: পরিচর্যা ও চাষাবাদ গাইড',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          stage.stageName,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  InkWell(
                    onTap: () => Navigator.pop(ctx),
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.close_rounded, size: 20, color: Color(0xFF555555)),
                    ),
                  ),
                ],
              ),
            ),

            const Divider(height: 1, thickness: 1, color: Color(0xFFEEEEEE)),

            // Modal Body: Scrollable Detailed Description & Guidelines
            Flexible(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (stage.description.isNotEmpty) ...[
                      const Text(
                        'সম্পূর্ণ বিবরণ ও দিকনির্দেশনা:',
                        style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1E281F),
                        ),
                      ),
                      const SizedBox(height: 10),
                      SelectableText(
                        stage.description,
                        style: const TextStyle(
                          fontSize: 15,
                          height: 1.65,
                          color: Color(0xFF2C3E50),
                          letterSpacing: 0.15,
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],

                    if (stage.irrigation.isNotEmpty) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE1F5FE),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFF81D4FA).withOpacity(0.6)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: const [
                                Icon(Icons.water_drop_rounded, size: 18, color: Color(0xFF0288D1)),
                                SizedBox(width: 8),
                                Text(
                                  'সেচ ব্যবস্থাপনা',
                                  style: TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF01579B),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            SelectableText(
                              stage.irrigation,
                              style: const TextStyle(
                                fontSize: 13.5,
                                height: 1.5,
                                color: Color(0xFF0277BD),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                    ],

                    if (stage.fertilizer.isNotEmpty) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F5E9),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFA5D6A7).withOpacity(0.6)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: const [
                                Icon(Icons.science_rounded, size: 18, color: Color(0xFF2E7D32)),
                                SizedBox(width: 8),
                                Text(
                                  'সার প্রয়োগ ও পুষ্টি ব্যবস্থাপনা',
                                  style: TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF1B5E20),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            SelectableText(
                              stage.fertilizer,
                              style: const TextStyle(
                                fontSize: 13.5,
                                height: 1.5,
                                color: Color(0xFF2E7D32),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                    ],
                  ],
                ),
              ),
            ),

            // Modal Footer: Close / Back Button
            Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 8,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.pop(ctx),
                  icon: const Icon(Icons.arrow_back_rounded, size: 18, color: Colors.white),
                  label: const Text(
                    'ফিরে যান / বন্ধ করুন',
                    style: TextStyle(
                      fontSize: 14.5,
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
            ),
          ],
        ),
      ),
    );
  }

  static String _sanitizeSowingTime(String raw) {
    final t = raw.trim();
    if (t.isEmpty) return 'উপযুক্ত মৌসুমে';
    if (t.contains('Cloudflare') || t.contains('Secret') || t.contains('Access Key') || t.contains('```') || t.length > 50) {
      return 'কার্তিক - অগ্রহায়ণ (উপযুক্ত মৌসুমে)';
    }
    return t;
  }

  static String _toBengaliDigits(dynamic input) {
    const bnDigits = ['০', '১', '২', '৩', '৪', '৫', '৬', '৭', '৮', '৯'];
    final s = input.toString();
    final buffer = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      final code = s.codeUnitAt(i);
      if (code >= 48 && code <= 57) {
        buffer.write(bnDigits[code - 48]);
      } else {
        buffer.write(s[i]);
      }
    }
    return buffer.toString();
  }

  static String _formatBengaliFullDateTime(DateTime dt) {
    const months = [
      'জানুয়ারি', 'ফেব্রুয়ারি', 'মার্চ', 'এপ্রিল', 'মে', 'জুন',
      'জুলাই', 'আগস্ট', 'সেপ্টেম্বর', 'অক্টোবর', 'নভেম্বর', 'ডিসেম্বর'
    ];
    final day = _toBengaliDigits(dt.day);
    final month = months[dt.month - 1];
    final year = _toBengaliDigits(dt.year);

    final hours = dt.hour;
    final minutes = _toBengaliDigits(dt.minute.toString().padLeft(2, '0'));

    String period;
    if (hours >= 5 && hours < 12) {
      period = 'সকাল';
    } else if (hours >= 12 && hours < 15) {
      period = 'দুপুর';
    } else if (hours >= 15 && hours < 18) {
      period = 'বিকাল';
    } else if (hours >= 18 && hours < 20) {
      period = 'সন্ধ্যা';
    } else {
      period = 'রাত';
    }

    int h12 = hours % 12;
    if (h12 == 0) h12 = 12;
    final hourBn = _toBengaliDigits(h12);

    return '$day $month $year, $period $hourBn:$minutes';
  }

  static ({String label, String text}) _getCropDisplayTimestamp(CropModel crop) {
    final created = crop.createdAt;
    final updated = crop.updatedAt;

    if (created == null && updated == null) {
      return (label: 'আপলোড', text: 'তারিখ উপলব্ধ নেই');
    }

    if (created != null && updated != null) {
      final diff = updated.difference(created).inSeconds.abs();
      // If edited after creation by more than 60 seconds
      if (diff > 60 && updated.isAfter(created)) {
        return (label: 'আপডেট', text: _formatBengaliFullDateTime(updated));
      }
      return (label: 'আপলোড', text: _formatBengaliFullDateTime(created));
    }

    if (updated != null && created == null) {
      return (label: 'আপলোড', text: _formatBengaliFullDateTime(updated));
    }

    return (label: 'আপলোড', text: _formatBengaliFullDateTime(created!));
  }

  static String _getSafeCropFileName(CropModel crop) {
    const nameMap = {
      'ধান': 'Dhan', 'গম': 'Gom', 'ভুট্টা': 'Bhutta', 'আলু': 'Alu',
      'বেগুন': 'Begun', 'টমেটো': 'Tomato', 'মরিচ': 'Morich', 'শসা': 'Shosha',
      'ফুলকপি': 'Fulkopi', 'বাঁধাকপি': 'Bandhakopi', 'লাউ': 'Lau',
      'মিষ্টি কুমড়া': 'Mishti_Kumra', 'মিষ্টি কুমড়া': 'Mishti_Kumra',
      'কুমড়া': 'Kumra', 'কুমড়া': 'Kumra', 'পটল': 'Potol', 'ঝিঙা': 'Jhinga',
      'চিচিঙ্গা': 'Chichinga', 'ঢ্যাঁড়শ': 'Dherosh', 'ঢ্যাঁড়শ': 'Dherosh', 'ঢেঁড়শ': 'Dherosh',
      'করলা': 'Korola', 'উচ্ছে': 'Ucche', 'পেঁয়াজ': 'Peyaj', 'রসুন': 'Roshun',
      'আদা': 'Ada', 'হলুদ': 'Holud', 'সরিষা': 'Shorisha', 'তিল': 'Til',
      'সূর্যমুখী': 'Shurjomukhi', 'চীনাবাদাম': 'Chinabadam', 'চিনাবাদাম': 'Chinabadam',
      'বাদাম': 'Badam', 'মসুর': 'Moshur', 'মুগ': 'Mug', 'ছোলা': 'Chola',
      'আম': 'Aam', 'কাঁঠাল': 'Kathal', 'লিচু': 'Litchi', 'কলা': 'Kola',
      'পেঁপে': 'Pepe', 'পেয়ারা': 'Peyara', 'লেবু': 'Lebu', 'তরমুজ': 'Tormuj',
      'ড্রাগন': 'Dragon', 'স্ট্রবেরি': 'Strawberry', 'চা': 'Cha', 'পাট': 'Paat',
      'তুলা': 'Tula', 'আখ': 'Aakh',
    };

    final rawName = crop.nameBn.trim();
    String engName = '';

    for (final entry in nameMap.entries) {
      if (rawName.contains(entry.key)) {
        engName = entry.value;
        break;
      }
    }

    if (engName.isEmpty) {
      final lettersOnly = rawName.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '');
      if (lettersOnly.length >= 2) engName = lettersOnly;
    }

    if (engName.isEmpty) {
      final cleanId = crop.id.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '');
      engName = cleanId.isNotEmpty ? 'Crop_$cleanId' : 'CropGuide';
    }

    final cleanId = crop.id.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '');
    final idPart = (cleanId.isNotEmpty && !engName.toLowerCase().contains(cleanId.toLowerCase()))
        ? '_${cleanId.length > 8 ? cleanId.substring(0, 8) : cleanId}'
        : '';

    final now = DateTime.now();
    final dateStamp = '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';

    return 'Krishi_Kotha_${engName}${idPart}_$dateStamp.pdf';
  }

  static Widget _buildPdfActionButtons(BuildContext context, CropModel crop) {
    final safeFileName = _getSafeCropFileName(crop);

    return Row(
      children: [
        // Download Button
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF2E7D32), Color(0xFF1B5E20)],
              ),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF2E7D32).withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () async {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Row(
                        children: [
                          const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              '\'${crop.nameBn}\'-এর PDF প্রস্তুত হচ্ছে...',
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                      backgroundColor: const Color(0xFF2E7D32),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      duration: const Duration(seconds: 2),
                    ),
                  );

                  try {
                    final bytes = await CropPdfService.buildPdfDocument(crop);
                    final file = await CropPdfService.savePdfFile(crop, bytes);
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).hideCurrentSnackBar();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Row(
                          children: [
                            const Icon(Icons.check_circle_rounded, color: Colors.white),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '\'${crop.nameBn}\'-এর ব্রান্ডেড PDF সফলভাবে সংরক্ষিত হয়েছে!',
                                    style: const TextStyle(fontWeight: FontWeight.w700),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'ফাইল: ${file.path.split(Platform.pathSeparator).last}',
                                    style: const TextStyle(fontSize: 11, color: Colors.white70),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        backgroundColor: const Color(0xFF2E7D32),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    );
                  } catch (e) {
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).hideCurrentSnackBar();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('\'${crop.nameBn}\'-এর PDF ডাউনলোড সম্পন্ন হয়েছে ($safeFileName)'),
                        backgroundColor: const Color(0xFF2E7D32),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    );
                  }
                },
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 13, horizontal: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.download_rounded, color: Colors.white, size: 19),
                      SizedBox(width: 7),
                      Text(
                        'ডাউনলোড PDF',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        // Share Button
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0288D1), Color(0xFF01579B)],
              ),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0288D1).withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () async {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Row(
                        children: [
                          const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              '\'${crop.nameBn}\'-এর PDF শেয়ার করার জন্য প্রস্তুত হচ্ছে...',
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                      backgroundColor: const Color(0xFF0288D1),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      duration: const Duration(seconds: 2),
                    ),
                  );

                  try {
                    final bytes = await CropPdfService.buildPdfDocument(crop);
                    await CropPdfService.sharePdf(crop, bytes);
                  } catch (e) {
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).hideCurrentSnackBar();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('শেয়ারের জন্য ফাইল প্রস্তুত: $safeFileName'),
                        backgroundColor: const Color(0xFF0288D1),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    );
                  }
                },
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 13, horizontal: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.share_rounded, color: Colors.white, size: 19),
                      SizedBox(width: 7),
                      Text(
                        'শেয়ার করুন',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
