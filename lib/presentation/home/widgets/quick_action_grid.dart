import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/utils/bangla_number_converter.dart';
import '../../../data/services/firestore_service.dart';
import '../agri_service_detail_screen.dart';
import '../../support/expert_helpline_screen.dart';

class QuickActionItem {
  final String id;
  final String title;
  final IconData icon;
  final Color color;
  final Color bgColor;
  final VoidCallback onTap;

  const QuickActionItem({
    required this.id,
    required this.title,
    required this.icon,
    required this.color,
    required this.bgColor,
    required this.onTap,
  });
}

class QuickActionGrid extends StatelessWidget {
  final Function(int tabIndex)? onNavigateTab;
  final VoidCallback onOpenPestCatalog;
  final FirestoreService? firestoreService;

  const QuickActionGrid({
    super.key,
    this.onNavigateTab,
    required this.onOpenPestCatalog,
    this.firestoreService,
  });

  void _openServiceDetail(
    BuildContext context, {
    required String serviceId,
    required String title,
    required IconData icon,
    required Color color,
    required Color bgColor,
  }) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AgriServiceDetailScreen(
          serviceId: serviceId,
          title: title,
          icon: icon,
          themeColor: color,
          bgColor: bgColor,
          firestoreService: firestoreService,
        ),
      ),
    );
  }

  void _showDiseaseScannerSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFCE4EC),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: const Icon(
                    Icons.document_scanner_rounded,
                    color: Color(0xFFD81B60),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ছবি দিয়ে রোগ শনাক্তকরণ',
                        style: TextStyle(
                          fontSize: 16.5,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'আক্রান্ত পাতার স্পষ্ট ছবি তুলে দ্রুত নির্ভুল সমাধান জানুন',
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
            _buildScannerOption(
              context,
              icon: Icons.camera_alt_rounded,
              color: const Color(0xFF2E7D32),
              bgColor: const Color(0xFFE8F5E9),
              title: 'ক্যামেরা দিয়ে ছবি তুলুন',
              subtitle: 'আক্রান্ত গাছের পাতা ও কাণ্ডের সরাসরি ছবি তুলুন',
              onTap: () {
                Navigator.pop(ctx);
                _showScanProcessingDialog(context);
              },
            ),
            const SizedBox(height: 10),
            _buildScannerOption(
              context,
              icon: Icons.photo_library_rounded,
              color: const Color(0xFF0288D1),
              bgColor: const Color(0xFFE1F5FE),
              title: 'গ্যালারি থেকে ছবি আপলোড করুন',
              subtitle: 'আগে তুলে রাখা ছবি নির্বাচন করে তাৎক্ষণিক রোগ জানুন',
              onTap: () {
                Navigator.pop(ctx);
                _showScanProcessingDialog(context);
              },
            ),
            const SizedBox(height: 10),
            _buildScannerOption(
              context,
              icon: Icons.pest_control_rounded,
              color: const Color(0xFF7B1FA2),
              bgColor: const Color(0xFFF3E5F5),
              title: 'রোগবালাই ক্যাটালগ ও দমন নির্দেশিকা',
              subtitle: 'সকল ফসলের পরিচিত রোগ, লক্ষণ ও অনুমোদিত সমাধান দেখুন',
              onTap: () {
                Navigator.pop(ctx);
                onOpenPestCatalog();
              },
            ),
            const SizedBox(height: 14),
          ],
        ),
      ),
    );
  }

  Widget _buildScannerOption(
    BuildContext context, {
    required IconData icon,
    required Color color,
    required Color bgColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAF7),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE0E8E1)),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }

  void _showScanProcessingDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: const EdgeInsets.all(20),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: const Color(0xFFFCE4EC),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFF8BBD0), width: 1.5),
              ),
              child: const Icon(
                Icons.check_circle_rounded,
                color: Color(0xFFD81B60),
                size: 30,
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'নমুনা স্ক্যান সম্পন্ন!',
              style: TextStyle(
                fontSize: 16.5,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'পাতায় আগাম ব্লাইট ও দাগের লক্ষণ শনাক্ত হয়েছে। অনুমোদিত কীটনাশক ও জৈব প্রতিকার দেখতে ক্যাটালগ খুলুন।',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12.5,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 11),
                    ),
                    child: const Text('বন্ধ করুন', style: TextStyle(fontSize: 13)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      onOpenPestCatalog();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFD81B60),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 11),
                      elevation: 0,
                    ),
                    child: const Text('প্রতিকার দেখুন', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // হোম পেজের সমস্ত সেবা — শতভাগ একীভূত ইউনিফাইড তালিকা
    final List<QuickActionItem> items = [
      // ১. চাষ ক্যালেন্ডার
      QuickActionItem(
        id: 'crop_calendar',
        title: 'চাষ ক্যালেন্ডার',
        icon: Icons.calendar_month_rounded,
        color: const Color(0xFF7B1FA2),
        bgColor: const Color(0xFFF3E5F5),
        onTap: () => _openServiceDetail(
          context,
          serviceId: 'calendar',
          title: 'চাষ ক্যালেন্ডার',
          icon: Icons.calendar_month_rounded,
          color: const Color(0xFF7B1FA2),
          bgColor: const Color(0xFFF3E5F5),
        ),
      ),
      // ২. রোগ শনাক্ত
      QuickActionItem(
        id: 'disease_scanner',
        title: 'রোগ শনাক্ত',
        icon: Icons.document_scanner_rounded,
        color: const Color(0xFFD81B60),
        bgColor: const Color(0xFFFCE4EC),
        onTap: () => _showDiseaseScannerSheet(context),
      ),
      // ৩. কৃষি বিশেষজ্ঞ
      QuickActionItem(
        id: 'agri_expert',
        title: 'কৃষি বিশেষজ্ঞ',
        icon: Icons.support_agent_rounded,
        color: const Color(0xFF00897B),
        bgColor: const Color(0xFFE0F2F1),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ExpertHelplineScreen()),
          );
        },
      ),
      // ৪. কৃষি রিমাইন্ডার
      QuickActionItem(
        id: 'agri_reminder',
        title: 'কৃষি রিমাইন্ডার',
        icon: Icons.alarm_on_rounded,
        color: const Color(0xFFE65100),
        bgColor: const Color(0xFFFFF3E0),
        onTap: () => _openServiceDetail(
          context,
          serviceId: 'agri_reminder',
          title: 'কৃষি রিমাইন্ডার',
          icon: Icons.alarm_on_rounded,
          color: const Color(0xFFE65100),
          bgColor: const Color(0xFFFFF3E0),
        ),
      ),
      // ৫. বীজের তথ্য
      QuickActionItem(
        id: 'seed_bank',
        title: 'বীজের তথ্য',
        icon: Icons.spa_rounded,
        color: const Color(0xFF2E7D32),
        bgColor: const Color(0xFFE8F5E9),
        onTap: () => _openServiceDetail(
          context,
          serviceId: 'seed_bank',
          title: 'বীজের তথ্য',
          icon: Icons.spa_rounded,
          color: const Color(0xFF2E7D32),
          bgColor: const Color(0xFFE8F5E9),
        ),
      ),
      // ৬. কৃষি অফিস
      QuickActionItem(
        id: 'agri_office',
        title: 'কৃষি অফিস',
        icon: Icons.location_city_rounded,
        color: const Color(0xFF1565C0),
        bgColor: const Color(0xFFE3F2FD),
        onTap: () => _openServiceDetail(
          context,
          serviceId: 'agri_office',
          title: 'কৃষি অফিস',
          icon: Icons.location_city_rounded,
          color: const Color(0xFF1565C0),
          bgColor: const Color(0xFFE3F2FD),
        ),
      ),
      // ৭. সেচ ট্র্যাকার
      QuickActionItem(
        id: 'irrigation',
        title: AppStrings.serviceSmartIrrigation,
        icon: Icons.water_drop_outlined,
        color: const Color(0xFF0288D1),
        bgColor: const Color(0xFFE1F5FE),
        onTap: () => _openServiceDetail(
          context,
          serviceId: 'irrigation',
          title: AppStrings.serviceSmartIrrigation,
          icon: Icons.water_drop_outlined,
          color: const Color(0xFF0288D1),
          bgColor: const Color(0xFFE1F5FE),
        ),
      ),
      // ৮. সার-বীজ ডিলার
      QuickActionItem(
        id: 'dealers',
        title: AppStrings.serviceInputDealers,
        icon: Icons.storefront_outlined,
        color: const Color(0xFF2E7D32),
        bgColor: const Color(0xFFE8F5E9),
        onTap: () => _openServiceDetail(
          context,
          serviceId: 'dealers',
          title: AppStrings.serviceInputDealers,
          icon: Icons.storefront_outlined,
          color: const Color(0xFF2E7D32),
          bgColor: const Color(0xFFE8F5E9),
        ),
      ),
      // ৯. কৃষি আয়-ব্যয়
      QuickActionItem(
        id: 'ledger',
        title: AppStrings.serviceFarmLedger,
        icon: Icons.menu_book_outlined,
        color: const Color(0xFF00897B),
        bgColor: const Color(0xFFE0F2F1),
        onTap: () => _openServiceDetail(
          context,
          serviceId: 'ledger',
          title: AppStrings.serviceFarmLedger,
          icon: Icons.menu_book_outlined,
          color: const Color(0xFF00897B),
          bgColor: const Color(0xFFE0F2F1),
        ),
      ),
      // ১০. মাটির স্বাস্থ্য
      QuickActionItem(
        id: 'soil',
        title: AppStrings.serviceSoilHealth,
        icon: Icons.terrain_outlined,
        color: const Color(0xFF6D4C41),
        bgColor: const Color(0xFFEFEBE9),
        onTap: () => _openServiceDetail(
          context,
          serviceId: 'soil',
          title: AppStrings.serviceSoilHealth,
          icon: Icons.terrain_outlined,
          color: const Color(0xFF6D4C41),
          bgColor: const Color(0xFFEFEBE9),
        ),
      ),
      // ১১. পশু ও হাঁস-মুরগি
      QuickActionItem(
        id: 'livestock',
        title: AppStrings.serviceLivestock,
        icon: Icons.pets_outlined,
        color: const Color(0xFFD84315),
        bgColor: const Color(0xFFFBE9E7),
        onTap: () => _openServiceDetail(
          context,
          serviceId: 'livestock',
          title: AppStrings.serviceLivestock,
          icon: Icons.pets_outlined,
          color: const Color(0xFFD84315),
          bgColor: const Color(0xFFFBE9E7),
        ),
      ),
      // ১২. মৎস্য চাষ
      QuickActionItem(
        id: 'fisheries',
        title: AppStrings.serviceFisheries,
        icon: Icons.set_meal_outlined,
        color: const Color(0xFF0097A7),
        bgColor: const Color(0xFFE0F7FA),
        onTap: () => _openServiceDetail(
          context,
          serviceId: 'fisheries',
          title: AppStrings.serviceFisheries,
          icon: Icons.set_meal_outlined,
          color: const Color(0xFF0097A7),
          bgColor: const Color(0xFFE0F7FA),
        ),
      ),
      // ১৩. ফসল সংরক্ষণ
      QuickActionItem(
        id: 'cold_storage',
        title: AppStrings.serviceColdStorage,
        icon: Icons.inventory_2_outlined,
        color: const Color(0xFF5D4037),
        bgColor: const Color(0xFFD7CCC8),
        onTap: () => _openServiceDetail(
          context,
          serviceId: 'cold_storage',
          title: AppStrings.serviceColdStorage,
          icon: Icons.inventory_2_outlined,
          color: const Color(0xFF5D4037),
          bgColor: const Color(0xFFD7CCC8),
        ),
      ),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // একক ইউনিফাইড সার্ভিস হেডার
          Row(
            children: [
              const Icon(Icons.apps_rounded, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              const Text(
                'প্রয়োজনীয় কৃষি সেবা',
                style: TextStyle(
                  fontSize: 16.5,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${BanglaNumberConverter.toBangla(items.length.toString())}টি সেবা',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // ১০০% একীভূত কম্প্যাক্ট ইউনিফাইড গ্রিড (৩ বা ৪ কলাম)
          LayoutBuilder(
            builder: (context, constraints) {
              final crossAxisCount = constraints.maxWidth > 550 ? 4 : 3;

              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: items.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 0.96,
                ),
                itemBuilder: (context, index) {
                  final item = items[index];
                  return _buildUnifiedServiceCard(context, item);
                },
              );
            },
          ),
        ],
      ),
    );
  }

  // শতভাগ ইউনিফাইড কম্প্যাক্ট সার্ভিস কার্ড
  Widget _buildUnifiedServiceCard(BuildContext context, QuickActionItem item) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: item.onTap,
        borderRadius: BorderRadius.circular(16),
        splashColor: item.color.withOpacity(0.12),
        highlightColor: item.color.withOpacity(0.06),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 4.0),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.92),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withOpacity(0.95),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF2979FF).withOpacity(0.04),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
              const BoxShadow(
                color: Color(0x06000000),
                blurRadius: 4,
                offset: Offset(0, 1),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: item.bgColor,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Icon(item.icon, color: item.color, size: 24),
                ),
              ),
              const SizedBox(height: 7),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3.0),
                child: Text(
                  item.title,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11.8,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    height: 1.22,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
