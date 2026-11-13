class DailyForecast {
  final String dayNameBn; // e.g., 'আজ', 'আগামীকাল', 'বুধবার'
  final String dateBn; // e.g., '১৫ নভে'
  final String conditionBn; // 'রোদেলা', 'হালকা বৃষ্টি', 'বজ্রসহ বৃষ্টি', 'মেঘলা'
  final double tempMax;
  final double tempMin;
  final int rainProbability;
  final String iconCode;

  const DailyForecast({
    required this.dayNameBn,
    this.dateBn = '',
    required this.conditionBn,
    required this.tempMax,
    required this.tempMin,
    required this.rainProbability,
    required this.iconCode,
  });

  Map<String, dynamic> toJson() => {
    'dayNameBn': dayNameBn,
    'dateBn': dateBn,
    'conditionBn': conditionBn,
    'tempMax': tempMax,
    'tempMin': tempMin,
    'rainProbability': rainProbability,
    'iconCode': iconCode,
  };

  factory DailyForecast.fromJson(Map<String, dynamic> json) => DailyForecast(
    dayNameBn: json['dayNameBn']?.toString() ?? '',
    dateBn: json['dateBn']?.toString() ?? '',
    conditionBn: json['conditionBn']?.toString() ?? '',
    tempMax: (json['tempMax'] as num?)?.toDouble() ?? 30.0,
    tempMin: (json['tempMin'] as num?)?.toDouble() ?? 20.0,
    rainProbability: (json['rainProbability'] as num?)?.toInt() ?? 0,
    iconCode: json['iconCode']?.toString() ?? 'sunny',
  );
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
  final List<DailyForecast> fiveDayForecast;
  final DateTime? fetchedAt;

  // ৩-দিনের জন্য ব্যাকওয়ার্ড কম্প্যাটিবিলিটি প্রোপার্টি
  List<DailyForecast> get threeDayForecast => fiveDayForecast.take(3).toList();

  const WeatherInfoModel({
    required this.district,
    required this.currentTemp,
    required this.feelsLike,
    required this.humidity,
    required this.rainProbability,
    required this.windSpeedKmH,
    required this.conditionBn,
    required this.farmingAdvice,
    required this.fiveDayForecast,
    this.fetchedAt,
  });

  Map<String, dynamic> toJson() => {
    'district': district,
    'currentTemp': currentTemp,
    'feelsLike': feelsLike,
    'humidity': humidity,
    'rainProbability': rainProbability,
    'windSpeedKmH': windSpeedKmH,
    'conditionBn': conditionBn,
    'farmingAdvice': farmingAdvice,
    'fiveDayForecast': fiveDayForecast.map((f) => f.toJson()).toList(),
    'fetchedAt': fetchedAt?.toIso8601String(),
  };

  factory WeatherInfoModel.fromJson(Map<String, dynamic> json) => WeatherInfoModel(
    district: json['district']?.toString() ?? '',
    currentTemp: (json['currentTemp'] as num?)?.toDouble() ?? 28.0,
    feelsLike: (json['feelsLike'] as num?)?.toDouble() ?? 29.0,
    humidity: (json['humidity'] as num?)?.toInt() ?? 70,
    rainProbability: (json['rainProbability'] as num?)?.toInt() ?? 20,
    windSpeedKmH: (json['windSpeedKmH'] as num?)?.toDouble() ?? 10.0,
    conditionBn: json['conditionBn']?.toString() ?? 'পরিষ্কার আকাশ',
    farmingAdvice: json['farmingAdvice']?.toString() ?? '',
    fiveDayForecast: (json['fiveDayForecast'] as List<dynamic>?)
            ?.map((e) => DailyForecast.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [],
    fetchedAt: json['fetchedAt'] != null ? DateTime.tryParse(json['fetchedAt'].toString()) : null,
  );
}
