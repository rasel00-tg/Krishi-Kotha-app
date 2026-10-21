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

    // ডিফল্ট ফিল্টার বাউন্ডারি বাইপাস: ইউজার নির্দিষ্ট জেলা বা বিভাগ সিলেক্ট না করলে কোনো ফিল্টারিং হবে না
    final bool isDistrictFiltered = marketProvider.selectedDistrict.trim().isNotEmpty &&
        marketProvider.selectedDistrict.trim() != 'সারাদেশ' &&
        marketProvider.selectedDistrict.trim() != 'সকল বাজার / সারাদেশ' &&
        marketProvider.selectedDistrict.trim() != 'সকল জেলা / সারাদেশ' &&
        marketProvider.selectedDistrict.trim() != 'সকল জেলা' &&
        marketProvider.selectedDistrict.trim() != 'সব জেলা' &&
        marketProvider.selectedDistrict.trim() != 'all' &&
        marketProvider.selectedDistrict.trim() != BangladeshLocationData.allDistrictsOption;

    final bool isDivisionFiltered = marketProvider.selectedDivision.trim().isNotEmpty &&
        marketProvider.selectedDivision.trim() != 'সকল বাজার / সারাদেশ' &&
        marketProvider.selectedDivision.trim() != 'সকল জেলা / সারাদেশ' &&
        marketProvider.selectedDivision.trim() != 'সকল বিভাগ' &&
        marketProvider.selectedDivision.trim() != 'সারাদেশ' &&
        marketProvider.selectedDivision.trim() != 'all';

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: null, // টপবার অপসারণ: ফুল-স্ক্রিন আধুনিক ডেলিভারি অ্যাপ লুক
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFE8F5E9), // শীর্ষে হালকা রিফ্রেশিং গ্রিন
              Color(0xFFF1F8F1), // মসৃণ ট্রাঞ্জিশন
              Color(0xFFF8FAF7), // নিচের দিকে ক্রমান্বয়ে মসৃণ অফ-হোয়াইট বা সফট লাইট
            ],
            stops: [0.0, 0.28, 0.65],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              // ১. আধুনিক ফুল-স্ক্রিন হেডার (স্লিক লোকেশন, সার্চ বার, ফিল্টার ও ফিচার ব্যানার)
              _buildModernHeader(context, marketProvider),

            // ২. রিয়েল-টাইম লাইভ বাজার দর গ্রিড (Firestore StreamBuilder)
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('market_prices').snapshots(),
                builder: (context, snapshot) {
                  // ১. যদি ডেটা লোড হতে থাকে (ConnectionState.waiting), পেজের সেন্টারে রঙিন লোডিং পপ-আপ প্রদর্শন
                  if ((snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) ||
                      (!snapshot.hasData && !snapshot.hasError)) {
                    return const Center(
                      child: PremiumLoadingWidget(
                        topic: 'বাজার দর',
                        subtitle: 'অনুগ্রহ করে কিছুক্ষণ অপেক্ষা করুন',
                      ),
                    );
                  }

                  // ২. ফায়ারস্টোর এরর আনমাস্কিং: সাইলেন্ট ট্র্যাপ বন্ধ করে লাল বক্সে আসল ত্রুটি প্রদর্শন
                  if (snapshot.hasError && !snapshot.hasData) {
                    final errString = snapshot.error.toString();
                    final isPermissionDenied = errString.toLowerCase().contains('permission') ||
                        errString.toLowerCase().contains('denied');
                    return Center(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
                        child: Container(
                          padding: const EdgeInsets.all(18.0),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFEBEE),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: const Color(0xFFEF5350), width: 1.5),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFEF5350).withOpacity(0.12),
                                blurRadius: 16,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 52,
                                height: 52,
                                decoration: const BoxDecoration(
                                  color: Color(0xFFFFCDD2),
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Icon(
                                    isPermissionDenied ? Icons.lock_outline_rounded : Icons.error_outline_rounded,
                                    color: const Color(0xFFC62828),
                                    size: 30,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                isPermissionDenied
                                    ? 'ফায়ারস্টোর পারমিশন এরর (Permission Denied)'
                                    : 'ফায়ারস্টোর সংযোগ ত্রুটি (Firestore Error)',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Color(0xFFC62828),
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: const Color(0xFFFFCDD2)),
                                ),
                                child: Text(
                                  errString,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: Color(0xFFB71C1C),
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                isPermissionDenied
                                    ? 'পরামর্শ: ফায়ারবেস কনসোলের Cloud Firestore > Rules ট্যাবে গিয়ে "allow read, write: if true;" রুলস পেস্ট করে Publish করুন।'
                                    : 'পরামর্শ: ইন্টারনেট সংযোগ বা ফায়ারবেস রুলস সক্রিয় আছে কিনা নিশ্চিত করুন।',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Color(0xFF7F0000),
                                  fontSize: 12,
                                  height: 1.35,
                                ),
                              ),
                              const SizedBox(height: 14),
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFC62828),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                                ),
                                onPressed: () {
                                  marketProvider.resetFilters();
                                  _searchController.clear();
                                },
                                icon: const Icon(Icons.refresh, size: 18),
                                label: const Text('পুনরায় লোড করুন', style: TextStyle(fontWeight: FontWeight.bold)),
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
                        subtitle: 'বর্তমানে ডেটাবেজে কোনো বাজার দর তালিকাভুক্ত নেই',
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
                      final raw = doc.data();
                      final Map<String, dynamic> data = {};
                      if (raw is Map) {
                        raw.forEach((k, v) {
                          if (k != null) data[k.toString()] = v;
                        });
                      }
                      final String cropName = (data['cropName'] ?? data['crop_name'] ?? data['name'] ?? 'ফসল').toString();
                      final String marketName = (data['marketName'] ?? data['market_name'] ?? data['market'] ?? 'স্থানীয় বাজার').toString();
                      final String district = (data['district']?.toString() ?? data['location']?.toString() ?? '').trim();
                      final String imageUrl = (data['imageUrl'] ?? data['image_url'] ?? data['image'] ?? '').toString();
                      final String unit = (data['unit'] ?? 'কেজি').toString();
                      final String trend = (data['trend'] ?? 'stable').toString();

                      final dynamic rawPrice = data['price'];
                      final dynamic rawRetail = data['retailPrice'] ?? data['retail_price'];
                      final double price = MarketPriceModel.parseDouble(rawPrice);
                      final double retailPrice = MarketPriceModel.parseDouble(rawRetail);
                      final String priceText = rawPrice != null ? rawPrice.toString() : '০';
                      final String retailPriceText = rawRetail != null ? rawRetail.toString() : '০';

                      DateTime updatedAt = DateTime.now();
                      final rawTime = data['updatedAt'] ?? data['updated_at'] ?? data['timestamp'];
                      if (rawTime is Timestamp) {
                        updatedAt = rawTime.toDate();
                      } else if (rawTime is String) {
                        updatedAt = DateTime.tryParse(rawTime) ?? DateTime.now();
                      }

                      allPrices.add(MarketPriceModel(
                        id: doc.id,
                        district: district,
                        marketName: marketName,
                        cropName: cropName,
                        unit: unit,
                        price: price,
                        retailPrice: retailPrice,
                        priceText: priceText,
                        retailPriceText: retailPriceText,
                        imageUrl: imageUrl,
                        trend: trend,
                        updatedAt: updatedAt,
                      ));
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

                  // ৩. আনরেস্ট্রিক্টেড ডিফল্ট ভিউ ও কেবল ইউজার বাছাই করলেই অ্যাপ-লেভেলে ফিল্টারিং
                  if (isDistrictFiltered) {
                    final targetDistrict = marketProvider.selectedDistrict.trim();
                    filteredPrices = filteredPrices.where((m) =>
                        _matchDistrict(m.district, targetDistrict)
                    ).toList();
                  } else if (isDivisionFiltered) {
                    final targetDivision = marketProvider.selectedDivision.trim();
                    final divDistricts = BangladeshLocationData.divisionDistricts[targetDivision] ?? [];
                    filteredPrices = filteredPrices.where((m) =>
                        divDistricts.any((d) => _matchDistrict(m.district, d)) ||
                        _matchDistrict(m.district, targetDivision)
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
                        subtitle: 'অন্য ফসল বা এলাকার নাম খুঁজে দেখতে পারেন',
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
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.68,
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
    ),
  );
}

  // ১. আধুনিক হেডার ও সার্চ অংশ (লোকেশন ট্যাগ, সার্চ বার, ফিল্টার ও ফিচার ব্যানার)
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
    final String locationDisplay = isDistrictFiltered
        ? 'নির্বাচিত বাজার: ${marketProvider.selectedDistrict}'
        : (isDivisionFiltered
            ? 'নির্বাচিত বিভাগ: ${marketProvider.selectedDivision}'
            : 'সারাদেশের বাজার দর');

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // মার্জিত শীর্ষ শিরোনাম: "দৈনিক বাজার দর" এবং সাব-টাইটেল: "সারাদেশের পাইকারি ও খুচরা বাজার দর"
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'দৈনিক বাজার দর',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF1E281F),
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        hasActiveFilter
                            ? locationDisplay
                            : 'সারাদেশের পাইকারি ও খুচরা বাজার দর',
                        style: TextStyle(
                          fontSize: 12.5,
                          color: hasActiveFilter ? const Color(0xFF2E7D32) : const Color(0xFF556B2F),
                          fontWeight: hasActiveFilter ? FontWeight.w700 : FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                if (hasActiveFilter)
                  GestureDetector(
                    onTap: () {
                      marketProvider.resetFilters();
                      _searchController.clear();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFEBEE),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFFFCDD2)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'রিসেট',
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFC62828),
                            ),
                          ),
                          SizedBox(width: 3),
                          Icon(Icons.close_rounded, size: 14, color: Color(0xFFC62828)),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // সাদা ফ্রস্টেড স্লিক সার্চবার ও পাশে ফিল্টার আইকন বাটন
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.black.withOpacity(0.06)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (val) => marketProvider.setSearchQuery(val),
                    style: const TextStyle(fontSize: 14, color: Color(0xFF1E281F)),
                    decoration: InputDecoration(
                      hintText: 'ফসল বা বাজার খুঁজুন...',
                      hintStyle: const TextStyle(fontSize: 13.5, color: Color(0xFF758577)),
                      prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF2E7D32), size: 22),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded, size: 18, color: Color(0xFF758577)),
                              onPressed: () {
                                _searchController.clear();
                                marketProvider.setSearchQuery('');
                              },
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              // ফিল্টার আইকন বাটন
              InkWell(
                onTap: () => _showDistrictFilter(context, marketProvider),
                borderRadius: BorderRadius.circular(16),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF2E7D32), Color(0xFF1B5E20)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF2E7D32).withOpacity(0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Icon(Icons.tune_rounded, size: 22, color: Colors.white),
                      ),
                    ),
                    if (hasActiveFilter)
                      Positioned(
                        top: -3,
                        right: -3,
                        child: Container(
                          width: 13,
                          height: 13,
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

          const SizedBox(height: 12),

          // ২. হাইলাইট অফার/দর ব্যানার (Feature Banner)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF2E7D32), Color(0xFF1B5E20)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF2E7D32).withOpacity(0.22),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.bolt_rounded, color: Color(0xFFFFD54F), size: 12),
                            SizedBox(width: 3),
                            Text(
                              'দৈনিক লাইভ রেট',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 5),
                      const Text(
                        'আজকের তাজা ফসলের বাজার দর জানুন সহজেই!',
                        style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          height: 1.25,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'ন্যায্য মূল্যে কেনাবেচার জন্য নির্ভরযোগ্য রিয়েল-টাইম তথ্য',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.white.withOpacity(0.88),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.18),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white.withOpacity(0.3), width: 1.5),
                  ),
                  child: const Center(
                    child: Icon(Icons.storefront_rounded, color: Colors.white, size: 26),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 6),
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
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => MarketPriceDetailScreen(item: item),
            ),
          );
        },
        borderRadius: BorderRadius.circular(18),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.black.withOpacity(0.06), width: 1),
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
              // ১. কার্ডের শীর্ষে ফসলের ছবি (Natural Aspect Ratio ও BoxFit.cover সহকারে ক্রিস্প ডিসপ্লে)
              Expanded(
                flex: 11,
                child: Container(
                  width: double.infinity,
                  margin: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F8F1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      item.imageUrl.isNotEmpty
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(14),
                              child: CachedNetworkImage(
                                imageUrl: item.imageUrl,
                                width: double.infinity,
                                height: double.infinity,
                                fit: BoxFit.cover,
                                placeholder: (_, __) => const Center(
                                  child: Icon(Icons.eco_rounded, color: Color(0xFF2E7D32), size: 30),
                                ),
                                errorWidget: (_, __, ___) => const Center(
                                  child: Icon(Icons.eco_rounded, color: Color(0xFF2E7D32), size: 30),
                                ),
                              ),
                            )
                          : const Center(
                              child: Icon(Icons.eco_rounded, color: Color(0xFF2E7D32), size: 34),
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
                                color: Colors.black.withOpacity(0.08),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                          child: Icon(trendIcon, size: 12, color: trendColor),
                        ),
                      ),

                      // Unit Pill Badge (Top Right)
                      Positioned(
                        top: 6,
                        right: 6,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.92),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.black.withOpacity(0.06)),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.06),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                          child: Text(
                            displayUnit,
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF2E7D32),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ২. কার্ড কন্টেন্ট
              Expanded(
                flex: 10,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(10, 0, 10, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ফসলের বাংলা নাম (বোল্ড গাঢ় ফন্টে)
                          Text(
                            item.cropName,
                            style: const TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF1E281F),
                              height: 1.15,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          // নিচে বাজারের নাম ও জেলার ছোট ব্যাজ
                          Row(
                            children: [
                              const Icon(Icons.location_on_outlined, size: 11, color: Color(0xFF2E7D32)),
                              const SizedBox(width: 2),
                              Expanded(
                                child: Text(
                                  locationText,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Color(0xFF556B2F),
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

                      // মূল মূল্য হাইলাইট: রেফারেন্সের মতো উজ্জ্বল সবুজ ক্যাপসুল ব্যাজে পাইকারি ও খুচরা দর
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4.5),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F5E9),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFC8E6C9), width: 1),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.baseline,
                                  textBaseline: TextBaseline.alphabetic,
                                  children: [
                                    Text(
                                      displayPrice,
                                      style: const TextStyle(
                                        fontSize: 14.5,
                                        fontWeight: FontWeight.w900,
                                        color: Color(0xFF1B5E20),
                                        letterSpacing: -0.2,
                                      ),
                                    ),
                                    Text(
                                      '/$displayUnit',
                                      style: const TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF2E7D32),
                                      ),
                                    ),
                                  ],
                                ),
                                if (cleanRetail != '০')
                                  Text(
                                    'খুচরা $displayRetail',
                                    style: const TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF388E3C),
                                    ),
                                  ),
                              ],
                            ),
                            Icon(trendIcon, size: 13, color: trendColor),
                          ],
                        ),
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
