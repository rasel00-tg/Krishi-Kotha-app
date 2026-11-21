import 'dart:ui';
import 'package:flutter/material.dart';

/// ============================================================================
/// KRISHI KOTHA — UNIFIED GLOBAL POPUP SYSTEM (MASTER TEMPLATE)
/// ============================================================================
/// এই ফাইলটি "কৃষি কথা" অ্যাপের সকল গ্লোবাল ডায়ালগ ও নোটিস পপআপের একক উৎস
/// (Single Source of Truth)। ভবিষ্যতে যেকোনো নতুন ফিচার নোটিস, কামিং সুন বার্তা
/// বা কনফার্মেশন পপআপ প্রদর্শনের জন্য এই ফাইলটিই একমাত্র ডিজাইন স্ট্যান্ডার্ড।
///
/// ডিজাইন স্পেসিফিকেশন (হুবহু "কৃষি বিশেষজ্ঞ" মাস্টার টেমপ্লেট):
/// 1. ব্যাকগ্রাউন্ড: ফ্রস্টেড গ্লাস ব্লার (BackdropFilter ImageFilter.blur) + সফট ডার্ক ওভারলে।
/// 2. কার্ড: পিওর হোয়াইট (22px বর্ডার রেডিয়াস, সফট এলিভেটেড ড্রপ শ্যাডো)।
/// 3. লোগো: কোনো গোল বর্ডার ছাড়া অ্যাপের ক্লিন লোগো (assets/icons/pnglogo.png)।
/// 4. টাইটেল: প্রিমিয়াম টিল-গ্রিন কালার (#00897B), বোল্ড টাইপোগ্রাফি।
/// 5. মেসেজ: সুষম লাইন-হাইট ও মার্জিত স্লিম টেক্সট (#455A64)।
/// 6. বাটন: টিল-গ্রিন (#00897B) ফুল-উইডথ রাউন্ডেড বাটন (উচ্চতা 46px, রেডিয়াস 12px)।
/// 7. নেভিগেশন: useRootNavigator: true (BottomNavigationBar-এর উপরে পপআপ প্রদর্শন নিশ্চিত)।
/// ============================================================================
class GlobalPopup {
  GlobalPopup._();

  static const Color primaryTeal = Color(0xFF00897B);
  static const Color textBodyColor = Color(0xFF455A64);
  static const Color cardBgColor = Colors.white;
  static const String appLogoAsset = 'assets/icons/pnglogo.png';

  /// ১. সাধারণ নোটিশ / অ্যালার্ট পপআপ (হুবহু "কৃষি বিশেষজ্ঞ" ডিজাইন)
  static Future<void> showNotice(
    BuildContext context, {
    required String title,
    required String message,
    String buttonText = 'ঠিক আছে',
    VoidCallback? onPressed,
    bool barrierDismissible = true,
  }) async {
    await showDialog(
      context: context,
      useRootNavigator: true,
      barrierDismissible: barrierDismissible,
      barrierColor: Colors.black.withOpacity(0.55),
      builder: (dialogCtx) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 6.0, sigmaY: 6.0),
        child: Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          insetPadding: const EdgeInsets.symmetric(horizontal: 30, vertical: 24),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 26),
            decoration: BoxDecoration(
              color: cardBgColor,
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.18),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // ক্লিন অফিসিয়াল অ্যাপ লোগো (কোনো বর্ডার ছাড়া)
                Image.asset(
                  appLogoAsset,
                  width: 62,
                  height: 62,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const Icon(
                    Icons.eco_rounded,
                    color: primaryTeal,
                    size: 48,
                  ),
                ),
                const SizedBox(height: 16),

                // টিল-গ্রিন টাইটেল
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 18.5,
                    fontWeight: FontWeight.bold,
                    color: primaryTeal,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 10),

                // সুষম মেসেজ বডি
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 13.8,
                    color: textBodyColor,
                    height: 1.48,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const SizedBox(height: 24),

                // টিল-গ্রিন ফুল-উইডথ রাউন্ডেড বাটন
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: ElevatedButton(
                    onPressed: () {
                      if (Navigator.of(dialogCtx, rootNavigator: true).canPop()) {
                        Navigator.of(dialogCtx, rootNavigator: true).pop();
                      }
                      if (onPressed != null) {
                        onPressed();
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryTeal,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      buttonText,
                      style: const TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// ২. ফিচার আপকামিং / কামিং সুন পপআপ (ডিফল্ট মেসেজ দিয়ে showNotice কল করে)
  static Future<void> showComingSoon(
    BuildContext context, {
    required String title,
    String message = 'এই ফিচারটি এখনো চালু হয়নি। অনুগ্রহ করে পরবর্তী আপডেটের জন্য অপেক্ষা করুন।',
    String buttonText = 'ঠিক আছে',
    VoidCallback? onPressed,
    bool barrierDismissible = true,
  }) {
    return showNotice(
      context,
      title: title,
      message: message,
      buttonText: buttonText,
      onPressed: onPressed,
      barrierDismissible: barrierDismissible,
    );
  }

  /// ৩. কনফার্মেশন পপআপ (যেমন: হ্যাঁ/না বা বাতিল/নিশ্চিত করুন)
  static Future<bool?> showConfirm(
    BuildContext context, {
    required String title,
    required String message,
    String confirmText = 'নিশ্চিত করুন',
    String cancelText = 'বাতিল',
    Color confirmColor = primaryTeal,
    VoidCallback? onConfirm,
    VoidCallback? onCancel,
    bool barrierDismissible = true,
  }) {
    return showDialog<bool>(
      context: context,
      useRootNavigator: true,
      barrierDismissible: barrierDismissible,
      barrierColor: Colors.black.withOpacity(0.55),
      builder: (dialogCtx) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 6.0, sigmaY: 6.0),
        child: Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          insetPadding: const EdgeInsets.symmetric(horizontal: 30, vertical: 24),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 26),
            decoration: BoxDecoration(
              color: cardBgColor,
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.18),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // ক্লিন অফিসিয়াল অ্যাপ লোগো
                Image.asset(
                  appLogoAsset,
                  width: 62,
                  height: 62,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => Icon(
                    Icons.eco_rounded,
                    color: confirmColor,
                    size: 48,
                  ),
                ),
                const SizedBox(height: 16),

                // টাইটেল
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18.5,
                    fontWeight: FontWeight.bold,
                    color: confirmColor,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 10),

                // মেসেজ বডি
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 13.8,
                    color: textBodyColor,
                    height: 1.48,
                  ),
                ),
                const SizedBox(height: 24),

                // অ্যাকশন বাটনসমূহ (বাতিল ও নিশ্চিত)
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 46,
                        child: OutlinedButton(
                          onPressed: () {
                            if (Navigator.of(dialogCtx, rootNavigator: true).canPop()) {
                              Navigator.of(dialogCtx, rootNavigator: true).pop(false);
                            }
                            if (onCancel != null) onCancel();
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF78909C),
                            side: const BorderSide(color: Color(0xFFCFD8DC), width: 1.2),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            cancelText,
                            style: const TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: SizedBox(
                        height: 46,
                        child: ElevatedButton(
                          onPressed: () {
                            if (Navigator.of(dialogCtx, rootNavigator: true).canPop()) {
                              Navigator.of(dialogCtx, rootNavigator: true).pop(true);
                            }
                            if (onConfirm != null) onConfirm();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: confirmColor,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            confirmText,
                            style: const TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
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

  /// ৪. কাস্টম বডি পপআপ শেল (একই ব্যাকগ্রাউন্ড ব্লার, কার্ড ও লোগো ফ্রেমওয়ার্ক)
  static Future<T?> showCustom<T>(
    BuildContext context, {
    required Widget child,
    bool showLogo = true,
    String? title,
    bool barrierDismissible = true,
  }) {
    return showDialog<T>(
      context: context,
      useRootNavigator: true,
      barrierDismissible: barrierDismissible,
      barrierColor: Colors.black.withOpacity(0.55),
      builder: (dialogCtx) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 6.0, sigmaY: 6.0),
        child: Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          insetPadding: const EdgeInsets.symmetric(horizontal: 30, vertical: 24),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 26),
            decoration: BoxDecoration(
              color: cardBgColor,
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.18),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (showLogo) ...[
                  Image.asset(
                    appLogoAsset,
                    width: 62,
                    height: 62,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => const Icon(
                      Icons.eco_rounded,
                      color: primaryTeal,
                      size: 48,
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                if (title != null) ...[
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 18.5,
                      fontWeight: FontWeight.bold,
                      color: primaryTeal,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                child,
              ],
            ),
          ),
        ),
      ),
    );
  }
}
