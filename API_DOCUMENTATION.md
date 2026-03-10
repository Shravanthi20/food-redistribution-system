# 📡 API Documentation

## Service Architecture Overview

The Food Redistribution Platform uses a microservices architecture with Firebase as the backend infrastructure. This document outlines the API structure, service contracts, and integration patterns.

## 🔐 Authentication Service

### Firebase Authentication Integration
```dart
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  // User registration with email
  Future<UserCredential> registerWithEmail(String email, String password);
  
  // Social authentication
  Future<UserCredential> signInWithGoogle();
  Future<UserCredential> signInWithFacebook();
  Future<UserCredential> signInWithApple();
  
  // Phone authentication
  Future<void> verifyPhoneNumber(String phoneNumber);
  Future<UserCredential> signInWithPhoneNumber(String verificationId, String smsCode);
  
  // Password management
  Future<void> sendPasswordResetEmail(String email);
  Future<void> updatePassword(String newPassword);
  
  // Session management
  Future<void> signOut();
  Stream<User?> get authStateChanges;
  User? get currentUser;
}
```

### Authentication Flow
1. **Registration**: Email/phone + password or social login
2. **Verification**: Email/SMS verification required
3. **Profile Setup**: Complete user profile with role selection
4. **Session**: JWT token management with auto-refresh

## 👤 User Management Service

### Core User Operations
```dart
class UserService {
  final FirestoreService _db = FirestoreService();
  final StorageService _storage = StorageService();
  
  // Profile management
  Future<AppUser> createUserProfile(AppUser user);
  Future<AppUser> getUserProfile(String userId);
  Future<AppUser> updateUserProfile(String userId, Map<String, dynamic> updates);
  Future<void> deleteUserAccount(String userId);
  
  // Role management
  Future<void> updateUserRole(String userId, UserRole newRole);
  Future<List<String>> getUserPermissions(String userId);
  
  // Location services
  Future<void> updateUserLocation(String userId, Location location);
  Future<List<AppUser>> getUsersNearby(Location center, double radiusKm);
  
  // Profile media
  Future<String> uploadProfileImage(String userId, File imageFile);
  Future<void> deleteProfileImage(String userId);
}
```

### User Data Model
```dart
class AppUser {
  final String id;
  final String email;
  final String? phoneNumber;
  final String displayName;
  final String? photoURL;
  final UserRole role;
  final Location? location;
  final UserProfile profile;
  final DateTime createdAt;
  final DateTime lastLoginAt;
  final bool isActive;
  final Map<String, dynamic> preferences;
  
  // Specialized profile data based on role
  final DonorProfile? donorProfile;
  final NGOProfile? ngoProfile;
  final VolunteerProfile? volunteerProfile;
  final CoordinatorProfile? coordinatorProfile;
}
```

## 🍽️ Food Donation Service

### Donation Management
```dart
class DonationService {
  final FirestoreService _db = FirestoreService();
  final NotificationService _notifications = NotificationService();
  final AIMatchingService _matching = AIMatchingService();
  
  // Create and manage donations
  Future<FoodDonation> createDonation(CreateDonationRequest request);
  Future<FoodDonation> updateDonation(String donationId, Map<String, dynamic> updates);
  Future<void> cancelDonation(String donationId, String reason);
  Future<List<FoodDonation>> getDonationsByUser(String userId, {DonationStatus? status});
  
  // Search and filtering
  Future<List<FoodDonation>> searchDonations(DonationSearchCriteria criteria);
  Future<List<FoodDonation>> getDonationsNearby(Location location, double radiusKm);
  Future<List<FoodDonation>> getUrgentDonations();
  
  // Claiming process
  Future<void> claimDonation(String donationId, String claimedById);
  Future<void> unclaimDonation(String donationId);
  Future<void> completeDonation(String donationId, CompletionDetails details);
  
  // AI-powered matching
  Future<List<FoodDonation>> getRecommendedDonations(String userId);
  Future<List<AppUser>> getMatchedRecipients(String donationId);
}
```

### Donation Data Model
```dart
class FoodDonation {
  final String id;
  final String donorId;
  final String title;
  final String description;
  final List<FoodItem> items;
  final Location pickupLocation;
  final DateTime availableFrom;
  final DateTime availableUntil;
  final DonationStatus status;
  final String? claimedBy;
  final DateTime? claimedAt;
  final List<String> imageUrls;
  final FoodSafetyInfo safetyInfo;
  final ContactInfo contactInfo;
  final DeliveryOptions deliveryOptions;
  final Map<String, dynamic> metadata;
}

class FoodItem {
  final String name;
  final FoodCategory category;
  final int quantity;
  final String unit;
  final DateTime? expiryDate;
  final FoodCondition condition;
  final bool requiresRefrigeration;
  final List<String> allergens;
  final String? nutritionalInfo;
}
```

## 🏢 NGO Management Service

### NGO Operations
```dart
class NGOService {
  final FirestoreService _db = FirestoreService();
  final VerificationService _verification = VerificationService();
  
  // Registration and verification
  Future<NGOProfile> registerNGO(NGORegistrationRequest request);
  Future<void> submitVerificationDocuments(String ngoId, List<File> documents);
  Future<VerificationStatus> getVerificationStatus(String ngoId);
  
  // Program management
  Future<FoodProgram> createProgram(CreateProgramRequest request);
  Future<List<FoodProgram>> getProgramsByNGO(String ngoId);
  Future<void> updateProgram(String programId, Map<String, dynamic> updates);
  
  // Impact tracking
  Future<NGOImpactReport> getImpactReport(String ngoId, DateRange period);
  Future<void> recordBeneficiaryServed(String programId, BeneficiaryRecord record);
  
  // Distribution management
  Future<DistributionEvent> scheduleDistribution(ScheduleDistributionRequest request);
  Future<List<DistributionEvent>> getUpcomingDistributions(String ngoId);
}
```

## 🙋‍♀️ Volunteer Service

### Volunteer Management
```dart
class VolunteerService {
  final FirestoreService _db = FirestoreService();
  final BackgroundCheckService _backgroundCheck = BackgroundCheckService();
  final SkillsAssessmentService _skillsAssessment = SkillsAssessmentService();
  
  // Volunteer onboarding
  Future<VolunteerProfile> createVolunteerProfile(VolunteerRegistrationRequest request);
  Future<void> submitBackgroundCheck(String volunteerId);
  Future<void> completeSkillsAssessment(String volunteerId, SkillsAssessment assessment);
  
  // Opportunity management
  Future<List<VolunteerOpportunity>> getAvailableOpportunities(String volunteerId);
  Future<void> applyForOpportunity(String volunteerId, String opportunityId);
  Future<void> acceptOpportunity(String volunteerId, String opportunityId);
  
  // Activity tracking
  Future<void> recordVolunteerHours(String volunteerId, VolunteerActivity activity);
  Future<VolunteerStats> getVolunteerStats(String volunteerId);
  Future<List<VolunteerActivity>> getVolunteerHistory(String volunteerId);
  
  // Recognition and rewards
  Future<List<VolunteerAchievement>> getVolunteerAchievements(String volunteerId);
  Future<void> awardAchievement(String volunteerId, String achievementId);
}
```

## 🚚 Logistics and Routing Service

### Route Optimization
```dart
class LogisticsService {
  final GoogleMapsService _maps = GoogleMapsService();
  final OptimizationEngine _optimizer = OptimizationEngine();
  
  // Route planning
  Future<OptimizedRoute> planPickupRoute(List<String> donationIds);
  Future<OptimizedRoute> planDeliveryRoute(List<String> destinationIds);
  Future<RouteEstimate> estimateDeliveryTime(Location from, Location to);
  
  // Vehicle management
  Future<List<Vehicle>> getAvailableVehicles(Location area);
  Future<void> assignVehicle(String routeId, String vehicleId);
  Future<VehicleStatus> getVehicleStatus(String vehicleId);
  
  // Real-time tracking
  Future<void> startRouteTracking(String routeId);
  Stream<LocationUpdate> trackRoute(String routeId);
  Future<void> updateDriverLocation(String routeId, Location currentLocation);
  
  // Delivery management
  Future<void> markPickupComplete(String donationId, PickupConfirmation confirmation);
  Future<void> markDeliveryComplete(String deliveryId, DeliveryConfirmation confirmation);
}
```

## 🧠 AI and Analytics Service

### Machine Learning Integration
```dart
class AIService {
  final MLModelService _models = MLModelService();
  final AnalyticsService _analytics = AnalyticsService();
  
  // Demand prediction
  Future<DemandForecast> predictFoodDemand(Location area, DateTime period);
  Future<List<FoodCategory>> predictNeededCategories(String ngoId);
  
  // Matching algorithms
  Future<List<MatchSuggestion>> findOptimalMatches(String donationId);
  Future<double> calculateMatchScore(String donationId, String recipientId);
  
  // Route optimization
  Future<OptimizedRoute> optimizeMultiStopRoute(List<Location> stops);
  Future<double> estimateDeliveryTime(RouteSegment segment);
  
  // Impact analysis
  Future<ImpactReport> generateImpactAnalysis(String organizationId, DateRange period);
  Future<List<Recommendation>> getOptimizationRecommendations(String organizationId);
  
  // Fraud detection
  Future<RiskScore> assessDonationRisk(String donationId);
  Future<List<AnomalyAlert>> detectAnomalies(String organizationId);
}
```

## 📊 Analytics and Reporting Service

### Data Analytics
```dart
class AnalyticsService {
  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;
  final BigQueryService _bigQuery = BigQueryService();
  
  // Event tracking
  Future<void> trackEvent(String eventName, Map<String, dynamic> parameters);
  Future<void> setUserProperty(String propertyName, String value);
  
  // Performance metrics
  Future<PerformanceReport> getSystemPerformance(DateRange period);
  Future<UserEngagementReport> getUserEngagement(DateRange period);
  Future<DonationMetrics> getDonationMetrics(DateRange period);
  
  // Business intelligence
  Future<List<Insight>> generateBusinessInsights(String organizationId);
  Future<TrendAnalysis> analyzeTrends(String metricType, DateRange period);
  
  // Custom reporting
  Future<CustomReport> generateCustomReport(ReportConfiguration config);
  Future<void> scheduleReport(String reportId, ReportSchedule schedule);
}
```

## 📱 Notification Service

### Multi-Channel Notifications
```dart
class NotificationService {
  final FCMService _fcm = FCMService();
  final SMSService _sms = SMSService();
  final EmailService _email = EmailService();
  
  // Push notifications
  Future<void> sendPushNotification(String userId, PushNotification notification);
  Future<void> sendBulkNotification(List<String> userIds, PushNotification notification);
  
  // Email notifications
  Future<void> sendEmailNotification(String userId, EmailNotification notification);
  Future<void> sendWelcomeEmail(String userId);
  
  // SMS notifications
  Future<void> sendSMSNotification(String phoneNumber, SMSNotification notification);
  Future<void> sendVerificationSMS(String phoneNumber, String code);
  
  // Notification preferences
  Future<NotificationPreferences> getNotificationPreferences(String userId);
  Future<void> updateNotificationPreferences(String userId, NotificationPreferences preferences);
  
  // Scheduled notifications
  Future<void> scheduleNotification(ScheduledNotification notification);
  Future<void> cancelScheduledNotification(String notificationId);
}
```

## 💾 Data Storage Service

### Firestore Operations
```dart
class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  
  // Document operations
  Future<DocumentSnapshot> getDocument(String collection, String documentId);
  Future<void> setDocument(String collection, String documentId, Map<String, dynamic> data);
  Future<void> updateDocument(String collection, String documentId, Map<String, dynamic> data);
  Future<void> deleteDocument(String collection, String documentId);
  
  // Query operations
  Future<QuerySnapshot> queryCollection(String collection, List<QueryFilter> filters);
  Stream<QuerySnapshot> streamCollection(String collection);
  Future<List<T>> queryWithPagination<T>(String collection, PaginationConfig config);
  
  // Batch operations
  Future<void> batchWrite(List<WriteOperation> operations);
  Future<void> transaction(Function(Transaction) transactionHandler);
  
  // Real-time subscriptions
  Stream<DocumentSnapshot> streamDocument(String collection, String documentId);
  StreamSubscription<QuerySnapshot> subscribeToQuery(String collection, List<QueryFilter> filters);
}
```

## ☁️ File Storage Service

### Cloud Storage Operations
```dart
class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImageCompressionService _compression = ImageCompressionService();
  
  // File upload
  Future<String> uploadFile(String path, File file, {UploadOptions? options});
  Future<String> uploadImage(String path, File imageFile, {ImageUploadOptions? options});
  Future<void> uploadMultipleFiles(List<FileUpload> uploads);
  
  // File download
  Future<File> downloadFile(String downloadURL, String localPath);
  Future<String> getDownloadURL(String storagePath);
  
  // File management
  Future<void> deleteFile(String storagePath);
  Future<List<StorageMetadata>> listFiles(String folderPath);
  Future<StorageMetadata> getFileMetadata(String storagePath);
  
  // Image processing
  Future<File> compressImage(File imageFile, CompressionOptions options);
  Future<File> resizeImage(File imageFile, ImageDimensions dimensions);
  Future<List<File>> generateImageThumbnails(File imageFile);
}
```

## 🔒 Security Service

### Security Operations
```dart
class SecurityService {
  final EncryptionService _encryption = EncryptionService();
  final ValidationService _validation = ValidationService();
  final AuditService _audit = AuditService();
  
  // Data protection
  Future<String> encryptSensitiveData(String data);
  Future<String> decryptSensitiveData(String encryptedData);
  Future<bool> validateDataIntegrity(String data, String hash);
  
  // Input validation
  ValidationResult validateEmail(String email);
  ValidationResult validatePhoneNumber(String phoneNumber);
  ValidationResult validateUserInput(String input, ValidationRules rules);
  
  // Access control
  Future<bool> hasPermission(String userId, String resource, String action);
  Future<void> logSecurityEvent(String userId, SecurityEvent event);
  Future<List<SecurityAlert>> getSecurityAlerts(String organizationId);
  
  // Fraud detection
  Future<RiskAssessment> assessUserRisk(String userId);
  Future<void> reportSuspiciousActivity(String userId, SuspiciousActivity activity);
}
```

## 📈 Performance Monitoring

### Monitoring and Diagnostics
```dart
class PerformanceMonitor {
  final FirebasePerformance _performance = FirebasePerformance.instance;
  final CrashlyticsService _crashlytics = CrashlyticsService();
  
  // Performance tracking
  Future<void> startTrace(String traceName);
  Future<void> stopTrace(String traceName);
  Future<void> recordMetric(String traceName, String metricName, int value);
  
  // Error tracking
  Future<void> recordError(dynamic exception, StackTrace stackTrace);
  Future<void> recordNonFatalError(String error, Map<String, dynamic> context);
  
  // Custom metrics
  Future<void> recordCustomMetric(String metricName, double value);
  Future<void> recordUserProperty(String property, String value);
  
  // Health checks
  Future<HealthStatus> performHealthCheck();
  Future<List<ServiceStatus>> getServiceStatus();
}
```

## 🌐 API Configuration

### Environment Configuration
```dart
class APIConfig {
  static const String baseURL = 'https://api.foodredistribution.org';
  static const String version = 'v1';
  static const Duration requestTimeout = Duration(seconds: 30);
  static const int maxRetries = 3;
  
  // Firebase configuration
  static const Map<String, dynamic> firebaseConfig = {
    'apiKey': 'your-api-key',
    'authDomain': 'food-redistribution.firebaseapp.com',
    'projectId': 'food-redistribution',
    'storageBucket': 'food-redistribution.appspot.com',
    'messagingSenderId': '123456789',
    'appId': 'your-app-id',
  };
  
  // External services
  static const String googleMapsApiKey = 'your-maps-api-key';
  static const String twilioAccountSid = 'your-twilio-sid';
  static const String sendGridApiKey = 'your-sendgrid-key';
}
```

### Error Handling
```dart
class APIError {
  final String code;
  final String message;
  final int? statusCode;
  final Map<String, dynamic>? details;
  
  static const Map<String, String> errorMessages = {
    'auth/user-not-found': 'User account does not exist',
    'auth/wrong-password': 'Invalid password',
    'auth/email-already-in-use': 'Email address is already registered',
    'permission-denied': 'You do not have permission to perform this action',
    'network-error': 'Network connection error',
    'service-unavailable': 'Service temporarily unavailable',
  };
}
```

## 📝 Usage Examples

### Complete User Registration Flow
```dart
// 1. Register user with email
final authResult = await AuthService.instance.registerWithEmail(
  'user@example.com', 
  'securePassword123'
);

// 2. Create user profile
final userProfile = AppUser(
  id: authResult.user!.uid,
  email: 'user@example.com',
  displayName: 'John Doe',
  role: UserRole.donor,
  location: Location(latitude: 37.7749, longitude: -122.4194),
  // ... other properties
);

await UserService.instance.createUserProfile(userProfile);

// 3. Send welcome notification
await NotificationService.instance.sendWelcomeEmail(userProfile.id);
```

### Food Donation Creation
```dart
// Create donation
final donation = FoodDonation(
  donorId: currentUser.id,
  title: 'Fresh Vegetables from Restaurant',
  description: 'Surplus vegetables, still fresh',
  items: [
    FoodItem(
      name: 'Mixed Vegetables',
      category: FoodCategory.vegetables,
      quantity: 10,
      unit: 'kg',
      expiryDate: DateTime.now().add(Duration(days: 2)),
      condition: FoodCondition.fresh,
    ),
  ],
  pickupLocation: restaurantLocation,
  availableFrom: DateTime.now(),
  availableUntil: DateTime.now().add(Duration(hours: 6)),
  status: DonationStatus.available,
  // ... other properties
);

final createdDonation = await DonationService.instance.createDonation(
  CreateDonationRequest(donation: donation)
);

// Find matches
final matches = await AIService.instance.findOptimalMatches(createdDonation.id);

// Notify potential recipients
for (final match in matches) {
  await NotificationService.instance.sendPushNotification(
    match.recipientId,
    PushNotification(
      title: 'New Food Donation Available',
      body: 'Fresh vegetables available for pickup',
      data: {'donationId': createdDonation.id},
    ),
  );
}
```

---

This API documentation provides a comprehensive overview of the service architecture and integration patterns. For specific implementation details, refer to the individual service files in the `lib/services/` directory.

## 🆘 Support

For API support and questions:
- **Email**: api-support@foodredistribution.org
- **Documentation**: [https://docs.foodredistribution.org](https://docs.foodredistribution.org)
- **GitHub Issues**: [Repository Issues](https://github.com/Shravanthi20/food-redistribution-system/issues)