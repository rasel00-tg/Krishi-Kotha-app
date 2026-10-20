import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../data/services/firestore_service.dart';
import '../agri_service_detail_screen.dart';

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

  @override
  Widget build(BuildContext context) {
    // 12 Essential Modern Agri Services
    final List<QuickActionItem> items = [
      // 1. রোগবালাই দমন
      QuickActionItem(
        id: 'pest_diagnosis',
        title: AppStrings.servicePestDiagnosis,
        icon: Icons.bug_report_outlined,
        color: const Color(0xFFC2185B),
        bgColor: const Color(0xFFFCE4EC),
        onTap: onOpenPestCatalog,
      ),
      // 2. সেচ ট্র্যাকার
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
      // 3. যন্ত্রপাতি ভাড়া
      QuickActionItem(
        id: 'machinery',
        title: AppStrings.serviceMachineryRental,
        icon: Icons.agriculture_outlined,
        color: const Color(0xFFE65100),
        bgColor: const Color(0xFFFFF3E0),
        onTap: () => _openServiceDetail(
          context,
          serviceId: 'machinery',
          title: AppStrings.serviceMachineryRental,
          icon: Icons.agriculture_outlined,
          color: const Color(0xFFE65100),
          bgColor: const Color(0xFFFFF3E0),
        ),
      ),
      // 4. সার-বীজ ডিলার
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
      // 5. কৃষি আয়-ব্যয়
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
      // 6. ফসল ক্যালেন্ডার
      QuickActionItem(
        id: 'calendar',
        title: AppStrings.serviceCropCalendar,
        icon: Icons.calendar_month_outlined,
        color: const Color(0xFF7B1FA2),
        bgColor: const Color(0xFFF3E5F5),
        onTap: () => _openServiceDetail(
          context,
          serviceId: 'calendar',
          title: AppStrings.serviceCropCalendar,
          icon: Icons.calendar_month_outlined,
          color: const Color(0xFF7B1FA2),
          bgColor: const Color(0xFFF3E5F5),
        ),
      ),
      // 7. মাটির স্বাস্থ্য
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
      // 8. কৃষি ঋণ ও প্রণোদনা
      QuickActionItem(
        id: 'loans',
        title: AppStrings.serviceAgriLoans,
        icon: Icons.account_balance_outlined,
        color: const Color(0xFF1565C0),
        bgColor: const Color(0xFFE3F2FD),
        onTap: () => _openServiceDetail(
          context,
          serviceId: 'loans',
          title: AppStrings.serviceAgriLoans,
          icon: Icons.account_balance_outlined,
          color: const Color(0xFF1565C0),
          bgColor: const Color(0xFFE3F2FD),
        ),
      ),
      // 9. পশু ও হাঁস-মুরগি
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
      // 10. মৎস্য চাষ
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
      // 11. ফসল সংরক্ষণ
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
      // 12. আধুনিক প্রযুক্তি
      QuickActionItem(
        id: 'modern_tech',
        title: AppStrings.serviceModernTech,
        icon: Icons.lightbulb_outline,
        color: const Color(0xFFF57F17),
        bgColor: const Color(0xFFFFFDE7),
        onTap: () => _openServiceDetail(
          context,
          serviceId: 'modern_tech',
          title: AppStrings.serviceModernTech,
          icon: Icons.lightbulb_outline,
          color: const Color(0xFFF57F17),
          bgColor: const Color(0xFFFFFDE7),
        ),
      ),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.apps_rounded, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              const Text(
                AppStrings.quickServices,
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
                child: const Text(
                  '১২টি সেবা',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
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

                  return InkWell(
                    onTap: item.onTap,
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 4.0),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFE2E8E2), width: 0.9),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x06000000),
                            blurRadius: 5,
                            offset: Offset(0, 2),
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
                          const SizedBox(height: 6),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 2.0),
                            child: Text(
                              item.title,
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                                height: 1.25,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}
