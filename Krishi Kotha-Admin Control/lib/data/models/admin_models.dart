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
  final String email;
  final String? photoUrl;
  final String district;
  final String upazila;
  final String village;
  final String occupation;
  final List<String> preferredCrops;
  final String status; // 'active', 'temporary_blocked', 'permanently_suspended'
  final String? blockReason;
  final DateTime? unblockAt;
  final String? suspendReason;
  final DateTime? lastProfileUpdate;
  final String? password;
  final int failedAttempts;
  final DateTime? lockUntil;
  final DateTime? updatedAt;
  final DateTime createdAt;

  bool get isPasswordLocked {
    if (lockUntil == null) return false;
    return DateTime.now().isBefore(lockUntil!);
  }

  const AdminUserModel({
    required this.uid,
    required this.name,
    required this.phone,
    this.email = '',
    this.photoUrl,
    required this.district,
    required this.upazila,
    this.village = '',
    this.occupation = '',
    this.preferredCrops = const [],
    this.status = 'active',
    this.blockReason,
    this.unblockAt,
    this.suspendReason,
    this.lastProfileUpdate,
    this.password,
    this.failedAttempts = 0,
    this.lockUntil,
    this.updatedAt,
    required this.createdAt,
  });

  factory AdminUserModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};

    DateTime? parseDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val);
      return null;
    }

    return AdminUserModel(
      uid: doc.id,
      name: data['name'] as String? ?? 'কৃষক ভাই',
      phone: data['phone'] as String? ?? '',
      email: data['email'] as String? ?? '',
      photoUrl: data['photo_url'] ?? data['photoUrl'] ?? data['image_url'],
      district: data['district'] as String? ?? 'ঢাকা',
      upazila: data['upazila'] as String? ?? '',
      village: data['village'] ?? data['village_name'] ?? '',
      occupation: data['occupation'] ?? '',
      preferredCrops: List<String>.from(data['preferred_crops'] ?? []),
      status: data['status'] as String? ?? 'active',
      blockReason: data['blockReason'] as String?,
      unblockAt: parseDate(data['unblockAt']),
      suspendReason: data['suspendReason'] as String?,
      lastProfileUpdate: parseDate(data.containsKey('lastProfileUpdate') ? data['lastProfileUpdate'] : data['last_profile_update']),
      password: data['password'] as String?,
      failedAttempts: (data['failedAttempts'] as num?)?.toInt() ?? 0,
      lockUntil: parseDate(data['lockUntil']),
      updatedAt: parseDate(data['updatedAt'] ?? data['updated_at']),
      createdAt: parseDate(data['createdAt']) ?? DateTime.now(),
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

/// Privacy Policy Settings Model for Admin Management
class AdminPrivacyPolicyModel {
  final String lastUpdated;
  final String bannerText;
  final String content;
  final String? bannerImageUrl;
  final DateTime? updatedAt;
  final String updatedBy;

  const AdminPrivacyPolicyModel({
    required this.lastUpdated,
    required this.bannerText,
    required this.content,
    this.bannerImageUrl,
    this.updatedAt,
    this.updatedBy = 'এডমিন',
  });

  factory AdminPrivacyPolicyModel.fromMap(Map<String, dynamic>? data) {
    if (data == null) {
      return AdminPrivacyPolicyModel.defaultPolicy();
    }
    return AdminPrivacyPolicyModel(
      lastUpdated: data['last_updated']?.toString() ?? 'সর্বশেষ হালনাগাদ: নভেম্বর ২০২৬ • সংস্করণ ১.০.০',
      bannerText: data['banner_text']?.toString() ??
          'কৃষি কথা অ্যাপ কৃষকদের আস্থার প্ল্যাটফর্ম। আপনার কোনো ব্যক্তিগত তথ্য বা ফোন নম্বর কখনো কোনো বাণিজ্যিক তৃতীয় পক্ষের কাছে বিক্রি বা শেয়ার করা হয় না।',
      content: data['policy_content']?.toString() ?? AdminPrivacyPolicyModel.defaultContentText(),
      bannerImageUrl: data['banner_image_url']?.toString() ?? data['image_url']?.toString(),
      updatedAt: (data['updated_at'] is Timestamp) ? (data['updated_at'] as Timestamp).toDate() : null,
      updatedBy: data['updated_by']?.toString() ?? 'এডমিন',
    );
  }

  static String defaultContentText() {
    return '''১. সংগৃহীত তথ্যাবলী ও কৃষকের তথ্য সংগ্রহ:
কৃষকদের সঠিক পরামর্শ ও স্থানীয় কৃষি সেবা প্রদানের জন্য অ্যাপে নিম্নলিখিত তথ্যগুলো সংগ্রহ করা হয়:
• ব্যবহারকারীর নাম: কৃষককে ব্যক্তিগতভাবে সঠিক সম্বোধন ও প্রোফাইল শনাক্তকরণের জন্য।
• মোবাইল নম্বর ও ইমেইল: ওটিপি ও পাসওয়ার্ড যাচাইয়ের মাধ্যমে অ্যাকাউন্ট নিরাপত্তা ও সরাসরি যোগাযোগের জন্য।
• লোকেশন (জেলা ও উপজেলা): স্থানীয় সঠিক আবহাওয়া পূর্বাভাস ও মোকামের বাজার দর দেখানোর জন্য।
• পছন্দের ফসল: কৃষকের চাষকৃত ফসল অনুযায়ী উপযুক্ত সার ও বালাইনাশকের সময়োপযোগী নির্দেশনা দিতে।

২. তথ্যের ব্যবহার ও কৃষি সেবা নিশ্চিতকরণ:
সংগৃহীত তথ্য কেবলমাত্র কৃষক কল্যাণ ও অ্যাপের কার্যকারিতা বৃদ্ধির উদ্দেশ্যে ব্যবহৃত হয়:
• জরুরি দুর্যোগ ও কালবৈশাখী ঝড়ের আবহাওয়ার তাৎক্ষণিক পুশ নোটিফিকেশন প্রদান।
• জমি ও শতক অনুযায়ী ইউরিয়া, টিএসপি, এমওপি সারের সঠিক পরিমাণ হিসাব করা।
• কৃষি কল সেন্টার ১৬১২৩ এবং উপজেলা কৃষি কর্মকর্তাদের সহায়তার সাথে যুক্ত করা।
• অ্যাপের ব্যবহারবান্ধব অভিজ্ঞতা নিশ্চিত ও সমস্যা সমাধানে প্রযুক্তিগত উন্নয়ন।

৩. ক্যামেরা, অবস্থান ও ছবি ব্যবহারের অনুমতি (KrishiMate AI):
রোগবালাই শনাক্তকরণ ও স্থানীয় সেবার জন্য নির্দিষ্ট পারমিশন নেওয়া হয়:
• ক্যামেরা ও গ্যালারি: "KrishiMate AI" ফিচারে আক্রান্ত ফসলের ছবি তুলে রোগ শনাক্ত ও প্রেসক্রিপশন তৈরির জন্য।
• অবস্থান (Location): স্থানীয় আবহাওয়া সতর্কতা ও নিকটের কৃষি বাজার দর নিখুঁতভাবে দেখানোর জন্য।
• ব্যাকগ্রাউন্ডে কোনো অপ্রয়োজনীয় ক্যামেরা, কল বা অবস্থান ট্র্যাকিং কখনো চালানো হয় না।

৪. তথ্যের সুরক্ষা, ডেটা নিরাপত্তা ও গোপনীয়তা:
আমরা কঠোর তথ্যের গোপনীয়তা নীতি মেনে চলি এবং ব্যবহারকারীর ডাটা সুরক্ষায় প্রতিশ্রুতিবদ্ধ:
• আপনার ডেটা কখনো বিজ্ঞাপন সংস্থা বা বাণিজ্যিক তৃতীয় পক্ষের কাছে বিক্রি বা হস্তান্তর করা হয় না।
• কৃষকের অনুমতি ছাড়া কোনো ব্যক্তিগত তথ্য প্রকাশ করা হয় না।
• ব্যবহারকারী যেকোনো সময় তার প্রোফাইল তথ্য হালনাগাদ বা পরিবর্তন করতে পারেন।

৫. ফায়ারবেস ও ক্লাউড সিকিউরিটি আর্কিটেকচার:
কৃষি কথা অ্যাপের সমস্ত রিয়েল-টাইম তথ্য ও অ্যাকাউন্ট গুগল ফায়ারবেস (Firebase Cloud) প্ল্যাটফর্মে পরিচালিত:
• Firebase Authentication এর মাধ্যমে নিরাপদ ও এনক্রিপ্টেড পরিচয় যাচাইকরণ ব্যবস্থা।
• Cloud Firestore ডেটাবেসের সিকিউরিটি রুলস দ্বারা কৃষকদের ডেটা অ্যাক্সেস কঠোরভাবে সংরক্ষিত।
• ইন্টারনেট সংযোগ সাময়িক বিচ্ছিন্ন থাকলেও লোকাল অফলাইন ক্যাশিং সুরক্ষার সাথে সংরক্ষিত থাকে।

৬. যোগাযোগ, সহায়তা ও অভিযোগ প্রতিকার:
গোপনীয়তা নীতিমালা বা তথ্যের নিরাপত্তা সংক্রান্ত যেকোনো প্রশ্ন বা সহায়তার ক্ষেত্রে আমাদের সাথে যোগাযোগ করুন:
• টোল-ফ্রি হেল্পলাইন: ১৬১২৩ (সরাসরি কৃষি কল সেন্টার, সকাল ৯টা - বিকাল ৫টা)
• ইমেইল সাপোর্ট: krishikotha.app@gmail.com
• অফিসিয়াল যোগাযোগ: কৃষি সম্প্রসারণ অধিদপ্তর (DAE), খামারবাড়ি, ঢাকা, বাংলাদেশ''';
  }

  static AdminPrivacyPolicyModel defaultPolicy() {
    return AdminPrivacyPolicyModel(
      lastUpdated: 'সর্বশেষ হালনাগাদ: নভেম্বর ২০২৬ • সংস্করণ ১.০.০',
      bannerText: 'কৃষি কথা অ্যাপ কৃষকদের আস্থার প্ল্যাটফর্ম। আপনার কোনো ব্যক্তিগত তথ্য বা ফোন নম্বর কখনো কোনো বাণিজ্যিক তৃতীয় পক্ষের কাছে বিক্রি বা শেয়ার করা হয় না।',
      content: defaultContentText(),
      updatedBy: 'সিস্টেম ডিফল্ট',
    );
  }
}
