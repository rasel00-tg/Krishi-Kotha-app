import 'package:cloud_firestore/cloud_firestore.dart';

class CropStage {
  final String stageName;
  final String description;
  final String irrigation;
  final String fertilizer;

  const CropStage({
    required this.stageName,
    required this.description,
    required this.irrigation,
    required this.fertilizer,
  });

  factory CropStage.fromMap(Map<String, dynamic> map, [int index = 0]) {
    final sName = map['title'] ??
        map['name'] ??
        map['step'] ??
        map['stage_name'] ??
        map['step_name'] ??
        map['heading'];
    final sDesc = map['desc'] ??
        map['description'] ??
        map['details'] ??
        map['step_desc'] ??
        map['content'] ??
        map['instruction'];
    final sIrrig = map['irrigation'] ?? map['water'];
    final sFert = map['fertilizer'] ?? map['sar'];

    return CropStage(
      stageName: (sName != null && sName.toString().trim().isNotEmpty)
          ? sName.toString().trim()
          : 'ধাপ ${index + 1}',
      description: (sDesc != null && sDesc.toString().trim().isNotEmpty)
          ? sDesc.toString().trim()
          : '',
      irrigation: (sIrrig != null && sIrrig.toString().trim().isNotEmpty)
          ? sIrrig.toString().trim()
          : '',
      fertilizer: (sFert != null && sFert.toString().trim().isNotEmpty)
          ? sFert.toString().trim()
          : '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': stageName,
      'name': stageName,
      'stage_name': stageName,
      'desc': description,
      'description': description,
      'details': description,
      'irrigation': irrigation,
      'fertilizer': fertilizer,
    };
  }
}

class CropModel {
  final String id;
  final String nameBn;
  final String category; // Cereals, Vegetables, Fruits, Spices, Oilseed
  final String season; // খরিফ-১, খরিফ-২, রবি
  final String soilType; // দোআঁশ, বেলে দোআঁশ, এটেল ইত্যাদি
  final String sowingTime;
  final String imageUrl;
  final List<CropStage> stages;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const CropModel({
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

  static List<CropStage> parseStages(dynamic rawStages) {
    final stagesList = <CropStage>[];
    if (rawStages is List) {
      for (int i = 0; i < rawStages.length; i++) {
        final item = rawStages[i];
        if (item is Map) {
          try {
            stagesList.add(CropStage.fromMap(Map<String, dynamic>.from(item), i));
          } catch (_) {}
        } else if (item != null) {
          final sName = item.toString().trim();
          if (sName.isNotEmpty) {
            stagesList.add(CropStage(
              stageName: sName,
              description: '',
              irrigation: '',
              fertilizer: '',
            ));
          }
        }
      }
    } else if (rawStages is Map) {
      try {
        stagesList.add(CropStage.fromMap(Map<String, dynamic>.from(rawStages), 0));
      } catch (_) {}
    }
    return stagesList;
  }

  factory CropModel.fromFirestore(DocumentSnapshot doc) {
    try {
      final data = (doc.data() as Map<String, dynamic>?) ?? {};
      return CropModel.fromMap(data, doc.id);
    } catch (_) {
      return CropModel(
        id: doc.id,
        nameBn: 'নাম নেই',
        category: '',
        season: '',
        soilType: '',
        sowingTime: '',
        imageUrl: '',
        stages: const [],
      );
    }
  }

  factory CropModel.fromMap(Map<String, dynamic> data, String id) {
    // 1. name_bn (ফসলের নাম)
    final rawName = data['name_bn'] ?? data['title'] ?? data['name'] ?? data['heading'];
    final name = (rawName != null && rawName.toString().trim().isNotEmpty)
        ? rawName.toString().trim()
        : 'নাম নেই';

    // 2. category (ক্যাটাগরি)
    final rawCat = data['category'] ?? data['cat'];
    final category = (rawCat != null && rawCat.toString().trim().isNotEmpty)
        ? rawCat.toString().trim()
        : '';

    // 3. season (মৌসুম)
    final rawSeason = data['season'];
    final season = (rawSeason != null && rawSeason.toString().trim().isNotEmpty)
        ? rawSeason.toString().trim()
        : '';

    // 4. soil_type (মাটির ধরন)
    final rawSoil = data['soil_type'] ?? data['soil'];
    final soilType = (rawSoil != null && rawSoil.toString().trim().isNotEmpty)
        ? rawSoil.toString().trim()
        : '';

    // 5. sowing_time (বপনের সময়)
    final rawSowing = data['sowing_time'] ?? data['sowing'];
    final sowingTime = (rawSowing != null && rawSowing.toString().trim().isNotEmpty)
        ? rawSowing.toString().trim()
        : '';

    // 6. imageUrl (ছবির লিংক)
    final rawImage = data['imageUrl'] ?? data['image_url'] ?? data['image'] ?? data['img'];
    final imageUrl = (rawImage != null && rawImage.toString().trim().isNotEmpty)
        ? rawImage.toString().trim()
        : '';

    // 7. stages (ধাপসমূহ)
    final stagesList = parseStages(data['stages']);

    DateTime? created;
    if (data['createdAt'] is Timestamp) {
      created = (data['createdAt'] as Timestamp).toDate();
    } else if (data['created_at'] is Timestamp) {
      created = (data['created_at'] as Timestamp).toDate();
    } else if (data['createdAt'] is String) {
      created = DateTime.tryParse(data['createdAt'] as String);
    }

    DateTime? updated;
    if (data['updatedAt'] is Timestamp) {
      updated = (data['updatedAt'] as Timestamp).toDate();
    } else if (data['updated_at'] is Timestamp) {
      updated = (data['updated_at'] as Timestamp).toDate();
    } else if (data['timestamp'] is Timestamp) {
      updated = (data['timestamp'] as Timestamp).toDate();
    } else if (data['updatedAt'] is String) {
      updated = DateTime.tryParse(data['updatedAt'] as String);
    }

    // Default created to updated if only updated is present
    created ??= updated;

    return CropModel(
      id: id,
      nameBn: name,
      category: category,
      season: season,
      soilType: soilType,
      sowingTime: sowingTime,
      imageUrl: imageUrl,
      stages: stagesList,
      createdAt: created,
      updatedAt: updated,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name_bn': nameBn,
      'title': nameBn,
      'category': category,
      'season': season,
      'soil_type': soilType,
      'soil': soilType,
      'sowing_time': sowingTime,
      'imageUrl': imageUrl,
      'image_url': imageUrl,
      'stages': stages.map((s) => s.toMap()).toList(),
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : FieldValue.serverTimestamp(),
    };
  }

  CropModel copyWith({
    String? id,
    String? nameBn,
    String? category,
    String? season,
    String? soilType,
    String? sowingTime,
    String? imageUrl,
    List<CropStage>? stages,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CropModel(
      id: id ?? this.id,
      nameBn: nameBn ?? this.nameBn,
      category: category ?? this.category,
      season: season ?? this.season,
      soilType: soilType ?? this.soilType,
      sowingTime: sowingTime ?? this.sowingTime,
      imageUrl: imageUrl ?? this.imageUrl,
      stages: stages ?? this.stages,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
