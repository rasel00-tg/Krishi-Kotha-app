import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/bangla_number_converter.dart';
import '../../data/services/firebase_service.dart';
import '../../providers/auth_provider.dart';
import '../auth/phone_login_screen.dart';
import '../navigation/main_navigation_screen.dart';
import '../profile/user_profile_screen.dart';
import '../profile/edit_profile_screen.dart';
import '../support/expert_helpline_screen.dart';
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
          body: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ================= 1. PINNED / FIXED NON-SCROLLING PROFILE CARD =================
                Padding(
                  padding: const EdgeInsets.fromLTRB(16.0, 18.0, 16.0, 12.0),
                  child: _buildLargeProfileCard(context, user, activeUid),
                ),

                // ================= 2. SCROLLABLE MENU LIST =================
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    // Generous bottom padding to ensure smooth scroll above fixed bottom navbar
                    padding: const EdgeInsets.fromLTRB(16.0, 4.0, 16.0, kBottomNavigationBarHeight + 40.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // [প্রোফাইল ট্যাব ও নোটিফিকেশন অপশন মেনু লিস্ট থেকে অপসারিত]

                        // CATEGORY 1: পছন্দ ও সেটিংস
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
                                Navigator.push(
                                  context,
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
                              iconColor: const Color(0xFF7B1FA2),
                              iconBgColor: const Color(0xFFF3E5F5),
                              title: 'সাপোর্ট ও যোগাযোগ (Support & Contact)',
                              subtitle: 'কৃষি হেল্পলাইন ও সহায়তা',
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => const ExpertHelplineScreen()),
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

  /// Large, Vibrant Emerald Glassmorphic Profile Card with Firestore StreamBuilder
  Widget _buildLargeProfileCard(BuildContext context, dynamic user, [String? activeUid]) {
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

          return _buildProfileCardContent(
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

    return _buildProfileCardContent(
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

  Widget _buildProfileCardContent({
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

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF0F4316),
            Color(0xFF1B5E20),
            Color(0xFF2E7D32),
            Color(0xFF388E3C),
          ],
          stops: [0.0, 0.35, 0.75, 1.0],
        ),
        border: Border.all(color: Colors.white.withOpacity(0.24), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1B5E20).withOpacity(0.38),
            blurRadius: 20,
            offset: const Offset(0, 9),
            spreadRadius: -1,
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            // Ambient Decorative Glass Circles for Modern Depth
            Positioned(
              top: -30,
              right: -30,
              child: Container(
                width: 130,
                height: 130,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.08),
                ),
              ),
            ),
            Positioned(
              bottom: -45,
              left: -20,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF81C784).withOpacity(0.09),
                ),
              ),
            ),

            // Card Content (Spacious, prominent and balanced)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Prominent Avatar with Bright Glowing Ring & Soft Shadow
                  Container(
                    width: 74,
                    height: 74,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xFFE8F5E9),
                          Color(0xFFA5D6A7),
                          Color(0xFF69F0AE),
                          Color(0xFF00E676),
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF69F0AE).withOpacity(0.42),
                          blurRadius: 14,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(3.0),
                    child: Container(
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                      ),
                      padding: const EdgeInsets.all(2.0),
                      child: ClipOval(
                        child: (photoUrl != null && photoUrl.trim().isNotEmpty)
                            ? CachedNetworkImage(
                                imageUrl: photoUrl.trim(),
                                fit: BoxFit.cover,
                                placeholder: (_, __) => Container(
                                  color: const Color(0xFFE8F5E9),
                                  child: const Center(
                                    child: SizedBox(
                                      width: 20,
                                      height: 20,
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

                  const SizedBox(width: 16),

                  // Center Info Column (Name, Location, Mobile Number)
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // User Name (Large, bold and clear)
                        Text(
                          name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 19.5,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 0.2,
                            height: 1.2,
                          ),
                        ),

                        const SizedBox(height: 5),

                        // District / Location
                        if (locationText.isNotEmpty) ...[
                          Row(
                            children: [
                              const Icon(Icons.location_on_rounded, size: 13.5, color: Color(0xFFB9F6CA)),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  locationText,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 12.8,
                                    color: Colors.white.withOpacity(0.92),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 3),
                        ],

                        // Mobile Number
                        if (formattedPhone.isNotEmpty) ...[
                          Row(
                            children: [
                              const Icon(Icons.phone_rounded, size: 12.5, color: Color(0xFFB9F6CA)),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  formattedPhone,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 12.8,
                                    color: Colors.white.withOpacity(0.92),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ] else if (email.isNotEmpty) ...[
                          Text(
                            email,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white.withOpacity(0.85),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(width: 10),

                  // Sleek "প্রোফাইল এডিট" Button (Navigates to Full-Screen Edit Page)
                  Material(
                    color: Colors.white.withOpacity(0.20),
                    borderRadius: BorderRadius.circular(16),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () {
                        Navigator.of(context, rootNavigator: true).push(
                          MaterialPageRoute(builder: (_) => const EditProfileScreen()),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white.withOpacity(0.38), width: 1.0),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(Icons.edit_outlined, size: 13, color: Colors.white),
                            SizedBox(width: 4),
                            Text(
                              'এডিট',
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
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

  /// ৩. লগআউট কনফার্মেশন ডায়ালগ (Confirmation Popup)
  Future<void> _showLogoutConfirmationDialog(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 10,
        backgroundColor: Colors.white,
        titlePadding: const EdgeInsets.fromLTRB(22, 22, 22, 10),
        contentPadding: const EdgeInsets.fromLTRB(22, 0, 22, 20),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: Color(0xFFFFEBEE),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.logout_rounded,
                color: Color(0xFFD32F2F),
                size: 22,
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              'লগআউট নিশ্চিতকরণ',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: Color(0xFFD32F2F),
              ),
            ),
          ],
        ),
        content: const Text(
          'আপনি কি লগআউট করতে চান?',
          style: TextStyle(
            fontSize: 14,
            color: Color(0xFF455A64),
            height: 1.4,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
            child: const Text(
              'না',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Color(0xFF78909C),
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD32F2F),
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text(
              'হ্যাঁ, লগআউট করুন',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.signOut();

      // SharedPreferences সেশন ক্লিয়ারিং
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('krishi_kotha_cached_user');
      } catch (_) {}

      if (context.mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const MainNavigationScreen(initialIndex: 4)),
          (route) => false,
        );
      }
    }
  }
}
