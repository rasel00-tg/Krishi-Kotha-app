import 'dart:io';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../data/models/support_ticket_model.dart';
import '../data/services/firestore_service.dart';
import '../data/services/storage_service.dart';

class SupportProvider extends ChangeNotifier {
  final FirestoreService _firestoreService;
  final StorageService _storageService = StorageService();

  bool _isSubmitting = false;
  String? _errorMessage;

  SupportProvider(this._firestoreService);

  bool get isSubmitting => _isSubmitting;
  String? get errorMessage => _errorMessage;

  /// Directly dials Bangladesh Agricultural Call Center (16123)
  Future<bool> callAgriCallCenter() async {
    final Uri callUri = Uri(scheme: 'tel', path: '16123');
    try {
      if (await canLaunchUrl(callUri)) {
        await launchUrl(callUri);
        return true;
      }
    } catch (e) {
      debugPrint('Error launching dialer: $e');
    }
    return false;
  }

  Stream<List<SupportTicketModel>> getUserTicketsStream(String userId) {
    return _firestoreService.getSupportTicketsStream(userId);
  }

  Future<bool> submitTicket({
    required String authorId,
    required String authorName,
    required String authorPhone,
    required String district,
    required String upazila,
    required String subject,
    required String details,
    File? imageFile,
  }) async {
    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      String? imageUrl;
      if (imageFile != null) {
        imageUrl = await _storageService.uploadImage(
          file: imageFile,
          folder: 'support_queries',
        );
      }

      await _firestoreService.submitSupportTicket(
        authorId: authorId,
        authorName: authorName,
        authorPhone: authorPhone,
        district: district,
        upazila: upazila,
        subject: subject,
        details: details,
        imageUrl: imageUrl,
      );

      _isSubmitting = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'পরামর্শ অনুরোধ জমা দিতে সমস্যা হয়েছে';
      _isSubmitting = false;
      notifyListeners();
      return false;
    }
  }
}
