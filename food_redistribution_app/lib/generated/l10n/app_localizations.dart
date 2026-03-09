import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_hi.dart';
import 'app_localizations_ta.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('hi'),
    Locale('ta')
  ];

  /// Application name
  ///
  /// In en, this message translates to:
  /// **'Food Redistribution Platform'**
  String get appName;

  /// App tagline shown on welcome screen
  ///
  /// In en, this message translates to:
  /// **'Reducing food waste, feeding communities'**
  String get appTagline;

  /// Coming soon label
  ///
  /// In en, this message translates to:
  /// **'Coming Soon'**
  String get comingSoon;

  /// Operational status
  ///
  /// In en, this message translates to:
  /// **'Operational'**
  String get operational;

  /// Generic save action
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// Generic cancel action
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// Generic submit action
  ///
  /// In en, this message translates to:
  /// **'Submit'**
  String get submit;

  /// Generic delete action
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// Generic edit action
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// Navigate back
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// Navigate next
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// Done action
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// Acknowledge
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// Confirm action
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// Loading indicator text
  ///
  /// In en, this message translates to:
  /// **'Loading…'**
  String get loading;

  /// Generic error label
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get error;

  /// Generic success label
  ///
  /// In en, this message translates to:
  /// **'Success'**
  String get success;

  /// Retry action
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// Close dialog or screen
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// Search action
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// Filter action
  ///
  /// In en, this message translates to:
  /// **'Filter'**
  String get filter;

  /// Show all items
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get all;

  /// Affirmative response
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get yes;

  /// Negative response
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get no;

  /// View action
  ///
  /// In en, this message translates to:
  /// **'View'**
  String get view;

  /// Refresh action
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get refresh;

  /// Shown when no data to display
  ///
  /// In en, this message translates to:
  /// **'No data available'**
  String get noDataAvailable;

  /// See all items
  ///
  /// In en, this message translates to:
  /// **'See All'**
  String get seeAll;

  /// View all items
  ///
  /// In en, this message translates to:
  /// **'View All'**
  String get viewAll;

  /// Field is required
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get required;

  /// Field is optional
  ///
  /// In en, this message translates to:
  /// **'Optional'**
  String get optional;

  /// Total label
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get total;

  /// Active status
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get active;

  /// Unknown status
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get unknown;

  /// Details label
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get details;

  /// Description label
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get description;

  /// Title label
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get title;

  /// Type label
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get type;

  /// Urgent flag
  ///
  /// In en, this message translates to:
  /// **'URGENT'**
  String get urgent;

  /// Processing indicator
  ///
  /// In en, this message translates to:
  /// **'Processing…'**
  String get processing;

  /// Submitting indicator
  ///
  /// In en, this message translates to:
  /// **'Submitting…'**
  String get submitting;

  /// Updating indicator
  ///
  /// In en, this message translates to:
  /// **'Updating…'**
  String get updating;

  /// Creating indicator
  ///
  /// In en, this message translates to:
  /// **'Creating…'**
  String get creating;

  /// Sending indicator
  ///
  /// In en, this message translates to:
  /// **'Sending…'**
  String get sending;

  /// Rejecting indicator
  ///
  /// In en, this message translates to:
  /// **'Rejecting…'**
  String get rejecting;

  /// Time: just now
  ///
  /// In en, this message translates to:
  /// **'Just now'**
  String get justNow;

  /// Time: never
  ///
  /// In en, this message translates to:
  /// **'Never'**
  String get never;

  /// Status: accepted
  ///
  /// In en, this message translates to:
  /// **'Accepted'**
  String get accepted;

  /// Status: approved
  ///
  /// In en, this message translates to:
  /// **'Approved'**
  String get approved;

  /// Status: rejected
  ///
  /// In en, this message translates to:
  /// **'Rejected'**
  String get rejected;

  /// Sign in button
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get signIn;

  /// Sign out button
  ///
  /// In en, this message translates to:
  /// **'Sign Out'**
  String get signOut;

  /// Sign up button
  ///
  /// In en, this message translates to:
  /// **'Sign Up'**
  String get signUp;

  /// Register action
  ///
  /// In en, this message translates to:
  /// **'Register'**
  String get register;

  /// Email label
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// Password label
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// Confirm password label
  ///
  /// In en, this message translates to:
  /// **'Confirm Password'**
  String get confirmPassword;

  /// Forgot password link
  ///
  /// In en, this message translates to:
  /// **'Forgot Password?'**
  String get forgotPassword;

  /// Reset password action
  ///
  /// In en, this message translates to:
  /// **'Reset Password'**
  String get resetPassword;

  /// Change password action
  ///
  /// In en, this message translates to:
  /// **'Change Password'**
  String get changePassword;

  /// Title on the login screen
  ///
  /// In en, this message translates to:
  /// **'Welcome Back'**
  String get loginTitle;

  /// Subtitle on login screen
  ///
  /// In en, this message translates to:
  /// **'Sign in to continue making a difference'**
  String get loginSubtitle;

  /// Shown to existing users on register screen
  ///
  /// In en, this message translates to:
  /// **'Already have an account? Sign in'**
  String get alreadyHaveAccount;

  /// Shown to new users on login screen
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account? Sign up'**
  String get dontHaveAccount;

  /// Email verification screen title
  ///
  /// In en, this message translates to:
  /// **'Verify Your Email'**
  String get emailVerificationTitle;

  /// Email verification instruction
  ///
  /// In en, this message translates to:
  /// **'A verification link has been sent to {email}. Please check your inbox.'**
  String emailVerificationBody(String email);

  /// Resend verification email button
  ///
  /// In en, this message translates to:
  /// **'Resend Verification Email'**
  String get resendVerification;

  /// OTP screen title
  ///
  /// In en, this message translates to:
  /// **'Enter OTP'**
  String get otpTitle;

  /// OTP subtitle
  ///
  /// In en, this message translates to:
  /// **'Enter the 6-digit code sent to {phone}'**
  String otpSubtitle(String phone);

  /// Validation: email required
  ///
  /// In en, this message translates to:
  /// **'Email is required'**
  String get emailRequired;

  /// Validation: password required
  ///
  /// In en, this message translates to:
  /// **'Password is required'**
  String get passwordRequired;

  /// Validation: invalid email
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid email address'**
  String get invalidEmail;

  /// Validation: password too short
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 8 characters'**
  String get passwordTooShort;

  /// Validation: passwords must match
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get passwordsMustMatch;

  /// Validation: field required
  ///
  /// In en, this message translates to:
  /// **'This field is required'**
  String get fieldRequired;

  /// Validation: invalid input
  ///
  /// In en, this message translates to:
  /// **'Invalid input'**
  String get invalidInput;

  /// Donor role label
  ///
  /// In en, this message translates to:
  /// **'Donor'**
  String get roleDonor;

  /// NGO role label
  ///
  /// In en, this message translates to:
  /// **'NGO'**
  String get roleNgo;

  /// Volunteer role label
  ///
  /// In en, this message translates to:
  /// **'Volunteer'**
  String get roleVolunteer;

  /// Admin role label
  ///
  /// In en, this message translates to:
  /// **'Admin'**
  String get roleAdmin;

  /// Role selection screen title
  ///
  /// In en, this message translates to:
  /// **'Select Your Role'**
  String get selectRole;

  /// Description of the donor role
  ///
  /// In en, this message translates to:
  /// **'Share your surplus food with those in need'**
  String get donorRoleDescription;

  /// Description of the NGO role
  ///
  /// In en, this message translates to:
  /// **'Connect with donors and distribute food to beneficiaries'**
  String get ngoRoleDescription;

  /// Description of the volunteer role
  ///
  /// In en, this message translates to:
  /// **'Help with food pickup and delivery logistics'**
  String get volunteerRoleDescription;

  /// Dashboard navigation label
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get dashboard;

  /// Profile navigation label
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// Notifications navigation label
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// Settings navigation label
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// Logout action
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// Donor dashboard title
  ///
  /// In en, this message translates to:
  /// **'Donor Dashboard'**
  String get donorDashboard;

  /// NGO dashboard title
  ///
  /// In en, this message translates to:
  /// **'NGO Dashboard'**
  String get ngoDashboard;

  /// Volunteer dashboard title
  ///
  /// In en, this message translates to:
  /// **'Volunteer Dashboard'**
  String get volunteerDashboard;

  /// Admin dashboard title
  ///
  /// In en, this message translates to:
  /// **'Admin Dashboard'**
  String get adminDashboard;

  /// Create donation action/title
  ///
  /// In en, this message translates to:
  /// **'Create Donation'**
  String get createDonation;

  /// List of my donations
  ///
  /// In en, this message translates to:
  /// **'My Donations'**
  String get myDonations;

  /// Donation details screen title
  ///
  /// In en, this message translates to:
  /// **'Donation Details'**
  String get donationDetails;

  /// Label for donation title field
  ///
  /// In en, this message translates to:
  /// **'Donation Title'**
  String get donationTitle;

  /// Label for donation description field
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get donationDescription;

  /// Label for quantity field
  ///
  /// In en, this message translates to:
  /// **'Quantity'**
  String get quantity;

  /// Label for unit field (e.g. servings, kg)
  ///
  /// In en, this message translates to:
  /// **'Unit'**
  String get unit;

  /// Label for food type field
  ///
  /// In en, this message translates to:
  /// **'Food Type'**
  String get foodType;

  /// Date/time food was prepared
  ///
  /// In en, this message translates to:
  /// **'Prepared At'**
  String get preparedAt;

  /// Date/time food expires — safety-critical
  ///
  /// In en, this message translates to:
  /// **'Expires At'**
  String get expiresAt;

  /// When food is available for pickup
  ///
  /// In en, this message translates to:
  /// **'Available From'**
  String get availableFrom;

  /// When food availability ends
  ///
  /// In en, this message translates to:
  /// **'Available Until'**
  String get availableUntil;

  /// Label for pickup address field
  ///
  /// In en, this message translates to:
  /// **'Pickup Address'**
  String get pickupAddress;

  /// Label for contact phone field
  ///
  /// In en, this message translates to:
  /// **'Contact Phone'**
  String get contactPhone;

  /// Number of estimated meals
  ///
  /// In en, this message translates to:
  /// **'Estimated Meals'**
  String get estimatedMeals;

  /// Estimated number of people served
  ///
  /// In en, this message translates to:
  /// **'Estimated People'**
  String get estimatedPeople;

  /// Allergen information — safety-critical
  ///
  /// In en, this message translates to:
  /// **'Allergens'**
  String get allergens;

  /// Food handling instructions — safety-critical
  ///
  /// In en, this message translates to:
  /// **'Handling Instructions'**
  String get handlingInstructions;

  /// Food storage instructions — safety-critical
  ///
  /// In en, this message translates to:
  /// **'Storage Instructions'**
  String get storageInstructions;

  /// Flag: food requires refrigeration — safety-critical
  ///
  /// In en, this message translates to:
  /// **'Requires Refrigeration'**
  String get requiresRefrigeration;

  /// Flag: food is vegetarian
  ///
  /// In en, this message translates to:
  /// **'Vegetarian'**
  String get isVegetarian;

  /// Flag: food is vegan
  ///
  /// In en, this message translates to:
  /// **'Vegan'**
  String get isVegan;

  /// Flag: food is halal certified
  ///
  /// In en, this message translates to:
  /// **'Halal'**
  String get isHalal;

  /// Flag: donation is urgent
  ///
  /// In en, this message translates to:
  /// **'Urgent'**
  String get isUrgent;

  /// Safety classification of food — SAFETY-CRITICAL
  ///
  /// In en, this message translates to:
  /// **'Food Safety Level'**
  String get foodSafetyLevel;

  /// High food safety level — SAFETY-CRITICAL
  ///
  /// In en, this message translates to:
  /// **'High — Freshly prepared, safe for all'**
  String get safetyHigh;

  /// Medium food safety level — SAFETY-CRITICAL
  ///
  /// In en, this message translates to:
  /// **'Medium — Prepared earlier, handle with care'**
  String get safetyMedium;

  /// Low food safety level — SAFETY-CRITICAL
  ///
  /// In en, this message translates to:
  /// **'Low — Near expiry, consume promptly'**
  String get safetyLow;

  /// Critical food safety level — SAFETY-CRITICAL
  ///
  /// In en, this message translates to:
  /// **'Critical — Immediate action required'**
  String get safetyCritical;

  /// Expiry warning — SAFETY-CRITICAL
  ///
  /// In en, this message translates to:
  /// **'Warning: This item expires in {hours} hour(s)'**
  String expiryWarning(int hours);

  /// Food has expired — SAFETY-CRITICAL
  ///
  /// In en, this message translates to:
  /// **'EXPIRED — Do not distribute'**
  String get foodExpired;

  /// Allergen alert — SAFETY-CRITICAL
  ///
  /// In en, this message translates to:
  /// **'Allergen Alert: Contains {allergens}'**
  String allergenWarning(String allergens);

  /// Refrigeration required warning — SAFETY-CRITICAL
  ///
  /// In en, this message translates to:
  /// **'⚠ Refrigeration Required — Keep below 4°C'**
  String get refrigerationRequired;

  /// General food safety warning header — SAFETY-CRITICAL
  ///
  /// In en, this message translates to:
  /// **'Food Safety Warning'**
  String get foodSafetyWarning;

  /// Strong warning not to consume — SAFETY-CRITICAL
  ///
  /// In en, this message translates to:
  /// **'DO NOT CONSUME — Food safety concern'**
  String get doNotConsume;

  /// Inspection reminder — SAFETY-CRITICAL
  ///
  /// In en, this message translates to:
  /// **'Please inspect food condition before distribution'**
  String get checkBeforeEating;

  /// Temperature breach warning — SAFETY-CRITICAL
  ///
  /// In en, this message translates to:
  /// **'Temperature safety threshold breached'**
  String get temperatureBreached;

  /// Cross-contamination warning — SAFETY-CRITICAL
  ///
  /// In en, this message translates to:
  /// **'Risk of cross-contamination detected'**
  String get crossContaminationRisk;

  /// Donation status label
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get donationStatus;

  /// Status: pending
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get statusPending;

  /// Status: approved
  ///
  /// In en, this message translates to:
  /// **'Approved'**
  String get statusApproved;

  /// Status: picked up
  ///
  /// In en, this message translates to:
  /// **'Picked Up'**
  String get statusPickedUp;

  /// Status: delivered
  ///
  /// In en, this message translates to:
  /// **'Delivered'**
  String get statusDelivered;

  /// Status: expired
  ///
  /// In en, this message translates to:
  /// **'Expired'**
  String get statusExpired;

  /// Status: cancelled
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get statusCancelled;

  /// Status: active
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get statusActive;

  /// Status: inactive
  ///
  /// In en, this message translates to:
  /// **'Inactive'**
  String get statusInactive;

  /// Status: verified
  ///
  /// In en, this message translates to:
  /// **'Verified'**
  String get statusVerified;

  /// Status: rejected
  ///
  /// In en, this message translates to:
  /// **'Rejected'**
  String get statusRejected;

  /// Status: matched to a recipient
  ///
  /// In en, this message translates to:
  /// **'Matched'**
  String get statusMatched;

  /// Status: in transit
  ///
  /// In en, this message translates to:
  /// **'In Transit'**
  String get statusInTransit;

  /// NGO screen: available donations title
  ///
  /// In en, this message translates to:
  /// **'Available Donations'**
  String get availableDonations;

  /// Create food request action
  ///
  /// In en, this message translates to:
  /// **'Create Request'**
  String get createRequest;

  /// Food request label
  ///
  /// In en, this message translates to:
  /// **'Food Request'**
  String get foodRequest;

  /// List of my food requests
  ///
  /// In en, this message translates to:
  /// **'My Requests'**
  String get myRequests;

  /// Label for request title field
  ///
  /// In en, this message translates to:
  /// **'Request Title'**
  String get requestTitle;

  /// Label for request description field
  ///
  /// In en, this message translates to:
  /// **'Request Description'**
  String get requestDescription;

  /// Label for quantity needed field
  ///
  /// In en, this message translates to:
  /// **'Quantity Needed'**
  String get quantityNeeded;

  /// Label for urgency level
  ///
  /// In en, this message translates to:
  /// **'Urgency Level'**
  String get urgencyLevel;

  /// Urgency: low
  ///
  /// In en, this message translates to:
  /// **'Low'**
  String get urgencyLow;

  /// Urgency: medium
  ///
  /// In en, this message translates to:
  /// **'Medium'**
  String get urgencyMedium;

  /// Urgency: high
  ///
  /// In en, this message translates to:
  /// **'High'**
  String get urgencyHigh;

  /// Urgency: critical
  ///
  /// In en, this message translates to:
  /// **'Critical'**
  String get urgencyCritical;

  /// Label for beneficiaries count
  ///
  /// In en, this message translates to:
  /// **'Number of Beneficiaries'**
  String get beneficiariesCount;

  /// Accept donation action
  ///
  /// In en, this message translates to:
  /// **'Accept Donation'**
  String get acceptDonation;

  /// Reject donation action
  ///
  /// In en, this message translates to:
  /// **'Reject Donation'**
  String get rejectDonation;

  /// List of pending requests
  ///
  /// In en, this message translates to:
  /// **'Pending Requests'**
  String get pendingRequests;

  /// NGO/org name label
  ///
  /// In en, this message translates to:
  /// **'Organization Name'**
  String get ngoName;

  /// Label for rejection reason
  ///
  /// In en, this message translates to:
  /// **'Reason for Rejection'**
  String get rejectReason;

  /// Action to request clarification
  ///
  /// In en, this message translates to:
  /// **'Clarify Request'**
  String get clarifyRequest;

  /// Inspect delivery action
  ///
  /// In en, this message translates to:
  /// **'Inspect Delivery'**
  String get inspectDelivery;

  /// Volunteer: list of my tasks
  ///
  /// In en, this message translates to:
  /// **'My Tasks'**
  String get myTasks;

  /// Accept a volunteer task
  ///
  /// In en, this message translates to:
  /// **'Accept Task'**
  String get acceptTask;

  /// Decline a volunteer task
  ///
  /// In en, this message translates to:
  /// **'Decline Task'**
  String get rejectTask;

  /// Mark task as complete action
  ///
  /// In en, this message translates to:
  /// **'Mark as Complete'**
  String get taskComplete;

  /// Pickup location label
  ///
  /// In en, this message translates to:
  /// **'Pickup Location'**
  String get pickupLocation;

  /// Delivery location label
  ///
  /// In en, this message translates to:
  /// **'Delivery Location'**
  String get deliveryLocation;

  /// Estimated distance label
  ///
  /// In en, this message translates to:
  /// **'Estimated Distance'**
  String get estimatedDistance;

  /// Assigned task label
  ///
  /// In en, this message translates to:
  /// **'Assigned Task'**
  String get assignedTask;

  /// Task status label
  ///
  /// In en, this message translates to:
  /// **'Task Status'**
  String get taskStatus;

  /// Delivery coordination screen title
  ///
  /// In en, this message translates to:
  /// **'Delivery Coordination'**
  String get deliveryCoordination;

  /// Report issue action
  ///
  /// In en, this message translates to:
  /// **'Report Issue'**
  String get reportIssue;

  /// Label for issue title field
  ///
  /// In en, this message translates to:
  /// **'Issue Title'**
  String get issueTitle;

  /// Label for issue description field
  ///
  /// In en, this message translates to:
  /// **'Issue Description'**
  String get issueDescription;

  /// Admin: user management title
  ///
  /// In en, this message translates to:
  /// **'User Management'**
  String get userManagement;

  /// Admin: verify user action
  ///
  /// In en, this message translates to:
  /// **'Verify User'**
  String get verifyUser;

  /// Users pending verification
  ///
  /// In en, this message translates to:
  /// **'Pending Verification'**
  String get pendingVerification;

  /// Admin: system status title
  ///
  /// In en, this message translates to:
  /// **'System Status'**
  String get systemStatus;

  /// Analytics screen title
  ///
  /// In en, this message translates to:
  /// **'Analytics'**
  String get analytics;

  /// Audit log label
  ///
  /// In en, this message translates to:
  /// **'Audit Log'**
  String get auditLog;

  /// Reports screen title
  ///
  /// In en, this message translates to:
  /// **'Reports'**
  String get reportsTitle;

  /// Donor impact reports title
  ///
  /// In en, this message translates to:
  /// **'Impact Reports'**
  String get impactReports;

  /// Stat: total donations
  ///
  /// In en, this message translates to:
  /// **'Total Donations'**
  String get totalDonations;

  /// Stat: total deliveries
  ///
  /// In en, this message translates to:
  /// **'Total Deliveries'**
  String get totalDeliveries;

  /// Stat: meals provided
  ///
  /// In en, this message translates to:
  /// **'Meals Provided'**
  String get mealsProvided;

  /// Stat: waste reduced
  ///
  /// In en, this message translates to:
  /// **'Waste Reduced'**
  String get wasteReduced;

  /// Stat: active users
  ///
  /// In en, this message translates to:
  /// **'Active Users'**
  String get activeUsers;

  /// Language setting label
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// English language option
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// Hindi language option
  ///
  /// In en, this message translates to:
  /// **'हिन्दी (Hindi)'**
  String get languageHindi;

  /// Tamil language option
  ///
  /// In en, this message translates to:
  /// **'தமிழ் (Tamil)'**
  String get languageTamil;

  /// Change language action
  ///
  /// In en, this message translates to:
  /// **'Change Language'**
  String get changeLanguage;

  /// Preferred language setting
  ///
  /// In en, this message translates to:
  /// **'Preferred Language'**
  String get preferredLanguage;

  /// Settings screen title
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// Dark mode toggle label
  ///
  /// In en, this message translates to:
  /// **'Dark Mode'**
  String get darkMode;

  /// Light mode toggle label
  ///
  /// In en, this message translates to:
  /// **'Light Mode'**
  String get lightMode;

  /// Theme settings section
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get themeSettings;

  /// Appearance settings section
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearanceSettings;

  /// Error: network connectivity
  ///
  /// In en, this message translates to:
  /// **'Network error. Please check your connection.'**
  String get networkError;

  /// Error: server error
  ///
  /// In en, this message translates to:
  /// **'Server error. Please try again later.'**
  String get serverError;

  /// Error: unknown
  ///
  /// In en, this message translates to:
  /// **'An unexpected error occurred. Please try again.'**
  String get unknownError;

  /// Error: session expired
  ///
  /// In en, this message translates to:
  /// **'Your session has expired. Please sign in again.'**
  String get sessionExpired;

  /// Error: permission denied
  ///
  /// In en, this message translates to:
  /// **'You do not have permission to perform this action.'**
  String get permissionDenied;

  /// Error: location permission required
  ///
  /// In en, this message translates to:
  /// **'Location permission is required for this feature.'**
  String get locationPermissionRequired;

  /// Error: camera permission required
  ///
  /// In en, this message translates to:
  /// **'Camera permission is required to upload photos.'**
  String get cameraPermissionRequired;

  /// Upload document action
  ///
  /// In en, this message translates to:
  /// **'Upload Document'**
  String get documentUpload;

  /// Document verification screen title
  ///
  /// In en, this message translates to:
  /// **'Document Verification'**
  String get documentVerification;

  /// Verification pending status message
  ///
  /// In en, this message translates to:
  /// **'Verification Pending'**
  String get verificationPending;

  /// Verification approved message
  ///
  /// In en, this message translates to:
  /// **'Verification Approved'**
  String get verificationApproved;

  /// Verification rejected message
  ///
  /// In en, this message translates to:
  /// **'Verification Rejected'**
  String get verificationRejected;

  /// Onboarding slide 1 title
  ///
  /// In en, this message translates to:
  /// **'Reduce Food Waste'**
  String get onboardingTitle1;

  /// Onboarding slide 1 body
  ///
  /// In en, this message translates to:
  /// **'Connect surplus food with communities that need it most.'**
  String get onboardingBody1;

  /// Onboarding slide 2 title
  ///
  /// In en, this message translates to:
  /// **'Real-Time Coordination'**
  String get onboardingTitle2;

  /// Onboarding slide 2 body
  ///
  /// In en, this message translates to:
  /// **'Track donations and deliveries in real time.'**
  String get onboardingBody2;

  /// Onboarding slide 3 title
  ///
  /// In en, this message translates to:
  /// **'Make an Impact'**
  String get onboardingTitle3;

  /// Onboarding slide 3 body
  ///
  /// In en, this message translates to:
  /// **'Every donation feeds a family and saves the planet.'**
  String get onboardingBody3;

  /// Get started button
  ///
  /// In en, this message translates to:
  /// **'Get Started'**
  String get getStarted;

  /// Skip onboarding button
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get skip;

  /// Name label
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get name;

  /// Full name label
  ///
  /// In en, this message translates to:
  /// **'Full Name'**
  String get fullName;

  /// Phone number label
  ///
  /// In en, this message translates to:
  /// **'Phone Number'**
  String get phoneNumber;

  /// Address label
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get address;

  /// City label
  ///
  /// In en, this message translates to:
  /// **'City'**
  String get city;

  /// State/province label
  ///
  /// In en, this message translates to:
  /// **'State'**
  String get state;

  /// Postal/PIN code label
  ///
  /// In en, this message translates to:
  /// **'PIN Code'**
  String get pincode;

  /// Latitude label
  ///
  /// In en, this message translates to:
  /// **'Latitude'**
  String get latitude;

  /// Longitude label
  ///
  /// In en, this message translates to:
  /// **'Longitude'**
  String get longitude;

  /// Use GPS location button
  ///
  /// In en, this message translates to:
  /// **'Use Current Location'**
  String get useCurrentLocation;

  /// Type of organization
  ///
  /// In en, this message translates to:
  /// **'Organization Type'**
  String get organizationType;

  /// NGO/organization registration number
  ///
  /// In en, this message translates to:
  /// **'Registration Number'**
  String get registrationNumber;

  /// Website URL label
  ///
  /// In en, this message translates to:
  /// **'Website'**
  String get website;

  /// Social media label
  ///
  /// In en, this message translates to:
  /// **'Social Media'**
  String get socialMedia;

  /// Category label
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get category;

  /// Tags label
  ///
  /// In en, this message translates to:
  /// **'Tags'**
  String get tags;

  /// Notes label
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get notes;

  /// Date label
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get date;

  /// Time label
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get time;

  /// Date and time label
  ///
  /// In en, this message translates to:
  /// **'Date & Time'**
  String get dateTime;

  /// Select date action
  ///
  /// In en, this message translates to:
  /// **'Select Date'**
  String get selectDate;

  /// Select time action
  ///
  /// In en, this message translates to:
  /// **'Select Time'**
  String get selectTime;

  /// Real-time tracking screen title
  ///
  /// In en, this message translates to:
  /// **'Real-Time Tracking'**
  String get realTimeTracking;

  /// Live location label
  ///
  /// In en, this message translates to:
  /// **'Live Location'**
  String get liveLocation;

  /// Track delivery action
  ///
  /// In en, this message translates to:
  /// **'Track Delivery'**
  String get trackDelivery;

  /// Dispatch order action
  ///
  /// In en, this message translates to:
  /// **'Dispatch Order'**
  String get dispatchOrder;

  /// Logistics management screen title
  ///
  /// In en, this message translates to:
  /// **'Logistics Management'**
  String get logisticsManagement;

  /// Matching algorithm label
  ///
  /// In en, this message translates to:
  /// **'Matching'**
  String get matchingAlgorithm;

  /// Match score label
  ///
  /// In en, this message translates to:
  /// **'Match Score'**
  String get matchScore;

  /// Distance label
  ///
  /// In en, this message translates to:
  /// **'Distance'**
  String get distance;

  /// Estimated arrival time
  ///
  /// In en, this message translates to:
  /// **'Estimated Arrival'**
  String get estimatedArrival;

  /// Logout confirmation dialog body
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to sign out?'**
  String get confirmLogout;

  /// Delete confirmation dialog body
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this? This action cannot be undone.'**
  String get confirmDelete;

  /// Save success message
  ///
  /// In en, this message translates to:
  /// **'Saved successfully'**
  String get savedSuccessfully;

  /// Delete success message
  ///
  /// In en, this message translates to:
  /// **'Deleted successfully'**
  String get deletedSuccessfully;

  /// Submit success message
  ///
  /// In en, this message translates to:
  /// **'Submitted successfully'**
  String get submittedSuccessfully;

  /// Donation created success message
  ///
  /// In en, this message translates to:
  /// **'Donation created successfully'**
  String get donationCreatedSuccess;

  /// Request created success message
  ///
  /// In en, this message translates to:
  /// **'Request created successfully'**
  String get requestCreatedSuccess;

  /// User verified success message
  ///
  /// In en, this message translates to:
  /// **'User verified successfully'**
  String get userVerifiedSuccess;

  /// Login success message
  ///
  /// In en, this message translates to:
  /// **'Signed in successfully'**
  String get loginSuccessful;

  /// Logout success message
  ///
  /// In en, this message translates to:
  /// **'Signed out successfully'**
  String get logoutSuccessful;

  /// Registration success message
  ///
  /// In en, this message translates to:
  /// **'Account created successfully'**
  String get registrationSuccessful;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'hi', 'ta'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'hi':
      return AppLocalizationsHi();
    case 'ta':
      return AppLocalizationsTa();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
