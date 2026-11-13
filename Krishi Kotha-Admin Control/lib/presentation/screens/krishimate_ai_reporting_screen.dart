import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/constants/admin_colors.dart';
import '../../core/responsive/responsive_layout.dart';
import '../widgets/admin_stat_card.dart';
import '../widgets/admin_loading_indicator.dart';

class KrishiMateAiReportingScreen extends StatefulWidget {
  const KrishiMateAiReportingScreen({super.key});

  @override
  State<KrishiMateAiReportingScreen> createState() => _KrishiMateAiReportingScreenState();
}

class _KrishiMateAiReportingScreenState extends State<KrishiMateAiReportingScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  late final Stream<QuerySnapshot> _prescriptionsStream;

  @override
  void initState() {
    super.initState();
    _prescriptionsStream = FirebaseFirestore.instance
        .collection('disease_prescriptions')
        .orderBy('created_at', descending: true)
        .snapshots();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _toBanglaNumber(int number) {
    const banglaDigits = ['০', '১', '২', '৩', '৪', '৫', '৬', '৭', '৮', '৯'];
    final s = number.toString();
    final buffer = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      final ch = s[i];
      final digit = int.tryParse(ch);
      if (digit != null) {
        buffer.write(banglaDigits[digit]);
      } else {
        buffer.write(ch);
      }
    }
    return buffer.toString();
  }

  String _formatDateTime(dynamic timestamp) {
    if (timestamp == null) return 'অজ্ঞাত সময়';
    DateTime dt;
    if (timestamp is Timestamp) {
      dt = timestamp.toDate();
    } else if (timestamp is String) {
      dt = DateTime.tryParse(timestamp) ?? DateTime.now();
    } else {
      return 'অজ্ঞাত সময়';
    }

    final datePart = DateFormat('dd MMM yyyy, hh:mm a').format(dt);
    return datePart;
  }

  bool _isCreatedToday(dynamic timestamp) {
    if (timestamp == null) return false;
    DateTime dt;
    if (timestamp is Timestamp) {
      dt = timestamp.toDate();
    } else if (timestamp is String) {
      final parsed = DateTime.tryParse(timestamp);
      if (parsed == null) return false;
      dt = parsed;
    } else {
      return false;
    }

    final now = DateTime.now();
    final startOfToday = DateTime(now.year, now.month, now.day, 0, 0, 0);
    return dt.isAfter(startOfToday);
  }

  void _openDetailDialog(BuildContext context, Map<String, dynamic> data) {
    final plantName = data['plant_name']?.toString() ?? 'অজ্ঞাত ফসল';
    final diseaseName = data['disease_name']?.toString() ?? 'অজ্ঞাত রোগ';
    final userQuery = data['user_query']?.toString() ?? data['user_symptoms']?.toString() ?? 'কোনো লক্ষণ উল্লেখ নেই';
    final imageUrl = data['image_url']?.toString() ?? data['user_image_thumb']?.toString();
    final confidence = data['confidence']?.toString() ?? '${data['confidence_percentage'] ?? 0}%';
    final isDeletedByUser = data['isDeletedByUser'] == true;
    final userPhone = data['user_phone']?.toString() ?? 'গেস্ট ইউজার';
    final userName = data['user_name']?.toString();
    final timeStr = _formatDateTime(data['created_at']);

    List<String> getList(String key) {
      final raw = data[key];
      if (raw is List) {
        return raw.map((e) => e.toString()).toList();
      }
      return [];
    }

    final causes = getList('causes_and_symptoms');
    final organic = getList('organic_cures');
    final precautions = getList('precaution_and_care');
    final chemicalRaw = data['chemical_cures'];

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          width: 720,
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.88,
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AdminColors.primaryContainer,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.smart_toy_rounded, color: AdminColors.primary, size: 24),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'KrishiMate AI প্রেসক্রিপশন বিস্তারিত',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AdminColors.textPrimary),
                          ),
                          Text(
                            timeStr,
                            style: const TextStyle(fontSize: 12, color: AdminColors.textMuted),
                          ),
                        ],
                      ),
                    ],
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(ctx),
                    icon: const Icon(Icons.close_rounded, color: AdminColors.textMuted),
                  ),
                ],
              ),
              const Divider(height: 24),

              // Scrollable Body
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // User & Status Banner
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: isDeletedByUser ? const Color(0xFFFFEBEE) : const Color(0xFFE8F5E9),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isDeletedByUser ? const Color(0xFFFFCDD2) : const Color(0xFFC8E6C9),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              isDeletedByUser ? Icons.delete_outline_rounded : Icons.check_circle_rounded,
                              color: isDeletedByUser ? const Color(0xFFD32F2F) : const Color(0xFF2E7D32),
                              size: 22,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'ব্যবহারকারী: ${userName?.isNotEmpty == true ? "$userName ($userPhone)" : userPhone}',
                                    style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: AdminColors.textPrimary),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    isDeletedByUser
                                        ? 'স্ট্যাটাস: ব্যবহারকারী কর্তৃক ডিলিটকৃত (ইউজার অ্যাপে লুকানো, সেন্ট্রাল ক্লাউড ব্যাকআপ সক্রিয়)'
                                        : 'স্ট্যাটাস: সক্রিয় (ব্যবহারকারীর হিস্ট্রিতে দৃশ্যমান)',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: isDeletedByUser ? const Color(0xFFC62828) : const Color(0xFF1B5E20),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Crop & Disease Summary Card
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F8E9),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFA5D6A7)),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF2E7D32),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          plantName,
                                          style: const TextStyle(fontSize: 13, color: Colors.white, fontWeight: FontWeight.w700),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(color: const Color(0xFF2E7D32)),
                                        ),
                                        child: Text(
                                          'নির্ভুলতা: $confidence',
                                          style: const TextStyle(fontSize: 12, color: Color(0xFF2E7D32), fontWeight: FontWeight.w700),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    diseaseName,
                                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF1B5E20)),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // User Query / Symptoms
                      const Text(
                        'কৃষকের জিজ্ঞাসা / লক্ষণসমূহ:',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AdminColors.textPrimary),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8F9FA),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AdminColors.border),
                        ),
                        child: Text(
                          userQuery,
                          style: const TextStyle(fontSize: 13.5, color: Color(0xFF37474F), height: 1.4),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Cloudflare R2 Uploaded Plant Image
                      if (imageUrl != null && imageUrl.isNotEmpty) ...[
                        const Text(
                          'ক্লাউডফ্লেয়ার R2-তে সংরক্ষিত আক্রান্ত উদ্ভিদের ছবি:',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AdminColors.textPrimary),
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            decoration: BoxDecoration(
                              border: Border.all(color: AdminColors.border),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Image.network(
                              imageUrl,
                              height: 240,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => Container(
                                height: 120,
                                color: Colors.grey.shade100,
                                alignment: Alignment.center,
                                child: const Text('ছবি লোড করা সম্ভব হয়নি', style: TextStyle(color: Colors.grey)),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Causes and Symptoms
                      if (causes.isNotEmpty) ...[
                        const Text(
                          'রোগের কারণ ও লক্ষণসমূহ:',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AdminColors.textPrimary),
                        ),
                        const SizedBox(height: 6),
                        ...causes.map((c) => Padding(
                              padding: const EdgeInsets.only(bottom: 6),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('• ', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AdminColors.primary)),
                                  Expanded(child: Text(c, style: const TextStyle(fontSize: 13, height: 1.4))),
                                ],
                              ),
                            )),
                        const SizedBox(height: 14),
                      ],

                      // Organic Cures
                      if (organic.isNotEmpty) ...[
                        const Text(
                          'জৈব ও প্রাকৃতিক প্রতিকার:',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF2E7D32)),
                        ),
                        const SizedBox(height: 6),
                        ...organic.map((o) => Padding(
                              padding: const EdgeInsets.only(bottom: 6),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(Icons.eco_rounded, size: 16, color: Color(0xFF2E7D32)),
                                  const SizedBox(width: 6),
                                  Expanded(child: Text(o, style: const TextStyle(fontSize: 13, height: 1.4))),
                                ],
                              ),
                            )),
                        const SizedBox(height: 14),
                      ],

                      // Chemical Cures
                      if (chemicalRaw is List && chemicalRaw.isNotEmpty) ...[
                        const Text(
                          'রাসায়নিক সমাধান ও সঠিক মাত্রা:',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFFC62828)),
                        ),
                        const SizedBox(height: 6),
                        ...chemicalRaw.map((chem) {
                          if (chem is Map) {
                            final name = chem['name']?.toString() ?? '';
                            final dosage = chem['dosage']?.toString() ?? '';
                            final instruction = chem['instruction']?.toString() ?? '';
                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFF3E0),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: const Color(0xFFFFCC80)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFFE65100))),
                                  if (dosage.isNotEmpty) Text('মাত্রা: $dosage', style: const TextStyle(fontSize: 12.5, color: Color(0xFF5D4037))),
                                  if (instruction.isNotEmpty) Text('প্রয়োগ: $instruction', style: const TextStyle(fontSize: 12, color: Color(0xFF757575))),
                                ],
                              ),
                            );
                          }
                          return Text('• ${chem.toString()}');
                        }),
                        const SizedBox(height: 14),
                      ],

                      // Precaution & Care
                      if (precautions.isNotEmpty) ...[
                        const Text(
                          'সতর্কতা ও ভবিষ্যত যত্ন:',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AdminColors.textPrimary),
                        ),
                        const SizedBox(height: 6),
                        ...precautions.map((p) => Padding(
                              padding: const EdgeInsets.only(bottom: 6),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(Icons.shield_outlined, size: 16, color: AdminColors.primary),
                                  const SizedBox(width: 6),
                                  Expanded(child: Text(p, style: const TextStyle(fontSize: 13, height: 1.4))),
                                ],
                              ),
                            )),
                      ],
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AdminColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                  child: const Text('বন্ধ করুন', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveLayout.isMobile(context);

    return StreamBuilder<QuerySnapshot>(
      stream: _prescriptionsStream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          // Fallback without orderBy if Firestore index is required
          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('disease_prescriptions').snapshots(),
            builder: (ctx, fallbackSnap) {
              if (fallbackSnap.connectionState == ConnectionState.waiting && !fallbackSnap.hasData) {
                return const AdminLoadingIndicator(message: 'তথ্য লোডিং হচ্ছে.....');
              }
              return _buildContent(fallbackSnap.data?.docs ?? [], isMobile);
            },
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
          return const AdminLoadingIndicator(message: 'তথ্য লোডিং হচ্ছে.....');
        }

        final docs = snapshot.data?.docs ?? [];
        return _buildContent(docs, isMobile);
      },
    );
  }

  Widget _buildContent(List<QueryDocumentSnapshot> rawDocs, bool isMobile) {
    // 1. Process documents into Maps
    final allList = rawDocs.map((doc) {
      final map = doc.data() as Map<String, dynamic>;
      map['doc_id'] = doc.id;
      return map;
    }).toList();

    // 2. Calculate Today's Successful Questions Metric
    // Counting logic: today (since 00:00:00), successful agricultural questions (exclude non-agri / invalid plant)
    final todaySuccessList = allList.where((item) {
      final isNonAgri = item['is_non_agri'] == true || item['isNonAgri'] == true;
      final isNotPlant = item['is_not_plant_image'] == true || item['isNotPlantImage'] == true;
      if (isNonAgri || isNotPlant) return false;
      return _isCreatedToday(item['created_at']);
    }).toList();

    final todaySuccessCount = todaySuccessList.length;
    final totalConsultations = allList.length;
    final deletedCount = allList.where((item) => item['isDeletedByUser'] == true).length;
    final activeCount = totalConsultations - deletedCount;

    // 3. Search Filtering (Mobile or Email)
    final filteredList = allList.where((item) {
      if (_searchQuery.isEmpty) return true;
      final q = _searchQuery.toLowerCase().trim();
      final phone = (item['user_phone'] ?? '').toString().toLowerCase();
      final email = (item['user_email'] ?? '').toString().toLowerCase();
      final name = (item['user_name'] ?? '').toString().toLowerCase();
      final crop = (item['plant_name'] ?? '').toString().toLowerCase();
      return phone.contains(q) || email.contains(q) || name.contains(q) || crop.contains(q);
    }).toList();

    return SingleChildScrollView(
      padding: EdgeInsets.all(isMobile ? 16 : 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Banner
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1B5E20), Color(0xFF2E7D32)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'KrishiMate AI রোগ শনাক্তকরণ ড্যাশবোর্ড',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'কৃষকদের আপলোডকৃত উদ্ভিদের রোগ নির্ণয়, ক্লাউড প্রেসক্রিপশন ও হিস্ট্রি ব্যবহারের রিয়েল-টাইম তদারকি ও রিপোর্টিং।',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                if (!isMobile)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.smart_toy_rounded, color: Colors.white, size: 36),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Top Metric Cards Grid
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 900;
              final crossAxisCount = isWide ? 4 : (constraints.maxWidth > 600 ? 2 : 1);

              return GridView.count(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                childAspectRatio: isWide ? 1.6 : 2.0,
                children: [
                  // ৩. আজকের সফল প্রশ্ন মেট্রিক কার্ড (Today's Total Success Metric)
                  AdminStatCard(
                    title: 'আজকের সফল প্রশ্ন',
                    value: '${_toBanglaNumber(todaySuccessCount)} টি',
                    icon: Icons.task_alt_rounded,
                    iconBgColor: const Color(0xFFE8F5E9),
                    iconColor: const Color(0xFF2E7D32),
                    subtitle: 'আজ রাত ১২:০০ টা থেকে এআই সফল সমাধান',
                    subtitleColor: const Color(0xFF2E7D32),
                  ),
                  AdminStatCard(
                    title: 'মোট প্রেসক্রিপশন',
                    value: '${_toBanglaNumber(totalConsultations)} টি',
                    icon: Icons.psychology_rounded,
                    iconBgColor: AdminColors.primaryContainer,
                    iconColor: AdminColors.primary,
                    subtitle: 'সর্বমোট এগ্রো প্যাথোলজি কিউরি',
                  ),
                  AdminStatCard(
                    title: 'সক্রিয় প্রেসক্রিপশন',
                    value: '${_toBanglaNumber(activeCount)} টি',
                    icon: Icons.eco_rounded,
                    iconBgColor: const Color(0xFFE0F2F1),
                    iconColor: const Color(0xFF00796B),
                    subtitle: 'ব্যবহারকারীদের সংরক্ষিত হিস্ট্রিতে বিদ্যমান',
                  ),
                  AdminStatCard(
                    title: 'ডিলিটকৃত হিস্ট্রি',
                    value: '${_toBanglaNumber(deletedCount)} টি',
                    icon: Icons.delete_outline_rounded,
                    iconBgColor: const Color(0xFFFFEBEE),
                    iconColor: const Color(0xFFC62828),
                    subtitle: 'ব্যবহারকারী অ্যাপ থেকে মুছে ফেলেছেন',
                    subtitleColor: const Color(0xFFC62828),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 28),

          // ৫. স্মার্ট ইউজার ফিল্টারিং ও সার্চ বার (Smart User Filtering & Search Bar)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AdminColors.border),
              boxShadow: const [
                BoxShadow(color: AdminColors.cardShadow, blurRadius: 10, offset: Offset(0, 4)),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    onChanged: (val) {
                      setState(() => _searchQuery = val);
                    },
                    decoration: InputDecoration(
                      hintText: 'ব্যবহারকারীর মোবাইল নম্বর বা ইমেইল দিয়ে খুঁজুন...',
                      hintStyle: const TextStyle(fontSize: 13.5, color: AdminColors.textMuted),
                      prefixIcon: const Icon(Icons.search_rounded, color: AdminColors.primary),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AdminColors.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AdminColors.border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AdminColors.primary, width: 1.5),
                      ),
                      filled: true,
                      fillColor: const Color(0xFFF9FBF9),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                  },
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: const Text('রিসেট', style: TextStyle(fontWeight: FontWeight.w700)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AdminColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // ৪. সম্পূর্ণ প্রশ্নোত্তর তালিকা ও ডেটা-টেবিল (Full Questions & Answers List)
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
                    Row(
                      children: [
                        const Text(
                          'KrishiMate AI হিস্ট্রি ও প্রেসক্রিপশন লগ',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AdminColors.textPrimary),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AdminColors.primaryContainer,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'মোট: ${_toBanglaNumber(filteredList.length)} টি',
                            style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: AdminColors.primary),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                if (filteredList.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 40),
                    alignment: Alignment.center,
                    child: Column(
                      children: [
                        const Icon(Icons.search_off_rounded, size: 48, color: AdminColors.textMuted),
                        const SizedBox(height: 10),
                        Text(
                          _searchQuery.isNotEmpty ? 'এই নম্বরে কোনো হিস্ট্রি পাওয়া যায়নি' : 'এখনও কোনো প্রেসক্রিপশন হিস্ট্রি রেকর্ড নেই',
                          style: const TextStyle(fontSize: 14, color: AdminColors.textMuted, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  )
                else
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      headingRowColor: WidgetStateProperty.all(const Color(0xFFF1F8E9)),
                      dataRowMinHeight: 56,
                      dataRowMaxHeight: 64,
                      columnSpacing: 24,
                      columns: const [
                        DataColumn(label: Text('তারিখ ও সময়', style: TextStyle(fontWeight: FontWeight.w700))),
                        DataColumn(label: Text('ব্যবহারকারীর তথ্য', style: TextStyle(fontWeight: FontWeight.w700))),
                        DataColumn(label: Text('ফসলের নাম', style: TextStyle(fontWeight: FontWeight.w700))),
                        DataColumn(label: Text('শনাক্তকৃত রোগ', style: TextStyle(fontWeight: FontWeight.w700))),
                        DataColumn(label: Text('স্ট্যাটাস ব্যাজ', style: TextStyle(fontWeight: FontWeight.w700))),
                        DataColumn(label: Text('অ্যাকশন', style: TextStyle(fontWeight: FontWeight.w700))),
                      ],
                      rows: filteredList.map((item) {
                        final isDeleted = item['isDeletedByUser'] == true;
                        final plant = item['plant_name']?.toString() ?? 'অজ্ঞাত ফসল';
                        final disease = item['disease_name']?.toString() ?? 'অজ্ঞাত রোগ';
                        final phone = item['user_phone']?.toString() ?? 'গেস্ট ইউজার';
                        final email = item['user_email']?.toString() ?? '';
                        final time = _formatDateTime(item['created_at']);

                        return DataRow(
                          cells: [
                            DataCell(Text(time, style: const TextStyle(fontSize: 12.5, color: AdminColors.textPrimary))),
                            DataCell(
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    phone,
                                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AdminColors.textPrimary),
                                  ),
                                  if (email.isNotEmpty)
                                    Text(
                                      email,
                                      style: const TextStyle(fontSize: 11, color: AdminColors.textMuted),
                                    ),
                                ],
                              ),
                            ),
                            DataCell(
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE8F5E9),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: const Color(0xFFA5D6A7)),
                                ),
                                child: Text(
                                  plant,
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF1B5E20)),
                                ),
                              ),
                            ),
                            DataCell(
                              ConstrainedBox(
                                constraints: const BoxConstraints(maxWidth: 220),
                                child: Text(
                                  disease,
                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AdminColors.textPrimary),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                            DataCell(
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: isDeleted ? const Color(0xFFFFEBEE) : const Color(0xFFE8F5E9),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: isDeleted ? const Color(0xFFFFCDD2) : const Color(0xFFA5D6A7),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 6,
                                      height: 6,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: isDeleted ? const Color(0xFFD32F2F) : const Color(0xFF2E7D32),
                                      ),
                                    ),
                                    const SizedBox(width: 5),
                                    Text(
                                      isDeleted ? 'ব্যবহারকারী কর্তৃক ডিলিটকৃত' : 'সক্রিয়',
                                      style: TextStyle(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w700,
                                        color: isDeleted ? const Color(0xFFC62828) : const Color(0xFF1B5E20),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            DataCell(
                              ElevatedButton(
                                onPressed: () => _openDetailDialog(context, item),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF2E7D32),
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.visibility_outlined, size: 14),
                                    SizedBox(width: 4),
                                    Text('বিস্তারিত দেখুন', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700)),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

