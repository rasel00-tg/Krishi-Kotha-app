import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'firebase_service.dart';

class StorageService {
  final FirebaseStorage? _storage =
      FirebaseService.isFirebaseInitialized ? FirebaseStorage.instance : null;

  /// Uploads image to Firebase Storage under the specified path
  Future<String?> uploadImage({
    required File file,
    required String folder,
  }) async {
    if (!FirebaseService.isFirebaseInitialized || _storage == null) {
      // In offline/mock mode, return a reliable placeholder agricultural image URL
      return 'https://images.unsplash.com/photo-1592924357228-91a4daadcfea?w=800&auto=format&fit=crop&q=80';
    }

    try {
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${file.path.split('/').last}';
      final ref = _storage.ref().child('$folder/$fileName');
      final uploadTask = await ref.putFile(file);
      final downloadUrl = await uploadTask.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      debugPrint('Error uploading image to storage: $e');
      return null;
    }
  }
}
