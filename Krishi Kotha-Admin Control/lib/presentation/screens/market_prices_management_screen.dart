import 'package:flutter/material.dart';
import '../../core/constants/admin_colors.dart';
import '../../core/constants/bangladesh_locations.dart';
import '../../core/responsive/responsive_layout.dart';
import '../../core/utils/admin_error_handler.dart';
import '../../data/models/admin_models.dart';
import '../../data/services/admin_firestore_service.dart';

class MarketPricesManagementScreen extends StatefulWidget {
  const MarketPricesManagementScreen({super.key});

  @override
  State<MarketPricesManagementScreen> createState() => _MarketPricesManagementScreenState();
}

class _MarketPricesManagementScreenState extends State<MarketPricesManagementScreen> {
  String _selectedDivision = 'সকল বিভাগ';
  String _selectedDistrict = 'সারাদেশ / সকল জেলা';
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _resetFilters() {
    setState(() {
      _selectedDivision = 'সকল বিভাগ';
      _selectedDistrict = 'সারাদেশ / সকল জেলা';
      _searchCtrl.clear();
    });
  }

  void _openPriceModal({AdminMarketPriceModel? existingItem}) {
    showDialog(
      context: context,
      builder: (context) => _PriceEditorDialog(existingItem: existingItem),
    );
  }

  Future<void> _confirmDelete(String id, String cropName, String marketName) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('পণ্যটি মুছে ফেলতে চান?'),
        content: Text('$marketName-এর "$cropName" দর তথ্যটি কি মুছে ফেলবেন?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('বাতিল')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AdminColors.alertCritical),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('মুছে ফেলুন', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await AdminFirestoreService.instance.deleteMarketPrice(id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('বাজার দর তথ্য সফলভাবে মুছে ফেলা হয়েছে।'), backgroundColor: AdminColors.primary),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AdminErrorHandler.getFriendlyErrorMessage(e)),
              backgroundColor: AdminColors.alertCritical,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      }
    }
  }

  String _formatBanglaFullDateTime(DateTime date) {
    const bnDigits = ['০', '১', '২', '৩', '৪', '৫', '৬', '৭', '৮', '৯'];
    String toBn(int num) => num.toString().split('').map((ch) {
      final idx = int.tryParse(ch);
      return idx != null ? bnDigits[idx] : ch;
    }).join();

    final day = toBn(date.day);
    final year = toBn(date.year);
    const monthsBn = [
      'জানুয়ারি', 'ফেব্রুয়ারি', 'মার্চ', 'এপ্রিল', 'মে', 'জুন',
      'জুলাই', 'আগস্ট', 'সেপ্টেম্বর', 'অক্টোবর', 'নভেম্বর', 'ডিসেম্বর'
    ];
    final month = monthsBn[date.month - 1];

    final hour24 = date.hour;
    String period = 'রাত';
    if (hour24 >= 5 && hour24 < 12) {
      period = 'সকাল';
    } else if (hour24 >= 12 && hour24 < 15) {
      period = 'দুপুর';
    } else if (hour24 >= 15 && hour24 < 18) {
      period = 'বিকাল';
    } else if (hour24 >= 18 && hour24 < 20) {
      period = 'সন্ধ্যা';
    } else {
      period = 'রাত';
    }

    var hour12 = hour24 % 12;
    if (hour12 == 0) hour12 = 12;
    final hourBn = toBn(hour12);
    final minBn = toBn(date.minute).padLeft(2, '০');

    return '$day $month $year, $period $hourBn:$minBn';
  }

  void _showPriceDetailDialog(BuildContext context, AdminMarketPriceModel item) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20),
        title: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: AdminColors.primaryContainer,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.storefront_rounded, color: AdminColors.primary, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.cropName,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AdminColors.textPrimary),
                  ),
                  Text(
                    '${item.marketName}, জেলা: ${item.district}',
                    style: const TextStyle(fontSize: 12, color: AdminColors.textMuted),
                  ),
                ],
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: 440,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 10),
                if (item.imageUrl.isNotEmpty)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      height: 180,
                      width: double.infinity,
                      color: AdminColors.background,
                      alignment: Alignment.center,
                      child: Image.network(
                        item.imageUrl,
                        height: 180,
                        width: double.infinity,
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => Container(
                          height: 120,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          alignment: Alignment.center,
                          child: const Icon(Icons.eco_rounded, color: AdminColors.primary, size: 48),
                        ),
                      ),
                    ),
                  )
                else
                  Container(
                    height: 120,
                    decoration: BoxDecoration(
                      color: AdminColors.primaryContainer.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    alignment: Alignment.center,
                    child: const Icon(Icons.eco_rounded, color: AdminColors.primary, size: 54),
                  ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F5E9),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFA5D6A7), width: 1.5),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AdminColors.primary.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text('পাইকারি দর (Wholesale)', style: TextStyle(fontSize: 10, color: AdminColors.primaryDark, fontWeight: FontWeight.bold)),
                            ),
                            const SizedBox(height: 6),
                            Text('৳${item.price.toStringAsFixed(0)}/${item.unit}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AdminColors.primaryDark)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE3F2FD),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFF90CAF9), width: 1.5),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1976D2).withOpacity(0.12),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text('খুচরা দর (Retail)', style: TextStyle(fontSize: 10, color: Color(0xFF0D47A1), fontWeight: FontWeight.bold)),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              item.retailPrice > 0 ? '৳${item.retailPrice.toStringAsFixed(0)}/${item.unit}' : 'তথ্য নেই',
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0D47A1)),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AdminColors.background,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AdminColors.border),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('বাজারের অবস্থান:', style: TextStyle(fontSize: 13, color: AdminColors.textMuted)),
                          Text('${item.marketName}, ${item.district}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                        ],
                      ),
                      const Divider(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('দরের প্রবণতা (Trend):', style: TextStyle(fontSize: 13, color: AdminColors.textMuted)),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: item.trend == 'up'
                                  ? const Color(0xFFE8F5E9)
                                  : (item.trend == 'down' ? const Color(0xFFFFEBEE) : const Color(0xFFF5F5F5)),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: item.trend == 'up'
                                    ? const Color(0xFFA5D6A7)
                                    : (item.trend == 'down' ? const Color(0xFFFFCDD2) : const Color(0xFFE0E0E0)),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  item.trend == 'up'
                                      ? Icons.arrow_upward_rounded
                                      : (item.trend == 'down' ? Icons.arrow_downward_rounded : Icons.remove_rounded),
                                  size: 15,
                                  color: item.trend == 'up'
                                      ? const Color(0xFF2E7D32)
                                      : (item.trend == 'down' ? const Color(0xFFD32F2F) : const Color(0xFF616161)),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  item.trend == 'up' ? 'উর্ধ্বমুখী' : (item.trend == 'down' ? 'নিম্নমুখী' : 'স্থিতিশীল'),
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: item.trend == 'up'
                                        ? const Color(0xFF2E7D32)
                                        : (item.trend == 'down' ? const Color(0xFFD32F2F) : const Color(0xFF616161)),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('সর্বশেষ আপডেট:', style: TextStyle(fontSize: 13, color: AdminColors.textMuted)),
                          Text(
                            _formatBanglaFullDateTime(item.updatedAt),
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AdminColors.textPrimary),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('বন্ধ করুন'),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: AdminColors.primary),
            onPressed: () {
              Navigator.pop(ctx);
              _openPriceModal(existingItem: item);
            },
            icon: const Icon(Icons.edit_rounded, size: 15, color: Colors.white),
            label: const Text('সম্পাদনা', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'বাজার দর আপডেট ও মনিটরিং',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: AdminColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'সারাদেশের ৬৪ জেলার বিভিন্ন হাট-বাজারের কৃষিপণ্যের পাইকারি ও খুচরা দর ইনপুট ও আপডেট করুন।',
                    style: TextStyle(fontSize: 13, color: AdminColors.textMuted),
                  ),
                ],
              ),
              ElevatedButton.icon(
                onPressed: () => _openPriceModal(),
                icon: const Icon(Icons.add_rounded, size: 20),
                label: const Text('নতুন দর যোগ করুন'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AdminColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Filters Card: Cascading Division + 64 Districts + Live Search
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AdminColors.border),
              boxShadow: const [
                BoxShadow(color: AdminColors.cardShadow, blurRadius: 4, offset: Offset(0, 2)),
              ],
            ),
            child: Wrap(
              spacing: 16,
              runSpacing: 12,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                // Division Filter
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: AdminColors.background,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AdminColors.border),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.apartment_rounded, color: AdminColors.primary, size: 18),
                      const SizedBox(width: 8),
                      const Text('বিভাগ:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                      const SizedBox(width: 8),
                      DropdownButton<String>(
                        value: _selectedDivision,
                        underline: const SizedBox(),
                        style: const TextStyle(fontSize: 13, color: AdminColors.textPrimary, fontWeight: FontWeight.w500),
                        items: BangladeshLocations.allDivisions
                            .map((div) => DropdownMenuItem(value: div, child: Text(div)))
                            .toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() {
                              _selectedDivision = val;
                              _selectedDistrict = 'সারাদেশ / সকল জেলা';
                            });
                          }
                        },
                      ),
                    ],
                  ),
                ),

                // Cascading District Filter (All 64 districts organized by division)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: AdminColors.background,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AdminColors.border),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.location_on_rounded, color: AdminColors.primary, size: 18),
                      const SizedBox(width: 8),
                      const Text('জেলা:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                      const SizedBox(width: 8),
                      DropdownButton<String>(
                        value: _selectedDistrict,
                        underline: const SizedBox(),
                        style: const TextStyle(fontSize: 13, color: AdminColors.textPrimary, fontWeight: FontWeight.w500),
                        items: BangladeshLocations.getFilterDistricts(_selectedDivision)
                            .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                            .toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _selectedDistrict = val);
                        },
                      ),
                    ],
                  ),
                ),

                // Instant Search Box
                SizedBox(
                  width: 260,
                  height: 42,
                  child: TextField(
                    controller: _searchCtrl,
                    style: const TextStyle(fontSize: 13),
                    decoration: InputDecoration(
                      hintText: 'পণ্য, বাজার বা জেলা দিয়ে খুঁজুন...',
                      hintStyle: const TextStyle(fontSize: 12.5, color: AdminColors.textMuted),
                      prefixIcon: const Icon(Icons.search_rounded, size: 18, color: AdminColors.textMuted),
                      suffixIcon: _searchCtrl.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded, size: 16),
                              onPressed: () {
                                _searchCtrl.clear();
                                setState(() {});
                              },
                            )
                          : null,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AdminColors.border)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AdminColors.border)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AdminColors.primary, width: 1.5)),
                      filled: true,
                      fillColor: AdminColors.background,
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ),

                // Reset Filters Button
                if (_selectedDivision != 'সকল বিভাগ' || _selectedDistrict != 'সারাদেশ / সকল জেলা' || _searchCtrl.text.isNotEmpty)
                  TextButton.icon(
                    onPressed: _resetFilters,
                    icon: const Icon(Icons.refresh_rounded, size: 16, color: AdminColors.alertCritical),
                    label: const Text('রিসেট', style: TextStyle(color: AdminColors.alertCritical, fontSize: 13, fontWeight: FontWeight.w600)),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Real-time StreamBuilder Table
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AdminColors.border),
              boxShadow: const [
                BoxShadow(color: AdminColors.cardShadow, blurRadius: 10, offset: Offset(0, 4)),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'বর্তমান লাইভ বাজার তালিকা (Firestore রিয়েল-টাইম)',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AdminColors.textPrimary,
                      ),
                    ),
                    StreamBuilder<List<AdminMarketPriceModel>>(
                      stream: AdminFirestoreService.instance.getMarketPricesStream(
                        division: _selectedDivision,
                        district: _selectedDistrict,
                        searchQuery: _searchCtrl.text,
                      ),
                      builder: (context, snapshot) {
                        final count = snapshot.data?.length ?? 0;
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AdminColors.secondaryContainer,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'মোট পণ্য: $count',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AdminColors.primaryDark,
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
                const Divider(color: AdminColors.divider, height: 28),

                StreamBuilder<List<AdminMarketPriceModel>>(
                  stream: AdminFirestoreService.instance.getMarketPricesStream(
                    division: _selectedDivision,
                    district: _selectedDistrict,
                    searchQuery: _searchCtrl.text,
                  ),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
                      return const Center(child: Padding(
                        padding: EdgeInsets.all(40),
                        child: CircularProgressIndicator(),
                      ));
                    }

                    final list = snapshot.data ?? [];
                    if (list.isEmpty) {
                      final isFiltered = _selectedDivision != 'সকল বিভাগ' ||
                          _selectedDistrict != 'সারাদেশ / সকল জেলা' ||
                          _searchCtrl.text.trim().isNotEmpty;

                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(40),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(isFiltered ? Icons.search_off_rounded : Icons.storefront_outlined, size: 48, color: AdminColors.textMuted),
                              const SizedBox(height: 12),
                              Text(
                                isFiltered ? 'নির্বাচিত জেলায় কোনো বাজার দর পাওয়া যায়নি।' : 'বর্তমানে কোনো তথ্য নেই',
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AdminColors.textPrimary),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                isFiltered
                                    ? 'অন্য কোনো জেলা বা বিভাগ নির্বাচন করুন অথবা ফিল্টার রিসেট করুন।'
                                    : 'নতুন বাজার দর যোগ করতে উপরের বোতামে ক্লিক করুন।',
                                style: const TextStyle(fontSize: 13, color: AdminColors.textMuted),
                              ),
                              if (isFiltered) ...[
                                const SizedBox(height: 16),
                                OutlinedButton.icon(
                                  onPressed: _resetFilters,
                                  icon: const Icon(Icons.refresh_rounded, size: 16),
                                  label: const Text('সকল ফিল্টার রিসেট করুন'),
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    }

                    return ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: list.length,
                      separatorBuilder: (context, index) => const Divider(color: AdminColors.divider, height: 16),
                      itemBuilder: (context, index) {
                        final item = list[index];
                        return Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AdminColors.background,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AdminColors.border),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: AdminColors.primaryContainer,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: item.imageUrl.isNotEmpty
                                    ? ClipRRect(
                                        borderRadius: BorderRadius.circular(10),
                                        child: Image.network(
                                          item.imageUrl,
                                          width: 44,
                                          height: 44,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) => const Icon(Icons.shopping_bag_rounded, color: AdminColors.primary, size: 22),
                                        ),
                                      )
                                    : const Icon(Icons.shopping_bag_rounded, color: AdminColors.primary, size: 22),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                flex: 3,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.cropName,
                                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${item.marketName}, জেলা: ${item.district}',
                                      style: const TextStyle(fontSize: 12, color: AdminColors.textMuted),
                                    ),
                                  ],
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'পাইকারি: ৳${item.price.toStringAsFixed(0)}/${item.unit}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 14,
                                        color: AdminColors.primaryDark,
                                      ),
                                    ),
                                    if (item.retailPrice > 0)
                                      Text(
                                        'খুচরা: ৳${item.retailPrice.toStringAsFixed(0)}/${item.unit}',
                                        style: const TextStyle(fontSize: 12, color: AdminColors.textSecondary),
                                      ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: item.trend == 'up'
                                      ? AdminColors.alertCriticalBg
                                      : (item.trend == 'down' ? AdminColors.successBg : const Color(0xFFEEEEEE)),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      item.trend == 'up'
                                          ? Icons.trending_up_rounded
                                          : (item.trend == 'down' ? Icons.trending_down_rounded : Icons.trending_flat_rounded),
                                      size: 16,
                                      color: item.trend == 'up'
                                          ? AdminColors.alertCritical
                                          : (item.trend == 'down' ? AdminColors.primary : AdminColors.textMuted),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      item.trend == 'up' ? 'উর্ধ্বমুখী' : (item.trend == 'down' ? 'নিম্নমুখী' : 'স্থিতিশীল'),
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: item.trend == 'up'
                                            ? AdminColors.alertCritical
                                            : (item.trend == 'down' ? AdminColors.primary : AdminColors.textMuted),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              OutlinedButton.icon(
                                onPressed: () => _showPriceDetailDialog(context, item),
                                icon: const Icon(Icons.visibility_outlined, size: 14, color: Color(0xFF0288D1)),
                                label: const Text('বিস্তারিত', style: TextStyle(fontSize: 12, color: Color(0xFF0288D1), fontWeight: FontWeight.w600)),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  side: const BorderSide(color: Color(0xFF0288D1)),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                              ),
                              const SizedBox(width: 8),
                              OutlinedButton.icon(
                                onPressed: () => _openPriceModal(existingItem: item),
                                icon: const Icon(Icons.edit_rounded, size: 14, color: AdminColors.primary),
                                label: const Text('এডিট', style: TextStyle(fontSize: 12, color: AdminColors.primary, fontWeight: FontWeight.w600)),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  side: const BorderSide(color: AdminColors.primary),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                              ),
                              const SizedBox(width: 8),
                              OutlinedButton.icon(
                                onPressed: () => _confirmDelete(item.id, item.cropName, item.marketName),
                                icon: const Icon(Icons.delete_outline_rounded, size: 14, color: AdminColors.alertCritical),
                                label: const Text('ডিলিট', style: TextStyle(fontSize: 12, color: AdminColors.alertCritical, fontWeight: FontWeight.w600)),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  side: const BorderSide(color: AdminColors.alertCritical),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PriceEditorDialog extends StatefulWidget {
  final AdminMarketPriceModel? existingItem;

  const _PriceEditorDialog({this.existingItem});

  @override
  State<_PriceEditorDialog> createState() => _PriceEditorDialogState();
}

class _PriceEditorDialogState extends State<_PriceEditorDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _cropNameCtrl;
  late TextEditingController _marketNameCtrl;
  late TextEditingController _priceCtrl;
  late TextEditingController _retailPriceCtrl;
  late TextEditingController _imageCtrl;
  late String _division;
  late String _district;
  late String _unit;
  late String _trend;
  bool _saving = false;

  final List<String> _units = ['কেজি', 'মণ', 'বস্তা', 'হালি', 'কুড়ি'];

  @override
  void initState() {
    super.initState();
    final item = widget.existingItem;
    _cropNameCtrl = TextEditingController(text: item?.cropName ?? '');
    _marketNameCtrl = TextEditingController(text: item?.marketName ?? '');
    _priceCtrl = TextEditingController(text: item != null ? item.price.toStringAsFixed(0) : '');
    _retailPriceCtrl = TextEditingController(text: item != null ? item.retailPrice.toStringAsFixed(0) : '');
    _imageCtrl = TextEditingController(text: item?.imageUrl ?? '');
    _unit = item?.unit ?? 'কেজি';
    _trend = item?.trend ?? 'stable';

    if (item != null) {
      _district = item.district;
      _division = BangladeshLocations.getDivisionForDistrict(_district);
      final list = BangladeshLocations.divisionDistricts[_division] ?? [];
      if (!list.any((d) => BangladeshLocations.matchDistrict(d, _district))) {
        _district = list.isNotEmpty ? list.first : 'ঢাকা';
      }
    } else {
      _division = 'ঢাকা বিভাগ';
      _district = 'ঢাকা';
    }
  }

  @override
  void dispose() {
    _cropNameCtrl.dispose();
    _marketNameCtrl.dispose();
    _priceCtrl.dispose();
    _retailPriceCtrl.dispose();
    _imageCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    try {
      await AdminFirestoreService.instance.saveMarketPrice(
        id: widget.existingItem?.id,
        district: _district,
        marketName: _marketNameCtrl.text.trim(),
        cropName: _cropNameCtrl.text.trim(),
        unit: _unit,
        price: double.tryParse(_priceCtrl.text) ?? 0.0,
        retailPrice: double.tryParse(_retailPriceCtrl.text) ?? 0.0,
        trend: _trend,
        imageUrl: _imageCtrl.text.trim().isEmpty ? null : _imageCtrl.text.trim(),
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('বাজার দর সফলভাবে সংরক্ষণ করা হয়েছে! মূল মোবাইল অ্যাপে সাথে সাথে সিঙ্ক হয়েছে।'),
            backgroundColor: AdminColors.primary,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AdminErrorHandler.getFriendlyErrorMessage(e)),
            backgroundColor: AdminColors.alertCritical,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existingItem != null;

    return AlertDialog(
      title: Text(isEdit ? 'বাজার দর সম্পাদনা করুন' : 'নতুন বাজার দর যোগ করুন'),
      content: SizedBox(
        width: 520,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: _cropNameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'ফসলের নাম',
                    hintText: 'পণ্যের নাম লিখুন (যেমন: ধান, আলু, পেঁয়াজ)',
                  ),
                  validator: (v) => v == null || v.trim().isEmpty ? 'ফসলের নাম আবশ্যক' : null,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    // Division Selector
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _division,
                        decoration: const InputDecoration(labelText: 'বিভাগ নির্বাচন'),
                        items: BangladeshLocations.divisionDistricts.keys
                            .map((div) => DropdownMenuItem(value: div, child: Text(div)))
                            .toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() {
                              _division = val;
                              _district = BangladeshLocations.divisionDistricts[val]!.first;
                            });
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Cascading 64-District Selector
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _district,
                        decoration: const InputDecoration(labelText: 'জেলা (৬৪ জেলা)'),
                        items: (BangladeshLocations.divisionDistricts[_division] ?? BangladeshLocations.allDistricts)
                            .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                            .toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _district = val);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _marketNameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'বাজার / হাটের নাম',
                    hintText: 'বাজারের নাম লিখুন (যেমন: কাওরান বাজার)',
                  ),
                  validator: (v) => v == null || v.trim().isEmpty ? 'বাজারের নাম আবশ্যক' : null,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _priceCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'পাইকারি দর (টাকা)',
                          hintText: 'বর্তমান পাইকারি দর দিন',
                        ),
                        validator: (v) => v == null || v.trim().isEmpty ? 'দর আবশ্যক' : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _retailPriceCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'খুচরা দর (টাকা)',
                          hintText: 'বর্তমান খুচরা দর দিন',
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _unit,
                        decoration: const InputDecoration(labelText: 'একক'),
                        items: _units.map((u) => DropdownMenuItem(value: u, child: Text(u))).toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _unit = val);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _trend,
                  decoration: const InputDecoration(labelText: 'দরের প্রবণতা'),
                  items: const [
                    DropdownMenuItem(value: 'stable', child: Text('স্থিতিশীল')),
                    DropdownMenuItem(value: 'up', child: Text('উর্ধ্বমুখী')),
                    DropdownMenuItem(value: 'down', child: Text('নিম্নমুখী')),
                  ],
                  onChanged: (val) {
                    if (val != null) setState(() => _trend = val);
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _imageCtrl,
                  decoration: const InputDecoration(
                    labelText: 'ফসলের ছবি (Cloudinary / ইমেজ লিংক)',
                    hintText: 'https://res.cloudinary.com/... বা ছবির সরাসরি লিংক',
                    prefixIcon: Icon(Icons.image_outlined, size: 20),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
                if (_imageCtrl.text.trim().isNotEmpty) ...[
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      _imageCtrl.text.trim(),
                      height: 120,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        height: 60,
                        alignment: Alignment.center,
                        color: Colors.grey.shade100,
                        child: const Text('ছবি লোড করা যায়নি', style: TextStyle(color: AdminColors.textMuted, fontSize: 12)),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('বাতিল')),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: AdminColors.primary),
          onPressed: _saving ? null : _save,
          child: Text(_saving ? 'সংরক্ষণ হচ্ছে...' : 'সংরক্ষণ করুন', style: const TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}
