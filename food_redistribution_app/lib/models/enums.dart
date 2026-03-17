enum UserRole { donor, ngo, volunteer, admin }

enum UserStatus { pending, verified, active, suspended, restricted }

enum OnboardingState {
  registered,
  documentSubmitted,
  verified,
  profileComplete,
  active
}

enum FoodType {
  cooked,
  raw,
  packaged,
  dairy,
  fruits,
  vegetables,
  grains,
  meat,
  seafood,
  bakery,
  beverages,
  other
}

enum DonationStatus {
  listed,
  matched,
  pickedUp,
  inTransit,
  delivered,
  cancelled,
  expired
}

enum FoodSafetyLevel {
  high,
  medium,
  low
}

enum DeliveryStatus {
  pending,
  assigned,
  pickedUp,
  inTransit,
  arrived,
  delivered,
  cancelled
}

enum Priority {
  low,
  normal,
  high,
  urgent,
  critical
}

enum TrackingStatus {
  idle,
  enRoute,
  atPickup,
  collected,
  inTransit,
  nearDelivery,
  delivered,
  completed
}

enum GeofenceType {
  pickup,
  delivery,
  checkpoint
}

enum OptimizationStrategy {
  shortestDistance,
  fastestTime,
  fuelEfficient,
  trafficAware,
  multiStop
}

enum NotificationPriority {
  low,
  normal,
  high,
  urgent,
  critical
}

enum NotificationChannel {
  inApp,
  push,
  email,
  sms,
  whatsapp
}

enum NotificationCategory {
  donationMatching,
  volunteerDispatch,
  routeOptimization,
  deliveryTracking,
  systemAlert,
  performanceUpdate,
  resourceAlert,
  scheduleUpdate
}

enum AuditEventType {
  authSuccess,
  authFailure,
  dataAccess,
  dataModification,
  securityAlert,
  systemError,
  adminAction,
  roleChange,
  userLogin,
  userLogout,
  verificationSubmitted,
  verificationApproved,
  verificationRejected,
}

enum AuditRiskLevel {
  low,
  medium,
  high,
  critical,
}

enum NGOType {
  orphanage,
  oldAgeHome,
  school,
  hospital,
  communityCenter,
  foodBank,
  shelter,
  other
}

enum DispatchPriority {
  immediate,   // < 30 minutes
  urgent,      // < 2 hours
  scheduled,   // > 2 hours
  flexible,    // No specific time
}

enum VolunteerStatus {
  available,
  busy,
  offline,
  onBreak,
}

enum MatchingCriteria {
  distance,
  capacity,
  urgency,
  foodType,
  availability
}

enum VehicleType {
  bicycle,
  motorcycle,
  car,
  van,
  truck,
  scooter,
  public,
  walking,
  none,
  other
}

enum DonorType {
  restaurant,
  bakery,
  supermarket,
  hotel,
  individual,
  catering,
  institutional,
  other
}
