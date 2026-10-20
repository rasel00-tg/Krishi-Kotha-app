import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseErrorHandler {
  static String getFriendlyErrorMessage(dynamic error) {
    if (error == null) return 'একটি অজানা সমস্যা হয়েছে।';

    final errStr = error.toString().toLowerCase();

    if (error is FirebaseException) {
      if (error.code == 'permission-denied' ||
          error.message?.toLowerCase().contains('permission') == true) {
        return 'ফায়ারবেস পারমিশন এরর: Firebase Console > Firestore Database > Rules-এ গিয়ে read/write পারমিশন চালু করুন।';
      }
      if (error.code == 'unavailable' || error.code == 'network-request-failed') {
        return 'ইন্টারনেট সংযোগ চেক করুন। ফায়ারবেস সার্ভার বর্তমানে পাওয়া যাচ্ছে না।';
      }
      if (error.code == 'not-found') {
        return 'অনুরোধকৃত তথ্যটি ডেটাবেজে পাওয়া যায়নি।';
      }
    }

    if (errStr.contains('permission-denied') ||
        errStr.contains('insufficient permissions') ||
        errStr.contains('missing or insufficient permissions')) {
      return 'ফায়ারবেস পারমিশন এরর: Firebase Console > Firestore Database > Rules-এ গিয়ে read/write পারমিশন চালু করুন।';
    }

    if (errStr.contains('network') || errStr.contains('unavailable')) {
      return 'ইন্টারনেট সংযোগ বিচ্ছিন্ন। অনুগ্রহ করে আপনার নেটওয়ার্ক চেক করুন।';
    }

    return 'ত্রুটি: ${error.toString().replaceFirst('Exception: ', '')}';
  }
}
