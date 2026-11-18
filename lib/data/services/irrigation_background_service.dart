import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:workmanager/workmanager.dart';
import '../../firebase_options.dart';

const String irrigationHourlyTaskName = "com.krishikotha.irrigation_hourly_update";
const String irrigationPeriodicTaskTag = "irrigationHourlyUpdateTask";

/// ব্যাকগ্রাউন্ড ওয়ার্কম্যানেজার এন্ট্রি পয়েন্ট
@pragma('vm:entry-point')
void irrigationCallbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    debugPrint("Workmanager executing irrigation task: $task");
    if (task == irrigationHourlyTaskName ||
        task == Workmanager.iOSBackgroundTask ||
        task == irrigationPeriodicTaskTag) {
      try {
        await dotenv.load(fileName: ".env").catchError((_) {});
      } catch (_) {}

      try {
        if (Firebase.apps.isEmpty) {
          await Firebase.initializeApp(
            options: DefaultFirebaseOptions.currentPlatform,
          );
        }
        await IrrigationBackgroundService.performHourlySync();
        return Future.value(true);
      } catch (e) {
        debugPrint("Irrigation background sync error: $e");
        return Future.value(false);
      }
    }
    return Future.value(true);
  });
}

class IrrigationBackgroundService {
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

  /// ওয়ার্কম্যানেজার ইনিশিয়ালাইজেশন এবং ১ ঘণ্টার পর্যায়ক্রমিক শিডিউল রেজিস্ট্রেশন
  static Future<void> initAndRegisterPeriodicTask() async {
    try {
      if (!kIsWeb) {
        await Workmanager().initialize(
          irrigationCallbackDispatcher,
          isInDebugMode: false,
        );

        await Workmanager().registerPeriodicTask(
          "irrigation_hourly_worker_unique_id",
          irrigationHourlyTaskName,
          tag: irrigationPeriodicTaskTag,
          frequency: const Duration(hours: 1),
          existingWorkPolicy: ExistingWorkPolicy.keep,
          constraints: Constraints(
            networkType: NetworkType.connected,
          ),
          backoffPolicy: BackoffPolicy.exponential,
          backoffPolicyDelay: const Duration(minutes: 10),
        );
        debugPrint("Workmanager: Irrigation 1-Hour periodic task registered successfully.");
      }
    } catch (e) {
      debugPrint("Workmanager init notice: $e");
    }
  }

  /// ফায়ারবেসে সকল ইউজারের ফসলের ১ ঘণ্টার লেজি/ব্যাকগ্রাউন্ড সিঙ্ক সম্পাদন
  static Future<void> performHourlySync() async {
    debugPrint("Starting Irrigation 1-Hour Background Sync...");
    final now = DateTime.now();

    try {
      final usersSnapshot = await FirebaseFirestore.instance.collection('users').get();

      for (final userDoc in usersSnapshot.docs) {
        final userId = userDoc.id;
        final userDistrict = (userDoc.data()['district'] as String? ?? 'ঢাকা').replaceAll(' জেলা', '');

        final cropsSnapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .collection('irrigation_tracker_crops')
            .where('isDeleted', isEqualTo: false)
            .get();

        for (final cropDoc in cropsSnapshot.docs) {
          final data = cropDoc.data();

          // এক্সপায়ারি চেক: মেয়াদোত্তীর্ণ ফসল স্কিপ
          final expRaw = data['expiryDate'];
          DateTime? expDate;
          if (expRaw is Timestamp) {
            expDate = expRaw.toDate();
          } else if (expRaw is DateTime) {
            expDate = expRaw;
          }
          if (expDate != null && now.isAfter(expDate)) {
            continue;
          }

          // ১ ঘণ্টার ডিফারেন্স যাচাই (Timestamp check)
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

          final int diffMinutes = lastUpdatedTime != null ? now.difference(lastUpdatedTime).inMinutes : 999;
          if (diffMinutes < 60) {
            continue; // ৬০ মিনিটের কম হলে কোনো এপিআই কল হবে না
          }

          // ১ ঘণ্টা পার হলে ব্যাকগ্রাউন্ডেই Weather ও Gemini API কল
          final cropDistrict = (data['weatherDistrict'] as String? ?? userDistrict).replaceAll(' জেলা', '');
          final weather = await _fetchBackgroundWeather(cropDistrict);

          final cropName = (data['cropName'] as String? ?? '').trim();
          final cropAge = (data['cropAge'] as String? ?? '').trim();
          final cropDetails = (data['cropDetails'] as String? ?? '').trim();

          final aiResult = await _deepAnalyzeWithGemini(
            cropName: cropName,
            cropAge: cropAge,
            cropDetails: cropDetails,
            temp: weather.temp,
            rainProb: weather.rainProb,
          );

          await cropDoc.reference.update({
            'aiAdvice': aiResult.advice,
            'aiStatus': aiResult.status,
            'medicine_info': aiResult.medicineInfo,
            'medicineInfo': aiResult.medicineInfo,
            'medicine_suggestion': aiResult.medicineInfo,
            'medicineSuggestion': aiResult.medicineInfo,
            'last_updated': FieldValue.serverTimestamp(),
            'last_updated_ms': DateTime.now().millisecondsSinceEpoch,
            'updatedAt': FieldValue.serverTimestamp(),
            'weatherDistrict': cropDistrict,
            'weatherTemp': weather.temp,
            'weatherRainProb': weather.rainProb,
            'weatherCondition': weather.condition,
          });

          debugPrint("Background Sync: Updated crop $cropName ($userId)");
        }
      }
    } catch (e) {
      debugPrint("performHourlySync exception: $e");
    }
  }

  /// ব্যাকগ্রাউন্ড আবহাওয়া তথ্য ফেচ
  static Future<({double temp, int rainProb, String condition})> _fetchBackgroundWeather(String district) async {
    try {
      final districtCoords = {
        'ঢাকা': {'lat': 23.8103, 'lon': 90.4125},
        'চট্টগ্রাম': {'lat': 22.3569, 'lon': 91.7832},
        'রাজশাহী': {'lat': 24.3636, 'lon': 88.6241},
        'খুলনা': {'lat': 22.8456, 'lon': 89.5403},
        'বরিশাল': {'lat': 22.7010, 'lon': 90.3535},
        'সিলেট': {'lat': 24.8949, 'lon': 91.8687},
        'রংপুর': {'lat': 25.7439, 'lon': 89.2752},
        'ময়মনসিংহ': {'lat': 24.7471, 'lon': 90.4203},
      };

      final coords = districtCoords[district] ?? {'lat': 23.8103, 'lon': 90.4125};
      final lat = coords['lat'];
      final lon = coords['lon'];

      final url = Uri.parse(
        'https://api.open-meteo.com/v1/forecast?latitude=$lat&longitude=$lon&current=temperature_2m,precipitation_probability,weather_code&timezone=auto',
      );
      final res = await http.get(url).timeout(const Duration(seconds: 8));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final current = data['current'] ?? {};
        final temp = (current['temperature_2m'] as num?)?.toDouble() ?? 29.0;
        final rainProb = (current['precipitation_probability'] as num?)?.toInt() ?? 20;
        return (temp: temp, rainProb: rainProb, condition: rainProb > 40 ? 'বৃষ্টির সম্ভাবনা' : 'পরিষ্কার');
      }
    } catch (_) {}
    return (temp: 29.0, rainProb: 20, condition: 'পরিষ্কার');
  }

  /// রিকোয়ারমেন্ট ১: Deep Analysis API Prompt (কঠোর ও নিখুঁত লজিক)
  static Future<({String advice, String status, String medicineInfo})> _deepAnalyzeWithGemini({
    required String cropName,
    required String cropAge,
    required String cropDetails,
    required double temp,
    required int rainProb,
  }) async {
    final detailsText = cropDetails.isNotEmpty ? cropDetails : 'মাটির অবস্থা স্বাভাবিক';
    final weatherDesc = 'তাপমাত্রা ${temp.toStringAsFixed(0)}°C এবং বৃষ্টিপাতের অবস্থা $rainProb%';

    final prompt = '''
তুমি বাংলাদেশের একজন শীর্ষস্থানীয় কৃষি বিশেষজ্ঞ। তোমাকে কৃষকের দেওয়া "জমির অবস্থা" গভীরভাবে বিশ্লেষণ করে সরাসরি সমস্যার সমাধান দিতে হবে। কোনো মুখস্থ বা জেনেরিক উত্তর দেওয়া যাবে না।

ইনপুট ডেটা:
- ফসলের নাম: $cropName
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
    if (token.isNotEmpty) {
      for (final engineId in _geminiEngines) {
        try {
          final url = Uri.parse(
            'https://generativelanguage.googleapis.com/v1beta/models/$engineId:generateContent?key=$token',
          );
          final res = await http.post(
            url,
            headers: {'Content-Type': 'application/json; charset=utf-8'},
            body: jsonEncode({
              'contents': [
                {
                  'parts': [{'text': prompt}]
                }
              ],
              'generationConfig': {
                'temperature': 0.1,
                'maxOutputTokens': 512,
              }
            }),
          ).timeout(const Duration(seconds: 10));

          if (res.statusCode == 200) {
            final resData = jsonDecode(utf8.decode(res.bodyBytes));
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
              final advice = (data['advice'] as String? ?? '').trim();
              final medicine = (data['medicine_info'] as String? ??
                      data['medicineInfo'] as String? ??
                      data['medicine_suggestion'] as String? ??
                      data['medicineSuggestion'] as String? ??
                      '')
                  .trim();

              if (advice.isNotEmpty) {
                final status = _deriveStatus(advice, rainProb);
                return (advice: advice, status: status, medicineInfo: medicine);
              }
            }
          }
        } catch (_) {}
      }
    }

    // অফলাইন ফলব্যাক
    return _generateFallback(cropName, cropAge, cropDetails, temp, rainProb);
  }

  static String _deriveStatus(String advice, int rainProb) {
    final lower = advice.toLowerCase();
    if (lower.contains('পানি নিষ্কাশন') || lower.contains('পানি বের') || lower.contains('নিষ্কাশন করুন') || lower.contains('ড্রেন পরিষ্কার')) {
      return '⚠️ পানি নিষ্কাশন করুন';
    } else if (lower.contains('সেচ প্রয়োজন নেই') || lower.contains('সেচ দেবেন না') || lower.contains('সেচ দেওয়া স্থগিত') || lower.contains('সেচ বন্ধ') || lower.contains('শুকানোর')) {
      return '🌿 সেচের প্রয়োজন নেই';
    } else if (lower.contains('জরুরি সেচ') || lower.contains('তাত্ক্ষণিক সেচ') || lower.contains('তীব্র খরা')) {
      return '🚨 জরুরি সেচ প্রয়োজন';
    } else if (lower.contains('হালকা সেচ') || lower.contains('পরিমিত সেচ')) {
      return '💧 হালকা সেচ দিন';
    }
    return rainProb >= 40 ? '🌿 সেচের প্রয়োজন নেই' : '💧 হালকা সেচ দিন';
  }

  static ({String advice, String status, String medicineInfo}) _generateFallback(
    String cropName,
    String cropAge,
    String cropDetails,
    double temp,
    int rainProb,
  ) {
    final lowerDetails = cropDetails.toLowerCase();
    String medicine = '';

    // ক) গাছ হেলে যাওয়া / হেলে পড়া
    if (lowerDetails.contains('হেলে') || lowerDetails.contains('ঢলে') || lowerDetails.contains('পড়ে যা')) {
      medicine = 'গাছের শিকড় ও কাণ্ড শক্ত করে সোজা রাখতে অনুমোদিত চিলেটেড জিংক (১ গ্রাম/লি.) অথবা পিজিআর (যেমন: ফ্লোরা প্রতি লিটার পানিতে ২ মিলি, আনুমানিক বাজারমূল্য ১৮০-২২০ টাকা) স্প্রে করুন।';
      return (
        status: '⚠️ পানি নিষ্কাশন ও ঠেকনা দিন',
        advice: '$cropName গাছ হেলে পড়া রোধে গোড়ার অতিরিক্ত পানি দ্রুত নিষ্কাশন করুন এবং গাছের গোড়ায় শুকনো মাটি তুলে দিয়ে বাঁশের কঞ্চি বা খুঁটি দিয়ে শক্ত ঠেকনা দিন। মাটি ভেজা থাকলে এখন কোনো সেচ দিবেন না।',
        medicineInfo: medicine,
      );
    }

    // খ) পাতা কুঁচকে যাওয়া / কোঁকড়ানো
    if (lowerDetails.contains('কুঁচকে') || lowerDetails.contains('কোঁকড়') || lowerDetails.contains('মুড়িয়ে')) {
      medicine = 'পাতা কোঁকড়ানো ও চোষক পোকা দমনে ইমিডাক্লোপ্রিড (যেমন: এডমায়ার ২০ এসএল প্রতি লিটার পানিতে ০.৫ মিলি, আনুমানিক বাজারমূল্য ১৮০-২১০ টাকা) স্প্রে করুন।';
      return (
        status: '🚨 চোষক পোকা দমন করুন',
        advice: '$cropName গাছের পাতা কুঁচকে যাওয়ার প্রধান কারণ চোষক পোকা বা মাইটের আক্রমণ। পাতা ভেজা রাখবেন না এবং অবিলম্বে চোষক পোকা দমনে স্প্রে করুন।',
        medicineInfo: medicine,
      );
    }

    // গ) পচন / ছত্রাক / ঝলসানো / দাগ / ব্লাইট
    if (lowerDetails.contains('পচ') ||
        lowerDetails.contains('পচে') ||
        lowerDetails.contains('পচন') ||
        lowerDetails.contains('ছত্রাক') ||
        lowerDetails.contains('হলুদ') ||
        lowerDetails.contains('দাগ') ||
        lowerDetails.contains('ব্লাইট')) {
      if (cropName.contains('মরিচ') || lowerDetails.contains('মরিচ')) {
        medicine = 'মরিচ ফসলে পচন ও ছত্রাকজনিত রোগ নিয়ন্ত্রণে টিল্ট ২৫০ ইসি (প্রপিকোনাজল) প্রতি লিটার পানিতে ০.৫ মিলি অথবা এমিস্টার টপ ৩২৫ এসসি প্রতি লিটার পানিতে ১ মিলি (আনুমানিক বাজারমূল্য ৩২০-৩৫০ টাকা) স্প্রে করুন।';
      } else {
        medicine = 'ছত্রাকজনিত রোগ ও পাতা হলুদ হওয়া দমনে এমিস্টার টপ ৩২৫ এসসি প্রতি লিটার পানিতে ১ মিলি (আনুমানিক বাজারমূল্য ৩২০-৩৫০ টাকা) অথবা টিল্ট ২৫০ ইসি স্প্রে করুন।';
      }
      return (
        status: '⚠️ সেচ বন্ধ ও ছত্রাকনাশক দিন',
        advice: '$cropName ফসলে পচন ও ছত্রাকের আক্রমণ দেখা দেওয়ায় সেচ দেওয়া অবিলম্বে বন্ধ রাখুন এবং জমে থাকা পানি দ্রুত নিষ্কাশন করুন। রোদের পর ছত্রাকনাশক স্প্রে করুন।',
        medicineInfo: medicine,
      );
    } else if (lowerDetails.contains('পোকা') || lowerDetails.contains('কীট') || lowerDetails.contains('মাজরা') || lowerDetails.contains('লেদা')) {
      medicine = 'পোকা ও কীটের উপদ্রব দমনে কীটনাশক ক্যারাটে ২.৫ ইসি প্রতি লিটার পানিতে ১ মিলি (আনুমানিক বাজারমূল্য ১৫০-১৮০ টাকা) স্প্রে করুন।';
      return (
        status: '🚨 কীটনাশক প্রয়োগ করুন',
        advice: '$cropName ফসলে পোকার আক্রমণ দমনে আক্রান্ত পাতা ও ডগা ধ্বংস করুন এবং অনুমোদিত কীটনাশক প্রয়োগ করুন।',
        medicineInfo: medicine,
      );
    }

    // নিয়ম ১: মাটি ভেজা বা বৃষ্টির সম্ভাবনা থাকলে সেচ নিষিদ্ধ
    if (rainProb >= 40 ||
        lowerDetails.contains('ভেজা') ||
        lowerDetails.contains('বৃষ্টি') ||
        lowerDetails.contains('পানি জমে') ||
        lowerDetails.contains('কাদা')) {
      return (
        status: '⚠️ পানি নিষ্কাশন করুন',
        advice: 'জমিতে পানি জমে বা মাটি ভেজা থাকায় এবং বৃষ্টির সম্ভাবনা ($rainProb%) থাকায় কোনো সেচ দেওয়া যাবে না। জমি থেকে দ্রুত অতিরিক্ত পানি নিষ্কাশন করুন এবং মাটি শুকাতে দিন।',
        medicineInfo: medicine,
      );
    }

    // নিয়ম ২: ফসল ও বয়সের স্পেসিফিক লজিক
    if (cropName.contains('ধান')) {
      return (
        status: '💧 হালকা সেচ দিন',
        advice: 'ধান ফসলের বর্তমান বয়স ($cropAge) অনুযায়ী জমিতে ২-৩ ইঞ্চি পরিমিত পানি ধরে রাখুন। অতিরিক্ত সেচ পরিহার করে নালা সচল রাখুন।',
        medicineInfo: medicine,
      );
    } else if (cropName.contains('আলু')) {
      return (
        status: '💧 হালকা সেচ দিন',
        advice: 'আলু ফসলে জলাবদ্ধতা একদমই সহ্য হয় না। সারির মাঝে নালায় সতর্কতার সাথে খুব হালকা সেচ দিন যাতে কন্দ পচে না যায়।',
        medicineInfo: medicine,
      );
    }

    if (temp >= 33) {
      return (
        status: '🚨 জরুরি সেচ প্রয়োজন',
        advice: 'তীব্র তাপমাত্রা (${temp.toStringAsFixed(0)}°C) ও প্রখর রোদে $cropName ফসলের মাটিতে পানির তীব্র ঘাটতি হতে পারে। বিকালে পরিমিত সেচ প্রদান করুন।',
        medicineInfo: medicine,
      );
    }

    return (
      status: '💧 হালকা সেচ দিন',
      advice: '$cropName ফসলের ($cropAge) বৃদ্ধি বজায় রাখতে বর্তমান আবহাওয়ায় (তাপমাত্রা ${temp.toStringAsFixed(0)}°C) বিকালে জমিতে হালকা সেচ দেওয়া উপযুক্ত।',
      medicineInfo: medicine,
    );
  }
}
