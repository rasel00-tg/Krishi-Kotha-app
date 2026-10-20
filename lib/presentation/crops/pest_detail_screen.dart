import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/widgets/custom_app_bar.dart';
import '../../core/widgets/custom_button.dart';
import '../../data/models/pest_disease_model.dart';
import '../support/expert_helpline_screen.dart';

class PestDetailScreen extends StatelessWidget {
  final PestDiseaseModel pest;

  const PestDetailScreen({super.key, required this.pest});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: CustomAppBar(title: pest.nameBn),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // High-Resolution Image Banner
            if (pest.imageUrl.isNotEmpty)
              CachedNetworkImage(
                imageUrl: pest.imageUrl,
                height: 220,
                width: double.infinity,
                fit: BoxFit.cover,
                errorWidget: (_, __, ___) => Container(
                  height: 180,
                  color: const Color(0xFFFCE4EC),
                  child: const Center(
                    child: Icon(Icons.bug_report, size: 64, color: Color(0xFFC2185B)),
                  ),
                ),
              ),

            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title & Crop badge
                  Text(
                    pest.nameBn,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  if (pest.cropNameBn.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primaryContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'আক্রান্ত ফসল: ${pest.cropNameBn}',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryDark,
                        ),
                      ),
                    ),
                  const SizedBox(height: 20),

                  // 1. Symptoms Card
                  _buildSectionCard(
                    icon: Icons.visibility_outlined,
                    iconColor: const Color(0xFFE65100),
                    bgColor: const Color(0xFFFFF3E0),
                    title: AppStrings.symptoms,
                    content: pest.symptoms,
                  ),
                  const SizedBox(height: 14),

                  // 2. Organic Cure Card
                  _buildSectionCard(
                    icon: Icons.eco_outlined,
                    iconColor: AppColors.primary,
                    bgColor: AppColors.surfaceVariant,
                    title: AppStrings.organicCure,
                    content: pest.organicCure,
                  ),
                  const SizedBox(height: 14),

                  // 3. Chemical Cure Card
                  _buildSectionCard(
                    icon: Icons.science_outlined,
                    iconColor: const Color(0xFF1565C0),
                    bgColor: const Color(0xFFE3F2FD),
                    title: AppStrings.chemicalCure,
                    content: pest.chemicalCure,
                  ),
                  const SizedBox(height: 14),

                  // 4. Precaution Card
                  if (pest.precaution.isNotEmpty) ...[
                    _buildSectionCard(
                      icon: Icons.shield_outlined,
                      iconColor: const Color(0xFF6A1B9A),
                      bgColor: const Color(0xFFF3E5F5),
                      title: AppStrings.precaution,
                      content: pest.precaution,
                    ),
                    const SizedBox(height: 20),
                  ],

                  // Ask Officer Button
                  CustomButton(
                    text: 'সমস্যা সমাধান না হলে কৃষি কর্মকর্তার পরামর্শ নিন',
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const ExpertHelplineScreen()),
                      );
                    },
                    icon: Icons.support_agent_rounded,
                    backgroundColor: AppColors.primary,
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
    required String title,
    required String content,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 0.8),
        boxShadow: const [
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Icon(icon, color: iconColor, size: 22),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: iconColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14.0),
            child: Text(
              content,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textPrimary,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
