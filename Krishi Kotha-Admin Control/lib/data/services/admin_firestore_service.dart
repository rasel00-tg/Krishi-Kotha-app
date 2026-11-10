import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
        'unit': unit.trim().isNotEmpty ? unit.trim() : 'কেজি',
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

  /// ইউজার পাসওয়ার্ড রিসেট ইমেইল প্রেরণ (Send Official Password Reset Email)
  Future<void> sendPasswordReset(String email, {String? uid}) async {
    if (email.trim().isEmpty) {
      throw Exception('ইউজারের কোনো নিবন্ধিত ইমেইল পাওয়া যায়নি।');
    }
    await FirebaseAuth.instance.sendPasswordResetEmail(email: email.trim());
    if (uid != null && uid.isNotEmpty) {
      final db = _db;
      if (db != null) {
        try {
          await db.collection('users').doc(uid).update({
            'lastPasswordReset': FieldValue.serverTimestamp(),
            'last_password_reset': FieldValue.serverTimestamp(),
            'passwordUpdatedAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          });
        } catch (_) {}
      }
    }
  }

  /// ইউজার সরাসরি পাসওয়ার্ড পরিবর্তন (Direct Password Set - Unified 'password' field)
  Future<void> setUserPasswordDirect(String uid, String newPassword) async {
    final db = _db;
    if (db != null) {
      await db.collection('users').doc(uid).update({
        'password': newPassword.trim(),
        'failedAttempts': 0,
        'lockUntil': null,
        'lastPasswordReset': FieldValue.serverTimestamp(),
        'last_password_reset': FieldValue.serverTimestamp(),
        'passwordUpdatedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
  }

  /// ইউজার লগইন লক রিসেট (Reset Login Lock - Clears failedAttempts & lockUntil)
  Future<void> resetLoginLock(String uid) async {
    final db = _db;
    if (db != null) {
      await db.collection('users').doc(uid).update({
        'failedAttempts': 0,
        'lockUntil': null,
        'status': 'active',
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
  }

  /// ইউজার একাউন্ট আনলক (Manual Unlock Account - Resets failedAttempts & lockUntil)
  Future<void> unlockUserAccount(String uid) => resetLoginLock(uid);

  /// ইউজার প্রোফাইল আপডেট লিমিট রিসেট (Reset 30-Day Edit Limit)
  Future<void> resetProfileUpdateLimit(String uid) async {
    final db = _db;
    if (db != null) {
      await db.collection('users').doc(uid).update({
        'lastProfileUpdate': FieldValue.delete(),
        'last_profile_update': FieldValue.delete(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
  }

  /// ইউজার সাময়িক ব্লক (Temporary Block User)
  Future<void> temporaryBlockUser({
    required String uid,
    required int days,
    required String reason,
  }) async {
    final db = _db;
    if (db != null) {
      final unblockDate = DateTime.now().add(Duration(days: days));
      await db.collection('users').doc(uid).update({
        'status': 'temporary_blocked',
        'blockReason': reason,
        'blockedAt': FieldValue.serverTimestamp(),
        'unblockAt': Timestamp.fromDate(unblockDate),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
  }

  /// ইউজার স্থায়ী সাসপেন্ড (Permanently Suspend User)
  Future<void> permanentlySuspendUser({
    required String uid,
    required String reason,
  }) async {
    final db = _db;
    if (db != null) {
      await db.collection('users').doc(uid).update({
        'status': 'permanently_suspended',
        'suspendReason': reason,
        'suspendedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
  }

  /// ইউজার সক্রিয়করণ / আনব্লক (Activate / Unblock User)
  Future<void> activateUser(String uid) async {
    final db = _db;
    if (db != null) {
      await db.collection('users').doc(uid).update({
        'status': 'active',
        'blockReason': FieldValue.delete(),
        'unblockAt': FieldValue.delete(),
        'suspendReason': FieldValue.delete(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
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
        'adminReply': reply,
        'officerReply': reply,
        'reply': reply,
        'officerName': officerName,
        'status': 'answered',
        'repliedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception(AdminErrorHandler.getFriendlyErrorMessage(e));
    }
  }

  Future<void> updateTicketDecision({
    required String ticketId,
    required String status,
    required String officerName,
    required String reasonOrReply,
  }) async {
    final db = _db;
    if (db == null) throw Exception('ফায়ারবেস ডেটাবেজ সংযুক্ত নেই।');

    try {
      final updateData = <String, dynamic>{
        'status': status,
        'officerName': officerName,
        'updatedAt': FieldValue.serverTimestamp(),
      };
      if (status == 'resolved' || status == 'answered') {
        updateData['adminReply'] = reasonOrReply;
        updateData['officerReply'] = reasonOrReply;
        updateData['reply'] = reasonOrReply;
        updateData['rejectionReason'] = null;
        updateData['resolvedAt'] = FieldValue.serverTimestamp();
      } else {
        updateData['adminReply'] = reasonOrReply;
        updateData['officerReply'] = reasonOrReply;
        updateData['reply'] = reasonOrReply;
        updateData['rejectionReason'] = reasonOrReply;
        updateData['rejectedAt'] = FieldValue.serverTimestamp();
      }
      await db.collection('support_tickets').doc(ticketId).update(updateData);
    } catch (e) {
      throw Exception(AdminErrorHandler.getFriendlyErrorMessage(e));
    }
  }

  Future<void> saveSupportContactSettings({
    required String hotlineTitle,
    required String hotlinePhone,
    required String whatsappTitle,
    required String whatsappPhone,
    required String emailTitle,
    required String emailAddress,
  }) async {
    final db = _db;
    if (db == null) throw Exception('ফায়ারবেস ডেটাবেজ সংযুক্ত নেই।');

    try {
      final data = {
        'hotline_title': hotlineTitle,
        'hotline_phone': hotlinePhone,
        'whatsapp_title': whatsappTitle,
        'whatsapp_phone': whatsappPhone,
        'email_title': emailTitle,
        'email_address': emailAddress,
        'updatedAt': FieldValue.serverTimestamp(),
      };
      await db.collection('app_settings').doc('support_contact').set(data, SetOptions(merge: true));
      await db.collection('settings').doc('support_contact').set(data, SetOptions(merge: true));
    } catch (e) {
      throw Exception(AdminErrorHandler.getFriendlyErrorMessage(e));
    }
  }

  // ==================== 8. APP SETTINGS & PRIVACY POLICY ====================
  /// Real-time stream of privacy policy settings document
  Stream<AdminPrivacyPolicyModel> getPrivacyPolicyStream() {
    final db = _db;
    if (db != null) {
      return db
          .collection('settings')
          .doc('privacy_policy')
          .snapshots()
          .handleError((error) {
            debugPrint('Privacy policy stream notice: ${AdminErrorHandler.getFriendlyErrorMessage(error)}');
          })
          .map((snapshot) {
            if (!snapshot.exists || snapshot.data() == null) {
              return AdminPrivacyPolicyModel.defaultPolicy();
            }
            return AdminPrivacyPolicyModel.fromMap(snapshot.data());
          });
    }
    return Stream.value(AdminPrivacyPolicyModel.defaultPolicy());
  }

  /// Update privacy policy in Firestore settings collection
  Future<void> updatePrivacyPolicy({
    required String content,
    String? bannerText,
    String? lastUpdated,
    String? bannerImageUrl,
    String updatedBy = 'এডমিন',
  }) async {
    final db = _db;
    if (db == null) {
      throw Exception('ফায়ারবেস ডেটাবেজ সংযুক্ত নেই।');
    }

    try {
      final data = <String, dynamic>{
        'policy_content': content.trim(),
        'updated_at': FieldValue.serverTimestamp(),
        'updated_by': updatedBy,
      };

      if (bannerText != null && bannerText.trim().isNotEmpty) {
        data['banner_text'] = bannerText.trim();
      }
      if (lastUpdated != null && lastUpdated.trim().isNotEmpty) {
        data['last_updated'] = lastUpdated.trim();
      }
      if (bannerImageUrl != null) {
        data['banner_image_url'] = bannerImageUrl.trim();
      }

      await db.collection('settings').doc('privacy_policy').set(data, SetOptions(merge: true));
    } catch (e) {
      throw Exception(AdminErrorHandler.getFriendlyErrorMessage(e));
    }
  }
}
