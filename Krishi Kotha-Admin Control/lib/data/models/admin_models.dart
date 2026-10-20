import 'package:cloud_firestore/cloud_firestore.dart';

/// Notification Model for Admin Management
class AdminNotificationModel {
  final String id;
  final String title;
  final String message;
  final DateTime timestamp;
  final bool isSeen;
  final String type; // 'weather', 'crop', 'market', 'general'
  final String imageUrl;

  const AdminNotificationModel({
    required this.id,
    required this.title,
    required this.message,
    required this.timestamp,
    this.isSeen = false,
    this.type = 'general',
    this.imageUrl = '',
  });

  factory AdminNotificationModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    final rawImg = data['imageUrl'] ?? data['image_url'] ?? data['image'];
    return AdminNotificationModel(
      id: doc.id,
      title: data['title'] as String? ?? 'নতুন বিজ্ঞপ্তি',
      message: data['message'] as String? ?? '',
      timestamp: (data['timestamp'] is Timestamp)
          ? (data['timestamp'] as Timestamp).toDate()
          : DateTime.now(),
      isSeen: data['isSeen'] as bool? ?? false,
      type: data['type'] as String? ?? 'general',
      imageUrl: (rawImg != null && rawImg.toString().trim().isNotEmpty) ? rawImg.toString().trim() : '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'message': message,
      'timestamp': Timestamp.fromDate(timestamp),
      'isSeen': isSeen,
      'type': type,
      'imageUrl': imageUrl,
      'image_url': imageUrl,
    };
  }
}

/// Market Price Model for Admin Management
class AdminMarketPriceModel {
  final String id;
  final String district;
  final String marketName;
  final String cropName;
  final String unit; // কেজি, মণ, বস্তা, হালি, কুড়ি
  final double price; // পাইকারি দর
  final double retailPrice; // খুচরা দর
  final String trend; // 'up', 'down', 'stable'
  final String imageUrl;
  final DateTime updatedAt;

  const AdminMarketPriceModel({
    required this.id,
    required this.district,
    required this.marketName,
    required this.cropName,
    required this.unit,
    required this.price,
    this.retailPrice = 0.0,
    this.trend = 'stable',
    this.imageUrl = '',
    required this.updatedAt,
  });

  factory AdminMarketPriceModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    final rawImg = data['imageUrl'] ?? data['image_url'] ?? data['image'] ?? data['img'];
    
    final crop = (data['cropName'] ?? data['crop_name'] ?? data['name'] ?? data['crop'] ?? '').toString().trim();
    final market = (data['marketName'] ?? data['market_name'] ?? data['market'] ?? '').toString().trim();
    final dist = (data['district'] ?? data['district_name'] ?? data['division'] ?? 'ঢাকা').toString().trim();
    final unitVal = (data['unit'] ?? data['unit_name'] ?? 'কেজি').toString().trim();
    
    final p = (data['price'] ?? data['wholesale_price'] ?? data['wholesalePrice'] as num?)?.toDouble() ?? 0.0;
    final rp = (data['retailPrice'] ?? data['retail_price'] as num?)?.toDouble() ?? 0.0;
    final tr = (data['trend'] ?? data['status'] ?? 'stable').toString().trim();

    DateTime time;
    final rawTime = data['updatedAt'] ?? data['updated_at'] ?? data['timestamp'] ?? data['date'];
    if (rawTime is Timestamp) {
      time = rawTime.toDate();
    } else if (rawTime is String) {
      time = DateTime.tryParse(rawTime) ?? DateTime.now();
    } else {
      time = DateTime.now();
    }

    return AdminMarketPriceModel(
      id: doc.id,
      district: dist.isNotEmpty ? dist : 'ঢাকা',
      marketName: market.isNotEmpty ? market : 'স্থানীয় বাজার',
      cropName: crop.isNotEmpty ? crop : 'ফসল',
      unit: unitVal.isNotEmpty ? unitVal : 'কেজি',
      price: p,
      retailPrice: rp,
      trend: tr.isNotEmpty ? tr : 'stable',
      imageUrl: (rawImg != null && rawImg.toString().trim().isNotEmpty) ? rawImg.toString().trim() : '',
      updatedAt: time,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'district': district,
      'market_name': marketName,
      'marketName': marketName,
      'crop_name': cropName,
      'cropName': cropName,
      'unit': unit,
      'price': price,
      'wholesale_price': price,
      'retail_price': retailPrice,
      'retailPrice': retailPrice,
      'trend': trend,
      'imageUrl': imageUrl,
      'image_url': imageUrl,
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }
}

/// Crop Model for Admin Management
class AdminCropModel {
  final String id;
  final String nameBn;
  final String category; // দানাশস্য, সবজি, ফলমূল, মসলা, তৈলবীজ
  final String season; // খরিফ-১, খরিফ-২, রবি
  final String soilType; // দোআঁশ, বেলে দোআঁশ, এটেল ইত্যাদি
  final String sowingTime;
  final String imageUrl;
  final List<dynamic> stages;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const AdminCropModel({
    required this.id,
    required this.nameBn,
    required this.category,
    required this.season,
    required this.soilType,
    this.sowingTime = '',
    this.imageUrl = '',
    this.stages = const [],
    this.createdAt,
    this.updatedAt,
  });

  factory AdminCropModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    DateTime? parseDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val);
      return null;
    }

    return AdminCropModel(
      id: doc.id,
      nameBn: data['title'] as String? ??
          data['name_bn'] as String? ??
          data['heading'] as String? ??
          data['name'] as String? ??
          '',
      category: data['category'] as String? ?? '',
      season: data['season'] as String? ?? '',
      soilType: data['soil_type'] as String? ?? data['soil'] as String? ?? '',
      sowingTime: data['sowing_time'] as String? ?? data['sowing'] as String? ?? '',
      imageUrl: data['imageUrl'] as String? ?? data['image_url'] as String? ?? '',
      stages: (data['stages'] is List) ? (data['stages'] as List) : const [],
      createdAt: parseDate(data['createdAt'] ?? data['created_at'] ?? data['timestamp']),
      updatedAt: parseDate(data['updatedAt'] ?? data['updated_at'] ?? data['timestamp']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': nameBn,
      'name_bn': nameBn,
      'category': category,
      'season': season,
      'soil_type': soilType,
      'soil': soilType,
      'sowing_time': sowingTime,
      'imageUrl': imageUrl,
      'image_url': imageUrl,
      'stages': stages,
      'updatedAt': FieldValue.serverTimestamp(),
      'timestamp': FieldValue.serverTimestamp(),
    };
  }
}

/// Pest & Disease Model for Admin Management
class AdminPestModel {
  final String id;
  final String cropId;
  final String cropNameBn;
  final String nameBn;
  final String symptoms;
  final String organicCure;
  final String chemicalCure;
  final String precaution;
  final String imageUrl;

  const AdminPestModel({
    required this.id,
    required this.cropId,
    this.cropNameBn = '',
    required this.nameBn,
    required this.symptoms,
    required this.organicCure,
    required this.chemicalCure,
    this.precaution = '',
    required this.imageUrl,
  });

  factory AdminPestModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return AdminPestModel(
      id: doc.id,
      cropId: data['crop_id'] as String? ?? data['cropId'] as String? ?? '',
      cropNameBn: data['crop_name_bn'] as String? ?? data['crop_name'] as String? ?? data['crop'] as String? ?? '',
      nameBn: data['title'] as String? ??
          data['name_bn'] as String? ??
          data['heading'] as String? ??
          data['name'] as String? ??
          '',
      symptoms: data['symptoms'] as String? ?? data['description'] as String? ?? '',
      organicCure: data['solution'] as String? ?? data['organic_cure'] as String? ?? data['cure'] as String? ?? '',
      chemicalCure: data['chemical_cure'] as String? ?? data['chemical'] as String? ?? '',
      precaution: data['precaution'] as String? ?? '',
      imageUrl: data['imageUrl'] as String? ?? data['image_url'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': nameBn,
      'name_bn': nameBn,
      'crop_id': cropId,
      'crop_name_bn': cropNameBn,
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
  }
}

/// Farmer / User Model for Admin Monitoring
class AdminUserModel {
  final String uid;
  final String name;
  final String phone;
  final String district;
  final String upazila;
  final List<String> preferredCrops;
  final DateTime createdAt;

  const AdminUserModel({
    required this.uid,
    required this.name,
    required this.phone,
    required this.district,
    required this.upazila,
    this.preferredCrops = const [],
    required this.createdAt,
  });

  factory AdminUserModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return AdminUserModel(
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
}

/// Support Ticket Model for Admin Monitoring & Replies
class AdminSupportTicketModel {
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

  const AdminSupportTicketModel({
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

  factory AdminSupportTicketModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return AdminSupportTicketModel(
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
}
