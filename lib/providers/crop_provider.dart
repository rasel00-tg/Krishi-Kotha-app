import 'package:flutter/material.dart';
import '../data/models/crop_model.dart';
import '../data/models/pest_disease_model.dart';
import '../data/services/firestore_service.dart';

class CropProvider extends ChangeNotifier {
  final FirestoreService _firestoreService;

  String _selectedCategory = 'সকল ফসল';
  String _pestSearchQuery = '';
  String? _selectedCropIdForPest;

  CropProvider(this._firestoreService);

  String get selectedCategory => _selectedCategory;
  String get pestSearchQuery => _pestSearchQuery;
  String? get selectedCropIdForPest => _selectedCropIdForPest;

  void setCategory(String category) {
    _selectedCategory = category;
    notifyListeners();
  }

  void setPestSearchQuery(String query) {
    _pestSearchQuery = query;
    notifyListeners();
  }

  void filterPestByCrop(String? cropId) {
    _selectedCropIdForPest = cropId;
    notifyListeners();
  }

  Stream<List<CropModel>> get cropsStream =>
      _firestoreService.getCropsStream(category: _selectedCategory);

  Stream<List<PestDiseaseModel>> get pestsStream =>
      _firestoreService.getPestsStream(
        cropId: _selectedCropIdForPest,
        searchQuery: _pestSearchQuery,
      );
}
