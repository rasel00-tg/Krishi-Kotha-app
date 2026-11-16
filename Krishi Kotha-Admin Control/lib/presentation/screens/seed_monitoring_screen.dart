import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants/admin_colors.dart';
import '../../core/utils/platform_file_picker/platform_file_picker.dart';
import '../../core/utils/image_compressor/image_compressor.dart';
import '../../core/utils/admin_loading_controller.dart';
import '../../data/services/admin_firestore_service.dart';
import '../../data/services/r2_storage_service.dart';
import '../widgets/admin_delete_dialog.dart';
import '../widgets/admin_loading_indicator.dart';

/// কৃষি কথা – এডমিন কন্ট্রোল: বীজের তথ্য মনিটরিং স্ক্রিন
class SeedMonitoringScreen extends StatefulWidget {
  const SeedMonitoringScreen({super.key});

  @override
  State<SeedMonitoringScreen> createState() => _SeedMonitoringScreenState();
}

class _SeedMonitoringScreenState extends State<SeedMonitoringScreen> {
  String _selectedCategory = 'সব';
  String _searchQuery = '';
  final TextEditingController _searchCtrl = TextEditingController();
  bool _isLoading = false;
  BuildContext? _loadingDialogCtx;

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

  Stream<List<Map<String, dynamic>>>? _seedStream;

  @override
  void initState() {
    super.initState();
    _loadStream();
    _searchCtrl.addListener(() {
      setState(() {
        _searchQuery = _searchCtrl.text.trim().toLowerCase();
      });
    });
  }

  void _loadStream() {
    _seedStream = AdminFirestoreService.instance.getSeedInformationStream(
      category: _selectedCategory == 'সব' ? null : _selectedCategory,
    );
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _showLoading(String message) {
    if (_isLoading) return;
    _isLoading = true;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        _loadingDialogCtx = ctx;
        return PopScope(
          canPop: false,
          child: Dialog(
            backgroundColor: Colors.transparent,
            elevation: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 10)],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2.5, color: AdminColors.primary),
                    ),
                    const SizedBox(width: 14),
                    Text(
                      message,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AdminColors.textPrimary),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _safeDismissLoading() {
    if (_isLoading) {
      _isLoading = false;
      if (_loadingDialogCtx != null && Navigator.canPop(_loadingDialogCtx!)) {
        Navigator.pop(_loadingDialogCtx!);
        _loadingDialogCtx = null;
      }
    }
  }

  // 6. Global Custom Popup: প্রজেক্টে ব্যবহৃত স্ট্যান্ডার্ড অ্যাডমিন অ্যাকশন সাকসেস/এরর পপআপ
  Future<void> _showAdminActionSuccessDialog({
    required String title,
    required String message,
    bool isDanger = false,
  }) async {
    if (!mounted) return;
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: (isDanger ? AdminColors.alertCritical : AdminColors.primary).withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isDanger ? Icons.cancel_rounded : Icons.check_circle_rounded,
                color: isDanger ? AdminColors.alertCritical : AdminColors.primary,
                size: 22,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ],
        ),
        content: Text(
          message,
          style: const TextStyle(fontSize: 13.5, height: 1.4, color: AdminColors.textPrimary),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: isDanger ? AdminColors.alertCritical : AdminColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => Navigator.pop(ctx),
            child: const Text('ঠিক আছে', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  static const List<String> _defaultSeedCategories = [
    'ধান',
    'গম ও ভুট্টা',
    'সবজি',
    'মসলা',
    'ডাল ও তৈলবীজ',
    'ফলমূল',
    'অন্যান্য',
  ];

  static const List<String> _banglaMonths = [
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

  List<Map<String, dynamic>> _getCategoriesFromSnapshot(AsyncSnapshot<QuerySnapshot> snapshot) {
    final list = <Map<String, dynamic>>[];
    final seen = <String>{};

    if (snapshot.hasData && snapshot.data != null && snapshot.data!.docs.isNotEmpty) {
      for (final doc in snapshot.data!.docs) {
        final data = doc.data() as Map<String, dynamic>? ?? {};
        final name = (data['name'] ?? '').toString().trim();
        if (name.isNotEmpty && !seen.contains(name)) {
          seen.add(name);
          list.add({'name': name, 'id': doc.id});
        }
      }
    }

    for (final def in _defaultSeedCategories) {
      if (!seen.contains(def)) {
        seen.add(def);
        list.add({'name': def, 'id': null});
      }
    }

    return list;
  }

  // ৩. Dynamic Category Management: নতুন ক্যাটাগরি Firestore-এ যোগ করা
  Future<void> _openAddCategoryDialog(BuildContext context, StateSetter setDlgState, Function(String) onAdded) async {
    final catCtrl = TextEditingController();
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.add_circle_outline_rounded, color: AdminColors.primary, size: 22),
            SizedBox(width: 8),
            Text('নতুন ক্যাটাগরি যোগ করুন', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('ক্যাটাগরির নাম *', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            TextField(
              controller: catCtrl,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'উদা: ফলমূল, তৈলবীজ ইত্যাদি',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('বাতিল', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AdminColors.primary, foregroundColor: Colors.white),
            onPressed: () async {
              final name = catCtrl.text.trim();
              if (name.isEmpty) return;
              Navigator.pop(ctx);
              try {
                _showLoading('ক্যাটাগরি ডাটাবেসে সেভ হচ্ছে...');
                await FirebaseFirestore.instance.collection('seed_categories').add({
                  'name': name,
                  'createdAt': FieldValue.serverTimestamp(),
                });
                _safeDismissLoading();
                onAdded(name);
                await _showAdminActionSuccessDialog(
                  title: 'সফল হয়েছে',
                  message: '"$name" ক্যাটাগরি সফলভাবে ডাটাবেসে যুক্ত হয়েছে!',
                );
              } catch (e) {
                _safeDismissLoading();
                await _showAdminActionSuccessDialog(
                  title: 'ব্যর্থ হয়েছে',
                  message: 'ক্যাটাগরি যোগ করতে সমস্যা হয়েছে: $e',
                  isDanger: true,
                );
              }
            },
            child: const Text('যোগ করুন', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // ৩. Dynamic Category Management: ক্যাটাগরি ডিলিট করা
  Future<void> _confirmDeleteCategory(String catId, String catName, StateSetter setDlgState, VoidCallback onDeleted) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: AdminColors.alertCritical, size: 24),
            SizedBox(width: 8),
            Text('ক্যাটাগরি মুছে ফেলা', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text('আপনি কি নিশ্চিত যে "$catName" ক্যাটাগরি ডাটাবেস থেকে মুছে ফেলতে চান?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('বাতিল', style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AdminColors.alertCritical, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('মুছে ফেলুন', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        _showLoading('ক্যাটাগরি মুছে ফেলা হচ্ছে...');
        await FirebaseFirestore.instance.collection('seed_categories').doc(catId).delete();
        _safeDismissLoading();
        onDeleted();
        await _showAdminActionSuccessDialog(
          title: 'সফল হয়েছে',
          message: '"$catName" ক্যাটাগরি সফলভাবে মুছে ফেলা হয়েছে!',
        );
      } catch (e) {
        _safeDismissLoading();
        await _showAdminActionSuccessDialog(
          title: 'ব্যর্থ হয়েছে',
          message: 'ক্যাটাগরি মুছতে সমস্যা হয়েছে: $e',
          isDanger: true,
        );
      }
    }
  }

  // ৪. Editable Month Dropdown: Autocomplete + ১২ মাসের সাজেশন ও কাস্টম টেক্সট এডিট
  Widget _buildEditableMonthField(TextEditingController sowingCtrl) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Autocomplete<String>(
          initialValue: TextEditingValue(text: sowingCtrl.text),
          optionsBuilder: (TextEditingValue textEditingValue) {
            if (textEditingValue.text.isEmpty) {
              return _banglaMonths;
            }
            return _banglaMonths.where((String option) {
              return option.contains(textEditingValue.text);
            });
          },
          onSelected: (String selection) {
            sowingCtrl.text = selection;
          },
          optionsViewBuilder: (context, onSelected, options) {
            return Align(
              alignment: Alignment.topLeft,
              child: Material(
                elevation: 4,
                borderRadius: BorderRadius.circular(10),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: 220,
                    maxWidth: constraints.maxWidth > 0 ? constraints.maxWidth : 300,
                  ),
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    shrinkWrap: true,
                    itemCount: options.length,
                    itemBuilder: (context, index) {
                      final option = options.elementAt(index);
                      return ListTile(
                        dense: true,
                        title: Text(option, style: const TextStyle(fontSize: 13)),
                        onTap: () => onSelected(option),
                      );
                    },
                  ),
                ),
              ),
            );
          },
          fieldViewBuilder: (context, fieldCtrl, focusNode, onFieldSubmitted) {
            if (sowingCtrl.text.isNotEmpty && fieldCtrl.text != sowingCtrl.text) {
              fieldCtrl.text = sowingCtrl.text;
            }
            fieldCtrl.addListener(() {
              sowingCtrl.text = fieldCtrl.text;
            });

            return TextFormField(
              controller: fieldCtrl,
              focusNode: focusNode,
              decoration: InputDecoration(
                hintText: 'উদা: অগ্রহায়ণ - পৌষ (লিস্ট বা কাস্টম টাইপ)',
                suffixIcon: PopupMenuButton<String>(
                  icon: const Icon(Icons.arrow_drop_down_rounded, color: AdminColors.primary, size: 26),
                  tooltip: 'মাসের তালিকা থেকে বাছুন',
                  onSelected: (String val) {
                    fieldCtrl.text = val;
                    sowingCtrl.text = val;
                  },
                  itemBuilder: (context) => _banglaMonths.map((m) => PopupMenuItem(value: m, child: Text(m))).toList(),
                ),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'বপন/রোপণের সময় আবশ্যক' : null,
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AdminColors.background,
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _seedStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
            return const AdminLoadingIndicator(message: 'সার্ভার থেকে বীজের তথ্য লোডিং হচ্ছে.....');
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline_rounded, color: AdminColors.alertCritical, size: 48),
                    const SizedBox(height: 12),
                    Text('ডেটা লোড করতে সমস্যা: ${snapshot.error}', style: const TextStyle(color: AdminColors.alertCritical)),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: () => setState(() => _loadStream()),
                      style: ElevatedButton.styleFrom(backgroundColor: AdminColors.primary, foregroundColor: Colors.white),
                      child: const Text('পুনরায় চেষ্টা করুন'),
                    ),
                  ],
                ),
              ),
            );
          }

          final allSeeds = snapshot.data ?? [];
          final filteredSeeds = allSeeds.where((seed) {
            final name = (seed['seedName'] ?? '').toString().toLowerCase();
            final cat = (seed['category'] ?? '').toString().toLowerCase();
            final sowing = (seed['sowingTime'] ?? '').toString().toLowerCase();
            final desc = (seed['description'] ?? '').toString().toLowerCase();

            if (_searchQuery.isNotEmpty) {
              return name.contains(_searchQuery) ||
                  cat.contains(_searchQuery) ||
                  sowing.contains(_searchQuery) ||
                  desc.contains(_searchQuery);
            }
            return true;
          }).toList();

          final photoCount = allSeeds.where((s) => (s['imageUrl'] ?? '').toString().trim().isNotEmpty).length;
          final categoriesCount = allSeeds.map((s) => s['category']).toSet().length;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ১. হেডার ও নতুন বীজ যোগ বাটন
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.spa_rounded, color: AdminColors.primary, size: 26),
                            SizedBox(width: 8),
                            Text(
                              'বীজের তথ্য মনিটরিং ও ব্যবস্থাপনা',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: AdminColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'উন্নত জাতের বীজ পরিচিতি, শোধন ও সংরক্ষণ নির্দেশিকা নিয়ন্ত্রণ',
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AdminColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        elevation: 2,
                      ),
                      icon: const Icon(Icons.add_rounded, size: 20),
                      label: const Text('নতুন বীজ যোগ করুন', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                      onPressed: () => _openSeedFormDialog(null),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // ২. সামারি স্ট্যাটাস কার্ড
                Row(
                  children: [
                    _buildStatCard('মোট তালিকাভুক্ত বীজ', '${allSeeds.length} টি', Icons.eco_rounded, const Color(0xFF2E7D32), const Color(0xFFE8F5E9)),
                    const SizedBox(width: 16),
                    _buildStatCard('ক্যাটাগরি সংখ্যা', '$categoriesCount টি', Icons.category_rounded, const Color(0xFF1565C0), const Color(0xFFE3F2FD)),
                    const SizedBox(width: 16),
                    _buildStatCard('ছবিযুক্ত বীজ', '$photoCount টি', Icons.photo_library_rounded, const Color(0xFFE65100), const Color(0xFFFFF3E0)),
                  ],
                ),
                const SizedBox(height: 20),

                // ৩. সার্চ ও ক্যাটাগরি ফিল্টার বার
                Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: Colors.grey.shade200),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        // সার্চ বক্স
                        Expanded(
                          flex: 3,
                          child: Container(
                            height: 40,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF7FBF7),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: TextField(
                              controller: _searchCtrl,
                              decoration: InputDecoration(
                                hintText: 'বীজের নাম, জাত বা বিবরণ দিয়ে খুঁজুন...',
                                hintStyle: TextStyle(fontSize: 12.5, color: Colors.grey.shade400),
                                prefixIcon: const Icon(Icons.search_rounded, size: 18, color: AdminColors.primary),
                                suffixIcon: _searchCtrl.text.isNotEmpty
                                    ? IconButton(
                                        icon: const Icon(Icons.close_rounded, size: 16, color: Colors.grey),
                                        onPressed: () => _searchCtrl.clear(),
                                      )
                                    : null,
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(vertical: 10),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),

                        // ক্যাটাগরি ড্রপডাউন (ডায়নামিক ফায়ারস্টোর স্ট্রিম)
                        StreamBuilder<QuerySnapshot>(
                          stream: FirebaseFirestore.instance.collection('seed_categories').orderBy('createdAt', descending: false).snapshots(),
                          builder: (context, catSnap) {
                            final catList = _getCategoriesFromSnapshot(catSnap).map((e) => e['name'] as String).toList();
                            final allCategories = ['সব', ...catList];
                            final curVal = allCategories.contains(_selectedCategory) ? _selectedCategory : 'সব';

                            return Container(
                              height: 40,
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.grey.shade300),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: curVal,
                                  icon: const Icon(Icons.filter_list_rounded, size: 18, color: AdminColors.primary),
                                  style: const TextStyle(fontSize: 13, color: AdminColors.textPrimary, fontWeight: FontWeight.w600),
                                  items: allCategories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                                  onChanged: (val) {
                                    if (val != null) {
                                      setState(() {
                                        _selectedCategory = val;
                                        _loadStream();
                                      });
                                    }
                                  },
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // ক্যাটাগরি ফিল্টার বাটনসমূহ (অনুভূমিক স্ক্রলেবল ডাইনামিক স্ট্রিম)
                    StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance.collection('seed_categories').orderBy('createdAt', descending: false).snapshots(),
                      builder: (context, catSnap) {
                        final catList = _getCategoriesFromSnapshot(catSnap).map((e) => e['name'] as String).toList();
                        final allCategories = ['সব', ...catList];

                        return SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          child: Row(
                            children: allCategories.map((c) {
                              final isSel = _selectedCategory == c;
                              return Padding(
                                padding: const EdgeInsets.only(right: 8.0),
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(20),
                                  onTap: () {
                                    setState(() {
                                      _selectedCategory = c;
                                      _loadStream();
                                    });
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: isSel ? AdminColors.primary : Colors.white,
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: isSel ? AdminColors.primary : AdminColors.border,
                                        width: 1.2,
                                      ),
                                      boxShadow: isSel
                                          ? const [BoxShadow(color: Color(0x182E7D32), blurRadius: 4, offset: Offset(0, 2))]
                                          : null,
                                    ),
                                    child: Text(
                                      c,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: isSel ? FontWeight.bold : FontWeight.w500,
                                        color: isSel ? Colors.white : AdminColors.textSecondary,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // ৪. বীজের তালিকা টেবিল / কার্ড
                if (filteredSeeds.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 48),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.spa_outlined, size: 54, color: Colors.grey.shade400),
                          const SizedBox(height: 14),
                          const Text(
                            'কোনো বীজের তথ্য পাওয়া যায়নি',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AdminColors.textPrimary),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _searchQuery.isNotEmpty || _selectedCategory != 'সব'
                                ? 'ফিল্টার বা সার্চ পরিবর্তন করে দেখুন।'
                                : 'নতুন বীজ যুক্ত করতে উপরের "নতুন বীজ যোগ করুন" বাটনে ক্লিক করুন।',
                            style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                      side: BorderSide(color: Colors.grey.shade200),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: filteredSeeds.length,
                      separatorBuilder: (_, __) => Divider(height: 1, color: Colors.grey.shade200),
                      itemBuilder: (context, index) {
                        final seed = filteredSeeds[index];
                        return _buildSeedRow(seed);
                      },
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color, Color bg) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 6, offset: const Offset(0, 2)),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                  const SizedBox(height: 3),
                  Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSeedRow(Map<String, dynamic> seed) {
    final seedId = seed['id']?.toString() ?? '';
    final seedName = seed['seedName']?.toString() ?? 'বীজের জাত';
    final category = seed['category']?.toString() ?? 'সাধারণ';
    final sowingTime = seed['sowingTime']?.toString() ?? '';
    final imageUrl = (seed['imageUrl'] ?? '').toString().trim();
    final description = (seed['description'] ?? '').toString();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          // ইমেজ থাম্বনেইল
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Container(
              width: 54,
              height: 54,
              color: const Color(0xFFE8F5E9),
              child: imageUrl.isNotEmpty
                  ? Image.network(
                      imageUrl,
                      width: 54,
                      height: 54,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Center(
                        child: Icon(Icons.spa_rounded, color: Color(0xFF2E7D32), size: 26),
                      ),
                    )
                  : const Center(
                      child: Icon(Icons.spa_rounded, color: Color(0xFF2E7D32), size: 26),
                    ),
            ),
          ),
          const SizedBox(width: 14),

          // নাম ও ক্যাটাগরি
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      seedName,
                      style: const TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.bold,
                        color: AdminColors.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F5E9),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        category,
                        style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Color(0xFF2E7D32)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  description.isNotEmpty ? description : 'কোনো অতিরিক্ত বিবরণ নেই।',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          // বপন সময়
          Expanded(
            flex: 2,
            child: Row(
              children: [
                const Icon(Icons.calendar_month_rounded, size: 14, color: Color(0xFFE65100)),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    sowingTime.isNotEmpty ? sowingTime : 'নির্দিষ্ট নয়',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFFD84315)),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),

          // একশন বাটন
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.visibility_rounded, color: AdminColors.primary, size: 20),
                tooltip: 'বিস্তারিত দেখুন',
                onPressed: () => _showSeedDetailMemo(seed),
              ),
              IconButton(
                icon: const Icon(Icons.edit_rounded, color: Color(0xFF1565C0), size: 20),
                tooltip: 'সম্পাদনা করুন',
                onPressed: () => _openSeedFormDialog(seed),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFD32F2F), size: 20),
                tooltip: 'মুছে ফেলুন',
                onPressed: () => _confirmDeleteSeed(seedId, seedName),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showSeedDetailMemo(Map<String, dynamic> seed) {
    final seedName = seed['seedName']?.toString() ?? 'বীজের বিবরণ';
    final category = seed['category']?.toString() ?? 'সাধারণ';
    final sowingTime = seed['sowingTime']?.toString() ?? '';
    final harvestingTime = seed['harvestingTime']?.toString() ?? '';
    final imageUrl = (seed['imageUrl'] ?? '').toString().trim();
    final description = (seed['description'] ?? '').toString();
    final treatment = (seed['treatment'] ?? '').toString();
    final preservation = (seed['preservation'] ?? '').toString();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.spa_rounded, color: AdminColors.primary, size: 22),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                seedName,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AdminColors.textPrimary),
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: 520,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (imageUrl.isNotEmpty) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.network(
                      imageUrl,
                      width: double.infinity,
                      height: 180,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                    ),
                  ),
                  const SizedBox(height: 14),
                ],
                Row(
                  children: [
                    _buildModalPill('ক্যাটাগরি: $category', const Color(0xFFE8F5E9), const Color(0xFF2E7D32)),
                    if (sowingTime.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      _buildModalPill('বপন: $sowingTime', const Color(0xFFFFF3E0), const Color(0xFFE65100)),
                    ],
                  ],
                ),
                if (harvestingTime.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text('জীবনকাল / ফলন: $harvestingTime', style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold)),
                ],
                const SizedBox(height: 14),
                if (description.isNotEmpty) ...[
                  const Text('জাতের বৈশিষ্ট্য ও বিবরণ:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(description, style: TextStyle(fontSize: 12.5, color: Colors.grey.shade800, height: 1.4)),
                  const SizedBox(height: 12),
                ],
                if (treatment.isNotEmpty) ...[
                  const Text('বীজ শোধন ও অঙ্কুরোদগম:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1565C0))),
                  const SizedBox(height: 4),
                  Text(treatment, style: TextStyle(fontSize: 12.5, color: Colors.grey.shade800, height: 1.4)),
                  const SizedBox(height: 12),
                ],
                if (preservation.isNotEmpty) ...[
                  const Text('বীজ সংরক্ষণ ও আর্দ্রতা ব্যবস্থাপনা:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF6D4C41))),
                  const SizedBox(height: 4),
                  Text(preservation, style: TextStyle(fontSize: 12.5, color: Colors.grey.shade800, height: 1.4)),
                ],
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('বন্ধ করুন', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildModalPill(String text, Color bg, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(text, style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: color)),
    );
  }

  void _confirmDeleteSeed(String id, String name) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Row(
          children: [
            Icon(Icons.delete_outline_rounded, color: Color(0xFFD32F2F), size: 22),
            SizedBox(width: 8),
            Text('বীজের তথ্য ডিলিট', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text('আপনি কি নিশ্চিত যে "$name" তথ্যটি সম্পূর্ণ মুছে ফেলতে চান? এটি ইউজারদের অ্যাপ থেকেও মুছে যাবে।'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('বাতিল', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD32F2F), foregroundColor: Colors.white),
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                _showLoading('বীজের তথ্য মুছে ফেলা হচ্ছে...');
                await AdminFirestoreService.instance.deleteSeedInformation(id);
                _safeDismissLoading();
                if (mounted) {
                  // ৬. Global Custom Popup
                  await _showAdminActionSuccessDialog(
                    title: 'সফল হয়েছে',
                    message: 'বীজের তথ্য সফলভাবে মুছে ফেলা হয়েছে!',
                  );
                }
              } catch (e) {
                _safeDismissLoading();
                if (mounted) {
                  // ৬. Global Custom Popup
                  await _showAdminActionSuccessDialog(
                    title: 'মুছে ফেলতে ব্যর্থ',
                    message: 'ডিলিট করতে সমস্যা হয়েছে: $e',
                    isDanger: true,
                  );
                }
              }
            },
            child: const Text('মুছে ফেলুন', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _openSeedFormDialog(Map<String, dynamic>? existingSeed) {
    final isEditing = existingSeed != null;
    final formKey = GlobalKey<FormState>();

    // ২. Form Reset State: নতুন বীজ যোগ করার সময় ১০০% খালি/রিসেট
    final nameCtrl = TextEditingController(text: existingSeed?['seedName'] ?? '');
    String? selectedCat = existingSeed?['category'];
    final sowingCtrl = TextEditingController(text: existingSeed?['sowingTime'] ?? '');
    final harvestCtrl = TextEditingController(text: existingSeed?['harvestingTime'] ?? '');
    final descCtrl = TextEditingController(text: existingSeed?['description'] ?? '');
    final treatCtrl = TextEditingController(text: existingSeed?['treatment'] ?? '');
    final preserveCtrl = TextEditingController(text: existingSeed?['preservation'] ?? '');

    String existingImageUrl = (existingSeed?['imageUrl'] ?? '').toString().trim();
    Uint8List? selectedImageBytes;
    String? selectedImageName;
    int selectedImageSize = 0;
    bool isImageRemoved = false;
    bool isCompressing = false;
    bool isSaving = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (context, setDlgState) {
            final hasActiveImage = selectedImageBytes != null || (existingImageUrl.isNotEmpty && !isImageRemoved);
            final screenWidth = MediaQuery.of(context).size.width;
            final isWide = screenWidth > 768;
            // ৫. Layout Width & Responsive Fix: প্রশস্ত ও স্পেশিয়াস ডায়ালগ
            final dialogWidth = (screenWidth * 0.85).clamp(420.0, 880.0);

            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              titlePadding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
              contentPadding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
              actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AdminColors.primary.withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(isEditing ? Icons.edit_rounded : Icons.add_circle_outline_rounded, color: AdminColors.primary, size: 22),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    isEditing ? 'বীজের তথ্য সম্পাদনা করুন' : 'নতুন বীজ যোগ করুন',
                    style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AdminColors.textPrimary),
                  ),
                ],
              ),
              content: SizedBox(
                width: dialogWidth,
                child: Form(
                  key: formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Row 1: নাম এবং ক্যাটাগরি
                        if (isWide)
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // নাম
                              Expanded(
                                flex: 6,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('বীজের নাম / জাতের নাম *', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 6),
                                    TextFormField(
                                      controller: nameCtrl,
                                      decoration: InputDecoration(
                                        hintText: 'উদা: ব্রি ধান-২৮, বারি গম-৩৩ ইত্যাদি',
                                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                                      ),
                                      validator: (v) => v == null || v.trim().isEmpty ? 'বীজের নাম আবশ্যক' : null,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 16),
                              // ক্যাটাগরি (Dynamic Firestore stream + নতুন যোগ + ডিলিট)
                              Expanded(
                                flex: 5,
                                child: _buildCategoryFormField(setDlgState, selectedCat, (newVal) {
                                  setDlgState(() => selectedCat = newVal);
                                }),
                              ),
                            ],
                          )
                        else ...[
                          const Text('বীজের নাম / জাতের নাম *', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: nameCtrl,
                            decoration: InputDecoration(
                              hintText: 'উদা: ব্রি ধান-২৮, বারি গম-৩৩ ইত্যাদি',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                            ),
                            validator: (v) => v == null || v.trim().isEmpty ? 'বীজের নাম আবশ্যক' : null,
                          ),
                          const SizedBox(height: 14),
                          _buildCategoryFormField(setDlgState, selectedCat, (newVal) {
                            setDlgState(() => selectedCat = newVal);
                          }),
                        ],
                        const SizedBox(height: 14),

                        // Row 2: বপন/রোপণের সময় (Editable Month) এবং ফলন
                        if (isWide)
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // ৪. Editable Month Dropdown
                              Expanded(
                                flex: 6,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('বপন/রোপণের সময় *', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 6),
                                    _buildEditableMonthField(sowingCtrl),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 16),
                              // জীবনকাল / ফলন
                              Expanded(
                                flex: 5,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('জীবনকাল / ফলন (ঐচ্ছিক)', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 6),
                                    TextFormField(
                                      controller: harvestCtrl,
                                      decoration: InputDecoration(
                                        hintText: 'উদা: জীবনকাল ১৪০-১৪৫ দিন, ফলন ৫-৬ টন',
                                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          )
                        else ...[
                          const Text('বপন/রোপণের সময় *', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 6),
                          _buildEditableMonthField(sowingCtrl),
                          const SizedBox(height: 14),
                          const Text('জীবনকাল / ফলন (ঐচ্ছিক)', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: harvestCtrl,
                            decoration: InputDecoration(
                              hintText: 'উদা: জীবনকাল ১৪০-১৪৫ দিন, হেক্টর প্রতি ফলন ৫-৬ টন',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                            ),
                          ),
                        ],
                        const SizedBox(height: 14),

                        // জাতের বৈশিষ্ট্য ও বিবরণ
                        const Text('জাতের বৈশিষ্ট্য ও বিবরণ', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: descCtrl,
                          maxLines: 2,
                          decoration: InputDecoration(
                            hintText: 'জাতের মূল বৈশিষ্ট্য, মাটির উপযোগীতা ও রোগ বালাই প্রতিরোধ ক্ষমতা...',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            contentPadding: const EdgeInsets.all(12),
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Row 4: বীজ শোধন ও সংরক্ষণ
                        if (isWide)
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('বীজ শোধন ও অঙ্কুরোদগম নির্দেশিকা', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Color(0xFF1565C0))),
                                    const SizedBox(height: 6),
                                    TextFormField(
                                      controller: treatCtrl,
                                      maxLines: 2,
                                      decoration: InputDecoration(
                                        hintText: 'উদা: প্রতি কেজি বীজে ২-২.৫ গ্রাম অটোস্টিন মিশিয়ে শুকিয়ে নিন...',
                                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                        contentPadding: const EdgeInsets.all(12),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('বীজ সংরক্ষণ ও ড্রাম ব্যবস্থাপনা', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Color(0xFF6D4C41))),
                                    const SizedBox(height: 6),
                                    TextFormField(
                                      controller: preserveCtrl,
                                      maxLines: 2,
                                      decoration: InputDecoration(
                                        hintText: 'উদা: আর্দ্রতা ১০-১২% এর নিচে রেখে বায়ুরোধী পাত্রে সংরক্ষণ করুন...',
                                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                        contentPadding: const EdgeInsets.all(12),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          )
                        else ...[
                          const Text('বীজ শোধন ও অঙ্কুরোদগম নির্দেশিকা', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Color(0xFF1565C0))),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: treatCtrl,
                            maxLines: 2,
                            decoration: InputDecoration(
                              hintText: 'উদা: প্রতি কেজি বীজে ২-২.৫ গ্রাম অটোস্টিন মিশিয়ে শুকিয়ে নিন...',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                              contentPadding: const EdgeInsets.all(12),
                            ),
                          ),
                          const SizedBox(height: 14),
                          const Text('বীজ সংরক্ষণ ও ড্রাম ব্যবস্থাপনা', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Color(0xFF6D4C41))),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: preserveCtrl,
                            maxLines: 2,
                            decoration: InputDecoration(
                              hintText: 'উদা: আর্দ্রতা ১০-১২% এর নিচে রেখে বায়ুরোধী পাত্রে সংরক্ষণ করুন...',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                              contentPadding: const EdgeInsets.all(12),
                            ),
                          ),
                        ],
                        const SizedBox(height: 16),

                        // ছবি আপলোড সেকশন
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('বীজের ছবি', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold)),
                                  Text('Cloudflare R2 স্টোরেজ', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AdminColors.primary)),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  OutlinedButton.icon(
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: AdminColors.primary,
                                      side: const BorderSide(color: AdminColors.primary),
                                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    ),
                                    icon: isCompressing
                                        ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: AdminColors.primary))
                                        : const Icon(Icons.file_upload_outlined, size: 18),
                                    label: Text(hasActiveImage ? 'ছবি পরিবর্তন করুন' : 'ছবি নির্বাচন করুন', style: const TextStyle(fontSize: 12)),
                                    onPressed: (isSaving || isCompressing)
                                        ? null
                                        : () async {
                                            final picked = await pickLocalImageFile();
                                            if (picked != null) {
                                              setDlgState(() => isCompressing = true);
                                              try {
                                                final compressed = await compressImageBytes(
                                                  picked.bytes,
                                                  maxWidth: 800,
                                                  quality: 75,
                                                );
                                                setDlgState(() {
                                                  selectedImageBytes = compressed;
                                                  selectedImageName = picked.name;
                                                  selectedImageSize = compressed.lengthInBytes;
                                                  isImageRemoved = false;
                                                  isCompressing = false;
                                                });
                                              } catch (_) {
                                                setDlgState(() {
                                                  selectedImageBytes = picked.bytes;
                                                  selectedImageName = picked.name;
                                                  selectedImageSize = picked.bytes.lengthInBytes;
                                                  isImageRemoved = false;
                                                  isCompressing = false;
                                                });
                                              }
                                            }
                                          },
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      isCompressing
                                          ? 'ছবি অপ্টিমাইজ ও কম্প্রেস হচ্ছে...'
                                          : selectedImageBytes != null
                                              ? 'ছবি নির্বাচিত (${(selectedImageSize / 1024).toStringAsFixed(1)} KB — অপ্টিমাইজড)\nসংরক্ষণ বাটনে চাপলে আপলোড হবে'
                                              : (existingImageUrl.isNotEmpty && !isImageRemoved)
                                                  ? 'বর্তমান ছবি সংযুক্ত রয়েছে'
                                                  : 'ডিভাইস থেকে লোকাল ছবি নির্বাচন করুন',
                                      style: TextStyle(
                                        fontSize: 11.5,
                                        color: selectedImageBytes != null ? const Color(0xFF2E7D32) : Colors.grey.shade600,
                                        fontWeight: selectedImageBytes != null ? FontWeight.bold : FontWeight.normal,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              if (hasActiveImage) ...[
                                const SizedBox(height: 10),
                                Stack(
                                  alignment: Alignment.topRight,
                                  children: [
                                    Container(
                                      width: double.infinity,
                                      height: 120,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(color: Colors.grey.shade300),
                                        color: Colors.grey.shade100,
                                      ),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(10),
                                        child: selectedImageBytes != null
                                            ? Image.memory(selectedImageBytes!, width: double.infinity, height: 120, fit: BoxFit.cover)
                                            : Image.network(
                                                existingImageUrl,
                                                width: double.infinity,
                                                height: 120,
                                                fit: BoxFit.cover,
                                                errorBuilder: (_, __, ___) => const Center(
                                                  child: Icon(Icons.broken_image_rounded, color: Colors.grey),
                                                ),
                                              ),
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.all(6),
                                      child: InkWell(
                                        onTap: () {
                                          setDlgState(() {
                                            selectedImageBytes = null;
                                            selectedImageName = null;
                                            selectedImageSize = 0;
                                            isImageRemoved = true;
                                          });
                                        },
                                        borderRadius: BorderRadius.circular(16),
                                        child: Container(
                                          padding: const EdgeInsets.all(4),
                                          decoration: const BoxDecoration(color: Color(0xFFD32F2F), shape: BoxShape.circle),
                                          child: const Icon(Icons.close_rounded, size: 14, color: Colors.white),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSaving ? null : () => Navigator.pop(dialogCtx),
                  child: const Text('বাতিল', style: TextStyle(color: Colors.grey)),
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AdminColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 11),
                  ),
                  icon: isSaving
                      ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.check_rounded, size: 18),
                  label: Text(isSaving ? 'সংরক্ষণ হচ্ছে...' : (isEditing ? 'আপডেট করুন' : 'সংরক্ষণ করুন'), style: const TextStyle(fontWeight: FontWeight.bold)),
                  onPressed: isSaving
                      ? null
                      : () async {
                          if (!formKey.currentState!.validate()) return;
                          setDlgState(() => isSaving = true);

                          try {
                            _showLoading(isEditing ? 'তথ্য আপডেট হচ্ছে...' : 'নতুন বীজ সংরক্ষণ হচ্ছে...');

                            String finalImageUrl = existingImageUrl;
                            if (isImageRemoved) {
                              finalImageUrl = '';
                            }

                            // শুধুমাত্র ফর্ম সাবমিটের সময় R2-তে আপলোড হবে
                            if (selectedImageBytes != null) {
                              _safeDismissLoading();
                              _showLoading('ছবি Cloudflare R2-তে আপলোড হচ্ছে...');

                              final cleanExt = (selectedImageName?.split('.').last ?? 'jpg').toLowerCase();
                              final uniqueFileName = 'seed_${DateTime.now().millisecondsSinceEpoch}_${(selectedImageName ?? 'seed').replaceAll(RegExp(r'[^a-zA-Z0-9_\-]'), '_')}.$cleanExt';

                              final uploadedUrl = await R2StorageService.uploadImageBytes(
                                bytes: selectedImageBytes!,
                                fileName: uniqueFileName,
                                contentType: cleanExt == 'png' ? 'image/png' : 'image/jpeg',
                              );
                              finalImageUrl = uploadedUrl;
                            }

                            final data = <String, dynamic>{
                              'seedName': nameCtrl.text.trim(),
                              'category': (selectedCat ?? '').trim(),
                              'sowingTime': sowingCtrl.text.trim(),
                              'harvestingTime': harvestCtrl.text.trim(),
                              'description': descCtrl.text.trim(),
                              'treatment': treatCtrl.text.trim(),
                              'preservation': preserveCtrl.text.trim(),
                              'imageUrl': finalImageUrl,
                            };

                            if (isEditing) {
                              await AdminFirestoreService.instance.updateSeedInformation(existingSeed['id'].toString(), data);
                            } else {
                              await AdminFirestoreService.instance.addSeedInformation(data);
                            }

                            _safeDismissLoading();
                            if (mounted) {
                              Navigator.pop(dialogCtx);
                              // ৬. Global Custom Popup
                              await _showAdminActionSuccessDialog(
                                title: 'সফল হয়েছে',
                                message: isEditing ? 'বীজের তথ্য সফলভাবে আপডেট হয়েছে!' : 'নতুন বীজ সফলভাবে যুক্ত হয়েছে!',
                              );
                            }
                          } catch (e) {
                            _safeDismissLoading();
                            setDlgState(() => isSaving = false);
                            if (mounted) {
                              // ৬. Global Custom Popup
                              await _showAdminActionSuccessDialog(
                                title: 'ব্যর্থ হয়েছে',
                                message: 'সংরক্ষণ করতে সমস্যা হয়েছে: $e',
                                isDanger: true,
                              );
                            }
                          }
                        },
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ৩. Dynamic Category Dropdown Field with "নতুন যোগ করুন" and Delete icon
  Widget _buildCategoryFormField(
    StateSetter setDlgState,
    String? selectedCat,
    Function(String?) onCategoryChanged,
  ) {
    return StreamBuilder<QuerySnapshot>(
      stream: AdminFirestoreService.instance.getSeedCategoriesStream(),
      builder: (context, catSnapshot) {
        final categoriesList = _getCategoriesFromSnapshot(catSnapshot);
        final hasMatch = selectedCat != null && categoriesList.any((c) => c['name'] == selectedCat);
        final currentVal = hasMatch ? selectedCat : null;

        // Current selected category item info
        final selectedCatObj = categoriesList.firstWhere(
          (c) => c['name'] == selectedCat,
          orElse: () => <String, dynamic>{'name': '', 'id': null},
        );
        final canDeleteSelected = selectedCatObj['id'] != null;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('ক্যাটাগরি *', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold)),
                const Spacer(),
                InkWell(
                  onTap: () {
                    _openAddCategoryDialog(context, setDlgState, (newCat) {
                      onCategoryChanged(newCat);
                    });
                  },
                  borderRadius: BorderRadius.circular(6),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AdminColors.primary.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AdminColors.primary.withOpacity(0.3)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.add_circle_outline_rounded, size: 14, color: AdminColors.primary),
                        SizedBox(width: 4),
                        Text('নতুন যোগ করুন', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AdminColors.primary)),
                      ],
                    ),
                  ),
                ),
                if (canDeleteSelected) ...[
                  const SizedBox(width: 6),
                  InkWell(
                    onTap: () {
                      _confirmDeleteCategory(selectedCatObj['id'].toString(), selectedCat!, setDlgState, () {
                        onCategoryChanged(null);
                      });
                    },
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        color: AdminColors.alertCritical.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Icon(Icons.delete_outline_rounded, size: 15, color: AdminColors.alertCritical),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 6),
            DropdownButtonFormField<String>(
              value: currentVal,
              isExpanded: true,
              hint: const Text('ক্যাটাগরি নির্বাচন করুন', style: TextStyle(fontSize: 12.5, color: Colors.grey)),
              decoration: InputDecoration(
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
              items: categoriesList.map((c) {
                final name = c['name'].toString();
                final isDbCustom = c['id'] != null;
                return DropdownMenuItem<String>(
                  value: name,
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(name, style: const TextStyle(fontSize: 13), overflow: TextOverflow.ellipsis),
                      ),
                      if (isDbCustom)
                        Container(
                          margin: const EdgeInsets.only(left: 6),
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AdminColors.primary.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text('কাস্টম', style: TextStyle(fontSize: 9.5, color: AdminColors.primary, fontWeight: FontWeight.bold)),
                        ),
                    ],
                  ),
                );
              }).toList(),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'ক্যাটাগরি নির্বাচন আবশ্যক' : null,
              onChanged: (v) {
                onCategoryChanged(v);
              },
            ),
          ],
        );
      },
    );
  }
}
