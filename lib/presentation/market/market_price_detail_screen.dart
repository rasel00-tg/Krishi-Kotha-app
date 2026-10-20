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
    Color trendColor = const Color(0xFF757575);
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
      backgroundColor: const Color(0xFFF8FAF8),
      body: SafeArea(
        child: Column(
          children: [
            // ১. কাস্টম আধুনিক টপবার (Back + Share/Favorite)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  InkWell(
                    onTap: () => Navigator.pop(context),
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.black.withOpacity(0.06)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.03),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: AppColors.textPrimary),
                      ),
                    ),
                  ),
                  const Text(
                    'বাজার দর বিস্তারিত',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
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
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: Colors.black.withOpacity(0.06)),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.03),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Center(
                            child: Icon(Icons.share_outlined, size: 20, color: AppColors.textPrimary),
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
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: Colors.black.withOpacity(0.06)),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.03),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Icon(
                              _isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                              size: 20,
                              color: _isFavorite ? Colors.red : AppColors.textPrimary,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // ২. স্ক্রলযোগ্য কনটেন্ট (বড় ইমেজ, শিরোনাম, মেট্রিক্স ও বিশ্লেষণ)
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // বড় ফ্লোটিং ইমেজ কন্টেইনার
                    Container(
                      width: double.infinity,
                      height: 230,
                      margin: const EdgeInsets.only(top: 8, bottom: 16),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFF1F8E9), Color(0xFFDCEDC8)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.08),
                            blurRadius: 18,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          item.imageUrl.isNotEmpty
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(24),
                                  child: CachedNetworkImage(
                                    imageUrl: item.imageUrl,
                                    width: double.infinity,
                                    height: double.infinity,
                                    fit: BoxFit.cover,
                                    placeholder: (_, __) => const Center(
                                      child: CircularProgressIndicator(color: AppColors.primary),
                                    ),
                                    errorWidget: (_, __, ___) => const Center(
                                      child: Icon(Icons.eco_rounded, size: 80, color: AppColors.primary),
                                    ),
                                  ),
                                )
                              : const Center(
                                  child: Icon(Icons.eco_rounded, size: 88, color: AppColors.primary),
                                ),

                          // লাইভ দর ট্যাগ
                          Positioned(
                            top: 14,
                            left: 14,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.92),
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.06),
                                    blurRadius: 6,
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFF2E7D32),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  const Text(
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
                        ],
                      ),
                    ),

                    // শ্বেতশুভ্র বিস্তারিত কার্ড
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: Colors.black.withOpacity(0.05)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.03),
                            blurRadius: 14,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ফসল নাম ও ট্রেন্ড ব্যাজ
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Text(
                                  item.cropName,
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w900,
                                    color: AppColors.textPrimary,
                                    letterSpacing: -0.3,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: trendBgColor,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(trendIcon, size: 14, color: trendColor),
                                    const SizedBox(width: 4),
                                    Text(
                                      trendText,
                                      style: TextStyle(
                                        fontSize: 12,
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

                          // বাজার ও জেলা লোকেশন
                          Row(
                            children: [
                              const Icon(Icons.location_on_rounded, size: 16, color: AppColors.primary),
                              const SizedBox(width: 5),
                              Expanded(
                                child: Text(
                                  locationText,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: AppColors.textSecondary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 6),

                          // হালনাগাদ সময়
                          Row(
                            children: [
                              const Icon(Icons.access_time_rounded, size: 14, color: AppColors.textMuted),
                              const SizedBox(width: 5),
                              Text(
                                'সর্বশেষ হালনাগাদ: ${BanglaDateFormatter.formatRelative(item.updatedAt)}',
                                style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                              ),
                            ],
                          ),

                          const SizedBox(height: 18),
                          const Divider(height: 1, color: Color(0xFFEEEEEE)),
                          const SizedBox(height: 18),

                          // ৪টি কি-মেট্রিক্স গ্রিড (পাইকারি, খুচরা, বাজার, একক)
                          Row(
                            children: [
                              Expanded(
                                child: _buildMetricTile(
                                  title: 'পাইকারি দর',
                                  value: '$displayPrice / $displayUnit',
                                  color: const Color(0xFF2E7D32),
                                  bgColor: const Color(0xFFF1F8E9),
                                  icon: Icons.storefront_rounded,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildMetricTile(
                                  title: 'খুচরা দর',
                                  value: cleanRetail != '০' ? '$displayRetail / $displayUnit' : 'তথ্য নেই',
                                  color: const Color(0xFFE65100),
                                  bgColor: const Color(0xFFFFF3E0),
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
                                  color: const Color(0xFF1565C0),
                                  bgColor: const Color(0xFFE3F2FD),
                                  icon: Icons.place_rounded,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildMetricTile(
                                  title: 'পরিমাপক একক',
                                  value: '১ $displayUnit',
                                  color: const Color(0xFF6A1B9A),
                                  bgColor: const Color(0xFFF3E5F5),
                                  icon: Icons.scale_rounded,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 22),

                          // বাজার দর বিশ্লেষণ ও নির্দেশিকা
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF9FBF9),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: const Color(0xFFE8F5E9)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: const [
                                    Icon(Icons.insights_rounded, size: 18, color: AppColors.primary),
                                    SizedBox(width: 8),
                                    Text(
                                      'বাজার দর বিশ্লেষণ ও পরামর্শ',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.primaryDark,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  cleanRetail != '০'
                                      ? 'পাইকারি ও খুচরা দরের পার্থক্য প্রায় ${BanglaNumberConverter.toBangla(((item.retailPrice - item.price) > 0 ? (item.retailPrice - item.price).toInt() : 0).toString())} টাকা। স্থানীয় আড়ৎ থেকে সরাসরি ক্রয়ে সাশ্রয় হতে পারে।'
                                      : 'বর্তমানে উক্ত বাজারে পাইকারি আড়ৎ মূল্যের ভিত্তিতে হিসাব প্রস্তুত করা হয়েছে। স্থানীয় সরবরাহের ওপর ভিত্তি করে বাজারদর ওঠানামা করতে পারে।',
                                  style: const TextStyle(
                                    fontSize: 12.5,
                                    height: 1.5,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),

            // ৩. ফিক্সড স্লিক বটম বার (মূল দর + অ্যাকশন বাটন)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
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
                            color: AppColors.textMuted,
                          ),
                        ),
                        const SizedBox(height: 2),
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
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '/ $displayUnit',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
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
          ],
        ),
      ),
    );
  }

  Widget _buildMetricTile({
    required String title,
    required String value,
    required Color color,
    required Color bgColor,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w900,
              color: AppColors.textPrimary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
