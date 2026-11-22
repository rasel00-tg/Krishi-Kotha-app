import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import '../../core/constants/app_colors.dart';
import '../../core/widgets/premium_loading_widget.dart';
import '../../global_popup/global_popup.dart';

class LivestockPoultryScreen extends StatefulWidget {
  final String? initialCategory;

  const LivestockPoultryScreen({super.key, this.initialCategory});

  @override
  State<LivestockPoultryScreen> createState() => _LivestockPoultryScreenState();
}

class _LivestockPoultryScreenState extends State<LivestockPoultryScreen> {
  late String _selectedCategory;

  final List<String> _baseCategories = [
    'সব',
    'গরু',
    'ছাগল ও ভেড়া',
    'হাঁস-মুরগি',
    'কোয়েল ও কবুতর',
    'রোগ ও টিকা',
    'খাদ্য ও পরিচর্যা',
  ];

  final Map<String, String> _categorySubtitleMap = {
    'গরু': 'উন্নত জাতের গাভী পালন, দুধ উৎপাদন ও মোটাতাজাকরণ',
    'ছাগল ও ভেড়া': 'ব্ল্যাক বেঙ্গল ছাগল ও ভেড়া খামার ব্যবস্থাপনা',
    'হাঁস-মুরগি': 'দেশি ও ব্রয়লার মুরগি এবং খাকি ক্যাম্পবেল হাঁস পালন',
    'কোয়েল ও কবুতর': 'কোয়েল পাখির ডিম ও শৌখিন কবুতর পালন পদ্ধতি',
    'রোগ ও টিকা': 'খুরারোগ, রাণীক্ষেত, গামবোরো ও পক্সের টিকা সূচি',
    'খাদ্য ও পরিচর্যা': 'সুষম খাদ্য তালিকা, খামারের বাসস্থান ও সঠিক যত্ন',
  };

  late final Stream<QuerySnapshot<Map<String, dynamic>>> _livestockStream;

  // Fallback high-quality initial data if Firestore collection is fresh
  static const List<Map<String, dynamic>> _defaultLivestockData = [
    {
      'id': 'live_1',
      'title': 'উন্নত জাতের দুগ্ধবতী গাভী পালন ও পরিচর্যা',
      'category': 'গরু',
      'breed': 'হোলস্টাইন ফ্রিজিয়ান ও শাহিওয়াল সংকর',
      'highlights': 'দৈনিক ১৫-২০ লিটার দুধ উৎপাদন ও রোগ সহনশীল',
      'description': 'উন্নত জাতের গাভীর জন্য শুষ্ক ও আলো-বাতাসপূর্ণ বাসস্থান নিশ্চিত করতে হবে। মেঝে যেন পিচ্ছিল না হয় সেদিকে খেয়াল রাখুন। প্রসবের আগে ও পরে পর্যাপ্ত ক্যালসিয়াম ও ভিটামিন সমৃদ্ধ পুষ্টিকর দানাদার খাদ্য সরবরাহ করা আবশ্যক।',
      'tips': 'প্রতি ৪ মাস অন্তর কৃমিনাশক ও বছরান্তে খুরারোগ (FMD) ও বাদলা রোগের টিকা নিশ্চিত করুন। কাঁচা ঘাসের সাথে দৈনিক ৩-৪ কেজি সুষম দানাদার খাদ্য দিন।',
      'imageUrl': 'https://images.unsplash.com/photo-1546445317-29f4545e9d53?auto=format&fit=crop&w=800&q=80',
    },
    {
      'id': 'live_2',
      'title': 'ব্ল্যাক বেঙ্গল ছাগল পালন ও মাচায় বাসস্থান',
      'category': 'ছাগল ও ভেড়া',
      'breed': 'দেশি ব্ল্যাক বেঙ্গল ছাগল',
      'highlights': 'বছরে দুবার বাচ্চা দেয়, সুস্বাদু মাংস ও আন্তর্জাতিক মানসম্পন্ন চামড়া',
      'description': 'ছাগলকে সবসময় মাচায় বা উঁচু কাঠের পাটাতনে রাখা উত্তম। এতে ঠান্ডা ও নিউমোনিয়া থেকে রক্ষা পায়। ছাগলের ঘর সবসময় শুকনো ও পরিষ্কার রাখতে হবে।',
      'tips': 'বাচ্চা জন্মের পর পিপিআর (PPR) টিকা দিতে হবে। কাঁঠাল পাতা, ইপিল-ইপিল ও কাঁচা ঘাসের সাথে সামান্য দানাদার খাদ্য ও লবণ মিশ্রিত পানি খাওয়াতে হবে।',
      'imageUrl': 'https://images.unsplash.com/photo-1524024973431-2ad916746881?auto=format&fit=crop&w=800&q=80',
    },
    {
      'id': 'live_3',
      'title': 'দেশি ও সোনালি মুরগি পালন নির্দেশিকা',
      'category': 'হাঁস-মুরগি',
      'breed': 'সোনালি ও দেশি উন্নত জাত',
      'highlights': 'স্বল্প পুঁজিতে লাভজনক ও মুক্ত খামার পদ্ধতিতে পালনযোগ্য',
      'description': 'ব্রুডিং পিরিয়ডে (প্রথম ২ সপ্তাহ) সঠিক তাপমাত্রা বজায় রাখা সবচেয়ে গুরুত্বপূর্ণ। ঘরের লিটার সবসময় শুকনো রাখতে হবে যাতে অ্যামোনিয়া গ্যাস না তৈরি হয়।',
      'tips': 'বাচ্চার বয়স ৩-৫ দিনে রাণীক্ষেতের ১ম ড্রপ (BCRDV) চোখে ও ৯-১১ দিনে গামবোরো ড্রপ দিতে হবে। পরিষ্কার বিশুদ্ধ পানির সাথে ভিটামিন সি দিন।',
      'imageUrl': 'https://images.unsplash.com/photo-1548550023-2bdb3c5beed7?auto=format&fit=crop&w=800&q=80',
    },
    {
      'id': 'live_4',
      'title': 'খাকি ক্যাম্পবেল ও দেশি হাঁস পালন',
      'category': 'হাঁস-মুরগি',
      'breed': 'খাকি ক্যাম্পবেল ও নাগেশ্বরী',
      'highlights': 'বছরে ২৫০-৩০০টি ডিম দেয় এবং প্রাকৃতিক জলাশয়ে সহজে বাড়ে',
      'description': 'হাঁস পালনের জন্য পুকুর বা আবদ্ধ ছোট জলাশয় থাকলে উৎপাদন খরচ অনেক কমে যায়। রাত্রে থাকার ঘরে শুকনো তুষের লিটার বিছিয়ে দিতে হবে।',
      'tips': '২১-২৮ দিন বয়সে ডাক প্লেগ ও ডাক কলেরা টিকা দেওয়া বাধ্যতামূলক। শামুক, ঝিনুক ও কুঁড়ো মিশিয়ে সুষম খাদ্য তৈরি করে দিন।',
      'imageUrl': 'https://images.unsplash.com/photo-1589656966895-2f33e7653819?auto=format&fit=crop&w=800&q=80',
    },
    {
      'id': 'live_5',
      'title': 'কোয়েল পাখির ডিম ও মাংস উৎপাদন খামার',
      'category': 'কোয়েল ও কবুতর',
      'breed': 'জাপানিজ কোয়েল (Coturnix japonica)',
      'highlights': 'মাত্র ৬-৭ সপ্তাহে ডিম দেওয়া শুরু করে ও স্বল্প স্থানে পালন সম্ভব',
      'description': 'কোয়েল পাখি অত্যন্ত সংবেদনশীল, তাই খামারে অতিরিক্ত শব্দ ও তীব্র আলো নিয়ন্ত্রণ করা উচিত। এক বর্গফুট জায়গায় ৫-৬টি কোয়েল খাঁচায় রাখা যায়।',
      'tips': 'প্রতিদিন ১৪-১৬ ঘণ্টা আলো সরবরাহ করলে ডিমের উৎপাদন সর্বোচ্চ থাকে। খাঁচায় পানি ও খাদ্য পাত্র নিয়মিত জীবাণুমুক্ত রাখুন।',
      'imageUrl': 'https://images.unsplash.com/photo-1552728089-57bdde30beb3?auto=format&fit=crop&w=800&q=80',
    },
    {
      'id': 'live_6',
      'title': 'গরু-ছাগলের খুরারোগ (FMD) ও তার প্রতিকার',
      'category': 'রোগ ও টিকা',
      'breed': 'সকল জাতের গবাদি পশু',
      'highlights': 'মুখে ঘা, পায়ে ক্ষত ও লালা ঝরা জরুরি লক্ষণ',
      'description': 'খুরারোগ একটি অত্যন্ত ছোঁয়াচে ভাইরাসজনিত রোগ। আক্রান্ত পশুর পায়ের ক্ষত ও মুখের ঘা পটাশ মিশ্রিত কুসুম গরম পানি দিয়ে ধুয়ে সোহাগার গুঁড়া ও গ্লিসারিন লাগাতে হবে।',
      'tips': 'সুস্থ পশুকে প্রতি ৬ মাস পরপর এফএমডি (FMD) ভ্যাকসিন দিন। খামারে প্রবেশের মুখে জীবাণুনাশক ফুটবাথ তৈরি রাখুন।',
      'imageUrl': 'https://images.unsplash.com/photo-1500595046743-cd271d694d30?auto=format&fit=crop&w=800&q=80',
    },
    {
      'id': 'live_7',
      'title': 'হাঁস-মুরগির সম্পূর্ণ টিকাদান সূচি ও চার্ট',
      'category': 'রোগ ও টিকা',
      'breed': 'মুরগি, হাঁস ও কোয়েল',
      'highlights': 'রাণীক্ষেত, গামবোরো ও ফাউল পক্সের সময়সূচি',
      'description': 'টিকা দেওয়ার আগের দিন ও পরের দিন অ্যান্টি-স্ট্রেস বা ভিটামিন পানি খাওয়াতে হবে। কখনোই অসুস্থ পাখিকে ভ্যাকসিন দেওয়া যাবে না। ভ্যাকসিন সবসময় বরফযুক্ত ফ্লাস্কে পরিবহন করুন।',
      'tips': '৩-৫ দিন: রাণীক্ষেত ১ম ডোজ; ১০-১২ দিন: গামবোরো ১ম ডোজ; ১৮-২০ দিন: গামবোরো বুস্টার; ২৪ দিন: রাণীক্ষেত ২য় ডোজ; ৩৫ দিন: পক্স টিকা।',
      'imageUrl': 'https://images.unsplash.com/photo-1516467508483-a7212febe31a?auto=format&fit=crop&w=800&q=80',
    },
    {
      'id': 'live_8',
      'title': 'নেপিয়ার ঘাস চাষ ও ইউরিয়া মোলাসেস স্ট্র (UMS)',
      'category': 'খাদ্য ও পরিচর্যা',
      'breed': 'উচ্চফলনশীল পুষ্টিকর গো-খাদ্য',
      'highlights': 'দুধ উৎপাদন বৃদ্ধি করে ও খাদ্যের ব্যয় ৩০% কমায়',
      'description': 'শুকনো খড়ের সাথে ইউরিয়া, চিটাগুড় (মোলাসেস) ও পানি মিশিয়ে ইউরিয়া মোলাসেস স্ট্র তৈরি করা হয়। এটি খড়ের পুষ্টিমান ও হজমযোগ্যতা বহুগুণ বাড়িয়ে দেয়।',
      'tips': 'নেপিয়ার বা জাম্বো ঘাস ফুল আসার আগেই কেটে খাওয়াতে হবে। প্রতিদিন গরুর ওজনের ১০% কাঁচা ঘাস ও ১-২% দানাদার খাদ্য দেওয়া আদর্শ।',
      'imageUrl': 'https://images.unsplash.com/photo-1500382017468-9049fed747ef?auto=format&fit=crop&w=800&q=80',
    },
  ];

  @override
  void initState() {
    super.initState();
    // Read Optimization: Initialize stream once in initState with reasonable limit
    _livestockStream = FirebaseFirestore.instance
        .collection('livestock_poultry')
        .limit(50)
        .snapshots();
    _selectedCategory = widget.initialCategory ?? 'সব';
  }

  /// Cloudflare R2 সহ যে কোনো ছবির URL নরমালাইজ করার নিরাপদ মেথড
  String _normalizeLivestockImageUrl(Map<String, dynamic> item) {
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

  void _showLivestockDetailModal(BuildContext context, Map<String, dynamic> data) {
    final title = (data['title'] ?? data['name'] ?? 'পশু ও হাঁস-মুরগির তথ্য').toString();
    final category = (data['category'] ?? 'অন্যান্য').toString();
    final breed = (data['breed'] ?? data['type'] ?? 'উল্লেখ নেই').toString();
    final highlights = (data['highlights'] ?? 'জরুরি লক্ষণ বা বৈশিষ্ট্য').toString();
    final description = (data['description'] ?? 'বিস্তারিত তথ্য শীঘ্রই যুক্ত হবে।').toString();
    final tips = (data['tips'] ?? data['vaccineInfo'] ?? data['feedInfo'] ?? 'সঠিক খাদ্য ও নিয়মিত টিকাদান নিশ্চিত করুন।').toString();
    final imageUrl = _normalizeLivestockImageUrl(data);

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
                      debugPrint('Livestock Detail Image Error: $errUrl');
                      return const SizedBox.shrink();
                    },
                  ),
                ),
                const SizedBox(height: 14),
              ],

              // ক্যাটাগরি ও জাত ব্যাজ
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
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
                        const Icon(Icons.pets, size: 13, color: Color(0xFFD84315)),
                        const SizedBox(width: 5),
                        Text(
                          category,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFD84315),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (breed != 'উল্লেখ নেই' && breed.isNotEmpty)
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
                          const Icon(Icons.category_rounded, size: 13, color: Color(0xFF5D4037)),
                          const SizedBox(width: 5),
                          Text(
                            breed,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF5D4037),
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
                    color: const Color(0xFFFFF3E0),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFFFE0B2)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.star_rounded, size: 18, color: Color(0xFFE65100)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          highlights,
                          style: const TextStyle(fontSize: 12.5, color: Color(0xFFE65100), fontWeight: FontWeight.w600, height: 1.4),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // বিস্তারিত পরিচর্যা ও বাসস্থান
              _buildModalSectionHeader('পরিচর্যা ও ব্যবস্থাপনা', Icons.info_outline_rounded, const Color(0xFF3E2723)),
              const SizedBox(height: 5),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFBFBFA),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFD7CCC8)),
                ),
                child: Text(
                  description,
                  style: const TextStyle(fontSize: 13, color: Color(0xFF4E342E), height: 1.5),
                ),
              ),
              const SizedBox(height: 12),

              // টিকা সূচি ও খাদ্য ব্যবস্থাপনা
              _buildModalSectionHeader('টিকা সূচি ও পুষ্টিকর খাদ্য', Icons.medical_services_outlined, const Color(0xFFD84315)),
              const SizedBox(height: 5),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFBE9E7),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFFFCCBC)),
                ),
                child: Text(
                  tips,
                  style: const TextStyle(fontSize: 13, color: Color(0xFFBF360C), height: 1.5),
                ),
              ),
              const SizedBox(height: 18),

              // বন্ধ করুন বাটন
              SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton(
                  onPressed: () {
                    if (Navigator.of(context, rootNavigator: true).canPop()) {
                      Navigator.of(context, rootNavigator: true).pop();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD84315),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: const Text('বন্ধ করুন', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
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
      backgroundColor: const Color(0xFFFDFBF9),
      appBar: AppBar(
        backgroundColor: const Color(0xFFD84315),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 19),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          children: [
            const Text(
              'পশু ও হাঁস-মুরগি',
              style: TextStyle(
                color: Colors.white,
                fontSize: 17.5,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'গবাদি পশু, হাঁস-মুরগি পালন ও স্বাস্থ্য নির্দেশিকা',
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
          stream: _livestockStream,
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
                // ১. "চাষ ক্যালেন্ডার" ও "মাটির স্বাস্থ্য" পেইজের হুবহু কালারিং টপবার বক্স (ক্যাটাগরি চিপস সহ)
                _buildColoredTopBar(categoriesList),

                // ২. নির্বাচিত ক্যাটাগরির অতিরিক্ত ব্যানার তথ্য (যদি কোনো নির্দিষ্ট ক্যাটাগরি সিলেক্ট থাকে)
                if (_selectedCategory != 'সব')
                  Container(
                    margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFBE9E7), Color(0xFFFFEBE6)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFFFCCBC)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: const Color(0xFFD84315),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.pets, color: Colors.white, size: 18),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '$_selectedCategory - পালন নির্দেশিকা',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFFBF360C),
                                ),
                              ),
                              Text(
                                _categorySubtitleMap[_selectedCategory] ??
                                    'এই ক্যাটাগরির উন্নত জাত, খাদ্য ও স্বাস্থ্য তথ্য নিচে প্রদর্শিত হচ্ছে',
                                style: const TextStyle(fontSize: 11, color: Color(0xFFD84315)),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                // ৩. পশু ও পাখির তালিকা (StreamBuilder রিয়েল-টাইম ডেটা ও R2 ইমেজ)
                Expanded(
                  child: _buildLivestockContent(snapshot, docs),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildColoredTopBar(List<String> categories) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFD84315), Color(0xFFBF360C)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFD84315).withOpacity(0.25),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 14),
      child: SizedBox(
        height: 38,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          itemCount: categories.length,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (context, index) {
            final cat = categories[index];
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
                      cat == 'সব'
                          ? Icons.grid_view_rounded
                          : (cat.contains('গরু')
                              ? Icons.pets
                              : (cat.contains('মুরগি') || cat.contains('পাখি')
                                  ? Icons.egg_rounded
                                  : (cat.contains('টিকা') || cat.contains('রোগ')
                                      ? Icons.healing_rounded
                                      : Icons.grass_rounded))),
                      size: 13,
                      color: isSelected ? const Color(0xFFBF360C) : Colors.white,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      cat,
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                        color: isSelected ? const Color(0xFFBF360C) : Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildLivestockContent(
      AsyncSnapshot<QuerySnapshot<Map<String, dynamic>>> snapshot,
      List<QueryDocumentSnapshot<Map<String, dynamic>>> docs) {
    if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
      return const Center(
        child: PremiumLoadingWidget(
          topic: 'পশু ও হাঁস-মুরগি',
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

    var items = docs.map((doc) {
      final data = Map<String, dynamic>.from(doc.data());
      data['id'] = doc.id;
      return data;
    }).toList();

    // ফায়ারস্টোর ডেটা খালি থাকলে ফলব্যাক ডেটা ব্যবহার করা
    if (items.isEmpty) {
      items = List<Map<String, dynamic>>.from(_defaultLivestockData);
    }

    // ফিল্টারিং: ক্যাটাগরিভিত্তিক
    if (_selectedCategory != 'সব') {
      final targetCat = _selectedCategory.toLowerCase();
      items = items.where((item) {
        final category = (item['category'] ?? '').toString().toLowerCase();
        final title = (item['title'] ?? item['name'] ?? '').toString().toLowerCase();
        return category.contains(targetCat) || title.contains(targetCat);
      }).toList();
    }

    // ক্রমানুসারে সাজানো (সর্বশেষ আপডেট হওয়া তথ্য প্রথমে)
    items.sort((a, b) {
      final timeA = (a['updatedAt'] as Timestamp?)?.millisecondsSinceEpoch ??
          (a['createdAt'] as Timestamp?)?.millisecondsSinceEpoch ??
          0;
      final timeB = (b['updatedAt'] as Timestamp?)?.millisecondsSinceEpoch ??
          (b['createdAt'] as Timestamp?)?.millisecondsSinceEpoch ??
          0;
      return timeB.compareTo(timeA);
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
                  color: Color(0xFFFBE9E7),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.pets, color: Color(0xFFD84315), size: 40),
              ),
              const SizedBox(height: 16),
              Text(
                _selectedCategory == 'সব'
                    ? 'কোনো তথ্য পাওয়া যায়নি'
                    : '$_selectedCategory ক্যাটাগরিতে কোনো তথ্য নেই',
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 6),
              const Text(
                'অন্য কোনো ক্যাটাগরি নির্বাচন করে চেষ্টা করুন',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
              if (_selectedCategory != 'সব') ...[
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: () => setState(() => _selectedCategory = 'সব'),
                  icon: const Icon(Icons.refresh_rounded, size: 16),
                  label: const Text('সকল তথ্য দেখুন'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFD84315),
                    side: const BorderSide(color: Color(0xFFD84315)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
        return _buildLivestockCard(context, item);
      },
    );
  }

  /// আধুনিক ও আকর্ষণীয় ক্লিন কার্ড (ছবিতে ক্লিকে ডিটেইলস ওপেন হবে, সার্চবার ও বিস্তারিত বাটন মুক্ত)
  Widget _buildLivestockCard(BuildContext context, Map<String, dynamic> item) {
    final title = (item['title'] ?? item['name'] ?? 'পশু ও হাঁস-মুরগির তথ্য').toString();
    final category = (item['category'] ?? 'অন্যান্য').toString();
    final breed = (item['breed'] ?? item['type'] ?? '').toString();
    final highlights = (item['highlights'] ?? '').toString();
    final description = (item['description'] ?? '').toString();
    final imageUrl = _normalizeLivestockImageUrl(item);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF0E5E0), width: 1.1),
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
          // ইমেজ ও গ্লাসমর্ফিক ক্যাটাগরি হেডার (ছবিতে ট্যাপ করলেই ডিটেইলস ওপেন হবে)
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => _showLivestockDetailModal(context, item),
                splashColor: const Color(0x22D84315),
                highlightColor: const Color(0x11D84315),
                child: SizedBox(
                  height: 190.0,
                  width: double.infinity,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      _buildCardImage(imageUrl, title, 190.0),

                      // উপরে ক্যাটাগরি ব্যাজ (Glassmorphic Top-Left Pill)
                      Positioned(
                        top: 12,
                        left: 12,
                        child: IgnorePointer(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
                            decoration: BoxDecoration(
                              color: const Color(0xE03E2723), // Deep terracotta glassmorphic
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.white.withOpacity(0.32), width: 1),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.18),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
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
                                    color: Color(0xFFFF8A65),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  category.isNotEmpty ? category : 'পশু ও পাখি',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      // জাত ব্যাজ (Top-Right Pill)
                      if (breed.isNotEmpty)
                        Positioned(
                          top: 12,
                          right: 12,
                          child: IgnorePointer(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4.5),
                              decoration: BoxDecoration(
                                color: const Color(0xE0D84315),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: Colors.white.withOpacity(0.32), width: 1),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.18),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.star_rate_rounded, size: 12, color: Color(0xFFFFE082)),
                                  const SizedBox(width: 4),
                                  Text(
                                    breed,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
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
              ),
            ),
          ),

          // কার্ডের বিস্তারিত তথ্য অংশ
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // শিরোনামের সাথে বামে কালার অ্যাক্সেন্ট বার
                InkWell(
                  onTap: () => _showLivestockDetailModal(context, item),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 3.5,
                        height: 20,
                        margin: const EdgeInsets.only(top: 2, right: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFD84315),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      Expanded(
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
                    ],
                  ),
                ),
                const SizedBox(height: 8),

                // হাইলাইটস
                if (highlights.isNotEmpty) ...[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.verified_outlined, size: 14, color: Color(0xFFD84315)),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          highlights,
                          style: const TextStyle(
                            fontSize: 12.5,
                            color: Color(0xFF5D4037),
                            fontWeight: FontWeight.w500,
                            height: 1.35,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],

                // বর্ণনা স্নিপেট
                if (description.isNotEmpty) ...[
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

  Widget _buildCardImage(String imageUrl, String title, double height) {
    if (imageUrl.isEmpty) {
      return Container(
        height: height,
        color: const Color(0xFFFBE9E7),
        child: Center(
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
                child: const Icon(Icons.pets, color: Color(0xFFD84315), size: 26),
              ),
              const SizedBox(height: 8),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFBF360C),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return CachedNetworkImage(
      imageUrl: imageUrl.trim(),
      height: height,
      width: double.infinity,
      fit: BoxFit.cover,
      placeholder: (_, __) => Shimmer.fromColors(
        baseColor: Colors.grey.shade200,
        highlightColor: Colors.grey.shade100,
        child: Container(height: height, color: Colors.white),
      ),
      errorWidget: (_, errUrl, ___) {
        debugPrint('Livestock Card Image Load Error: $errUrl');
        return Container(
          height: height,
          color: const Color(0xFFFBE9E7),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.pets, color: Color(0xFFD84315), size: 30),
                const SizedBox(height: 6),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFBF360C),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
