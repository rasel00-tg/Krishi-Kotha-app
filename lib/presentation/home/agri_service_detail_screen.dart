import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/utils/bangla_number_converter.dart';
import '../../data/services/firestore_service.dart';

class AgriServiceDetailScreen extends StatefulWidget {
  final String serviceId;
  final String title;
  final IconData icon;
  final Color themeColor;
  final Color bgColor;
  final FirestoreService? firestoreService;

  const AgriServiceDetailScreen({
    super.key,
    required this.serviceId,
    required this.title,
    required this.icon,
    required this.themeColor,
    required this.bgColor,
    this.firestoreService,
  });

  @override
  State<AgriServiceDetailScreen> createState() => _AgriServiceDetailScreenState();
}

class _AgriServiceDetailScreenState extends State<AgriServiceDetailScreen> {
  // Mini Farm Ledger state for service_ledger
  final TextEditingController _incomeCtrl = TextEditingController();
  final TextEditingController _seedCtrl = TextEditingController();
  final TextEditingController _fertilizerCtrl = TextEditingController();
  final TextEditingController _irrigationCtrl = TextEditingController();
  final TextEditingController _pesticideCtrl = TextEditingController();
  final TextEditingController _laborCtrl = TextEditingController();
  final TextEditingController _otherCtrl = TextEditingController();

  double _totalIncome = 0;
  double _totalExpense = 0;
  double _netProfit = 0;

  void _calculateLedger() {
    final income = double.tryParse(_incomeCtrl.text) ?? 0;
    final seed = double.tryParse(_seedCtrl.text) ?? 0;
    final fertilizer = double.tryParse(_fertilizerCtrl.text) ?? 0;
    final irrigation = double.tryParse(_irrigationCtrl.text) ?? 0;
    final pesticide = double.tryParse(_pesticideCtrl.text) ?? 0;
    final labor = double.tryParse(_laborCtrl.text) ?? 0;
    final other = double.tryParse(_otherCtrl.text) ?? 0;

    final expense = seed + fertilizer + irrigation + pesticide + labor + other;
    setState(() {
      _totalIncome = income;
      _totalExpense = expense;
      _netProfit = income - expense;
    });
  }

  void _resetLedger() {
    _incomeCtrl.clear();
    _seedCtrl.clear();
    _fertilizerCtrl.clear();
    _irrigationCtrl.clear();
    _pesticideCtrl.clear();
    _laborCtrl.clear();
    _otherCtrl.clear();
    setState(() {
      _totalIncome = 0;
      _totalExpense = 0;
      _netProfit = 0;
    });
  }

  @override
  void dispose() {
    _incomeCtrl.dispose();
    _seedCtrl.dispose();
    _fertilizerCtrl.dispose();
    _irrigationCtrl.dispose();
    _pesticideCtrl.dispose();
    _laborCtrl.dispose();
    _otherCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          widget.title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: widget.themeColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: StreamBuilder<Map<String, dynamic>>(
        stream: widget.firestoreService?.getAgriServiceStream(widget.serviceId) ?? Stream.value({}),
        builder: (context, snapshot) {
          final liveData = snapshot.data ?? {};
          final liveNotice = liveData['notice'] as String?;

          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Hero Card
                _buildHeroHeader(),

                // Live Firestore Notice if available
                if (liveNotice != null && liveNotice.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF8E1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFFFE082)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.campaign, color: Color(0xFFF57F17), size: 22),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            liveNotice,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFFE65100),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 16),

                // Specific Service Content Body
                _buildServiceContent(),

                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeroHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8E2)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: widget.bgColor,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Icon(widget.icon, color: widget.themeColor, size: 28),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: widget.themeColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _getServiceSubtitle(),
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getServiceSubtitle() {
    switch (widget.serviceId) {
      case 'irrigation':
        return 'আর্দ্রতা ও পূর্বাভাসের ওপর ভিত্তি করে পরিমিত সেচ নির্দেশনা';
      case 'machinery':
        return 'পাওয়ার টিলার, হার্ভেস্টার ও স্প্রেয়ার স্থানীয় ভাড়ার তালিকা';
      case 'dealers':
        return 'সরকারি অনুমোদিত সার ও বীজ বিক্রেতাদের ঠিকানা ও সরকারি রেট';
      case 'ledger':
        return 'বীজ, সার, সেচ ও ফসলের বিক্রির ডিজিটাল লাভ-লোকসান হিসাব';
      case 'calendar':
        return 'বাংলা ঋতু ও মাস অনুযায়ী রবি ও খরিপ ফসল আবাদের সময়সূচি';
      case 'soil':
        return 'মাটির ধরন ও বৈশিষ্ট্য অনুযায়ী সঠিক ফসল নির্বাচন ও ল্যাব তথ্য';
      case 'loans':
        return '৪% রেয়াতি সুদে শস্য ঋণ ও সরকারি প্রণোদনা প্রাপ্তির নিয়মাবলী';
      case 'livestock':
        return 'গরু, ছাগল ও মুরগির রোগবালাই দমন ও নিয়মিত টিকাদান সূচি';
      case 'fisheries':
        return 'পুকুর প্রস্তুতি, পোনা অবমুক্তকরণ ও আধুনিক মাছ চাষ নির্দেশিকা';
      case 'cold_storage':
        return 'আলু, পেঁয়াজ ও শস্য দীর্ঘদিন সঠিক পদ্ধতিতে সংরক্ষণের নিয়ম';
      case 'modern_tech':
        return 'মালচিং, সৌর সেচ পাম্প ও ফেরোমোন ফাঁদ দিয়ে বিষমুক্ত চাষ';
      default:
        return 'আধুনিক কৃষি সেবার নির্ভরযোগ্য নির্দেশিকা';
    }
  }

  Widget _buildServiceContent() {
    switch (widget.serviceId) {
      case 'irrigation':
        return _buildIrrigationContent();
      case 'machinery':
        return _buildMachineryContent();
      case 'dealers':
        return _buildDealersContent();
      case 'ledger':
        return _buildLedgerContent();
      case 'calendar':
        return _buildCalendarContent();
      case 'soil':
        return _buildSoilContent();
      case 'loans':
        return _buildLoansContent();
      case 'livestock':
        return _buildLivestockContent();
      case 'fisheries':
        return _buildFisheriesContent();
      case 'cold_storage':
        return _buildColdStorageContent();
      case 'modern_tech':
        return _buildModernTechContent();
      default:
        return _buildGeneralContent();
    }
  }

  // 1. SMART IRRIGATION
  Widget _buildIrrigationContent() {
    return Column(
      children: [
        _buildInfoCard(
          title: 'মাটির বর্তমান অবস্থা ও আবহাওয়া পূর্বাভাস',
          icon: Icons.water_drop,
          color: const Color(0xFF0288D1),
          items: const [
            'মাটির গড় আর্দ্রতা: প্রায় ৬৯% (পরিমিত আর্দ্রতা বিদ্যমান)',
            'বৃষ্টির শঙ্কা: ৩৫% (আগামী ২৪ ঘণ্টায় ভারী বৃষ্টির সম্ভাবনা কম)',
            'সুপারিশ: শাকসবজি ও ভুট্টায় বিকালবেলা হালকা সেচ দিন। নিচু জমিতে অতিরিক্ত পানি জমতে দেবেন না।',
          ],
        ),
        const SizedBox(height: 12),
        _buildInfoCard(
          title: 'প্রধান ফসলের সেচ সময়সূচি',
          icon: Icons.schedule,
          color: const Color(0xFF00897B),
          items: const [
            'বোরো ধান: চারা রোপণের পর ২০-২৫ দিন ছিপছিপে পানি রাখুন। ফুল আসার সময় পানির অভাব যেন না হয়।',
            'গম: বীজ বপনের ১৮-২১ দিনে মুকুট শিকড় গজানোর সময় ১ম সেচ এবং শিষ বের হলে ২য় সেচ দিন।',
            'ভুট্টা: হাঁটু সমান উচ্চতায় ১ম সেচ এবং মোচা গঠনের সময় অবশ্যই ২য় সেচ নিশ্চিত করুন।',
            'আলু: রোপণের ২০-২৫ দিন পর ১ম এবং ৪০-৪৫ দিন পর ২য় হালকা সেচ দিন।',
          ],
        ),
        const SizedBox(height: 12),
        _buildInfoCard(
          title: 'পানি সাশ্রয়ী আধুনিক কৌশল',
          icon: Icons.eco,
          color: const Color(0xFF2E7D32),
          items: const [
            'এডব্লিউডি (AWD) পদ্ধতি: ধানের জমিতে ছিদ্রযুক্ত পাইপ ব্যবহার করে পানি ৩০% সাশ্রয় হয়।',
            'ফিতা পাইপ সেচ: মাটির ওপর দিয়ে সহজে পানি পৌঁছায়, নালার অপচয় রোধ হয়।',
            'বিকালে সেচ প্রদান: দুপুরের কড়া রোদে সেচ দিলে বাষ্পীভবনে পানির অপচয় বেশি হয়।',
          ],
        ),
      ],
    );
  }

  // 2. MACHINERY RENTAL
  Widget _buildMachineryContent() {
    return Column(
      children: [
        _buildInfoCard(
          title: 'স্থানীয় যন্ত্রপাতির তালিকা ও সম্ভাব্য ভাড়ার হার',
          icon: Icons.agriculture,
          color: const Color(0xFFE65100),
          items: const [
            'কম্বাইন হার্ভেস্টার (ধান/গম কাটা, মাড়াই ও প্যাকেট): ৳১,৫০০ - ৳২,০০০ / বিঘা',
            'পাওয়ার টিলার ও ট্রাক্টর (জমি চাষ ও মই দেওয়া): ৳৮০০ - ৳১,২০০ / বিঘা',
            'পাওয়ার রিপার (দ্রুত ফসল কর্তন): ৳৬০০ - ৳৮০০ / বিঘা',
            'ব্যাটারি চালিত পাওয়ার স্প্রেয়ার: ৳১৫০ - ৳২০০ / দিন',
            'সেন্ট্রিফিউগাল সেচ পাম্প: ৳২০০ - ৳৩০০ / ঘণ্টা',
          ],
        ),
        const SizedBox(height: 12),
        _buildInfoCard(
          title: 'সরকারি উন্নয়ন সহায়তায় কৃষিযন্ত্র প্রাপ্তি',
          icon: Icons.account_balance,
          color: const Color(0xFF1565C0),
          items: const [
            'হাওর ও উপকূলীয় এলাকায় ৭০% এবং অন্যান্য এলাকায় ৫০% সরকারি ভর্তুকি দেওয়া হয়।',
            'উপজেলা কৃষি অফিসে কৃষক গ্রুপ বা ব্যক্তিগতভাবে আবেদন জমা দিতে হয়।',
            'আবেদনের জন্য জাতীয় পরিচয়পত্র, কৃষি কার্ড ও জমির দলিল প্রয়োজন।',
          ],
        ),
      ],
    );
  }

  // 3. INPUT DEALERS
  Widget _buildDealersContent() {
    return Column(
      children: [
        _buildInfoCard(
          title: 'সরকারি নির্ধারিত সারের সর্বোচ্চ খুচরা মূল্য',
          icon: Icons.price_check,
          color: const Color(0xFF2E7D32),
          items: const [
            'ইউরিয়া সার: ২৭ টাকা / কেজি (৫০ কেজির বস্তা ১,৩৫০ টাকা)',
            'টিএসপি (TSP) সার: ৩২ টাকা / কেজি (৫০ কেজির বস্তা ১,৬০০ টাকা)',
            'ডিএপি (DAP) সার: ২১ টাকা / কেজি (৫০ কেজির বস্তা ১,০৫০ টাকা)',
            'এমওপি (পটাশ) সার: ২০ টাকা / কেজি (৫০ কেজির বস্তা ১,০০০ টাকা)',
            'জিপসাম সার: ১০ - ১২ টাকা / কেজি',
          ],
        ),
        const SizedBox(height: 12),
        _buildInfoCard(
          title: 'ভেজাল সার ও নকল বীজ চেনার উপায়',
          icon: Icons.verified,
          color: const Color(0xFF6A1B9A),
          items: const [
            'আসল ইউরিয়া সার আগুনে দিলে কোনো ছাই না রেখে সম্পূর্ণ বাষ্প হয়ে উবে যাবে।',
            'আসল ডিএপি ও টিএসপিতে অম্লীয় গন্ধ থাকে এবং পানিতে দ্রুত গলে না।',
            'বিএডিসি অনুমোদিত বীজের প্যাকেটে সর্বদা অফিশিয়াল হলোগ্রাম সিল ও ব্যাচ নম্বর চেক করুন।',
            'অতিরিক্ত মূল্যে সার বিক্রি করলে উপজেলা নির্বাহী অফিসার বা কৃষি কর্মকর্তাকে জানান।',
          ],
        ),
      ],
    );
  }

  // 4. FARM LEDGER
  Widget _buildLedgerContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8E2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.calculate, color: Color(0xFF00897B)),
                  SizedBox(width: 8),
                  Text(
                    'সহজ ডিজিটাল আয়-ব্যয় ক্যালকুলেটর',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _incomeCtrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'ফসল বিক্রয় থেকে মোট আয় (টাকা)',
                  labelStyle: const TextStyle(fontSize: 13),
                  prefixIcon: const Icon(Icons.monetization_on, color: Colors.green),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
                onChanged: (_) => _calculateLedger(),
              ),
              const SizedBox(height: 12),
              const Text(
                'খরচের খাতসমূহ:',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 8),
              _buildLedgerInput(_seedCtrl, 'বীজ ও চারার খরচ (টাকা)', Icons.grass),
              const SizedBox(height: 8),
              _buildLedgerInput(_fertilizerCtrl, 'সার ও গোবরের খরচ (টাকা)', Icons.science),
              const SizedBox(height: 8),
              _buildLedgerInput(_irrigationCtrl, 'সেচ ও জ্বালানি খরচ (টাকা)', Icons.water_drop),
              const SizedBox(height: 8),
              _buildLedgerInput(_pesticideCtrl, 'বালাইনাশক ও স্প্রে খরচ (টাকা)', Icons.bug_report),
              const SizedBox(height: 8),
              _buildLedgerInput(_laborCtrl, 'শ্রমিকের মজুরি খরচ (টাকা)', Icons.group),
              const SizedBox(height: 8),
              _buildLedgerInput(_otherCtrl, 'পরিবহন ও অন্যান্য খরচ (টাকা)', Icons.local_shipping),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _calculateLedger,
                      icon: const Icon(Icons.check),
                      label: const Text('হিসাব সম্পন্ন করুন'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00897B),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton(
                    onPressed: _resetLedger,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('রিসেট'),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        // Result Box
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _netProfit >= 0 ? const Color(0xFFE8F5E9) : const Color(0xFFFFEBEE),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _netProfit >= 0 ? const Color(0xFFA5D6A7) : const Color(0xFFFFCDD2)),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('মোট প্রাপ্ত আয়:', style: TextStyle(fontSize: 14)),
                  Text(
                    '৳ ${BanglaNumberConverter.toBangla(_totalIncome.toStringAsFixed(0))}',
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.green),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('মোট খরচ:', style: TextStyle(fontSize: 14)),
                  Text(
                    '৳ ${BanglaNumberConverter.toBangla(_totalExpense.toStringAsFixed(0))}',
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.red),
                  ),
                ],
              ),
              const Divider(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _netProfit >= 0 ? 'নিট লাভ (মুনাফা):' : 'নিট লোকসান (ক্ষতি):',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '৳ ${BanglaNumberConverter.toBangla(_netProfit.abs().toStringAsFixed(0))}',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: _netProfit >= 0 ? const Color(0xFF1B5E20) : const Color(0xFFC62828),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLedgerInput(TextEditingController controller, String label, IconData icon) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(fontSize: 12),
        prefixIcon: Icon(icon, size: 20, color: Colors.grey),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      ),
      onChanged: (_) => _calculateLedger(),
    );
  }

  // 5. CROP CALENDAR
  Widget _buildCalendarContent() {
    return Column(
      children: [
        _buildInfoCard(
          title: 'রবি মৌসুম (কার্তিক - ফাল্গুন / অক্টোবর - মার্চ)',
          icon: Icons.ac_unit,
          color: const Color(0xFF6A1B9A),
          items: const [
            'প্রধান ফসল: বোরো ধান, গম, আলু, ভুট্টা, সরিষা, মসুর, পেঁয়াজ, রসুন।',
            'শীতকালীন সবজি: ফুলকপি, বাঁধাকপি, শিম, মুলা, গাজর, টমেটো, লালশাক।',
            'আদর্শ বপন সময়: মধ্য-কার্তিক থেকে অগ্রহায়ণের শেষ সপ্তাহ পর্যন্ত।',
          ],
        ),
        const SizedBox(height: 12),
        _buildInfoCard(
          title: 'খরিপ-১ মৌসুম (চৈত্র - জ্যৈষ্ঠ / মার্চ - জুন)',
          icon: Icons.wb_sunny,
          color: const Color(0xFFE65100),
          items: const [
            'প্রধান ফসল: আউশ ধান, তোষা ও দেশি পাট, তিল, গ্রীষ্মকালীন ভুট্টা।',
            'গ্রীষ্মকালীন সবজি: ঢ্যাঁড়শ, করলা, ঝিঙা, চিচিঙ্গা, পটল, মিষ্টি কুমড়া, ডাটা শাক।',
            'আদর্শ বপন সময়: চৈত্রের প্রথম বৃষ্টিপাতের পরপরই জমি চাষ করে বপন।',
          ],
        ),
        const SizedBox(height: 12),
        _buildInfoCard(
          title: 'খরিপ-২ মৌসুম (আষাঢ় - আশ্বিন / জুলাই - অক্টোবর)',
          icon: Icons.water,
          color: const Color(0xFF1565C0),
          items: const [
            'প্রধান ফসল: রোপা আমন ধান (ব্রি ধান-৪৯, ৮৭, স্বর্ণা ইত্যাদি), নাবী পাট।',
            'শাকসবজি: লাউ, চালকুমড়া, বরবটি এবং শীতের আগাম সবজির চারা তৈরি।',
            'চারা রোপণ সময়: শ্রাবণ মাসের মধ্যে রোপণ শেষ করা উত্তম।',
          ],
        ),
      ],
    );
  }

  // 6. SOIL HEALTH
  Widget _buildSoilContent() {
    return Column(
      children: [
        _buildInfoCard(
          title: 'মাটির প্রধান শ্রেণি ও উপযোগী ফসল',
          icon: Icons.terrain,
          color: const Color(0xFF6D4C41),
          items: const [
            'দোআঁশ মাটি: ধান, গম, আলু, ভুট্টা, সবজি সব ফসলের জন্যই সবচেয়ে আদর্শ।',
            'বেলে-দোআঁশ মাটি: আলু, তরমুজ, চিনা বাদাম, মিষ্টি আলু ও সবজিতে ভালো ফলন।',
            'এঁটেল মাটি: ধান, পাট, গম ও ডাল জাতীয় ফসলের জন্য উপযোগী।',
          ],
        ),
        const SizedBox(height: 12),
        _buildInfoCard(
          title: 'মাটির পিএইচ (pH) মাত্রা ও প্রতিকার',
          icon: Icons.science,
          color: const Color(0xFF00897B),
          items: const [
            'আদর্শ পিএইচ: ৬.০ থেকে ৭.০ (নিরপেক্ষ)।',
            'অম্লীয় মাটি (pH < ৬.০): শতকে ১-২ কেজি ডলোচুন প্রয়োগ করে অম্লতা কমানো যায়।',
            'ক্ষারীয় মাটি (pH > ৭.৫): জিপসাম ও বেশি করে পচা গোবর সার প্রয়োগ করতে হবে।',
          ],
        ),
        const SizedBox(height: 12),
        _buildInfoCard(
          title: 'উপজেলা মৃত্তিকা পরীক্ষা কেন্দ্র (SRDI)',
          icon: Icons.biotech,
          color: const Color(0xFF2E7D32),
          items: const [
            'মাত্র ২৫-৫০ টাকা খরচে উপজেলা পর্যায়ে মাটির পুষ্টি উপাদান পরীক্ষা করা যায়।',
            'নমুনা সংগ্রহের নিয়ম: জমি থেকে ইংরেজি V আকারে ৬ ইঞ্চি গভীর করে মাটি সংগ্রহ করুন।',
          ],
        ),
      ],
    );
  }

  // 7. AGRI LOANS
  Widget _buildLoansContent() {
    return Column(
      children: [
        _buildInfoCard(
          title: '৪% রেয়াতি সুদে বিশেষ শস্য ঋণ',
          icon: Icons.percent,
          color: const Color(0xFF1565C0),
          items: const [
            'ডাল, তেলবীজ, মসলা জাতীয় ফসল এবং ভুট্টা চাষে মাত্র ৪% রেয়াতি সুদে ঋণ পাওয়া যায়।',
            'বাংলাদেশ কৃষি ব্যাংক ও রাজশাহী কৃষি উন্নয়ন ব্যাংকের প্রতিটি শাখায় এই সুবিধা বিদ্যমান।',
          ],
        ),
        const SizedBox(height: 12),
        _buildInfoCard(
          title: 'সরকারি বীজ ও সার প্রণোদনা প্রাপ্তির নিয়ম',
          icon: Icons.card_giftcard,
          color: const Color(0xFF2E7D32),
          items: const [
            'ক্ষুদ্র ও প্রান্তিক কৃষকদের মাঝে সম্পূর্ণ বিনামূল্যে সার ও বীজ বিতরণ করা হয়।',
            'উপজেলা কৃষি পুনর্বাসন বাস্তবায়ন কমিটি ইউনিয়ন পর্যায়ে তালিকা প্রস্তুত করে।',
            'আবেদনের জন্য জাতীয় পরিচয়পত্র (NID) ও কৃষক কৃষি কার্ড থাকতে হবে।',
          ],
        ),
        const SizedBox(height: 12),
        _buildInfoCard(
          title: 'ঋণ আবেদনের প্রয়োজনীয় কাগজপত্র',
          icon: Icons.checklist,
          color: const Color(0xFFE65100),
          items: const [
            'কৃষকের জাতীয় পরিচয়পত্রের অনুলিপি ও ২ কপি পাসপোর্ট ছবি।',
            'কৃষি কার্ড ও ইউনিয়ন পরিষদের নাগরিকত্ব সনদ।',
            'নিজস্ব বা বর্গা চাষের জমির হালনাগাদ দাখিলা / খতিয়ান / প্রত্যয়নপত্র।',
          ],
        ),
      ],
    );
  }

  // 8. LIVESTOCK
  Widget _buildLivestockContent() {
    return Column(
      children: [
        _buildInfoCard(
          title: 'গরু ও ছাগলের সাধারণ রোগ ও চিকিৎসা',
          icon: Icons.pets,
          color: const Color(0xFFD84315),
          items: const [
            'খুরারোগ (FMD): মুখে ও পায়ে ক্ষত। পটাশ পানিতে পা ধোয়া ও সোহাগার গুঁড়া লাগান।',
            'তড়কা ও বাদলা রোগ: দ্রুত উপজেলা প্রাণিসম্পদ কর্মকর্তার শরণাপন্ন হয়ে অ্যান্টিবায়োটিক দিন।',
            'কৃমিনাশক: প্রতি ৩-৪ মাস অন্তর নিয়মিত কৃমিনাশক ট্যাবলেট খাওয়ান।',
          ],
        ),
        const SizedBox(height: 12),
        _buildInfoCard(
          title: 'হাঁস-মুরগির নিয়মিত টিকাদান সূচি',
          icon: Icons.medical_services,
          color: const Color(0xFF7B1FA2),
          items: const [
            'রাণীক্ষেত (BCRDV): বাচ্চার বয়স ৩-৫ দিনে চোখে ১ম ড্রপ এবং ২১ দিনে ২য় ড্রপ।',
            'গামবোরো: বাচ্চার ৯-১১ দিনে ১ম ডোজ এবং ১৭-১৯ দিনে বুস্টার ডোজ।',
            'ফাউল পক্স (বসন্ত): ৩৫-৪০ দিনে ডানার চামড়ায় সুঁই দিয়ে টিকা দিন।',
          ],
        ),
      ],
    );
  }

  // 9. FISHERIES
  Widget _buildFisheriesContent() {
    return Column(
      children: [
        _buildInfoCard(
          title: 'পুকুর প্রস্তুতি ও চুন প্রয়োগ',
          icon: Icons.water,
          color: const Color(0xFF0097A7),
          items: const [
            'পুকুরের পাড় মেরামত ও রাক্ষুসে মাছ নিধনে রোটেনন প্রয়োগ করুন।',
            'শতকে ১-২ কেজি চুন গুলিয়ে ছিটিয়ে দিলে পানির অম্লতা দূর হয় ও রোগ জীবাণু মরে।',
            'চুন দেওয়ার ৫-৭ দিন পর শতকে ৫-৭ কেজি গোবর ও ১০০ গ্রাম ইউরিয়া দিন।',
          ],
        ),
        const SizedBox(height: 12),
        _buildInfoCard(
          title: 'কার্প জাতীয় মাছের মিশ্র চাষ',
          icon: Icons.set_meal,
          color: const Color(0xFF1565C0),
          items: const [
            'উপরের স্তর: কাতলা ও সিলভার কার্প (প্লাঙ্কটন খায়)।',
            'মধ্য স্তর: রুই মাছ (জলের শেওলা ও খাদ্য খায়)।',
            'নিচের স্তর: মৃগেল ও কার্পিও (পুকুরের তলদেশের জৈব পদার্থ খায়)।',
            'শীতকালে ক্ষতরোগ দেখা দিলে শতকে ১০০ গ্রাম লবণ ও ৫০ গ্রাম পটাশ পানিতে দিন।',
          ],
        ),
      ],
    );
  }

  // 10. COLD STORAGE
  Widget _buildColdStorageContent() {
    return Column(
      children: [
        _buildInfoCard(
          title: 'আলু হিমাগারে রাখার পূর্বশর্ত',
          icon: Icons.inventory_2,
          color: const Color(0xFF5D4037),
          items: const [
            'পরিপক্ক ও খোসা শক্ত হওয়া আলু বাছাই করুন। কাটা বা দাগযুক্ত আলু আলাদা করুন।',
            'হিমাগারে নেওয়ার আগে ছায়াযুক্ত শুকনো স্থানে ৭-১০ দিন কিউরিং (শুকানো) করুন।',
            'হিমাগারে ৩-৪ ডিগ্রি সেলসিয়াস তাপমাত্রায় আলু ৬-৮ মাস সতেজ থাকে।',
          ],
        ),
        const SizedBox(height: 12),
        _buildInfoCard(
          title: 'ঘরোয়া পদ্ধতিতে পেঁয়াজ ও রসুন সংরক্ষণ',
          icon: Icons.home,
          color: const Color(0xFFE65100),
          items: const [
            'রোদে ভালো করে শুকিয়ে পাতার অংশ ২ ইঞ্চি রেখে কেটে ফেলুন।',
            'বাঁশের মাচায় আলো-বাতাস চলাচল করে এমন ঘরে পাতলা করে ছড়িয়ে রাখুন।',
            'প্লাস্টিকের বস্তায় রাখবেন না, এতে ঘেমে পচন ধরে।',
          ],
        ),
      ],
    );
  }

  // 11. MODERN TECH
  Widget _buildModernTechContent() {
    return Column(
      children: [
        _buildInfoCard(
          title: 'মালচিং পেপারে আধুনিক চাষাবাদ',
          icon: Icons.lightbulb,
          color: const Color(0xFFF57F17),
          items: const [
            'আগাছা জন্মানো প্রায় ১০০% বন্ধ করে, শ্রমিক খরচ অনেক কমে যায়।',
            'মাটির আর্দ্রতা ধরে রেখে সেচের পানির অপচয় ৫০% কমিয়ে দেয়।',
            'টমেটো, মরিচ, তরমুজ, স্ট্রবেরি ও শসায় অসাধারণ ফলন পাওয়া যায়।',
          ],
        ),
        const SizedBox(height: 12),
        _buildInfoCard(
          title: 'বিষমুক্ত চাষে সেক্স ফেরোমোন ট্র্যাপ',
          icon: Icons.pest_control,
          color: const Color(0xFF2E7D32),
          items: const [
            'পুরুষ পোকাকে আকর্ষণ করে ফাঁদে ফেলে মেরে ফেলে।',
            'বেগুন ও ডাল ফসলের ডগা ও ফল ছিদ্রকারী পোকা দমনে অত্যন্ত কার্যকর।',
            'পরিবেশের বন্ধু পোকাদের ক্ষতি করে না এবং রাসায়নিক বিষমুক্ত নিরাপদ সবজি মেলে।',
          ],
        ),
        const SizedBox(height: 12),
        _buildInfoCard(
          title: 'সৌরচালিত সেচ পাম্প ও কৃষি ড্রোন',
          icon: Icons.solar_power,
          color: const Color(0xFF0288D1),
          items: const [
            'বিদ্যুৎ বিল বা ডিজেলের খরচ ছাড়াই সারাদিন নিরবচ্ছিন্ন সেচ পাওয়া যায়।',
            'কৃষি ড্রোন দিয়ে এক একর জমিতে মাত্র ৫-১০ মিনিটে নিখুঁত বালাইনাশক স্প্রে করা সম্ভব।',
          ],
        ),
      ],
    );
  }

  Widget _buildGeneralContent() {
    return _buildInfoCard(
      title: 'সেবা বিবরণী',
      icon: widget.icon,
      color: widget.themeColor,
      items: const [
        'এই সেবার বিস্তারিত তথ্য ও দিকনির্দেশনা আপডেট করা হচ্ছে।',
        'যেকোনো জরুরি প্রয়োজনে কৃষি কল সেন্টারে ১৬১২৩ নম্বরে বিনামূল্যে কল দিন।',
      ],
    );
  }

  Widget _buildInfoCard({
    required String title,
    required IconData icon,
    required Color color,
    required List<String> items,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8E2)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...items.map((item) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('• ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    Expanded(
                      child: Text(
                        item,
                        style: const TextStyle(
                          fontSize: 13.5,
                          color: AppColors.textPrimary,
                          height: 1.35,
                        ),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}
