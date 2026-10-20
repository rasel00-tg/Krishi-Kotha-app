import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'bangla_number_converter.dart';

class BanglaDateFormatter {
  static const Map<String, String> _monthNames = {
    '1': 'জানুয়ারি',
    '2': 'ফেব্রুয়ারি',
    '3': 'মার্চ',
    '4': 'এপ্রিল',
    '5': 'মে',
    '6': 'জুন',
    '7': 'জুলাই',
    '8': 'আগস্ট',
    '9': 'সেপ্টেম্বর',
    '10': 'অক্টোবর',
    '11': 'নভেম্বর',
    '12': 'ডিসেম্বর',
  };

  /// Converts Timestamp or DateTime to formatted Bangla relative string
  /// (e.g. '৫ মিনিট আগে', '২ ঘণ্টা আগে', 'আজ সকাল ১০:৩০', 'গতকাল', '১২ অক্টোবর ২০২৪')
  static String formatRelative(dynamic dateObj) {
    if (dateObj == null) return '';

    DateTime dateTime;
    if (dateObj is Timestamp) {
      dateTime = dateObj.toDate();
    } else if (dateObj is DateTime) {
      dateTime = dateObj;
    } else {
      return '';
    }

    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inSeconds < 60) {
      return 'এইমাত্র';
    } else if (difference.inMinutes < 60) {
      return '${BanglaNumberConverter.toBangla(difference.inMinutes)} মিনিট আগে';
    } else if (difference.inHours < 24 && now.day == dateTime.day) {
      return '${BanglaNumberConverter.toBangla(difference.inHours)} ঘণ্টা আগে';
    } else if (difference.inDays == 1 || (difference.inHours < 48 && now.day - dateTime.day == 1)) {
      final timeStr = DateFormat('hh:mm').format(dateTime);
      final period = dateTime.hour >= 12 ? 'বিকাল' : 'সকাল';
      return 'গতকাল $period ${BanglaNumberConverter.toBangla(timeStr)}';
    } else {
      final day = BanglaNumberConverter.toBangla(dateTime.day);
      final month = _monthNames[dateTime.month.toString()] ?? '';
      final year = BanglaNumberConverter.toBangla(dateTime.year);
      return '$day $month $year';
    }
  }

  /// Formats Date into full Bengali Date with time
  static String formatFull(dynamic dateObj) {
    if (dateObj == null) return '';

    DateTime dateTime;
    if (dateObj is Timestamp) {
      dateTime = dateObj.toDate();
    } else if (dateObj is DateTime) {
      dateTime = dateObj;
    } else {
      return '';
    }

    final day = BanglaNumberConverter.toBangla(dateTime.day);
    final month = _monthNames[dateTime.month.toString()] ?? '';
    final year = BanglaNumberConverter.toBangla(dateTime.year);
    final timeStr = DateFormat('hh:mm a').format(dateTime);
    return '$day $month $year, ${BanglaNumberConverter.toBangla(timeStr)}';
  }
}
