import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/utils/bangla_number_converter.dart';
import '../../core/widgets/custom_app_bar.dart';
import '../../core/widgets/custom_button.dart';
import '../../providers/auth_provider.dart';
import '../auth/phone_login_screen.dart';
import '../auth/profile_setup_screen.dart';

class UserProfileScreen extends StatelessWidget {
  const UserProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final user = auth.user;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const CustomAppBar(title: 'কৃষক প্রোফাইল'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Farmer Avatar & Name Card
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: const BorderSide(color: AppColors.border),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 38,
                      backgroundColor: AppColors.primaryContainer,
                      child: Text(
                        user?.name.isNotEmpty == true ? user!.name.substring(0, 1) : 'ক',
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryDark,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      user?.name ?? 'শ্রদ্ধেয় কৃষক ভাই',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user?.phone.isNotEmpty == true
                          ? BanglaNumberConverter.toBangla(user!.phone)
                          : 'অতিথি ব্যবহারকারী',
                      style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const ProfileSetupScreen()),
                        );
                      },
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      label: const Text('তথ্য সংশোধন করুন'),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.primary),
                        minimumSize: const Size(160, 40),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Farming Details Card
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
                side: const BorderSide(color: AppColors.border),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'কৃষি তথ্য ও এলাকা',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                    ),
                    const Divider(color: AppColors.divider, height: 20),
                    _buildInfoTile(
                      icon: Icons.location_on_outlined,
                      label: 'এলাকা',
                      value: '${user?.upazila ?? ''}, ${user?.district ?? 'বাংলাদেশ'}',
                    ),
                    const SizedBox(height: 12),
                    _buildInfoTile(
                      icon: Icons.eco_outlined,
                      label: 'প্রধান চাষকৃত ফসল',
                      value: user?.preferredCrops.isNotEmpty == true
                          ? user!.preferredCrops.join(', ')
                          : 'সকল প্রকার ফসল',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // App Information
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
                side: const BorderSide(color: AppColors.border),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    _buildInfoTile(
                      icon: Icons.info_outline,
                      label: 'অ্যাপ সংস্করণ',
                      value: AppStrings.appVersion,
                    ),
                    const Divider(color: AppColors.divider, height: 20),
                    _buildInfoTile(
                      icon: Icons.support_agent_outlined,
                      label: 'সহায়তা হেল্পলাইন',
                      value: '১৬১২৩ (কৃষি কল সেন্টার)',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Logout Button
            CustomButton(
              text: 'লগআউট করুন',
              onPressed: () async {
                await auth.signOut();
                if (context.mounted) {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const PhoneLoginScreen()),
                    (route) => false,
                  );
                }
              },
              backgroundColor: AppColors.alertCritical,
              icon: Icons.logout_rounded,
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoTile({required IconData icon, required String label, required String value}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppColors.primary, size: 22),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
