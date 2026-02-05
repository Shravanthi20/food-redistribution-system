// Storage service removed - using text-based verification only
// This file is kept for reference but not used in the no-storage version

class StorageService {
  // Placeholder - no storage operations available

  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  Future<String?> uploadProfileImage({
    required String userId,
    required String imagePath,
  }) async {
    // throw Exception('Storage operations not available in this version');
    return null;
  }

  Future<String?> uploadFoodImage({
    required String donationId,
    required String imagePath,
  }) async {
    // throw Exception('Storage operations not available in this version');
    return null;
  }

  Future<String?> uploadVerificationDocument({
    required String userId,
    required String documentPath,
    required String documentType,
  }) async {
    // throw Exception('Storage operations not available in this version');
    return null;
  }

  Future<void> deleteFile(String path) async {
    // throw Exception('Storage operations not available in this version');
  }
}
