import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/bangla_number_converter.dart';
import '../../core/widgets/app_unified_dialog.dart';
import '../../data/services/firebase_service.dart';
import '../../providers/auth_provider.dart';
import '../auth/phone_login_screen.dart';
import '../navigation/main_navigation_screen.dart';
import '../profile/user_profile_screen.dart';
import '../profile/edit_profile_screen.dart';
import '../support/expert_helpline_screen.dart';
import '../support/support_contact_screen.dart';
import 'settings_screen.dart';
import 'privacy_policy_screen.dart';

class AppMenuScreen extends StatelessWidget {
  const AppMenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;

    // ১. মেনু পেজের ভিউ সরাসরি FirebaseAuth.instance.authStateChanges() স্ট্রিমের সাথে যুক্ত
    return StreamBuilder<User?>(
      stream: FirebaseService.isFirebaseInitialized
          ? FirebaseAuth.instance.authStateChanges()
          : const Stream.empty(),
      builder: (context, authSnapshot) {
        final firebaseUser = authSnapshot.data;
        final bool isFirebaseLoggedIn = firebaseUser != null;
        final bool isProviderLoggedIn = authProvider.isLoggedIn;
        final bool isLoggedIn = isFirebaseLoggedIn || isProviderLoggedIn;

        // মেনু ট্যাবে কন্ডিশনাল অথ গেটওয়ে (Authentication Gateway for Menu Tab):
        // ব্যবহারকারী যদি লগইন অবস্থায় না থাকেন (Guest State):
        // মেনু পেজটি সম্পূর্ণ লক থাকবে এবং কোনো মেনু আইটেম প্রদর্শিত হবে না।
        // সরাসরি রেফারেন্স ছবির আধুনিক লগইন স্ক্রিন প্রদর্শিত হবে।
        // লগইন সফল হওয়া মাত্রই স্বয়ংক্রিয়ভাবে পূর্ণাঙ্গ মেনু পেজে প্রবেশ করবে।
        if (!isLoggedIn) {
          return const PhoneLoginScreen(isGatewayForMenu: true);
        }

        final activeUid = firebaseUser?.uid ?? user?.uid;

        return Scaffold(
          backgroundColor: const Color(0xFFF7FAF7),
          // No topbar in Menu screen as requested
          appBar: null,
          body: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            // Generous bottom padding to ensure smooth scroll above fixed bottom navbar
            padding: const EdgeInsets.only(bottom: kBottomNavigationBarHeight + 64.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ================= 1. MODERN CURVED PROFILE HEADER =================
                _buildCurvedProfileHeader(context, user, activeUid),

                // ================= 2. SCROLLABLE MENU LIST =================
                Padding(
                  padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // CATEGORY 1: ব্যবহারকারী ও একাউন্ট
                      _buildCategoryHeader('ব্যবহারকারী ও একাউন্ট'),
                      _buildCardWrapper(
                        children: [
                          _buildMenuItem(
                            context: context,
                            icon: Icons.person_outline_rounded,
                            iconColor: const Color(0xFF2E7D32),
                            iconBgColor: const Color(0xFFE8F5E9),
                            title: 'প্রোফাইল সম্পাদনা (Edit Profile)',
                            subtitle: 'নাম, ঠিকানা ও ব্যক্তিগত তথ্য আপডেট করুন',
                            onTap: () {
                              Navigator.of(context, rootNavigator: true).push(
                                MaterialPageRoute(builder: (_) => const EditProfileScreen()),
                              );
                            },
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // CATEGORY 2: পছন্দ ও সেটিংস
                      _buildCategoryHeader('পছন্দ ও সেটিংস'),
                      _buildCardWrapper(
                        children: [
                          _buildMenuItem(
                            context: context,
                            icon: Icons.settings_outlined,
                            iconColor: const Color(0xFF1565C0),
                            iconBgColor: const Color(0xFFE3F2FD),
                            title: 'সেটিংস (Settings)',
                            subtitle: 'অ্যাপ সেটিংস ও ভাষা',
                            onTap: () {
                              Navigator.of(context, rootNavigator: true).push(
                                MaterialPageRoute(builder: (_) => const SettingsScreen()),
                              );
                            },
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // CATEGORY 3: সহায়তা ও নিয়মাবলী
                      _buildCategoryHeader('সহায়তা ও নিয়মাবলী'),
                      _buildCardWrapper(
                        children: [
                          _buildMenuItem(
                            context: context,
                            icon: Icons.headset_mic_outlined,
                            iconColor: const Color(0xFF00A86B),
                            iconBgColor: const Color(0xFFE8F5E9),
                            title: 'সাপোর্ট ও যোগাযোগ (Support & Contact)',
                            subtitle: 'কৃষি হেল্পলাইন ও সহায়তা',
                            onTap: () {
                              Navigator.of(context, rootNavigator: true).push(
                                MaterialPageRoute(builder: (_) => const SupportContactScreen()),
                              );
                            },
                          ),
                          const Divider(
                            height: 1,
                            thickness: 0.8,
                            indent: 68,
                            endIndent: 16,
                            color: Color(0xFFEFF3EF),
                          ),
                          _buildMenuItem(
                            context: context,
                            icon: Icons.privacy_tip_outlined,
                            iconColor: const Color(0xFFE65100),
                            iconBgColor: const Color(0xFFFFF3E0),
                            title: 'গোপনীয় নীতি (Privacy Policy)',
                            subtitle: 'ব্যবহারের শর্ত ও নীতিমালা',
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const PrivacyPolicyScreen()),
                              );
                            },
                          ),
                        ],
                      ),

                      // CATEGORY 4: লগআউট বাটন (Sleek Logout Button - Logged in Only)
                      if (isLoggedIn) ...[
                        const SizedBox(height: 18),
                        _buildLogoutButton(context),
                      ],

                      const SizedBox(height: 28),

                        // APP BRANDING FOOTER
                        Center(
                          child: Column(
                            children: [
                              Container(
                                width: 46,
                                height: 46,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.08),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: ClipOval(
                                  child: Padding(
                                    padding: const EdgeInsets.all(3.0),
                                    child: Image.asset(
                                      'assets/icons/pnglogo.png',
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => const Icon(
                                        Icons.eco_rounded,
                                        color: AppColors.primary,
                                        size: 28,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'কৃষি কথা – Krishi Kotha',
                                style: TextStyle(
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              const Text(
                                'স্মার্ট কৃষিতে আধুনিক সমাধান • সংস্করণ ১.০.০',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
  }

  /// Category Header Text
  Widget _buildCategoryHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: AppColors.primaryDark,
          letterSpacing: 0.2,
        ),
      ),
    );
  }

  /// Rounded Card Container with light shadow & full width
  Widget _buildCardWrapper({required List<Widget> children}) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8E2), width: 0.9),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          children: children,
        ),
      ),
    );
  }

  /// Individual Full-Width Menu Item with Proper Horizontal Row Alignment
  Widget _buildMenuItem({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        splashColor: iconColor.withOpacity(0.12),
        highlightColor: iconBgColor.withOpacity(0.35),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Left Themed Icon Container
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: iconBgColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: iconColor.withOpacity(0.15), width: 1.0),
                ),
                child: Center(
                  child: Icon(icon, color: iconColor, size: 21),
                ),
              ),

              const SizedBox(width: 14),

              // Center Title & Subtitle (Takes remaining available width)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2.5),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                        height: 1.25,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              // Right Arrow Icon
              const Icon(
                Icons.arrow_forward_ios_rounded,
                color: Color(0xFFB0BEC5),
                size: 14,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Modern Curved Profile Header Card with Real-time Firestore StreamBuilder
  Widget _buildCurvedProfileHeader(BuildContext context, dynamic user, [String? activeUid]) {
    final String? uid = activeUid ?? (user != null ? (user.uid ?? user.userId) : null);
    if (FirebaseService.isFirebaseInitialized && uid != null && uid.isNotEmpty) {
      return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance.collection('users').doc(uid).snapshots(),
        builder: (context, snapshot) {
          String name = user?.name ?? 'কৃষক ভাই';
          String district = user?.district ?? '';
          String upazila = user?.upazila ?? '';
          String village = user?.village ?? '';
          String phone = user?.phone ?? '';
          String email = user?.email ?? '';
          String? photoUrl;

          if (snapshot.hasData && snapshot.data?.exists == true) {
            final data = snapshot.data!.data();
            if (data != null) {
              name = data['name'] ?? name;
              district = data['district'] ?? district;
              upazila = data['upazila'] ?? upazila;
              village = data['village'] ?? data['village_name'] ?? village;
              phone = data['phone'] ?? phone;
              email = data['email'] ?? email;
              photoUrl = data['photo_url'] ?? data['photoUrl'] ?? data['image_url'];
            }
          }

          return _buildCurvedHeaderContent(
            context: context,
            name: name.isNotEmpty ? name : 'কৃষক ভাই',
            district: district,
            upazila: upazila,
            village: village,
            phone: phone,
            email: email,
            photoUrl: photoUrl,
          );
        },
      );
    }

    return _buildCurvedHeaderContent(
      context: context,
      name: user?.name.isNotEmpty == true ? user!.name : 'কৃষক ভাই',
      district: user?.district ?? '',
      upazila: user?.upazila ?? '',
      village: user?.village ?? '',
      phone: user?.phone ?? '',
      email: user?.email ?? '',
      photoUrl: null,
    );
  }

  Widget _buildCurvedHeaderContent({
    required BuildContext context,
    required String name,
    required String district,
    required String upazila,
    required String village,
    required String phone,
    required String email,
    String? photoUrl,
  }) {
    final List<String> locParts = [];
    if (village.trim().isNotEmpty) locParts.add(village.trim());
    if (upazila.trim().isNotEmpty) locParts.add(upazila.trim());
    if (district.trim().isNotEmpty) locParts.add(district.trim());
    final locationText = locParts.join(', ');

    final formattedPhone = phone.trim().isNotEmpty ? BanglaNumberConverter.toBangla(phone.trim()) : '';
    final topPadding = MediaQuery.of(context).padding.top;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(34)),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF0B3310),
            Color(0xFF1B5E20),
            Color(0xFF2E7D32),
            Color(0xFF388E3C),
          ],
          stops: [0.0, 0.30, 0.70, 1.0],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1B5E20).withOpacity(0.35),
            blurRadius: 18,
            offset: const Offset(0, 8),
            spreadRadius: -2,
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(34)),
        child: Stack(
          children: [
            // Ambient Decorative Glass Circles for Modern Depth
            Positioned(
              top: -30,
              right: -30,
              child: Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.08),
                ),
              ),
            ),
            Positioned(
              bottom: -40,
              left: -30,
              child: Container(
                width: 130,
                height: 130,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF81C784).withOpacity(0.10),
                ),
              ),
            ),

            // Header Content (Edge-to-edge, status bar padded, centered layout, no edit icon on avatar)
            Padding(
              padding: EdgeInsets.only(top: topPadding + 22, bottom: 28, left: 20, right: 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Center Circle Avatar (Radius 45, Diameter 90) with Bright White Border (NO pen/edit icon)
                  Center(
                    child: Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3.5),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF69F0AE).withOpacity(0.40),
                            blurRadius: 18,
                            spreadRadius: 2,
                          ),
                          BoxShadow(
                            color: Colors.black.withOpacity(0.18),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: (photoUrl != null && photoUrl.trim().isNotEmpty)
                            ? CachedNetworkImage(
                                imageUrl: photoUrl.trim(),
                                fit: BoxFit.cover,
                                placeholder: (_, __) => Container(
                                  color: const Color(0xFFE8F5E9),
                                  child: const Center(
                                    child: SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                                    ),
                                  ),
                                ),
                                errorWidget: (_, __, ___) => _buildFallbackAvatar(name),
                              )
                            : _buildFallbackAvatar(name),
                      ),
                    ),
                  ),

                  const SizedBox(height: 14),

                  // User Name with Glowing Animated Verified Badge
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Flexible(
                        child: Text(
                          name,
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 21.0,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 0.3,
                            height: 1.25,
                          ),
                        ),
                      ),
                      const SizedBox(width: 7),
                      const AnimatedGlowingVerifiedBadge(),
                    ],
                  ),

                  const SizedBox(height: 10),

                  // District, Upazila & Phone Chips
                  Wrap(
                    alignment: WrapAlignment.center,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      if (locationText.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4.5),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.18),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.white.withOpacity(0.28), width: 0.8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.location_on_rounded, size: 13.5, color: Color(0xFFB9F6CA)),
                              const SizedBox(width: 4),
                              Text(
                                locationText,
                                style: const TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      if (formattedPhone.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4.5),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.18),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.white.withOpacity(0.28), width: 0.8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.phone_rounded, size: 12.5, color: Color(0xFFB9F6CA)),
                              const SizedBox(width: 4),
                              Text(
                                formattedPhone,
                                style: const TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        )
                      else if (email.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4.5),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.18),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.white.withOpacity(0.28), width: 0.8),
                          ),
                          child: Text(
                            email,
                            style: TextStyle(
                              fontSize: 12.0,
                              fontWeight: FontWeight.w500,
                              color: Colors.white.withOpacity(0.95),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFallbackAvatar(String name) {
    return Container(
      color: const Color(0xFFE8F5E9),
      child: Center(
        child: Text(
          name.trim().isNotEmpty ? name.trim().substring(0, 1) : 'ক',
          style: const TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1B5E20),
          ),
        ),
      ),
    );
  }

  /// Attractive Login/Sign-up Card for Guest Users
  Widget _buildLoginPromptCard(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primaryLight, width: 1.2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0C000000),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const PhoneLoginScreen()),
            );
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: AppColors.primaryContainer,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.primaryLight, width: 2),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.person_add_alt_1_rounded,
                      color: AppColors.primaryDark,
                      size: 30,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'লগইন বা একাউন্ট খুলুন',
                        style: TextStyle(
                          fontSize: 16.5,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      SizedBox(height: 3),
                      Text(
                        'সকল সুবিধা পেতে সাইন ইন বা নিবন্ধন করুন',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.25),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'লগইন',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(width: 4),
                      Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 11),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// ৩. স্লিক ও মার্জিত লগআউট বাটন (Sleek Logout Button)
  Widget _buildLogoutButton(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFFFF5F5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFFCDD2), width: 1.0),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08D32F2F),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _showLogoutConfirmationDialog(context),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Logout Circular Icon
                Container(
                  width: 42,
                  height: 42,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFFEBEE),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.logout_rounded,
                      color: Color(0xFFD32F2F),
                      size: 22,
                    ),
                  ),
                ),

                const SizedBox(width: 14),

                // Center Title & Subtitle
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'লগআউট (Logout)',
                        style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFD32F2F),
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'অ্যাকাউন্ট থেকে সুরক্ষিতভাবে প্রস্থান করুন',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFFE57373),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 8),

                // Right Arrow Icon
                const Icon(
                  Icons.arrow_forward_ios,
                  color: Color(0xFFEF9A9A),
                  size: 14,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// ৩. লগআউট কনফার্মেশন ও সফল লগআউট ফ্লো (Unified Confirmation & Success Flow)
  Future<void> _showLogoutConfirmationDialog(BuildContext context) async {
    final confirmed = await AppUnifiedDialog.showConfirmation(
      context,
      title: 'লগআউট নিশ্চিতকরণ',
      message: 'আপনি কি নিশ্চিতভাবে একাউন্ট থেকে লগআউট করতে চান?',
      confirmText: 'হ্যাঁ, লগআউট করুন',
      cancelText: 'না',
      icon: Icons.logout_rounded,
      confirmColor: const Color(0xFFD32F2F),
    );

    if (confirmed == true && context.mounted) {
      // ১. ব্যাকগ্রাউন্ডে নন-ব্লকিংভাবে FirebaseAuth.instance.signOut() কল
      FirebaseAuth.instance.signOut().catchError((e) {
        debugPrint('Non-blocking FirebaseAuth signOut error: $e');
      });

      // ২. তাৎক্ষণিকভাবে লোকাল স্টেট ও প্রোভাইডার সেশন ক্লিয়ার
      try {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        authProvider.signOut();
      } catch (_) {}

      // ৩. লোকাল ক্যাশ ও বায়োমেট্রিক সেশন প্রিফারেন্সেস ক্লিয়ার
      SharedPreferences.getInstance().then((prefs) {
        prefs.remove('krishi_kotha_cached_user');
        prefs.remove('krishi_kotha_biometric_user');
      }).catchError((_) {});

      // ৪. সমস্ত রুট ক্লিয়ার করে সরাসরি শূন্য বিলম্বে লগইন পেজে রিডাইরেক্ট
      Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => const PhoneLoginScreen(isGatewayForMenu: false),
        ),
        (route) => false,
      );

      // ৫. সফল লগআউটের তাৎক্ষণিক সবুজ বার্তা
      try {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                SizedBox(width: 10),
                Text(
                  'সফলভাবে লগআউট সম্পন্ন হয়েছে!',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF2E7D32),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            duration: const Duration(seconds: 2),
          ),
        );
      } catch (_) {}
    }
  }
}

/// ভেরিফাইড ব্যাজের স্বচ্ছ ব্যাকগ্রাউন্ড ও অবিরাম ঘূর্ণন এনিমেশন (Transparent & Rotating Verified Badge)
class AnimatedGlowingVerifiedBadge extends StatefulWidget {
  const AnimatedGlowingVerifiedBadge({super.key});

  @override
  State<AnimatedGlowingVerifiedBadge> createState() => _AnimatedGlowingVerifiedBadgeState();
}

class _AnimatedGlowingVerifiedBadgeState extends State<AnimatedGlowingVerifiedBadge>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    // ৬ সেকেন্ডে ৩৬০ ডিগ্রি মসৃণ ও মার্জিত অবিরাম ঘূর্ণন
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.transparent,
      width: 22,
      height: 22,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // মার্জিত অবিরাম ঘূর্ণনরত এমারেল্ড রোজেট (কোনো সাদা বর্ডার বা অস্বচ্ছ গ্লো নেই)
          RotationTransition(
            turns: _controller,
            child: const Icon(
              Icons.verified_rounded,
              color: Color(0xFF00E676),
              size: 22,
            ),
          ),
          // ক্রিস্টাল ক্লিয়ার প্রমিনেন্ট চেক আইকন যা সর্বদা সোজা ও সুস্পষ্ট থাকে
          const Icon(
            Icons.check_rounded,
            color: Colors.white,
            size: 13,
          ),
        ],
      ),
    );
  }
}
