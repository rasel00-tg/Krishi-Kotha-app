import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;

/// Secure Cloudflare R2 Upload Service (Zero Hardcoded Secrets)
/// 
/// Follows the Pre-signed URL / Secure Gateway Architecture:
/// - Client apps never hold master Secret Access Key or Access Key ID.
/// - Obtains a short-lived Pre-signed PUT URL from the secure backend or uploads
///   through the authenticated backend gateway.
/// - Master credentials reside strictly in backend environment variables (.env).
class R2StorageService {
  static const String publicDevUrl = 'https://pub-660f3103c4924ba0a9526f4bbc8dd392.r2.dev';
  
  // Default local or deployed gateway endpoint
  static String backendGatewayUrl = 'http://localhost:5000/api';

  /// Uploads binary image bytes securely without client-side secrets.
  /// 
  /// 1. Requests a temporary single-use Pre-signed PUT URL from the backend gateway.
  /// 2. Directly PUTs the binary image bytes to Cloudflare R2 using the signed URL.
  /// 3. Returns the publicly accessible CDN URL.
  static Future<String> uploadImageBytes({
    required Uint8List bytes,
    required String fileName,
    String contentType = 'image/jpeg',
  }) async {
    final cleanName = fileName.replaceAll(RegExp(r'[^a-zA-Z0-9_\.\-]'), '_');
    final uniqueName = 'upload_${DateTime.now().millisecondsSinceEpoch}_$cleanName';

    try {
      // Step 1: Request short-lived Pre-signed URL from secure backend gateway
      final presignUri = Uri.parse('$backendGatewayUrl/get-presigned-url?filename=$uniqueName&contentType=$contentType');
      final presignRes = await http.get(presignUri);

      if (presignRes.statusCode == 200) {
        final data = json.decode(presignRes.body) as Map<String, dynamic>;
        final uploadUrl = data['uploadUrl'] as String?;
        final publicUrl = data['publicUrl'] as String?;

        if (uploadUrl != null && uploadUrl.isNotEmpty) {
          // Step 2: Directly PUT bytes to Cloudflare R2 with temporary authorization
          final putRes = await http.put(
            Uri.parse(uploadUrl),
            headers: {
              'Content-Type': contentType,
            },
            body: bytes,
          );

          if (putRes.statusCode == 200 || putRes.statusCode == 201) {
            return publicUrl ?? '$publicDevUrl/$uniqueName';
          }
        }
      }
    } catch (_) {
      // Fallback to direct backend gateway upload if direct pre-signed PUT is unavailable
    }

    // Fallback: Upload through secure backend gateway proxy
    final uploadUri = Uri.parse('$backendGatewayUrl/upload-r2?filename=$uniqueName');
    final response = await http.post(
      uploadUri,
      headers: {
        'Content-Type': contentType,
        'x-filename': uniqueName,
      },
      body: bytes,
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body) as Map<String, dynamic>;
      final publicUrl = data['publicUrl'] as String?;
      if (publicUrl != null && publicUrl.isNotEmpty) {
        return publicUrl;
      }
      return '$publicDevUrl/$uniqueName';
    } else {
      throw Exception('Secure R2 upload failed [${response.statusCode}]: ${response.body}');
    }
  }
}
