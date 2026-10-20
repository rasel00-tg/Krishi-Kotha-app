import 'package:cloud_firestore/cloud_firestore.dart';

class CommunityPostModel {
  final String postId;
  final String authorId;
  final String authorName;
  final String authorPhone;
  final String content;
  final String? imageUrl;
  final int likesCount;
  final int commentsCount;
  final List<String> likedBy;
  final DateTime timestamp;

  const CommunityPostModel({
    required this.postId,
    required this.authorId,
    required this.authorName,
    required this.authorPhone,
    required this.content,
    this.imageUrl,
    this.likesCount = 0,
    this.commentsCount = 0,
    this.likedBy = const [],
    required this.timestamp,
  });

  factory CommunityPostModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return CommunityPostModel(
      postId: doc.id,
      authorId: data['authorId'] as String? ?? '',
      authorName: data['authorName'] as String? ?? 'কৃষক ভাই',
      authorPhone: data['authorPhone'] as String? ?? '',
      content: data['content'] as String? ?? '',
      imageUrl: data['imageUrl'] as String?,
      likesCount: (data['likesCount'] as num?)?.toInt() ?? 0,
      commentsCount: (data['commentsCount'] as num?)?.toInt() ?? 0,
      likedBy: List<String>.from(data['likedBy'] ?? []),
      timestamp: (data['timestamp'] is Timestamp)
          ? (data['timestamp'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  factory CommunityPostModel.fromMap(Map<String, dynamic> data, String id) {
    return CommunityPostModel(
      postId: id,
      authorId: data['authorId'] as String? ?? '',
      authorName: data['authorName'] as String? ?? 'কৃষক ভাই',
      authorPhone: data['authorPhone'] as String? ?? '',
      content: data['content'] as String? ?? '',
      imageUrl: data['imageUrl'] as String?,
      likesCount: (data['likesCount'] as num?)?.toInt() ?? 0,
      commentsCount: (data['commentsCount'] as num?)?.toInt() ?? 0,
      likedBy: List<String>.from(data['likedBy'] ?? []),
      timestamp: (data['timestamp'] is Timestamp)
          ? (data['timestamp'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'authorId': authorId,
      'authorName': authorName,
      'authorPhone': authorPhone,
      'content': content,
      'imageUrl': imageUrl,
      'likesCount': likesCount,
      'commentsCount': commentsCount,
      'likedBy': likedBy,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }

  CommunityPostModel copyWith({
    String? postId,
    String? authorId,
    String? authorName,
    String? authorPhone,
    String? content,
    String? imageUrl,
    int? likesCount,
    int? commentsCount,
    List<String>? likedBy,
    DateTime? timestamp,
  }) {
    return CommunityPostModel(
      postId: postId ?? this.postId,
      authorId: authorId ?? this.authorId,
      authorName: authorName ?? this.authorName,
      authorPhone: authorPhone ?? this.authorPhone,
      content: content ?? this.content,
      imageUrl: imageUrl ?? this.imageUrl,
      likesCount: likesCount ?? this.likesCount,
      commentsCount: commentsCount ?? this.commentsCount,
      likedBy: likedBy ?? this.likedBy,
      timestamp: timestamp ?? this.timestamp,
    );
  }
}
