import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// Bangladesh Geo API v2.0 আইটেম মডেল (Division, District, Upazila, Union)
class BdGeoItem {
  final String id;
  final String name;
  final String bnName;
  final String? parentId;

  const BdGeoItem({
    required this.id,
    required this.name,
    required this.bnName,
    this.parentId,
  });

  factory BdGeoItem.fromJson(Map<String, dynamic> json) {
    return BdGeoItem(
      id: (json['id'] ?? '').toString().trim(),
      name: (json['name'] ?? '').toString().trim(),
      bnName: (json['bn_name'] ?? json['bnName'] ?? json['name'] ?? '').toString().trim(),
      parentId: (json['division_id'] ?? json['district_id'] ?? json['upazila_id'])?.toString().trim(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'bn_name': bnName,
        if (parentId != null) 'parent_id': parentId,
      };
}

/// Bangladesh Geo API v2.0 সার্ভিস (In-Memory + SharedPreferences 7-Day TTL Cache)
class BdGeoApiService {
  BdGeoApiService._();

  static const String baseUrl = 'https://bdapis.pro.bd/geo/v2.0';
  static const int _ttlMs = 7 * 24 * 60 * 60 * 1000; // 7 days
  static const String _cachePrefix = 'kk_bd_geo_v2_';

  static final Map<String, List<BdGeoItem>> _memCache = {};

  static Future<List<BdGeoItem>> getDivisions({bool forceRefresh = false}) {
    return _fetchCached('divisions', '$baseUrl/divisions', forceRefresh: forceRefresh);
  }

  static Future<List<BdGeoItem>> getAllDistricts({bool forceRefresh = false}) {
    return _fetchCached('districts_all', '$baseUrl/districts', forceRefresh: forceRefresh);
  }

  static Future<List<BdGeoItem>> getDistrictsByDivision(String divisionId, {bool forceRefresh = false}) {
    final cleanId = divisionId.trim();
    if (cleanId.isEmpty) return getAllDistricts(forceRefresh: forceRefresh);
    return _fetchCached('districts_div_$cleanId', '$baseUrl/districts/$cleanId', forceRefresh: forceRefresh);
  }

  static Future<List<BdGeoItem>> getAllUpazilas({bool forceRefresh = false}) {
    return _fetchCached('upazilas_all', '$baseUrl/upazilas', forceRefresh: forceRefresh);
  }

  static Future<List<BdGeoItem>> getUpazilasByDistrict(String districtId, {bool forceRefresh = false}) {
    final cleanId = districtId.trim();
    if (cleanId.isEmpty) return Future.value([]);
    return _fetchCached('upazilas_dist_$cleanId', '$baseUrl/upazilas/$cleanId', forceRefresh: forceRefresh);
  }

  static Future<List<BdGeoItem>> getUnionsByUpazila(String upazilaId, {bool forceRefresh = false}) {
    final cleanId = upazilaId.trim();
    if (cleanId.isEmpty) return Future.value([]);
    return _fetchCached('unions_upa_$cleanId', '$baseUrl/unions/$cleanId', forceRefresh: forceRefresh);
  }

  /// প্রোফাইলের জেলার নাম (বাংলা বা ইংরেজি) থেকে সঠিক BdGeoItem খুঁজে বের করে
  static Future<BdGeoItem?> findDistrictByName(String? districtQuery) async {
    final q = (districtQuery ?? '').trim().toLowerCase();
    if (q.isEmpty) return null;
    final cleanQ = q.replaceAll('জেলা', '').replaceAll('district', '').trim();
    try {
      final all = await getAllDistricts();
      for (final d in all) {
        if (d.bnName.toLowerCase() == cleanQ ||
            d.name.toLowerCase() == cleanQ ||
            d.bnName.toLowerCase().contains(cleanQ) ||
            cleanQ.contains(d.bnName.toLowerCase())) {
          return d;
        }
      }
    } catch (e) {
      debugPrint('findDistrictByName notice: $e');
    }
    return null;
  }

  /// প্রোফাইলের উপজেলার নাম (বাংলা বা ইংরেজি) থেকে সঠিক BdGeoItem খুঁজে বের করে
  static Future<BdGeoItem?> findUpazilaByName(String districtId, String? upazilaQuery) async {
    final q = (upazilaQuery ?? '').trim().toLowerCase();
    if (q.isEmpty || districtId.isEmpty) return null;
    final cleanQ = q.replaceAll('উপজেলা', '').replaceAll('upazila', '').trim();
    try {
      final list = await getUpazilasByDistrict(districtId);
      for (final u in list) {
        if (u.bnName.toLowerCase() == cleanQ ||
            u.name.toLowerCase() == cleanQ ||
            u.bnName.toLowerCase().contains(cleanQ) ||
            cleanQ.contains(u.bnName.toLowerCase())) {
          return u;
        }
      }
    } catch (e) {
      debugPrint('findUpazilaByName notice: $e');
    }
    return null;
  }

  static Future<List<BdGeoItem>> _fetchCached(
    String cacheKey,
    String url, {
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh && _memCache.containsKey(cacheKey)) {
      return _memCache[cacheKey]!;
    }

    final prefs = await SharedPreferences.getInstance();
    final fullKey = '$_cachePrefix$cacheKey';
    List<BdGeoItem>? staleFallback;

    try {
      final raw = prefs.getString(fullKey);
      if (raw != null && raw.isNotEmpty) {
        final decoded = jsonDecode(raw) as Map<String, dynamic>;
        final ts = (decoded['ts'] as int?) ?? 0;
        final itemsRaw = decoded['items'] as List<dynamic>? ?? [];
        final parsed = itemsRaw
            .whereType<Map<String, dynamic>>()
            .map((e) => BdGeoItem.fromJson(e))
            .where((e) => e.id.isNotEmpty)
            .toList();
        if (parsed.isNotEmpty) {
          staleFallback = parsed;
          if (!forceRefresh && (DateTime.now().millisecondsSinceEpoch - ts) < _ttlMs) {
            _memCache[cacheKey] = parsed;
            return parsed;
          }
        }
      }
    } catch (e) {
      debugPrint('BdGeo cache read notice ($cacheKey): $e');
    }

    try {
      final response = await http
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 12));

      if (response.statusCode == 200) {
        final dynamic decoded = jsonDecode(utf8.decode(response.bodyBytes));
        final dynamic rawList = (decoded is Map<String, dynamic>)
            ? (decoded['data'] ?? [])
            : decoded;

        if (rawList is List) {
          final items = rawList
              .whereType<Map<String, dynamic>>()
              .map((e) => BdGeoItem.fromJson(e))
              .where((e) => e.id.isNotEmpty)
              .toList();

          if (items.isNotEmpty) {
            _memCache[cacheKey] = items;
            try {
              await prefs.setString(
                fullKey,
                jsonEncode({
                  'ts': DateTime.now().millisecondsSinceEpoch,
                  'items': items.map((e) => e.toJson()).toList(),
                }),
              );
            } catch (_) {}
            return items;
          }
        }
      }
      throw Exception('HTTP ${response.statusCode}');
    } catch (e) {
      debugPrint('BdGeo API fetch error ($url): $e');
      if (staleFallback != null && staleFallback.isNotEmpty) {
        _memCache[cacheKey] = staleFallback;
        return staleFallback;
      }
      throw Exception('বাংলাদেশ জিও ডেটা লোড করা যায়নি। ইন্টারনেট সংযোগ পরীক্ষা করুন।');
    }
  }
}
