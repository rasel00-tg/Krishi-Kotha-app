import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class NotificationModel {
  final String id;
  final String title;
  final String message;
  final DateTime timestamp;
  final bool isSeen;
  final String type; // 'weather', 'crop', 'market', 'general'
  final String imageUrl;

  const NotificationModel({
    required this.id,
    required this.title,
    required this.message,
    required this.timestamp,
    this.isSeen = false,
    this.type = 'general',
    this.imageUrl = '',
  });

  factory NotificationModel.fromFirestore(DocumentSnapshot doc) {
    try {
      final data = (doc.data() as Map<String, dynamic>?) ?? {};
      return NotificationModel.fromMap(data, doc.id);
    } catch (_) {
      return NotificationModel(
        id: doc.id,
        title: 'নোটিফিকেশন',
        message: '',
        timestamp: DateTime.now(),
        isSeen: false,
        type: 'general',
        imageUrl: '',
      );
    }
  }

  factory NotificationModel.fromMap(Map<String, dynamic> data, String id) {
    DateTime time;
    if (data['timestamp'] is Timestamp) {
      time = (data['timestamp'] as Timestamp).toDate();
    } else if (data['timestamp'] is DateTime) {
      time = data['timestamp'] as DateTime;
    } else if (data['updatedAt'] is Timestamp) {
      time = (data['updatedAt'] as Timestamp).toDate();
    } else if (data['createdAt'] is Timestamp) {
      time = (data['createdAt'] as Timestamp).toDate();
    } else if (data['timestamp'] is String) {
      time = DateTime.tryParse(data['timestamp'] as String) ?? DateTime.now();
    } else if (data['updatedAt'] is String) {
      time = DateTime.tryParse(data['updatedAt'] as String) ?? DateTime.now();
    } else if (data['createdAt'] is String) {
      time = DateTime.tryParse(data['createdAt'] as String) ?? DateTime.now();
    } else if (data['timestamp'] is int) {
      time = DateTime.fromMillisecondsSinceEpoch(data['timestamp'] as int);
    } else if (data['updatedAt'] is int) {
      time = DateTime.fromMillisecondsSinceEpoch(data['updatedAt'] as int);
    } else {
      time = DateTime.now();
    }

    final rawTitle = data['title']?.toString() ?? data['heading']?.toString() ?? data['name']?.toString();
    final rawMsg = data['message']?.toString() ?? data['description']?.toString() ?? data['details']?.toString() ?? data['body']?.toString();
    final rawType = data['type']?.toString();
    final rawImg = data['imageUrl'] ?? data['image_url'] ?? data['image'];
    final imageUrl = (rawImg != null && rawImg.toString().trim().isNotEmpty) ? rawImg.toString().trim() : '';

    return NotificationModel(
      id: (data['id'] ?? id).toString(),
      title: (rawTitle != null && rawTitle.trim().isNotEmpty)
          ? rawTitle.trim()
          : 'নোটিফিকেশন',
      message: rawMsg?.trim() ?? '',
      timestamp: time,
      isSeen: data['isSeen'] == true || data['is_seen'] == true,
      type: (rawType != null && rawType.trim().isNotEmpty) ? rawType.trim() : 'সাধারণ',
      imageUrl: imageUrl,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'heading': title,
      'message': message,
      'description': message,
      'timestamp': Timestamp.fromDate(timestamp),
      'isSeen': isSeen,
      'type': type,
      'imageUrl': imageUrl,
      'image_url': imageUrl,
    };
  }

  NotificationModel copyWith({
    String? id,
    String? title,
    String? message,
    DateTime? timestamp,
    bool? isSeen,
    String? type,
    String? imageUrl,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      timestamp: timestamp ?? this.timestamp,
      isSeen: isSeen ?? this.isSeen,
      type: type ?? this.type,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }

  IconData get icon {
    final t = type.toLowerCase();
    if (t == 'weather' || t.contains('সতর্কতা') || t.contains('আবহাওয়া')) {
      return Icons.thunderstorm_rounded;
    } else if (t == 'crop' || t.contains('ফসল') || t.contains('বালাই')) {
      return Icons.grass_rounded;
    } else if (t == 'market' || t.contains('বাজার') || t.contains('দর')) {
      return Icons.storefront_rounded;
    }
    return Icons.notifications_active_rounded;
  }

  Color get iconColor {
    final t = type.toLowerCase();
    if (t == 'weather' || t.contains('সতর্কতা') || t.contains('আবহাওয়া')) {
      return AppColors.alertWarning;
    } else if (t == 'crop' || t.contains('ফসল') || t.contains('বালাই')) {
      return AppColors.primary;
    } else if (t == 'market' || t.contains('বাজার') || t.contains('দর')) {
      return const Color(0xFF1565C0);
    }
    return const Color(0xFF7B1FA2);
  }

  String get formattedTime {
    final diff = DateTime.now().difference(timestamp);
    if (diff.inMinutes < 60) {
      final mins = diff.inMinutes <= 0 ? 1 : diff.inMinutes;
      return '$mins মিনিট আগে';
    } else if (diff.inHours < 24) {
      return '${diff.inHours} ঘণ্টা আগে';
    } else {
      return '${diff.inDays} দিন আগে';
    }
  }
}
