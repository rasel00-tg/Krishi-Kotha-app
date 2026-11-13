import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../data/services/firestore_service.dart';
import '../../providers/auth_provider.dart';
import '../../providers/support_provider.dart';
import 'widgets/emergency_alert_banner.dart';
import 'widgets/weather_card_widget.dart';
import 'widgets/quick_action_grid.dart';
import 'crop_calendar_screen.dart';
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
      backgroundColor: const Color(0xFFF8FAF7),
      body: Stack(
        children: [
          // ইথারিয়াল গ্লাস স্ফিয়ার ও ভাইব্রেন্ট অ্যাকসেন্ট অর্বস ব্যাকগ্রাউন্ড
          Positioned.fill(
            child: IgnorePointer(
              child: _buildEtherealBackgroundOrbs(context),
            ),
          ),

          // প্রধান স্ক্রোল ভিউ (SliverAppBar & FlexibleSpaceBar)
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // ৪. স্মুথ স্ক্রলিং ও ফেড-আউট ইফেক্ট (SliverAppBar & FlexibleSpaceBar)
              SliverAppBar(
                expandedHeight: 330.0,
                collapsedHeight: 0,
                toolbarHeight: 0,
                pinned: false,
                floating: false,
                stretch: true,
                elevation: 0,
                backgroundColor: Colors.transparent,
                flexibleSpace: FlexibleSpaceBar(
                  collapseMode: CollapseMode.parallax,
                  background: LayoutBuilder(
                    builder: (context, constraints) {
                      // স্ক্রল পজিশনের সাথে অপাসিটি ডাইনামিক্যালি রিয়্যাক্ট করবে
                      final double progress = ((constraints.maxHeight - 50.0) / (330.0 - 50.0)).clamp(0.0, 1.0);
                      return Opacity(
                        opacity: progress,
                        child: SingleChildScrollView(
                          physics: const NeverScrollableScrollPhysics(),
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              // ১. অ্যানিমেশন ও আবহাওয়া ডেটা (স্ক্রিনের টপ থেকে শুরু হয়ে আকাশের ব্যাকগ্রাউন্ড ব্লেন্ড হবে)
                              Padding(
                                padding: EdgeInsets.only(
                                  top: MediaQuery.of(context).padding.top + 8,
                                ),
                                child: const WeatherCardWidget(),
                              ),

                              // ১. সিমলেস ট্রান্সপারেন্ট টপবার (সরাসরি স্ট্যাটাস বারের সাথে মিশে ভাসমান থাকবে)
                              Positioned(
                                top: 0,
                                left: 0,
                                right: 0,
                                child: SafeArea(
                                  bottom: false,
                                  child: _buildTopHeader(context),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),

            // ৫. নিচের সমস্ত ফিচার (SliverToBoxAdapter এ সুরক্ষিত)
            SliverToBoxAdapter(
              child: Padding(
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

                      // ৪. চাষ ক্যালেন্ডার সেকশন (ভিউ মোর সহ ফুল পেজ নেভিগেশন)
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 16),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFF1F8F1), Colors.white],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFC8E6C9), width: 1.2),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x06000000),
                              blurRadius: 10,
                              offset: Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(7),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF2E7D32),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Icon(Icons.calendar_month_rounded, color: Colors.white, size: 18),
                                    ),
                                    const SizedBox(width: 10),
                                    const Text(
                                      'চাষ ক্যালেন্ডার',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                  ],
                                ),
                                InkWell(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (_) => const CropCalendarScreen()),
                                    );
                                  },
                                  borderRadius: BorderRadius.circular(8),
                                  child: const Padding(
                                    padding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                                    child: Row(
                                      children: [
                                        Text(
                                          'সব দেখুন',
                                          style: TextStyle(
                                            fontSize: 12.5,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF2E7D32),
                                          ),
                                        ),
                                        SizedBox(width: 4),
                                        Icon(Icons.arrow_forward_ios_rounded, size: 12, color: Color(0xFF2E7D32)),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            const Text(
                              'মাসভিত্তিক সঠিক ফসল রোপণ, পরিচর্যা ও ফসল কাটার সম্পূর্ণ সময়সূচি দেখুন।',
                              style: TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.35),
                            ),
                            const SizedBox(height: 12),
                            InkWell(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => const CropCalendarScreen()),
                                );
                              },
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: const Color(0xFFE0EFE0)),
                                ),
                                child: const Row(
                                  children: [
                                    Icon(Icons.eco_rounded, color: Color(0xFF2E7D32), size: 18),
                                    SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        'বৈশাখ থেকে চৈত্র - ১২ মাসের পূর্ণাঙ্গ চাষ ক্যালেন্ডার খুলুন',
                                        style: TextStyle(
                                          fontSize: 12.5,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF1B5E20),
                                        ),
                                      ),
                                    ),
                                    Icon(Icons.arrow_forward_rounded, color: Color(0xFF2E7D32), size: 16),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),
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

  /// ট্রান্সপারেন্ট টপবার (সরাসরি বডিতে, আলাদা কোনো AppBar বা সাদা ব্যাকগ্রাউন্ড ছাড়া)
  Widget _buildTopHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: const BoxDecoration(
        color: Colors.transparent, // সম্পূর্ণ ট্রান্সপারেন্ট
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // হেডারের বাম পাশে অ্যাপের লোগো (রিসাইজ: height 48 এবং Transform.translate দিয়ে নিচে নামানো)
          Transform.translate(
            offset: const Offset(0, 6),
            child: Image.asset(
              'assets/icons/pnglogo.png',
              height: 48,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) => Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.08),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.eco_rounded, color: AppColors.primary, size: 28),
              ),
            ),
          ),

          // হেডারের ডান পাশে নোটিফিকেশন আইকন উইথ আনরিড কাউন্ট ব্যাজ (মানানসই অ্যালাইনমেন্ট)
          Transform.translate(
            offset: const Offset(0, 6),
            child: StreamBuilder<List<NotificationModel>>(
              stream: firestoreService.getNotificationsStream(),
              builder: (context, snapshot) {
                final notifications = snapshot.data ?? [];
                final unreadCount = notifications.where((n) => !n.isSeen).length;

                return Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => NotificationsScreen(
                            firestoreService: firestoreService,
                          ),
                        ),
                      );
                    },
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.0),
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        clipBehavior: Clip.none,
                        children: [
                          Icon(
                            unreadCount > 0
                                ? Icons.notifications_rounded
                                : Icons.notifications_none_rounded,
                            size: 22,
                            color: const Color(0xFF1E293B),
                          ),
                          if (unreadCount > 0)
                            Positioned(
                              top: 8,
                              right: 8,
                              child: Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE53935),
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 1.5),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
