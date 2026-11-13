import 'package:flutter/material.dart';
import '../../core/constants/admin_colors.dart';

/// সেন্ট্রালাইজড ফাস্ট ও সুন্দর লোডিং ইন্ডিকেটর
class AdminLoadingIndicator extends StatelessWidget {
  final String message;
  final double padding;

  const AdminLoadingIndicator({
    super.key,
    this.message = 'তথ্য লোডিং হচ্ছে.....',
    this.padding = 32.0,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(padding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(
              width: 36,
              height: 36,
              child: CircularProgressIndicator(
                strokeWidth: 3.0,
                color: AdminColors.primary,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              message,
              style: const TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                color: AdminColors.textSecondary,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

