import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import '../models/crop_model.dart';
import '../models/pest_disease_model.dart';
import '../models/market_price_model.dart';
import '../models/community_post_model.dart';
import '../models/comment_model.dart';
import '../models/weather_alert_model.dart';
import '../models/support_ticket_model.dart';
import '../models/notification_model.dart';
import 'firebase_service.dart';
import 'dummy_data_seeder.dart';

class FirestoreService {
  FirebaseFirestore? get _db {
    try {
      if (FirebaseService.isFirebaseInitialized || Firebase.apps.isNotEmpty) {
        return FirebaseFirestore.instance;
      }
    } catch (_) {}
    try {
      return FirebaseFirestore.instance;
    } catch (_) {
      return null;
    }
  }

  // Local reactive streams for offline/fallback mode
  final StreamController<List<CropModel>> _cropsController = StreamController<List<CropModel>>.broadcast();
  final StreamController<List<PestDiseaseModel>> _pestsController = StreamController<List<PestDiseaseModel>>.broadcast();
  final StreamController<List<MarketPriceModel>> _marketController = StreamController<List<MarketPriceModel>>.broadcast();
  final StreamController<List<CommunityPostModel>> _postsController = StreamController<List<CommunityPostModel>>.broadcast();
  final StreamController<List<WeatherAlertModel>> _alertsController = StreamController<List<WeatherAlertModel>>.broadcast();
  final StreamController<List<SupportTicketModel>> _supportController = StreamController<List<SupportTicketModel>>.broadcast();
  final StreamController<List<NotificationModel>> _notificationsController = StreamController<List<NotificationModel>>.broadcast();

  // In-memory fallback caches (Empty by default - no hardcoded dummy data)
  List<CropModel> _fallbackCrops = [];
  List<PestDiseaseModel> _fallbackPests = [];
  List<MarketPriceModel> _fallbackMarket = [];
  List<CommunityPostModel> _fallbackPosts = [];
  List<WeatherAlertModel> _fallbackAlerts = [];
  List<NotificationModel> _fallbackNotifications = [];
  final List<SupportTicketModel> _fallbackTickets = [];
  final Map<String, List<CommentModel>> _fallbackComments = {};

  FirestoreService() {
    // Seed initial broadcast events with empty lists
    _cropsController.add(_fallbackCrops);
    _pestsController.add(_fallbackPests);
    _marketController.add(_fallbackMarket);
    _postsController.add(_fallbackPosts);
    _alertsController.add(_fallbackAlerts);
    _supportController.add(_fallbackTickets);
    _notificationsController.add(_fallbackNotifications);
  }

  /// Retained for API compatibility - no dummy data auto-seeded
  Future<void> seedInitialDataIfEmpty() async {
    // Intentionally no-op to prevent hardcoded dummy data from overwriting real Firestore data
  }

  // ==================== CROPS ====================
  Stream<List<CropModel>> getCropsStream({String? category}) {
    return FirebaseFirestore.instance.collection('crops').snapshots().map((snapshot) {
      if (snapshot.docs.isEmpty) return const [];
      final List<CropModel> list = [];
      for (final doc in snapshot.docs) {
        try {
          list.add(CropModel.fromFirestore(doc));
        } catch (e) {
          debugPrint('CropModel parse error for ${doc.id}: $e');
        }
      }

      // Sort so newest crops appear at the top
      list.sort((a, b) {
        final aTime = a.updatedAt;
        final bTime = b.updatedAt;
        if (aTime != null && bTime != null) return bTime.compareTo(aTime);
        if (aTime != null) return -1;
        if (bTime != null) return 1;
        return 0;
      });

      // Category filter with synonym support
      if (category != null && category.isNotEmpty && category != 'সকল ফসল') {
        list = list.where((c) {
          final cCat = c.category.trim().toLowerCase();
          final target = category.trim().toLowerCase();
          if (cCat == target) return true;
          if (target.contains('দানাদার') && (cCat.contains('দানা') || cCat.contains('cereal'))) return true;
          if (target.contains('সবজি') && (cCat.contains('সবজি') || cCat.contains('vegetable'))) return true;
          if (target.contains('ফল') && (cCat.contains('ফল') || cCat.contains('fruit'))) return true;
          if (target.contains('মসলা') && (cCat.contains('মসলা') || cCat.contains('spice'))) return true;
          if (target.contains('তেল') && (cCat.contains('তেল') || cCat.contains('ডাল') || cCat.contains('oil'))) return true;
          return false;
        }).toList();
      }

      return list;
    });
  }

  // ==================== PESTS & DISEASES ====================
  Stream<List<PestDiseaseModel>> getPestsStream({String? cropId, String? searchQuery}) {
    return FirebaseFirestore.instance.collection('pests_diseases').snapshots().timeout(
      const Duration(seconds: 4),
      onTimeout: (sink) async {
        try {
          final snap = await FirebaseFirestore.instance.collection('pests_diseases').get();
          sink.add(snap);
        } catch (e) {
          sink.addError(e);
        }
      },
    ).map((snapshot) {
      if (snapshot.docs.isEmpty) return const [];
      final List<PestDiseaseModel> list = [];
      for (final doc in snapshot.docs) {
        try {
          list.add(PestDiseaseModel.fromFirestore(doc));
        } catch (e) {
          debugPrint('PestDiseaseModel parse error: $e');
        }
      }

      // Sort so newest pests appear at the top
      list.sort((a, b) {
        final aTime = a.updatedAt;
        final bTime = b.updatedAt;
        if (aTime != null && bTime != null) return bTime.compareTo(aTime);
        if (aTime != null) return -1;
        if (bTime != null) return 1;
        return 0;
      });

      return _filterPests(list, cropId, searchQuery);
    });
  }

  List<PestDiseaseModel> _filterPests(List<PestDiseaseModel> list, String? cropId, String? searchQuery) {
    var result = list;
    if (cropId != null && cropId.isNotEmpty) {
      result = result.where((p) => p.cropId == cropId).toList();
    }
    if (searchQuery != null && searchQuery.trim().isNotEmpty) {
      final q = searchQuery.toLowerCase().trim();
      result = result.where((p) =>
        p.nameBn.toLowerCase().contains(q) ||
        p.cropNameBn.toLowerCase().contains(q) ||
        p.symptoms.toLowerCase().contains(q)
      ).toList();
    }
    return result;
  }

  // ==================== MARKET PRICES ====================
  Stream<List<MarketPriceModel>> getMarketPricesStream({String? district, String? searchQuery}) {
    return FirebaseFirestore.instance
        .collection('market_prices')
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isEmpty) return const [];
      final List<MarketPriceModel> list = [];
      for (final doc in snapshot.docs) {
        try {
          list.add(MarketPriceModel.fromFirestore(doc));
        } catch (e) {
          debugPrint('MarketPriceModel parse error: $e');
        }
      }
      list.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      return _filterMarket(list, district, searchQuery);
    });
  }

  bool _matchDistrict(String? a, String? b) {
    if (a == null || b == null) return false;
    if (a == b) return true;
    final normA = a.replaceAll('ড়', 'ড়').replaceAll('ঢ়', 'ঢ়').replaceAll('য়', 'য়').replaceAll('ণ', 'ন').trim().toLowerCase();
    final normB = b.replaceAll('ড়', 'ড়').replaceAll('ঢ়', 'ঢ়').replaceAll('য়', 'য়').replaceAll('ণ', 'ন').trim().toLowerCase();
    return normA == normB || normA.contains(normB) || normB.contains(normA);
  }

  List<MarketPriceModel> _filterMarket(List<MarketPriceModel> list, String? district, String? searchQuery) {
    var result = list;
    if (district != null &&
        district.trim().isNotEmpty &&
        district.trim() != 'সারাদেশ' &&
        district.trim() != 'সকল জেলা / সারাদেশ' &&
        district.trim() != 'সকল বাজার / সারাদেশ' &&
        district.trim() != 'সকল জেলা' &&
        district.trim() != 'সব জেলা' &&
        district.trim() != 'all' &&
        district.trim() != BangladeshLocationData.allDistrictsOption) {
      result = result.where((m) => _matchDistrict(m.district, district)).toList();
    }
    if (searchQuery != null && searchQuery.trim().isNotEmpty) {
      final q = searchQuery.toLowerCase().trim();
      result = result.where((m) =>
        m.cropName.toLowerCase().contains(q) ||
        m.marketName.toLowerCase().contains(q) ||
        m.district.toLowerCase().contains(q)
      ).toList();
    }
    return result;
  }

  // ==================== COMMUNITY POSTS ====================
  Stream<List<CommunityPostModel>> getCommunityPostsStream() {
    return FirebaseFirestore.instance
        .collection('community_posts')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isEmpty) return const [];
      final List<CommunityPostModel> list = [];
      for (final doc in snapshot.docs) {
        try {
          list.add(CommunityPostModel.fromFirestore(doc));
        } catch (e) {
          debugPrint('CommunityPostModel parse error: $e');
        }
      }
      return list;
    });
  }

  Future<void> createPost({
    required String authorId,
    required String authorName,
    required String authorPhone,
    required String content,
    String? imageUrl,
  }) async {
    final newPost = CommunityPostModel(
      postId: 'post_${DateTime.now().millisecondsSinceEpoch}',
      authorId: authorId,
      authorName: authorName,
      authorPhone: authorPhone,
      content: content,
      imageUrl: imageUrl,
      likesCount: 0,
      commentsCount: 0,
      likedBy: [],
      timestamp: DateTime.now(),
    );

    if (FirebaseService.isFirebaseInitialized && _db != null) {
      await _db.collection('community_posts').doc(newPost.postId).set(newPost.toMap());
    } else {
      _fallbackPosts = [newPost, ..._fallbackPosts];
      _postsController.add(_fallbackPosts);
    }
  }

  Future<void> togglePostLike({
    required String postId,
    required String userId,
  }) async {
    if (FirebaseService.isFirebaseInitialized && _db != null) {
      final postRef = _db.collection('community_posts').doc(postId);
      await _db.runTransaction((transaction) async {
        final snapshot = await transaction.get(postRef);
        if (!snapshot.exists) return;
        final data = snapshot.data() ?? {};
        List<String> likedBy = List<String>.from(data['likedBy'] ?? []);
        int likesCount = (data['likesCount'] as num?)?.toInt() ?? 0;

        if (likedBy.contains(userId)) {
          likedBy.remove(userId);
          likesCount = (likesCount - 1).clamp(0, 999999);
        } else {
          likedBy.add(userId);
          likesCount += 1;
        }

        transaction.update(postRef, {
          'likedBy': likedBy,
          'likesCount': likesCount,
        });
      });
    } else {
      _fallbackPosts = _fallbackPosts.map((post) {
        if (post.postId == postId) {
          final isLiked = post.likedBy.contains(userId);
          final updatedLikedBy = List<String>.from(post.likedBy);
          if (isLiked) {
            updatedLikedBy.remove(userId);
          } else {
            updatedLikedBy.add(userId);
          }
          final newCount = isLiked ? (post.likesCount - 1).clamp(0, 999999) : post.likesCount + 1;
          return post.copyWith(likedBy: updatedLikedBy, likesCount: newCount);
        }
        return post;
      }).toList();
      _postsController.add(_fallbackPosts);
    }
  }

  // ==================== COMMENTS ====================
  Stream<List<CommentModel>> getCommentsStream(String postId) {
    if (FirebaseService.isFirebaseInitialized && _db != null) {
      return _db
          .collection('community_posts')
          .doc(postId)
          .collection('comments')
          .orderBy('timestamp', descending: false)
          .snapshots()
          .map((snapshot) => snapshot.docs.map((doc) => CommentModel.fromFirestore(doc)).toList());
    }

    final list = _fallbackComments[postId] ?? const [];
    return Stream.value(list);
  }

  Future<void> addComment({
    required String postId,
    required String authorId,
    required String authorName,
    required String content,
  }) async {
    final comment = CommentModel(
      commentId: 'comment_${DateTime.now().millisecondsSinceEpoch}',
      authorId: authorId,
      authorName: authorName,
      content: content,
      timestamp: DateTime.now(),
    );

    if (FirebaseService.isFirebaseInitialized && _db != null) {
      await _db
          .collection('community_posts')
          .doc(postId)
          .collection('comments')
          .doc(comment.commentId)
          .set(comment.toMap());

      await _db.collection('community_posts').doc(postId).update({
        'commentsCount': FieldValue.increment(1),
      });
    } else {
      final list = _fallbackComments[postId] ?? [];
      list.add(comment);
      _fallbackComments[postId] = list;

      _fallbackPosts = _fallbackPosts.map((p) {
        if (p.postId == postId) {
          return p.copyWith(commentsCount: p.commentsCount + 1);
        }
        return p;
      }).toList();
      _postsController.add(_fallbackPosts);
    }
  }

  // ==================== WEATHER ALERTS ====================
  Stream<List<WeatherAlertModel>> getWeatherAlertsStream({String? district}) {
    return FirebaseFirestore.instance
        .collection('weather_alerts')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isEmpty) return const [];
      final List<WeatherAlertModel> list = [];
      for (final doc in snapshot.docs) {
        try {
          list.add(WeatherAlertModel.fromFirestore(doc));
        } catch (e) {
          debugPrint('WeatherAlertModel parse error: $e');
        }
      }
      return list;
    });
  }

  // ==================== SUPPORT TICKETS ====================
  Stream<List<SupportTicketModel>> getSupportTicketsStream(String userId) {
    return FirebaseFirestore.instance
        .collection('support_tickets')
        .where('authorId', isEqualTo: userId)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      final List<SupportTicketModel> list = [];
      for (final doc in snapshot.docs) {
        try {
          list.add(SupportTicketModel.fromFirestore(doc));
        } catch (e) {
          debugPrint('SupportTicketModel parse error: $e');
        }
      }
      return list;
    });
  }

  Future<void> submitSupportTicket({
    required String authorId,
    required String authorName,
    required String authorPhone,
    required String district,
    required String upazila,
    required String subject,
    required String details,
    String? imageUrl,
  }) async {
    final ticket = SupportTicketModel(
      ticketId: 'ticket_${DateTime.now().millisecondsSinceEpoch}',
      authorId: authorId,
      authorName: authorName,
      authorPhone: authorPhone,
      district: district,
      upazila: upazila,
      subject: subject,
      details: details,
      imageUrl: imageUrl,
      status: 'pending',
      timestamp: DateTime.now(),
    );

    if (FirebaseService.isFirebaseInitialized && _db != null) {
      await _db.collection('support_tickets').doc(ticket.ticketId).set(ticket.toMap());
    } else {
      _fallbackTickets.insert(0, ticket);
      _supportController.add(_fallbackTickets);
    }
  }

  // ==================== NOTIFICATIONS ====================
  Stream<List<NotificationModel>> getNotificationsStream() {
    return FirebaseFirestore.instance
        .collection('notifications')
        .snapshots()
        .timeout(
          const Duration(seconds: 4),
          onTimeout: (sink) async {
            try {
              final snap = await FirebaseFirestore.instance.collection('notifications').get();
              sink.add(snap);
            } catch (e) {
              sink.addError(e);
            }
          },
        )
        .map((snapshot) {
      if (snapshot.docs.isEmpty) return const [];
      final List<NotificationModel> list = [];
      for (final doc in snapshot.docs) {
        try {
          list.add(NotificationModel.fromFirestore(doc));
        } catch (e) {
          debugPrint('NotificationModel parse error: $e');
        }
      }
      list.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return list;
    });
  }

  Future<void> markNotificationAsSeen(String id) async {
    final db = _db;
    if (db != null) {
      try {
        await db.collection('notifications').doc(id).update({'isSeen': true});
      } catch (e) {
        debugPrint('Error updating notification isSeen in Firestore: $e');
      }
    }

    // Always update reactive local fallback
    _fallbackNotifications = _fallbackNotifications.map((n) {
      if (n.id == id) {
        return n.copyWith(isSeen: true);
      }
      return n;
    }).toList();
    _notificationsController.add(_fallbackNotifications);
  }

  Future<void> markAllNotificationsAsSeen() async {
    final db = _db;
    if (db != null) {
      try {
        final unreadDocs = await db.collection('notifications').where('isSeen', isEqualTo: false).get();
        final batch = db.batch();
        for (final doc in unreadDocs.docs) {
          batch.update(doc.reference, {'isSeen': true});
        }
        await batch.commit();
      } catch (e) {
        debugPrint('Error marking all notifications as seen: $e');
      }
    }

    _fallbackNotifications = _fallbackNotifications.map((n) => n.copyWith(isSeen: true)).toList();
    _notificationsController.add(_fallbackNotifications);
  }

  // ==================== AGRI SERVICES ADVISORIES ====================
  Stream<Map<String, dynamic>> getAgriServiceStream(String serviceId) {
    return FirebaseFirestore.instance
        .collection('agri_services')
        .doc(serviceId)
        .snapshots()
        .map((snapshot) => snapshot.data() ?? {});
  }

  void dispose() {
    _cropsController.close();
    _pestsController.close();
    _marketController.close();
    _postsController.close();
    _alertsController.close();
    _supportController.close();
    _notificationsController.close();
  }
}
