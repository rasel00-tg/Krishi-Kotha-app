import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:printing/printing.dart';
import '../models/disease_diagnosis_result.dart';
import '../../core/utils/bangla_number_converter.dart';

class PrescriptionPdfService {
  // ১. বাংলা ট্রু-টাইপ ফন্ট লোডার
  static Future<pw.Font> _loadBanglaFont() async {
    final paths = [
      'assets/fonts/TiroBangla-Regular.ttf',
      'assets/fonts/HindSiliguri-Regular.ttf',
      'assets/font/TiroBangla-Regular.ttf',
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
      'assets/fonts/HindSiliguri-Regular.ttf',
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

  // ২. অ্যাপের লোগো লোডার
  static Future<Uint8List?> _loadLogoBytes() async {
    final paths = [
      'assets/icons/pnglogo.png',
      'assets/icons/appicon.png',
      'assets/images/logo.png',
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

  // ৩. মূল প্রেসক্রিপশন পিডিএফ ডকুমেন্টস জেনারেশন
  static Future<pw.Document> generatePrescriptionPdf(DiseaseDiagnosisResult result) async {
    final pdf = pw.Document();
    final banglaFont = await _loadBanglaFont();
    final banglaBoldFont = await _loadBanglaBoldFont();
    final logoBytes = await _loadLogoBytes();

    final logoImage = logoBytes != null ? pw.MemoryImage(logoBytes) : null;

    // ইউজার ছবি থাকলে লোড করা
    pw.MemoryImage? userCropImage;
    if (result.localImagePath != null && result.localImagePath!.isNotEmpty) {
      try {
        final f = File(result.localImagePath!);
        if (f.existsSync()) {
          final b = await f.readAsBytes();
          if (b.isNotEmpty) {
            userCropImage = pw.MemoryImage(b);
          }
        }
      } catch (_) {}
    }

    final primaryColor = PdfColor.fromHex('#2E7D32');
    final secondaryColor = PdfColor.fromHex('#1B5E20');
    final darkText = PdfColor.fromHex('#212121');
    final lightGreenBg = PdfColor.fromHex('#E8F5E9');
    final subtleBorder = PdfColor.fromHex('#C8E6C9');

    final dateFormatted = BanglaNumberConverter.toBangla('${result.createdAt.day}/${result.createdAt.month}/${result.createdAt.year}');

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        theme: pw.ThemeData.withFont(base: banglaFont, bold: banglaBoldFont),
        build: (pw.Context context) => [
          // হেডার ও লোগো সেকশন
          pw.Container(
            padding: const pw.EdgeInsets.only(bottom: 12),
            decoration: pw.BoxDecoration(
              border: pw.Border(bottom: pw.BorderSide(color: primaryColor, width: 2)),
            ),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                if (logoImage != null)
                  pw.Container(
                    width: 48,
                    height: 48,
                    margin: const pw.EdgeInsets.only(right: 12),
                    child: pw.Image(logoImage),
                  ),
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'কৃষি কথা – KrishiMate AI প্রেসক্রিপশন',
                        style: pw.TextStyle(
                          fontSize: 16,
                          fontWeight: pw.FontWeight.bold,
                          color: secondaryColor,
                        ),
                      ),
                      pw.SizedBox(height: 2),
                      pw.Text(
                        'স্মার্ট উদ্ভিদ রোগ বিশেষজ্ঞ ও চিকিৎসা ব্যবস্থাপনা',
                        style: pw.TextStyle(
                          fontSize: 10.5,
                          color: primaryColor,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text(
                      'প্রেসক্রিপশন আইডি: #${result.id.length > 8 ? result.id.substring(result.id.length - 8) : result.id}',
                      style: pw.TextStyle(fontSize: 8.5, color: darkText),
                    ),
                    pw.SizedBox(height: 2),
                    pw.Text(
                      'তারিখ: $dateFormatted',
                      style: pw.TextStyle(fontSize: 8.5, color: darkText),
                    ),
                  ],
                ),
              ],
            ),
          ),

          pw.SizedBox(height: 12),

          // ব্যবহারকারীর প্রশ্ন / লক্ষণ এবং আক্রান্ত পাতার ছবি (যদি থাকে)
          if ((result.userSymptoms != null && result.userSymptoms!.isNotEmpty) || userCropImage != null) ...[
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.all(10),
              margin: const pw.EdgeInsets.only(bottom: 12),
              decoration: pw.BoxDecoration(
                color: lightGreenBg,
                borderRadius: pw.BorderRadius.circular(6),
                border: pw.Border.all(color: subtleBorder, width: 1),
              ),
              child: pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  if (userCropImage != null)
                    pw.Container(
                      width: 52,
                      height: 52,
                      margin: const pw.EdgeInsets.only(right: 10),
                      child: pw.ClipRRect(
                        horizontalRadius: 6,
                        verticalRadius: 6,
                        child: pw.Image(userCropImage, fit: pw.BoxFit.cover),
                      ),
                    ),
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'আপনার প্রশ্ন / লক্ষণ:',
                          style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: secondaryColor),
                        ),
                        pw.SizedBox(height: 3),
                        pw.Text(
                          result.userSymptoms?.isNotEmpty == true
                              ? result.userSymptoms!
                              : 'আক্রান্ত পাতার ছবি সংযুক্ত করে পরামর্শ চাওয়া হয়েছিল।',
                          style: pw.TextStyle(fontSize: 9.5, color: darkText),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],

          // চিহ্নিত রোগ ও ফসলের মূল হাইলাইট কার্ড
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.all(12),
            margin: const pw.EdgeInsets.only(bottom: 12),
            decoration: pw.BoxDecoration(
              color: lightGreenBg,
              borderRadius: pw.BorderRadius.circular(8),
              border: pw.Border.all(color: subtleBorder, width: 1),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'আক্রান্ত ফসল: ${result.plantName}',
                      style: pw.TextStyle(fontSize: 11, color: secondaryColor, fontWeight: pw.FontWeight.bold),
                    ),
                    pw.SizedBox(height: 3),
                    pw.Text(
                      'চিহ্নিত রোগ: ${result.diseaseName}',
                      style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: darkText),
                    ),
                  ],
                ),
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: pw.BoxDecoration(
                    color: primaryColor,
                    borderRadius: pw.BorderRadius.circular(6),
                  ),
                  child: pw.Text(
                    'নির্ভুলতা: ${result.confidence}',
                    style: pw.TextStyle(fontSize: 10.5, color: PdfColors.white, fontWeight: pw.FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),

          // সেকশন ১: কারণ ও দৃশ্যমান লক্ষণসমূহ
          if (result.causesAndSymptoms.isNotEmpty) ...[
            pw.Text(
              '১. রোগের প্রধান কারণ ও লক্ষণসমূহ:',
              style: pw.TextStyle(fontSize: 11.5, fontWeight: pw.FontWeight.bold, color: secondaryColor),
            ),
            pw.SizedBox(height: 4),
            ...result.causesAndSymptoms.map(
              (s) => pw.Padding(
                padding: const pw.EdgeInsets.only(left: 8, bottom: 2),
                child: pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('• ', style: pw.TextStyle(color: primaryColor, fontWeight: pw.FontWeight.bold)),
                    pw.Expanded(
                      child: pw.Text(s, style: pw.TextStyle(fontSize: 9.5, color: darkText)),
                    ),
                  ],
                ),
              ),
            ),
            pw.SizedBox(height: 10),
          ],

          // সেকশন ২: জরুরি প্রতিকার ও চিকিৎসা ব্যবস্থাপনা
          pw.Text(
            '২. জরুরি প্রতিকার ও চিকিৎসা ব্যবস্থাপনা:',
            style: pw.TextStyle(fontSize: 11.5, fontWeight: pw.FontWeight.bold, color: secondaryColor),
          ),
          pw.SizedBox(height: 4),

          // ক. জৈব ও প্রাকৃতিক সমাধান
          if (result.organicCures.isNotEmpty) ...[
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.all(8),
              margin: const pw.EdgeInsets.only(bottom: 8),
              decoration: pw.BoxDecoration(
                color: PdfColor.fromHex('#F1F8E9'),
                borderRadius: pw.BorderRadius.circular(6),
                border: pw.Border.all(color: PdfColor.fromHex('#DCEDC8')),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'ঘরোয়া ও প্রাকৃতিক জৈব প্রতিকার:',
                    style: pw.TextStyle(fontSize: 9.5, fontWeight: pw.FontWeight.bold, color: secondaryColor),
                  ),
                  pw.SizedBox(height: 3),
                  ...result.organicCures.map(
                    (o) => pw.Padding(
                      padding: const pw.EdgeInsets.only(left: 6, bottom: 2),
                      child: pw.Text('✓ $o', style: pw.TextStyle(fontSize: 9, color: darkText)),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // খ. রাসায়নিক সমাধান ও সঠিক ডোজ
          if (result.chemicalCures.isNotEmpty) ...[
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.all(8),
              margin: const pw.EdgeInsets.only(bottom: 8),
              decoration: pw.BoxDecoration(
                color: PdfColor.fromHex('#FFF8E1'),
                borderRadius: pw.BorderRadius.circular(6),
                border: pw.Border.all(color: PdfColor.fromHex('#FFE082')),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'অনুমোদিত রাসায়নিক বালাইনাশক ও সঠিক প্রয়োগমাত্রা (ডোজ):',
                    style: pw.TextStyle(fontSize: 9.5, fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex('#E65100')),
                  ),
                  pw.SizedBox(height: 4),
                  ...result.chemicalCures.map(
                    (c) => pw.Padding(
                      padding: const pw.EdgeInsets.only(left: 6, bottom: 3),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            '• ${c.name} (${c.dosage})',
                            style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: darkText),
                          ),
                          if (c.instruction.isNotEmpty)
                            pw.Padding(
                              padding: const pw.EdgeInsets.only(left: 8),
                              child: pw.Text(c.instruction, style: pw.TextStyle(fontSize: 8.5, color: darkText)),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // সেকশন ৩: ভবিষ্যৎ সুরক্ষায় করণীয়
          if (result.precautionAndCare.isNotEmpty) ...[
            pw.Text(
              '৩. ভবিষ্যৎ সুরক্ষায় করণীয় ও পরিচর্যা টিপস:',
              style: pw.TextStyle(fontSize: 11.5, fontWeight: pw.FontWeight.bold, color: secondaryColor),
            ),
            pw.SizedBox(height: 4),
            ...result.precautionAndCare.map(
              (p) => pw.Padding(
                padding: const pw.EdgeInsets.only(left: 8, bottom: 2),
                child: pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('• ', style: pw.TextStyle(color: primaryColor, fontWeight: pw.FontWeight.bold)),
                    pw.Expanded(
                      child: pw.Text(p, style: pw.TextStyle(fontSize: 9, color: darkText)),
                    ),
                  ],
                ),
              ),
            ),
            pw.SizedBox(height: 8),
          ],

          // ফুটার ও সতর্কবার্তা
          if (result.emergencyWarning != null && result.emergencyWarning!.isNotEmpty) ...[
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 5),
              margin: const pw.EdgeInsets.only(bottom: 8),
              decoration: pw.BoxDecoration(
                color: PdfColor.fromHex('#FFEBEE'),
                borderRadius: pw.BorderRadius.circular(4),
                border: pw.Border.all(color: PdfColor.fromHex('#FFCDD2')),
              ),
              child: pw.Text(
                'সতর্কতা: ${result.emergencyWarning}',
                style: pw.TextStyle(fontSize: 8.5, color: PdfColor.fromHex('#C62828'), fontWeight: pw.FontWeight.bold),
              ),
            ),
          ],

          pw.Container(
            padding: const pw.EdgeInsets.only(top: 8),
            decoration: const pw.BoxDecoration(
              border: pw.Border(top: pw.BorderSide(color: PdfColors.grey300, width: 1)),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'কৃষি কথা – কৃষকের ডিজিটাল প্রযুক্তি সঙ্গী',
                  style: pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
                ),
                pw.Text(
                  'KrishiMate AI অফিশিয়াল পরামর্শ',
                  style: pw.TextStyle(fontSize: 8, color: secondaryColor, fontWeight: pw.FontWeight.bold),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    return pdf;
  }

  // ৪. অফিশিয়াল পিডিএফ ফাইল শেয়ারিং (ক্রিস্প লোডিং ডায়ালগ সহ)
  static Future<void> shareOrDownloadPrescription(
    BuildContext context,
    DiseaseDiagnosisResult result,
  ) async {
    if (result.isNonAgri) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('শুধুমাত্র ফসলের রোগবালাই সংক্রান্ত পরামর্শের জন্য পিডিএফ প্রযোজ্য।'),
          ),
        );
      }
      return;
    }

    // ক্রিস্প লোডিং ইন্ডিকেটর ডায়ালগ
    BuildContext? dialogContext;
    if (context.mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) {
          dialogContext = ctx;
          return PopScope(
            canPop: false,
            child: Dialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    SizedBox(
                      width: 26,
                      height: 26,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2E7D32)),
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        'অফিশিয়াল PDF প্রেসক্রিপশন তৈরি হচ্ছে...',
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1B5E20),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    }

    try {
      final pdf = await generatePrescriptionPdf(result);
      final pdfBytes = await pdf.save();

      // লোডিং ডায়ালগ বন্ধ করা
      if (dialogContext != null && dialogContext!.mounted) {
        Navigator.of(dialogContext!).pop();
        dialogContext = null;
      }

      final cleanCrop = result.plantName.replaceAll(RegExp(r'[^\w\s\u0980-\u09FF]'), '').trim();
      final filename = 'KrishiMate_${cleanCrop.isNotEmpty ? cleanCrop : "Crop"}_Prescription.pdf';

      // ১. Printing.sharePdf (ডিভাইসের নেটিভ শেয়ার শিটে ফাইল শেয়ারিং)
      await Printing.sharePdf(bytes: pdfBytes, filename: filename);
    } catch (e) {
      // লোডিং ডায়ালগ বন্ধ করা
      if (dialogContext != null && dialogContext!.mounted) {
        Navigator.of(dialogContext!).pop();
        dialogContext = null;
      }

      // ২. ব্যাকআপ ডিরেক্টরি সেভ এবং ShareXFiles
      try {
        final pdf = await generatePrescriptionPdf(result);
        final pdfBytes = await pdf.save();
        final tempDir = await getTemporaryDirectory();
        final cleanCrop = result.plantName.replaceAll(RegExp(r'[^\w\s\u0980-\u09FF]'), '').trim();
        final file = File('${tempDir.path}/KrishiMate_${cleanCrop}_${DateTime.now().millisecondsSinceEpoch}.pdf');
        await file.writeAsBytes(pdfBytes);
        await Share.shareXFiles(
          [XFile(file.path, mimeType: 'application/pdf')],
          subject: 'KrishiMate AI প্রেসক্রিপশন - ${result.diseaseName}',
          text: '🌿 কৃষি কথা KrishiMate AI প্রেসক্রিপশন: ${result.plantName} - ${result.diseaseName}',
        );
      } catch (err) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('পিডিএফ শেয়ার করতে সমস্যা হয়েছে: $err')),
          );
        }
      }
    }
  }

  // ৫. সরাসরি প্রিন্ট বা পিডিএফ ভিউয়ার
  static Future<void> printPrescription(BuildContext context, DiseaseDiagnosisResult result) async {
    try {
      final pdf = await generatePrescriptionPdf(result);
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save(),
        name: 'KrishiMate_${result.plantName}_${result.id}',
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('প্রিন্ট করতে সমস্যা হয়েছে: $e')),
        );
      }
    }
  }
}
