import 'package:flutter/material.dart';
import '../../core/constants/admin_colors.dart';
import '../../core/responsive/responsive_layout.dart';

class AdminHeader extends StatelessWidget {
  final String title;
  final VoidCallback? onMenuPressed;

  const AdminHeader({
    super.key,
    required this.title,
    this.onMenuPressed,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveLayout.isMobile(context);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 16 : 24,
        vertical: 16,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: AdminColors.border, width: 1),
        ),
      ),
      child: Row(
        children: [
          if (isMobile) ...[
            IconButton(
              icon: const Icon(Icons.menu_rounded, color: AdminColors.textPrimary),
              onPressed: onMenuPressed,
              tooltip: 'মেনু খুলুন',
            ),
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: const [
                  BoxShadow(color: Color(0x15000000), blurRadius: 4, offset: Offset(0, 1)),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: Image.asset(
                'assets/icons/pnglogo.png',
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => Container(
                  color: AdminColors.primaryLight,
                  child: const Center(
                    child: Icon(Icons.eco_rounded, color: Colors.white, size: 20),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AdminColors.textPrimary,
                  ),
                ),
                Text(
                  'কৃষি কথা এডমিন কন্ট্রোল ও রিয়েল-টাইম ম্যানেজমেন্ট',
                  style: TextStyle(
                    fontSize: 12,
                    color: AdminColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          // Live Firestore Status Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AdminColors.successBg,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AdminColors.primary.withOpacity(0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AdminColors.primary,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                const Text(
                  'সিস্টেম সক্রিয়',
                  style: TextStyle(
                    color: AdminColors.primaryDark,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
