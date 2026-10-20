import 'package:cloud_firestore/cloud_firestore.dart';

class CommentModel {
  final String commentId;
  final String authorId;
  final String authorName;
  final String content;
  final DateTime timestamp;

  const CommentModel({
    required this.commentId,
    required this.authorId,
    required this.authorName,
    required this.content,
    required this.timestamp,
  });

  factory CommentModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return CommentModel(
      commentId: doc.id,
      authorId: data['authorId'] as String? ?? '',
      authorName: data['authorName'] as String? ?? 'কৃষক ভাই',
      content: data['content'] as String? ?? '',
      timestamp: (data['timestamp'] is Timestamp)
          ? (data['timestamp'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  factory CommentModel.fromMap(Map<String, dynamic> data, String id) {
    return CommentModel(
      commentId: id,
      authorId: data['authorId'] as String? ?? '',
      authorName: data['authorName'] as String? ?? 'কৃষক ভাই',
      content: data['content'] as String? ?? '',
      timestamp: (data['timestamp'] is Timestamp)
          ? (data['timestamp'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'authorId': authorId,
      'authorName': authorName,
      'content': content,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }
}
