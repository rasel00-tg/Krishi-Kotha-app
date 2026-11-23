import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';

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

  /// ৫. নোটিফিকেশন বিস্তারিত পপআপ (মাষ্টার গ্লোবাল পপআপ টেমপ্লেট)
  static Future<void> showNotificationDetail(
    BuildContext context, {
    required String title,
    required String message,
    required String timeText,
    String? imageUrl,
    String? actionUrl,
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
          insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
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
                  width: 58,
                  height: 58,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const Icon(
                    Icons.eco_rounded,
                    color: primaryTeal,
                    size: 44,
                  ),
                ),
                const SizedBox(height: 14),

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
                const SizedBox(height: 6),

                // তারিখ ও সময়
                if (timeText.trim().isNotEmpty) ...[
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.calendar_today_rounded,
                        size: 13,
                        color: Color(0xFF78909C),
                      ),
                      const SizedBox(width: 5),
                      Flexible(
                        child: Text(
                          timeText,
                          style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF78909C),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                ],

                // Cloudflare R2 ব্যানার ছবি (যদি থাকে)
                if (imageUrl != null && imageUrl.trim().isNotEmpty) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      constraints: const BoxConstraints(maxHeight: 180),
                      width: double.infinity,
                      color: Colors.grey.shade100,
                      child: CachedNetworkImage(
                        imageUrl: imageUrl.trim(),
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          height: 120,
                          color: Colors.grey.shade100,
                          child: const Center(
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: primaryTeal,
                            ),
                          ),
                        ),
                        errorWidget: (context, url, error) => const SizedBox.shrink(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                ],

                // স্ক্রলেবল বডি মেসেজ (লম্বা হলেও স্মুথ স্ক্রলেবল)
                Flexible(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: MediaQuery.of(dialogCtx).size.height * 0.38,
                    ),
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Text(
                        message,
                        textAlign: TextAlign.left,
                        style: const TextStyle(
                          fontSize: 14.5,
                          height: 1.6,
                          color: textBodyColor,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // ফুল-উইডথ টিল-গ্রিন বাটন
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: ElevatedButton(
                    onPressed: () async {
                      if (Navigator.of(dialogCtx, rootNavigator: true).canPop()) {
                        Navigator.of(dialogCtx, rootNavigator: true).pop();
                      }
                      if (onPressed != null) {
                        onPressed();
                      } else if (actionUrl != null && actionUrl.trim().isNotEmpty) {
                        final uri = Uri.tryParse(actionUrl.trim());
                        if (uri != null && await canLaunchUrl(uri)) {
                          await launchUrl(uri, mode: LaunchMode.externalApplication);
                        }
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
                      (actionUrl != null && actionUrl.trim().isNotEmpty)
                          ? 'লিংকে যান'
                          : buttonText,
                      style: const TextStyle(
                        fontSize: 15,
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

  static bool _isLoadingOpen = false;

  /// ৬. গ্লোবাল পপআপ লোডিং (মাস্টার টেমপ্লেট ডিজাইন)
  static void showLoading(
    BuildContext context, {
    String message = 'রিমাইন্ডার সেভ হচ্ছে...',
  }) {
    if (_isLoadingOpen) return;
    _isLoadingOpen = true;
    showDialog(
      context: context,
      useRootNavigator: true,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.55),
      builder: (dialogCtx) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 6.0, sigmaY: 6.0),
        child: Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 26),
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
                Image.asset(
                  appLogoAsset,
                  width: 58,
                  height: 58,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const Icon(
                    Icons.eco_rounded,
                    color: primaryTeal,
                    size: 44,
                  ),
                ),
                const SizedBox(height: 18),
                const SizedBox(
                  width: 36,
                  height: 36,
                  child: CircularProgressIndicator(
                    strokeWidth: 3.2,
                    valueColor: AlwaysStoppedAnimation<Color>(primaryTeal),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: primaryTeal,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ).then((_) {
      _isLoadingOpen = false;
    });
  }

  static void hideLoading(BuildContext context) {
    if (_isLoadingOpen) {
      _isLoadingOpen = false;
      try {
        if (Navigator.of(context, rootNavigator: true).canPop()) {
          Navigator.of(context, rootNavigator: true).pop();
        }
      } catch (_) {}
    }
  }
}
