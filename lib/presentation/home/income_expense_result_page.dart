import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/bangla_number_converter.dart';
import '../../core/widgets/app_unified_dialog.dart';
import '../../providers/auth_provider.dart';
import '../auth/phone_login_screen.dart';

class IncomeExpenseResultPage extends StatefulWidget {
  final String title;
  final double totalIncome;
  final double totalExpense;
  final double netProfitLoss;
  final Map<String, double> incomeDetails;
  final Map<String, double> expenseDetails;
  final DateTime dateTime;
  final bool isSavedAlready;
  final String? existingDocId;

  const IncomeExpenseResultPage({
    super.key,
    required this.title,
    required this.totalIncome,
    required this.totalExpense,
    required this.netProfitLoss,
    required this.incomeDetails,
    required this.expenseDetails,
    required this.dateTime,
    this.isSavedAlready = false,
    this.existingDocId,
  });

  @override
  State<IncomeExpenseResultPage> createState() => _IncomeExpenseResultPageState();
}

class _IncomeExpenseResultPageState extends State<IncomeExpenseResultPage> {
  late bool _isSaved;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _isSaved = widget.isSavedAlready;
  }

  String _formatBanglaDateTime(DateTime dt) {
    final monthsBn = [
      'জানুয়ারি', 'ফেব্রুয়ারি', 'মার্চ', 'এপ্রিল', 'মে', 'জুন',
      'জুলাই', 'আগস্ট', 'সেপ্টেম্বর', 'অক্টোবর', 'নভেম্বর', 'ডিসেম্বর'
    ];
    final day = BanglaNumberConverter.toBangla(dt.day);
    final month = monthsBn[dt.month - 1];
    final year = BanglaNumberConverter.toBangla(dt.year);

    final hour = dt.hour;
    final minute = dt.minute.toString().padLeft(2, '0');
    final minuteBn = BanglaNumberConverter.toBangla(minute);

    String period = 'সকাল';
    int displayHour = hour;
    if (hour >= 12) {
      if (hour >= 18) {
        period = 'রাত';
      } else if (hour >= 15) {
        period = 'বিকাল';
      } else {
        period = 'দুপুর';
      }
      if (hour > 12) displayHour = hour - 12;
    } else if (hour == 0) {
      displayHour = 12;
      period = 'রাত';
    } else if (hour < 6) {
      period = 'রাত';
    }
    final hourBn = BanglaNumberConverter.toBangla(displayHour);

    return '$day $month $year, $period $hourBn:$minuteBn';
  }

  String _formatCurrency(double amount) {
    final isNegative = amount < 0;
    final absVal = amount.abs();
    final formatted = absVal.toStringAsFixed(absVal.truncateToDouble() == absVal ? 0 : 2);
    return '${isNegative ? "- " : ""}৳ ${BanglaNumberConverter.toBangla(formatted)}';
  }

  bool _isUserLoggedIn(BuildContext context) {
    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      if (auth.isLoggedIn) return true;
    } catch (_) {}

    try {
      final curUser = FirebaseAuth.instance.currentUser;
      if (curUser != null && !curUser.isAnonymous) {
        return true;
      }
    } catch (_) {}

    return false;
  }

  Future<void> _saveToFirestore() async {
    if (_isSaved || _isSaving) return;

    // ১. প্রথমে চেক করো FirebaseAuth.instance.currentUser != null কি না
    final curUser = FirebaseAuth.instance.currentUser;
    UserModel? authUser;
    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      if (auth.isLoggedIn) {
        authUser = auth.user;
      }
    } catch (_) {}

    final bool isUserAuthenticated = (curUser != null && !curUser.isAnonymous) || authUser != null;

    if (!isUserAuthenticated) {
      AppUnifiedDialog.showLogoDialog(
        context,
        title: 'লগইন প্রয়োজন',
        message: 'আপনার হিসাব সংরক্ষণ করতে একাউন্ট লগইন করুন',
        buttonText: 'লগইন করুন',
        primaryColor: const Color(0xFF00897B),
        onConfirm: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const PhoneLoginScreen()),
          );
        },
      );
      return;
    }

    setState(() => _isSaving = true);

    // ক) প্রথমে স্ট্যান্ডার্ড লোডিং ডায়ালগ ওপেন হবে
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: Color(0xFF00897B)),
      ),
    );

    try {
      final String uid = curUser?.uid ?? authUser?.uid ?? 'unknown_user';
      final String userPhone = (curUser?.phoneNumber?.isNotEmpty == true)
          ? curUser!.phoneNumber!
          : (authUser?.phone ?? '');
      final String userName = (authUser?.name.isNotEmpty == true)
          ? authUser!.name
          : (curUser?.displayName?.isNotEmpty == true ? curUser!.displayName! : 'কৃষক ভাই');

      final payload = {
        'userId': uid,
        'uid': uid,
        'userPhone': userPhone,
        'userName': userName,
        'title': widget.title.trim().isNotEmpty ? widget.title.trim() : 'কৃষি আয়-ব্যয় হিসাব',
        'totalIncome': widget.totalIncome,
        'totalExpense': widget.totalExpense,
        'netProfitLoss': widget.netProfitLoss,
        'isProfit': widget.netProfitLoss >= 0,
        'isDeleted': false, // বাই-ডিফল্ট isDeleted: false
        'incomeDetails': widget.incomeDetails,
        'expenseDetails': widget.expenseDetails,
        'date': widget.dateTime.toIso8601String(),
        'createdAt': FieldValue.serverTimestamp(),
      };

      // খ) FirebaseFirestore.instance.collection('agricultural_accounts').add(...)
      await FirebaseFirestore.instance.collection('agricultural_accounts').add(payload);

      // ইউজারের UID-এর আন্ডারে সাব-কালেকশনেও সেভ
      if (uid.isNotEmpty && uid != 'unknown_user') {
        try {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(uid)
              .collection('agricultural_accounts')
              .add(payload);
        } catch (_) {}
      }

      // গ) সেভ সফল হলে Navigator.pop(context) দিয়ে লোডিং ডায়ালগটি রিমুভ হবে
      if (mounted) {
        Navigator.pop(context);
      }

      // ঘ) লোডিং রিমুভ হওয়ার পর সাকসেস পপআপটি (লোগোসহ) দেখাবে
      if (mounted) {
        setState(() {
          _isSaved = true;
          _isSaving = false;
        });
        await AppUnifiedDialog.showLogoDialog(
          context,
          title: 'সফল হয়েছে!',
          message: 'আপনার হিসাব সফলভাবে সংরক্ষণ করা হয়েছে।',
          buttonText: 'ঠিক আছে',
          primaryColor: const Color(0xFF00897B),
        );
      }
    } catch (e) {
      // ফায়ারবেস এরর হলে লোডিং ডায়ালগ রিমুভ করে ব্যর্থতার পপআপ দেখাবে
      if (mounted) {
        Navigator.pop(context);
      }
      if (mounted) {
        setState(() => _isSaving = false);
        await AppUnifiedDialog.showLogoDialog(
          context,
          title: 'ব্যর্থ হয়েছে!',
          message: 'দুঃখিত, হিসাব সংরক্ষণ করা যায়নি।',
          buttonText: 'ঠিক আছে',
          primaryColor: const Color(0xFFD32F2F),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isProfit = widget.netProfitLoss >= 0;
    final isZero = widget.netProfitLoss == 0;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F4),
      appBar: AppBar(
        backgroundColor: const Color(0xFF00897B),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 19),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'আয়-ব্যয় হিসাবের ফলাফল',
          style: TextStyle(
            color: Colors.white,
            fontSize: 17.5,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
          child: Column(
            children: [
              // রসিদ বা ইনভয়েস (Memo / Receipt Card)
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                  border: Border.all(color: const Color(0xFFE0E0E0), width: 1.2),
                ),
                child: Column(
                  children: [
                    // ইনভয়েস হেডার
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: const BoxDecoration(
                        color: Color(0xFFE0F2F1),
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(18),
                          topRight: Radius.circular(18),
                        ),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF00897B),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Icon(Icons.receipt_long_rounded, color: Colors.white, size: 22),
                                  ),
                                  const SizedBox(width: 10),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'কৃষি কথা – আয়-ব্যয় স্মারক',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                          color: Color(0xFF004D40),
                                        ),
                                      ),
                                      Text(
                                        widget.title.isNotEmpty ? widget.title : 'সাধারণ চাষাবাদ হিসাব',
                                        style: const TextStyle(
                                          fontSize: 12.5,
                                          color: Color(0xFF00796B),
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: const Color(0xFFB2DFDB)),
                                ),
                                child: Text(
                                  _isSaved ? 'সংরক্ষিত' : 'খসড়া',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: _isSaved ? const Color(0xFF2E7D32) : Colors.orange.shade800,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              const Icon(Icons.calendar_today_rounded, size: 14, color: Color(0xFF00796B)),
                              const SizedBox(width: 6),
                              Text(
                                _formatBanglaDateTime(widget.dateTime),
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF004D40),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // নিট লাভ বা ক্ষতি স্পেশাল হাইলাইটেড ব্যানার
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: isZero
                                ? [const Color(0xFFECEFF1), const Color(0xFFCFD8DC)]
                                : isProfit
                                    ? [const Color(0xFFE8F5E9), const Color(0xFFC8E6C9)]
                                    : [const Color(0xFFFFEBEE), const Color(0xFFFFCDD2)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isZero
                                ? Colors.blueGrey.shade300
                                : isProfit
                                    ? const Color(0xFF81C784)
                                    : const Color(0xFFE57373),
                            width: 1.5,
                          ),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  isZero
                                      ? Icons.balance_rounded
                                      : isProfit
                                          ? Icons.trending_up_rounded
                                          : Icons.trending_down_rounded,
                                  color: isZero
                                      ? Colors.blueGrey.shade800
                                      : isProfit
                                          ? const Color(0xFF1B5E20)
                                          : const Color(0xFFB71C1C),
                                  size: 26,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  isZero
                                      ? 'আয় ও ব্যয় সমান (লাভ-ক্ষতি ০)'
                                      : isProfit
                                          ? 'অভিনন্দন! আপনার নিট লাভ হয়েছে'
                                          : 'সতর্কতা: আপনার নিট ক্ষতি হয়েছে',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: isZero
                                        ? Colors.blueGrey.shade800
                                        : isProfit
                                            ? const Color(0xFF1B5E20)
                                            : const Color(0xFFB71C1C),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              isZero ? '৳ ০' : _formatCurrency(widget.netProfitLoss),
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w900,
                                color: isZero
                                    ? Colors.blueGrey.shade900
                                    : isProfit
                                        ? const Color(0xFF1B5E20)
                                        : const Color(0xFFB71C1C),
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // ড্যাশড ডিভাইডার (রসিদ কাটিং লাইন)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Row(
                        children: List.generate(
                          30,
                          (index) => Expanded(
                            child: Container(
                              color: index % 2 == 0 ? Colors.transparent : Colors.grey.shade300,
                              height: 1.8,
                            ),
                          ),
                        ),
                      ),
                    ),

                    // মোট আয় ও মোট ব্যয় সংক্ষেপ কার্ড
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1F8E9),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: const Color(0xFFC5E1A5)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Row(
                                    children: [
                                      Icon(Icons.arrow_downward_rounded, size: 16, color: Color(0xFF2E7D32)),
                                      SizedBox(width: 4),
                                      Text(
                                        'মোট আয়',
                                        style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Color(0xFF2E7D32)),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    _formatCurrency(widget.totalIncome),
                                    style: const TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF1B5E20),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFF3E0),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: const Color(0xFFFFCC80)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Row(
                                    children: [
                                      Icon(Icons.arrow_upward_rounded, size: 16, color: Color(0xFFE65100)),
                                      SizedBox(width: 4),
                                      Text(
                                        'মোট ব্যয়',
                                        style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Color(0xFFE65100)),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    _formatCurrency(widget.totalExpense),
                                    style: const TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFFBF360C),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // আয়ের বিশদ বিবরণ
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.check_circle_outline_rounded, size: 16, color: Color(0xFF2E7D32)),
                              SizedBox(width: 6),
                              Text(
                                'আয়ের খাতের বিবরণ',
                                style: TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          _buildDetailRow('ফসল বিক্রি', widget.incomeDetails['cropSales'] ?? 0),
                          _buildDetailRow('বীজ বিক্রি', widget.incomeDetails['seedSales'] ?? 0),
                          _buildDetailRow('অন্যান্য আয়', widget.incomeDetails['otherIncome'] ?? 0),
                        ],
                      ),
                    ),

                    const SizedBox(height: 14),

                    // ব্যয়ের বিশদ বিবরণ
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.remove_circle_outline_rounded, size: 16, color: Color(0xFFC62828)),
                              SizedBox(width: 6),
                              Text(
                                'ব্যয়ের খাতের বিবরণ',
                                style: TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          _buildDetailRow('জমি চাষ', widget.expenseDetails['tillage'] ?? 0, isExpense: true),
                          _buildDetailRow('বীজ ক্রয়', widget.expenseDetails['seedBuy'] ?? 0, isExpense: true),
                          _buildDetailRow('সার ও কীটনাশক', widget.expenseDetails['fertilizerPesticide'] ?? 0, isExpense: true),
                          _buildDetailRow('সেচ ও জ্বালানি', widget.expenseDetails['irrigation'] ?? 0, isExpense: true),
                          _buildDetailRow('শ্রমিক খরচ', widget.expenseDetails['labor'] ?? 0, isExpense: true),
                          _buildDetailRow('যাতায়াত ও পরিবহন', widget.expenseDetails['transport'] ?? 0, isExpense: true),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // ইনভয়েস ফুটার
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      decoration: const BoxDecoration(
                        color: Color(0xFFF9FBF9),
                        borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(18),
                          bottomRight: Radius.circular(18),
                        ),
                        border: Border(top: BorderSide(color: Color(0xFFEEEEEE))),
                      ),
                      child: const Text(
                        'কৃষি কথা ডিজিটাল কৃষি সহকারী কর্তৃক প্রস্তুতকৃত',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.textMuted,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // অ্যাকশন বাটনসমূহ
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isSaved ? const Color(0xFF2E7D32) : const Color(0xFF00897B),
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 2,
                ),
                icon: Icon(_isSaved ? Icons.check_circle_rounded : Icons.bookmark_add_rounded, size: 20),
                label: Text(
                  _isSaved ? 'হিসাবটি সফলভাবে সংরক্ষিত হয়েছে' : 'হিসাবটি সেভ করুন',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
                onPressed: _isSaved ? null : _saveToFirestore,
              ),

              const SizedBox(height: 10),

              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF00897B),
                  side: const BorderSide(color: Color(0xFF00897B), width: 1.2),
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                icon: const Icon(Icons.arrow_back_rounded, size: 18),
                label: const Text(
                  'ফিরে যান',
                  style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.bold),
                ),
                onPressed: () => Navigator.pop(context),
              ),

              const SizedBox(height: 14),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String title, double amount, {bool isExpense = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
          Text(
            _formatCurrency(amount),
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: amount > 0
                  ? (isExpense ? const Color(0xFFC62828) : const Color(0xFF2E7D32))
                  : Colors.grey.shade400,
            ),
          ),
        ],
      ),
    );
  }
}
