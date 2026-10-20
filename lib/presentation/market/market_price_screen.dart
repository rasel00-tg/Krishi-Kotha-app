import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/utils/bangla_number_converter.dart';
import '../../core/utils/date_formatter.dart';
import '../../core/utils/district_data.dart';
import '../../core/widgets/empty_state_widget.dart';
import '../../core/widgets/premium_loading_widget.dart';
import '../../data/models/market_price_model.dart';
import '../../providers/market_price_provider.dart';
import 'market_price_detail_screen.dart';

class MarketPriceScreen extends StatefulWidget {
  const MarketPriceScreen({super.key});

  @override
  State<MarketPriceScreen> createState() => _MarketPriceScreenState();
}

class _MarketPriceScreenState extends State<MarketPriceScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        Provider.of<MarketPriceProvider>(context, listen: false).resetFilters();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  bool _matchDistrict(String? a, String? b) {
    if (a == null || b == null) return false;
    final cleanA = a.trim().toLowerCase();
    final cleanB = b.trim().toLowerCase();
    if (cleanA.isEmpty || cleanB.isEmpty) return false;
    if (cleanA == cleanB) return true;
    if (cleanA.contains(cleanB) || cleanB.contains(cleanA)) return true;
    // Normalize Bengali characters (র/ড়, য়/য়, ণ/ন)
    final normA = cleanA.replaceAll('ড়', 'ড়').replaceAll('ঢ়', 'ঢ়').replaceAll('য়', 'য়').replaceAll('ণ', 'ন');
    final normB = cleanB.replaceAll('ড়', 'ড়').replaceAll('ঢ়', 'ঢ়').replaceAll('য়', 'য়').replaceAll('ণ', 'ন');
    if (normA == normB || normA.contains(normB) || normB.contains(normA)) return true;

    // Cross-check Bengali and English District/Location names
    const Map<String, String> enBnMap = {
      "cox's bazar": "কক্সবাজার",
      "coxsbazar": "কক্সবাজার",
      "teknaf": "কক্সবাজার",
      "dhaka": "ঢাকা",
      "bogra": "বগুড়া",
      "bogura": "বগুড়া",
      "jessore": "যশোর",
      "jashore": "যশোর",
      "dinajpur": "দিনাজপুর",
      "chittagong": "চট্টগ্রাম",
      "chattogram": "চট্টগ্রাম",
      "rajshahi": "রাজশাহী",
      "rangpur": "রংপুর",
      "khulna": "খুলনা",
      "barisal": "বরিশাল",
      "barishal": "বরিশাল",
      "sylhet": "সিলেট",
      "mymensingh": "ময়মনসিংহ",
    };
    for (final entry in enBnMap.entries) {
      if ((cleanA.contains(entry.key) && normB.contains(entry.value)) ||
          (cleanB.contains(entry.key) && normA.contains(entry.value))) {
        return true;
      }
    }
    return false;
  }

  static const List<String> divisionChips = [
    'সকল বাজার / সারাদেশ',
    'ঢাকা বিভাগ',
    'চট্টগ্রাম বিভাগ',
    'রাজশাহী বিভাগ',
    'রংপুর বিভাগ',
    'খুলনা বিভাগ',
    'বরিশাল বিভাগ',
    'সিলেট বিভাগ',
    'ময়মনসিংহ বিভাগ',
  ];

  @override
  Widget build(BuildContext context) {
    final marketProvider = Provider.of<MarketPriceProvider>(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF8),
      appBar: null, // টপবার অপসারণ: ফুল-স্ক্রিন আধুনিক লুক
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // ১. আধুনিক ফুল-স্ক্রিন হেডার (স্লিক টাইটেল, সার্চ বার ও ফিল্টার)
            _buildModernHeader(context, marketProvider),

            // ২. রিয়েল-টাইম লাইভ বাজার দর গ্রিড (Firestore StreamBuilder)
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('market_prices').snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData && !snapshot.hasError) {
                    return const PremiumLoadingWidget(
                      topic: 'বাজার দর',
                      subtitle: 'অনুগ্রহ করে কিছুক্ষণ অপেক্ষা করুন',
                    );
                  }

                  // লাল বক্সে স্পষ্ট এরর ডিসপ্লে (সাইলেন্ট এরর নির্মূল)
                  if (snapshot.hasError) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Container(
                          padding: const EdgeInsets.all(16.0),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFEBEE),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFEF5350), width: 1.5),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.error_outline_rounded, color: Color(0xFFC62828), size: 48),
                              const SizedBox(height: 10),
                              const Text(
                                'Firestore এরর (সাইলেন্ট এরর ডিটেক্টেড):',
                                style: TextStyle(color: Color(0xFFC62828), fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '${snapshot.error}',
                                textAlign: TextAlign.center,
                                style: const TextStyle(color: Color(0xFFB71C1C), fontSize: 13, fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 14),
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFC62828),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                                onPressed: () {
                                  marketProvider.resetFilters();
                                  _searchController.clear();
                                },
                                icon: const Icon(Icons.refresh, size: 18),
                                label: const Text('ফিল্টার রিসেট ও রিফ্রেশ'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }

                  final docs = snapshot.data?.docs ?? [];
                  if (docs.isEmpty) {
                    return Center(
                      child: EmptyStateWidget(
                        icon: Icons.store_mall_directory_outlined,
                        message: 'কোনো বাজার দর পাওয়া যায়নি',
                        action: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          onPressed: () {
                            marketProvider.resetFilters();
                            _searchController.clear();
                          },
                          icon: const Icon(Icons.refresh, size: 18),
                          label: const Text('ফিল্টার রিসেট করুন'),
                        ),
                      ),
                    );
                  }

                  final List<MarketPriceModel> allPrices = [];
                  for (final doc in docs) {
                    try {
                      allPrices.add(MarketPriceModel.fromFirestore(doc));
                    } catch (e) {
                      debugPrint('MarketPriceModel parse error for doc ${doc.id}: $e');
                    }
                  }

                  // Sorting: newest updated first with safe try-catch
                  try {
                    allPrices.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
                  } catch (e) {
                    debugPrint('Sorting error: $e');
                  }

                  var filteredPrices = allPrices;

                  // ৩. আনরেস্ট্রিক্টেড ডিফল্ট ভিউ ও কেবল ইউজার সিলেক্ট করলে ফিল্টারিং
                  final selectedDivision = marketProvider.selectedDivision;
                  if (selectedDivision.isNotEmpty &&
                      selectedDivision != 'সকল বাজার / সারাদেশ' &&
                      selectedDivision != 'সকল জেলা / সারাদেশ' &&
                      selectedDivision != 'সকল বিভাগ' &&
                      selectedDivision != 'সারাদেশ' &&
                      selectedDivision != 'all') {
                    final divDistricts = BangladeshLocationData.divisionDistricts[selectedDivision] ?? [];
                    filteredPrices = filteredPrices.where((m) =>
                        divDistricts.any((d) => _matchDistrict(m.district, d)) ||
                        _matchDistrict(m.district, selectedDivision)
                    ).toList();
                  }

                  final selectedDistrict = marketProvider.selectedDistrict;
                  if (selectedDistrict.isNotEmpty &&
                      selectedDistrict != 'সারাদেশ' &&
                      selectedDistrict != 'সকল বাজার / সারাদেশ' &&
                      selectedDistrict != 'সকল জেলা / সারাদেশ' &&
                      selectedDistrict != 'সকল জেলা' &&
                      selectedDistrict != 'সব জেলা' &&
                      selectedDistrict != 'all' &&
                      selectedDistrict != BangladeshLocationData.allDistrictsOption) {
                    filteredPrices = filteredPrices.where((m) =>
                        _matchDistrict(m.district, selectedDistrict)
                    ).toList();
                  }

                  final query = marketProvider.searchQuery.trim().toLowerCase();
                  if (query.isNotEmpty) {
                    filteredPrices = filteredPrices.where((m) =>
                      m.cropName.toLowerCase().contains(query) ||
                      m.marketName.toLowerCase().contains(query) ||
                      m.district.toLowerCase().contains(query)
                    ).toList();
                  }

                  if (filteredPrices.isEmpty) {
                    return Center(
                      child: EmptyStateWidget(
                        icon: Icons.search_off_rounded,
                        message: 'কোনো বাজার দর পাওয়া যায়নি',
                        action: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          onPressed: () {
                            marketProvider.resetFilters();
                            _searchController.clear();
                          },
                          icon: const Icon(Icons.refresh, size: 18),
                          label: const Text('সকল এলাকার দর দেখুন'),
                        ),
                      ),
                    );
                  }

                  // ৩. ২-কলামের প্রিমিয়াম প্রোডাক্ট কার্ড গ্রিড (2-Column Grid Layout)
                  return GridView.builder(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.69,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 14,
                    ),
                    itemCount: filteredPrices.length,
                    itemBuilder: (context, index) {
                      return _buildGridPriceCard(context, filteredPrices[index]);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ১. ক্লিন আধুনিক টপ হেডার ও সার্চ অংশ (No Traditional AppBar)
  Widget _buildModernHeader(BuildContext context, MarketPriceProvider marketProvider) {
    final bool isDistrictFiltered = marketProvider.selectedDistrict.isNotEmpty &&
        marketProvider.selectedDistrict != 'সারাদেশ' &&
        marketProvider.selectedDistrict != 'সকল বাজার / সারাদেশ' &&
        marketProvider.selectedDistrict != 'সকল জেলা / সারাদেশ' &&
        marketProvider.selectedDistrict != 'সকল জেলা' &&
        marketProvider.selectedDistrict != 'সব জেলা' &&
        marketProvider.selectedDistrict != 'all' &&
        marketProvider.selectedDistrict != BangladeshLocationData.allDistrictsOption;

    final bool isDivisionFiltered = marketProvider.selectedDivision.isNotEmpty &&
        marketProvider.selectedDivision != 'সকল বাজার / সারাদেশ' &&
        marketProvider.selectedDivision != 'সকল জেলা / সারাদেশ' &&
        marketProvider.selectedDivision != 'সকল বিভাগ' &&
        marketProvider.selectedDivision != 'সারাদেশ' &&
        marketProvider.selectedDivision != 'all';

    final bool hasActiveFilter = isDistrictFiltered || isDivisionFiltered;
    final String activeFilterLabel = isDistrictFiltered
        ? marketProvider.selectedDistrict
        : (isDivisionFiltered ? marketProvider.selectedDivision : '');

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title Bar with Market/Storefront Icon (No Notification Bell Icon)
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 10),
            child: Row(
              children: [
                // মার্কেট রিলেটেড চমৎকার আধুনিক স্টোরফ্রন্ট আইকন/ব্যাজ
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF2E7D32), Color(0xFF1B5E20)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF2E7D32).withOpacity(0.25),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(Icons.storefront_rounded, color: Colors.white, size: 24),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'বাজার দর',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: AppColors.textPrimary,
                          letterSpacing: -0.3,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'আজকের তাজা ফসলের দৈনিক বাজার দর',
                        style: TextStyle(
                          fontSize: 12.5,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Search Field & Square-Rounded Filter Slider Button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    height: 46,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF4F7F4),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.black.withOpacity(0.05)),
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (val) => marketProvider.setSearchQuery(val),
                      style: const TextStyle(fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'ফসল বা বাজারের নাম খুঁজুন...',
                        hintStyle: const TextStyle(fontSize: 13, color: AppColors.textMuted),
                        prefixIcon: const Icon(Icons.search, color: AppColors.primary, size: 21),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, size: 18),
                                onPressed: () {
                                  _searchController.clear();
                                  marketProvider.setSearchQuery('');
                                },
                              )
                            : null,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                // Square-rounded Filter Slider Icon Button
                InkWell(
                  onTap: () => _showDistrictFilter(context, marketProvider),
                  borderRadius: BorderRadius.circular(16),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF2E7D32), Color(0xFF1B5E20)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withOpacity(0.25),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Icon(Icons.tune_rounded, size: 21, color: Colors.white),
                        ),
                      ),
                      if (hasActiveFilter)
                        Positioned(
                          top: -3,
                          right: -3,
                          child: Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: const Color(0xFFFF9800),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ফিল্টার সক্রিয় থাকলে তাৎক্ষণিক ভিজ্যুয়াল ব্যাজ ও ওয়ান-ট্যাপ ক্লিয়ার (চিপস সম্পূর্ণ মুছে ফেলা হয়েছে)
          if (hasActiveFilter)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F5E9),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFF81C784)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.location_on, size: 14, color: AppColors.primary),
                        const SizedBox(width: 4),
                        Text(
                          activeFilterLabel,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: 6),
                        GestureDetector(
                          onTap: () => marketProvider.resetFilters(),
                          child: const Icon(Icons.close_rounded, size: 15, color: AppColors.primary),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => marketProvider.resetFilters(),
                    child: const Text('ফিল্টার রিসেট', style: TextStyle(fontSize: 12, color: AppColors.textMuted, decoration: TextDecoration.underline)),
                  ),
                ],
              ),
            )
          else
            const SizedBox(height: 10),
        ],
      ),
    );
  }

  // ৩. ২-কলামের প্রিমিয়াম প্রোডাক্ট কার্ড গ্রিড আইটেম (2-Column Grid Card)
  Widget _buildGridPriceCard(BuildContext context, MarketPriceModel item) {
    IconData trendIcon = Icons.remove_rounded;
    Color trendColor = const Color(0xFF757575);
    Color trendBgColor = const Color(0xFFF5F5F5);

    final trendKey = item.trend.trim().toLowerCase();
    if (trendKey == 'down') {
      trendIcon = Icons.arrow_downward_rounded;
      trendColor = const Color(0xFFD32F2F); // লাল ডাউন-অ্যারো
      trendBgColor = const Color(0xFFFFEBEE);
    } else if (trendKey == 'up') {
      trendIcon = Icons.arrow_upward_rounded;
      trendColor = const Color(0xFF2E7D32); // সবুজ আপ-অ্যারো
      trendBgColor = const Color(0xFFE8F5E9);
    }

    final String cleanPrice = item.price > 0
        ? (item.price % 1 == 0 ? item.price.toInt().toString() : item.price.toString())
        : (item.priceText.isNotEmpty && item.priceText != '0' ? item.priceText : '০');
    final String displayPrice = '৳${BanglaNumberConverter.toBangla(cleanPrice)}';

    final String cleanRetail = item.retailPrice > 0
        ? (item.retailPrice % 1 == 0 ? item.retailPrice.toInt().toString() : item.retailPrice.toString())
        : (item.retailPriceText.isNotEmpty && item.retailPriceText != '0' ? item.retailPriceText : '০');
    final String displayRetail = '৳${BanglaNumberConverter.toBangla(cleanRetail)}';

    final String displayUnit = item.unit.isNotEmpty ? item.unit : 'কেজি';
    final String locationText = item.district.isNotEmpty
        ? '${item.marketName}, ${item.district}'
        : item.marketName;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          // ৪. পূর্ণাঙ্গ ও আকর্ষণীয় "বাজার দর বিস্তারিত" স্ক্রিন ওপেন
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => MarketPriceDetailScreen(item: item),
            ),
          );
        },
        borderRadius: BorderRadius.circular(20),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.black.withOpacity(0.05)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.035),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image Container with Floating Overlays
              Expanded(
                flex: 11,
                child: Container(
                  width: double.infinity,
                  margin: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFF4F8F4), Color(0xFFEBF5EB)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      item.imageUrl.isNotEmpty
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: CachedNetworkImage(
                                imageUrl: item.imageUrl,
                                width: double.infinity,
                                height: double.infinity,
                                fit: BoxFit.cover,
                                placeholder: (_, __) => const Center(
                                  child: Icon(Icons.eco_rounded, color: AppColors.primary, size: 28),
                                ),
                                errorWidget: (_, __, ___) => const Center(
                                  child: Icon(Icons.eco_rounded, color: AppColors.primary, size: 28),
                                ),
                              ),
                            )
                          : const Center(
                              child: Icon(Icons.eco_rounded, color: AppColors.primary, size: 36),
                            ),

                      // Trend Icon Badge (Top Left)
                      Positioned(
                        top: 6,
                        left: 6,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: trendBgColor,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.06),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                          child: Icon(trendIcon, size: 12, color: trendColor),
                        ),
                      ),

                      // Heart/Favorite Icon (Top Right)
                      Positioned(
                        top: 6,
                        right: 6,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.9),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.06),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                          child: const Icon(Icons.favorite_border_rounded, size: 13, color: AppColors.textMuted),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Content Body
              Expanded(
                flex: 9,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.cropName,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                              height: 1.15,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 3),
                          Row(
                            children: [
                              const Icon(Icons.location_on_outlined, size: 11, color: AppColors.primary),
                              const SizedBox(width: 3),
                              Expanded(
                                child: Text(
                                  locationText,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: AppColors.textSecondary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),

                      // Price & Retail Tag
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Text(
                                displayPrice,
                                style: const TextStyle(
                                  fontSize: 16.5,
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFF1B5E20),
                                  letterSpacing: -0.3,
                                ),
                              ),
                              const SizedBox(width: 2),
                              Text(
                                '/$displayUnit',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF2E7D32),
                                ),
                              ),
                            ],
                          ),
                          if (cleanRetail != '০')
                            Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF1F8E9),
                                  borderRadius: BorderRadius.circular(5),
                                ),
                                child: Text(
                                  'খুচরা $displayRetail',
                                  style: const TextStyle(
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF2E7D32),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Backward compatibility alias
  Widget _buildPriceCard(MarketPriceModel item) {
    return _buildGridPriceCard(context, item);
  }

  // District Filter Modal
  // District Filter Modal
  void _showDistrictFilter(BuildContext context, MarketPriceProvider provider) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        String modalSearch = '';
        String tempDivision = provider.selectedDivision.isNotEmpty &&
                provider.selectedDivision != 'সকল জেলা / সারাদেশ' &&
                provider.selectedDivision != 'সকল বিভাগ' &&
                provider.selectedDivision != 'all'
            ? provider.selectedDivision
            : 'সকল বাজার / সারাদেশ';
        String tempDistrict = provider.selectedDistrict;

        final List<String> modalDivisions = [
          'সকল বাজার / সারাদেশ',
          'ঢাকা বিভাগ',
          'চট্টগ্রাম বিভাগ',
          'রাজশাহী বিভাগ',
          'রংপুর বিভাগ',
          'খুলনা বিভাগ',
          'বরিশাল বিভাগ',
          'সিলেট বিভাগ',
          'ময়মনসিংহ বিভাগ',
        ];

        return StatefulBuilder(
          builder: (context, setModalState) {
            List<String> displayedDistricts;
            if (tempDivision == 'সকল বাজার / সারাদেশ' || tempDivision == 'সকল বিভাগ') {
              displayedDistricts = BangladeshLocationData.districts;
            } else {
              displayedDistricts = BangladeshLocationData.divisionDistricts[tempDivision] ?? [];
            }

            if (modalSearch.trim().isNotEmpty) {
              final q = modalSearch.trim().toLowerCase();
              displayedDistricts = displayedDistricts
                  .where((d) => d.toLowerCase().contains(q))
                  .toList();
            }

            final isAllActive = tempDistrict == BangladeshLocationData.allDistrictsOption ||
                tempDistrict == 'সকল বাজার / সারাদেশ' ||
                tempDistrict == 'সারাদেশ' ||
                tempDistrict == 'সকল জেলা' ||
                (tempDistrict.isEmpty && tempDivision == 'সকল বাজার / সারাদেশ');

            return Container(
              height: MediaQuery.of(context).size.height * 0.85,
              decoration: const BoxDecoration(
                color: Color(0xFFF8FAF8),
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: Column(
                children: [
                  // Drag Handle
                  Container(
                    margin: const EdgeInsets.only(top: 12, bottom: 6),
                    width: 44,
                    height: 4.5,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),

                  // Header Bar
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                color: const Color(0xFFE8F5E9),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Center(
                                child: Icon(Icons.tune_rounded, color: AppColors.primary, size: 20),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: const [
                                Text(
                                  'জেলা / বাজার ফিল্টার',
                                  style: TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                SizedBox(height: 1),
                                Text(
                                  'বিভাগ ও জেলা অনুযায়ী বাজার দর খুঁজুন',
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    color: AppColors.textMuted,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        InkWell(
                          onTap: () => Navigator.pop(ctx),
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.black.withOpacity(0.06)),
                            ),
                            child: const Center(
                              child: Icon(Icons.close_rounded, size: 18, color: AppColors.textSecondary),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Search Field
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    child: Container(
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.black.withOpacity(0.06)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.02),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: TextField(
                        onChanged: (val) {
                          setModalState(() {
                            modalSearch = val;
                          });
                        },
                        style: const TextStyle(fontSize: 13.5),
                        decoration: const InputDecoration(
                          hintText: 'জেলার নাম দিয়ে খুঁজুন (যেমন: কক্সবাজার, বগুড়া)...',
                          hintStyle: TextStyle(fontSize: 12.5, color: AppColors.textMuted),
                          prefixIcon: Icon(Icons.search, size: 20, color: AppColors.primary),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                        ),
                      ),
                    ),
                  ),

                  // Division Filter Chips (Capsule shape, vibrant green active state)
                  Container(
                    height: 48,
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: modalDivisions.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (context, i) {
                        final div = modalDivisions[i];
                        final isDivActive = tempDivision == div;
                        return InkWell(
                          onTap: () {
                            setModalState(() {
                              tempDivision = div;
                              modalSearch = '';
                              // If current tempDistrict doesn't belong to this division, clear it
                              if (div != 'সকল বাজার / সারাদেশ') {
                                final divList = BangladeshLocationData.divisionDistricts[div] ?? [];
                                if (!divList.contains(tempDistrict)) {
                                  tempDistrict = '';
                                }
                              }
                            });
                          },
                          borderRadius: BorderRadius.circular(14),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                            decoration: BoxDecoration(
                              gradient: isDivActive
                                  ? const LinearGradient(
                                      colors: [Color(0xFF2E7D32), Color(0xFF1B5E20)],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    )
                                  : null,
                              color: isDivActive ? null : Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: isDivActive ? Colors.transparent : Colors.black.withOpacity(0.08),
                              ),
                              boxShadow: isDivActive
                                  ? [
                                      BoxShadow(
                                        color: AppColors.primary.withOpacity(0.3),
                                        blurRadius: 6,
                                        offset: const Offset(0, 2),
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Center(
                              child: Text(
                                div,
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: isDivActive ? FontWeight.bold : FontWeight.w600,
                                  color: isDivActive ? Colors.white : AppColors.textPrimary,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 6),

                  // District List Section Title
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          tempDivision == 'সকল বাজার / সারাদেশ'
                              ? 'সকল জেলা (${displayedDistricts.length}টি)'
                              : '$tempDivision এর জেলাসমূহ (${displayedDistricts.length}টি)',
                          style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        if (tempDistrict.isNotEmpty && tempDistrict != BangladeshLocationData.allDistrictsOption)
                          Text(
                            'নির্বাচিত: $tempDistrict',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2E7D32),
                            ),
                          ),
                      ],
                    ),
                  ),

                  // District Cards (Smooth Bouncing Scroll)
                  Expanded(
                    child: ListView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      children: [
                        // Option for All Districts / Nationwide
                        if (modalSearch.isEmpty && tempDivision == 'সকল বাজার / সারাদেশ')
                          InkWell(
                            onTap: () {
                              setModalState(() {
                                tempDistrict = BangladeshLocationData.allDistrictsOption;
                              });
                            },
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              decoration: BoxDecoration(
                                color: isAllActive ? const Color(0xFFE8F5E9) : Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isAllActive ? const Color(0xFF2E7D32) : Colors.black.withOpacity(0.06),
                                  width: isAllActive ? 1.5 : 1,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.02),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 36,
                                    height: 36,
                                    decoration: BoxDecoration(
                                      color: isAllActive ? const Color(0xFF2E7D32) : const Color(0xFFF1F8E9),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Icon(
                                      Icons.public_rounded,
                                      size: 18,
                                      color: isAllActive ? Colors.white : AppColors.primary,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  const Expanded(
                                    child: Text(
                                      'সারাদেশের সকল বাজার (সকল জেলা)',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                  ),
                                  if (isAllActive)
                                    const Icon(Icons.check_circle_rounded, color: Color(0xFF2E7D32), size: 20),
                                ],
                              ),
                            ),
                          ),

                        if (displayedDistricts.isEmpty)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 40),
                            child: Center(
                              child: Text(
                                'কোনো জেলা খুঁজে পাওয়া যায়নি',
                                style: TextStyle(color: AppColors.textMuted, fontSize: 13),
                              ),
                            ),
                          )
                        else
                          ...displayedDistricts.map((d) {
                            final isCurrent = tempDistrict == d;
                            return InkWell(
                              onTap: () {
                                setModalState(() {
                                  tempDistrict = d;
                                });
                              },
                              borderRadius: BorderRadius.circular(14),
                              child: Container(
                                margin: const EdgeInsets.symmetric(vertical: 4),
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                                decoration: BoxDecoration(
                                  color: isCurrent ? const Color(0xFFE8F5E9) : Colors.white,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: isCurrent ? const Color(0xFF2E7D32) : Colors.black.withOpacity(0.06),
                                    width: isCurrent ? 1.5 : 1,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: isCurrent ? AppColors.primary.withOpacity(0.08) : Colors.black.withOpacity(0.015),
                                      blurRadius: 5,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 32,
                                      height: 32,
                                      decoration: BoxDecoration(
                                        color: isCurrent ? const Color(0xFFC8E6C9) : const Color(0xFFF4F7F4),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Icon(
                                        Icons.location_on_rounded,
                                        size: 17,
                                        color: isCurrent ? const Color(0xFF1B5E20) : const Color(0xFF81C784),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        d,
                                        style: TextStyle(
                                          fontWeight: isCurrent ? FontWeight.bold : FontWeight.w600,
                                          color: isCurrent ? const Color(0xFF1B5E20) : AppColors.textPrimary,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                    if (isCurrent)
                                      Container(
                                        width: 22,
                                        height: 22,
                                        decoration: const BoxDecoration(
                                          color: Color(0xFF2E7D32),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Center(
                                          child: Icon(Icons.check, size: 14, color: Colors.white),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                      ],
                    ),
                  ),

                  // Bottom Action Bar: "ফিল্টার প্রয়োগ করুন" Button
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, -3),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        // Reset button
                        TextButton.icon(
                          onPressed: () {
                            setModalState(() {
                              tempDivision = 'সকল বাজার / সারাদেশ';
                              tempDistrict = BangladeshLocationData.allDistrictsOption;
                              modalSearch = '';
                            });
                          },
                          icon: const Icon(Icons.refresh_rounded, size: 18, color: AppColors.textSecondary),
                          label: const Text(
                            'রিসেট',
                            style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.textSecondary),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Apply button
                        Expanded(
                          child: InkWell(
                            onTap: () {
                              if (tempDistrict.isNotEmpty &&
                                  tempDistrict != BangladeshLocationData.allDistrictsOption &&
                                  tempDistrict != 'সকল বাজার / সারাদেশ') {
                                provider.setDistrict(tempDistrict);
                              } else if (tempDivision != 'সকল বাজার / সারাদেশ' &&
                                  tempDivision != 'সকল বিভাগ') {
                                provider.setDivision(tempDivision);
                              } else {
                                provider.setDistrict(BangladeshLocationData.allDistrictsOption);
                              }
                              Navigator.pop(ctx);
                            },
                            borderRadius: BorderRadius.circular(14),
                            child: Container(
                              height: 46,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFF2E7D32), Color(0xFF1B5E20)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(14),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.primary.withOpacity(0.35),
                                    blurRadius: 8,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: const [
                                  Icon(Icons.check_rounded, color: Colors.white, size: 20),
                                  SizedBox(width: 8),
                                  Text(
                                    'ফিল্টার প্রয়োগ করুন',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 14.5,
                                      fontWeight: FontWeight.bold,
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
                ],
              ),
            );
          },
        );
      },
    );
  }
}
