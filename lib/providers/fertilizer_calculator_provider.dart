import 'package:flutter/material.dart';
import '../core/utils/bangla_number_converter.dart';

class FertilizerResult {
  final String nameBn;
  final String englishName;
  final double amountKg;
  final String applicationStage;
  final String role;
  final String note;
  final double pricePerKg; // সরকারি/স্থানীয় আনুমানিক ভর্তুকিমূল্য (টাকা/কেজি)
  final Color primaryColor;
  final Color bgColor;
  final IconData icon;

  const FertilizerResult({
    required this.nameBn,
    this.englishName = '',
    required this.amountKg,
    required this.applicationStage,
    this.role = '',
    this.note = '',
    this.pricePerKg = 0.0,
    this.primaryColor = const Color(0xFF2E7D32),
    this.bgColor = const Color(0xFFE8F5E9),
    this.icon = Icons.eco_rounded,
  });

  String get formattedAmount {
    if (amountKg >= 40) {
      final mon = amountKg / 40.0;
      final monStr = mon % 1 == 0 ? mon.toInt().toString() : mon.toStringAsFixed(1);
      final kgStr = amountKg % 1 == 0 ? amountKg.toInt().toString() : amountKg.toStringAsFixed(1);
      return '${BanglaNumberConverter.toBangla(monStr)} মণ (${BanglaNumberConverter.toBangla(kgStr)} কেজি)';
    } else if (amountKg < 1 && amountKg > 0) {
      final gm = (amountKg * 1000).toInt();
      return '${BanglaNumberConverter.toBangla(gm)} গ্রাম';
    }
    final kgStr = amountKg % 1 == 0 ? amountKg.toInt().toString() : amountKg.toStringAsFixed(1);
    return '${BanglaNumberConverter.toBangla(kgStr)} কেজি';
  }

  double get estimatedCost => amountKg * pricePerKg;
}

class FertilizerTimelineStep {
  final String stageTitle;
  final String timing;
  final List<String> fertilizers;
  final String instructions;
  final IconData icon;
  final Color color;

  const FertilizerTimelineStep({
    required this.stageTitle,
    required this.timing,
    required this.fertilizers,
    required this.instructions,
    this.icon = Icons.schedule_rounded,
    this.color = const Color(0xFF2E7D32),
  });
}

class FertilizerCalculatorProvider extends ChangeNotifier {
  String _selectedCrop = 'বোরো ধান';
  String _selectedUnit = 'শতক / শতাংশ';
  double _landArea = 10.0;
  List<FertilizerResult> _results = [];
  List<FertilizerTimelineStep> _timelineSteps = [];
  List<String> _safetyTips = [];
  String _applicationGuidelines = '';

  String get selectedCrop => _selectedCrop;
  String get selectedUnit => _selectedUnit;
  double get landArea => _landArea;
  List<FertilizerResult> get results => _results;
  List<FertilizerTimelineStep> get timelineSteps => _timelineSteps;
  List<String> get safetyTips => _safetyTips;
  String get applicationGuidelines => _applicationGuidelines;

  double get estimatedTotalCost {
    double total = 0.0;
    for (final r in _results) {
      total += r.estimatedCost;
    }
    return total;
  }

  final List<String> supportedCrops = [
    'বোরো ধান',
    'আমন ধান',
    'আউশ ধান',
    'গোল আলু',
    'ভুট্টা',
    'গম',
    'সরিষা',
    'মরিচ',
    'টমেটো',
    'বেগুন',
    'পেঁয়াজ',
    'পাট',
  ];

  final List<String> supportedUnits = [
    'শতক / শতাংশ',
    'কাঠা (১.৬৫ শতক)',
    'বিঘা (৩৩ শতক)',
    'একর (১০০ শতক)',
    'হেক্টর (২৪৭ শতক)',
  ];

  FertilizerCalculatorProvider() {
    calculate();
  }

  void setCrop(String crop) {
    _selectedCrop = crop;
    calculate();
  }

  void setUnit(String unit) {
    _selectedUnit = unit;
    calculate();
  }

  void setLandArea(double area) {
    _landArea = area;
    calculate();
  }

  void calculate() {
    if (_landArea <= 0) {
      _results = [];
      _timelineSteps = [];
      _safetyTips = [];
      _applicationGuidelines = '';
      notifyListeners();
      return;
    }

    // Normalize to Decimals (শতক)
    double decimals = _landArea;
    if (_selectedUnit.contains('বিঘা')) {
      decimals = _landArea * 33.0;
    } else if (_selectedUnit.contains('কাঠা')) {
      decimals = _landArea * 1.65;
    } else if (_selectedUnit.contains('একর')) {
      decimals = _landArea * 100.0;
    } else if (_selectedUnit.contains('হেক্টর')) {
      decimals = _landArea * 247.0;
    }

    _safetyTips = [
      'প্রখর কড়া রোদ বা ভারী বৃষ্টিপাতের আগে জমিতে রাসায়নিক সার ছিটাবেন না, এতে সারের কার্যকারিতা অপচয় হয়।',
      'শিশিরভেজা পাতায় ইউরিয়া সার ছিটাবেন না; পাতা শুকানোর পর জমিতে ছিপছিপে রস বা হালকা পানি থাকা অবস্থায় দিন।',
      'ইউরিয়া সার সবসময় কিস্তিতে উপরিপ্রয়োগ করুন, একবারে দিলে গাছ নিতে পারে না ও মাটির নিচে লিচিং হয়ে নষ্ট হয়।',
      'টিএসপি, জিপসাম ও দস্তা সার সবসময় জমি তৈরির শেষ চাষে কাদার সাথে ভালোভাবে মিশিয়ে দিন।',
    ];

    switch (_selectedCrop) {
      case 'বোরো ধান':
        _results = [
          FertilizerResult(
            nameBn: 'ইউরিয়া (Urea)',
            englishName: 'Nitrogen (N) 46%',
            amountKg: decimals * 1.10,
            pricePerKg: 27.0,
            primaryColor: const Color(0xFF1B5E20),
            bgColor: const Color(0xFFE8F5E9),
            icon: Icons.grain_rounded,
            role: 'নাইট্রোজেনের প্রধান উৎস • দ্রুত দৈহিক বৃদ্ধি, প্রচুর কুশি উৎপাদন ও পাতা গাঢ় সবুজ রাখা।',
            applicationStage: '৩টি সমান কিস্তিতে উপরিপ্রয়োগ (চারা রোপণের ১৫, ৩০ ও ৪৫ দিন পর)',
            note: 'জমিতে রস বা হালকা পানি থাকা অবস্থায় দিন',
          ),
          FertilizerResult(
            nameBn: 'টিএসপি / ডিএপি (TSP/DAP)',
            englishName: 'Phosphorus (P) 46%',
            amountKg: decimals * 0.45,
            pricePerKg: 22.0,
            primaryColor: const Color(0xFFE65100),
            bgColor: const Color(0xFFFFF3E0),
            icon: Icons.hub_rounded,
            role: 'ফসফরাসের প্রধান উৎস • শিকড়ের দ্রুত ও মজবুত বিস্তার, কাণ্ড শক্ত করা ও সময়মতো ফুল-ফল ধরা।',
            applicationStage: 'জমি তৈরির শেষ চাষে পুরোটা মাটির নিচে প্রয়োগ করুন',
          ),
          FertilizerResult(
            nameBn: 'এমওপি / পটাশ (MoP)',
            englishName: 'Potassium (K) 60%',
            amountKg: decimals * 0.65,
            pricePerKg: 20.0,
            primaryColor: const Color(0xFF0288D1),
            bgColor: const Color(0xFFE1F5FE),
            icon: Icons.shield_rounded,
            role: 'পটাশিয়ামের উৎস • গাছের রোগবালাই ও পোকার আক্রমণ প্রতিরোধ, দানা পুষ্ট ও ফলন বৃদ্ধি।',
            applicationStage: 'অর্ধেক শেষ চাষে এবং বাকি অর্ধেক শেষ কিস্তি ইউরিয়ার সাথে (কাইচ থোড়ের সময়)',
          ),
          FertilizerResult(
            nameBn: 'জিপসাম (Gypsum)',
            englishName: 'Sulphur (S) 18%',
            amountKg: decimals * 0.40,
            pricePerKg: 12.0,
            primaryColor: const Color(0xFF6A1B9A),
            bgColor: const Color(0xFFF3E5F5),
            icon: Icons.bubble_chart_rounded,
            role: 'সালফারের প্রধান উৎস • পাতার হলদে রোগ দূরীকরণ, প্রোটিন তৈরি ও কুশি সতেজ রাখা।',
            applicationStage: 'জমি তৈরির শেষ চাষে পুরোটা প্রয়োগ করুন',
          ),
          FertilizerResult(
            nameBn: 'জিঙ্ক সালফেট (Zinc)',
            englishName: 'Zinc (Zn) 36%',
            amountKg: decimals * 0.04,
            pricePerKg: 200.0,
            primaryColor: const Color(0xFF00695C),
            bgColor: const Color(0xFFE0F2F1),
            icon: Icons.flare_rounded,
            role: 'অনুপুষ্টি জিংক • ধানের পাতা খর্বাকৃতি ও মরিচা রোগ রোধ করে দানা চিটা হওয়া কমায়।',
            applicationStage: 'জমি তৈরির শেষ চাষে অথবা চারা রোপণের ২০ দিন পর',
          ),
          FertilizerResult(
            nameBn: 'জৈব সার / পচা গোবর',
            englishName: 'Organic Compost',
            amountKg: decimals * 15.0,
            pricePerKg: 8.0,
            primaryColor: const Color(0xFF5D4037),
            bgColor: const Color(0xFFEFEBE9),
            icon: Icons.yard_rounded,
            role: 'মাটির স্বাস্থ্য ও জৈব পদার্থ বৃদ্ধি • পানির ধারণক্ষমতা বাড়ায় এবং রাসায়নিক সারের অপচয় রোধ করে।',
            applicationStage: 'প্রথম বা দ্বিতীয় চাষের সময় মাটির সাথে ভালোভাবে মিশিয়ে দিন',
          ),
        ];

        _timelineSteps = [
          const FertilizerTimelineStep(
            stageTitle: '১. জমি তৈরির শেষ চাষে (Basal Dose)',
            timing: 'চারা রোপণের ১-২ দিন পূর্বে',
            fertilizers: ['সম্পূর্ণ টিএসপি', 'সম্পূর্ণ জিপসাম', 'সম্পূর্ণ জিঙ্ক', '৫০% পটাশ (এমওপি)'],
            instructions: 'কাদার সাথে মিশিয়ে মই দিয়ে জমি সমতল করুন যাতে সার সমানভাবে মাটির নিচে থাকে।',
            icon: Icons.landscape_rounded,
            color: Color(0xFF2E7D32),
          ),
          const FertilizerTimelineStep(
            stageTitle: '২. প্রথম কিস্তি উপরিপ্রয়োগ',
            timing: 'চারা রোপণের ১৫-২০ দিন পর (কুশি শুরুর প্রাক্কালে)',
            fertilizers: ['ইউরিয়া সারের ১/৩ অংশ'],
            instructions: 'জমিতে ছিপছিপে পানি রেখে আগাছা নিড়ানোর পর সমানভাবে ছিটিয়ে দিন।',
            icon: Icons.grass_rounded,
            color: Color(0xFF1B5E20),
          ),
          const FertilizerTimelineStep(
            stageTitle: '৩. দ্বিতীয় কিস্তি উপরিপ্রয়োগ',
            timing: 'চারা রোপণের ৩০-৩৫ দিন পর (সর্বোচ্চ কুশি পর্যায়ে)',
            fertilizers: ['ইউরিয়া সারের ১/৩ অংশ'],
            instructions: 'সার ছিটানোর পর হাত বা উইডার দিয়ে মাটির সাথে কিছুটা ওলটপালট করে দিন।',
            icon: Icons.energy_savings_leaf_rounded,
            color: Color(0xFF00796B),
          ),
          const FertilizerTimelineStep(
            stageTitle: '৪. তৃতীয় কিস্তি উপরিপ্রয়োগ',
            timing: 'কাইচ থোড় আসার ৫-৭ দিন পূর্বে (৪৫-৫০ দিন পর)',
            fertilizers: ['বাকি ১/৩ অংশ ইউরিয়া', 'অবশিষ্ট ৫০% পটাশ (এমওপি)'],
            instructions: 'দানা পুষ্ট ও ফলন বাড়াতে এটি জরুরি। পাতা অতিরিক্ত সবুজ থাকলে ইউরিয়া সামান্য কমান।',
            icon: Icons.eco_rounded,
            color: Color(0xFF0288D1),
          ),
        ];

        _applicationGuidelines =
            'বোরো ধানে ইউরিয়া সার কখনোই একবারে দেবেন না। ৩টি সমান কিস্তিতে জমিতে হালকা পানি থাকা অবস্থায় সমানভাবে ছিটিয়ে দিন। টিএসপি, জিপসাম ও জিঙ্ক সার শেষ চাষের সময় কাদার সাথে মিশিয়ে দেওয়া জরুরি।';
        break;

      case 'আমন ধান':
        _results = [
          FertilizerResult(
            nameBn: 'ইউরিয়া (Urea)',
            englishName: 'Nitrogen (N)',
            amountKg: decimals * 0.85,
            pricePerKg: 27.0,
            primaryColor: const Color(0xFF1B5E20),
            bgColor: const Color(0xFFE8F5E9),
            icon: Icons.grain_rounded,
            role: 'গাছের শারীরিক বৃদ্ধি ও পাতা সতেজ রাখা।',
            applicationStage: '৩ কিস্তিতে উপরিপ্রয়োগ (চারা রোপণের ১০-১৫, ২৫-৩০ ও ৪০-৪৫ দিন পর)',
          ),
          FertilizerResult(
            nameBn: 'টিএসপি / ডিএপি',
            englishName: 'Phosphorus (P)',
            amountKg: decimals * 0.35,
            pricePerKg: 22.0,
            primaryColor: const Color(0xFFE65100),
            bgColor: const Color(0xFFFFF3E0),
            icon: Icons.hub_rounded,
            role: 'শিকড় শক্ত করা ও ধানের ফলন বৃদ্ধি।',
            applicationStage: 'জমি তৈরির শেষ চাষে পুরোটা দিন',
          ),
          FertilizerResult(
            nameBn: 'এমওপি / পটাশ (MoP)',
            englishName: 'Potassium (K)',
            amountKg: decimals * 0.45,
            pricePerKg: 20.0,
            primaryColor: const Color(0xFF0288D1),
            bgColor: const Color(0xFFE1F5FE),
            icon: Icons.shield_rounded,
            role: 'খরা ও রোগ প্রতিরোধ ক্ষমতা বৃদ্ধি, দানা পুষ্ট করা।',
            applicationStage: 'অর্ধেক শেষ চাষে এবং বাকি অর্ধেক থোড় আসার আগে',
          ),
          FertilizerResult(
            nameBn: 'জিপসাম (Gypsum)',
            englishName: 'Sulphur (S)',
            amountKg: decimals * 0.30,
            pricePerKg: 12.0,
            primaryColor: const Color(0xFF6A1B9A),
            bgColor: const Color(0xFFF3E5F5),
            icon: Icons.bubble_chart_rounded,
            role: 'সালফারের জোগান ও কুশি বাড়ানো।',
            applicationStage: 'জমি তৈরির শেষ চাষে পুরোটা দিন',
          ),
          FertilizerResult(
            nameBn: 'জৈব সার / পচা গোবর',
            englishName: 'Organic Compost',
            amountKg: decimals * 12.0,
            pricePerKg: 8.0,
            primaryColor: const Color(0xFF5D4037),
            bgColor: const Color(0xFFEFEBE9),
            icon: Icons.yard_rounded,
            role: 'মাটির উর্বরতা ও আর্দ্রতা রক্ষা।',
            applicationStage: 'জমি তৈরির শুরুতে চাষের সময়',
          ),
        ];

        _timelineSteps = [
          const FertilizerTimelineStep(
            stageTitle: '১. জমি তৈরির শেষ চাষে',
            timing: 'রোপণের সময়',
            fertilizers: ['সম্পূর্ণ টিএসপি', 'সম্পূর্ণ জিপসাম', '৫০% পটাশ'],
            instructions: 'মাটির সাথে ভালোভাবে মিশিয়ে কাদা সমান করুন।',
            icon: Icons.landscape_rounded,
            color: Color(0xFF2E7D32),
          ),
          const FertilizerTimelineStep(
            stageTitle: '২. ১ম কিস্তি ইউরিয়া',
            timing: 'রোপণের ১৫ দিন পর',
            fertilizers: ['ইউরিয়ার ১/৩ অংশ'],
            instructions: 'আগাছা পরিষ্কার করে জমিতে ছিপছিপে রস অবস্থায় দিন।',
            icon: Icons.grass_rounded,
            color: Color(0xFF1B5E20),
          ),
          const FertilizerTimelineStep(
            stageTitle: '৩. ২য় ও ৩য় কিস্তি',
            timing: '৩০ দিন ও ৪৫ দিন পর',
            fertilizers: ['বাকি ইউরিয়া ও অবশিষ্ট পটাশ'],
            instructions: 'কুশি ও থোড় আসার সময়ে বাকি সার সুষমভাবে দিন।',
            icon: Icons.eco_rounded,
            color: Color(0xFF0288D1),
          ),
        ];
        _applicationGuidelines = 'আমন ধানে বেশি মাত্রায় ইউরিয়া দিলে রোগ ও পোকার আক্রমণ বাড়ে। নিয়মমাফিক ৩ কিস্তিতে দিন।';
        break;

      case 'গোল আলু':
        _results = [
          FertilizerResult(
            nameBn: 'ইউরিয়া (Urea)',
            englishName: 'Nitrogen (N)',
            amountKg: decimals * 1.25,
            pricePerKg: 27.0,
            primaryColor: const Color(0xFF1B5E20),
            bgColor: const Color(0xFFE8F5E9),
            icon: Icons.grain_rounded,
            role: 'আলু গাছের বিস্তার ও পাতার সঠিক বৃদ্ধি।',
            applicationStage: 'অর্ধেক শেষ চাষে এবং বাকি অর্ধেক রোপণের ৩০-৩৫ দিন পর মাটি তোলার সময়',
          ),
          FertilizerResult(
            nameBn: 'টিএসপি / ডিএপি',
            englishName: 'Phosphorus (P)',
            amountKg: decimals * 0.85,
            pricePerKg: 22.0,
            primaryColor: const Color(0xFFE65100),
            bgColor: const Color(0xFFFFF3E0),
            icon: Icons.hub_rounded,
            role: 'শিকড় বৃদ্ধি ও আলুর গুঁটি (Tuber) গঠন দ্রুত করে।',
            applicationStage: 'জমি তৈরির শেষ চাষে পুরোটা দিন',
          ),
          FertilizerResult(
            nameBn: 'এমওপি / পটাশ (MoP)',
            englishName: 'Potassium (K)',
            amountKg: decimals * 1.10,
            pricePerKg: 20.0,
            primaryColor: const Color(0xFF0288D1),
            bgColor: const Color(0xFFE1F5FE),
            icon: Icons.shield_rounded,
            role: 'আলুর সাইজ বড় করা, খোসা মসৃণ রাখা ও রোগ প্রতিরোধ ক্ষমতা বৃদ্ধি।',
            applicationStage: 'অর্ধেক শেষ চাষে এবং বাকি অর্ধেক ৩০ দিন পর মাটি তোলার সময়',
          ),
          FertilizerResult(
            nameBn: 'জিপসাম ও বোরন',
            englishName: 'Gypsum + Boron',
            amountKg: decimals * 0.48,
            pricePerKg: 25.0,
            primaryColor: const Color(0xFF6A1B9A),
            bgColor: const Color(0xFFF3E5F5),
            icon: Icons.bubble_chart_rounded,
            role: 'আলুর ফেটে যাওয়া রোধ করে ও ভেতর ফাঁপা হওয়া প্রতিরোধ করে।',
            applicationStage: 'জমি তৈরির শেষ চাষে মাটির নিচে দিন',
          ),
          FertilizerResult(
            nameBn: 'জৈব সার / ভার্মিকম্পোস্ট',
            englishName: 'Vermicompost',
            amountKg: decimals * 25.0,
            pricePerKg: 10.0,
            primaryColor: const Color(0xFF5D4037),
            bgColor: const Color(0xFFEFEBE9),
            icon: Icons.yard_rounded,
            role: 'মাটি ঝুরঝুরে রাখা যা আলু বৃদ্ধির জন্য সবচেয়ে উপযোগী।',
            applicationStage: 'জমি তৈরির শুরুতে চাষে দিন',
          ),
        ];

        _timelineSteps = [
          const FertilizerTimelineStep(
            stageTitle: '১. জমি তৈরির শেষ চাষে',
            timing: 'আলু রোপণের দিন',
            fertilizers: ['সম্পূর্ণ টিএসপি', 'সম্পূর্ণ জিপসাম ও বোরন', '৫০% ইউরিয়া', '৫০% পটাশ'],
            instructions: 'নালা বা লাইনের নিচে সার দিয়ে মাটি দিয়ে হালকা ঢেকে আলু বীজ বসান।',
            icon: Icons.landscape_rounded,
            color: Color(0xFF2E7D32),
          ),
          const FertilizerTimelineStep(
            stageTitle: '২. মাটি তোলার সময় (Earthing up)',
            timing: 'রোপণের ৩০-৩৫ দিন পর',
            fertilizers: ['অবশিষ্ট ৫০% ইউরিয়া', 'অবশিষ্ট ৫০% পটাশ'],
            instructions: 'গাছের গোড়ায় সার ছিটিয়ে দুই পাশ থেকে মাটি তুলে ভেলি উঁচু করে দিন।',
            icon: Icons.terrain_rounded,
            color: Color(0xFF0288D1),
          ),
        ];
        _applicationGuidelines = 'আলুর আকার বড় ও মানসম্মত করতে পটাশ (MoP) ও বোরন সার অত্যন্ত গুরুত্বপূর্ণ। দ্বিতীয় কিস্তির সাথে অবশ্যই গোড়ায় মাটি তুলুন।';
        break;

      case 'ভুট্টা':
        _results = [
          FertilizerResult(
            nameBn: 'ইউরিয়া (Urea)',
            englishName: 'Nitrogen (N)',
            amountKg: decimals * 2.0,
            pricePerKg: 27.0,
            primaryColor: const Color(0xFF1B5E20),
            bgColor: const Color(0xFFE8F5E9),
            icon: Icons.grain_rounded,
            role: 'ভুট্টার দ্রুত বৃদ্ধি, গাঢ় সবুজ মোচা ও বড় পাতা গঠনে প্রধান সহায়ক।',
            applicationStage: '৩টি সমান কিস্তিতে (শেষ চাষে ১/৩, ২৫ দিন পর ১/৩ এবং ৫০ দিন পর ১/৩)',
          ),
          FertilizerResult(
            nameBn: 'ডিএপি / টিএসপি',
            englishName: 'Phosphorus (P)',
            amountKg: decimals * 1.0,
            pricePerKg: 22.0,
            primaryColor: const Color(0xFFE65100),
            bgColor: const Color(0xFFFFF3E0),
            icon: Icons.hub_rounded,
            role: 'শক্ত শিকড় ও লম্বা শক্ত কাণ্ড তৈরি।',
            applicationStage: 'জমি তৈরির শেষ চাষে পুরোটা প্রয়োগ করুন',
          ),
          FertilizerResult(
            nameBn: 'এমওপি / পটাশ (MoP)',
            englishName: 'Potassium (K)',
            amountKg: decimals * 0.85,
            pricePerKg: 20.0,
            primaryColor: const Color(0xFF0288D1),
            bgColor: const Color(0xFFE1F5FE),
            icon: Icons.shield_rounded,
            role: 'মোচায় দানার পূর্ণতা ও দানা ঝরে পড়া রোধ করে।',
            applicationStage: 'অর্ধেক শেষ চাষে এবং বাকি অর্ধেক মোচা আসার প্রাক্কালে',
          ),
          FertilizerResult(
            nameBn: 'জিপসাম ও জিংক',
            englishName: 'Gypsum + Zinc',
            amountKg: decimals * 0.55,
            pricePerKg: 25.0,
            primaryColor: const Color(0xFF6A1B9A),
            bgColor: const Color(0xFFF3E5F5),
            icon: Icons.bubble_chart_rounded,
            role: 'পাতার শিরা বিবর্ণ হওয়া রোধ ও পরাগায়ন বৃদ্ধি।',
            applicationStage: 'জমি তৈরির শেষ চাষে দিন',
          ),
          FertilizerResult(
            nameBn: 'জৈব সার',
            englishName: 'Compost',
            amountKg: decimals * 20.0,
            pricePerKg: 8.0,
            primaryColor: const Color(0xFF5D4037),
            bgColor: const Color(0xFFEFEBE9),
            icon: Icons.yard_rounded,
            role: 'মাটির উর্বরতা ও আর্দ্রতা রক্ষা।',
            applicationStage: 'প্রথম চাষের সময় দিন',
          ),
        ];

        _timelineSteps = [
          const FertilizerTimelineStep(
            stageTitle: '১. জমি তৈরির শেষ চাষে',
            timing: 'বীজ বপনের পূর্বে',
            fertilizers: ['সম্পূর্ণ টিএসপি', 'সম্পূর্ণ জিপসাম ও জিংক', '১/৩ ইউরিয়া', '৫০% পটাশ'],
            instructions: 'মাটিতে সমানভাবে মিশিয়ে দিন।',
            icon: Icons.landscape_rounded,
            color: Color(0xFF2E7D32),
          ),
          const FertilizerTimelineStep(
            stageTitle: '২. হাঁটু সমান উচ্চতায় (Knee-high)',
            timing: 'বপনের ২৫-৩০ দিন পর',
            fertilizers: ['১/৩ ইউরিয়া'],
            instructions: 'গাছের গোড়া থেকে ৫-৬ সেমি দূরে রিং বা লাইন করে দিয়ে সেচ দিন।',
            icon: Icons.grass_rounded,
            color: Color(0xFF1B5E20),
          ),
          const FertilizerTimelineStep(
            stageTitle: '৩. মোচা ও ফুল আসার পূর্বে',
            timing: 'বপনের ৫০-৫৫ দিন পর',
            fertilizers: ['বাকি ১/৩ ইউরিয়া', 'অবশিষ্ট ৫০% পটাশ'],
            instructions: 'মোচায় দানা পূর্ণ করার জন্য এই কিস্তি অত্যন্ত গুরুত্বপূর্ণ।',
            icon: Icons.eco_rounded,
            color: Color(0xFF0288D1),
          ),
        ];
        _applicationGuidelines = 'ভুট্টা অত্যন্ত পুষ্টিগ্রাহী ফসল। ইউরিয়া ও পটাশ কিস্তিতে দিয়ে প্রতি কিস্তির পর হালকা সেচ দিন।';
        break;

      case 'টমেটো':
      case 'বেগুন':
      case 'মরিচ':
        _results = [
          FertilizerResult(
            nameBn: 'ইউরিয়া (Urea)',
            englishName: 'Nitrogen (N)',
            amountKg: decimals * 1.10,
            pricePerKg: 27.0,
            primaryColor: const Color(0xFF1B5E20),
            bgColor: const Color(0xFFE8F5E9),
            icon: Icons.grain_rounded,
            role: 'শাখা-প্রশাখা বৃদ্ধি ও প্রচুর ফুল আসার উপযোগী পাতা তৈরি।',
            applicationStage: 'চারা রোপণের ১৫, ৩০ এবং ৪৫ দিন পর ৩ কিস্তিতে উপরিপ্রয়োগ',
          ),
          FertilizerResult(
            nameBn: 'টিএসপি / ডিএপি',
            englishName: 'Phosphorus (P)',
            amountKg: decimals * 0.80,
            pricePerKg: 22.0,
            primaryColor: const Color(0xFFE65100),
            bgColor: const Color(0xFFFFF3E0),
            icon: Icons.hub_rounded,
            role: 'মাদায় শিকড় মজবুত করা ও ফুল ঝরে পড়া রোধ করা।',
            applicationStage: 'বেড তৈরির সময় মাটির নিচে দিন',
          ),
          FertilizerResult(
            nameBn: 'এমওপি / পটাশ (MoP)',
            englishName: 'Potassium (K)',
            amountKg: decimals * 0.85,
            pricePerKg: 20.0,
            primaryColor: const Color(0xFF0288D1),
            bgColor: const Color(0xFFE1F5FE),
            icon: Icons.shield_rounded,
            role: 'ফলের আকার বড় ও চকচকে করা, স্বাদ ও রঙ সুন্দর করা।',
            applicationStage: 'অর্ধেক বেড তৈরিতে, বাকি অর্ধেক ফুল ও ফল ধরার সময়',
          ),
          FertilizerResult(
            nameBn: 'জিপসাম ও বোরন',
            englishName: 'Gypsum + Boron',
            amountKg: decimals * 0.40,
            pricePerKg: 30.0,
            primaryColor: const Color(0xFF6A1B9A),
            bgColor: const Color(0xFFF3E5F5),
            icon: Icons.bubble_chart_rounded,
            role: 'ফল পচা ও ফেটে যাওয়া রোধ করে।',
            applicationStage: 'জমি তৈরিতে দিন',
          ),
          FertilizerResult(
            nameBn: 'জৈব সার / ভার্মিকম্পোস্ট',
            englishName: 'Organic Compost',
            amountKg: decimals * 20.0,
            pricePerKg: 10.0,
            primaryColor: const Color(0xFF5D4037),
            bgColor: const Color(0xFFEFEBE9),
            icon: Icons.yard_rounded,
            role: 'শাকসবজিতে মাটির জৈব রস বজায় রাখা।',
            applicationStage: 'প্রতি মাদায় বা বেডে ভালো করে মিশিয়ে দিন',
          ),
        ];

        _timelineSteps = [
          const FertilizerTimelineStep(
            stageTitle: '১. বেড বা মাদা তৈরির সময়',
            timing: 'চারা লাগানোর ৩-৫ দিন পূর্বে',
            fertilizers: ['সম্পূর্ণ টিএসপি', 'সম্পূর্ণ জিপসাম ও বোরন', '৫০% পটাশ', 'সম্পূর্ণ জৈব সার'],
            instructions: 'মাদার মাটির সাথে ভালোভাবে মিশিয়ে দিন।',
            icon: Icons.landscape_rounded,
            color: Color(0xFF2E7D32),
          ),
          const FertilizerTimelineStep(
            stageTitle: '২. প্রথম ও দ্বিতীয় কিস্তি',
            timing: 'রোপণের ১৫ ও ৩০ দিন পর',
            fertilizers: ['ইউরিয়া সারের দুই কিস্তি'],
            instructions: 'গাছের গোড়া থেকে দূরে রিং আকারে দিয়ে মাটি চাপা দিন।',
            icon: Icons.grass_rounded,
            color: Color(0xFF1B5E20),
          ),
          const FertilizerTimelineStep(
            stageTitle: '৩. ফল তোলার সময়কালীন কিস্তি',
            timing: 'রোপণের ৪৫-৫০ দিন পর',
            fertilizers: ['বাকি ইউরিয়া ও অবশিষ্ট ৫০% পটাশ'],
            instructions: 'ফল তোলার পর গাছে সজীবতা ফেরাতে এই কিস্তি দিন।',
            icon: Icons.eco_rounded,
            color: Color(0xFF0288D1),
          ),
        ];
        _applicationGuidelines = 'অতিরিক্ত ইউরিয়া দিলে গাছ অতিরিক্ত বাড়ে কিন্তু ফুল-ফল কমে যায়। সুষম অনুপাতে সার প্রয়োগ করুন।';
        break;

      default:
        _results = [
          FertilizerResult(
            nameBn: 'ইউরিয়া (Urea)',
            englishName: 'Nitrogen (N)',
            amountKg: decimals * 1.0,
            pricePerKg: 27.0,
            primaryColor: const Color(0xFF1B5E20),
            bgColor: const Color(0xFFE8F5E9),
            icon: Icons.grain_rounded,
            role: 'গাছের দৈহিক বৃদ্ধি ও পাতা সবুজ রাখা।',
            applicationStage: '২-৩ কিস্তিতে উপরিপ্রয়োগ',
          ),
          FertilizerResult(
            nameBn: 'টিএসপি / ডিএপি',
            englishName: 'Phosphorus (P)',
            amountKg: decimals * 0.60,
            pricePerKg: 22.0,
            primaryColor: const Color(0xFFE65100),
            bgColor: const Color(0xFFFFF3E0),
            icon: Icons.hub_rounded,
            role: 'শিকড় বিস্তার ও কাণ্ড মজবুত করা।',
            applicationStage: 'জমি তৈরির শেষ চাষে পুরোটা দিন',
          ),
          FertilizerResult(
            nameBn: 'এমওপি / পটাশ (MoP)',
            englishName: 'Potassium (K)',
            amountKg: decimals * 0.50,
            pricePerKg: 20.0,
            primaryColor: const Color(0xFF0288D1),
            bgColor: const Color(0xFFE1F5FE),
            icon: Icons.shield_rounded,
            role: 'রোগ প্রতিরোধ ক্ষমতা ও ফলন বাড়ানো।',
            applicationStage: 'শেষ চাষে এবং বৃদ্ধির মাঝামাঝি সময়ে',
          ),
          FertilizerResult(
            nameBn: 'জিপসাম (Gypsum)',
            englishName: 'Sulphur (S)',
            amountKg: decimals * 0.35,
            pricePerKg: 12.0,
            primaryColor: const Color(0xFF6A1B9A),
            bgColor: const Color(0xFFF3E5F5),
            icon: Icons.bubble_chart_rounded,
            role: 'সালফারের ঘাটতি পূরণ ও ফসল সতেজ রাখা।',
            applicationStage: 'জমি তৈরিতে দিন',
          ),
          FertilizerResult(
            nameBn: 'জৈব সার',
            englishName: 'Compost',
            amountKg: decimals * 15.0,
            pricePerKg: 8.0,
            primaryColor: const Color(0xFF5D4037),
            bgColor: const Color(0xFFEFEBE9),
            icon: Icons.yard_rounded,
            role: 'মাটির উর্বরতা ও স্বাস্থ্য বৃদ্ধি।',
            applicationStage: 'জমি তৈরির শুরুতে চাষে দিন',
          ),
        ];

        _timelineSteps = [
          const FertilizerTimelineStep(
            stageTitle: '১. জমি তৈরির সময়',
            timing: 'বপন বা রোপণের পূর্বে',
            fertilizers: ['সম্পূর্ণ টিএসপি', 'সম্পূর্ণ জিপসাম', '৫০% পটাশ'],
            instructions: 'মাটির সাথে ভালোভাবে মিশিয়ে চাষ দিন।',
            icon: Icons.landscape_rounded,
            color: Color(0xFF2E7D32),
          ),
          const FertilizerTimelineStep(
            stageTitle: '২. ফসলের প্রাথমিক বৃদ্ধি পর্যায়ে',
            timing: '২০-২৫ দিন বয়সে',
            fertilizers: ['ইউরিয়া সারের প্রথম কিস্তি'],
            instructions: 'হালকা রসে আগাছা নিড়ানোর পর দিন।',
            icon: Icons.grass_rounded,
            color: Color(0xFF1B5E20),
          ),
          const FertilizerTimelineStep(
            stageTitle: '৩. ফুল ও দানা আসার সময়',
            timing: '৪০-৫০ দিন বয়সে',
            fertilizers: ['বাকি ইউরিয়া ও অবশিষ্ট পটাশ'],
            instructions: 'গাছের খাদ্য সঞ্চয়ের জন্য এই কিস্তি দিন।',
            icon: Icons.eco_rounded,
            color: Color(0xFF0288D1),
          ),
        ];
        _applicationGuidelines = 'মাটি পরীক্ষা করে সার দিলে অপচয় কমে ও ফলন সর্বোচ্চ পাওয়া যায়। রাসায়নিকের পাশাপাশি সবসময় জৈব সার ব্যবহার করুন।';
        break;
    }

    notifyListeners();
  }
}
