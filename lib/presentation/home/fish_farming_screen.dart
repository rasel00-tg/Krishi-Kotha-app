import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import '../../core/constants/app_colors.dart';
import '../../core/widgets/premium_loading_widget.dart';
import '../../global_popup/global_popup.dart';

class FishFarmingScreen extends StatefulWidget {
  final String? initialCategory;

  const FishFarmingScreen({super.key, this.initialCategory});

  @override
  State<FishFarmingScreen> createState() => _FishFarmingScreenState();
}

class _FishFarmingScreenState extends State<FishFarmingScreen> {
  late String _selectedCategory;

  final List<String> _baseCategories = [
    'সব',
    'কার্প ও রুই জাতীয়',
    'তেলাপিয়া ও পাঙ্গাস',
    'শিং-মাগুর ও পাবদা',
    'চিংড়ি চাষ',
    'পুকুর ও পানি ব্যবস্থাপনা',
    'মাছের রোগ ও প্রতিকার',
  ];

  final Map<String, String> _categorySubtitleMap = {
    'কার্প ও রুই জাতীয়': 'রুই, কাতলা, মৃগেল ও কার্প মিশ্র চাষ পদ্ধতি ও পোনা মজুদ',
    'তেলাপিয়া ও পাঙ্গাস': 'মনোসেক্স তেলাপিয়া ও থাই পাঙ্গাস চাষ এবং নিবিড় ব্যবস্থাপনা',
    'শিং-মাগুর ও পাবদা': 'উচ্চমূল্যের দেশি শিং, মাগুর ও পাবদা চাষের আধুনিক কৌশল',
    'চিংড়ি চাষ': 'গলদা ও বাগদা চিংড়ির লাভজনক চাষ, ঘের প্রস্তুতি ও খাদ্য',
    'পুকুর ও পানি ব্যবস্থাপনা': 'পুকুর প্রস্তুতি, চুন-সার প্রয়োগ ও পানির গুণাগুণ নিয়ন্ত্রণ',
    'মাছের রোগ ও প্রতিকার': 'ফুলকা পচা, ঘা রোগ ও শীতকালীন মড়ক প্রতিরোধ নির্দেশিকা',
  };

  late final Stream<QuerySnapshot<Map<String, dynamic>>> _fishStream;

  // Fallback high-quality initial data if Firestore collection is fresh
  static const List<Map<String, dynamic>> _defaultFishData = [
    {
      'id': 'fish_1',
      'title': 'রুই, কাতলা ও মৃগেল মাছের মিশ্র চাষ পদ্ধতি',
      'category': 'কার্প ও রুই জাতীয়',
      'species': 'দেশি রুই, কাতলা ও মৃগেল কার্প',
      'highlights': 'পুকুরের সকল স্তরের খাদ্য ব্যবহার করে সর্বোচ্চ ফলন নিশ্চিত করে',
      'description': 'মিশ্র চাষে পুকুরের ওপরের স্তরের জন্য কাতলা ও সিলভার কার্প, মধ্য স্তরের জন্য রুই এবং তলদেশের জন্য মৃগেল ও কার্পিও মজুদ করা হয়। শতাংশ প্রতি ৩৫-৪০টি পোনা ছাড়া আদর্শ। নিয়মিত প্রাকৃতিক খাদ্যের উপস্থিতি পরীক্ষা করতে হবে।',
      'tips': 'পুকুর তৈরির সময় শতাংশে ১ কেজি চুন প্রয়োগ করুন। পোনা মজুদের পর খৈল, কুঁড়ো ও ফিশমিল দিয়ে তৈরি সম্পূরক খাদ্য দৈনিক মাছের মোট ওজনের ৩-৫% হারে দিন।',
      'imageUrl': 'https://images.unsplash.com/photo-1524704654690-b56c05c78a00?auto=format&fit=crop&w=800&q=80',
    },
    {
      'id': 'fish_2',
      'title': 'উন্নত জাতের মনোসেক্স তেলাপিয়া চাষ নির্দেশিকা',
      'category': 'তেলাপিয়া ও পাঙ্গাস',
      'species': 'মনোসেক্স গিফট তেলাপিয়া (GIFT)',
      'highlights': 'মাত্র ৪-৫ মাসে প্রতিটি মাছের ওজন ৪০০-৫০০ গ্রাম হয়',
      'description': 'মনোসেক্স তেলাপিয়া দ্রুত বাড়ে এবং প্রজননজনিত অতিরিক্ত পোনা উৎপাদনে পুষ্টি অপচয় হয় না। পুকুর ছাড়াও বায়োফ্লক ও খাঁচায় সফলভাবে চাষ করা যায়। পানির দ্রবীভূত অক্সিজেন ৫ পিপিএমের ওপরে রাখতে হবে।',
      'tips': 'শতাংশে ২০০-২৫০টি পোনা মজুদ করা যায়। দিনে দুইবার ৩০% আমিষযুক্ত বাণিজ্যিক ভাসমান ফিড সরবরাহ করতে হবে। অ্যামোনিয়া নিয়ন্ত্রণে প্রোবায়োটিক ব্যবহার ফলপ্রসূ।',
      'imageUrl': 'https://images.unsplash.com/photo-1544551763-46a013bb70d5?auto=format&fit=crop&w=800&q=80',
    },
    {
      'id': 'fish_3',
      'title': 'আধুনিক পদ্ধতিতে শিং ও মাগুর মাছ চাষ',
      'category': 'শিং-মাগুর ও পাবদা',
      'species': 'দেশি শিং ও আফ্রিকান/দেশি মাগুর',
      'highlights': 'স্বল্প গভীরতার পুকুর ও চৌবাচ্চায় অধিক ঘনত্বে চাষযোগ্য',
      'description': 'শিং ও মাগুর বায়ুশ্বাসী মাছ হওয়ায় অল্প অক্সিজেনেও বেঁচে থাকে। পুকুরের পাড় দিয়ে জাল দিয়ে বেড়া দেওয়া জরুরি যাতে বৃষ্টির দিনে মাছ উঠে যেতে না পারে। তলার কাদা পরিষ্কার রাখা আবশ্যক।',
      'tips': 'শতাংশে ৪০০-৫০০টি আঙুল সাইজের সুস্থ পোনা মজুদ করুন। রাতে খাবার গ্রহণের প্রবণতা বেশি থাকায় সন্ধ্যায় দানাদার খাদ্য দিন। ফুলকা ও শরীরে ছত্রাক রোধে পটাশ দিন।',
      'imageUrl': 'https://images.unsplash.com/photo-1535591273668-578e31182c4f?auto=format&fit=crop&w=800&q=80',
    },
    {
      'id': 'fish_4',
      'title': 'গলদা ও বাগদা চিংড়ি চাষ ও ঘের প্রস্তুতি',
      'category': 'চিংড়ি চাষ',
      'species': 'গলদা (মিঠা পানি) ও বাগদা (লোনা পানি)',
      'highlights': 'উচ্চ আন্তর্জাতিক রফতানি মূল্য ও অধিক মুনাফাজনক',
      'description': 'চিংড়ি চাষের জন্য তলদেশের স্বাস্থ্য সুরক্ষা সবচেয়ে গুরুত্বপূর্ণ। ঘেরের পানি প্রবেশ ও নিষ্কাশন ব্যবস্থা পৃথক হতে হবে। পানির লবণাক্ততা ও অ্যালকালিনিটি নিয়মিত পরীক্ষা করতে হয়।',
      'tips': 'পোনা ছাড়ার আগে ঘেরে শেল্টার (আশ্রয়স্থল) তৈরি করে দিতে হবে যাতে খোলস বদলের সময় অন্য চিংড়ি ক্ষতি না করে। উচ্চ প্রোটিনযুক্ত চিংড়ির বিশেষ পিলেট খাদ্য দিন।',
      'imageUrl': 'https://images.unsplash.com/photo-1565680018434-b513d5e5fd47?auto=format&fit=crop&w=800&q=80',
    },
    {
      'id': 'fish_5',
      'title': 'পাবদা মাছের নিবিড় ও আধা-নিবিড় চাষ পদ্ধতি',
      'category': 'শিং-মাগুর ও পাবদা',
      'species': 'দেশি পাবদা (Ompok pabda)',
      'highlights': 'সুস্বাদু কাটা কম মাছ, বাজারে ব্যাপক চাহিদা ও প্রিমিয়াম মূল্য',
      'description': 'পাবদা মাছ অত্যন্ত নরম প্রকৃতির এবং খাদ্য নির্বাচনে সংবেদনশীল। পুকুরে পর্যাপ্ত প্রাকৃতিক খাদ্য জুপ্ল্যাঙ্কটন নিশ্চিত করতে হবে। পোনা মজুদের পর প্রথম মাসে ক্যানিবালিজম (একটি মাছ আরেকটিকে খাওয়া) রোধে নিয়মিত খাবার দিতে হবে।',
      'tips': 'শতাংশে ২০০-২৫০টি পোনা দেওয়া যায়। প্রোটিন সমৃদ্ধ ভাসমান ও ডুবন্ত ফিডের সমন্বয় রাখুন। প্রতি মাসে পানির ২৫% পরিবর্তন করলে বৃদ্ধি ত্বরান্বিত হয়।',
      'imageUrl': 'https://images.unsplash.com/photo-1576836165612-8bc9b07e7778?auto=format&fit=crop&w=800&q=80',
    },
    {
      'id': 'fish_6',
      'title': 'মাছ চাষের পুকুর প্রস্তুতি ও চুন-সার প্রয়োগ গাইড',
      'category': 'পুকুর ও পানি ব্যবস্থাপনা',
      'species': 'সকল ধরনের মাছের পুকুর',
      'highlights': 'সঠিক প্রস্তুতি মাছের রোগবালাই ৮০% কমিয়ে দেয়',
      'description': 'পুরোনো পুকুরের তলার পচা কাদা তুলে ফেলে শতাংশে ১-২ কেজি চুন ছিটিয়ে রোদ খাওয়াতে হবে। এরপর জলজ বিষমুক্ত পানি ঢুকিয়ে শতাংশে ইউরিয়া ১০০ গ্রাম ও টিএসপি ১০০ গ্রাম দিলে প্ল্যাঙ্কটন জন্মায়।',
      'tips': 'পানির রং হালকা সবুজ বা বাদামি হলে বুঝতে হবে পোনা ছাড়ার উপযোগী হয়েছে। পানির স্বচ্ছতা সেচি ডিস্ক দিয়ে ২৫-৩০ সেন্টিমিটারের মধ্যে রাখা উচিত।',
      'imageUrl': 'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?auto=format&fit=crop&w=800&q=80',
    },
    {
      'id': 'fish_7',
      'title': 'মাছের ঘা রোগ ও লেজ-পাখনা পচা রোগের প্রতিকার',
      'category': 'মাছের রোগ ও প্রতিকার',
      'species': 'রুই, কার্প, শিং ও পাঙ্গাস',
      'highlights': 'শরীরে লাল দাগ, ক্ষত ও খসখসে ভাব দেখা দিলে দ্রুত ব্যবস্থা নিন',
      'description': 'শীতের শুরুতে ব্যাকটেরিয়া ও পরজীবী আক্রমণে মাছের ক্ষত রোগ (EUS) দেখা দেয়। আক্রান্ত মাছ পানির ওপরে খাবি খায় ও খাওয়া বন্ধ করে দেয়। পুকুরে অতিরিক্ত কাদা থাকলে রোগের তীব্রতা বাড়ে।',
      'tips': 'শতাংশে প্রতি ফুট পানির জন্য ২৫০ গ্রাম চুন ও ২৫০ গ্রাম লবণ একসাথে গুলে ছিটিয়ে দিন। তীব্র আক্রমণে প্রতি শতাংশে ১-২ গ্রাম পটাশিয়াম পারম্যাঙ্গানেট প্রয়োগ করুন।',
      'imageUrl': 'https://images.unsplash.com/photo-1518837695005-2083093ee35b?auto=format&fit=crop&w=800&q=80',
    },
    {
      'id': 'fish_8',
      'title': 'শীতকালীন মাছের বিশেষ যত্ন ও খাদ্য ব্যবস্থাপনা',
      'category': 'পুকুর ও পানি ব্যবস্থাপনা',
      'species': 'পুকুরের সকল চাষযোগ্য মাছ',
      'highlights': 'তাপমাত্রা কমলে মাছের বিপাক ক্রিয়া ও খাদ্য গ্রহণ কমে যায়',
      'description': 'শীতকালে পানির তাপমাত্রা ১৮ ডিগ্রির নিচে নামলে খাদ্যের পরিমাণ অর্ধেক করে দিতে হবে। অতিরিক্ত খাবার পানির তলায় পচে অ্যামোনিয়া গ্যাস সৃষ্টি করে মাছের মৃত্যু ডেকে আনতে পারে।',
      'tips': 'সপ্তাহে অন্তত একদিন সকালে পুকুরে নতুন গভীর নলকূপের হালকা গরম পানি সরবরাহ করুন। সকালের দিকে জাল টেনে গ্যাস বের করে দেওয়া অত্যন্ত উপকারী।',
      'imageUrl': 'https://images.unsplash.com/photo-1498084393756-2383789bd031?auto=format&fit=crop&w=800&q=80',
    },
  ];

  @override
  void initState() {
    super.initState();
    // Read Optimization: Initialize stream once in initState with reasonable limit
    _fishStream = FirebaseFirestore.instance
        .collection('fish_farming')
        .limit(50)
        .snapshots();
    _selectedCategory = widget.initialCategory ?? 'সব';
  }

  /// Cloudflare R2 সহ যে কোনো ছবির URL নরমালাইজ করার নিরাপদ মেথড
  String _normalizeFishImageUrl(Map<String, dynamic> item) {
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

  void _showFishDetailModal(BuildContext context, Map<String, dynamic> data) {
    final title = (data['title'] ?? data['name'] ?? 'মৎস চাষের তথ্য').toString();
    final category = (data['category'] ?? 'অন্যান্য').toString();
    final species = (data['species'] ?? data['breed'] ?? data['type'] ?? 'উল্লেখ নেই').toString();
    final highlights = (data['highlights'] ?? 'জরুরি লক্ষণ বা বৈশিষ্ট্য').toString();
    final description = (data['description'] ?? 'বিস্তারিত তথ্য শীঘ্রই যুক্ত হবে।').toString();
    final tips = (data['tips'] ?? data['feedInfo'] ?? data['pondCare'] ?? 'সঠিক খাদ্য ও নিয়মিত পুকুর পরিচর্যা নিশ্চিত করুন।').toString();
    final imageUrl = _normalizeFishImageUrl(data);

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
                      debugPrint('Fish Detail Image Error: $errUrl');
                      return const SizedBox.shrink();
                    },
                  ),
                ),
                const SizedBox(height: 14),
              ],

              // ক্যাটাগরি ও প্রজাতি ব্যাজ
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE0F7FA),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFB2EBF2)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.set_meal_rounded, size: 13, color: Color(0xFF00838F)),
                        const SizedBox(width: 5),
                        Text(
                          category,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF00838F),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (species != 'উল্লেখ নেই' && species.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE0F2F1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFB2DFDB)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.category_rounded, size: 13, color: Color(0xFF004D40)),
                          const SizedBox(width: 5),
                          Text(
                            species,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF004D40),
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
                    color: const Color(0xFFE0F7FA),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF80DEEA)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.star_rounded, size: 18, color: Color(0xFF00838F)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          highlights,
                          style: const TextStyle(
                            fontSize: 12.5,
                            color: Color(0xFF006064),
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

              // বিস্তারিত পুকুর প্রস্তুতি ও চাষ ব্যবস্থাপনা
              _buildModalSectionHeader('পুকুর প্রস্তুতি ও চাষ ব্যবস্থাপনা', Icons.water_drop_rounded, const Color(0xFF006064)),
              const SizedBox(height: 5),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF9FDFD),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE0F2F1)),
                ),
                child: Text(
                  description,
                  style: const TextStyle(fontSize: 13, color: Color(0xFF263238), height: 1.5),
                ),
              ),
              const SizedBox(height: 14),

              // খাদ্য ও রোগ প্রতিকার টিপস
              if (tips.isNotEmpty && tips != 'উল্লেখ নেই') ...[
                _buildModalSectionHeader('খাদ্য তালিকা ও রোগ প্রতিকার টিপস', Icons.health_and_safety_rounded, const Color(0xFF00838F)),
                const SizedBox(height: 5),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFC8E6C9)),
                  ),
                  child: Text(
                    tips,
                    style: const TextStyle(fontSize: 12.5, color: Color(0xFF1B5E20), height: 1.5, fontWeight: FontWeight.w500),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // বন্ধ করুন বোতাম
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00838F),
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
      backgroundColor: const Color(0xFFF7FCFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFF00838F),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 19),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          children: [
            const Text(
              'মৎস চাষ',
              style: TextStyle(
                color: Colors.white,
                fontSize: 17.5,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'আধুনিক পদ্ধতিতে মাছ চাষ, পুকুর ব্যবস্থাপনা ও রোগবালাই প্রতিকার',
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
          stream: _fishStream,
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
                        colors: [Color(0xFFE0F7FA), Color(0xFFE0F2F1)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFB2EBF2)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: const Color(0xFF00838F),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.set_meal_rounded, color: Colors.white, size: 18),
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
                                  color: Color(0xFF006064),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _categorySubtitleMap[_selectedCategory] ??
                                    'এই ক্যাটাগরির উন্নত জাত, পুকুর প্রস্তুতি ও রোগ ব্যবস্থাপনা তথ্য নিচে প্রদর্শিত হচ্ছে',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.blueGrey.shade700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                // ৩. মাছ চাষের কার্ড তালিকা (নো সার্চ বার, নো বিস্তারিত বাটন, ছবিতে ক্লিকে পপআপ)
                Expanded(
                  child: _buildFishList(snapshot),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  /// চাষ ক্যালেন্ডার ও মাটির স্বাস্থ্য পেইজের হুবহু ডিজাইনে স্টাইলিশ টপবার
  Widget _buildColoredTopBar(List<String> categories) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF00838F), Color(0xFF006064)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x3300838F),
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
                      color: isSelected ? const Color(0xFF00838F) : Colors.white,
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

  /// মাছ চাষের কার্ড তালিকা বিল্ডার
  Widget _buildFishList(AsyncSnapshot<QuerySnapshot<Map<String, dynamic>>> snapshot) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return const Center(
        child: PremiumLoadingWidget(
          title: 'মৎস চাষের তথ্য লোড হচ্ছে...',
          subtitle: 'অনুগ্রহ করে অপেক্ষা করুন',
        ),
      );
    }

    // ফায়ারস্টোর ডেটা
    final firestoreDocs = snapshot.data?.docs ?? [];
    List<Map<String, dynamic>> items = [];

    if (firestoreDocs.isNotEmpty) {
      items = firestoreDocs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } else {
      // ফায়ারস্টোর ফাঁকা থাকলে অফলাইন ফলব্যাক ডেটা
      items = List.from(_defaultFishData);
    }

    // ক্যাটাগরি ফিল্টারিং
    if (_selectedCategory != 'সব') {
      items = items.where((item) {
        final cat = (item['category'] ?? '').toString().toLowerCase();
        final title = (item['title'] ?? item['name'] ?? '').toString().toLowerCase();
        final target = _selectedCategory.toLowerCase();
        return cat.contains(target) || title.contains(target);
      }).toList();
    }

    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 65,
              height: 65,
              decoration: BoxDecoration(
                color: const Color(0xFFE0F7FA),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.set_meal_outlined, size: 30, color: Color(0xFF00838F)),
            ),
            const SizedBox(height: 12),
            const Text(
              'কোনো তথ্য পাওয়া যায়নি',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Color(0xFF263238),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'অন্য কোনো ক্যাটাগরি নির্বাচন করুন',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
            if (_selectedCategory != 'সব') ...[
              const SizedBox(height: 14),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00838F),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
                onPressed: () => setState(() => _selectedCategory = 'সব'),
                icon: const Icon(Icons.rotate_right_rounded, size: 16),
                label: const Text('সকল তথ্য দেখুন', style: TextStyle(fontSize: 12.5)),
              ),
            ],
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 30),
      physics: const BouncingScrollPhysics(),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return _buildFishCard(context, item);
      },
    );
  }

  /// কার্ড ডিজাইন: নো সার্চ বার, নো বিস্তারিত বাটন, ছবিতে ক্লিকে বিস্তারিত পপআপ
  Widget _buildFishCard(BuildContext context, Map<String, dynamic> item) {
    final title = (item['title'] ?? item['name'] ?? 'মাছের তথ্য').toString();
    final category = (item['category'] ?? 'অন্যান্য').toString();
    final species = (item['species'] ?? item['breed'] ?? item['type'] ?? '').toString();
    final highlights = (item['highlights'] ?? '').toString();
    final description = (item['description'] ?? '').toString();
    final imageUrl = _normalizeFishImageUrl(item);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE0F2F1), width: 1.2),
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
            onTap: () => _showFishDetailModal(context, item),
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

                // ক্যাটাগরি গ্লাস ব্যাজ (টপ-লেফট)
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xE6004D40),
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
                            color: Color(0xFF80DEEA),
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

                // প্রজাতি বা জাত ব্যাজ (টপ-রাইট)
                if (species.isNotEmpty && species != 'উল্লেখ নেই')
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xE600838F),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white.withOpacity(0.25)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.tag_rounded, size: 10, color: Color(0xFFE0F7FA)),
                          const SizedBox(width: 4),
                          Text(
                            species,
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
                  onTap: () => _showFishDetailModal(context, item),
                  child: Container(
                    padding: const EdgeInsets.only(left: 8),
                    decoration: const BoxDecoration(
                      border: Border(
                        left: BorderSide(color: Color(0xFF00838F), width: 3.5),
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
                      const Icon(Icons.check_circle_rounded, size: 14, color: Color(0xFF00838F)),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          highlights,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF006064),
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
          colors: [Color(0xFFE0F7FA), Color(0xFFB2EBF2)],
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
            child: const Icon(Icons.set_meal_rounded, size: 26, color: Color(0xFF00838F)),
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
                color: Color(0xFF006064),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
