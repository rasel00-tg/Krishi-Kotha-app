import 'package:cloud_firestore/cloud_firestore.dart';

class PestDiseaseModel {
  final String id;
  final String cropId;
  final String cropNameBn;
  final String nameBn;
  final String symptoms;
  final String organicCure;
  final String chemicalCure;
  final String precaution;
  final String imageUrl;
  final DateTime? updatedAt;

  const PestDiseaseModel({
    required this.id,
    required this.cropId,
    this.cropNameBn = '',
    required this.nameBn,
    required this.symptoms,
    required this.organicCure,
    required this.chemicalCure,
    this.precaution = '',
    required this.imageUrl,
    this.updatedAt,
  });

  factory PestDiseaseModel.fromFirestore(DocumentSnapshot doc) {
    try {
      final data = (doc.data() as Map<String, dynamic>?) ?? {};
      return PestDiseaseModel.fromMap(data, doc.id);
    } catch (_) {
      return PestDiseaseModel(
        id: doc.id,
        cropId: '',
        cropNameBn: '',
        nameBn: 'বালাই ও রোগবালাই',
        symptoms: '',
        organicCure: '',
        chemicalCure: '',
        precaution: '',
        imageUrl: '',
      );
    }
  }

  factory PestDiseaseModel.fromMap(Map<String, dynamic> data, String id) {
    DateTime? updated;
    if (data['updatedAt'] is Timestamp) {
      updated = (data['updatedAt'] as Timestamp).toDate();
    } else if (data['timestamp'] is Timestamp) {
      updated = (data['timestamp'] as Timestamp).toDate();
    } else if (data['updatedAt'] is String) {
      updated = DateTime.tryParse(data['updatedAt'] as String);
    } else if (data['timestamp'] is String) {
      updated = DateTime.tryParse(data['timestamp'] as String);
    } else if (data['updatedAt'] is int) {
      updated = DateTime.fromMillisecondsSinceEpoch(data['updatedAt'] as int);
    }

    final rawTitle = data['title'] ?? data['name_bn'] ?? data['name'] ?? data['heading'];
    final rawCrop = data['crop_name_bn'] ?? data['crop_name'] ?? data['crop'] ?? data['category'];
    final rawSymptoms = data['symptoms'] ?? data['description'];
    final rawSolution = data['solution'] ?? data['organic_cure'] ?? data['cure'];
    final rawChemical = data['chemical_cure'] ?? data['chemical'];
    final rawImg = data['imageUrl'] ?? data['image_url'] ?? data['image'];

    return PestDiseaseModel(
      id: (data['id'] ?? id).toString(),
      cropId: (data['crop_id'] ?? data['cropId'] ?? '').toString().trim(),
      cropNameBn: rawCrop?.toString().trim() ?? '',
      nameBn: (rawTitle != null && rawTitle.toString().trim().isNotEmpty)
          ? rawTitle.toString().trim()
          : 'বালাই ও রোগবালাই',
      symptoms: rawSymptoms?.toString().trim() ?? '',
      organicCure: rawSolution?.toString().trim() ?? '',
      chemicalCure: rawChemical?.toString().trim() ?? '',
      precaution: (data['precaution'] ?? '').toString().trim(),
      imageUrl: rawImg?.toString().trim() ?? '',
      updatedAt: updated,
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
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : FieldValue.serverTimestamp(),
    };
  }
}
