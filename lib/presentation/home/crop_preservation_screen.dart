import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import '../../core/constants/app_colors.dart';
import '../../core/widgets/premium_loading_widget.dart';
import '../../global_popup/global_popup.dart';

class CropPreservationScreen extends StatefulWidget {
  final String? initialCategory;

  const CropPreservationScreen({super.key, this.initialCategory});

  @override
  State<CropPreservationScreen> createState() => _CropPreservationScreenState();
}

class _CropPreservationScreenState extends State<CropPreservationScreen> {
  late String _selectedCategory;

  final List<String> _baseCategories = [
    'সব',
    'ধান ও চাল',
    'আলু ও কন্দ',
    'শাকসবজি',
    'ফলমূল',
    'মসলা ও ডাল',
    'বীজ সংরক্ষন',
    'হিমাগার ও আধুনিক পদ্ধতি',
  ];

  final Map<String, String> _categorySubtitleMap = {
    'ধান ও চাল': 'আর্দ্রতা নিয়ন্ত্রণ, গোলাজাতকরণ ও ধানের নিরাপদ সংরক্ষণ নির্দেশিকা',
    'আলু ও কন্দ': 'হিমাগারে সংরক্ষণ, তাপমাত্রা ও আর্দ্রতা নিয়ন্ত্রণ ও আলো থেকে সুরক্ষা',
    'শাকসবজি': 'হিমাগার ছাড়াও দেশীয় পদ্ধতিতে তাজা শাকসবজি সংরক্ষণের কৌশল',
    'ফলমূল': 'আম, কলা, লিচু ও অন্যান্য ফলের দীর্ঘস্থায়ী সংরক্ষণ ও পরিবহন ব্যবস্থা',
    'মসলা ও ডাল': 'শুকানো, বায়ুরোধক পাত্রে বায়ু নিরোধক মজুদ ও পোকা দমন',
    'বীজ সংরক্ষন': 'ভবিষ্যৎ ফসলের জন্য বীজের অঙ্কুরোদগম ক্ষমতা ধরে রাখার পদ্ধতি',
    'হিমাগার ও আধুনিক পদ্ধতি': 'কোল্ড স্টোরেজ ভাড়া, সাইলো, কুল চেইন ও আধুনিক প্যাকিং প্রযুক্তি',
  };

  late final Stream<QuerySnapshot<Map<String, dynamic>>> _preservationStream;

  @override
  void initState() {
    super.initState();
    // Read Optimization: Initialize stream once in initState with reasonable limit
    _preservationStream = FirebaseFirestore.instance
        .collection('crop_preservation')
        .limit(50)
        .snapshots();
    _selectedCategory = widget.initialCategory ?? 'সব';
  }

  /// Cloudflare R2 সহ যে কোনো ছবির URL নরমালাইজ করার নিরাপদ মেথড
  String _normalizePreservationImageUrl(Map<String, dynamic> item) {
    String url = (item['imageUrl'] ??
            item['image'] ??
            item['photoUrl'] ??
            item['imgUrl'] ??
            item['thumbnail'] ??
            item['img'] ??
            '')
        .toString()
        .trim();
    if (url.isEmpty) return '';
    if (url.startsWith('http://') || url.startsWith('https://')) {
      return url;
    }
    const r2Base = 'https://pub-660f3103c4924ba0a9526f4bbc8dd392.r2.dev/';
    return '$r2Base${url.replaceFirst(RegExp(r'^/+'), '')}';
  }

  void _showPreservationDetailModal(BuildContext context, Map<String, dynamic> data) {
    final title = (data['title'] ?? data['name'] ?? 'ফসল সংরক্ষণের তথ্য').toString();
    final category = (data['category'] ?? 'অন্যান্য').toString();
    final cropType = (data['cropType'] ?? data['type'] ?? data['variety'] ?? '').toString();
    final highlights = (data['highlights'] ?? '').toString();
    final description = (data['description'] ?? 'বিস্তারিত সংরক্ষণ পদ্ধতি শীঘ্রই যুক্ত হবে।').toString();
    final tips = (data['tips'] ?? data['storageTips'] ?? data['temperature'] ?? '').toString();
    final imageUrl = _normalizePreservationImageUrl(data);

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
              // Cloudflare R2 ছবি
              if (imageUrl.isNotEmpty) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: CachedNetworkImage(
                    imageUrl: imageUrl.trim(),
                    height: 190,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Shimmer.fromColors(
                      baseColor: Colors.grey.shade200,
                      highlightColor: Colors.grey.shade100,
                      child: Container(height: 190, color: Colors.white),
                    ),
                    errorWidget: (_, errUrl, ___) {
                      debugPrint('Preservation Detail Image Error: $errUrl');
                      return const SizedBox.shrink();
                    },
                  ),
                ),
                const SizedBox(height: 14),
              ],

              // ক্যাটাগরি ও ফসল ধরন ব্যাজ
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFEBE9),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFD7CCC8)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.inventory_2_rounded, size: 13, color: Color(0xFF5D4037)),
                        const SizedBox(width: 5),
                        Text(
                          category,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF5D4037),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (cropType.isNotEmpty && cropType != 'উল্লেখ নেই')
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFBE9E7),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFFFCCBC)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.category_rounded, size: 13, color: Color(0xFFD84315)),
                          const SizedBox(width: 5),
                          Text(
                            cropType,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFD84315),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 14),

              // মূল বৈশিষ্ট্য / হাইলাইটস
              if (highlights.isNotEmpty && highlights != 'উল্লেখ নেই') ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFEBE9),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFD7CCC8)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.star_rounded, size: 18, color: Color(0xFF5D4037)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          highlights,
                          style: const TextStyle(
                            fontSize: 12.5,
                            color: Color(0xFF3E2723),
                            fontWeight: FontWeight.w600,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // বিস্তারিত সংরক্ষণ পদ্ধতি ও ব্যবস্থাপনা
              _buildModalSectionHeader('সংরক্ষণ পদ্ধতি ও ব্যবস্থাপনা', Icons.warehouse_rounded, const Color(0xFF3E2723)),
              const SizedBox(height: 5),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFAFAFA),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFEFEBE9)),
                ),
                child: Text(
                  description,
                  style: const TextStyle(fontSize: 13, color: Color(0xFF263238), height: 1.5),
                ),
              ),
              const SizedBox(height: 14),

              // তাপমাত্রা, আর্দ্রতা ও নিরাপত্তা টিপস
              if (tips.isNotEmpty && tips != 'উল্লেখ নেই') ...[
                _buildModalSectionHeader('তাপমাত্রা, আর্দ্রতা ও নিরাপত্তা টিপস', Icons.thermostat_rounded, const Color(0xFF5D4037)),
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
                    tips,
                    style: const TextStyle(fontSize: 12.5, color: Color(0xFF4E342E), height: 1.5, fontWeight: FontWeight.w500),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // বন্ধ করুন বোতাম
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF5D4037),
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(vertical: 11),
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'বন্ধ করুন',
                    style: TextStyle(color: Colors.white, fontSize: 13.5, fontWeight: FontWeight.bold),
                  ),
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
      backgroundColor: const Color(0xFFFAF8F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFF5D4037),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 19),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          children: [
            const Text(
              'ফসল সংরক্ষন',
              style: TextStyle(
                color: Colors.white,
                fontSize: 17.5,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'দানা শস্য, আলু, ফলমূল ও বীজের নিরাপদ সংরক্ষণ ও হিমাগার নির্দেশিকা',
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
        child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: _preservationStream,
          builder: (context, snapshot) {
            final docs = snapshot.data?.docs ?? [];

            // ডাইনামিক ক্যাটাগরি তালিকা তৈরি (বেস ক্যাটাগরি + ফায়ারস্টোরের নতুন ক্যাটাগরি)
            final Set<String> dynamicCategories = Set.from(_baseCategories);
            for (final doc in docs) {
              final data = doc.data();
              final cat = (data['category'] ?? '').toString().trim();
              if (cat.isNotEmpty && !dynamicCategories.contains(cat)) {
                dynamicCategories.add(cat);
              }
            }
            final categoriesList = dynamicCategories.toList();

            return Column(
              children: [
                // ১. কালারিং টপবার বক্স (ক্যাটাগরি চিপস সহ)
                _buildColoredTopBar(categoriesList),

                // ২. নির্বাচিত ক্যাটাগরির অতিরিক্ত ব্যানার তথ্য (যদি কোনো নির্দিষ্ট ক্যাটাগরি সিলেক্ট থাকে)
                if (_selectedCategory != 'সব')
                  Container(
                    margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFEFEBE9), Color(0xFFD7CCC8)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFD7CCC8)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: const Color(0xFF5D4037),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.inventory_2_rounded, color: Colors.white, size: 18),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _selectedCategory,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF3E2723),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _categorySubtitleMap[_selectedCategory] ??
                                    'এই ক্যাটাগরির ফসল সংরক্ষণ পদ্ধতি, তাপমাত্রা ও আর্দ্রতা নির্দেশিকা নিচে প্রদর্শিত হচ্ছে',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF4E342E),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                // ৩. ফসল সংরক্ষণের কার্ড তালিকা (নো সার্চ বার, নো বিস্তারিত বাটন, ছবিতে ক্লিকে পপআপ)
                Expanded(
                  child: _buildPreservationList(snapshot),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  /// স্টাইলিশ টপবার
  Widget _buildColoredTopBar(List<String> categories) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF5D4037), Color(0xFF3E2723)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x335D4037),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.only(top: 8, bottom: 14),
      child: SizedBox(
        height: 36,
        child: ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          itemCount: categories.length,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (context, index) {
            final category = categories[index];
            final isSelected = _selectedCategory == category;
            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedCategory = category;
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white : Colors.white.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected ? Colors.white : Colors.white.withOpacity(0.3),
                    width: 1,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.12),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Center(
                  child: Text(
                    category,
                    style: TextStyle(
                      color: isSelected ? const Color(0xFF5D4037) : Colors.white,
                      fontSize: 12.5,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  /// ফসল সংরক্ষণের কার্ড তালিকা বিল্ডার (শুধুমাত্র Firestore লাইভ ডেটা, কোনো ডেমো ডেটা নেই)
  Widget _buildPreservationList(AsyncSnapshot<QuerySnapshot<Map<String, dynamic>>> snapshot) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return const Center(
        child: PremiumLoadingWidget(
          title: 'ফসল সংরক্ষণের তথ্য লোড হচ্ছে...',
          subtitle: 'অনুগ্রহ করে অপেক্ষা করুন',
        ),
      );
    }

    // ফায়ারস্টোর লাইভ ডেটা
    final firestoreDocs = snapshot.data?.docs ?? [];
    List<Map<String, dynamic>> items = firestoreDocs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      return data;
    }).toList();

    // ক্যাটাগরি ফিল্টারিং
    if (_selectedCategory != 'সব') {
      items = items.where((item) {
        final cat = (item['category'] ?? '').toString().toLowerCase();
        final title = (item['title'] ?? item['name'] ?? '').toString().toLowerCase();
        final target = _selectedCategory.toLowerCase();
        return cat.contains(target) || title.contains(target);
      }).toList();
    }

    // লাইভ ডেটা না থাকলে ক্লিন এম্পটি স্টেট মেসেজ
    if (items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 65,
                height: 65,
                decoration: const BoxDecoration(
                  color: Color(0xFFEFEBE9),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.inventory_2_outlined, size: 30, color: Color(0xFF5D4037)),
              ),
              const SizedBox(height: 14),
              const Text(
                'এখনো কোনো ফসল সংরক্ষনের তথ্য যুক্ত করা হয়নি',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15.5,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF263238),
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                _selectedCategory != 'সব'
                    ? 'অন্য কোনো ক্যাটাগরি নির্বাচন করুন'
                    : 'শীঘ্রই অ্যাডমিন প্যানেল থেকে তথ্য যুক্ত করা হবে',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12.5, color: Colors.grey.shade600),
              ),
              if (_selectedCategory != 'সব') ...[
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF5D4037),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
                  ),
                  onPressed: () => setState(() => _selectedCategory = 'সব'),
                  icon: const Icon(Icons.rotate_right_rounded, size: 16),
                  label: const Text('সকল তথ্য দেখুন', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
                ),
              ],
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 30),
      physics: const BouncingScrollPhysics(),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return _buildPreservationCard(context, item);
      },
    );
  }

  /// কার্ড ডিজাইন: নো সার্চ বার, নো বিস্তারিত বাটন, ছবিতে ক্লিকে বিস্তারিত পপআপ
  Widget _buildPreservationCard(BuildContext context, Map<String, dynamic> item) {
    final title = (item['title'] ?? item['name'] ?? 'ফসল সংরক্ষণের তথ্য').toString();
    final category = (item['category'] ?? 'অন্যান্য').toString();
    final cropType = (item['cropType'] ?? item['type'] ?? item['variety'] ?? '').toString();
    final highlights = (item['highlights'] ?? '').toString();
    final description = (item['description'] ?? '').toString();
    final imageUrl = _normalizePreservationImageUrl(item);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEFEBE9), width: 1.2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ছবিতে ক্লিক করলে সরাসরি বিস্তারিত পপআপ ওপেন হবে
          GestureDetector(
            onTap: () => _showPreservationDetailModal(context, item),
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(15),
                    topRight: Radius.circular(15),
                  ),
                  child: imageUrl.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: imageUrl,
                          height: 180,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => Shimmer.fromColors(
                            baseColor: Colors.grey.shade200,
                            highlightColor: Colors.grey.shade100,
                            child: Container(height: 180, color: Colors.white),
                          ),
                          errorWidget: (_, errUrl, ___) => _buildImageFallback(title),
                        )
                      : _buildImageFallback(title),
                ),

                // ক্যাটাগরি ব্যাজ (টপ-লেফট)
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xE63E2723),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withOpacity(0.28)),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x33000000),
                          blurRadius: 6,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: Color(0xFFFFCCBC),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 5),
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

                // ফসল ধরন ব্যাজ (টপ-রাইট)
                if (cropType.isNotEmpty && cropType != 'উল্লেখ নেই')
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xE65D4037),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white.withOpacity(0.25)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.tag_rounded, size: 10, color: Color(0xFFFFE0B2)),
                          const SizedBox(width: 4),
                          Text(
                            cropType,
                            style: const TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // টেক্সট কনটেন্ট
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // শিরোনাম ও লেফট অ্যাকসেন্ট বার
                GestureDetector(
                  onTap: () => _showPreservationDetailModal(context, item),
                  child: Container(
                    padding: const EdgeInsets.only(left: 8),
                    decoration: const BoxDecoration(
                      border: Border(
                        left: BorderSide(color: Color(0xFF5D4037), width: 3.5),
                      ),
                    ),
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF263238),
                        height: 1.35,
                      ),
                    ),
                  ),
                ),

                // হাইলাইটস
                if (highlights.isNotEmpty && highlights != 'উল্লেখ নেই') ...[
                  const SizedBox(height: 9),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.check_circle_rounded, size: 14, color: Color(0xFF5D4037)),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          highlights,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF3E2723),
                            height: 1.35,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],

                // সংক্ষিপ্ত বিবরণী
                if (description.isNotEmpty && description != 'উল্লেখ নেই') ...[
                  const SizedBox(height: 7),
                  Text(
                    description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade700,
                      height: 1.4,
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

  Widget _buildImageFallback(String title) {
    return Container(
      height: 180,
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFEFEBE9), Color(0xFFD7CCC8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.inventory_2_rounded, size: 26, color: Color(0xFF5D4037)),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.bold,
                color: Color(0xFF3E2723),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
