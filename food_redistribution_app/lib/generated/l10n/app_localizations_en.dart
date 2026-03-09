// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Food Redistribution Platform';

  @override
  String get appTagline => 'Reducing food waste, feeding communities';

  @override
  String get comingSoon => 'Coming Soon';

  @override
  String get operational => 'Operational';

  @override
  String get save => 'Save';

  @override
  String get cancel => 'Cancel';

  @override
  String get submit => 'Submit';

  @override
  String get delete => 'Delete';

  @override
  String get edit => 'Edit';

  @override
  String get back => 'Back';

  @override
  String get next => 'Next';

  @override
  String get done => 'Done';

  @override
  String get ok => 'OK';

  @override
  String get confirm => 'Confirm';

  @override
  String get loading => 'Loading…';

  @override
  String get error => 'Error';

  @override
  String get success => 'Success';

  @override
  String get retry => 'Retry';

  @override
  String get close => 'Close';

  @override
  String get search => 'Search';

  @override
  String get filter => 'Filter';

  @override
  String get all => 'All';

  @override
  String get yes => 'Yes';

  @override
  String get no => 'No';

  @override
  String get view => 'View';

  @override
  String get refresh => 'Refresh';

  @override
  String get noDataAvailable => 'No data available';

  @override
  String get seeAll => 'See All';

  @override
  String get viewAll => 'View All';

  @override
  String get required => 'Required';

  @override
  String get optional => 'Optional';

  @override
  String get total => 'Total';

  @override
  String get active => 'Active';

  @override
  String get unknown => 'Unknown';

  @override
  String get details => 'Details';

  @override
  String get description => 'Description';

  @override
  String get title => 'Title';

  @override
  String get type => 'Type';

  @override
  String get urgent => 'URGENT';

  @override
  String get processing => 'Processing…';

  @override
  String get submitting => 'Submitting…';

  @override
  String get updating => 'Updating…';

  @override
  String get creating => 'Creating…';

  @override
  String get sending => 'Sending…';

  @override
  String get rejecting => 'Rejecting…';

  @override
  String get justNow => 'Just now';

  @override
  String get never => 'Never';

  @override
  String get accepted => 'Accepted';

  @override
  String get approved => 'Approved';

  @override
  String get rejected => 'Rejected';

  @override
  String get signIn => 'Sign In';

  @override
  String get signOut => 'Sign Out';

  @override
  String get signUp => 'Sign Up';

  @override
  String get register => 'Register';

  @override
  String get email => 'Email';

  @override
  String get password => 'Password';

  @override
  String get confirmPassword => 'Confirm Password';

  @override
  String get forgotPassword => 'Forgot Password?';

  @override
  String get resetPassword => 'Reset Password';

  @override
  String get changePassword => 'Change Password';

  @override
  String get loginTitle => 'Welcome Back';

  @override
  String get loginSubtitle => 'Sign in to continue making a difference';

  @override
  String get alreadyHaveAccount => 'Already have an account? Sign in';

  @override
  String get dontHaveAccount => 'Don\'t have an account? Sign up';

  @override
  String get emailVerificationTitle => 'Verify Your Email';

  @override
  String emailVerificationBody(String email) {
    return 'A verification link has been sent to $email. Please check your inbox.';
  }

  @override
  String get resendVerification => 'Resend Verification Email';

  @override
  String get otpTitle => 'Enter OTP';

  @override
  String otpSubtitle(String phone) {
    return 'Enter the 6-digit code sent to $phone';
  }

  @override
  String get emailRequired => 'Email is required';

  @override
  String get passwordRequired => 'Password is required';

  @override
  String get invalidEmail => 'Please enter a valid email address';

  @override
  String get passwordTooShort => 'Password must be at least 8 characters';

  @override
  String get passwordsMustMatch => 'Passwords do not match';

  @override
  String get fieldRequired => 'This field is required';

  @override
  String get invalidInput => 'Invalid input';

  @override
  String get roleDonor => 'Donor';

  @override
  String get roleNgo => 'NGO';

  @override
  String get roleVolunteer => 'Volunteer';

  @override
  String get roleAdmin => 'Admin';

  @override
  String get selectRole => 'Select Your Role';

  @override
  String get donorRoleDescription =>
      'Share your surplus food with those in need';

  @override
  String get ngoRoleDescription =>
      'Connect with donors and distribute food to beneficiaries';

  @override
  String get volunteerRoleDescription =>
      'Help with food pickup and delivery logistics';

  @override
  String get dashboard => 'Dashboard';

  @override
  String get profile => 'Profile';

  @override
  String get notifications => 'Notifications';

  @override
  String get settings => 'Settings';

  @override
  String get logout => 'Logout';

  @override
  String get donorDashboard => 'Donor Dashboard';

  @override
  String get ngoDashboard => 'NGO Dashboard';

  @override
  String get volunteerDashboard => 'Volunteer Dashboard';

  @override
  String get adminDashboard => 'Admin Dashboard';

  @override
  String get createDonation => 'Create Donation';

  @override
  String get myDonations => 'My Donations';

  @override
  String get donationDetails => 'Donation Details';

  @override
  String get donationTitle => 'Donation Title';

  @override
  String get donationDescription => 'Description';

  @override
  String get quantity => 'Quantity';

  @override
  String get unit => 'Unit';

  @override
  String get foodType => 'Food Type';

  @override
  String get preparedAt => 'Prepared At';

  @override
  String get expiresAt => 'Expires At';

  @override
  String get availableFrom => 'Available From';

  @override
  String get availableUntil => 'Available Until';

  @override
  String get pickupAddress => 'Pickup Address';

  @override
  String get contactPhone => 'Contact Phone';

  @override
  String get estimatedMeals => 'Estimated Meals';

  @override
  String get estimatedPeople => 'Estimated People';

  @override
  String get allergens => 'Allergens';

  @override
  String get handlingInstructions => 'Handling Instructions';

  @override
  String get storageInstructions => 'Storage Instructions';

  @override
  String get requiresRefrigeration => 'Requires Refrigeration';

  @override
  String get isVegetarian => 'Vegetarian';

  @override
  String get isVegan => 'Vegan';

  @override
  String get isHalal => 'Halal';

  @override
  String get isUrgent => 'Urgent';

  @override
  String get foodSafetyLevel => 'Food Safety Level';

  @override
  String get safetyHigh => 'High — Freshly prepared, safe for all';

  @override
  String get safetyMedium => 'Medium — Prepared earlier, handle with care';

  @override
  String get safetyLow => 'Low — Near expiry, consume promptly';

  @override
  String get safetyCritical => 'Critical — Immediate action required';

  @override
  String expiryWarning(int hours) {
    return 'Warning: This item expires in $hours hour(s)';
  }

  @override
  String get foodExpired => 'EXPIRED — Do not distribute';

  @override
  String allergenWarning(String allergens) {
    return 'Allergen Alert: Contains $allergens';
  }

  @override
  String get refrigerationRequired =>
      '⚠ Refrigeration Required — Keep below 4°C';

  @override
  String get foodSafetyWarning => 'Food Safety Warning';

  @override
  String get doNotConsume => 'DO NOT CONSUME — Food safety concern';

  @override
  String get checkBeforeEating =>
      'Please inspect food condition before distribution';

  @override
  String get temperatureBreached => 'Temperature safety threshold breached';

  @override
  String get crossContaminationRisk => 'Risk of cross-contamination detected';

  @override
  String get donationStatus => 'Status';

  @override
  String get statusPending => 'Pending';

  @override
  String get statusApproved => 'Approved';

  @override
  String get statusPickedUp => 'Picked Up';

  @override
  String get statusDelivered => 'Delivered';

  @override
  String get statusExpired => 'Expired';

  @override
  String get statusCancelled => 'Cancelled';

  @override
  String get statusActive => 'Active';

  @override
  String get statusInactive => 'Inactive';

  @override
  String get statusVerified => 'Verified';

  @override
  String get statusRejected => 'Rejected';

  @override
  String get statusMatched => 'Matched';

  @override
  String get statusInTransit => 'In Transit';

  @override
  String get availableDonations => 'Available Donations';

  @override
  String get createRequest => 'Create Request';

  @override
  String get foodRequest => 'Food Request';

  @override
  String get myRequests => 'My Requests';

  @override
  String get requestTitle => 'Request Title';

  @override
  String get requestDescription => 'Request Description';

  @override
  String get quantityNeeded => 'Quantity Needed';

  @override
  String get urgencyLevel => 'Urgency Level';

  @override
  String get urgencyLow => 'Low';

  @override
  String get urgencyMedium => 'Medium';

  @override
  String get urgencyHigh => 'High';

  @override
  String get urgencyCritical => 'Critical';

  @override
  String get beneficiariesCount => 'Number of Beneficiaries';

  @override
  String get acceptDonation => 'Accept Donation';

  @override
  String get rejectDonation => 'Reject Donation';

  @override
  String get pendingRequests => 'Pending Requests';

  @override
  String get ngoName => 'Organization Name';

  @override
  String get rejectReason => 'Reason for Rejection';

  @override
  String get clarifyRequest => 'Clarify Request';

  @override
  String get inspectDelivery => 'Inspect Delivery';

  @override
  String get myTasks => 'My Tasks';

  @override
  String get acceptTask => 'Accept Task';

  @override
  String get rejectTask => 'Decline Task';

  @override
  String get taskComplete => 'Mark as Complete';

  @override
  String get pickupLocation => 'Pickup Location';

  @override
  String get deliveryLocation => 'Delivery Location';

  @override
  String get estimatedDistance => 'Estimated Distance';

  @override
  String get assignedTask => 'Assigned Task';

  @override
  String get taskStatus => 'Task Status';

  @override
  String get deliveryCoordination => 'Delivery Coordination';

  @override
  String get reportIssue => 'Report Issue';

  @override
  String get issueTitle => 'Issue Title';

  @override
  String get issueDescription => 'Issue Description';

  @override
  String get userManagement => 'User Management';

  @override
  String get verifyUser => 'Verify User';

  @override
  String get pendingVerification => 'Pending Verification';

  @override
  String get systemStatus => 'System Status';

  @override
  String get analytics => 'Analytics';

  @override
  String get auditLog => 'Audit Log';

  @override
  String get reportsTitle => 'Reports';

  @override
  String get impactReports => 'Impact Reports';

  @override
  String get totalDonations => 'Total Donations';

  @override
  String get totalDeliveries => 'Total Deliveries';

  @override
  String get mealsProvided => 'Meals Provided';

  @override
  String get wasteReduced => 'Waste Reduced';

  @override
  String get activeUsers => 'Active Users';

  @override
  String get language => 'Language';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageHindi => 'हिन्दी (Hindi)';

  @override
  String get languageTamil => 'தமிழ் (Tamil)';

  @override
  String get changeLanguage => 'Change Language';

  @override
  String get preferredLanguage => 'Preferred Language';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get darkMode => 'Dark Mode';

  @override
  String get lightMode => 'Light Mode';

  @override
  String get themeSettings => 'Theme';

  @override
  String get appearanceSettings => 'Appearance';

  @override
  String get networkError => 'Network error. Please check your connection.';

  @override
  String get serverError => 'Server error. Please try again later.';

  @override
  String get unknownError => 'An unexpected error occurred. Please try again.';

  @override
  String get sessionExpired =>
      'Your session has expired. Please sign in again.';

  @override
  String get permissionDenied =>
      'You do not have permission to perform this action.';

  @override
  String get locationPermissionRequired =>
      'Location permission is required for this feature.';

  @override
  String get cameraPermissionRequired =>
      'Camera permission is required to upload photos.';

  @override
  String get documentUpload => 'Upload Document';

  @override
  String get documentVerification => 'Document Verification';

  @override
  String get verificationPending => 'Verification Pending';

  @override
  String get verificationApproved => 'Verification Approved';

  @override
  String get verificationRejected => 'Verification Rejected';

  @override
  String get onboardingTitle1 => 'Reduce Food Waste';

  @override
  String get onboardingBody1 =>
      'Connect surplus food with communities that need it most.';

  @override
  String get onboardingTitle2 => 'Real-Time Coordination';

  @override
  String get onboardingBody2 => 'Track donations and deliveries in real time.';

  @override
  String get onboardingTitle3 => 'Make an Impact';

  @override
  String get onboardingBody3 =>
      'Every donation feeds a family and saves the planet.';

  @override
  String get getStarted => 'Get Started';

  @override
  String get skip => 'Skip';

  @override
  String get name => 'Name';

  @override
  String get fullName => 'Full Name';

  @override
  String get phoneNumber => 'Phone Number';

  @override
  String get address => 'Address';

  @override
  String get city => 'City';

  @override
  String get state => 'State';

  @override
  String get pincode => 'PIN Code';

  @override
  String get latitude => 'Latitude';

  @override
  String get longitude => 'Longitude';

  @override
  String get useCurrentLocation => 'Use Current Location';

  @override
  String get organizationType => 'Organization Type';

  @override
  String get registrationNumber => 'Registration Number';

  @override
  String get website => 'Website';

  @override
  String get socialMedia => 'Social Media';

  @override
  String get category => 'Category';

  @override
  String get tags => 'Tags';

  @override
  String get notes => 'Notes';

  @override
  String get date => 'Date';

  @override
  String get time => 'Time';

  @override
  String get dateTime => 'Date & Time';

  @override
  String get selectDate => 'Select Date';

  @override
  String get selectTime => 'Select Time';

  @override
  String get realTimeTracking => 'Real-Time Tracking';

  @override
  String get liveLocation => 'Live Location';

  @override
  String get trackDelivery => 'Track Delivery';

  @override
  String get dispatchOrder => 'Dispatch Order';

  @override
  String get logisticsManagement => 'Logistics Management';

  @override
  String get matchingAlgorithm => 'Matching';

  @override
  String get matchScore => 'Match Score';

  @override
  String get distance => 'Distance';

  @override
  String get estimatedArrival => 'Estimated Arrival';

  @override
  String get confirmLogout => 'Are you sure you want to sign out?';

  @override
  String get confirmDelete =>
      'Are you sure you want to delete this? This action cannot be undone.';

  @override
  String get savedSuccessfully => 'Saved successfully';

  @override
  String get deletedSuccessfully => 'Deleted successfully';

  @override
  String get submittedSuccessfully => 'Submitted successfully';

  @override
  String get donationCreatedSuccess => 'Donation created successfully';

  @override
  String get requestCreatedSuccess => 'Request created successfully';

  @override
  String get userVerifiedSuccess => 'User verified successfully';

  @override
  String get loginSuccessful => 'Signed in successfully';

  @override
  String get logoutSuccessful => 'Signed out successfully';

  @override
  String get registrationSuccessful => 'Account created successfully';
}
