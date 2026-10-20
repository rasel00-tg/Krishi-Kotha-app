import 'dart:io';
import 'package:flutter/material.dart';
import '../data/models/community_post_model.dart';
import '../data/models/comment_model.dart';
import '../data/services/firestore_service.dart';
import '../data/services/storage_service.dart';

class CommunityProvider extends ChangeNotifier {
  final FirestoreService _firestoreService;
  final StorageService _storageService = StorageService();

  bool _isPosting = false;
  String? _errorMessage;

  CommunityProvider(this._firestoreService);

  bool get isPosting => _isPosting;
  String? get errorMessage => _errorMessage;

  Stream<List<CommunityPostModel>> get postsStream =>
      _firestoreService.getCommunityPostsStream();

  Stream<List<CommentModel>> getCommentsStream(String postId) =>
      _firestoreService.getCommentsStream(postId);

  Future<bool> createPost({
    required String authorId,
    required String authorName,
    required String authorPhone,
    required String content,
    File? imageFile,
  }) async {
    _isPosting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      String? imageUrl;
      if (imageFile != null) {
        imageUrl = await _storageService.uploadImage(
          file: imageFile,
          folder: 'community_photos',
        );
      }

      await _firestoreService.createPost(
        authorId: authorId,
        authorName: authorName,
        authorPhone: authorPhone,
        content: content,
        imageUrl: imageUrl,
      );

      _isPosting = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'পোস্ট প্রকাশ করতে ব্যর্থ হয়েছে';
      _isPosting = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> toggleLike(String postId, String userId) async {
    await _firestoreService.togglePostLike(postId: postId, userId: userId);
  }

  Future<void> addComment({
    required String postId,
    required String authorId,
    required String authorName,
    required String content,
  }) async {
    await _firestoreService.addComment(
      postId: postId,
      authorId: authorId,
      authorName: authorName,
      content: content,
    );
  }
}
