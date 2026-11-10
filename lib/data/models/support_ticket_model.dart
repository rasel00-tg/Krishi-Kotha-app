import 'package:cloud_firestore/cloud_firestore.dart';

class SupportTicketModel {
  final String ticketId;
  final String authorId;
  final String authorName;
  final String authorPhone;
  final String? authorEmail;
  final String district;
  final String upazila;
  final String subject;
  final String details;
  final String? imageUrl;
  final String status; // 'pending', 'answered', 'closed'
  final String? officerReply;
  final String? officerName;
  final DateTime timestamp;

  // Standard schema getters for forward & backward compatibility
  String get userId => authorId;
  String get userName => authorName;
  String get userPhone => authorPhone;
  String? get userEmail => authorEmail;
  String get category => subject;
  String get message => details;
  String? get adminReply => officerReply;

  const SupportTicketModel({
    required this.ticketId,
    required this.authorId,
    required this.authorName,
    required this.authorPhone,
    this.authorEmail,
    required this.district,
    required this.upazila,
    required this.subject,
    required this.details,
    this.imageUrl,
    this.status = 'pending',
    this.officerReply,
    this.officerName,
    required this.timestamp,
  });

  factory SupportTicketModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    DateTime parsedTime = DateTime.now();
    final ts = data['createdAt'] ?? data['timestamp'];
    if (ts is Timestamp) {
      parsedTime = ts.toDate();
    } else if (ts is String) {
      parsedTime = DateTime.tryParse(ts) ?? DateTime.now();
    }

    return SupportTicketModel(
      ticketId: (data['ticketId'] ?? doc.id).toString(),
      authorId: (data['userId'] ?? data['authorId'] ?? '').toString(),
      authorName: (data['userName'] ?? data['authorName'] ?? 'কৃষক ভাই').toString(),
      authorPhone: (data['userPhone'] ?? data['authorPhone'] ?? '').toString(),
      authorEmail: data['userEmail'] as String? ?? data['authorEmail'] as String?,
      district: (data['district'] ?? '').toString(),
      upazila: (data['upazila'] ?? '').toString(),
      subject: (data['category'] ?? data['subject'] ?? 'সহায়তা অনুসন্ধান').toString(),
      details: (data['message'] ?? data['details'] ?? '').toString(),
      imageUrl: data['imageUrl'] as String?,
      status: (data['status'] ?? 'pending').toString(),
      officerReply: (data['adminReply'] ?? data['officerReply'] ?? data['reply']) as String?,
      officerName: (data['officerName'] ?? '').toString(),
      timestamp: parsedTime,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'ticketId': ticketId,
      'userId': authorId,
      'authorId': authorId,
      'userName': authorName,
      'authorName': authorName,
      'userPhone': authorPhone,
      'authorPhone': authorPhone,
      if (authorEmail != null && authorEmail!.isNotEmpty) 'userEmail': authorEmail,
      if (authorEmail != null && authorEmail!.isNotEmpty) 'authorEmail': authorEmail,
      'district': district,
      'upazila': upazila,
      'category': subject,
      'subject': subject,
      'message': details,
      'details': details,
      'imageUrl': imageUrl,
      'status': status,
      'adminReply': officerReply ?? '',
      'officerReply': officerReply,
      'officerName': officerName,
      'createdAt': Timestamp.fromDate(timestamp),
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }
}
