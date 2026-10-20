import 'package:cloud_firestore/cloud_firestore.dart';

class SupportTicketModel {
  final String ticketId;
  final String authorId;
  final String authorName;
  final String authorPhone;
  final String district;
  final String upazila;
  final String subject;
  final String details;
  final String? imageUrl;
  final String status; // 'pending', 'answered', 'closed'
  final String? officerReply;
  final String? officerName;
  final DateTime timestamp;

  const SupportTicketModel({
    required this.ticketId,
    required this.authorId,
    required this.authorName,
    required this.authorPhone,
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
    return SupportTicketModel(
      ticketId: doc.id,
      authorId: data['authorId'] as String? ?? '',
      authorName: data['authorName'] as String? ?? 'কৃষক ভাই',
      authorPhone: data['authorPhone'] as String? ?? '',
      district: data['district'] as String? ?? '',
      upazila: data['upazila'] as String? ?? '',
      subject: data['subject'] as String? ?? '',
      details: data['details'] as String? ?? '',
      imageUrl: data['imageUrl'] as String?,
      status: data['status'] as String? ?? 'pending',
      officerReply: data['officerReply'] as String?,
      officerName: data['officerName'] as String?,
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
      'district': district,
      'upazila': upazila,
      'subject': subject,
      'details': details,
      'imageUrl': imageUrl,
      'status': status,
      'officerReply': officerReply,
      'officerName': officerName,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }
}
