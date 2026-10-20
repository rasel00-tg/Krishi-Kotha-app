import 'package:flutter/material.dart';
import '../core/utils/district_data.dart';
import '../data/models/market_price_model.dart';
import '../data/services/firestore_service.dart';

class MarketPriceProvider extends ChangeNotifier {
  final FirestoreService _firestoreService;

  String _selectedDivision = 'সকল জেলা / সারাদেশ';
  String _selectedDistrict = BangladeshLocationData.allDistrictsOption;
  String _searchQuery = '';

  MarketPriceProvider(this._firestoreService);

  String get selectedDivision => _selectedDivision;
  String get selectedDistrict => _selectedDistrict;
  String get searchQuery => _searchQuery;

  void setDivision(String division) {
    _selectedDivision = division;
    // When division chip changes, reset specific district filter to avoid filter collisions
    _selectedDistrict = BangladeshLocationData.allDistrictsOption;
    notifyListeners();
  }

  void setDistrict(String district) {
    _selectedDistrict = district;
    if (district == BangladeshLocationData.allDistrictsOption ||
        district == 'সারাদেশ' ||
        district == 'সকল জেলা' ||
        district == 'সব জেলা') {
      _selectedDivision = 'সকল জেলা / সারাদেশ';
    } else {
      // Find the division that contains this district
      for (final entry in BangladeshLocationData.divisionDistricts.entries) {
        if (entry.value.contains(district)) {
          _selectedDivision = entry.key;
          break;
        }
      }
    }
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void resetFilters() {
    _selectedDivision = 'সকল জেলা / সারাদেশ';
    _selectedDistrict = BangladeshLocationData.allDistrictsOption;
    _searchQuery = '';
    notifyListeners();
  }

  Stream<List<MarketPriceModel>> get marketPricesStream =>
      _firestoreService.getMarketPricesStream(
        district: _selectedDistrict,
        searchQuery: _searchQuery,
      );
}
