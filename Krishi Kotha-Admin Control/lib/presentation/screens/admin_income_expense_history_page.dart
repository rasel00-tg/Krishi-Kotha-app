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
  String _selectedFilter = 'all'; // 'all', 'active', 'deleted'

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
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
    if (raw == null) return 'অজানা তারিখ';
    DateTime dt;
    if (raw is Timestamp) {
      dt = raw.toDate();
    } else if (raw is DateTime) {
      dt = raw;
    } else {
      dt = DateTime.tryParse(raw.toString()) ?? DateTime.now();
    }
    final months = [
      'জানুয়ারি', 'ফেব্রুয়ারি', 'মার্চ', 'এপ্রিল', 'মে', 'জুন',
      'জুলাই', 'আগস্ট', 'সেপ্টেম্বর', 'অক্টোবর', 'নভেম্বর', 'ডিসেম্বর'
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

  void _showMemoDetailsDialog(BuildContext context, Map<String, dynamic> data) {
    final title = data['title']?.toString() ?? 'কৃষি আয়-ব্যয় হিসাব';
    final userName = data['userName']?.toString() ?? 'কৃষক ভাই';
    final userPhone = data['userPhone']?.toString() ?? 'প্রদান করা হয়নি';
    final userId = data['userId']?.toString() ?? data['uid']?.toString() ?? 'N/A';
    final isDeleted = data['isDeleted'] == true;
    final totalIncome = (data['totalIncome'] as num?)?.toDouble() ?? 0.0;
    final totalExpense = (data['totalExpense'] as num?)?.toDouble() ?? 0.0;
    final netProfitLoss = (data['netProfitLoss'] as num?)?.toDouble() ?? (totalIncome - totalExpense);
    final isProfit = netProfitLoss >= 0;

    final incomeDetailsRaw = data['incomeDetails'] as Map<String, dynamic>? ?? {};
    final expenseDetailsRaw = data['expenseDetails'] as Map<String, dynamic>? ?? {};

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Container(
          width: 580,
          padding: const EdgeInsets.all(24),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AdminColors.primary.withOpacity(0.12),
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
                      icon: const Icon(Icons.close_rounded, size: 20),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),

                const SizedBox(height: 16),
                const Divider(height: 1),
                const SizedBox(height: 14),

                // User Info Banner
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
                              Text('কৃষক: $userName', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: isDeleted ? AdminColors.alertCriticalBg : AdminColors.successBg,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: isDeleted ? AdminColors.alertCritical : AdminColors.success, width: 0.8),
                            ),
                            child: Text(
                              isDeleted ? 'ইউজার ডিলিট করেছে' : 'অ্যাক্টিভ হিসাব',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: isDeleted ? AdminColors.alertCritical : AdminColors.success,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.phone_rounded, size: 14, color: AdminColors.textMuted),
                          const SizedBox(width: 6),
                          Text('মোবাইল: $userPhone', style: const TextStyle(fontSize: 12, color: AdminColors.textSecondary)),
                          const SizedBox(width: 14),
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

                // Profit / Loss Summary Card
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

                // Income Breakdown
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

                // Expense Breakdown
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
                    child: const Text('বন্ধ করুন', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AdminColors.background,
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('agricultural_accounts')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
            return const AdminLoadingIndicator(message: 'আয়-ব্যয়ের রেকর্ড লোড হচ্ছে...');
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Text('ডেটা লোড করতে সমস্যা হয়েছে: ${snapshot.error}', style: const TextStyle(color: Colors.red)),
              ),
            );
          }

          final allDocs = snapshot.data?.docs ?? [];

          // তারিখ অনুযায়ী ডিসেন্ডিং সর্ট (সবচেয়ে নতুনটি উপরে)
          final sortedDocs = List<QueryDocumentSnapshot<Map<String, dynamic>>>.from(allDocs)
            ..sort((a, b) {
              final aData = a.data();
              final bData = b.data();
              final aDate = (aData['createdAt'] as Timestamp?)?.toDate() ??
                  DateTime.tryParse(aData['date']?.toString() ?? '') ??
                  DateTime(2000);
              final bDate = (bData['createdAt'] as Timestamp?)?.toDate() ??
                  DateTime.tryParse(bData['date']?.toString() ?? '') ??
                  DateTime(2000);
              return bDate.compareTo(aDate);
            });

          // পরিসংখ্যান গণনা
          final totalCount = sortedDocs.length;
          final deletedCount = sortedDocs.where((d) => d.data()['isDeleted'] == true).length;
          final activeCount = totalCount - deletedCount;

          double sumIncome = 0;
          double sumExpense = 0;
          for (final doc in sortedDocs) {
            final data = doc.data();
            sumIncome += (data['totalIncome'] as num?)?.toDouble() ?? 0.0;
            sumExpense += (data['totalExpense'] as num?)?.toDouble() ?? 0.0;
          }

          // সার্চ এবং ফিল্টারিং
          final query = _searchCtrl.text.trim().toLowerCase();
          final filteredDocs = sortedDocs.where((doc) {
            final data = doc.data();
            final isDel = data['isDeleted'] == true;

            // ফিল্টার ট্যাব ম্যাচ
            if (_selectedFilter == 'active' && isDel) return false;
            if (_selectedFilter == 'deleted' && !isDel) return false;

            // সার্চ কোয়েরি ম্যাচ
            if (query.isNotEmpty) {
              final title = (data['title']?.toString() ?? '').toLowerCase();
              final name = (data['userName']?.toString() ?? '').toLowerCase();
              final phone = (data['userPhone']?.toString() ?? '').toLowerCase();
              final uid = (data['userId']?.toString() ?? data['uid']?.toString() ?? '').toLowerCase();
              return title.contains(query) || name.contains(query) || phone.contains(query) || uid.contains(query);
            }
            return true;
          }).toList();

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Header Section
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AdminColors.border),
                    boxShadow: const [
                      BoxShadow(color: Color(0x06000000), blurRadius: 10, offset: Offset(0, 3)),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.receipt_long_rounded, color: AdminColors.primaryDark, size: 22),
                              SizedBox(width: 8),
                              Text(
                                'কৃষি আয়-ব্যায় হিস্ট্রি কন্ট্রোল',
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AdminColors.textPrimary),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'অ্যাপের সকল ইউজারের আয়-ব্যয়ের হিসাব, লাভ-লোকসান ও ডিলিট স্ট্যাটাস কেন্দ্রীয় মনিটরিং কনসোল',
                            style: TextStyle(fontSize: 12.5, color: AdminColors.textMuted),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AdminColors.primaryContainer,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.sync_rounded, size: 15, color: AdminColors.primaryDark),
                            const SizedBox(width: 6),
                            Text(
                              'মোট ${_toBn(totalCount.toString())} টি হিসাব',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AdminColors.primaryDark),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Stat Cards Overview
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isNarrow = constraints.maxWidth < 900;
                    return Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        _buildStatCard(
                          label: 'মোট সংরক্ষিত হিসাব',
                          value: '${_toBn(totalCount.toString())} টি',
                          icon: Icons.all_inbox_rounded,
                          color: const Color(0xFF1565C0),
                          bgColor: const Color(0xFFE3F2FD),
                          width: isNarrow ? constraints.maxWidth / 2 - 8 : (constraints.maxWidth - 36) / 4,
                        ),
                        _buildStatCard(
                          label: 'সর্বমোট কৃষক আয়',
                          value: _formatCurrency(sumIncome),
                          icon: Icons.trending_up_rounded,
                          color: const Color(0xFF2E7D32),
                          bgColor: const Color(0xFFE8F5E9),
                          width: isNarrow ? constraints.maxWidth / 2 - 8 : (constraints.maxWidth - 36) / 4,
                        ),
                        _buildStatCard(
                          label: 'সর্বমোট কৃষক ব্যয়',
                          value: _formatCurrency(sumExpense),
                          icon: Icons.trending_down_rounded,
                          color: const Color(0xFFC62828),
                          bgColor: const Color(0xFFFFEBEE),
                          width: isNarrow ? constraints.maxWidth / 2 - 8 : (constraints.maxWidth - 36) / 4,
                        ),
                        _buildStatCard(
                          label: 'ইউজার ডিলিট করেছে',
                          value: '${_toBn(deletedCount.toString())} টি',
                          icon: Icons.delete_sweep_rounded,
                          color: AdminColors.alertCritical,
                          bgColor: AdminColors.alertCriticalBg,
                          width: isNarrow ? constraints.maxWidth / 2 - 8 : (constraints.maxWidth - 36) / 4,
                        ),
                      ],
                    );
                  },
                ),

                const SizedBox(height: 16),

                // Table Container with Search & Filters
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AdminColors.border),
                    boxShadow: const [
                      BoxShadow(color: Color(0x06000000), blurRadius: 10, offset: Offset(0, 3)),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Search and Filter Bar
                      Padding(
                        padding: const EdgeInsets.all(14.0),
                        child: Row(
                          children: [
                            // Filter Pills
                            Wrap(
                              spacing: 8,
                              children: [
                                _buildFilterPill('all', 'সব হিসাব (${_toBn(totalCount.toString())})'),
                                _buildFilterPill('active', 'অ্যাক্টিভ (${_toBn(activeCount.toString())})'),
                                _buildFilterPill('deleted', 'ইউজার ডিলিট করেছে (${_toBn(deletedCount.toString())})'),
                              ],
                            ),
                            const Spacer(),
                            // Search Box
                            SizedBox(
                              width: 300,
                              height: 38,
                              child: TextField(
                                controller: _searchCtrl,
                                onChanged: (_) => setState(() {}),
                                style: const TextStyle(fontSize: 12.5),
                                decoration: InputDecoration(
                                  hintText: 'ইউজার নাম, ফোন, UID বা বিবরণ দিয়ে খুঁজুন...',
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
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AdminColors.border)),
                                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AdminColors.border)),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const Divider(height: 1),

                      // Table Header
                      Container(
                        color: const Color(0xFFF4F7F4),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        child: const Row(
                          children: [
                            Expanded(flex: 3, child: Text('সাবমিট তারিখ ও সময়', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5, color: AdminColors.textPrimary))),
                            Expanded(flex: 3, child: Text('ইউজারের তথ্য', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5, color: AdminColors.textPrimary))),
                            Expanded(flex: 2, child: Text('মোট আয়', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5, color: AdminColors.textPrimary))),
                            Expanded(flex: 2, child: Text('মোট ব্যয়', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5, color: AdminColors.textPrimary))),
                            Expanded(flex: 2, child: Text('নিট লাভ/ক্ষতি', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5, color: AdminColors.textPrimary))),
                            Expanded(flex: 2, child: Center(child: Text('স্ট্যাটাস', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5, color: AdminColors.textPrimary)))),
                            SizedBox(width: 80, child: Center(child: Text('অ্যাকশন', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5, color: AdminColors.textPrimary)))),
                          ],
                        ),
                      ),

                      // Table Content Rows
                      if (filteredDocs.isEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 48),
                          alignment: Alignment.center,
                          child: const Column(
                            children: [
                              Icon(Icons.search_off_rounded, size: 40, color: AdminColors.textMuted),
                              SizedBox(height: 10),
                              Text('কোনো হিসাব পাওয়া যায়নি', style: TextStyle(fontSize: 14, color: AdminColors.textMuted)),
                            ],
                          ),
                        )
                      else
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: filteredDocs.length,
                          separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xFFEEEEEE)),
                          itemBuilder: (context, index) {
                            final doc = filteredDocs[index];
                            final data = doc.data();

                            final title = data['title']?.toString() ?? 'কৃষি আয়-ব্যয় হিসাব';
                            final userName = data['userName']?.toString() ?? 'কৃষক ভাই';
                            final userPhone = data['userPhone']?.toString() ?? '';
                            final userId = data['userId']?.toString() ?? data['uid']?.toString() ?? 'N/A';
                            final isDeleted = data['isDeleted'] == true;

                            final totalIncome = (data['totalIncome'] as num?)?.toDouble() ?? 0.0;
                            final totalExpense = (data['totalExpense'] as num?)?.toDouble() ?? 0.0;
                            final netProfitLoss = (data['netProfitLoss'] as num?)?.toDouble() ?? (totalIncome - totalExpense);
                            final isProfit = netProfitLoss >= 0;

                            final rawDate = data['createdAt'] ?? data['date'];

                            return Container(
                              color: isDeleted ? const Color(0xFFFFFBFB) : Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              child: Row(
                                children: [
                                  // ক) সাবমিট তারিখ ও সময়
                                  Expanded(
                                    flex: 3,
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          _formatDateTime(rawDate),
                                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AdminColors.textPrimary),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          title,
                                          style: const TextStyle(fontSize: 11, color: AdminColors.textMuted),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),

                                  // খ) ইউজারের তথ্য
                                  Expanded(
                                    flex: 3,
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          userName,
                                          style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: AdminColors.textPrimary),
                                        ),
                                        if (userPhone.isNotEmpty)
                                          Text(
                                            userPhone,
                                            style: const TextStyle(fontSize: 11.5, color: AdminColors.textSecondary),
                                          ),
                                        Text(
                                          'UID: $userId',
                                          style: const TextStyle(fontSize: 10, color: AdminColors.textMuted),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),

                                  // গ) মোট আয়
                                  Expanded(
                                    flex: 2,
                                    child: Text(
                                      _formatCurrency(totalIncome),
                                      style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Color(0xFF2E7D32)),
                                    ),
                                  ),

                                  // ঘ) মোট ব্যয়
                                  Expanded(
                                    flex: 2,
                                    child: Text(
                                      _formatCurrency(totalExpense),
                                      style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Color(0xFFC62828)),
                                    ),
                                  ),

                                  // ঙ) নিট লাভ/ক্ষতি
                                  Expanded(
                                    flex: 2,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: isProfit ? const Color(0xFFE8F5E9) : const Color(0xFFFFEBEE),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            isProfit ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
                                            size: 12,
                                            color: isProfit ? const Color(0xFF2E7D32) : const Color(0xFFC62828),
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            _formatCurrency(netProfitLoss),
                                            style: TextStyle(
                                              fontSize: 11.5,
                                              fontWeight: FontWeight.bold,
                                              color: isProfit ? const Color(0xFF2E7D32) : const Color(0xFFC62828),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),

                                  // চ) স্ট্যাটাস
                                  Expanded(
                                    flex: 2,
                                    child: Center(
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: isDeleted ? const Color(0xFFFFEBEE) : const Color(0xFFE8F5E9),
                                          borderRadius: BorderRadius.circular(6),
                                          border: Border.all(
                                            color: isDeleted ? const Color(0xFFEF9A9A) : const Color(0xFFA5D6A7),
                                            width: 0.8,
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              isDeleted ? Icons.delete_sweep_rounded : Icons.check_circle_rounded,
                                              size: 13,
                                              color: isDeleted ? AdminColors.alertCritical : const Color(0xFF2E7D32),
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              isDeleted ? 'ইউজার ডিলিট করেছে' : 'অ্যাক্টিভ',
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                                color: isDeleted ? AdminColors.alertCritical : const Color(0xFF2E7D32),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),

                                  // অ্যাকশন বাটন
                                  SizedBox(
                                    width: 80,
                                    child: Center(
                                      child: IconButton(
                                        icon: const Icon(Icons.visibility_rounded, size: 19, color: AdminColors.primary),
                                        tooltip: 'বিস্তারিত মেমো দেখুন',
                                        onPressed: () => _showMemoDetailsDialog(context, data),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
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

  Widget _buildFilterPill(String key, String label) {
    final isSelected = _selectedFilter == key;
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () => setState(() => _selectedFilter = key),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AdminColors.primary : const Color(0xFFF4F7F4),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: isSelected ? AdminColors.primary : AdminColors.border),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? Colors.white : AdminColors.textPrimary,
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
    required Color bgColor,
    required double width,
  }) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AdminColors.border),
        boxShadow: const [
          BoxShadow(color: Color(0x04000000), blurRadius: 6, offset: Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 11.5, color: AdminColors.textMuted)),
                const SizedBox(height: 2),
                Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
