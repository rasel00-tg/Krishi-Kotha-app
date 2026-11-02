import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/bangla_number_converter.dart';
import '../../providers/fertilizer_calculator_provider.dart';
import 'fertilizer_result_screen.dart';

class FertilizerCalculatorScreen extends StatefulWidget {
  const FertilizerCalculatorScreen({super.key});

  @override
  State<FertilizerCalculatorScreen> createState() => _FertilizerCalculatorScreenState();
}

class _FertilizerCalculatorScreenState extends State<FertilizerCalculatorScreen> {
  final TextEditingController _areaController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  String? _selectedCategory;
  String? _selectedCrop;
  String _selectedUnit = 'শতক / শতাংশ';

  @override
  void dispose() {
    _areaController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onAreaChanged(String val, FertilizerCalculatorProvider provider) {
    // Keep local controller value synced
  }

  void _handleCalculate(BuildContext context, FertilizerCalculatorProvider provider) {
    final areaText = _areaController.text.trim();
    final eng = BanglaNumberConverter.toEnglish(areaText);
    final parsed = double.tryParse(eng);

    // Validation check: ensure category and crop are selected and area is greater than 0
    if (_selectedCategory == null ||
        _selectedCategory!.trim().isEmpty ||
        _selectedCrop == null ||
        _selectedCrop!.trim().isEmpty ||
        areaText.isEmpty ||
        parsed == null ||
        parsed <= 0) {
      _showValidationDialog(context);
      return;
    }

    // Set data in provider
    provider.setCategory(_selectedCategory);
    provider.setCrop(_selectedCrop!);
    provider.setUnit(_selectedUnit);
    provider.setLandArea(parsed);

    // Navigate to full dedicated result page
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FertilizerResultScreen(
          category: _selectedCategory,
          crop: _selectedCrop!,
          landArea: parsed,
          unit: _selectedUnit,
        ),
      ),
    );
  }

  void _showValidationDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        elevation: 8,
        backgroundColor: Colors.white,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF3E0),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFFFB74D), width: 1.5),
                ),
                child: const Icon(
                  Icons.warning_amber_rounded,
                  color: Color(0xFFE65100),
                  size: 32,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'তথ্য অসম্পূর্ণ',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'অনুগ্রহ করে সবকটি নির্দিষ্ট ঘর সঠিকভাবে পূরণ করুন',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF5D4037),
                  height: 1.4,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text(
                    'ঠিক আছে',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
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
    final calcProvider = Provider.of<FertilizerCalculatorProvider>(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF7FAF7),
      appBar: null, // ডিফল্ট AppBar অপসারিত
      body: SafeArea(
        child: SingleChildScrollView(
          controller: _scrollController,
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ১. আধুনিক আকর্ষণীয় হেডলাইন সেকশন
              _buildTopHeader(),

              const SizedBox(height: 18),

              // ২. স্মার্ট ও ক্লিন ইনপুট সেকশন
              _buildSmartInputCard(context, calcProvider),

              const SizedBox(height: 20),

              // ৩. হিসাব করার আগের ভিউ: গাইড ও সতর্কতা কার্ডসমূহ
              _buildHowToCalculateCard(),

              const SizedBox(height: 14),

              _buildGeneralSafetyCard(),

              // ৪. ফিক্সড বটম মেনুবারের জন্য নিরাপদ ফাঁকা জায়গা (Full-Length Scrolling Safe Area)
              const SizedBox(height: 120),
            ],
          ),
        ),
      ),
    );
  }

  // ১. আধুনিক আকর্ষণীয় শীর্ষ হেডলাইন সেকশন (একমাত্র মূল হেডার ও আসল লোগো)
  Widget _buildTopHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE0E8E1), width: 1.2),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF2E7D32).withOpacity(0.08),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Image.asset(
              'assets/icons/pnglogo.png',
              height: 38,
              width: 38,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.eco_rounded, color: AppColors.primary, size: 22),
              ),
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'কৃষি ও সার ক্যালকুলেটর',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.3,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'আপনার জমির সঠিক মাপে প্রয়োজনীয় সারের সঠিক হিসাব জানুন',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ২. স্মার্ট ও ক্লিন ইনপুট কার্ড (ডুপ্লিকেট হেডার অপসারিত)
  Widget _buildSmartInputCard(BuildContext context, FertilizerCalculatorProvider provider) {
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
          // ১. ফসলের ক্যাটাগরি নির্বাচন (Category-First Flow)
          const Text(
            'ফসলের ক্যাটাগরি',
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
              value: _selectedCategory,
              isExpanded: true,
              dropdownColor: Colors.white,
              hint: const Text(
                'ক্যাটাগরি নির্বাচন করুন',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                ),
              ),
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.category_rounded, color: AppColors.primary, size: 22),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
              style: const TextStyle(
                fontSize: 14.5,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
              items: FertilizerCalculatorProvider.supportedCategories.map((cat) {
                return DropdownMenuItem(value: cat, child: Text(cat));
              }).toList(),
              onChanged: (cat) {
                setState(() {
                  _selectedCategory = cat;
                  _selectedCrop = null;
                  provider.setCategory(cat);
                });
              },
            ),
          ),

          const SizedBox(height: 16),

          // ২. ফসল নির্বাচন (ক্যাটাগরি অনুযায়ী ফিল্টারকৃত ডাইনামিক তালিকা)
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
              value: _selectedCrop,
              isExpanded: true,
              dropdownColor: Colors.white,
              hint: Text(
                _selectedCategory == null ? 'প্রথমে ক্যাটাগরি নির্বাচন করুন' : 'ফসলের নাম নির্বাচন করুন',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                ),
              ),
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
              items: (_selectedCategory == null
                      ? <String>[]
                      : (FertilizerCalculatorProvider.cropCategories[_selectedCategory] ?? <String>[]))
                  .map((c) {
                return DropdownMenuItem(value: c, child: Text(c));
              }).toList(),
              onChanged: _selectedCategory == null
                  ? null
                  : (val) {
                      setState(() {
                        _selectedCrop = val;
                      });
                    },
            ),
          ),

          const SizedBox(height: 16),

          // জমির পরিমাণ ও একক ইনপুট (2 কলাম)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // জমির পরিমাণ ইনপুট (শুরুতে সম্পূর্ণ ফাঁকা)
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
                          hintText: 'জমির পরিমাণ লিখুন',
                          hintStyle: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textSecondary,
                          ),
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
                        value: _selectedUnit,
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
                            setState(() {
                              _selectedUnit = val;
                            });
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // "হিসাব করুন" অ্যাকশন বাটন (ভাইব্রেন্ট গ্রিন গ্রেডিয়েন্ট)
          InkWell(
            onTap: () => _handleCalculate(context, provider),
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

  // ৩.১ "কীভাবে হিসাব করবেন?" গাইড কার্ড
  Widget _buildHowToCalculateCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFC8E6C9), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2E7D32).withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.help_outline_rounded, color: AppColors.primary, size: 20),
              ),
              const SizedBox(width: 10),
              const Text(
                'কীভাবে হিসাব করবেন?',
                style: TextStyle(
                  fontSize: 15.5,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primaryDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _buildStepRow('১', 'প্রথমে আপনার ফসলের ক্যাটাগরি ও ফসল নির্বাচন করুন।'),
          const SizedBox(height: 10),
          _buildStepRow('২', 'আপনার জমির একক (শতক, কাঠা বা বিঘা) ও সঠিক পরিমাপ লিখুন।'),
          const SizedBox(height: 10),
          _buildStepRow('৩', '"সারের সঠিক পরিমাণ হিসাব করুন" বাটনে চাপুন।'),
        ],
      ),
    );
  }

  Widget _buildStepRow(String stepNumber, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: const Color(0xFF2E7D32),
            borderRadius: BorderRadius.circular(7),
          ),
          alignment: Alignment.center,
          child: Text(
            stepNumber,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF37474F),
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }

  // ৩.২ সার প্রয়োগ ও স্বাস্থ্য ঝুঁকির পূর্ণাঙ্গ সতর্কবার্তা (Comprehensive Safety & Health Hazards)
  Widget _buildGeneralSafetyCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFFFCC80), width: 1.3),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFE65100).withOpacity(0.06),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // কার্ডের মূল হেডার
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFE65100), Color(0xFFBF360C)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(11),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFE65100).withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: const Icon(Icons.health_and_safety_rounded, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'সার প্রয়োগ ও স্বাস্থ্য ঝুঁকির পূর্ণাঙ্গ সতর্কতা',
                      style: TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFFBF360C),
                      ),
                    ),
                    Text(
                      'কৃষক ভাইদের স্বাস্থ্য সুরক্ষা ও জরুরি প্রাথমিক চিকিৎসা নির্দেশিকা',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // সেকশন ১: সাধারণ সতর্কতা
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFBEA),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFFFE082)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.shield_outlined, color: Color(0xFFE65100), size: 17),
                    SizedBox(width: 6),
                    Text(
                      'সাধারণ সতর্কতা',
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFFE65100),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                _buildBulletItem('অতিরিক্ত সার প্রয়োগ থেকে বিরত থাকুন; অতিরিক্ত রাসায়নিক সার মাটির গঠন ও উর্বরতা নষ্ট করে।'),
                _buildBulletItem('কড়া রোদ বা বৃষ্টির দিনে জমিতে ইউরিয়া সার ছিটাবেন না।'),
                _buildBulletItem('রাসায়নিক সারের পাশাপাশি নিয়মিত জমিতে কম্পোস্ট বা জৈব সার প্রয়োগ করুন।', isLast: true),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // সেকশন ২: স্বাস্থ্য ঝুঁকি ও জরুরি প্রাথমিক চিকিৎসা (Health Hazards & First Aid)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF5F5),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFFFCDD2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.medical_services_rounded, color: Color(0xFFC62828), size: 17),
                    SizedBox(width: 6),
                    Text(
                      'স্বাস্থ্য ঝুঁকি ও জরুরি প্রাথমিক চিকিৎসা',
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFFC62828),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                _buildHazardItem(
                  title: 'পেটে বা মুখে গেলে:',
                  description: 'রাসায়নিক সার (বিশেষ করে ইউরিয়া, ডিএপি বা দস্তা) ভুলবশত মুখে বা পেটে চলে গেলে বমি করানোর চেষ্টা করবেন না; তৎক্ষণাৎ প্রচুর পরিষ্কার পানি পান করান এবং দ্রুত নিকটস্থ স্বাস্থ্য কমপ্লেক্স বা চিকিৎসকের কাছে নিয়ে যান।',
                  icon: Icons.emergency_rounded,
                  iconColor: const Color(0xFFD32F2F),
                ),
                const SizedBox(height: 8),
                _buildHazardItem(
                  title: 'চোখ ও ত্বকের সংস্পর্শে এলে:',
                  description: 'সার ছিটানোর সময় চোখে বা ক্ষতস্থানে লাগলে কমপক্ষে ১৫ মিনিট পরিষ্কার ঠান্ডা পানির ঝাপটা দিন এবং সাবান দিয়ে হাত-পা ভালো করে ধুয়ে ফেলুন।',
                  icon: Icons.visibility_rounded,
                  iconColor: const Color(0xFFC2185B),
                ),
                const SizedBox(height: 8),
                _buildHazardItem(
                  title: 'সার ছিটানোর সময় সতর্কতা:',
                  description: 'খালি গায়ে বা খালি হাতে সার ছিটানো নিষেধ; মাস্ক, গ্লাভস ও ফুল হাতা পোশাক ব্যবহার করুন।',
                  icon: Icons.masks_rounded,
                  iconColor: const Color(0xFF1976D2),
                ),
                const SizedBox(height: 8),
                _buildHazardItem(
                  title: 'শিশু ও গবাদি পশু থেকে সুরক্ষা:',
                  description: 'সার সবসময় শুষ্ক ও নিরাপদ স্থানে শিশুদের নাগালের বাইরে রাখুন এবং জমিতে সার ছিটানোর পর কয়েকদিন গবাদি পশু চড়ানো থেকে বিরত থাকুন।',
                  icon: Icons.pets_rounded,
                  iconColor: const Color(0xFFE65100),
                  isLast: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBulletItem(String text, {bool isLast = false}) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 2),
            child: Icon(Icons.check_circle_rounded, color: Color(0xFFFFA000), size: 15),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
                color: Color(0xFF5D4037),
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHazardItem({
    required String title,
    required String description,
    required IconData icon,
    required Color iconColor,
    bool isLast = false,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(7),
            ),
            child: Icon(icon, color: iconColor, size: 15),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(
                  fontSize: 12.5,
                  color: Color(0xFF37474F),
                  height: 1.45,
                ),
                children: [
                  TextSpan(
                    text: '$title ',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: iconColor,
                    ),
                  ),
                  TextSpan(
                    text: description,
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF455A64),
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
}
