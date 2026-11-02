import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/bangla_number_converter.dart';
import '../../core/widgets/premium_loading_widget.dart';
import '../../data/models/market_price_model.dart';
import '../../data/services/market_favorites_service.dart';
import 'market_price_detail_screen.dart';
import 'widgets/market_feedback_dialog.dart';

/// পূর্ণাঙ্গ ডেডিকেটেড ফুল-স্ক্রিন স্ক্রলেবল ফেভারিট পেজ (Full Screen Market Favorites Screen)
class MarketFavoritesScreen extends StatefulWidget {
  const MarketFavoritesScreen({super.key});

  @override
  State<MarketFavoritesScreen> createState() => _MarketFavoritesScreenState();
}

class _MarketFavoritesScreenState extends State<MarketFavoritesScreen> {
  @override
  void initState() {
    super.initState();
    MarketFavoritesService.init();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF7),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFE8F5E9), // শীর্ষে হালকা সতেজ গ্রিন
              Color(0xFFF3F8F3), // মসৃণ ট্রাঞ্জিশন
              Color(0xFFF8FAF7), // নিচে ক্লিন অফ-হোয়াইট ব্যাকগ্রাউন্ড
            ],
            stops: [0.0, 0.22, 0.65],
          ),
        ),
        child: SafeArea(
          bottom: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ১. শীর্ষে হেডার, ব্যাক বাটন ও অ্যাপের অফিসিয়াল ব্র্যান্ডিং
              _buildHeader(context),

              // ২. ফেভারিট ফসলের রিয়েল-টাইম স্ক্রলেবল ভিউ (Firestore StreamBuilder)
              Expanded(
                child: ValueListenableBuilder<List<String>>(
                  valueListenable: MarketFavoritesService.favoriteIdsNotifier,
                  builder: (context, favIds, _) {
                    // খালি স্টেট (Empty State): কোনো ফেভারিট না থাকলে তাৎক্ষণিক প্রদর্শন
                    if (favIds.isEmpty) {
                      return _buildEmptyState(context);
                    }

                    return StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance.collection('market_prices').snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
                          return const Center(
                            child: PremiumLoadingWidget(
                              topic: 'পছন্দের বাজার দর',
                              subtitle: 'তথ্য লোড হচ্ছে...',
                            ),
                          );
                        }

                        if (snapshot.hasError && !snapshot.hasData) {
                          return Center(
                            child: Padding(
                              padding: const EdgeInsets.all(24.0),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.wifi_off_rounded, size: 48, color: Color(0xFFC62828)),
                                  const SizedBox(height: 12),
                                  const Text(
                                    'ডেটা লোড করতে সমস্যা হয়েছে',
                                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E281F)),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    snapshot.error.toString(),
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(fontSize: 12, color: Color(0xFF758577)),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }

                        final docs = snapshot.data?.docs ?? [];
                        final List<MarketPriceModel> allPrices = docs
                            .map((doc) => MarketPriceModel.fromFirestore(doc))
                            .toList();

                        // স্ট্রিক্ট আইডি ম্যাচিং ফিল্টার
                        final List<MarketPriceModel> favoriteItems = allPrices
                            .where((item) => favIds.contains(item.id.trim()))
                            .toList();

                        if (favoriteItems.isEmpty) {
                          return _buildEmptyState(context);
                        }

                        // পূর্ণাঙ্গ স্ক্রলেবল তালিকা (ListView.builder)
                        return ListView.builder(
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
                          itemCount: favoriteItems.length,
                          itemBuilder: (context, index) {
                            final item = favoriteItems[index];
                            return _buildFavoriteCard(context, item);
                          },
                        );
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

  // ১. শীর্ষে হেডার ও ব্র্যান্ডিং উইজেট
  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.92),
        border: Border(
          bottom: BorderSide(
            color: Colors.black.withOpacity(0.05),
            width: 1,
          ),
        ),
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
          // টপ বার: ব্যাক বাটন, অফিসিয়াল লোগো ও ফেভারিট কাউন্টার
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  // ব্যাক বাটন
                  InkWell(
                    onTap: () => Navigator.of(context).pop(),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.black.withOpacity(0.06)),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.arrow_back_ios_new_rounded,
                          size: 18,
                          color: Color(0xFF1E281F),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // অ্যাপ অফিসিয়াল আসল লোগো
                  Image.asset(
                    'assets/icons/pnglogo.png',
                    height: 40,
                    width: 40,
                    fit: BoxFit.contain,
                  ),
                ],
              ),

              // ফেভারিট কাউন্ট ব্যাজ
              ValueListenableBuilder<List<String>>(
                valueListenable: MarketFavoritesService.favoriteIdsNotifier,
                builder: (context, favIds, _) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFEBEE),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFFFCDD2)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.favorite_rounded, color: Color(0xFFE53935), size: 14),
                        const SizedBox(width: 5),
                        Text(
                          '${BanglaNumberConverter.toBangla(favIds.length)} টি ফসল',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFFC62828),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 14),

          // বড় মার্জিত বোল্ড হেডলাইন ও সাব-টাইটেল (কোনো টেকনিক্যাল স্টোরেজ পরিচয় নেই)
          const Text(
            'আপনার ফেভারিট করা ফসলের বাজার দর',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: Color(0xFF1E281F),
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 3),
          const Text(
            'প্রয়োজনে দ্রুত দেখার জন্য আপনার সংরক্ষিত ফসলের তালিকা',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Color(0xFF556B2F),
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }

  // ২. প্রিমিয়াম ফেভারিট কার্ড উইজেট
  Widget _buildFavoriteCard(BuildContext context, MarketPriceModel item) {
    final String cleanPrice = item.price > 0
        ? (item.price % 1 == 0 ? item.price.toInt().toString() : item.price.toString())
        : (item.priceText.isNotEmpty && item.priceText != '0' ? item.priceText : '০');

    final String cleanRetail = item.retailPrice > 0
        ? (item.retailPrice % 1 == 0 ? item.retailPrice.toInt().toString() : item.retailPrice.toString())
        : (item.retailPriceText.isNotEmpty && item.retailPriceText != '0' ? item.retailPriceText : '০');

    final String unit = item.unit.isNotEmpty ? item.unit : 'কেজি';
    final String location = item.district.isNotEmpty
        ? '${item.marketName}, ${item.district}'
        : item.marketName;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.black.withOpacity(0.06), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          // যেকোনো কার্ডে ট্যাপ করলে সরাসরি তার বিস্তারিত পেজে নিয়ে যাবে
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => MarketPriceDetailScreen(item: item),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // ফসলের ছবি
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    width: 72,
                    height: 72,
                    color: const Color(0xFFF1F8F1),
                    child: item.imageUrl.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: item.imageUrl,
                            fit: BoxFit.cover,
                            placeholder: (_, __) => const Center(
                              child: SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Color(0xFF2E7D32),
                                ),
                              ),
                            ),
                            errorWidget: (_, __, ___) => const Center(
                              child: Icon(Icons.eco_rounded, color: Color(0xFF2E7D32), size: 30),
                            ),
                          )
                        : const Center(
                            child: Icon(Icons.eco_rounded, color: Color(0xFF2E7D32), size: 30),
                          ),
                  ),
                ),
                const SizedBox(width: 12),

                // ফসলের বিবরণ ও দর
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ফসলের নাম
                      Text(
                        item.cropName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1E281F),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),

                      // বাজার ও জেলা
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on_rounded,
                            size: 13,
                            color: Color(0xFF2E7D32),
                          ),
                          const SizedBox(width: 3),
                          Expanded(
                            child: Text(
                              location,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF556B2F),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),

                      // পাইকারি ও খুচরা দর
                      Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 8,
                        children: [
                          // পাইকারি দর
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE8F5E9),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: RichText(
                              text: TextSpan(
                                style: const TextStyle(fontFamily: 'HindSiliguri'),
                                children: [
                                  const TextSpan(
                                    text: 'পাইকারি: ',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF1B5E20),
                                    ),
                                  ),
                                  TextSpan(
                                    text: '৳${BanglaNumberConverter.toBangla(cleanPrice)}',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w900,
                                      color: Color(0xFF1B5E20),
                                    ),
                                  ),
                                  TextSpan(
                                    text: '/$unit',
                                    style: const TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF2E7D32),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          // খুচরা দর (যদি থাকে)
                          if (cleanRetail.isNotEmpty && cleanRetail != '০')
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: RichText(
                                text: TextSpan(
                                  style: const TextStyle(fontFamily: 'HindSiliguri'),
                                  children: [
                                    const TextSpan(
                                      text: 'খুচরা: ',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF475569),
                                      ),
                                    ),
                                    TextSpan(
                                      text: '৳${BanglaNumberConverter.toBangla(cleanRetail)}',
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w800,
                                        color: Color(0xFF1E293B),
                                      ),
                                    ),
                                    TextSpan(
                                      text: '/$unit',
                                      style: const TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF64748B),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 8),

                // সরাসরি "মুছুন / রিমুভ (Trash)" আইকন বাটন
                InkWell(
                  onTap: () async {
                    await MarketFavoritesService.removeFavorite(item.id);
                    if (context.mounted) {
                      MarketFeedbackDialog.show(
                        context,
                        isAdded: false,
                        customMessage: 'পছন্দের তালিকা থেকে সরানো হয়েছে!',
                      );
                    }
                  },
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFEBEE),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFFFCDD2)),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.delete_outline_rounded,
                        color: Color(0xFFE53935),
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ৩. এম্পটি স্টেট উইজেট (পছন্দের তালিকায় কোনো ফসল না থাকলে)
  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 36),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // লাভ / মার্কেট আইকন
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFFFEBEE),
                border: Border.all(color: const Color(0xFFFFCDD2), width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFE53935).withOpacity(0.12),
                    blurRadius: 18,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: const Center(
                child: Icon(
                  Icons.favorite_border_rounded,
                  size: 44,
                  color: Color(0xFFE53935),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // টেক্সট বার্তা
            const Text(
              'আপনার পছন্দের তালিকায় কোনো ফসল যুক্ত নেই',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1E281F),
                letterSpacing: -0.2,
              ),
            ),
            const SizedBox(height: 8),

            const Text(
              'বাজার দর পেজ থেকে আপনার প্রয়োজনীয় যেকোনো ফসলের পাশের হার্ট আইকনে চাপ দিয়ে এখানে সংরক্ষণ করতে পারেন।',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Color(0xFF758577),
                height: 1.45,
              ),
            ),
            const SizedBox(height: 24),

            // বাটন: বাজার দর দেখুন
            ElevatedButton.icon(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.storefront_rounded, size: 18, color: Colors.white),
              label: const Text(
                'বাজার দর দেখুন',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2E7D32),
                padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                elevation: 3,
                shadowColor: const Color(0xFF2E7D32).withOpacity(0.3),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

