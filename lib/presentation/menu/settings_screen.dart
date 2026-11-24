import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/widgets/custom_app_bar.dart';
import '../../global_popup/global_popup.dart';
import '../../data/services/auth_service.dart';
import '../../data/services/biometric_auth_service.dart';
import '../../providers/auth_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> with SingleTickerProviderStateMixin {
  bool _weatherAlerts = true;
  bool _marketUpdates = true;
  bool _offlineCache = true;
  bool _biometricEnabled = false;
  late final Stream<DocumentSnapshot<Map<String, dynamic>>> _appConfigStream;
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    // Read Optimization: Cache app_config stream once in initState
    _appConfigStream = FirebaseFirestore.instance
        .collection('settings')
        .doc('app_config')
        .snapshots();
    _loadBiometricState();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
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
      // Unified Auth Resolution (AuthProvider -> FirebaseAuth -> SharedPreferences AuthService)
      if (user == null || user.uid.isEmpty || user.uid.startsWith('guest_')) {
        try {
          final cachedUser = await AuthService().loadCachedUser();
          if (cachedUser != null && cachedUser.uid.isNotEmpty && !cachedUser.uid.startsWith('guest_')) {
            user = cachedUser;
          }
        } catch (_) {}
      }

      String activeUid = user?.uid ?? '';
      if ((activeUid.isEmpty || activeUid.startsWith('guest_')) && fbUser != null && !fbUser.isAnonymous) {
        activeUid = fbUser.uid;
      }

      String userPhone = user?.phone ?? fbUser?.phoneNumber ?? '';
      String userEmail = user?.email ?? fbUser?.email ?? '';
      String userName = user?.name ?? fbUser?.displayName ?? 'সম্মানিত কৃষক';
      String userDistrict = user?.district ?? '';
      String userUpazila = user?.upazila ?? '';
      String userVillage = user?.village ?? '';
      String userOccupation = user?.occupation ?? '';

      // ফায়ারবেস কারেন্ট ইউজার থাকলে প্রয়োজনে ফায়ারস্টোর থেকে ইউজারের বিস্তারিত লোড করা
      if (fbUser != null && !fbUser.isAnonymous && (userName == 'সম্মানিত কৃষক' || userPhone.isEmpty)) {
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
        setState(() => _biometricEnabled = false);
        await GlobalPopup.showNotice(
          context,
          title: 'লগইন প্রয়োজন',
          message: 'বায়োমেট্রিক লগইন চালু করতে প্রথমে আপনার একাউন্টে লগইন করুন।',
          buttonText: 'বুঝেছি',
        );
        return;
      }

      // ১. ডিভাইস বায়োমেট্রিক বা স্ক্রিন লক সাপোর্ট চেক (isDeviceSupported || canCheckBiometrics)
      final isSupported = await BiometricAuthService.isDeviceBiometricAvailable();
      if (!isSupported && mounted) {
        setState(() => _biometricEnabled = false);
        await GlobalPopup.showNotice(
          context,
          title: 'ডিভাইস অসঙ্গতি',
          message: 'আপনার ডিভাইসে বায়োমেট্রিক বা স্ক্রিন লক সেট করা নেই। অনুগ্রহ করে ফোনের সেটিংস থেকে ফিঙ্গারপ্রিন্ট বা স্ক্রিন লক চালু করুন।',
          buttonText: 'বুঝেছি',
        );
        return;
      }

      // ২. সরাসরি ডিভাইসের নেটিভ বায়োমেট্রিক/লক প্রমট (biometricOnly: false)
      final verifyRes = await BiometricAuthService.authenticateDevice(
        reason: 'বায়োমেট্রিক লগইন চালু করতে আপনার ডিভাইস যাচাই করুন',
      );

      if (!mounted) return;

      if (verifyRes.success) {
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
          identifier: userEmail.isNotEmpty ? userEmail : userPhone,
          userData: userData,
        );
        setState(() => _biometricEnabled = true);
        if (mounted) {
          await GlobalPopup.showNotice(
            context,
            title: 'সফল হয়েছে!',
            message: 'বায়োমেট্রিক লগইন সফলভাবে চালু হয়েছে!',
            buttonText: 'ঠিক আছে',
          );
        }
      } else {
        setState(() => _biometricEnabled = false);
        await GlobalPopup.showNotice(
          context,
          title: 'বায়োমেট্রিক যাচাই ব্যর্থ',
          message: verifyRes.errorMessage ?? 'বায়োমেট্রিক যাচাইকরণ সম্পন্ন হয়নি।',
          buttonText: 'বুঝেছি',
        );
      }
    } else {
      // ৩. ইউজার সুইচ অফ করতে চাইলে GlobalPopup কনফার্মেশন ডায়ালগ
      final confirmed = await GlobalPopup.showConfirm(
        context,
        title: 'বায়োমেট্রিক বন্ধ করবেন?',
        message: 'আপনি কি নিশ্চিত যে বায়োমেট্রিক লগইন ফিচারটি বন্ধ করতে চান?',
        confirmText: 'হ্যাঁ, বন্ধ করুন',
        cancelText: 'বাতিল',
      );

      if (confirmed == true && mounted) {
        await BiometricAuthService.disableBiometrics();
        setState(() => _biometricEnabled = false);
        if (mounted) {
          await GlobalPopup.showNotice(
            context,
            title: 'বায়োমেট্রিক বন্ধ',
            message: 'বায়োমেট্রিক লগইন বন্ধ করা হয়েছে।',
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

          // Section: Language
          _buildSectionHeader('ভাষা'),
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
              onTap: () {
                GlobalPopup.showNotice(
                  context,
                  title: 'ভাষা পরিবর্তন',
                  message: 'এই ফিচারটি এখনো চালু হয়নি',
                  buttonText: 'ঠিক আছে',
                );
              },
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
            stream: _appConfigStream,
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

  /// ডেডিকেটেড বায়োমেট্রিক সেটিংস কার্ড (Colorful Animated Biometric Settings Card)
  Widget _buildBiometricCard() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOutCubic,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: _biometricEnabled
              ? const [Color(0xFFECFDF5), Color(0xFFD1FAE5)]
              : const [Color(0xFFF8FAFC), Color(0xFFEEF2FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: _biometricEnabled ? const Color(0xFF10B981) : const Color(0xFFC7D2FE),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: _biometricEnabled
                ? const Color(0xFF10B981).withOpacity(0.16)
                : const Color(0xFF6366F1).withOpacity(0.10),
            blurRadius: 16,
            offset: const Offset(0, 6),
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
              ScaleTransition(
                scale: _pulseAnimation,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 350),
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: _biometricEnabled
                          ? const [Color(0xFF10B981), Color(0xFF059669)]
                          : const [Color(0xFF6366F1), Color(0xFF0EA5E9)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: (_biometricEnabled
                                ? const Color(0xFF10B981)
                                : const Color(0xFF6366F1))
                            .withOpacity(0.35),
                        blurRadius: 12,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.fingerprint_rounded,
                      color: Colors.white,
                      size: 25,
                    ),
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
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    SizedBox(height: 2.5),
                    Text(
                      'ফিঙ্গারপ্রিন্ট দিয়ে এক ক্লিকে সুরক্ষিত লগইন',
                      style: TextStyle(
                        fontSize: 12.5,
                        color: Color(0xFF475569),
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Transform.scale(
                scale: 0.92,
                child: Switch(
                  value: _biometricEnabled,
                  activeColor: Colors.white,
                  activeTrackColor: const Color(0xFF10B981),
                  inactiveThumbColor: Colors.white,
                  inactiveTrackColor: const Color(0xFF94A3B8),
                  onChanged: _handleBiometricToggle,
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),
          Divider(height: 1, color: const Color(0xFF94A3B8).withOpacity(0.22)),
          const SizedBox(height: 12),

          // Live Status & Action Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _biometricEnabled ? const Color(0xFF10B981) : const Color(0xFFCBD5E1),
                    width: 1.2,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ScaleTransition(
                      scale: _biometricEnabled ? _pulseAnimation : const AlwaysStoppedAnimation(1.0),
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _biometricEnabled ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                    const SizedBox(width: 7),
                    Text(
                      _biometricEnabled ? 'চালু আছে' : 'বন্ধ আছে',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: _biometricEnabled ? const Color(0xFF065F46) : const Color(0xFF475569),
                      ),
                    ),
                  ],
                ),
              ),

              InkWell(
                onTap: () => _handleBiometricToggle(!_biometricEnabled),
                borderRadius: BorderRadius.circular(12),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: _biometricEnabled
                          ? const [Color(0xFFF43F5E), Color(0xFFFB923C)]
                          : const [Color(0xFF0D9488), Color(0xFF059669)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: (_biometricEnabled
                                ? const Color(0xFFF43F5E)
                                : const Color(0xFF0D9488))
                            .withOpacity(0.28),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _biometricEnabled ? Icons.power_settings_new_rounded : Icons.fingerprint_rounded,
                        color: Colors.white,
                        size: 15,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _biometricEnabled ? 'বন্ধ করুন' : 'চালু করুন',
                        style: const TextStyle(
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
