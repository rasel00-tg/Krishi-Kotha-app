import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';

/// কৃষি কথা – বীজের তথ্যভান্ডার ও জাত পরিচিতি স্ক্রিন (ফুল পেজ স্ক্যাফোল্ড)
class SeedInformationPage extends StatefulWidget {
  const SeedInformationPage({super.key});

  @override
  State<SeedInformationPage> createState() => _SeedInformationPageState();
}

class _SeedInformationPageState extends State<SeedInformationPage> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';
  String _selectedCategory = 'সব';

  final List<String> _categories = [
    'সব',
    'ধান',
    'গম ও ভুট্টা',
    'সবজি',
    'মসলা',
    'ডাল ও তৈলবীজ',
    'ফলমূল',
    'অন্যান্য',
  ];

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(() {
      setState(() {
        _searchQuery = _searchCtrl.text.trim().toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F4),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1B5E20),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          children: [
            const Text(
              'বীজের তথ্যভান্ডার',
              style: TextStyle(
                color: Colors.white,
                fontSize: 17.5,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'উন্নত ও প্রত্যয়িত জাতের বীজ নির্দেশিকা',
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
            // ১. সার্চ ও ফিল্টার এরিয়া
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // সার্চ বার
                  Container(
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE0E8E1)),
                    ),
                    child: TextField(
                      controller: _searchCtrl,
                      decoration: InputDecoration(
                        hintText: 'বীজের নাম বা জাত দিয়ে খুঁজুন...',
                        hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade500),
                        prefixIcon: const Icon(Icons.search_rounded, size: 20, color: Color(0xFF2E7D32)),
                        suffixIcon: _searchCtrl.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.close_rounded, size: 18, color: Colors.grey),
                                onPressed: () => _searchCtrl.clear(),
                              )
                            : null,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  // ক্যাটাগরি চিপস
                  SizedBox(
                    height: 34,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _categories.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (context, index) {
                        final cat = _categories[index];
                        final isSelected = _selectedCategory == cat;
                        return InkWell(
                          onTap: () => setState(() => _selectedCategory = cat),
                          borderRadius: BorderRadius.circular(20),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                            decoration: BoxDecoration(
                              color: isSelected ? const Color(0xFF2E7D32) : const Color(0xFFF0F4F1),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isSelected ? const Color(0xFF1B5E20) : const Color(0xFFDCE5DD),
                                width: 1,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                cat,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                  color: isSelected ? Colors.white : const Color(0xFF333333),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),

            // ২. রিয়েল ফায়ারস্টোর ডেটা স্ট্রিমবিল্ডার
            Expanded(
              child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: FirebaseFirestore.instance.collection('seed_information').snapshots(),
                builder: (context, snapshot) {
                  // ২.১ লোডিং স্টেট: স্ক্রিন ফ্রিজ এড়াতে কোনো showDialog ছাড়াই সেন্টার উইজেট রেন্ডার
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 40),
                        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 26),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(22),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.08),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 62,
                              height: 62,
                              decoration: BoxDecoration(
                                color: const Color(0xFFE8F5E9),
                                shape: BoxShape.circle,
                                border: Border.all(color: const Color(0xFF81C784).withOpacity(0.4), width: 1.5),
                              ),
                              padding: const EdgeInsets.all(12),
                              child: Image.asset(
                                'assets/icons/pnglogo.png',
                                fit: BoxFit.contain,
                                errorBuilder: (_, __, ___) => const Icon(Icons.spa_rounded, color: Color(0xFF2E7D32), size: 30),
                              ),
                            ),
                            const SizedBox(height: 18),
                            const SizedBox(
                              width: 30,
                              height: 30,
                              child: CircularProgressIndicator(
                                strokeWidth: 3,
                                color: Color(0xFF2E7D32),
                              ),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'তথ্য লোডিং হচ্ছে...',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1B5E20),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'অনুগ্রহ করে কিছুক্ষণ অপেক্ষা করুন',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  // ২.২ এরর স্টেট
                  if (snapshot.hasError) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 48),
                            const SizedBox(height: 12),
                            const Text(
                              'তথ্য লোড করতে সমস্যা হয়েছে',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF333333)),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '${snapshot.error}',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  // ২.৩ ডেটা ফিল্টারিং
                  final allDocs = snapshot.data?.docs ?? [];
                  final filteredDocs = allDocs.where((doc) {
                    final data = doc.data();
                    final name = (data['seedName'] ?? '').toString().toLowerCase();
                    final cat = (data['category'] ?? '').toString();
                    final desc = (data['description'] ?? '').toString().toLowerCase();

                    // ক্যাটাগরি ফিল্টার
                    if (_selectedCategory != 'সব' && !cat.contains(_selectedCategory)) {
                      return false;
                    }

                    // সার্চ কুয়েরি ফিল্টার
                    if (_searchQuery.isNotEmpty && !name.contains(_searchQuery) && !desc.contains(_searchQuery)) {
                      return false;
                    }

                    return true;
                  }).toList();

                  // ২.৪ খালি স্টেট (কোনো ডেটা না থাকলে)
                  if (filteredDocs.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                color: const Color(0xFFE8F5E9),
                                shape: BoxShape.circle,
                                border: Border.all(color: const Color(0xFFA5D6A7)),
                              ),
                              child: const Icon(Icons.spa_rounded, color: Color(0xFF2E7D32), size: 40),
                            ),
                            const SizedBox(height: 18),
                            const Text(
                              'কোনো বীজের তথ্য পাওয়া যায়নি',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1B5E20),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _searchQuery.isNotEmpty || _selectedCategory != 'সব'
                                  ? 'আপনার খোঁজা অনুযায়ী কোনো বীজ তালিকাভুক্ত নেই।'
                                  : 'এডমিন প্যানেল থেকে নতুন বীজের তথ্য যোগ করা হলে এখানে রিয়েল-টাইমে দেখতে পাবেন।',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey.shade600,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  // ২.৫ ডেটা লিস্ট রেন্ডার
                  return ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: filteredDocs.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final doc = filteredDocs[index];
                      final data = doc.data();
                      data['id'] = doc.id;
                      return _buildSeedCard(context, data);
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

  Widget _buildSeedCard(BuildContext context, Map<String, dynamic> data) {
    final seedName = data['seedName']?.toString() ?? 'বীজের জাত';
    final category = data['category']?.toString() ?? 'সাধারণ';
    final sowingTime = data['sowingTime']?.toString() ?? '';
    final imageUrl = (data['imageUrl'] ?? '').toString().trim();
    final description = (data['description'] ?? '').toString();

    return InkWell(
      onTap: () => _showSeedDetailsDialog(context, data),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE0E8E1)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ছবি বা আইকন
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: 80,
                  height: 80,
                  color: const Color(0xFFE8F5E9),
                  child: imageUrl.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: imageUrl,
                          width: 80,
                          height: 80,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => const Center(
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF2E7D32)),
                            ),
                          ),
                          errorBuilder: (_, __, ___) => const Center(
                            child: Icon(Icons.spa_rounded, color: Color(0xFF2E7D32), size: 36),
                          ),
                        )
                      : const Center(
                          child: Icon(Icons.spa_rounded, color: Color(0xFF2E7D32), size: 36),
                        ),
                ),
              ),
              const SizedBox(width: 14),

              // বিস্তারিত তথ্য
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ক্যাটাগরি ব্যাজ
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F5E9),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        category,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2E7D32),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),

                    // বীজের নাম
                    Text(
                      seedName,
                      style: const TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1B5E20),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),

                    // রোপণের সময়
                    if (sowingTime.isNotEmpty) ...[
                      Row(
                        children: [
                          const Icon(Icons.calendar_month_rounded, size: 14, color: Color(0xFFE65100)),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              'রোপণ: $sowingTime',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFFD84315),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                    ],

                    // সংক্ষিপ্ত বিবরণ
                    if (description.isNotEmpty)
                      Text(
                        description,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade700,
                          height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),

              const SizedBox(width: 6),
              const Icon(Icons.chevron_right_rounded, color: Color(0xFFA5D6A7), size: 24),
            ],
          ),
        ),
      ),
    );
  }

  void _showSeedDetailsDialog(BuildContext context, Map<String, dynamic> data) {
    final seedName = data['seedName']?.toString() ?? 'বীজের বিবরণ';
    final category = data['category']?.toString() ?? 'সাধারণ';
    final sowingTime = data['sowingTime']?.toString() ?? '';
    final harvestingTime = data['harvestingTime']?.toString() ?? '';
    final imageUrl = (data['imageUrl'] ?? '').toString().trim();
    final description = (data['description'] ?? '').toString();
    final treatment = (data['treatment'] ?? '').toString();
    final preservation = (data['preservation'] ?? '').toString();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            // হ্যাণ্ডেল বার
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // টপ বার
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                children: [
                  const Icon(Icons.spa_rounded, color: Color(0xFF2E7D32), size: 22),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      seedName,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1B5E20),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Colors.grey),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            // বিস্তারিত বডি
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ছবি
                    if (imageUrl.isNotEmpty) ...[
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: CachedNetworkImage(
                          imageUrl: imageUrl,
                          width: double.infinity,
                          height: 190,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => Container(
                            height: 190,
                            color: const Color(0xFFE8F5E9),
                            child: const Center(
                              child: CircularProgressIndicator(color: Color(0xFF2E7D32)),
                            ),
                          ),
                          errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // ক্যাটাগরি ও রোপণ সময় চিপস
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _buildBadge(Icons.category_rounded, category, const Color(0xFFE8F5E9), const Color(0xFF2E7D32)),
                        if (sowingTime.isNotEmpty)
                          _buildBadge(Icons.calendar_month_rounded, 'বপন: $sowingTime', const Color(0xFFFFF3E0), const Color(0xFFE65100)),
                        if (harvestingTime.isNotEmpty)
                          _buildBadge(Icons.timer_outlined, 'জীবনকাল: $harvestingTime', const Color(0xFFE3F2FD), const Color(0xFF1565C0)),
                      ],
                    ),
                    const SizedBox(height: 18),

                    // জাতের বৈশিষ্ট্য ও বিবরণ
                    if (description.isNotEmpty) ...[
                      _buildSectionTitle('জাতের বৈশিষ্ট্য ও পরিচিতি', Icons.article_rounded, const Color(0xFF2E7D32)),
                      const SizedBox(height: 6),
                      Text(
                        description,
                        style: TextStyle(fontSize: 13.5, color: Colors.grey.shade800, height: 1.5),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // বীজ শোধন ও অঙ্কুরোদগম
                    if (treatment.isNotEmpty) ...[
                      _buildInfoBox(
                        title: 'বীজ শোধন ও অঙ্কুরোদগম নির্দেশিকা',
                        content: treatment,
                        icon: Icons.verified_rounded,
                        color: const Color(0xFF1565C0),
                        bgColor: const Color(0xFFE3F2FD),
                      ),
                      const SizedBox(height: 14),
                    ],

                    // বীজ সংরক্ষণ পদ্ধতি
                    if (preservation.isNotEmpty) ...[
                      _buildInfoBox(
                        title: 'বীজ সংরক্ষণ ও আর্দ্রতা ব্যবস্থাপনা',
                        content: preservation,
                        icon: Icons.inventory_2_rounded,
                        color: const Color(0xFF6D4C41),
                        bgColor: const Color(0xFFEFEBE9),
                      ),
                      const SizedBox(height: 14),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBadge(IconData icon, String text, Color bg, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 5),
          Text(
            text,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 6),
        Text(
          title,
          style: TextStyle(
            fontSize: 14.5,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoBox({
    required String title,
    required String content,
    required IconData icon,
    required Color color,
    required Color bgColor,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Text(
                title,
                style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: color),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            content,
            style: TextStyle(fontSize: 12.5, color: Colors.grey.shade900, height: 1.45),
          ),
        ],
      ),
    );
  }
}
