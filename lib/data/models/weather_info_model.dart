class DailyForecast {
  final String dayNameBn; // e.g., 'আজ', 'আগামীকাল', 'পরশু'
  final String conditionBn; // 'রোদেলা', 'হালকা বৃষ্টি', 'বজ্রসহ বৃষ্টি', 'মেঘলা'
  final double tempMax;
  final double tempMin;
  final int rainProbability;
  final String iconCode;

  const DailyForecast({
    required this.dayNameBn,
    required this.conditionBn,
    required this.tempMax,
    required this.tempMin,
    required this.rainProbability,
    required this.iconCode,
  });
}

class WeatherInfoModel {
  final String district;
  final double currentTemp;
  final double feelsLike;
  final int humidity; // percentage
  final int rainProbability; // percentage
  final double windSpeedKmH;
  final String conditionBn;
  final String farmingAdvice;
  final List<DailyForecast> threeDayForecast;

  const WeatherInfoModel({
    required this.district,
    required this.currentTemp,
    required this.feelsLike,
    required this.humidity,
    required this.rainProbability,
    required this.windSpeedKmH,
    required this.conditionBn,
    required this.farmingAdvice,
    required this.threeDayForecast,
  });
}
