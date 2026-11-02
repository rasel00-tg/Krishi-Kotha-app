import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/utils/bangla_number_converter.dart';
import '../../core/utils/date_formatter.dart';
import '../models/market_price_model.dart';

/// সার্ভিস: বাজার দর রিপোর্ট PDF তৈরি ও নেটিভ শেয়ার
class MarketPricePdfService {
  static pw.Font? _cachedRegularFont;
  static pw.Font? _cachedBoldFont;
  static Uint8List? _cachedLogoBytes;

  // ১. বাংলা ফন্ট লোডার (টিরো বাংলা ও হিন্দ শিলিগুড়ি মাল্টি-টিয়ার ফলব্যাক ও ক্যাশিং)
  static Future<pw.Font> _loadBanglaFont() async {
    if (_cachedRegularFont != null) return _cachedRegularFont!;
    final paths = [
      'assets/fonts/TiroBangla-Regular.ttf',
      'assets/font/TiroBangla-Regular.ttf',
      'assets/fonts/HindSiliguri-Regular.ttf',
      'assets/font/HindSiliguri-Regular.ttf',
      'assets/font/Li Ador Noirrit A-V1 Regular.ttf',
    ];

    for (final p in paths) {
      try {
        final data = await rootBundle.load(p);
        if (data.lengthInBytes > 1000) {
          _cachedRegularFont = pw.Font.ttf(data);
          return _cachedRegularFont!;
        }
      } catch (_) {}
    }
    return pw.Font.helvetica();
  }

  static Future<pw.Font> _loadBanglaBoldFont() async {
    if (_cachedBoldFont != null) return _cachedBoldFont!;
    final paths = [
      'assets/fonts/HindSiliguri-Bold.ttf',
      'assets/font/HindSiliguri-Bold.ttf',
      'assets/fonts/TiroBangla-Regular.ttf',
      'assets/font/TiroBangla-Regular.ttf',
      'assets/fonts/HindSiliguri-Regular.ttf',
      'assets/font/HindSiliguri-Regular.ttf',
    ];

    for (final p in paths) {
      try {
        final data = await rootBundle.load(p);
        if (data.lengthInBytes > 1000) {
          _cachedBoldFont = pw.Font.ttf(data);
          return _cachedBoldFont!;
        }
      } catch (_) {}
    }
    return pw.Font.helveticaBold();
  }

  // ২. অ্যাপ লোগো লোডার (assets/icons/pnglogo.png সরাসরি ক্যাশড)
  static Future<Uint8List?> _loadLogoBytes() async {
    if (_cachedLogoBytes != null) return _cachedLogoBytes;
    final logoPaths = [
      'assets/icons/pnglogo.png',
      'assets/icons/appicon.png',
      'assets/icons/pnglogo.png.png',
      'assets/icons/appicon.png.png',
    ];

    for (final path in logoPaths) {
      try {
        final data = await rootBundle.load(path);
        if (data.lengthInBytes > 100) {
          _cachedLogoBytes = data.buffer.asUint8List();
          return _cachedLogoBytes;
        }
      } catch (_) {}
    }
    return null;
  }

  // ৩. নেটওয়ার্ক থেকে ফসলের ছবি ডাউনলোড (টাইমআউট ও এরর ক্যাচিং সহ)
  static Future<Uint8List?> _fetchCropImageBytes(String url) async {
    if (url.trim().isEmpty || !url.startsWith('http')) return null;
    try {
      final res = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 4));
      if (res.statusCode == 200 && res.bodyBytes.lengthInBytes > 200) {
        return res.bodyBytes;
      }
    } catch (e) {
      debugPrint('Crop image fetch failed for PDF: $e');
    }
    return null;
  }

  // ৪. ফাইলনেমের জন্য নিরাপদ নাম তৈরি (${cropName}_bazar_dor.pdf)
  static String _getSafeFileName(String cropName) {
    const Map<String, String> nameMap = {
      'ধান': 'Dhan', 'গম': 'Gom', 'ভুট্টা': 'Bhutta', 'আলু': 'Alu',
      'বেগুন': 'Begun', 'টমেটো': 'Tomato', 'মরিচ': 'Morich', 'শসা': 'Shosha',
      'ফুলকপি': 'Fulkopi', 'বাঁধাকপি': 'Bandhakopi', 'লাউ': 'Lau',
      'মিষ্টি কুমড়া': 'Mishti_Kumra', 'কুমড়া': 'Kumra', 'কুমড়া': 'Kumra',
      'পটল': 'Potol', 'ঝিঙা': 'Jhinga', 'চিচিঙ্গা': 'Chichinga', 'ঢ্যাঁড়শ': 'Dherosh',
      'করলা': 'Korola', 'পেঁয়াজ': 'Peyaj', 'রসুন': 'Roshun', 'আদা': 'Ada',
      'হলুদ': 'Holud', 'সরিষা': 'Shorisha', 'তিল': 'Til', 'আম': 'Aam',
      'কলা': 'Kola', 'পেঁপে': 'Pepe', 'লেবু': 'Lebu', 'তরমুজ': 'Tormuj',
    };

    String name = '';
    for (final e in nameMap.entries) {
      if (cropName.contains(e.key)) {
        name = e.value;
        break;
      }
    }
    if (name.isEmpty) {
      final sanitized = cropName.replaceAll(RegExp(r'[\\/:*?"<>|\s]'), '_').trim();
      name = sanitized.isNotEmpty ? sanitized : 'crop';
    }
    return '${name}_bazar_dor.pdf';
  }

  // ৫. পূর্ণাঙ্গ PDF ডকুমেন্ট তৈরি
  static Future<Uint8List> generatePdf(MarketPriceModel item) async {
    final regularFont = await _loadBanglaFont();
    final boldFont = await _loadBanglaBoldFont();
    final logoBytes = await _loadLogoBytes();
    final cropImageBytes = await _fetchCropImageBytes(item.imageUrl);

    final pdf = pw.Document(
      title: 'কৃষি কথা – ${item.cropName} বাজার দর রিপোর্ট',
      author: 'কৃষি কথা (Krishi Kotha)',
      subject: 'দৈনিক বাজার দর অফিশিয়াল রিপোর্ট',
    );

    final String wholesaleStr = item.price > 0
        ? BanglaNumberConverter.toBangla(item.price % 1 == 0 ? item.price.toInt().toString() : item.price.toString())
        : (item.priceText.isNotEmpty && item.priceText != '0' ? BanglaNumberConverter.toBangla(item.priceText) : '০');

    final String retailStr = item.retailPrice > 0
        ? BanglaNumberConverter.toBangla(item.retailPrice % 1 == 0 ? item.retailPrice.toInt().toString() : item.retailPrice.toString())
        : (item.retailPriceText.isNotEmpty && item.retailPriceText != '0' ? BanglaNumberConverter.toBangla(item.retailPriceText) : '০');

    final String unitText = item.unit.isNotEmpty ? item.unit : 'কেজি';
    final String locationText = item.district.isNotEmpty
        ? '${item.marketName}, ${item.district}'
        : item.marketName;
    final String updateDateText = DateFormatter.formatBangla(item.updatedAt);
    final String printDateText = DateFormatter.formatBangla(DateTime.now());

    String trendText = 'দর স্থিতিশীল রয়েছে';
    PdfColor trendColor = PdfColor.fromHex('#2E7D32');
    if (item.trend == 'up') {
      trendText = 'দর ঊর্ধ্বমুখী (মূল্য বৃদ্ধি)';
      trendColor = PdfColor.fromHex('#C62828');
    } else if (item.trend == 'down') {
      trendText = 'দর নিম্নমুখী (মূল্য হ্রাস)';
      trendColor = PdfColor.fromHex('#1565C0');
    }

    final pw.ThemeData theme = pw.ThemeData.withFont(
      base: regularFont,
      bold: boldFont,
      fontFallback: [boldFont, regularFont],
    );

    // নিরাপদ ক্রপ ইমেজ উইজেট তৈরি (ক্র্যাশ প্রতিরোধ সহ)
    pw.Widget cropImageWidget;
    if (cropImageBytes != null) {
      try {
        cropImageWidget = pw.ClipRRect(
          horizontalRadius: 10,
          verticalRadius: 10,
          child: pw.Image(
            pw.MemoryImage(cropImageBytes),
            fit: pw.BoxFit.cover,
          ),
        );
      } catch (e) {
        cropImageWidget = pw.Center(
          child: pw.Text(
            item.cropName.isNotEmpty ? item.cropName.substring(0, 1) : 'ফ',
            style: pw.TextStyle(
              font: boldFont,
              fontSize: 32,
              color: const PdfColor.fromInt(0xFF2E7D32),
            ),
          ),
        );
      }
    } else {
      cropImageWidget = pw.Center(
        child: pw.Text(
          item.cropName.isNotEmpty ? item.cropName.substring(0, 1) : 'ফ',
          style: pw.TextStyle(
            font: boldFont,
            fontSize: 32,
            color: const PdfColor.fromInt(0xFF2E7D32),
          ),
        ),
      );
    }

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.symmetric(horizontal: 32, vertical: 28),
        theme: theme,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              // ক) টপ হেডার ও অফিশিয়াল ব্র্যান্ডিং
              pw.Container(
                padding: const pw.EdgeInsets.only(bottom: 12),
                decoration: const pw.BoxDecoration(
                  border: pw.Border(
                    bottom: pw.BorderSide(color: PdfColor.fromInt(0xFF2E7D32), width: 2.2),
                  ),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    pw.Row(
                      children: [
                        if (logoBytes != null)
                          pw.Container(
                            width: 48,
                            height: 48,
                            margin: const pw.EdgeInsets.only(right: 12),
                            decoration: pw.BoxDecoration(
                              borderRadius: pw.BorderRadius.circular(8),
                            ),
                            child: pw.Image(pw.MemoryImage(logoBytes)),
                          ),
                        pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(
                              'কৃষি কথা – Krishi Kotha',
                              style: pw.TextStyle(
                                font: boldFont,
                                fontSize: 18,
                                color: const PdfColor.fromInt(0xFF1B5E20),
                              ),
                            ),
                            pw.SizedBox(height: 2),
                            pw.Text(
                              'দৈনিক বাজার দর অফিশিয়াল বুলেটিন ও পরামর্শ',
                              style: pw.TextStyle(
                                font: regularFont,
                                fontSize: 10.5,
                                color: const PdfColor.fromInt(0xFF4A5568),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Container(
                          padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: pw.BoxDecoration(
                            color: const PdfColor.fromInt(0xFFE8F5E9),
                            borderRadius: pw.BorderRadius.circular(6),
                            border: pw.Border.all(color: const PdfColor.fromInt(0xFFA5D6A7)),
                          ),
                          child: pw.Text(
                            'বাজার দর রিপোর্ট',
                            style: pw.TextStyle(
                              font: boldFont,
                              fontSize: 10,
                              color: const PdfColor.fromInt(0xFF1B5E20),
                            ),
                          ),
                        ),
                        pw.SizedBox(height: 3),
                        pw.Text(
                          'রিপোর্ট তৈরির তারিখ: $printDateText',
                          style: pw.TextStyle(
                            font: regularFont,
                            fontSize: 8.5,
                            color: const PdfColor.fromInt(0xFF718096),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 14),

              // খ) ফসলের মূল পরিচিতি ও ছবি হিরো কার্ড
              pw.Container(
                padding: const pw.EdgeInsets.all(14),
                decoration: pw.BoxDecoration(
                  color: const PdfColor.fromInt(0xFFF9FBF9),
                  borderRadius: pw.BorderRadius.circular(12),
                  border: pw.Border.all(color: const PdfColor.fromInt(0xFFE2E8F0)),
                ),
                child: pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    // ফসলের ছবি বা প্লেসহোল্ডার
                    pw.Container(
                      width: 100,
                      height: 100,
                      decoration: pw.BoxDecoration(
                        color: const PdfColor.fromInt(0xFFE8F5E9),
                        borderRadius: pw.BorderRadius.circular(10),
                        border: pw.Border.all(color: const PdfColor.fromInt(0xFFC8E6C9)),
                      ),
                      child: cropImageWidget,
                    ),
                    pw.SizedBox(width: 16),

                    // ফসলের নাম ও অবস্থানগত তথ্য
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            item.cropName,
                            style: pw.TextStyle(
                              font: boldFont,
                              fontSize: 22,
                              color: const PdfColor.fromInt(0xFF1E281F),
                            ),
                          ),
                          pw.SizedBox(height: 4),
                          pw.Row(
                            children: [
                              pw.Text(
                                'বাজার ও জেলা: ',
                                style: pw.TextStyle(
                                  font: boldFont,
                                  fontSize: 11,
                                  color: const PdfColor.fromInt(0xFF2E7D32),
                                ),
                              ),
                              pw.Text(
                                locationText,
                                style: pw.TextStyle(
                                  font: regularFont,
                                  fontSize: 11,
                                  color: const PdfColor.fromInt(0xFF2D3748),
                                ),
                              ),
                            ],
                          ),
                          pw.SizedBox(height: 4),
                          pw.Row(
                            children: [
                              pw.Text(
                                'দর হালনাগাদ: ',
                                style: pw.TextStyle(
                                  font: boldFont,
                                  fontSize: 10,
                                  color: const PdfColor.fromInt(0xFF4A5568),
                                ),
                              ),
                              pw.Text(
                                updateDateText,
                                style: pw.TextStyle(
                                  font: regularFont,
                                  fontSize: 10,
                                  color: const PdfColor.fromInt(0xFF4A5568),
                                ),
                              ),
                            ],
                          ),
                          pw.SizedBox(height: 6),
                          // মার্কেট ট্রেন্ড ইন্ডিকেটর
                          pw.Container(
                            padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: pw.BoxDecoration(
                              color: const PdfColor.fromInt(0xFFF1F5F9),
                              borderRadius: pw.BorderRadius.circular(6),
                              border: pw.Border.all(color: trendColor, width: 0.8),
                            ),
                            child: pw.Text(
                              trendText,
                              style: pw.TextStyle(
                                font: boldFont,
                                fontSize: 9.5,
                                color: trendColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 14),

              // গ) বাজার দর সামারি কার্ড (পাইকারি ও খুচরা দর হাইলাইট)
              pw.Row(
                children: [
                  // পাইকারি দর বক্স
                  pw.Expanded(
                    child: pw.Container(
                      padding: const pw.EdgeInsets.all(12),
                      decoration: pw.BoxDecoration(
                        color: const PdfColor.fromInt(0xFFF0FDF4),
                        borderRadius: pw.BorderRadius.circular(10),
                        border: pw.Border.all(color: const PdfColor.fromInt(0xFF86EFAC), width: 1.2),
                      ),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            'পাইকারি বাজার দর',
                            style: pw.TextStyle(
                              font: boldFont,
                              fontSize: 11,
                              color: const PdfColor.fromInt(0xFF166534),
                            ),
                          ),
                          pw.SizedBox(height: 4),
                          pw.Row(
                            crossAxisAlignment: pw.CrossAxisAlignment.baseline,
                            children: [
                              pw.Text(
                                '৳ $wholesaleStr',
                                style: pw.TextStyle(
                                  font: boldFont,
                                  fontSize: 20,
                                  color: const PdfColor.fromInt(0xFF15803D),
                                ),
                              ),
                              pw.Text(
                                ' / $unitText',
                                style: pw.TextStyle(
                                  font: regularFont,
                                  fontSize: 11,
                                  color: const PdfColor.fromInt(0xFF374151),
                                ),
                              ),
                            ],
                          ),
                          pw.SizedBox(height: 2),
                          pw.Text(
                            'মোকাম ও পাইকারি আড়ত মূল্য',
                            style: pw.TextStyle(
                              font: regularFont,
                              fontSize: 8.5,
                              color: const PdfColor.fromInt(0xFF4B5563),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  pw.SizedBox(width: 12),

                  // খুচরা দর বক্স
                  pw.Expanded(
                    child: pw.Container(
                      padding: const pw.EdgeInsets.all(12),
                      decoration: pw.BoxDecoration(
                        color: const PdfColor.fromInt(0xFFF8FAFC),
                        borderRadius: pw.BorderRadius.circular(10),
                        border: pw.Border.all(color: const PdfColor.fromInt(0xFFCBD5E1), width: 1.2),
                      ),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            'খুচরা বাজার দর',
                            style: pw.TextStyle(
                              font: boldFont,
                              fontSize: 11,
                              color: const PdfColor.fromInt(0xFF334155),
                            ),
                          ),
                          pw.SizedBox(height: 4),
                          pw.Row(
                            crossAxisAlignment: pw.CrossAxisAlignment.baseline,
                            children: [
                              pw.Text(
                                retailStr != '০' ? '৳ $retailStr' : 'বাজারভেদে প্রযোজ্য',
                                style: pw.TextStyle(
                                  font: boldFont,
                                  fontSize: retailStr != '০' ? 20 : 13,
                                  color: const PdfColor.fromInt(0xFF1E293B),
                                ),
                              ),
                              if (retailStr != '০')
                                pw.Text(
                                  ' / $unitText',
                                  style: pw.TextStyle(
                                    font: regularFont,
                                    fontSize: 11,
                                    color: const PdfColor.fromInt(0xFF374151),
                                  ),
                                ),
                            ],
                          ),
                          pw.SizedBox(height: 2),
                          pw.Text(
                            'স্থানীয় খুচরা বাজার আনুমানিক দর',
                            style: pw.TextStyle(
                              font: regularFont,
                              fontSize: 8.5,
                              color: const PdfColor.fromInt(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 14),

              // ঘ) বিস্তারিত বাজার বিবরণ টেবিল
              pw.Container(
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: const PdfColor.fromInt(0xFFE2E8F0)),
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Table(
                  border: pw.TableBorder.symmetric(
                    inside: const pw.BorderSide(color: PdfColor.fromInt(0xFFE2E8F0), width: 0.8),
                  ),
                  children: [
                    _buildTableRow('পণ্যের নাম (Crop)', item.cropName, 'পরিমাপের একক', unitText, boldFont, regularFont),
                    _buildTableRow('পাইকারি বাজার', item.marketName, 'জেলা / অঞ্চল', item.district.isNotEmpty ? item.district : 'সারাদেশ', boldFont, regularFont),
                    _buildTableRow('বাজার দর ট্রেন্ড', trendText, 'তথ্য আপডেট', updateDateText, boldFont, regularFont),
                  ],
                ),
              ),
              pw.SizedBox(height: 14),

              // ঙ) বাজার দর বিশ্লেষণ ও কৃষকের জন্য বাস্তব পরামর্শ
              pw.Container(
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  color: const PdfColor.fromInt(0xFFFFFBEB),
                  borderRadius: pw.BorderRadius.circular(10),
                  border: pw.Border.all(color: const PdfColor.fromInt(0xFFFDE68A)),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'কৃষক ও ব্যবসায়ীদের জন্য বাজার বিশ্লেষণ ও পরামর্শ:',
                      style: pw.TextStyle(
                        font: boldFont,
                        fontSize: 11,
                        color: const PdfColor.fromInt(0xFF92400E),
                      ),
                    ),
                    pw.SizedBox(height: 6),
                    _buildBulletPoint('ফসল সংগ্রহের পর সঠিকভাবে গ্রেডিং ও বাছাই করুন; ভালো মানের ফসলে সর্বোচ্চ পাইকারি দর পাওয়া যায়।', regularFont),
                    _buildBulletPoint('দূরবর্তী বাজারে পাঠানোর পূর্বে আবহাওয়া ও পরিবহন ভাড়া যাচাই করে লাভজনক আড়ত নির্বাচন করুন।', regularFont),
                    _buildBulletPoint('পচনশীল ফসলের ক্ষেত্রে সঠিক বায়ু চলাচলযুক্ত প্যাকেজিং ব্যবহার করে ক্ষতি কমান।', regularFont),
                    _buildBulletPoint('সরাসরি পাইকারদের সঙ্গে যোগাযোগ করে মধ্যস্বত্বভোগীদের অতিরিক্ত কমিশন পরিহার করার চেষ্টা করুন।', regularFont),
                  ],
                ),
              ),

              pw.Spacer(),

              // চ) অফিসিয়াল ভেরিফিকেশন ফুটার ও ডিসক্লেইমার
              pw.Container(
                padding: const pw.EdgeInsets.only(top: 8),
                decoration: const pw.BoxDecoration(
                  border: pw.Border(
                    top: pw.BorderSide(color: PdfColor.fromInt(0xFFE2E8F0), width: 1.2),
                  ),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'তথ্যসূত্র: কৃষি কথা কেন্দ্রীয় বাজার পর্যবেক্ষণ ও স্থানীয় কৃষিবাজার',
                          style: pw.TextStyle(font: regularFont, fontSize: 8, color: const PdfColor.fromInt(0xFF64748B)),
                        ),
                        pw.SizedBox(height: 1),
                        pw.Text(
                          'সতর্কতা: পরিবহন খরচ, আবহাওয়া ও পণ্যের গুণমানের ওপর ভিত্তি করে দর কিছুটা পরিবর্তিত হতে পারে।',
                          style: pw.TextStyle(font: regularFont, fontSize: 7.5, color: const PdfColor.fromInt(0xFF94A3B8)),
                        ),
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text(
                          'কৃষি কথা – কৃষকের ডিজিটাল সহায়তাকারী',
                          style: pw.TextStyle(font: boldFont, fontSize: 9, color: const PdfColor.fromInt(0xFF1B5E20)),
                        ),
                        pw.Text(
                          'সবুজ বিপ্লবের বিশ্বস্ত সঙ্গী',
                          style: pw.TextStyle(font: regularFont, fontSize: 7.5, color: const PdfColor.fromInt(0xFF64748B)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  static pw.TableRow _buildTableRow(
    String label1,
    String val1,
    String label2,
    String val2,
    pw.Font boldFont,
    pw.Font regularFont,
  ) {
    return pw.TableRow(
      children: [
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: pw.Row(
            children: [
              pw.Text('$label1: ', style: pw.TextStyle(font: boldFont, fontSize: 9, color: const PdfColor.fromInt(0xFF475569))),
              pw.Expanded(child: pw.Text(val1, style: pw.TextStyle(font: regularFont, fontSize: 9, color: const PdfColor.fromInt(0xFF0F172A)))),
            ],
          ),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: pw.Row(
            children: [
              pw.Text('$label2: ', style: pw.TextStyle(font: boldFont, fontSize: 9, color: const PdfColor.fromInt(0xFF475569))),
              pw.Expanded(child: pw.Text(val2, style: pw.TextStyle(font: regularFont, fontSize: 9, color: const PdfColor.fromInt(0xFF0F172A)))),
            ],
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildBulletPoint(String text, pw.Font font) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 3),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('• ', style: pw.TextStyle(font: font, fontSize: 9, color: const PdfColor.fromInt(0xFF92400E))),
          pw.Expanded(
            child: pw.Text(
              text,
              style: pw.TextStyle(font: font, fontSize: 8.5, color: const PdfColor.fromInt(0xFF451A03), height: 1.25),
            ),
          ),
        ],
      ),
    );
  }

  /// ৬. PDF তৈরি ও ডিভাইসের নেটিভ শেয়ার শিট ওপেন (ক্র্যাশ-প্রুফ টেক্সট ফলব্যাক সহ)
  static Future<void> shareMarketPricePdf(BuildContext context, MarketPriceModel item) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    scaffoldMessenger.hideCurrentSnackBar();
    scaffoldMessenger.showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
            ),
            const SizedBox(width: 12),
            Text(
              '${item.cropName} এর বাজার দর রিপোর্ট তৈরি হচ্ছে...',
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF1B5E20),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );

    try {
      final Uint8List pdfBytes = await generatePdf(item);
      final String fileName = _getSafeFileName(item.cropName);

      scaffoldMessenger.hideCurrentSnackBar();

      // ওয়েব ও অ্যান্ড্রয়েড উভয় প্ল্যাটফর্মে ক্র্যাশ-প্রুফ PDF শেয়ারিং
      try {
        await Printing.sharePdf(
          bytes: pdfBytes,
          filename: fileName,
          subject: 'কৃষি কথা – ${item.cropName} বাজার দর রিপোর্ট',
        );
      } catch (printingErr) {
        debugPrint('Printing.sharePdf failed, falling back to Share.shareXFiles: $printingErr');
        if (!kIsWeb) {
          final tempDir = await getTemporaryDirectory();
          final file = File('${tempDir.path}/$fileName');
          await file.writeAsBytes(pdfBytes, flush: true);
          await Share.shareXFiles(
            [XFile(file.path, mimeType: 'application/pdf', name: fileName)],
            subject: 'কৃষি কথা – ${item.cropName} বাজার দর রিপোর্ট',
            text: 'কৃষি কথা অ্যাপ থেকে ${item.cropName} এর অফিশিয়াল বাজার দর রিপোর্ট।',
          );
        } else {
          // ওয়েবে প্রিন্টিং শেয়ার ব্যর্থ হলে সমৃদ্ধ টেক্সট ফলব্যাকে সুইচ করা
          await shareFallbackText(item);
        }
      }
    } catch (e) {
      debugPrint('PDF generation failed: $e. Falling back to rich text share immediately.');
      scaffoldMessenger.hideCurrentSnackBar();
      // ফন্ট লোডিং বা PDF তৈরিতে কোনো সমস্যা হলে তাৎক্ষণিক সমৃদ্ধ টেক্সট দিয়ে শেয়ার শিট ওপেন
      await shareFallbackText(item);
    }
  }

  /// ৭. সমৃদ্ধ ও পরিচ্ছন্ন টেক্সট ফরম্যাট শেয়ার ফলব্যাক (বাটন যেন কখনো হ্যাং না করে)
  static Future<void> shareFallbackText(MarketPriceModel item) async {
    final String cleanPrice = item.price > 0
        ? (item.price % 1 == 0 ? item.price.toInt().toString() : item.price.toString())
        : (item.priceText.isNotEmpty && item.priceText != '0' ? item.priceText : '০');
    final String cleanRetail = item.retailPrice > 0
        ? (item.retailPrice % 1 == 0 ? item.retailPrice.toInt().toString() : item.retailPrice.toString())
        : (item.retailPriceText.isNotEmpty && item.retailPriceText != '0' ? item.retailPriceText : '০');
    final String unit = item.unit.isNotEmpty ? item.unit : 'কেজি';
    final String location = item.district.isNotEmpty ? '${item.marketName}, ${item.district}' : item.marketName;
    final String date = DateFormatter.formatBangla(item.updatedAt);

    final String retailInfo = (cleanRetail.isNotEmpty && cleanRetail != '০')
        ? '🛍️ খুচরা দর: ৳${BanglaNumberConverter.toBangla(cleanRetail)} / $unit\n'
        : '';

    String trendStr = 'দর স্থিতিশীল';
    if (item.trend == 'up') {
      trendStr = 'দর ঊর্ধ্বমুখী 📈';
    } else if (item.trend == 'down') {
      trendStr = 'দর নিম্নমুখী 📉';
    }

    final String shareText = '''
[কৃষি কথা – বাজার দর বুলেটিন]
🌱 ফসল: ${item.cropName}
💰 পাইকারি দর: ৳${BanglaNumberConverter.toBangla(cleanPrice)} / $unit
${retailInfo}📍 বাজার ও জেলা: $location
📊 বাজার অবস্থা: $trendStr
📅 সর্বশেষ আপডেট: $date

💡 কৃষকের জন্য পরামর্শ:
• ফসল বাজারে নেওয়ার আগে আড়তের বর্তমান দর ও চাহিদা যাচাই করুন।
• উপযুক্ত গ্রেডিং ও বাছাইকরণ করলে সর্বোচ্চ পাইকারি দর নিশ্চিত হয়।

কৃষি কথা – কৃষকের ডিজিটাল সহায়তাকারী
'''.trim();

    try {
      await Share.share(
        shareText,
        subject: 'কৃষি কথা – ${item.cropName} বাজার দর রিপোর্ট',
      );
    } catch (e) {
      debugPrint('Fallback text share error: $e');
    }
  }
}

