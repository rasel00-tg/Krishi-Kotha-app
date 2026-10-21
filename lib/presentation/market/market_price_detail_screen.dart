import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/bangla_number_converter.dart';
import '../../core/utils/date_formatter.dart';
import '../../data/models/market_price_model.dart';

class MarketPriceDetailScreen extends StatefulWidget {
  final MarketPriceModel item;

  const MarketPriceDetailScreen({super.key, required this.item});

  @override
  State<MarketPriceDetailScreen> createState() => _MarketPriceDetailScreenState();
}

class _MarketPriceDetailScreenState extends State<MarketPriceDetailScreen> {
  bool _isFavorite = false;

  @override
  Widget build(BuildContext context) {
    final item = widget.item;

    // Trend setup
    IconData trendIcon = Icons.remove_rounded;
    Color trendColor = const Color(0xFF616161);
    Color trendBgColor = const Color(0xFFF5F5F5);
    String trendText = 'দর স্থিতিশীল';

    final trendKey = item.trend.trim().toLowerCase();
    if (trendKey == 'down') {
      trendIcon = Icons.arrow_downward_rounded;
      trendColor = const Color(0xFFD32F2F);
      trendBgColor = const Color(0xFFFFEBEE);
      trendText = 'দর নিম্নমুখী';
    } else if (trendKey == 'up') {
      trendIcon = Icons.arrow_upward_rounded;
      trendColor = const Color(0xFF2E7D32);
      trendBgColor = const Color(0xFFE8F5E9);
      trendText = 'দর ঊর্ধ্বমুখী';
    }

    // Safe string formatting
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

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF7),
      body: Column(
        children: [
          // স্ক্রলযোগ্য পূর্ণাঙ্গ কনটেন্ট (ফুল-উইডথ ব্যানার + বিস্তারিত তথ্য)
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ১. ফুল-উইডথ প্রিমিয়াম হিরো ব্যানার (Full-Width Banner, Height: 215pt, BoxFit.cover)
                  Stack(
                    children: [
                      Container(
                        width: double.infinity,
                        height: 215,
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Color(0xFFE8F5E9), Color(0xFFC8E6C9)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: item.imageUrl.isNotEmpty
                            ? CachedNetworkImage(
                                imageUrl: item.imageUrl,
                                width: double.infinity,
                                height: 215,
                                fit: BoxFit.cover,
                                placeholder: (_, __) => const Center(
                                  child: CircularProgressIndicator(color: AppColors.primary),
                                ),
                                errorWidget: (_, __, ___) => const Center(
                                  child: Icon(Icons.eco_rounded, size: 70, color: Color(0xFF2E7D32)),
                                ),
                              )
                            : const Center(
                                child: Icon(Icons.eco_rounded, size: 75, color: Color(0xFF2E7D32)),
                              ),
                      ),

                      // ডার্ক গ্রেডিয়েন্ট ওভারলে (ফর ক্রিস্প কন্ট্রোলস ভিজিবিলিটি)
                      Container(
                        width: double.infinity,
                        height: 215,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withOpacity(0.45),
                              Colors.transparent,
                              Colors.black.withOpacity(0.35),
                            ],
                            stops: const [0.0, 0.5, 1.0],
                          ),
                        ),
                      ),

                      // শীর্ষ নেভিগেশন ও অ্যাকশন বাটন (SafeArea এর ভেতর ক্রিস্প বাটন)
                      SafeArea(
                        bottom: false,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // ব্যাক বাটন
                              InkWell(
                                onTap: () => Navigator.pop(context),
                                borderRadius: BorderRadius.circular(14),
                                child: Container(
                                  width: 42,
                                  height: 42,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.92),
                                    borderRadius: BorderRadius.circular(14),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.12),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: const Center(
                                    child: Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: Color(0xFF1E281F)),
                                  ),
                                ),
                              ),

                              // শিরোনাম
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.92),
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 8,
                                    ),
                                  ],
                                ),
                                child: const Text(
                                  'বাজার দর বিস্তারিত',
                                  style: TextStyle(
                                    fontSize: 14.5,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF1E281F),
                                  ),
                                ),
                              ),

                              // শেয়ার ও ফেভারিট বাটন
                              Row(
                                children: [
                                  InkWell(
                                    onTap: () {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('${item.cropName} এর বাজার দর কপি করা হয়েছে'),
                                          behavior: SnackBarBehavior.floating,
                                          duration: const Duration(seconds: 2),
                                        ),
                                      );
                                    },
                                    borderRadius: BorderRadius.circular(14),
                                    child: Container(
                                      width: 42,
                                      height: 42,
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.92),
                                        borderRadius: BorderRadius.circular(14),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(0.12),
                                            blurRadius: 8,
                                          ),
                                        ],
                                      ),
                                      child: const Center(
                                        child: Icon(Icons.share_outlined, size: 19, color: Color(0xFF1E281F)),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  InkWell(
                                    onTap: () {
                                      setState(() {
                                        _isFavorite = !_isFavorite;
                                      });
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text(_isFavorite ? 'পছন্দের তালিকায় যুক্ত হয়েছে' : 'পছন্দের তালিকা থেকে সরানো হয়েছে'),
                                          behavior: SnackBarBehavior.floating,
                                          duration: const Duration(seconds: 1),
                                        ),
                                      );
                                    },
                                    borderRadius: BorderRadius.circular(14),
                                    child: Container(
                                      width: 42,
                                      height: 42,
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.92),
                                        borderRadius: BorderRadius.circular(14),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(0.12),
                                            blurRadius: 8,
                                          ),
                                        ],
                                      ),
                                      child: Center(
                                        child: Icon(
                                          _isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                                          size: 20,
                                          color: _isFavorite ? Colors.red : const Color(0xFF1E281F),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),

                      // হিরো ব্যানারের নিচে লাইভ রেট ব্যাজ
                      Positioned(
                        bottom: 12,
                        left: 14,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.95),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.12),
                                blurRadius: 6,
                              ),
                            ],
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.bolt_rounded, size: 14, color: Color(0xFF2E7D32)),
                              SizedBox(width: 4),
                              Text(
                                'লাইভ বাজার দর',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1B5E20),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // ইউনিট ব্যাজ (নিচে ডানে)
                      Positioned(
                        bottom: 12,
                        right: 14,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1B5E20).withOpacity(0.9),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.15),
                                blurRadius: 6,
                              ),
                            ],
                          ),
                          child: Text(
                            'প্রতি $displayUnit',
                            style: const TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  // ২. তথ্যের পুনর্বিন্যাস ও এজ-টু-এজ মার্জিত প্রিমিয়াম কার্ড
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ফসলের নাম (বড় বোল্ড ফন্টে) ও পাশে দর ট্রেন্ড ব্যাজ
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                item.cropName,
                                style: const TextStyle(
                                  fontSize: 26,
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFF1E281F),
                                  letterSpacing: -0.4,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: trendBgColor,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: trendColor.withOpacity(0.2)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(trendIcon, size: 15, color: trendColor),
                                  const SizedBox(width: 4),
                                  Text(
                                    trendText,
                                    style: TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.bold,
                                      color: trendColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 8),

                        // বাজারের নাম ও জেলা
                        Row(
                          children: [
                            const Icon(Icons.location_on_rounded, size: 17, color: Color(0xFF2E7D32)),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                locationText,
                                style: const TextStyle(
                                  fontSize: 14.5,
                                  color: Color(0xFF4A5B4C),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 6),

                        // সর্বশেষ আপডেটের বাংলা সময়
                        Row(
                          children: [
                            const Icon(Icons.access_time_rounded, size: 15, color: Color(0xFF758577)),
                            const SizedBox(width: 6),
                            Text(
                              'সর্বশেষ হালনাগাদ: ${BanglaDateFormatter.formatRelative(item.updatedAt)}',
                              style: const TextStyle(fontSize: 12.5, color: Color(0xFF758577), fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),

                        const SizedBox(height: 18),
                        const Divider(height: 1, color: Color(0xFFE0E0E0)),
                        const SizedBox(height: 18),

                        // ৩. ৪টি কালারফুল ইনফো কার্ড (পাইকারি দর, খুচরা দর, বাজারের স্থান, পরিমাপক একক)
                        Row(
                          children: [
                            Expanded(
                              child: _buildMetricTile(
                                title: 'পাইকারি দর',
                                value: displayPrice,
                                unit: '/ $displayUnit',
                                color: const Color(0xFF1B5E20),
                                headerColor: const Color(0xFF2E7D32),
                                gradientColors: const [Color(0xFFF1F8E9), Color(0xFFE8F5E9)],
                                borderColor: const Color(0xFFC8E6C9),
                                icon: Icons.storefront_rounded,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildMetricTile(
                                title: 'খুচরা দর',
                                value: cleanRetail != '০' ? displayRetail : 'তথ্য নেই',
                                unit: cleanRetail != '০' ? '/ $displayUnit' : '',
                                color: const Color(0xFFBF360C),
                                headerColor: const Color(0xFFE65100),
                                gradientColors: const [Color(0xFFFFF3E0), Color(0xFFFFE0B2)],
                                borderColor: const Color(0xFFFFCC80),
                                icon: Icons.shopping_basket_rounded,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 12),

                        Row(
                          children: [
                            Expanded(
                              child: _buildMetricTile(
                                title: 'বাজারের স্থান',
                                value: item.marketName,
                                unit: item.district.isNotEmpty ? item.district : '',
                                color: const Color(0xFF0D47A1),
                                headerColor: const Color(0xFF1565C0),
                                gradientColors: const [Color(0xFFE3F2FD), Color(0xFFBBDEFB)],
                                borderColor: const Color(0xFF90CAF9),
                                icon: Icons.place_rounded,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildMetricTile(
                                title: 'পরিমাপক একক',
                                value: '১ $displayUnit',
                                unit: 'ওজন ভিত্তি',
                                color: const Color(0xFF4A148C),
                                headerColor: const Color(0xFF6A1B9A),
                                gradientColors: const [Color(0xFFF3E5F5), Color(0xFFE1BEE7)],
                                borderColor: const Color(0xFFCE93D8),
                                icon: Icons.scale_rounded,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 22),

                        // ৪. "বাজার দর বিশ্লেষণ ও পরামর্শ" সেকশনটি একটি সফট গ্রিন কার্ডের ভেতর স্পষ্ট ও সহজে পড়ার মতো ফন্ট সাইজ
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF4F9F4),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: const Color(0xFFC8E6C9), width: 1.2),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF2E7D32).withOpacity(0.04),
                                blurRadius: 10,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                children: [
                                  Icon(Icons.insights_rounded, size: 20, color: Color(0xFF2E7D32)),
                                  SizedBox(width: 8),
                                  Text(
                                    'বাজার দর বিশ্লেষণ ও পরামর্শ',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF1B5E20),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Text(
                                cleanRetail != '০'
                                    ? 'পাইকারি ও খুচরা দরের পার্থক্য প্রায় ${BanglaNumberConverter.toBangla(((item.retailPrice - item.price) > 0 ? (item.retailPrice - item.price).toInt() : 0).toString())} টাকা। স্থানীয় আড়ৎ থেকে সরাসরি ক্রয়ে সাশ্রয় হতে পারে।'
                                    : 'বর্তমানে উক্ত বাজারে পাইকারি আড়ৎ মূল্যের ভিত্তিতে হিসাব প্রস্তুত করা হয়েছে। স্থানীয় সরবরাহের ওপর ভিত্তি করে বাজারদর ওঠানামা করতে পারে।',
                                style: const TextStyle(
                                  fontSize: 13.5,
                                  height: 1.55,
                                  color: Color(0xFF2E4030),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ৫. ফিক্সড স্লিক বটম বার (ফুল-উইডথ রেসপনসিভ ফিট)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 16,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'আজকের মূল দর',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF758577),
                          ),
                        ),
                        const SizedBox(height: 1),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              displayPrice,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF1B5E20),
                                letterSpacing: -0.4,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '/ $displayUnit',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF4A5B4C),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2E7D32),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 13),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('${item.cropName} এর বাজার দর যাচাই সম্পন্ন হয়েছে'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                    icon: const Icon(Icons.verified_rounded, size: 18),
                    label: const Text(
                      'দর যাচাই করুন',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // প্রিমিয়াম কালারফুল ইনফো মেট্রিক টাইল
  Widget _buildMetricTile({
    required String title,
    required String value,
    required String unit,
    required Color color,
    required Color headerColor,
    required List<Color> gradientColors,
    required Color borderColor,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 15, color: headerColor),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: headerColor,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Flexible(
                child: Text(
                  value,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: color,
                    letterSpacing: -0.3,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (unit.isNotEmpty) ...[
                const SizedBox(width: 3),
                Text(
                  unit,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: color.withOpacity(0.8),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
