import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/widgets/shimmer_loader.dart';
import '../../core/widgets/premium_loading_widget.dart';
import '../../core/widgets/empty_state_widget.dart';
import '../../data/models/crop_model.dart';
import '../../providers/crop_provider.dart';
import 'crop_detail_screen.dart';
import 'pest_catalog_screen.dart';

class CropListScreen extends StatefulWidget {
  const CropListScreen({super.key});

  static const List<String> categories = [
    AppStrings.allCrops,
    AppStrings.categoryCereal,
    AppStrings.categoryVegetable,
    AppStrings.categoryFruit,
    AppStrings.categorySpice,
  ];

  @override
  State<CropListScreen> createState() => _CropListScreenState();
}

class _CropListScreenState extends State<CropListScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  String _searchQuery = '';
  bool _isSearchFocused = false;
  bool _isSearchExpanded = false;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.trim().toLowerCase();
      });
    });
    _searchFocusNode.addListener(() {
      setState(() {
        _isSearchFocused = _searchFocusNode.hasFocus;
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cropProvider = Provider.of<CropProvider>(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        top: true,
        bottom: false,
        child: Column(
          children: [
            // 1. Full-Width Glassmorphic Search Bar with Interactive Focus Animation
            _buildModernSearchHeader(context),

            // 2. Section-Colored Vibrant Category Chips
            _buildCategoryChipsRow(cropProvider),

            // 3. Dynamic Crop Cards via Firestore StreamBuilder
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('crops').snapshots().timeout(
                  const Duration(seconds: 3),
                  onTimeout: (sink) async {
                    try {
                      final snap = await FirebaseFirestore.instance
                          .collection('crops')
                          .get(const GetOptions(source: Source.serverAndCache));
                      sink.add(snap);
                    } catch (e) {
                      sink.addError(e);
                    }
                  },
                ),
                builder: (context, snapshot) {
                  final bool hasData = snapshot.hasData && snapshot.data != null;
                  final bool isLoading = snapshot.connectionState == ConnectionState.waiting && !hasData;

                  // Clear error handling without getting stuck in infinite loading
                  if (snapshot.hasError && !hasData) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.cloud_off_rounded, color: Colors.red, size: 48),
                            const SizedBox(height: 12),
                            Text(
                              'Firestore ত্রুটি: ${snapshot.error}',
                              style: const TextStyle(color: Colors.red, fontSize: 15, fontWeight: FontWeight.bold),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 12),
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                              ),
                              onPressed: () {
                                cropProvider.setCategory(AppStrings.allCrops);
                              },
                              icon: const Icon(Icons.refresh, size: 18),
                              label: const Text('পুনরায় চেষ্টা করুন'),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  // 100% Defensive Null-Safe Parsing
                  final docs = snapshot.data?.docs ?? [];
                  final List<CropModel> parsedCrops = [];
                  for (final doc in docs) {
                    try {
                      parsedCrops.add(CropModel.fromFirestore(doc));
                    } catch (e) {
                      debugPrint('CropModel parse error for doc ${doc.id}: $e');
                    }
                  }

                  var crops = parsedCrops;
                  final selectedCat = cropProvider.selectedCategory.trim();

                  // Category Filter: Unrestricted if default/all
                  final bool isAllCategory = selectedCat.isEmpty ||
                      selectedCat == AppStrings.allCrops ||
                      selectedCat == 'সকল ফসল' ||
                      selectedCat == 'সকল' ||
                      selectedCat.toLowerCase() == 'all';

                  if (!isAllCategory) {
                    crops = crops.where((c) {
                      final cCat = c.category.toLowerCase().trim();
                      final target = selectedCat.toLowerCase();
                      if (cCat == target) return true;
                      if (target.contains('দানাদার') && (cCat.contains('দানা') || cCat.contains('cereal') || cCat.contains('ধান'))) return true;
                      if (target.contains('সবজি') && (cCat.contains('সবজি') || cCat.contains('vegetable'))) return true;
                      if (target.contains('ফল') && (cCat.contains('ফল') || cCat.contains('fruit'))) return true;
                      if (target.contains('মসলা') && (cCat.contains('মসলা') || cCat.contains('spice'))) return true;
                      return false;
                    }).toList();
                  }

                  // Search Query Filter: Unrestricted when empty
                  if (_searchQuery.isNotEmpty) {
                    crops = crops.where((c) {
                      final name = c.nameBn.toLowerCase();
                      final cat = c.category.toLowerCase();
                      final season = c.season.toLowerCase();
                      final soil = c.soilType.toLowerCase();
                      return name.contains(_searchQuery) ||
                          cat.contains(_searchQuery) ||
                          season.contains(_searchQuery) ||
                          soil.contains(_searchQuery);
                    }).toList();
                  }

                  Widget mainListWidget;
                  if (crops.isEmpty && hasData) {
                    mainListWidget = Center(
                      child: EmptyStateWidget(
                        icon: Icons.grass_rounded,
                        message: _searchQuery.isNotEmpty
                            ? '"$_searchQuery" সম্পর্কিত কোনো ফসল পাওয়া যায়নি'
                            : 'কোনো ফসল পাওয়া যায়নি',
                        action: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          onPressed: () {
                            _searchController.clear();
                            cropProvider.setCategory(AppStrings.allCrops);
                          },
                          icon: const Icon(Icons.refresh, size: 18),
                          label: const Text('সকল ফসল দেখুন'),
                        ),
                      ),
                    );
                  } else {
                    // Optimized edge-to-edge layout with reduced margins (10px padding)
                    mainListWidget = ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      itemCount: crops.length,
                      itemBuilder: (context, index) {
                        final crop = crops[index];
                        return _buildCropListCard(context, crop);
                      },
                    );
                  }

                  // Smooth Stack: Instant unblock upon data arrival with elegant fading transition
                  return Stack(
                    children: [
                      mainListWidget,
                      if (isLoading)
                        Positioned.fill(
                          child: AnimatedOpacity(
                            opacity: isLoading ? 1.0 : 0.0,
                            duration: const Duration(milliseconds: 300),
                            child: const PremiumLoadingWidget(topic: 'ফসলের তথ্য'),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 1. Expandable Animated Search Bar (Default: Compact Icon Button -> Expands smoothly to typing field)
  Widget _buildModernSearchHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.92),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: AnimatedCrossFade(
        duration: const Duration(milliseconds: 300),
        firstCurve: Curves.easeOutCubic,
        secondCurve: Curves.easeInCubic,
        crossFadeState: _isSearchExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
        // 1. Default State: Title with Leaf Badge & Compact Stylish Glassmorphic Search Button
        firstChild: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primaryContainer.withOpacity(0.45),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.eco_rounded, color: AppColors.primary, size: 20),
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'ফসলের তথ্য ও গাইড',
                    style: TextStyle(
                      fontSize: 16.5,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                      letterSpacing: 0.1,
                    ),
                  ),
                  SizedBox(height: 1.5),
                  Text(
                    'সকল ফসলের আধুনিক চাষাবাদ নির্দেশিকা',
                    style: TextStyle(
                      fontSize: 11.5,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            // Stylish Glassmorphic Search Button (Expands on Tap)
            Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () {
                  setState(() {
                    _isSearchExpanded = true;
                  });
                  Future.delayed(const Duration(milliseconds: 150), () {
                    _searchFocusNode.requestFocus();
                  });
                },
                child: Container(
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFE8F5E9), Color(0xFFC8E6C9)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.primary.withOpacity(0.35), width: 1.2),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.search_rounded,
                    color: AppColors.primary,
                    size: 22,
                  ),
                ),
              ),
            ),
          ],
        ),
        // 2. Expanded State: Full-Width Animated Typing Field with Collapse / Back Button
        secondChild: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          height: 48,
          decoration: BoxDecoration(
            color: _isSearchFocused
                ? const Color(0xFFE8F5E9).withOpacity(0.95)
                : const Color(0xFFF1F5F2).withOpacity(0.85),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _isSearchFocused ? AppColors.primary : Colors.black.withOpacity(0.08),
              width: _isSearchFocused ? 1.5 : 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(_isSearchFocused ? 0.22 : 0.04),
                blurRadius: _isSearchFocused ? 12 : 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              const SizedBox(width: 4),
              IconButton(
                icon: const Icon(Icons.arrow_back_rounded, size: 20, color: AppColors.primary),
                tooltip: 'সার্চ বন্ধ করুন',
                onPressed: () {
                  _searchController.clear();
                  _searchFocusNode.unfocus();
                  setState(() {
                    _isSearchExpanded = false;
                    _searchQuery = '';
                  });
                },
              ),
              Expanded(
                child: TextField(
                  controller: _searchController,
                  focusNode: _searchFocusNode,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                  decoration: InputDecoration(
                    hintText: 'ফসলের নাম দিয়ে খুঁজুন (যেমন: ধান, আলু, বেগুন)...',
                    hintStyle: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary.withOpacity(0.75),
                      fontWeight: FontWeight.normal,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              if (_searchController.text.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 18, color: Colors.grey),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {
                      _searchQuery = '';
                    });
                  },
                ),
              const SizedBox(width: 4),
            ],
          ),
        ),
      ),
    );
  }

  // 2. Section-Colored Category Chips with Individual Soft Palettes & Vibrant Active State
  Widget _buildCategoryChipsRow(CropProvider cropProvider) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('categories').snapshots(),
      builder: (context, catSnapshot) {
        final List<String> dynamicCategories = [
          AppStrings.allCrops,
          AppStrings.categoryCereal,
          AppStrings.categoryVegetable,
          AppStrings.categoryFruit,
          AppStrings.categorySpice,
        ];

        if (catSnapshot.hasData && catSnapshot.data != null) {
          for (final doc in catSnapshot.data!.docs) {
            final data = doc.data() as Map<String, dynamic>?;
            final name = (data?['name_bn'] ?? data?['name'] ?? doc.id.replaceFirst('cat_', '')).toString().trim();
            if (name.isNotEmpty && !dynamicCategories.contains(name)) {
              dynamicCategories.add(name);
            }
          }
        }

        return Container(
          height: 50,
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            itemCount: dynamicCategories.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final cat = dynamicCategories[index];
              final isSelected = cropProvider.selectedCategory == cat;
              final theme = _getCategoryTheme(cat);

              return GestureDetector(
                onTap: () => cropProvider.setCategory(cat),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeInOut,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                    gradient: isSelected
                        ? LinearGradient(
                            colors: theme.activeGradient,
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : null,
                    color: isSelected ? null : theme.tagBg,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isSelected ? Colors.transparent : theme.borderColor,
                      width: 1,
                    ),
                    boxShadow: [
                      if (isSelected)
                        BoxShadow(
                          color: theme.glowColor.withOpacity(0.35),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        )
                      else
                        BoxShadow(
                          color: Colors.black.withOpacity(0.02),
                          blurRadius: 3,
                          offset: const Offset(0, 1),
                        ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      cat,
                      style: TextStyle(
                        color: isSelected ? Colors.white : theme.tagColor,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                        fontSize: 12.5,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  // 4. Section-Based Colorful Crop List Card with "বিস্তারিত" Action Button
  Widget _buildCropListCard(BuildContext context, CropModel crop) {
    final theme = _getCategoryTheme(crop.category);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 5),
      decoration: BoxDecoration(
        color: theme.bgColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: theme.borderColor, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => CropDetailScreen(crop: crop, cropData: crop.toMap()),
                settings: RouteSettings(arguments: crop.toMap()),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // 1. Large Rounded Thumbnail
                Hero(
                  tag: 'crop_img_${crop.id}',
                  child: Container(
                    width: 86,
                    height: 86,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      color: AppColors.surfaceVariant,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.06),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: crop.imageUrl.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: crop.imageUrl,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => const ShimmerCardLoader(height: 86, width: 86),
                            errorWidget: (context, url, error) => Center(
                              child: Icon(Icons.eco_rounded, color: theme.tagColor, size: 36),
                            ),
                          )
                        : Center(
                            child: Icon(Icons.eco_rounded, color: theme.tagColor, size: 36),
                          ),
                  ),
                ),

                const SizedBox(width: 12),

                // 2. Crop Details Typography & Colorful Badges
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Category Tag Badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                        decoration: BoxDecoration(
                          color: theme.tagBg,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: theme.borderColor, width: 0.8),
                        ),
                        child: Text(
                          crop.category,
                          style: TextStyle(
                            color: theme.tagColor,
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),

                      const SizedBox(height: 4),

                      // Bold Crop Name
                      Text(
                        crop.nameBn,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                          letterSpacing: 0.1,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),

                      const SizedBox(height: 5),

                      // Season Badge
                      Row(
                        children: [
                          const Icon(Icons.wb_sunny_rounded, size: 13, color: AppColors.earthyGold),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              'মৌসুম: ${crop.season}',
                              style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 2.5),

                      // Soil Badge
                      Row(
                        children: [
                          const Icon(Icons.terrain_rounded, size: 13, color: Color(0xFF8D6E63)),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              'মাটি: ${crop.soilType}',
                              style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 6),

                // 3. Prominent "বিস্তারিত" Action Button Pill Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: theme.activeGradient,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: theme.glowColor.withOpacity(0.35),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'বিস্তারিত',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(width: 3),
                      Icon(
                        Icons.arrow_forward_ios_rounded,
                        color: Colors.white,
                        size: 10,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Helper function for category themes
  static _CropCategoryTheme _getCategoryTheme(String category) {
    final cat = category.toLowerCase().trim();
    if (cat.contains('দানা') || cat.contains('cereal') || cat.contains('ধান') || cat.contains('গম')) {
      // Golden Amber Theme
      return const _CropCategoryTheme(
        bgColor: Color(0xFFFFFDF5),
        borderColor: Color(0xFFFFECB3),
        tagBg: Color(0xFFFFF8E1),
        tagColor: Color(0xFFE65100),
        activeGradient: [Color(0xFFF57F17), Color(0xFFE65100)],
        glowColor: Color(0xFFF57F17),
      );
    } else if (cat.contains('সবজি') || cat.contains('vegetable')) {
      // Emerald / Mint Theme
      return const _CropCategoryTheme(
        bgColor: Color(0xFFF4FBF7),
        borderColor: Color(0xFFC8E6C9),
        tagBg: Color(0xFFE8F5E9),
        tagColor: Color(0xFF2E7D32),
        activeGradient: [Color(0xFF2E7D32), Color(0xFF1B5E20)],
        glowColor: Color(0xFF2E7D32),
      );
    } else if (cat.contains('ফল') || cat.contains('fruit')) {
      // Coral / Orange Theme
      return const _CropCategoryTheme(
        bgColor: Color(0xFFFFF8F6),
        borderColor: Color(0xFFFFCCBC),
        tagBg: Color(0xFFFBE9E7),
        tagColor: Color(0xFFD84315),
        activeGradient: [Color(0xFFFF7043), Color(0xFFD84315)],
        glowColor: Color(0xFFFF7043),
      );
    } else if (cat.contains('মসলা') || cat.contains('spice')) {
      // Purple / Violet Theme
      return const _CropCategoryTheme(
        bgColor: Color(0xFFFAF5FF),
        borderColor: Color(0xFFE1BEE7),
        tagBg: Color(0xFFF3E5F5),
        tagColor: Color(0xFF7B1FA2),
        activeGradient: [Color(0xFF8E24AA), Color(0xFF4A148C)],
        glowColor: Color(0xFF8E24AA),
      );
    } else {
      // Default / Teal Theme
      return const _CropCategoryTheme(
        bgColor: Color(0xFFF6FAF7),
        borderColor: Color(0xFFD7E7D9),
        tagBg: Color(0xFFE8F5E9),
        tagColor: Color(0xFF2E7D32),
        activeGradient: [Color(0xFF00897B), Color(0xFF004D40)],
        glowColor: Color(0xFF00897B),
      );
    }
  }
}

class _CropCategoryTheme {
  final Color bgColor;
  final Color borderColor;
  final Color tagBg;
  final Color tagColor;
  final List<Color> activeGradient;
  final Color glowColor;

  const _CropCategoryTheme({
    required this.bgColor,
    required this.borderColor,
    required this.tagBg,
    required this.tagColor,
    required this.activeGradient,
    required this.glowColor,
  });
}

