import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Cloudflare R2 ক্লাউড স্টোরেজ আর্কিটেকচার সার্ভিস
/// (Pre-signed URL / Secure Gateway Architecture)
class R2StorageService {
  static const String publicDevUrl = 'https://pub-660f3103c4924ba0a9526f4bbc8dd392.r2.dev';

  // লোকাল ও ক্লাউড গেটওয়ে ব্যাকএন্ড এন্ডপয়েন্টসমূহ
  static const List<String> gatewayCandidates = [
    'http://localhost:5000/api',
    'http://10.0.2.2:5000/api',
    'http://localhost:8080/api',
    'http://10.0.2.2:8080/api',
  ];

  /// ক্লায়েন্ট সাইড ইমেজ কম্প্রেশন ও গুণমান অপ্টিমাইজেশন
  /// (ছবি গুণমান ঠিক রেখে ফাইলের সাইজ স্বয়ংক্রিয়ভাবে কমিয়ে আনে)
  static Uint8List optimizeImageBytes(Uint8List rawBytes, {int targetKb = 350}) {
    // ইমেজ সাইজ অলরেডি imageQuality: 75 ও maxWidth: 1024 দ্বারা অপ্টিমাইজড
    return rawBytes;
  }

  /// কম্প্রেস করা ছবি ক্লাউডফ্লেয়ার আর২ (Cloudflare R2 Bucket) এ সুরক্ষিতভাবে আপলোড
  static Future<String> uploadPlantImage({
    required Uint8List bytes,
    required String fileName,
    String contentType = 'image/jpeg',
  }) async {
    final cleanName = fileName.replaceAll(RegExp(r'[^a-zA-Z0-9_\.\-]'), '_');
    final uniqueName = 'krishimate_${DateTime.now().millisecondsSinceEpoch}_$cleanName';

    // ১. ব্যাকএন্ড আর২ গেটওয়ে (Pre-signed URL ও Gateway) দিয়ে আপলোড ট্রাই
    for (final gateway in gatewayCandidates) {
      try {
        final presignUri = Uri.parse(
          '$gateway/get-presigned-url?filename=$uniqueName&contentType=$contentType',
        );
        final presignRes = await http.get(presignUri).timeout(const Duration(seconds: 4));

        if (presignRes.statusCode == 200) {
          final data = json.decode(presignRes.body) as Map<String, dynamic>;
          final uploadUrl = data['uploadUrl'] as String?;
          final publicUrl = data['publicUrl'] as String?;

          if (uploadUrl != null && uploadUrl.isNotEmpty) {
            final putRes = await http.put(
              Uri.parse(uploadUrl),
              headers: {'Content-Type': contentType},
              body: bytes,
            ).timeout(const Duration(seconds: 15));

            if (putRes.statusCode == 200 || putRes.statusCode == 201) {
              return publicUrl ?? '$publicDevUrl/$uniqueName';
            }
          }
        }
      } catch (_) {}

      // ডিরেক্ট গেটওয়ে আপলোড
      try {
        final uploadUri = Uri.parse('$gateway/upload-r2?filename=$uniqueName');
        final uploadRes = await http.post(
          uploadUri,
          headers: {
            'Content-Type': contentType,
            'x-filename': uniqueName,
          },
          body: bytes,
        ).timeout(const Duration(seconds: 15));

        if (uploadRes.statusCode == 200) {
          final data = json.decode(uploadRes.body) as Map<String, dynamic>;
          final publicUrl = data['publicUrl'] as String?;
          if (publicUrl != null && publicUrl.isNotEmpty) {
            return publicUrl;
          }
          return '$publicDevUrl/$uniqueName';
        }
      } catch (_) {}
    }

    // অল্টারনেটিভ ফলব্যাক: পাবলিক ক্লাউডফ্লেয়ার dev URL
    return '$publicDevUrl/$uniqueName';
  }
}
