import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants/app_colors.dart';
import '../../data/services/firebase_service.dart';
import '../../providers/auth_provider.dart';
import '../profile/user_profile_screen.dart';
import '../support/expert_helpline_screen.dart';
import '../crops/pest_catalog_screen.dart';
import '../notifications/notifications_screen.dart';
import 'settings_screen.dart';
import 'privacy_policy_screen.dart';

class AppMenuScreen extends StatelessWidget {
  const AppMenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;

    return Scaffold(
      backgroundColor: const Color(0xFFF7FAF7),
      // No topbar in Menu screen as requested
      appBar: null,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ================= REDESIGNED LARGE PROFILE CARD =================
              _buildLargeProfileCard(context, user),

              const SizedBox(height: 22),

              // ================= CATEGORY 1: ব্যবহারকারী ও অ্যাকাউন্ট =================
              _buildCategoryHeader('ব্যবহারকারী ও অ্যাকাউন্ট'),
              _buildCardWrapper(
                children: [
                  _buildMenuItem(
                    context: context,
                    icon: Icons.person_outline,
                    iconColor: const Color(0xFF2E7D32),
                    iconBgColor: const Color(0xFFE8F5E9),
                    title: 'প্রোফাইল (Profile)',
                    subtitle: 'আপনার তথ্য ও জেলা নির্বাচন',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const UserProfileScreen()),
                      );
                    },
                  ),
                ],
              ),

              const SizedBox(height: 18),

              // ================= CATEGORY: কৃষি সেবা ও নোটিফিকেশন =================
              _buildCategoryHeader('কৃষি সেবা ও নোটিফিকেশন'),
              _buildCardWrapper(
                children: [
                  _buildMenuItem(
                    context: context,
                    icon: Icons.bug_report_outlined,
                    iconColor: const Color(0xFFC2185B),
                    iconBgColor: const Color(0xFFFCE4EC),
                    title: 'রোগবালাই দমন (Pests & Diseases)',
                    subtitle: 'ফসলের রোগ ও পোকা দমন নির্দেশিকা',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const PestCatalogScreen()),
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
                    icon: Icons.notifications_none_rounded,
                    iconColor: const Color(0xFF2E7D32),
                    iconBgColor: const Color(0xFFE8F5E9),
                    title: 'নোটিফিকেশন (Notifications)',
                    subtitle: 'জরুরি বার্তা ও সতর্কতা',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const NotificationsScreen()),
                      );
                    },
                  ),
                ],
              ),

              const SizedBox(height: 18),

              // ================= CATEGORY 2: পছন্দ ও সেটিংস =================
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

              const SizedBox(height: 18),

              // ================= CATEGORY 3: সহায়তা ও নিয়মাবলী =================
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

              const SizedBox(height: 32),

              // ================= APP BRANDING FOOTER =================
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
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
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
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Left Circular Icon
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: iconBgColor,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Icon(icon, color: iconColor, size: 22),
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
                    const SizedBox(height: 3),
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
                Icons.arrow_forward_ios,
                color: Color(0xFFB0BEC5),
                size: 14,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Large, Centered Profile Header Card with Firestore StreamBuilder
  Widget _buildLargeProfileCard(BuildContext context, dynamic user) {
    if (FirebaseService.isFirebaseInitialized && user != null && user.userId.isNotEmpty == true) {
      return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance.collection('users').doc(user.userId).snapshots(),
        builder: (context, snapshot) {
          String name = user.name;
          String district = user.district;
          String upazila = user.upazila;
          String phone = user.phone;

          if (snapshot.hasData && snapshot.data?.exists == true) {
            final data = snapshot.data!.data();
            if (data != null) {
              name = data['name'] ?? name;
              district = data['district'] ?? district;
              upazila = data['upazila'] ?? upazila;
              phone = data['phone'] ?? phone;
            }
          }

          return _buildProfileCardContent(
            context: context,
            name: name.isNotEmpty ? name : 'মো: আব্দুল করিম',
            district: district.isNotEmpty ? district : 'বগুড়া',
            upazila: upazila.isNotEmpty ? upazila : 'শেরপুর',
            phone: phone.isNotEmpty ? phone : '০১৭১১-২২৩৩৪৪',
          );
        },
      );
    }

    return _buildProfileCardContent(
      context: context,
      name: user?.name.isNotEmpty == true ? user!.name : 'মো: আব্দুল করিম',
      district: user?.district.isNotEmpty == true ? user!.district : 'বগুড়া',
      upazila: user?.upazila.isNotEmpty == true ? user!.upazila : 'শেরপুর',
      phone: user?.phone.isNotEmpty == true ? user!.phone : '০১৭১১-২২৩৩৪৪',
    );
  }

  Widget _buildProfileCardContent({
    required BuildContext context,
    required String name,
    required String district,
    required String upazila,
    required String phone,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8E2), width: 1.0),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0C000000),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Centered Avatar Badge
          Stack(
            alignment: Alignment.bottomRight,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primaryContainer,
                  border: Border.all(color: AppColors.primaryLight, width: 2.5),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.12),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    name.isNotEmpty ? name.substring(0, 1) : 'ক',
                    style: const TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryDark,
                    ),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(5),
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.verified,
                  color: Colors.white,
                  size: 14,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // User Name
          Text(
            name,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),

          const SizedBox(height: 4),

          // District & Upazila + Phone
          Text(
            '$district, $upazila • $phone',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),

          const SizedBox(height: 14),

          // 'প্রোফাইল সম্পাদনা' (Edit Profile) Badge / Button
          InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const UserProfileScreen()),
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F8E9),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFC8E6C9), width: 1),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.edit_outlined,
                    size: 15,
                    color: AppColors.primaryDark,
                  ),
                  SizedBox(width: 6),
                  Text(
                    'প্রোফাইল সম্পাদনা',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryDark,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
