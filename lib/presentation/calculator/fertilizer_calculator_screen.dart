import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/utils/bangla_number_converter.dart';
import '../../core/widgets/custom_app_bar.dart';
import '../../core/widgets/custom_button.dart';
import '../../providers/fertilizer_calculator_provider.dart';

class FertilizerCalculatorScreen extends StatefulWidget {
  const FertilizerCalculatorScreen({super.key});

  @override
  State<FertilizerCalculatorScreen> createState() => _FertilizerCalculatorScreenState();
}

class _FertilizerCalculatorScreenState extends State<FertilizerCalculatorScreen> {
  final TextEditingController _areaController = TextEditingController(text: '১০');

  @override
  void dispose() {
    _areaController.dispose();
    super.dispose();
  }

  void _onAreaChanged(String val, FertilizerCalculatorProvider provider) {
    final eng = BanglaNumberConverter.toEnglish(val);
    final parsed = double.tryParse(eng);
    if (parsed != null) {
      provider.setLandArea(parsed);
    }
  }

  @override
  Widget build(BuildContext context) {
    final calcProvider = Provider.of<FertilizerCalculatorProvider>(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const CustomAppBar(
        title: AppStrings.calcTitle,
        showBackButton: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Input Control Card
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
                side: const BorderSide(color: AppColors.border),
              ),
              child: Padding(
                padding: const EdgeInsets.all(18.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Crop Selector
                    const Text(
                      'ফসল নির্বাচন করুন',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: calcProvider.selectedCrop,
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.grass_rounded, color: AppColors.primary),
                      ),
                      items: calcProvider.supportedCrops.map((c) {
                        return DropdownMenuItem(value: c, child: Text(c));
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) calcProvider.setCrop(val);
                      },
                    ),
                    const SizedBox(height: 18),

                    // Land Area Input and Unit Selector
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Land Area Input
                        Expanded(
                          flex: 5,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                AppStrings.landArea,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _areaController,
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                decoration: const InputDecoration(
                                  hintText: '১০',
                                  prefixIcon: Icon(Icons.square_foot_rounded, color: AppColors.primary),
                                ),
                                onChanged: (val) => _onAreaChanged(val, calcProvider),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),

                        // Unit Selector
                        Expanded(
                          flex: 6,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                AppStrings.selectUnit,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 8),
                              DropdownButtonFormField<String>(
                                value: calcProvider.selectedUnit,
                                isExpanded: true,
                                decoration: const InputDecoration(
                                  contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 16),
                                ),
                                items: calcProvider.supportedUnits.map((u) {
                                  return DropdownMenuItem(
                                    value: u,
                                    child: Text(u, style: const TextStyle(fontSize: 14)),
                                  );
                                }).toList(),
                                onChanged: (val) {
                                  if (val != null) calcProvider.setUnit(val);
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),
                    // Quick Increment Buttons
                    Row(
                      children: [
                        const Text(
                          'দ্রুত যোগ করুন: ',
                          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                        ...[5, 10, 33, 100].map((num) {
                          return Padding(
                            padding: const EdgeInsets.only(left: 6.0),
                            child: ActionChip(
                              label: Text(
                                '+${BanglaNumberConverter.toBangla(num)}',
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                              onPressed: () {
                                final current = double.tryParse(_areaController.text) ?? 0;
                                final updated = current + num;
                                _areaController.text = updated.toInt().toString();
                                calcProvider.setLandArea(updated);
                              },
                              backgroundColor: AppColors.primaryContainer,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                          );
                        }).toList(),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Results Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  AppStrings.calcResultTitle,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  'মোট জমি: ${BanglaNumberConverter.toBangla(calcProvider.landArea)} ${calcProvider.selectedUnit}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Fertilizer Items Cards
            ...calcProvider.results.map((item) {
              return _buildFertilizerResultCard(item);
            }).toList(),

            const SizedBox(height: 16),

            // Application Guidelines Card
            if (calcProvider.applicationGuidelines.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.secondaryContainer),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.assignment_outlined, color: AppColors.primary, size: 22),
                        SizedBox(width: 8),
                        Text(
                          AppStrings.applicationSchedule,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryDark,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      calcProvider.applicationGuidelines,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textPrimary,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildFertilizerResultCard(FertilizerResult item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border, width: 0.8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Row(
          children: [
            // Icon
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.science_rounded, color: AppColors.primary, size: 24),
            ),
            const SizedBox(width: 14),

            // Name & Stage
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.nameBn,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.applicationStage,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),

            // Amount Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF81C784)),
              ),
              child: Text(
                item.formattedAmount,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryDark,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
