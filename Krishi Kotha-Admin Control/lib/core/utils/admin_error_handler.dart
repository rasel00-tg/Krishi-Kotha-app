import 'package:cloud_firestore/cloud_firestore.dart';

class AdminErrorHandler {
  /// Translates raw Firestore and network errors into clean, friendly Bengali messages.
  static String getFriendlyErrorMessage(dynamic error) {
    if (error == null) return 'একটি অজানা ত্রুটি ঘটেছে।';

    final errStr = error.toString().toLowerCase();

    // Check for FirebaseException
    if (error is FirebaseException) {
      if (error.code == 'permission-denied' ||
          error.message?.toLowerCase().contains('permission') == true) {
        return 'ফায়ারবেস পারমিশন এরর: Firebase Console > Firestore Database > Rules-এ গিয়ে read/write পারমিশন চালু করুন।';
      }
      if (error.code == 'unavailable' || error.code == 'network-request-failed') {
        return 'ইন্টারনেট বা ফায়ারবেস সার্ভার সংযোগ বিচ্ছিন্ন। অনুগ্রহ করে আপনার নেটওয়ার্ক সংযোগ চেক করুন।';
      }
      if (error.code == 'not-found') {
        return 'অনুরোধকৃত তথ্যটি ফায়ারবেস ডেটাবেজে পাওয়া যায়নি।';
      }
    }

    // String based matching
    if (errStr.contains('permission-denied') ||
        errStr.contains('insufficient permissions') ||
        errStr.contains('missing or insufficient permissions')) {
      return 'ফায়ারবেস পারমিশন এরর: Firebase Console > Firestore Database > Rules-এ গিয়ে read/write পারমিশন চালু করুন।';
    }

    if (errStr.contains('network') ||
        errStr.contains('unavailable') ||
        errStr.contains('failed to fetch') ||
        errStr.contains('connection failed')) {
      return 'ইন্টারনেট সংযোগ চেক করুন। ফায়ারবেস সার্ভারের সাথে যোগাযোগ করা যাচ্ছে না।';
    }

    return 'ত্রুটি: ${error.toString().replaceFirst('Exception: ', '')}';
  }
}
