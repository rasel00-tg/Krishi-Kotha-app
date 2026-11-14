import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import '../../core/constants/app_colors.dart';
import '../../core/widgets/premium_loading_widget.dart';
import 'crop_details_page.dart';

class CropCalendarScreen extends StatefulWidget {
  final String? initialMonth;

  const CropCalendarScreen({super.key, this.initialMonth});

  @override
  State<CropCalendarScreen> createState() => _CropCalendarScreenState();
}

class _CropCalendarScreenState extends State<CropCalendarScreen> {
  late String _selectedMonth;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  final List<String> _months = [
    'সব মাস',
    'বৈশাখ',
    'জ্যৈষ্ঠ',
    'আষাঢ়',
    'শ্রাবণ',
    'ভাদ্র',
    'আশ্বিন',
    'কার্তিক',
    'অগ্রহায়ণ',
    'পৌষ',
    'মাঘ',
    'ফাল্গুন',
    'চৈত্র',
  ];

  final Map<String, String> _monthEnglishMap = {
    'বৈশাখ': 'এপ্রিল - মে',
    'জ্যৈষ্ঠ': 'মে - জুন',
    'আষাঢ়': 'জুন - জুলাই',
    'শ্রাবণ': 'জুলাই - আগস্ট',
    'ভাদ্র': 'আগস্ট - সেপ্টেম্বর',
    'আশ্বিন': 'সেপ্টেম্বর - অক্টোবর',
    'কার্তিক': 'অক্টোবর - নভেম্বর',
    'অগ্রহায়ণ': 'নভেম্বর - ডিসেম্বর',
    'পৌষ': 'ডিসেম্বর - জানুয়ারি',
    'মাঘ': 'জানুয়ারি - ফেব্রুয়ারি',
    'ফাল্গুন': 'ফেব্রুয়ারি - মার্চ',
    'চৈত্র': 'মার্চ - এপ্রিল',
  };

  @override
  void initState() {
    super.initState();
    _selectedMonth = widget.initialMonth ?? 'সব মাস';
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
              'ফসল চাষ ক্যালেন্ডার',
              style: TextStyle(
                color: Colors.white,
                fontSize: 17.5,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'মাসভিত্তিক ফসল রোপণ ও পরিচর্যার সময়সূচি',
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
            // ১. কালারিং টপবার (Colored Top Bar with Month Filters & Search)
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
                        hintText: 'ফসলের নাম বা মৌসুম খুঁজুন...',
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

                  // মাসভিত্তিক অনুভূমিক ফিল্টার চিপস (আকর্ষণীয় আইকন ও কালারিং স্টেট)
                  SizedBox(
                    height: 38,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _months.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (context, index) {
                        final month = _months[index];
                        final isSelected = _selectedMonth == month;

                        return InkWell(
                          borderRadius: BorderRadius.circular(20),
                          onTap: () {
                            setState(() => _selectedMonth = month);
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
                                  month == 'সব মাস'
                                      ? Icons.grid_view_rounded
                                      : Icons.calendar_today_rounded,
                                  size: 13,
                                  color: isSelected ? const Color(0xFF1B5E20) : Colors.white,
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  month,
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
            ),

            // ২. নির্বাচিত মাসের অতিরিক্ত ব্যানার তথ্য (যদি কোনো নির্দিষ্ট মাস সিলেক্ট থাকে)
            if (_selectedMonth != 'সব মাস' && _monthEnglishMap.containsKey(_selectedMonth))
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
                      child: const Icon(Icons.calendar_month_rounded, color: Colors.white, size: 18),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '$_selectedMonth মাস (${_monthEnglishMap[_selectedMonth]})',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1B5E20),
                            ),
                          ),
                          const Text(
                            'এই মাসের উপযুক্ত ফসল ও পরিচর্যার পরামর্শ নিচে প্রদর্শিত হচ্ছে',
                            style: TextStyle(fontSize: 11, color: Color(0xFF2E7D32)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

            // ৪. রিয়েল-টাইম ফায়ারস্টোর StreamBuilder দিয়ে ফসলের তালিকা
            Expanded(
              child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: FirebaseFirestore.instance.collection('farming_calendar').snapshots(),
                builder: (context, snapshot) {
                  if ((snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) ||
                      (!snapshot.hasData && !snapshot.hasError)) {
                    return const Center(
                      child: PremiumLoadingWidget(
                        topic: 'চাষ ক্যালেন্ডার',
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

                  final allDocs = snapshot.data?.docs ?? [];
                  var items = allDocs.map((doc) {
                    final data = Map<String, dynamic>.from(doc.data());
                    data['id'] = doc.id;
                    return data;
                  }).toList();

                  // ফিল্টারিং: মাসভিত্তিক
                  if (_selectedMonth != 'সব মাস') {
                    items = items.where((item) {
                      final m = item['month']?.toString() ?? '';
                      return m.contains(_selectedMonth);
                    }).toList();
                  }

                  // ফিল্টারিং: সার্চ কোয়েরি
                  if (_searchQuery.isNotEmpty) {
                    final q = _searchQuery.toLowerCase();
                    items = items.where((item) {
                      final name = (item['cropName']?.toString() ?? '').toLowerCase();
                      final season = (item['season']?.toString() ?? '').toLowerCase();
                      final cat = (item['cropCategory']?.toString() ?? '').toLowerCase();
                      final desc = (item['description']?.toString() ?? '').toLowerCase();
                      return name.contains(q) || season.contains(q) || cat.contains(q) || desc.contains(q);
                    }).toList();
                  }

                  // ক্রমানুসারে সাজানো
                  items.sort((a, b) {
                    final idxA = a['monthIndex'] as int? ?? 99;
                    final idxB = b['monthIndex'] as int? ?? 99;
                    return idxA.compareTo(idxB);
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
                              child: const Icon(Icons.eco_outlined, color: Color(0xFF2E7D32), size: 40),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _selectedMonth == 'সব মাস'
                                  ? 'কোনো ফসলের তথ্য পাওয়া যায়নি'
                                  : '$_selectedMonth মাসে কোনো ফসলের তথ্য নেই',
                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'এডমিন প্যানেল থেকে তথ্য যুক্ত করা হলে এখানে প্রদর্শিত হবে।',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
                            ),
                            if (_selectedMonth != 'সব মাস') ...[
                              const SizedBox(height: 16),
                              OutlinedButton.icon(
                                onPressed: () => setState(() => _selectedMonth = 'সব মাস'),
                                icon: const Icon(Icons.refresh_rounded, size: 16),
                                label: const Text('সব মাসের ফসল দেখুন'),
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
                      return _buildCropCalendarCard(item);
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

  Widget _buildCropCalendarCard(Map<String, dynamic> item) {
    final cropName = item['cropName']?.toString() ?? 'ফসলের নাম';
    final month = item['month']?.toString() ?? '';
    final season = item['season']?.toString() ?? '';
    final category = item['cropCategory']?.toString() ?? '';
    final sowingTime = item['sowingTime']?.toString() ?? '';
    final harvestingTime = item['harvestingTime']?.toString() ?? '';
    final description = item['description']?.toString() ?? '';
    final careTips = item['careTips']?.toString() ?? '';
    final imageUrl = item['imageUrl']?.toString() ?? '';

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
          // ইমেজ ও ব্যানার হেডার (ক্লিকেবল ইমেজ -> ছবিতে ট্যাপ করলেই ডিটেইলস পেজ ওপেন হবে)
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => CropDetailsPage(cropData: item),
                ),
              );
            },
            child: SizedBox(
              height: 160.0,
              width: double.infinity,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _buildCardImage(imageUrl, cropName),

                  // মাস ও মৌসুম ব্যাজ (IgnorePointer যাতে স্পর্শ কোনোভাবেই আটকাতে না পারে)
                  Positioned(
                    top: 10,
                    left: 10,
                    child: IgnorePointer(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.65),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white24),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.calendar_month_rounded, color: Colors.amberAccent, size: 13),
                            const SizedBox(width: 4),
                            Text(
                              month.isNotEmpty ? '$month মাস' : 'চলতি মাস',
                              style: const TextStyle(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // ক্যাটাগরি ব্যাজ (IgnorePointer)
                  if (category.isNotEmpty)
                    Positioned(
                      top: 10,
                      right: 10,
                      child: IgnorePointer(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2E7D32).withOpacity(0.9),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            category,
                            style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                    ),

                  // সবার উপরে স্বচ্ছ ক্লিকেবল লেয়ার (কোনো লেয়ার বা উইজেট এর স্পর্শ আটকাতে পারবে না)
                  Positioned.fill(
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => CropDetailsPage(cropData: item),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        cropName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    if (season.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF3E0),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFFFB74D)),
                        ),
                        child: Text(
                          season,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFE65100),
                          ),
                        ),
                      ),
                  ],
                ),

                const SizedBox(height: 8),

                // বিবরণ
                if (description.isNotEmpty) ...[
                  Text(
                    description,
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

                // বপন ও ফসল তোলার সময়সূচি চিপস
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9FAF9),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFE8EFE8)),
                  ),
                  child: Column(
                    children: [
                      if (sowingTime.isNotEmpty)
                        Row(
                          children: [
                            const Icon(Icons.grain_rounded, size: 15, color: Color(0xFF2E7D32)),
                            const SizedBox(width: 6),
                            const Text('বপন/রোপণ: ', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                            Expanded(
                              child: Text(sowingTime, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                            ),
                          ],
                        ),
                      if (sowingTime.isNotEmpty && harvestingTime.isNotEmpty)
                        const Divider(height: 12, color: Color(0xFFE8EFE8)),
                      if (harvestingTime.isNotEmpty)
                        Row(
                          children: [
                            const Icon(Icons.agriculture_rounded, size: 15, color: Color(0xFFE65100)),
                            const SizedBox(width: 6),
                            const Text('ফসল সংগ্রহ: ', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                            Expanded(
                              child: Text(harvestingTime, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),

                // যত্ন ও পরিচর্যা পরামর্শ (যদি থাকে)
                if (careTips.isNotEmpty) ...[
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
                            'পরিচর্যা টিপস: $careTips',
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
  Widget _buildCardImage(String imageUrl, String cropName) {
    const double imageHeight = 160.0;
    final cleanUrl = imageUrl.trim();

    return SizedBox(
      height: imageHeight,
      width: double.infinity,
      child: cleanUrl.isEmpty
          ? _buildImagePlaceholder(imageHeight, cropName)
          : CachedNetworkImage(
              imageUrl: cleanUrl,
              height: imageHeight,
              width: double.infinity,
              fit: BoxFit.cover,
              memCacheHeight: 400,
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
                // কোনো ব্লকিং ছাড়া তাত্ক্ষণিক নিরাপদ প্লেসহোল্ডার
                return _buildImagePlaceholder(imageHeight, cropName);
              },
            ),
    );
  }

  /// ডিফল্ট আকর্ষণীয় ইমেজ প্লেসহোল্ডার (লেআউট অক্ষত রাখা নিশ্চিত করে)
  Widget _buildImagePlaceholder(double height, String cropName) {
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
                Icons.eco_rounded,
                size: 28,
                color: Color(0xFF2E7D32),
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                cropName.isNotEmpty ? cropName : 'কৃষি কথা – ফসল ক্যালেন্ডার',
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

