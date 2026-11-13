import 'dart:async';
import 'package:flutter/foundation.dart';

/// গ্লোবাল স্ক্রিন-ব্লকিং লোডিং কন্ট্রোলার (Global Non-Dismissible Loading Overlay Controller)
/// এডমিন প্যানেলের যেকোনো পেজ বা ট্যাব থেকে ট্রিগার ও ডিসমিস করা যায়।
class AdminLoadingController {
  AdminLoadingController._();
  static final AdminLoadingController instance = AdminLoadingController._();

  final ValueNotifier<bool> isLoading = ValueNotifier<bool>(false);
  final ValueNotifier<String> loadingMessage = ValueNotifier<String>('তথ্য লোডিং হচ্ছে...');
  Timer? _timeoutTimer;

  /// গ্লোবাল নন-ডিসমিসিবল স্ক্রিন ব্লকিং লোডিং চালু করার ফাংশন
  /// সেফটি টাইমআউট ফায়ারওয়াল সহ (যাতে কোনো অবস্থাতেই পার্মানেন্ট লক না হয়)
  void show({
    String message = 'তথ্য লোডিং হচ্ছে...',
    Duration timeout = const Duration(seconds: 8),
  }) {
    _timeoutTimer?.cancel();
    loadingMessage.value = message;
    isLoading.value = true;

    // Safety timeout firewall to prevent permanent screen freeze
    _timeoutTimer = Timer(timeout, () {
      if (isLoading.value) {
        debugPrint('[AdminLoadingController] Safety timeout triggered ($timeout). Auto-dismissing.');
        safeDismiss();
      }
    });
  }

  /// নিরাপদে লোডিং বন্ধ করার ফাংশন (try-catch-finally ফ্রেন্ডলি)
  void safeDismiss() {
    _timeoutTimer?.cancel();
    _timeoutTimer = null;
    if (isLoading.value) {
      isLoading.value = false;
    }
  }

  void hide() => safeDismiss();
}

/// গ্লোবাল লোডিং চালু করার টপ-লেভেল শর্টকাট
void showGlobalAdminLoading({
  String message = 'তথ্য লোডিং হচ্ছে...',
  Duration timeout = const Duration(seconds: 8),
}) {
  AdminLoadingController.instance.show(message: message, timeout: timeout);
}

/// গ্লোবাল লোডিং বন্ধ করার টপ-লেভেল নিরাপদ শর্টকাট
void safeDismissAdminLoading() {
  AdminLoadingController.instance.safeDismiss();
}

