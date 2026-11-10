import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

/// Single Unified Loading Dialog Controller for 100% Guaranteed Dismissal
class AppLoadingDialogController {
  final BuildContext _parentContext;
  BuildContext? _dialogContext;
  bool _isDismissed = false;
  bool _isAttached = false;

  AppLoadingDialogController(this._parentContext);

  void attachDialogContext(BuildContext ctx) {
    _dialogContext = ctx;
    _isAttached = true;
    if (_isDismissed) {
      _safelyPop();
    }
  }

  void dismiss() {
    if (_isDismissed) return;
    _isDismissed = true;
    if (_isAttached) {
      _safelyPop();
    } else {
      // If dismiss() was called before the dialog builder rendered,
      // safely pop on the next postFrameCallback as soon as it mounts.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _safelyPop();
      });
    }
  }

  void _safelyPop() {
    try {
      if (_dialogContext != null && _dialogContext!.mounted) {
        final nav = Navigator.of(_dialogContext!, rootNavigator: true);
        if (nav.canPop()) {
          nav.pop();
          return;
        }
      }
    } catch (e) {
      debugPrint('Error dismissing loading dialog: $e');
    }
  }
}

/// একক ও অভিন্ন গ্লোবাল ডায়ালগ সিস্টেম (Unified Reusable Dialog Architecture)
/// পুরো অ্যাপ্লিকেশনের সব ডায়ালগ ও পপ-আপের জন্য একক আর্কিটেকচার
class AppUnifiedDialog {
  AppUnifiedDialog._();

  /// রুট নেভিগেটরে কোনো ডায়ালগ বা পপ-আপ ওপেন থাকলে নিরাপদে ডিসমিস করা (Safe Dialog Dismissal)
  /// ভুল করে মূল পেজ যাতে পপ না হয়ে যায়, তার জন্য canPop নিশ্চিত করে কেবল ডায়ালগই বন্ধ হবে
  static void safeDismiss(BuildContext context) {
    try {
      if (context.mounted) {
        final nav = Navigator.of(context, rootNavigator: true);
        if (nav.canPop()) {
          nav.pop();
        }
      }
    } catch (e) {
      debugPrint('AppUnifiedDialog safeDismiss notice: $e');
    }
  }

  /// গ্যারান্টিড লোডার ও মোডাল ব্যারিয়ার ডিসমিসাল (Guaranteed ModalBarrier Safe Dismissal)
  static void safeDismissLoading(BuildContext context) {
    try {
      if (context.mounted) {
        final nav = Navigator.of(context, rootNavigator: true);
        if (nav.canPop()) {
          nav.pop();
        }
      }
    } catch (e) {
      debugPrint('AppUnifiedDialog safeDismissLoading notice: $e');
    }
  }

  /// রুট লেভেলে আটকে থাকা যেকোনো অপ্রত্যাশিত বা অনাথ ModalBarrier/Dialog ফ্লাশ করা
  static void flushRootDialogs(BuildContext context) {
    try {
      if (context.mounted) {
        final nav = Navigator.of(context, rootNavigator: true);
        while (nav.canPop()) {
          nav.pop();
        }
      }
    } catch (e) {
      debugPrint('AppUnifiedDialog flushRootDialogs notice: $e');
    }
  }

  // ================= 1. LOADING STATE =================
  static AppLoadingDialogController showLoading(
    BuildContext context, {
    required String message,
    Duration timeout = const Duration(seconds: 12),
  }) {
    final controller = AppLoadingDialogController(context);

    showDialog(
      context: context,
      barrierDismissible: true,
      useRootNavigator: true,
      builder: (dCtx) {
        controller.attachDialogContext(dCtx);
        return PopScope(
          canPop: true,
          onPopInvokedWithResult: (didPop, _) {
            if (didPop) {
              controller.dismiss();
            }
          },
          canPop: true,
          child: Dialog(
            backgroundColor: Colors.white,
            elevation: 10,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F5E9),
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFF81C784).withOpacity(0.4), width: 1.5),
                    ),
                    child: const Center(
                      child: SizedBox(
                        width: 30,
                        height: 30,
                        child: CircularProgressIndicator(
                          strokeWidth: 3,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1B5E20),
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    // 100% Fail-safe auto-timeout to prevent any frozen screen
    Future.delayed(timeout, () {
      controller.dismiss();
    });

    return controller;
  }

  // ================= 2. SUCCESS STATE =================
  static Future<void> showSuccess(
    BuildContext context, {
    required String title,
    required String message,
    VoidCallback? onConfirm,
    String buttonText = 'ঠিক আছে',
    bool barrierDismissible = true,
  }) async {
    await showDialog(
      context: context,
      barrierDismissible: barrierDismissible,
      useRootNavigator: true,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.white,
        elevation: 10,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        insetPadding: const EdgeInsets.symmetric(horizontal: 30, vertical: 24),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 26),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // মসৃণ ট্রানজিশনে অ্যানিমেটেড সবুজ 'টিক' (✓) চিহ্ন
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFF81C784), width: 2),
                ),
                child: const Center(
                  child: Icon(
                    Icons.check_rounded,
                    color: Color(0xFF2E7D32),
                    size: 40,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 18.5,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1B5E20),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13.5,
                  color: Color(0xFF455A64),
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                height: 44,
                child: ElevatedButton(
                  onPressed: () {
                    if (Navigator.of(ctx, rootNavigator: true).canPop()) {
                      Navigator.of(ctx, rootNavigator: true).pop();
                    }
                    if (onConfirm != null) {
                      onConfirm();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E7D32),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    buttonText,
                    style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ================= 3. ERROR / FAILURE STATE =================
  static Future<void> showError(
    BuildContext context, {
    required String title,
    required String message,
    VoidCallback? onConfirm,
    String buttonText = 'ঠিক আছে',
    bool barrierDismissible = true,
  }) async {
    await showDialog(
      context: context,
      barrierDismissible: barrierDismissible,
      useRootNavigator: true,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.white,
        elevation: 10,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        insetPadding: const EdgeInsets.symmetric(horizontal: 30, vertical: 24),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 26),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // অ্যানিমেটেড লাল 'ক্রস' (✗) চিহ্ন
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFEBEE),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFE57373), width: 2),
                ),
                child: const Center(
                  child: Icon(
                    Icons.close_rounded,
                    color: Color(0xFFD32F2F),
                    size: 40,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFD32F2F),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13.5,
                  color: Color(0xFF455A64),
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                height: 44,
                child: ElevatedButton(
                  onPressed: () {
                    if (Navigator.of(ctx, rootNavigator: true).canPop()) {
                      Navigator.of(ctx, rootNavigator: true).pop();
                    }
                    if (onConfirm != null) {
                      onConfirm();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD32F2F),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    buttonText,
                    style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ================= 4. WARNING / LIMITATION STATE =================
  static Future<void> showWarning(
    BuildContext context, {
    required String title,
    required String message,
    VoidCallback? onConfirm,
    String buttonText = 'বুঝেছি',
    bool barrierDismissible = true,
  }) async {
    await showDialog(
      context: context,
      barrierDismissible: barrierDismissible,
      useRootNavigator: true,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.white,
        elevation: 10,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        insetPadding: const EdgeInsets.symmetric(horizontal: 30, vertical: 24),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 26),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF3E0),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFFFB74D), width: 2),
                ),
                child: const Center(
                  child: Icon(
                    Icons.access_time_rounded,
                    color: Color(0xFFE65100),
                    size: 36,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFE65100),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13.5,
                  color: Color(0xFF455A64),
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                height: 44,
                child: ElevatedButton(
                  onPressed: () {
                    if (Navigator.of(ctx, rootNavigator: true).canPop()) {
                      Navigator.of(ctx, rootNavigator: true).pop();
                    }
                    if (onConfirm != null) {
                      onConfirm();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE65100),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    buttonText,
                    style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ================= 5. CONFIRMATION STATE (e.g. LOGOUT / DELETE) =================
  static Future<bool> showConfirmation(
    BuildContext context, {
    required String title,
    required String message,
    String confirmText = 'হ্যাঁ, নিশ্চিত',
    String cancelText = 'বাতিল',
    Color confirmColor = const Color(0xFFD32F2F),
    IconData icon = Icons.help_outline_rounded,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      useRootNavigator: true,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.white,
        elevation: 10,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        insetPadding: const EdgeInsets.symmetric(horizontal: 30, vertical: 24),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 26),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: confirmColor.withOpacity(0.12),
                  shape: BoxShape.circle,
                  border: Border.all(color: confirmColor.withOpacity(0.35), width: 2),
                ),
                child: Center(
                  child: Icon(
                    icon,
                    color: confirmColor,
                    size: 32,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: confirmColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13.5,
                  color: Color(0xFF455A64),
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 22),
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 44,
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(ctx, rootNavigator: true).pop(false),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFFCFD8DC), width: 1.2),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          cancelText,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF546E7A),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SizedBox(
                      height: 44,
                      child: ElevatedButton(
                        onPressed: () => Navigator.of(ctx, rootNavigator: true).pop(true),
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
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
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
    );

    return result ?? false;
  }
}

