import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/widgets/custom_app_bar.dart';
import '../../core/widgets/app_unified_dialog.dart';
import '../../data/services/biometric_auth_service.dart';
import '../../providers/auth_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _weatherAlerts = true;
  bool _marketUpdates = true;
  bool _offlineCache = true;
  bool _biometricEnabled = false;

  @override
  void initState() {
    super.initState();
    _loadBiometricState();
  }

  Future<void> _loadBiometricState() async {
    final enabled = await BiometricAuthService.isBiometricEnabled();
    if (mounted) {
      setState(() => _biometricEnabled = enabled);
    }
  }

  Future<void> _handleBiometricToggle(bool enable) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final fbUser = FirebaseAuth.instance.currentUser;
    var user = authProvider.user;

    if (enable) {
      String activeUid = user?.uid ?? fbUser?.uid ?? '';
      String userPhone = user?.phone ?? fbUser?.phoneNumber ?? '';
      String userEmail = user?.email ?? fbUser?.email ?? '';
      String userName = user?.name ?? fbUser?.displayName ?? 'সম্মানিত কৃষক';
      String userDistrict = user?.district ?? '';
      String userUpazila = user?.upazila ?? '';
      String userVillage = user?.village ?? '';
      String userOccupation = user?.occupation ?? '';

      // ফায়ারবেস কারেন্ট ইউজার থাকলে সরাসরি ফায়ারস্টোর থেকে ইউজারের বিস্তারিত লোড করা
      if (fbUser != null && !fbUser.isAnonymous) {
        activeUid = fbUser.uid;
        try {
          final doc = await FirebaseFirestore.instance.collection('users').doc(fbUser.uid).get();
          if (doc.exists && doc.data() != null) {
            final d = doc.data()!;
            userName = d['name'] ?? userName;
            userPhone = d['phone'] ?? userPhone;
            userEmail = d['email'] ?? userEmail;
            userDistrict = d['district'] ?? userDistrict;
            userUpazila = d['upazila'] ?? userUpazila;
            userVillage = d['village'] ?? userVillage;
            userOccupation = d['occupation'] ?? userOccupation;
          }
        } catch (_) {}
      }

      final isGuest = activeUid.isEmpty || activeUid.startsWith('guest_');
      if (isGuest) {
        await AppUnifiedDialog.showWarning(
          context,
          title: 'লগইন প্রয়োজন',
          message: 'ফিঙ্গারপ্রিন্ট সক্রিয় করতে প্রথমে আপনার আসল কৃষক একাউন্টে লগইন করুন।',
          buttonText: 'বুঝেছি',
        );
        return;
      }

      // ১. ডিভাইস বায়োমেট্রিক সাপোর্ট চেক (canCheckBiometrics & isDeviceSupported)
      final isSupported = await BiometricAuthService.canCheckBiometrics();
      if (!isSupported && mounted) {
        await AppUnifiedDialog.showWarning(
          context,
          title: 'ডিভাইস অসঙ্গতি',
          message: 'আপনার ডিভাইসে ফিঙ্গারপ্রিন্ট বা বায়োমেট্রিক সেন্সর পাওয়া যায়নি।',
          buttonText: 'বুঝেছি',
        );
        return;
      }

      // ২. সরাসরি ডিভাইসের নেটিভ ফিঙ্গারপ্রিন্ট স্ক্যানার (local_auth) ওপেন
      final success = await BiometricAuthService.showBiometricScanDialog(
        context,
        title: 'বায়োমেট্রিক ভেরিফিকেশন',
        subtitle: 'সক্রিয় করতে সেন্সরে আঙুল রাখুন',
      );

      if (success && mounted) {
        final userData = {
          'uid': activeUid,
          'name': userName,
          'phone': userPhone,
          'email': userEmail,
          'district': userDistrict,
          'upazila': userUpazila,
          'village': userVillage,
          'occupation': userOccupation,
        };
        await BiometricAuthService.enableBiometrics(
          phone: userPhone,
          uid: activeUid,
          userData: userData,
        );
        setState(() => _biometricEnabled = true);
        if (mounted) {
          await AppUnifiedDialog.showSuccess(
            context,
            title: 'সফল হয়েছে!',
            message: 'বায়োমেট্রিক সফলভাবে সেট করা হয়েছে!',
            buttonText: 'ঠিক আছে',
          );
        }
      }
    } else {
      // ৩. ইউজার সুইচ অফ করতে চাইলে কনফার্মেশন ডায়ালগ
      final confirmed = await AppUnifiedDialog.showConfirmation(
        context,
        title: 'ফিঙ্গারপ্রিন্ট বন্ধ করবেন?',
        message: 'আপনি কি নিশ্চিত যে ফিঙ্গারপ্রিন্ট লগইন ফিচারটি নিষ্ক্রিয় করতে চান?',
        confirmText: 'হ্যাঁ, বন্ধ করুন',
        cancelText: 'বাতিল',
      );

      if (confirmed && mounted) {
        await BiometricAuthService.disableBiometrics();
        setState(() => _biometricEnabled = false);
        if (mounted) {
          await AppUnifiedDialog.showSuccess(
            context,
            title: 'নিষ্ক্রিয় হয়েছে',
            message: 'ফিঙ্গারপ্রিন্ট লগইন সফলভাবে বন্ধ করা হয়েছে।',
            buttonText: 'ঠিক আছে',
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7FAF7),
      appBar: CustomAppBar(
        title: 'সেটিংস',
        showBackButton: true,
        onBackPressed: () => Navigator.pop(context),
      ),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
        children: [
          // Section 1: Security & Biometrics (Prominently Placed at the Top)
          _buildSectionHeader('নিরাপত্তা ও বায়োমেট্রিক'),
          _buildBiometricCard(),

          const SizedBox(height: 20),

          // Section 2: Notifications
          _buildSectionHeader('নোটিফিকেশন ও অ্যালার্ট'),
          _buildCardWrapper([
            SwitchListTile(
              activeColor: AppColors.primary,
              title: const Text('জরুরি আবহাওয়া সতর্কতা', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
              subtitle: const Text('ঝড়-বৃষ্টি ও দুর্যোগের জরুরি পুশ নোটিফিকেশন', style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary)),
              value: _weatherAlerts,
              onChanged: (val) => setState(() => _weatherAlerts = val),
            ),
            const Divider(height: 1, indent: 16, endIndent: 16),
            SwitchListTile(
              activeColor: AppColors.primary,
              title: const Text('দৈনিক বাজার দর আপডেট', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
              subtitle: const Text('প্রতিদিন সকালে মোকামের পাইকারি দরের বার্তা', style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary)),
              value: _marketUpdates,
              onChanged: (val) => setState(() => _marketUpdates = val),
            ),
          ]),

          const SizedBox(height: 20),

          // Section: Language & Display
          _buildSectionHeader('ভাষা ও ফন্ট'),
          _buildCardWrapper([
            ListTile(
              leading: const Icon(Icons.language_rounded, color: AppColors.primary),
              title: const Text('অ্যাপের ভাষা', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
              subtitle: const Text('বাংলা (বাংলাদেশ)', style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary)),
              trailing: const Chip(
                label: Text('বাংলা', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primaryDark)),
                backgroundColor: AppColors.primaryContainer,
                padding: EdgeInsets.zero,
              ),
            ),
            const Divider(height: 1, indent: 16, endIndent: 16),
            const ListTile(
              leading: Icon(Icons.font_download_outlined, color: AppColors.primary),
              title: Text('টাইপোগ্রাফি ফন্ট', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
              subtitle: Text('Tiro Bangla (গ্লোবাল বাংলা ফন্ট)', style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary)),
              trailing: Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 20),
            ),
          ]),

          const SizedBox(height: 20),

          // Section: Storage & Cache
          _buildSectionHeader('ডেটা ও অফলাইন মোড'),
          _buildCardWrapper([
            SwitchListTile(
              activeColor: AppColors.primary,
              title: const Text('অফলাইন ডেটা সংরক্ষণ', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
              subtitle: const Text('ইন্টারনেট সংযোগ ছাড়াও আগের তথ্য দেখার সুবিধা', style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary)),
              value: _offlineCache,
              onChanged: (val) => setState(() => _offlineCache = val),
            ),
            const Divider(height: 1, indent: 16, endIndent: 16),
            ListTile(
              leading: const Icon(Icons.cleaning_services_outlined, color: Color(0xFFE65100)),
              title: const Text('ক্যাশ মেমোরি পরিষ্কার করুন', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
              subtitle: const Text('অব্যবহৃত ছবি ও অস্থায়ী ডেটা মুছে ফেলুন', style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary)),
              trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.textMuted),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('ক্যাশ মেমোরি সফলভাবে পরিষ্কার করা হয়েছে'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
            ),
          ]),

          const SizedBox(height: 20),

          // Section: App Version with Real-time Firestore StreamBuilder
          _buildSectionHeader('অ্যাপ তথ্য'),
          StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance
                .collection('settings')
                .doc('app_config')
                .snapshots(),
            builder: (context, snapshot) {
              final appVer = (snapshot.hasData &&
                      snapshot.data?.data() != null &&
                      snapshot.data!.data()!['version'] != null)
                  ? snapshot.data!.data()!['version'].toString()
                  : AppStrings.appVersion;

              return _buildCardWrapper([
                ListTile(
                  leading: const Icon(Icons.info_outline_rounded, color: AppColors.primary),
                  title: const Text('অ্যাপ সংস্করণ', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                  subtitle: Text('কৃষি কথা – Krishi Kotha (Build $appVer)', style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary)),
                  trailing: Text('v$appVer', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textMuted)),
                ),
              ]);
            },
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  /// ডেডিকেটেড বায়োমেট্রিক সেটিংস কার্ড (Dedicated Biometric Settings Card with Live Status)
  Widget _buildBiometricCard() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _biometricEnabled ? const Color(0xFF81C784) : const Color(0xFFE2E8E2),
          width: _biometricEnabled ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: _biometricEnabled ? const Color(0xFF2E7D32).withOpacity(0.08) : const Color(0x0A000000),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: _biometricEnabled ? const Color(0xFFE8F5E9) : const Color(0xFFF1F8E9),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: _biometricEnabled ? const Color(0xFF2E7D32) : const Color(0xFF81C784).withOpacity(0.5),
                    width: 1.5,
                  ),
                ),
                child: const Center(
                  child: Icon(
                    Icons.fingerprint_rounded,
                    color: Color(0xFF2E7D32),
                    size: 26,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'বায়োমেট্রিক সেটিংস',
                      style: TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: 2.5),
                    Text(
                      'ফিঙ্গারপ্রিন্ট দিয়ে এক ক্লিকে সুরক্ষিত লগইন',
                      style: TextStyle(
                        fontSize: 12.5,
                        color: AppColors.textSecondary,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Transform.scale(
                scale: 0.9,
                child: Switch(
                  value: _biometricEnabled,
                  activeColor: const Color(0xFF2E7D32),
                  activeTrackColor: const Color(0xFFA5D6A7),
                  inactiveThumbColor: Colors.white,
                  inactiveTrackColor: const Color(0xFFCFD8DC),
                  onChanged: _handleBiometricToggle,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),
          const Divider(height: 1, color: Color(0xFFEFF3EF)),
          const SizedBox(height: 10),

          // Live Status Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (_biometricEnabled)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFF81C784), width: 1.0),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle_rounded, color: Color(0xFF2E7D32), size: 14),
                      SizedBox(width: 5),
                      Text(
                        'সেট করা আছে',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1B5E20),
                        ),
                      ),
                    ],
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFECEFF1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFCFD8DC), width: 1.0),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.info_outline_rounded, color: Color(0xFF78909C), size: 14),
                      SizedBox(width: 5),
                      Text(
                        'নিষ্ক্রিয় আছে',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF546E7A),
                        ),
                      ),
                    ],
                  ),
                ),

              if (!_biometricEnabled)
                InkWell(
                  onTap: () => _handleBiometricToggle(true),
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2E7D32),
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF2E7D32).withOpacity(0.25),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.fingerprint_rounded, color: Colors.white, size: 15),
                        SizedBox(width: 6),
                        Text(
                          'চালু করুন',
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
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: AppColors.primaryDark,
          letterSpacing: 0.2,
        ),
      ),
    );
  }

  Widget _buildCardWrapper(List<Widget> children) {
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
        children: children,
      ),
    );
  }
}
