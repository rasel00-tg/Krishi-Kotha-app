import 'dart:ui';
import 'package:flutter/material.dart';
import '../../core/constants/admin_colors.dart';

/// প্রিমিয়াম সেন্ট্রালাইজড ডিলিট কনফার্মেশন ডায়ালগ
///
/// অ্যাপের লোডিং পপ-আপের আদলে BackdropFilter ব্লার (8px), সফট ডার্ক ওভারলে,
/// ২৪px বর্ডার রেডিয়াস, শীর্ষে সফট রেড ওয়ার্নিং ব্যাজ, এবং পরিচ্ছন্ন হ্যাঁ/না অ্যাকশন বাটন।
class AdminDeleteDialog extends StatelessWidget {
  final String title;
  final String subtitle;
  final String? itemName;

  const AdminDeleteDialog({
    super.key,
    this.title = 'আপনি কি নিশ্চিত মুছে ফেলতে চান?',
    this.subtitle = 'এই তথ্যটি মুছে ফেললে অ্যাপ থেকেও স্থায়ীভাবে মুছে যাবে। আপনি কি এগিয়ে যেতে চান?',
    this.itemName,
  });

  /// সেন্ট্রালাইজড ডায়ালগ খোলার স্ট্যাটিক হেল্পার
  static Future<bool> show(
    BuildContext context, {
    String title = 'আপনি কি নিশ্চিত মুছে ফেলতে চান?',
    String subtitle = 'এই তথ্যটি মুছে ফেললে অ্যাপ থেকেও স্থায়ীভাবে মুছে যাবে। আপনি কি এগিয়ে যেতে চান?',
    String? itemName,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      barrierColor: const Color(0xFF041208).withOpacity(0.55),
      builder: (ctx) => AdminDeleteDialog(
        title: title,
        subtitle: subtitle,
        itemName: itemName,
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
      child: Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          constraints: const BoxConstraints(maxWidth: 400),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: const Color(0xFFDC2626).withOpacity(0.15),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.22),
                blurRadius: 36,
                spreadRadius: 2,
                offset: const Offset(0, 14),
              ),
              BoxShadow(
                color: const Color(0xFFDC2626).withOpacity(0.12),
                blurRadius: 20,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          padding: const EdgeInsets.fromLTRB(26, 28, 26, 24),
          child: Material(
            color: Colors.transparent,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAlignment.center,
              children: [
                // শীর্ষে সফট রেড/অরেঞ্জ স্কয়ার-রাউন্ডেড ব্যাজের ভেতর ট্র্যাশ-ক্যান আইকন
                Container(
                  width: 66,
                  height: 66,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEE2E2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: const Color(0xFFFECACA),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFDC2626).withOpacity(0.18),
                        blurRadius: 14,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.delete_forever_rounded,
                      color: Color(0xFFDC2626),
                      size: 34,
                    ),
                  ),
                ),
                const SizedBox(height: 18),

                // শিরোনাম: বড় ও স্পষ্ট বোল্ড হরফ
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AdminColors.textPrimary,
                    height: 1.35,
                  ),
                ),

                // আইটেমের নাম ট্যাগ (যদি থাকে)
                if (itemName != null && itemName!.trim().isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Text(
                      itemName!,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF334155),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 10),

                // সাব-টাইটেল: মার্জিত সতর্কতা টেক্সট
                Text(
                  subtitle,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 13.5,
                    color: Color(0xFF64748B),
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 24),

                // অ্যাকশন বাটনসমূহ (স্পষ্ট হ্যাঁ / না)
                Row(
                  children: [
                    // "না, বাতিল করুন" বাটন
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          backgroundColor: const Color(0xFFF1F5F9),
                          foregroundColor: const Color(0xFF334155),
                          side: const BorderSide(color: Color(0xFFCBD5E1)),
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text(
                          'না, বাতিল করুন',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // "হ্যাঁ, মুছে ফেলুন" বাটন
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFDC2626),
                          foregroundColor: Colors.white,
                          elevation: 3,
                          shadowColor: const Color(0xFFDC2626).withOpacity(0.4),
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: () => Navigator.pop(context, true),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.delete_outline_rounded, size: 17, color: Colors.white),
                            SizedBox(width: 5),
                            Text(
                              'হ্যাঁ, মুছে ফেলুন',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
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
          ),
        ),
      ),
    );
  }
}
