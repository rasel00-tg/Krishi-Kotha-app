import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import 'app_unified_dialog.dart';

export 'app_unified_dialog.dart';

/// কাস্টম ওয়ার্নিং অ্যালার্ট ডায়ালগ (ইউনিফাইড সিস্টেমের সাথে সংযুক্ত)
void showAppWarningDialog(
  BuildContext context, {
  required String message,
  String title = 'সতর্কবার্তা',
  VoidCallback? onConfirm,
}) {
  AppUnifiedDialog.showWarning(
    context,
    title: title,
    message: message,
    onConfirm: onConfirm,
  );
}

/// কাস্টম সাকসেস ডায়ালগ (ইউনিফাইড সিস্টেমের সাথে সংযুক্ত)
void showAppSuccessDialog(
  BuildContext context, {
  required String title,
  required String message,
  VoidCallback? onConfirm,
  bool autoDismiss = true,
}) {
  AppUnifiedDialog.showSuccess(
    context,
    title: title,
    message: message,
    onConfirm: onConfirm,
  );
}

/// অ্যানিমেটেড লাল ক্রস (✗) সংবলিত ফেইলিউর ডায়ালগ (ইউনিফাইড সিস্টেমের সাথে সংযুক্ত)
void showAppFailureDialog(
  BuildContext context, {
  required String message,
  String title = 'ব্যর্থ হয়েছে!',
  VoidCallback? onConfirm,
}) {
  AppUnifiedDialog.showError(
    context,
    title: title,
    message: message,
    onConfirm: onConfirm,
  );
}

/// গ্লোবাল এরর ও সাকসেস পপ-আপ হেল্পার (ক্র্যাশ-প্রুফ ও ইনস্ট্যান্ট টাচ আনব্লকার)
void showErrorPopup(BuildContext context, String message, {String title = 'ব্যর্থ হয়েছে!'}) {
  showAppFailureDialog(context, title: title, message: message);
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

