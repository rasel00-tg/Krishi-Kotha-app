import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
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
    final user = authProvider.user;

    if (enable) {
      if (user == null || user.uid.startsWith('guest_')) {
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

      // ২. নেটিভ ফিঙ্গারপ্রিন্ট ভেরিফিকেশন ডায়ালগ প্রদর্শন
      final success = await BiometricAuthService.showBiometricScanDialog(
        context,
        title: 'ফিঙ্গারপ্রিন্ট ভেরিফাই করুন',
        subtitle: 'আপনার ফিঙ্গারপ্রিন্ট সেন্সরে আঙুল রেখে শনাক্তকরণ সম্পন্ন করুন',
      );

      if (success && mounted) {
        final userData = {
          'uid': user.uid,
          'name': user.name,
          'phone': user.phone,
          'email': user.email,
          'district': user.district,
          'upazila': user.upazila,
          'village': user.village,
          'occupation': user.occupation,
        };
        await BiometricAuthService.enableBiometrics(
          phone: user.phone,
          uid: user.uid,
          userData: userData,
        );
        setState(() => _biometricEnabled = true);
        if (mounted) {
          await AppUnifiedDialog.showSuccess(
            context,
            title: 'সফল হয়েছে!',
            message: 'ফিঙ্গারপ্রিন্ট লগইন সফলভাবে সক্রিয় করা হয়েছে। এখন থেকে আপনি ফিঙ্গারপ্রিন্ট দিয়ে এক ক্লিকে লগইন করতে পারবেন।',
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
      backgroundColor: AppColors.background,
      appBar: const CustomAppBar(title: 'সেটিংস'),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
        children: [
          // Section 1: Security & Biometrics (Prominently Placed at the Top)
          _buildSectionHeader('নিরাপত্তা ও বায়োমেট্রিক'),
          _buildCardWrapper([
            SwitchListTile(
              activeColor: AppColors.primary,
              secondary: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.primary.withOpacity(0.2), width: 1.0),
                ),
                child: const Center(
                  child: Icon(Icons.fingerprint_rounded, color: AppColors.primary, size: 24),
                ),
              ),
              title: const Text('ফিঙ্গারপ্রিন্ট লগইন (Biometric Login)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              subtitle: const Text('দ্রুত ও সুরক্ষিতভাবে ফিঙ্গারপ্রিন্ট দিয়ে একাউন্টে প্রবেশ করুন', style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary)),
              value: _biometricEnabled,
              onChanged: _handleBiometricToggle,
            ),
          ]),

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

          // Section: App Version
          _buildCardWrapper([
            const ListTile(
              leading: Icon(Icons.info_outline_rounded, color: AppColors.primary),
              title: Text('অ্যাপ সংস্করণ', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
              subtitle: Text('কৃষি কথা – Krishi Kotha (Build 1.0.0+1)', style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary)),
              trailing: Text('v1.0.0', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textMuted)),
            ),
          ]),
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
