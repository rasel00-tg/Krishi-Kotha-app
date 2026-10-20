import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String name;
  final String phone;
  final String district;
  final String upazila;
  final List<String> preferredCrops;
  final DateTime createdAt;

  const UserModel({
    required this.uid,
    required this.name,
    required this.phone,
    required this.district,
    required this.upazila,
    this.preferredCrops = const [],
    required this.createdAt,
  });

  factory UserModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return UserModel(
      uid: doc.id,
      name: data['name'] as String? ?? 'কৃষক ভাই',
      phone: data['phone'] as String? ?? '',
      district: data['district'] as String? ?? 'ঢাকা',
      upazila: data['upazila'] as String? ?? '',
      preferredCrops: List<String>.from(data['preferred_crops'] ?? []),
      createdAt: (data['createdAt'] is Timestamp)
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  factory UserModel.fromMap(Map<String, dynamic> data, String uid) {
    return UserModel(
      uid: uid,
      name: data['name'] as String? ?? 'কৃষক ভাই',
      phone: data['phone'] as String? ?? '',
      district: data['district'] as String? ?? 'ঢাকা',
      upazila: data['upazila'] as String? ?? '',
      preferredCrops: List<String>.from(data['preferred_crops'] ?? []),
      createdAt: (data['createdAt'] is Timestamp)
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'phone': phone,
      'district': district,
      'upazila': upazila,
      'preferred_crops': preferredCrops,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  UserModel copyWith({
    String? uid,
    String? name,
    String? phone,
    String? district,
    String? upazila,
    List<String>? preferredCrops,
    DateTime? createdAt,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      district: district ?? this.district,
      upazila: upazila ?? this.upazila,
      preferredCrops: preferredCrops ?? this.preferredCrops,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
