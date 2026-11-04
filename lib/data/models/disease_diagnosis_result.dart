import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/utils/bangla_number_converter.dart';

class ChemicalCureItem {
  final String name;
  final String dosage;
  final String instruction;

  const ChemicalCureItem({
    required this.name,
    required this.dosage,
    this.instruction = '',
  });

  Map<String, dynamic> toMap() => {
    'name': name,
    'dosage': dosage,
    'instruction': instruction,
  };

  factory ChemicalCureItem.fromMap(Map<String, dynamic> map) => ChemicalCureItem(
    name: map['name']?.toString() ?? '',
    dosage: map['dosage']?.toString() ?? '',
    instruction: map['instruction']?.toString() ?? '',
  );
}

class DiseaseDiagnosisResult {
  final String id;
  final String plantName;
  final String diseaseName;
  final String confidence;
  final int confidencePercentage;
  final List<String> causesAndSymptoms;
  final List<String> organicCures;
  final List<ChemicalCureItem> chemicalCures;
  final List<String> precautionAndCare;
  final String? emergencyWarning;
  final String? userSymptoms;
  final String? localImagePath;
  final String? imageUrl;
  final DateTime createdAt;
  final bool expertVerified;
  final bool isNonAgri;
  final String? nonAgriMessage;
  final bool isNotPlantImage;
  final String? notPlantImageMessage;

  const DiseaseDiagnosisResult({
    required this.id,
    required this.plantName,
    required this.diseaseName,
    required this.confidence,
    required this.confidencePercentage,
    required this.causesAndSymptoms,
    required this.organicCures,
    required this.chemicalCures,
    required this.precautionAndCare,
    this.emergencyWarning,
    this.userSymptoms,
    this.localImagePath,
    this.imageUrl,
    required this.createdAt,
    this.expertVerified = true,
    this.isNonAgri = false,
    this.nonAgriMessage,
    this.isNotPlantImage = false,
    this.notPlantImageMessage,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'plant_name': plantName,
      'disease_name': diseaseName,
      'confidence': confidence,
      'confidence_percentage': confidencePercentage,
      'causes_and_symptoms': causesAndSymptoms,
      'organic_cures': organicCures,
      'chemical_cures': chemicalCures.map((c) => c.toMap()).toList(),
      'precaution_and_care': precautionAndCare,
      'emergency_warning': emergencyWarning,
      'user_symptoms': userSymptoms,
      'local_image_path': localImagePath,
      'image_url': imageUrl,
      'created_at': createdAt.toIso8601String(),
      'expert_verified': expertVerified,
      'is_non_agri': isNonAgri,
      'non_agri_message': nonAgriMessage,
      'is_not_plant_image': isNotPlantImage,
      'not_plant_image_message': notPlantImageMessage,
    };
  }

  Map<String, dynamic> toFirestoreMap() {
    final map = toMap();
    map['created_at'] = Timestamp.fromDate(createdAt);
    return map;
  }

  factory DiseaseDiagnosisResult.fromMap(Map<String, dynamic> map, [String? docId]) {
    DateTime parsedDate = DateTime.now();
    if (map['created_at'] is Timestamp) {
      parsedDate = (map['created_at'] as Timestamp).toDate();
    } else if (map['created_at'] is String) {
      parsedDate = DateTime.tryParse(map['created_at'] as String) ?? DateTime.now();
    }

    final rawConfidence = map['confidence']?.toString() ?? '';
    int confPct = (map['confidence_percentage'] as num?)?.toInt() ?? 95;
    if (confPct <= 0 || confPct > 100) confPct = 95;

    final displayConfidence = rawConfidence.isNotEmpty
        ? rawConfidence
        : '${BanglaNumberConverter.toBangla(confPct.toString())}%';

    List<String> parseStringList(dynamic value) {
      if (value is List) {
        return value.map((e) => e.toString().trim()).where((e) => e.isNotEmpty).toList();
      }
      return [];
    }

    List<ChemicalCureItem> parseChemicalCures(dynamic value) {
      if (value is List) {
        return value.map((e) {
          if (e is Map<String, dynamic>) {
            return ChemicalCureItem.fromMap(e);
          } else if (e is String) {
            return ChemicalCureItem(name: e, dosage: 'প্রয়োজনমতো সঠিক মাত্রায় ব্যবহার করুন');
          }
          return ChemicalCureItem(name: e.toString(), dosage: '');
        }).toList();
      }
      return [];
    }

    return DiseaseDiagnosisResult(
      id: docId ?? map['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
      plantName: map['plant_name']?.toString() ?? 'অজ্ঞাত ফসল / গাছ',
      diseaseName: map['disease_name']?.toString() ?? 'চিহ্নিত রোগ',
      confidence: displayConfidence,
      confidencePercentage: confPct,
      causesAndSymptoms: parseStringList(map['causes_and_symptoms']),
      organicCures: parseStringList(map['organic_cures']),
      chemicalCures: parseChemicalCures(map['chemical_cures']),
      precautionAndCare: parseStringList(map['precaution_and_care']),
      emergencyWarning: map['emergency_warning']?.toString(),
      userSymptoms: map['user_symptoms']?.toString(),
      localImagePath: map['local_image_path']?.toString(),
      imageUrl: map['image_url']?.toString(),
      createdAt: parsedDate,
      expertVerified: map['expert_verified'] as bool? ?? true,
      isNonAgri: map['is_non_agri'] as bool? ?? (map['is_non_agricultural'] as bool? ?? false),
      nonAgriMessage: map['non_agri_message']?.toString(),
      isNotPlantImage: map['is_not_plant_image'] as bool? ??
          (map['status']?.toString() == 'NOT_PLANT_IMAGE' ||
              map['disease_name']?.toString() == 'NOT_PLANT_IMAGE' ||
              map['flag']?.toString() == 'NOT_PLANT_IMAGE'),
      notPlantImageMessage: map['not_plant_image_message']?.toString() ??
          (map['is_not_plant_image'] == true
              ? 'আপনার দেওয়া ছবিটি কোনো উদ্ভিদ বা ফসলের নয়। অনুগ্রহ করে আক্রান্ত ফসলের পাতা বা গাছের স্পষ্ট ছবি আপলোড করুন।'
              : null),
    );
  }

  factory DiseaseDiagnosisResult.fromFirestore(DocumentSnapshot doc) {
    final data = (doc.data() as Map<String, dynamic>?) ?? {};
    return DiseaseDiagnosisResult.fromMap(data, doc.id);
  }
}

