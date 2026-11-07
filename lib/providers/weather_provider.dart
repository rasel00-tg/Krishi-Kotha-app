import 'package:flutter/material.dart';
import '../data/models/weather_info_model.dart';
import '../data/services/weather_service.dart';

class WeatherProvider extends ChangeNotifier {
  WeatherInfoModel? _weatherInfo;
  bool _isLoading = false;
  String? _errorMessage;
  String _selectedDistrict = 'ঢাকা';

  WeatherInfoModel? get weatherInfo => _weatherInfo;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get selectedDistrict => _selectedDistrict;
  String get currentDistrict => _selectedDistrict;

  WeatherProvider() {
    fetchWeather(_selectedDistrict);
  }

  Future<void> fetchWeather(String district) async {
    final clean = district.trim();
    if (clean.isEmpty) return;
    _selectedDistrict = clean;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _weatherInfo = await WeatherService.getWeatherForDistrict(clean);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'আবহাওয়ার তথ্য লোড করা যায়নি';
      _isLoading = false;
      notifyListeners();
    }
  }

  void updateDistrict(String district) {
    if (_selectedDistrict != district.trim()) {
      fetchWeather(district.trim());
    }
  }

  void changeDistrict(String district) => updateDistrict(district);

  void setInitialDistrict(String district) {
    if (district.trim().isNotEmpty && _selectedDistrict != district.trim()) {
      fetchWeather(district.trim());
    }
  }
}
