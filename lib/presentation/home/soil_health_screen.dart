import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import '../../core/constants/app_colors.dart';
import '../../global_popup/global_popup.dart';

class SoilHealthScreen extends StatefulWidget {
  final String? initialCategory;

  const SoilHealthScreen({super.key, this.initialCategory});

  @override
  State<SoilHealthScreen> createState() => _SoilHealthScreenState();
}

class _SoilHealthScreenState extends State<SoilHealthScreen> {
  late String _selectedCategory;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  final List<String> _baseCategories = [
    'সব মাটি',
    'দোআঁশ মাটি',
    'এঁটেল মাটি',
    'বেলে মাটি',
    'পলি মাটি',
    'লাল/পাহাড়ি মাটি',
    'লবণাক্ত মাটি',
  ];

  late final Stream<QuerySnapshot> _soilStream;

  @override
  void initState() {
    super.initState();
    _soilStream = FirebaseFirestore.instance.collection('soil_health').limit(100).snapshots();
    _selectedCategory = widget.initialCategory ?? 'সব মাটি';
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showSoilDetailModal(BuildContext context, Map<String, dynamic> data) {
    final title = (data['title'] ?? data['soilName'] ?? data['name'] ?? 'মাটির তথ্য').toString();
    final category = (data['category'] ?? data['soilType'] ?? 'মাটি').toString();
    final ph = (data['phRange'] ?? data['ph'] ?? 'উল্লেখ নেই').toString();
    final crops = (data['suitableCrops'] ?? data['crops'] ?? 'উল্লেখ নেই').toString();
    final characteristics = (data['characteristics'] ?? data['description'] ?? 'বিস্তারিত তথ্য শীঘ্রই যুক্ত হবে।').toString();
    final fertilizer = (data['fertilizerManagement'] ?? data['fertilizer'] ?? 'সুষম সার প্রয়োগ ও সঠিক পরিচর্যা করুন।').toString();
    final imageUrl = (data['imageUrl'] ?? data['img'] ?? '').toString();

    GlobalPopup.showCustom(
      context,
      showLogo: true,
      title: title,
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.62,
        ),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // ছবি (Cloudflare R2)
              if (imageUrl.isNotEmpty) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: CachedNetworkImage(
                    imageUrl: imageUrl,
                    height: 150,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Shimmer.fromColors(
                      baseColor: Colors.grey.shade200,
                      highlightColor: Colors.grey.shade100,
                      child: Container(height: 150, color: Colors.white),
                    ),
                    errorWidget: (_, __, ___) => const SizedBox.shrink(),
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
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
                          'pH: $ph',
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

              // উপযোগী ফসল
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
                  style: const TextStyle(fontSize: 13, color: Color(0xFF33691E), height: 1.4),
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
                  style: const TextStyle(fontSize: 13, color: Color(0xFF4E342E), height: 1.4),
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
                  style: const TextStyle(fontSize: 13, color: Color(0xFF01579B), height: 1.4),
                ),
              ),
              const SizedBox(height: 18),

              // বন্ধ করুন বাটন (সেন্ট্রালাইজড গ্লোবাল স্টাইল)
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
      // ২. "চাষ ক্যালেন্ডার" পেইজের মতো হুবহু AppBar (TopBar)
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
        child: StreamBuilder<QuerySnapshot>(
          stream: _soilStream,
          builder: (context, snapshot) {
            final docs = snapshot.data?.docs ?? [];

            // ৩. ডাইনামিক ক্যাটাগরি তালিকা তৈরি (বেস ক্যাটাগরি + ফায়ারবেসের নতুন ক্যাটাগরি)
            final Set<String> dynamicCategories = Set.from(_baseCategories);
            for (final doc in docs) {
              final data = doc.data() as Map<String, dynamic>;
              final cat = (data['category'] ?? data['soilType'] ?? '').toString().trim();
              if (cat.isNotEmpty && !dynamicCategories.contains(cat)) {
                dynamicCategories.add(cat);
              }
            }
            final categoriesList = dynamicCategories.toList();

            return Column(
              children: [
                // ২ & ৩. "চাষ ক্যালেন্ডার" পেইজের হুবহু কালারিং টপবার বক্স (সার্চ বার ও ক্যাটাগরি চিপস সহ)
                _buildColoredTopBar(categoriesList),

                // ৪. মাটির তালিকা (StreamBuilder রিয়েল-টাইম ডেটা ও R2 ইমেজ)
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
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 14),
      child: Column(
        children: [
          // সার্চ বার (পরিষ্কার সাদা কার্ড ও গ্রিন আইকন)
          Container(
            height: 42,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TextField(
              controller: _searchController,
              style: const TextStyle(fontSize: 13.5, color: AppColors.textPrimary),
              decoration: InputDecoration(
                hintText: 'মাটির নাম, pH বা ফসল দিয়ে খুঁজুন...',
                hintStyle: const TextStyle(fontSize: 12.5, color: AppColors.textMuted),
                prefixIcon: const Icon(Icons.search_rounded, size: 20, color: Color(0xFF2E7D32)),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, size: 16, color: AppColors.textMuted),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
              onChanged: (val) => setState(() => _searchQuery = val.trim()),
            ),
          ),

          const SizedBox(height: 12),

          // ৩. মাটির ক্যাটাগরি ফিল্টার চিপস (হুবহু "চাষ ক্যালেন্ডার" স্টাইল)
          SizedBox(
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
        ],
      ),
    );
  }

  Widget _buildSoilContent(AsyncSnapshot<QuerySnapshot> snapshot, List<QueryDocumentSnapshot> docs) {
    if (snapshot.connectionState == ConnectionState.waiting && docs.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF1B5E20)),
      );
    }

    if (snapshot.hasError) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.cloud_off_rounded, size: 48, color: Colors.grey),
              const SizedBox(height: 12),
              Text(
                'তথ্য লোড করতে সমস্যা হয়েছে: ${snapshot.error}',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey, fontSize: 13),
              ),
            ],
          ),
        ),
      );
    }

    if (docs.isEmpty) {
      return _buildEmptyState('ডাটাবেসে এখনো কোনো মাটির স্বাস্থ্য সংক্রান্ত তথ্য যুক্ত করা হয়নি।');
    }

    // ফিল্টারিং ও সার্চিং
    final filteredDocs = docs.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      final title = (data['title'] ?? data['soilName'] ?? data['name'] ?? '').toString().toLowerCase();
      final category = (data['category'] ?? data['soilType'] ?? '').toString().toLowerCase();
      final ph = (data['phRange'] ?? data['ph'] ?? '').toString().toLowerCase();
      final crops = (data['suitableCrops'] ?? data['crops'] ?? '').toString().toLowerCase();
      final characteristics = (data['characteristics'] ?? data['description'] ?? '').toString().toLowerCase();
      final fertilizer = (data['fertilizerManagement'] ?? data['fertilizer'] ?? '').toString().toLowerCase();

      // ক্যাটাগরি ফিল্টার
      if (_selectedCategory != 'সব মাটি') {
        final targetCat = _selectedCategory.toLowerCase();
        if (!category.contains(targetCat) && !title.contains(targetCat)) {
          return false;
        }
      }

      // সার্চ কুয়েরি
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final matches = title.contains(q) ||
            category.contains(q) ||
            ph.contains(q) ||
            crops.contains(q) ||
            characteristics.contains(q) ||
            fertilizer.contains(q);
        if (!matches) return false;
      }

      return true;
    }).toList();

    // ইন-মেমোরি সর্ট (সর্বশেষ আপডেট হওয়া তথ্য প্রথমে)
    filteredDocs.sort((a, b) {
      final dataA = a.data() as Map<String, dynamic>;
      final dataB = b.data() as Map<String, dynamic>;
      final timeA = (dataA['updatedAt'] as Timestamp?)?.millisecondsSinceEpoch ??
          (dataA['createdAt'] as Timestamp?)?.millisecondsSinceEpoch ??
          0;
      final timeB = (dataB['updatedAt'] as Timestamp?)?.millisecondsSinceEpoch ??
          (dataB['createdAt'] as Timestamp?)?.millisecondsSinceEpoch ??
          0;
      return timeB.compareTo(timeA);
    });

    if (filteredDocs.isEmpty) {
      return _buildEmptyState('আপনার অনুসন্ধানের সাথে কোনো মাটির তথ্য মেলেনি।');
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      physics: const BouncingScrollPhysics(),
      itemCount: filteredDocs.length,
      separatorBuilder: (_, __) => const SizedBox(height: 14),
      itemBuilder: (context, index) {
        final doc = filteredDocs[index];
        final data = doc.data() as Map<String, dynamic>;
        return _buildSoilCard(context, data);
      },
    );
  }

  Widget _buildSoilCard(BuildContext context, Map<String, dynamic> data) {
    final title = (data['title'] ?? data['soilName'] ?? data['name'] ?? 'মাটির তথ্য').toString();
    final category = (data['category'] ?? data['soilType'] ?? 'মাটি').toString();
    final ph = (data['phRange'] ?? data['ph'] ?? 'উল্লেখ নেই').toString();
    final crops = (data['suitableCrops'] ?? data['crops'] ?? 'উল্লেখ নেই').toString();
    final characteristics = (data['characteristics'] ?? data['description'] ?? '').toString();
    final imageUrl = (data['imageUrl'] ?? data['img'] ?? '').toString();

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _showSoilDetailModal(context, data),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE0E0E0), width: 1),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0A000000),
                blurRadius: 8,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ৪. Cloudflare R2 ছবি (CachedNetworkImage + Shimmer)
              if (imageUrl.isNotEmpty)
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                  child: CachedNetworkImage(
                    imageUrl: imageUrl,
                    height: 140,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Shimmer.fromColors(
                      baseColor: Colors.grey.shade200,
                      highlightColor: Colors.grey.shade100,
                      child: Container(height: 140, color: Colors.white),
                    ),
                    errorWidget: (_, __, ___) => Container(
                      height: 140,
                      color: const Color(0xFFE8F5E9),
                      child: const Center(
                        child: Icon(Icons.terrain_rounded, size: 48, color: Color(0xFF2E7D32)),
                      ),
                    ),
                  ),
                ),

              Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // টাইটেল এবং ক্যাটাগরি ব্যাজ
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF263238),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8F5E9),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFF81C784), width: 1),
                          ),
                          child: Text(
                            category,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1B5E20),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // pH লেভেল ও ফসল চিপস
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE0F2F1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.science_rounded, size: 13, color: Color(0xFF00695C)),
                              const SizedBox(width: 4),
                              Text(
                                'pH: $ph',
                                style: const TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF00695C),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'উপযোগী: $crops',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF546E7A),
                            ),
                          ),
                        ),
                      ],
                    ),

                    if (characteristics.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        characteristics,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12.5,
                          color: Color(0xFF78909C),
                          height: 1.35,
                        ),
                      ),
                    ],

                    const SizedBox(height: 12),

                    // বাটন: সার ও পরিচর্যা দেখুন
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1B5E20),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'সার ও পরিচর্যা দেখুন',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              SizedBox(width: 4),
                              Icon(Icons.arrow_forward_ios_rounded, size: 11, color: Colors.white),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: const BoxDecoration(
                color: Color(0xFFE8F5E9),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.terrain_rounded,
                size: 42,
                color: Color(0xFF2E7D32),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF546E7A),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
