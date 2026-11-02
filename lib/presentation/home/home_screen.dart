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
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFF4F7FC), // আল্ট্রা-ক্লিন সফট আইস ব্লু
              Color(0xFFEBF2FA), // পিওর অফ-হোয়াইট রিফ্রেশিং টোন
            ],
          ),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // ১. ফ্লুয়িড গ্লাস স্ফিয়ার ও ভাইব্রেন্ট অ্যাকসেন্ট অর্বস (IgnorePointer ensures 0 touch obstruction)
            Positioned.fill(
              child: IgnorePointer(
                ignoring: true,
                child: _buildEtherealBackgroundOrbs(context),
              ),
            ),

            // ২. মূল কনটেন্ট লেয়ার: আবহাওয়া কার্ড শীর্ষে ফিক্সড/পিন্ড এবং নিচে মসৃণ স্ক্রল
            SafeArea(
              bottom: false,
              child: Column(
                children: [
                  // ফিক্সড / পিন্ড আবহাওয়া কার্ড (স্ক্রল করলেও শীর্ষে স্থির থাকবে)
                  const WeatherCardWidget(),

                  // নিচের স্ক্রলযোগ্য অংশ (আবহাওয়া কার্ডের নিচ দিয়ে স্ক্রল হবে)
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.only(bottom: 110), // Clearance for floating bottom nav
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
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

                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ইথারিয়াল গ্লাস স্ফিয়ার ও ভাইব্রেন্ট অ্যাকসেন্ট অর্বস আর্কিটেকচার
  Widget _buildEtherealBackgroundOrbs(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // ১. ট্রান্সলুসেন্ট ফ্রস্টেড বড় সার্কেল (টপ-রাইট কর্নার)
        Positioned(
          top: -50,
          right: -50,
          width: 280,
          height: 280,
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  const Color(0xFFBBDEFB).withOpacity(0.35),
                  const Color(0xFFD1C4E9).withOpacity(0.18),
                  Colors.transparent,
                ],
                stops: const [0.0, 0.55, 1.0],
              ),
            ),
          ),
        ),

        // ২. ট্রান্সলুসেন্ট সফট আইস ব্লু অর্ব (টপ-লেফট)
        Positioned(
          top: 80,
          left: -60,
          width: 220,
          height: 220,
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  const Color(0xFF90CAF9).withOpacity(0.28),
                  const Color(0xFFE3F2FD).withOpacity(0.12),
                  Colors.transparent,
                ],
                stops: const [0.0, 0.6, 1.0],
              ),
            ),
          ),
        ),

        // ৩. অ্যাকসেন্ট ভাইব্রেন্ট কোবাল্ট ব্লু অর্ব (স্ক্রিনের ডান পাশের মাঝামাঝি)
        Positioned(
          top: 310,
          right: -30,
          width: 135,
          height: 135,
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const RadialGradient(
                center: Alignment(-0.35, -0.35),
                radius: 0.85,
                colors: [
                  Color(0xFF82B1FF), // হাইলাইট গ্লো
                  Color(0xFF2979FF), // ভাইব্রেন্ট কোবাল্ট ব্লু
                  Color(0xFF0D47A1), // ডিপ থ্রিডি শেড
                ],
                stops: [0.0, 0.55, 1.0],
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF2979FF).withOpacity(0.42),
                  blurRadius: 42,
                  spreadRadius: 4,
                  offset: const Offset(0, 10),
                ),
                BoxShadow(
                  color: Colors.white.withOpacity(0.5),
                  blurRadius: 10,
                  spreadRadius: -2,
                  offset: const Offset(-4, -4),
                ),
              ],
            ),
          ),
        ),

        // ৪. অ্যাকসেন্ট ভাইব্রেন্ট রয়্যাল ব্লু অর্ব (বাম পাশের নিচের দিকে)
        Positioned(
          bottom: 140,
          left: -35,
          width: 125,
          height: 125,
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const RadialGradient(
                center: Alignment(-0.3, -0.3),
                radius: 0.85,
                colors: [
                  Color(0xFF90CAF9), // সফট লাইট
                  Color(0xFF3D7BF6), // ইলেকট্রিক রয়্যাল ব্লু
                  Color(0xFF1565C0), // ডিপ ব্লু
                ],
                stops: [0.0, 0.55, 1.0],
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF3D7BF6).withOpacity(0.38),
                  blurRadius: 36,
                  spreadRadius: 3,
                  offset: const Offset(0, 8),
                ),
                BoxShadow(
                  color: Colors.white.withOpacity(0.45),
                  blurRadius: 8,
                  spreadRadius: -2,
                  offset: const Offset(-3, -3),
                ),
              ],
            ),
          ),
        ),

        // ৫. সেন্টার-রাইট সফট অ্যাম্বিয়েন্ট ল্যাভেন্ডার স্ফিয়ার
        Positioned(
          top: 520,
          right: 25,
          width: 170,
          height: 170,
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  const Color(0xFFE8EAF6).withOpacity(0.30),
                  const Color(0xFFC5CAE9).withOpacity(0.12),
                  Colors.transparent,
                ],
                stops: const [0.0, 0.65, 1.0],
              ),
            ),
          ),
        ),
      ],
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
}
