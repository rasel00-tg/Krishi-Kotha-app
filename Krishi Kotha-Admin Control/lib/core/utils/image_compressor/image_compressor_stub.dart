import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';

/// Non-web / Mobile / Desktop Image Compression using Flutter native ui engine
Future<Uint8List> compressImageBytes(
  Uint8List inputBytes, {
  int maxWidth = 800,
  int quality = 75,
}) async {
  if (inputBytes.isEmpty) return inputBytes;

  try {
    // Decode image downscaled to maxWidth preserving aspect ratio
    final codec = await ui.instantiateImageCodec(
      inputBytes,
      targetWidth: maxWidth,
    );
    final frame = await codec.getNextFrame();
    final image = frame.image;

    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    if (byteData != null) {
      final compressed = byteData.buffer.asUint8List();
      if (compressed.lengthInBytes < inputBytes.lengthInBytes) {
        return compressed;
      }
    }
  } catch (e) {
    debugPrint('[ImageCompressorStub] Compression fallback: $e');
  }
  return inputBytes;
}
