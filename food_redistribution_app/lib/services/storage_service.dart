import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:firebase_storage/firebase_storage.dart';

class StorageService {
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<String?> uploadProfileImage({
    required String userId,
    required String imagePath,
  }) async {
    try {
      final file = File(imagePath);
      if (!await file.exists()) return null;

      final ref = _storage.ref().child('profile_images/$userId.jpg');
      final uploadTask = await ref.putFile(
        file,
        SettableMetadata(contentType: 'image/jpeg'),
      );
      return await uploadTask.ref.getDownloadURL();
    } catch (e) {
      debugPrint('Error uploading profile image: $e');
      return null;
    }
  }

  Future<String?> uploadFoodImage({
    required String donationId,
    required String imagePath,
  }) async {
    try {
      final file = File(imagePath);
      if (!await file.exists()) return null;

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final ref =
          _storage.ref().child('food_images/${donationId}_$timestamp.jpg');
      final uploadTask = await ref.putFile(
        file,
        SettableMetadata(contentType: 'image/jpeg'),
      );
      return await uploadTask.ref.getDownloadURL();
    } catch (e) {
      debugPrint('Error uploading food image: $e');
      return null;
    }
  }

  Future<String?> uploadVerificationDocument({
    required String userId,
    required String documentPath,
    required String documentType,
  }) async {
    try {
      final file = File(documentPath);
      if (!await file.exists()) return null;

      final ext = documentPath.split('.').last;
      final ref = _storage.ref().child(
          'verification_docs/$userId/${documentType}_${DateTime.now().millisecondsSinceEpoch}.$ext');
      final uploadTask = await ref.putFile(file);
      return await uploadTask.ref.getDownloadURL();
    } catch (e) {
      debugPrint('Error uploading verification document: $e');
      return null;
    }
  }

  Future<void> deleteFile(String path) async {
    try {
      if (path.isEmpty) return;
      // Handle both paths and full URLs
      if (path.startsWith('http')) {
        final ref = _storage.refFromURL(path);
        await ref.delete();
      } else {
        final ref = _storage.ref().child(path);
        await ref.delete();
      }
    } catch (e) {
      debugPrint('Error deleting file: $e');
    }
  }
}
