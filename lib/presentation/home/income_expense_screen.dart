import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/bangla_number_converter.dart';
import '../../core/widgets/app_unified_dialog.dart';
import '../../providers/auth_provider.dart';
import '../auth/phone_login_screen.dart';
import 'income_expense_result_page.dart';

/// রিয়েল-টাইম ইংরেজি ডিজিট (0-9) কে বাংলা ডিজিটে (০-৯) রূপান্তর করার ফরম্যাটার
class EnglishToBanglaNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final converted = BanglaNumberConverter.toBangla(newValue.text);
    return newValue.copyWith(
      text: converted,
      selection: newValue.selection,
    );
  }
}

class IncomeExpensePage extends StatefulWidget {
  const IncomeExpensePage({super.key});

  @override
  State<IncomeExpensePage> createState() => _IncomeExpensePageState();
}

typedef IncomeExpenseScreen = IncomeExpensePage;

class _IncomeExpensePageState extends State<IncomeExpensePage> {
  int _selectedTabIndex = 0; // 0: নতুন হিসাব, 1: পূর্বের হিস্ট্রি

  // শিরোনাম কন্ট্রোলার (ডিফল্ট ফাঁকা থাকবে)
  final TextEditingController _titleCtrl = TextEditingController();

  // আয়ের খাত কন্ট্রোলারসমূহ
  final TextEditingController _cropSalesCtrl = TextEditingController();
  final TextEditingController _seedSalesCtrl = TextEditingController();
  final TextEditingController _otherIncomeCtrl = TextEditingController();

  // ব্যয়ের খাত কন্ট্রোলারসমূহ
  final TextEditingController _tillageCtrl = TextEditingController();
  final TextEditingController _seedBuyCtrl = TextEditingController();
  final TextEditingController _fertilizerPesticideCtrl = TextEditingController();
  final TextEditingController _irrigationCtrl = TextEditingController();
  final TextEditingController _laborCtrl = TextEditingController();
  final TextEditingController _transportCtrl = TextEditingController();

  @override
  void dispose() {
    _titleCtrl.dispose();
    _cropSalesCtrl.dispose();
    _seedSalesCtrl.dispose();
    _otherIncomeCtrl.dispose();
    _tillageCtrl.dispose();
    _seedBuyCtrl.dispose();
    _fertilizerPesticideCtrl.dispose();
    _irrigationCtrl.dispose();
    _laborCtrl.dispose();
    _transportCtrl.dispose();
    super.dispose();
  }

  double _parseInput(TextEditingController ctrl) {
    final text = ctrl.text.trim();
    if (text.isEmpty) return 0.0;
    final englishDigits = BanglaNumberConverter.toEnglish(text);
    return double.tryParse(englishDigits) ?? 0.0;
  }

  void _calculateAndNavigate() {
    final cropSales = _parseInput(_cropSalesCtrl);
    final seedSales = _parseInput(_seedSalesCtrl);
    final otherIncome = _parseInput(_otherIncomeCtrl);

    final tillage = _parseInput(_tillageCtrl);
    final seedBuy = _parseInput(_seedBuyCtrl);
    final fertilizerPesticide = _parseInput(_fertilizerPesticideCtrl);
    final irrigation = _parseInput(_irrigationCtrl);
    final labor = _parseInput(_laborCtrl);
    final transport = _parseInput(_transportCtrl);

    final totalIncome = cropSales + seedSales + otherIncome;
    final totalExpense = tillage + seedBuy + fertilizerPesticide + irrigation + labor + transport;

    // ২. ইনপুট ভ্যালিডেশন: সবগুলো ফিল্ড খালি বা ০ হলে রেজাল্ট পেজে যাওয়া যাবে না
    if (totalIncome <= 0 && totalExpense <= 0) {
      AppUnifiedDialog.showLogoDialog(
        context,
        title: 'সতর্কতা',
        message: 'দয়া করে আয় বা ব্যয়ের কমপক্ষে একটি ফিল্ড পূরণ করুন।',
        buttonText: 'বুঝেছি',
        primaryColor: const Color(0xFFE65100),
      );
      return;
    }

    final netProfitLoss = totalIncome - totalExpense;

    final incomeDetails = {
      'cropSales': cropSales,
      'seedSales': seedSales,
      'otherIncome': otherIncome,
    };

    final expenseDetails = {
      'tillage': tillage,
      'seedBuy': seedBuy,
      'fertilizerPesticide': fertilizerPesticide,
      'irrigation': irrigation,
      'labor': labor,
      'transport': transport,
    };

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => IncomeExpenseResultPage(
          title: _titleCtrl.text.trim().isNotEmpty ? _titleCtrl.text.trim() : 'কৃষি আয়-ব্যয় হিসাব',
          totalIncome: totalIncome,
          totalExpense: totalExpense,
          netProfitLoss: netProfitLoss,
          incomeDetails: incomeDetails,
          expenseDetails: expenseDetails,
          dateTime: DateTime.now(),
        ),
      ),
    );
  }

  void _resetAllFields() {
    setState(() {
      _titleCtrl.clear();
      _cropSalesCtrl.clear();
      _seedSalesCtrl.clear();
      _otherIncomeCtrl.clear();
      _tillageCtrl.clear();
      _seedBuyCtrl.clear();
      _fertilizerPesticideCtrl.clear();
      _irrigationCtrl.clear();
      _laborCtrl.clear();
      _transportCtrl.clear();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('সকল ইনপুট ফিল্ড রিসেট করা হয়েছে।'),
        duration: Duration(seconds: 2),
        backgroundColor: Color(0xFF00897B),
      ),
    );
  }

  Set<String> _getCurrentUserIdentifiers() {
    final ids = <String>{};
    try {
      final curUser = FirebaseAuth.instance.currentUser;
      if (curUser != null) {
        if (curUser.uid.isNotEmpty) ids.add(curUser.uid);
        if ((curUser.phoneNumber ?? '').isNotEmpty) {
          final p = curUser.phoneNumber!;
          ids.add(p);
          ids.add(p.replaceAll('+88', ''));
          ids.add(p.replaceAll('+880', '0'));
        }
      }
    } catch (_) {}

    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      if (auth.user != null) {
        if (auth.user!.uid.isNotEmpty) ids.add(auth.user!.uid);
        if (auth.user!.phone.isNotEmpty) {
          final p = auth.user!.phone;
          ids.add(p);
          ids.add(p.replaceAll('+88', ''));
          ids.add(p.replaceAll('+880', '0'));
        }
      }
    } catch (_) {}

    return ids;
  }

  String _getUserIdentifier() {
    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      if (auth.user != null) {
        if (auth.user!.uid.isNotEmpty) return auth.user!.uid;
        if (auth.user!.phone.isNotEmpty) return auth.user!.phone;
      }
    } catch (_) {}

    try {
      final curUser = FirebaseAuth.instance.currentUser;
      if (curUser != null) {
        if (curUser.uid.isNotEmpty) return curUser.uid;
        if ((curUser.phoneNumber ?? '').isNotEmpty) return curUser.phoneNumber!;
      }
    } catch (_) {}

    return 'default_farmer';
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

  void _confirmSoftDelete(BuildContext context, DocumentSnapshot doc, String title) {
    showDialog(
      context: context,
      builder: (dCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.delete_outline_rounded, color: Color(0xFFD32F2F), size: 22),
            SizedBox(width: 8),
            Text('হিসাব ডিলিট', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text('আপনি কি "$title" হিসাবটি আপনার তালিকা থেকে মুছে ফেলতে চান?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dCtx),
            child: const Text('না', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD32F2F),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () async {
              Navigator.pop(dCtx);
              try {
                // ডিরেক্ট doc.delete() এর বদলে ফায়ারস্টোর সফট-ডিলিট লজিক: doc.reference.update({'isDeleted': true})
                await doc.reference.update({'isDeleted': true});
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('হিসাবটি মুছে ফেলা হয়েছে।'),
                      backgroundColor: Color(0xFF00897B),
                      duration: Duration(seconds: 2),
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('মুছতে সমস্যা হয়েছে: $e'),
                      backgroundColor: Colors.red,
                    ),
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

  void _showLoginRequiredDialog(BuildContext context) {
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
  }

  String _formatBanglaDate(DateTime dt) {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F4),
      appBar: AppBar(
        backgroundColor: const Color(0xFF00897B),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 19),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          children: [
            const Text(
              'কৃষি খাতা (আয়-ব্যায় হিসাব)',
              style: TextStyle(
                color: Colors.white,
                fontSize: 17.5,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'সহজ হিসাব ও লাভ-লোকসান ক্যালকুলেটর',
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
            // ১. কালারিং টপবার (Colored Top Bar with 2 Segmented Tabs)
            Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF00897B), Color(0xFF00695C)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF004D40).withOpacity(0.22),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 14),
              child: Row(
                children: [
                  Expanded(
                    child: _buildTabButton(
                      index: 0,
                      label: 'নতুন হিসাব',
                      icon: Icons.calculate_rounded,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildTabButton(
                      index: 1,
                      label: 'পূর্বের হিস্ট্রি',
                      icon: Icons.history_rounded,
                    ),
                  ),
                ],
              ),
            ),

            // বডি সেকশন (ফুল স্ক্রলএবল)
            Expanded(
              child: _selectedTabIndex == 0
                  ? _buildNewCalculationView()
                  : _buildHistoryView(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabButton({required int index, required String label, required IconData icon}) {
    final isActive = _selectedTabIndex == index;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          if (index == 1 && !_isUserLoggedIn(context)) {
            _showLoginRequiredDialog(context);
            return;
          }
          setState(() => _selectedTabIndex = index);
        },
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isActive ? Colors.white : Colors.white.withOpacity(0.16),
            borderRadius: BorderRadius.circular(12),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
            border: Border.all(
              color: isActive ? Colors.white : Colors.white.withOpacity(0.3),
              width: 1.2,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color: isActive ? const Color(0xFF00695C) : Colors.white,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                  color: isActive ? const Color(0xFF00695C) : Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==================== TAB 0: নতুন হিসাব ভিউ ====================
  Widget _buildNewCalculationView() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // শিরোনাম বা ফসলের নাম ইনপুট
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE0E0E0)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.edit_note_rounded, size: 20, color: Color(0xFF00897B)),
                    SizedBox(width: 6),
                    Text(
                      'হিসাবের নাম / বিবরণ',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _titleCtrl,
                  style: const TextStyle(fontSize: 13.5),
                  decoration: InputDecoration(
                    hintText: 'যেমন: বোরো ধান চাষ, আলু আবাদ ইত্যাদি',
                    hintStyle: const TextStyle(fontSize: 12.5, color: AppColors.textMuted),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFFCFD8DC)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFF00897B), width: 1.5),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // ২. আয়ের খাত কার্ড (Income Card)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFC8E6C9), width: 1.2),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF2E7D32).withOpacity(0.06),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F5E9),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.monetization_on_rounded, color: Color(0xFF2E7D32), size: 20),
                    ),
                    const SizedBox(width: 10),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'আয়ের খাত',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1B5E20)),
                        ),
                        Text(
                          'ফসল ও বীজ বিক্রি থেকে প্রাপ্ত আয় (টাকায়)',
                          style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                _buildNumberField(
                  controller: _cropSalesCtrl,
                  label: 'ফসল বিক্রয় থেকে আয়',
                  hint: '০',
                  icon: Icons.eco_rounded,
                  accentColor: const Color(0xFF2E7D32),
                ),
                const SizedBox(height: 10),
                _buildNumberField(
                  controller: _seedSalesCtrl,
                  label: 'বীজ বিক্রয় থেকে আয়',
                  hint: '০',
                  icon: Icons.grain_rounded,
                  accentColor: const Color(0xFF2E7D32),
                ),
                const SizedBox(height: 10),
                _buildNumberField(
                  controller: _otherIncomeCtrl,
                  label: 'অন্যান্য কৃষি আয় (খড়, ডালপালা বিক্রি ইত্যাদি)',
                  hint: '০',
                  icon: Icons.add_circle_outline_rounded,
                  accentColor: const Color(0xFF2E7D32),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // ২. ব্যয়ের খাত কার্ড (Expense Card)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFFFCDD2), width: 1.2),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFC62828).withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFEBEE),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.receipt_long_rounded, color: Color(0xFFC62828), size: 20),
                    ),
                    const SizedBox(width: 10),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'ব্যয়ের খাত',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFFB71C1C)),
                        ),
                        Text(
                          'চাষাবাদ, সার, বীজ ও শ্রমিকের সকল খরচ (টাকায়)',
                          style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                _buildNumberField(
                  controller: _tillageCtrl,
                  label: 'জমি চাষ ও প্রস্তুত খরচ',
                  hint: '০',
                  icon: Icons.agriculture_rounded,
                  accentColor: const Color(0xFFC62828),
                ),
                const SizedBox(height: 10),
                _buildNumberField(
                  controller: _seedBuyCtrl,
                  label: 'বীজ ও চারা ক্রয় খরচ',
                  hint: '০',
                  icon: Icons.spa_rounded,
                  accentColor: const Color(0xFFC62828),
                ),
                const SizedBox(height: 10),
                _buildNumberField(
                  controller: _fertilizerPesticideCtrl,
                  label: 'সার ও কীটনাশক খরচ',
                  hint: '০',
                  icon: Icons.science_rounded,
                  accentColor: const Color(0xFFC62828),
                ),
                const SizedBox(height: 10),
                _buildNumberField(
                  controller: _irrigationCtrl,
                  label: 'সেচ ও ডিজেল/বিদ্যুৎ খরচ',
                  hint: '০',
                  icon: Icons.water_drop_rounded,
                  accentColor: const Color(0xFFC62828),
                ),
                const SizedBox(height: 10),
                _buildNumberField(
                  controller: _laborCtrl,
                  label: 'শ্রমিক ও নিড়ানির মজুরি',
                  hint: '০',
                  icon: Icons.groups_rounded,
                  accentColor: const Color(0xFFC62828),
                ),
                const SizedBox(height: 10),
                _buildNumberField(
                  controller: _transportCtrl,
                  label: 'যাতায়াত ও ফসল পরিবহন খরচ',
                  hint: '০',
                  icon: Icons.local_shipping_rounded,
                  accentColor: const Color(0xFFC62828),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // ৩. হিসাব বের করুন বাটন
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00897B),
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(52),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              elevation: 3,
            ),
            icon: const Icon(Icons.calculate_rounded, size: 22),
            label: const Text(
              'হিসাব বের করুন',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            onPressed: _calculateAndNavigate,
          ),

          const SizedBox(height: 10),

          Center(
            child: TextButton.icon(
              icon: const Icon(Icons.restart_alt_rounded, size: 18, color: Colors.grey),
              label: const Text(
                'সব ইনপুট রিসেট করুন',
                style: TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.w600),
              ),
              onPressed: _resetAllFields,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNumberField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required Color accentColor,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'[0-9০-৯.]')),
        EnglishToBanglaNumberFormatter(),
      ],
      style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        hintStyle: const TextStyle(fontSize: 13, color: AppColors.textMuted),
        labelStyle: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
        prefixIcon: Icon(icon, size: 19, color: accentColor.withOpacity(0.85)),
        suffixText: '৳',
        suffixStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: accentColor),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: accentColor, width: 1.5),
        ),
        filled: true,
        fillColor: const Color(0xFFFAFAFA),
      ),
    );
  }

  // ==================== TAB 1: পূর্বের হিস্ট্রি ভিউ (StreamBuilder) ====================
  Widget _buildHistoryView() {
    if (!_isUserLoggedIn(context)) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: const BoxDecoration(
                  color: Color(0xFFE0F2F1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.lock_outline_rounded, size: 36, color: Color(0xFF00897B)),
              ),
              const SizedBox(height: 16),
              const Text(
                'লগইন প্রয়োজন',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 6),
              const Text(
                'আপনার পূর্বের সংরক্ষিত হিসাব দেখতে অনুগ্রহ করে একাউন্ট লগইন করুন।',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12.5, color: AppColors.textMuted, height: 1.4),
              ),
              const SizedBox(height: 18),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00897B),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                ),
                icon: const Icon(Icons.login_rounded, size: 18),
                label: const Text('লগইন করুন', style: TextStyle(fontWeight: FontWeight.bold)),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const PhoneLoginScreen()),
                  );
                },
              ),
            ],
          ),
        ),
      );
    }

    final userIdentifier = _getUserIdentifier();

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('agricultural_accounts')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Color(0xFF00897B), strokeWidth: 3),
                  SizedBox(height: 14),
                  Text(
                    'হিসাবের তালিকা লোড হচ্ছে...',
                    style: TextStyle(fontSize: 13, color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline_rounded, size: 48, color: Colors.red),
                  const SizedBox(height: 12),
                  Text(
                    'হিসাব লোড করতে সমস্যা হয়েছে: ${snapshot.error}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
          );
        }

        final allDocs = snapshot.data?.docs ?? [];
        final userIds = _getCurrentUserIdentifiers();

        // ফিল্টারিং: বর্তমান ইউজার অনুযায়ী এবং সফট-ডিলিট না হওয়া ডেটা
        final userDocs = allDocs.where((doc) {
          final data = doc.data();
          // ২. ফায়ারবেস সফট-ডিলিট লজিক: ইউজার ডিলিট করলে ইউজারের কাছে আর দেখাবে না
          if (data['isDeleted'] == true) return false;

          final uId = data['userId']?.toString() ?? '';
          final uidField = data['uid']?.toString() ?? '';
          final uPhone = data['userPhone']?.toString() ?? '';

          if (userIds.isEmpty) return true;
          if (userIds.contains(uId) || userIds.contains(uidField)) return true;
          if (uPhone.isNotEmpty) {
            if (userIds.contains(uPhone)) return true;
            if (userIds.contains(uPhone.replaceAll('+88', ''))) return true;
            if (userIds.contains(uPhone.replaceAll('+880', '0'))) return true;
          }
          return false;
        }).toList();

        // তারিখ অনুযায়ী ডিসেন্ডিং সর্ট (সবচেয়ে নতুনটি উপরে)
        userDocs.sort((a, b) {
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

        if (userDocs.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: const BoxDecoration(
                      color: Color(0xFFE0F2F1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.receipt_long_outlined, size: 36, color: Color(0xFF00897B)),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'এখনো কোনো সংরক্ষিত হিসাব নেই',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'আপনার ফসলের আয় ও ব্যয়ের হিসাব সংরক্ষণ করতে "নতুন হিসাব" ট্যাবে গিয়ে তথ্য প্রদান করুন।',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12.5, color: AppColors.textMuted, height: 1.4),
                  ),
                  const SizedBox(height: 18),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00897B),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                    ),
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: const Text('নতুন হিসাব শুরু করুন', style: TextStyle(fontWeight: FontWeight.bold)),
                    onPressed: () => setState(() => _selectedTabIndex = 0),
                  ),
                ],
              ),
            ),
          );
        }

        return ListView.builder(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          itemCount: userDocs.length,
          itemBuilder: (context, index) {
            final doc = userDocs[index];
            final data = doc.data();

            final title = data['title']?.toString() ?? 'কৃষি আয়-ব্যয় হিসাব';
            final totalIncome = (data['totalIncome'] as num?)?.toDouble() ?? 0.0;
            final totalExpense = (data['totalExpense'] as num?)?.toDouble() ?? 0.0;
            final netProfitLoss = (data['netProfitLoss'] as num?)?.toDouble() ?? (totalIncome - totalExpense);
            final isProfit = netProfitLoss >= 0;

            final dt = (data['createdAt'] as Timestamp?)?.toDate() ??
                DateTime.tryParse(data['date']?.toString() ?? '') ??
                DateTime.now();

            final incomeDetailsRaw = data['incomeDetails'] as Map<String, dynamic>? ?? {};
            final incomeDetails = incomeDetailsRaw.map((k, v) => MapEntry(k, (v as num?)?.toDouble() ?? 0.0));

            final expenseDetailsRaw = data['expenseDetails'] as Map<String, dynamic>? ?? {};
            final expenseDetails = expenseDetailsRaw.map((k, v) => MapEntry(k, (v as num?)?.toDouble() ?? 0.0));

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE0E0E0)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => IncomeExpenseResultPage(
                          title: title,
                          totalIncome: totalIncome,
                          totalExpense: totalExpense,
                          netProfitLoss: netProfitLoss,
                          incomeDetails: incomeDetails,
                          expenseDetails: expenseDetails,
                          dateTime: dt,
                          isSavedAlready: true,
                          existingDocId: doc.id,
                        ),
                      ),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(14.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // তারিখ ও লাভ/ক্ষতি স্ট্যাটাস ব্যাজ
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.calendar_month_rounded, size: 14, color: Color(0xFF00897B)),
                                const SizedBox(width: 5),
                                Text(
                                  _formatBanglaDate(dt),
                                  style: const TextStyle(fontSize: 11.5, color: Color(0xFF00796B), fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: isProfit ? const Color(0xFFE8F5E9) : const Color(0xFFFFEBEE),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: isProfit ? const Color(0xFF81C784) : const Color(0xFFE57373),
                                      width: 0.8,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        isProfit ? Icons.trending_up_rounded : Icons.trending_down_rounded,
                                        size: 13,
                                        color: isProfit ? const Color(0xFF2E7D32) : const Color(0xFFC62828),
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        isProfit ? 'লাভ' : 'ক্ষতি',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: isProfit ? const Color(0xFF2E7D32) : const Color(0xFFC62828),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap: () => _confirmSoftDelete(context, doc, title),
                                    borderRadius: BorderRadius.circular(6),
                                    child: Padding(
                                      padding: const EdgeInsets.all(4.0),
                                      child: Icon(Icons.delete_outline_rounded, size: 18, color: Colors.red.shade400),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),

                        const SizedBox(height: 8),

                        // টাইটেল
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),

                        const SizedBox(height: 10),

                        // মেমো সারাংশ (আয়, ব্যয় ও নিট লাভ)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF9FBF9),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFECEFF1)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('মোট আয়', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                                  Text(
                                    _formatCurrency(totalIncome),
                                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF2E7D32)),
                                  ),
                                ],
                              ),
                              Container(height: 22, width: 1, color: Colors.grey.shade300),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('মোট ব্যয়', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                                  Text(
                                    _formatCurrency(totalExpense),
                                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFFC62828)),
                                  ),
                                ],
                              ),
                              Container(height: 22, width: 1, color: Colors.grey.shade300),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    isProfit ? 'নিট লাভ' : 'নিট ক্ষতি',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: isProfit ? const Color(0xFF2E7D32) : const Color(0xFFC62828),
                                    ),
                                  ),
                                  Text(
                                    _formatCurrency(netProfitLoss),
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w900,
                                      color: isProfit ? const Color(0xFF1B5E20) : const Color(0xFFB71C1C),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 8),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text(
                              'বিস্তারিত রসিদ দেখুন',
                              style: TextStyle(
                                fontSize: 12,
                                color: const Color(0xFF00897B),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const Icon(Icons.arrow_forward_ios_rounded, size: 11, color: Color(0xFF00897B)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
