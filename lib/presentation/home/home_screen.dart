import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
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
import '../../services/smart_popup_manager.dart';

class HomeScreen extends StatefulWidget {
  final Function(int tabIndex) onNavigateTab;
  final FirestoreService firestoreService;

  const HomeScreen({
    super.key,
    required this.onNavigateTab,
    required this.firestoreService,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  String? _lastEvaluatedNotificationId;
  Map<String, dynamic>? _lastPopupData;
  late final Stream<DocumentSnapshot<Map<String, dynamic>>> _popupStream;
  late final Stream<List<NotificationModel>> _notificationStream;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _notificationStream = widget.firestoreService.getNotificationsStream(limit: 30);
    // Read Optimization: Initialize stream once in initState
    _popupStream = FirebaseFirestore.instance
        .collection('admin_settings')
        .doc('popup_notification')
        .snapshots();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // ব্যাকগ্রাউন্ড থেকে অ্যাপে ফিরলে চেক করে পপআপ ট্রাই করা (স্মার্ট ম্যানেজার ডুপ্লিকেট ও লিমিট নিয়ন্ত্রণ করবে)
      if (!SmartPopupManager.instance.isPopupCurrentlyOpen && _lastPopupData != null) {
        _evaluateAndShowPopup(_lastPopupData!);
      }
    }
  }

  /// স্মার্ট পপআপ যাচাই ও প্রদর্শন নিয়ন্ত্রণ
  void _evaluateAndShowPopup(Map<String, dynamic> data) async {
    if (SmartPopupManager.instance.isPopupCurrentlyOpen || !mounted) return;

    final bool isActive = data['isActive'] == true;
    final String imageUrl = (data['imageUrl'] as String?)?.trim() ?? '';
    final String headline = (data['headline'] as String?)?.trim() ?? '';

    // ১) isActive == true কিনা চেক
    if (!isActive) return;

    // ২) imageUrl ফাঁকা নয় কিনা চেক
    if (imageUrl.isEmpty) return;

    // ৩) নিরাপদ এক্সপায়ারি ডেট চেক (Safe Expiry Parsing):
    DateTime? expiryDate;
    final dynamic rawExpiresAt = data['expiresAt'];
    if (rawExpiresAt is Timestamp) {
      expiryDate = rawExpiresAt.toDate();
    } else if (rawExpiresAt is String && rawExpiresAt.trim().isNotEmpty) {
      expiryDate = DateTime.tryParse(rawExpiresAt.trim());
    }

    if (expiryDate != null && DateTime.now().isAfter(expiryDate)) {
      // নির্ধারিত তারিখ পার হয়ে গেছে (Auto-Expired) -> পপআপ সম্পূর্ণ হাইড থাকবে
      return;
    }

    // ৪) স্মার্ট পপআপ ম্যানেজার দ্বারা আইডি ও আপডেট নোটিফিকেশন শনাক্তকরণ
    final String notificationId = SmartPopupManager.extractNotificationId(data);
    final bool isUpdate = SmartPopupManager.checkIsUpdate(data);

    // ৫) স্লট অধিগ্রহণ (দৈনিক সর্বোচ্চ ৫ বার, আপডেট বাইপাস ও ডুপ্লিকেট রোধ)
    final bool slotAcquired = await SmartPopupManager.instance.tryAcquirePopupSlot(
      notificationId: notificationId,
      isUpdate: isUpdate,
    );

    if (!slotAcquired || !mounted) return;

    // ৬) দ্রুততম ইনস্ট্যান্ট লোডিং নিশ্চিত করতে ব্যাকগ্রাউন্ডে প্রি-ক্যাশ (Precache with timeout fallback)
    try {
      await precacheImage(
        CachedNetworkImageProvider(imageUrl),
        context,
      ).timeout(const Duration(seconds: 2), onTimeout: () {});
    } catch (_) {
      // নেট স্লো হলেও ডায়ালগ ওপেন আটকে থাকবে না
    }

    if (!mounted) {
      SmartPopupManager.instance.releasePopupSlot(notificationId);
      return;
    }

    // কোনো বাড়তি ডিলে ছাড়া ফ্রেম রেন্ডার হলে ডায়ালগ প্রদর্শন
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _showStartupNotificationDialog(
          imageUrl: imageUrl,
          headline: headline,
          notificationId: notificationId,
        );
      } else {
        SmartPopupManager.instance.releasePopupSlot(notificationId);
      }
    });
  }

  /// গ্লোবাল স্টার্টআপ পপআপ মডাল ডায়ালগ (ইমেজ + হেডলাইন সমন্বিত কার্ড)
  void _showStartupNotificationDialog({
    required String imageUrl,
    required String headline,
    required String notificationId,
  }) {
    showDialog(
      context: context,
      useRootNavigator: true,
      barrierDismissible: true,
      barrierColor: Colors.black.withOpacity(0.85),
      builder: (BuildContext dialogContext) {
        final double dialogWidth = MediaQuery.of(dialogContext).size.width * 0.85;

        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Dialog(
            backgroundColor: Colors.transparent,
            elevation: 0,
            insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            child: Center(
              child: Container(
                width: dialogWidth,
                color: Colors.transparent,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // সমন্বিত সাদা কার্ড (বর্ডার রেডিয়াস ১৬.০)
                    Container(
                      width: dialogWidth,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16.0),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.35),
                            blurRadius: 25,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // ১. ইমেজ (উপরে রাউন্ডেড ১৬.০, আল্ট্রা-ফাস্ট ক্যাশ ও শিমার প্লেসহোল্ডার)
                          if (imageUrl.isNotEmpty)
                            ClipRRect(
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(16.0)),
                              child: CachedNetworkImage(
                                imageUrl: imageUrl,
                                width: dialogWidth,
                                memCacheWidth: 800,
                                fadeInDuration: const Duration(milliseconds: 100),
                                fit: BoxFit.contain,
                                placeholder: (context, url) => Container(
                                  height: 220,
                                  width: double.infinity,
                                  color: const Color(0xFFF1F5F9),
                                  child: const Center(
                                    child: SizedBox(
                                      height: 36,
                                      width: 36,
                                      child: CircularProgressIndicator(
                                        color: AppColors.primary,
                                        strokeWidth: 2.5,
                                      ),
                                    ),
                                  ),
                                ),
                                errorWidget: (context, url, error) => Container(
                                  height: 200,
                                  width: double.infinity,
                                  color: const Color(0xFFF8FAFC),
                                  padding: const EdgeInsets.all(20),
                                  child: const Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.broken_image_rounded, size: 48, color: Colors.grey),
                                      SizedBox(height: 8),
                                      Text(
                                        'ছবিটি লোড করা সম্ভব হয়নি',
                                        style: TextStyle(color: Colors.grey, fontSize: 13),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),

                          // ২. হেডলাইন (ইমেজের ঠিক নিচে bold ১৮ ফন্ট সাইজ এবং মাঝে সেন্টারড)
                          if (headline.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
                              child: Text(
                                headline,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1E293B),
                                  height: 1.35,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),

                    // ক্রস (X) ক্লোজ বাটন - ঠিক কার্ডের উপরের ডান কোনায়
                    Positioned(
                      top: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: () => Navigator.of(dialogContext, rootNavigator: true).pop(),
                        child: Container(
                          margin: const EdgeInsets.all(8),
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.25),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.close_rounded,
                            color: Color(0xFFD32F2F), // স্পষ্ট লাল রঙ
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    ).whenComplete(() {
      SmartPopupManager.instance.releasePopupSlot(notificationId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF7),
      body: Stack(
        children: [
          // রিয়েল-টাইম স্মার্ট পপআপ স্ট্রিম লিসেনার (কোনো বাড়তি রিড ছাড়া ক্যাশড স্ট্রিম)
          StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
            stream: _popupStream,
            builder: (context, snapshot) {
              if (snapshot.hasData && snapshot.data != null && snapshot.data!.exists) {
                final data = snapshot.data!.data();
                if (data != null) {
                  final String currentId = SmartPopupManager.extractNotificationId(data);
                  if (_lastEvaluatedNotificationId != currentId) {
                    _lastEvaluatedNotificationId = currentId;
                    _lastPopupData = data;
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted) {
                        _evaluateAndShowPopup(data);
                      }
                    });
                  }
                }
              }
              return const SizedBox.shrink();
            },
          ),

          // ইথারিয়াল গ্লাস স্ফিয়ার ও ভাইব্রেন্ট অ্যাকসেন্ট অর্বস ব্যাকগ্রাউন্ড
          Positioned.fill(
            child: IgnorePointer(
              child: _buildEtherealBackgroundOrbs(context),
            ),
          ),

          // প্রধান স্ক্রোল ভিউ (SliverAppBar & FlexibleSpaceBar) - ৩. স্ক্রলবার সম্পূর্ণ হাইড (ScrollConfiguration)
          ScrollConfiguration(
            behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                // ৪. স্মুথ স্ক্রলিং ও ফেড-আউট ইফেক্ট (SliverAppBar & FlexibleSpaceBar with Dynamic Opacity & Parallax)
                SliverAppBar(
                  expandedHeight: 350.0,
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
                        // স্ক্রল পজিশনের সাথে টপবার ও ওয়েদার কার্ড একসাথে ডাইনামিক্যালি ফেড-আউট হবে
                        final double progress = ((constraints.maxHeight - 50.0) / (350.0 - 50.0)).clamp(0.0, 1.0);
                        return Opacity(
                          opacity: progress,
                          child: SingleChildScrollView(
                            physics: const NeverScrollableScrollPhysics(),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // ১ ও ২. ডেডিকেটেড টপবার রো (লোগো, ডাইনামিক গ্রিটিং, নোটিফিকেশন আইকন)
                                SafeArea(
                                  bottom: false,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                    color: const Color(0xFFF8FAF7), // ওয়েদার সেকশন ও কার্ডের ব্যাকগ্রাউন্ড কালার
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      crossAxisAlignment: CrossAxisAlignment.center,
                                      children: [
                                        // বাম দিকে: অ্যাপের লোগো (PNG)
                                        _buildAppLogo(),

                                        // মাঝখানে: ডাইনামিক গ্রিটিং টেক্সট ("শুভ সকাল/অপরাহ্ণ/বিকেল/রাত")
                                        _buildDynamicGreetingBadge(),

                                        // ডান দিকে: নোটিফিকেশন আইকন (Notification Bell with unread badge)
                                        _buildNotificationButton(context),
                                      ],
                                    ),
                                  ),
                                ),

                                const SizedBox(height: 2),

                                // ৩. নিচের ওয়েদার অ্যানিমেশন ও কার্ড সেকশন (একই সাথে স্মুথলি ফেড-আউট হবে)
                                const WeatherCardWidget(),
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
                    EmergencyAlertBanner(firestoreService: widget.firestoreService),

                    // Quick Action Services Grid (12 Essential Unique Services)
                    QuickActionGrid(
                      onNavigateTab: widget.onNavigateTab,
                      firestoreService: widget.firestoreService,
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

  /// হেডারের বাম পাশের অ্যাপের লোগো (PNG)
  Widget _buildAppLogo() {
    return Image.asset(
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
    );
  }

  /// হেডারের মাঝের ডাইনামিক গ্রিটিং টেক্সট ("শুভ সকাল/অপরাহ্ণ/বিকেল/রাত")
  Widget _buildDynamicGreetingBadge() {
    final hour = DateTime.now().hour;
    String greeting;
    IconData icon;
    if (hour >= 6 && hour < 12) {
      greeting = 'শুভ সকাল';
      icon = Icons.wb_sunny_rounded;
    } else if (hour >= 12 && hour < 16) {
      greeting = 'শুভ অপরাহ্ণ';
      icon = Icons.light_mode_rounded;
    } else if (hour >= 16 && hour < 18) {
      greeting = 'শুভ বিকেল';
      icon = Icons.wb_twilight_rounded;
    } else if (hour >= 18 && hour < 20) {
      greeting = 'শুভ সন্ধ্যা';
      icon = Icons.nights_stay_rounded;
    } else {
      greeting = 'শুভ রাত্রি';
      icon = Icons.bedtime_rounded;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFC8E6C9),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1B5E20).withOpacity(0.06),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: const Color(0xFF2E7D32),
          ),
          const SizedBox(width: 5),
          Text(
            greeting,
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1B5E20),
            ),
          ),
        ],
      ),
    );
  }

  /// হেডারের ডান পাশের নোটিফিকেশন আইকন উইথ আনরিড কাউন্ট ব্যাজ
  Widget _buildNotificationButton(BuildContext context) {
    return StreamBuilder<List<NotificationModel>>(
      stream: _notificationStream,
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
                    firestoreService: widget.firestoreService,
                  ),
                ),
              );
            },
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFE2E8F0), width: 1.0),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
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
    );
  }
}
