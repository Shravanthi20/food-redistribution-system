/// Typed constants for every translation key in the ARB files.
///
/// Usage:
///   AppLocalizations.of(context).save
///   context.l10n.save   // requires the BuildContext extension in app_localizations_ext.dart
///
/// Having explicit constants here means a typo is caught at compile time
/// rather than silently producing a missing-key fallback at runtime.
// ignore_for_file: constant_identifier_names
abstract final class LocaleKeys {
  // ── Common ─────────────────────────────────────────────────────────────────
  static const String appName = 'appName';
  static const String appTagline = 'appTagline';
  static const String comingSoon = 'comingSoon';
  static const String operational = 'operational';
  static const String save = 'save';
  static const String cancel = 'cancel';
  static const String submit = 'submit';
  static const String delete = 'delete';
  static const String edit = 'edit';
  static const String back = 'back';
  static const String next = 'next';
  static const String done = 'done';
  static const String ok = 'ok';
  static const String confirm = 'confirm';
  static const String loading = 'loading';
  static const String error = 'error';
  static const String success = 'success';
  static const String retry = 'retry';
  static const String close = 'close';
  static const String search = 'search';
  static const String filter = 'filter';
  static const String all = 'all';
  static const String yes = 'yes';
  static const String no = 'no';
  static const String view = 'view';
  static const String refresh = 'refresh';
  static const String noDataAvailable = 'noDataAvailable';
  static const String seeAll = 'seeAll';
  static const String viewAll = 'viewAll';
  static const String required = 'required';
  static const String optional = 'optional';
  static const String total = 'total';
  static const String active = 'active';
  static const String unknown = 'unknown';
  static const String details = 'details';
  static const String description = 'description';
  static const String title = 'title';
  static const String type = 'type';
  static const String urgent = 'urgent';
  static const String processing = 'processing';
  static const String submitting = 'submitting';
  static const String updating = 'updating';
  static const String creating = 'creating';
  static const String sending = 'sending';
  static const String rejecting = 'rejecting';
  static const String justNow = 'justNow';
  static const String never = 'never';
  static const String accepted = 'accepted';
  static const String approved = 'approved';
  static const String rejected = 'rejected';

  // ── Auth ───────────────────────────────────────────────────────────────────
  static const String signIn = 'signIn';
  static const String signOut = 'signOut';
  static const String signUp = 'signUp';
  static const String register = 'register';
  static const String email = 'email';
  static const String password = 'password';
  static const String confirmPassword = 'confirmPassword';
  static const String forgotPassword = 'forgotPassword';
  static const String resetPassword = 'resetPassword';
  static const String changePassword = 'changePassword';
  static const String loginTitle = 'loginTitle';
  static const String loginSubtitle = 'loginSubtitle';
  static const String alreadyHaveAccount = 'alreadyHaveAccount';
  static const String dontHaveAccount = 'dontHaveAccount';
  static const String emailVerificationTitle = 'emailVerificationTitle';
  static const String emailVerificationBody = 'emailVerificationBody';
  static const String resendVerification = 'resendVerification';
  static const String otpTitle = 'otpTitle';
  static const String otpSubtitle = 'otpSubtitle';

  // ── Validation ─────────────────────────────────────────────────────────────
  static const String emailRequired = 'emailRequired';
  static const String passwordRequired = 'passwordRequired';
  static const String invalidEmail = 'invalidEmail';
  static const String passwordTooShort = 'passwordTooShort';
  static const String passwordsMustMatch = 'passwordsMustMatch';
  static const String fieldRequired = 'fieldRequired';
  static const String invalidInput = 'invalidInput';

  // ── Roles ──────────────────────────────────────────────────────────────────
  static const String roleDonor = 'roleDonor';
  static const String roleNgo = 'roleNgo';
  static const String roleVolunteer = 'roleVolunteer';
  static const String roleAdmin = 'roleAdmin';
  static const String selectRole = 'selectRole';
  static const String donorRoleDescription = 'donorRoleDescription';
  static const String ngoRoleDescription = 'ngoRoleDescription';
  static const String volunteerRoleDescription = 'volunteerRoleDescription';

  // ── Navigation ─────────────────────────────────────────────────────────────
  static const String dashboard = 'dashboard';
  static const String profile = 'profile';
  static const String notifications = 'notifications';
  static const String settings = 'settings';
  static const String logout = 'logout';
  static const String donorDashboard = 'donorDashboard';
  static const String ngoDashboard = 'ngoDashboard';
  static const String volunteerDashboard = 'volunteerDashboard';
  static const String adminDashboard = 'adminDashboard';

  // ── Donation ───────────────────────────────────────────────────────────────
  static const String createDonation = 'createDonation';
  static const String myDonations = 'myDonations';
  static const String donationDetails = 'donationDetails';
  static const String donationTitle = 'donationTitle';
  static const String donationDescription = 'donationDescription';
  static const String quantity = 'quantity';
  static const String unit = 'unit';
  static const String foodType = 'foodType';
  static const String preparedAt = 'preparedAt';
  static const String expiresAt = 'expiresAt';
  static const String availableFrom = 'availableFrom';
  static const String availableUntil = 'availableUntil';
  static const String pickupAddress = 'pickupAddress';
  static const String contactPhone = 'contactPhone';
  static const String estimatedMeals = 'estimatedMeals';
  static const String estimatedPeople = 'estimatedPeople';
  static const String allergens = 'allergens';
  static const String handlingInstructions = 'handlingInstructions';
  static const String storageInstructions = 'storageInstructions';
  static const String requiresRefrigeration = 'requiresRefrigeration';
  static const String isVegetarian = 'isVegetarian';
  static const String isVegan = 'isVegan';
  static const String isHalal = 'isHalal';
  static const String isUrgent = 'isUrgent';

  // ── Food Safety (SAFETY-CRITICAL — translations must be reviewed by a
  //    qualified food-safety expert before deployment) ────────────────────────
  static const String foodSafetyLevel = 'foodSafetyLevel';
  static const String safetyHigh = 'safetyHigh';
  static const String safetyMedium = 'safetyMedium';
  static const String safetyLow = 'safetyLow';
  static const String safetyCritical = 'safetyCritical';
  static const String expiryWarning = 'expiryWarning';
  static const String foodExpired = 'foodExpired';
  static const String allergenWarning = 'allergenWarning';
  static const String refrigerationRequired = 'refrigerationRequired';
  static const String foodSafetyWarning = 'foodSafetyWarning';
  static const String doNotConsume = 'doNotConsume';
  static const String checkBeforeEating = 'checkBeforeEating';
  static const String temperatureBreached = 'temperatureBreached';
  static const String crossContaminationRisk = 'crossContaminationRisk';

  // ── Donation Status ────────────────────────────────────────────────────────
  static const String donationStatus = 'donationStatus';
  static const String statusPending = 'statusPending';
  static const String statusApproved = 'statusApproved';
  static const String statusPickedUp = 'statusPickedUp';
  static const String statusDelivered = 'statusDelivered';
  static const String statusExpired = 'statusExpired';
  static const String statusCancelled = 'statusCancelled';
  static const String statusActive = 'statusActive';
  static const String statusInactive = 'statusInactive';
  static const String statusVerified = 'statusVerified';
  static const String statusRejected = 'statusRejected';
  static const String statusMatched = 'statusMatched';
  static const String statusInTransit = 'statusInTransit';

  // ── NGO ────────────────────────────────────────────────────────────────────
  static const String availableDonations = 'availableDonations';
  static const String createRequest = 'createRequest';
  static const String foodRequest = 'foodRequest';
  static const String myRequests = 'myRequests';
  static const String requestTitle = 'requestTitle';
  static const String requestDescription = 'requestDescription';
  static const String quantityNeeded = 'quantityNeeded';
  static const String urgencyLevel = 'urgencyLevel';
  static const String urgencyLow = 'urgencyLow';
  static const String urgencyMedium = 'urgencyMedium';
  static const String urgencyHigh = 'urgencyHigh';
  static const String urgencyCritical = 'urgencyCritical';
  static const String beneficiariesCount = 'beneficiariesCount';
  static const String acceptDonation = 'acceptDonation';
  static const String rejectDonation = 'rejectDonation';
  static const String pendingRequests = 'pendingRequests';
  static const String ngoName = 'ngoName';
  static const String rejectReason = 'rejectReason';
  static const String clarifyRequest = 'clarifyRequest';
  static const String inspectDelivery = 'inspectDelivery';

  // ── Volunteer ──────────────────────────────────────────────────────────────
  static const String myTasks = 'myTasks';
  static const String acceptTask = 'acceptTask';
  static const String rejectTask = 'rejectTask';
  static const String taskComplete = 'taskComplete';
  static const String pickupLocation = 'pickupLocation';
  static const String deliveryLocation = 'deliveryLocation';
  static const String estimatedDistance = 'estimatedDistance';
  static const String assignedTask = 'assignedTask';
  static const String taskStatus = 'taskStatus';
  static const String deliveryCoordination = 'deliveryCoordination';
  static const String reportIssue = 'reportIssue';
  static const String issueTitle = 'issueTitle';
  static const String issueDescription = 'issueDescription';

  // ── Admin ──────────────────────────────────────────────────────────────────
  static const String userManagement = 'userManagement';
  static const String verifyUser = 'verifyUser';
  static const String pendingVerification = 'pendingVerification';
  static const String systemStatus = 'systemStatus';
  static const String analytics = 'analytics';
  static const String auditLog = 'auditLog';
  static const String reportsTitle = 'reportsTitle';
  static const String impactReports = 'impactReports';
  static const String totalDonations = 'totalDonations';
  static const String totalDeliveries = 'totalDeliveries';
  static const String mealsProvided = 'mealsProvided';
  static const String wasteReduced = 'wasteReduced';
  static const String activeUsers = 'activeUsers';

  // ── Language / Settings ────────────────────────────────────────────────────
  static const String language = 'language';
  static const String languageEnglish = 'languageEnglish';
  static const String languageHindi = 'languageHindi';  static const String languageTamil = 'languageTamil';  static const String changeLanguage = 'changeLanguage';
  static const String preferredLanguage = 'preferredLanguage';
  static const String settingsTitle = 'settingsTitle';
  static const String darkMode = 'darkMode';
  static const String lightMode = 'lightMode';
  static const String themeSettings = 'themeSettings';
  static const String appearanceSettings = 'appearanceSettings';

  // ── Errors ─────────────────────────────────────────────────────────────────
  static const String networkError = 'networkError';
  static const String serverError = 'serverError';
  static const String unknownError = 'unknownError';
  static const String sessionExpired = 'sessionExpired';
  static const String permissionDenied = 'permissionDenied';
  static const String locationPermissionRequired = 'locationPermissionRequired';
  static const String cameraPermissionRequired = 'cameraPermissionRequired';

  // ── Documents / Verification ───────────────────────────────────────────────
  static const String documentUpload = 'documentUpload';
  static const String documentVerification = 'documentVerification';
  static const String verificationPending = 'verificationPending';
  static const String verificationApproved = 'verificationApproved';
  static const String verificationRejected = 'verificationRejected';

  // ── Onboarding ─────────────────────────────────────────────────────────────
  static const String onboardingTitle1 = 'onboardingTitle1';
  static const String onboardingBody1 = 'onboardingBody1';
  static const String onboardingTitle2 = 'onboardingTitle2';
  static const String onboardingBody2 = 'onboardingBody2';
  static const String onboardingTitle3 = 'onboardingTitle3';
  static const String onboardingBody3 = 'onboardingBody3';
  static const String getStarted = 'getStarted';
  static const String skip = 'skip';

  // ── Form Fields ────────────────────────────────────────────────────────────
  static const String name = 'name';
  static const String fullName = 'fullName';
  static const String phoneNumber = 'phoneNumber';
  static const String address = 'address';
  static const String city = 'city';
  static const String state = 'state';
  static const String pincode = 'pincode';
  static const String latitude = 'latitude';
  static const String longitude = 'longitude';
  static const String useCurrentLocation = 'useCurrentLocation';
  static const String organizationType = 'organizationType';
  static const String registrationNumber = 'registrationNumber';
  static const String website = 'website';
  static const String socialMedia = 'socialMedia';
  static const String category = 'category';
  static const String tags = 'tags';
  static const String notes = 'notes';
  static const String date = 'date';
  static const String time = 'time';
  static const String dateTime = 'dateTime';
  static const String selectDate = 'selectDate';
  static const String selectTime = 'selectTime';

  // ── Logistics / Tracking ───────────────────────────────────────────────────
  static const String realTimeTracking = 'realTimeTracking';
  static const String liveLocation = 'liveLocation';
  static const String trackDelivery = 'trackDelivery';
  static const String dispatchOrder = 'dispatchOrder';
  static const String logisticsManagement = 'logisticsManagement';
  static const String matchingAlgorithm = 'matchingAlgorithm';
  static const String matchScore = 'matchScore';
  static const String distance = 'distance';
  static const String estimatedArrival = 'estimatedArrival';

  // ── Dialogs / Feedback ─────────────────────────────────────────────────────
  static const String confirmLogout = 'confirmLogout';
  static const String confirmDelete = 'confirmDelete';
  static const String savedSuccessfully = 'savedSuccessfully';
  static const String deletedSuccessfully = 'deletedSuccessfully';
  static const String submittedSuccessfully = 'submittedSuccessfully';
  static const String donationCreatedSuccess = 'donationCreatedSuccess';
  static const String requestCreatedSuccess = 'requestCreatedSuccess';
  static const String userVerifiedSuccess = 'userVerifiedSuccess';
  static const String loginSuccessful = 'loginSuccessful';
  static const String logoutSuccessful = 'logoutSuccessful';
  static const String registrationSuccessful = 'registrationSuccessful';

  // ── Supported locales (single source of truth for the app) ─────────────────
  /// All locales the app officially supports.
  static const List<String> supportedLocaleCodes = ['en', 'hi', 'ta'];

  /// The fallback locale used when a key is missing in the active locale.
  static const String fallbackLocaleCode = 'en';
}
