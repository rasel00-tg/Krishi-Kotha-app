import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// সার্ভিস: বাজার দর পছন্দের তালিকা ব্যবস্থাপনা (Strict Unique ID)
class MarketFavoritesService {
  static const String _key = 'market_favorite_ids';
  static final ValueNotifier<List<String>> favoriteIdsNotifier = ValueNotifier<List<String>>([]);
  static bool _initialized = false;

  /// ইনিশিয়ালাইজেশন: লোকাল স্টোরেজ থেকে ইউনিক আইডি লোড করা
  static Future<void> init() async {
    if (_initialized) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final rawList = prefs.getStringList(_key) ?? [];
      
      // ডুপ্লিকেট দূর করে শুধুমাত্র ইউনিক আইডি সংরক্ষণ
      final uniqueSet = <String>{};
      for (final id in rawList) {
        final clean = id.trim();
        if (clean.isNotEmpty) {
          uniqueSet.add(clean);
        }
      }
      favoriteIdsNotifier.value = uniqueSet.toList();
      _initialized = true;
    } catch (e) {
      debugPrint('MarketFavoritesService init error: $e');
    }
  }

  /// কোনো আইটেম ফেভারিট কিনা যাচাই (Async)
  static Future<bool> isFavorite(String id) async {
    await init();
    return isFavoriteSync(id);
  }

  /// সিঙ্ক ভ্যালিডেশন (ValueNotifier থেকে সরাসরি)
  static bool isFavoriteSync(String id) {
    final cleanId = id.trim();
    if (cleanId.isEmpty) return false;
    return favoriteIdsNotifier.value.contains(cleanId);
  }

  /// টগল ফেভারিট (ডুপ্লিকেট প্রতিরোধ সহ স্ট্রিক্ট ইউনিক টগল)
  /// রিটার্ন: true হলে যুক্ত হয়েছে, false হলে বাদ দেওয়া হয়েছে
  static Future<bool> toggleFavorite(String id) async {
    await init();
    final cleanId = id.trim();
    if (cleanId.isEmpty) return false;

    try {
      final prefs = await SharedPreferences.getInstance();
      final Set<String> uniqueSet = favoriteIdsNotifier.value
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toSet();

      final bool isAdded;
      // স্ট্রিক্ট ইউনিকনেস চেক
      if (uniqueSet.contains(cleanId)) {
        uniqueSet.remove(cleanId);
        isAdded = false;
      } else {
        uniqueSet.add(cleanId);
        isAdded = true;
      }

      final updatedList = uniqueSet.toList();
      await prefs.setStringList(_key, updatedList);
      favoriteIdsNotifier.value = updatedList;
      return isAdded;
    } catch (e) {
      debugPrint('MarketFavoritesService toggle error: $e');
      final Set<String> fallbackSet = favoriteIdsNotifier.value
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toSet();
      final bool isAdded;
      if (fallbackSet.contains(cleanId)) {
        fallbackSet.remove(cleanId);
        isAdded = false;
      } else {
        fallbackSet.add(cleanId);
        isAdded = true;
      }
      favoriteIdsNotifier.value = fallbackSet.toList();
      return isAdded;
    }
  }

  /// ফেভারিট থেকে সুনির্দিষ্টভাবে বাদ দেওয়া (Remove)
  static Future<bool> removeFavorite(String id) async {
    await init();
    final cleanId = id.trim();
    if (cleanId.isEmpty) return false;

    try {
      final prefs = await SharedPreferences.getInstance();
      final Set<String> uniqueSet = favoriteIdsNotifier.value
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toSet();

      if (uniqueSet.remove(cleanId)) {
        final updatedList = uniqueSet.toList();
        await prefs.setStringList(_key, updatedList);
        favoriteIdsNotifier.value = updatedList;
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('MarketFavoritesService remove error: $e');
      final Set<String> fallbackSet = favoriteIdsNotifier.value
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toSet();
      if (fallbackSet.remove(cleanId)) {
        favoriteIdsNotifier.value = fallbackSet.toList();
        return true;
      }
      return false;
    }
  }

  /// ফেভারিট আইডিগুলোর আনমডিফায়েবল তালিকা
  static List<String> getFavoriteIds() {
    return List.unmodifiable(favoriteIdsNotifier.value);
  }
}
