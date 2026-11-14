import 'dart:async';
import 'dart:convert';
import 'dart:html' as html;
import 'dart:typed_data';
import 'package:flutter/foundation.dart';

/// Web Image Compression using HTML5 Canvas & JPEG encoding (70-80% quality, max width 800px)
Future<Uint8List> compressImageBytes(
  Uint8List inputBytes, {
  int maxWidth = 800,
  int quality = 75,
}) async {
  if (inputBytes.isEmpty) return inputBytes;

  final completer = Completer<Uint8List>();

  try {
    final blob = html.Blob([inputBytes]);
    final blobUrl = html.Url.createObjectUrlFromBlob(blob);
    final img = html.ImageElement();

    img.onLoad.listen((_) {
      try {
        int width = img.naturalWidth;
        int height = img.naturalHeight;

        if (width <= 0) width = img.width ?? 800;
        if (height <= 0) height = img.height ?? 600;

        // Downscale to maxWidth 800px keeping aspect ratio
        if (width > maxWidth) {
          height = (height * maxWidth / width).round();
          width = maxWidth;
        }

        final canvas = html.CanvasElement(width: width, height: height);
        final ctx = canvas.context2D;
        ctx.imageSmoothingEnabled = true;
        ctx.imageSmoothingQuality = 'high';
        ctx.drawImageScaled(img, 0, 0, width, height);

        // Quality 70-80% (0.75 default)
        final q = (quality.clamp(10, 100)) / 100.0;
        final dataUrl = canvas.toDataUrl('image/jpeg', q);
        html.Url.revokeObjectUrl(blobUrl);

        final commaIdx = dataUrl.indexOf(',');
        if (commaIdx != -1) {
          final base64Str = dataUrl.substring(commaIdx + 1);
          final compressedBytes = Uint8List.fromList(base64Decode(base64Str));
          completer.complete(compressedBytes);
          return;
        }
        completer.complete(inputBytes);
      } catch (err) {
        debugPrint('[ImageCompressorWeb] Error: $err');
        html.Url.revokeObjectUrl(blobUrl);
        completer.complete(inputBytes);
      }
    });

    img.onError.listen((_) {
      html.Url.revokeObjectUrl(blobUrl);
      completer.complete(inputBytes);
    });

    img.src = blobUrl;
  } catch (e) {
    debugPrint('[ImageCompressorWeb] Exception: $e');
    completer.complete(inputBytes);
  }

  return completer.future;
}
