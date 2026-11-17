import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants/admin_colors.dart';
import '../widgets/admin_stat_card.dart';
import '../widgets/admin_delete_dialog.dart';

/// কৃষি কথা – এডমিন কন্ট্রোল: সেচ ট্র্যাকার মনিটরিং স্ক্রিন
/// 
/// প্রধান বৈশিষ্ট্য:
/// ১. CollectionGroup লজিক: `FirebaseFirestore.instance.collectionGroup('irrigation_tracker_crops')` দিয়ে
///    সকল ইউজারের সেচ ট্র্যাকারের ডাটা রিয়েল-টাইমে মনিটর করা।
/// ২. দুটি সেকশন / ট্যাব:
///    - "Active Crops" (সচল ফসলসমূহ - যেগুলো ইউজাররা ব্যবহার করছেন, isDeleted != true)
///    - "Deleted Folder" (ডিলিট ফোল্ডার - ইউজার সফট ডিলিট করেছেন, isDeleted == true)
/// ৩. অ্যাডমিন সার্চ বার: ইউজারের ইমেইল, ফোন নাম্বার, ইউজার আইডি বা ফসলের নাম দিয়ে সার্চ।
/// ৪. অ্যাডমিন অ্যাকশনসমূহ:
///    - এডিট (Edit): ফসল তথ্য ও এআই পরামর্শ সম্পাদন
///    - পার্মানেন্ট ডিলিট (Hard Delete): ফায়ারবেস থেকে চিরতরে মুছে ফেলা
///    - রিস্টোর (Restore): সফট ডিলিট ফোল্ডার থেকে পুনরায় সক্রিয় করা
class IrrigationMonitoringScreen extends StatefulWidget {
  const IrrigationMonitoringScreen({super.key});

  @override
  State<IrrigationMonitoringScreen> createState() => _IrrigationMonitoringScreenState();
}

class _IrrigationMonitoringScreenState extends State<IrrigationMonitoringScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _searchCtrl.addListener(() {
      setState(() {
        _searchQuery = _searchCtrl.text.trim().toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  static String _toBangla(dynamic input) {
    if (input == null) return '';
    const en = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
    const bn = ['০', '১', '২', '৩', '৪', '৫', '৬', '৭', '৮', '৯'];
    var str = input.toString();
    for (int i = 0; i < en.length; i++) {
      str = str.replaceAll(en[i], bn[i]);
    }
    return str;
  }

  static String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return 'অজ্ঞাত সময়';
    DateTime dt;
    if (timestamp is Timestamp) {
      dt = timestamp.toDate();
    } else if (timestamp is DateTime) {
      dt = timestamp;
    } else if (timestamp is num) {
      dt = DateTime.fromMillisecondsSinceEpoch(timestamp.toInt());
    } else {
      return timestamp.toString();
    }

    final dateStr =
        '${_toBangla(dt.day.toString().padLeft(2, '0'))}/${_toBangla(dt.month.toString().padLeft(2, '0'))}/${_toBangla(dt.year)}';
    final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final period = dt.hour >= 12 ? 'বিকাল' : 'সকাল';
    final minute = _toBangla(dt.minute.toString().padLeft(2, '0'));
    final timeStr = '$period ${_toBangla(hour)}:$minute';

    return '$dateStr ($timeStr)';
  }

  // ====================== অ্যাডমিন অ্যাকশন: এডিট ডায়ালগ ======================
  void _openEditCropModal(DocumentSnapshot doc, Map<String, dynamic> data) {
    final cropNameCtrl = TextEditingController(text: data['cropName']?.toString() ?? '');
    final landAmountCtrl = TextEditingController(text: data['landAmount']?.toString() ?? '');
    final cropAgeCtrl = TextEditingController(text: data['cropAge']?.toString() ?? '');
    final cropDetailsCtrl = TextEditingController(text: data['cropDetails']?.toString() ?? '');
    final aiStatusCtrl = TextEditingController(text: data['aiStatus']?.toString() ?? '💧 হালকা সেচ দিন');
    final aiAdviceCtrl = TextEditingController(text: data['aiAdvice']?.toString() ?? '');

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return Dialog(
            backgroundColor: Colors.white,
            elevation: 16,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 550),
              padding: const EdgeInsets.all(24),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // হেডার
                    Row(
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8F5E9),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.edit_note_rounded, color: AdminColors.primary, size: 24),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'ফসলের তথ্য ও এআই পরামর্শ এডিট',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AdminColors.textPrimary,
                                ),
                              ),
                              Text(
                                'অ্যাডমিন কর্তৃক সরাসরি তথ্য হালনাগাদ',
                                style: TextStyle(fontSize: 11.5, color: AdminColors.textMuted),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.grey),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                    const Divider(height: 24, color: AdminColors.divider),

                    // ১. ফসলের নাম
                    const Text('ফসলের নাম:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: cropNameCtrl,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // ২. জমির পরিমাণ ও ফসলের বয়স
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('জমির পরিমাণ:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                              const SizedBox(height: 6),
                              TextField(
                                controller: landAmountCtrl,
                                decoration: InputDecoration(
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('ফসলের বয়স:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                              const SizedBox(height: 6),
                              TextField(
                                controller: cropAgeCtrl,
                                decoration: InputDecoration(
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // ৩. ফসলের বিস্তারিত অবস্থা
                    const Text('ফসলের বিস্তারিত বিবরণ (কৃষকের ইনপুট):',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: cropDetailsCtrl,
                      maxLines: 2,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // ৪. এআই সেচ স্ট্যাটাস
                    const Text('এআই সেচ স্ট্যাটাস:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: aiStatusCtrl,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // ৫. এআই পরামর্শ / নির্দেশনা
                    const Text('এআই সেচ নির্দেশনা (AI Feedback):',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: aiAdviceCtrl,
                      maxLines: 3,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // বাটনসমূহ
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        OutlinedButton(
                          onPressed: () => Navigator.pop(ctx),
                          style: OutlinedButton.styleFrom(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                          ),
                          child: const Text('বাতিল'),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton.icon(
                          onPressed: () async {
                            final newName = cropNameCtrl.text.trim();
                            final newLand = landAmountCtrl.text.trim();
                            final newAge = cropAgeCtrl.text.trim();
                            final newDetails = cropDetailsCtrl.text.trim();
                            final newStatus = aiStatusCtrl.text.trim();
                            final newAdvice = aiAdviceCtrl.text.trim();

                            try {
                              await doc.reference.update({
                                'cropName': newName,
                                'landAmount': newLand,
                                'cropAge': newAge,
                                'cropDetails': newDetails,
                                'aiStatus': newStatus,
                                'aiAdvice': newAdvice,
                                'updatedAt': FieldValue.serverTimestamp(),
                              });
                              if (mounted) {
                                Navigator.pop(ctx);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('ফসলের তথ্য সফলভাবে আপডেট করা হয়েছে!'),
                                    backgroundColor: AdminColors.primary,
                                  ),
                                );
                              }
                            } catch (e) {
                              debugPrint('Admin update crop error: $e');
                            }
                          },
                          icon: const Icon(Icons.check_circle_outline_rounded, size: 18),
                          label: const Text('পরিবর্তন সংরক্ষণ করুন'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AdminColors.primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ====================== অ্যাডমিন অ্যাকশন: পার্মানেন্ট হার্ড ডিলিট ======================
  Future<void> _hardDeleteCrop(DocumentSnapshot doc, String cropName) async {
    final confirmed = await AdminDeleteDialog.show(
      context,
      title: 'স্থায়ীভাবে মুছে ফেলার নিশ্চয়তা',
      subtitle:
          'আপনি কি নিশ্চিতভাবে "$cropName" ফসলটির সকল তথ্য ও হিস্ট্রি সার্ভার থেকে স্থায়ীভাবে (Hard Delete) মুছে ফেলতে চান? এটি আর ফিরিয়ে আনা সম্ভব হবে না।',
      itemName: cropName,
    );

    if (confirmed) {
      try {
        await doc.reference.delete();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('"$cropName" ফসলটি ডাটাবেস থেকে স্থায়ীভাবে মুছে ফেলা হয়েছে!'),
              backgroundColor: AdminColors.alertCritical,
            ),
          );
        }
      } catch (e) {
        debugPrint('Hard delete crop error: $e');
      }
    }
  }

  // ====================== অ্যাডমিন অ্যাকশন: সফট ডিলিট রিস্টোর ======================
  Future<void> _restoreCrop(DocumentSnapshot doc, String cropName) async {
    try {
      await doc.reference.update({
        'isDeleted': false,
        'restoredAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('"$cropName" ফসলটি পুনরায় সচল তালিকায় ফিরিয়ে নেওয়া হয়েছে!'),
            backgroundColor: AdminColors.primary,
          ),
        );
      }
    } catch (e) {
      debugPrint('Restore crop error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AdminColors.background,
      child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        // রিকোয়ারমেন্ট ৩: CollectionGroup দিয়ে সব ইউজারের সেচ ট্র্যাকারের ডাটা রিয়েল-টাইমে আনা
        stream: FirebaseFirestore.instance
            .collectionGroup('irrigation_tracker_crops')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
            return const Center(child: CircularProgressIndicator(color: AdminColors.primary));
          }

          final allDocs = snapshot.data?.docs ?? [];

          // ফিল্টারিং: Active Crops vs Deleted Folder
          final List<DocumentSnapshot<Map<String, dynamic>>> activeDocs = [];
          final List<DocumentSnapshot<Map<String, dynamic>>> deletedDocs = [];
          final Set<String> uniqueUserIds = {};

          for (final doc in allDocs) {
            final data = doc.data();
            final uid = (data['userId']?.toString() ?? '').trim();
            if (uid.isNotEmpty) uniqueUserIds.add(uid);

            final isDeleted = data['isDeleted'] == true;
            if (isDeleted) {
              deletedDocs.add(doc);
            } else {
              activeDocs.add(doc);
            }
          }

          // সাজানো: নতুন থেকে পুরাতন
          int compareDocs(DocumentSnapshot a, DocumentSnapshot b) {
            final aData = a.data() as Map<String, dynamic>? ?? {};
            final bData = b.data() as Map<String, dynamic>? ?? {};
            final aTime = (aData['createdAt'] as Timestamp?)?.toDate() ??
                (aData['updatedAt'] as Timestamp?)?.toDate() ??
                DateTime(2020);
            final bTime = (bData['createdAt'] as Timestamp?)?.toDate() ??
                (bData['updatedAt'] as Timestamp?)?.toDate() ??
                DateTime(2020);
            return bTime.compareTo(aTime);
          }

          activeDocs.sort(compareDocs);
          deletedDocs.sort(compareDocs);

          // সার্চ ফিল্টারিং হেল্পার
          List<DocumentSnapshot<Map<String, dynamic>>> filterBySearch(
              List<DocumentSnapshot<Map<String, dynamic>>> list) {
            if (_searchQuery.isEmpty) return list;
            return list.where((doc) {
              final d = doc.data();
              final cropName = (d['cropName']?.toString() ?? '').toLowerCase();
              final email = (d['userEmail']?.toString() ?? '').toLowerCase();
              final phone = (d['userPhone']?.toString() ?? '').toLowerCase();
              final uid = (d['userId']?.toString() ?? '').toLowerCase();
              final dist = (d['weatherDistrict']?.toString() ?? '').toLowerCase();
              final details = (d['cropDetails']?.toString() ?? '').toLowerCase();

              return cropName.contains(_searchQuery) ||
                  email.contains(_searchQuery) ||
                  phone.contains(_searchQuery) ||
                  uid.contains(_searchQuery) ||
                  dist.contains(_searchQuery) ||
                  details.contains(_searchQuery);
            }).toList();
          }

          final filteredActiveDocs = filterBySearch(activeDocs);
          final filteredDeletedDocs = filterBySearch(deletedDocs);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ১. ব্যানার হেডার
                _buildBannerHeader(),

                const SizedBox(height: 20),

                // ২. মেট্রিক স্ট্যাট কার্ডসমূহ
                _buildMetricsOverview(
                  totalCount: allDocs.length,
                  activeCount: activeDocs.length,
                  deletedCount: deletedDocs.length,
                  userCount: uniqueUserIds.length,
                ),

                const SizedBox(height: 20),

                // ৩. সার্চ বার ও ট্যাব বার কার্ড
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AdminColors.border),
                    boxShadow: const [
                      BoxShadow(
                        color: AdminColors.cardShadow,
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // সার্চ বার
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _searchCtrl,
                              decoration: InputDecoration(
                                hintText:
                                    'ইউজারের ইমেইল, ফোন নাম্বার, জেলা অথবা ফসলের নাম দিয়ে সার্চ করুন...',
                                hintStyle: const TextStyle(fontSize: 13, color: AdminColors.textMuted),
                                prefixIcon: const Icon(Icons.search_rounded, color: AdminColors.primary, size: 22),
                                suffixIcon: _searchQuery.isNotEmpty
                                    ? IconButton(
                                        icon: const Icon(Icons.clear, size: 18),
                                        onPressed: () => _searchCtrl.clear(),
                                      )
                                    : null,
                                filled: true,
                                fillColor: const Color(0xFFF9FAF9),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
                                  borderSide: const BorderSide(color: AdminColors.primary, width: 1.8),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // রিকোয়ারমেন্ট ২: দুটি ট্যাব (Active Crops ও Deleted Folder)
                      Container(
                        height: 48,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F8E9),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: TabBar(
                          controller: _tabController,
                          indicator: BoxDecoration(
                            color: AdminColors.primary,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          labelColor: Colors.white,
                          unselectedLabelColor: AdminColors.textSecondary,
                          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                          tabs: [
                            Tab(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.eco_rounded, size: 18),
                                  const SizedBox(width: 8),
                                  Text('সচল ফসল (Active Crops) - ${_toBangla(filteredActiveDocs.length)}টি'),
                                ],
                              ),
                            ),
                            Tab(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.delete_outline_rounded, size: 18),
                                  const SizedBox(width: 8),
                                  Text('ডিলিট ফোল্ডার (Deleted Folder) - ${_toBangla(filteredDeletedDocs.length)}টি'),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // ৪. ট্যাব ভিউ কন্টেন্ট
                SizedBox(
                  height: 600,
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      // ট্যাব ১: Active Crops
                      _buildCropsListView(
                        docs: filteredActiveDocs,
                        isDeletedTab: false,
                      ),
                      // ট্যাব ২: Deleted Folder
                      _buildCropsListView(
                        docs: filteredDeletedDocs,
                        isDeletedTab: true,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  /// ব্যানার হেডার
  Widget _buildBannerHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1B5E20), Color(0xFF2E7D32)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1B5E20).withOpacity(0.25),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.18),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.water_drop_rounded, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'হোমপেজ • সেচ ট্র্যাকার মনিটরিং ও কন্ট্রোল',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'সকল ব্যবহারকারীর জমির সেচ পরিকল্পনা, ফসলের অবস্থা ও এআই নির্দেশনা পর্যবেক্ষণ ও রিয়েল-টাইম পরিচালনা।',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 12.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// মেট্রিক ওভারভিউ কার্ডসমূহ
  Widget _buildMetricsOverview({
    required int totalCount,
    required int activeCount,
    required int deletedCount,
    required int userCount,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmall = constraints.maxWidth < 800;
        return GridView.count(
          crossAxisCount: isSmall ? 2 : 4,
          crossAxisSpacing: 14,
          mainAxisSpacing: 14,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: isSmall ? 1.6 : 2.1,
          children: [
            AdminStatCard(
              title: 'মোট ট্র্যাকিং রেকর্ড',
              value: _toBangla(totalCount),
              icon: Icons.layers_rounded,
              iconBgColor: const Color(0xFFE8F5E9),
              iconColor: const Color(0xFF2E7D32),
              subtitle: 'ডাটাবেসের সকল রেকর্ড',
            ),
            AdminStatCard(
              title: 'সচল ফসল (Active)',
              value: _toBangla(activeCount),
              icon: Icons.eco_rounded,
              iconBgColor: const Color(0xFFE1F5FE),
              iconColor: const Color(0xFF0288D1),
              subtitle: 'বর্তমানে কৃষকদের তালিকায়',
            ),
            AdminStatCard(
              title: 'ডিলিট ফোল্ডার (Soft)',
              value: _toBangla(deletedCount),
              icon: Icons.delete_sweep_rounded,
              iconBgColor: const Color(0xFFFFEBEE),
              iconColor: const Color(0xFFD32F2F),
              subtitle: 'কৃষক কর্তৃক ডিলিটকৃত',
            ),
            AdminStatCard(
              title: 'মোট কৃষক ব্যবহারকারী',
              value: _toBangla(userCount),
              icon: Icons.people_alt_rounded,
              iconBgColor: const Color(0xFFFFF3E0),
              iconColor: const Color(0xFFE65100),
              subtitle: 'সেচ ট্র্যাকার ব্যবহারকারী',
            ),
          ],
        );
      },
    );
  }

  /// ক্রপস লিস্ট ভিউ (Active Crops অথবা Deleted Folder)
  Widget _buildCropsListView({
    required List<DocumentSnapshot<Map<String, dynamic>>> docs,
    required bool isDeletedTab,
  }) {
    if (docs.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AdminColors.border),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isDeletedTab ? Icons.delete_outline_rounded : Icons.search_off_rounded,
                size: 48,
                color: Colors.grey.shade400,
              ),
              const SizedBox(height: 12),
              Text(
                isDeletedTab
                    ? 'ডিলিট ফোল্ডারে কোনো ফসল পাওয়া যায়নি'
                    : 'কোনো সচল ফসল পাওয়া যায়নি',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AdminColors.textPrimary),
              ),
              const SizedBox(height: 6),
              Text(
                isDeletedTab
                    ? 'কৃষক কোনো ফসল ডিলিট করলে তা এই ফোল্ডারে সংরক্ষিত থাকবে।'
                    : 'ইউজাররা যখন সেচ ট্র্যাকারে নতুন ফসল যুক্ত করবেন তখন এখানে দৃশ্যমান হবে।',
                style: const TextStyle(fontSize: 12.5, color: AdminColors.textMuted),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      itemCount: docs.length,
      itemBuilder: (context, idx) {
        final doc = docs[idx];
        final data = doc.data() ?? {};
        return _buildCropAdminCard(doc, data, isDeletedTab);
      },
    );
  }

  /// প্রতিটি ফসলের জন্য সম্পূর্ণ তথ্যসহ অ্যাডমিন কার্ড
  Widget _buildCropAdminCard(
    DocumentSnapshot doc,
    Map<String, dynamic> data,
    bool isDeletedTab,
  ) {
    final cropName = data['cropName']?.toString() ?? 'নামহীন ফসল';
    final landAmount = data['landAmount']?.toString() ?? '-';
    final cropAge = data['cropAge']?.toString() ?? '-';
    final cropDetails = data['cropDetails']?.toString() ?? '';
    final aiStatus = data['aiStatus']?.toString() ?? '💧 হালকা সেচ দিন';
    final aiAdvice = data['aiAdvice']?.toString() ?? 'কোনো নির্দেশনা নেই';

    final userEmail = data['userEmail']?.toString() ?? '';
    final userPhone = data['userPhone']?.toString() ?? '';
    final userId = data['userId']?.toString() ?? doc.reference.parent.parent?.id ?? 'অজ্ঞাত';

    final weatherDistrict = data['weatherDistrict']?.toString() ?? 'ঢাকা';
    final weatherTemp = data['weatherTemp']?.toString() ?? '--';
    final weatherHumidity = data['weatherHumidity']?.toString() ?? '--';

    final createdAt = _formatTimestamp(data['createdAt']);
    final lastUpdated = _formatTimestamp(data['last_updated'] ?? data['updatedAt']);
    final deletedAt = data['deletedAt'] != null ? _formatTimestamp(data['deletedAt']) : null;

    final expiryRaw = data['expiryDate'];
    DateTime? expDate;
    if (expiryRaw is Timestamp) {
      expDate = expiryRaw.toDate();
    } else if (expiryRaw is DateTime) {
      expDate = expiryRaw;
    } else if (expiryRaw is String) {
      expDate = DateTime.tryParse(expiryRaw);
    }
    final bool isExpired = expDate != null && DateTime.now().isAfter(expDate);

    Color statusColor = const Color(0xFF2E7D32);
    Color statusBg = const Color(0xFFE8F5E9);
    if (aiStatus.contains('প্রয়োজন নেই') || aiStatus.contains('না')) {
      statusColor = const Color(0xFF2E7D32);
      statusBg = const Color(0xFFE8F5E9);
    } else if (aiStatus.contains('জরুরি') || aiStatus.contains('বেশি')) {
      statusColor = const Color(0xFFE65100);
      statusBg = const Color(0xFFFFF3E0);
    } else {
      statusColor = const Color(0xFF0288D1);
      statusBg = const Color(0xFFE1F5FE);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDeletedTab ? const Color(0xFFFFCDD2) : AdminColors.border,
          width: isDeletedTab ? 1.4 : 1.0,
        ),
        boxShadow: const [
          BoxShadow(
            color: AdminColors.cardShadow,
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // শীর্ষ সারি: ফসলের নাম, স্ট্যাটাস ব্যাজ ও অ্যাকশন বাটনসমূহ
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: isDeletedTab ? const Color(0xFFFFEBEE) : statusBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Icon(
                    isDeletedTab ? Icons.delete_outline_rounded : Icons.water_drop_rounded,
                    color: isDeletedTab ? const Color(0xFFD32F2F) : statusColor,
                    size: 24,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          cropName,
                          style: const TextStyle(
                            fontSize: 16.5,
                            fontWeight: FontWeight.bold,
                            color: AdminColors.textPrimary,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                          decoration: BoxDecoration(
                            color: statusBg,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            aiStatus,
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.bold,
                              color: statusColor,
                            ),
                          ),
                        ),
                        if (isDeletedTab) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFEBEE),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: const Color(0xFFEF9A9A)),
                            ),
                            child: const Text(
                              'সফট ডিলিট',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFD32F2F),
                              ),
                            ),
                          ),
                        ] else if (isExpired) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF3E0),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: const Color(0xFFFFB74D)),
                            ),
                            child: const Text(
                              'মেয়াদ উত্তীর্ণ',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFE65100),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    // ইউজার আইডেন্টিটি ব্যাজ
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        if (userEmail.isNotEmpty)
                          _buildBadge(Icons.email_outlined, userEmail, const Color(0xFF1976D2)),
                        if (userPhone.isNotEmpty)
                          _buildBadge(Icons.phone_outlined, userPhone, const Color(0xFF388E3C)),
                        _buildBadge(Icons.badge_outlined, 'UID: $userId', const Color(0xFF5D4037)),
                      ],
                    ),
                  ],
                ),
              ),
              // অ্যাডমিন অ্যাকশন বাটনসমূহ (Edit & Delete)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isDeletedTab)
                    IconButton(
                      icon: const Icon(Icons.restore_rounded, color: Color(0xFF2E7D32)),
                      tooltip: 'সচল তালিকায় ফিরিয়ে আনুন (Restore)',
                      onPressed: () => _restoreCrop(doc, cropName),
                    ),
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, color: AdminColors.primary),
                    tooltip: 'তথ্য বা এআই পরামর্শ এডিট করুন',
                    onPressed: () => _openEditCropModal(doc, data),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_forever_rounded, color: Color(0xFFD32F2F)),
                    tooltip: 'সার্ভার থেকে চিরতরে মুছে ফেলুন (Hard Delete)',
                    onPressed: () => _hardDeleteCrop(doc, cropName),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 12),
          const Divider(height: 1, color: AdminColors.divider),
          const SizedBox(height: 12),

          // প্যারামিটার ও বিস্তারিত তথ্য গ্রিড
          Row(
            children: [
              Expanded(
                child: _buildMetaInfo('জমির পরিমাণ', landAmount, Icons.square_foot_rounded),
              ),
              Expanded(
                child: _buildMetaInfo('ফসলের বয়স', cropAge, Icons.hourglass_top_rounded),
              ),
              Expanded(
                child: _buildMetaInfo(
                  'ট্র্যাকিং মেয়াদ',
                  expDate != null
                      ? '${_toBangla(expDate.day)}/${_toBangla(expDate.month)}/${_toBangla(expDate.year)} ${isExpired ? '(উত্তীর্ণ)' : ''}'
                      : 'অনির্ধারিত',
                  Icons.calendar_month_outlined,
                ),
              ),
              Expanded(
                child: _buildMetaInfo('আবহাওয়া ($weatherDistrict)', '🌡️ $weatherTemp°C | 💧 $weatherHumidity%', Icons.cloud_outlined),
              ),
            ],
          ),

          if (cropDetails.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFF9FAF9),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AdminColors.border),
              ),
              child: RichText(
                text: TextSpan(
                  children: [
                    const TextSpan(
                      text: 'কৃষকের দেওয়া বিবরণ: ',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AdminColors.textPrimary),
                    ),
                    TextSpan(
                      text: cropDetails,
                      style: const TextStyle(fontSize: 12, color: AdminColors.textSecondary),
                    ),
                  ],
                ),
              ),
            ),
          ],

          const SizedBox(height: 10),

          // এআই পরামর্শ কার্ড
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: statusBg.withOpacity(0.5),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: statusColor.withOpacity(0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.lightbulb_outline_rounded, color: statusColor, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      'কৃষককে দেওয়া এআই সেচ নির্দেশনা',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: statusColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  aiAdvice,
                  style: const TextStyle(fontSize: 12.5, color: AdminColors.textPrimary, height: 1.4),
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // সময়কাল ফুটার
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'যোগ করার সময়: $createdAt',
                style: const TextStyle(fontSize: 11, color: AdminColors.textMuted),
              ),
              Text(
                'শেষ এআই আপডেট: $lastUpdated',
                style: const TextStyle(fontSize: 11, color: AdminColors.textMuted),
              ),
              if (deletedAt != null)
                Text(
                  'ডিলিট করার সময়: $deletedAt',
                  style: const TextStyle(fontSize: 11, color: Color(0xFFD32F2F), fontWeight: FontWeight.bold),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBadge(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(fontSize: 10.5, color: color, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildMetaInfo(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 15, color: AdminColors.primary),
        const SizedBox(width: 6),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 10.5, color: AdminColors.textMuted)),
              Text(
                value,
                style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: AdminColors.textPrimary),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
