import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import '../../core/constants/app_colors.dart';

/// চাষ ক্যালেন্ডারের নির্দিষ্ট ফসলের বিস্তারিত চাষাবাদ বিবরণী স্ক্রিন
class CropDetailsPage extends StatelessWidget {
  final Map<String, dynamic> cropData;

  const CropDetailsPage({
    super.key,
    required this.cropData,
  });

  @override
  Widget build(BuildContext context) {
    final cropName = cropData['cropName']?.toString() ?? 'ফসলের বিস্তারিত';
    final month = cropData['month']?.toString() ?? '';
    final season = cropData['season']?.toString() ?? '';
    final category = cropData['cropCategory']?.toString() ?? '';
    final sowingTime = cropData['sowingTime']?.toString() ?? '';
    final harvestingTime =
        (cropData['harvestingTime'] ?? cropData['plantingTime'])?.toString() ?? '';
    final description = cropData['description']?.toString() ?? '';
    final careTips =
        (cropData['careTips'] ?? cropData['careInstructions'])?.toString() ?? '';
    final fertilizer =
        cropData['fertilizerRecommendation']?.toString() ?? '';
    final rawUrl = cropData['imageUrl']?.toString() ?? '';
    final imageUrl = rawUrl.trim();

    return Scaffold(
      backgroundColor: const Color(0xFFF7FAF7),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1B5E20),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 19),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          children: [
            Text(
              cropName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 17.5,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (month.isNotEmpty || category.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(
                [if (month.isNotEmpty) '$month মাস', if (category.isNotEmpty) category]
                    .join(' • '),
                style: TextStyle(
                  color: Colors.white.withOpacity(0.85),
                  fontSize: 11,
                  fontWeight: FontWeight.normal,
                ),
              ),
            ],
          ],
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ১. বড় আকারের হেডার ইমেজ (Cloudflare R2 সহ রোবাস্ট রেন্ডারিং)
              Stack(
                children: [
                  _buildHeaderImage(imageUrl, cropName),

                  // মাস ব্যাজ
                  if (month.isNotEmpty)
                    Positioned(
                      top: 14,
                      left: 14,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.65),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white24),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.calendar_month_rounded, color: Colors.amberAccent, size: 14),
                            const SizedBox(width: 5),
                            Text(
                              '$month মাস',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  // ক্যাটাগরি ব্যাজ
                  if (category.isNotEmpty)
                    Positioned(
                      top: 14,
                      right: 14,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2E7D32).withOpacity(0.92),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.15),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Text(
                          category,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                ],
              ),

              // ২. বিস্তারিত কনটেন্ট এরিয়া
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ফসলের নাম ও মৌসুম
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            cropName,
                            softWrap: true,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                              height: 1.25,
                            ),
                          ),
                        ),
                        if (season.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF3E0),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: const Color(0xFFFFB74D)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.wb_sunny_rounded, size: 13, color: Color(0xFFE65100)),
                                const SizedBox(width: 4),
                                Text(
                                  season,
                                  softWrap: true,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFFE65100),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),

                    const SizedBox(height: 14),

                    // ৩. বপন ও ফসল তোলার সময়সূচি কার্ড
                    if (sowingTime.isNotEmpty || harvestingTime.isNotEmpty) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFE2EBE2)),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x06000000),
                              blurRadius: 8,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            if (sowingTime.isNotEmpty)
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(7),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFE8F5E9),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(Icons.grain_rounded, size: 18, color: Color(0xFF2E7D32)),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'বপন/রোপণ সময়সূচি',
                                          softWrap: true,
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.textPrimary,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          sowingTime,
                                          softWrap: true,
                                          style: const TextStyle(
                                            fontSize: 13,
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            if (sowingTime.isNotEmpty && harvestingTime.isNotEmpty)
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 10),
                                child: Divider(height: 1, color: Color(0xFFE8EFE8)),
                              ),
                            if (harvestingTime.isNotEmpty)
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(7),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFFF3E0),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(Icons.agriculture_rounded, size: 18, color: Color(0xFFE65100)),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'ফসল সংগ্রহ / কর্তন',
                                          softWrap: true,
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.textPrimary,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          harvestingTime,
                                          softWrap: true,
                                          style: const TextStyle(
                                            fontSize: 13,
                                            color: AppColors.textSecondary,
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
                      const SizedBox(height: 18),
                    ],

                    // ৪. চাষের বিস্তারিত বিবরণ (কোনো maxLines বা overflow ছাড়া সম্পূর্ণ প্রদর্শিত)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE2EBE2)),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x06000000),
                            blurRadius: 10,
                            offset: Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE8F5E9),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.menu_book_rounded,
                                  size: 18,
                                  color: Color(0xFF2E7D32),
                                ),
                              ),
                              const SizedBox(width: 10),
                              const Expanded(
                                child: Text(
                                  'চাষের বিস্তারিত বিবরণ',
                                  softWrap: true,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1B5E20),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          const Divider(height: 1, color: Color(0xFFE8EFE8)),
                          const SizedBox(height: 12),
                          // সম্পূর্ণ আনট্রাংকেটেড বড় টেক্সট
                          Text(
                            description.isNotEmpty
                                ? description
                                : 'এই ফসলের চাষ সংক্রান্ত বিস্তারিত তথ্য শীঘ্রই হালনাগাদ করা হবে।',
                            softWrap: true,
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppColors.textPrimary,
                              height: 1.65,
                              letterSpacing: 0.15,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // ৫. যত্ন ও পরিচর্যার পরামর্শ (যদি থাকে)
                    if (careTips.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F8F1),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFC8E6C9)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(
                                  Icons.tips_and_updates_outlined,
                                  size: 18,
                                  color: Color(0xFF2E7D32),
                                ),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'পরিচর্যা ও রোগবালাই প্রতিরোধ টিপস',
                                    softWrap: true,
                                    style: TextStyle(
                                      fontSize: 14.5,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF1B5E20),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(
                              careTips,
                              softWrap: true,
                              style: const TextStyle(
                                fontSize: 13.5,
                                color: Color(0xFF1B5E20),
                                height: 1.55,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    // ৬. সার প্রয়োগ নির্দেশিকা (যদি থাকে)
                    if (fertilizer.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE3F2FD),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFBBDEFB)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(
                                  Icons.science_outlined,
                                  size: 18,
                                  color: Color(0xFF1565C0),
                                ),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'সার প্রয়োগ সংক্রান্ত নির্দেশনা',
                                    softWrap: true,
                                    style: TextStyle(
                                      fontSize: 14.5,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF0D47A1),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(
                              fertilizer,
                              softWrap: true,
                              style: const TextStyle(
                                fontSize: 13.5,
                                color: Color(0xFF0D47A1),
                                height: 1.55,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Cloudflare R2 সহ বড় আকারের নেটওয়ার্ক হেডার ইমেজ রেন্ডারিং
  Widget _buildHeaderImage(String imageUrl, String cropName) {
    const double imageHeight = 230.0;
    final cleanUrl = imageUrl.trim();

    return SizedBox(
      height: imageHeight,
      width: double.infinity,
      child: cleanUrl.isEmpty
          ? _buildImagePlaceholder(imageHeight, cropName)
          : CachedNetworkImage(
              imageUrl: cleanUrl,
              height: imageHeight,
              width: double.infinity,
              fit: BoxFit.cover,
              memCacheHeight: 600,
              fadeInDuration: const Duration(milliseconds: 200),
              placeholder: (context, url) => Container(
                color: const Color(0xFFF1F8F1),
                child: const Center(
                  child: SizedBox(
                    width: 28,
                    height: 28,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Color(0xFF2E7D32),
                    ),
                  ),
                ),
              ),
              errorWidget: (context, url, error) =>
                  _buildImagePlaceholder(imageHeight, cropName),
            ),
    );
  }

  /// ফলব্যাক ইমেজ প্লেসহোল্ডার
  Widget _buildImagePlaceholder(double height, String cropName) {
    return Container(
      height: height,
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFE8F5E9), Color(0xFFC8E6C9)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.92),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF2E7D32).withOpacity(0.18),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                Icons.eco_rounded,
                size: 32,
                color: Color(0xFF2E7D32),
              ),
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                cropName.isNotEmpty ? cropName : 'কৃষি কথা – ফসল ক্যালেন্ডার',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1B5E20),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
