import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/utils/bangla_number_converter.dart';

class MarketPriceModel {
  final String id;
  final String district;
  final String marketName;
  final String cropName;
  final String unit; // কেজি, মণ, বস্তা, হালি, কুড়ি
  final double price; // পাইকারি দর
  final double retailPrice; // খুচরা দর
  final String priceText;
  final String retailPriceText;
  final String imageUrl;
  final String trend; // 'up', 'down', 'stable'
  final DateTime updatedAt;

  const MarketPriceModel({
    required this.id,
    required this.district,
    required this.marketName,
    required this.cropName,
    required this.unit,
    required this.price,
    this.retailPrice = 0.0,
    this.priceText = '',
    this.retailPriceText = '',
    this.imageUrl = '',
    this.trend = 'stable',
    required this.updatedAt,
  });

  static double parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    if (value is String) {
      final engStr = BanglaNumberConverter.toEnglish(value);
      final sanitized = engStr.replaceAll(RegExp(r'[^0-9.]'), '');
      return double.tryParse(sanitized) ?? 0.0;
    }
    return 0.0;
  }

  static String _firstNonEmpty(List<dynamic> candidates, [String fallback = '']) {
    for (final c in candidates) {
      if (c != null) {
        final s = c.toString().trim();
        if (s.isNotEmpty) return s;
      }
    }
    return fallback;
  }

  static dynamic _firstNonNull(List<dynamic> candidates) {
    for (final c in candidates) {
      if (c != null) {
        if (c is String) {
          final s = c.trim();
          if (s.isNotEmpty && s != '0') return c;
        } else if (c is num && c > 0) {
          return c;
        }
      }
    }
    for (final c in candidates) {
      if (c != null) return c;
    }
    return null;
  }

  factory MarketPriceModel.fromFirestore(DocumentSnapshot doc) {
    try {
      final raw = doc.data();
      final Map<String, dynamic> data = {};
      if (raw is Map) {
        raw.forEach((k, v) {
          if (k != null) data[k.toString()] = v;
        });
      }
      return MarketPriceModel.fromMap(data, doc.id);
    } catch (e) {
      return MarketPriceModel(
        id: doc.id,
        district: '',
        marketName: 'স্থানীয় বাজার',
        cropName: 'ফসল',
        unit: 'কেজি',
        price: 0.0,
        retailPrice: 0.0,
        priceText: '০',
        retailPriceText: '০',
        imageUrl: '',
        trend: 'stable',
        updatedAt: DateTime.now(),
      );
    }
  }

  factory MarketPriceModel.fromMap(Map<String, dynamic> data, String id) {
    DateTime time;
    try {
      final rawTime = data['updatedAt'] ?? data['updated_at'] ?? data['timestamp'] ?? data['date'] ?? data['createdAt'];
      if (rawTime is Timestamp) {
        time = rawTime.toDate();
      } else if (rawTime is String) {
        time = DateTime.tryParse(rawTime) ?? DateTime.now();
      } else if (rawTime is int) {
        time = DateTime.fromMillisecondsSinceEpoch(rawTime);
      } else {
        time = DateTime.now();
      }
    } catch (_) {
      time = DateTime.now();
    }

    // ১. ফসলের নাম: data['crop_name'] ?? data['cropName'] ?? 'ফসল'
    final String cropName = _firstNonEmpty([
      data['crop_name'],
      data['cropName'],
      data['name'],
      data['crop'],
      data['name_bn'],
      data['title'],
    ], 'ফসল');

    // ২. ছবি URL: data['image_url'] ?? data['imageUrl'] ?? ''
    final String imageUrl = _firstNonEmpty([
      data['image_url'],
      data['imageUrl'],
      data['img'],
      data['image'],
    ], '');

    // ৩. বাজারের নাম: data['market_name'] ?? data['marketName'] ?? 'স্থানীয় বাজার'
    final String marketName = _firstNonEmpty([
      data['market_name'],
      data['marketName'],
      data['market'],
      data['bazar_name'],
      data['bazar'],
      data['hat'],
    ], 'স্থানীয় বাজার');

    // ৪. পাইকারি দর: data['price'] != null ? '${data['price']}' : '০'
    final dynamic rawPrice = _firstNonNull([
      data['price'],
      data['wholesale_price'],
      data['wholesalePrice'],
      data['wholesale'],
      data['rate'],
      data['bazar_dor'],
    ]);
    final String priceText = rawPrice != null ? '$rawPrice'.trim() : '০';

    // ৫. খুচরা দর: (data['retail_price'] ?? data['retailPrice']) != null ? '${data['retail_price'] ?? data['retailPrice']}' : '০'
    final dynamic rawRetail = _firstNonNull([
      data['retail_price'],
      data['retailPrice'],
      data['retail'],
      data['khuchra'],
    ]);
    final String retailPriceText = rawRetail != null ? '$rawRetail'.trim() : '০';

    // ৬. ইউনিট: data['unit']?.toString() ?? 'কেজি'
    final String unit = (data['unit'] ?? data['unit_name'] ?? data['unitName'] ?? data['poriman'] ?? 'কেজি').toString().trim();

    // ৭. জেলা: data['district']?.toString() ?? ''
    final String district = (data['district'] ?? data['district_name'] ?? data['districtName'] ?? data['division'] ?? data['location'] ?? data['jela'] ?? '').toString().trim();

    // ৮. ট্রেন্ড: data['trend']?.toString() ?? 'stable'
    final String trend = (data['trend'] ?? data['status'] ?? 'stable').toString().trim().toLowerCase();

    final double price = parseDouble(rawPrice);
    final double retailPrice = parseDouble(rawRetail);

    return MarketPriceModel(
      id: id,
      district: district,
      marketName: marketName.isNotEmpty ? marketName : 'স্থানীয় বাজার',
      cropName: cropName.isNotEmpty ? cropName : 'ফসল',
      unit: unit.isNotEmpty ? unit : 'কেজি',
      price: price,
      retailPrice: retailPrice,
      priceText: priceText.isNotEmpty ? priceText : '০',
      retailPriceText: retailPriceText.isNotEmpty ? retailPriceText : '০',
      imageUrl: imageUrl,
      trend: trend.isNotEmpty ? trend : 'stable',
      updatedAt: time,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'district': district,
      'market_name': marketName,
      'marketName': marketName,
      'crop_name': cropName,
      'cropName': cropName,
      'unit': unit,
      'price': price,
      'retail_price': retailPrice,
      'retailPrice': retailPrice,
      'image_url': imageUrl,
      'imageUrl': imageUrl,
      'trend': trend,
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }
}
