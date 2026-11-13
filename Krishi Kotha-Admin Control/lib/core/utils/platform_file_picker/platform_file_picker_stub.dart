import 'dart:typed_data';

/// Represents picked file data in memory (zero disk path dependency)
class PickedAdminFile {
  final String name;
  final Uint8List bytes;
  final int size;

  const PickedAdminFile({
    required this.name,
    required this.bytes,
    required this.size,
  });
}

/// Fallback / Stub implementation for non-web platforms
Future<PickedAdminFile?> pickLocalImageFile() async {
  return null;
}

