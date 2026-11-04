import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String name;
  final String email;
  final String phone;
  final String district;
  final String upazila;
  final String village;
  final String occupation;
  final List<String> preferredCrops;
  final DateTime createdAt;

  String get userId => uid;

  const UserModel({
    required this.uid,
    required this.name,
    this.email = '',
    required this.phone,
    required this.district,
    required this.upazila,
    this.village = '',
    this.occupation = 'কৃষক',
    this.preferredCrops = const [],
    required this.createdAt,
  });

  factory UserModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return UserModel(
      uid: doc.id,
      name: data['name'] as String? ?? 'কৃষক ভাই',
      email: data['email'] as String? ?? '',
      phone: data['phone'] as String? ?? '',
      district: data['district'] as String? ?? 'ঢাকা',
      upazila: data['upazila'] as String? ?? '',
      village: data['village'] as String? ?? data['village_name'] as String? ?? '',
      occupation: data['occupation'] as String? ?? 'কৃষক',
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
      email: data['email'] as String? ?? '',
      phone: data['phone'] as String? ?? '',
      district: data['district'] as String? ?? 'ঢাকা',
      upazila: data['upazila'] as String? ?? '',
      village: data['village'] as String? ?? data['village_name'] as String? ?? '',
      occupation: data['occupation'] as String? ?? 'কৃষক',
      preferredCrops: List<String>.from(data['preferred_crops'] ?? []),
      createdAt: (data['createdAt'] is Timestamp)
          ? (data['createdAt'] as Timestamp).toDate()
          : (data['createdAt'] is String ? DateTime.tryParse(data['createdAt']) ?? DateTime.now() : DateTime.now()),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'phone': phone,
      'district': district,
      'upazila': upazila,
      'village': village,
      'village_name': village,
      'occupation': occupation,
      'preferred_crops': preferredCrops,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  UserModel copyWith({
    String? uid,
    String? name,
    String? email,
    String? phone,
    String? district,
    String? upazila,
    String? village,
    String? occupation,
    List<String>? preferredCrops,
    DateTime? createdAt,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      district: district ?? this.district,
      upazila: upazila ?? this.upazila,
      village: village ?? this.village,
      occupation: occupation ?? this.occupation,
      preferredCrops: preferredCrops ?? this.preferredCrops,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
