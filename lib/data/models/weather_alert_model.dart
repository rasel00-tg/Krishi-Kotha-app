import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class WeatherAlertModel {
  final String id;
  final String title;
  final String description;
  final String severity; // 'critical', 'warning', 'info'
  final String district;
  final DateTime timestamp;

  const WeatherAlertModel({
    required this.id,
    required this.title,
    required this.description,
    required this.severity,
    required this.district,
    required this.timestamp,
  });

  factory WeatherAlertModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return WeatherAlertModel(
      id: doc.id,
      title: data['title'] as String? ?? 'জরুরি কৃষি সতর্কবার্তা',
      description: data['description'] as String? ?? '',
      severity: data['severity'] as String? ?? 'warning',
      district: data['district'] as String? ?? 'সকল জেলা',
      timestamp: (data['timestamp'] is Timestamp)
          ? (data['timestamp'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  factory WeatherAlertModel.fromMap(Map<String, dynamic> data, String id) {
    return WeatherAlertModel(
      id: id,
      title: data['title'] as String? ?? 'জরুরি কৃষি সতর্কবার্তা',
      description: data['description'] as String? ?? '',
      severity: data['severity'] as String? ?? 'warning',
      district: data['district'] as String? ?? 'সকল জেলা',
      timestamp: (data['timestamp'] is Timestamp)
          ? (data['timestamp'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'severity': severity,
      'district': district,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }

  Color get color {
    switch (severity.toLowerCase()) {
      case 'critical':
        return AppColors.alertCritical;
      case 'warning':
        return AppColors.alertWarning;
      case 'info':
      default:
        return AppColors.alertInfo;
    }
  }

  Color get backgroundColor {
    switch (severity.toLowerCase()) {
      case 'critical':
        return AppColors.alertCriticalBg;
      case 'warning':
        return AppColors.alertWarningBg;
      case 'info':
      default:
        return AppColors.alertInfoBg;
    }
  }

  IconData get icon {
    switch (severity.toLowerCase()) {
      case 'critical':
        return Icons.warning_rounded;
      case 'warning':
        return Icons.error_outline_rounded;
      case 'info':
      default:
        return Icons.info_outline_rounded;
    }
  }
}
