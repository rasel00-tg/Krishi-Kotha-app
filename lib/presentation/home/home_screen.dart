import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../data/services/firestore_service.dart';
import '../../providers/auth_provider.dart';
import '../../providers/support_provider.dart';
import 'widgets/emergency_alert_banner.dart';
import 'widgets/weather_card_widget.dart';
import 'widgets/quick_action_grid.dart';
import '../crops/pest_catalog_screen.dart';
import '../support/expert_helpline_screen.dart';
import '../profile/user_profile_screen.dart';
import '../notifications/notifications_screen.dart';
import '../../data/models/notification_model.dart';

class HomeScreen extends StatelessWidget {
  final Function(int tabIndex) onNavigateTab;
  final FirestoreService firestoreService;

  const HomeScreen({
    super.key,
    required this.onNavigateTab,
    required this.firestoreService,
  });

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        toolbarHeight: 64,
        title: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Circular, Enlarged Logo Badge with CircleAvatar & ClipOval
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2.0),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 6,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: CircleAvatar(
                radius: 22, // 44px crisp diameter
                backgroundColor: Colors.white,
                child: ClipOval(
                  child: Image.asset(
                    'assets/icons/pnglogo.png',
                    width: 44,
                    height: 44,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => const Center(
                      child: Icon(Icons.eco_rounded, color: AppColors.primary, size: 26),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'কৃষি কথা – Krishi Kotha',
                    style: TextStyle(
                      fontSize: 16.5,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 0.1,
                      height: 1.2,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 2),
                  Text(
                    'কৃষকের পাশে সবসময়',
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFFE8F5E9),
                      fontWeight: FontWeight.w500,
                      height: 1.2,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          StreamBuilder<List<NotificationModel>>(
            stream: firestoreService.getNotificationsStream(),
            builder: (context, snapshot) {
              final notifications = snapshot.data ?? [];
              final unreadCount = notifications.where((n) => !n.isSeen).length;

              return IconButton(
                icon: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Icon(
                      unreadCount > 0
                          ? Icons.notifications_rounded
                          : Icons.notifications_none_rounded,
                      size: 26,
                      color: Colors.white,
                    ),
                    if (unreadCount > 0)
                      Positioned(
                        top: -2,
                        right: -2,
                        child: Container(
                          width: 10,
                          height: 10,
                          decoration: const BoxDecoration(
                            color: Color(0xFFE53935),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                  ],
                ),
                tooltip: 'বিজ্ঞপ্তি ও নোটিফিকেশন',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => NotificationsScreen(
                        firestoreService: firestoreService,
                      ),
                    ),
                  );
                },
              );
            },
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Weather Card Widget (Live + 3-Day Forecast) - Moved right to the top
              const WeatherCardWidget(),

              // Real-time Emergency Alert Banner from Firestore (if active)
              EmergencyAlertBanner(firestoreService: firestoreService),

              // Quick Action Services Grid (12 Essential Unique Services)
              QuickActionGrid(
                onNavigateTab: onNavigateTab,
                firestoreService: firestoreService,
                onOpenPestCatalog: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const PestCatalogScreen()),
                  );
                },
              ),

              // Featured Farming Tips Card
              _buildFeaturedTipCard(context),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGovtHelplineBanner(BuildContext context) {
    final supportProvider = Provider.of<SupportProvider>(context, listen: false);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: const Color(0xFFF3E5F5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFCE93D8), width: 1),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              color: Color(0xFF7B1FA2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.phone_in_talk, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  AppStrings.govtCallCenterTitle,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF4A148C),
                  ),
                ),
                const SizedBox(height: 3),
                const Text(
                  'বিনামূল্যে কৃষি কর্মকর্তার সাথে কথা বলতে ট্যাপ করুন',
                  style: TextStyle(fontSize: 12, color: Color(0xFF6A1B9A)),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () => supportProvider.callAgriCallCenter(),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF7B1FA2),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              minimumSize: const Size(60, 42),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('কল দিন', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturedTipCard(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.lightbulb_outline, color: AppColors.earthyGold, size: 22),
              SizedBox(width: 8),
              Text(
                'আজকের গুরুত্বপূর্ণ পরামর্শ',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'ধানের জমিতে ইউরিয়া সার প্রয়োগের সময় জমিতে ছিপছিপে পানি রাখুন। প্রখর রোদ বা বৃষ্টির আগে ইউরিয়া প্রয়োগ করবেন না, এতে নাইট্রোজেনের অপচয় রোধ হবে।',
            style: TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.4),
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => onNavigateTab(1),
              child: const Text(
                'আরও বিস্তারিত ফসল গাইড দেখুন →',
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
