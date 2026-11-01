import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/utils/bangla_number_converter.dart';
import '../../core/widgets/custom_app_bar.dart';
import '../../providers/fertilizer_calculator_provider.dart';

class FertilizerCalculatorScreen extends StatefulWidget {
  const FertilizerCalculatorScreen({super.key});

  @override
  State<FertilizerCalculatorScreen> createState() => _FertilizerCalculatorScreenState();
}

class _FertilizerCalculatorScreenState extends State<FertilizerCalculatorScreen> {
  final TextEditingController _areaController = TextEditingController(text: '১০');
  final ScrollController _scrollController = ScrollController();
  bool _isCalculated = true;

  @override
  void dispose() {
    _areaController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onAreaChanged(String val, FertilizerCalculatorProvider provider) {
    final eng = BanglaNumberConverter.toEnglish(val);
    final parsed = double.tryParse(eng);
    if (parsed != null && parsed >= 0) {
      provider.setLandArea(parsed);
    }
  }

  void _handleCalculate(FertilizerCalculatorProvider provider) {
    final eng = BanglaNumberConverter.toEnglish(_areaController.text);
    final parsed = double.tryParse(eng) ?? 10.0;
    provider.setLandArea(parsed);
    setState(() {
      _isCalculated = true;
    });

    // Smooth subtle scroll to results
    Future.delayed(const Duration(milliseconds: 150), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          280,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final calcProvider = Provider.of<FertilizerCalculatorProvider>(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF7FAF7),
      appBar: const CustomAppBar(
        title: 'সুষম সার সুপারিশ ক্যালকুলেটর',
        showBackButton: false,
      ),
      body: SingleChildScrollView(
        controller: _scrollController,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ১. স্মার্ট ও সহজ ইনপুট সেকশন (User-Friendly Glassmorphic Input Card)
            _buildSmartInputCard(calcProvider),

            const SizedBox(height: 20),

            // ২. ফলাফল ও আনুমানিক সম্ভাব্য খরচ সেকশন
            if (_isCalculated && calcProvider.results.isNotEmpty) ...[
              // শিরোনাম ও জমি সারসংক্ষেপ
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.analytics_rounded, color: AppColors.primary, size: 22),
                      SizedBox(width: 8),
                      Text(
                        'প্রয়োজনীয় সারের সঠিক হিসাব',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F5E9),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFC8E6C9)),
                    ),
                    child: Text(
                      'জমি: ${BanglaNumberConverter.toBangla(calcProvider.landArea)} ${calcProvider.selectedUnit.split(' ')[0]}',
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryDark,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // আনুমানিক সম্ভাব্য সার খরচ কার্ড
              _buildEstimatedCostCard(calcProvider),

              const SizedBox(height: 14),

              // ৩. বিস্তারিত ও ভেঙে ভেঙে হিসাব প্রদর্শন (Individual Fertilizer Cards)
              ...calcProvider.results.map((item) {
                return _buildFertilizerItemCard(item);
              }),

              const SizedBox(height: 20),

              // ৪. "প্রয়োগের সঠিক নিয়ম ও সময়সূচি" গাইড (Application Timeline Guide)
              if (calcProvider.timelineSteps.isNotEmpty)
                _buildTimelineGuideCard(calcProvider),

              const SizedBox(height: 16),

              // ৫. বিশেষ সতর্কতা ও কৃষকের পরামর্শ (Farmer Safety Box)
              _buildSafetyAdviceCard(calcProvider),
            ],

            // ৬. ফিক্সড বটম মেনুবারের জন্য নিরাপদ ফাঁকা জায়গা (Full-Length Scrolling Safe Area)
            const SizedBox(height: 120),
          ],
        ),
      ),
    );
  }

  // ১. স্মার্ট ইনপুট কার্ড (User-Friendly Glassmorphic Input Card)
  Widget _buildSmartInputCard(FertilizerCalculatorProvider provider) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2E7D32).withOpacity(0.06),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.all(18.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // কার্ডের হেডার
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF2E7D32), Color(0xFF1B5E20)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF2E7D32).withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: const Icon(Icons.calculate_rounded, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'জমির সার পরিমাপক',
                      style: TextStyle(
                        fontSize: 16.5,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      'ফসল ও জমির পরিমাপ দিলে সঠিক সার জানুন',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          // ফসল নির্বাচন
          const Text(
            'ফসল নির্বাচন করুন',
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
              color: Color(0xFF2C3E50),
            ),
          ),
          const SizedBox(height: 7),
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAF7),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE0E8E1)),
            ),
            child: DropdownButtonFormField<String>(
              value: provider.selectedCrop,
              isExpanded: true,
              dropdownColor: Colors.white,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.eco_rounded, color: AppColors.primary, size: 22),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
              style: const TextStyle(
                fontSize: 14.5,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
              items: provider.supportedCrops.map((c) {
                return DropdownMenuItem(value: c, child: Text(c));
              }).toList(),
              onChanged: (val) {
                if (val != null) {
                  provider.setCrop(val);
                }
              },
            ),
          ),

          const SizedBox(height: 16),

          // জমির পরিমাণ ও একক ইনপুট (2 কলাম)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // জমির পরিমাণ ইনপুট
              Expanded(
                flex: 5,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'জমির পরিমাণ',
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF2C3E50),
                      ),
                    ),
                    const SizedBox(height: 7),
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAF7),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFE0E8E1)),
                      ),
                      child: TextFormField(
                        controller: _areaController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                        decoration: const InputDecoration(
                          hintText: '১০',
                          prefixIcon: Icon(Icons.straighten_rounded, color: AppColors.primary, size: 20),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        ),
                        onChanged: (val) => _onAreaChanged(val, provider),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 12),

              // জমির পরিমাপক একক নির্বাচন
              Expanded(
                flex: 6,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'পরিমাপক একক',
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF2C3E50),
                      ),
                    ),
                    const SizedBox(height: 7),
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAF7),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFE0E8E1)),
                      ),
                      child: DropdownButtonFormField<String>(
                        value: provider.selectedUnit,
                        isExpanded: true,
                        dropdownColor: Colors.white,
                        decoration: const InputDecoration(
                          prefixIcon: Icon(Icons.square_foot_rounded, color: AppColors.primary, size: 20),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                        ),
                        style: const TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                        items: provider.supportedUnits.map((u) {
                          return DropdownMenuItem(value: u, child: Text(u));
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            provider.setUnit(val);
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // কুইক ইনক্রিমেন্ট চিপস (দ্রুত যোগ)
          Row(
            children: [
              const Text(
                'দ্রুত যোগ: ',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: Row(
                    children: [
                      _buildQuickChip('+১', 1, provider),
                      _buildQuickChip('+৫', 5, provider),
                      _buildQuickChip('+১০', 10, provider),
                      _buildQuickChip('+৩৩ (১ বিঘা)', 33, provider),
                      _buildQuickChip('+১০০ (১ একর)', 100, provider),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          // "হিসাব করুন" অ্যাকশন বাটন (ভাইব্রেন্ট গ্রিন গ্রেডিয়েন্ট)
          InkWell(
            onTap: () => _handleCalculate(provider),
            borderRadius: BorderRadius.circular(16),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF2E7D32), Color(0xFF1B5E20)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF2E7D32).withOpacity(0.35),
                    blurRadius: 14,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.bolt_rounded, color: Color(0xFFFFD54F), size: 22),
                  SizedBox(width: 8),
                  Text(
                    'সারের সঠিক পরিমাণ হিসাব করুন',
                    style: TextStyle(
                      fontSize: 15.5,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickChip(String label, double val, FertilizerCalculatorProvider provider) {
    return Padding(
      padding: const EdgeInsets.only(right: 6.0),
      child: InkWell(
        onTap: () {
          final current = double.tryParse(BanglaNumberConverter.toEnglish(_areaController.text)) ?? 0;
          final updated = current + val;
          _areaController.text = (updated % 1 == 0 ? updated.toInt().toString() : updated.toStringAsFixed(1));
          provider.setLandArea(updated);
        },
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: const Color(0xFFE8F5E9),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFC8E6C9)),
          ),
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.primaryDark,
            ),
          ),
        ),
      ),
    );
  }

  // ২. আনুমানিক সম্ভাব্য খরচ সামারি কার্ড
  Widget _buildEstimatedCostCard(FertilizerCalculatorProvider provider) {
    final cost = provider.estimatedTotalCost;
    final formattedCost = BanglaNumberConverter.toBangla(cost.toInt());

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFE8F5E9), Color(0xFFF1F8E9)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFA5D6A7), width: 1.2),
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.account_balance_wallet_rounded, color: Color(0xFF1B5E20), size: 20),
                  SizedBox(width: 8),
                  Text(
                    'আনুমানিক সম্ভাব্য সার খরচ',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1B5E20),
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFA5D6A7)),
                ),
                child: const Text(
                  'ভর্তুকিমূল্য ভিত্তিক',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF2E7D32)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '৳ $formattedCost',
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF1B5E20),
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(width: 6),
              const Text(
                'টাকা (আনুমানিক মোট)',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF388E3C),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            '* সরকারি নির্ধারিত বিসিআইসি ডিলার বিক্রয়মূল্য অনুযায়ী আনুমানিক ব্যয় প্রাক্কলন। বাজারভেদে কিছুটা তারতম্য হতে পারে।',
            style: TextStyle(fontSize: 11.5, color: Color(0xFF558B2F), height: 1.3),
          ),
        ],
      ),
    );
  }

  // ৩. বিস্তারিত ও ভেঙে ভেঙে হিসাব প্রদর্শন (Individual Fertilizer Cards)
  Widget _buildFertilizerItemCard(FertilizerResult item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFEAEAEA), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // কার্ডের উপরের অংশ: আইকন, নাম ও পরিমাণ ব্যাজ
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // থিমযুক্ত কালারফুল আইকন
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: item.bgColor,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: item.primaryColor.withOpacity(0.2)),
                  ),
                  child: Icon(item.icon, color: item.primaryColor, size: 22),
                ),
                const SizedBox(width: 12),

                // সারের নাম ও বৈজ্ঞানিক উপাদান ট্যাগ
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.nameBn,
                        style: const TextStyle(
                          fontSize: 15.5,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      if (item.englishName.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          item.englishName,
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: item.primaryColor,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                // সারের পরিমাণ বড় হাইলাইট ব্যাজ
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: item.bgColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: item.primaryColor.withOpacity(0.35)),
                  ),
                  child: Text(
                    item.formattedAmount,
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w900,
                      color: item.primaryColor,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // সারের পুষ্টি ভূমিকা (গাছের উপকারে এর কাজ)
          if (item.role.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAF7),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFE8EFE8)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.check_circle_outline_rounded, size: 15, color: Color(0xFF2E7D32)),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        item.role,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF2C3E50),
                          height: 1.35,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          const SizedBox(height: 8),

          // প্রয়োগের সময়কাল নির্দেশক স্ট্রিপ
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: const BoxDecoration(
              color: Color(0xFFFAFAFA),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(18),
                bottomRight: Radius.circular(18),
              ),
              border: Border(
                top: BorderSide(color: Color(0xFFEEEEEE), width: 0.8),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.schedule_rounded, size: 14, color: AppColors.textSecondary),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'প্রয়োগ: ${item.applicationStage}',
                    style: const TextStyle(
                      fontSize: 11.5,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ৪. "প্রয়োগের সঠিক নিয়ম ও সময়সূচি" গাইড (Application Timeline Guide)
  Widget _buildTimelineGuideCard(FertilizerCalculatorProvider provider) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.timeline_rounded, color: AppColors.primary, size: 22),
              SizedBox(width: 8),
              Text(
                'সার প্রয়োগের সঠিক সময়সূচি ও নিয়ম',
                style: TextStyle(
                  fontSize: 16.5,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'সঠিক সময়ে সার দিলে প্রতিটি দানার সর্বোত্তম কার্যকারিতা পাওয়া যায়',
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 16),

          // টাইমলাইন স্টেপসমূহ
          ...List.generate(provider.timelineSteps.length, (index) {
            final step = provider.timelineSteps[index];
            final isLast = (index == provider.timelineSteps.length - 1);

            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // টাইমলাইন গোল মার্কার ও কানেক্টিং লাইন
                Column(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: step.color,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: step.color.withOpacity(0.3),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          BanglaNumberConverter.toBangla(index + 1),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                    if (!isLast)
                      Container(
                        width: 2,
                        height: 65,
                        color: const Color(0xFFC8E6C9),
                        margin: const EdgeInsets.symmetric(vertical: 4),
                      ),
                  ],
                ),
                const SizedBox(width: 14),

                // স্টেপ বিবরণ
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 14.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          step.stageTitle,
                          style: const TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F8F1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'সময়: ${step.timing}',
                            style: const TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primaryDark,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: step.fertilizers.map((f) {
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: const Color(0xFFB0BEC5)),
                              ),
                              child: Text(
                                f,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF37474F),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          step.instructions,
                          style: const TextStyle(
                            fontSize: 12.5,
                            color: Color(0xFF455A64),
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          }),
        ],
      ),
    );
  }

  // ৫. বিশেষ সতর্কতা ও কৃষকের পরামর্শ (Safety Box)
  Widget _buildSafetyAdviceCard(FertilizerCalculatorProvider provider) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEA),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFFFE082), width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.lightbulb_rounded, color: Color(0xFFF57F17), size: 22),
              SizedBox(width: 8),
              Text(
                'সার প্রয়োগের বিশেষ সতর্কতা ও পরামর্শ',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFFE65100),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...provider.safetyTips.map((tip) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 6.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('• ', style: TextStyle(color: Color(0xFFE65100), fontSize: 16, fontWeight: FontWeight.bold)),
                  Expanded(
                    child: Text(
                      tip,
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: Color(0xFF5D4037),
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
