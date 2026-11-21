import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Singleton Service to control Smart Popup Notification frequency,
/// daily limits, deduplication, and update bypass.
class SmartPopupManager {
  SmartPopupManager._internal();
  static final SmartPopupManager instance = SmartPopupManager._internal();

  static const String keyCounterDate = 'smart_popup_counter_date';
  static const String keyDailyNormalCount = 'smart_popup_daily_normal_count';
  static const String keySeenNormalIds = 'smart_popup_seen_normal_ids';
  static const String keySeenUpdateIds = 'smart_popup_seen_update_ids';

  static const int maxDailyNormalPopups = 5;

  /// In-memory Singleton Locks to prevent duplicate popups across Lifecycle, FCM, and StreamBuilder
  bool _isPopupCurrentlyOpen = false;
  bool _isAcquiringLock = false;
  final Set<String> _inFlightIds = <String>{};

  bool get isPopupCurrentlyOpen => _isPopupCurrentlyOpen;

  /// Helper to get current local date in YYYY-MM-DD format
  String getTodayDateString() {
    final now = DateTime.now();
    final year = now.year.toString().padLeft(4, '0');
    final month = now.month.toString().padLeft(2, '0');
    final day = now.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  /// Evaluates and attempts to acquire a slot to show a popup.
  /// - Normal notifications: Max 5 times per day, never shown again once seen.
  /// - Update notifications: Bypasses daily 5 limit, never consumes normal count, never shown again once seen.
  /// Locks and commits to SharedPreferences immediately before the dialog opens.
  Future<bool> tryAcquirePopupSlot({
    required String notificationId,
    required bool isUpdate,
  }) async {
    final cleanId = notificationId.trim();
    if (cleanId.isEmpty) return false;

    // ১. Synchronous In-memory lock check (যেকোনো await-এর আগে সিঙ্ক্রোনাসলি যাচাই ও ব্লক)
    if (_isPopupCurrentlyOpen || _isAcquiringLock || _inFlightIds.contains(cleanId)) {
      debugPrint('[SmartPopupManager] Blocked: Popup already open, acquiring, or in-flight ($cleanId)');
      return false;
    }

    _isAcquiringLock = true;

    try {
      final prefs = await SharedPreferences.getInstance();
      final todayStr = getTodayDateString();

      // ২. তারিখ পরিবর্তন হলে সাধারণ নোটিফিকেশনের দৈনিক কাউন্টার ০-এ রিসেট
      final savedDate = prefs.getString(keyCounterDate) ?? '';
      int currentDailyCount = prefs.getInt(keyDailyNormalCount) ?? 0;

      if (savedDate != todayStr) {
        currentDailyCount = 0;
        await prefs.setString(keyCounterDate, todayStr);
        await prefs.setInt(keyDailyNormalCount, 0);
      }

      final seenNormalIds = (prefs.getStringList(keySeenNormalIds) ?? <String>[]).toSet();
      final seenUpdateIds = (prefs.getStringList(keySeenUpdateIds) ?? <String>[]).toSet();

      // ৩. নতুন Update Notification লজিক (নিয়ম ৪ ও ৫)
      if (isUpdate) {
        // একই Update Notification একবারের বেশি কখনোই দেখাবে না
        if (seenUpdateIds.contains(cleanId)) {
          debugPrint('[SmartPopupManager] Blocked: Update popup already seen ($cleanId)');
          return false;
        }

        // দৈনিক ৫ বারের সীমা উপেক্ষা করে সঙ্গে সঙ্গে একবার দেখাবে এবং দৈনিক কাউন্টার খরচ করবে না
        _isPopupCurrentlyOpen = true;
        _inFlightIds.add(cleanId);

        seenUpdateIds.add(cleanId);
        await prefs.setStringList(keySeenUpdateIds, seenUpdateIds.toList());
        debugPrint('[SmartPopupManager] Slot acquired for UPDATE popup ($cleanId)');
        return true;
      }

      // ৪. সাধারণ নোটিফিকেশন লজিক (নিয়ম ১ ও ২)
      // একই Notification ID একবারের বেশি কখনোই দেখাবে না
      if (seenNormalIds.contains(cleanId)) {
        debugPrint('[SmartPopupManager] Blocked: Normal popup already seen ($cleanId)');
        return false;
      }

      // সাধারণ নোটিফিকেশন দিনে সর্বোচ্চ ৫ বার দেখাবে (Daily limit = 5)
      if (currentDailyCount >= maxDailyNormalPopups) {
        debugPrint('[SmartPopupManager] Blocked: Daily normal limit reached ($currentDailyCount/$maxDailyNormalPopups)');
        return false;
      }

      // স্লট অধিগ্রহণ ও লক কার্যকর
      _isPopupCurrentlyOpen = true;
      _inFlightIds.add(cleanId);

      // দৈনিক কাউন্টার বৃদ্ধি ও দেখা হওয়া আইডি পার্মানেন্ট সেভ
      currentDailyCount += 1;
      await prefs.setInt(keyDailyNormalCount, currentDailyCount);
      seenNormalIds.add(cleanId);
      await prefs.setStringList(keySeenNormalIds, seenNormalIds.toList());

      debugPrint('[SmartPopupManager] Slot acquired for NORMAL popup ($cleanId). Count: $currentDailyCount/$maxDailyNormalPopups');
      return true;
    } catch (e) {
      debugPrint('[SmartPopupManager] Error checking popup slot: $e');
      return false;
    } finally {
      _isAcquiringLock = false;
    }
  }

  /// ডায়ালগ বন্ধ হলে ইন-মেমোরি লক মুক্ত করে
  void releasePopupSlot(String notificationId) {
    final cleanId = notificationId.trim();
    _inFlightIds.remove(cleanId);
    _isPopupCurrentlyOpen = false;
    _isAcquiringLock = false;
    debugPrint('[SmartPopupManager] Released popup slot for ($cleanId)');
  }

  /// ডকুমেন্টের ডাটা থেকে ইউনিক ও ডিটারমিনিস্টিক Notification ID বের করার হেল্পার
  static String extractNotificationId(Map<String, dynamic> data) {
    final explicitId = (data['notificationId'] ?? data['id'])?.toString().trim();
    if (explicitId != null && explicitId.isNotEmpty) {
      return explicitId;
    }
    final rawUpdatedAt = data['updatedAt'];
    String tsPart = '';
    if (rawUpdatedAt is Timestamp) {
      tsPart = rawUpdatedAt.millisecondsSinceEpoch.toString();
    } else if (rawUpdatedAt != null) {
      tsPart = rawUpdatedAt.toString().trim();
    }
    final imgPart = (data['imageUrl'] ?? data['image'] ?? data['photoUrl'] ?? '').toString().trim();
    final headlinePart = (data['headline'] ?? '').toString().trim();
    final combined = '${tsPart}_${imgPart}_$headlinePart';
    return 'popup_${combined.hashCode.abs()}';
  }

  /// ডাটাটি Update Notification কিনা যাচাই করার হেল্পার
  static bool checkIsUpdate(Map<String, dynamic> data) {
    if (data['isUpdate'] == true) return true;
    final type = data['type']?.toString().toLowerCase().trim();
    if (type == 'update') return true;
    final category = data['category']?.toString().toLowerCase().trim();
    if (category == 'update') return true;
    return false;
  }
}
