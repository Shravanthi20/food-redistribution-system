// Firestore Database Schema for Food Redistribution Platform
// This file documents the complete database structure

/*
FIRESTORE COLLECTIONS STRUCTURE:

📁 users (main user collection)
├── {userId}
    ├── id: string
    ├── email: string
    ├── fullName: string
    ├── role: string (donor|ngo|volunteer|admin)
    ├── phoneNumber: string?
    ├── status: string (pending|verified|suspended)
    ├── emailVerified: boolean
    ├── onboardingState: string (registered|profileCompleted|documentSubmitted|verified)
    ├── createdAt: timestamp
    ├── updatedAt: timestamp
    ├── restrictions: map
    ├── suspendedAt: timestamp?
    ├── suspendedBy: string?
    ├── suspendedUntil: timestamp?
    ├── suspensionReason: string?
    └── notifications (subcollection)
        └── {notificationId}
            ├── title: string
            ├── message: string
            ├── type: string
            ├── data: map
            ├── read: boolean
            ├── createdAt: timestamp
            └── readAt: timestamp?

📁 donor_profiles
├── {userId}
    ├── userId: string
    ├── businessName: string
    ├── businessType: string
    ├── businessAddress: string
    ├── contactPerson: string
    ├── businessHours: string
    ├── donationCapacity: number
    ├── specialRequirements: string
    ├── isVerified: boolean
    ├── createdAt: timestamp
    └── updatedAt: timestamp

📁 ngo_profiles
├── {userId}
    ├── userId: string
    ├── organizationName: string
    ├── registrationNumber: string
    ├── organizationType: string
    ├── serviceArea: string
    ├── capacity: number
    ├── operatingHours: string
    ├── contactPerson: string
    ├── description: string
    ├── isVerified: boolean
    ├── createdAt: timestamp
    └── updatedAt: timestamp

📁 volunteer_profiles
├── {userId}
    ├── userId: string
    ├── availability: array
    ├── transportMode: string
    ├── serviceRadius: number
    ├── skills: array
    ├── experience: string
    ├── emergencyContact: string
    ├── isVerified: boolean
    ├── rating: number
    ├── totalDeliveries: number
    ├── createdAt: timestamp
    └── updatedAt: timestamp

📁 admin_profiles
├── {userId}
    ├── userId: string
    ├── adminLevel: string
    ├── permissions: array
    ├── department: string
    ├── createdAt: timestamp
    └── updatedAt: timestamp

📁 food_donations
├── {donationId}
    ├── id: string
    ├── donorId: string
    ├── title: string
    ├── description: string
    ├── foodType: string
    ├── quantity: number
    ├── unit: string
    ├── expiryDate: timestamp
    ├── location: map {lat: number, lng: number}
    ├── address: string
    ├── specialInstructions: string?
    ├── status: string (available|reserved|pickedUp|delivered|completed|cancelled)
    ├── assignedNGOId: string?
    ├── assignedVolunteerId: string?
    ├── assignedAt: timestamp?
    ├── pickedUpAt: timestamp?
    ├── deliveredAt: timestamp?
    ├── completedAt: timestamp?
    ├── cancelledAt: timestamp?
    ├── cancellationReason: string?
    ├── notes: array
    ├── createdAt: timestamp
    └── updatedAt: timestamp

📁 verification_submissions
├── {submissionId}
    ├── userId: string
    ├── userRole: string
    ├── documentInfo: array
        └── {
            ├── type: string
            ├── information: string
            └── submittedAt: timestamp
        }
    ├── status: string (pending|underReview|approved|rejected|clarificationNeeded)
    ├── submittedAt: timestamp
    ├── reviewedBy: string?
    ├── reviewedAt: timestamp?
    ├── notes: string?
    └── requestedClarifications: array?

📁 admin_tasks
├── {taskId}
    ├── type: string (document_verification|user_review|system_alert)
    ├── submissionId: string?
    ├── userId: string
    ├── userRole: string?
    ├── priority: number
    ├── status: string (pending|in_progress|completed|cancelled)
    ├── assignedTo: string?
    ├── completedBy: string?
    ├── createdAt: timestamp
    ├── completedAt: timestamp?
    └── notes: string?

📁 audit_logs
├── {logId}
    ├── eventType: string
    ├── riskLevel: string (low|medium|high|critical)
    ├── userId: string
    ├── currentUserId: string?
    ├── targetUserId: string?
    ├── resourceId: string?
    ├── resourceType: string?
    ├── timestamp: timestamp
    ├── ipAddress: string?
    ├── userAgent: string?
    ├── deviceInfo: map
    └── additionalData: map

📁 security_logs
├── {emailHash}
    ├── emailHash: string
    ├── failedAttempts: number
    ├── lastAttempt: timestamp
    ├── ipAddress: string?
    ├── createdAt: timestamp
    └── updatedAt: timestamp

📁 user_sessions
├── {sessionId}
    ├── userId: string
    ├── sessionId: string
    ├── ipAddress: string?
    ├── createdAt: timestamp
    ├── expiresAt: timestamp
    ├── isActive: boolean
    ├── invalidatedAt: timestamp?
    └── terminatedAt: timestamp?

📁 security_events
├── {eventId}
    ├── event: string
    ├── timestamp: timestamp
    ├── userId: string?
    ├── emailHash: string?
    ├── ipAddress: string?
    └── additionalData: map

📁 security_alerts
├── {alertId}
    ├── auditLogId: string
    ├── eventType: string
    ├── riskLevel: string
    ├── userId: string
    ├── timestamp: timestamp
    ├── status: string (open|investigating|resolved|false_positive)
    ├── reviewedBy: string?
    ├── reviewedAt: timestamp?
    ├── notes: string?
    └── createdAt: timestamp

📁 notifications (main collection)
├── {notificationId}
    ├── userId: string
    ├── title: string
    ├── message: string
    ├── type: string
    ├── data: map
    ├── read: boolean
    └── createdAt: timestamp

📁 donation_tracking
├── {trackingId}
    ├── donationId: string
    ├── donorId: string?
    ├── ngoId: string?
    ├── volunteerId: string?
    ├── action: string
    ├── timestamp: timestamp
    ├── details: map
    └── location: map?

📁 donation_assignments
├── {assignmentId}
    ├── donationId: string
    ├── ngoId: string
    ├── volunteerId: string?
    ├── assignedAt: timestamp
    ├── status: string (active|completed|cancelled)
    ├── completedAt: timestamp?
    └── notes: string?

📁 verification_logs
├── {logId}
    ├── event: string
    ├── userId: string
    ├── timestamp: timestamp
    ├── submissionId: string?
    ├── adminId: string?
    ├── decision: string?
    └── additionalData: map

INDEXES RECOMMENDED:
- users: role, status, onboardingState, createdAt
- food_donations: donorId, status, assignedNGOId, assignedVolunteerId, expiryDate
- verification_submissions: userId, status, submittedAt
- audit_logs: userId, eventType, riskLevel, timestamp
- security_events: event, timestamp
- notifications: userId, read, createdAt
- donation_tracking: donationId, action, timestamp

SECURITY RULES:
- Users can read/write their own data
- Admins can read all data and write admin-specific data
- NGOs can read assigned donations
- Volunteers can read assigned donations
- Verification submissions readable by user and admins
- Audit logs readable by admins only
*/

class FirestoreCollections {
  // Collection names as constants
  static const String users = 'users';
  static const String donorProfiles = 'donor_profiles';
  static const String ngoProfiles = 'ngo_profiles';
  static const String volunteerProfiles = 'volunteer_profiles';
  static const String adminProfiles = 'admin_profiles';
  static const String foodDonations = 'food_donations';
  static const String verificationSubmissions = 'verification_submissions';
  static const String adminTasks = 'admin_tasks';
  static const String auditLogs = 'audit_logs';
  static const String securityLogs = 'security_logs';
  static const String userSessions = 'user_sessions';
  static const String securityEvents = 'security_events';
  static const String securityAlerts = 'security_alerts';
  static const String notifications = 'notifications';
  static const String donationTracking = 'donation_tracking';
  static const String donationAssignments = 'donation_assignments';
  static const String verificationLogs = 'verification_logs';
  
  // Subcollections
  static const String userNotifications = 'notifications';
}
