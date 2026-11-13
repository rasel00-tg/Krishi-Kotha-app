import 'package:flutter/material.dart';
import '../core/utils/bangla_number_converter.dart';
import '../core/widgets/app_warning_dialog.dart';
import '../data/models/weather_info_model.dart';
import '../data/services/weather_service.dart';

class WeatherProvider extends ChangeNotifier {
  WeatherInfoModel? _weatherInfo;
  bool _isLoading = false;
  String? _errorMessage;
  String _selectedDistrict = 'ঢাকা';
  DateTime? _lastApiCallTime;

  WeatherInfoModel? get weatherInfo => _weatherInfo;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get selectedDistrict => _selectedDistrict;
  String get currentDistrict => _selectedDistrict;
  DateTime? get lastApiCallTime => _lastApiCallTime ?? WeatherService.lastApiCallTime ?? _weatherInfo?.fetchedAt;

  WeatherProvider() {
    fetchWeather(_selectedDistrict);
  }

  /// ডেটা ফেচিং মেথড (স্মার্ট ক্যাশিং সাপোর্ট সহ)
  Future<void> fetchWeather(String district, {bool forceRefresh = false}) async {
    final clean = district.trim().replaceAll(' জেলা', '');
    if (clean.isEmpty) return;
    _selectedDistrict = clean;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _weatherInfo = await WeatherService.getWeatherForDistrict(
        clean,
        forceRefresh: forceRefresh,
      );
      _lastApiCallTime = WeatherService.lastApiCallTime ?? _weatherInfo?.fetchedAt ?? DateTime.now();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'আবহাওয়ার তথ্য লোড করা যায়নি';
      _isLoading = false;
      notifyListeners();
    }
  }

  /// ম্যানুয়াল রিফ্রেশ মেথড (কাস্টম লোগো ডায়ালগ ও ১০ মিনিট থ্রটলিং প্রটেকশন সহ)
  Future<void> manualRefresh(BuildContext context) async {
    final now = DateTime.now();
    final lastCall = _lastApiCallTime ?? WeatherService.lastApiCallTime ?? _weatherInfo?.fetchedAt;

    if (lastCall != null) {
      final diffMinutes = now.difference(lastCall).inMinutes;

      // কন্ডিশন ১: যদি শেষ আপডেটের সময় ১০ মিনিটের কম হয়
      if (diffMinutes < 10) {
        if (context.mounted) {
          final String minutesBn = diffMinutes <= 0
              ? '১'
              : BanglaNumberConverter.toBangla(diffMinutes);
          showAppLogoDialog(
            context,
            title: 'আবহাওয়ার তথ্য আপডেট',
            message: 'আবহাওয়ার তথ্য ইতিমধ্যেই আপডেট করা আছে। $minutesBn মিনিট আগে সর্বশেষ আপডেট হয়েছে।',
            primaryColor: const Color(0xFF2E7D32),
            buttonText: 'বুঝেছি',
          );
        }
        return;
      }
    }

    // কন্ডিশন ২: ১০ মিনিট পার হলে নতুনভাবে API কল করে ডেটা আপডেট করা
    _isLoading = true;
    notifyListeners();

    try {
      final updatedInfo = await WeatherService.getWeatherForDistrict(
        _selectedDistrict,
        forceRefresh: true,
      );
      _weatherInfo = updatedInfo;
      _lastApiCallTime = DateTime.now();
      _isLoading = false;
      notifyListeners();

      if (context.mounted) {
        showAppLogoDialog(
          context,
          title: 'সফল হয়েছে!',
          message: 'আবহাওয়ার তথ্য সফলভাবে আপডেট হয়েছে।',
          primaryColor: const Color(0xFF2E7D32),
          buttonText: 'ঠিক আছে',
        );
      }
    } catch (e) {
      _isLoading = false;
      notifyListeners();

      if (context.mounted) {
        showAppLogoDialog(
          context,
          title: 'ব্যর্থ হয়েছে',
          message: 'ইন্টারনেট সংযোগ নেই বা আবহাওয়ার তথ্য আপডেট করা যায়নি। অনুগ্রহ করে সংযোগ পরীক্ষা করুন।',
          primaryColor: const Color(0xFFD32F2F),
          buttonText: 'ঠিক আছে',
        );
      }
    }
  }

  void updateDistrict(String district, {bool forceRefresh = false}) {
    final clean = district.trim().replaceAll(' জেলা', '');
    if (clean.isNotEmpty && (_selectedDistrict != clean || forceRefresh)) {
      fetchWeather(clean, forceRefresh: forceRefresh);
    }
  }

  void changeDistrict(String district, {bool forceRefresh = false}) =>
      updateDistrict(district, forceRefresh: forceRefresh);

  void setInitialDistrict(String district, {bool forceRefresh = false}) {
    final clean = district.trim().replaceAll(' জেলা', '');
    if (clean.isNotEmpty && (_selectedDistrict != clean || forceRefresh)) {
      fetchWeather(clean, forceRefresh: forceRefresh);
    }
  }

  /// ফায়ারস্টোর বা প্রোফাইল জেলা পরিবর্তন হলে ক্যাশ (২ ঘণ্টা) ও থ্রটলিং (১০ মিনিট) বাইপাস করে ফোর্স ফেচ করা
  Future<void> onProfileDistrictChanged(String newDistrict) async {
    final clean = newDistrict.trim().replaceAll(' জেলা', '');
    if (clean.isEmpty) return;
    _selectedDistrict = clean;
    await fetchWeather(clean, forceRefresh: true);
  }
}
