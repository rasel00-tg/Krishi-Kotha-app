import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/crop_model.dart';

class CropPdfService {
  // Safe ASCII & Professional Filename Generator
  static String getSafeFileName(CropModel crop) {
    const nameMap = {
      'ধান': 'Dhan', 'গম': 'Gom', 'ভুট্টা': 'Bhutta', 'আলু': 'Alu',
      'বেগুন': 'Begun', 'টমেটো': 'Tomato', 'মরিচ': 'Morich', 'শসা': 'Shosha',
      'ফুলকপি': 'Fulkopi', 'বাঁধাকপি': 'Bandhakopi', 'লাউ': 'Lau',
      'মিষ্টি কুমড়া': 'Mishti_Kumra', 'মিষ্টি কুমড়া': 'Mishti_Kumra',
      'কুমড়া': 'Kumra', 'কুমড়া': 'Kumra', 'পটল': 'Potol', 'ঝিঙা': 'Jhinga',
      'চিচিঙ্গা': 'Chichinga', 'ঢ্যাঁড়শ': 'Dherosh', 'ঢ্যাঁড়শ': 'Dherosh', 'ঢেঁড়শ': 'Dherosh',
      'করলা': 'Korola', 'উচ্ছে': 'Ucche', 'পেঁয়াজ': 'Peyaj', 'রসুন': 'Roshun',
      'আদা': 'Ada', 'হলুদ': 'Holud', 'সরিষা': 'Shorisha', 'তিল': 'Til',
      'সূর্যমুখী': 'Shurjomukhi', 'চীনাবাদাম': 'Chinabadam', 'চিনাবাদাম': 'Chinabadam',
      'বাদাম': 'Badam', 'মসুর': 'Moshur', 'মুগ': 'Mug', 'ছোলা': 'Chola',
      'আম': 'Aam', 'কাঁঠাল': 'Kathal', 'লিচু': 'Litchi', 'কলা': 'Kola',
      'পেঁপে': 'Pepe', 'পেয়ারা': 'Peyara', 'লেবু': 'Lebu', 'তরমুজ': 'Tormuj',
      'ড্রাগন': 'Dragon', 'স্ট্রবেরি': 'Strawberry', 'চা': 'Cha', 'পাট': 'Paat',
      'তুলা': 'Tula', 'আখ': 'Aakh',
    };

    final rawName = crop.nameBn.trim();
    String engName = '';

    for (final entry in nameMap.entries) {
      if (rawName.contains(entry.key)) {
        engName = entry.value;
        break;
      }
    }

    if (engName.isEmpty) {
      final lettersOnly = rawName.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '');
      if (lettersOnly.length >= 2) engName = lettersOnly;
    }

    if (engName.isEmpty) {
      final cleanId = crop.id.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '');
      engName = cleanId.isNotEmpty ? 'Crop_$cleanId' : 'CropGuide';
    }

    final cleanId = crop.id.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '');
    final idPart = (cleanId.isNotEmpty && !engName.toLowerCase().contains(cleanId.toLowerCase()))
        ? '_${cleanId.length > 8 ? cleanId.substring(0, 8) : cleanId}'
        : '';

    final now = DateTime.now();
    final dateStamp = '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';

    return 'Krishi_Kotha_${engName}${idPart}_$dateStamp.pdf';
  }

  // 1. Bengali TrueType Font Loader with Defensive Multi-Tier Fallback (Tiro Bangla & Hind Siliguri)
  static Future<pw.Font> _loadBanglaFont() async {
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
          return pw.Font.ttf(data);
        }
      } catch (_) {}
    }
    return pw.Font.helvetica();
  }

  static Future<pw.Font> _loadBanglaBoldFont() async {
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
          return pw.Font.ttf(data);
        }
      } catch (_) {}
    }
    return pw.Font.helveticaBold();
  }

  // Official User App Green Sprout Logo Loader
  static Future<Uint8List?> _loadAppLogoBytes() async {
    final paths = [
      'assets/icons/pnglogo.png',
      'assets/icons/appicon.png',
    ];
    for (final p in paths) {
      try {
        final data = await rootBundle.load(p);
        if (data.lengthInBytes > 100) {
          return data.buffer.asUint8List();
        }
      } catch (_) {}
    }
    return null;
  }

  // 2. Defensive Image Bytes Validator (PNG / JPEG magic bytes check)
  static bool _isValidPdfImageBytes(Uint8List bytes) {
    if (bytes.length < 8) return false;
    // JPEG magic bytes: FF D8 FF
    if (bytes[0] == 0xFF && bytes[1] == 0xD8 && bytes[2] == 0xFF) return true;
    // PNG magic bytes: 89 50 4E 47
    if (bytes[0] == 0x89 && bytes[1] == 0x50 && bytes[2] == 0x4E && bytes[3] == 0x47) return true;
    return false;
  }

  // Defensive Async Image Byte Loader (Never crashes layout on network timeout or invalid bytes)
  static Future<Uint8List?> _fetchImageBytes(String url) async {
    if (url.trim().isEmpty) return null;
    try {
      final uri = Uri.tryParse(url.trim());
      if (uri == null || !uri.hasScheme) return null;
      final response = await http.get(uri).timeout(const Duration(seconds: 4));
      if (response.statusCode == 200 && response.bodyBytes.isNotEmpty) {
        if (_isValidPdfImageBytes(response.bodyBytes)) {
          return response.bodyBytes;
        }
      }
    } catch (_) {}
    return null;
  }

  // Bengali Digit Helper
  static String _toBengali(dynamic input) {
    const bnDigits = ['০', '১', '২', '৩', '৪', '৫', '৬', '৭', '৮', '৯'];
    final s = input.toString();
    final buffer = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      final code = s.codeUnitAt(i);
      if (code >= 48 && code <= 57) {
        buffer.write(bnDigits[code - 48]);
      } else {
        buffer.write(s[i]);
      }
    }
    return buffer.toString();
  }

  // 3. Build Full Vector PDF Document with MultiPage Layout
  static Future<Uint8List> buildPdfDocument(CropModel crop) async {
    final pdf = pw.Document();

    final baseFont = await _loadBanglaFont();
    final boldFont = await _loadBanglaBoldFont();
    final logoBytes = await _loadAppLogoBytes();
    final imageBytes = await _fetchImageBytes(crop.imageUrl);

    // Primary Colors
    const primaryGreen = PdfColor.fromInt(0xFF2E7D32);
    const darkGreen = PdfColor.fromInt(0xFF1B5E20);
    const lightBg = PdfColor.fromInt(0xFFF4F8F4);
    const borderGreen = PdfColor.fromInt(0xFFC8E6C9);

    final now = DateTime.now();
    final dateStr = '${_toBengali(now.day)}/${_toBengali(now.month)}/${_toBengali(now.year)}';

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.symmetric(horizontal: 26, vertical: 26),
        theme: pw.ThemeData.withFont(
          base: baseFont,
          bold: boldFont,
        ),
        header: (context) {
          return pw.Container(
            padding: const pw.EdgeInsets.only(bottom: 12),
            margin: const pw.EdgeInsets.only(bottom: 16),
            decoration: const pw.BoxDecoration(
              border: pw.Border(bottom: pw.BorderSide(color: primaryGreen, width: 2.5)),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    if (logoBytes != null) ...[
                      pw.Container(
                        width: 38,
                        height: 38,
                        decoration: pw.BoxDecoration(
                          color: const PdfColor.fromInt(0xFFE8F5E9),
                          borderRadius: pw.BorderRadius.circular(8),
                          border: pw.Border.all(color: borderGreen, width: 1),
                        ),
                        child: pw.ClipRRect(
                          horizontalRadius: 7,
                          verticalRadius: 7,
                          child: pw.Image(
                            pw.MemoryImage(logoBytes),
                            fit: pw.BoxFit.contain,
                          ),
                        ),
                      ),
                      pw.SizedBox(width: 10),
                    ],
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'কৃষি কথা – Krishi Kotha',
                          style: pw.TextStyle(
                            fontSize: 19,
                            fontWeight: pw.FontWeight.bold,
                            color: primaryGreen,
                          ),
                        ),
                        pw.SizedBox(height: 2),
                        pw.Text(
                          'কৃষকের পাশে সবসময় | আধুনিক কৃষি তথ্য ও চাষাবাদ নির্দেশিকা',
                          style: const pw.TextStyle(fontSize: 9.5, color: PdfColors.grey700),
                        ),
                      ],
                    ),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: pw.BoxDecoration(
                        color: primaryGreen,
                        borderRadius: pw.BorderRadius.circular(6),
                      ),
                      child: pw.Text(
                        'অফিশিয়াল গাইড',
                        style: const pw.TextStyle(
                          color: PdfColors.white,
                          fontSize: 9,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ),
                    pw.SizedBox(height: 3),
                    pw.Text(
                      'প্রিন্ট: $dateStr',
                      style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
        footer: (context) {
          return pw.Container(
            padding: const pw.EdgeInsets.only(top: 10),
            margin: const pw.EdgeInsets.only(top: 16),
            decoration: const pw.BoxDecoration(
              border: pw.Border(top: pw.BorderSide(color: primaryGreen, width: 1.5)),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'কৃষি কথা – Krishi Kotha অ্যাপ থেকে সংগৃহীত | কৃষকের ডিজিটাল সহযোগী',
                  style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
                ),
                pw.Text(
                  'জরুরি পরামর্শে: ১৬১২৩',
                  style: pw.TextStyle(
                    fontSize: 9,
                    fontWeight: pw.FontWeight.bold,
                    color: primaryGreen,
                  ),
                ),
              ],
            ),
          );
        },
        build: (context) {
          return [
            // 1. Full-Width Premium Hero Banner Landscape Image (True Aspect Ratio, 180pt, BoxFit.cover)
            pw.Container(
              height: 180,
              width: double.infinity,
              decoration: pw.BoxDecoration(
                color: const PdfColor.fromInt(0xFFE8F5E9),
                borderRadius: pw.BorderRadius.circular(8),
                border: pw.Border.all(color: borderGreen, width: 1.2),
              ),
              child: imageBytes != null
                  ? pw.ClipRRect(
                      horizontalRadius: 7.5,
                      verticalRadius: 7.5,
                      child: pw.FittedBox(
                        fit: pw.BoxFit.cover,
                        child: pw.Image(
                          pw.MemoryImage(imageBytes),
                        ),
                      ),
                    )
                  : pw.Container(
                      width: double.infinity,
                      height: 180,
                      decoration: pw.BoxDecoration(
                        color: const PdfColor.fromInt(0xFFF1F8F1),
                        borderRadius: pw.BorderRadius.circular(7.5),
                      ),
                      child: pw.Center(
                        child: pw.Column(
                          mainAxisAlignment: pw.MainAxisAlignment.center,
                          children: [
                            pw.Container(
                              width: 44,
                              height: 44,
                              decoration: const pw.BoxDecoration(
                                color: primaryGreen,
                                shape: pw.BoxShape.circle,
                              ),
                              child: pw.Center(
                                child: pw.Text(
                                  'কৃ',
                                  style: pw.TextStyle(
                                    color: PdfColors.white,
                                    fontSize: 22,
                                    fontWeight: pw.FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            pw.SizedBox(height: 6),
                            pw.Text(
                              crop.nameBn,
                              style: pw.TextStyle(
                                fontSize: 14,
                                fontWeight: pw.FontWeight.bold,
                                color: darkGreen,
                              ),
                            ),
                            pw.SizedBox(height: 2),
                            pw.Text(
                              'কৃষি কথা – আধুনিক চাষাবাদ নির্দেশিকা',
                              style: const pw.TextStyle(
                                fontSize: 9,
                                color: PdfColors.grey600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
            ),

            pw.SizedBox(height: 12),

            // 2. Crop Title & Metadata Card Section (Below Hero Banner)
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: pw.BoxDecoration(
                color: lightBg,
                borderRadius: pw.BorderRadius.circular(8),
                border: pw.Border.all(color: borderGreen, width: 1),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  // Top Row: Category Badge & Upload/Update Bengali Date
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: [
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: pw.BoxDecoration(
                          color: const PdfColor.fromInt(0xFFE8F5E9),
                          borderRadius: pw.BorderRadius.circular(5),
                          border: pw.Border.all(color: borderGreen, width: 0.8),
                        ),
                        child: pw.Text(
                          crop.category.isNotEmpty ? crop.category : 'সাধারণ ফসল',
                          style: pw.TextStyle(
                            fontSize: 9.5,
                            fontWeight: pw.FontWeight.bold,
                            color: darkGreen,
                          ),
                        ),
                      ),
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                        decoration: pw.BoxDecoration(
                          color: PdfColors.white,
                          borderRadius: pw.BorderRadius.circular(4),
                          border: pw.Border.all(color: const PdfColor.fromInt(0xFFE0E0E0), width: 0.8),
                        ),
                        child: pw.Text(
                          'আপডেট: $dateStr',
                          style: const pw.TextStyle(
                            fontSize: 8.5,
                            color: PdfColors.grey700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  pw.SizedBox(height: 6),

                  // Crop Name & Variety (Large & Bold)
                  pw.Text(
                    crop.nameBn,
                    style: pw.TextStyle(
                      fontSize: 20,
                      fontWeight: pw.FontWeight.bold,
                      color: const PdfColor.fromInt(0xFF1E281F),
                    ),
                  ),
                  pw.SizedBox(height: 2),

                  // Subtitle / Variety features
                  pw.Text(
                    'উন্নত জাত, উৎপাদন প্রযুক্তি ও বিজ্ঞানসম্মত চাষাবাদ নির্দেশিকা',
                    style: const pw.TextStyle(
                      fontSize: 9.5,
                      color: PdfColors.grey700,
                    ),
                  ),
                ],
              ),
            ),

            pw.SizedBox(height: 12),

            // 3-Column Agricultural Metric Table
            pw.Row(
              children: [
                pw.Expanded(
                  child: pw.Container(
                    padding: const pw.EdgeInsets.all(8),
                    decoration: pw.BoxDecoration(
                      color: const PdfColor.fromInt(0xFFFFFDE7),
                      borderRadius: pw.BorderRadius.circular(6),
                      border: pw.Border.all(color: const PdfColor.fromInt(0xFFFFF59D)),
                    ),
                    child: pw.Column(
                      children: [
                        pw.Text(
                          'মৌসুম (Season)',
                          style: const pw.TextStyle(fontSize: 8.5, color: PdfColors.orange900),
                        ),
                        pw.SizedBox(height: 2),
                        pw.Text(
                          crop.season.isNotEmpty ? crop.season : 'উপযুক্ত মৌসুমে',
                          style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
                          textAlign: pw.TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
                pw.SizedBox(width: 8),
                pw.Expanded(
                  child: pw.Container(
                    padding: const pw.EdgeInsets.all(8),
                    decoration: pw.BoxDecoration(
                      color: const PdfColor.fromInt(0xFFEFEBE9),
                      borderRadius: pw.BorderRadius.circular(6),
                      border: pw.Border.all(color: const PdfColor.fromInt(0xFFD7CCC8)),
                    ),
                    child: pw.Column(
                      children: [
                        pw.Text(
                          'মাটির ধরন (Soil)',
                          style: const pw.TextStyle(fontSize: 8.5, color: PdfColors.brown800),
                        ),
                        pw.SizedBox(height: 2),
                        pw.Text(
                          crop.soilType.isNotEmpty ? crop.soilType : 'দোআঁশ মাটি',
                          style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
                          textAlign: pw.TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
                pw.SizedBox(width: 8),
                pw.Expanded(
                  child: pw.Container(
                    padding: const pw.EdgeInsets.all(8),
                    decoration: pw.BoxDecoration(
                      color: const PdfColor.fromInt(0xFFE1F5FE),
                      borderRadius: pw.BorderRadius.circular(6),
                      border: pw.Border.all(color: const PdfColor.fromInt(0xFFB3E5FC)),
                    ),
                    child: pw.Column(
                      children: [
                        pw.Text(
                          'বপন ও রোপণ (Sowing)',
                          style: const pw.TextStyle(fontSize: 8.5, color: PdfColors.blue800),
                        ),
                        pw.SizedBox(height: 2),
                        pw.Text(
                          crop.sowingTime.isNotEmpty ? crop.sowingTime : 'সঠিক সময়ে',
                          style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
                          textAlign: pw.TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            pw.SizedBox(height: 14),

            // Stages Header
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: pw.BoxDecoration(
                color: primaryGreen,
                borderRadius: pw.BorderRadius.circular(6),
              ),
              child: pw.Row(
                children: [
                  pw.Text(
                    'ধাপ ভিত্তিক চাষাবাদ ও পরিচর্যা গাইড',
                    style: pw.TextStyle(
                      color: PdfColors.white,
                      fontSize: 12,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            pw.SizedBox(height: 8),

            // Stages Content List (Wrapped in pw.Column to seamlessly flow across pages)
            if (crop.stages.isNotEmpty)
              ...crop.stages.asMap().entries.map((entry) {
                final idx = entry.key;
                final stage = entry.value;
                return pw.Container(
                  margin: const pw.EdgeInsets.only(bottom: 8),
                  padding: const pw.EdgeInsets.all(10),
                  decoration: pw.BoxDecoration(
                    color: const PdfColor.fromInt(0xFFFAFAFA),
                    borderRadius: pw.BorderRadius.circular(6),
                    border: pw.Border.all(color: const PdfColor.fromInt(0xFFE0E0E0)),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Row(
                        children: [
                          pw.Container(
                            width: 18,
                            height: 18,
                            decoration: const pw.BoxDecoration(
                              color: primaryGreen,
                              shape: pw.BoxShape.circle,
                            ),
                            child: pw.Center(
                              child: pw.Text(
                                _toBengali(idx + 1),
                                style: pw.TextStyle(
                                  color: PdfColors.white,
                                  fontSize: 9,
                                  fontWeight: pw.FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          pw.SizedBox(width: 8),
                          pw.Expanded(
                            child: pw.Text(
                              stage.stageName,
                              style: pw.TextStyle(
                                fontSize: 11.5,
                                fontWeight: pw.FontWeight.bold,
                                color: darkGreen,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (stage.description.isNotEmpty) ...[
                        pw.SizedBox(height: 4),
                        pw.Padding(
                          padding: const pw.EdgeInsets.only(left: 26),
                          child: pw.Text(
                            stage.description,
                            style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey800, lineSpacing: 1.3),
                          ),
                        ),
                      ],
                      if (stage.irrigation.isNotEmpty || stage.fertilizer.isNotEmpty) ...[
                        pw.SizedBox(height: 4),
                        pw.Padding(
                          padding: const pw.EdgeInsets.only(left: 26),
                          child: pw.Row(
                            children: [
                              if (stage.irrigation.isNotEmpty)
                                pw.Expanded(
                                  child: pw.Text(
                                    'সেচ: ${stage.irrigation}',
                                    style: const pw.TextStyle(fontSize: 8.5, color: PdfColors.blue800),
                                  ),
                                ),
                              if (stage.fertilizer.isNotEmpty)
                                pw.Expanded(
                                  child: pw.Text(
                                    'সার: ${stage.fertilizer}',
                                    style: const pw.TextStyle(fontSize: 8.5, color: PdfColors.green900),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              })
            else
              pw.Container(
                padding: const pw.EdgeInsets.all(12),
                child: pw.Text(
                  'উপযুক্ত মৌসুমে নিয়মিত সেচ, সুষম সার ও সতর্কতার সাথে বালাই দমন করুন।',
                  style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
                ),
              ),
          ];
        },
      ),
    );

    return pdf.save();
  }

  // 4. Download / Save Pipeline
  static Future<File> savePdfFile(CropModel crop, Uint8List bytes) async {
    final fileName = getSafeFileName(crop);
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/$fileName');
    await file.writeAsBytes(bytes);
    return file;
  }

  // 5. Native Social Share Pipeline
  static Future<void> sharePdf(CropModel crop, Uint8List bytes) async {
    final fileName = getSafeFileName(crop);
    final tempDir = await getTemporaryDirectory();
    final file = File('${tempDir.path}/$fileName');
    await file.writeAsBytes(bytes);

    await Share.shareXFiles(
      [XFile(file.path, mimeType: 'application/pdf')],
      text: 'কৃষি কথা অ্যাপ থেকে ${crop.nameBn} এর পূর্ণাঙ্গ চাষাবাদ ও পরিচর্যা নির্দেশিকা PDF',
      subject: '${crop.nameBn} চাষাবাদ গাইড',
    );
  }
}
