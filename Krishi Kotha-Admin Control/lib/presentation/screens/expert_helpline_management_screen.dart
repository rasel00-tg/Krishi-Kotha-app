import 'package:flutter/material.dart';
import '../../core/constants/admin_colors.dart';

/// হোমপেজ সাব-মেনু: "কৃষি বিশেষজ্ঞ" (Coming Soon Page)
class ExpertHelplineManagementScreen extends StatelessWidget {
  const ExpertHelplineManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AdminColors.background,
      width: double.infinity,
      height: double.infinity,
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 520),
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 48),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AdminColors.border),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x06000000),
                  blurRadius: 16,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 76,
                  height: 76,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE0F2F1),
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFF80CBC4), width: 1.5),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.support_agent_rounded,
                      size: 40,
                      color: Color(0xFF00897B),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'কৃষি বিশেষজ্ঞ',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AdminColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE0F2F1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Coming Soon',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF00897B),
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  'এই ফিচারটি এখনো চালু হয়নি। অনুগ্রহ করে পরবর্তী আপডেটের জন্য অপেক্ষা করুন।',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: AdminColors.textSecondary,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
