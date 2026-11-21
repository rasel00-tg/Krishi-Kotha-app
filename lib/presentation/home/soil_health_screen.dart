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

  @override
  void initState() {
    super.initState();
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
          maxHeight: MediaQuery.of(context).size.height * 0.65,
        ),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // ছবি (যদি থাকে)
              if (imageUrl.isNotEmpty) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: CachedNetworkImage(
                    imageUrl: imageUrl,
                    height: 160,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Shimmer.fromColors(
                      baseColor: Colors.grey.shade200,
                      highlightColor: Colors.grey.shade100,
                      child: Container(height: 160, color: Colors.white),
                    ),
                    errorBuilder: (_, __, ___) => const SizedBox.shrink(),
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
              const SizedBox(height: 4),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F8E9),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  crops,
                  style: const TextStyle(fontSize: 13, color: Color(0xFF33691E), height: 1.4),
                ),
              ),
              const SizedBox(height: 12),

              // মাটির বৈশিষ্ট্য
              _buildModalSectionHeader('মাটির বৈশিষ্ট্য ও গঠন', Icons.info_outline_rounded, const Color(0xFF0288D1)),
              const SizedBox(height: 4),
              Text(
                characteristics,
                style: const TextStyle(fontSize: 13, color: Color(0xFF37474F), height: 1.45),
              ),
              const SizedBox(height: 12),

              // সার ব্যবস্থাপনা ও পরিচর্যা
              _buildModalSectionHeader('সার ব্যবস্থাপনা ও পরিচর্যা', Icons.water_drop_outlined, const Color(0xFFE65100)),
              const SizedBox(height: 4),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF3E0),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  fertilizer,
                  style: const TextStyle(fontSize: 13, color: Color(0xFFBF360C), height: 1.45),
                ),
              ),
              const SizedBox(height: 18),

              // ঠিক আছে বাটন
              SizedBox(
                width: double.infinity,
                height: 44,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context, rootNavigator: true).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00897B),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('ঠিক আছে', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
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
            fontSize: 13.5,
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
              'মাটির ধরন, pH মাত্রা ও উপযোগী ফসল নির্দেশিকা',
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
        child: Column(
          children: [
            // ১. কালারিং টপবার (Colored Top Bar with Soil Categories & Search)
            Container(
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
                        hintText: 'মাটির নাম, pH বা ফসল খুঁজুন...',
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

                  // মাটির ক্যাটাগরি ফিল্টার চিপস (হরাইজন্টাল স্ক্রলেবল)
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance.collection('soil_health').snapshots(),
                    builder: (context, catSnap) {
                      final Set<String> categories = Set.from(_baseCategories);
                      if (catSnap.hasData) {
                        for (var doc in catSnap.data!.docs) {
                          final data = doc.data() as Map<String, dynamic>?;
                          final cat = data?['category'] ?? data?['soilType'];
                          if (cat != null && cat.toString().trim().isNotEmpty) {
                            categories.add(cat.toString().trim());
                          }
                        }
                      }
                      final catList = categories.toList();

                      return SizedBox(
                        height: 38,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: catList.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 8),
                          itemBuilder: (context, index) {
                            final cat = catList[index];
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
                      );
                    },
                  ),
                ],
              ),
            ),

            // ২. রিয়েল-টাইম মাটির কার্ড তালিকা
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('soil_health')
                    .orderBy('updatedAt', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    // ফলব্যাক কোয়েরি (যদি ইনডেক্সিং ছাড়া সরাসরি ডকুমেন্টস আসে)
                    return StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance.collection('soil_health').snapshots(),
                      builder: (context, fallbackSnap) {
                        if (fallbackSnap.connectionState == ConnectionState.waiting) {
                          return _buildLoadingShimmer();
                        }
                        return _buildSoilList(fallbackSnap.data?.docs ?? []);
                      },
                    );
                  }

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return _buildLoadingShimmer();
                  }

                  final docs = snapshot.data?.docs ?? [];
                  return _buildSoilList(docs);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSoilList(List<QueryDocumentSnapshot> docs) {
    // ফিল্টারিং
    final filtered = docs.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      final title = (data['title'] ?? data['soilName'] ?? data['name'] ?? '').toString().toLowerCase();
      final category = (data['category'] ?? data['soilType'] ?? '').toString();
      final crops = (data['suitableCrops'] ?? data['crops'] ?? '').toString().toLowerCase();
      final desc = (data['characteristics'] ?? data['description'] ?? '').toString().toLowerCase();
      final ph = (data['phRange'] ?? data['ph'] ?? '').toString().toLowerCase();

      // ক্যাটাগরি ফিল্টার
      if (_selectedCategory != 'সব মাটি' && category != _selectedCategory) {
        return false;
      }

      // সার্চ ফিল্টার
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final match = title.contains(q) ||
            category.toLowerCase().contains(q) ||
            crops.contains(q) ||
            desc.contains(q) ||
            ph.contains(q);
        if (!match) return false;
      }

      return true;
    }).toList();

    if (filtered.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFC8E6C9), width: 1.5),
                ),
                child: const Icon(
                  Icons.terrain_rounded,
                  size: 36,
                  color: Color(0xFF2E7D32),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'কোনো মাটির তথ্য পাওয়া যায়নি',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                _searchQuery.isNotEmpty || _selectedCategory != 'সব মাটি'
                    ? 'অন্য ক্যাটাগরি বা শব্দ দিয়ে অনুসন্ধান করে দেখুন।'
                    : 'ডাটাবেসে এখনো কোনো মাটির স্বাস্থ্য সংক্রান্ত তথ্য যুক্ত করা হয়নি।',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
              ),
              if (_searchQuery.isNotEmpty || _selectedCategory != 'সব মাটি') ...[
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: () {
                    _searchController.clear();
                    setState(() {
                      _searchQuery = '';
                      _selectedCategory = 'সব মাটি';
                    });
                  },
                  icon: const Icon(Icons.refresh_rounded, size: 16),
                  label: const Text('ফিল্টার রিসেট করুন'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF2E7D32),
                    side: const BorderSide(color: Color(0xFF81C784)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      physics: const BouncingScrollPhysics(),
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final doc = filtered[index];
        final data = doc.data() as Map<String, dynamic>;
        return _buildSoilCard(context, data);
      },
    );
  }

  Widget _buildSoilCard(BuildContext context, Map<String, dynamic> data) {
    final title = (data['title'] ?? data['soilName'] ?? data['name'] ?? 'অজ্ঞাত মাটি').toString();
    final category = (data['category'] ?? data['soilType'] ?? 'মাটি').toString();
    final ph = (data['phRange'] ?? data['ph'] ?? '৬.০ - ৭.০').toString();
    final crops = (data['suitableCrops'] ?? data['crops'] ?? 'বিভিন্ন ধরনের ফসল').toString();
    final desc = (data['characteristics'] ?? data['description'] ?? '').toString();
    final imageUrl = (data['imageUrl'] ?? data['img'] ?? '').toString();

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE8F5E9), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1B5E20).withOpacity(0.06),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
          const BoxShadow(
            color: Color(0x06000000),
            blurRadius: 4,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showSoilDetailModal(context, data),
          borderRadius: BorderRadius.circular(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ১. ছবি ও ব্যাজ
              if (imageUrl.isNotEmpty)
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
                  child: Stack(
                    children: [
                      CachedNetworkImage(
                        imageUrl: imageUrl,
                        height: 160,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Shimmer.fromColors(
                          baseColor: Colors.grey.shade200,
                          highlightColor: Colors.grey.shade100,
                          child: Container(
                            height: 160,
                            width: double.infinity,
                            color: Colors.white,
                          ),
                        ),
                        errorBuilder: (context, error, stackTrace) => Container(
                          height: 120,
                          color: const Color(0xFFEFEBE9),
                          child: const Center(
                            child: Icon(Icons.terrain_rounded, size: 40, color: Color(0xFF8D6E63)),
                          ),
                        ),
                      ),
                      // ক্যাটাগরি ওভারলে ব্যাজ
                      Positioned(
                        left: 12,
                        top: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1B5E20).withOpacity(0.88),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.terrain_rounded, size: 12, color: Colors.white),
                              const SizedBox(width: 4),
                              Text(
                                category,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      // pH ওভারলে ব্যাজ
                      Positioned(
                        right: 12,
                        top: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.92),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.15),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                          child: Text(
                            'pH: $ph',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF00695C),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              // ২. বিবরণী বডি
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ছবি না থাকলে ক্যাটাগরি ও pH এখানে দেখাবে
                    if (imageUrl.isEmpty) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE8F5E9),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: const Color(0xFFC8E6C9)),
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
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE0F2F1),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Text(
                              'pH: $ph',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF00695C),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                    ],

                    // মাটির নাম
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16.5,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // উপযোগী ফসল
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F8E9),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.eco_rounded, size: 15, color: Color(0xFF2E7D32)),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'উপযোগী ফসল: $crops',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF2E7D32),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),

                    if (desc.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        desc,
                        style: const TextStyle(
                          fontSize: 12.5,
                          color: AppColors.textSecondary,
                          height: 1.4,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],

                    const SizedBox(height: 12),

                    // অ্যাকশন ফুটনোট
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: const [
                        Text(
                          'সার ও পরিচর্যা দেখুন',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF00897B),
                          ),
                        ),
                        SizedBox(width: 4),
                        Icon(Icons.arrow_forward_ios_rounded, size: 12, color: Color(0xFF00897B)),
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

  Widget _buildLoadingShimmer() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 4,
      itemBuilder: (_, __) => Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Shimmer.fromColors(
          baseColor: Colors.grey.shade200,
          highlightColor: Colors.grey.shade100,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 140,
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(height: 16, width: 140, color: Colors.white),
                    const SizedBox(height: 10),
                    Container(height: 12, width: double.infinity, color: Colors.white),
                    const SizedBox(height: 6),
                    Container(height: 12, width: 200, color: Colors.white),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
