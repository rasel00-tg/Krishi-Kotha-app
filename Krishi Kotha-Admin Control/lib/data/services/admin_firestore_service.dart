import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../../core/constants/bangladesh_locations.dart';
import '../../core/utils/admin_error_handler.dart';
import '../models/admin_models.dart';
import 'admin_seed_data.dart';

class AdminFirestoreService {
  static final AdminFirestoreService instance = AdminFirestoreService._internal();
  AdminFirestoreService._internal();

  FirebaseFirestore? get _db {
    try {
      return FirebaseFirestore.instance;
    } catch (e) {
      debugPrint('Firestore initialization notice: $e');
      return null;
    }
  }

  // ==================== DATABASE SEEDING ====================
  /// Checks if collections are empty; if so, populates initial real data into Firestore.
  Future<int> seedDatabaseIfEmpty({bool force = false}) async {
    final db = _db;
    if (db == null) {
      throw Exception('ফায়ারবেস ডেটাবেজ সংযুক্ত নেই। অনুগ্রহ করে নেটওয়ার্ক চেক করুন।');
    }

    int seededCount = 0;

    try {
      // 1. Crops Collection
      final cropsSnap = await db.collection('crops').limit(1).get();
      if (cropsSnap.docs.isEmpty || force) {
        final initialCrops = AdminSeedData.getInitialCrops();
        for (final item in initialCrops) {
          final id = item['id'] as String;
          final data = Map<String, dynamic>.from(item);
          data.remove('id');
          data['updatedAt'] = FieldValue.serverTimestamp();
          await db.collection('crops').doc(id).set(data, SetOptions(merge: true));
          seededCount++;
        }
      }

      // 2. Pests & Diseases Collection
      final pestsSnap = await db.collection('pests_diseases').limit(1).get();
      if (pestsSnap.docs.isEmpty || force) {
        final initialPests = AdminSeedData.getInitialPests();
        for (final item in initialPests) {
          final id = item['id'] as String;
          final data = Map<String, dynamic>.from(item);
          data.remove('id');
          data['updatedAt'] = FieldValue.serverTimestamp();
          await db.collection('pests_diseases').doc(id).set(data, SetOptions(merge: true));
          seededCount++;
        }
      }

      // 3. Market Prices Collection
      final marketSnap = await db.collection('market_prices').limit(1).get();
      if (marketSnap.docs.isEmpty || force) {
        final initialPrices = AdminSeedData.getInitialMarketPrices();
        for (final item in initialPrices) {
          final id = item['id'] as String;
          final data = Map<String, dynamic>.from(item);
          data.remove('id');
          data['updatedAt'] = FieldValue.serverTimestamp();
          await db.collection('market_prices').doc(id).set(data, SetOptions(merge: true));
          seededCount++;
        }
      }

      // 4. Notifications Collection
      final notifSnap = await db.collection('notifications').limit(1).get();
      if (notifSnap.docs.isEmpty || force) {
        final initialNotifs = AdminSeedData.getInitialNotifications();
        for (final item in initialNotifs) {
          final id = item['id'] as String;
          final data = Map<String, dynamic>.from(item);
          data.remove('id');
          data['timestamp'] = FieldValue.serverTimestamp();
          await db.collection('notifications').doc(id).set(data, SetOptions(merge: true));
          seededCount++;
        }
      }

      return seededCount;
    } catch (e) {
      debugPrint('Firestore Seeding Notice: $e');
      throw Exception(AdminErrorHandler.getFriendlyErrorMessage(e));
    }
  }

  // ==================== 1. NOTIFICATIONS STREAM & CRUD ====================
  Stream<List<AdminNotificationModel>> getNotificationsStream() {
    final db = _db;
    if (db != null) {
      return db
          .collection('notifications')
          .orderBy('timestamp', descending: true)
          .snapshots()
          .handleError((error) {
            debugPrint('Notifications stream notice: ${AdminErrorHandler.getFriendlyErrorMessage(error)}');
          })
          .map((snapshot) {
            if (snapshot.docs.isEmpty) return const [];
            return snapshot.docs
                .map((doc) => AdminNotificationModel.fromFirestore(doc))
                .toList();
          });
    }
    return Stream.value(const []);
  }

  Future<void> sendNotification({
    required String title,
    required String message,
    required String type,
    String? imageUrl,
  }) async {
    final db = _db;
    if (db == null) {
      throw Exception('ফায়ারবেস ডেটাবেজ সংযুক্ত নেই।');
    }

    try {
      final notifId = 'notif_${DateTime.now().millisecondsSinceEpoch}';
      final data = {
        'id': notifId,
        'title': title,
        'message': message,
        'timestamp': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'isSeen': false,
        'type': type,
        if (imageUrl != null && imageUrl.trim().isNotEmpty) ...{
          'imageUrl': imageUrl.trim(),
          'image_url': imageUrl.trim(),
        },
      };

      await db.collection('notifications').doc(notifId).set(data);
    } catch (e) {
      throw Exception(AdminErrorHandler.getFriendlyErrorMessage(e));
    }
  }

  Future<void> deleteNotification(String id) async {
    final db = _db;
    if (db == null) {
      throw Exception('ফায়ারবেস ডেটাবেজ সংযুক্ত নেই।');
    }
    try {
      await db.collection('notifications').doc(id).delete();
    } catch (e) {
      throw Exception(AdminErrorHandler.getFriendlyErrorMessage(e));
    }
  }

  // ==================== 2. MARKET PRICES STREAM & CRUD ====================
  Stream<List<AdminMarketPriceModel>> getMarketPricesStream({
    String? district,
    String? division,
    String? searchQuery,
  }) {
    final db = _db;
    if (db != null) {
      return db
          .collection('market_prices')
          .orderBy('updatedAt', descending: true)
          .snapshots()
          .handleError((error) {
            debugPrint('Market prices stream notice: ${AdminErrorHandler.getFriendlyErrorMessage(error)}');
          })
          .map((snapshot) {
            if (snapshot.docs.isEmpty) return const [];
            var list = snapshot.docs
                .map((doc) => AdminMarketPriceModel.fromFirestore(doc))
                .toList();

            // 1. Division Filter
            if (division != null && division.isNotEmpty && division != 'সকল বিভাগ') {
              final divDistricts = BangladeshLocations.divisionDistricts[division] ?? [];
              list = list.where((m) =>
                divDistricts.any((d) => BangladeshLocations.matchDistrict(d, m.district))
              ).toList();
            }

            // 2. District Filter
            if (district != null &&
                district.isNotEmpty &&
                district != 'সারাদেশ' &&
                district != 'সকল জেলা' &&
                district != 'সব জেলা' &&
                district != 'সারাদেশ / সকল জেলা') {
              list = list.where((m) =>
                BangladeshLocations.matchDistrict(m.district, district)
              ).toList();
            }

            // 3. Search Query Filter
            if (searchQuery != null && searchQuery.trim().isNotEmpty) {
              final q = searchQuery.trim().toLowerCase();
              list = list.where((m) =>
                m.cropName.toLowerCase().contains(q) ||
                m.marketName.toLowerCase().contains(q) ||
                m.district.toLowerCase().contains(q)
              ).toList();
            }

            return list;
          });
    }
    return Stream.value(const []);
  }

  Future<void> saveMarketPrice({
    String? id,
    required String district,
    required String marketName,
    required String cropName,
    required String unit,
    required double price,
    required double retailPrice,
    required String trend,
    String? imageUrl,
  }) async {
    final db = _db;
    if (db == null) {
      throw Exception('ফায়ারবেস ডেটাবেজ সংযুক্ত নেই।');
    }

    try {
      final itemId = id ?? 'mp_${DateTime.now().millisecondsSinceEpoch}';
      final data = {
        'district': district,
        'market_name': marketName,
        'marketName': marketName,
        'crop_name': cropName,
        'cropName': cropName,
        'unit': unit,
        'price': price,
        'retail_price': retailPrice,
        'retailPrice': retailPrice,
        'trend': trend,
        'updatedAt': FieldValue.serverTimestamp(),
        if (imageUrl != null && imageUrl.trim().isNotEmpty) ...{
          'image_url': imageUrl.trim(),
          'imageUrl': imageUrl.trim(),
        },
      };

      await db.collection('market_prices').doc(itemId).set(data, SetOptions(merge: true));
    } catch (e) {
      throw Exception(AdminErrorHandler.getFriendlyErrorMessage(e));
    }
  }

  Future<void> deleteMarketPrice(String id) async {
    final db = _db;
    if (db == null) {
      throw Exception('ফায়ারবেস ডেটাবেজ সংযুক্ত নেই।');
    }
    try {
      await db.collection('market_prices').doc(id).delete();
    } catch (e) {
      throw Exception(AdminErrorHandler.getFriendlyErrorMessage(e));
    }
  }

  // ==================== 3. CROPS STREAM & CRUD ====================
  Stream<List<AdminCropModel>> getCropsStream() {
    final db = _db;
    if (db != null) {
      return db
          .collection('crops')
          .snapshots()
          .handleError((error) {
            debugPrint('Crops stream notice: ${AdminErrorHandler.getFriendlyErrorMessage(error)}');
          })
          .map((snapshot) {
            if (snapshot.docs.isEmpty) return const [];
            return snapshot.docs
                .map((doc) => AdminCropModel.fromFirestore(doc))
                .toList();
          });
    }
    return Stream.value(const []);
  }

  Future<void> saveCrop({
    String? id,
    required String nameBn,
    required String category,
    required String season,
    required String soilType,
    required String sowingTime,
    required String imageUrl,
  }) async {
    final db = _db;
    if (db == null) {
      throw Exception('ফায়ারবেস ডেটাবেজ সংযুক্ত নেই।');
    }

    try {
      final cropId = (id != null && id.isNotEmpty)
          ? id
          : 'crop_${DateTime.now().millisecondsSinceEpoch}';

      final data = {
        'title': nameBn,
        'name_bn': nameBn,
        'category': category,
        'season': season,
        'soil_type': soilType,
        'soil': soilType,
        'sowing_time': sowingTime,
        'imageUrl': imageUrl,
        'image_url': imageUrl,
        'stages': [],
        'updatedAt': FieldValue.serverTimestamp(),
        'timestamp': FieldValue.serverTimestamp(),
      };

      await db.collection('crops').doc(cropId).set(data, SetOptions(merge: true));

      // Persist dynamic category to categories collection (Single Source of Truth)
      if (category.trim().isNotEmpty) {
        final catId = 'cat_${Uri.encodeComponent(category.trim().toLowerCase().replaceAll(' ', '_'))}';
        await db.collection('categories').doc(catId).set({
          'name': category.trim(),
          'name_bn': category.trim(),
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
    } catch (e) {
      throw Exception(AdminErrorHandler.getFriendlyErrorMessage(e));
    }
  }

  Future<void> deleteCrop(String id) async {
    final db = _db;
    if (db == null) {
      throw Exception('ফায়ারবেস ডেটাবেজ সংযুক্ত নেই।');
    }
    try {
      await db.collection('crops').doc(id).delete();
    } catch (e) {
      throw Exception(AdminErrorHandler.getFriendlyErrorMessage(e));
    }
  }

  // ==================== 4. PESTS STREAM & CRUD ====================
  Stream<List<AdminPestModel>> getPestsStream() {
    final db = _db;
    if (db != null) {
      return db
          .collection('pests_diseases')
          .snapshots()
          .handleError((error) {
            debugPrint('Pests stream notice: ${AdminErrorHandler.getFriendlyErrorMessage(error)}');
          })
          .map((snapshot) {
            if (snapshot.docs.isEmpty) return const [];
            return snapshot.docs
                .map((doc) => AdminPestModel.fromFirestore(doc))
                .toList();
          });
    }
    return Stream.value(const []);
  }

  Future<void> savePest({
    String? id,
    required String cropId,
    required String cropNameBn,
    required String nameBn,
    required String symptoms,
    required String organicCure,
    required String chemicalCure,
    required String precaution,
    required String imageUrl,
  }) async {
    final db = _db;
    if (db == null) {
      throw Exception('ফায়ারবেস ডেটাবেজ সংযুক্ত নেই।');
    }

    try {
      final pestId = (id != null && id.isNotEmpty)
          ? id
          : 'pest_${DateTime.now().millisecondsSinceEpoch}';

      final data = {
        'title': nameBn,
        'name_bn': nameBn,
        'crop_id': cropId,
        'crop_name_bn': cropNameBn,
        'crop_name': cropNameBn,
        'symptoms': symptoms,
        'solution': organicCure,
        'organic_cure': organicCure,
        'chemical_cure': chemicalCure,
        'precaution': precaution,
        'imageUrl': imageUrl,
        'image_url': imageUrl,
        'updatedAt': FieldValue.serverTimestamp(),
        'timestamp': FieldValue.serverTimestamp(),
      };

      await db.collection('pests_diseases').doc(pestId).set(data, SetOptions(merge: true));
    } catch (e) {
      throw Exception(AdminErrorHandler.getFriendlyErrorMessage(e));
    }
  }

  Future<void> deletePest(String id) async {
    final db = _db;
    if (db == null) {
      throw Exception('ফায়ারবেস ডেটাবেজ সংযুক্ত নেই।');
    }
    try {
      await db.collection('pests_diseases').doc(id).delete();
    } catch (e) {
      throw Exception(AdminErrorHandler.getFriendlyErrorMessage(e));
    }
  }

  // ==================== 5. USERS & SUPPORT STREAM ====================
  Stream<List<AdminUserModel>> getUsersStream() {
    final db = _db;
    if (db != null) {
      return db
          .collection('users')
          .orderBy('createdAt', descending: true)
          .snapshots()
          .handleError((error) {
            debugPrint('Users stream notice: ${AdminErrorHandler.getFriendlyErrorMessage(error)}');
          })
          .map((snapshot) {
            if (snapshot.docs.isEmpty) return const [];
            return snapshot.docs
                .map((doc) => AdminUserModel.fromFirestore(doc))
                .toList();
          });
    }
    return Stream.value(const []);
  }

  Stream<List<AdminSupportTicketModel>> getSupportTicketsStream() {
    final db = _db;
    if (db != null) {
      return db
          .collection('support_tickets')
          .orderBy('timestamp', descending: true)
          .snapshots()
          .handleError((error) {
            debugPrint('Support tickets stream notice: ${AdminErrorHandler.getFriendlyErrorMessage(error)}');
          })
          .map((snapshot) {
            if (snapshot.docs.isEmpty) return const [];
            return snapshot.docs
                .map((doc) => AdminSupportTicketModel.fromFirestore(doc))
                .toList();
          });
    }
    return Stream.value(const []);
  }

  Future<void> replyToTicket({
    required String ticketId,
    required String reply,
    required String officerName,
  }) async {
    final db = _db;
    if (db == null) {
      throw Exception('ফায়ারবেস ডেটাবেজ সংযুক্ত নেই।');
    }

    try {
      await db.collection('support_tickets').doc(ticketId).update({
        'officerReply': reply,
        'officerName': officerName,
        'status': 'answered',
        'repliedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception(AdminErrorHandler.getFriendlyErrorMessage(e));
    }
  }
}
