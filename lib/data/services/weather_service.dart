import '../models/weather_info_model.dart';

class WeatherService {
  /// Fetches farming-focused weather for the farmer's selected district
  static Future<WeatherInfoModel> getWeatherForDistrict(String district) async {
    // In production, integrate with OpenWeatherMap or BMD (Bangladesh Meteorological Dept) API.
    // Here we generate tailored, realistic weather data based on geographic zone:
    await Future.delayed(const Duration(milliseconds: 300));

    double temp = 28.5;
    int humidity = 72;
    int rainChance = 35;
    String condition = 'আংশিক মেঘলা';
    String advice = 'মাটিতে আর্দ্রতা ভালো আছে। বিকালে সবজি ও ধানের জমিতে হালকা সেচ দেওয়া যেতে পারে।';

    if (district == 'রংপুর' || district == 'দিনাজপুর' || district == 'বগুড়া') {
      temp = 27.0;
      humidity = 68;
      rainChance = 20;
      condition = 'রোদেলা ও শুষ্ক';
      advice = 'আবহাওয়া শুষ্ক রয়েছে। বোরো ধান ও আলুর জমিতে সেচ ও সার প্রয়োগের উপযুক্ত সময়।';
    } else if (district == 'সিলেট' || district == 'চট্টগ্রাম') {
      temp = 29.0;
      humidity = 84;
      rainChance = 65;
      condition = 'হালকা থেকে মাঝারি বৃষ্টি';
      advice = 'বৃষ্টির সম্ভাবনা থাকায় আজ জমিতে রাসায়নিক সার ও স্প্রে করা স্থগিত রাখুন। নালা পরিষ্কার রাখুন।';
    } else if (district == 'খুলনা' || district == 'যশোর' || district == 'বরিশাল') {
      temp = 30.5;
      humidity = 76;
      rainChance = 40;
      condition = 'উষ্ণ ও আর্দ্র';
      advice = 'গাছের গোড়ায় পানি জমতে দেবেন না। পোকার আক্রমণ পর্যবেক্ষণ করে ফেরোমন ফাঁদ ব্যবহার করুন।';
    }

    return WeatherInfoModel(
      district: district,
      currentTemp: temp,
      feelsLike: temp + 2.0,
      humidity: humidity,
      rainProbability: rainChance,
      windSpeedKmH: 14.5,
      conditionBn: condition,
      farmingAdvice: advice,
      threeDayForecast: const [
        DailyForecast(
          dayNameBn: 'আজ',
          conditionBn: 'আংশিক মেঘলা',
          tempMax: 31.0,
          tempMin: 22.0,
          rainProbability: 35,
          iconCode: 'partly_cloudy',
        ),
        DailyForecast(
          dayNameBn: 'আগামীকাল',
          conditionBn: 'রোদেলা',
          tempMax: 32.5,
          tempMin: 23.0,
          rainProbability: 15,
          iconCode: 'sunny',
        ),
        DailyForecast(
          dayNameBn: 'পরশু',
          conditionBn: 'বজ্রসহ বৃষ্টি',
          tempMax: 29.0,
          tempMin: 21.0,
          rainProbability: 75,
          iconCode: 'thunderstorm',
        ),
      ],
    );
  }
}
