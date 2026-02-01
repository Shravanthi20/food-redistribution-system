// Storage service removed - using text-based verification only
// This file is kept for reference but not used in the no-storage version

class StorageService {
  // Placeholder - no storage operations available
  
  Future<String?> uploadProfileImage({
    required String userId,
    required String imagePath,
  }) async {
    throw Exception('Storage operations not available in this version');
  }
  
  Future<String?> uploadFoodImage({
    required String donationId,
    required String imagePath,
  }) async {
    throw Exception('Storage operations not available in this version');
  }
  
  Future<String?> uploadVerificationDocument({
    required String userId,
    required String documentPath,
    required String documentType,
  }) async {
    throw Exception('Storage operations not available in this version');
  }
  
  Future<void> deleteFile(String path) async {
    throw Exception('Storage operations not available in this version');
  }
}
    required XFile imageFile,
  }) async {
    try {
      final file = File(imageFile.path);
      final ref = _storage.ref().child('profile_images/$userId.jpg');
      
      final uploadTask = ref.putFile(file);
      final snapshot = await uploadTask;
      
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      print('Error uploading profile image: $e');
      return null;
    }
  }

  // Upload donation image
  Future<String?> uploadDonationImage({
    required String donationId,
    required XFile imageFile,
    required int index,
  }) async {
    try {
      final file = File(imageFile.path);
      final ref = _storage.ref().child('donation_images/$donationId/image_$index.jpg');
      
      final uploadTask = ref.putFile(file);
      final snapshot = await uploadTask;
      
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      print('Error uploading donation image: $e');
      return null;
    }
  }

  // Upload verification document
  Future<String?> uploadVerificationDocument({
    required String userId,
    required XFile documentFile,
    required String documentType,
  }) async {
    try {
      final file = File(documentFile.path);
      final fileName = '${documentType}_${DateTime.now().millisecondsSinceEpoch}';
      final ref = _storage.ref().child('verification_documents/$userId/$fileName');
      
      final uploadTask = ref.putFile(file);
      final snapshot = await uploadTask;
      
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      print('Error uploading verification document: $e');
      return null;
    }
  }

  // Delete file
  Future<bool> deleteFile(String downloadUrl) async {
    try {
      final ref = _storage.refFromURL(downloadUrl);
      await ref.delete();
      return true;
    } catch (e) {
      print('Error deleting file: $e');
      return false;
    }
  }

  // Get download URL
  Future<String?> getDownloadUrl(String path) async {
    try {
      final ref = _storage.ref().child(path);
      return await ref.getDownloadURL();
    } catch (e) {
      print('Error getting download URL: $e');
      return null;
    }
  }
}