import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants/admin_colors.dart';
import '../widgets/admin_loading_indicator.dart';

class AdminIncomeExpenseHistoryPage extends StatefulWidget {
  const AdminIncomeExpenseHistoryPage({super.key});

  @override
  State<AdminIncomeExpenseHistoryPage> createState() => _AdminIncomeExpenseHistoryPageState();
}

typedef AdminIncomeExpenseHistoryScreen = AdminIncomeExpenseHistoryPage;

class _AdminIncomeExpenseHistoryPageState extends State<AdminIncomeExpenseHistoryPage> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _selectedStatusFilter = 'all'; // 'all', 'profit', 'loss', 'active', 'deleted'
  late final Stream<List<Map<String, dynamic>>> _incomeExpenseStream;

  @override
  void initState() {
    super.initState();
    _incomeExpenseStream = _createIncomeExpenseStream();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  /// রিয়েল-টাইম ফায়ারবেস স্ট্রিম যা 'agricultural_accounts' এবং 'user_income_expense_history'
  /// উভয় কালেকশন থেকেই লাইভ সিঙ্ক করে এবং কোনো ডুপ্লিকেট না রেখে নতুন থেকে পুরাতন ক্রমানুসারে সাজায়।
  Stream<List<Map<String, dynamic>>> _createIncomeExpenseStream() {
    late StreamController<List<Map<String, dynamic>>> controller;
    StreamSubscription? sub1;
    StreamSubscription? sub2;
    final Map<String, Map<String, dynamic>> map1 = {};
    final Map<String, Map<String, dynamic>> map2 = {};

    void emitMerged() {
      if (!controller.isClosed) {
        final combined = <String, Map<String, dynamic>>{...map1, ...map2};
        final list = combined.values.toList();
        list.sort((a, b) {
          final aDate = (a['createdAt'] as Timestamp?)?.toDate() ??
              DateTime.tryParse(a['date']?.toString() ?? '') ??
              DateTime(2000);
          final bDate = (b['createdAt'] as Timestamp?)?.toDate() ??
              DateTime.tryParse(b['date']?.toString() ?? '') ??
              DateTime(2000);
          return bDate.compareTo(aDate);
        });
        controller.add(list);
      }
    }

    controller = StreamController<List<Map<String, dynamic>>>(
      onListen: () {
        sub1 = FirebaseFirestore.instance
            .collection('agricultural_accounts')
            .snapshots(includeMetadataChanges: false)
            .listen((snap) {
          map1.clear();
          for (var doc in snap.docs) {
            map1[doc.id] = {'id': doc.id, ...doc.data()};
          }
          emitMerged();
        }, onError: (err) {
          emitMerged();
        });

        sub2 = FirebaseFirestore.instance
            .collection('user_income_expense_history')
            .snapshots(includeMetadataChanges: false)
            .listen((snap) {
          map2.clear();
          for (var doc in snap.docs) {
            map2[doc.id] = {'id': doc.id, ...doc.data()};
          }
          emitMerged();
        }, onError: (err) {
          emitMerged();
        });
      },
      onCancel: () {
        sub1?.cancel();
        sub2?.cancel();
      },
    );

    return controller.stream;
  }

  String _toBn(String s) {
    const eng = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
    const bng = ['০', '১', '২', '৩', '৪', '৫', '৬', '৭', '৮', '৯'];
    for (int i = 0; i < eng.length; i++) {
      s = s.replaceAll(eng[i], bng[i]);
    }
    return s;
  }

  String _formatDateTime(dynamic raw) {
    if (raw == null) return 'অনুপলব্ধ';
    DateTime dt;
    if (raw is Timestamp) {
      dt = raw.toDate();
    } else if (raw is DateTime) {
      dt = raw;
    } else {
      dt = DateTime.tryParse(raw.toString()) ?? DateTime.now();
    }
    final months = [
      'জানু', 'ফেব্রু', 'মার্চ', 'এপ্রিল', 'মে', 'জুন',
      'জুলাই', 'আগস্ট', 'সেপ্টে', 'অক্টো', 'নভে', 'ডিসে'
    ];
    final d = _toBn(dt.day.toString().padLeft(2, '0'));
    final m = months[dt.month - 1];
    final y = _toBn(dt.year.toString());
    final hr = _toBn((dt.hour % 12 == 0 ? 12 : dt.hour % 12).toString().padLeft(2, '0'));
    final min = _toBn(dt.minute.toString().padLeft(2, '0'));
    final ampm = dt.hour >= 12 ? 'বিকাল' : 'সকাল';
    return '$d $m $y, $hr:$min $ampm';
  }

  String _formatCurrency(num amount) {
    final absAmount = amount.abs();
    final formatted = absAmount % 1 == 0 ? absAmount.toInt().toString() : absAmount.toStringAsFixed(2);
    final sign = amount < 0 ? '- ' : '';
    return '$sign৳ ${_toBn(formatted)}';
  }

  // ==================== MAIN BUILD METHOD ====================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AdminColors.background,
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _incomeExpenseStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
            return const AdminLoadingIndicator(message: 'তথ্য লোডিং হচ্ছে.....');
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Text('ডেটা লোড করতে সমস্যা হয়েছে: ${snapshot.error}', style: const TextStyle(color: AdminColors.alertCritical)),
              ),
            );
          }

          final allDocs = snapshot.data ?? [];

          // পরিসংখ্যান গণনা (KPI Metrics)
          final totalCount = allDocs.length;
          final deletedCount = allDocs.where((d) => d['isDeleted'] == true).length;
          final activeCount = totalCount - deletedCount;

          int profitCount = 0;
          int lossCount = 0;
          double sumIncome = 0;
          double sumExpense = 0;

          for (final data in allDocs) {
            final inc = (data['totalIncome'] as num?)?.toDouble() ?? 0.0;
            final exp = (data['totalExpense'] as num?)?.toDouble() ?? 0.0;
            final net = (data['netProfitLoss'] as num?)?.toDouble() ?? (inc - exp);
            sumIncome += inc;
            sumExpense += exp;
            if (net >= 0) {
              profitCount++;
            } else {
              lossCount++;
            }
          }

          // সার্চ এবং ফিল্টারিং লজিক (Filter Chips & Search Bar)
          final query = _searchCtrl.text.trim().toLowerCase();
          final filteredDocs = allDocs.where((data) {
            final isDel = data['isDeleted'] == true;
            final inc = (data['totalIncome'] as num?)?.toDouble() ?? 0.0;
            final exp = (data['totalExpense'] as num?)?.toDouble() ?? 0.0;
            final net = (data['netProfitLoss'] as num?)?.toDouble() ?? (inc - exp);

            // স্ট্যাটাস ফিল্টার ম্যাচিং
            if (_selectedStatusFilter == 'active' && isDel) return false;
            if (_selectedStatusFilter == 'deleted' && !isDel) return false;
            if (_selectedStatusFilter == 'profit' && net < 0) return false;
            if (_selectedStatusFilter == 'loss' && net >= 0) return false;

            // সার্চ কোয়েরি ফিল্টারিং (নাম, ইমেইল, ফোন, ফসল ও বিবরণ)
            if (query.isNotEmpty) {
              final title = (data['title']?.toString() ?? '').toLowerCase();
              final crop = (data['cropName']?.toString() ?? data['crop']?.toString() ?? '').toLowerCase();
              final name = (data['userName']?.toString() ?? data['farmerName']?.toString() ?? '').toLowerCase();
              final email = (data['userEmail']?.toString() ?? data['email']?.toString() ?? '').toLowerCase();
              final phone = (data['userPhone']?.toString() ?? data['phone']?.toString() ?? '').toLowerCase();
              final uid = (data['userId']?.toString() ?? data['uid']?.toString() ?? '').toLowerCase();
              return title.contains(query) || crop.contains(query) || name.contains(query) || email.contains(query) || phone.contains(query) || uid.contains(query);
            }
            return true;
          }).toList();

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ১. ইউজার কন্ট্রোলের মতো ৪টি কালারফুল কার্ড (নীল, সবুজ, কমলা, লাল)
                _buildTopColorfulSummaryCards(
                  totalCount: totalCount,
                  sumIncome: sumIncome,
                  sumExpense: sumExpense,
                  deletedCount: deletedCount,
                ),

                const SizedBox(height: 16),

                // ২. মেইন টেবিল কার্ড কন্টেইনার (হুবহু ইউজার কন্ট্রোল স্টাইল)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AdminColors.border),
                    boxShadow: const [
                      BoxShadow(color: Color(0x06000000), blurRadius: 6, offset: Offset(0, 2)),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // হেডার ও সার্চ বার রো
                      Wrap(
                        spacing: 12,
                        runSpacing: 10,
                        alignment: WrapAlignment.spaceBetween,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text(
                                'কৃষি আয়-ব্যায় হিস্ট্রি তালিকা',
                                style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.bold, color: AdminColors.textPrimary),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: AdminColors.primaryContainer,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  'মোট ${_toBn(filteredDocs.length.toString())} টি',
                                  style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: AdminColors.primaryDark),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(
                            width: 280,
                            height: 38,
                            child: TextField(
                              controller: _searchCtrl,
                              onChanged: (_) => setState(() {}),
                              style: const TextStyle(fontSize: 12.5),
                              decoration: InputDecoration(
                                hintText: 'কৃষক, ইমেইল, ফোন, ফসল দিয়ে খুঁজুন...',
                                hintStyle: const TextStyle(fontSize: 12, color: AdminColors.textMuted),
                                prefixIcon: const Icon(Icons.search_rounded, size: 18, color: AdminColors.primary),
                                suffixIcon: _searchCtrl.text.isNotEmpty
                                    ? IconButton(
                                        icon: const Icon(Icons.clear, size: 16),
                                        onPressed: () {
                                          _searchCtrl.clear();
                                          setState(() {});
                                        },
                                      )
                                    : null,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AdminColors.border)),
                                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AdminColors.border)),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      // স্ট্যাটাস ফিল্টার পিলস (হুবহু ইউজার কন্ট্রোলের মতো)
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          _buildFilterPill('all', 'সকল (${_toBn(totalCount.toString())})'),
                          _buildFilterPill('profit', 'লাভজনক (${_toBn(profitCount.toString())})'),
                          _buildFilterPill('loss', 'ক্ষতিগ্রস্ত (${_toBn(lossCount.toString())})'),
                          _buildFilterPill('active', 'সচল (${_toBn(activeCount.toString())})'),
                          _buildFilterPill('deleted', 'ইউজার ডিলিট করেছে (${_toBn(deletedCount.toString())})'),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // কম্প্যাক্ট টেবিল হেডার
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF4F7F4),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AdminColors.border),
                        ),
                        child: const Row(
                          children: [
                            Expanded(flex: 3, child: Text('ইউজারের তথ্য', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5, color: AdminColors.textPrimary))),
                            Expanded(flex: 2, child: Text('মোবাইল নম্বর', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5, color: AdminColors.textPrimary))),
                            Expanded(flex: 2, child: Text('ফসলের বিবরণ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5, color: AdminColors.textPrimary))),
                            Expanded(flex: 2, child: Text('মোট আয় ও ব্যয়', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5, color: AdminColors.textPrimary))),
                            Expanded(flex: 2, child: Center(child: Text('নিট লাভ/ক্ষতি', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5, color: AdminColors.textPrimary)))),
                            Expanded(flex: 2, child: Center(child: Text('স্ট্যাটাস', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5, color: AdminColors.textPrimary)))),
                            SizedBox(width: 80, child: Center(child: Text('অ্যাকশন', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5, color: AdminColors.textPrimary)))),
                          ],
                        ),
                      ),

                      const SizedBox(height: 6),

                      // ডেটা রো তালিকা
                      if (filteredDocs.isEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 36),
                          alignment: Alignment.center,
                          child: const Column(
                            children: [
                              Icon(Icons.receipt_long_outlined, size: 36, color: AdminColors.textMuted),
                              SizedBox(height: 8),
                              Text('কোনো হিসাব পাওয়া যায়নি', style: TextStyle(fontSize: 13, color: AdminColors.textMuted)),
                            ],
                          ),
                        )
                      else
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: filteredDocs.length,
                          separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xFFF0F0F0)),
                          itemBuilder: (context, index) {
                            final data = filteredDocs[index];
                            return _buildCompactIncomeExpenseRow(data, context);
                          },
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

  // ==================== ১. TOP COLORFUL SUMMARY CARDS (নীল, সবুজ, কমলা, লাল) ====================
  Widget _buildTopColorfulSummaryCards({
    required int totalCount,
    required double sumIncome,
    required double sumExpense,
    required int deletedCount,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 700;
        final cardWidth = isWide ? (constraints.maxWidth - 36) / 4 : (constraints.maxWidth - 12) / 2;

        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            // ১ম কার্ড (নীল): "সংরক্ষিত হিসাব"
            _buildGradientStatCard(
              title: 'সংরক্ষিত হিসাব',
              value: '${_toBn(totalCount.toString())} টি',
              icon: Icons.receipt_long_rounded,
              gradient: const LinearGradient(
                colors: [Color(0xFF6366F1), Color(0xFF4338CA)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shadowColor: const Color(0x406366F1),
              width: cardWidth,
            ),

            // ২য় কার্ড (সবুজ): "সর্বমোট কৃষক আয়"
            _buildGradientStatCard(
              title: 'সর্বমোট কৃষক আয়',
              value: _formatCurrency(sumIncome),
              icon: Icons.trending_up_rounded,
              gradient: const LinearGradient(
                colors: [Color(0xFF10B981), Color(0xFF059669)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shadowColor: const Color(0x4010B981),
              width: cardWidth,
            ),

            // ৩য় কার্ড (কমলা/হলুদ): "সর্বমোট কৃষক ব্যয়"
            _buildGradientStatCard(
              title: 'সর্বমোট কৃষক ব্যয়',
              value: _formatCurrency(sumExpense),
              icon: Icons.trending_down_rounded,
              gradient: const LinearGradient(
                colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shadowColor: const Color(0x40F59E0B),
              width: cardWidth,
            ),

            // ৪র্থ কার্ড (লাল): "ডিলিট হিসাব"
            _buildGradientStatCard(
              title: 'ডিলিট হিসাব',
              value: '${_toBn(deletedCount.toString())} টি',
              icon: Icons.delete_sweep_rounded,
              gradient: const LinearGradient(
                colors: [Color(0xFFF43F5E), Color(0xFFBE123C)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shadowColor: const Color(0x40F43F5E),
              width: cardWidth,
            ),
          ],
        );
      },
    );
  }

  Widget _buildGradientStatCard({
    required String title,
    required String value,
    required IconData icon,
    required LinearGradient gradient,
    required Color shadowColor,
    required double width,
  }) {
    return Container(
      width: width,
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: shadowColor,
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Stack(
          children: [
            // ব্যাকগ্রাউন্ড ওয়াটারমার্ক আইকন
            Positioned(
              right: -10,
              bottom: -10,
              child: Icon(
                icon,
                size: 64,
                color: Colors.white.withOpacity(0.16),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // টাইটেল ও ছোট আইকন বক্স
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.white.withOpacity(0.92),
                            letterSpacing: 0.2,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(icon, color: Colors.white, size: 16),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  // বড় বোল্ড ভ্যালু
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      height: 1.1,
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

  // ==================== FILTER PILL ====================
  Widget _buildFilterPill(String key, String label) {
    final isSelected = _selectedStatusFilter == key;
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () => setState(() => _selectedStatusFilter = key),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? AdminColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? AdminColors.primary : AdminColors.border),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? Colors.white : AdminColors.textSecondary,
          ),
        ),
      ),
    );
  }

  // ==================== ২. COMPACT DATA ROW (নামের নিচে ইমেইল সহ) ====================
  Widget _buildCompactIncomeExpenseRow(Map<String, dynamic> data, BuildContext context) {
    final title = data['title']?.toString() ?? data['cropName']?.toString() ?? 'কৃষি হিসাব';
    final userName = data['userName']?.toString() ?? data['farmerName']?.toString() ?? 'কৃষক ভাই';
    final userEmail = data['userEmail']?.toString() ?? data['email']?.toString() ?? '';
    final userPhone = data['userPhone']?.toString() ?? data['phone']?.toString() ?? 'ফোন নেই';
    final isDeleted = data['isDeleted'] == true;

    final totalIncome = (data['totalIncome'] as num?)?.toDouble() ?? 0.0;
    final totalExpense = (data['totalExpense'] as num?)?.toDouble() ?? 0.0;
    final netProfitLoss = (data['netProfitLoss'] as num?)?.toDouble() ?? (totalIncome - totalExpense);
    final isProfit = netProfitLoss >= 0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isDeleted ? const Color(0xFFFFFBFB) : Colors.white,
      ),
      child: Row(
        children: [
          // ১. ইউজারের তথ্য: কৃষকের নাম ও নিচে ইমেইল (হুবহু ইউজার কন্ট্রোলের মতো)
          Expanded(
            flex: 3,
            child: Row(
              children: [
                CircleAvatar(
                  radius: 14,
                  backgroundColor: AdminColors.primaryContainer,
                  child: Text(
                    userName.isNotEmpty ? userName[0].toUpperCase() : 'ক',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                      color: AdminColors.primaryDark,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        userName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: AdminColors.textPrimary),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        userEmail.isNotEmpty ? userEmail : 'ইমেইল নিবন্ধিত নেই',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 11, color: AdminColors.textMuted),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ২. মোবাইল নম্বর
          Expanded(
            flex: 2,
            child: Text(
              userPhone.isNotEmpty ? userPhone : 'ফোন নেই',
              style: const TextStyle(fontSize: 12, color: AdminColors.textSecondary),
            ),
          ),

          // ৩. ফসলের বিবরণ
          Expanded(
            flex: 2,
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, color: AdminColors.textSecondary),
            ),
          ),

          // ৪. মোট আয় ও মোট ব্যয়
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'আয়: ${_formatCurrency(totalIncome)}',
                  style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Color(0xFF2E7D32)),
                ),
                Text(
                  'ব্যয়: ${_formatCurrency(totalExpense)}',
                  style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Color(0xFFC62828)),
                ),
              ],
            ),
          ),

          // ৫. নিট লাভ/ক্ষতি ব্যাজ
          Expanded(
            flex: 2,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isProfit ? const Color(0xFFE8F5E9) : const Color(0xFFFFEBEE),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isProfit ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
                      size: 11,
                      color: isProfit ? const Color(0xFF2E7D32) : const Color(0xFFC62828),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _formatCurrency(netProfitLoss),
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.bold,
                        color: isProfit ? const Color(0xFF2E7D32) : const Color(0xFFC62828),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ৬. ডিলিট স্ট্যাটাস ব্যাজ
          Expanded(
            flex: 2,
            child: Center(
              child: _buildDeleteStatusBadge(isDeleted),
            ),
          ),

          // ৭. বিস্তারিত বাটন (হুবহু ইউজার কন্ট্রোলের আউটলাইন্ড বাটন)
          SizedBox(
            width: 80,
            child: Center(
              child: SizedBox(
                height: 28,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    side: const BorderSide(color: AdminColors.primary, width: 1.2),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                    foregroundColor: AdminColors.primaryDark,
                  ),
                  onPressed: () => _showMemoDetailsDialog(context, data),
                  child: const Text('বিস্তারিত', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeleteStatusBadge(bool isDeleted) {
    final bg = isDeleted ? const Color(0xFFFFEBEE) : const Color(0xFFE8F5E9);
    final fg = isDeleted ? AdminColors.alertCritical : const Color(0xFF2E7D32);
    final text = isDeleted ? 'ডিলিটকৃত' : 'সচল';
    final icon = isDeleted ? Icons.delete_sweep_rounded : Icons.check_circle_rounded;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: fg),
          const SizedBox(width: 4),
          Text(text, style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: fg)),
        ],
      ),
    );
  }

  // ==================== MEMO DETAILS MODAL DIALOG ====================
  void _showMemoDetailsDialog(BuildContext context, Map<String, dynamic> data) {
    final title = data['title']?.toString() ?? data['cropName']?.toString() ?? 'কৃষি আয়-ব্যয় হিসাব';
    final userName = data['userName']?.toString() ?? data['farmerName']?.toString() ?? 'কৃষক ভাই';
    final userEmail = data['userEmail']?.toString() ?? data['email']?.toString() ?? 'নিবন্ধিত নেই';
    final userPhone = data['userPhone']?.toString() ?? data['phone']?.toString() ?? 'প্রদান করা হয়নি';
    final userId = data['userId']?.toString() ?? data['uid']?.toString() ?? 'N/A';
    final isDeleted = data['isDeleted'] == true;
    final totalIncome = (data['totalIncome'] as num?)?.toDouble() ?? 0.0;
    final totalExpense = (data['totalExpense'] as num?)?.toDouble() ?? 0.0;
    final netProfitLoss = (data['netProfitLoss'] as num?)?.toDouble() ?? (totalIncome - totalExpense);
    final isProfit = netProfitLoss >= 0;

    final incomeDetailsRaw = data['incomeDetails'] as Map<String, dynamic>? ?? {};
    final expenseDetailsRaw = data['expenseDetails'] as Map<String, dynamic>? ?? {};
    final rawDate = data['createdAt'] ?? data['date'];

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 580),
          child: Padding(
            padding: const EdgeInsets.all(22),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // হেডার
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AdminColors.primaryContainer,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.receipt_long_rounded, color: AdminColors.primaryDark, size: 22),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'হিসাবের বিস্তারিত মেমো',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AdminColors.textPrimary),
                              ),
                              Text(
                                title,
                                style: const TextStyle(fontSize: 12.5, color: AdminColors.textSecondary),
                              ),
                            ],
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, size: 20, color: AdminColors.textMuted),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),
                  const Divider(color: AdminColors.divider),
                  const SizedBox(height: 14),

                  // ইউজার ও আবেদনকারী তথ্য ব্যানার
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF9FBF9),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AdminColors.border),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.person_rounded, size: 16, color: AdminColors.primary),
                                const SizedBox(width: 6),
                                Text('কৃষক: $userName', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AdminColors.textPrimary)),
                              ],
                            ),
                            _buildDeleteStatusBadge(isDeleted),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(Icons.email_outlined, size: 14, color: AdminColors.textMuted),
                            const SizedBox(width: 6),
                            Text('ইমেইল: $userEmail', style: const TextStyle(fontSize: 12, color: AdminColors.textSecondary)),
                            const SizedBox(width: 14),
                            const Icon(Icons.phone_rounded, size: 14, color: AdminColors.textMuted),
                            const SizedBox(width: 6),
                            Text('মোবাইল: $userPhone', style: const TextStyle(fontSize: 12, color: AdminColors.textSecondary)),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(Icons.calendar_today_outlined, size: 14, color: AdminColors.textMuted),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                'তারিখ: ${_formatDateTime(rawDate)}',
                                style: const TextStyle(fontSize: 11.5, color: AdminColors.textMuted),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 10),
                            const Icon(Icons.fingerprint_rounded, size: 14, color: AdminColors.textMuted),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                'UID: $userId',
                                style: const TextStyle(fontSize: 11, color: AdminColors.textMuted),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),

                  // নিট লাভ / ক্ষতি সারসংক্ষেপ কার্ড
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isProfit ? const Color(0xFFE8F5E9) : const Color(0xFFFFEBEE),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: isProfit ? const Color(0xFF81C784) : const Color(0xFFE57373)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isProfit ? 'অভিনন্দন! নিট লাভ হয়েছে' : 'সতর্কতা: নিট ক্ষতি হয়েছে',
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.bold,
                                color: isProfit ? const Color(0xFF1B5E20) : const Color(0xFFB71C1C),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _formatCurrency(netProfitLoss),
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                color: isProfit ? const Color(0xFF1B5E20) : const Color(0xFFB71C1C),
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                const Text('মোট আয়', style: TextStyle(fontSize: 11, color: AdminColors.textMuted)),
                                Text(_formatCurrency(totalIncome), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF2E7D32))),
                              ],
                            ),
                            const SizedBox(width: 14),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                const Text('মোট ব্যয়', style: TextStyle(fontSize: 11, color: AdminColors.textMuted)),
                                Text(_formatCurrency(totalExpense), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFFC62828))),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // আয়ের খাতসমূহ
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFC8E6C9)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.monetization_on_rounded, size: 16, color: Color(0xFF2E7D32)),
                            SizedBox(width: 6),
                            Text('আয়ের খাতসমূহ', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1B5E20))),
                          ],
                        ),
                        const SizedBox(height: 8),
                        _buildDetailRow('ফসল বিক্রয় থেকে আয়', (incomeDetailsRaw['cropSales'] as num?)?.toDouble() ?? 0.0),
                        _buildDetailRow('বীজ বিক্রয় থেকে আয়', (incomeDetailsRaw['seedSales'] as num?)?.toDouble() ?? 0.0),
                        _buildDetailRow('অন্যান্য উৎস থেকে আয়', (incomeDetailsRaw['otherIncome'] as num?)?.toDouble() ?? 0.0),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // ব্যয়ের খাতসমূহ
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFFFCDD2)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.receipt_rounded, size: 16, color: Color(0xFFC62828)),
                            SizedBox(width: 6),
                            Text('ব্যয়ের খাতসমূহ', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFFB71C1C))),
                          ],
                        ),
                        const SizedBox(height: 8),
                        _buildDetailRow('জমি প্রস্তুত ও চাষ খরচ', (expenseDetailsRaw['tillage'] as num?)?.toDouble() ?? 0.0, isExpense: true),
                        _buildDetailRow('বীজ ও চারা ক্রয় খরচ', (expenseDetailsRaw['seedBuy'] as num?)?.toDouble() ?? 0.0, isExpense: true),
                        _buildDetailRow('সার ও কীটনাশক খরচ', (expenseDetailsRaw['fertilizerPesticide'] as num?)?.toDouble() ?? 0.0, isExpense: true),
                        _buildDetailRow('সেচ ও জ্বালানি খরচ', (expenseDetailsRaw['irrigation'] as num?)?.toDouble() ?? 0.0, isExpense: true),
                        _buildDetailRow('শ্রমিক ও নিড়ানির মজুরি', (expenseDetailsRaw['labor'] as num?)?.toDouble() ?? 0.0, isExpense: true),
                        _buildDetailRow('পরিবহন ও অন্যান্য খরচ', (expenseDetailsRaw['transport'] as num?)?.toDouble() ?? 0.0, isExpense: true),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ফুটারে বাটন
                  Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AdminColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      ),
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('বন্ধ করুন', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String title, double amount, {bool isExpense = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3.5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(fontSize: 12.5, color: AdminColors.textSecondary)),
          Text(
            _formatCurrency(amount),
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.bold,
              color: isExpense ? const Color(0xFFC62828) : const Color(0xFF2E7D32),
            ),
          ),
        ],
      ),
    );
  }
}
