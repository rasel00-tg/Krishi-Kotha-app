import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

/// কাস্টম ওয়ার্নিং অ্যালার্ট ডায়ালগ (অ্যাপ লোগো সহ সেন্ট্রাল পপ-আপ)
void showAppWarningDialog(
  BuildContext context, {
  required String message,
  String title = 'সতর্কবার্তা',
  VoidCallback? onConfirm,
}) {
  bool isDismissed = false;
  void dismiss(BuildContext dContext) {
    if (!isDismissed) {
      isDismissed = true;
      if (Navigator.of(dContext, rootNavigator: true).canPop()) {
        Navigator.of(dContext, rootNavigator: true).pop();
      }
      if (onConfirm != null) {
        Future.microtask(onConfirm);
      }
    }
  }

  showDialog(
    context: context,
    useRootNavigator: true,
    barrierDismissible: true,
    builder: (dialogContext) {
      return Dialog(
        backgroundColor: Colors.white,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
        ),
        insetPadding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 24, 22, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // ১. শীর্ষে অ্যাপের আসল লোগো (assets/icons/pnglogo.png, height: 55, width: 55)
              SizedBox(
                width: 55,
                height: 55,
                child: Image.asset(
                  'assets/icons/pnglogo.png',
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const Icon(
                    Icons.warning_amber_rounded,
                    size: 50,
                    color: Color(0xFFD32F2F),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // ২. লালচে ওয়ার্নিং টাইটেল: "সতর্কবার্তা"
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFD32F2F),
                  letterSpacing: 0.3,
                ),
              ),

              const SizedBox(height: 10),

              // ৩. মাঝখানে বড় ও স্পষ্ট হরফে নির্দিষ্ট সতর্কবার্তা বার্তা
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary,
                  height: 1.45,
                ),
              ),

              const SizedBox(height: 22),

              // ৪. নিচে স্পষ্ট ও আকর্ষণীয় "ঠিক আছে" অ্যাকশন বাটন
              SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton(
                  onPressed: () => dismiss(dialogContext),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'ঠিক আছে',
                    style: TextStyle(
                      fontSize: 15.5,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

/// কাস্টম সাকসেস ডায়ালগ (অ্যাপ লোগো ও সবুজ সাকসেস আইকন সহ)
void showAppSuccessDialog(
  BuildContext context, {
  required String title,
  required String message,
  VoidCallback? onConfirm,
  bool autoDismiss = true,
}) {
  bool isDismissed = false;

  void dismiss(BuildContext dContext) {
    if (!isDismissed) {
      isDismissed = true;
      if (Navigator.of(dContext, rootNavigator: true).canPop()) {
        Navigator.of(dContext, rootNavigator: true).pop();
      }
      if (onConfirm != null) {
        Future.microtask(onConfirm);
      }
    }
  }

  showDialog(
    context: context,
    useRootNavigator: true,
    barrierDismissible: true,
    builder: (dialogContext) {
      if (autoDismiss) {
        Future.delayed(const Duration(milliseconds: 1600), () {
          dismiss(dialogContext);
        });
      }

      return Dialog(
        backgroundColor: Colors.white,
        elevation: 10,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
        ),
        insetPadding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 24, 22, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // ১. শীর্ষে অ্যাপের আসল লোগো (assets/icons/pnglogo.png, height: 55, width: 55)
              SizedBox(
                width: 55,
                height: 55,
                child: Image.asset(
                  'assets/icons/pnglogo.png',
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const Icon(
                    Icons.check_circle_outline_rounded,
                    size: 50,
                    color: AppColors.primary,
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // ২. সবুজ টিক / সাকসেস আইকন
              Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(
                  color: Color(0xFFE8F5E9),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle_rounded,
                  color: Color(0xFF2E7D32),
                  size: 34,
                ),
              ),

              const SizedBox(height: 12),

              // ৩. হেডিং: "লগইন সফল হয়েছে!"
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryDark,
                  letterSpacing: 0.2,
                ),
              ),

              const SizedBox(height: 8),

              // ৪. বার্তা: "কৃষি কথা অ্যাপে আপনাকে স্বাগতম।"
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary,
                  height: 1.45,
                ),
              ),

              const SizedBox(height: 22),

              // ৫. "চালিয়ে যান" বাটন
              SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton(
                  onPressed: () => dismiss(dialogContext),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'চালিয়ে যান',
                    style: TextStyle(
                      fontSize: 15.5,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

/// গ্লোবাল এরর ও সাকসেস পপ-আপ হেল্পার (ক্র্যাশ-প্রুফ ও ইনস্ট্যান্ট টাচ আনব্লকার)
void showErrorPopup(BuildContext context, String message, {String title = 'ব্যর্থ হয়েছে!'}) {
  showAppWarningDialog(context, title: title, message: message);
}

void showSuccessPopup(
  BuildContext context,
  String message, {
  String title = 'সফল হয়েছে!',
  VoidCallback? onConfirm,
}) {
  showAppSuccessDialog(
    context,
    title: title,
    message: message,
    autoDismiss: false,
    onConfirm: onConfirm,
  );
}
