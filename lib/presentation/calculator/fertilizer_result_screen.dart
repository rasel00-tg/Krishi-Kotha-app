import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/bangla_number_converter.dart';
import '../../providers/fertilizer_calculator_provider.dart';

class FertilizerResultScreen extends StatelessWidget {
  final String crop;
  final double landArea;
  final String unit;
  final String? category;

  const FertilizerResultScreen({
    super.key,
    required this.crop,
    required this.landArea,
    required this.unit,
    this.category,
  });

  @override
  Widget build(BuildContext context) {
    final calcProvider = Provider.of<FertilizerCalculatorProvider>(context);
    final results = calcProvider.results;
    final timelineSteps = calcProvider.timelineSteps;

    return Scaffold(
      backgroundColor: const Color(0xFFF7FAF7),
      body: SafeArea(
        child: Column(
          children: [
            // ১. আধুনিক টপ হেডার (Logo, Back Button, Title)
            _buildHeader(context),

            // ২. স্ক্রলেবল কনটেন্ট বডি
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // জমির সারসংক্ষেপ তথ্য কার্ড/ব্যাজ
                    _buildSummaryCard(),

                    const SizedBox(height: 14),

                    // আনুমানিক সম্ভাব্য মোট খরচ কার্ড
                    _buildEstimatedCostCard(calcProvider),

                    const SizedBox(height: 16),

                    // সেকশন হেডার
                    const Row(
                      children: [
                        Icon(Icons.grass_rounded, color: AppColors.primary, size: 22),
                        SizedBox(width: 8),
                        Text(
                          'সারের তালিকা ও নির্দিষ্ট পরিমাণ',
                          style: TextStyle(
                            fontSize: 16.5,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // ৩. প্রতি সারের আলাদা রঙিন কার্ড
                    if (results.isEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: const Center(
                          child: Text(
                            'কোনো সারের তথ্য পাওয়া যায়নি। অনুগ্রহ করে সঠিক তথ্য দিয়ে পুনরায় চেষ্টা করুন।',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
                          ),
                        ),
                      )
                    else
                      ...results.map((item) => _buildFertilizerItemCard(item)),

                    const SizedBox(height: 20),

                    // ৪. প্রয়োগের সঠিক নিয়ম ও সময়সূচি (Timeline Guide)
                    if (timelineSteps.isNotEmpty)
                      _buildTimelineGuideCard(calcProvider),

                    const SizedBox(height: 16),

                    // ৫. সার প্রয়োগের বিশেষ সতর্কতা ও কৃষকের পরামর্শ
                    _buildSafetyAdviceCard(calcProvider),

                    const SizedBox(height: 20),

                    // পুনরায় হিসাব বা ইনপুট পরিবর্তন বাটন
                    InkWell(
                      onTap: () => Navigator.pop(context),
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.primary, width: 1.5),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withOpacity(0.08),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.edit_note_rounded, color: AppColors.primary, size: 22),
                            SizedBox(width: 8),
                            Text(
                              'নতুন জমির হিসাব বা পরিবর্তন করুন',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // ৬. ফিক্সড বটম মেনুবারের জন্য নিরাপদ ফাঁকা জায়গা (Full-Length Scrolling Safe Area)
                    const SizedBox(height: 120),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ১. আধুনিক হেডার বার
  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 10.0),
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(
          bottom: BorderSide(color: Color(0xFFEAEAEA), width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // ব্যাক বাটন
          InkWell(
            onTap: () => Navigator.pop(context),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F8F1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFC8E6C9)),
              ),
              child: const Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 18,
                color: AppColors.primaryDark,
              ),
            ),
          ),

          const SizedBox(width: 12),

          // আসল অ্যাপ লোগো (ক্রিস্প ও ফ্রেমড)
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE0E8E1), width: 1.2),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF2E7D32).withOpacity(0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
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
                  color: AppColors.primaryLight.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.eco_rounded, color: AppColors.primary, size: 22),
              ),
            ),
          ),

          const SizedBox(width: 10),

          // টাইটেল ও সাবটাইটেল
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'আপনার জমির সারের সঠিক হিসাব',
                  style: TextStyle(
                    fontSize: 16.5,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.2,
                  ),
                ),
                Text(
                  'কৃষি গবেষণা ইনস্টিটিউট ও বার্ক নির্দেশিকা ভিত্তিক',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ২. জমির সারসংক্ষেপ তথ্য কার্ড
  Widget _buildSummaryCard() {
    final cleanUnit = unit.split(' ')[0];
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2E7D32).withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (category != null && category!.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF8E1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFFFE082)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.category_rounded, size: 14, color: Color(0xFFF57F17)),
                  const SizedBox(width: 6),
                  Text(
                    'ক্যাটাগরি: $category',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFFE65100),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
          ],
          Row(
            children: [
              // ফসল ব্যাজ
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F8F1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFC8E6C9)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.eco_rounded, size: 18, color: AppColors.primary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'নির্বাচিত ফসল',
                              style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                            ),
                            Text(
                              crop,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: AppColors.primaryDark,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(width: 10),

              // জমির পরিমাণ ব্যাজ
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE3F2FD),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFBBDEFB)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.square_foot_rounded, size: 18, color: Color(0xFF1976D2)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'জমির পরিমাণ',
                              style: TextStyle(fontSize: 11, color: Color(0xFF546E7A)),
                            ),
                            Text(
                              '${BanglaNumberConverter.toBangla(landArea)} $cleanUnit',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF0D47A1),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ৩. আনুমানিক সম্ভাব্য খরচ সামারি কার্ড
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

  // ৪. বিস্তারিত ও ভেঙে ভেঙে হিসাব প্রদর্শন (Individual Fertilizer Cards)
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

  // ৫. "প্রয়োগের সঠিক নিয়ম ও সময়সূচি" গাইড (Application Timeline Guide)
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

  // ৫. সার প্রয়োগ ও স্বাস্থ্য ঝুঁকির পূর্ণাঙ্গ সতর্কবার্তা (Comprehensive Safety & Health Hazards)
  Widget _buildSafetyAdviceCard(FertilizerCalculatorProvider provider) {
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

