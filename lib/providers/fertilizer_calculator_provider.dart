import 'package:flutter/material.dart';
import '../core/utils/bangla_number_converter.dart';

class FertilizerResult {
  final String nameBn;
  final double amountKg;
  final String applicationStage;
  final String note;

  const FertilizerResult({
    required this.nameBn,
    required this.amountKg,
    required this.applicationStage,
    this.note = '',
  });

  String get formattedAmount {
    if (amountKg >= 40) {
      final mon = amountKg / 40.0;
      final monStr = mon % 1 == 0 ? mon.toInt().toString() : mon.toStringAsFixed(1);
      final kgStr = amountKg % 1 == 0 ? amountKg.toInt().toString() : amountKg.toStringAsFixed(1);
      return '${BanglaNumberConverter.toBangla(monStr)} মণ (${BanglaNumberConverter.toBangla(kgStr)} কেজি)';
    }
    final kgStr = amountKg % 1 == 0 ? amountKg.toInt().toString() : amountKg.toStringAsFixed(1);
    return '${BanglaNumberConverter.toBangla(kgStr)} কেজি';
  }
}

class FertilizerCalculatorProvider extends ChangeNotifier {
  String _selectedCrop = 'বোরো ধান';
  String _selectedUnit = 'শতাংশ (শতক)';
  double _landArea = 10.0;
  List<FertilizerResult> _results = [];
  String _applicationGuidelines = '';

  String get selectedCrop => _selectedCrop;
  String get selectedUnit => _selectedUnit;
  double get landArea => _landArea;
  List<FertilizerResult> get results => _results;
  String get applicationGuidelines => _applicationGuidelines;

  final List<String> supportedCrops = [
    'বোরো ধান',
    'আমন ধান',
    'গোল আলু',
    'ভুট্টা',
    'গম',
    'টমেটো',
    'বেগুন',
    'সরিষা',
    'পেঁয়াজ',
  ];

  final List<String> supportedUnits = [
    'শতাংশ (শতক)',
    'বিঘা (৩৩ শতক)',
    'একর (১০০ শতক)',
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
      _applicationGuidelines = '';
      notifyListeners();
      return;
    }

    // Normalize to Decimals (শতাংশ)
    double decimals = _landArea;
    if (_selectedUnit == 'বিঘা (৩৩ শতক)') {
      decimals = _landArea * 33.0;
    } else if (_selectedUnit == 'একর (১০০ শতক)') {
      decimals = _landArea * 100.0;
    }

    switch (_selectedCrop) {
      case 'বোরো ধান':
        _results = [
          FertilizerResult(
            nameBn: 'ইউরিয়া (Urea)',
            amountKg: decimals * 1.1,
            applicationStage: '৩ কিস্তিতে উপরিপ্রয়োগ (চারা রোপণের ১৫, ৩০ ও ৪৫ দিন পর)',
            note: 'জমিতে রস বা হালকা পানি থাকা অবস্থায় দিন',
          ),
          FertilizerResult(
            nameBn: 'টিএসপি (TSP)',
            amountKg: decimals * 0.45,
            applicationStage: 'জমি তৈরির শেষ চাষে পুরোটা প্রয়োগ করুন',
          ),
          FertilizerResult(
            nameBn: 'এমওপি / পটাশ (MoP)',
            amountKg: decimals * 0.65,
            applicationStage: 'অর্ধেক শেষ চাষে এবং বাকি অর্ধেক শেষ কিস্তি ইউরিয়ার সাথে',
          ),
          FertilizerResult(
            nameBn: 'জিপসাম (Gypsum)',
            amountKg: decimals * 0.4,
            applicationStage: 'জমি তৈরির শেষ চাষে পুরোটা প্রয়োগ করুন',
          ),
          FertilizerResult(
            nameBn: 'জিঙ্ক সালফেট (Zinc)',
            amountKg: decimals * 0.04,
            applicationStage: 'জমি তৈরির শেষ চাষে প্রয়োগ করুন',
          ),
          FertilizerResult(
            nameBn: 'পচা গোবর / জৈব সার',
            amountKg: decimals * 15.0,
            applicationStage: 'প্রথম চাষের সময় মাটির সাথে ভালোভাবে মিশিয়ে দিন',
          ),
        ];
        _applicationGuidelines =
            'বোরো ধানে ইউরিয়া সার কখনোই একবারে দেবেন না। ৩টি সমান কিস্তিতে জমিতে হালকা পানি থাকা অবস্থায় সমানভাবে ছিটিয়ে দিন। টিএসপি, জিপসাম ও জিঙ্ক সার শেষ চাষের সময় কাদার সাথে মিশিয়ে দেওয়া জরুরি।';
        break;

      case 'গোল আলু':
        _results = [
          FertilizerResult(
            nameBn: 'ইউরিয়া (Urea)',
            amountKg: decimals * 1.25,
            applicationStage: 'অর্ধেক শেষ চাষে এবং বাকি অর্ধেক রোপণের ৩০-৩৫ দিন পর মাটি তোলার সময়',
          ),
          FertilizerResult(
            nameBn: 'টিএসপি (TSP)',
            amountKg: decimals * 0.85,
            applicationStage: 'জমি তৈরির শেষ চাষে পুরোটা দিন',
          ),
          FertilizerResult(
            nameBn: 'এমওপি / পটাশ (MoP)',
            amountKg: decimals * 1.1,
            applicationStage: 'অর্ধেক শেষ চাষে এবং বাকি অর্ধেক গাছ ৩০ দিন বয়সে মাটি তোলার সময়',
          ),
          FertilizerResult(
            nameBn: 'জিপসাম (Gypsum)',
            amountKg: decimals * 0.45,
            applicationStage: 'জমি তৈরির শেষ চাষে',
          ),
          FertilizerResult(
            nameBn: 'বোরন / ম্যাগনেশিয়াম',
            amountKg: decimals * 0.035,
            applicationStage: 'শেষ চাষের সময় অথবা ৩৫ দিন পর স্প্রে',
          ),
          FertilizerResult(
            nameBn: 'জৈব সার / ভার্মিকম্পোস্ট',
            amountKg: decimals * 25.0,
            applicationStage: 'প্রথম চাষের সময় জমিতে ছড়িয়ে চাষ দিন',
          ),
        ];
        _applicationGuidelines =
            'আলুর আকার বড় ও মানসম্মত করতে পটাশ (MoP) ও বোরন সার অত্যন্ত কার্যকরী ভূমিকা রাখে। দ্বিতীয় কিস্তি সারের সাথে অবশ্যই গোড়ায় মাটি তুলে দিতে হবে।';
        break;

      case 'টমেটো':
        _results = [
          FertilizerResult(
            nameBn: 'ইউরিয়া (Urea)',
            amountKg: decimals * 1.0,
            applicationStage: 'চারা রোপণের ১৫, ৩০ এবং ৪৫ দিন পর ৩ কিস্তিতে উপরিপ্রয়োগ',
          ),
          FertilizerResult(
            nameBn: 'টিএসপি (TSP)',
            amountKg: decimals * 0.75,
            applicationStage: 'মাদায় বা বেড তৈরির সময় মাটির নিচে দিন',
          ),
          FertilizerResult(
            nameBn: 'এমওপি (MoP)',
            amountKg: decimals * 0.8,
            applicationStage: 'অর্ধেক বেড তৈরিতে, বাকি অর্ধেক ফল ধরার সময়',
          ),
          FertilizerResult(
            nameBn: 'জৈব সার',
            amountKg: decimals * 20.0,
            applicationStage: 'মাদাপ্রতি ২-৩ কেজি হারে ভালো করে মিশিয়ে দিন',
          ),
        ];
        _applicationGuidelines =
            'টমেটোতে ফল পচা রোধে ক্যালসিয়াম ও বোরন স্প্রে করুন। গাছে অতিরিক্ত ইউরিয়া দিলে ডালপালা বাড়বে কিন্তু ফুল কমে যাবে, তাই সুষম মাত্রায় প্রয়োগ করুন।';
        break;

      default:
        _results = [
          FertilizerResult(
            nameBn: 'ইউরিয়া (Urea)',
            amountKg: decimals * 1.0,
            applicationStage: '২-৩ কিস্তিতে উপরিপ্রয়োগ',
          ),
          FertilizerResult(
            nameBn: 'টিএসপি / ডিএপি',
            amountKg: decimals * 0.6,
            applicationStage: 'জমি তৈরির শেষ চাষে',
          ),
          FertilizerResult(
            nameBn: 'এমওপি (পটাশ)',
            amountKg: decimals * 0.5,
            applicationStage: 'শেষ চাষে ও বৃদ্ধির মাঝামাঝি সময়ে',
          ),
          FertilizerResult(
            nameBn: 'জৈব সার',
            amountKg: decimals * 15.0,
            applicationStage: 'জমি তৈরির শুরুতে',
          ),
        ];
        _applicationGuidelines =
            'মাটি পরীক্ষা করে সার দিলে অপচয় কম হয় এবং ফলন সর্বোচ্চ পাওয়া যায়। রাসায়নিক সারের পাশাপাশি সবসময় পর্যাপ্ত জৈব সার ব্যবহার করুন।';
        break;
    }

    notifyListeners();
  }
}
