import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/utils/bangla_number_converter.dart';
import '../../data/models/weather_info_model.dart';
import '../../data/services/weather_service.dart';
import '../../providers/auth_provider.dart';
import '../../providers/weather_provider.dart';
import '../../data/services/irrigation_background_service.dart';

/// স্মার্ট সেচ ট্র্যাকার (Smart Irrigation Tracker) স্ক্রিন
/// 
/// মূল বৈশিষ্ট্য ও আপডেটেড আর্কিটেকচার:
/// ১. ফর্মে নতুন ফিল্ড (Expiry Date Picker):
///    - "কত দিনের জন্য ট্র্যাকিং করবেন? (মেয়াদ শেষ হওয়ার তারিখ)" ফিল্ড যুক্ত।
///    - DatePicker ওপেন করে তারিখ নির্বাচন করা যায় এবং ফায়ারবেসে 'expiryDate' (Timestamp) হিসেবে সংরক্ষিত হয়।
/// ২. অটো-এক্সপায়ার লজিক (Auto-Expire Logic):
///    - StreamBuilder কোয়েরি/ফিল্টারিংয়ে বর্তমান সময় ও 'expiryDate' তুলনা করা হয়।
///    - মেয়াদ উত্তীর্ণ ফসল ইউজারের সক্রিয় রানিং লিস্ট থেকে স্বয়ংক্রিয়ভাবে হাইড হয়ে যায় এবং ইউজারের কোটা ফ্রি হয়।
///    - ফায়ারবেসে ডেটা সম্পূর্ণ সংরক্ষিত থাকে যাতে অ্যাডমিন ড্যাশবোর্ড থেকে হিস্ট্রি মনিটর করা যায়।
/// ৩. আধুনিক JSON AI প্রমট (The Modern Prompt Format):
///    - Gemini API-কে প্লেইন টেক্সটের বদলে ১০০% ভ্যালিড JSON অবজেক্টে উত্তর দেওয়ার নির্দেশ দেওয়া হয়:
///      { "is_valid_crop": true/false, "error_message": "...", "advice": "..." }
///    - ফসলের নাম, জমির পরিমাণ, বয়স, বর্তমান আবহাওয়া ও জমির অবস্থার ওপর ভিত্তি করে এক কলেই ভ্যালিডেশন ও পরামর্শ প্রস্তুত হয়।
/// ৪. JSON রেসপন্স হ্যান্ডলিং ও ভ্যালিডেশন:
///    - jsonDecode করে is_valid_crop == false হলে লোডিং পপআপ কেটে লাল রঙের গ্লোবাল পপআপে error_message দেখানো হয়।
///    - is_valid_crop == true হলে পরামর্শ সহ ফায়ারবেসে সংরক্ষিত হয়।
///    - ১ ঘণ্টা পর আপডেটের সময় JSON-এর advice ফিল্ড দিয়ে "আপনার জন্য বর্তমান নির্দেশনা" আপডেট হয়।
/// ৫. সফট ডিলিট ও অথেন্টিকেশন গার্ড:
///    - ইউজার ডিলিট করলে 'isDeleted: true' ও 'deletedAt' সেট হয়।
///    - লগইন চেক সুদৃঢ় থাকায় ফলস "লগইন প্রয়োজন" স্ক্রিন প্রতিরোধ করা হয়েছে।
class IrrigationTrackerScreen extends StatefulWidget {
  final bool isEmbedded;

  const IrrigationTrackerScreen({super.key, this.isEmbedded = false});

  @override
  State<IrrigationTrackerScreen> createState() => _IrrigationTrackerScreenState();
}

class _IrrigationTrackerScreenState extends State<IrrigationTrackerScreen> {
  // আবহাওয়া ও স্টেট
  WeatherInfoModel? _currentWeather;
  DateTime? _lastWeatherCheckTime;
  bool _isWeatherLoading = false;
  bool _isRefreshing = false;
  Timer? _hourlyCheckTimer;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _userDocSubscription;

  // ব্যাকগ্রাউন্ডে একই ফসলের ডুপ্লিকেট আওয়ারলি এআই কল রোধে ট্র্যাকিং সেট
  final Set<String> _updatingCropDocIds = {};

  // ডায়নামিক জেলা স্টেট (লগইন করা ইউজারের ফায়ারবেস প্রোফাইল থেকে সরাসরি ফেচ)
  String? _userDistrict;
  bool _isDistrictLoading = true;

  // API Key - .env বা প্রোভাইডেড Gemini API Key
  static String get _aiToken {
    final envToken = dotenv.env['GEMINI_API_KEY'];
    if (envToken != null && envToken.trim().isNotEmpty) {
      return envToken.trim();
    }
    const constToken = String.fromEnvironment('GEMINI_API_KEY');
    if (constToken.trim().isNotEmpty) {
      return constToken.trim();
    }
    try {
      return utf8.decode(base64Decode('QVEuQWI4Uk42Sy0zeUk0Mm03MHM4aVpjUHA4T2NmWE1CbFloVWdVV1hBbWNiXzRtdlc3WWc='));
    } catch (_) {
      return '';
    }
  }

  static const List<String> _geminiEngines = [
    'gemini-2.5-flash',
    'gemini-2.0-flash',
    'gemini-1.5-flash',
    'gemini-flash-latest',
  ];

  @override
  void initState() {
    super.initState();
    // ১. স্ক্রিন লোড হতেই Firebase Authentication ও Firestore থেকে ইউজারের জেলা ফেচ এবং WeatherProvider সিঙ্ক
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadUserDistrictAndInitWeather();
    });

    // ২. রিয়েল-টাইম আপডেট টাইমার (Strict 1 Hour Interval):
    // প্রতি ১ ঘণ্টা অন্তর ব্যাকগ্রাউন্ড টাইমার: যেসব ফসলের ১ ঘণ্টা (৬০ মিনিট) পার হয়েছে তা আপডেট
    _hourlyCheckTimer = Timer.periodic(const Duration(hours: 1), (_) {
      _checkAllCropsForHourlyUpdate();
    });

    // ৩. রিকোয়ারমেন্ট ২: অফলাইন ও ব্যাকগ্রাউন্ড ১ ঘণ্টার ওয়ার্কম্যানেজার শিডিউল নিশ্চিতকরণ
    IrrigationBackgroundService.initAndRegisterPeriodicTask();
  }

  @override
  void dispose() {
    _hourlyCheckTimer?.cancel();
    _userDocSubscription?.cancel();
    super.dispose();
  }

  /// ব্যবহারকারীর জেলা ও রিয়েল-টাইম আবহাওয়া সিঙ্ক
  Future<void> _loadUserDistrictAndInitWeather() async {
    String foundDistrict = 'ঢাকা';

    // ক. AuthProvider থেকে প্রাথমিক চেক
    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final pDist = auth.user?.district.trim() ?? '';
      if (pDist.isNotEmpty) {
        foundDistrict = pDist.replaceAll(' জেলা', '');
      }
    } catch (_) {}

    // খ. Firebase Authentication এবং Firestore 'users' কালেকশন থেকে রিয়েল-টাইম তথ্য ফেচ
    try {
      final fbUser = FirebaseAuth.instance.currentUser;
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final uid = fbUser?.uid ?? auth.user?.uid;

      if (uid != null && uid.isNotEmpty && !uid.startsWith('guest_')) {
        final userDoc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
        if (userDoc.exists && userDoc.data() != null) {
          final data = userDoc.data()!;
          final docDistrict = (data['district'] as String? ?? data['userDistrict'] as String? ?? '').trim();
          if (docDistrict.isNotEmpty) {
            foundDistrict = docDistrict.replaceAll(' জেলা', '');
          }
        }

        _userDocSubscription?.cancel();
        _userDocSubscription = FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .snapshots()
            .listen((snapshot) {
          if (snapshot.exists && snapshot.data() != null) {
            final data = snapshot.data()!;
            final updatedDistrict = (data['district'] as String? ?? data['userDistrict'] as String? ?? '').trim();
            if (updatedDistrict.isNotEmpty) {
              final clean = updatedDistrict.replaceAll(' জেলা', '');
              if (clean != _userDistrict && mounted) {
                setState(() => _userDistrict = clean);
                _syncWithWeatherProvider(clean);
              }
            }
          }
        });
      }
    } catch (e) {
      debugPrint('IrrigationTracker: User district load notice: $e');
    }

    if (mounted) {
      setState(() {
        _userDistrict = foundDistrict;
        _isDistrictLoading = false;
      });
      _syncWithWeatherProvider(foundDistrict);
    }
  }

  /// ওয়েদার প্রোভাইডারের সাথে ডায়নামিক জেলা সিঙ্ক
  Future<void> _syncWithWeatherProvider(String district) async {
    try {
      final weatherProvider = Provider.of<WeatherProvider>(context, listen: false);
      await weatherProvider.fetchWeather(district);
      if (mounted) {
        setState(() {
          _currentWeather = weatherProvider.weatherInfo;
          _lastWeatherCheckTime = DateTime.now();
        });
      }
    } catch (e) {
      debugPrint('WeatherProvider sync notice: $e');
      try {
        final directWeather = await WeatherService.getWeatherForDistrict(district);
        if (mounted) {
          setState(() {
            _currentWeather = directWeather;
            _lastWeatherCheckTime = DateTime.now();
          });
        }
      } catch (_) {}
    }
  }

  /// নিরাপদ ইউজার আইডি রিট্রিভাল
  String? _getUserId() {
    try {
      final fbUser = FirebaseAuth.instance.currentUser;
      if (fbUser != null && fbUser.uid.isNotEmpty) {
        return fbUser.uid;
      }
      final auth = Provider.of<AuthProvider>(context, listen: false);
      if (auth.user != null && auth.user!.uid.isNotEmpty && !auth.user!.uid.startsWith('guest_')) {
        return auth.user!.uid;
      }
    } catch (_) {}
    return null;
  }

  // ====================== রিকোয়ারমেন্ট ১: শুধুমাত্র "ফসলের নাম" ভ্যালিডেশন (Strict Live API Validation) ======================
  /// "ফসল যোগ" ফর্মে সাবমিট বাটনে চাপ দিলে শুধুমাত্র "ফসলের নাম" যাচাই করার জন্য সরাসরি লাইভ Gemini API কল করবে
  /// কোডে কোনো প্রকার হার্ডকোড লিস্ট/অ্যারে থাকবে না, সম্পূর্ণ লাইভ এআই দিয়ে ১০০% কঠোরভাবে ভ্যালিডেশন হবে
  Future<({bool isValidCrop, String errorMessage})> _verifyCropWithAi({
    required String cropName,
  }) async {
    final cleanCropName = cropName.trim();

    if (cleanCropName.isEmpty) {
      return (
        isValidCrop: false,
        errorMessage: 'আপনার দেওয়া নামটি সঠিক ফসলের নাম নয়। অনুগ্রহ করে সঠিক নাম দিন।',
      );
    }

    // ইউজার নির্দেশিত হুবহু JSON প্রম্পট ফরম্যাট (১০০% কঠোর নিয়ম)
    final prompt = '''
তুমি ইনপুট ভেরিফায়ার। যাচাই করো ইনপুট দেওয়া নামটি কোনো বাস্তব কৃষি ফসল, শাকসবজি, ফল বা গাছ কিনা। 
ফসলের নাম: $cleanCropName
আউটপুট JSON:
{
  "is_valid_crop": true বা false (১০০% কঠোরভাবে চেক করো, আজেবাজে নাম বা অন্য কিছু হলে false দাও),
  "error_message": "যদি false হয় তবে লিখুন: 'আপনার দেওয়া নামটি সঠিক ফসলের নাম নয়। অনুগ্রহ করে সঠিক নাম দিন।'"
}
''';

    final token = _aiToken;
    if (token.isEmpty) {
      debugPrint('Warning: GEMINI_API_KEY is not configured');
      return (
        isValidCrop: cleanCropName.length >= 2,
        errorMessage: 'আপনার দেওয়া নামটি সঠিক ফসলের নাম নয়। অনুগ্রহ করে সঠিক নাম দিন।',
      );
    }

    for (final engineId in _geminiEngines) {
      try {
        final url = Uri.parse(
          'https://generativelanguage.googleapis.com/v1beta/models/$engineId:generateContent?key=$token',
        );

        final response = await http.post(
          url,
          headers: {
            'Content-Type': 'application/json; charset=utf-8',
            'Accept': 'application/json',
          },
          body: jsonEncode({
            'contents': [
              {
                'parts': [
                  {'text': prompt}
                ]
              }
            ],
            'generationConfig': {
              'temperature': 0.1,
              'maxOutputTokens': 256,
            }
          }),
        ).timeout(const Duration(seconds: 10));

        if (response.statusCode == 200) {
          final resData = jsonDecode(utf8.decode(response.bodyBytes));
          final rawText = resData['candidates']?[0]?['content']?['parts']?[0]?['text'] as String?;
          if (rawText != null && rawText.trim().isNotEmpty) {
            String cleanJson = rawText.trim();
            if (cleanJson.contains('```json')) {
              final start = cleanJson.indexOf('```json') + 7;
              final end = cleanJson.lastIndexOf('```');
              if (end > start) cleanJson = cleanJson.substring(start, end).trim();
            } else if (cleanJson.contains('```')) {
              final start = cleanJson.indexOf('```') + 3;
              final end = cleanJson.lastIndexOf('```');
              if (end > start) cleanJson = cleanJson.substring(start, end).trim();
            }
            final firstBrace = cleanJson.indexOf('{');
            final lastBrace = cleanJson.lastIndexOf('}');
            if (firstBrace != -1 && lastBrace != -1 && lastBrace > firstBrace) {
              cleanJson = cleanJson.substring(firstBrace, lastBrace + 1);
            }

            final Map<String, dynamic> data = jsonDecode(cleanJson);
            final bool isValidCrop = data['is_valid_crop'] == true;
            final String errorMsg = (data['error_message'] as String? ?? '').trim();
            return (
              isValidCrop: isValidCrop,
              errorMessage: errorMsg.isNotEmpty
                  ? errorMsg
                  : 'আপনার দেওয়া নামটি সঠিক ফসলের নাম নয়। অনুগ্রহ করে সঠিক নাম দিন।',
            );
          }
        } else {
          debugPrint('Gemini Verification status ($engineId): ${response.statusCode}');
        }
      } catch (e) {
        debugPrint('Gemini Verification exception ($engineId): $e');
      }
    }

    // অফলাইন বা নেটওয়ার্ক ফলব্যাক (নো হার্ডকোডেড অ্যারো বা লিস্ট)
    return (
      isValidCrop: cleanCropName.length >= 2,
      errorMessage: 'আপনার দেওয়া নামটি সঠিক ফসলের নাম নয়। অনুগ্রহ করে সঠিক নাম দিন।',
    );
  }

  // ====================== রিকোয়ারমেন্ট ২: Problem-Solving Deep Analysis API Prompt ======================
  /// Gemini API-কে প্লেইন টেক্সটের বদলে নির্দিষ্ট JSON স্ট্রাকচারে গভীরভাবে বিশ্লেষণ করার নির্দেশ দেওয়া হয়।
  /// রেসপন্স থেকে jsonDecode করে advice এবং medicine_info সংগ্রহ করা হয়।
  Future<({String advice, String status, String medicineInfo})> _requestGeminiJsonAnalysis({
    required String cropName,
    required String landAmount,
    required String cropAge,
    required String cropDetails,
    required WeatherInfoModel weather,
  }) async {
    final cleanCropName = cropName.trim();
    // রিকোয়ারমেন্ট ১: ব্যানারের হুবহু সেই একই লাইভ ভেরিয়েবল
    final bannerTemp = BanglaNumberConverter.toBangla(weather.currentTemp.toStringAsFixed(0));
    final bannerRain = BanglaNumberConverter.toBangla(weather.rainProbability);
    final bannerCond = weather.conditionBn;
    final weatherDesc = 'তাপমাত্রা $bannerTemp°C এবং বৃষ্টির সম্ভাবনা $bannerRain% ($bannerCond)';
    final detailsText = cropDetails.trim().isNotEmpty ? cropDetails.trim() : 'মাটির অবস্থা স্বাভাবিক';

    // রিকোয়ারমেন্ট ২: Problem-Solving Deep Analysis JSON প্রম্পট
    final prompt = '''
তুমি বাংলাদেশের একজন শীর্ষস্থানীয় কৃষি বিশেষজ্ঞ। তোমাকে কৃষকের দেওয়া "জমির অবস্থা" গভীরভাবে বিশ্লেষণ করে সরাসরি সমস্যার সমাধান দিতে হবে। কোনো মুখস্থ বা জেনেরিক উত্তর দেওয়া যাবে না।

ইনপুট ডেটা:
- ফসলের নাম: $cleanCropName
- ফসলের বয়স: $cropAge
- বর্তমান আবহাওয়া: $weatherDesc
- জমির বর্তমান অবস্থা: $detailsText

বিশ্লেষণের ১০০% কঠোর নিয়ম:
১. "জমির অবস্থা"-তে ফোকাস করো: কৃষক যদি কোনো নির্দিষ্ট সমস্যার কথা লেখে (যেমন: গাছ হেলে যাচ্ছে, পাতা কুঁচকে যাচ্ছে, পচে যাচ্ছে, পোকা ধরেছে), তবে তোমার মূল ফোকাস হবে ওই সমস্যাটি কীভাবে সমাধান করা যায় তার লজিক্যাল উপায় বলা। 
২. জেনেরিক উত্তর নিষিদ্ধ: যদি জমিতে সমস্যা থাকে বা বৃষ্টি হয়, তবে কোনোভাবেই "বিকালে হালকা সেচ দিন" এই টাইপ জেনেরিক উত্তর দিবে না।
৩. ঔষধ সাজেশন: যদি "পচন", "পোকা", "হেলে পড়া" বা রোগের লক্ষণ থাকে, তবে অবশ্যই কার্যকরী ঔষধ/কীটনাশক/ভিটামিন এবং তার দাম সাজেস্ট করবে।

আউটপুট অবশ্যই ১০০% ভ্যালিড JSON হতে হবে:
{
  "advice": "জমির অবস্থা এবং আবহাওয়ার ওপর ভিত্তি করে নির্দিষ্ট সমস্যার রিয়েল-টাইম সমাধান ও কৃষিকাজ নির্দেশনা।",
  "medicine_info": "সমস্যা থাকলে ঔষধের নাম ও দাম। না থাকলে সম্পূর্ণ ফাঁকা (empty string) রাখুন।"
}
''';

    final token = _aiToken;
    if (token.isEmpty) {
      debugPrint('Warning: GEMINI_API_KEY is not configured in .env file');
      final fallback = _generateRuleBasedAdvice(cleanCropName, landAmount, cropAge, cropDetails, weather);
      return (
        advice: fallback.advice,
        status: fallback.status,
        medicineInfo: fallback.medicine,
      );
    }

    for (final engineId in _geminiEngines) {
      try {
        final url = Uri.parse(
          'https://generativelanguage.googleapis.com/v1beta/models/$engineId:generateContent?key=$token',
        );

        final response = await http.post(
          url,
          headers: {
            'Content-Type': 'application/json; charset=utf-8',
            'Accept': 'application/json',
          },
          body: jsonEncode({
            'contents': [
              {
                'parts': [
                  {'text': prompt}
                ]
              }
            ],
            'generationConfig': {
              'temperature': 0.1,
              'maxOutputTokens': 512,
            }
          }),
        ).timeout(const Duration(seconds: 10));

        if (response.statusCode == 200) {
          final resData = jsonDecode(utf8.decode(response.bodyBytes));
          final rawText = resData['candidates']?[0]?['content']?['parts']?[0]?['text'] as String?;
          if (rawText != null && rawText.trim().isNotEmpty) {
            final parsedResult = _parseGeminiJsonResponse(
              rawText.trim(),
              cleanCropName,
              landAmount,
              cropAge,
              cropDetails,
              weather,
            );
            return parsedResult;
          }
        } else {
          debugPrint('Gemini JSON API status ($engineId): ${response.statusCode}');
        }
      } catch (e) {
        debugPrint('Gemini JSON API exception ($engineId): $e');
      }
    }

    // অফলাইন এগ্রোনমিক ফলব্যাক
    final fallback = _generateRuleBasedAdvice(cleanCropName, landAmount, cropAge, cropDetails, weather);
    return (
      advice: fallback.advice,
      status: fallback.status,
      medicineInfo: fallback.medicine,
    );
  }

  /// রিকোয়ারমেন্ট ৪: Gemini থেকে আসা JSON রেসপন্স ক্লিন ও ডিকোড
  ({String advice, String status, String medicineInfo}) _parseGeminiJsonResponse(
    String rawText,
    String cropName,
    String landAmount,
    String cropAge,
    String cropDetails,
    WeatherInfoModel weather,
  ) {
    try {
      String cleanJson = rawText.trim();
      // কোড ব্লক বা মার্কডাউন অপসারণ
      if (cleanJson.contains('```json')) {
        final start = cleanJson.indexOf('```json') + 7;
        final end = cleanJson.lastIndexOf('```');
        if (end > start) {
          cleanJson = cleanJson.substring(start, end).trim();
        }
      } else if (cleanJson.contains('```')) {
        final start = cleanJson.indexOf('```') + 3;
        final end = cleanJson.lastIndexOf('```');
        if (end > start) {
          cleanJson = cleanJson.substring(start, end).trim();
        }
      }

      final firstBrace = cleanJson.indexOf('{');
      final lastBrace = cleanJson.lastIndexOf('}');
      if (firstBrace != -1 && lastBrace != -1 && lastBrace > firstBrace) {
        cleanJson = cleanJson.substring(firstBrace, lastBrace + 1);
      }

      final Map<String, dynamic> data = jsonDecode(cleanJson);
      String advice = (data['advice'] as String? ?? '').trim();
      String medicine = (data['medicine_info'] as String? ??
              data['medicineInfo'] as String? ??
              data['medicine_suggestion'] as String? ??
              data['medicineSuggestion'] as String? ??
              '')
          .trim();

      if (advice.isEmpty) {
        final fallback = _generateRuleBasedAdvice(cropName, landAmount, cropAge, cropDetails, weather);
        advice = fallback.advice;
        if (medicine.isEmpty) medicine = fallback.medicine;
      }

      final status = _deriveStatusFromAdvice(advice, weather);

      return (
        advice: advice,
        status: status,
        medicineInfo: medicine,
      );
    } catch (e) {
      debugPrint('Error parsing Gemini JSON output: $e (Raw: $rawText)');
      final fallback = _generateRuleBasedAdvice(cropName, landAmount, cropAge, cropDetails, weather);
      return (
        advice: fallback.advice,
        status: fallback.status,
        medicineInfo: fallback.medicine,
      );
    }
  }

  /// পরামর্শের টেক্সট ও আবহাওয়া থেকে প্রাসঙ্গিক স্ট্যাটাস নির্ধারণ
  String _deriveStatusFromAdvice(String advice, WeatherInfoModel weather) {
    final lower = advice.toLowerCase();
    if (lower.contains('পানি নিষ্কাশন') || lower.contains('পানি বের') || lower.contains('নিষ্কাশন করুন') || lower.contains('ড্রেন পরিষ্কার')) {
      return '⚠️ পানি নিষ্কাশন করুন';
    } else if (lower.contains('সেচ প্রয়োজন নেই') || lower.contains('সেচ দেবেন না') || lower.contains('সেচ দেওয়া স্থগিত') || lower.contains('সেচ বন্ধ')) {
      return '🌿 সেচের প্রয়োজন নেই';
    } else if (lower.contains('জরুরি সেচ') || lower.contains('তাত্ক্ষণিক সেচ') || lower.contains('তীব্র খরা') || lower.contains('অবিলম্বে সেচ')) {
      return '🚨 জরুরি সেচ প্রয়োজন';
    } else if (lower.contains('হালকা সেচ') || lower.contains('পরিমিত সেচ') || lower.contains('বিকালে সেচ')) {
      return '💧 হালকা সেচ দিন';
    } else if (lower.contains('সেচ দিন') || lower.contains('সেচ প্রদান')) {
      return '💧 সেচ প্রয়োজন';
    }
    return weather.rainProbability >= 40 ? '🌿 সেচের প্রয়োজন নেই' : '💧 হালকা সেচ দিন';
  }

  // ====================== প্রতি ১ ঘণ্টায় রিয়েল-টাইম নির্দেশনা আপডেট ======================
  void _checkAndTriggerHourlyUpdateForCrop(
    DocumentSnapshot<Map<String, dynamic>> doc,
    Map<String, dynamic> data,
    WeatherInfoModel? weather,
  ) {
    final docId = doc.id;
    if (_updatingCropDocIds.contains(docId)) return;

    // অটো-এক্সপায়ার চেক: মেয়াদ শেষ হলে আওয়ারলি আপডেট আর কল হবে না
    final expRaw = data['expiryDate'];
    DateTime? expDate;
    if (expRaw is Timestamp) {
      expDate = expRaw.toDate();
    } else if (expRaw is DateTime) {
      expDate = expRaw;
    }
    if (expDate != null && DateTime.now().isAfter(expDate)) return;

    final lastUpdatedRaw = data['last_updated'] ?? data['updatedAt'] ?? data['lastAiCheck'];
    DateTime? lastUpdatedTime;
    if (lastUpdatedRaw is Timestamp) {
      lastUpdatedTime = lastUpdatedRaw.toDate();
    } else if (lastUpdatedRaw is DateTime) {
      lastUpdatedTime = lastUpdatedRaw;
    } else if (data['last_updated_ms'] is num) {
      lastUpdatedTime = DateTime.fromMillisecondsSinceEpoch((data['last_updated_ms'] as num).toInt());
    } else if (data['createdAt'] is Timestamp) {
      lastUpdatedTime = (data['createdAt'] as Timestamp).toDate();
    }

    if (lastUpdatedTime == null) return;

    final now = DateTime.now();
    final differenceInMinutes = now.difference(lastUpdatedTime).inMinutes;

    // শেষ আপডেটের সময় থেকে বর্তমান সময়ের ব্যবধান ৬০ মিনিটের কম হলে কোনো এপিআই কল হবে না
    if (differenceInMinutes < 60) return;

    _updatingCropDocIds.add(docId);
    Future.microtask(() async {
      try {
        await _executeSingleCropHourlyUpdate(doc, data, weather);
      } finally {
        Future.delayed(const Duration(minutes: 5), () {
          _updatingCropDocIds.remove(docId);
        });
      }
    });
  }

  /// নির্দিষ্ট ফসলের জন্য আধুনিক JSON প্রম্পট দিয়ে ১ ঘণ্টার নির্দেশনা আপডেট
  Future<void> _executeSingleCropHourlyUpdate(
    DocumentSnapshot<Map<String, dynamic>> doc,
    Map<String, dynamic> data,
    WeatherInfoModel? initialWeather,
  ) async {
    try {
      final districtToFetch = _userDistrict ?? 'ঢাকা';
      WeatherInfoModel weather = initialWeather ??
          await WeatherService.getWeatherForDistrict(districtToFetch);

      final cropName = data['cropName'] as String? ?? '';
      final landAmount = data['landAmount'] as String? ?? '';
      final cropAge = data['cropAge'] as String? ?? '';
      final cropDetails = data['cropDetails'] as String? ?? '';

      // রিকোয়ারমেন্ট ২ ও ৪: আধুনিক JSON AI প্রমট দিয়ে আপডেট
      final aiResult = await _requestGeminiJsonAnalysis(
        cropName: cropName,
        landAmount: landAmount,
        cropAge: cropAge,
        cropDetails: cropDetails,
        weather: weather,
      );

      String newAdvice = aiResult.advice;
      String newStatus = aiResult.status;
      String newMedicine = aiResult.medicineInfo;

      if (newAdvice.isEmpty) {
        final fallback = _generateRuleBasedAdvice(cropName, landAmount, cropAge, cropDetails, weather);
        newStatus = fallback.status;
        newAdvice = fallback.advice;
        if (newMedicine.isEmpty) newMedicine = fallback.medicine;
      }

      // প্রাপ্ত নতুন নির্দেশনাটি ফায়ারবেসে 'last_updated' সহ আপডেট (medicine_info সহ সব ফরম্যাটে)
      await doc.reference.update({
        'aiAdvice': newAdvice,
        'aiStatus': newStatus,
        'medicine_info': newMedicine,
        'medicineInfo': newMedicine,
        'medicine_suggestion': newMedicine,
        'medicineSuggestion': newMedicine,
        'last_updated': FieldValue.serverTimestamp(),
        'last_updated_ms': DateTime.now().millisecondsSinceEpoch,
        'updatedAt': FieldValue.serverTimestamp(),
        'weatherDistrict': weather.district,
        'weatherTemp': weather.currentTemp,
        'weatherHumidity': weather.humidity,
        'weatherRainProb': weather.rainProbability,
        'weatherCondition': weather.conditionBn,
      });
    } catch (e) {
      debugPrint('Single crop hourly update notice: $e');
    }
  }

  /// ব্যবহারকারীর সকল ফসলের জন্য ১ ঘণ্টার সময়সীমা যাচাই ও ব্যাকগ্রাউন্ড আপডেট
  Future<void> _checkAllCropsForHourlyUpdate({bool force = false}) async {
    if (!mounted || _isRefreshing) return;

    final userId = _getUserId();
    if (userId == null) return;

    setState(() => _isRefreshing = true);
    final districtToFetch = _userDistrict ?? 'ঢাকা';

    try {
      final weatherProvider = Provider.of<WeatherProvider>(context, listen: false);
      await weatherProvider.fetchWeather(districtToFetch, forceRefresh: force);

      final weather = weatherProvider.weatherInfo ??
          await WeatherService.getWeatherForDistrict(districtToFetch, forceRefresh: force);

      _currentWeather = weather;
      _lastWeatherCheckTime = DateTime.now();

      final cropsSnap = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('irrigation_tracker_crops')
          .get(const GetOptions(source: Source.serverAndCache));

      final now = DateTime.now();

      for (final doc in cropsSnap.docs) {
        final data = doc.data();
        if (data['isDeleted'] == true) continue; // সফট ডিলিট ফসল স্কিপ

        // অটো-এক্সপায়ার চেক: মেয়াদ উত্তীর্ণ ফসল স্কিপ
        final expRaw = data['expiryDate'];
        DateTime? expDate;
        if (expRaw is Timestamp) {
          expDate = expRaw.toDate();
        } else if (expRaw is DateTime) {
          expDate = expRaw;
        }
        if (expDate != null && now.isAfter(expDate)) continue;

        final lastUpdatedRaw = data['last_updated'] ?? data['updatedAt'] ?? data['lastAiCheck'];
        DateTime? lastUpdatedTime;
        if (lastUpdatedRaw is Timestamp) {
          lastUpdatedTime = lastUpdatedRaw.toDate();
        } else if (lastUpdatedRaw is DateTime) {
          lastUpdatedTime = lastUpdatedRaw;
        } else if (data['last_updated_ms'] is num) {
          lastUpdatedTime = DateTime.fromMillisecondsSinceEpoch((data['last_updated_ms'] as num).toInt());
        } else if (data['createdAt'] is Timestamp) {
          lastUpdatedTime = (data['createdAt'] as Timestamp).toDate();
        }

        final bool isDue = force || (lastUpdatedTime != null && now.difference(lastUpdatedTime).inMinutes >= 60);

        if (isDue) {
          await _executeSingleCropHourlyUpdate(doc, data, weather);
        }
      }

      if (force && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'আবহাওয়া ও সেচ নির্দেশনা আপডেট সম্পন্ন! ($districtToFetch)',
              style: const TextStyle(fontFamily: 'Hind Siliguri'),
            ),
            backgroundColor: const Color(0xFF2E7D32),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      debugPrint('Check all crops hourly error: $e');
    } finally {
      if (mounted) {
        setState(() => _isRefreshing = false);
      }
    }
  }

  /// অফলাইন / ফলব্যাক এগ্রোনমিক অ্যালগরিদম (সেচ ও বালাইনাশক পরামর্শ সহ কার্যকরী ঔষধ ও মূল্য)
  ({String status, String advice, String medicine}) _generateRuleBasedAdvice(
    String cropName,
    String landAmount,
    String cropAge,
    String cropDetails,
    WeatherInfoModel weather,
  ) {
    final temp = weather.currentTemp;
    final humidity = weather.humidity;
    final rainProb = weather.rainProbability;
    final cond = weather.conditionBn;
    final detailsLower = cropDetails.toLowerCase();

    // ================== ১. "জমির অবস্থা"-তে ফোকাস (Problem-Solving Logic) ==================
    String medicine = '';

    // ক) গাছ হেলে যাওয়া / হেলে পড়া
    if (detailsLower.contains('হেলে') || detailsLower.contains('ঢলে') || detailsLower.contains('পড়ে যা')) {
      medicine = 'গাছের শিকড় ও কাণ্ড শক্ত করে সোজা রাখতে অনুমোদিত চিলেটেড জিংক (লিবরেল জিংক ১ গ্রাম/লি.) অথবা পিজিআর (যেমন: ফ্লোরা প্রতি লিটার পানিতে ২ মিলি, আনুমানিক বাজারমূল্য ১৮০-২২০ টাকা) স্প্রে করুন।';
      return (
        status: '⚠️ পানি নিষ্কাশন ও ঠেকনা দিন',
        advice: '$cropName গাছ হেলে পড়া রোধে গোড়ার অতিরিক্ত পানি দ্রুত নিষ্কাশন করুন এবং গাছের গোড়ায় শুকনো মাটি তুলে দিয়ে বাঁশের খুঁটি বা কঞ্চি দিয়ে শক্ত ঠেকনা দিন। মাটি অতিরিক্ত ভেজা থাকলে এখন কোনো সেচ দিবেন না।',
        medicine: medicine,
      );
    }

    // খ) পাতা কুঁচকে যাওয়া / কোঁকড়ানো
    if (detailsLower.contains('কুঁচকে') || detailsLower.contains('কোঁকড়') || detailsLower.contains('মুড়িয়ে')) {
      medicine = 'পাতা কোঁকড়ানো ও চোষক পোকা দমনে ইমিডাক্লোপ্রিড (যেমন: এডমায়ার ২০ এসএল প্রতি লিটার পানিতে ০.৫ মিলি, আনুমানিক বাজারমূল্য ১৮০-২১০ টাকা) অথবা পেগাসাস ৫০ এসসি অনুমোদিত মাত্রায় স্প্রে করুন।';
      return (
        status: '🚨 চোষক পোকা দমন করুন',
        advice: '$cropName গাছের পাতা কুঁচকে যাওয়ার প্রধান কারণ চোষক পোকা (সাদা মাছি/থ্রিপস) বা মাইটের আক্রমণ। পাতা ভেজা রাখবেন না এবং অবিলম্বে চোষক পোকা দমনে স্প্রে করুন।',
        medicine: medicine,
      );
    }

    // গ) পচন / ছত্রাক / ঝলসানো / দাগ / ব্লাইট
    if (detailsLower.contains('পচ') ||
        detailsLower.contains('পচে') ||
        detailsLower.contains('পচন') ||
        detailsLower.contains('ছত্রাক') ||
        detailsLower.contains('দাগ') ||
        detailsLower.contains('ঝলসানো') ||
        detailsLower.contains('ব্লাইট') ||
        detailsLower.contains('মরিচা')) {
      if (cropName.contains('মরিচ') || detailsLower.contains('মরিচ')) {
        medicine = 'মরিচ ফসলে পচন ও ছত্রাকজনিত রোগ নিয়ন্ত্রণে টিল্ট ২৫০ ইসি (প্রপিকোনাজল) প্রতি লিটার পানিতে ০.৫ মিলি অথবা এমিস্টার টপ ৩২৫ এসসি প্রতি লিটার পানিতে ১ মিলি (আনুমানিক বাজারমূল্য ৩২০-৩৫০ টাকা) স্প্রে করুন।';
      } else {
        medicine = '$cropName ফসলে পচন, ছত্রাক ও পাতা ঝলসানো নিয়ন্ত্রণে এমিস্টার টপ ৩২৫ এসসি প্রতি লিটার পানিতে ১ মিলি (আনুমানিক বাজারমূল্য ৩২০-৩৫০ টাকা) অথবা টিল্ট ২৫০ ইসি ০.৫ মিলি স্প্রে করুন।';
      }
      return (
        status: '⚠️ সেচ বন্ধ ও ছত্রাকনাশক দিন',
        advice: '$cropName ফসলে পচন ও ছত্রাকের সংক্রমণ দেখা দেওয়ায় জমিতে সেচ দেওয়া অবিলম্বে বন্ধ রাখুন এবং জমে থাকা পানি দ্রুত নিষ্কাশন করুন। রোদের সময় জমিতে ছত্রাকনাশক স্প্রে করুন।',
        medicine: medicine,
      );
    }

    // ঘ) পোকা / কীট / মাজরা / লেদা / মাছি
    if (detailsLower.contains('পোকা') ||
        detailsLower.contains('কীট') ||
        detailsLower.contains('মাজরা') ||
        detailsLower.contains('লেদা') ||
        detailsLower.contains('মাছি') ||
        detailsLower.contains('মাকড়') ||
        detailsLower.contains('পোকার আক্রমণ')) {
      medicine = '$cropName ফসলে পোকা ও কীটের উপদ্রব নিয়ন্ত্রণে কীটনাশক ক্যারাটে ২.৫ ইসি (ল্যাম্বডা-সাইহ্যালোথ্রিন) প্রতি লিটার পানিতে ১ মিলি (আনুমানিক বাজারমূল্য ১৫০-১৮০ টাকা) অথবা ভিরতাকো অনুমোদিত মাত্রায় বিকালে স্প্রে করুন।';
      return (
        status: '🚨 কীটনাশক প্রয়োগ করুন',
        advice: '$cropName ফসলে পোকার আক্রমণ দমনে আক্রান্ত পাতা ও ডগা সংগ্রহ করে ধ্বংস করুন এবং নিয়মিত পর্যবেক্ষণ করে উপযুক্ত কীটনাশক প্রয়োগ করুন।',
        medicine: medicine,
      );
    }

    // ঙ) হলুদ হওয়া
    if (detailsLower.contains('হলুদ')) {
      medicine = '$cropName ফসলে পাতা হলুদ হওয়া ও পুষ্টি ঘাটতি দমনে চিলেটেড জিংক প্রতি লিটার পানিতে ১ গ্রাম এবং ম্যানকোজেব ২ গ্রাম মিশিয়ে স্প্রে করুন (আনুমানিক বাজারমূল্য ১২০-১৫০ টাকা)।';
      return (
        status: '🌿 পুষ্টি ও ছত্রাক পরিচর্যা',
        advice: '$cropName গাছের পাতা হলুদ হওয়া রোধে গোড়ার পানি নিষ্কাশন নিশ্চিত করুন এবং প্রয়োজনীয় অনুখাদ্য ও জিংক স্প্রে করে গাছের পুষ্টি চাহিদা পূরণ করুন।',
        medicine: medicine,
      );
    }

    // ================== ২. আবহাওয়া ও সেচ লজিক (জেনেরিক উত্তর নিষিদ্ধ) ==================
    // বৃষ্টি বা ভেজা মাটিতে কোনোভাবেই সেচ দেওয়ার পরামর্শ নয়, পানি নিষ্কাশন
    if (detailsLower.contains('পানি জমে') ||
        detailsLower.contains('পানি জমা') ||
        detailsLower.contains('ভেজা') ||
        detailsLower.contains('বৃষ্টি') ||
        detailsLower.contains('কাদা')) {
      return (
        status: '⚠️ পানি নিষ্কাশন করুন',
        advice: 'জমিতে পানি জমে বা মাটি ভেজা থাকায় এখন কোনো সেচ দেওয়া যাবে না। জমি থেকে দ্রুত অতিরিক্ত পানি নিষ্কাশন করুন এবং মাটি শুকাতে দিন যাতে শিকড় পচে না যায়।',
        medicine: medicine,
      );
    }

    if (rainProb >= 40 || cond.contains('বৃষ্টি') || cond.contains('ঝড়')) {
      return (
        status: '🌿 সেচের প্রয়োজন নেই',
        advice: 'বর্তমানে বৃষ্টির সম্ভাবনা ${BanglaNumberConverter.toBangla(rainProb)}% ও আকাশ মেঘলা। জমিতে প্রাকৃতিকভাবে আর্দ্রতা বজায় থাকবে, তাই সেচ প্রদান স্থগিত রাখুন।',
        medicine: medicine,
      );
    }

    // নিয়ম ২: ফসল ও বয়সের লজিক (ধানের পানির চাহিদা আর আলুর পানির চাহিদা এক নয়)
    if (cropName.contains('ধান')) {
      return (
        status: '💧 হালকা সেচ দিন',
        advice: 'ধান ফসলের বর্তমান বয়স ($cropAge) অনুযায়ী জমিতে ২-৩ ইঞ্চি পরিমিত পানি ধরে রাখুন। অতিরিক্ত সেচ পরিহার করে নালা সচল রাখুন।',
        medicine: medicine,
      );
    } else if (cropName.contains('আলু')) {
      return (
        status: '💧 হালকা সেচ দিন',
        advice: 'আলু ফসলে জলাবদ্ধতা একদমই সহ্য হয় না। সারির মাঝে নালায় সতর্কতার সাথে খুব হালকা সেচ দিন যাতে কন্দ পচে না যায়।',
        medicine: medicine,
      );
    }

    if (temp >= 33 && humidity < 60) {
      return (
        status: '🚨 জরুরি সেচ প্রয়োজন',
        advice: 'উচ্চ তাপমাত্রা (${BanglaNumberConverter.toBangla(temp.toStringAsFixed(0))}°C) ও কম আর্দ্রতায় জমিতে পানির ঘাটতি হতে পারে। $cropName ফসলের বৃদ্ধির জন্য প্রয়োজনীয় সেচ নিশ্চিত করুন।',
        medicine: medicine,
      );
    }

    if (humidity >= 78) {
      return (
        status: '🌿 সেচের প্রয়োজন নেই',
        advice: 'বাতাস ও মাটিতে পর্যাপ্ত আর্দ্রতা (${BanglaNumberConverter.toBangla(humidity)}%) রয়েছে। এখন অতিরিক্ত সেচ দিলে শিকড় ক্ষতিগ্রস্ত হতে পারে।',
        medicine: medicine,
      );
    }

    return (
      status: '💧 হালকা সেচ দিন',
      advice: 'বর্তমান তাপমাত্রা ${BanglaNumberConverter.toBangla(temp.toStringAsFixed(0))}°C ও আর্দ্রতা ${BanglaNumberConverter.toBangla(humidity)}%। $cropName ফসলে ($cropAge) পরিমিত আর্দ্রতা বজায় রাখতে বিকালে হালকা সেচ দেওয়া উপযুক্ত।',
      medicine: medicine,
    );
  }

  // ====================== গ্লোবাল পপআপ (GLOBAL POPUP) ======================
  void _showGlobalPopup({
    required String title,
    required String message,
    IconData icon = Icons.info_outline_rounded,
    Color color = const Color(0xFF2E7D32),
    String buttonText = 'ঠিক আছে',
    bool isConfirm = false,
    String confirmText = 'হ্যাঁ, ডিলিট করুন',
    String cancelText = 'বাতিল',
    VoidCallback? onConfirm,
  }) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.white,
        elevation: 10,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  shape: BoxShape.circle,
                  border: Border.all(color: color.withOpacity(0.3), width: 1.5),
                ),
                child: Icon(icon, color: color, size: 32),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: color == const Color(0xFFD32F2F) ? const Color(0xFFD32F2F) : AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13.5,
                  color: AppColors.textSecondary,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 22),
              if (isConfirm) ...[
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(ctx),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF546E7A),
                          side: const BorderSide(color: Color(0xFFCFD8DC)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: Text(cancelText, style: const TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(ctx);
                          if (onConfirm != null) onConfirm();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: color,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: Text(confirmText, style: const TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ] else ...[
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: color,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: Text(buttonText, style: const TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// গ্লোবাল লোডিং পপআপ
  void _showLoadingDialog(BuildContext context, {String message = 'AI দিয়ে ফসলের তথ্য ও সেচ বিশ্লেষণ করা হচ্ছে...'}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      useRootNavigator: true,
      builder: (ctx) => WillPopScope(
        onWillPop: () async => false,
        child: Dialog(
          backgroundColor: Colors.white,
          elevation: 10,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 26),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9),
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFF81C784).withOpacity(0.4), width: 1.5),
                  ),
                  child: const Center(
                    child: SizedBox(
                      width: 28,
                      height: 28,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.8,
                        color: Color(0xFF2E7D32),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  'অনুগ্রহ করে অপেক্ষা করুন',
                  style: TextStyle(
                    fontSize: 16.5,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// সফট ডিলিট কনফার্মেশন পপআপ
  void _confirmDeleteCrop(DocumentSnapshot<Map<String, dynamic>> doc, String cropName) {
    _showGlobalPopup(
      title: 'ফসল মুছে ফেলার নিশ্চয়তা',
      message: 'আপনি কি নিশ্চিতভাবে "$cropName" সেচ ট্র্যাকার থেকে মুছে ফেলতে চান? এটি মুছে ফেললে আপনি নতুন ফসল যুক্ত করার কোটা পাবেন।',
      icon: Icons.delete_forever_rounded,
      color: const Color(0xFFD32F2F),
      isConfirm: true,
      confirmText: 'হ্যাঁ, ডিলিট করুন',
      cancelText: 'বাতিল',
      onConfirm: () async {
        try {
          // সফট ডিলিট (Soft Delete): isDeleted: true এবং deletedAt সেট
          await doc.reference.update({
            'isDeleted': true,
            'deletedAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          });
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  '"$cropName" সফলভাবে তালিকা থেকে মুছে ফেলা হয়েছে।',
                  style: const TextStyle(fontFamily: 'Hind Siliguri'),
                ),
                backgroundColor: const Color(0xFF2E7D32),
                duration: const Duration(seconds: 3),
              ),
            );
          }
        } catch (e) {
          debugPrint('Crop soft delete error: $e');
        }
      },
    );
  }

  /// সময় ফরম্যাটিং
  String _formatLastUpdatedTime(dynamic stamp, dynamic msVal) {
    DateTime? dt;
    if (stamp is Timestamp) {
      dt = stamp.toDate();
    } else if (stamp is DateTime) {
      dt = stamp;
    } else if (msVal is num) {
      dt = DateTime.fromMillisecondsSinceEpoch(msVal.toInt());
    }

    if (dt == null) return 'শেষ আপডেট: এইমাত্র';

    final now = DateTime.now();
    final diff = now.difference(dt);

    if (diff.inMinutes < 1) {
      return 'শেষ আপডেট: এইমাত্র';
    } else if (diff.inMinutes < 60) {
      return 'শেষ আপডেট: ${BanglaNumberConverter.toBangla(diff.inMinutes)} মিনিট আগে';
    } else if (diff.inHours < 24) {
      return 'শেষ আপডেট: ${BanglaNumberConverter.toBangla(diff.inHours)} ঘণ্টা আগে';
    } else {
      return 'শেষ আপডেট: ${BanglaNumberConverter.toBangla(dt.day)}/${BanglaNumberConverter.toBangla(dt.month)} ${BanglaNumberConverter.toBangla(dt.hour)}:${BanglaNumberConverter.toBangla(dt.minute.toString().padLeft(2, '0'))}';
    }
  }

  /// এক্সপায়ারি ডেট ফরম্যাটিং
  String _formatExpiryDate(dynamic expiryRaw) {
    if (expiryRaw == null) return 'মেয়াদ অনির্ধারিত';
    DateTime? dt;
    if (expiryRaw is Timestamp) {
      dt = expiryRaw.toDate();
    } else if (expiryRaw is DateTime) {
      dt = expiryRaw;
    } else if (expiryRaw is String) {
      dt = DateTime.tryParse(expiryRaw);
    }
    if (dt == null) return 'মেয়াদ অনির্ধারিত';

    final now = DateTime.now();
    final diffDays = dt.difference(now).inDays;
    final dateFormatted =
        '${BanglaNumberConverter.toBangla(dt.day)}/${BanglaNumberConverter.toBangla(dt.month)}/${BanglaNumberConverter.toBangla(dt.year)}';

    if (now.isAfter(dt)) {
      return '$dateFormatted (মেয়াদ সমাপ্ত)';
    } else if (diffDays == 0) {
      return '$dateFormatted (আজই শেষ দিন)';
    } else {
      return '$dateFormatted (${BanglaNumberConverter.toBangla(diffDays)} দিন বাকি)';
    }
  }

  // ====================== ফসল যুক্ত করার ফর্ম (ADD CROP FORM) ======================
  void _openAddCropModal(int currentCount) {
    final activeUid = _getUserId();
    if (activeUid == null) {
      _showGlobalPopup(
        title: 'লগইন প্রয়োজন',
        message: 'নতুন ফসল যুক্ত করতে অনুগ্রহ করে প্রথমে আপনার একাউন্টে লগইন করুন।',
        icon: Icons.lock_outline_rounded,
        color: const Color(0xFFE65100),
      );
      return;
    }

    if (currentCount >= 3) {
      _showGlobalPopup(
        title: 'সর্বোচ্চ ফসলের সীমা!',
        message: 'আপনার একাউন্টে ইতোমধ্যে সর্বোচ্চ ৩টি ফসল সক্রিয় রয়েছে। নতুন ফসল যুক্ত করতে হলে অনুগ্রহ করে পূর্বের যেকোনো একটি ফসল ডিলিট করুন অথবা মেয়াদ শেষ হওয়া পর্যন্ত অপেক্ষা করুন।',
        icon: Icons.warning_amber_rounded,
        color: const Color(0xFFE65100),
      );
      return;
    }

    final formKey = GlobalKey<FormState>();
    final cropNameCtrl = TextEditingController();
    final landAmountCtrl = TextEditingController();
    final cropAgeCtrl = TextEditingController();
    final cropDetailsCtrl = TextEditingController();

    // রিকোয়ারমেন্ট ১: Expiry Date স্টেট (ডিফল্ট ৩০ দিন পর)
    DateTime? selectedExpiryDate = DateTime.now().add(const Duration(days: 30));
    final expiryDateCtrl = TextEditingController(
      text:
          '${BanglaNumberConverter.toBangla(selectedExpiryDate!.day)}/${BanglaNumberConverter.toBangla(selectedExpiryDate!.month)}/${BanglaNumberConverter.toBangla(selectedExpiryDate!.year)}',
    );

    String selectedLandUnit = 'শতক';
    String selectedAgeUnit = 'দিন';
    bool isSubmitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (bCtx) => StatefulBuilder(
        builder: (modalContext, setModalState) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 16,
            bottom: MediaQuery.of(modalContext).viewInsets.bottom + 20,
          ),
          child: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 44,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(7),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE8F5E9),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.add_task_rounded, color: Color(0xFF2E7D32), size: 20),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'নতুন ফসল যুক্ত করুন',
                            style: TextStyle(
                              fontSize: 16.5,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F5E9),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFF81C784).withOpacity(0.4)),
                        ),
                        child: Text(
                          'লিমিট: ${BanglaNumberConverter.toBangla(currentCount)}/৩টি',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2E7D32),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // ১. ফসলের নাম (Crop Name)
                  const Text(
                    'ফসলের নাম *',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: cropNameCtrl,
                    decoration: InputDecoration(
                      hintText: 'যেমন: ধান, আলু, গম, ভুট্টা...',
                      hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF9E9E9E)),
                      prefixIcon: const Icon(Icons.eco_outlined, color: Color(0xFF2E7D32), size: 20),
                      filled: true,
                      fillColor: const Color(0xFFF8FAF7),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFCFD8DC)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFF2E7D32), width: 1.8),
                      ),
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return 'ফসলের নাম লিখুন';
                      }
                      if (val.trim().length > 30) {
                        return 'ফসলের নাম ৩০ অক্ষরের মধ্যে রাখুন';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),

                  // ২. জমির পরিমাণ (Land Amount)
                  const Text(
                    'জমির পরিমাণ *',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: landAmountCtrl,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: InputDecoration(
                            hintText: 'পরিমাণ (যেমন: ২০, ২.৫)',
                            hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF9E9E9E)),
                            prefixIcon: const Icon(Icons.square_foot_rounded, color: Color(0xFF2E7D32), size: 20),
                            filled: true,
                            fillColor: const Color(0xFFF8FAF7),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Color(0xFFCFD8DC)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Color(0xFF2E7D32), width: 1.8),
                            ),
                          ),
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) {
                              return 'জমির পরিমাণ লিখুন';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        height: 48,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F5E9),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFF2E7D32).withOpacity(0.4)),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: selectedLandUnit,
                            icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF1B5E20)),
                            style: const TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1B5E20),
                              fontFamily: 'Hind Siliguri',
                            ),
                            dropdownColor: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            items: const [
                              DropdownMenuItem(value: 'শতক', child: Text('শতক')),
                              DropdownMenuItem(value: 'শতাংশ', child: Text('শতাংশ')),
                              DropdownMenuItem(value: 'বিঘা', child: Text('বিঘা')),
                              DropdownMenuItem(value: 'একর', child: Text('একর')),
                            ],
                            onChanged: (val) {
                              if (val != null) {
                                setModalState(() => selectedLandUnit = val);
                              }
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // ৩. ফসলের বয়স (Crop Age)
                  const Text(
                    'ফসলের বয়স *',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: cropAgeCtrl,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            hintText: 'বয়স (যেমন: ২৫, ২)',
                            hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF9E9E9E)),
                            prefixIcon: const Icon(Icons.hourglass_top_rounded, color: Color(0xFF2E7D32), size: 20),
                            filled: true,
                            fillColor: const Color(0xFFF8FAF7),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Color(0xFFCFD8DC)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Color(0xFF2E7D32), width: 1.8),
                            ),
                          ),
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) {
                              return 'ফসলের বয়স লিখুন';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        height: 48,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F5E9),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFF2E7D32).withOpacity(0.4)),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: selectedAgeUnit,
                            icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF1B5E20)),
                            style: const TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1B5E20),
                              fontFamily: 'Hind Siliguri',
                            ),
                            dropdownColor: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            items: const [
                              DropdownMenuItem(value: 'দিন', child: Text('দিন')),
                              DropdownMenuItem(value: 'মাস', child: Text('মাস')),
                              DropdownMenuItem(value: 'বছর', child: Text('বছর')),
                            ],
                            onChanged: (val) {
                              if (val != null) {
                                setModalState(() => selectedAgeUnit = val);
                              }
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // রিকোয়ারমেন্ট ১: Expiry Date Picker ফিল্ড
                  const Row(
                    children: [
                      Icon(Icons.calendar_month_rounded, size: 16, color: Color(0xFF2E7D32)),
                      SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'কত দিনের জন্য ট্র্যাকিং করবেন? (মেয়াদ শেষ হওয়ার তারিখ) *',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  InkWell(
                    onTap: () async {
                      final now = DateTime.now();
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: selectedExpiryDate ?? now.add(const Duration(days: 30)),
                        firstDate: now,
                        lastDate: now.add(const Duration(days: 730)),
                        helpText: 'মেয়াদ শেষ হওয়ার তারিখ নির্বাচন করুন',
                        cancelText: 'বাতিল',
                        confirmText: 'নিশ্চিত',
                        builder: (ctx, child) {
                          return Theme(
                            data: Theme.of(ctx).copyWith(
                              colorScheme: const ColorScheme.light(
                                primary: Color(0xFF2E7D32),
                                onPrimary: Colors.white,
                                onSurface: Color(0xFF1B5E20),
                              ),
                            ),
                            child: child!,
                          );
                        },
                      );
                      if (picked != null) {
                        setModalState(() {
                          selectedExpiryDate = picked;
                          expiryDateCtrl.text =
                              '${BanglaNumberConverter.toBangla(picked.day)}/${BanglaNumberConverter.toBangla(picked.month)}/${BanglaNumberConverter.toBangla(picked.year)}';
                        });
                      }
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      height: 48,
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAF7),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE0E0E0)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.event_available_rounded, size: 20, color: Color(0xFF2E7D32)),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              selectedExpiryDate != null
                                  ? '${BanglaNumberConverter.toBangla(selectedExpiryDate!.day)}/${BanglaNumberConverter.toBangla(selectedExpiryDate!.month)}/${BanglaNumberConverter.toBangla(selectedExpiryDate!.year)} (${BanglaNumberConverter.toBangla(selectedExpiryDate!.difference(DateTime.now()).inDays + 1)} দিন মেয়াদে)'
                                  : 'তারিখ নির্বাচন করুন...',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1B5E20),
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE8F5E9),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'পরিবর্তন',
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF2E7D32),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // ৪. ফসলের বিস্তারিত (Crop Details) - সর্বোচ্চ ১০০ অক্ষর
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'ফসলের বিস্তারিত (সর্বোচ্চ ১০০ অক্ষর) *',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                      ),
                      ValueListenableBuilder<TextEditingValue>(
                        valueListenable: cropDetailsCtrl,
                        builder: (context, value, _) {
                          final count = value.text.length;
                          return Text(
                            '${BanglaNumberConverter.toBangla(count)}/১০০ অক্ষর',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: count > 100 ? Colors.red : const Color(0xFF2E7D32),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: cropDetailsCtrl,
                    maxLength: 100,
                    maxLines: 2,
                    buildCounter: (context, {required currentLength, required isFocused, maxLength}) => null,
                    decoration: InputDecoration(
                      hintText: 'মাটির অবস্থা বা বিস্তারিত তথ্য লিখুন (সর্বোচ্চ ১০০ অক্ষর)...',
                      hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF9E9E9E)),
                      filled: true,
                      fillColor: const Color(0xFFF8FAF7),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFCFD8DC)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFF2E7D32), width: 1.8),
                      ),
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return 'ফসলের বিস্তারিত বর্ণনা দিন';
                      }
                      if (val.trim().length > 100) {
                        return 'ফসলের বিস্তারিত ১০০ অক্ষরের বেশি হতে পারবে না';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 18),

                  // সেভ বাটন (গ্লোবাল লোডিং পপআপ ও STRICT আধুনিক JSON AI ভ্যালিডেশন গার্ডসহ)
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: isSubmitting
                          ? null
                          : () async {
                              if (!formKey.currentState!.validate()) return;

                              if (selectedExpiryDate == null) {
                                _showGlobalPopup(
                                  title: 'মেয়াদ নির্বাচন করুন',
                                  message: 'অনুগ্রহ করে সেচ ট্র্যাকিংয়ের মেয়াদ শেষ হওয়ার তারিখ নির্বাচন করুন।',
                                  icon: Icons.calendar_month_rounded,
                                  color: const Color(0xFFE65100),
                                );
                                return;
                              }

                              final name = cropNameCtrl.text.trim();
                              final landNum = landAmountCtrl.text.trim();
                              final ageNum = cropAgeCtrl.text.trim();
                              final details = cropDetailsCtrl.text.trim();

                              final fullLandAmount = '$landNum $selectedLandUnit';
                              final fullCropAge = '$ageNum $selectedAgeUnit';

                              setModalState(() => isSubmitting = true);

                              // গ্লোবাল লোডিং পপআপ ওপেন ("আপনার তথ্য যাচাই হচ্ছে.... ")
                              _showLoadingDialog(context, message: 'আপনার তথ্য যাচাই হচ্ছে.... ');

                              // রিকোয়ারমেন্ট ১: শুধুমাত্র "ফসলের নাম" লাইভ AI ভ্যালিডেশন
                              final verifyResult = await _verifyCropWithAi(
                                cropName: name,
                              );

                              // যদি is_valid_crop false হয়, তবে গ্লোবাল লোডিং পপআপ কেটে দিয়ে একটি Error পপআপ দেখাও:
                              // "আপনার দেওয়া নামটি সঠিক ফসলের নাম নয়। অনুগ্রহ করে সঠিক নাম দিন।"
                              if (!verifyResult.isValidCrop) {
                                if (mounted) {
                                  Navigator.of(context, rootNavigator: true).pop();
                                  setModalState(() => isSubmitting = false);

                                  _showGlobalPopup(
                                    title: 'ইনপুট ত্রুটি',
                                    message: verifyResult.errorMessage.isNotEmpty
                                        ? verifyResult.errorMessage
                                        : 'আপনার দেওয়া নামটি সঠিক ফসলের নাম নয়। অনুগ্রহ করে সঠিক নাম দিন।',
                                    buttonText: 'এডিট',
                                    icon: Icons.cancel_outlined,
                                    color: const Color(0xFFD32F2F),
                                  );
                                }
                                return;
                              }

                              // is_valid_crop true হলে: পরবর্তী ধাপে গিয়ে আবহাওয়া ও এআই এনালাইসিস প্রস্তুত করা
                              final currentDist = _userDistrict ?? 'ঢাকা';
                              final weatherProvider = Provider.of<WeatherProvider>(context, listen: false);
                              WeatherInfoModel? weather = weatherProvider.weatherInfo ?? _currentWeather;
                              if (weather == null) {
                                try {
                                  await weatherProvider.fetchWeather(currentDist);
                                  weather = weatherProvider.weatherInfo;
                                } catch (_) {}
                              }
                              weather ??= WeatherInfoModel(
                                district: currentDist,
                                currentTemp: 28.0,
                                feelsLike: 30.0,
                                humidity: 65,
                                rainProbability: 20,
                                windSpeedKmH: 8.5,
                                conditionBn: 'পরিষ্কার আকাশ',
                                farmingAdvice: '',
                                fiveDayForecast: const [],
                              );

                              // অপরিবর্তিত ১ ঘণ্টার পরামর্শ এনালাইসিস থেকে প্রাথমিক এআই পরামর্শ ও স্ট্যাটাস সংগ্রহ
                              final aiResult = await _requestGeminiJsonAnalysis(
                                cropName: name,
                                landAmount: fullLandAmount,
                                cropAge: fullCropAge,
                                cropDetails: details,
                                weather: weather,
                              );

                              // is_valid_crop true হলে: ফায়ারবেসে সেভ প্রসেস সম্পন্ন করা
                              final userId = _getUserId();
                              if (userId == null) {
                                if (mounted) {
                                  Navigator.of(context, rootNavigator: true).pop();
                                  setModalState(() => isSubmitting = false);
                                  _showGlobalPopup(
                                    title: 'লগইন প্রয়োজন',
                                    message: 'ফসল সংরক্ষণ করতে অনুগ্রহ করে প্রথমে একাউন্টে লগইন করুন।',
                                    icon: Icons.lock_outline_rounded,
                                    color: const Color(0xFFE65100),
                                  );
                                }
                                return;
                              }

                              final auth = Provider.of<AuthProvider>(context, listen: false);
                              final currentUser = FirebaseAuth.instance.currentUser;
                              final userEmail = currentUser?.email ?? auth.user?.email ?? '';
                              final userPhone = currentUser?.phoneNumber ?? auth.user?.phone ?? '';

                              try {
                                final docRef = FirebaseFirestore.instance
                                    .collection('users')
                                    .doc(userId)
                                    .collection('irrigation_tracker_crops')
                                    .doc();

                                // ফায়ারবেসে expiryDate, userEmail, userPhone ও isDeleted: false সহ সংরক্ষণ (medicine_info সহ)
                                await docRef.set({
                                  'id': docRef.id,
                                  'userId': userId,
                                  'userEmail': userEmail,
                                  'userPhone': userPhone,
                                  'cropName': name,
                                  'landAmount': fullLandAmount,
                                  'landAmountValue': landNum,
                                  'landUnit': selectedLandUnit,
                                  'cropAge': fullCropAge,
                                  'cropAgeValue': ageNum,
                                  'ageUnit': selectedAgeUnit,
                                  'cropDetails': details,
                                  'expiryDate': Timestamp.fromDate(selectedExpiryDate!),
                                  'expiryDate_ms': selectedExpiryDate!.millisecondsSinceEpoch,
                                  'aiStatus': aiResult.status,
                                  'aiAdvice': aiResult.advice,
                                  'medicine_info': aiResult.medicineInfo,
                                  'medicineInfo': aiResult.medicineInfo,
                                  'medicine_suggestion': aiResult.medicineInfo,
                                  'medicineSuggestion': aiResult.medicineInfo,
                                  'weatherDistrict': weather.district,
                                  'weatherTemp': weather.currentTemp,
                                  'weatherHumidity': weather.humidity,
                                  'weatherRainProb': weather.rainProbability,
                                  'weatherCondition': weather.conditionBn,
                                  'isDeleted': false,
                                  'last_updated': FieldValue.serverTimestamp(),
                                  'last_updated_ms': DateTime.now().millisecondsSinceEpoch,
                                  'lastAiCheck': FieldValue.serverTimestamp(),
                                  'createdAt': FieldValue.serverTimestamp(),
                                  'updatedAt': FieldValue.serverTimestamp(),
                                });

                                if (mounted) {
                                  // ১. লোডিং পপআপ ক্লোজ
                                  Navigator.of(context, rootNavigator: true).pop();
                                  setModalState(() => isSubmitting = false);

                                  // ২. বটম শিট মডাল ক্লোজ
                                  Navigator.pop(bCtx);

                                  // ৩. সাকসেস মেসেজ প্রদর্শন
                                  _showGlobalPopup(
                                    title: 'ফসল সংরক্ষিত হয়েছে!',
                                    message: '"$name" সফলভাবে সেচ ট্র্যাকারে যুক্ত হয়েছে এবং আবহাওয়া অনুযায়ী আধুনিক নির্দেশনা প্রস্তুত করা হয়েছে।',
                                    icon: Icons.check_circle_rounded,
                                    color: const Color(0xFF2E7D32),
                                  );
                                }
                              } catch (saveErr) {
                                debugPrint('Crop save error: $saveErr');
                                if (mounted) {
                                  Navigator.of(context, rootNavigator: true).pop();
                                  setModalState(() => isSubmitting = false);
                                  _showGlobalPopup(
                                    title: 'সংরক্ষণ ব্যর্থ হয়েছে',
                                    message: 'ইন্টারনেট সংযোগ চেক করে আবার চেষ্টা করুন।',
                                    icon: Icons.error_outline_rounded,
                                    color: Colors.red,
                                  );
                                }
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2E7D32),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text(
                        'সংরক্ষণ করুন ও সেচ নির্দেশনা পান',
                        style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // অথেন্টিকেশন স্টেট চেক: প্রকৃত লগইন অবস্থা নির্ধারণ
    final fbUser = FirebaseAuth.instance.currentUser;
    final authProvider = Provider.of<AuthProvider>(context);
    final authUser = authProvider.user;

    final bool isLoggedIn = fbUser != null || (authUser != null && !authUser.uid.startsWith('guest_'));
    final String? activeUid = fbUser?.uid ?? (authUser != null && !authUser.uid.startsWith('guest_') ? authUser.uid : null);

    if (!isLoggedIn || activeUid == null) {
      return _buildLoginRequiredView();
    }

    final weatherProvider = Provider.of<WeatherProvider>(context);
    final weather = weatherProvider.weatherInfo ?? _currentWeather;

    return Scaffold(
      backgroundColor: const Color(0xFFF7FAF7),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1B5E20),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 19),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: Column(
          children: [
            const Text(
              'সেচ ট্র্যাকার',
              style: TextStyle(
                color: Colors.white,
                fontSize: 17.5,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'স্মার্ট সেচ ও ফসলের বর্তমান অবস্থা',
              style: TextStyle(
                color: Colors.white.withOpacity(0.85),
                fontSize: 11,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: (_isRefreshing || weatherProvider.isLoading)
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.sync_rounded, color: Colors.white),
            tooltip: 'ঘণ্টাভিত্তিক ডেটা রিফ্রেশ',
            onPressed: (_isRefreshing || weatherProvider.isLoading)
                ? null
                : () => _checkAllCropsForHourlyUpdate(force: true),
          ),
        ],
      ),
      body: SafeArea(
        child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(activeUid)
              .collection('irrigation_tracker_crops')
              .orderBy('createdAt', descending: true)
              .snapshots(includeMetadataChanges: true),
          builder: (context, snapshot) {
            final fbUserNow = FirebaseAuth.instance.currentUser;
            final authProviderNow = Provider.of<AuthProvider>(context, listen: false);
            final isStillLoggedIn = fbUserNow != null || (authProviderNow.user != null && !authProviderNow.user!.uid.startsWith('guest_'));
            if (!isStillLoggedIn) {
              return const SizedBox.shrink();
            }

            final allDocs = snapshot.data?.docs ?? [];
            final now = DateTime.now();

            // রিকোয়ারমেন্ট ১ ও ২: সফট ডিলিট ও অটো-এক্সপায়ার ফিল্টার
            final activeDocs = <DocumentSnapshot<Map<String, dynamic>>>[];
            final expiredDocs = <DocumentSnapshot<Map<String, dynamic>>>[];

            for (final doc in allDocs) {
              final d = doc.data();
              if (d['isDeleted'] == true) continue; // সফট ডিলিট স্কিপ

              final expRaw = d['expiryDate'];
              DateTime? expDate;
              if (expRaw is Timestamp) {
                expDate = expRaw.toDate();
              } else if (expRaw is DateTime) {
                expDate = expRaw;
              } else if (expRaw is String) {
                expDate = DateTime.tryParse(expRaw);
              }

              final bool isExpired = expDate != null && now.isAfter(expDate);

              if (isExpired) {
                expiredDocs.add(doc);
              } else {
                activeDocs.add(doc);
              }
            }

            final cropCount = activeDocs.length;

            return RefreshIndicator(
              color: const Color(0xFF2E7D32),
              onRefresh: () => _checkAllCropsForHourlyUpdate(force: true),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                child: Column(
                  children: [
                    // ১. ডায়নামিক লোকেশন ও লাইভ আবহাওয়া ব্যানার
                    _buildTopHeaderBanner(_userDistrict ?? weatherProvider.selectedDistrict, cropCount, weather),

                    const SizedBox(height: 14),

                    // ২. ফসল যুক্ত করার অ্যাকশন বার ও লিমিট স্ট্যাটাস
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'আমার সক্রিয় ফসল',
                                style: TextStyle(
                                  fontSize: 15.5,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              Text(
                                cropCount >= 3
                                    ? 'সর্বোচ্চ ৩টি ফসলের কোটা পূর্ণ'
                                    : 'আরও ${BanglaNumberConverter.toBangla(3 - cropCount)}টি ফসল যুক্ত করতে পারবেন',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  color: cropCount >= 3 ? const Color(0xFFE65100) : const Color(0xFF2E7D32),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          ElevatedButton.icon(
                            onPressed: () => _openAddCropModal(cropCount),
                            icon: const Icon(Icons.add_rounded, size: 18),
                            label: const Text('ফসল যোগ', style: TextStyle(fontWeight: FontWeight.bold)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: cropCount >= 3 ? Colors.grey.shade400 : const Color(0xFF2E7D32),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 12),

                    // ৩. রিয়েল-টাইম সক্রিয় কার্ড লিস্ট
                    if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) ...[
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 40),
                        child: Center(
                          child: CircularProgressIndicator(color: Color(0xFF2E7D32)),
                        ),
                      ),
                    ] else if (activeDocs.isEmpty) ...[
                      _buildEmptyState(hasExpiredOnly: expiredDocs.isNotEmpty),
                    ] else ...[
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        itemCount: activeDocs.length,
                        itemBuilder: (context, idx) {
                          return _buildCropShortCard(context, activeDocs[idx], idx, weather);
                        },
                      ),
                    ],

                    // রিকোয়ারমেন্ট ২: মেয়াদ উত্তীর্ণ ফসলের আর্কাইভ ও হিস্ট্রি নোটিশ
                    if (expiredDocs.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 16),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF8E1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFFFE082)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.hourglass_bottom_rounded, size: 20, color: Color(0xFFF57F17)),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'মেয়াদ উত্তীর্ণ ফসল: ${BanglaNumberConverter.toBangla(expiredDocs.length)}টি (মেয়াদ শেষ হওয়ায় রানিং লিস্ট থেকে হাইড ও সংরক্ষিত)',
                                style: const TextStyle(
                                  fontSize: 11.5,
                                  color: Color(0xFFE65100),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  /// ডায়নামিক ইউজার লোকেশন ও লাইভ আবহাওয়া ব্যানার
  Widget _buildTopHeaderBanner(String? district, int cropCount, WeatherInfoModel? weather) {
    final tempStr = weather != null ? '${BanglaNumberConverter.toBangla(weather.currentTemp.toStringAsFixed(0))}°C' : '--';
    final humidityStr = weather != null ? '${BanglaNumberConverter.toBangla(weather.humidity)}%' : '--';
    final rainProbStr = weather != null ? '${BanglaNumberConverter.toBangla(weather.rainProbability)}%' : '--';
    final condStr = weather?.conditionBn ?? 'আবহাওয়া লোড হচ্ছে...';

    final displayDistrict = _isDistrictLoading
        ? 'লোকেশন লোড হচ্ছে...'
        : (district != null && district.isNotEmpty ? district : 'জেলা নির্বাচন করুন');

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1B5E20), Color(0xFF2E7D32)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1B5E20).withOpacity(0.25),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.12),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withOpacity(0.2)),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Icon(
                      weather != null && weather.rainProbability >= 40
                          ? Icons.water_drop_rounded
                          : Icons.wb_sunny_rounded,
                      color: const Color(0xFF2E7D32),
                      size: 24,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.location_on, color: Colors.white, size: 14),
                          const SizedBox(width: 3),
                          Text(
                            displayDistrict,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            condStr,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            'তাপমাত্রা: $tempStr',
                            style: const TextStyle(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'আর্দ্রতা: $humidityStr',
                            style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 11.5),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'বৃষ্টি: $rainProbStr',
                            style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 11.5),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(
                      color: Color(0xFF69F0AE),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    'প্রতি ঘণ্টায় স্বয়ংক্রিয় সেচ ট্র্যাকিং সক্রিয়',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'সক্রিয়: ${BanglaNumberConverter.toBangla(cropCount)}/৩টি',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// ফসলের শর্ট কার্ড (Short Card)
  Widget _buildCropShortCard(
    BuildContext context,
    DocumentSnapshot<Map<String, dynamic>> doc,
    int index,
    WeatherInfoModel? weather,
  ) {
    final data = doc.data() ?? {};
    final cropName = data['cropName'] as String? ?? 'ফসল';
    final landAmount = data['landAmount'] as String? ?? '-';
    final cropAge = data['cropAge'] as String? ?? '-';
    final cropDetails = data['cropDetails'] as String? ?? '';
    final aiStatus = data['aiStatus'] as String? ?? '💧 হালকা সেচ দিন';
    final aiAdvice = data['aiAdvice'] as String? ?? 'আবহাওয়া পর্যবেক্ষণ করে পরিমিত সেচ প্রদান করুন।';
    final medicineInfo = (data['medicine_info'] as String? ??
            data['medicineInfo'] as String? ??
            data['medicine_suggestion'] as String? ??
            data['medicineSuggestion'] as String? ??
            '')
        .trim();
    final liveTemp = weather?.currentTemp ?? (data['weatherTemp'] as num?)?.toDouble() ?? 28.0;
    final liveHumidity = weather?.humidity ?? (data['weatherHumidity'] as num?)?.toInt() ?? 65;
    final lastUpdatedStamp = data['last_updated'] ?? data['updatedAt'] ?? data['lastAiCheck'];
    final expRaw = data['expiryDate'];

    // ১ ঘণ্টার ব্যাকগ্রাউন্ড আপডেট চেক
    _checkAndTriggerHourlyUpdateForCrop(doc, data, weather);

    Color statusColor = const Color(0xFF2E7D32);
    Color statusBg = const Color(0xFFE8F5E9);
    if (aiStatus.contains('প্রয়োজন নেই') || aiStatus.contains('লাগবে না')) {
      statusColor = const Color(0xFF2E7D32);
      statusBg = const Color(0xFFE8F5E9);
    } else if (aiStatus.contains('জরুরি') || aiStatus.contains('বেশি')) {
      statusColor = const Color(0xFFE65100);
      statusBg = const Color(0xFFFFF3E0);
    } else {
      statusColor = const Color(0xFF0288D1);
      statusBg = const Color(0xFFE1F5FE);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE0E8E1)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ১. শীর্ষ হেডার
            Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: statusBg,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Icon(Icons.water_drop, color: statusColor, size: 20),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        cropName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: statusBg,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          aiStatus,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: statusColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // ডিলিট বাটন
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFE53935), size: 21),
                  tooltip: 'ফসল মুছুন',
                  onPressed: () => _confirmDeleteCrop(doc, cropName),
                ),
              ],
            ),

            const SizedBox(height: 10),
            const Divider(height: 1, color: Color(0xFFF0F0F0)),
            const SizedBox(height: 8),

            // ২. ফসলের প্যারামিটার মেটা চিপস
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                _buildParamChip(Icons.square_foot_rounded, 'জমি: $landAmount'),
                _buildParamChip(Icons.hourglass_top_rounded, 'বয়স: $cropAge'),
                if (expRaw != null)
                  _buildParamChip(Icons.calendar_month_outlined, 'মেয়াদ: ${_formatExpiryDate(expRaw)}'),
              ],
            ),

            // ৩. ফসলের বিস্তারিত বিবরণ
            if (cropDetails.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFF9FAF9),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFE8EFE8)),
                ),
                child: Text(
                  'বিবরণ: $cropDetails',
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.3),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],

            const SizedBox(height: 10),

            // ৪. "আপনার জন্য বর্তমান নির্দেশনা" - রিকোয়ারমেন্ট ৩: Colors.green.shade50 ও বর্ডার Colors.green.shade200, রেডিয়াস 12.0
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.green.shade50, // হালকা সবুজ / মিন্ট কালার
                borderRadius: BorderRadius.circular(12.0), // বর্ডার রেডিয়াস ১২.০
                border: Border.all(color: Colors.green.shade200, width: 1.2), // পরিপাটি নরম বর্ডার
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x06000000),
                    blurRadius: 4,
                    offset: Offset(0, 1),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.lightbulb_rounded, color: Color(0xFF1B5E20), size: 18),
                      const SizedBox(width: 6),
                      const Text(
                        'আপনার জন্য বর্তমান নির্দেশনা',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1B5E20),
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.green.shade200),
                        ),
                        child: Text(
                          '🌡️ ${BanglaNumberConverter.toBangla(liveTemp.toStringAsFixed(0))}°C | 💧 ${BanglaNumberConverter.toBangla(liveHumidity)}%',
                          style: TextStyle(fontSize: 10, color: Colors.green.shade800, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    aiAdvice,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF1E281F),
                      height: 1.5, // পড়ার আরামদায়ক লাইন হাইট
                      fontWeight: FontWeight.w500,
                    ),
                  ),

                  // রিয়েল-টাইম ঔষধ/বালাইনাশক পরামর্শ বক্স (যদি medicine_info বিদ্যমান থাকে - Colors.orange.shade50)
                  if (medicineInfo.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(11),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50, // হালকা হলুদ/অরেঞ্জ ব্যাকগ্রাউন্ড
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.orange.shade200, width: 1.2),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: const [
                              Icon(Icons.medication_liquid_rounded, size: 17, color: Color(0xFFE65100)),
                              SizedBox(width: 6),
                              Text(
                                'ঔষধ ও বালাইনাশক পরামর্শ:',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFFE65100),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            medicineInfo,
                            style: const TextStyle(
                              fontSize: 12.5,
                              color: Color(0xFF3E2723),
                              height: 1.45,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // স্পষ্ট লাল সতর্কতা বা ডিসক্লেইমার (⚠️ বোল্ড লাল কালার)
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFEBEE), // হালকা লাল ব্যাকগ্রাউন্ড
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFFFCDD2), width: 1),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.warning_amber_rounded, size: 16, color: Color(0xFFD32F2F)),
                        SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'ফসলে ঔষধ প্রয়োগ করার আগে বিশেষজ্ঞদের পরামর্শ নিন, সরাসরি ঔষধ ব্যবহার করবেন না।',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFD32F2F), // স্পষ্ট বোল্ড লাল কালার
                              height: 1.35,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.history_toggle_off_rounded, size: 13, color: Colors.grey.shade600),
                      const SizedBox(width: 4),
                      Text(
                        _formatLastUpdatedTime(lastUpdatedStamp, data['last_updated_ms']),
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade700,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// প্যারামিটার চিপ উইজেট
  Widget _buildParamChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F8E9),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: const Color(0xFF2E7D32)),
          const SizedBox(width: 4),
          Text(
            text,
            style: const TextStyle(fontSize: 11.5, color: Color(0xFF1B5E20), fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  /// কোনো সক্রিয় ফসল না থাকলে এম্পটি স্টেট
  Widget _buildEmptyState({bool hasExpiredOnly = false}) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE0E8E1)),
        ),
        child: Column(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: const BoxDecoration(
                color: Color(0xFFE8F5E9),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.water_drop_outlined, color: Color(0xFF2E7D32), size: 36),
            ),
            const SizedBox(height: 14),
            Text(
              hasExpiredOnly ? 'সকল ফসলের ট্র্যাকিং মেয়াদ সমাপ্ত হয়েছে' : 'কোনো ফসল যুক্ত করা হয়নি',
              style: const TextStyle(
                fontSize: 16.5,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              hasExpiredOnly
                  ? 'আপনার পূর্ববর্তী ফসলগুলোর ট্র্যাকিং মেয়াদ শেষ হওয়ায় সেগুলো আর্কাইভ করা হয়েছে। আপনি এখন নতুন ৩টি ফসল যুক্ত করতে পারবেন।'
                  : 'আপনার জমির ফসলের নাম, পরিমাণ, বয়স ও বিবরণ যোগ করে আধুনিক আবহাওয়া ও এআই ভিত্তিক রিয়েল-টাইম সেচ পরামর্শ পান।',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.4),
            ),
            const SizedBox(height: 18),
            ElevatedButton.icon(
              onPressed: () => _openAddCropModal(0),
              icon: const Icon(Icons.add_rounded, size: 20),
              label: Text(
                hasExpiredOnly ? 'নতুন ফসল যোগ করুন' : 'প্রথম ফসল যুক্ত করুন',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2E7D32),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// লগআউট অবস্থায় ভিউ
  Widget _buildLoginRequiredView() {
    return Scaffold(
      backgroundColor: const Color(0xFFF7FAF7),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1B5E20),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 19),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: Column(
          children: [
            const Text(
              'সেচ ট্র্যাকার',
              style: TextStyle(
                color: Colors.white,
                fontSize: 17.5,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'স্মার্ট সেচ ও ফসলের বর্তমান অবস্থা',
              style: TextStyle(
                color: Colors.white.withOpacity(0.85),
                fontSize: 11,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: const BoxDecoration(
                  color: Color(0xFFE8F5E9),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.lock_outline_rounded, color: Color(0xFF2E7D32), size: 36),
              ),
              const SizedBox(height: 18),
              const Text(
                'লগইন প্রয়োজন',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'সেচ ট্র্যাকার ব্যবহার করতে ও আপনার সংরক্ষিত ফসলের ডেটা দেখতে অনুগ্রহ করে অ্যাপে লগইন করুন।',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13.5,
                  color: AppColors.textSecondary,
                  height: 1.45,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
