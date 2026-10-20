import 'package:flutter/material.dart';
import '../data/models/weather_info_model.dart';
import '../data/services/weather_service.dart';

class WeatherProvider extends ChangeNotifier {
  WeatherInfoModel? _weatherInfo;
  bool _isLoading = false;
  String? _errorMessage;
  String _selectedDistrict = 'বগুড়া';

  WeatherInfoModel? get weatherInfo => _weatherInfo;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get selectedDistrict => _selectedDistrict;

  WeatherProvider() {
    fetchWeather(_selectedDistrict);
  }

  Future<void> fetchWeather(String district) async {
    _selectedDistrict = district;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _weatherInfo = await WeatherService.getWeatherForDistrict(district);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'আবহাওয়ার তথ্য লোড করা যায়নি';
      _isLoading = false;
      notifyListeners();
    }
  }

  void updateDistrict(String district) {
    if (_selectedDistrict != district) {
      fetchWeather(district);
    }
  }
}
