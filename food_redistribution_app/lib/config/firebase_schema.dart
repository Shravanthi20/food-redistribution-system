/// Firebase Schema Configuration
/// 
/// This file defines all collection names and document structures
/// for the Food Redistribution App's Firestore database.
/// 
/// SCHEMA VERSION: 2.0
/// Last Updated: 2026-02-10

library firebase_schema;

/// Collection names - use these constants throughout the app
class Collections {
  // Core collections
  static const String users = 'users';
  static const String organizations = 'organizations';
  static const String donations = 'donations';
  static const String deliveries = 'deliveries';
  static const String requests = 'requests';
  static const String assignments = 'assignments';
  
  // Tracking & notifications
  static const String tracking = 'tracking';
  static const String notifications = 'notifications';
  
  // Verification & audit
  static const String verifications = 'verifications';
  static const String audit = 'audit';
  static const String security = 'security';
  
  // Analytics & system
  static const String analytics = 'analytics';
  static const String matching = 'matching';
  static const String adminTasks = 'admin_tasks';
  static const String system = 'system';
}

/// Subcollection names
class Subcollections {
  // User subcollections
  static const String tokens = 'tokens';
  static const String settings = 'settings';
  
  // Organization subcollections
  static const String branches = 'branches';
  
  // Donation subcollections
  static const String history = 'history';
  static const String messages = 'messages';
  
  // Delivery subcollections
  static const String checkpoints = 'checkpoints';
  
  // Tracking subcollections
  static const String locations = 'locations';
  
  // Notification subcollections
  static const String items = 'items';
  
  // Matching subcollections
  static const String results = 'results';
  
  // Analytics subcollections
  static const String daily = 'daily';
}

/// Document field names for consistency
class Fields {
  // Common fields
  static const String id = 'id';
  static const String createdAt = 'createdAt';
  static const String updatedAt = 'updatedAt';
  static const String status = 'status';
  
  // User fields
  static const String userId = 'userId';
  static const String email = 'email';
  static const String role = 'role';
  static const String onboardingState = 'onboardingState';
  static const String profile = 'profile';
  static const String firstName = 'firstName';
  static const String lastName = 'lastName';
  static const String phone = 'phone';
  static const String location = 'location';
  static const String isVerified = 'isVerified';
  
  // Location fields
  static const String latitude = 'latitude';
  static const String longitude = 'longitude';
  static const String geohash = 'geohash';
  static const String address = 'address';
  
  // Donation fields
  static const String donorId = 'donorId';
  static const String ngoId = 'ngoId';
  static const String volunteerId = 'volunteerId';
  static const String title = 'title';
  static const String description = 'description';
  static const String foodTypes = 'foodTypes';
  static const String quantity = 'quantity';
  static const String unit = 'unit';
  static const String expiresAt = 'expiresAt';
  static const String pickupLocation = 'pickupLocation';
  static const String isUrgent = 'isUrgent';
  
  // Delivery fields
  static const String donationId = 'donationId';
  static const String pickupTime = 'pickupTime';
  static const String deliveryTime = 'deliveryTime';
  
  // Assignment fields
  static const String assigneeId = 'assigneeId';
  static const String type = 'type';
  static const String score = 'score';
  static const String expiresAtField = 'expiresAt';
  
  // Organization fields
  static const String ownerId = 'ownerId';
  static const String organizationName = 'organizationName';
  static const String capacity = 'capacity';
  static const String registrationNumber = 'registrationNumber';
}

/// Schema structure documentation
/// 
/// ## Collections Overview
/// 
/// ### /users/{userId}
/// Unified user document containing core auth info and role-specific profile data.
/// ```
/// {
///   email: string,
///   role: 'donor' | 'ngo' | 'volunteer' | 'admin',
///   status: 'pending' | 'verified' | 'active' | 'suspended' | 'restricted',
///   onboardingState: 'registered' | 'documentSubmitted' | 'verified' | 'active',
///   createdAt: timestamp,
///   updatedAt: timestamp,
///   profile: {
///     firstName: string,
///     lastName: string,
///     phone: string,
///     profileImageUrl: string?,
///     location: {
///       latitude: number,
///       longitude: number,
///       geohash: string,
///       address: string
///     },
///     // Role-specific fields embedded here
///     // For donor: businessName, businessType
///     // For volunteer: hasVehicle, vehicleType, maxRadius, availabilityHours
///     // For NGO: links to /organizations collection
///   }
/// }
/// ```
/// 
/// ### /organizations/{orgId}
/// NGO organization profiles (separate for multi-user orgs).
/// ```
/// {
///   ownerId: string (userId),
///   organizationName: string,
///   registrationNumber: string,
///   ngoType: string,
///   location: { latitude, longitude, geohash, address },
///   capacity: number,
///   servingPopulation: string[],
///   operatingHours: string,
///   preferredFoodTypes: string[],
///   storageCapacity: number,
///   refrigerationAvailable: boolean,
///   contactPerson: string,
///   contactPhone: string,
///   verificationUrl: string?,
///   isVerified: boolean,
///   createdAt: timestamp
/// }
/// ```
/// 
/// ### /donations/{donationId}
/// Food donation listings.
/// ```
/// {
///   donorId: string,
///   ngoId: string?,
///   volunteerId: string?,
///   title: string,
///   description: string,
///   foodTypes: string[],
///   quantity: number,
///   unit: string,
///   preparedAt: timestamp,
///   expiresAt: timestamp,
///   availableFrom: timestamp,
///   availableUntil: timestamp,
///   pickupLocation: { latitude, longitude, geohash, address },
///   pickupPhone: string,
///   status: 'listed' | 'matched' | 'pickedUp' | 'inTransit' | 'delivered' | 'cancelled' | 'expired',
///   isUrgent: boolean,
///   safetyLevel: 'high' | 'medium' | 'low',
///   dietary: { isVegetarian, isVegan, isHalal },
///   allergenInfo: string?,
///   images: string[],
///   createdAt: timestamp,
///   updatedAt: timestamp
/// }
/// ```
/// 
/// ### /deliveries/{deliveryId}
/// Active delivery tasks linking donation, volunteer, and NGO.
/// ```
/// {
///   donationId: string,
///   donorId: string,
///   ngoId: string,
///   volunteerId: string,
///   status: 'pending' | 'accepted' | 'pickedUp' | 'inTransit' | 'delivered' | 'cancelled',
///   pickupLocation: { latitude, longitude, address },
///   dropoffLocation: { latitude, longitude, address },
///   scheduledPickup: timestamp,
///   actualPickup: timestamp?,
///   scheduledDelivery: timestamp,
///   actualDelivery: timestamp?,
///   notes: string?,
///   rating: number?,
///   createdAt: timestamp
/// }
/// ```
/// 
/// ### /requests/{requestId}
/// NGO food requests/demands.
/// ```
/// {
///   ngoId: string,
///   organizationId: string,
///   foodTypes: string[],
///   quantityMin: number,
///   quantityMax: number,
///   urgency: 'low' | 'normal' | 'high' | 'critical',
///   status: 'active' | 'matched' | 'fulfilled' | 'cancelled',
///   timing: { preferredDays, preferredHours },
///   specialRequirements: string?,
///   createdAt: timestamp
/// }
/// ```
/// 
/// ### /assignments/{assignmentId}
/// Matching assignments for NGOs and volunteers.
/// ```
/// {
///   donationId: string,
///   assigneeId: string,
///   type: 'ngo_offer' | 'volunteer_task',
///   status: 'pending' | 'accepted' | 'rejected' | 'expired',
///   score: number,
///   expiresAt: timestamp,
///   createdAt: timestamp,
///   respondedAt: timestamp?
/// }
/// ```
/// 
/// ### /tracking/{volunteerId}/locations/{locationId}
/// Real-time location updates.
/// ```
/// {
///   latitude: number,
///   longitude: number,
///   accuracy: number,
///   speed: number?,
///   heading: number?,
///   timestamp: timestamp,
///   taskId: string?,
///   status: 'idle' | 'enRoute' | 'atPickup' | 'inTransit' | 'nearDelivery' | 'delivered'
/// }
/// ```
/// 
/// ### /notifications/{userId}/items/{notificationId}
/// User notifications.
/// ```
/// {
///   title: string,
///   body: string,
///   type: string,
///   data: map?,
///   read: boolean,
///   createdAt: timestamp
/// }
/// ```
/// 
/// ### /verifications/{verificationId}
/// Document verification submissions.
/// ```
/// {
///   userId: string,
///   userRole: string,
///   documentType: string,
///   documentUrl: string?,
///   documentInfo: map?,
///   status: 'pending' | 'underReview' | 'approved' | 'rejected',
///   submittedAt: timestamp,
///   reviewedBy: string?,
///   reviewedAt: timestamp?,
///   notes: string?
/// }
/// ```
class FirebaseSchema {
  static const String version = '2.0';
  static const String lastUpdated = '2026-02-10';
}
