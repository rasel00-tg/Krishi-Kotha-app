import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import '../../core/constants/app_colors.dart';

/// বীজের তথ্যভান্ডারের নির্দিষ্ট বীজের বিস্তারিত নির্দেশিকা স্ক্রিন
class SeedDetailsPage extends StatelessWidget {
  final Map<String, dynamic> seedData;

  const SeedDetailsPage({
    super.key,
    required this.seedData,
  });

  @override
  Widget build(BuildContext context) {
    final seedName = seedData['seedName']?.toString() ?? 'বীজের বিস্তারিত';
    final category = seedData['category']?.toString() ?? '';
    final sowingTime = seedData['sowingTime']?.toString() ?? '';
    final harvestingTime =
        (seedData['harvestingTime'] ?? seedData['plantingTime'])?.toString() ?? '';
    final description = seedData['description']?.toString() ?? '';
    final treatment = seedData['treatment']?.toString() ?? '';
    final preservation = seedData['preservation']?.toString() ?? '';
    final rawUrl = seedData['imageUrl']?.toString() ?? '';
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
              seedName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 17.5,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (category.isNotEmpty || sowingTime.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(
                [if (category.isNotEmpty) category, if (sowingTime.isNotEmpty) 'বপন: $sowingTime']
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
                  _buildHeaderImage(imageUrl, seedName),

                  // ক্যাটাগরি ব্যাজ
                  if (category.isNotEmpty)
                    Positioned(
                      top: 14,
                      left: 14,
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

                  // রোপণ সময় ব্যাজ
                  if (sowingTime.isNotEmpty)
                    Positioned(
                      top: 14,
                      right: 14,
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
                              'বপন: $sowingTime',
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
                ],
              ),

              // ২. বিস্তারিত কনটেন্ট এরিয়া
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // বীজের জাতের নাম ও ক্যাটাগরি
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            seedName,
                            softWrap: true,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                              height: 1.25,
                            ),
                          ),
                        ),
                        if (category.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE8F5E9),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: const Color(0xFFA5D6A7)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.spa_rounded, size: 13, color: Color(0xFF2E7D32)),
                                const SizedBox(width: 4),
                                Text(
                                  category,
                                  softWrap: true,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1B5E20),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),

                    const SizedBox(height: 14),

                    // ৩. বপন ও জীবনকাল/ফসল তোলার সময়সূচি কার্ড
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
                                      color: const Color(0xFFE3F2FD),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(Icons.timer_outlined, size: 18, color: Color(0xFF1565C0)),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'জীবনকাল / ফসল সংগ্রহ',
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

                    // ৪. জাতের বৈশিষ্ট্য ও বিবরণ (কোনো maxLines বা overflow ছাড়া সম্পূর্ণ প্রদর্শিত)
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
                                  'জাতের বৈশিষ্ট্য ও পরিচিতি',
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
                                : 'এই বীজের জাত সংক্রান্ত বিস্তারিত বৈশিষ্ট্য শীঘ্রই হালনাগাদ করা হবে।',
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

                    // ৫. বীজ শোধন ও অঙ্কুরোদগম নির্দেশিকা (যদি থাকে)
                    if (treatment.isNotEmpty) ...[
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
                                  Icons.verified_rounded,
                                  size: 18,
                                  color: Color(0xFF1565C0),
                                ),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'বীজ শোধন ও অঙ্কুরোদগম নির্দেশিকা',
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
                              treatment,
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

                    // ৬. বীজ সংরক্ষণ ও ড্রাম ব্যবস্থাপনা (যদি থাকে)
                    if (preservation.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFEBE9),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFD7CCC8)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(
                                  Icons.inventory_2_rounded,
                                  size: 18,
                                  color: Color(0xFF6D4C41),
                                ),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'বীজ সংরক্ষণ ও আর্দ্রতা ব্যবস্থাপনা',
                                    softWrap: true,
                                    style: TextStyle(
                                      fontSize: 14.5,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF4E342E),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(
                              preservation,
                              softWrap: true,
                              style: const TextStyle(
                                fontSize: 13.5,
                                color: Color(0xFF4E342E),
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

  /// Cloudflare R2 ইমেজ লোডার (CropDetailsPage এর অনুরূপ রোবাস্ট লোডার)
  Widget _buildHeaderImage(String imageUrl, String seedName) {
    const double headerHeight = 220.0;

    if (imageUrl.isEmpty) {
      return _buildImagePlaceholder(headerHeight, seedName);
    }

    return SizedBox(
      height: headerHeight,
      width: double.infinity,
      child: CachedNetworkImage(
        imageUrl: imageUrl,
        height: headerHeight,
        width: double.infinity,
        fit: BoxFit.cover,
        memCacheHeight: 600,
        fadeInDuration: const Duration(milliseconds: 250),
        placeholder: (context, url) => Shimmer.fromColors(
          baseColor: Colors.grey.shade300,
          highlightColor: Colors.grey.shade100,
          child: Container(
            height: headerHeight,
            width: double.infinity,
            color: Colors.white,
          ),
        ),
        errorWidget: (context, errorUrl, error) {
          return _buildImagePlaceholder(headerHeight, seedName);
        },
      ),
    );
  }

  Widget _buildImagePlaceholder(double height, String seedName) {
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
                color: Colors.white.withOpacity(0.85),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.spa_rounded,
                color: Color(0xFF2E7D32),
                size: 32,
              ),
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                seedName,
                textAlign: TextAlign.center,
                softWrap: true,
                style: const TextStyle(
                  color: Color(0xFF1B5E20),
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
