import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import '../../core/constants/app_colors.dart';
import '../../core/widgets/premium_loading_widget.dart';
import '../../global_popup/global_popup.dart';

class SoilHealthScreen extends StatefulWidget {
  final String? initialCategory;

  const SoilHealthScreen({super.key, this.initialCategory});

  @override
  State<SoilHealthScreen> createState() => _SoilHealthScreenState();
}

class _SoilHealthScreenState extends State<SoilHealthScreen> {
  late String _selectedCategory;

  final List<String> _baseCategories = [
    'সব মাটি',
    'দোআঁশ মাটি',
    'এঁটেল মাটি',
    'বেলে মাটি',
    'পলি মাটি',
    'লাল/পাহাড়ি মাটি',
    'লবণাক্ত মাটি',
  ];

  final Map<String, String> _categorySubtitleMap = {
    'দোআঁশ মাটি': 'আদর্শ কৃষিজ মাটি (সব ফসলের জন্য উপযোগী)',
    'এঁটেল মাটি': 'ভারী ও পানি ধারণক্ষম মাটি (ধান ও রবি ফসল)',
    'বেলে মাটি': 'হালকা ও পানি নিষ্কাশনশীল মাটি (তরমুজ, বাদাম ও আলু)',
    'পলি মাটি': 'উর্বর পলিগঠিত চর ও নদী অববাহিকার মাটি',
    'লাল/পাহাড়ি মাটি': 'লৌহসমৃদ্ধ অম্লীয় পাহাড়ি অঞ্চলের মাটি',
    'লবণাক্ত মাটি': 'উপকূলীয় অঞ্চলের লবণাক্ততামুক্ত সহনশীল চাষ',
  };

  late final Stream<QuerySnapshot<Map<String, dynamic>>> _soilStream;

  @override
  void initState() {
    super.initState();
    // Read Optimization: Initialize stream once in initState with reasonable limit
    _soilStream = FirebaseFirestore.instance
        .collection('soil_health')
        .limit(50)
        .snapshots();
    _selectedCategory = widget.initialCategory ?? 'সব মাটি';
  }

  /// Cloudflare R2 সহ যে কোনো ছবির URL নরমালাইজ করার নিরাপদ মেথড
  String _normalizeSoilImageUrl(Map<String, dynamic> item) {
    String url = (item['imageUrl'] ??
            item['image'] ??
            item['photoUrl'] ??
            item['imgUrl'] ??
            item['thumbnail'] ??
            item['img'] ??
            '')
        .toString()
        .trim();
    if (url.isEmpty) return '';
    if (url.startsWith('http://') || url.startsWith('https://')) {
      return url;
    }
    const r2Base = 'https://pub-660f3103c4924ba0a9526f4bbc8dd392.r2.dev/';
    return '$r2Base${url.replaceFirst(RegExp(r'^/+'), '')}';
  }

  void _showSoilDetailModal(BuildContext context, Map<String, dynamic> data) {
    final title = (data['title'] ?? data['soilName'] ?? data['name'] ?? 'মাটির তথ্য').toString();
    final category = (data['category'] ?? data['soilType'] ?? 'মাটি').toString();
    final ph = (data['phRange'] ?? data['ph'] ?? 'উল্লেখ নেই').toString();
    final crops = (data['suitableCrops'] ?? data['crops'] ?? 'উল্লেখ নেই').toString();
    final characteristics = (data['characteristics'] ?? data['description'] ?? 'বিস্তারিত তথ্য শীঘ্রই যুক্ত হবে।').toString();
    final fertilizer = (data['fertilizerManagement'] ?? data['fertilizer'] ?? 'সুষম সার প্রয়োগ ও সঠিক পরিচর্যা করুন।').toString();
    final imageUrl = _normalizeSoilImageUrl(data);

    GlobalPopup.showCustom(
      context,
      showLogo: true,
      title: title,
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.65,
        ),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Cloudflare R2 ছবি
              if (imageUrl.isNotEmpty) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: CachedNetworkImage(
                    imageUrl: imageUrl.trim(),
                    height: 190,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Shimmer.fromColors(
                      baseColor: Colors.grey.shade200,
                      highlightColor: Colors.grey.shade100,
                      child: Container(height: 190, color: Colors.white),
                    ),
                    errorWidget: (_, errUrl, ___) {
                      debugPrint('Soil Detail Image Error: $errUrl');
                      return const SizedBox.shrink();
                    },
                  ),
                ),
                const SizedBox(height: 14),
              ],

              // ক্যাটাগরি ও pH ব্যাজ
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F5E9),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFF81C784), width: 1),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.terrain_rounded, size: 14, color: Color(0xFF1B5E20)),
                        const SizedBox(width: 4),
                        Text(
                          category,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1B5E20),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE0F2F1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFF80CBC4), width: 1),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.science_rounded, size: 14, color: Color(0xFF00695C)),
                        const SizedBox(width: 4),
                        Text(
                          'pH মাত্রা: $ph',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF00695C),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // উপযোগী ফসলসমূহ
              _buildModalSectionHeader('উপযোগী ফসলসমূহ', Icons.eco_rounded, const Color(0xFF2E7D32)),
              const SizedBox(height: 5),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F8E9),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFDCEDC8)),
                ),
                child: Text(
                  crops,
                  style: const TextStyle(fontSize: 13, color: Color(0xFF33691E), height: 1.45),
                ),
              ),
              const SizedBox(height: 12),

              // মাটির বৈশিষ্ট্য ও গঠন
              _buildModalSectionHeader('মাটির বৈশিষ্ট্য ও গঠন', Icons.info_outline_rounded, const Color(0xFF6D4C41)),
              const SizedBox(height: 5),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFEBE9),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFD7CCC8)),
                ),
                child: Text(
                  characteristics,
                  style: const TextStyle(fontSize: 13, color: Color(0xFF4E342E), height: 1.45),
                ),
              ),
              const SizedBox(height: 12),

              // সার ও পুষ্টি ব্যবস্থাপনা
              _buildModalSectionHeader('সার ও পুষ্টি ব্যবস্থাপনা', Icons.water_drop_rounded, const Color(0xFF0277BD)),
              const SizedBox(height: 5),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFE1F5FE),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFB3E5FC)),
                ),
                child: Text(
                  fertilizer,
                  style: const TextStyle(fontSize: 13, color: Color(0xFF01579B), height: 1.45),
                ),
              ),
              const SizedBox(height: 18),

              // বন্ধ করুন বাটন
              SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton(
                  onPressed: () {
                    if (Navigator.of(context, rootNavigator: true).canPop()) {
                      Navigator.of(context, rootNavigator: true).pop();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00897B),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: const Text('বন্ধ করুন', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModalSectionHeader(String title, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 6),
        Text(
          title,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
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
            const Text(
              'মাটির স্বাস্থ্য ও পরিচর্যা',
              style: TextStyle(
                color: Colors.white,
                fontSize: 17.5,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'মাটির ধরন, pH মাত্রা ও সার ব্যবস্থাপনা',
              style: TextStyle(
                color: Colors.white.withOpacity(0.85),
                fontSize: 11,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: _soilStream,
          builder: (context, snapshot) {
            final docs = snapshot.data?.docs ?? [];

            // ডাইনামিক ক্যাটাগরি তালিকা তৈরি (বেস ক্যাটাগরি + ফায়ারস্টোরের নতুন ক্যাটাগরি)
            final Set<String> dynamicCategories = Set.from(_baseCategories);
            for (final doc in docs) {
              final data = doc.data();
              final cat = (data['category'] ?? data['soilType'] ?? '').toString().trim();
              if (cat.isNotEmpty && !dynamicCategories.contains(cat)) {
                dynamicCategories.add(cat);
              }
            }
            final categoriesList = dynamicCategories.toList();

            return Column(
              children: [
                // ১. "চাষ ক্যালেন্ডার" পেইজের হুবহু কালারিং টপবার বক্স (সার্চ বার ও ক্যাটাগরি চিপস সহ)
                _buildColoredTopBar(categoriesList),

                // ২. নির্বাচিত ক্যাটাগরির অতিরিক্ত ব্যানার তথ্য (যদি কোনো নির্দিষ্ট ক্যাটাগরি সিলেক্ট থাকে)
                if (_selectedCategory != 'সব মাটি')
                  Container(
                    margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFE8F5E9), Color(0xFFF1F8E9)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFC8E6C9)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: const Color(0xFF2E7D32),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.terrain_rounded, color: Colors.white, size: 18),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '$_selectedCategory - স্বাস্থ্য নির্দেশিকা',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1B5E20),
                                ),
                              ),
                              Text(
                                _categorySubtitleMap[_selectedCategory] ??
                                    'এই মাটির উপযুক্ত ফসল ও সার ব্যবস্থাপনা নিচে প্রদর্শিত হচ্ছে',
                                style: const TextStyle(fontSize: 11, color: Color(0xFF2E7D32)),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                // ৩. মাটির তালিকা (StreamBuilder রিয়েল-টাইম ডেটা ও R2 ইমেজ)
                Expanded(
                  child: _buildSoilContent(snapshot, docs),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildColoredTopBar(List<String> categories) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1B5E20), Color(0xFF2E7D32)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1B5E20).withOpacity(0.25),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 14),
      child: SizedBox(
        height: 38,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          itemCount: categories.length,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (context, index) {
                final cat = categories[index];
                final isSelected = _selectedCategory == cat;

                return InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () {
                    setState(() => _selectedCategory = cat);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.white : Colors.white.withOpacity(0.18),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected ? Colors.white : Colors.white.withOpacity(0.32),
                        width: 1,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.15),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ]
                          : null,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          cat == 'সব মাটি'
                              ? Icons.grid_view_rounded
                              : Icons.terrain_rounded,
                          size: 13,
                          color: isSelected ? const Color(0xFF1B5E20) : Colors.white,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          cat,
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                            color: isSelected ? const Color(0xFF1B5E20) : Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
    );
  }

  Widget _buildSoilContent(AsyncSnapshot<QuerySnapshot<Map<String, dynamic>>> snapshot, List<QueryDocumentSnapshot<Map<String, dynamic>>> docs) {
    if ((snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) ||
        (!snapshot.hasData && !snapshot.hasError)) {
      return const Center(
        child: PremiumLoadingWidget(
          topic: 'মাটির স্বাস্থ্য',
          subtitle: 'অনুগ্রহ করে কিছুক্ষণ অপেক্ষা করুন',
        ),
      );
    }

    if (snapshot.hasError && !snapshot.hasData) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline_rounded, color: Color(0xFFD32F2F), size: 48),
              const SizedBox(height: 12),
              const Text(
                'তথ্য লোড করতে সমস্যা হয়েছে',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              Text(
                '${snapshot.error}',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      );
    }

    var items = docs.map((doc) {
      final data = Map<String, dynamic>.from(doc.data());
      data['id'] = doc.id;
      return data;
    }).toList();

    // ফিল্টারিং: ক্যাটাগরিভিত্তিক
    if (_selectedCategory != 'সব মাটি') {
      final targetCat = _selectedCategory.toLowerCase();
      items = items.where((item) {
        final category = (item['category'] ?? item['soilType'] ?? '').toString().toLowerCase();
        final title = (item['title'] ?? item['soilName'] ?? item['name'] ?? '').toString().toLowerCase();
        return category.contains(targetCat) || title.contains(targetCat);
      }).toList();
    }

    // ক্রমানুসারে সাজানো (সর্বশেষ আপডেট হওয়া তথ্য প্রথমে)
    items.sort((a, b) {
      final timeA = (a['updatedAt'] as Timestamp?)?.millisecondsSinceEpoch ??
          (a['createdAt'] as Timestamp?)?.millisecondsSinceEpoch ??
          0;
      final timeB = (b['updatedAt'] as Timestamp?)?.millisecondsSinceEpoch ??
          (b['createdAt'] as Timestamp?)?.millisecondsSinceEpoch ??
          0;
      return timeB.compareTo(timeA);
    });

    if (items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: const BoxDecoration(
                  color: Color(0xFFF1F8F1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.terrain_rounded, color: Color(0xFF2E7D32), size: 40),
              ),
              const SizedBox(height: 16),
              Text(
                _selectedCategory == 'সব মাটি'
                    ? 'কোনো মাটির তথ্য পাওয়া যায়নি'
                    : '$_selectedCategory ক্যাটাগরিতে কোনো তথ্য নেই',
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 6),
              const Text(
                'এডমিন প্যানেল থেকে তথ্য যুক্ত করা হলে এখানে প্রদর্শিত হবে।',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
              ),
              if (_selectedCategory != 'সব মাটি') ...[
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: () {
                    setState(() {
                      _selectedCategory = 'সব মাটি';
                    });
                  },
                  icon: const Icon(Icons.refresh_rounded, size: 16),
                  label: const Text('সব মাটির তথ্য দেখুন'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF2E7D32),
                    side: const BorderSide(color: Color(0xFF2E7D32)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      physics: const BouncingScrollPhysics(),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 14),
      itemBuilder: (context, index) {
        final item = items[index];
        return _buildSoilCard(context, item);
      },
    );
  }

  /// আধুনিক ও আকর্ষণীয় নিউজ/ব্লগ স্টাইল মাটির কার্ড
  Widget _buildSoilCard(BuildContext context, Map<String, dynamic> item) {
    final title = (item['title'] ?? item['soilName'] ?? item['name'] ?? 'মাটির তথ্য').toString();
    final category = (item['category'] ?? item['soilType'] ?? 'মাটি').toString();
    final ph = (item['phRange'] ?? item['ph'] ?? '').toString();
    final crops = (item['suitableCrops'] ?? item['crops'] ?? '').toString();
    final characteristics = (item['characteristics'] ?? item['description'] ?? '').toString();
    final fertilizer = (item['fertilizerManagement'] ?? item['fertilizer'] ?? '').toString();
    final imageUrl = _normalizeSoilImageUrl(item);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE4EDE4), width: 1.1),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ইমেজ ও গ্লাসমর্ফিক ক্যাটাগরি হেডার (ছবিতে ট্যাপ করলেই ডিটেইলস ওপেন হবে)
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => _showSoilDetailModal(context, item),
                splashColor: const Color(0x222E7D32),
                highlightColor: const Color(0x112E7D32),
                child: SizedBox(
                  height: 190.0,
                  width: double.infinity,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      _buildCardImage(imageUrl, title, 190.0),

                      // উপরে ক্যাটাগরি ব্যাজ (Glassmorphic Top-Left Pill)
                      Positioned(
                        top: 12,
                        left: 12,
                        child: IgnorePointer(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
                            decoration: BoxDecoration(
                              color: const Color(0xE0133B18), // Deep green glassmorphic
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.white.withOpacity(0.32), width: 1),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.18),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF81C784),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  category.isNotEmpty ? category : 'মাটির ধরন',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.2,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      // pH মান ব্যাজ (Top-Right Pill)
                      if (ph.isNotEmpty)
                        Positioned(
                          top: 12,
                          right: 12,
                          child: IgnorePointer(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xE600695C),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: Colors.white.withOpacity(0.25), width: 1),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.15),
                                    blurRadius: 5,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.science_rounded, color: Color(0xFF80CBC4), size: 12),
                                  const SizedBox(width: 4),
                                  Text(
                                    'pH $ph',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // নিচে হেডলাইন: ভিন্ন ও আকর্ষণীয় ভিজ্যুয়াল হায়ারার্কি (ডার্ক চারকোল/ডিপ-গ্রিন বোল্ড ও ভার্টিক্যাল অ্যাকসেন্ট বার)
                InkWell(
                  onTap: () => _showSoilDetailModal(context, item),
                  borderRadius: BorderRadius.circular(6),
                  child: Container(
                    decoration: const BoxDecoration(
                      border: Border(
                        left: BorderSide(color: Color(0xFF2E7D32), width: 3.5),
                      ),
                    ),
                    padding: const EdgeInsets.only(left: 10, top: 2, bottom: 2),
                    margin: const EdgeInsets.only(bottom: 10),
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16.5,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1B2E1E),
                        height: 1.38,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ),
                ),

                // বিবরণ / বৈশিষ্ট্য
                if (characteristics.isNotEmpty) ...[
                  Text(
                    characteristics,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 10),
                ],

                // উপযোগী ফসল ও pH মান চিপস বক্স
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9FAF9),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFE8EFE8)),
                  ),
                  child: Column(
                    children: [
                      if (crops.isNotEmpty)
                        Row(
                          children: [
                            const Icon(Icons.eco_rounded, size: 15, color: Color(0xFF2E7D32)),
                            const SizedBox(width: 6),
                            const Text('উপযোগী ফসল: ', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                            Expanded(
                              child: Text(
                                crops,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                              ),
                            ),
                          ],
                        ),
                      if (crops.isNotEmpty && ph.isNotEmpty)
                        const Divider(height: 12, color: Color(0xFFE8EFE8)),
                      if (ph.isNotEmpty)
                        Row(
                          children: [
                            const Icon(Icons.science_rounded, size: 15, color: Color(0xFF0277BD)),
                            const SizedBox(width: 6),
                            const Text('মাটির মান (pH): ', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                            Expanded(
                              child: Text(
                                ph,
                                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),

                // সার ও পরিচর্যা পরামর্শ (যদি থাকে)
                if (fertilizer.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F8F1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.tips_and_updates_outlined, size: 15, color: Color(0xFF2E7D32)),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'সার ও পরিচর্যা: $fertilizer',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 11.5,
                              color: Color(0xFF1B5E20),
                              height: 1.35,
                            ),
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
    );
  }

  /// Cloudflare R2 সহ যেকোনো নেটওয়ার্ক ইমেজ নিরাপদে রেন্ডার করার নন-ব্লকিং হেল্পার
  Widget _buildCardImage(String imageUrl, String soilName, [double imageHeight = 190.0]) {
    final cleanUrl = imageUrl.trim();

    return SizedBox(
      height: imageHeight,
      width: double.infinity,
      child: cleanUrl.isEmpty
          ? _buildImagePlaceholder(imageHeight, soilName)
          : CachedNetworkImage(
              imageUrl: cleanUrl,
              height: imageHeight,
              width: double.infinity,
              fit: BoxFit.cover,
              memCacheHeight: 450,
              fadeInDuration: const Duration(milliseconds: 200),
              placeholder: (context, url) => Container(
                color: const Color(0xFFF1F8F1),
                child: const Center(
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      color: Color(0xFF2E7D32),
                    ),
                  ),
                ),
              ),
              errorWidget: (context, errorUrl, error) {
                debugPrint('Soil Card Image Error: $errorUrl -> $error');
                return _buildImagePlaceholder(imageHeight, soilName);
              },
            ),
    );
  }

  /// ডিফল্ট আকর্ষণীয় ইমেজ প্লেসহোল্ডার
  Widget _buildImagePlaceholder(double height, String soilName) {
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
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF2E7D32).withOpacity(0.15),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: const Icon(
                Icons.terrain_rounded,
                size: 28,
                color: Color(0xFF2E7D32),
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                soilName.isNotEmpty ? soilName : 'কৃষি কথা – মাটির স্বাস্থ্য',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 12.5,
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
