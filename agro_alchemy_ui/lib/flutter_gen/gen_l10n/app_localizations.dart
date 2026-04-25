import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_hi.dart';
import 'app_localizations_mr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'gen_l10n/app_localizations.dart';
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
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

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
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('hi'),
    Locale('mr')
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'AgroAlchemy'**
  String get appTitle;

  /// No description provided for @login.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get login;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Log Out'**
  String get logout;

  /// No description provided for @dashboard.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get dashboard;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'My Profile'**
  String get profile;

  /// No description provided for @editProfile.
  ///
  /// In en, this message translates to:
  /// **'Edit Profile'**
  String get editProfile;

  /// No description provided for @saveProfile.
  ///
  /// In en, this message translates to:
  /// **'Save Profile'**
  String get saveProfile;

  /// No description provided for @personalInfo.
  ///
  /// In en, this message translates to:
  /// **'Personal Information'**
  String get personalInfo;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @phone.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get phone;

  /// No description provided for @annualRainfall.
  ///
  /// In en, this message translates to:
  /// **'Annual Rainfall (mm)'**
  String get annualRainfall;

  /// No description provided for @areaOfPlot.
  ///
  /// In en, this message translates to:
  /// **'Area of Plot (sq.m)'**
  String get areaOfPlot;

  /// No description provided for @state.
  ///
  /// In en, this message translates to:
  /// **'State'**
  String get state;

  /// No description provided for @city.
  ///
  /// In en, this message translates to:
  /// **'City'**
  String get city;

  /// No description provided for @fertilizerPrediction.
  ///
  /// In en, this message translates to:
  /// **'Fertilizer Prediction'**
  String get fertilizerPrediction;

  /// No description provided for @pestManagement.
  ///
  /// In en, this message translates to:
  /// **'Pest Management'**
  String get pestManagement;

  /// No description provided for @cropHealth.
  ///
  /// In en, this message translates to:
  /// **'Crop Health Analysis'**
  String get cropHealth;

  /// No description provided for @cropHistory.
  ///
  /// In en, this message translates to:
  /// **'Crop History'**
  String get cropHistory;

  /// No description provided for @aboutHelp.
  ///
  /// In en, this message translates to:
  /// **'About & Help'**
  String get aboutHelp;

  /// No description provided for @chatbot.
  ///
  /// In en, this message translates to:
  /// **'Chatbot'**
  String get chatbot;

  /// No description provided for @review.
  ///
  /// In en, this message translates to:
  /// **'Write a Review'**
  String get review;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'App Language'**
  String get language;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @hindi.
  ///
  /// In en, this message translates to:
  /// **'Hindi'**
  String get hindi;

  /// No description provided for @marathi.
  ///
  /// In en, this message translates to:
  /// **'Marathi'**
  String get marathi;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @loadingProfile.
  ///
  /// In en, this message translates to:
  /// **'Loading Profile...'**
  String get loadingProfile;

  /// No description provided for @updateProfile.
  ///
  /// In en, this message translates to:
  /// **'Update Your Profile'**
  String get updateProfile;

  /// No description provided for @errorLoadingProfile.
  ///
  /// In en, this message translates to:
  /// **'Error loading profile'**
  String get errorLoadingProfile;

  /// No description provided for @profileUpdated.
  ///
  /// In en, this message translates to:
  /// **'Profile updated successfully'**
  String get profileUpdated;

  /// No description provided for @nameRequired.
  ///
  /// In en, this message translates to:
  /// **'Name is required'**
  String get nameRequired;

  /// No description provided for @yourBasicProfileDetails.
  ///
  /// In en, this message translates to:
  /// **'Your basic profile details'**
  String get yourBasicProfileDetails;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @name.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get name;

  /// No description provided for @notSet.
  ///
  /// In en, this message translates to:
  /// **'Not Set'**
  String get notSet;

  /// No description provided for @aboutUs.
  ///
  /// In en, this message translates to:
  /// **'About Us'**
  String get aboutUs;

  /// No description provided for @aboutUsDescription.
  ///
  /// In en, this message translates to:
  /// **'AgriAssist is an AI-powered agriculture advisory platform designed to empower farmers with intelligent tools and insights. Our core features include:\n\n• Crop Health Analysis: Detect and monitor crop conditions using advanced imaging and data analytics.\n• Fertilizer Prediction: Receive tailored fertilizer recommendations based on soil and crop data.\n• Pest Management: Identify and manage pest infestations effectively.\n• Crop History: Maintain records of past crops to inform future planting decisions.\n• Chatbot Assistance: Get instant answers to agricultural queries through our AI-driven chatbot.\n\nOur mission is to enhance agricultural productivity and sustainability by providing accessible and reliable technological solutions.'**
  String get aboutUsDescription;

  /// No description provided for @developmentTeam.
  ///
  /// In en, this message translates to:
  /// **'Development Team'**
  String get developmentTeam;

  /// No description provided for @teamMembers.
  ///
  /// In en, this message translates to:
  /// **'• Tejas (Group Leader): Backend & Machine Learning\n• Atharva: Backend & Machine Learning\n• Harshali: Backend & Machine Learning\n• Prisha: User Interface Design\n• Harsh: User Interface Design'**
  String get teamMembers;

  /// No description provided for @helpFaqs.
  ///
  /// In en, this message translates to:
  /// **'Help & FAQs'**
  String get helpFaqs;

  /// No description provided for @faqAnalyzeCropHealth.
  ///
  /// In en, this message translates to:
  /// **'How do I analyze crop health?'**
  String get faqAnalyzeCropHealth;

  /// No description provided for @faqAnalyzeCropHealthAnswer.
  ///
  /// In en, this message translates to:
  /// **'Navigate to the \'Crop Health Analysis\' section, input the required data, and receive a detailed health report of your crops.'**
  String get faqAnalyzeCropHealthAnswer;

  /// No description provided for @faqFertilizerRecommendations.
  ///
  /// In en, this message translates to:
  /// **'How can I get fertilizer recommendations?'**
  String get faqFertilizerRecommendations;

  /// No description provided for @faqFertilizerRecommendationsAnswer.
  ///
  /// In en, this message translates to:
  /// **'Go to the \'Fertilizer Prediction\' page, enter your soil and crop details, and obtain customized fertilizer suggestions.'**
  String get faqFertilizerRecommendationsAnswer;

  /// No description provided for @faqChatbotPurpose.
  ///
  /// In en, this message translates to:
  /// **'What is the purpose of the chatbot?'**
  String get faqChatbotPurpose;

  /// No description provided for @faqChatbotPurposeAnswer.
  ///
  /// In en, this message translates to:
  /// **'The chatbot provides instant answers to your agricultural questions, offering support and guidance whenever needed.'**
  String get faqChatbotPurposeAnswer;

  /// No description provided for @faqViewCropHistory.
  ///
  /// In en, this message translates to:
  /// **'How do I view my crop history?'**
  String get faqViewCropHistory;

  /// No description provided for @faqViewCropHistoryAnswer.
  ///
  /// In en, this message translates to:
  /// **'Access the \'Crop History\' section to review records of your past crops, aiding in informed decision-making for future planting.'**
  String get faqViewCropHistoryAnswer;

  /// No description provided for @faqContactSupport.
  ///
  /// In en, this message translates to:
  /// **'How do I contact support?'**
  String get faqContactSupport;

  /// No description provided for @faqContactSupportAnswer.
  ///
  /// In en, this message translates to:
  /// **'For assistance, email us at support@agriassist.com or call +91-1234567890.'**
  String get faqContactSupportAnswer;

  /// No description provided for @fertilizerHistoryTitle.
  ///
  /// In en, this message translates to:
  /// **'Fertilizer History'**
  String get fertilizerHistoryTitle;

  /// No description provided for @errorLoadingData.
  ///
  /// In en, this message translates to:
  /// **'Error loading data'**
  String get errorLoadingData;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @noFertilizerRecommendations.
  ///
  /// In en, this message translates to:
  /// **'No fertilizer recommendations found'**
  String get noFertilizerRecommendations;

  /// No description provided for @unknownCrop.
  ///
  /// In en, this message translates to:
  /// **'Unknown Crop'**
  String get unknownCrop;

  /// No description provided for @unknownLocation.
  ///
  /// In en, this message translates to:
  /// **'Unknown Location'**
  String get unknownLocation;

  /// No description provided for @fertilizerNA.
  ///
  /// In en, this message translates to:
  /// **'N/A'**
  String get fertilizerNA;

  /// No description provided for @nutrientNitrogen.
  ///
  /// In en, this message translates to:
  /// **'Nitrogen'**
  String get nutrientNitrogen;

  /// No description provided for @nutrientPhosphorus.
  ///
  /// In en, this message translates to:
  /// **'Phosphorus'**
  String get nutrientPhosphorus;

  /// No description provided for @nutrientPotassium.
  ///
  /// In en, this message translates to:
  /// **'Potassium'**
  String get nutrientPotassium;

  /// No description provided for @moreDetails.
  ///
  /// In en, this message translates to:
  /// **'More Details'**
  String get moreDetails;

  /// No description provided for @soilColor.
  ///
  /// In en, this message translates to:
  /// **'Soil Color'**
  String get soilColor;

  /// No description provided for @temperature.
  ///
  /// In en, this message translates to:
  /// **'Temperature'**
  String get temperature;

  /// No description provided for @ph.
  ///
  /// In en, this message translates to:
  /// **'pH'**
  String get ph;

  /// No description provided for @rainfall.
  ///
  /// In en, this message translates to:
  /// **'Rainfall'**
  String get rainfall;

  /// No description provided for @refresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get refresh;

  /// No description provided for @noUserLoggedIn.
  ///
  /// In en, this message translates to:
  /// **'No user logged in'**
  String get noUserLoggedIn;

  /// No description provided for @userDataNotFound.
  ///
  /// In en, this message translates to:
  /// **'User data not found'**
  String get userDataNotFound;

  /// No description provided for @errorLoadingUserData.
  ///
  /// In en, this message translates to:
  /// **'Error loading user data'**
  String get errorLoadingUserData;

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @myCrops.
  ///
  /// In en, this message translates to:
  /// **'My Crops'**
  String get myCrops;

  /// No description provided for @analytics.
  ///
  /// In en, this message translates to:
  /// **'Analytics'**
  String get analytics;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @helpSupport.
  ///
  /// In en, this message translates to:
  /// **'Help & Support'**
  String get helpSupport;

  /// No description provided for @loadingFarmData.
  ///
  /// In en, this message translates to:
  /// **'Loading your farm data...'**
  String get loadingFarmData;

  /// No description provided for @hello.
  ///
  /// In en, this message translates to:
  /// **'Hello!'**
  String get hello;

  /// No description provided for @farmer.
  ///
  /// In en, this message translates to:
  /// **'Farmer'**
  String get farmer;

  /// No description provided for @checkCrops.
  ///
  /// In en, this message translates to:
  /// **'Time to check on your crops!'**
  String get checkCrops;

  /// No description provided for @growthProgress.
  ///
  /// In en, this message translates to:
  /// **'Growth Progress'**
  String get growthProgress;

  /// No description provided for @num.
  ///
  /// In en, this message translates to:
  /// **'75%'**
  String get num;

  /// No description provided for @wheat.
  ///
  /// In en, this message translates to:
  /// **'Wheat'**
  String get wheat;

  /// No description provided for @rice.
  ///
  /// In en, this message translates to:
  /// **'Rice'**
  String get rice;

  /// No description provided for @profitLoss.
  ///
  /// In en, this message translates to:
  /// **'Profit / Loss'**
  String get profitLoss;

  /// No description provided for @alertsReminders.
  ///
  /// In en, this message translates to:
  /// **'Alerts & Reminders'**
  String get alertsReminders;

  /// No description provided for @reminder.
  ///
  /// In en, this message translates to:
  /// **'Reminder'**
  String get reminder;

  /// No description provided for @checkSoilMoisture.
  ///
  /// In en, this message translates to:
  /// **'Check soil moisture'**
  String get checkSoilMoisture;

  /// No description provided for @yieldPrediction.
  ///
  /// In en, this message translates to:
  /// **'Yield\nPrediction'**
  String get yieldPrediction;

  /// No description provided for @yieldPredictionTooltip.
  ///
  /// In en, this message translates to:
  /// **'Check crop yield predictions'**
  String get yieldPredictionTooltip;

  /// No description provided for @fertilizerPredictionH.
  ///
  /// In en, this message translates to:
  /// **'Fertilizer\nPrediction'**
  String get fertilizerPredictionH;

  /// No description provided for @fertilizerPredictionTooltip.
  ///
  /// In en, this message translates to:
  /// **'Calculate optimal fertilizer'**
  String get fertilizerPredictionTooltip;

  /// No description provided for @pestPrediction.
  ///
  /// In en, this message translates to:
  /// **'Pest\nPrediction'**
  String get pestPrediction;

  /// No description provided for @pestPredictionTooltip.
  ///
  /// In en, this message translates to:
  /// **'Identify potential pest risks'**
  String get pestPredictionTooltip;

  /// No description provided for @reviews.
  ///
  /// In en, this message translates to:
  /// **'Reviews'**
  String get reviews;

  /// No description provided for @greatAppReview.
  ///
  /// In en, this message translates to:
  /// **'Great app! Helped me monitor crops effectively.'**
  String get greatAppReview;

  /// No description provided for @history.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get history;

  /// No description provided for @validNumber.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid number for'**
  String get validNumber;

  /// No description provided for @fertilizerPredictionTitle.
  ///
  /// In en, this message translates to:
  /// **'Fertilizer Recommendation'**
  String get fertilizerPredictionTitle;

  /// No description provided for @resetForm.
  ///
  /// In en, this message translates to:
  /// **'Reset form'**
  String get resetForm;

  /// No description provided for @enterCropSoilDetails.
  ///
  /// In en, this message translates to:
  /// **'Enter Crop & Soil Details'**
  String get enterCropSoilDetails;

  /// No description provided for @district.
  ///
  /// In en, this message translates to:
  /// **'District'**
  String get district;

  /// No description provided for @selectDistrict.
  ///
  /// In en, this message translates to:
  /// **'Please select a district'**
  String get selectDistrict;

  /// No description provided for @selectSoilColor.
  ///
  /// In en, this message translates to:
  /// **'Please select a soil color'**
  String get selectSoilColor;

  /// No description provided for @crop.
  ///
  /// In en, this message translates to:
  /// **'Crop'**
  String get crop;

  /// No description provided for @selectCrop.
  ///
  /// In en, this message translates to:
  /// **'Please select a crop'**
  String get selectCrop;

  /// No description provided for @soilParameters.
  ///
  /// In en, this message translates to:
  /// **'Soil Parameters'**
  String get soilParameters;

  /// No description provided for @phLevel.
  ///
  /// In en, this message translates to:
  /// **'pH Level'**
  String get phLevel;

  /// No description provided for @environmentalParameters.
  ///
  /// In en, this message translates to:
  /// **'Environmental Parameters'**
  String get environmentalParameters;

  /// No description provided for @getFertilizerRecommendation.
  ///
  /// In en, this message translates to:
  /// **'Get Fertilizer Recommendation'**
  String get getFertilizerRecommendation;

  /// No description provided for @analysisComplete.
  ///
  /// In en, this message translates to:
  /// **'Analysis Complete'**
  String get analysisComplete;

  /// No description provided for @recommendedFertilizer.
  ///
  /// In en, this message translates to:
  /// **'Recommended Fertilizer'**
  String get recommendedFertilizer;

  /// No description provided for @timing.
  ///
  /// In en, this message translates to:
  /// **'Timing'**
  String get timing;

  /// No description provided for @timingDesc.
  ///
  /// In en, this message translates to:
  /// **'Apply during soil preparation before planting for best results.'**
  String get timingDesc;

  /// No description provided for @method.
  ///
  /// In en, this message translates to:
  /// **'Method'**
  String get method;

  /// No description provided for @methodDesc.
  ///
  /// In en, this message translates to:
  /// **'Mix thoroughly with topsoil or apply as directed on fertilizer packaging.'**
  String get methodDesc;

  /// No description provided for @caution.
  ///
  /// In en, this message translates to:
  /// **'Caution'**
  String get caution;

  /// No description provided for @cautionDesc.
  ///
  /// In en, this message translates to:
  /// **'Always wear gloves and follow safety instructions when handling fertilizers.'**
  String get cautionDesc;

  /// No description provided for @noPredictionYet.
  ///
  /// In en, this message translates to:
  /// **'No prediction yet'**
  String get noPredictionYet;

  /// No description provided for @authenticationRequired.
  ///
  /// In en, this message translates to:
  /// **'Authentication required. Please login first.'**
  String get authenticationRequired;

  /// No description provided for @tagline.
  ///
  /// In en, this message translates to:
  /// **'Smart farming at your fingertips'**
  String get tagline;

  /// No description provided for @continueWithGoogle.
  ///
  /// In en, this message translates to:
  /// **'Continue with Google'**
  String get continueWithGoogle;

  /// No description provided for @continueWithApple.
  ///
  /// In en, this message translates to:
  /// **'Continue with Apple'**
  String get continueWithApple;

  /// No description provided for @exploreAsGuest.
  ///
  /// In en, this message translates to:
  /// **'Explore as Guest'**
  String get exploreAsGuest;

  /// No description provided for @loginFailed.
  ///
  /// In en, this message translates to:
  /// **'Login failed:'**
  String get loginFailed;

  /// No description provided for @termsAndPrivacy.
  ///
  /// In en, this message translates to:
  /// **'By continuing, you agree to our Terms of Service and Privacy Policy'**
  String get termsAndPrivacy;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loading;

  /// No description provided for @plantDiseaseIdentifierTitle.
  ///
  /// In en, this message translates to:
  /// **'Plant Disease Identifier'**
  String get plantDiseaseIdentifierTitle;

  /// No description provided for @identifyPlantDiseasesHeader.
  ///
  /// In en, this message translates to:
  /// **'Identify Plant Diseases'**
  String get identifyPlantDiseasesHeader;

  /// No description provided for @identifyPlantDiseasesDescription.
  ///
  /// In en, this message translates to:
  /// **'Take or upload a photo of a plant leaf to identify diseases and get treatment recommendations'**
  String get identifyPlantDiseasesDescription;

  /// No description provided for @chooseAnOption.
  ///
  /// In en, this message translates to:
  /// **'Choose an Option'**
  String get chooseAnOption;

  /// No description provided for @takePhoto.
  ///
  /// In en, this message translates to:
  /// **'Take a Photo'**
  String get takePhoto;

  /// No description provided for @takePhotoSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Use your camera to capture a new image'**
  String get takePhotoSubtitle;

  /// No description provided for @chooseFromGallery.
  ///
  /// In en, this message translates to:
  /// **'Choose from Gallery'**
  String get chooseFromGallery;

  /// No description provided for @chooseFromGallerySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Select an existing image from your device'**
  String get chooseFromGallerySubtitle;

  /// No description provided for @uploadLeafImage.
  ///
  /// In en, this message translates to:
  /// **'Upload a clear image of the plant leaf'**
  String get uploadLeafImage;

  /// No description provided for @uploadLeafImageHint.
  ///
  /// In en, this message translates to:
  /// **'Make sure the leaf is well-lit and the affected area is clearly visible'**
  String get uploadLeafImageHint;

  /// No description provided for @selectLeafImage.
  ///
  /// In en, this message translates to:
  /// **'Select Leaf Image'**
  String get selectLeafImage;

  /// No description provided for @change.
  ///
  /// In en, this message translates to:
  /// **'Change'**
  String get change;

  /// No description provided for @analyzeLeaf.
  ///
  /// In en, this message translates to:
  /// **'Analyze Leaf'**
  String get analyzeLeaf;

  /// No description provided for @analyzing.
  ///
  /// In en, this message translates to:
  /// **'Analyzing...'**
  String get analyzing;

  /// No description provided for @readyToAnalyze.
  ///
  /// In en, this message translates to:
  /// **'Ready to analyze'**
  String get readyToAnalyze;

  /// No description provided for @tapAnalyzeToIdentify.
  ///
  /// In en, this message translates to:
  /// **'Tap the analyze button to identify potential diseases'**
  String get tapAnalyzeToIdentify;

  /// No description provided for @errorOccurred.
  ///
  /// In en, this message translates to:
  /// **'Error Occurred'**
  String get errorOccurred;

  /// No description provided for @diagnosis.
  ///
  /// In en, this message translates to:
  /// **'Diagnosis'**
  String get diagnosis;

  /// No description provided for @severity.
  ///
  /// In en, this message translates to:
  /// **'Severity:'**
  String get severity;

  /// No description provided for @recommendedTreatment.
  ///
  /// In en, this message translates to:
  /// **'Recommended Treatment'**
  String get recommendedTreatment;

  /// No description provided for @preventionTips.
  ///
  /// In en, this message translates to:
  /// **'Prevention Tips'**
  String get preventionTips;

  /// No description provided for @similarDiseases.
  ///
  /// In en, this message translates to:
  /// **'Similar Diseases'**
  String get similarDiseases;

  /// No description provided for @viewAllSimilarDiseases.
  ///
  /// In en, this message translates to:
  /// **'View All Similar Diseases'**
  String get viewAllSimilarDiseases;

  /// No description provided for @aboutPlantDiseaseIdentifier.
  ///
  /// In en, this message translates to:
  /// **'About Plant Disease Identifier'**
  String get aboutPlantDiseaseIdentifier;

  /// No description provided for @aboutPlantDiseaseIdentifierDescription.
  ///
  /// In en, this message translates to:
  /// **'This tool uses machine learning to identify plant diseases from leaf images. For best results:'**
  String get aboutPlantDiseaseIdentifierDescription;

  /// No description provided for @infoUseWellLitImages.
  ///
  /// In en, this message translates to:
  /// **'Use well-lit images without shadows'**
  String get infoUseWellLitImages;

  /// No description provided for @infoAffectedAreaVisible.
  ///
  /// In en, this message translates to:
  /// **'Ensure the affected area is clearly visible'**
  String get infoAffectedAreaVisible;

  /// No description provided for @infoCloseUpShots.
  ///
  /// In en, this message translates to:
  /// **'Take close-up shots for better analysis'**
  String get infoCloseUpShots;

  /// No description provided for @infoConsultExpert.
  ///
  /// In en, this message translates to:
  /// **'Results are suggestions only, consult an expert for confirmation'**
  String get infoConsultExpert;

  /// No description provided for @gotIt.
  ///
  /// In en, this message translates to:
  /// **'Got it'**
  String get gotIt;

  /// No description provided for @pleaseSelectImageFirst.
  ///
  /// In en, this message translates to:
  /// **'Please select an image first'**
  String get pleaseSelectImageFirst;

  /// No description provided for @unknownDisease.
  ///
  /// In en, this message translates to:
  /// **'Unknown disease'**
  String get unknownDisease;

  /// No description provided for @defaultTreatment.
  ///
  /// In en, this message translates to:
  /// **'Consult with an agricultural expert for appropriate treatment options.'**
  String get defaultTreatment;

  /// No description provided for @tip_one.
  ///
  /// In en, this message translates to:
  /// **'Ensure proper spacing between plants for adequate air circulation'**
  String get tip_one;

  /// No description provided for @tip_two.
  ///
  /// In en, this message translates to:
  /// **'Water at the base of plants rather than on foliage'**
  String get tip_two;

  /// No description provided for @tip_three.
  ///
  /// In en, this message translates to:
  /// **'Remove and destroy infected plant parts'**
  String get tip_three;

  /// No description provided for @tip_four.
  ///
  /// In en, this message translates to:
  /// **'Practice crop rotation to reduce pathogen buildup in soil'**
  String get tip_four;

  /// No description provided for @writeReview.
  ///
  /// In en, this message translates to:
  /// **'Write a Review'**
  String get writeReview;

  /// No description provided for @yourFeedback.
  ///
  /// In en, this message translates to:
  /// **'Your Feedback'**
  String get yourFeedback;

  /// No description provided for @writeExperienceHint.
  ///
  /// In en, this message translates to:
  /// **'Write your experience here...'**
  String get writeExperienceHint;

  /// No description provided for @submitReview.
  ///
  /// In en, this message translates to:
  /// **'Submit Review'**
  String get submitReview;

  /// No description provided for @previousReviews.
  ///
  /// In en, this message translates to:
  /// **'Previous Reviews'**
  String get previousReviews;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @drawerYieldPrediction.
  ///
  /// In en, this message translates to:
  /// **'Yield Prediction'**
  String get drawerYieldPrediction;

  /// No description provided for @drawerPestPrediction.
  ///
  /// In en, this message translates to:
  /// **'Pest Prediction'**
  String get drawerPestPrediction;

  /// No description provided for @drawerAboutHelp.
  ///
  /// In en, this message translates to:
  /// **'About and Help'**
  String get drawerAboutHelp;

  /// No description provided for @drawerContactUs.
  ///
  /// In en, this message translates to:
  /// **'Contact Us'**
  String get drawerContactUs;

  /// No description provided for @drawerHelloUser.
  ///
  /// In en, this message translates to:
  /// **'Hello, User'**
  String get drawerHelloUser;

  /// No description provided for @bottomNavCropHistory.
  ///
  /// In en, this message translates to:
  /// **'Crop History'**
  String get bottomNavCropHistory;

  /// No description provided for @reviewSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Review submitted successfully!'**
  String get reviewSubmitted;

  /// No description provided for @reviewSubmissionFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to submit review. Please try again.'**
  String get reviewSubmissionFailed;

  /// No description provided for @reviewEditSuccess.
  ///
  /// In en, this message translates to:
  /// **'Review edited successfully!'**
  String get reviewEditSuccess;

  /// No description provided for @reviewDeleteSuccess.
  ///
  /// In en, this message translates to:
  /// **'Review deleted successfully!'**
  String get reviewDeleteSuccess;

  /// No description provided for @applicationGuidelines.
  ///
  /// In en, this message translates to:
  /// **'Application Guidelines'**
  String get applicationGuidelines;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['en', 'hi', 'mr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {


  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en': return AppLocalizationsEn();
    case 'hi': return AppLocalizationsHi();
    case 'mr': return AppLocalizationsMr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.'
  );
}
