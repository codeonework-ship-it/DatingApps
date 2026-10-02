import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_de.dart';
import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_fr.dart';
import 'app_localizations_it.dart';
import 'app_localizations_nl.dart';
import 'app_localizations_pl.dart';
import 'app_localizations_pt.dart';
import 'app_localizations_ru.dart';

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
    Locale('de'),
    Locale('en'),
    Locale('en', 'GB'),
    Locale('es'),
    Locale('fr'),
    Locale('it'),
    Locale('nl'),
    Locale('pl'),
    Locale('pt'),
    Locale('ru'),
  ];

  /// Bottom navigation tab: the discovery / swipe deck.
  ///
  /// In en, this message translates to:
  /// **'Discover'**
  String get navDiscover;

  /// Bottom navigation tab: the member's matches and conversations.
  ///
  /// In en, this message translates to:
  /// **'Matches'**
  String get navMatches;

  /// Bottom navigation tab: the engagement hub (prompts, rooms, challenges).
  ///
  /// In en, this message translates to:
  /// **'Engage'**
  String get navEngage;

  /// Bottom navigation tab: the member's own profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get navProfile;

  /// Bottom navigation tab: the settings hub.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get navSettings;

  /// App bar title of the settings hub.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// Settings hub section header grouping profile tiles.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get settingsSectionProfile;

  /// Settings tile title: opens the profile editor.
  ///
  /// In en, this message translates to:
  /// **'Edit Profile'**
  String get settingsEditProfileTitle;

  /// Settings tile subtitle under Edit Profile.
  ///
  /// In en, this message translates to:
  /// **'Update your information'**
  String get settingsEditProfileSubtitle;

  /// Settings tile title: opens the photo manager.
  ///
  /// In en, this message translates to:
  /// **'Photos'**
  String get settingsPhotosTitle;

  /// Settings tile subtitle under Photos.
  ///
  /// In en, this message translates to:
  /// **'Manage your photos'**
  String get settingsPhotosSubtitle;

  /// Settings hub section header grouping preference tiles (appearance, language, notifications).
  ///
  /// In en, this message translates to:
  /// **'Preferences'**
  String get settingsSectionPreferences;

  /// Title of the inline theme picker card.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get settingsAppearanceTitle;

  /// Subtitle of the theme picker card: the theme is stored server-side.
  ///
  /// In en, this message translates to:
  /// **'Saved to your account'**
  String get settingsAppearanceSubtitle;

  /// Theme mode segment label: light theme.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get settingsThemeLight;

  /// Theme mode segment label: dark theme.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get settingsThemeDark;

  /// Theme mode segment label: follow the device's light/dark setting.
  ///
  /// In en, this message translates to:
  /// **'Match device'**
  String get settingsThemeMatchDevice;

  /// Heading above the themed preset chips.
  ///
  /// In en, this message translates to:
  /// **'Looks'**
  String get settingsLooksTitle;

  /// Explains the Classic look. 'Daylight' and 'Afterdark Ember' are theme names and stay in English.
  ///
  /// In en, this message translates to:
  /// **'Warm ivory and forest by day. Soft mint and deep forest by night.'**
  String get settingsLooksClassicDescription;

  /// Chip label for the default look, the one the Today screen is designed in. A product name; keep it the same as the Today tab name.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get settingsLooksClassicLabel;

  /// Snack bar shown when persisting the theme choice failed.
  ///
  /// In en, this message translates to:
  /// **'Could not save your theme. Please try again.'**
  String get settingsThemeSaveFailed;

  /// Settings tile title: opens the language picker.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settingsLanguageTitle;

  /// Settings tile subtitle under Language.
  ///
  /// In en, this message translates to:
  /// **'Choose the app language'**
  String get settingsLanguageSubtitle;

  /// Settings tile title: opens the dating preferences editor.
  ///
  /// In en, this message translates to:
  /// **'Dating Preferences'**
  String get settingsDatingPreferencesTitle;

  /// Settings tile subtitle under Dating Preferences.
  ///
  /// In en, this message translates to:
  /// **'Age, location, interests'**
  String get settingsDatingPreferencesSubtitle;

  /// Settings tile title: account visibility, export and deletion.
  ///
  /// In en, this message translates to:
  /// **'Account & Data'**
  String get settingsAccountDataTitle;

  /// Settings tile subtitle under Account & Data.
  ///
  /// In en, this message translates to:
  /// **'Hide, download or delete your account'**
  String get settingsAccountDataSubtitle;

  /// Settings tile title: opens notification settings.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get settingsNotificationsTitle;

  /// Settings tile subtitle under Notifications.
  ///
  /// In en, this message translates to:
  /// **'Push & email notifications'**
  String get settingsNotificationsSubtitle;

  /// Settings hub section header grouping engagement features.
  ///
  /// In en, this message translates to:
  /// **'Engagement'**
  String get settingsSectionEngagement;

  /// Settings tile title: earned trust badges.
  ///
  /// In en, this message translates to:
  /// **'Trust Badges'**
  String get settingsTrustBadgesTitle;

  /// Settings tile subtitle under Trust Badges.
  ///
  /// In en, this message translates to:
  /// **'See earned badges and trust history'**
  String get settingsTrustBadgesSubtitle;

  /// Settings tile title: trust requirements for discovery.
  ///
  /// In en, this message translates to:
  /// **'Trust Filters'**
  String get settingsTrustFiltersTitle;

  /// Settings tile subtitle under Trust Filters.
  ///
  /// In en, this message translates to:
  /// **'Control trust requirements for discovery'**
  String get settingsTrustFiltersSubtitle;

  /// Settings tile title: group conversation rooms.
  ///
  /// In en, this message translates to:
  /// **'Conversation Rooms'**
  String get settingsConversationRoomsTitle;

  /// Settings tile subtitle under Conversation Rooms.
  ///
  /// In en, this message translates to:
  /// **'Browse, join, leave, and moderate rooms'**
  String get settingsConversationRoomsSubtitle;

  /// Settings tile title: the friends list.
  ///
  /// In en, this message translates to:
  /// **'Friends & Connections'**
  String get settingsFriendsTitle;

  /// Settings tile subtitle under Friends & Connections.
  ///
  /// In en, this message translates to:
  /// **'Build and maintain friend connections'**
  String get settingsFriendsSubtitle;

  /// Settings tile title: past video/voice calls.
  ///
  /// In en, this message translates to:
  /// **'Call History'**
  String get settingsCallHistoryTitle;

  /// Settings tile subtitle under Call History.
  ///
  /// In en, this message translates to:
  /// **'Review durable call sessions'**
  String get settingsCallHistorySubtitle;

  /// Settings tile title: nudges that restart quiet conversations.
  ///
  /// In en, this message translates to:
  /// **'Match Nudges'**
  String get settingsMatchNudgesTitle;

  /// Settings tile subtitle under Match Nudges.
  ///
  /// In en, this message translates to:
  /// **'Restart quiet conversations'**
  String get settingsMatchNudgesSubtitle;

  /// Settings tile title: membership plans and payments.
  ///
  /// In en, this message translates to:
  /// **'Subscriptions'**
  String get settingsSubscriptionsTitle;

  /// Settings tile subtitle under Subscriptions.
  ///
  /// In en, this message translates to:
  /// **'Plans, entitlement status, and payments'**
  String get settingsSubscriptionsSubtitle;

  /// Settings hub section header grouping app-level tiles.
  ///
  /// In en, this message translates to:
  /// **'App'**
  String get settingsSectionApp;

  /// Settings tile title: privacy and safety controls.
  ///
  /// In en, this message translates to:
  /// **'Privacy & Safety'**
  String get settingsPrivacySafetyTitle;

  /// Settings tile subtitle under Privacy & Safety.
  ///
  /// In en, this message translates to:
  /// **'Manage your privacy settings'**
  String get settingsPrivacySafetySubtitle;

  /// Settings tile title: government ID verification status.
  ///
  /// In en, this message translates to:
  /// **'Government Verification'**
  String get settingsGovernmentVerificationTitle;

  /// Settings tile subtitle under Government Verification.
  ///
  /// In en, this message translates to:
  /// **'View identity verification status'**
  String get settingsGovernmentVerificationSubtitle;

  /// Settings tile title shown only in QA automation builds.
  ///
  /// In en, this message translates to:
  /// **'QA Verification Upload'**
  String get settingsQaVerificationUploadTitle;

  /// Settings tile subtitle under QA Verification Upload.
  ///
  /// In en, this message translates to:
  /// **'Automation-only ID and selfie flow'**
  String get settingsQaVerificationUploadSubtitle;

  /// Settings tile title: FAQ and support.
  ///
  /// In en, this message translates to:
  /// **'Help & Support'**
  String get settingsHelpSupportTitle;

  /// Settings tile subtitle under Help & Support.
  ///
  /// In en, this message translates to:
  /// **'FAQ and contact support'**
  String get settingsHelpSupportSubtitle;

  /// Settings tile title: about the app.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get settingsAboutTitle;

  /// Settings tile subtitle under About.
  ///
  /// In en, this message translates to:
  /// **'App details and stack'**
  String get settingsAboutSubtitle;

  /// Button that signs the member out.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get settingsLogout;

  /// App bar title of the language picker screen.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get languageTitle;

  /// Explanatory line at the top of the language picker.
  ///
  /// In en, this message translates to:
  /// **'Pick the language Connect uses. Your choice is saved to your account and applies on every device you sign in on.'**
  String get languageIntro;

  /// Language option: follow the phone's language setting.
  ///
  /// In en, this message translates to:
  /// **'Use device language'**
  String get languageUseDevice;

  /// Subtitle under 'Use device language'.
  ///
  /// In en, this message translates to:
  /// **'Follows your phone\'s language setting'**
  String get languageUseDeviceSubtitle;

  /// Snack bar shown when persisting the language choice failed.
  ///
  /// In en, this message translates to:
  /// **'Could not save your language. Please try again.'**
  String get languageSaveFailed;

  /// App bar title of the notification settings screen.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notificationsTitle;

  /// Row that opens the notification inbox.
  ///
  /// In en, this message translates to:
  /// **'Notification inbox'**
  String get notificationsInboxTitle;

  /// Inbox row subtitle when there are no unread notifications.
  ///
  /// In en, this message translates to:
  /// **'You are all caught up'**
  String get notificationsInboxCaughtUp;

  /// Inbox row subtitle with the number of unread notifications.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 unread} other{{count} unread}}'**
  String notificationsInboxUnread(int count);

  /// Switch: show notifications while the app is open.
  ///
  /// In en, this message translates to:
  /// **'In-app notifications'**
  String get notificationsInAppTitle;

  /// Subtitle of the in-app notifications switch.
  ///
  /// In en, this message translates to:
  /// **'Show notifications while using the app'**
  String get notificationsInAppSubtitle;

  /// Switch: allow push delivery.
  ///
  /// In en, this message translates to:
  /// **'Push notifications'**
  String get notificationsPushTitle;

  /// Subtitle of the push notifications switch.
  ///
  /// In en, this message translates to:
  /// **'Allow delivery when the app is in background'**
  String get notificationsPushSubtitle;

  /// Switch: notify on a new match.
  ///
  /// In en, this message translates to:
  /// **'New matches'**
  String get notificationsNewMatchesTitle;

  /// Subtitle of the new matches switch.
  ///
  /// In en, this message translates to:
  /// **'Get notified when you match'**
  String get notificationsNewMatchesSubtitle;

  /// Switch: notify on a new chat message.
  ///
  /// In en, this message translates to:
  /// **'New messages'**
  String get notificationsNewMessagesTitle;

  /// Subtitle of the new messages switch.
  ///
  /// In en, this message translates to:
  /// **'Get notified for chat messages'**
  String get notificationsNewMessagesSubtitle;

  /// Switch: notify when someone likes the member.
  ///
  /// In en, this message translates to:
  /// **'Likes'**
  String get notificationsLikesTitle;

  /// Subtitle of the likes switch.
  ///
  /// In en, this message translates to:
  /// **'Get notified when someone likes you'**
  String get notificationsLikesSubtitle;

  /// Switch: notify when a match nudges the member.
  ///
  /// In en, this message translates to:
  /// **'Match nudges'**
  String get notificationsMatchNudgesTitle;

  /// Subtitle of the match nudges switch.
  ///
  /// In en, this message translates to:
  /// **'Get notified when a match nudges you'**
  String get notificationsMatchNudgesSubtitle;

  /// Switch: show incoming call alerts.
  ///
  /// In en, this message translates to:
  /// **'Incoming calls'**
  String get notificationsIncomingCallsTitle;

  /// Subtitle of the incoming calls switch.
  ///
  /// In en, this message translates to:
  /// **'Show incoming call alerts'**
  String get notificationsIncomingCallsSubtitle;

  /// Switch: safety status notifications.
  ///
  /// In en, this message translates to:
  /// **'Safety updates'**
  String get notificationsSafetyTitle;

  /// Subtitle of the safety updates switch.
  ///
  /// In en, this message translates to:
  /// **'Receive important safety status updates'**
  String get notificationsSafetySubtitle;

  /// Switch: notifications about friends' date plans and check-ins.
  ///
  /// In en, this message translates to:
  /// **'Friends\' date plans'**
  String get notificationsFriendPlansTitle;

  /// Subtitle of the friends' date plans switch.
  ///
  /// In en, this message translates to:
  /// **'Know when a friend plans a date or checks in'**
  String get notificationsFriendPlansSubtitle;

  /// Small brand tagline beside the logo on the welcome screen.
  ///
  /// In en, this message translates to:
  /// **'Made for real life.'**
  String get welcomeTagline;

  /// Chip over the welcome photo: the app aims to get people meeting in person.
  ///
  /// In en, this message translates to:
  /// **'Offline is the goal.'**
  String get welcomePhotoNote;

  /// First part of the welcome headline; it is followed by welcomeHeadlineAccent rendered in a gradient. Keep the trailing space and the line break.
  ///
  /// In en, this message translates to:
  /// **'A good story\nstarts with '**
  String get welcomeHeadlineLead;

  /// Accented last word(s) of the welcome headline, rendered in a gradient italic.
  ///
  /// In en, this message translates to:
  /// **'hello.'**
  String get welcomeHeadlineAccent;

  /// Body copy under the welcome headline.
  ///
  /// In en, this message translates to:
  /// **'Find someone who feels like your kind of person. Take it from there.'**
  String get welcomeBody;

  /// Primary call to action on the welcome screen.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get welcomeCreateAccount;

  /// Text before the sign-in link on the welcome screen. Keep the trailing space.
  ///
  /// In en, this message translates to:
  /// **'Already a member? '**
  String get welcomeAlreadyMember;

  /// Sign-in link on the welcome screen.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get welcomeSignIn;

  /// Footer line on the welcome screen: age gate and brand promise.
  ///
  /// In en, this message translates to:
  /// **'18+  ·  Your pace. Your choice.'**
  String get welcomeFooter;

  /// Tooltip of the back button on the sign-in screen.
  ///
  /// In en, this message translates to:
  /// **'Back to welcome'**
  String get authBackTooltip;

  /// Headline of the sign-in screen.
  ///
  /// In en, this message translates to:
  /// **'Good to see you.'**
  String get authHeadline;

  /// Line under the sign-in headline.
  ///
  /// In en, this message translates to:
  /// **'Use your username and password to continue'**
  String get authSubtitle;

  /// Label above the credential form.
  ///
  /// In en, this message translates to:
  /// **'Welcome back'**
  String get authWelcomeBack;

  /// Line under the 'Welcome back' label.
  ///
  /// In en, this message translates to:
  /// **'Your next hello is waiting.'**
  String get authNextHello;

  /// Hint of the username field (lower-case, like a handle).
  ///
  /// In en, this message translates to:
  /// **'username'**
  String get authUsernameHint;

  /// Hint of the password field.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get authPasswordHint;

  /// Tooltip of the eye icon while the password is hidden.
  ///
  /// In en, this message translates to:
  /// **'Show password'**
  String get authShowPassword;

  /// Tooltip of the eye icon while the password is visible.
  ///
  /// In en, this message translates to:
  /// **'Hide password'**
  String get authHidePassword;

  /// Link to account recovery.
  ///
  /// In en, this message translates to:
  /// **'Can\'t sign in?'**
  String get authCantSignIn;

  /// Primary button of the sign-in screen.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get authSignIn;

  /// Privacy note under the credential form.
  ///
  /// In en, this message translates to:
  /// **'Your password is sent only when you sign in and is never stored in the app.'**
  String get authPrivacyNote;

  /// Validation message when the username is empty.
  ///
  /// In en, this message translates to:
  /// **'Please enter your username.'**
  String get authEnterUsername;

  /// Validation message when the password is empty.
  ///
  /// In en, this message translates to:
  /// **'Please enter your password.'**
  String get authEnterPassword;

  /// Generic yes choice.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get commonYes;

  /// Generic no choice.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get commonNo;

  /// Date plan venue category label.
  ///
  /// In en, this message translates to:
  /// **'Coffee'**
  String get planVenueCoffee;

  /// Date plan venue category label.
  ///
  /// In en, this message translates to:
  /// **'A meal'**
  String get planVenueMeal;

  /// Date plan venue category label.
  ///
  /// In en, this message translates to:
  /// **'Drinks'**
  String get planVenueDrinks;

  /// Date plan venue category label.
  ///
  /// In en, this message translates to:
  /// **'A walk'**
  String get planVenueWalk;

  /// Date plan venue category label.
  ///
  /// In en, this message translates to:
  /// **'An activity'**
  String get planVenueActivity;

  /// Date plan venue category label.
  ///
  /// In en, this message translates to:
  /// **'An event'**
  String get planVenueEvent;

  /// Date plan venue category label.
  ///
  /// In en, this message translates to:
  /// **'Video call'**
  String get planVenueVideoCall;

  /// Date plan venue category label for the catch-all category.
  ///
  /// In en, this message translates to:
  /// **'Something else'**
  String get planVenueOther;

  /// Title of the propose card and sheet.
  ///
  /// In en, this message translates to:
  /// **'Plan a date with {name}'**
  String planProposeTitle(String name);

  /// Subtitle of the propose call to action in the chat.
  ///
  /// In en, this message translates to:
  /// **'Shape a first hello together. Contact sharing starts off.'**
  String get planProposeSubtitle;

  /// Button that opens the propose sheet.
  ///
  /// In en, this message translates to:
  /// **'Propose'**
  String get planProposeButton;

  /// Plan card headline when the partner proposed and the viewer must decide.
  ///
  /// In en, this message translates to:
  /// **'{name} proposed a date'**
  String planHeadlineProposed(String name);

  /// Plan card headline while the partner has not decided.
  ///
  /// In en, this message translates to:
  /// **'Waiting for {name}'**
  String planHeadlineWaiting(String name);

  /// Plan card headline once both agreed.
  ///
  /// In en, this message translates to:
  /// **'It is a plan'**
  String get planHeadlineUpcoming;

  /// Plan card headline when the safety check-in is due.
  ///
  /// In en, this message translates to:
  /// **'How did it go?'**
  String get planHeadlineCheckin;

  /// Plan card headline when the post-date debrief is due.
  ///
  /// In en, this message translates to:
  /// **'How was it?'**
  String get planHeadlineDebrief;

  /// Plan card headline once both members debriefed.
  ///
  /// In en, this message translates to:
  /// **'Debrief complete'**
  String get planHeadlineDebriefComplete;

  /// Plan card headline while the partner has not debriefed.
  ///
  /// In en, this message translates to:
  /// **'Waiting for {name}\'s debrief'**
  String planHeadlineWaitingDebrief(String name);

  /// Plan card headline after a safe check-in.
  ///
  /// In en, this message translates to:
  /// **'You checked in safe'**
  String get planHeadlineCheckedInSafe;

  /// Plan card headline after a need-help check-in.
  ///
  /// In en, this message translates to:
  /// **'Your request for help is recorded'**
  String get planHeadlineFriendsAlerted;

  /// Fallback plan card headline.
  ///
  /// In en, this message translates to:
  /// **'Plan'**
  String get planHeadlineDefault;

  /// Status chip: the plan is proposed.
  ///
  /// In en, this message translates to:
  /// **'Proposed'**
  String get planStatusProposed;

  /// Status chip: the plan is accepted.
  ///
  /// In en, this message translates to:
  /// **'Confirmed'**
  String get planStatusConfirmed;

  /// Button that opens the debrief sheet.
  ///
  /// In en, this message translates to:
  /// **'Ten-second debrief'**
  String get planDebriefButton;

  /// Button that declines a proposed plan.
  ///
  /// In en, this message translates to:
  /// **'Decline'**
  String get planDecline;

  /// Button that accepts a proposed plan.
  ///
  /// In en, this message translates to:
  /// **'Accept'**
  String get planAccept;

  /// Line on an accepted plan: both members' friends were told.
  ///
  /// In en, this message translates to:
  /// **'Choose trusted contacts to share your updates.'**
  String get planFriendsKnowAccepted;

  /// Line on a proposed plan: the proposer's friends were told.
  ///
  /// In en, this message translates to:
  /// **'Contact sharing is optional for each plan.'**
  String get planFriendsKnowProposed;

  /// Button that cancels the plan (also the confirm button in the dialog).
  ///
  /// In en, this message translates to:
  /// **'Cancel plan'**
  String get planCancel;

  /// Check-in button: the member needs help.
  ///
  /// In en, this message translates to:
  /// **'I need help'**
  String get planNeedHelp;

  /// Check-in button: the member is safe.
  ///
  /// In en, this message translates to:
  /// **'I\'m safe'**
  String get planImSafe;

  /// Title of the cancel confirmation dialog.
  ///
  /// In en, this message translates to:
  /// **'Cancel this plan?'**
  String get planCancelDialogTitle;

  /// Body of the cancel confirmation dialog.
  ///
  /// In en, this message translates to:
  /// **'{name} and everyone you shared it with will be told.'**
  String planCancelDialogBody(String name);

  /// Dialog button that keeps the plan.
  ///
  /// In en, this message translates to:
  /// **'Keep it'**
  String get planKeepIt;

  /// Intro line of the propose sheet.
  ///
  /// In en, this message translates to:
  /// **'This starts between you and your date. After proposing, choose trusted contacts if you want to share plan and check-in updates.'**
  String get planProposeIntro;

  /// Section label in the propose sheet: date and time.
  ///
  /// In en, this message translates to:
  /// **'When'**
  String get planSectionWhen;

  /// Section label in the propose sheet: venue category.
  ///
  /// In en, this message translates to:
  /// **'What'**
  String get planSectionWhat;

  /// Section label in the propose sheet: friend groups to include.
  ///
  /// In en, this message translates to:
  /// **'Trusted contacts'**
  String get planSectionGroups;

  /// Duration chip, e.g. '2 h'.
  ///
  /// In en, this message translates to:
  /// **'{hours} h'**
  String planDurationHours(int hours);

  /// Label of the venue name field.
  ///
  /// In en, this message translates to:
  /// **'Place (optional)'**
  String get planPlaceLabel;

  /// Hint of the venue name field.
  ///
  /// In en, this message translates to:
  /// **'A public place works best'**
  String get planPlaceHint;

  /// Label of the venue area field.
  ///
  /// In en, this message translates to:
  /// **'Area or neighborhood'**
  String get planAreaLabel;

  /// Label of the note field.
  ///
  /// In en, this message translates to:
  /// **'Note for them (optional)'**
  String get planNoteLabel;

  /// Validation error when the chosen start is in the past.
  ///
  /// In en, this message translates to:
  /// **'Pick a time in the future.'**
  String get planFutureTimeError;

  /// Fallback error when the propose request failed.
  ///
  /// In en, this message translates to:
  /// **'Unable to propose this plan.'**
  String get planProposeFailed;

  /// Submit button of the propose sheet.
  ///
  /// In en, this message translates to:
  /// **'Send the plan'**
  String get planSendButton;

  /// Title of the accept sheet.
  ///
  /// In en, this message translates to:
  /// **'Accept the plan?'**
  String get planAcceptTitle;

  /// Intro line of the accept sheet.
  ///
  /// In en, this message translates to:
  /// **'Accept this plan with your date. Choose trusted contacts afterwards if you want to share your updates.'**
  String get planAcceptIntro;

  /// Submit button of the accept sheet.
  ///
  /// In en, this message translates to:
  /// **'Accept plan'**
  String get planAcceptButton;

  /// Title of the debrief sheet.
  ///
  /// In en, this message translates to:
  /// **'How was it with {name}?'**
  String debriefTitle(String name);

  /// Intro line of the debrief sheet. 'Shows Up' is a badge name.
  ///
  /// In en, this message translates to:
  /// **'Your answers are private. When you both confirm the date happened, it counts toward your Shows Up badge.'**
  String get debriefIntro;

  /// Debrief question.
  ///
  /// In en, this message translates to:
  /// **'Did the date happen?'**
  String get debriefHappened;

  /// Debrief question.
  ///
  /// In en, this message translates to:
  /// **'Would you meet again?'**
  String get debriefMeetAgain;

  /// Debrief question.
  ///
  /// In en, this message translates to:
  /// **'Did you feel safe?'**
  String get debriefFeltSafe;

  /// Label of the debrief note field.
  ///
  /// In en, this message translates to:
  /// **'Anything to add? (optional)'**
  String get debriefNoteLabel;

  /// Validation error when the first question is unanswered.
  ///
  /// In en, this message translates to:
  /// **'Tell us whether the date happened.'**
  String get debriefMissingHappened;

  /// Fallback error when the debrief request failed.
  ///
  /// In en, this message translates to:
  /// **'Unable to save your debrief.'**
  String get debriefSaveFailed;

  /// Submit button of the debrief sheet.
  ///
  /// In en, this message translates to:
  /// **'Save debrief'**
  String get debriefSave;

  /// Title of the dialog offered after a 'did not feel safe' answer.
  ///
  /// In en, this message translates to:
  /// **'Sorry that did not feel safe'**
  String get debriefUnsafeTitle;

  /// Body of the dialog offered after a 'did not feel safe' answer.
  ///
  /// In en, this message translates to:
  /// **'Your answer is noted for our safety team. Do you also want to report {name}?'**
  String debriefUnsafeBody(String name);

  /// Dialog button that dismisses the report offer.
  ///
  /// In en, this message translates to:
  /// **'Not now'**
  String get debriefNotNow;

  /// Dialog button that opens the report flow.
  ///
  /// In en, this message translates to:
  /// **'Report'**
  String get debriefReport;

  /// App bar title of the plans screen.
  ///
  /// In en, this message translates to:
  /// **'Date plans'**
  String get plansTitle;

  /// Tab: the member's own plans.
  ///
  /// In en, this message translates to:
  /// **'Mine'**
  String get plansTabMine;

  /// Tab: plans friends shared.
  ///
  /// In en, this message translates to:
  /// **'Friends'**
  String get plansTabFriends;

  /// Empty state title of the Mine tab.
  ///
  /// In en, this message translates to:
  /// **'No plans yet'**
  String get plansEmptyMineTitle;

  /// Empty state body of the Mine tab.
  ///
  /// In en, this message translates to:
  /// **'Propose a date from a conversation. You choose whether to share plan and check-in updates with trusted contacts.'**
  String get plansEmptyMineBody;

  /// Plan tile title: who the date is with.
  ///
  /// In en, this message translates to:
  /// **'With {name}'**
  String plansWith(String name);

  /// Plan tile footer: the viewer must decide.
  ///
  /// In en, this message translates to:
  /// **'Waiting for your answer'**
  String get plansNextDecide;

  /// Plan tile footer: the partner must decide.
  ///
  /// In en, this message translates to:
  /// **'Waiting for {name}'**
  String plansNextAwait(String name);

  /// Plan tile footer: the plan is confirmed.
  ///
  /// In en, this message translates to:
  /// **'Confirmed. Your time together is planned.'**
  String get plansNextUpcoming;

  /// Plan tile footer: the check-in is due.
  ///
  /// In en, this message translates to:
  /// **'Check in after your date'**
  String get plansNextCheckin;

  /// Plan tile footer: the debrief is due.
  ///
  /// In en, this message translates to:
  /// **'Tell us how it went'**
  String get plansNextDebrief;

  /// Plan tile footer: the plan was cancelled.
  ///
  /// In en, this message translates to:
  /// **'Canceled'**
  String get plansNextCancelled;

  /// Plan tile footer: nothing left to do.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get plansNextDone;

  /// Empty state title of the Friends tab.
  ///
  /// In en, this message translates to:
  /// **'Nothing shared yet'**
  String get plansEmptyFriendsTitle;

  /// Empty state body of the Friends tab.
  ///
  /// In en, this message translates to:
  /// **'Plans appear here when friends explicitly choose to share with you.'**
  String get plansEmptyFriendsBody;

  /// How a friend's plan reached the viewer: through a friend group.
  ///
  /// In en, this message translates to:
  /// **'Shared with you'**
  String get plansViaGroup;

  /// How a friend's plan reached the viewer: directly as a friend.
  ///
  /// In en, this message translates to:
  /// **'Trusted contact'**
  String get plansViaFriend;

  /// Friend plan footer after a need-help check-in.
  ///
  /// In en, this message translates to:
  /// **'{name} asked for help. Reach out now.'**
  String plansFriendNeedsHelp(String name);

  /// Friend plan footer when the check-in was missed.
  ///
  /// In en, this message translates to:
  /// **'{name} has not checked in yet.'**
  String plansFriendMissedCheckin(String name);

  /// Friend plan footer after a safe check-in; {via} is plansViaGroup or plansViaFriend.
  ///
  /// In en, this message translates to:
  /// **'{name} checked in safe · {via}'**
  String plansFriendCheckedInSafe(String name, String via);

  /// Friend plan footer: how it was shared and the status word.
  ///
  /// In en, this message translates to:
  /// **'{via} · {status}'**
  String plansFriendStatusLine(String via, String status);

  /// Lower-case status word used in plansFriendStatusLine.
  ///
  /// In en, this message translates to:
  /// **'proposed'**
  String get plansStatusWordProposed;

  /// Lower-case status word used in plansFriendStatusLine.
  ///
  /// In en, this message translates to:
  /// **'confirmed'**
  String get plansStatusWordConfirmed;

  /// Lower-case status word used in plansFriendStatusLine.
  ///
  /// In en, this message translates to:
  /// **'canceled'**
  String get plansStatusWordCancelled;

  /// Lower-case status word used in plansFriendStatusLine.
  ///
  /// In en, this message translates to:
  /// **'happened'**
  String get plansStatusWordHappened;

  /// Shared chat: shown while a conversation has no messages yet.
  ///
  /// In en, this message translates to:
  /// **'Say hello. Messages appear here for everyone in this conversation.'**
  String get chatEmptyDefault;

  /// Shared chat: snack bar when a message failed to send.
  ///
  /// In en, this message translates to:
  /// **'Not sent. Tap the message to retry.'**
  String get chatNotSentRetry;

  /// Shared chat: message action to resend a failed message.
  ///
  /// In en, this message translates to:
  /// **'Try sending again'**
  String get chatRetrySend;

  /// Shared chat: message action to copy the text.
  ///
  /// In en, this message translates to:
  /// **'Copy text'**
  String get chatCopyText;

  /// Shared chat: message action to delete your own message.
  ///
  /// In en, this message translates to:
  /// **'Delete my message'**
  String get chatDeleteMine;

  /// Shared chat: moderator action to remove someone else's message.
  ///
  /// In en, this message translates to:
  /// **'Remove message'**
  String get chatRemoveMessage;

  /// Shared chat: message action to report a message to moderators.
  ///
  /// In en, this message translates to:
  /// **'Report message'**
  String get chatReportMessage;

  /// Shared chat: fallback name for a sender without a name.
  ///
  /// In en, this message translates to:
  /// **'This member'**
  String get chatThisMember;

  /// Shared chat: fallback name for a member without a name.
  ///
  /// In en, this message translates to:
  /// **'Member'**
  String get chatMember;

  /// Shared chat: snack bar after copying a message.
  ///
  /// In en, this message translates to:
  /// **'Copied.'**
  String get chatCopied;

  /// Shared chat: snack bar when deleting a message failed.
  ///
  /// In en, this message translates to:
  /// **'Could not delete. Please retry.'**
  String get chatDeleteFailed;

  /// Shared chat: app bar subtitle of a conversation between two friends.
  ///
  /// In en, this message translates to:
  /// **'Friends'**
  String get chatSubtitleFriends;

  /// Shared chat: app bar subtitle with how many people are in a group conversation.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 member} other{{count} members}}'**
  String chatMemberCount(int count);

  /// Shared chat: tooltip on the offline icon while the live connection is down.
  ///
  /// In en, this message translates to:
  /// **'Reconnecting. New messages may take a moment.'**
  String get chatReconnecting;

  /// Shared chat: shown when the conversation could not be opened.
  ///
  /// In en, this message translates to:
  /// **'This conversation is unavailable. You may no longer be a member.'**
  String get chatUnavailable;

  /// Shared chat and Rooms: retry button.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get chatTryAgain;

  /// Shared chat: status under a message that failed to send.
  ///
  /// In en, this message translates to:
  /// **'Not sent · tap and hold to retry'**
  String get chatStatusNotSent;

  /// Shared chat: status under a message that is being sent.
  ///
  /// In en, this message translates to:
  /// **'Sending…'**
  String get chatStatusSending;

  /// Shared chat: placeholder for a deleted or removed message.
  ///
  /// In en, this message translates to:
  /// **'Message removed'**
  String get chatMessageRemoved;

  /// Shared chat: screen reader label for your own message.
  ///
  /// In en, this message translates to:
  /// **'You at {time}'**
  String chatSemanticsYouAt(String time);

  /// Shared chat: screen reader label for someone else's message.
  ///
  /// In en, this message translates to:
  /// **'{name} at {time}'**
  String chatSemanticsMemberAt(String name, String time);

  /// Shared chat: screen reader label for a sender's name that opens their card.
  ///
  /// In en, this message translates to:
  /// **'About {name}'**
  String chatAboutMember(String name);

  /// Shared chat: hint in the message field.
  ///
  /// In en, this message translates to:
  /// **'Write a message'**
  String get chatComposerHint;

  /// Shared chat: hint in the disabled message field while the member is muted.
  ///
  /// In en, this message translates to:
  /// **'You can’t post right now'**
  String get chatMutedComposerHint;

  /// Shared chat: tooltip of the send button.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get chatSend;

  /// Shared chat: banner above the closed composer when a room host muted the member. {when} is a time or date and time.
  ///
  /// In en, this message translates to:
  /// **'You’re muted in this room until {when}. You can still read along.'**
  String chatRoomMutedUntil(String when);

  /// Shared chat: banner above the closed composer when a room host muted the member with no end time.
  ///
  /// In en, this message translates to:
  /// **'You’re muted in this room. You can still read along.'**
  String get chatRoomMuted;

  /// Shared chat: banner above the closed composer in a non-room conversation the member can read but not post in.
  ///
  /// In en, this message translates to:
  /// **'You can read this conversation but can’t post until {when}.'**
  String chatReadOnlyUntil(String when);

  /// Shared chat: banner above the closed composer in a conversation the member can read but not post in.
  ///
  /// In en, this message translates to:
  /// **'You can read this conversation but can’t post right now.'**
  String get chatReadOnly;

  /// Shared chat: tooltip of the bell that mutes a conversation's notifications.
  ///
  /// In en, this message translates to:
  /// **'Mute notifications'**
  String get chatMuteTooltip;

  /// Shared chat: tooltip of the bell while the conversation's notifications are muted.
  ///
  /// In en, this message translates to:
  /// **'Notifications muted'**
  String get chatMutedTooltip;

  /// Shared chat: title of the sheet that mutes a conversation's notifications.
  ///
  /// In en, this message translates to:
  /// **'Mute notifications'**
  String get chatMuteSheetTitle;

  /// Shared chat: explains muting notifications in the mute sheet.
  ///
  /// In en, this message translates to:
  /// **'Messages still arrive here, just without notifications.'**
  String get chatMuteSheetBody;

  /// Shared chat: mute notifications for one hour.
  ///
  /// In en, this message translates to:
  /// **'For 1 hour'**
  String get chatMuteOneHour;

  /// Shared chat: mute notifications for eight hours.
  ///
  /// In en, this message translates to:
  /// **'For 8 hours'**
  String get chatMuteEightHours;

  /// Shared chat: mute notifications for one week.
  ///
  /// In en, this message translates to:
  /// **'For 1 week'**
  String get chatMuteOneWeek;

  /// Shared chat: mute notifications until the member turns them back on.
  ///
  /// In en, this message translates to:
  /// **'Until I turn it back on'**
  String get chatMuteForever;

  /// Shared chat: turn a conversation's notifications back on.
  ///
  /// In en, this message translates to:
  /// **'Turn notifications back on'**
  String get chatUnmute;

  /// Shared chat: mute sheet line while notifications are muted until a time.
  ///
  /// In en, this message translates to:
  /// **'Muted until {when}'**
  String chatMutedUntilLabel(String when);

  /// Shared chat: mute sheet line while notifications are muted with no end.
  ///
  /// In en, this message translates to:
  /// **'Muted until you turn notifications back on.'**
  String get chatMutedIndefinitely;

  /// Shared chat: snack bar after muting notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications muted.'**
  String get chatMuteDone;

  /// Shared chat: snack bar after turning notifications back on.
  ///
  /// In en, this message translates to:
  /// **'Notifications are back on.'**
  String get chatUnmuteDone;

  /// Shared chat: snack bar when changing notifications failed.
  ///
  /// In en, this message translates to:
  /// **'Could not change notifications. Please retry.'**
  String get chatMuteFailed;

  /// Rooms: snack bar when tapping a room that has closed.
  ///
  /// In en, this message translates to:
  /// **'This room has closed.'**
  String get roomsClosedSnack;

  /// Rooms: snack bar when a joined room has no chat yet.
  ///
  /// In en, this message translates to:
  /// **'This room’s chat isn’t open yet.'**
  String get roomsChatNotOpen;

  /// Rooms: snack bar when joining a room failed.
  ///
  /// In en, this message translates to:
  /// **'Could not join this room. Please retry.'**
  String get roomsJoinFailed;

  /// Rooms: floating button and sheet title to start (host) a room.
  ///
  /// In en, this message translates to:
  /// **'Start a room'**
  String get roomsStartRoom;

  /// Rooms: small capitalised eyebrow above the page title.
  ///
  /// In en, this message translates to:
  /// **'LIVE CHAT'**
  String get roomsEyebrow;

  /// Rooms: page title. Keep consistent with the Conversation Rooms settings tile.
  ///
  /// In en, this message translates to:
  /// **'Rooms'**
  String get roomsTitle;

  /// Rooms: page subtitle.
  ///
  /// In en, this message translates to:
  /// **'Drop into a conversation. If you click with someone, add them as a friend.'**
  String get roomsSubtitle;

  /// Rooms: section label above the error panel.
  ///
  /// In en, this message translates to:
  /// **'ROOMS'**
  String get roomsSectionRooms;

  /// Rooms: section label for rooms the member is in.
  ///
  /// In en, this message translates to:
  /// **'YOUR ROOMS'**
  String get roomsSectionYours;

  /// Rooms: caption under 'Your rooms'.
  ///
  /// In en, this message translates to:
  /// **'Rooms you’re in. Tap to pick up the chat.'**
  String get roomsYoursCaption;

  /// Rooms: section label for rooms with people here now.
  ///
  /// In en, this message translates to:
  /// **'LIVE NOW'**
  String get roomsSectionLive;

  /// Rooms: title of the live now section.
  ///
  /// In en, this message translates to:
  /// **'Where people are talking'**
  String get roomsLiveTitle;

  /// Rooms: section label for browsing every open room.
  ///
  /// In en, this message translates to:
  /// **'BROWSE'**
  String get roomsSectionBrowse;

  /// Rooms: title of the browse section.
  ///
  /// In en, this message translates to:
  /// **'Find your room'**
  String get roomsBrowseTitle;

  /// Rooms: caption of the browse section.
  ///
  /// In en, this message translates to:
  /// **'Always open. Pick a topic, say hi, and see who you click with.'**
  String get roomsBrowseCaption;

  /// Rooms: empty browse list with the Friends here filter on.
  ///
  /// In en, this message translates to:
  /// **'None of your friends are in a room here right now.'**
  String get roomsNoFriendsHere;

  /// Rooms: empty browse list for a topic.
  ///
  /// In en, this message translates to:
  /// **'No rooms in this topic yet.'**
  String get roomsNoRoomsInTopic;

  /// Rooms: section label for hosted rooms that have not started.
  ///
  /// In en, this message translates to:
  /// **'COMING UP'**
  String get roomsSectionComingUp;

  /// Rooms: caption of the coming up section.
  ///
  /// In en, this message translates to:
  /// **'Rooms members are hosting. Join early to save a spot.'**
  String get roomsComingUpCaption;

  /// Rooms: topic filter chip for every topic.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get roomsCategoryAll;

  /// Rooms: topic name for conversation rooms (category talk).
  ///
  /// In en, this message translates to:
  /// **'Talk'**
  String get roomsCategoryTalk;

  /// Rooms: topic name for hobby rooms (category interests).
  ///
  /// In en, this message translates to:
  /// **'Interests'**
  String get roomsCategoryInterests;

  /// Rooms: topic name for outdoors, travel and fitness rooms (category active).
  ///
  /// In en, this message translates to:
  /// **'Out & about'**
  String get roomsCategoryActive;

  /// Rooms: topic name for city rooms (category city).
  ///
  /// In en, this message translates to:
  /// **'Your city'**
  String get roomsCategoryCity;

  /// Rooms: filter chip showing only rooms with friends in them.
  ///
  /// In en, this message translates to:
  /// **'Friends here'**
  String get roomsFriendsHereChip;

  /// Rooms: presence summary when nobody is here now.
  ///
  /// In en, this message translates to:
  /// **'Quiet right now. Be the first to say hello.'**
  String get roomsQuiet;

  /// Rooms: number of people, used inside roomsChattingIn.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 person} other{{count} people}}'**
  String roomsPeopleCount(int count);

  /// Rooms: number of rooms, used inside roomsChattingIn.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 room} other{{count} rooms}}'**
  String roomsRoomCount(int count);

  /// Rooms: live presence summary, e.g. '3 people chatting in 2 rooms'. {people} is roomsPeopleCount, {rooms} is roomsRoomCount.
  ///
  /// In en, this message translates to:
  /// **'{people} chatting in {rooms}'**
  String roomsChattingIn(String people, String rooms);

  /// Rooms: how many people are in the room right now.
  ///
  /// In en, this message translates to:
  /// **'{count} here now'**
  String roomsHereNow(int count);

  /// Rooms: how many members the room has.
  ///
  /// In en, this message translates to:
  /// **'{count} in the room'**
  String roomsInTheRoom(int count);

  /// Rooms: how many of the member's friends are in the room.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 friend here} other{{count} friends here}}'**
  String roomsFriendsHere(int count);

  /// Rooms: a room the member is hosting.
  ///
  /// In en, this message translates to:
  /// **'Hosted by you'**
  String get roomsHostedByYou;

  /// Rooms: who is hosting the room.
  ///
  /// In en, this message translates to:
  /// **'Hosted by {name}'**
  String roomsHostedBy(String name);

  /// Rooms: tile action for a room the member is in.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get roomsActionOpen;

  /// Rooms: tile label for a full room.
  ///
  /// In en, this message translates to:
  /// **'Full'**
  String get roomsActionFull;

  /// Rooms: tile action to join a room.
  ///
  /// In en, this message translates to:
  /// **'Join'**
  String get roomsActionJoin;

  /// Rooms: start time of a hosted room later today.
  ///
  /// In en, this message translates to:
  /// **'Starts {time}'**
  String roomsStartsAt(String time);

  /// Rooms: start date and time of a hosted room on another day.
  ///
  /// In en, this message translates to:
  /// **'Starts {day} {time}'**
  String roomsStartsOn(String day, String time);

  /// Rooms: start-room form error for a short name.
  ///
  /// In en, this message translates to:
  /// **'Give the room a name of at least 3 letters.'**
  String get roomsStartNameTooShort;

  /// Rooms: explains hosting at the top of the start-room sheet.
  ///
  /// In en, this message translates to:
  /// **'You host it: you can warn, mute or remove people, and close it when you’re done. One room at a time.'**
  String get roomsStartIntro;

  /// Rooms: start-room name field label.
  ///
  /// In en, this message translates to:
  /// **'Room name'**
  String get roomsStartNameLabel;

  /// Rooms: example room name in the start-room form.
  ///
  /// In en, this message translates to:
  /// **'Sunday book swap'**
  String get roomsStartNameHint;

  /// Rooms: start-room description field label.
  ///
  /// In en, this message translates to:
  /// **'What’s it about? (optional)'**
  String get roomsStartAboutLabel;

  /// Rooms: start-room topic label.
  ///
  /// In en, this message translates to:
  /// **'Topic'**
  String get roomsStartTopic;

  /// Rooms: start-room duration label.
  ///
  /// In en, this message translates to:
  /// **'How long'**
  String get roomsStartHowLong;

  /// Rooms: 30 minute room length.
  ///
  /// In en, this message translates to:
  /// **'30 min'**
  String get roomsLength30Min;

  /// Rooms: one hour room length.
  ///
  /// In en, this message translates to:
  /// **'1 hour'**
  String get roomsLength1Hour;

  /// Rooms: two hour room length.
  ///
  /// In en, this message translates to:
  /// **'2 hours'**
  String get roomsLength2Hours;

  /// Rooms: start-room submit button.
  ///
  /// In en, this message translates to:
  /// **'Start now'**
  String get roomsStartNow;

  /// Rooms: role label for a room's host.
  ///
  /// In en, this message translates to:
  /// **'Host'**
  String get roomsRoleHost;

  /// Rooms: role label for a room moderator.
  ///
  /// In en, this message translates to:
  /// **'Moderator'**
  String get roomsRoleModerator;

  /// Rooms: generic word for a room when its topic is unknown.
  ///
  /// In en, this message translates to:
  /// **'Room'**
  String get roomsRoomFallback;

  /// Rooms: shown in a room's chat before any messages.
  ///
  /// In en, this message translates to:
  /// **'You’re in. Say hello: everyone in {room} sees what you write here.'**
  String roomsChatEmpty(String room);

  /// Rooms: tooltip of the people button in a room's chat.
  ///
  /// In en, this message translates to:
  /// **'People in this room'**
  String get roomsPeopleTooltip;

  /// Rooms: confirm dialog title for leaving a room.
  ///
  /// In en, this message translates to:
  /// **'Leave {room}?'**
  String roomsLeaveTitle(String room);

  /// Rooms: confirm dialog body for leaving a room.
  ///
  /// In en, this message translates to:
  /// **'You’ll stop seeing this room’s messages. You can come back any time it’s open.'**
  String get roomsLeaveBody;

  /// Rooms: leave the room (menu item and confirm button).
  ///
  /// In en, this message translates to:
  /// **'Leave room'**
  String get roomsLeaveAction;

  /// Rooms: snack bar when leaving failed.
  ///
  /// In en, this message translates to:
  /// **'Could not leave. Please retry.'**
  String get roomsLeaveFailed;

  /// Rooms: confirm dialog title when a host closes their room.
  ///
  /// In en, this message translates to:
  /// **'Close {room}?'**
  String roomsCloseTitle(String room);

  /// Rooms: confirm dialog body when a host closes their room.
  ///
  /// In en, this message translates to:
  /// **'The chat ends for everyone in the room. This can’t be undone.'**
  String get roomsCloseBody;

  /// Rooms: close the room (menu item and confirm button).
  ///
  /// In en, this message translates to:
  /// **'Close room'**
  String get roomsCloseAction;

  /// Rooms: snack bar when closing failed.
  ///
  /// In en, this message translates to:
  /// **'Could not close. Please retry.'**
  String get roomsCloseFailed;

  /// Rooms: tooltip of the room chat menu.
  ///
  /// In en, this message translates to:
  /// **'Room options'**
  String get roomsMenuTooltip;

  /// Rooms: menu item and sheet title listing the people in the room.
  ///
  /// In en, this message translates to:
  /// **'People here'**
  String get roomsMenuPeople;

  /// Rooms: menu item for hosts and moderators.
  ///
  /// In en, this message translates to:
  /// **'Moderate'**
  String get roomsMenuModerate;

  /// Rooms: moderation sheet title.
  ///
  /// In en, this message translates to:
  /// **'Moderate {room}'**
  String roomsModerateTitle(String room);

  /// Rooms: moderation sheet explanation.
  ///
  /// In en, this message translates to:
  /// **'Tap someone to warn, mute or remove them. Muted members can still read; removed members can rejoin when the session ends.'**
  String get roomsModerateIntro;

  /// Rooms: people sheet explanation.
  ///
  /// In en, this message translates to:
  /// **'Click with someone? Add them as a friend to keep talking after the room.'**
  String get roomsPeopleIntro;

  /// Rooms: people sheet error.
  ///
  /// In en, this message translates to:
  /// **'Could not load who is here.'**
  String get roomsMembersLoadFailed;

  /// Rooms: member status, an accepted friend.
  ///
  /// In en, this message translates to:
  /// **'Friend'**
  String get roomsStatusFriend;

  /// Rooms: member status, here now.
  ///
  /// In en, this message translates to:
  /// **'Here now'**
  String get roomsStatusHereNow;

  /// Rooms: member status, in the room but not here right now.
  ///
  /// In en, this message translates to:
  /// **'In the room'**
  String get roomsStatusInRoom;

  /// Rooms: member card status when the person has left.
  ///
  /// In en, this message translates to:
  /// **'No longer in the room'**
  String get roomsStatusGone;

  /// Rooms: member status for hosts and moderators while the member is muted.
  ///
  /// In en, this message translates to:
  /// **'Muted until {time}'**
  String roomsStatusMutedUntil(String time);

  /// Rooms: the member's own row in the people list.
  ///
  /// In en, this message translates to:
  /// **'{name} (you)'**
  String roomsYouSuffix(String name);

  /// Rooms: confirm title for removing a member.
  ///
  /// In en, this message translates to:
  /// **'Remove {name} from the room?'**
  String roomsRemoveTitle(String name);

  /// Rooms: confirm body for removing a member from an always-on room.
  ///
  /// In en, this message translates to:
  /// **'{name} leaves the chat now and can come back after 24 hours.'**
  String roomsRemoveBodyAlwaysOn(String name);

  /// Rooms: confirm body for removing a member from a hosted room.
  ///
  /// In en, this message translates to:
  /// **'{name} leaves the chat now and can’t rejoin until this room ends.'**
  String roomsRemoveBodyHosted(String name);

  /// Rooms: confirm title for warning a member.
  ///
  /// In en, this message translates to:
  /// **'Warn {name}?'**
  String roomsWarnTitle(String name);

  /// Rooms: confirm body for warning a member.
  ///
  /// In en, this message translates to:
  /// **'{name} gets a private reminder to keep the conversation kind and on topic.'**
  String roomsWarnBody(String name);

  /// Rooms: confirm button for removing a member.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get roomsRemoveAction;

  /// Rooms: confirm button for warning a member.
  ///
  /// In en, this message translates to:
  /// **'Send warning'**
  String get roomsWarnAction;

  /// Rooms: snack bar after removing a member.
  ///
  /// In en, this message translates to:
  /// **'{name} was removed from the room.'**
  String roomsRemovedDone(String name);

  /// Rooms: snack bar after warning a member.
  ///
  /// In en, this message translates to:
  /// **'Warning sent to {name}.'**
  String roomsWarnedDone(String name);

  /// Rooms: snack bar when a moderation action failed.
  ///
  /// In en, this message translates to:
  /// **'That did not go through. Retry.'**
  String get roomsModerationFailed;

  /// Rooms: snack bar after blocking a member from their room card.
  ///
  /// In en, this message translates to:
  /// **'You blocked {name}. You won’t see each other’s messages here.'**
  String roomsBlockedDone(String name);

  /// Rooms: member card action to report the person.
  ///
  /// In en, this message translates to:
  /// **'Report'**
  String get roomsReport;

  /// Rooms: member card action to block the person.
  ///
  /// In en, this message translates to:
  /// **'Block'**
  String get roomsBlock;

  /// Rooms: small capitalised label above the moderation buttons on a member card.
  ///
  /// In en, this message translates to:
  /// **'MODERATE'**
  String get roomsModerateEyebrow;

  /// Rooms: member card moderation button to warn.
  ///
  /// In en, this message translates to:
  /// **'Warn'**
  String get roomsWarn;

  /// Rooms: member card moderation button to remove.
  ///
  /// In en, this message translates to:
  /// **'Remove from room'**
  String get roomsRemoveFromRoom;

  /// Rooms: member card moderation button to mute (the member can read but not post).
  ///
  /// In en, this message translates to:
  /// **'Mute'**
  String get roomsMute;

  /// Rooms: member card moderation button to lift a mute.
  ///
  /// In en, this message translates to:
  /// **'Unmute'**
  String get roomsUnmute;

  /// Rooms: title of the sheet choosing how long to mute a member.
  ///
  /// In en, this message translates to:
  /// **'Mute {name}?'**
  String roomsMuteSheetTitle(String name);

  /// Rooms: explains a mute in the mute duration sheet.
  ///
  /// In en, this message translates to:
  /// **'{name} can still read the chat but can’t post until the mute ends. They’ll get a private note.'**
  String roomsMuteSheetBody(String name);

  /// Rooms: mute a member for ten minutes.
  ///
  /// In en, this message translates to:
  /// **'For 10 minutes'**
  String get roomsMuteTenMinutes;

  /// Rooms: mute a member for one hour.
  ///
  /// In en, this message translates to:
  /// **'For 1 hour'**
  String get roomsMuteOneHour;

  /// Rooms: mute a member until the hosted room ends.
  ///
  /// In en, this message translates to:
  /// **'Until the room ends'**
  String get roomsMuteUntilEnd;

  /// Rooms: mute a member of an always-on room for 24 hours.
  ///
  /// In en, this message translates to:
  /// **'For 24 hours'**
  String get roomsMuteOneDay;

  /// Rooms: snack bar after muting a member.
  ///
  /// In en, this message translates to:
  /// **'{name} is muted.'**
  String roomsMutedDone(String name);

  /// Rooms: snack bar after lifting a mute.
  ///
  /// In en, this message translates to:
  /// **'{name} can post again.'**
  String roomsUnmutedDone(String name);

  /// Rich text editor: accessible label of the formatting toolbar.
  ///
  /// In en, this message translates to:
  /// **'Formatting'**
  String get richFormattingToolbar;

  /// Rich text editor: toolbar button to undo the last change.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get richUndo;

  /// Rich text editor: toolbar button to redo a change.
  ///
  /// In en, this message translates to:
  /// **'Redo'**
  String get richRedo;

  /// Rich text editor: toolbar toggle for bold text.
  ///
  /// In en, this message translates to:
  /// **'Bold'**
  String get richBold;

  /// Rich text editor: toolbar toggle for italic text.
  ///
  /// In en, this message translates to:
  /// **'Italic'**
  String get richItalic;

  /// Rich text editor: toolbar toggle for underlined text.
  ///
  /// In en, this message translates to:
  /// **'Underline'**
  String get richUnderline;

  /// Rich text editor: toolbar toggle for struck-through text.
  ///
  /// In en, this message translates to:
  /// **'Strikethrough'**
  String get richStrikethrough;

  /// Rich text editor: toolbar toggle that highlights text with a soft background.
  ///
  /// In en, this message translates to:
  /// **'Highlight'**
  String get richHighlight;

  /// Rich text editor: toolbar button to add or edit a web link on the selected words.
  ///
  /// In en, this message translates to:
  /// **'Link'**
  String get richLink;

  /// Rich text editor: toolbar menu to choose paragraph, heading, quote or callout.
  ///
  /// In en, this message translates to:
  /// **'Text style'**
  String get richTextStyleMenu;

  /// Rich text editor: plain body text (menu item).
  ///
  /// In en, this message translates to:
  /// **'Paragraph'**
  String get richParagraph;

  /// Rich text editor: large heading (menu item).
  ///
  /// In en, this message translates to:
  /// **'Heading'**
  String get richHeading;

  /// Rich text editor: smaller heading (menu item).
  ///
  /// In en, this message translates to:
  /// **'Subheading'**
  String get richSubheading;

  /// Rich text editor: quotation block (menu item).
  ///
  /// In en, this message translates to:
  /// **'Quote'**
  String get richQuote;

  /// Rich text editor: a softly boxed note that stands out from the story (menu item).
  ///
  /// In en, this message translates to:
  /// **'Callout'**
  String get richCallout;

  /// Rich text editor: toolbar toggle for a bulleted list.
  ///
  /// In en, this message translates to:
  /// **'Bulleted list'**
  String get richBulletList;

  /// Rich text editor: toolbar toggle for a numbered list.
  ///
  /// In en, this message translates to:
  /// **'Numbered list'**
  String get richNumberedList;

  /// Rich text editor: toolbar button that adds a section break; also the screen-reader label of a rendered break.
  ///
  /// In en, this message translates to:
  /// **'Section break'**
  String get richDivider;

  /// Rich text editor: toolbar menu for text alignment.
  ///
  /// In en, this message translates to:
  /// **'Alignment'**
  String get richAlignMenu;

  /// Rich text editor: align text to the start of the line (left in left-to-right languages).
  ///
  /// In en, this message translates to:
  /// **'Align to start'**
  String get richAlignStart;

  /// Rich text editor: centre text.
  ///
  /// In en, this message translates to:
  /// **'Center'**
  String get richAlignCenter;

  /// Rich text editor: align text to the end of the line (right in left-to-right languages).
  ///
  /// In en, this message translates to:
  /// **'Align to end'**
  String get richAlignEnd;

  /// Rich text editor: toolbar button that removes formatting from the selection.
  ///
  /// In en, this message translates to:
  /// **'Clear formatting'**
  String get richClearFormatting;

  /// Rich text editor: heading above the writing style choices (the overall look of a chapter or story).
  ///
  /// In en, this message translates to:
  /// **'Writing style'**
  String get richWritingStyle;

  /// Writing style name: elegant serif.
  ///
  /// In en, this message translates to:
  /// **'Classic'**
  String get richStyleClassic;

  /// Writing style description for Classic.
  ///
  /// In en, this message translates to:
  /// **'Elegant serif, like a printed page'**
  String get richStyleClassicHint;

  /// Writing style name: clean sans-serif.
  ///
  /// In en, this message translates to:
  /// **'Modern'**
  String get richStyleModern;

  /// Writing style description for Modern.
  ///
  /// In en, this message translates to:
  /// **'Clean and easy to read'**
  String get richStyleModernHint;

  /// Writing style name: italic serif, like a diary.
  ///
  /// In en, this message translates to:
  /// **'Journal'**
  String get richStyleJournal;

  /// Writing style description for Journal.
  ///
  /// In en, this message translates to:
  /// **'Warm italic, like a diary entry'**
  String get richStyleJournalHint;

  /// Writing style name: squared, evenly spaced letters.
  ///
  /// In en, this message translates to:
  /// **'Typewriter'**
  String get richStyleTypewriter;

  /// Writing style description for Typewriter.
  ///
  /// In en, this message translates to:
  /// **'Squared letters with extra spacing'**
  String get richStyleTypewriterHint;

  /// Writing style name: centred serif with generous spacing.
  ///
  /// In en, this message translates to:
  /// **'Poetic'**
  String get richStylePoetic;

  /// Writing style description for Poetic.
  ///
  /// In en, this message translates to:
  /// **'Centered lines with room to breathe'**
  String get richStylePoeticHint;

  /// Rich text editor: word count under the editor.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 word} other{{count} words}}'**
  String richWordCount(int count);

  /// Rich text editor: helper under the editor explaining that alignment and spacing appear in the preview and for readers.
  ///
  /// In en, this message translates to:
  /// **'Alignment and spacing show in Preview and for readers.'**
  String get richAlignmentNote;

  /// Rich text editor: title of the dialog for adding a link.
  ///
  /// In en, this message translates to:
  /// **'Add a link'**
  String get richLinkTitle;

  /// Rich text editor: label of the web address field in the link dialog.
  ///
  /// In en, this message translates to:
  /// **'Web address'**
  String get richLinkField;

  /// Rich text editor: error when the link is not a complete https address.
  ///
  /// In en, this message translates to:
  /// **'Use a complete https:// address.'**
  String get richLinkInvalid;

  /// Rich text editor: confirm button in the link dialog.
  ///
  /// In en, this message translates to:
  /// **'Add link'**
  String get richLinkApply;

  /// Rich text editor: removes the link from the selected words.
  ///
  /// In en, this message translates to:
  /// **'Remove link'**
  String get richLinkRemove;

  /// Rich text editor: message when the member taps Link without selecting words.
  ///
  /// In en, this message translates to:
  /// **'Select the words you want to link first.'**
  String get richLinkNeedsSelection;

  /// Rich text editor: cancel button in dialogs.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get richCancel;

  /// Reading view: title of the confirmation before opening a link someone wrote in their story.
  ///
  /// In en, this message translates to:
  /// **'Open this link?'**
  String get richOpenLinkTitle;

  /// Reading view: explains the link leaves the app. {host} is the website name.
  ///
  /// In en, this message translates to:
  /// **'{host} opens outside Connect. Only open links you trust.'**
  String richOpenLinkBody(String host);

  /// Reading view: confirm button that opens the link in the browser.
  ///
  /// In en, this message translates to:
  /// **'Open link'**
  String get richOpenLink;

  /// Support centre: uppercase eyebrow above the page title.
  ///
  /// In en, this message translates to:
  /// **'HELP & SUPPORT'**
  String get supportCentreEyebrow;

  /// Support centre: page title.
  ///
  /// In en, this message translates to:
  /// **'How can we help?'**
  String get supportCentreTitle;

  /// Support centre: one-line promise under the title.
  ///
  /// In en, this message translates to:
  /// **'Find a quick answer, or ask our team. Every request and reply stays in one private conversation.'**
  String get supportCentreSubtitle;

  /// Support centre: uppercase section label above the contact actions.
  ///
  /// In en, this message translates to:
  /// **'CONTACT US'**
  String get supportContactSection;

  /// Support centre: action that opens the new support request form.
  ///
  /// In en, this message translates to:
  /// **'Contact support'**
  String get supportContactTitle;

  /// Support centre: caption of the Contact support action.
  ///
  /// In en, this message translates to:
  /// **'Tell us what happened. We reply here and let you know.'**
  String get supportContactSubtitle;

  /// Support centre: action that opens the member's list of support requests.
  ///
  /// In en, this message translates to:
  /// **'My tickets'**
  String get supportMyTicketsTitle;

  /// Support centre: caption of My tickets when nothing is open or unread.
  ///
  /// In en, this message translates to:
  /// **'Follow your requests and our replies'**
  String get supportMyTicketsSubtitle;

  /// Support centre: caption of My tickets with the number of open requests.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 open request} other{{count} open requests}}'**
  String supportOpenRequests(int count);

  /// Support: number of unread replies from the support team (badge label and ticket row).
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 new reply} other{{count} new replies}}'**
  String supportUnreadReplies(int count);

  /// Support centre: uppercase section label above the self-help answers.
  ///
  /// In en, this message translates to:
  /// **'QUICK ANSWERS'**
  String get supportQuickAnswersSection;

  /// Support centre quick answer title about signing in.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get supportFaqLoginTitle;

  /// Support centre quick answer about signing in.
  ///
  /// In en, this message translates to:
  /// **'Sign in with your unique username and password.'**
  String get supportFaqLoginBody;

  /// Support centre quick answer title about identity verification.
  ///
  /// In en, this message translates to:
  /// **'Verification'**
  String get supportFaqVerificationTitle;

  /// Support centre quick answer about identity verification.
  ///
  /// In en, this message translates to:
  /// **'Identity verification is optional while the provider is paused.'**
  String get supportFaqVerificationBody;

  /// Support centre quick answer title about reporting abuse.
  ///
  /// In en, this message translates to:
  /// **'Abuse'**
  String get supportFaqAbuseTitle;

  /// Support centre quick answer about reporting abuse.
  ///
  /// In en, this message translates to:
  /// **'Use Report on a profile or conversation for faster safety triage.'**
  String get supportFaqAbuseBody;

  /// Support centre quick answer title about billing.
  ///
  /// In en, this message translates to:
  /// **'Billing'**
  String get supportFaqBillingTitle;

  /// Support centre quick answer about billing questions.
  ///
  /// In en, this message translates to:
  /// **'Include the transaction reference, never your card details.'**
  String get supportFaqBillingBody;

  /// Support centre: note that tickets are not an emergency service.
  ///
  /// In en, this message translates to:
  /// **'If someone is in immediate danger, contact local emergency services. Support tickets do not replace emergency help.'**
  String get supportEmergencyNote;

  /// Support: shown when support requests are switched off on the server.
  ///
  /// In en, this message translates to:
  /// **'Support requests are not available right now'**
  String get supportUnavailableTitle;

  /// Support: explains the fallback when support requests are switched off. Keep the email address unchanged.
  ///
  /// In en, this message translates to:
  /// **'The answers on this page still work. For anything urgent, email support@connect.example.'**
  String get supportUnavailableBody;

  /// Support: button returning from the request form to the support centre.
  ///
  /// In en, this message translates to:
  /// **'Back to Help & Support'**
  String get supportBackToHelp;

  /// Support request form: uppercase eyebrow above the title.
  ///
  /// In en, this message translates to:
  /// **'NEW REQUEST'**
  String get supportFormEyebrow;

  /// Support request form: page title.
  ///
  /// In en, this message translates to:
  /// **'Contact support'**
  String get supportFormTitle;

  /// Support request form: guidance under the title.
  ///
  /// In en, this message translates to:
  /// **'Give us enough detail to act. Never include a password, recovery code, card number or identity document.'**
  String get supportFormSubtitle;

  /// Support request form: uppercase section label above the topic choices.
  ///
  /// In en, this message translates to:
  /// **'TOPIC'**
  String get supportFormCategorySection;

  /// Support request form: question above the topic choices.
  ///
  /// In en, this message translates to:
  /// **'What do you need help with?'**
  String get supportFormCategoryLabel;

  /// Support topic: account and sign-in problems.
  ///
  /// In en, this message translates to:
  /// **'Account & login'**
  String get supportCategoryAccountLogin;

  /// Support topic: identity verification.
  ///
  /// In en, this message translates to:
  /// **'Verification'**
  String get supportCategoryVerification;

  /// Support topic: payments, subscriptions and billing.
  ///
  /// In en, this message translates to:
  /// **'Payments & billing'**
  String get supportCategoryPaymentsBilling;

  /// Support topic: safety concerns and harassment.
  ///
  /// In en, this message translates to:
  /// **'Safety & harassment'**
  String get supportCategorySafetyHarassment;

  /// Support topic: matches and chat.
  ///
  /// In en, this message translates to:
  /// **'Matches & chat'**
  String get supportCategoryMatchesChat;

  /// Support topic: technical problems and bugs.
  ///
  /// In en, this message translates to:
  /// **'Technical problem or bug'**
  String get supportCategoryTechnical;

  /// Support topic: suggesting a feature.
  ///
  /// In en, this message translates to:
  /// **'Feature request'**
  String get supportCategoryFeatureRequest;

  /// Support topic: privacy and personal data requests.
  ///
  /// In en, this message translates to:
  /// **'Privacy & data request'**
  String get supportCategoryPrivacyData;

  /// Support topic: anything else.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get supportCategoryOther;

  /// Support request form: note shown when the safety topic is chosen.
  ///
  /// In en, this message translates to:
  /// **'If you or someone else is in immediate danger, use SOS in the app or call your local emergency services. Safety requests are prioritized, but a ticket is not an emergency line.'**
  String get supportSafetyNote;

  /// Support request form: button opening the in-app SOS screen.
  ///
  /// In en, this message translates to:
  /// **'Open SOS'**
  String get supportOpenSos;

  /// Support request form: uppercase section label above subject and description.
  ///
  /// In en, this message translates to:
  /// **'DETAILS'**
  String get supportFormDetailsSection;

  /// Support request form: subject field label.
  ///
  /// In en, this message translates to:
  /// **'Subject'**
  String get supportFormSubjectLabel;

  /// Support request form: subject field hint.
  ///
  /// In en, this message translates to:
  /// **'Briefly describe the issue'**
  String get supportFormSubjectHint;

  /// Support request form: description field label.
  ///
  /// In en, this message translates to:
  /// **'What happened?'**
  String get supportFormDescriptionLabel;

  /// Support request form: description field hint.
  ///
  /// In en, this message translates to:
  /// **'What you did, what you expected and what happened instead'**
  String get supportFormDescriptionHint;

  /// Support request form: uppercase section label above screenshots.
  ///
  /// In en, this message translates to:
  /// **'SCREENSHOTS'**
  String get supportFormScreenshotsSection;

  /// Support request form: caption with the maximum number of screenshots.
  ///
  /// In en, this message translates to:
  /// **'Optional. Up to {max} images.'**
  String supportFormScreenshotsCaption(int max);

  /// Support request form: button to pick screenshots.
  ///
  /// In en, this message translates to:
  /// **'Add screenshot'**
  String get supportAddScreenshot;

  /// Support: tooltip of the button removing a chosen screenshot.
  ///
  /// In en, this message translates to:
  /// **'Remove {name}'**
  String supportRemoveAttachment(String name);

  /// Support: screen-reader label while a screenshot uploads.
  ///
  /// In en, this message translates to:
  /// **'Uploading'**
  String get supportAttachmentUploading;

  /// Support: tooltip of the button retrying a failed screenshot upload.
  ///
  /// In en, this message translates to:
  /// **'Retry upload'**
  String get supportRetryUpload;

  /// Support request form: explains which device details are attached.
  ///
  /// In en, this message translates to:
  /// **'We’ll include your app version ({version}), platform, system version and language to help us troubleshoot.'**
  String supportFormDeviceNote(String version);

  /// Support request form: submit button.
  ///
  /// In en, this message translates to:
  /// **'Send request'**
  String get supportSubmit;

  /// Support request form: error when no topic is chosen.
  ///
  /// In en, this message translates to:
  /// **'Choose a topic.'**
  String get supportErrorCategoryRequired;

  /// Support request form: error when the subject is too short or long.
  ///
  /// In en, this message translates to:
  /// **'Use {min} to {max} characters for the subject.'**
  String supportErrorSubjectLength(int min, int max);

  /// Support request form: error when the description is empty.
  ///
  /// In en, this message translates to:
  /// **'Describe what happened.'**
  String get supportErrorDescriptionRequired;

  /// Support: error when a message is too long.
  ///
  /// In en, this message translates to:
  /// **'Keep it under {max} characters.'**
  String supportErrorDescriptionTooLong(int max);

  /// Support: error when screenshots are still uploading or failed.
  ///
  /// In en, this message translates to:
  /// **'Wait for your screenshots to finish uploading, or remove any that failed.'**
  String get supportErrorUploadsPending;

  /// Support: snack bar after a request is created, with its reference number.
  ///
  /// In en, this message translates to:
  /// **'Request {reference} sent. We’ll reply here.'**
  String supportCreatedSnack(String reference);

  /// Support: snack bar when the same request was already sent in the last few minutes.
  ///
  /// In en, this message translates to:
  /// **'You already sent this request, so we opened it: {reference}.'**
  String supportDuplicateSnack(String reference);

  /// Support: error when too many requests were sent; minutes until retry.
  ///
  /// In en, this message translates to:
  /// **'{minutes, plural, =1{You’ve sent several requests in a short time. Try again in 1 minute.} other{You’ve sent several requests in a short time. Try again in {minutes} minutes.}}'**
  String supportErrorRateLimited(int minutes);

  /// Support: error when too many requests were sent, without a wait time.
  ///
  /// In en, this message translates to:
  /// **'You’ve sent several requests in a short time. Please try again later.'**
  String get supportErrorRateLimitedGeneric;

  /// Support: error when the member already has the maximum of 10 open requests.
  ///
  /// In en, this message translates to:
  /// **'You already have 10 open requests. Close one you no longer need, or wait for our replies.'**
  String get supportErrorTooManyOpen;

  /// Support: error replying to a request that can no longer be reopened.
  ///
  /// In en, this message translates to:
  /// **'This request is closed and can no longer be reopened. Please start a new request.'**
  String get supportErrorTicketClosed;

  /// Support: error when the 14-day reopen window has passed.
  ///
  /// In en, this message translates to:
  /// **'The time to reopen this request has passed. Please start a new request.'**
  String get supportErrorReopenWindowPassed;

  /// Support: error when the request was already rated.
  ///
  /// In en, this message translates to:
  /// **'You’ve already rated this request.'**
  String get supportErrorAlreadyRated;

  /// Support: error when rating a request that is not resolved.
  ///
  /// In en, this message translates to:
  /// **'You can rate a request once it’s resolved.'**
  String get supportErrorNotResolved;

  /// Support: error for an unsupported attachment type.
  ///
  /// In en, this message translates to:
  /// **'Only JPEG or PNG images and PDF files can be attached.'**
  String get supportErrorAttachmentType;

  /// Support: error for an attachment that is too large.
  ///
  /// In en, this message translates to:
  /// **'That file is too large. Images can be up to 8 MB.'**
  String get supportErrorAttachmentTooLarge;

  /// Support: error when the server cannot be reached.
  ///
  /// In en, this message translates to:
  /// **'Can’t reach Connect right now. Check your connection and try again.'**
  String get supportErrorOffline;

  /// Support: error when a request does not exist or is not the member's.
  ///
  /// In en, this message translates to:
  /// **'We couldn’t find this request.'**
  String get supportErrorNotFound;

  /// Support: fallback error message.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get supportErrorGeneric;

  /// Support: retry button after a failed load.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get supportTryAgain;

  /// My tickets: uppercase eyebrow above the page title.
  ///
  /// In en, this message translates to:
  /// **'SUPPORT'**
  String get supportTicketsEyebrow;

  /// My tickets: page title.
  ///
  /// In en, this message translates to:
  /// **'My tickets'**
  String get supportTicketsTitle;

  /// My tickets: line under the title.
  ///
  /// In en, this message translates to:
  /// **'Your requests and our replies.'**
  String get supportTicketsSubtitle;

  /// My tickets: uppercase section label for requests still in progress.
  ///
  /// In en, this message translates to:
  /// **'ACTIVE'**
  String get supportTicketsActiveSection;

  /// My tickets: uppercase section label for resolved and closed requests.
  ///
  /// In en, this message translates to:
  /// **'RESOLVED & CLOSED'**
  String get supportTicketsClosedSection;

  /// My tickets: empty state title.
  ///
  /// In en, this message translates to:
  /// **'No requests yet'**
  String get supportTicketsEmptyTitle;

  /// My tickets: empty state message.
  ///
  /// In en, this message translates to:
  /// **'When you contact support, your request and our replies appear here.'**
  String get supportTicketsEmptyBody;

  /// My tickets: title when the list fails to load.
  ///
  /// In en, this message translates to:
  /// **'Your requests couldn’t load'**
  String get supportTicketsLoadErrorTitle;

  /// My tickets: when a request last changed; when is a time or date.
  ///
  /// In en, this message translates to:
  /// **'Updated {when}'**
  String supportTicketUpdated(String when);

  /// My tickets: button to start a new request.
  ///
  /// In en, this message translates to:
  /// **'New request'**
  String get supportNewTicket;

  /// Support request status: new or being worked on.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get supportStatusOpen;

  /// Support request status: support is waiting for the member's answer.
  ///
  /// In en, this message translates to:
  /// **'Waiting for you'**
  String get supportStatusWaitingForYou;

  /// Support request status: paused by the support team.
  ///
  /// In en, this message translates to:
  /// **'On hold'**
  String get supportStatusOnHold;

  /// Support request status: resolved.
  ///
  /// In en, this message translates to:
  /// **'Resolved'**
  String get supportStatusResolved;

  /// Support request status: closed.
  ///
  /// In en, this message translates to:
  /// **'Closed'**
  String get supportStatusClosed;

  /// Support: screen-reader label of a status chip.
  ///
  /// In en, this message translates to:
  /// **'Status: {status}'**
  String supportStatusSemantics(String status);

  /// Support thread: name shown on replies from the support team. Keep the brand name Connect.
  ///
  /// In en, this message translates to:
  /// **'Connect Support'**
  String get supportThreadAgentName;

  /// Support thread: author label on the member's own messages.
  ///
  /// In en, this message translates to:
  /// **'You'**
  String get supportThreadYou;

  /// Support thread: topic and the date the request was opened.
  ///
  /// In en, this message translates to:
  /// **'{category} · Opened {date}'**
  String supportTicketMeta(String category, String date);

  /// Support thread banner for an open request.
  ///
  /// In en, this message translates to:
  /// **'We have your request. Our team will reply here and let you know.'**
  String get supportBannerOpen;

  /// Support thread banner when support is waiting for the member.
  ///
  /// In en, this message translates to:
  /// **'Support replied and is waiting for your answer.'**
  String get supportBannerWaiting;

  /// Support thread banner for a request on hold.
  ///
  /// In en, this message translates to:
  /// **'Your request is paused while we look into it. We’ll update you here.'**
  String get supportBannerOnHold;

  /// Support thread banner for a resolved request.
  ///
  /// In en, this message translates to:
  /// **'Marked as resolved. Reply to reopen it; otherwise it closes automatically after 7 days.'**
  String get supportBannerResolved;

  /// Support thread banner for a closed request that can still be reopened.
  ///
  /// In en, this message translates to:
  /// **'This request is closed. You can reopen it until {date}.'**
  String supportBannerClosedUntil(String date);

  /// Support thread banner for a closed request.
  ///
  /// In en, this message translates to:
  /// **'This request is closed.'**
  String get supportBannerClosed;

  /// Support thread banner when the request was merged into another.
  ///
  /// In en, this message translates to:
  /// **'This request was merged into {reference}. The conversation continues there.'**
  String supportBannerMerged(String reference);

  /// Support thread: reply field hint.
  ///
  /// In en, this message translates to:
  /// **'Write a reply'**
  String get supportReplyHint;

  /// Support thread: reply field hint when replies are not possible.
  ///
  /// In en, this message translates to:
  /// **'Replies are closed for this request'**
  String get supportReplyDisabledHint;

  /// Support thread: tooltip of the send button.
  ///
  /// In en, this message translates to:
  /// **'Send reply'**
  String get supportSendReply;

  /// Support thread: tooltip of the attach screenshot button.
  ///
  /// In en, this message translates to:
  /// **'Attach screenshot'**
  String get supportAttachScreenshot;

  /// Support thread: button and dialog action closing the request.
  ///
  /// In en, this message translates to:
  /// **'Close request'**
  String get supportCloseTicket;

  /// Support thread: close confirmation dialog title.
  ///
  /// In en, this message translates to:
  /// **'Close this request?'**
  String get supportCloseConfirmTitle;

  /// Support thread: close confirmation dialog message.
  ///
  /// In en, this message translates to:
  /// **'Close it if your problem is solved. You can reopen it for 14 days.'**
  String get supportCloseConfirmBody;

  /// Support: cancel button in a dialog.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get supportCancel;

  /// Support thread: snack bar after closing a request.
  ///
  /// In en, this message translates to:
  /// **'Request closed.'**
  String get supportClosedSnack;

  /// Support thread: button reopening a closed request.
  ///
  /// In en, this message translates to:
  /// **'Reopen request'**
  String get supportReopen;

  /// Support thread: snack bar after reopening a request.
  ///
  /// In en, this message translates to:
  /// **'Request reopened.'**
  String get supportReopenedSnack;

  /// Support thread: heading of the satisfaction rating card.
  ///
  /// In en, this message translates to:
  /// **'How did we do?'**
  String get supportRateTitle;

  /// Support thread: caption of the satisfaction rating card.
  ///
  /// In en, this message translates to:
  /// **'Rate your experience with this request.'**
  String get supportRateCaption;

  /// Support thread: tooltip of a rating star button.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 star} other{{count} stars}}'**
  String supportRateStar(int count);

  /// Support thread: optional rating comment field label.
  ///
  /// In en, this message translates to:
  /// **'Anything to add? (optional)'**
  String get supportRateCommentLabel;

  /// Support thread: button sending the rating.
  ///
  /// In en, this message translates to:
  /// **'Send rating'**
  String get supportRateSubmit;

  /// Support thread: heading once the member has rated the request.
  ///
  /// In en, this message translates to:
  /// **'Thanks for your feedback'**
  String get supportRatedTitle;

  /// Support thread: the rating the member gave, out of five.
  ///
  /// In en, this message translates to:
  /// **'You rated this {rating} out of 5.'**
  String supportRatedValue(int rating);

  /// Support thread: snack bar after sending a rating.
  ///
  /// In en, this message translates to:
  /// **'Thanks for rating your experience.'**
  String get supportRatingSnack;

  /// Support thread: screen-reader label of an attached screenshot.
  ///
  /// In en, this message translates to:
  /// **'Screenshot {name}'**
  String supportAttachmentImage(String name);

  /// Support thread: tooltip when an attachment cannot be loaded.
  ///
  /// In en, this message translates to:
  /// **'Couldn’t load attachment'**
  String get supportAttachmentLoadFailed;

  /// Support thread: title when the request fails to load.
  ///
  /// In en, this message translates to:
  /// **'This request couldn’t load'**
  String get supportThreadLoadErrorTitle;

  /// Chat connection card: secondary action that opens the private "A little chemistry" moment sheet (pick an answer, both answers are revealed together).
  ///
  /// In en, this message translates to:
  /// **'A little chemistry?'**
  String get chemistryCardEntry;

  /// Member profile hero: small eyebrow above another member's name, like a film credit.
  ///
  /// In en, this message translates to:
  /// **'Introducing'**
  String get memberProfileIntroducing;

  /// Own profile hero: small eyebrow above the member's own name, like a film credit.
  ///
  /// In en, this message translates to:
  /// **'Starring'**
  String get memberProfileStarring;

  /// Member profile: screen-reader word added after the name when the member is verified.
  ///
  /// In en, this message translates to:
  /// **'Verified'**
  String get memberProfileVerified;

  /// Member profile: screen-reader label of a photo.
  ///
  /// In en, this message translates to:
  /// **'{name}, photo {index} of {count}'**
  String memberProfilePhotoLabel(String name, int index, int count);

  /// Member profile: screen-reader label of the initials placeholder shown when there is no photo.
  ///
  /// In en, this message translates to:
  /// **'No photo yet'**
  String get memberProfileNoPhoto;

  /// Member profile: screen-reader hint for tapping a photo (read as 'Double tap to …').
  ///
  /// In en, this message translates to:
  /// **'view full screen'**
  String get memberProfileViewPhotoHint;

  /// Full-screen photo gallery: tooltip of the close button.
  ///
  /// In en, this message translates to:
  /// **'Close photos'**
  String get memberProfileCloseGallery;

  /// Member profile: eyebrow of the film-strip of photos.
  ///
  /// In en, this message translates to:
  /// **'Photos'**
  String get memberProfilePhotos;

  /// Member profile: count beside the photo strip of the photos after the main one.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 more photo} other{{count} more photos}}'**
  String memberProfileMorePhotos(int count);

  /// Member profile: eyebrow of the About section (the member's bio).
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get memberProfileSceneAbout;

  /// Member profile: eyebrow of the profile stories section.
  ///
  /// In en, this message translates to:
  /// **'Stories'**
  String get memberProfileSceneStories;

  /// Member profile: title of the profile stories section, in the member's voice.
  ///
  /// In en, this message translates to:
  /// **'A little more me'**
  String get memberProfileSceneStoriesTitle;

  /// Member profile: eyebrow of the interests section.
  ///
  /// In en, this message translates to:
  /// **'Interests'**
  String get memberProfileSceneInterests;

  /// Member profile: eyebrow of the facts grid (height, work, education...).
  ///
  /// In en, this message translates to:
  /// **'The basics'**
  String get memberProfileSceneBasics;

  /// Member profile: eyebrow of the lifestyle section.
  ///
  /// In en, this message translates to:
  /// **'Lifestyle'**
  String get memberProfileSceneLifestyle;

  /// Member profile: eyebrow of the verification and vouches section.
  ///
  /// In en, this message translates to:
  /// **'Trust'**
  String get memberProfileSceneTrust;

  /// Member profile: button that unfolds a long bio.
  ///
  /// In en, this message translates to:
  /// **'Read more'**
  String get memberProfileReadMore;

  /// Member profile: button that folds an unfolded bio.
  ///
  /// In en, this message translates to:
  /// **'Read less'**
  String get memberProfileReadLess;

  /// Member profile: label of the hobbies pills.
  ///
  /// In en, this message translates to:
  /// **'Hobbies'**
  String get memberProfileHobbies;

  /// Member profile: label of the activities pills.
  ///
  /// In en, this message translates to:
  /// **'Activities'**
  String get memberProfileActivities;

  /// Member profile: label of the favourite songs pills.
  ///
  /// In en, this message translates to:
  /// **'On repeat'**
  String get memberProfileSongs;

  /// Member profile: label of the favourite books and novels pills.
  ///
  /// In en, this message translates to:
  /// **'Books & novels'**
  String get memberProfileBooks;

  /// Member profile: label of the relationship intent pills.
  ///
  /// In en, this message translates to:
  /// **'Looking for'**
  String get memberProfileLookingFor;

  /// Member profile: label of the languages pills.
  ///
  /// In en, this message translates to:
  /// **'Languages'**
  String get memberProfileLanguages;

  /// Member profile: label of the deal-breaker pills.
  ///
  /// In en, this message translates to:
  /// **'Deal breakers'**
  String get memberProfileDealBreakers;

  /// Member profile: label of the pills the viewer and the member share.
  ///
  /// In en, this message translates to:
  /// **'In common'**
  String get memberProfileInCommon;

  /// Member profile fact label.
  ///
  /// In en, this message translates to:
  /// **'Height'**
  String get memberProfileFactHeight;

  /// Member profile: a height in centimetres.
  ///
  /// In en, this message translates to:
  /// **'{cm} cm'**
  String memberProfileHeightCm(int cm);

  /// Member profile fact label: profession.
  ///
  /// In en, this message translates to:
  /// **'Work'**
  String get memberProfileFactWork;

  /// Member profile fact label.
  ///
  /// In en, this message translates to:
  /// **'Education'**
  String get memberProfileFactEducation;

  /// Member profile fact label: city, region and country.
  ///
  /// In en, this message translates to:
  /// **'Lives in'**
  String get memberProfileFactLivesIn;

  /// Member profile fact label.
  ///
  /// In en, this message translates to:
  /// **'Mother tongue'**
  String get memberProfileFactMotherTongue;

  /// Member profile fact label.
  ///
  /// In en, this message translates to:
  /// **'Religion'**
  String get memberProfileFactReligion;

  /// Member profile fact label.
  ///
  /// In en, this message translates to:
  /// **'Personality'**
  String get memberProfileFactPersonality;

  /// Member profile fact label: relationship status.
  ///
  /// In en, this message translates to:
  /// **'Relationship'**
  String get memberProfileFactRelationship;

  /// Member profile fact label: Instagram handle.
  ///
  /// In en, this message translates to:
  /// **'Instagram'**
  String get memberProfileFactInstagram;

  /// Member profile lifestyle label.
  ///
  /// In en, this message translates to:
  /// **'Drinking'**
  String get memberProfileFactDrinking;

  /// Member profile lifestyle label.
  ///
  /// In en, this message translates to:
  /// **'Smoking'**
  String get memberProfileFactSmoking;

  /// Member profile lifestyle label.
  ///
  /// In en, this message translates to:
  /// **'Workout'**
  String get memberProfileFactWorkout;

  /// Member profile lifestyle label: diet preference.
  ///
  /// In en, this message translates to:
  /// **'Diet'**
  String get memberProfileFactDiet;

  /// Member profile lifestyle label.
  ///
  /// In en, this message translates to:
  /// **'Diet type'**
  String get memberProfileFactDietType;

  /// Member profile lifestyle label: sleep schedule.
  ///
  /// In en, this message translates to:
  /// **'Sleep'**
  String get memberProfileFactSleep;

  /// Member profile lifestyle label: travel style.
  ///
  /// In en, this message translates to:
  /// **'Travel'**
  String get memberProfileFactTravel;

  /// Member profile lifestyle label: pet preference.
  ///
  /// In en, this message translates to:
  /// **'Pets'**
  String get memberProfileFactPets;

  /// Member profile lifestyle label: political comfort range.
  ///
  /// In en, this message translates to:
  /// **'Politics'**
  String get memberProfileFactPolitics;

  /// Member profile lifestyle label (value is yes or no).
  ///
  /// In en, this message translates to:
  /// **'Open to casual'**
  String get memberProfileFactOpenToCasual;

  /// Member profile lifestyle label (shown only when yes).
  ///
  /// In en, this message translates to:
  /// **'Loves a party'**
  String get memberProfileFactPartyLover;

  /// Member profile trust section: title when the member is verified.
  ///
  /// In en, this message translates to:
  /// **'Verified profile'**
  String get memberProfileVerifiedTitle;

  /// Member profile trust section: line under the verified title.
  ///
  /// In en, this message translates to:
  /// **'Identity verification completed.'**
  String get memberProfileVerifiedBody;

  /// Member profile trust section: heading of the vouches written by the member's friends.
  ///
  /// In en, this message translates to:
  /// **'Vouched for by friends'**
  String get memberProfileVouchesTitle;

  /// Member profile hero: pill when the member is in the Spotlight.
  ///
  /// In en, this message translates to:
  /// **'Spotlight'**
  String get memberProfileSpotlight;

  /// Member profile hero: pill when the member's availability overlaps the viewer's.
  ///
  /// In en, this message translates to:
  /// **'Free when you are'**
  String get memberProfileFreeWhenYouAre;

  /// Member profile action dock: opens a conversation.
  ///
  /// In en, this message translates to:
  /// **'Message'**
  String get memberProfileMessage;

  /// Member profile action dock: sends a love (super like).
  ///
  /// In en, this message translates to:
  /// **'Love'**
  String get memberProfileLove;

  /// Member profile top bar: tooltip of the report button.
  ///
  /// In en, this message translates to:
  /// **'Report'**
  String get memberProfileReport;

  /// Own profile: eyebrow of the owner tools panel under the hero.
  ///
  /// In en, this message translates to:
  /// **'This is how you appear'**
  String get memberProfileOwnerTitle;

  /// Own profile: line under the owner tools eyebrow.
  ///
  /// In en, this message translates to:
  /// **'Members see your profile just like this.'**
  String get memberProfileOwnerCaption;

  /// Own profile: completeness meter label.
  ///
  /// In en, this message translates to:
  /// **'Profile {percent}% complete'**
  String memberProfileCompleteness(int percent);

  /// Own profile: hint under the completeness meter when below 100%.
  ///
  /// In en, this message translates to:
  /// **'Add photos, stories and details to stand out.'**
  String get memberProfileCompletenessHint;

  /// Own profile: line under the completeness meter at 100%.
  ///
  /// In en, this message translates to:
  /// **'Your profile is complete.'**
  String get memberProfileCompletenessDone;

  /// Own profile owner tool: opens Edit profile.
  ///
  /// In en, this message translates to:
  /// **'Edit profile'**
  String get memberProfileToolEdit;

  /// Own profile owner tool: opens the photo manager.
  ///
  /// In en, this message translates to:
  /// **'Edit photos'**
  String get memberProfileToolPhotos;

  /// Own profile owner tool: opens the profile stories editor.
  ///
  /// In en, this message translates to:
  /// **'Your stories'**
  String get memberProfileToolStories;

  /// Own profile owner tool: opens who viewed the profile.
  ///
  /// In en, this message translates to:
  /// **'Who viewed you'**
  String get memberProfileToolViewers;

  /// Own profile: heading of the owner-only part (stats, likes, preferences).
  ///
  /// In en, this message translates to:
  /// **'Behind the scenes'**
  String get memberProfileBehindTheScenes;

  /// Own profile: line under Behind the scenes.
  ///
  /// In en, this message translates to:
  /// **'Only you can see this.'**
  String get memberProfileOnlyYou;

  /// Own profile: title in the collapsed top bar and placeholder name while loading.
  ///
  /// In en, this message translates to:
  /// **'My profile'**
  String get memberProfileMine;

  /// Profile: eyebrow of the section with the member's public chapters and wall photos.
  ///
  /// In en, this message translates to:
  /// **'Writing & moments'**
  String get profileShowcaseLabel;

  /// Profile: title of that section on another member's profile.
  ///
  /// In en, this message translates to:
  /// **'In their own words'**
  String get profileShowcaseTitleOther;

  /// Own profile: title of that section.
  ///
  /// In en, this message translates to:
  /// **'Your public writing & photos'**
  String get profileShowcaseTitleSelf;

  /// Profile: sub-heading above the public chapters.
  ///
  /// In en, this message translates to:
  /// **'Chapters'**
  String get profileShowcaseChapters;

  /// Profile: sub-heading above the wall photos.
  ///
  /// In en, this message translates to:
  /// **'Wall photos'**
  String get profileShowcasePhotos;

  /// Profile: link to all of the member's chapters.
  ///
  /// In en, this message translates to:
  /// **'Read all their chapters'**
  String get profileShowcaseReadAll;

  /// Own profile: the section is a private preview because consent is off.
  ///
  /// In en, this message translates to:
  /// **'Only you can see this'**
  String get profileShowcaseHiddenTitle;

  /// Own profile: explains that public writing is hidden until the member turns it on.
  ///
  /// In en, this message translates to:
  /// **'Your public chapters and wall photos are hidden from your profile. Turn this on to let members see them here.'**
  String get profileShowcaseHiddenBody;

  /// Own profile: explains what members see with consent on.
  ///
  /// In en, this message translates to:
  /// **'Members can see these on your profile. Only chapters shared with the community and photos on the wall appear.'**
  String get profileShowcaseShownBody;

  /// Own profile and privacy: switch to show public writing and wall photos on the profile.
  ///
  /// In en, this message translates to:
  /// **'Show on my profile'**
  String get profileShowcaseSwitch;

  /// Snack bar when the choice could not be saved.
  ///
  /// In en, this message translates to:
  /// **'Your choice could not be saved.'**
  String get profileShowcaseSaveFailed;

  /// Calls: title of the call history screen.
  ///
  /// In en, this message translates to:
  /// **'Call history'**
  String get callsHistoryTitle;

  /// Calls: shown on the call history screen when there are no calls yet.
  ///
  /// In en, this message translates to:
  /// **'No call sessions yet.'**
  String get callsHistoryEmpty;

  /// Calls: secondary line on a call history row naming the match by a short id.
  ///
  /// In en, this message translates to:
  /// **'Match {id}'**
  String callsHistoryMatch(String id);

  /// Calls: button/tooltip that opens the live video room in the provider window.
  ///
  /// In en, this message translates to:
  /// **'Join live room'**
  String get callsJoinLiveRoom;

  /// Calls: call history row title for a call that has not ended yet.
  ///
  /// In en, this message translates to:
  /// **'Active call session'**
  String get callsActiveSession;

  /// Calls: call history row title for an ended call, with its duration as minutes:seconds.
  ///
  /// In en, this message translates to:
  /// **'Ended · {duration}'**
  String callsEndedWithDuration(String duration);

  /// Calls: app bar title of the in-call screen.
  ///
  /// In en, this message translates to:
  /// **'Call session'**
  String get callsSessionTitle;

  /// Calls: status while the call session is being created.
  ///
  /// In en, this message translates to:
  /// **'Starting secure session…'**
  String get callsStarting;

  /// Calls: status when the call session is running.
  ///
  /// In en, this message translates to:
  /// **'Session active'**
  String get callsSessionActive;

  /// Calls: status when no call session could be started.
  ///
  /// In en, this message translates to:
  /// **'Session unavailable'**
  String get callsSessionUnavailable;

  /// Calls: explanation under the call status that the live room opens in the video provider's own window.
  ///
  /// In en, this message translates to:
  /// **'The live room opens in a secure provider window. Use that room’s microphone, camera, and leave controls during the call.'**
  String get callsLiveRoomNote;

  /// Calls: label under the button that ends the call.
  ///
  /// In en, this message translates to:
  /// **'End'**
  String get callsEnd;

  /// Calls: error when the call history is opened while signed out.
  ///
  /// In en, this message translates to:
  /// **'Please sign in to view call history.'**
  String get callsErrorSignInHistory;

  /// Calls: error when a call is started while signed out.
  ///
  /// In en, this message translates to:
  /// **'Please sign in before starting a call.'**
  String get callsErrorSignInStart;

  /// Calls: error when camera/microphone permission was denied.
  ///
  /// In en, this message translates to:
  /// **'Camera and microphone permissions are required for calls.'**
  String get callsErrorPermissions;

  /// Calls: fallback error when the call history could not be loaded.
  ///
  /// In en, this message translates to:
  /// **'Unable to load call history.'**
  String get callsErrorLoadHistory;

  /// Calls: fallback error when the call session could not be started.
  ///
  /// In en, this message translates to:
  /// **'Unable to start the call session.'**
  String get callsErrorStart;

  /// Calls: fallback error when the call could not be ended.
  ///
  /// In en, this message translates to:
  /// **'Unable to end the call.'**
  String get callsErrorEnd;

  /// Calls: error when the live video room has no usable link in this environment.
  ///
  /// In en, this message translates to:
  /// **'Live call rooms are not configured for this environment.'**
  String get callsErrorNotConfigured;

  /// Calls: error when the live video room could not be opened.
  ///
  /// In en, this message translates to:
  /// **'Unable to open the live call room.'**
  String get callsErrorOpenRoom;

  /// Generic button: retry a failed load or action.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get commonRetry;

  /// Generic button: cancel and close a dialog.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get commonCancel;

  /// Generic button: close a dialog or sheet.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get commonClose;

  /// Generic button: copy text to the clipboard.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get commonCopy;

  /// Generic destructive button: delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get commonDelete;

  /// Generic back button / tooltip.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get commonBack;

  /// Generic button: apply chosen settings or filters.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get commonApply;

  /// Generic button: reset settings or filters to defaults.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get commonReset;

  /// Generic action: open the item (e.g. snackbar action).
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get commonOpen;

  /// Generic button: view the item in detail.
  ///
  /// In en, this message translates to:
  /// **'View'**
  String get commonView;

  /// Generic button: dismiss an alert.
  ///
  /// In en, this message translates to:
  /// **'Dismiss'**
  String get commonDismiss;

  /// Dropdown placeholder meaning no filter is set (any value).
  ///
  /// In en, this message translates to:
  /// **'Any'**
  String get commonAny;

  /// Generic error heading.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong'**
  String get commonSomethingWentWrong;

  /// Generic error message after a failed action.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get commonSomethingWentWrongTryAgain;

  /// Generic retry button on error states (title case).
  ///
  /// In en, this message translates to:
  /// **'Try Again'**
  String get commonTryAgainTitle;

  /// Generic empty-state heading.
  ///
  /// In en, this message translates to:
  /// **'Nothing here yet'**
  String get commonNothingHereYet;

  /// Accessibility label for a button that is busy. {label} is the button text.
  ///
  /// In en, this message translates to:
  /// **'{label}, loading'**
  String commonLoadingLabel(String label);

  /// A distance in kilometres, e.g. '50 km'.
  ///
  /// In en, this message translates to:
  /// **'{distance} km'**
  String commonDistanceKm(int distance);

  /// Bottom navigation tab: the Today home screen (intentional dating).
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get navToday;

  /// Banner when the app is offline and showing cached data.
  ///
  /// In en, this message translates to:
  /// **'Offline mode: Some data may be outdated.'**
  String get navOfflineBanner;

  /// Banner when the connection is slow. {mbps} is the recommended bandwidth.
  ///
  /// In en, this message translates to:
  /// **'Weak network detected. Use at least {mbps} Mbps for smoother app performance.'**
  String navWeakNetworkBanner(int mbps);

  /// Sheet title when a push for an incoming call is opened.
  ///
  /// In en, this message translates to:
  /// **'Incoming call'**
  String get navIncomingCallTitle;

  /// Sheet body for an incoming call push.
  ///
  /// In en, this message translates to:
  /// **'A match is calling you.'**
  String get navIncomingCallBody;

  /// Button in the incoming call sheet: open notifications for the call.
  ///
  /// In en, this message translates to:
  /// **'View call details'**
  String get navViewCallDetails;

  /// Title of the Discover / Matches filter sheet.
  ///
  /// In en, this message translates to:
  /// **'Filter Matches'**
  String get filterSheetTitle;

  /// Filter sheet section: age range slider.
  ///
  /// In en, this message translates to:
  /// **'Age Range'**
  String get filterAgeRange;

  /// Filter sheet section: profile and lifestyle dropdowns.
  ///
  /// In en, this message translates to:
  /// **'Profile & Lifestyle Filters'**
  String get filterProfileLifestyle;

  /// Filter dropdown label: country.
  ///
  /// In en, this message translates to:
  /// **'Country'**
  String get filterCountry;

  /// Filter dropdown label: state / region.
  ///
  /// In en, this message translates to:
  /// **'State'**
  String get filterState;

  /// Filter dropdown label: city.
  ///
  /// In en, this message translates to:
  /// **'City'**
  String get filterCity;

  /// Filter dropdown label: mother tongue.
  ///
  /// In en, this message translates to:
  /// **'Mother Tongue'**
  String get filterMotherTongue;

  /// Filter dropdown label: religion.
  ///
  /// In en, this message translates to:
  /// **'Religion'**
  String get filterReligion;

  /// Filter dropdown label: relationship status.
  ///
  /// In en, this message translates to:
  /// **'Relationship Status'**
  String get filterRelationshipStatus;

  /// Filter dropdown label: smoking habit.
  ///
  /// In en, this message translates to:
  /// **'Smoking'**
  String get filterSmoking;

  /// Filter dropdown label: drinking habit.
  ///
  /// In en, this message translates to:
  /// **'Drinking'**
  String get filterDrinking;

  /// Filter dropdown label: personality type.
  ///
  /// In en, this message translates to:
  /// **'Personality Type'**
  String get filterPersonalityType;

  /// Filter switch: only people who love parties.
  ///
  /// In en, this message translates to:
  /// **'Party lover only'**
  String get filterPartyLoverOnly;

  /// Filter switch: only people looking for hookups.
  ///
  /// In en, this message translates to:
  /// **'Hookups only'**
  String get filterHookupsOnly;

  /// Filter sheet section: advanced bio filters managed elsewhere.
  ///
  /// In en, this message translates to:
  /// **'Advanced Bio Filters'**
  String get filterAdvancedBio;

  /// Explains where advanced bio filters are managed.
  ///
  /// In en, this message translates to:
  /// **'Books, novels, songs, hobbies, location and extra-curricular tags can be managed in Settings → Dating Preferences.'**
  String get filterAdvancedBioBody;

  /// Button: open the dating preferences screen.
  ///
  /// In en, this message translates to:
  /// **'Open Dating Preferences'**
  String get filterOpenDatingPreferences;

  /// Filter sheet section: maximum distance slider, in kilometres.
  ///
  /// In en, this message translates to:
  /// **'Distance (km)'**
  String get filterDistanceKm;

  /// Filter sheet section: verified profiles only.
  ///
  /// In en, this message translates to:
  /// **'Verified Only'**
  String get filterVerifiedOnlyTitle;

  /// Switch label: show only verified profiles.
  ///
  /// In en, this message translates to:
  /// **'Show only verified profiles'**
  String get filterVerifiedOnlyBody;

  /// Active filter chip: verified only.
  ///
  /// In en, this message translates to:
  /// **'Verified only'**
  String get filterVerifiedOnlyChip;

  /// Active filter chip: party lovers only.
  ///
  /// In en, this message translates to:
  /// **'Party lover'**
  String get filterPartyLoverChip;

  /// Active filter chip: hookups only.
  ///
  /// In en, this message translates to:
  /// **'Hookup only'**
  String get filterHookupChip;

  /// Switch label: enable trust-badge based filtering.
  ///
  /// In en, this message translates to:
  /// **'Enable trust-based filtering'**
  String get filterEnableTrust;

  /// Label above the slider for the minimum number of trust badges.
  ///
  /// In en, this message translates to:
  /// **'Minimum active trust badges: {count}'**
  String filterMinimumTrustBadges(int count);

  /// Snackbar after saving filters. verified/trust are 'true' or 'false'.
  ///
  /// In en, this message translates to:
  /// **'Filters saved: {minAge}-{maxAge} yrs, {distance} km{verified, select, true{, verified only} other{}}{trust, select, true{, trust filter on} other{, trust filter off}}'**
  String filterSavedSnack(
    int minAge,
    int maxAge,
    int distance,
    String verified,
    String trust,
  );

  /// Display label for the profile/filter option stored as 'Never'.
  ///
  /// In en, this message translates to:
  /// **'Never'**
  String get optionNever;

  /// Display label for the profile/filter option stored as 'Occasionally'.
  ///
  /// In en, this message translates to:
  /// **'Occasionally'**
  String get optionOccasionally;

  /// Display label for the profile/filter option stored as 'Socially'.
  ///
  /// In en, this message translates to:
  /// **'Socially'**
  String get optionSocially;

  /// Display label for the profile/filter option stored as 'Regularly'.
  ///
  /// In en, this message translates to:
  /// **'Regularly'**
  String get optionRegularly;

  /// Display label for the profile/filter option stored as 'Single'.
  ///
  /// In en, this message translates to:
  /// **'Single'**
  String get optionSingle;

  /// Display label for the profile/filter option stored as 'Divorced'.
  ///
  /// In en, this message translates to:
  /// **'Divorced'**
  String get optionDivorced;

  /// Display label for the profile/filter option stored as 'Widowed'.
  ///
  /// In en, this message translates to:
  /// **'Widowed'**
  String get optionWidowed;

  /// Display label for the profile/filter option stored as 'Separated'.
  ///
  /// In en, this message translates to:
  /// **'Separated'**
  String get optionSeparated;

  /// Display label for the profile/filter option stored as 'Complicated'.
  ///
  /// In en, this message translates to:
  /// **'Complicated'**
  String get optionComplicated;

  /// Display label for the profile/filter option stored as 'Introvert'.
  ///
  /// In en, this message translates to:
  /// **'Introvert'**
  String get optionIntrovert;

  /// Display label for the profile/filter option stored as 'Ambivert'.
  ///
  /// In en, this message translates to:
  /// **'Ambivert'**
  String get optionAmbivert;

  /// Display label for the profile/filter option stored as 'Extrovert'.
  ///
  /// In en, this message translates to:
  /// **'Extrovert'**
  String get optionExtrovert;

  /// Display label for the profile/filter option stored as 'High School'.
  ///
  /// In en, this message translates to:
  /// **'High School'**
  String get optionHighSchool;

  /// Display label for the profile/filter option stored as 'Bachelor's'.
  ///
  /// In en, this message translates to:
  /// **'Bachelor\'s'**
  String get optionBachelors;

  /// Display label for the profile/filter option stored as 'Master's'.
  ///
  /// In en, this message translates to:
  /// **'Master\'s'**
  String get optionMasters;

  /// Display label for the profile/filter option stored as 'PhD'.
  ///
  /// In en, this message translates to:
  /// **'PhD'**
  String get optionPhd;

  /// Display label for the profile/filter option stored as 'Other'.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get optionOther;

  /// Display label for the profile/filter option stored as 'Prefer not to say'.
  ///
  /// In en, this message translates to:
  /// **'Prefer not to say'**
  String get optionPreferNotToSay;

  /// Display label for the profile/filter option stored as 'Hindu'.
  ///
  /// In en, this message translates to:
  /// **'Hindu'**
  String get optionHindu;

  /// Display label for the profile/filter option stored as 'Muslim'.
  ///
  /// In en, this message translates to:
  /// **'Muslim'**
  String get optionMuslim;

  /// Display label for the profile/filter option stored as 'Christian'.
  ///
  /// In en, this message translates to:
  /// **'Christian'**
  String get optionChristian;

  /// Display label for the profile/filter option stored as 'Sikh'.
  ///
  /// In en, this message translates to:
  /// **'Sikh'**
  String get optionSikh;

  /// Display label for the profile/filter option stored as 'Buddhist'.
  ///
  /// In en, this message translates to:
  /// **'Buddhist'**
  String get optionBuddhist;

  /// Display label for the profile/filter option stored as 'Jain'.
  ///
  /// In en, this message translates to:
  /// **'Jain'**
  String get optionJain;

  /// Display label for the profile/filter option stored as 'Jewish'.
  ///
  /// In en, this message translates to:
  /// **'Jewish'**
  String get optionJewish;

  /// Display label for the profile/filter option stored as 'Spiritual'.
  ///
  /// In en, this message translates to:
  /// **'Spiritual'**
  String get optionSpiritual;

  /// Display label for the profile/filter option stored as 'Agnostic'.
  ///
  /// In en, this message translates to:
  /// **'Agnostic'**
  String get optionAgnostic;

  /// Display label for the profile/filter option stored as 'Atheist'.
  ///
  /// In en, this message translates to:
  /// **'Atheist'**
  String get optionAtheist;

  /// Today story card: title when no stories are written (or count unknown).
  ///
  /// In en, this message translates to:
  /// **'Tell a little more of your story'**
  String get storiesNudgeTitle;

  /// Today story card: body while the story count is unknown.
  ///
  /// In en, this message translates to:
  /// **'Short stories on your profile give people something real to say hello about.'**
  String get storiesNudgeBodyUnknown;

  /// Today story card: button while the story count is unknown.
  ///
  /// In en, this message translates to:
  /// **'Open your stories'**
  String get storiesNudgeActionOpen;

  /// Today story card: body when no stories are written yet.
  ///
  /// In en, this message translates to:
  /// **'Add a short story to your profile: a small joy, a weekend worth sharing. People read these before they say hello.'**
  String get storiesNudgeBodyEmpty;

  /// Today story card: button when no stories are written yet.
  ///
  /// In en, this message translates to:
  /// **'Write your first story'**
  String get storiesNudgeActionFirst;

  /// Today story card: title when all three stories are written.
  ///
  /// In en, this message translates to:
  /// **'Your story is complete'**
  String get storiesNudgeCompleteTitle;

  /// Today story card: body when all three stories are written.
  ///
  /// In en, this message translates to:
  /// **'All three stories are on your profile. Refresh one whenever life gives you a new one.'**
  String get storiesNudgeCompleteBody;

  /// Today story card: button when all stories are written.
  ///
  /// In en, this message translates to:
  /// **'Edit your stories'**
  String get storiesNudgeActionEdit;

  /// Today story card: title with how many of the maximum stories are written, e.g. '1 of 3 stories shared'.
  ///
  /// In en, this message translates to:
  /// **'{count} of {max} stories shared'**
  String storiesNudgeSharedTitle(int count, int max);

  /// Today story card: body when some stories are written but the latest prompt is unknown.
  ///
  /// In en, this message translates to:
  /// **'One more story gives people another way to start a conversation.'**
  String get storiesNudgeBodyMore;

  /// Today story card: body naming the prompt of the latest story.
  ///
  /// In en, this message translates to:
  /// **'Latest: “{prompt}”. One more gives people another way to start a conversation.'**
  String storiesNudgeBodyLatest(String prompt);

  /// Today story card: button to add another story.
  ///
  /// In en, this message translates to:
  /// **'Add another story'**
  String get storiesNudgeActionAdd;

  /// Today story card: label above suggested prompts.
  ///
  /// In en, this message translates to:
  /// **'Ideas to start with'**
  String get storiesNudgeIdeas;

  /// Screen-reader label for the story progress bar.
  ///
  /// In en, this message translates to:
  /// **'{count} of {max} stories written'**
  String storiesProgressSemantics(int count, int max);

  /// Profile story prompt (id little_joy).
  ///
  /// In en, this message translates to:
  /// **'A small thing I always make time for'**
  String get storiesPromptLittleJoy;

  /// Profile story prompt (id weekend).
  ///
  /// In en, this message translates to:
  /// **'A weekend worth sharing'**
  String get storiesPromptWeekend;

  /// Profile story prompt (id first_hello).
  ///
  /// In en, this message translates to:
  /// **'A first hello I would love'**
  String get storiesPromptFirstHello;

  /// Profile story prompt (id learning).
  ///
  /// In en, this message translates to:
  /// **'Something I am learning, just for me'**
  String get storiesPromptLearning;

  /// Profile story prompt (id care).
  ///
  /// In en, this message translates to:
  /// **'A small way I show I care'**
  String get storiesPromptCare;

  /// Profile stories editor: app bar title.
  ///
  /// In en, this message translates to:
  /// **'A little more you'**
  String get storiesScreenTitle;

  /// Profile stories editor: shown when signed out.
  ///
  /// In en, this message translates to:
  /// **'Sign in to edit your stories.'**
  String get storiesSignIn;

  /// Profile stories editor: load error.
  ///
  /// In en, this message translates to:
  /// **'Your stories couldn’t load.'**
  String get storiesLoadFailed;

  /// Profile stories: retry button.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get storiesTryAgain;

  /// Profile stories editor: validation error before saving.
  ///
  /// In en, this message translates to:
  /// **'Add words to each story and a description for each photo, or remove the unfinished story.'**
  String get storiesIncomplete;

  /// Profile stories editor: snackbar after publishing.
  ///
  /// In en, this message translates to:
  /// **'Your profile stories are published.'**
  String get storiesPublished;

  /// Profile stories editor: snackbar after saving without publishing.
  ///
  /// In en, this message translates to:
  /// **'Saved privately. Your stories are hidden from other members.'**
  String get storiesSavedPrivately;

  /// Profile stories editor: fallback error when the save could not be confirmed.
  ///
  /// In en, this message translates to:
  /// **'We couldn’t confirm the save. Your edits are still here; reload saved stories to check.'**
  String get storiesSaveUnconfirmed;

  /// Profile stories editor: two-line headline.
  ///
  /// In en, this message translates to:
  /// **'Let someone meet\nthe everyday you.'**
  String get storiesHeadline;

  /// Profile stories editor: intro paragraph.
  ///
  /// In en, this message translates to:
  /// **'A small ritual, a story behind a photo, a first hello you would enjoy. Share up to three moments, in your own words.'**
  String get storiesIntro;

  /// Profile stories editor: privacy note.
  ///
  /// In en, this message translates to:
  /// **'Optional, with no score or completion requirement. Avoid contact details or precise locations you do not want to share.'**
  String get storiesOptionalNote;

  /// Profile stories editor: publish switch title.
  ///
  /// In en, this message translates to:
  /// **'Show these stories on my profile'**
  String get storiesPublishSwitch;

  /// Profile stories editor: publish switch subtitle.
  ///
  /// In en, this message translates to:
  /// **'Starts off. Visible to eligible members when your profile is published and available. You can hide them at any time.'**
  String get storiesPublishSwitchHint;

  /// Profile stories editor: leave preview.
  ///
  /// In en, this message translates to:
  /// **'Back to editing'**
  String get storiesBackToEditing;

  /// Profile stories editor: open preview.
  ///
  /// In en, this message translates to:
  /// **'Preview my stories'**
  String get storiesPreview;

  /// Profile stories editor: uppercase banner above the preview.
  ///
  /// In en, this message translates to:
  /// **'PREVIEW · THIS DOES NOT PUBLISH'**
  String get storiesPreviewBanner;

  /// Profile stories editor: add a story button.
  ///
  /// In en, this message translates to:
  /// **'Add a story'**
  String get storiesAdd;

  /// Profile stories editor: reload saved stories and discard edits.
  ///
  /// In en, this message translates to:
  /// **'Reload saved stories · discard edits'**
  String get storiesReloadDiscard;

  /// Profile stories editor: save button while saving.
  ///
  /// In en, this message translates to:
  /// **'Saving…'**
  String get storiesSaving;

  /// Profile stories editor: save button when publishing.
  ///
  /// In en, this message translates to:
  /// **'Publish stories'**
  String get storiesPublishButton;

  /// Profile stories editor: save button when not publishing.
  ///
  /// In en, this message translates to:
  /// **'Save privately'**
  String get storiesSavePrivatelyButton;

  /// Profile stories editor: footer note about photos and safety.
  ///
  /// In en, this message translates to:
  /// **'Photos come from your approved profile gallery. Stories and photos remain subject to member reporting and safety policies.'**
  String get storiesPolicyNote;

  /// Profile stories editor: uppercase label above each story, e.g. 'MOMENT 1'.
  ///
  /// In en, this message translates to:
  /// **'MOMENT {number}'**
  String storiesMomentLabel(int number);

  /// Profile stories editor: tooltip on the remove button of a story.
  ///
  /// In en, this message translates to:
  /// **'Remove story {number}'**
  String storiesRemoveTooltip(int number);

  /// Profile stories editor: prompt dropdown label.
  ///
  /// In en, this message translates to:
  /// **'A starting point'**
  String get storiesPromptLabel;

  /// Profile stories editor: story text field label.
  ///
  /// In en, this message translates to:
  /// **'In your words'**
  String get storiesTextLabel;

  /// Profile stories editor: story text field hint.
  ///
  /// In en, this message translates to:
  /// **'A real detail makes it yours.'**
  String get storiesTextHint;

  /// Profile stories editor: empty story validation.
  ///
  /// In en, this message translates to:
  /// **'Add a few words, or remove this story.'**
  String get storiesTextRequired;

  /// Profile stories editor: photo dropdown label.
  ///
  /// In en, this message translates to:
  /// **'A photo, if you like'**
  String get storiesPhotoLabel;

  /// Profile stories editor: no-photo option.
  ///
  /// In en, this message translates to:
  /// **'Words only'**
  String get storiesWordsOnly;

  /// Profile stories editor: photo option, e.g. 'Profile photo 2'.
  ///
  /// In en, this message translates to:
  /// **'Profile photo {number}'**
  String storiesProfilePhoto(int number);

  /// Profile stories editor: photo description field label.
  ///
  /// In en, this message translates to:
  /// **'Describe this photo'**
  String get storiesPhotoDescriptionLabel;

  /// Profile stories editor: photo description helper text.
  ///
  /// In en, this message translates to:
  /// **'Helps people using screen readers.'**
  String get storiesPhotoDescriptionHelper;

  /// Profile stories editor: photo description validation.
  ///
  /// In en, this message translates to:
  /// **'Add a short photo description.'**
  String get storiesPhotoDescriptionRequired;

  /// Screen-reader label for a story photo without a description.
  ///
  /// In en, this message translates to:
  /// **'Profile story photo'**
  String get storiesPhotoSemantics;

  /// Heading above a member's stories on their profile; also the fallback story title.
  ///
  /// In en, this message translates to:
  /// **'A little more me'**
  String get storiesSectionTitle;

  /// Profile: retry loading a member's stories.
  ///
  /// In en, this message translates to:
  /// **'Try loading stories again'**
  String get storiesRetryLoad;

  /// Sign-in screen / snackbar: the server ended the session.
  ///
  /// In en, this message translates to:
  /// **'You were signed out. Please sign in again.'**
  String get authErrorSessionExpired;

  /// Sign-in: generic failure when the request fails.
  ///
  /// In en, this message translates to:
  /// **'Unable to sign in. Try again.'**
  String get authErrorSignInFailed;

  /// Signup: generic failure when the request fails.
  ///
  /// In en, this message translates to:
  /// **'Unable to create account. Try again.'**
  String get authErrorCreateAccountFailed;

  /// Signup: the server did not return a session and gave no reason.
  ///
  /// In en, this message translates to:
  /// **'Unable to create account.'**
  String get authErrorCreateAccountGeneric;

  /// Sign-in: the server rejected the credentials without a reason.
  ///
  /// In en, this message translates to:
  /// **'Invalid username or password.'**
  String get authErrorInvalidCredentials;

  /// Sign-in/signup validation: username format rule. Keep the characters _ and . literally.
  ///
  /// In en, this message translates to:
  /// **'Username must be 3–30 characters using letters, numbers, _ or .'**
  String get authErrorUsernameFormat;

  /// Signup validation: password strength rule (bytes = UTF-8 bytes).
  ///
  /// In en, this message translates to:
  /// **'Password must be 8–72 bytes with letters and numbers.'**
  String get authErrorPasswordFormat;

  /// Welcome screen: link to create a friend-only (introducer) account.
  ///
  /// In en, this message translates to:
  /// **'Just here to introduce friends'**
  String get authWelcomeIntroducerLink;

  /// Signup: back button tooltip.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get signupBackTooltip;

  /// Signup (friend-only introducer account): headline.
  ///
  /// In en, this message translates to:
  /// **'Be the friend who brings people together.'**
  String get signupIntroducerTitle;

  /// Signup (introducer account): explanation of a friend-only account and the age range.
  ///
  /// In en, this message translates to:
  /// **'A friend-only account. No dating profile, photos or swiping. Your age stays private; Connect is for adults 18–80.'**
  String get signupIntroducerBody;

  /// Signup: headline.
  ///
  /// In en, this message translates to:
  /// **'Create your account'**
  String get signupTitle;

  /// Signup: subtitle under the headline.
  ///
  /// In en, this message translates to:
  /// **'Choose a unique username and secure password'**
  String get signupSubtitle;

  /// Signup: username field label.
  ///
  /// In en, this message translates to:
  /// **'Unique username'**
  String get signupUsernameLabel;

  /// Signup: username field placeholder, shaped like a username (lowercase, underscore, no spaces).
  ///
  /// In en, this message translates to:
  /// **'your_username'**
  String get signupUsernameHint;

  /// Signup: helper text under the username field.
  ///
  /// In en, this message translates to:
  /// **'3–30 characters. Letters, numbers, underscore and dot.'**
  String get signupUsernameHelp;

  /// Signup: password field label.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get signupPasswordLabel;

  /// Signup: password field placeholder.
  ///
  /// In en, this message translates to:
  /// **'At least 8 characters'**
  String get signupPasswordHint;

  /// Signup: confirm-password field placeholder.
  ///
  /// In en, this message translates to:
  /// **'Confirm password'**
  String get signupConfirmPasswordHint;

  /// Signup: full name field label.
  ///
  /// In en, this message translates to:
  /// **'Full name'**
  String get signupNameLabel;

  /// Signup: full name field placeholder.
  ///
  /// In en, this message translates to:
  /// **'Your name'**
  String get signupNameHint;

  /// Signup: date of birth field label.
  ///
  /// In en, this message translates to:
  /// **'Date of birth'**
  String get signupDobLabel;

  /// Signup: title of the date picker for the date of birth.
  ///
  /// In en, this message translates to:
  /// **'Select date of birth'**
  String get signupDobPickerHelp;

  /// Signup: date of birth field before a date is picked.
  ///
  /// In en, this message translates to:
  /// **'Select date'**
  String get signupDobPlaceholder;

  /// Signup: gender selector label.
  ///
  /// In en, this message translates to:
  /// **'I identify as'**
  String get signupGenderLabel;

  /// Signup: gender option (man).
  ///
  /// In en, this message translates to:
  /// **'Man'**
  String get signupGenderMan;

  /// Signup: gender option (woman).
  ///
  /// In en, this message translates to:
  /// **'Woman'**
  String get signupGenderWoman;

  /// Signup: gender option (other / non-binary).
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get signupGenderOther;

  /// Signup (introducer): submit button.
  ///
  /// In en, this message translates to:
  /// **'Create friend account'**
  String get signupCreateFriendAccount;

  /// Signup: prompt before the Sign in link.
  ///
  /// In en, this message translates to:
  /// **'Already have an account?'**
  String get signupAlreadyHaveAccount;

  /// Signup validation: the two passwords differ.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match.'**
  String get signupErrorPasswordMismatch;

  /// Signup validation: name missing or too short.
  ///
  /// In en, this message translates to:
  /// **'Please enter your full name.'**
  String get signupErrorFullName;

  /// Signup validation: date of birth not picked.
  ///
  /// In en, this message translates to:
  /// **'Please select your date of birth.'**
  String get signupErrorDobMissing;

  /// Signup validation (age gate): member younger than 18.
  ///
  /// In en, this message translates to:
  /// **'You must be at least 18 years old.'**
  String get signupErrorUnderage;

  /// Signup validation (age gate): member older than 80.
  ///
  /// In en, this message translates to:
  /// **'Connect currently supports members aged 18–80.'**
  String get signupErrorAgeRange;

  /// Signup validation: no gender option chosen.
  ///
  /// In en, this message translates to:
  /// **'Please choose how you identify.'**
  String get signupErrorGenderMissing;

  /// Account recovery: username missing.
  ///
  /// In en, this message translates to:
  /// **'Enter your username.'**
  String get authRecoveryEnterUsername;

  /// Account recovery: recovery code missing.
  ///
  /// In en, this message translates to:
  /// **'Enter your recovery code.'**
  String get authRecoveryEnterCode;

  /// Account recovery: new password does not meet the rule.
  ///
  /// In en, this message translates to:
  /// **'Use 8–72 characters with at least one letter and one number.'**
  String get authRecoveryPasswordRule;

  /// Account recovery: password reset succeeded; all devices signed out.
  ///
  /// In en, this message translates to:
  /// **'Your password has been reset and every device has been signed out. Sign in with your new password.'**
  String get authRecoveryResetDone;

  /// Account recovery: help request sent (fallback when the server gives no message). Must not reveal whether the username exists.
  ///
  /// In en, this message translates to:
  /// **'If this username belongs to a Connect account, our safety team will review the request.'**
  String get authRecoveryAssistanceDone;

  /// Account recovery: the code was rejected.
  ///
  /// In en, this message translates to:
  /// **'That recovery code is not valid or has expired.'**
  String get authRecoveryInvalidCode;

  /// Account recovery: network error while resetting the password.
  ///
  /// In en, this message translates to:
  /// **'Could not reach Connect. Check your connection and try again.'**
  String get authRecoveryOffline;

  /// Account recovery: the help request could not be sent.
  ///
  /// In en, this message translates to:
  /// **'Could not send your request. Check your connection and try again.'**
  String get authRecoverySendFailed;

  /// Account recovery: button after completion.
  ///
  /// In en, this message translates to:
  /// **'Back to sign in'**
  String get authRecoveryBackToSignIn;

  /// Account recovery: segment for members who have their recovery code.
  ///
  /// In en, this message translates to:
  /// **'I have my code'**
  String get authRecoveryHaveCode;

  /// Account recovery: segment for members who lost their recovery code.
  ///
  /// In en, this message translates to:
  /// **'I lost my code'**
  String get authRecoveryLostCode;

  /// Account recovery: explanation for the have-code path.
  ///
  /// In en, this message translates to:
  /// **'Use the recovery code you saved when you created your account, or one issued by our safety team.'**
  String get authRecoveryHaveCodeIntro;

  /// Account recovery: explanation for the lost-code path.
  ///
  /// In en, this message translates to:
  /// **'Tell us your username. We\'ll confirm your identity before issuing a recovery code. We never ask for your password.'**
  String get authRecoveryLostCodeIntro;

  /// Account recovery: username field label.
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get authRecoveryUsernameLabel;

  /// Account recovery: recovery code field label.
  ///
  /// In en, this message translates to:
  /// **'Recovery code'**
  String get authRecoveryCodeLabel;

  /// Account recovery: new password field label.
  ///
  /// In en, this message translates to:
  /// **'New password'**
  String get authRecoveryNewPasswordLabel;

  /// Account recovery (lost code): optional message field label.
  ///
  /// In en, this message translates to:
  /// **'Anything that helps us (optional)'**
  String get authRecoveryMessageLabel;

  /// Account recovery (lost code): optional message field placeholder.
  ///
  /// In en, this message translates to:
  /// **'For example, when you last signed in'**
  String get authRecoveryMessageHint;

  /// Account recovery: submit button while sending.
  ///
  /// In en, this message translates to:
  /// **'Sending…'**
  String get authRecoverySending;

  /// Account recovery: submit button for the have-code path.
  ///
  /// In en, this message translates to:
  /// **'Reset password'**
  String get authRecoveryResetPassword;

  /// Account recovery: submit button for the lost-code path.
  ///
  /// In en, this message translates to:
  /// **'Ask for help'**
  String get authRecoveryAskForHelp;

  /// Terms acceptance screen: headline.
  ///
  /// In en, this message translates to:
  /// **'Terms and Conditions'**
  String get authTermsTitle;

  /// Terms acceptance screen: subtitle.
  ///
  /// In en, this message translates to:
  /// **'A quick review before you enter the app.'**
  String get authTermsSubtitle;

  /// Terms acceptance screen: intro paragraph.
  ///
  /// In en, this message translates to:
  /// **'Please review and accept our Terms and Privacy Policy to continue.'**
  String get authTermsIntro;

  /// Terms acceptance screen: section title.
  ///
  /// In en, this message translates to:
  /// **'Community expectations'**
  String get authTermsCommunityTitle;

  /// Terms acceptance screen: community rule.
  ///
  /// In en, this message translates to:
  /// **'Be respectful and authentic.'**
  String get authTermsPointRespect;

  /// Terms acceptance screen: community rule.
  ///
  /// In en, this message translates to:
  /// **'No harassment or fraudulent behavior.'**
  String get authTermsPointNoHarassment;

  /// Terms acceptance screen: community rule.
  ///
  /// In en, this message translates to:
  /// **'You control your privacy settings and profile visibility.'**
  String get authTermsPointPrivacy;

  /// Terms acceptance screen: community rule.
  ///
  /// In en, this message translates to:
  /// **'Reports are reviewed to keep the community safe.'**
  String get authTermsPointReports;

  /// Terms acceptance screen: community rule about sanctions.
  ///
  /// In en, this message translates to:
  /// **'Violations may result in suspension or account removal.'**
  String get authTermsPointViolations;

  /// Terms acceptance screen: note that acceptance is required.
  ///
  /// In en, this message translates to:
  /// **'You can review the full policy details later from settings, but acceptance is required before using the app.'**
  String get authTermsReviewLater;

  /// Terms acceptance screen: consent checkbox label.
  ///
  /// In en, this message translates to:
  /// **'I agree to the Terms & Privacy Policy'**
  String get authTermsAgreeCheckbox;

  /// Terms acceptance screen: continue button.
  ///
  /// In en, this message translates to:
  /// **'I Accept and Continue'**
  String get authTermsAcceptButton;

  /// Terms acceptance screen: saving the agreement failed.
  ///
  /// In en, this message translates to:
  /// **'Could not save your agreement. Please check network and try again.'**
  String get authTermsSaveFailed;

  /// Discover: snackbar after sending a super like.
  ///
  /// In en, this message translates to:
  /// **'Super like sent to {name}'**
  String discoverSuperLikeSent(String name);

  /// Discover: placeholder last message for a brand-new match before any chat.
  ///
  /// In en, this message translates to:
  /// **'Say hi'**
  String get discoverMatchPlaceholderMessage;

  /// Discover: snackbar when trying to message someone without a match yet.
  ///
  /// In en, this message translates to:
  /// **'You can chat with {name} after a real match is created.'**
  String discoverChatNeedsMatch(String name);

  /// Discover: daily like limit sheet title (fallback when the server sends none).
  ///
  /// In en, this message translates to:
  /// **'You\'ve used today\'s likes'**
  String get discoverDailyLimitTitle;

  /// Discover: daily like limit sheet body when the reset time is unknown.
  ///
  /// In en, this message translates to:
  /// **'Come back tomorrow, or upgrade for more likes every day.'**
  String get discoverDailyLimitBody;

  /// Discover: daily like limit sheet body. {reset} is the already-localised reset time sentence, e.g. 'Resets in 3 hours'.
  ///
  /// In en, this message translates to:
  /// **'{reset}. Upgrade for more likes every day.'**
  String discoverDailyLimitResetBody(String reset);

  /// Discover: button opening subscription plans.
  ///
  /// In en, this message translates to:
  /// **'See plans'**
  String get discoverSeePlans;

  /// Discover: dismiss button on the daily limit sheet.
  ///
  /// In en, this message translates to:
  /// **'Not now'**
  String get discoverNotNow;

  /// Discover: tooltip of the back button returning from Explore to Today.
  ///
  /// In en, this message translates to:
  /// **'Back to Today'**
  String get discoverBackToToday;

  /// Discover: app bar title when browsing the full deck.
  ///
  /// In en, this message translates to:
  /// **'Explore'**
  String get discoverExploreTitle;

  /// Discover: shown when every spotlight profile in the deck has been reviewed.
  ///
  /// In en, this message translates to:
  /// **'Spotlight reviewed!'**
  String get discoverSpotlightReviewed;

  /// Discover: shown when every profile in the deck has been reviewed.
  ///
  /// In en, this message translates to:
  /// **'All reviewed!'**
  String get discoverAllReviewed;

  /// Discover: eyebrow above the title (shown uppercased).
  ///
  /// In en, this message translates to:
  /// **'Curated for you'**
  String get discoverCuratedForYou;

  /// Discover: main screen heading.
  ///
  /// In en, this message translates to:
  /// **'Discover Matches'**
  String get discoverTitle;

  /// Discover: tagline under the heading.
  ///
  /// In en, this message translates to:
  /// **'A little curiosity. A real connection.'**
  String get discoverTagline;

  /// Discover: button opening messages.
  ///
  /// In en, this message translates to:
  /// **'Messages'**
  String get discoverMessages;

  /// Discover: button/heading for discovery filters.
  ///
  /// In en, this message translates to:
  /// **'Filters'**
  String get discoverFilters;

  /// Discover (desktop): heading of the deck statistics panel.
  ///
  /// In en, this message translates to:
  /// **'Your deck'**
  String get discoverYourDeck;

  /// Discover: deck statistic label for profiles still to review.
  ///
  /// In en, this message translates to:
  /// **'Ready'**
  String get discoverStatReady;

  /// Discover: deck statistic label for profiles liked.
  ///
  /// In en, this message translates to:
  /// **'Liked'**
  String get discoverStatLiked;

  /// Discover: deck statistic / button label for profiles passed on.
  ///
  /// In en, this message translates to:
  /// **'Passed'**
  String get discoverStatPassed;

  /// Discover (desktop): button to edit filters.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get discoverEdit;

  /// Discover (desktop): shown when no filters are active.
  ///
  /// In en, this message translates to:
  /// **'Showing everyone in your preferences.'**
  String get discoverShowingEveryone;

  /// Discover: heading of today's curated picks.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get discoverToday;

  /// Discover (desktop): subtitle of today's curated picks.
  ///
  /// In en, this message translates to:
  /// **'Five picks, refreshed every day.'**
  String get discoverTodaySubtitle;

  /// Discover (desktop): button opening all spotlight profiles.
  ///
  /// In en, this message translates to:
  /// **'View all'**
  String get discoverViewAll;

  /// Discover (desktop): safety panel heading.
  ///
  /// In en, this message translates to:
  /// **'Match on your terms'**
  String get discoverMatchOnYourTerms;

  /// Discover (desktop): safety panel body.
  ///
  /// In en, this message translates to:
  /// **'Mutual interest creates a match. You can block or report anyone from their profile or conversation.'**
  String get discoverMatchOnYourTermsBody;

  /// Discover: eyebrow on the load error card (shown uppercased).
  ///
  /// In en, this message translates to:
  /// **'Connection paused'**
  String get discoverErrorEyebrow;

  /// Discover: title on the load error card.
  ///
  /// In en, this message translates to:
  /// **'Unable to load profiles'**
  String get discoverErrorTitle;

  /// Discover: empty deck message when trust filters hid profiles. English keeps the '(s)' wording used by tests.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, other{Trust filters hid {count} profile(s). Try relaxing trust filters or refresh to rebuild your deck.}}'**
  String discoverTrustFilteredBody(int count);

  /// Discover: empty deck message.
  ///
  /// In en, this message translates to:
  /// **'Your curated deck is being prepared. Refresh to check for new verified profiles near you.'**
  String get discoverDeckPreparingBody;

  /// Discover: eyebrow on the empty deck card (shown uppercased).
  ///
  /// In en, this message translates to:
  /// **'Check back soon'**
  String get discoverCheckBackSoon;

  /// Discover: empty title in spotlight mode.
  ///
  /// In en, this message translates to:
  /// **'No spotlight profiles'**
  String get discoverNoSpotlightProfiles;

  /// Discover: empty deck title.
  ///
  /// In en, this message translates to:
  /// **'No profiles'**
  String get discoverNoProfiles;

  /// Discover: button refreshing the deck.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get discoverRefresh;

  /// Discover: small promise chip on the empty deck card.
  ///
  /// In en, this message translates to:
  /// **'Private'**
  String get discoverPromisePrivate;

  /// Discover: 'Premium' chip / fallback spotlight tier label.
  ///
  /// In en, this message translates to:
  /// **'Premium'**
  String get discoverPremium;

  /// Discover: screen-reader label of the notification bell with unread items.
  ///
  /// In en, this message translates to:
  /// **'Notifications, {count} unread'**
  String discoverNotificationsUnread(int count);

  /// Discover: notifications sheet heading.
  ///
  /// In en, this message translates to:
  /// **'Latest unread notifications'**
  String get discoverLatestUnreadNotifications;

  /// Discover: notifications sheet empty state.
  ///
  /// In en, this message translates to:
  /// **'No unread notifications'**
  String get discoverNoUnreadNotifications;

  /// Discover: notification title for daily prompt replies.
  ///
  /// In en, this message translates to:
  /// **'Who replied me'**
  String get discoverNotificationWhoReplied;

  /// Discover: notification subtitle with the number of new replies.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 new reply} other{{count} new replies}}'**
  String discoverNotificationRepliesCount(int count);

  /// Discover: notification title for pending likes.
  ///
  /// In en, this message translates to:
  /// **'Who has liked me'**
  String get discoverNotificationWhoLiked;

  /// Discover: notification subtitle with the number of new likes.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 new like} other{{count} new likes}}'**
  String discoverNotificationLikesCount(int count);

  /// Discover: link opening more spotlight profiles / the full profile.
  ///
  /// In en, this message translates to:
  /// **'View more'**
  String get discoverViewMore;

  /// Discover: button opening dating rhythm (when you are free this week).
  ///
  /// In en, this message translates to:
  /// **'Fits your week'**
  String get discoverFitsYourWeek;

  /// Discover: number of today's curated picks.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 pick} other{{count} picks}}'**
  String discoverTodayPicks(int count);

  /// Discover: screen-reader fallback reason for a curated pick.
  ///
  /// In en, this message translates to:
  /// **'Picked for you today.'**
  String get discoverPickedForYouToday;

  /// Discover: error when no user is signed in.
  ///
  /// In en, this message translates to:
  /// **'Please login to discover profiles.'**
  String get discoverErrorLoginToDiscover;

  /// Discover: generic error loading the deck.
  ///
  /// In en, this message translates to:
  /// **'Failed to load profiles. Please try again.'**
  String get discoverErrorLoadProfiles;

  /// Discover: error when the session is missing.
  ///
  /// In en, this message translates to:
  /// **'User session not available. Please login again.'**
  String get discoverErrorSessionUnavailable;

  /// Discover: error when a like fails.
  ///
  /// In en, this message translates to:
  /// **'Unable to like right now. Please try again.'**
  String get discoverErrorLikeRetry;

  /// Discover: short error when a like fails.
  ///
  /// In en, this message translates to:
  /// **'Unable to like right now.'**
  String get discoverErrorLike;

  /// Discover: error when passing on a profile fails.
  ///
  /// In en, this message translates to:
  /// **'Unable to pass right now. Please try again.'**
  String get discoverErrorPassRetry;

  /// Who liked me: error loading the list.
  ///
  /// In en, this message translates to:
  /// **'Could not load who liked you. Please try again.'**
  String get discoverErrorLoadLikedMe;

  /// Who liked me: error when an answer is already being sent.
  ///
  /// In en, this message translates to:
  /// **'Already sending your answer.'**
  String get discoverErrorAnswerInFlight;

  /// Who liked me: error when liking back or passing fails.
  ///
  /// In en, this message translates to:
  /// **'Could not send your answer. Please try again.'**
  String get discoverErrorAnswer;

  /// Comfort card topic: how fast the member likes to communicate.
  ///
  /// In en, this message translates to:
  /// **'Communication pace'**
  String get firstChapterTopicPace;

  /// Comfort card topic: what kinds of dates feel comfortable.
  ///
  /// In en, this message translates to:
  /// **'Dating comfort'**
  String get firstChapterTopicDates;

  /// Comfort card topic: languages the member speaks.
  ///
  /// In en, this message translates to:
  /// **'Languages'**
  String get firstChapterTopicLanguage;

  /// Comfort card topic: how involved family is.
  ///
  /// In en, this message translates to:
  /// **'Family involvement'**
  String get firstChapterTopicFamily;

  /// Comfort cards: screen title, section title and fallback card topic.
  ///
  /// In en, this message translates to:
  /// **'In my words'**
  String get firstChapterInMyWords;

  /// Comfort card: label above the original text. {language} is the language the member typed.
  ///
  /// In en, this message translates to:
  /// **'Original · {language}'**
  String firstChapterComfortOriginal(String language);

  /// Comfort card: label above a translation written by the member. {language} is the translation language the member typed.
  ///
  /// In en, this message translates to:
  /// **'Member-provided translation · {language}'**
  String firstChapterComfortMemberTranslation(String language);

  /// Comfort cards: tooltip on the reload button.
  ///
  /// In en, this message translates to:
  /// **'Reload saved version'**
  String get firstChapterComfortReloadSaved;

  /// Comfort cards: retry button when the cards fail to load.
  ///
  /// In en, this message translates to:
  /// **'Reload comfort cards'**
  String get firstChapterComfortReloadCards;

  /// Comfort cards: headline.
  ///
  /// In en, this message translates to:
  /// **'Your words. Your boundaries.'**
  String get firstChapterComfortHeadline;

  /// Comfort cards: introduction under the headline.
  ///
  /// In en, this message translates to:
  /// **'Optional context for people you have matched with. Nothing is inferred from your background. Write in the language that feels like you.'**
  String get firstChapterComfortIntro;

  /// Comfort cards: switch title to share cards with matches.
  ///
  /// In en, this message translates to:
  /// **'Share these cards with my matches'**
  String get firstChapterComfortShareTitle;

  /// Comfort cards: switch subtitle.
  ///
  /// In en, this message translates to:
  /// **'Off keeps every card private.'**
  String get firstChapterComfortShareSubtitle;

  /// Comfort cards: button to remove a card from the draft.
  ///
  /// In en, this message translates to:
  /// **'Remove from draft'**
  String get firstChapterComfortRemoveFromDraft;

  /// Comfort cards: dropdown label to pick a topic.
  ///
  /// In en, this message translates to:
  /// **'A little context about'**
  String get firstChapterComfortTopicLabel;

  /// Comfort cards: field label for the language of the original text.
  ///
  /// In en, this message translates to:
  /// **'Original language'**
  String get firstChapterComfortOriginalLanguage;

  /// Comfort cards: field label for the member's text.
  ///
  /// In en, this message translates to:
  /// **'In your own words'**
  String get firstChapterComfortOwnWords;

  /// Comfort cards: example hint for the member's text.
  ///
  /// In en, this message translates to:
  /// **'For example: I enjoy daytime dates and a little time to get comfortable.'**
  String get firstChapterComfortOwnWordsHint;

  /// Comfort cards: optional translation field label.
  ///
  /// In en, this message translates to:
  /// **'Your translation (optional)'**
  String get firstChapterComfortTranslation;

  /// Comfort cards: field label for the translation language.
  ///
  /// In en, this message translates to:
  /// **'Translation language (if added)'**
  String get firstChapterComfortTranslationLanguage;

  /// Comfort cards: note about member-provided translations.
  ///
  /// In en, this message translates to:
  /// **'Translations are labelled as member-provided. Your original words are always preserved.'**
  String get firstChapterComfortTranslationNote;

  /// Comfort cards: button to add or replace the card in the draft.
  ///
  /// In en, this message translates to:
  /// **'Add / replace this card in draft'**
  String get firstChapterComfortAddCard;

  /// Comfort cards: validation error.
  ///
  /// In en, this message translates to:
  /// **'Add your words and language. A translation also needs its language.'**
  String get firstChapterComfortMissingFields;

  /// Comfort cards: error when the typed card was not added before saving.
  ///
  /// In en, this message translates to:
  /// **'Add your written card to the draft before saving.'**
  String get firstChapterComfortUnaddedCard;

  /// Comfort cards: fallback error when saving fails.
  ///
  /// In en, this message translates to:
  /// **'Your draft is still here. Reload to check the latest saved version before retrying.'**
  String get firstChapterComfortSaveFailed;

  /// First Chapter: button label while saving.
  ///
  /// In en, this message translates to:
  /// **'Saving…'**
  String get firstChapterSaving;

  /// Comfort cards: save button.
  ///
  /// In en, this message translates to:
  /// **'Save my choices'**
  String get firstChapterComfortSave;

  /// First Chapter Studio: stands in for the partner's name when it is unknown.
  ///
  /// In en, this message translates to:
  /// **'your match'**
  String get firstChapterYourMatch;

  /// First Chapter Studio: fallback error when a save cannot be confirmed.
  ///
  /// In en, this message translates to:
  /// **'We could not confirm the save. Refresh to check before retrying.'**
  String get firstChapterSaveUnconfirmed;

  /// First Chapter Studio: dialog title when sharing a story both people approve.
  ///
  /// In en, this message translates to:
  /// **'A story you both approve'**
  String get firstChapterJointPreviewTitle;

  /// First Chapter Studio: dialog title when previewing a solo public chapter.
  ///
  /// In en, this message translates to:
  /// **'Preview your public chapter'**
  String get firstChapterSoloPreviewTitle;

  /// First Chapter Studio: the surprise that follows the beginning. {surprise} is chapter text.
  ///
  /// In en, this message translates to:
  /// **'Then… {surprise}'**
  String firstChapterThenSurprise(String surprise);

  /// First Chapter Studio: explanation in the joint share dialog.
  ///
  /// In en, this message translates to:
  /// **'Your approval is one half. The link works only after your partner also approves this exact card. Either of you can revoke it.'**
  String get firstChapterJointPreviewBody;

  /// First Chapter Studio: explanation in the solo share dialog.
  ///
  /// In en, this message translates to:
  /// **'Only this scene and your selected beginning are public. No names, photos, private chat, location or partner contribution. You can revoke the link.'**
  String get firstChapterSoloPreviewBody;

  /// First Chapter Studio: dialog button to cancel sharing.
  ///
  /// In en, this message translates to:
  /// **'Keep private'**
  String get firstChapterKeepPrivate;

  /// First Chapter Studio: dialog button to approve one's half of a joint share.
  ///
  /// In en, this message translates to:
  /// **'Approve my half'**
  String get firstChapterApproveMyHalf;

  /// First Chapter Studio: dialog button to create a share link.
  ///
  /// In en, this message translates to:
  /// **'Create share link'**
  String get firstChapterCreateShareLink;

  /// First Chapter Studio: app bar title.
  ///
  /// In en, this message translates to:
  /// **'First Chapter Studio'**
  String get firstChapterStudioTitle;

  /// First Chapter Studio: refresh tooltip.
  ///
  /// In en, this message translates to:
  /// **'Refresh chapter'**
  String get firstChapterRefresh;

  /// First Chapter Studio: small all-caps line above the headline.
  ///
  /// In en, this message translates to:
  /// **'A SMALL ADVENTURE. TWO AUTHORS.'**
  String get firstChapterHeroEyebrow;

  /// First Chapter Studio: headline, with a line break.
  ///
  /// In en, this message translates to:
  /// **'What happens\nnext is yours.'**
  String get firstChapterHeroTitle;

  /// First Chapter Studio: intro when opened without a match.
  ///
  /// In en, this message translates to:
  /// **'Make a scene. Pass it to a friend. Or create a first chapter with someone you have matched with.'**
  String get firstChapterHeroSolo;

  /// First Chapter Studio: intro with a match. {name} is the match's name.
  ///
  /// In en, this message translates to:
  /// **'You and {name}. One beginning, one unexpected turn, and a story you can make real.'**
  String firstChapterHeroPair(String name);

  /// First Chapter Studio: reassurance line.
  ///
  /// In en, this message translates to:
  /// **'Optional, at your pace. Chat is always a choice.'**
  String get firstChapterHeroPace;

  /// First Chapter Studio: error when the chapter cannot load.
  ///
  /// In en, this message translates to:
  /// **'Your chapter could not be loaded.'**
  String get firstChapterLoadFailed;

  /// First Chapter Studio: retry button.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get firstChapterTryAgain;

  /// First Chapter Studio: step 1 title.
  ///
  /// In en, this message translates to:
  /// **'01 / Choose your scene'**
  String get firstChapterStepChooseScene;

  /// First Chapter Studio: step 2 title.
  ///
  /// In en, this message translates to:
  /// **'02 / Write the beginning'**
  String get firstChapterStepWriteBeginning;

  /// First Chapter Studio: button to start a chapter with the match.
  ///
  /// In en, this message translates to:
  /// **'Start our chapter'**
  String get firstChapterStartOurChapter;

  /// First Chapter Studio: button to share a solo scene.
  ///
  /// In en, this message translates to:
  /// **'Pass the Chapter'**
  String get firstChapterPassTheChapter;

  /// First Chapter Studio: section title for the pair's chapter.
  ///
  /// In en, this message translates to:
  /// **'Your first chapter'**
  String get firstChapterYourFirstChapter;

  /// First Chapter Studio: all-caps label before the beginning text.
  ///
  /// In en, this message translates to:
  /// **'IT BEGINS WITH'**
  String get firstChapterItBeginsWith;

  /// First Chapter Studio: all-caps label before the surprise text.
  ///
  /// In en, this message translates to:
  /// **'AND THEN…'**
  String get firstChapterAndThen;

  /// First Chapter Studio: prefilled, editable note for a date plan. {beginning} and {surprise} are chapter text.
  ///
  /// In en, this message translates to:
  /// **'{beginning}. Then {surprise}.'**
  String firstChapterDateIdeaNote(String beginning, String surprise);

  /// First Chapter Studio: button that turns the chapter into a date plan.
  ///
  /// In en, this message translates to:
  /// **'Make this a date idea'**
  String get firstChapterMakeDateIdea;

  /// First Chapter Studio: note under the date idea button.
  ///
  /// In en, this message translates to:
  /// **'A suggestion to shape together. No date is booked or accepted automatically.'**
  String get firstChapterDateIdeaHint;

  /// First Chapter Studio: prompt to add a surprise.
  ///
  /// In en, this message translates to:
  /// **'Your turn: add a surprise.'**
  String get firstChapterYourTurn;

  /// First Chapter Studio: status while waiting for the match.
  ///
  /// In en, this message translates to:
  /// **'Your beginning is saved. Your match can add a surprise whenever they like. You can keep chatting.'**
  String get firstChapterBeginningSaved;

  /// First Chapter Studio: button to close the chapter.
  ///
  /// In en, this message translates to:
  /// **'Close this chapter'**
  String get firstChapterClose;

  /// First Chapter Studio: section title for sharing an anonymous story.
  ///
  /// In en, this message translates to:
  /// **'Stories that give back'**
  String get firstChapterGiveBackTitle;

  /// First Chapter Studio: explanation of anonymous story sharing.
  ///
  /// In en, this message translates to:
  /// **'Your connection can inspire a new beginning. Share only this anonymous date idea, with both of your approvals.'**
  String get firstChapterGiveBackBody;

  /// First Chapter Studio: button to preview the anonymous story.
  ///
  /// In en, this message translates to:
  /// **'Preview our anonymous story'**
  String get firstChapterPreviewAnonymous;

  /// First Chapter Studio: section title for private next-step choices.
  ///
  /// In en, this message translates to:
  /// **'A private green light'**
  String get firstChapterGreenLightTitle;

  /// First Chapter Studio: section title for the match's comfort cards.
  ///
  /// In en, this message translates to:
  /// **'In their words'**
  String get firstChapterInTheirWords;

  /// First Chapter Studio: tile title linking to comfort cards.
  ///
  /// In en, this message translates to:
  /// **'Make room for what matters to you'**
  String get firstChapterMakeRoomTitle;

  /// First Chapter Studio: tile subtitle linking to comfort cards.
  ///
  /// In en, this message translates to:
  /// **'Your pace, languages, dates and family expectations. Your words, shared only when you choose.'**
  String get firstChapterMakeRoomSubtitle;

  /// First Chapter Studio: section title listing matches.
  ///
  /// In en, this message translates to:
  /// **'Create with a connection'**
  String get firstChapterCreateWithConnection;

  /// First Chapter Studio: subtitle on each match row.
  ///
  /// In en, this message translates to:
  /// **'Create a first chapter together'**
  String get firstChapterCreateTogether;

  /// First Chapter Studio: shown when there are no matches.
  ///
  /// In en, this message translates to:
  /// **'Your mutual matches appear here. You can try and share a solo scene now.'**
  String get firstChapterMatchesAppearHere;

  /// First Chapter Studio: section title for published chapters.
  ///
  /// In en, this message translates to:
  /// **'Your shared chapters'**
  String get firstChapterSharedChapters;

  /// First Chapter Studio: retry button for shared chapters.
  ///
  /// In en, this message translates to:
  /// **'Reload shared chapters'**
  String get firstChapterReloadShared;

  /// First Chapter Studio: empty state for shared chapters.
  ///
  /// In en, this message translates to:
  /// **'Nothing public until you choose to share.'**
  String get firstChapterNothingPublic;

  /// First Chapter Studio: green light option.
  ///
  /// In en, this message translates to:
  /// **'Keep chatting'**
  String get firstChapterGreenChat;

  /// First Chapter Studio: green light option.
  ///
  /// In en, this message translates to:
  /// **'Try a call'**
  String get firstChapterGreenCall;

  /// First Chapter Studio: green light option.
  ///
  /// In en, this message translates to:
  /// **'Suggest a date'**
  String get firstChapterGreenDate;

  /// First Chapter Studio: explanation of the green light.
  ///
  /// In en, this message translates to:
  /// **'Only a shared choice is revealed. Nobody sees an unanswered request. Choices expire after seven days; clear them to withdraw.'**
  String get firstChapterGreenLightIntro;

  /// First Chapter Studio: save the green light choices.
  ///
  /// In en, this message translates to:
  /// **'Save privately'**
  String get firstChapterSavePrivately;

  /// First Chapter Studio: shown before there is any mutual choice.
  ///
  /// In en, this message translates to:
  /// **'Any shared next step will appear here.'**
  String get firstChapterGreenLightNone;

  /// First Chapter Studio: the choices both people picked. {choices} is a ' · '-separated list of options.
  ///
  /// In en, this message translates to:
  /// **'You both feel comfortable with: {choices}'**
  String firstChapterGreenLightMutual(String choices);

  /// First Chapter Studio: note under the green light.
  ///
  /// In en, this message translates to:
  /// **'A green light is permission to suggest. A call or date still needs a separate agreement.'**
  String get firstChapterGreenLightNote;

  /// First Chapter Studio: publication status.
  ///
  /// In en, this message translates to:
  /// **'Link revoked'**
  String get firstChapterLinkRevoked;

  /// First Chapter Studio: publication status.
  ///
  /// In en, this message translates to:
  /// **'Public, anonymous scene'**
  String get firstChapterPublicScene;

  /// First Chapter Studio: publication status.
  ///
  /// In en, this message translates to:
  /// **'Private until both approve'**
  String get firstChapterPrivateUntilBoth;

  /// First Chapter Studio: snack bar after copying a link.
  ///
  /// In en, this message translates to:
  /// **'Chapter link copied. Share it wherever you choose.'**
  String get firstChapterLinkCopied;

  /// First Chapter Studio: copy link button.
  ///
  /// In en, this message translates to:
  /// **'Copy link'**
  String get firstChapterCopyLink;

  /// First Chapter Studio: approve a joint publication.
  ///
  /// In en, this message translates to:
  /// **'Approve this exact story'**
  String get firstChapterApproveStory;

  /// First Chapter Studio: revoke a publication.
  ///
  /// In en, this message translates to:
  /// **'Revoke link'**
  String get firstChapterRevokeLink;

  /// Banner when API responses are slow. {mbps} is the recommended bandwidth.
  ///
  /// In en, this message translates to:
  /// **'Weak network detected. Use at least {mbps} Mbps for smoother chat, gifts, and gestures.'**
  String networkSlowResponse(int mbps);

  /// Banner when there is no network connection.
  ///
  /// In en, this message translates to:
  /// **'No stable network connection. Reconnect to continue using the app.'**
  String get networkOffline;

  /// Banner when a request failed on a weak network. {mbps} is the recommended bandwidth.
  ///
  /// In en, this message translates to:
  /// **'Network is weak. Use at least {mbps} Mbps for a smoother experience.'**
  String networkWeak(int mbps);

  /// Error when the app cannot reach its API (connection error or timeout).
  ///
  /// In en, this message translates to:
  /// **'Cannot reach the local service. Check that the API is running.'**
  String get networkCannotReachService;

  /// Loading message while checking whether the member accepted the terms.
  ///
  /// In en, this message translates to:
  /// **'Checking terms…'**
  String get gateCheckingTerms;

  /// Loading message while the member's profile loads after sign-in.
  ///
  /// In en, this message translates to:
  /// **'Loading your profile…'**
  String get gateLoadingProfile;

  /// Heading when the app cannot load the profile from the server.
  ///
  /// In en, this message translates to:
  /// **'Connection issue'**
  String get gateConnectionIssue;

  /// Error when reporting a member failed.
  ///
  /// In en, this message translates to:
  /// **'Failed to report user'**
  String get safetyReportFailed;

  /// Error when blocking a member failed.
  ///
  /// In en, this message translates to:
  /// **'Failed to block user'**
  String get safetyBlockFailed;

  /// Error when unblocking a member failed.
  ///
  /// In en, this message translates to:
  /// **'Failed to unblock user'**
  String get safetyUnblockFailed;

  /// Error when a safety action needs a signed-in member.
  ///
  /// In en, this message translates to:
  /// **'Not authenticated'**
  String get safetyNotAuthenticated;

  /// Relative time: less than a minute ago.
  ///
  /// In en, this message translates to:
  /// **'Just now'**
  String get timeAgoJustNow;

  /// Relative time in minutes.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 minute ago} other{{count} minutes ago}}'**
  String timeAgoMinutes(int count);

  /// Relative time in hours.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 hour ago} other{{count} hours ago}}'**
  String timeAgoHours(int count);

  /// Relative time in days.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 day ago} other{{count} days ago}}'**
  String timeAgoDays(int count);

  /// Relative time in weeks.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 week ago} other{{count} weeks ago}}'**
  String timeAgoWeeks(int count);

  /// Accessibility label for the dismissible theme title card overlay.
  ///
  /// In en, this message translates to:
  /// **'Theme preview'**
  String get themePreviewBarrier;

  /// Small cinema-style eyebrow on the theme title card (all caps).
  ///
  /// In en, this message translates to:
  /// **'NOW SHOWING'**
  String get themeNowShowing;

  /// One-line description of the 'real-life' look (theme name stays untranslated).
  ///
  /// In en, this message translates to:
  /// **'Warm ivory, forest and apricot.'**
  String get themeTaglineRealLife;

  /// One-line description of the 'real-life-night' look (theme name stays untranslated).
  ///
  /// In en, this message translates to:
  /// **'Forest, soft mint and candlelight.'**
  String get themeTaglineRealLifeNight;

  /// One-line description of the 'daylight' look (theme name stays untranslated).
  ///
  /// In en, this message translates to:
  /// **'Cream, ink and a raspberry accent, like the website.'**
  String get themeTaglineDaylight;

  /// One-line description of the 'ember' look (theme name stays untranslated).
  ///
  /// In en, this message translates to:
  /// **'Plum-black night with ember and violet glow.'**
  String get themeTaglineEmber;

  /// One-line description of the 'forge' look (theme name stays untranslated).
  ///
  /// In en, this message translates to:
  /// **'Furnace red, steel blue, gunmetal chrome.'**
  String get themeTaglineForge;

  /// One-line description of the 'neongrid' look (theme name stays untranslated).
  ///
  /// In en, this message translates to:
  /// **'Black glass, cyan light-lines, amber pulse.'**
  String get themeTaglineNeongrid;

  /// One-line description of the 'crimsonalloy' look (theme name stays untranslated).
  ///
  /// In en, this message translates to:
  /// **'Crimson lacquer, molten gold, midnight maroon.'**
  String get themeTaglineCrimsonalloy;

  /// One-line description of the 'circuit' look (theme name stays untranslated).
  ///
  /// In en, this message translates to:
  /// **'Circuit green, signal violet, carbon black.'**
  String get themeTaglineCircuit;

  /// One-line description of the 'deepfield' look (theme name stays untranslated).
  ///
  /// In en, this message translates to:
  /// **'Deep space, plasma blue and a flash of starlight gold.'**
  String get themeTaglineDeepfield;

  /// One-line description of the 'love' look (theme name stays untranslated).
  ///
  /// In en, this message translates to:
  /// **'Blush, rose and a little gold.'**
  String get themeTaglineLove;

  /// One-line description of the 'rose' look (theme name stays untranslated).
  ///
  /// In en, this message translates to:
  /// **'Velvet wine, rose red and a little gold.'**
  String get themeTaglineRose;

  /// One-line description of the 'petal' look (theme name stays untranslated).
  ///
  /// In en, this message translates to:
  /// **'Blush paper, drifting petals, a hint of sage.'**
  String get themeTaglinePetal;

  /// One-line description of the 'snow' look (theme name stays untranslated).
  ///
  /// In en, this message translates to:
  /// **'Fresh snowfall, frosted glass and a ribbon of aurora.'**
  String get themeTaglineSnow;

  /// One-line description of the 'gothic' look (theme name stays untranslated).
  ///
  /// In en, this message translates to:
  /// **'Moonlit tracery, garnet, candle smoke and antique gold.'**
  String get themeTaglineGothic;

  /// One-line description of the 'calm' look (theme name stays untranslated).
  ///
  /// In en, this message translates to:
  /// **'Low stimulation, high contrast. Still backdrop, no motion.'**
  String get themeTaglineCalm;

  /// Description of the default Today look under the Looks heading.
  ///
  /// In en, this message translates to:
  /// **'Warm ivory and forest by day. Soft mint and deep forest by night.'**
  String get themeLooksTodayDescription;

  /// Small all-caps eyebrow above the Settings title.
  ///
  /// In en, this message translates to:
  /// **'SETTINGS'**
  String get settingsEyebrow;

  /// Subtitle under the Settings title.
  ///
  /// In en, this message translates to:
  /// **'Your look, your privacy and your account.'**
  String get settingsHeaderSubtitle;

  /// Settings section eyebrow above the theme picker.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get settingsThemeSection;

  /// Settings section title above the theme picker.
  ///
  /// In en, this message translates to:
  /// **'Make it yours'**
  String get settingsThemeSectionTitle;

  /// Caption under the theme section title.
  ///
  /// In en, this message translates to:
  /// **'Every screen follows the look you choose.'**
  String get settingsThemeSectionCaption;

  /// Settings section header for intentional-dating story tiles.
  ///
  /// In en, this message translates to:
  /// **'Your story'**
  String get settingsSectionYourStory;

  /// Settings tile title: dating rhythm (intent, pace, availability).
  ///
  /// In en, this message translates to:
  /// **'Your dating rhythm'**
  String get settingsDatingRhythmTitle;

  /// Settings tile subtitle under Your dating rhythm.
  ///
  /// In en, this message translates to:
  /// **'Intent, pace, availability and introduction privacy'**
  String get settingsDatingRhythmSubtitle;

  /// Settings tile title: profile stories.
  ///
  /// In en, this message translates to:
  /// **'Your profile stories'**
  String get settingsProfileStoriesTitle;

  /// Settings tile subtitle under Your profile stories.
  ///
  /// In en, this message translates to:
  /// **'Small moments, your words, optional photos'**
  String get settingsProfileStoriesSubtitle;

  /// Settings tile title: the blog (Open Chapters).
  ///
  /// In en, this message translates to:
  /// **'Blog · Open Chapters'**
  String get settingsBlogTitle;

  /// Settings tile subtitle under the blog tile.
  ///
  /// In en, this message translates to:
  /// **'Your journal, your photos, your choice of audience'**
  String get settingsBlogSubtitle;

  /// Tiny all-caps label in a look's miniature Today page preview.
  ///
  /// In en, this message translates to:
  /// **'TODAY'**
  String get settingsLookPreviewEyebrow;

  /// Tiny headline in a look's miniature Today page preview.
  ///
  /// In en, this message translates to:
  /// **'Something real.'**
  String get settingsLookPreviewHeadline;

  /// Friends screen: eyebrow above the page title and the friends list section label.
  ///
  /// In en, this message translates to:
  /// **'FRIENDS'**
  String get friendsEyebrow;

  /// Friends screen: page title.
  ///
  /// In en, this message translates to:
  /// **'Your people'**
  String get friendsTitle;

  /// Friends screen: page subtitle explaining what friends can do.
  ///
  /// In en, this message translates to:
  /// **'Friends can message, plan and make groups together. Requests need a yes from both sides.'**
  String get friendsSubtitle;

  /// Friends screen: tooltip of the back button.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get friendsBack;

  /// Friends: button to add a friend (Friends screen and the Add friend button on member rows).
  ///
  /// In en, this message translates to:
  /// **'Add friend'**
  String get friendsAddFriend;

  /// Friends screen: button to start a group with chosen friends.
  ///
  /// In en, this message translates to:
  /// **'Create a group'**
  String get friendsCreateGroup;

  /// Friends screen: section label above friend requests.
  ///
  /// In en, this message translates to:
  /// **'REQUESTS'**
  String get friendsSectionRequests;

  /// Friends screen: requests section title when only my sent requests are pending.
  ///
  /// In en, this message translates to:
  /// **'Waiting on others'**
  String get friendsRequestsWaitingOnOthers;

  /// Friends screen: requests section title when someone asked me to be friends.
  ///
  /// In en, this message translates to:
  /// **'Waiting on you'**
  String get friendsRequestsWaitingOnYou;

  /// Friends screen: caption under the requests section title.
  ///
  /// In en, this message translates to:
  /// **'Nothing is shared until both of you agree.'**
  String get friendsRequestsCaption;

  /// Friends screen: section label above conversations with friends.
  ///
  /// In en, this message translates to:
  /// **'CHATS'**
  String get friendsSectionChats;

  /// Friends screen: title of the conversations section.
  ///
  /// In en, this message translates to:
  /// **'Conversations'**
  String get friendsChatsTitle;

  /// Friends screen: section label above introductions friends made for me.
  ///
  /// In en, this message translates to:
  /// **'INTROS'**
  String get friendsSectionIntros;

  /// Friends screen: title of the intros section.
  ///
  /// In en, this message translates to:
  /// **'Intros for you'**
  String get friendsIntrosTitle;

  /// Friends screen: section label above vouches (friend recommendations) waiting for approval.
  ///
  /// In en, this message translates to:
  /// **'VOUCHES'**
  String get friendsSectionVouches;

  /// Friends screen: title of the pending vouches section.
  ///
  /// In en, this message translates to:
  /// **'Vouches waiting for your approval'**
  String get friendsVouchesPendingTitle;

  /// Friends screen: title of the friends list with how many accepted friends I have.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No friends yet} =1{1 friend} other{{count} friends}}'**
  String friendsCountTitle(int count);

  /// Friends screen: button next to the friends list to introduce two friends.
  ///
  /// In en, this message translates to:
  /// **'Introduce'**
  String get friendsIntroduce;

  /// Friends screen: shown when I have no friends yet.
  ///
  /// In en, this message translates to:
  /// **'Find people you know by name or username, or add someone from a match, a room or a group.'**
  String get friendsEmptyBody;

  /// Friends screen: section label above vouches shown on my profile.
  ///
  /// In en, this message translates to:
  /// **'ON YOUR PROFILE'**
  String get friendsSectionOnProfile;

  /// Friends screen: title of the approved vouches section.
  ///
  /// In en, this message translates to:
  /// **'Vouches on your profile'**
  String get friendsVouchesOnProfileTitle;

  /// Friends: a vouch text, intro message or search query shown in quotation marks.
  ///
  /// In en, this message translates to:
  /// **'“{text}”'**
  String friendsQuoted(String text);

  /// Friends: a friend wrote a vouch about me.
  ///
  /// In en, this message translates to:
  /// **'{name} vouched for you'**
  String friendsVouchedForYou(String name);

  /// Friends screen: tooltip to hide an approved vouch from my profile.
  ///
  /// In en, this message translates to:
  /// **'Hide from profile'**
  String get friendsHideFromProfile;

  /// Friends screen: section label above links to plans and introductions.
  ///
  /// In en, this message translates to:
  /// **'MORE'**
  String get friendsSectionMore;

  /// Friends screen: title of the section linking to plans and introductions.
  ///
  /// In en, this message translates to:
  /// **'Plans and introductions'**
  String get friendsMoreTitle;

  /// Friends screen: link to date plans friends shared with me.
  ///
  /// In en, this message translates to:
  /// **'Date plans shared with you'**
  String get friendsPlansLinkTitle;

  /// Friends screen: subtitle of the shared date plans link.
  ///
  /// In en, this message translates to:
  /// **'Friends tell you when they plan a date and when they check in afterwards.'**
  String get friendsPlansLinkSubtitle;

  /// Friends screen: link to invite a friend who only introduces people and does not date.
  ///
  /// In en, this message translates to:
  /// **'Invite a friend who isn’t dating'**
  String get friendsInviteIntroducerTitle;

  /// Friends screen: subtitle of the invite-an-introducer link.
  ///
  /// In en, this message translates to:
  /// **'Choose who can introduce you. Review or withdraw permission anytime.'**
  String get friendsInviteIntroducerSubtitle;

  /// Friends screen: link to introduction preferences.
  ///
  /// In en, this message translates to:
  /// **'Introductions, on your terms'**
  String get friendsIntroTermsTitle;

  /// Friends screen: subtitle of the introduction preferences link.
  ///
  /// In en, this message translates to:
  /// **'Choose whether friends can introduce you and what a preview shares.'**
  String get friendsIntroTermsSubtitle;

  /// Friends screen: section label above recent activity with friends.
  ///
  /// In en, this message translates to:
  /// **'ACTIVITY'**
  String get friendsSectionActivity;

  /// Friends screen: title of the activity section.
  ///
  /// In en, this message translates to:
  /// **'With your friends'**
  String get friendsActivityTitle;

  /// Friends screen: snackbar after sending a vouch for a friend.
  ///
  /// In en, this message translates to:
  /// **'Vouch sent. {name} approves it before it shows.'**
  String friendsVouchSentSnack(String name);

  /// Friends screen: confirm dialog title for removing a friend.
  ///
  /// In en, this message translates to:
  /// **'Remove {name}?'**
  String friendsRemoveTitle(String name);

  /// Friends screen: confirm dialog body for removing a friend.
  ///
  /// In en, this message translates to:
  /// **'You’ll stop being friends and your friend chat closes. They aren’t told.'**
  String get friendsRemoveBody;

  /// Friends: action to remove a friend (menu item and confirm button).
  ///
  /// In en, this message translates to:
  /// **'Remove friend'**
  String get friendsRemoveFriend;

  /// Friends screen: snackbar after introducing two friends.
  ///
  /// In en, this message translates to:
  /// **'Intro made. Both friends will hear from you.'**
  String get friendsIntroMadeSnack;

  /// Add friend sheet: section label.
  ///
  /// In en, this message translates to:
  /// **'ADD FRIEND'**
  String get friendsAddSheetLabel;

  /// Add friend sheet: title.
  ///
  /// In en, this message translates to:
  /// **'Find someone you know'**
  String get friendsAddSheetTitle;

  /// Add friend sheet: caption under the title.
  ///
  /// In en, this message translates to:
  /// **'Search by name or @username. They choose whether to accept.'**
  String get friendsAddSheetCaption;

  /// Add friend sheet: note shown when I turned off being found in friend search.
  ///
  /// In en, this message translates to:
  /// **'You’re hidden from friend search, so others can’t find you here. Change this in Privacy & Safety.'**
  String get friendsSearchHiddenNote;

  /// Add friend sheet: search field label.
  ///
  /// In en, this message translates to:
  /// **'Name or @username'**
  String get friendsSearchLabel;

  /// Add friend sheet: helper text under the search field.
  ///
  /// In en, this message translates to:
  /// **'Type at least 3 letters'**
  String get friendsSearchHelper;

  /// Add friend sheet: shown when the search request fails.
  ///
  /// In en, this message translates to:
  /// **'Search is unavailable right now. Try again.'**
  String get friendsSearchFailed;

  /// Add friend sheet: no members match the query. {query} is what the member typed; keep the quotation marks of the language.
  ///
  /// In en, this message translates to:
  /// **'No one found for “{query}”.'**
  String friendsSearchNoResults(String query);

  /// Create group sheet: section label.
  ///
  /// In en, this message translates to:
  /// **'NEW GROUP'**
  String get friendsNewGroupLabel;

  /// Create group sheet: title asking which friends to include.
  ///
  /// In en, this message translates to:
  /// **'Who’s in?'**
  String get friendsNewGroupTitle;

  /// Create group sheet: caption under the title.
  ///
  /// In en, this message translates to:
  /// **'Choose friends to invite. You can add more later.'**
  String get friendsNewGroupCaption;

  /// Create group sheet: disabled continue button before any friend is chosen.
  ///
  /// In en, this message translates to:
  /// **'Choose friends'**
  String get friendsChooseFriends;

  /// Create group sheet: continue button with how many friends are chosen.
  ///
  /// In en, this message translates to:
  /// **'Create a group with {count}'**
  String friendsCreateGroupWith(int count);

  /// Friend request detail: the request came from my matches.
  ///
  /// In en, this message translates to:
  /// **'From your matches'**
  String get friendsSourceMatch;

  /// Friend request detail: the person saw my profile.
  ///
  /// In en, this message translates to:
  /// **'Saw your profile'**
  String get friendsSourceProfile;

  /// Friend request detail: we met in a conversation room.
  ///
  /// In en, this message translates to:
  /// **'Met in a room'**
  String get friendsSourceRoom;

  /// Friend request detail: the request came from a group.
  ///
  /// In en, this message translates to:
  /// **'From a group'**
  String get friendsSourceGroup;

  /// Friend request detail: the person found me by name search.
  ///
  /// In en, this message translates to:
  /// **'Found you by name'**
  String get friendsSourceSearch;

  /// Friend request row: someone asked me to be friends.
  ///
  /// In en, this message translates to:
  /// **'Wants to be friends'**
  String get friendsWantsToBeFriends;

  /// Friend request row: I sent this request.
  ///
  /// In en, this message translates to:
  /// **'Request sent'**
  String get friendsRequestSent;

  /// Friend request row: cancel my sent request.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get friendsCancel;

  /// Friend request row: decline an incoming request.
  ///
  /// In en, this message translates to:
  /// **'Decline'**
  String get friendsDecline;

  /// Friend request row: accept an incoming request.
  ///
  /// In en, this message translates to:
  /// **'Accept'**
  String get friendsAccept;

  /// Friends list: tooltip of the message button for a friend.
  ///
  /// In en, this message translates to:
  /// **'Message {name}'**
  String friendsMessageTooltip(String name);

  /// Friends list: tooltip of the message button for a friend with unread messages.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, other{Message {name}, {count} unread}}'**
  String friendsMessageTooltipUnread(String name, int count);

  /// Friends list: tooltip of the more-actions menu for a friend.
  ///
  /// In en, this message translates to:
  /// **'More for {name}'**
  String friendsMoreFor(String name);

  /// Friends list menu: write a vouch for this friend.
  ///
  /// In en, this message translates to:
  /// **'Vouch for them'**
  String get friendsMenuVouch;

  /// Friends list menu: introduce this friend to another friend.
  ///
  /// In en, this message translates to:
  /// **'Introduce to a friend'**
  String get friendsMenuIntro;

  /// Friends screen: screen reader label of a friend chat row.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{Chat with {name}} other{Chat with {name}, {count} unread}}'**
  String friendsChatSemantics(String name, int count);

  /// Friends screen: screen reader label of a friend chat row whose notifications are muted.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{Chat with {name}, notifications muted} other{Chat with {name}, {count} unread, notifications muted}}'**
  String friendsChatSemanticsMuted(String name, int count);

  /// Friends screen intro card: a friend thinks I should meet someone. {person} is a name, or a name and age.
  ///
  /// In en, this message translates to:
  /// **'{introducer} thinks you should meet {person}'**
  String friendsIntroHeadline(String introducer, String person);

  /// Friends screen intro card: a friend thinks I should meet someone whose details are not available.
  ///
  /// In en, this message translates to:
  /// **'{introducer} thinks you should meet someone'**
  String friendsIntroHeadlineSomeone(String introducer);

  /// Friends screen intro card: a person's name followed by their age.
  ///
  /// In en, this message translates to:
  /// **'{name}, {age}'**
  String friendsNameAge(String name, int age);

  /// Friends screen intro card: decline the introduction.
  ///
  /// In en, this message translates to:
  /// **'No thanks'**
  String get friendsIntroNoThanks;

  /// Friends screen intro card: accept the introduction.
  ///
  /// In en, this message translates to:
  /// **'I\'m in'**
  String get friendsIntroImIn;

  /// Friends screen vouch card: do not show this vouch on my profile.
  ///
  /// In en, this message translates to:
  /// **'Keep private'**
  String get friendsVouchKeepPrivate;

  /// Friends screen vouch card: approve the vouch and show it on my profile.
  ///
  /// In en, this message translates to:
  /// **'Show on my profile'**
  String get friendsVouchShowOnProfile;

  /// Own profile: shown when the account has no profile data yet.
  ///
  /// In en, this message translates to:
  /// **'No profile data found.'**
  String get memberProfileNoData;

  /// Own profile: error when nobody is signed in.
  ///
  /// In en, this message translates to:
  /// **'Please login to view your profile.'**
  String get memberProfileSignInToView;

  /// Own profile: error when the profile could not be loaded.
  ///
  /// In en, this message translates to:
  /// **'Failed to load profile. Please try again.'**
  String get memberProfileLoadFailed;

  /// Own profile: section header (shown in capitals) over the liked/matches/messages tiles.
  ///
  /// In en, this message translates to:
  /// **'Your connections'**
  String get memberProfileConnectionsTitle;

  /// Own profile: caption under the connections header.
  ///
  /// In en, this message translates to:
  /// **'People you liked, matched and talk to.'**
  String get memberProfileConnectionsCaption;

  /// Own profile: stat tile label under the number of members you liked.
  ///
  /// In en, this message translates to:
  /// **'You liked'**
  String get memberProfileStatLiked;

  /// Own profile: stat tile label under the number of matches.
  ///
  /// In en, this message translates to:
  /// **'Matches'**
  String get memberProfileStatMatches;

  /// Own profile: stat tile label under the number of messages.
  ///
  /// In en, this message translates to:
  /// **'Messages'**
  String get memberProfileStatMessages;

  /// Own profile: screen-reader label for a stat tile; label is the tile's name (e.g. Matches).
  ///
  /// In en, this message translates to:
  /// **'Open {label}'**
  String memberProfileOpenStat(String label);

  /// Own profile: section header (shown in capitals) over who liked / who viewed.
  ///
  /// In en, this message translates to:
  /// **'Who has noticed'**
  String get memberProfileNoticedTitle;

  /// Own profile: caption under the who-has-noticed header.
  ///
  /// In en, this message translates to:
  /// **'Likes and views from members near you.'**
  String get memberProfileNoticedCaption;

  /// Own profile: tile opening the list of members who liked you.
  ///
  /// In en, this message translates to:
  /// **'Who Liked Me'**
  String get memberProfileWhoLikedMe;

  /// Own profile: who-liked-me tile with the number of likes in brackets.
  ///
  /// In en, this message translates to:
  /// **'Who Liked Me ({count})'**
  String memberProfileWhoLikedMeCount(int count);

  /// Own profile: subtitle of the who-liked-me tile.
  ///
  /// In en, this message translates to:
  /// **'Members who liked your profile.'**
  String get memberProfileWhoLikedMeSubtitle;

  /// Own profile: tile opening the list of profile viewers.
  ///
  /// In en, this message translates to:
  /// **'Who Viewed My Profile'**
  String get memberProfileWhoViewedTitle;

  /// Own profile: subtitle of the who-viewed tile.
  ///
  /// In en, this message translates to:
  /// **'Recent visits to your profile.'**
  String get memberProfileWhoViewedSubtitle;

  /// Own profile: tooltip of the eye button in the top bar.
  ///
  /// In en, this message translates to:
  /// **'Who viewed my profile'**
  String get memberProfileWhoViewedTooltip;

  /// Own profile: tooltip of the refresh button in the top bar.
  ///
  /// In en, this message translates to:
  /// **'Refresh profile'**
  String get memberProfileRefreshTooltip;

  /// Own profile: section header (shown in capitals) over your dating preferences.
  ///
  /// In en, this message translates to:
  /// **'Your preferences'**
  String get memberProfilePreferencesTitle;

  /// Own profile preferences: row label for the genders you are looking for.
  ///
  /// In en, this message translates to:
  /// **'Seeking'**
  String get memberProfilePrefSeeking;

  /// Own profile preferences: row label for the maximum distance.
  ///
  /// In en, this message translates to:
  /// **'Distance'**
  String get memberProfilePrefDistance;

  /// Own profile preferences: maximum distance value.
  ///
  /// In en, this message translates to:
  /// **'Within {km} km'**
  String memberProfileWithinKm(int km);

  /// Profile viewers screen: app bar title.
  ///
  /// In en, this message translates to:
  /// **'Viewed My Profile'**
  String get profileViewersTitle;

  /// Profile viewers screen: error when the list could not be loaded.
  ///
  /// In en, this message translates to:
  /// **'Failed to load profile viewers.'**
  String get profileViewersLoadFailed;

  /// Profile viewers screen: empty state.
  ///
  /// In en, this message translates to:
  /// **'No one has viewed your profile yet.'**
  String get profileViewersEmpty;

  /// Profile viewers screen: subtitle when the visit time is unknown.
  ///
  /// In en, this message translates to:
  /// **'Viewed recently'**
  String get profileViewersViewedRecently;

  /// Profile viewers screen: subtitle with the date and time of the visit (already formatted).
  ///
  /// In en, this message translates to:
  /// **'Viewed at {time}'**
  String profileViewersViewedAt(String time);

  /// Display label for the religion option stored as 'Parsi'. The stored value never changes.
  ///
  /// In en, this message translates to:
  /// **'Parsi'**
  String get profileMasterReligionParsi;

  /// Display label for the religion option stored as 'Bahai'. The stored value never changes.
  ///
  /// In en, this message translates to:
  /// **'Bahai'**
  String get profileMasterReligionBahai;

  /// Display label for the religion option stored as 'Tribal / Indigenous'. The stored value never changes.
  ///
  /// In en, this message translates to:
  /// **'Tribal / Indigenous'**
  String get profileMasterReligionTribal;

  /// Display label for the workout frequency option stored as '1-2 times a week'. The stored value never changes.
  ///
  /// In en, this message translates to:
  /// **'1-2 times a week'**
  String get profileMasterWorkout1to2;

  /// Display label for the workout frequency option stored as '3-4 times a week'. The stored value never changes.
  ///
  /// In en, this message translates to:
  /// **'3-4 times a week'**
  String get profileMasterWorkout3to4;

  /// Display label for the workout frequency option stored as '5+ times a week'. The stored value never changes.
  ///
  /// In en, this message translates to:
  /// **'5+ times a week'**
  String get profileMasterWorkout5Plus;

  /// Display label for the workout frequency option stored as 'Daily'. The stored value never changes.
  ///
  /// In en, this message translates to:
  /// **'Daily'**
  String get profileMasterWorkoutDaily;

  /// Display label for the diet preference option stored as 'No preference'. The stored value never changes.
  ///
  /// In en, this message translates to:
  /// **'No preference'**
  String get profileMasterDietNoPreference;

  /// Display label for the diet preference option stored as 'Vegetarian'. The stored value never changes.
  ///
  /// In en, this message translates to:
  /// **'Vegetarian'**
  String get profileMasterDietVegetarian;

  /// Display label for the diet preference (vegetarian who eats eggs) option stored as 'Eggetarian'. The stored value never changes.
  ///
  /// In en, this message translates to:
  /// **'Eggetarian'**
  String get profileMasterDietEggetarian;

  /// Display label for the diet preference option stored as 'Non-vegetarian'. The stored value never changes.
  ///
  /// In en, this message translates to:
  /// **'Non-vegetarian'**
  String get profileMasterDietNonVegetarian;

  /// Display label for the diet preference option stored as 'Vegan'. The stored value never changes.
  ///
  /// In en, this message translates to:
  /// **'Vegan'**
  String get profileMasterDietVegan;

  /// Display label for the diet preference (Jain diet, not the religion) option stored as 'Jain'. The stored value never changes.
  ///
  /// In en, this message translates to:
  /// **'Jain'**
  String get profileMasterDietJain;

  /// Display label for the diet type option stored as 'Balanced'. The stored value never changes.
  ///
  /// In en, this message translates to:
  /// **'Balanced'**
  String get profileMasterDietTypeBalanced;

  /// Display label for the diet type option stored as 'High Protein'. The stored value never changes.
  ///
  /// In en, this message translates to:
  /// **'High Protein'**
  String get profileMasterDietTypeHighProtein;

  /// Display label for the diet type option stored as 'Low Carb'. The stored value never changes.
  ///
  /// In en, this message translates to:
  /// **'Low Carb'**
  String get profileMasterDietTypeLowCarb;

  /// Display label for the diet type option stored as 'Keto'. The stored value never changes.
  ///
  /// In en, this message translates to:
  /// **'Keto'**
  String get profileMasterDietTypeKeto;

  /// Display label for the diet type option stored as 'Mediterranean'. The stored value never changes.
  ///
  /// In en, this message translates to:
  /// **'Mediterranean'**
  String get profileMasterDietTypeMediterranean;

  /// Display label for the diet type option stored as 'Intermittent Fasting'. The stored value never changes.
  ///
  /// In en, this message translates to:
  /// **'Intermittent Fasting'**
  String get profileMasterDietTypeIntermittentFasting;

  /// Display label for the sleep schedule option stored as 'Early bird'. The stored value never changes.
  ///
  /// In en, this message translates to:
  /// **'Early bird'**
  String get profileMasterSleepEarlyBird;

  /// Display label for the sleep schedule option stored as 'Night owl'. The stored value never changes.
  ///
  /// In en, this message translates to:
  /// **'Night owl'**
  String get profileMasterSleepNightOwl;

  /// Display label for the sleep schedule option stored as 'Flexible'. The stored value never changes.
  ///
  /// In en, this message translates to:
  /// **'Flexible'**
  String get profileMasterSleepFlexible;

  /// Display label for the sleep schedule option stored as 'Shift based'. The stored value never changes.
  ///
  /// In en, this message translates to:
  /// **'Shift based'**
  String get profileMasterSleepShiftBased;

  /// Display label for the travel style option stored as 'Homebody'. The stored value never changes.
  ///
  /// In en, this message translates to:
  /// **'Homebody'**
  String get profileMasterTravelHomebody;

  /// Display label for the travel style option stored as 'Occasional traveler'. The stored value never changes.
  ///
  /// In en, this message translates to:
  /// **'Occasional traveler'**
  String get profileMasterTravelOccasional;

  /// Display label for the travel style option stored as 'Frequent traveler'. The stored value never changes.
  ///
  /// In en, this message translates to:
  /// **'Frequent traveler'**
  String get profileMasterTravelFrequent;

  /// Display label for the travel style option stored as 'Adventure seeker'. The stored value never changes.
  ///
  /// In en, this message translates to:
  /// **'Adventure seeker'**
  String get profileMasterTravelAdventure;

  /// Display label for the travel style option stored as 'Luxury traveler'. The stored value never changes.
  ///
  /// In en, this message translates to:
  /// **'Luxury traveler'**
  String get profileMasterTravelLuxury;

  /// Display label for the travel style option stored as 'Backpacker'. The stored value never changes.
  ///
  /// In en, this message translates to:
  /// **'Backpacker'**
  String get profileMasterTravelBackpacker;

  /// Display label for the political comfort option stored as 'Similar views only'. The stored value never changes.
  ///
  /// In en, this message translates to:
  /// **'Similar views only'**
  String get profileMasterPoliticsSimilar;

  /// Display label for the political comfort option stored as 'Open to differences'. The stored value never changes.
  ///
  /// In en, this message translates to:
  /// **'Open to differences'**
  String get profileMasterPoliticsOpen;

  /// Display label for the political comfort option stored as 'Prefer not to discuss'. The stored value never changes.
  ///
  /// In en, this message translates to:
  /// **'Prefer not to discuss'**
  String get profileMasterPoliticsNotDiscuss;

  /// Display label for the political comfort option stored as 'No strong preference'. The stored value never changes.
  ///
  /// In en, this message translates to:
  /// **'No strong preference'**
  String get profileMasterPoliticsNoStrong;

  /// Display label for the relationship intent option stored as 'long_term'. The stored value never changes.
  ///
  /// In en, this message translates to:
  /// **'Long term'**
  String get profileMasterIntentLongTerm;

  /// Display label for the relationship intent option stored as 'marriage'. The stored value never changes.
  ///
  /// In en, this message translates to:
  /// **'Marriage'**
  String get profileMasterIntentMarriage;

  /// Display label for the relationship intent option stored as 'new_friends'. The stored value never changes.
  ///
  /// In en, this message translates to:
  /// **'New friends'**
  String get profileMasterIntentNewFriends;

  /// Match chat: tooltip of the back button that returns to the conversation list.
  ///
  /// In en, this message translates to:
  /// **'Back to conversations'**
  String get chatBackToConversations;

  /// Match chat: banner shown while the device is offline.
  ///
  /// In en, this message translates to:
  /// **'You’re offline. Your draft will stay here while you reconnect.'**
  String get chatOfflineBanner;

  /// Match chat: button that opens voice icebreakers (record or listen to a short voice hello).
  ///
  /// In en, this message translates to:
  /// **'Share a voice hello · read & listen'**
  String get chatVoiceHello;

  /// Match chat: title when the conversation could not be loaded.
  ///
  /// In en, this message translates to:
  /// **'Let’s reconnect.'**
  String get chatLoadFailedTitle;

  /// Match chat: body when the conversation could not be loaded.
  ///
  /// In en, this message translates to:
  /// **'Your conversation couldn’t load. Try again.'**
  String get chatLoadFailedBody;

  /// Match chat: banner when the match has ended and no new messages can be sent.
  ///
  /// In en, this message translates to:
  /// **'This conversation has ended.'**
  String get chatConversationEnded;

  /// Match chat: banner when the chat is locked until the member completes an unlock step.
  ///
  /// In en, this message translates to:
  /// **'Complete the current unlock step to continue this conversation.'**
  String get chatUnlockStepRequired;

  /// Match chat: title of the gift tray.
  ///
  /// In en, this message translates to:
  /// **'A little something for them'**
  String get chatGiftTrayTitle;

  /// Match chat: tooltip of the button that closes the gift tray.
  ///
  /// In en, this message translates to:
  /// **'Close gifts'**
  String get chatCloseGifts;

  /// Match chat: gift tray filter chip showing every gift category.
  ///
  /// In en, this message translates to:
  /// **'All gifts'**
  String get chatAllGifts;

  /// Match chat: gift tray message when the selected category has no gifts.
  ///
  /// In en, this message translates to:
  /// **'No gifts available in this collection.'**
  String get chatNoGiftsInCollection;

  /// Match chat: gift tile label when the member cannot afford the gift.
  ///
  /// In en, this message translates to:
  /// **'Add coins'**
  String get chatAddCoins;

  /// Match chat: gift tile price label for the free gift (one per day).
  ///
  /// In en, this message translates to:
  /// **'Free · 1 a day'**
  String get chatFreeGiftDaily;

  /// Chat: an amount of in-app coins (gift prices, wallet balance).
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 coin} other{{count} coins}}'**
  String chatCoinCount(int count);

  /// Match chat: overlay while a gift is being sent.
  ///
  /// In en, this message translates to:
  /// **'Sending your gift…'**
  String get chatSendingGift;

  /// Match chat: snackbar when a gift is tapped while offline.
  ///
  /// In en, this message translates to:
  /// **'You\'re offline. You can browse gifts and send once you reconnect.'**
  String get chatOfflineGifts;

  /// Match chat: title of the sheet confirming a paid gift. {gift} is the gift name, {name} the match's name.
  ///
  /// In en, this message translates to:
  /// **'Send {gift} to {name}?'**
  String chatGiftConfirmTitle(String gift, String name);

  /// Match chat: the note typed with a gift, shown in quotation marks on the confirm sheet.
  ///
  /// In en, this message translates to:
  /// **'“{note}”'**
  String chatGiftNoteQuote(String note);

  /// Match chat: gift confirm sheet, current coin balance and what will be left after sending.
  ///
  /// In en, this message translates to:
  /// **'·  {balance} → {remaining} left'**
  String chatGiftBalanceAfter(int balance, int remaining);

  /// Match chat: reassurance on the gift confirm sheet.
  ///
  /// In en, this message translates to:
  /// **'A gift is a gesture, never an obligation to reply or meet.'**
  String get chatGiftNoObligation;

  /// Match chat: confirm button on the paid gift sheet. {price} is an amount of coins, e.g. '50 coins'.
  ///
  /// In en, this message translates to:
  /// **'Send for {price}'**
  String chatGiftSendFor(String price);

  /// Match chat: dismisses the paid gift confirm sheet.
  ///
  /// In en, this message translates to:
  /// **'Not now'**
  String get chatNotNow;

  /// Match chat: title of the sheet confirming a message delete.
  ///
  /// In en, this message translates to:
  /// **'Delete message?'**
  String get chatDeleteMessageTitle;

  /// Match chat: body of the sheet confirming a message delete.
  ///
  /// In en, this message translates to:
  /// **'This removes the message from both chat inboxes.'**
  String get chatDeleteMessageBody;

  /// Match chat: button that deletes a message for both people.
  ///
  /// In en, this message translates to:
  /// **'Delete for everyone'**
  String get chatDeleteForEveryone;

  /// Match chat: snackbar after a message was deleted (with an Undo action).
  ///
  /// In en, this message translates to:
  /// **'Message deleted.'**
  String get chatMessageDeletedSnack;

  /// Match chat: snackbar action that undoes a delete.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get chatUndo;

  /// Match chat: snackbar after a delete was undone.
  ///
  /// In en, this message translates to:
  /// **'Delete undone.'**
  String get chatDeleteUndone;

  /// Match chat: heading of a gift someone sent you. {name} is the sender.
  ///
  /// In en, this message translates to:
  /// **'Gift received from {name}'**
  String chatGiftReceivedFrom(String name);

  /// Match chat: intro on the received-gift options sheet.
  ///
  /// In en, this message translates to:
  /// **'You decide what stays in your chat.'**
  String get chatGiftReceiverIntro;

  /// Match chat: option that hides a received gift.
  ///
  /// In en, this message translates to:
  /// **'Hide gift'**
  String get chatHideGift;

  /// Match chat: explains that hiding a gift only affects your own chat.
  ///
  /// In en, this message translates to:
  /// **'Remove it from your chat only.'**
  String get chatHideGiftSubtitle;

  /// Match chat: option that reports and hides a received gift.
  ///
  /// In en, this message translates to:
  /// **'Report and hide'**
  String get chatReportAndHide;

  /// Match chat: explains the report-and-hide option for a gift.
  ///
  /// In en, this message translates to:
  /// **'Send it to the safety team and remove it now.'**
  String get chatReportAndHideSubtitle;

  /// Match chat: snackbar after hiding a received gift.
  ///
  /// In en, this message translates to:
  /// **'Gift hidden from your chat.'**
  String get chatGiftHidden;

  /// Match chat: title of the sheet for reporting a gift.
  ///
  /// In en, this message translates to:
  /// **'Report this gift'**
  String get chatReportGiftTitle;

  /// Match chat: intro of the sheet for reporting a gift.
  ///
  /// In en, this message translates to:
  /// **'Choose a reason. The gift will be hidden immediately.'**
  String get chatReportGiftIntro;

  /// Match chat: label of the gift report reason dropdown.
  ///
  /// In en, this message translates to:
  /// **'Reason'**
  String get chatReportReasonLabel;

  /// Match chat: gift report reason.
  ///
  /// In en, this message translates to:
  /// **'Unwanted gift'**
  String get chatReportReasonUnwanted;

  /// Match chat: gift report reason.
  ///
  /// In en, this message translates to:
  /// **'Harassment'**
  String get chatReportReasonHarassment;

  /// Match chat: gift report reason.
  ///
  /// In en, this message translates to:
  /// **'Sexual content'**
  String get chatReportReasonSexual;

  /// Match chat: gift report reason.
  ///
  /// In en, this message translates to:
  /// **'Scam or fraud'**
  String get chatReportReasonScam;

  /// Match chat: gift report reason for anything else.
  ///
  /// In en, this message translates to:
  /// **'Something else'**
  String get chatReportReasonOther;

  /// Match chat: optional details field when reporting a gift.
  ///
  /// In en, this message translates to:
  /// **'Add details (optional)'**
  String get chatReportDetailsLabel;

  /// Match chat: button that submits a gift report and hides the gift.
  ///
  /// In en, this message translates to:
  /// **'Submit report and hide'**
  String get chatReportSubmit;

  /// Match chat: snackbar after reporting a gift.
  ///
  /// In en, this message translates to:
  /// **'Gift reported and hidden. Our safety team will review it.'**
  String get chatGiftReported;

  /// Match chat: title of the quick emoji picker.
  ///
  /// In en, this message translates to:
  /// **'Quick emojis'**
  String get chatQuickEmojis;

  /// Match chat: tooltip of the wallet chip in the header.
  ///
  /// In en, this message translates to:
  /// **'Your wallet · {count, plural, =1{1 coin} other{{count} coins}}'**
  String chatWalletTooltip(int count);

  /// Match chat: fallback headline when today's message allowance is used up.
  ///
  /// In en, this message translates to:
  /// **'Daily message limit reached'**
  String get chatDailyLimitReached;

  /// Match chat: daily limit banner body when no reset time is known.
  ///
  /// In en, this message translates to:
  /// **'Try again tomorrow or upgrade your plan.'**
  String get chatDailyLimitFallback;

  /// Match chat: daily limit banner body. {reset} says when the allowance resets (already localized).
  ///
  /// In en, this message translates to:
  /// **'{reset} · upgrade for more.'**
  String chatDailyLimitReset(String reset);

  /// Match chat: button on the daily limit banner that opens plans.
  ///
  /// In en, this message translates to:
  /// **'See plans'**
  String get chatSeePlans;

  /// Match chat: remaining-messages hint under the composer. {quota} is the remaining allowance text, {plan} the plan name.
  ///
  /// In en, this message translates to:
  /// **'{quota} on {plan}'**
  String chatQuotaOnPlan(String quota, String plan);

  /// Match chat: header subtitle when neither member is verified.
  ///
  /// In en, this message translates to:
  /// **'Your conversation'**
  String get chatYourConversation;

  /// Match chat: header subtitle when both members are verified humans.
  ///
  /// In en, this message translates to:
  /// **'Verified humans'**
  String get chatVerifiedHumans;

  /// Match chat: header subtitle when both are verified and the match has the 'Shows up' badge (keeps their dates).
  ///
  /// In en, this message translates to:
  /// **'Verified humans · Shows up'**
  String get chatVerifiedHumansShowsUp;

  /// Who liked me: snackbar after liking someone back (no match screen).
  ///
  /// In en, this message translates to:
  /// **'You liked {name} back'**
  String discoverLikedBack(String name);

  /// Who liked me: snackbar after passing on someone.
  ///
  /// In en, this message translates to:
  /// **'Passed on {name}'**
  String discoverPassedOn(String name);

  /// Who liked me: error state title.
  ///
  /// In en, this message translates to:
  /// **'Could not load your likes'**
  String get discoverLikedMeLoadFailedTitle;

  /// Who liked me: empty state title.
  ///
  /// In en, this message translates to:
  /// **'No new likes yet'**
  String get discoverLikedMeEmptyTitle;

  /// Who liked me: empty state body.
  ///
  /// In en, this message translates to:
  /// **'When someone likes you, they show up here. Like them back and it\'s a match.'**
  String get discoverLikedMeEmptyBody;

  /// Who liked me: explainer above the list.
  ///
  /// In en, this message translates to:
  /// **'They already like you. Like back to match, or pass. Passing is private.'**
  String get discoverLikedMeIntro;

  /// Who liked me: screen title (also the liked-at fallback label).
  ///
  /// In en, this message translates to:
  /// **'Liked you'**
  String get discoverLikedMeTitle;

  /// Who liked me: screen title with the number of pending likes.
  ///
  /// In en, this message translates to:
  /// **'Liked you · {count}'**
  String discoverLikedMeTitleCount(int count);

  /// Who liked me: pass button.
  ///
  /// In en, this message translates to:
  /// **'Pass'**
  String get discoverPass;

  /// Who liked me: like back button.
  ///
  /// In en, this message translates to:
  /// **'Like back'**
  String get discoverLikeBack;

  /// Who liked me: when the like arrived less than a minute ago.
  ///
  /// In en, this message translates to:
  /// **'Liked you just now'**
  String get discoverLikedJustNow;

  /// Who liked me: minutes since the like.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Liked you 1 minute ago} other{Liked you {count} minutes ago}}'**
  String discoverLikedMinutesAgo(int count);

  /// Who liked me: hours since the like.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Liked you 1 hour ago} other{Liked you {count} hours ago}}'**
  String discoverLikedHoursAgo(int count);

  /// Who liked me: days since the like.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Liked you 1 day ago} other{Liked you {count} days ago}}'**
  String discoverLikedDaysAgo(int count);

  /// Who liked me: weeks since the like.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Liked you 1 week ago} other{Liked you {count} weeks ago}}'**
  String discoverLikedWeeksAgo(int count);

  /// Who liked me: like older than a month. {date} is a locale-formatted date.
  ///
  /// In en, this message translates to:
  /// **'Liked you on {date}'**
  String discoverLikedOnDate(String date);

  /// Liked profiles screen title with the count.
  ///
  /// In en, this message translates to:
  /// **'Liked Profiles ({count})'**
  String discoverLikedProfilesTitle(int count);

  /// Liked profiles screen empty state.
  ///
  /// In en, this message translates to:
  /// **'No liked profiles yet'**
  String get discoverNoLikedProfiles;

  /// Liked profiles screen: subtitle when the profile has no details.
  ///
  /// In en, this message translates to:
  /// **'Liked profile'**
  String get discoverLikedProfileFallback;

  /// Passed profiles screen title.
  ///
  /// In en, this message translates to:
  /// **'Passed Profiles'**
  String get discoverPassedProfilesTitle;

  /// Passed profiles screen empty state.
  ///
  /// In en, this message translates to:
  /// **'No passed profiles yet'**
  String get discoverNoPassedProfiles;

  /// Passed profiles screen: subtitle when the profile has no details.
  ///
  /// In en, this message translates to:
  /// **'Saved for later'**
  String get discoverSavedForLater;

  /// Spotlight: filters sheet title.
  ///
  /// In en, this message translates to:
  /// **'Spotlight Filters'**
  String get discoverSpotlightFiltersTitle;

  /// Spotlight: switch / chip limiting to verified members.
  ///
  /// In en, this message translates to:
  /// **'Verified only'**
  String get discoverVerifiedOnly;

  /// Spotlight: selected age range in the filters sheet.
  ///
  /// In en, this message translates to:
  /// **'Age range: {min} - {max}'**
  String discoverAgeRange(int min, int max);

  /// Spotlight: screen heading.
  ///
  /// In en, this message translates to:
  /// **'Spotlight Matches'**
  String get discoverSpotlightTitle;

  /// Spotlight: screen subtitle.
  ///
  /// In en, this message translates to:
  /// **'Curated premium connections'**
  String get discoverSpotlightSubtitle;

  /// Spotlight: button showing the number of passed profiles.
  ///
  /// In en, this message translates to:
  /// **'Passed ({count})'**
  String discoverPassedCount(int count);

  /// Spotlight: snackbar when tapping Messages.
  ///
  /// In en, this message translates to:
  /// **'Open chats from Discover'**
  String get discoverOpenChatsFromDiscover;

  /// Spotlight: snackbar when tapping the bell.
  ///
  /// In en, this message translates to:
  /// **'No new notifications'**
  String get discoverNoNewNotifications;

  /// Spotlight: empty state when filters exclude everyone.
  ///
  /// In en, this message translates to:
  /// **'No spotlight profiles match filters'**
  String get discoverNoSpotlightMatchFilters;

  /// Spotlight: empty state when everyone was reviewed.
  ///
  /// In en, this message translates to:
  /// **'All spotlight profiles reviewed!'**
  String get discoverAllSpotlightReviewed;

  /// Spotlight: empty state hint.
  ///
  /// In en, this message translates to:
  /// **'Check back later for new spotlight profiles'**
  String get discoverSpotlightCheckBackLater;

  /// Profile details: snackbar after a report is submitted.
  ///
  /// In en, this message translates to:
  /// **'Report submitted.'**
  String get discoverReportSubmitted;

  /// Profile details: snackbar action opening moderation appeals.
  ///
  /// In en, this message translates to:
  /// **'Appeal'**
  String get discoverAppeal;

  /// Profile details: prefilled appeal reason. {userId} is an internal id.
  ///
  /// In en, this message translates to:
  /// **'Review moderation outcome for report on user {userId}'**
  String discoverAppealPrefill(String userId);

  /// Profile details: shown when the profile cannot be loaded.
  ///
  /// In en, this message translates to:
  /// **'This profile is unavailable right now.'**
  String get discoverProfileUnavailable;

  /// Profile details: button leaving an unavailable profile.
  ///
  /// In en, this message translates to:
  /// **'Go back'**
  String get discoverGoBack;

  /// Premium spotlight card: button opening the premium profile view.
  ///
  /// In en, this message translates to:
  /// **'Premium view'**
  String get discoverPremiumView;

  /// Today screen: uppercase kicker above the date.
  ///
  /// In en, this message translates to:
  /// **'TODAY'**
  String get todayLabel;

  /// Today screen: refresh button tooltip.
  ///
  /// In en, this message translates to:
  /// **'Refresh Today'**
  String get todayRefreshTooltip;

  /// Today screen: tooltip for the discovery filters button.
  ///
  /// In en, this message translates to:
  /// **'Discovery preferences'**
  String get todayDiscoveryPreferences;

  /// Today screen: two-line serif headline.
  ///
  /// In en, this message translates to:
  /// **'A little hello.\nRoom for something real.'**
  String get todayHeroTitle;

  /// Today screen: one-line promise under the headline.
  ///
  /// In en, this message translates to:
  /// **'A few thoughtful introductions, at your pace.'**
  String get todayHeroSubtitle;

  /// Today screen: uppercase section label for the dating rhythm card.
  ///
  /// In en, this message translates to:
  /// **'YOUR PACE'**
  String get todaySectionPace;

  /// Today screen: dating rhythm card title.
  ///
  /// In en, this message translates to:
  /// **'What fits your week?'**
  String get todayPaceTitle;

  /// Today screen: dating rhythm card body.
  ///
  /// In en, this message translates to:
  /// **'Your pace, your kind of first date, optional availability.'**
  String get todayPaceBody;

  /// Today screen: button opening the dating rhythm.
  ///
  /// In en, this message translates to:
  /// **'Set your rhythm'**
  String get todaySetRhythm;

  /// Today screen: uppercase section label for the story card.
  ///
  /// In en, this message translates to:
  /// **'YOUR STORY'**
  String get todaySectionStory;

  /// Today screen: uppercase section label for today's introductions.
  ///
  /// In en, this message translates to:
  /// **'TODAY’S INTRODUCTIONS'**
  String get todaySectionIntroductions;

  /// Today screen: introductions section title.
  ///
  /// In en, this message translates to:
  /// **'A few people to get to know'**
  String get todayIntroductionsTitle;

  /// Today screen: introductions section caption.
  ///
  /// In en, this message translates to:
  /// **'Shared interests are a starting point. Chemistry is yours to discover.'**
  String get todayIntroductionsCaption;

  /// Today screen: notice title while introductions are paused.
  ///
  /// In en, this message translates to:
  /// **'Take the time you need.'**
  String get todayPausedTitle;

  /// Today screen: notice body while introductions are paused.
  ///
  /// In en, this message translates to:
  /// **'Introductions are paused. Your conversations are still here.'**
  String get todayPausedBody;

  /// Today screen: button to manage the dating rhythm while paused.
  ///
  /// In en, this message translates to:
  /// **'Manage your rhythm'**
  String get todayManageRhythm;

  /// Today screen: screen-reader label of the loading spinner.
  ///
  /// In en, this message translates to:
  /// **'Loading introductions'**
  String get todayLoadingIntroductions;

  /// Today screen: notice title when introductions fail to load.
  ///
  /// In en, this message translates to:
  /// **'Your introductions are taking a moment.'**
  String get todayFailedTitle;

  /// Today screen: notice body when introductions fail to load.
  ///
  /// In en, this message translates to:
  /// **'We couldn’t load the latest information. Please try again.'**
  String get todayFailedBody;

  /// Today screen: retry button.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get todayTryAgain;

  /// Today screen: notice title when there are no introductions.
  ///
  /// In en, this message translates to:
  /// **'A little breathing room.'**
  String get todayEmptyTitle;

  /// Today screen: notice body when there are no introductions.
  ///
  /// In en, this message translates to:
  /// **'There are no new introductions for your preferences right now. You can adjust your rhythm or explore profiles.'**
  String get todayEmptyBody;

  /// Today screen: button to browse profiles when empty.
  ///
  /// In en, this message translates to:
  /// **'Explore profiles'**
  String get todayExploreProfiles;

  /// Today screen: filter chip showing all introductions.
  ///
  /// In en, this message translates to:
  /// **'All introductions'**
  String get todayAllIntroductions;

  /// Today screen: closing card title under the introductions.
  ///
  /// In en, this message translates to:
  /// **'A good connection has room to breathe.'**
  String get todayBreatheTitle;

  /// Today screen: closing card body under the introductions.
  ///
  /// In en, this message translates to:
  /// **'These are today’s introductions. There is no countdown, and no need to decide on everyone.'**
  String get todayBreatheBody;

  /// Today screen: button to browse more profiles.
  ///
  /// In en, this message translates to:
  /// **'Explore more profiles'**
  String get todayExploreMore;

  /// Today introduction card: uppercase label above shared reasons.
  ///
  /// In en, this message translates to:
  /// **'A LITTLE COMMON GROUND'**
  String get todayCommonGround;

  /// Today introduction card: button to open a profile.
  ///
  /// In en, this message translates to:
  /// **'Meet {name}'**
  String todayMeetName(String name);

  /// Today introduction card: first-date idea for the shared activity 'coffee'.
  ///
  /// In en, this message translates to:
  /// **'A first hello could be a coffee together.'**
  String get todayFirstHelloCoffee;

  /// Today introduction card: first-date idea for the shared activity 'walk'.
  ///
  /// In en, this message translates to:
  /// **'A first hello could be a daytime walk.'**
  String get todayFirstHelloWalk;

  /// Today introduction card: first-date idea for the shared activity 'meal'.
  ///
  /// In en, this message translates to:
  /// **'A first hello could be a relaxed meal.'**
  String get todayFirstHelloMeal;

  /// Today introduction card: first-date idea for the shared activity 'video_call'.
  ///
  /// In en, this message translates to:
  /// **'A first hello could be a video hello.'**
  String get todayFirstHelloVideoCall;

  /// Today introduction card: first-date idea for the shared activity 'event'.
  ///
  /// In en, this message translates to:
  /// **'A first hello could be an event you both enjoy.'**
  String get todayFirstHelloEvent;

  /// Today introduction card: first-date idea for the shared activity 'drinks'.
  ///
  /// In en, this message translates to:
  /// **'A first hello could be a drink together.'**
  String get todayFirstHelloDrinks;

  /// Today introduction card: first-date idea for the shared activity 'any other activity'.
  ///
  /// In en, this message translates to:
  /// **'A first hello could be something you both enjoy.'**
  String get todayFirstHelloOther;

  /// Today screen: uppercase section label for shared activities.
  ///
  /// In en, this message translates to:
  /// **'SOMETHING TO TALK ABOUT'**
  String get todaySectionTalk;

  /// Today screen: caption for the shared activities section.
  ///
  /// In en, this message translates to:
  /// **'Stories, clubs and prompts that make a first hello easier.'**
  String get todayTalkCaption;

  /// Today screen: blog feature card title.
  ///
  /// In en, this message translates to:
  /// **'Blog · Open Chapters'**
  String get todayBlogTitle;

  /// Today screen: blog feature card subtitle.
  ///
  /// In en, this message translates to:
  /// **'Read members’ stories and write your own.'**
  String get todayBlogSubtitle;

  /// Today screen: book clubs tile title.
  ///
  /// In en, this message translates to:
  /// **'Book clubs'**
  String get todayBookClubsTitle;

  /// Today screen: book clubs tile subtitle.
  ///
  /// In en, this message translates to:
  /// **'One book a week, talked over together.'**
  String get todayBookClubsSubtitle;

  /// Today screen: film clubs tile title.
  ///
  /// In en, this message translates to:
  /// **'Film clubs'**
  String get todayFilmClubsTitle;

  /// Today screen: film clubs tile subtitle.
  ///
  /// In en, this message translates to:
  /// **'Watch the pick, then swap takes.'**
  String get todayFilmClubsSubtitle;

  /// Today screen: photo themes tile title.
  ///
  /// In en, this message translates to:
  /// **'Photo Themes'**
  String get todayPhotoThemesTitle;

  /// Today screen: photo themes tile subtitle.
  ///
  /// In en, this message translates to:
  /// **'One photo per prompt. See everyone’s.'**
  String get todayPhotoThemesSubtitle;

  /// Today screen: First Chapter Studio tile title.
  ///
  /// In en, this message translates to:
  /// **'First Chapter Studio'**
  String get todayChapterStudioTitle;

  /// Today screen: First Chapter Studio tile subtitle.
  ///
  /// In en, this message translates to:
  /// **'Begin a story together.'**
  String get todayChapterStudioSubtitle;

  /// Cover of the Week: line shown when the photo has no caption or theme.
  ///
  /// In en, this message translates to:
  /// **'A photo members loved'**
  String get todayCoverFallbackLine;

  /// Cover of the Week: screen-reader label, with the photographer's first name.
  ///
  /// In en, this message translates to:
  /// **'Open the Cover of the Week by {name}'**
  String todayCoverSemantics(String name);

  /// Cover of the Week: uppercase masthead.
  ///
  /// In en, this message translates to:
  /// **'COVER OF THE WEEK'**
  String get todayCoverTitle;

  /// Cover of the Week: uppercase byline; the name is already uppercased.
  ///
  /// In en, this message translates to:
  /// **'BY {name}'**
  String todayCoverBy(String name);

  /// Screen-reader label for the likes icon.
  ///
  /// In en, this message translates to:
  /// **'Likes'**
  String get todayLikes;

  /// Screen-reader label for the comments icon.
  ///
  /// In en, this message translates to:
  /// **'Comments'**
  String get todayComments;

  /// Cover of the Week: small chip.
  ///
  /// In en, this message translates to:
  /// **'This week'**
  String get todayThisWeek;

  /// Today's wall: uppercase section label.
  ///
  /// In en, this message translates to:
  /// **'FROM THE COMMUNITY'**
  String get todayWallLabel;

  /// Today's wall: section title.
  ///
  /// In en, this message translates to:
  /// **'Today’s wall'**
  String get todayWallTitle;

  /// Today's wall: section caption.
  ///
  /// In en, this message translates to:
  /// **'Stories and photos members loved — new picks every day'**
  String get todayWallCaption;

  /// Today's wall: previous item tooltip.
  ///
  /// In en, this message translates to:
  /// **'Previous pick'**
  String get todayWallPrevious;

  /// Today's wall: next item tooltip.
  ///
  /// In en, this message translates to:
  /// **'Next pick'**
  String get todayWallNext;

  /// Today's wall: uppercase label on a blog chapter card.
  ///
  /// In en, this message translates to:
  /// **'CHAPTER'**
  String get todayWallChapter;

  /// Today's wall: title for a chapter without one.
  ///
  /// In en, this message translates to:
  /// **'An untitled chapter'**
  String get todayWallUntitled;

  /// Today's wall: author byline on a chapter card.
  ///
  /// In en, this message translates to:
  /// **'by {name}'**
  String todayWallBy(String name);

  /// Today's wall: empty state.
  ///
  /// In en, this message translates to:
  /// **'Your wall fills up as members share stories and photos they love'**
  String get todayWallEmpty;

  /// Today's wall: empty-state button to write a chapter.
  ///
  /// In en, this message translates to:
  /// **'Write a chapter'**
  String get todayWallWrite;

  /// Today's wall: empty-state button to share a photo.
  ///
  /// In en, this message translates to:
  /// **'Share a photo'**
  String get todayWallShare;

  /// Profile setup header: tooltip of the back button.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get profileSetupBackTooltip;

  /// Profile setup header: which step of the setup flow the member is on.
  ///
  /// In en, this message translates to:
  /// **'Step {current} of {total}'**
  String profileSetupStepCounter(int current, int total);

  /// Profile setup / edit profile: heading when the saved profile could not be loaded.
  ///
  /// In en, this message translates to:
  /// **'Could not load profile data.'**
  String get profileSetupLoadErrorTitle;

  /// Profile setup: button that retries loading the profile.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get profileSetupRetry;

  /// Profile option label: education level 'High School'.
  ///
  /// In en, this message translates to:
  /// **'High School'**
  String get profileSetupEducationHighSchool;

  /// Profile option label: education level 'Bachelor's' degree.
  ///
  /// In en, this message translates to:
  /// **'Bachelor\'s'**
  String get profileSetupEducationBachelors;

  /// Profile option label: education level 'Master's' degree.
  ///
  /// In en, this message translates to:
  /// **'Master\'s'**
  String get profileSetupEducationMasters;

  /// Profile option label: education level 'PhD'.
  ///
  /// In en, this message translates to:
  /// **'PhD'**
  String get profileSetupEducationPhd;

  /// Profile option label: education level 'Other'.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get profileSetupEducationOther;

  /// Profile option label and dropdown hint: 'Prefer not to say' (income, religion).
  ///
  /// In en, this message translates to:
  /// **'Prefer not to say'**
  String get profileSetupPreferNotToSay;

  /// Profile option label: income range below an amount (amount stays as written, e.g. ₹5L).
  ///
  /// In en, this message translates to:
  /// **'Below {amount}'**
  String profileSetupIncomeBelow(String amount);

  /// Profile option label: drinking/smoking frequency 'Never'.
  ///
  /// In en, this message translates to:
  /// **'Never'**
  String get profileSetupFrequencyNever;

  /// Profile option label: drinking frequency 'Socially'.
  ///
  /// In en, this message translates to:
  /// **'Socially'**
  String get profileSetupFrequencySocially;

  /// Profile option label: smoking frequency 'Occasionally'.
  ///
  /// In en, this message translates to:
  /// **'Occasionally'**
  String get profileSetupFrequencyOccasionally;

  /// Profile option label: drinking/smoking frequency 'Regularly'.
  ///
  /// In en, this message translates to:
  /// **'Regularly'**
  String get profileSetupFrequencyRegularly;

  /// Profile: gender value 'Man' shown on the edit profile screen.
  ///
  /// In en, this message translates to:
  /// **'Man'**
  String get profileSetupGenderMan;

  /// Profile: gender value 'Woman' shown on the edit profile screen.
  ///
  /// In en, this message translates to:
  /// **'Woman'**
  String get profileSetupGenderWoman;

  /// Profile: gender value 'Other' (non-binary or other).
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get profileSetupGenderOther;

  /// Profile setup: error when the bio is shorter than the minimum length.
  ///
  /// In en, this message translates to:
  /// **'{min, plural, =1{Bio must be at least 1 character.} other{Bio must be at least {min} characters.}}'**
  String profileSetupBioTooShort(int min);

  /// Profile setup: snack bar when saving the About step failed.
  ///
  /// In en, this message translates to:
  /// **'Failed to save — please try again.'**
  String get profileSetupSaveFailed;

  /// Profile setup: snack bar when changes could not be saved on leaving a step.
  ///
  /// In en, this message translates to:
  /// **'Could not save your changes. Please try again.'**
  String get profileSetupCouldNotSaveChanges;

  /// Profile setup About step: page title.
  ///
  /// In en, this message translates to:
  /// **'Make your profile shine'**
  String get profileSetupAboutTitle;

  /// Profile setup About step: subtitle under the title.
  ///
  /// In en, this message translates to:
  /// **'These details help find better matches.'**
  String get profileSetupAboutSubtitle;

  /// Profile setup / edit profile: label of the bio field.
  ///
  /// In en, this message translates to:
  /// **'Bio'**
  String get profileSetupBioLabel;

  /// Profile setup: hint inside the bio text field with the minimum length.
  ///
  /// In en, this message translates to:
  /// **'{min, plural, =1{Tell people about you (min 1 char)} other{Tell people about you (min {min} chars)}}'**
  String profileSetupBioHint(int min);

  /// Profile setup: label of the height dropdown (centimetres).
  ///
  /// In en, this message translates to:
  /// **'Height (cm)'**
  String get profileSetupHeightLabel;

  /// Profile setup: placeholder of the height dropdown.
  ///
  /// In en, this message translates to:
  /// **'Select height'**
  String get profileSetupHeightHint;

  /// Profile: a height in centimetres (dropdown items, chips, edit profile).
  ///
  /// In en, this message translates to:
  /// **'{cm} cm'**
  String profileSetupHeightValue(int cm);

  /// Profile setup / edit profile: label of the education field.
  ///
  /// In en, this message translates to:
  /// **'Education'**
  String get profileSetupEducationLabel;

  /// Profile setup: placeholder of the education dropdown.
  ///
  /// In en, this message translates to:
  /// **'Select education'**
  String get profileSetupEducationHint;

  /// Profile setup / edit profile: label of the profession field.
  ///
  /// In en, this message translates to:
  /// **'Profession'**
  String get profileSetupProfessionLabel;

  /// Profile setup: example placeholder in the profession field.
  ///
  /// In en, this message translates to:
  /// **'e.g. Software Engineer'**
  String get profileSetupProfessionHint;

  /// Profile setup: label of the optional income dropdown.
  ///
  /// In en, this message translates to:
  /// **'Income (optional)'**
  String get profileSetupIncomeLabel;

  /// Profile setup / edit profile: Lifestyle section heading.
  ///
  /// In en, this message translates to:
  /// **'Lifestyle'**
  String get profileSetupLifestyleTitle;

  /// Profile setup / edit profile: label of the drinking habit field.
  ///
  /// In en, this message translates to:
  /// **'Drinking'**
  String get profileSetupDrinkingLabel;

  /// Profile setup / edit profile: label of the smoking habit field.
  ///
  /// In en, this message translates to:
  /// **'Smoking'**
  String get profileSetupSmokingLabel;

  /// Profile setup: generic placeholder of a dropdown.
  ///
  /// In en, this message translates to:
  /// **'Select'**
  String get profileSetupSelectHint;

  /// Profile setup: label of the optional religion dropdown.
  ///
  /// In en, this message translates to:
  /// **'Religion (optional)'**
  String get profileSetupReligionOptionalLabel;

  /// Profile setup About step: primary button moving to the next step.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get profileSetupContinue;

  /// Edit About screen: primary button saving the About details.
  ///
  /// In en, this message translates to:
  /// **'Save About'**
  String get profileSetupSaveAbout;

  /// Photos screen (web): snack bar after the photos were saved.
  ///
  /// In en, this message translates to:
  /// **'Photos saved.'**
  String get profileSetupPhotosSaved;

  /// Photos screen: error when the member already has the maximum number of photos.
  ///
  /// In en, this message translates to:
  /// **'{max, plural, =1{You can upload up to 1 photo only.} other{You can upload up to {max} photos only.}}'**
  String profileSetupPhotosMaxReached(int max);

  /// Photos screen: title of the dialog confirming a photo removal.
  ///
  /// In en, this message translates to:
  /// **'Remove this photo?'**
  String get profileSetupRemovePhotoTitle;

  /// Photos screen: body of the dialog confirming a photo removal.
  ///
  /// In en, this message translates to:
  /// **'It will be removed from your profile and deleted from storage.'**
  String get profileSetupRemovePhotoBody;

  /// Photos screen: dialog button that cancels the removal.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get profileSetupCancel;

  /// Photos screen: dialog button that confirms the removal.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get profileSetupRemove;

  /// Photos screen: error when continuing with fewer than the minimum photos.
  ///
  /// In en, this message translates to:
  /// **'{min, plural, =1{Please upload at least 1 photo to continue.} other{Please upload at least {min} photos to continue.}}'**
  String profileSetupPhotosMinRequired(int min);

  /// Photos screen: page title.
  ///
  /// In en, this message translates to:
  /// **'Add your photos'**
  String get profileSetupPhotosTitle;

  /// Photos screen: subtitle with the minimum number of photos.
  ///
  /// In en, this message translates to:
  /// **'{min, plural, =1{Add at least 1 photo to get matches} other{Add at least {min} photos to get matches}}'**
  String profileSetupPhotosSubtitle(int min);

  /// Photos screen: heading of the card choosing gallery or camera.
  ///
  /// In en, this message translates to:
  /// **'Choose source'**
  String get profileSetupChooseSource;

  /// Photos screen: button picking a photo from the gallery.
  ///
  /// In en, this message translates to:
  /// **'Gallery'**
  String get profileSetupGallery;

  /// Photos screen: button taking a photo with the camera.
  ///
  /// In en, this message translates to:
  /// **'Camera'**
  String get profileSetupCamera;

  /// Photos screen: accepted formats and limits (keep format names and units).
  ///
  /// In en, this message translates to:
  /// **'JPEG, PNG, WebP or HEIC · 300×300 minimum · 10 MB each · 50 MB total'**
  String get profileSetupPhotoRequirements;

  /// Photos screen: tip shown when no photo has been added yet.
  ///
  /// In en, this message translates to:
  /// **'{min, plural, =1{Add at least 1 photo to show different sides of you.} other{Add at least {min} photos to show different sides of you.}}'**
  String profileSetupPhotosTipEmpty(int min);

  /// Photos screen: tip with how many more photos are needed (English keeps 'photo(s)').
  ///
  /// In en, this message translates to:
  /// **'Add {count} more photo(s) to unlock full matching.'**
  String profileSetupPhotosTipMore(int count);

  /// Photos screen: tip once enough photos have been added.
  ///
  /// In en, this message translates to:
  /// **'Great! You can reorder photos by dragging.'**
  String get profileSetupPhotosTipDone;

  /// Photos screen: heading of the reorderable photo list.
  ///
  /// In en, this message translates to:
  /// **'Your photos  •  drag to reorder'**
  String get profileSetupYourPhotosHeading;

  /// Photos screen (setup flow): button moving on to the About step.
  ///
  /// In en, this message translates to:
  /// **'Continue to About'**
  String get profileSetupContinueToAbout;

  /// Photos screen (editing): button saving the photos.
  ///
  /// In en, this message translates to:
  /// **'Save Photos'**
  String get profileSetupSavePhotos;

  /// Photos screen: label of the first (primary) photo row.
  ///
  /// In en, this message translates to:
  /// **'Primary photo'**
  String get profileSetupPrimaryPhoto;

  /// Photos screen: label of a non-primary photo row by its position.
  ///
  /// In en, this message translates to:
  /// **'Photo {number}'**
  String profileSetupPhotoNumber(int number);

  /// Photos screen: hint under the primary photo.
  ///
  /// In en, this message translates to:
  /// **'Shown first on your profile'**
  String get profileSetupShownFirst;

  /// Photos screen: hint under a non-primary photo.
  ///
  /// In en, this message translates to:
  /// **'Drag handle to reorder'**
  String get profileSetupDragHandleHint;

  /// Photos screen: moderation status of a photo needing manual review.
  ///
  /// In en, this message translates to:
  /// **'Awaiting safety review'**
  String get profileSetupAwaitingSafetyReview;

  /// Photos screen: moderation status of a photo being checked automatically.
  ///
  /// In en, this message translates to:
  /// **'Safety check in progress'**
  String get profileSetupSafetyCheckInProgress;

  /// Photos screen: link making this photo the profile picture.
  ///
  /// In en, this message translates to:
  /// **'Set as profile picture'**
  String get profileSetupSetAsProfilePicture;

  /// Photos screen: note on the photo that is the profile picture.
  ///
  /// In en, this message translates to:
  /// **'Profile picture selected'**
  String get profileSetupProfilePictureSelected;

  /// Photos screen: tooltip of the delete button on a photo row.
  ///
  /// In en, this message translates to:
  /// **'Remove photo'**
  String get profileSetupRemovePhotoTooltip;

  /// Photo upload error: the file is over 10 MB.
  ///
  /// In en, this message translates to:
  /// **'This photo is larger than the 10 MB limit.'**
  String get profileSetupPhotoTooLarge;

  /// Photo upload error: unsupported image type.
  ///
  /// In en, this message translates to:
  /// **'Use a JPEG, PNG, WebP, or HEIC photo.'**
  String get profileSetupPhotoUnsupportedType;

  /// Photo upload error: image dimensions out of range.
  ///
  /// In en, this message translates to:
  /// **'Photo dimensions must be between 300×300 and 4096×4096.'**
  String get profileSetupPhotoBadDimensions;

  /// Photo upload error: the member's photo quota is full.
  ///
  /// In en, this message translates to:
  /// **'Your profile photo quota has been reached.'**
  String get profileSetupPhotoQuotaReached;

  /// Photo upload error: server storage temporarily full.
  ///
  /// In en, this message translates to:
  /// **'Photo storage is temporarily full. Please try again later.'**
  String get profileSetupPhotoStorageFull;

  /// Photo upload/delete/reorder: generic failure.
  ///
  /// In en, this message translates to:
  /// **'Photo update failed. Please try again.'**
  String get profileSetupPhotoUpdateFailed;

  /// Photo upload error: maximum number of photos reached.
  ///
  /// In en, this message translates to:
  /// **'{max, plural, =1{Maximum 1 photo is allowed.} other{Maximum {max} photos are allowed.}}'**
  String profileSetupPhotoMaxAllowed(int max);

  /// Preferences screen: error when preferences could not load.
  ///
  /// In en, this message translates to:
  /// **'Failed to load preferences'**
  String get profileSetupPreferencesLoadFailed;

  /// Preferences screen: banner when option lists are loaded from the offline copy.
  ///
  /// In en, this message translates to:
  /// **'Offline mode — some data may be outdated.'**
  String get profileSetupOfflineBanner;

  /// Preferences screen (setup flow): page title.
  ///
  /// In en, this message translates to:
  /// **'Your Preferences'**
  String get profileSetupYourPreferences;

  /// Preferences screen (editing): page title.
  ///
  /// In en, this message translates to:
  /// **'Edit Preferences'**
  String get profileSetupEditPreferencesTitle;

  /// Preferences screen (setup flow): button finishing setup.
  ///
  /// In en, this message translates to:
  /// **'Finish & Find Matches'**
  String get profileSetupFinishAndFindMatches;

  /// Preferences screen (editing): button saving preferences.
  ///
  /// In en, this message translates to:
  /// **'Save Preferences'**
  String get profileSetupSavePreferences;

  /// Preferences screen: error when no gender is selected.
  ///
  /// In en, this message translates to:
  /// **'Select at least one gender preference.'**
  String get profileSetupSelectGenderPreference;

  /// Preferences screen (setup flow): error when finishing setup failed.
  ///
  /// In en, this message translates to:
  /// **'Could not finish setup. Please check your photos and preferences, then try again.'**
  String get profileSetupFinishFailed;

  /// Preferences screen (editing): error when saving failed.
  ///
  /// In en, this message translates to:
  /// **'Some preferences could not be saved right now.'**
  String get profileSetupPreferencesSaveFailed;

  /// Preferences screen (web): snack bar after saving.
  ///
  /// In en, this message translates to:
  /// **'Preferences saved.'**
  String get profileSetupPreferencesSaved;

  /// Preferences screen: tab with the basic preferences.
  ///
  /// In en, this message translates to:
  /// **'Basic'**
  String get profileSetupTabBasic;

  /// Preferences screen: tab with the advanced preferences.
  ///
  /// In en, this message translates to:
  /// **'Advanced'**
  String get profileSetupTabAdvanced;

  /// Preferences screen: heading of the genders the member wants to meet.
  ///
  /// In en, this message translates to:
  /// **'I\'m looking for'**
  String get profileSetupLookingFor;

  /// Preferences screen: chip to meet men.
  ///
  /// In en, this message translates to:
  /// **'Men'**
  String get profileSetupSeekingMen;

  /// Preferences screen: chip to meet women.
  ///
  /// In en, this message translates to:
  /// **'Women'**
  String get profileSetupSeekingWomen;

  /// Preferences screen: chip to meet people of another gender.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get profileSetupSeekingOther;

  /// Preferences screen: age range heading with the selected bounds.
  ///
  /// In en, this message translates to:
  /// **'Age range: {min} – {max}'**
  String profileSetupAgeRangeTitle(int min, int max);

  /// Preferences screen: max distance heading with the selected kilometres.
  ///
  /// In en, this message translates to:
  /// **'Max distance: {km} km'**
  String profileSetupMaxDistanceTitle(int km);

  /// Preferences screen / edit profile: a distance in kilometres.
  ///
  /// In en, this message translates to:
  /// **'{km} km'**
  String profileSetupDistanceValue(int km);

  /// Preferences screen: heading of the intent toggles.
  ///
  /// In en, this message translates to:
  /// **'Relationship intent'**
  String get profileSetupRelationshipIntent;

  /// Preferences screen: toggle limiting to people seeking a serious relationship.
  ///
  /// In en, this message translates to:
  /// **'Serious relationship only'**
  String get profileSetupSeriousOnly;

  /// Preferences screen: explanation of the serious-only toggle.
  ///
  /// In en, this message translates to:
  /// **'Show only users seeking commitment'**
  String get profileSetupSeriousOnlySubtitle;

  /// Preferences screen: toggle limiting to verified profiles.
  ///
  /// In en, this message translates to:
  /// **'Verified profiles only'**
  String get profileSetupVerifiedOnly;

  /// Preferences screen: explanation of the verified-only toggle.
  ///
  /// In en, this message translates to:
  /// **'Filter to ID-verified accounts'**
  String get profileSetupVerifiedOnlySubtitle;

  /// Preferences screen: toggle limiting to casual-only profiles.
  ///
  /// In en, this message translates to:
  /// **'Hookups only'**
  String get profileSetupHookupsOnly;

  /// Preferences screen: explanation of the hookups-only toggle.
  ///
  /// In en, this message translates to:
  /// **'Show casual-only profiles'**
  String get profileSetupHookupsOnlySubtitle;

  /// Preferences screen: Location card heading.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get profileSetupLocation;

  /// Preferences screen / edit profile: country field label.
  ///
  /// In en, this message translates to:
  /// **'Country'**
  String get profileSetupCountry;

  /// Preferences screen: state or region field label.
  ///
  /// In en, this message translates to:
  /// **'State / Region'**
  String get profileSetupStateRegion;

  /// Preferences screen / edit profile: city field label.
  ///
  /// In en, this message translates to:
  /// **'City'**
  String get profileSetupCity;

  /// Preferences screen: Background & culture card heading.
  ///
  /// In en, this message translates to:
  /// **'Background & culture'**
  String get profileSetupBackgroundCulture;

  /// Preferences screen: religion field label.
  ///
  /// In en, this message translates to:
  /// **'Religion preference'**
  String get profileSetupReligionPreference;

  /// Preferences screen / edit profile: mother tongue field label.
  ///
  /// In en, this message translates to:
  /// **'Mother tongue'**
  String get profileSetupMotherTongue;

  /// Preferences screen: language field label.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get profileSetupLanguage;

  /// Preferences screen / edit profile: diet preference field label.
  ///
  /// In en, this message translates to:
  /// **'Diet preference'**
  String get profileSetupDietPreference;

  /// Preferences screen: workout frequency field label.
  ///
  /// In en, this message translates to:
  /// **'Workout frequency'**
  String get profileSetupWorkoutFrequency;

  /// Preferences screen / edit profile: diet type field label.
  ///
  /// In en, this message translates to:
  /// **'Diet type'**
  String get profileSetupDietType;

  /// Preferences screen / edit profile: sleep schedule field label.
  ///
  /// In en, this message translates to:
  /// **'Sleep schedule'**
  String get profileSetupSleepSchedule;

  /// Preferences screen / edit profile: travel style field label.
  ///
  /// In en, this message translates to:
  /// **'Travel style'**
  String get profileSetupTravelStyle;

  /// Preferences screen: political comfort range field label.
  ///
  /// In en, this message translates to:
  /// **'Political comfort range'**
  String get profileSetupPoliticalComfortRange;

  /// Preferences screen: Interests & personality card heading.
  ///
  /// In en, this message translates to:
  /// **'Interests & personality'**
  String get profileSetupInterestsPersonality;

  /// Preferences screen: Instagram handle field label.
  ///
  /// In en, this message translates to:
  /// **'Instagram handle (without @)'**
  String get profileSetupInstagramHandle;

  /// Preferences screen: relationship intent tags field label with examples.
  ///
  /// In en, this message translates to:
  /// **'Intent tags (long-term, marriage, casual…)'**
  String get profileSetupIntentTags;

  /// Preferences screen: hobbies field label.
  ///
  /// In en, this message translates to:
  /// **'Hobbies (comma-separated)'**
  String get profileSetupHobbiesField;

  /// Preferences screen: favourite books field label.
  ///
  /// In en, this message translates to:
  /// **'Favourite books (comma-separated)'**
  String get profileSetupFavouriteBooksField;

  /// Preferences screen: favourite novels field label.
  ///
  /// In en, this message translates to:
  /// **'Favourite novels (comma-separated)'**
  String get profileSetupFavouriteNovelsField;

  /// Preferences screen: favourite songs field label.
  ///
  /// In en, this message translates to:
  /// **'Favourite songs (comma-separated)'**
  String get profileSetupFavouriteSongsField;

  /// Preferences screen: extra-curricular activities field label.
  ///
  /// In en, this message translates to:
  /// **'Extra-curricular activities (comma-separated)'**
  String get profileSetupExtraCurricularField;

  /// Preferences screen: free-text additional information field label.
  ///
  /// In en, this message translates to:
  /// **'Additional information'**
  String get profileSetupAdditionalInformation;

  /// Preferences screen: pet preference field label.
  ///
  /// In en, this message translates to:
  /// **'Pet preference'**
  String get profileSetupPetPreference;

  /// Preferences screen: Deal-breakers card heading.
  ///
  /// In en, this message translates to:
  /// **'Deal-breakers'**
  String get profileSetupDealBreakers;

  /// Preferences screen: deal-breaker tags field label.
  ///
  /// In en, this message translates to:
  /// **'Tags (comma-separated)'**
  String get profileSetupTagsField;

  /// Profile preview: validation error when the name is missing.
  ///
  /// In en, this message translates to:
  /// **'Name is required.'**
  String get profileSetupNameRequired;

  /// Profile preview: validation error when the date of birth is missing.
  ///
  /// In en, this message translates to:
  /// **'Date of birth is required.'**
  String get profileSetupDobRequired;

  /// Profile preview: validation error when there are too few photos.
  ///
  /// In en, this message translates to:
  /// **'{min, plural, =1{At least 1 photo is required.} other{At least {min} photos are required.}}'**
  String profileSetupPhotosRequired(int min);

  /// Profile preview: fallback when the server rejected completion without a message.
  ///
  /// In en, this message translates to:
  /// **'Server error'**
  String get profileSetupServerError;

  /// Profile preview: error when completing failed because of the network.
  ///
  /// In en, this message translates to:
  /// **'Network error — please try again.'**
  String get profileSetupNetworkError;

  /// Profile preview: unexpected error when completing the profile.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get profileSetupGenericError;

  /// Profile preview: page title.
  ///
  /// In en, this message translates to:
  /// **'Preview your profile'**
  String get profileSetupPreviewTitle;

  /// Profile preview: subtitle.
  ///
  /// In en, this message translates to:
  /// **'This is how others will see you.'**
  String get profileSetupPreviewSubtitle;

  /// Profile preview: the member's name followed by their age.
  ///
  /// In en, this message translates to:
  /// **'{name}, {age}'**
  String profileSetupNameAge(String name, int age);

  /// Profile preview: chip with the member's drinking habit.
  ///
  /// In en, this message translates to:
  /// **'Drinks: {value}'**
  String profileSetupDrinksChip(String value);

  /// Profile preview: chip with the member's smoking habit.
  ///
  /// In en, this message translates to:
  /// **'Smokes: {value}'**
  String profileSetupSmokesChip(String value);

  /// Profile preview: button completing the profile.
  ///
  /// In en, this message translates to:
  /// **'Complete Profile'**
  String get profileSetupCompleteProfile;

  /// Profile preview: profile completion percentage.
  ///
  /// In en, this message translates to:
  /// **'Profile completion: {percent}%'**
  String profileSetupCompletionPercent(int percent);

  /// Edit profile screen: app bar title.
  ///
  /// In en, this message translates to:
  /// **'Edit Profile'**
  String get profileEditTitle;

  /// Edit profile screen: tooltip of the refresh button.
  ///
  /// In en, this message translates to:
  /// **'Refresh profile'**
  String get profileEditRefreshTooltip;

  /// Edit profile screen: About you section heading.
  ///
  /// In en, this message translates to:
  /// **'About you'**
  String get profileEditAboutYou;

  /// Edit profile screen: button opening the About editor.
  ///
  /// In en, this message translates to:
  /// **'Edit about'**
  String get profileEditEditAbout;

  /// Edit profile screen: row label for the name.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get profileEditName;

  /// Edit profile screen: row label for the phone number.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get profileEditPhone;

  /// Edit profile screen: row label for the date of birth.
  ///
  /// In en, this message translates to:
  /// **'Date of birth'**
  String get profileEditDateOfBirth;

  /// Edit profile screen: row label for the gender.
  ///
  /// In en, this message translates to:
  /// **'Gender'**
  String get profileEditGender;

  /// Edit profile screen: row label for the height.
  ///
  /// In en, this message translates to:
  /// **'Height'**
  String get profileEditHeight;

  /// Edit profile screen: row label for the income range.
  ///
  /// In en, this message translates to:
  /// **'Income range'**
  String get profileEditIncomeRange;

  /// Edit profile screen: Location & social section heading.
  ///
  /// In en, this message translates to:
  /// **'Location & social'**
  String get profileEditLocationSocial;

  /// Edit profile screen: button opening the preferences editor.
  ///
  /// In en, this message translates to:
  /// **'Edit preferences'**
  String get profileEditEditPreferences;

  /// Edit profile screen: row label for the state or region.
  ///
  /// In en, this message translates to:
  /// **'State'**
  String get profileEditState;

  /// Edit profile screen: row label for the Instagram handle (brand name).
  ///
  /// In en, this message translates to:
  /// **'Instagram'**
  String get profileEditInstagram;

  /// Edit profile screen: Dating preferences section heading.
  ///
  /// In en, this message translates to:
  /// **'Dating preferences'**
  String get profileEditDatingPreferences;

  /// Edit profile screen: row label for the genders the member is seeking.
  ///
  /// In en, this message translates to:
  /// **'Seeking'**
  String get profileEditSeeking;

  /// Edit profile screen: row label for the preferred age range.
  ///
  /// In en, this message translates to:
  /// **'Age range'**
  String get profileEditAgeRange;

  /// Edit profile screen: preferred age range value.
  ///
  /// In en, this message translates to:
  /// **'{min}–{max}'**
  String profileEditAgeRangeValue(int min, int max);

  /// Edit profile screen: row label for the maximum distance.
  ///
  /// In en, this message translates to:
  /// **'Max distance'**
  String get profileEditMaxDistance;

  /// Edit profile screen: row label for the education filter.
  ///
  /// In en, this message translates to:
  /// **'Education filter'**
  String get profileEditEducationFilter;

  /// Edit profile screen: row label for the serious-only preference.
  ///
  /// In en, this message translates to:
  /// **'Serious only'**
  String get profileEditSeriousOnly;

  /// Edit profile screen: row label for the verified-only preference.
  ///
  /// In en, this message translates to:
  /// **'Verified only'**
  String get profileEditVerifiedOnly;

  /// Edit profile screen: row label for the hookup-only preference.
  ///
  /// In en, this message translates to:
  /// **'Hookup only'**
  String get profileEditHookupOnly;

  /// Edit profile screen: value of an enabled yes/no preference.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get profileEditYes;

  /// Edit profile screen: value of a disabled yes/no preference.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get profileEditNo;

  /// Edit profile screen: row label for the relationship intent tags.
  ///
  /// In en, this message translates to:
  /// **'Intent'**
  String get profileEditIntent;

  /// Edit profile screen: row label for languages.
  ///
  /// In en, this message translates to:
  /// **'Languages'**
  String get profileEditLanguages;

  /// Edit profile screen: row label for deal breakers.
  ///
  /// In en, this message translates to:
  /// **'Deal breakers'**
  String get profileEditDealBreakers;

  /// Edit profile screen: row label for religion.
  ///
  /// In en, this message translates to:
  /// **'Religion'**
  String get profileEditReligion;

  /// Edit profile screen: row label for pet preference.
  ///
  /// In en, this message translates to:
  /// **'Pets'**
  String get profileEditPets;

  /// Edit profile screen: row label for workout frequency.
  ///
  /// In en, this message translates to:
  /// **'Workout'**
  String get profileEditWorkout;

  /// Edit profile screen: row label for political comfort range.
  ///
  /// In en, this message translates to:
  /// **'Politics comfort'**
  String get profileEditPoliticsComfort;

  /// Edit profile screen: Interests & details section heading.
  ///
  /// In en, this message translates to:
  /// **'Interests & details'**
  String get profileEditInterestsDetails;

  /// Edit profile screen: row label for hobbies.
  ///
  /// In en, this message translates to:
  /// **'Hobbies'**
  String get profileEditHobbies;

  /// Edit profile screen: row label for favourite books.
  ///
  /// In en, this message translates to:
  /// **'Books'**
  String get profileEditBooks;

  /// Edit profile screen: row label for favourite novels.
  ///
  /// In en, this message translates to:
  /// **'Novels'**
  String get profileEditNovels;

  /// Edit profile screen: row label for favourite songs.
  ///
  /// In en, this message translates to:
  /// **'Songs'**
  String get profileEditSongs;

  /// Edit profile screen: row label for extra-curricular activities.
  ///
  /// In en, this message translates to:
  /// **'Extra curriculars'**
  String get profileEditExtraCurriculars;

  /// Edit profile screen: row label for additional information.
  ///
  /// In en, this message translates to:
  /// **'Additional info'**
  String get profileEditAdditionalInfo;

  /// Edit profile screen: placeholder for a field with no value.
  ///
  /// In en, this message translates to:
  /// **'Not set'**
  String get profileEditNotSet;

  /// Edit profile screen: heading while the saved profile loads.
  ///
  /// In en, this message translates to:
  /// **'Loading your saved profile'**
  String get profileEditLoadingTitle;

  /// Edit profile screen: explanation while the saved profile loads.
  ///
  /// In en, this message translates to:
  /// **'Binding the information saved during account setup.'**
  String get profileEditLoadingBody;

  /// Edit profile screen: hero title when the member has no name yet.
  ///
  /// In en, this message translates to:
  /// **'Your profile'**
  String get profileEditYourProfile;

  /// Edit profile screen: profile completion percentage under the progress bar.
  ///
  /// In en, this message translates to:
  /// **'{percent}% complete'**
  String profileEditPercentComplete(int percent);

  /// Edit profile screen: Photo gallery section heading.
  ///
  /// In en, this message translates to:
  /// **'Photo gallery'**
  String get profileEditPhotoGallery;

  /// Edit profile screen: button opening the photo manager.
  ///
  /// In en, this message translates to:
  /// **'Manage photos'**
  String get profileEditManagePhotos;

  /// Edit profile screen: empty state of the photo gallery.
  ///
  /// In en, this message translates to:
  /// **'No photos uploaded yet.'**
  String get profileEditNoPhotos;

  /// Edit profile screen: badge on the primary photo.
  ///
  /// In en, this message translates to:
  /// **'Primary'**
  String get profileEditPrimaryBadge;

  /// Engage hub: Daily Prompt tile subtitle while today's prompt loads.
  ///
  /// In en, this message translates to:
  /// **'Loading today\'s prompt'**
  String get engagementHubPromptLoading;

  /// Engage hub: Daily Prompt tile subtitle when no prompt is loaded.
  ///
  /// In en, this message translates to:
  /// **'Answer one prompt daily and build your streak.'**
  String get engagementHubPromptIntro;

  /// Engage hub: Daily Prompt tile subtitle, how many people answered today's prompt.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, other{{count} people replied today}}'**
  String engagementHubPromptRepliedToday(int count);

  /// Engage hub: Daily Prompt tile subtitle after answering; streak length in days (d = days) and number of similar replies.
  ///
  /// In en, this message translates to:
  /// **'Streak {days}d · {similar} similar replies'**
  String engagementHubPromptStreakSummary(int days, int similar);

  /// Engage hub tile title for the blog. 'Open Chapters' is the blog's name.
  ///
  /// In en, this message translates to:
  /// **'Blog · Open Chapters'**
  String get engagementHubBlogTitle;

  /// Engage hub tile subtitle for the blog.
  ///
  /// In en, this message translates to:
  /// **'Read stories, share photos and write your own.'**
  String get engagementHubBlogSubtitle;

  /// Engage hub tile title for Photo Themes.
  ///
  /// In en, this message translates to:
  /// **'Photo Themes'**
  String get engagementHubPhotoThemesTitle;

  /// Engage hub tile subtitle for Photo Themes.
  ///
  /// In en, this message translates to:
  /// **'Share one photo per prompt and see everyone’s.'**
  String get engagementHubPhotoThemesSubtitle;

  /// Engage hub tile title for book and film clubs.
  ///
  /// In en, this message translates to:
  /// **'Book & Film Clubs'**
  String get engagementHubClubsTitle;

  /// Engage hub tile subtitle for book and film clubs.
  ///
  /// In en, this message translates to:
  /// **'Follow a weekly pick, talk it over, rate it.'**
  String get engagementHubClubsSubtitle;

  /// Engage hub tile title for the City Pilot community.
  ///
  /// In en, this message translates to:
  /// **'The City Pilot'**
  String get engagementHubCityPilotTitle;

  /// Engage hub tile subtitle for the City Pilot community.
  ///
  /// In en, this message translates to:
  /// **'A small community. Conversations that become plans.'**
  String get engagementHubCityPilotSubtitle;

  /// Title of the Daily Prompt Streak screen and its Engage hub tile.
  ///
  /// In en, this message translates to:
  /// **'Daily Prompt Streak'**
  String get engagementDailyPromptTitle;

  /// Engage hub tile title for voice icebreakers.
  ///
  /// In en, this message translates to:
  /// **'Guided Voice Icebreakers'**
  String get engagementHubVoiceTitle;

  /// Engage hub tile subtitle for voice icebreakers (20-45 second voice intro, one per match per day).
  ///
  /// In en, this message translates to:
  /// **'Send one guided 20-45s voice intro per match/day'**
  String get engagementHubVoiceSubtitle;

  /// Title of the Local Circle Challenges screen and its Engage hub tile.
  ///
  /// In en, this message translates to:
  /// **'Local Circle Challenges'**
  String get engagementCirclesTitle;

  /// Engage hub tile subtitle for local circle challenges.
  ///
  /// In en, this message translates to:
  /// **'Join a city circle and submit this week\'s entry'**
  String get engagementHubCirclesSubtitle;

  /// Engage hub tile title for group coffee polls.
  ///
  /// In en, this message translates to:
  /// **'Group Coffee Poll'**
  String get engagementHubCoffeeTitle;

  /// Engage hub tile subtitle for group coffee polls.
  ///
  /// In en, this message translates to:
  /// **'Create, vote, and finalize lightweight meetup polls'**
  String get engagementHubCoffeeSubtitle;

  /// Engage hub tile title for Groups.
  ///
  /// In en, this message translates to:
  /// **'Groups'**
  String get engagementHubGroupsTitle;

  /// Engage hub tile subtitle for Groups.
  ///
  /// In en, this message translates to:
  /// **'Lifestyle communities and private friend groups'**
  String get engagementHubGroupsSubtitle;

  /// Engage hub tile subtitle for Conversation Rooms.
  ///
  /// In en, this message translates to:
  /// **'Live chat rooms: drop in, talk, make friends'**
  String get engagementHubRoomsSubtitle;

  /// Engage hub tile title for friends and introductions.
  ///
  /// In en, this message translates to:
  /// **'Friends & Introductions'**
  String get engagementHubFriendsTitle;

  /// Engage hub tile subtitle for friends and introductions.
  ///
  /// In en, this message translates to:
  /// **'Invite a trusted friend, even if they aren’t dating'**
  String get engagementHubFriendsSubtitle;

  /// Title of the Level & XP screen and its Engage hub tile. XP = experience points.
  ///
  /// In en, this message translates to:
  /// **'Level & XP'**
  String get engagementLevelTitle;

  /// Engage hub tile subtitle for Level & XP.
  ///
  /// In en, this message translates to:
  /// **'Track meaningful activity, level rewards, and trust gates'**
  String get engagementHubLevelSubtitle;

  /// Engage hub billing note: core progression never requires payment.
  ///
  /// In en, this message translates to:
  /// **'Core progression stays paywall-free.'**
  String get engagementHubPaywallFree;

  /// Engage hub billing note while the monetization policy changes.
  ///
  /// In en, this message translates to:
  /// **'Monetization policy is being updated.'**
  String get engagementHubPolicyUpdating;

  /// Engage hub billing note listing optional paid features (codes from the server).
  ///
  /// In en, this message translates to:
  /// **'Optional premium areas: {features}'**
  String engagementHubPremiumAreas(String features);

  /// Engage hub page eyebrow (small uppercase label).
  ///
  /// In en, this message translates to:
  /// **'ENGAGE'**
  String get engagementHubEyebrow;

  /// Engage hub page title.
  ///
  /// In en, this message translates to:
  /// **'Make something together.'**
  String get engagementHubTitle;

  /// Engage hub page subtitle.
  ///
  /// In en, this message translates to:
  /// **'Build stronger matches with trust and shared activities.'**
  String get engagementHubSubtitle;

  /// Engage hub section label (uppercase).
  ///
  /// In en, this message translates to:
  /// **'CREATE & SHARE'**
  String get engagementHubSectionCreate;

  /// Engage hub caption under CREATE & SHARE.
  ///
  /// In en, this message translates to:
  /// **'Stories, photos and clubs that start real conversations.'**
  String get engagementHubSectionCreateCaption;

  /// Engage hub section label (uppercase).
  ///
  /// In en, this message translates to:
  /// **'MEET PEOPLE'**
  String get engagementHubSectionMeet;

  /// Engage hub caption under MEET PEOPLE.
  ///
  /// In en, this message translates to:
  /// **'Small groups, prompts and plans at your pace.'**
  String get engagementHubSectionMeetCaption;

  /// Engage hub section label (uppercase).
  ///
  /// In en, this message translates to:
  /// **'TRUST & PROGRESS'**
  String get engagementHubSectionProgress;

  /// Engage hub caption under TRUST & PROGRESS.
  ///
  /// In en, this message translates to:
  /// **'Your level, your badges and who can find you.'**
  String get engagementHubSectionProgressCaption;

  /// Voice introduction screen app bar title.
  ///
  /// In en, this message translates to:
  /// **'A voice, a little closer'**
  String get engagementVoiceAppBarTitle;

  /// Voice introduction screen headline; keep the line break.
  ///
  /// In en, this message translates to:
  /// **'Let your hello\nsound like you.'**
  String get engagementVoiceHeadline;

  /// Voice introduction screen intro paragraph.
  ///
  /// In en, this message translates to:
  /// **'An optional 20–45 second introduction, shared only in this conversation. Text is always welcome, too.'**
  String get engagementVoiceIntro;

  /// Voice introduction screen: header naming the conversation partner.
  ///
  /// In en, this message translates to:
  /// **'You and {name}'**
  String engagementVoiceYouAndName(String name);

  /// Voice introduction screen: header when the partner's name is unknown.
  ///
  /// In en, this message translates to:
  /// **'You and your match'**
  String get engagementVoiceYouAndYourMatch;

  /// Voice introduction screen: privacy note under the partner header.
  ///
  /// In en, this message translates to:
  /// **'Private to this conversation'**
  String get engagementVoicePrivate;

  /// Voice introduction screen: the list of conversations failed to load.
  ///
  /// In en, this message translates to:
  /// **'Your conversations couldn’t load.'**
  String get engagementVoiceConversationsLoadFailed;

  /// Voice introduction screen: empty state when there are no matches.
  ///
  /// In en, this message translates to:
  /// **'When you have a match, you can share a voice introduction here. No rush.'**
  String get engagementVoiceNoMatches;

  /// Voice introduction screen: label of the dropdown to choose a match.
  ///
  /// In en, this message translates to:
  /// **'Who would you like to say hello to?'**
  String get engagementVoicePickConversation;

  /// Voice introduction screen: card title above the prompt picker.
  ///
  /// In en, this message translates to:
  /// **'A small starting point'**
  String get engagementVoiceStartingPoint;

  /// Voice introduction screen: label of the prompt dropdown.
  ///
  /// In en, this message translates to:
  /// **'Choose a prompt'**
  String get engagementVoiceChoosePrompt;

  /// Voice introduction screen: label of the written transcript field.
  ///
  /// In en, this message translates to:
  /// **'Your words, in writing'**
  String get engagementVoiceTranscriptLabel;

  /// Voice introduction screen: helper text under the transcript field.
  ///
  /// In en, this message translates to:
  /// **'Write what you say so they can read it, too. This is not automatic transcription.'**
  String get engagementVoiceTranscriptHelper;

  /// Voice introduction screen: record button while recording; seconds elapsed (s = seconds).
  ///
  /// In en, this message translates to:
  /// **'Stop · {seconds}s'**
  String engagementVoiceStop(int seconds);

  /// Voice introduction screen: record button before recording.
  ///
  /// In en, this message translates to:
  /// **'Record your hello'**
  String get engagementVoiceRecord;

  /// Voice introduction screen: record button after a recording exists; length of the current recording (s = seconds).
  ///
  /// In en, this message translates to:
  /// **'Record again · {seconds}s'**
  String engagementVoiceRecordAgain(int seconds);

  /// Voice introduction screen: shown when a recording of valid length is ready.
  ///
  /// In en, this message translates to:
  /// **'Recording ready. Check your transcript before sending.'**
  String get engagementVoiceRecordingReady;

  /// Voice introduction screen: recording was under 20 seconds.
  ///
  /// In en, this message translates to:
  /// **'That was a little short. Record 20–45 seconds.'**
  String get engagementVoiceRecordingShort;

  /// Voice introduction screen: button to discard the recording.
  ///
  /// In en, this message translates to:
  /// **'Discard recording'**
  String get engagementVoiceDiscard;

  /// Voice introduction screen: snackbar after sending.
  ///
  /// In en, this message translates to:
  /// **'Introduction submitted. Approved recordings appear below.'**
  String get engagementVoiceSubmitted;

  /// Voice introduction screen: send button while sending.
  ///
  /// In en, this message translates to:
  /// **'Sending…'**
  String get engagementVoiceSending;

  /// Voice introduction screen: send button.
  ///
  /// In en, this message translates to:
  /// **'Share your hello'**
  String get engagementVoiceShare;

  /// Voice introduction screen: moderation note under the send button.
  ///
  /// In en, this message translates to:
  /// **'Recordings are checked before they are shared. There is no autoplay.'**
  String get engagementVoiceCheckedNote;

  /// Voice introduction screen: heading of the list of shared introductions.
  ///
  /// In en, this message translates to:
  /// **'Your voice introductions'**
  String get engagementVoiceYourIntros;

  /// Voice introduction screen: note under the list heading.
  ///
  /// In en, this message translates to:
  /// **'The latest 20 approved recordings in this conversation. Transcripts are always available to read.'**
  String get engagementVoiceLatestNote;

  /// Voice introduction screen: list failed to load.
  ///
  /// In en, this message translates to:
  /// **'Introductions couldn’t load. The conversation may no longer be available.'**
  String get engagementVoiceIntrosLoadFailed;

  /// Voice introduction screen: empty list.
  ///
  /// In en, this message translates to:
  /// **'Nothing shared yet. A simple hello is a good beginning.'**
  String get engagementVoiceNothingYet;

  /// Voice introduction screen: title of an introduction the member sent.
  ///
  /// In en, this message translates to:
  /// **'Your hello'**
  String get engagementVoiceYourHello;

  /// Voice introduction screen: title of an introduction from the partner.
  ///
  /// In en, this message translates to:
  /// **'A hello from {name}'**
  String engagementVoiceHelloFromName(String name);

  /// Voice introduction screen: title of an introduction from the partner when the name is unknown.
  ///
  /// In en, this message translates to:
  /// **'A hello from your match'**
  String get engagementVoiceHelloFromYourMatch;

  /// Voice introduction screen: uppercase label above a transcript.
  ///
  /// In en, this message translates to:
  /// **'TRANSCRIPT'**
  String get engagementVoiceTranscriptHeading;

  /// Voice introduction screen: stop playing a recording.
  ///
  /// In en, this message translates to:
  /// **'Stop playback'**
  String get engagementVoiceStopPlayback;

  /// Voice introduction screen: play a recording; its length (s = seconds).
  ///
  /// In en, this message translates to:
  /// **'Listen · {seconds}s'**
  String engagementVoiceListen(int seconds);

  /// Voice introduction screen: retry loading prompts.
  ///
  /// In en, this message translates to:
  /// **'Reload prompts'**
  String get engagementVoiceReloadPrompts;

  /// Voice introduction screen: microphone permission missing.
  ///
  /// In en, this message translates to:
  /// **'Allow microphone access to record. You can still read transcripts without it.'**
  String get engagementVoiceMicPermission;

  /// Voice introduction screen: recording could not start.
  ///
  /// In en, this message translates to:
  /// **'Unable to start recording. Check microphone access and try again.'**
  String get engagementVoiceStartFailed;

  /// Voice introduction screen: recording could not be saved.
  ///
  /// In en, this message translates to:
  /// **'The recording could not be saved. Please try again.'**
  String get engagementVoiceSaveFailed;

  /// Voice introduction: fallback error when prompts fail to load.
  ///
  /// In en, this message translates to:
  /// **'Unable to load voice prompts right now.'**
  String get engagementVoicePromptsLoadFailed;

  /// Engagement features: fallback error when there is no signed-in session.
  ///
  /// In en, this message translates to:
  /// **'User session not available.'**
  String get engagementSessionUnavailable;

  /// Voice introduction: validation error, no conversation chosen.
  ///
  /// In en, this message translates to:
  /// **'Choose a conversation first.'**
  String get engagementVoiceChooseConversation;

  /// Voice introduction: validation error, no prompt chosen.
  ///
  /// In en, this message translates to:
  /// **'Please select a voice prompt.'**
  String get engagementVoiceSelectPrompt;

  /// Voice introduction: validation error, transcript empty.
  ///
  /// In en, this message translates to:
  /// **'Please enter a transcript.'**
  String get engagementVoiceEnterTranscript;

  /// Voice introduction: the server did not start a session.
  ///
  /// In en, this message translates to:
  /// **'Unable to create voice icebreaker session.'**
  String get engagementVoiceSessionFailed;

  /// Voice introduction: fallback error when sending fails.
  ///
  /// In en, this message translates to:
  /// **'Unable to send voice icebreaker right now.'**
  String get engagementVoiceSendFailed;

  /// Voice introduction: playback needs a signed-in user.
  ///
  /// In en, this message translates to:
  /// **'User ID is required to mark playback.'**
  String get engagementVoicePlaybackUserRequired;

  /// Voice introduction: fallback error when the server cannot record playback.
  ///
  /// In en, this message translates to:
  /// **'Unable to mark playback right now.'**
  String get engagementVoiceMarkPlaybackFailed;

  /// Voice introduction: a recording could not be played.
  ///
  /// In en, this message translates to:
  /// **'Unable to play this recording right now.'**
  String get engagementVoicePlayFailed;

  /// Match chat: conversation starter suggestion; tapping it puts the text in the composer.
  ///
  /// In en, this message translates to:
  /// **'What made you smile today?'**
  String get chatStarterSmile;

  /// Match chat: conversation starter suggestion; tapping it puts the text in the composer.
  ///
  /// In en, this message translates to:
  /// **'Your ideal Sunday: go.'**
  String get chatStarterSunday;

  /// Match chat: conversation starter suggestion; tapping it puts the text in the composer.
  ///
  /// In en, this message translates to:
  /// **'Coffee, a walk, or a little adventure?'**
  String get chatStarterCoffee;

  /// Match chat: headline of an empty conversation (keeps the line break).
  ///
  /// In en, this message translates to:
  /// **'Every good story\nstarts with a hello.'**
  String get chatWelcomeTitle;

  /// Match chat: empty conversation body while the match is not confirmed yet.
  ///
  /// In en, this message translates to:
  /// **'Your conversation will open when the match is confirmed.'**
  String get chatWelcomePending;

  /// Match chat: empty conversation encouragement.
  ///
  /// In en, this message translates to:
  /// **'No perfect opening line needed. Just be you.'**
  String get chatWelcomeBody;

  /// Match chat: small uppercase label above the conversation starter suggestions.
  ///
  /// In en, this message translates to:
  /// **'A LITTLE INSPIRATION'**
  String get chatInspirationEyebrow;

  /// Match chat (wide layout): sidebar button back to all conversations.
  ///
  /// In en, this message translates to:
  /// **'All conversations'**
  String get chatAllConversations;

  /// Match chat (wide layout): small uppercase sidebar section label.
  ///
  /// In en, this message translates to:
  /// **'MAKE A CONNECTION'**
  String get chatMakeConnectionEyebrow;

  /// Match chat (wide layout): sidebar tip title.
  ///
  /// In en, this message translates to:
  /// **'A little less small talk.'**
  String get chatLessSmallTalk;

  /// Match chat (wide layout): sidebar tip body.
  ///
  /// In en, this message translates to:
  /// **'Ask about the things that make them light up. Share something that feels like you.'**
  String get chatLessSmallTalkBody;

  /// Match chat (wide layout): sidebar button opening the writing helper.
  ///
  /// In en, this message translates to:
  /// **'Find the words'**
  String get chatFindTheWords;

  /// Match chat (wide layout): sidebar button opening the gift tray.
  ///
  /// In en, this message translates to:
  /// **'Send a little joy'**
  String get chatSendJoy;

  /// Match chat (wide layout): sidebar safety card title.
  ///
  /// In en, this message translates to:
  /// **'Your pace. Your space.'**
  String get chatPaceTitle;

  /// Match chat (wide layout): sidebar safety card body.
  ///
  /// In en, this message translates to:
  /// **'Share only what feels comfortable. A good connection respects your boundaries.'**
  String get chatPaceBody;

  /// Match chat: composer placeholder.
  ///
  /// In en, this message translates to:
  /// **'Write a message…'**
  String get chatWriteMessageHint;

  /// Match chat: composer placeholder while sending is not possible.
  ///
  /// In en, this message translates to:
  /// **'Conversation paused'**
  String get chatConversationPaused;

  /// Match chat: send button tooltip while a message is being sent.
  ///
  /// In en, this message translates to:
  /// **'Sending message'**
  String get chatSendingMessageTooltip;

  /// Match chat: send button tooltip.
  ///
  /// In en, this message translates to:
  /// **'Send message'**
  String get chatSendMessageTooltip;

  /// Match chat: tooltip of the button that opens the gift tray.
  ///
  /// In en, this message translates to:
  /// **'Send a gift'**
  String get chatSendGiftTooltip;

  /// Match chat: tooltip of the emoji button.
  ///
  /// In en, this message translates to:
  /// **'Add an emoji'**
  String get chatAddEmojiTooltip;

  /// Match chat: label on the composer button and on a sent message that started as a writing-helper draft.
  ///
  /// In en, this message translates to:
  /// **'Drafted with help'**
  String get chatDraftedWithHelp;

  /// Match chat: writing helper button and sheet title.
  ///
  /// In en, this message translates to:
  /// **'Help me say it'**
  String get chatHelpMeSayIt;

  /// Match chat (web, wide): keyboard hint under the composer.
  ///
  /// In en, this message translates to:
  /// **'Enter to send · Shift + Enter for a new line'**
  String get chatEnterToSendHint;

  /// Chat: date divider for messages sent today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get chatToday;

  /// Chat: date divider for messages sent yesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get chatYesterday;

  /// Match chat: button under a received gift that opens hide/report options.
  ///
  /// In en, this message translates to:
  /// **'Gift options'**
  String get chatGiftOptions;

  /// Match chat: accessibility label of the read receipt on your message.
  ///
  /// In en, this message translates to:
  /// **'Read'**
  String get chatStatusRead;

  /// Match chat: accessibility label of the delivered receipt on your message.
  ///
  /// In en, this message translates to:
  /// **'Delivered'**
  String get chatStatusDelivered;

  /// Match chat: accessibility label of the sent receipt on your message.
  ///
  /// In en, this message translates to:
  /// **'Sent'**
  String get chatStatusSent;

  /// Match chat: heading of a message that combines a gesture with a rose gift.
  ///
  /// In en, this message translates to:
  /// **'Gesture + Rose Gift'**
  String get chatGestureGiftHeading;

  /// Match chat: heading of a gift message.
  ///
  /// In en, this message translates to:
  /// **'A little something for you'**
  String get chatGiftForYouHeading;

  /// Match chat: tone of a gesture gift. {tone} comes from the gift data.
  ///
  /// In en, this message translates to:
  /// **'Tone: {tone}'**
  String chatGiftTone(String tone);

  /// Match chat: price label of a free gift.
  ///
  /// In en, this message translates to:
  /// **'Free gift'**
  String get chatFreeGift;

  /// Writing helper: draft type for a first message.
  ///
  /// In en, this message translates to:
  /// **'Opener'**
  String get chatCopilotKindOpener;

  /// Writing helper: draft type for a reply.
  ///
  /// In en, this message translates to:
  /// **'Reply'**
  String get chatCopilotKindReply;

  /// Writing helper: draft type that suggests a date.
  ///
  /// In en, this message translates to:
  /// **'Date idea'**
  String get chatCopilotKindDateIdea;

  /// Writing helper: tone option.
  ///
  /// In en, this message translates to:
  /// **'Warm'**
  String get chatCopilotToneWarm;

  /// Writing helper: tone option.
  ///
  /// In en, this message translates to:
  /// **'Playful'**
  String get chatCopilotTonePlayful;

  /// Writing helper: tone option.
  ///
  /// In en, this message translates to:
  /// **'Direct'**
  String get chatCopilotToneDirect;

  /// Writing helper: explanation under the title. {name} is the match's name.
  ///
  /// In en, this message translates to:
  /// **'A draft in your voice, from {name}’s profile and your conversation. It is never sent for you, and if you send it as drafted they can see it was written with help.'**
  String chatCopilotIntro(String name);

  /// Writing helper: disclosure text from the server followed by how many drafts are left today.
  ///
  /// In en, this message translates to:
  /// **'{disclosure} {count, plural, =1{1 draft left today.} other{{count} drafts left today.}}'**
  String chatCopilotDisclosure(String disclosure, int count);

  /// Writing helper: button that asks for a draft.
  ///
  /// In en, this message translates to:
  /// **'Draft it'**
  String get chatCopilotDraftIt;

  /// Writing helper: button that asks for a different draft.
  ///
  /// In en, this message translates to:
  /// **'Try another'**
  String get chatCopilotTryAnother;

  /// Writing helper: button that puts the draft into the composer for editing.
  ///
  /// In en, this message translates to:
  /// **'Use and edit'**
  String get chatCopilotUseAndEdit;

  /// Writing helper: error when the server returned no draft.
  ///
  /// In en, this message translates to:
  /// **'The copilot returned nothing.'**
  String get chatCopilotEmpty;

  /// Writing helper: fallback error when the helper cannot be reached.
  ///
  /// In en, this message translates to:
  /// **'The copilot is unavailable.'**
  String get chatCopilotUnavailable;

  /// Match chat: error when the match has ended.
  ///
  /// In en, this message translates to:
  /// **'This match has ended.'**
  String get chatErrorMatchEnded;

  /// Match chat: error when messages could not be loaded.
  ///
  /// In en, this message translates to:
  /// **'Failed to load messages. Please try again.'**
  String get chatErrorLoadMessages;

  /// Match chat: error when the chat is locked until a quest is approved.
  ///
  /// In en, this message translates to:
  /// **'Chat is locked until the quest is approved.'**
  String get chatErrorLockedQuest;

  /// Match chat: error when a message could not be sent.
  ///
  /// In en, this message translates to:
  /// **'Failed to send message.'**
  String get chatErrorSendFailed;

  /// Match chat: error when a message could not be deleted.
  ///
  /// In en, this message translates to:
  /// **'Failed to delete message.'**
  String get chatErrorDeleteFailed;

  /// Match chat: error when the 24-hour delete window has passed.
  ///
  /// In en, this message translates to:
  /// **'Delete window expired (24h).'**
  String get chatErrorDeleteWindowExpired;

  /// Match chat: error when trying to hide/report a gift you sent yourself.
  ///
  /// In en, this message translates to:
  /// **'Only received gifts can be managed.'**
  String get chatErrorOnlyReceivedGifts;

  /// Match chat: error when a gift no longer exists.
  ///
  /// In en, this message translates to:
  /// **'This gift is no longer available.'**
  String get chatErrorGiftGone;

  /// Match chat: error when reporting a gift failed.
  ///
  /// In en, this message translates to:
  /// **'Could not report this gift. Please try again.'**
  String get chatErrorGiftReportFailed;

  /// Match chat: error when hiding a gift failed.
  ///
  /// In en, this message translates to:
  /// **'Could not hide this gift. Please try again.'**
  String get chatErrorGiftHideFailed;

  /// Match chat: error when gifts are switched off.
  ///
  /// In en, this message translates to:
  /// **'Rose gifts are currently unavailable.'**
  String get chatErrorGiftsUnavailable;

  /// Match chat: error when the wallet cannot pay for a gift. {gift} is the gift name.
  ///
  /// In en, this message translates to:
  /// **'Not enough coins to send {gift}.'**
  String chatErrorNotEnoughCoins(String gift);

  /// Match chat: error when the wallet cannot pay for the selected gift.
  ///
  /// In en, this message translates to:
  /// **'Not enough coins to send selected gift.'**
  String get chatErrorNotEnoughCoinsSelected;

  /// Match chat: error when paid gifts are blocked while a refunded purchase is reviewed.
  ///
  /// In en, this message translates to:
  /// **'Your coins are on hold while we review a refunded purchase. Free gifts are still available.'**
  String get chatErrorWalletFrozen;

  /// Match chat: error when too many gifts were sent in a short time.
  ///
  /// In en, this message translates to:
  /// **'You\'ve sent a lot of gifts in a short time. Please try again later.'**
  String get chatErrorGiftVelocity;

  /// Match chat: error when today's free gift was already sent.
  ///
  /// In en, this message translates to:
  /// **'You\'ve sent today\'s free gift. A new one is available after midnight UTC.'**
  String get chatErrorFreeGiftUsed;

  /// Match chat: error when a gift cannot be sent right now. {gift} is the gift name.
  ///
  /// In en, this message translates to:
  /// **'{gift} is not available right now.'**
  String chatErrorGiftNotAvailable(String gift);

  /// Match chat: error when sending a gift outside an active match.
  ///
  /// In en, this message translates to:
  /// **'Gifts can only be sent in an active match.'**
  String get chatErrorGiftNeedsActiveMatch;

  /// Match chat: error when an exclusive gift was already sent today.
  ///
  /// In en, this message translates to:
  /// **'This exclusive gift can only be sent once today.'**
  String get chatErrorExclusiveGiftOnce;

  /// Match chat: error when a gift could not be sent.
  ///
  /// In en, this message translates to:
  /// **'Failed to send gift.'**
  String get chatErrorGiftFailed;

  /// Match chat: error when the signed-in session is missing.
  ///
  /// In en, this message translates to:
  /// **'User session not available.'**
  String get chatErrorSessionUnavailable;

  /// Match chat: error when the conversation is missing.
  ///
  /// In en, this message translates to:
  /// **'Conversation unavailable.'**
  String get chatErrorConversationUnavailable;

  /// ID verification landing: headline.
  ///
  /// In en, this message translates to:
  /// **'Verify with confidence'**
  String get verificationLandingTitle;

  /// ID verification landing: what is uploaded and how it is stored.
  ///
  /// In en, this message translates to:
  /// **'Upload a clear government identity document and a recent selfie. Files are sent as encrypted transport data and stored in a private evidence area.'**
  String get verificationLandingBody;

  /// ID verification landing: limits of what verification means.
  ///
  /// In en, this message translates to:
  /// **'A review signal adds context to your profile. It never guarantees another person’s identity, intentions, or safety.'**
  String get verificationLandingDisclaimer;

  /// ID verification landing: button when already verified.
  ///
  /// In en, this message translates to:
  /// **'View verified status'**
  String get verificationViewVerifiedStatus;

  /// ID verification landing: button when a review is pending.
  ///
  /// In en, this message translates to:
  /// **'View review status'**
  String get verificationViewReviewStatus;

  /// ID verification landing: start button.
  ///
  /// In en, this message translates to:
  /// **'Start secure verification'**
  String get verificationStartButton;

  /// ID verification: app bar title of the ID photo step.
  ///
  /// In en, this message translates to:
  /// **'Upload ID'**
  String get verificationUploadIdTitle;

  /// ID verification: instruction on the ID photo step.
  ///
  /// In en, this message translates to:
  /// **'Take or upload a clear photo of your government ID.'**
  String get verificationUploadIdInstruction;

  /// ID verification: pick a photo from the gallery.
  ///
  /// In en, this message translates to:
  /// **'Gallery'**
  String get verificationGallery;

  /// ID verification: take a photo with the camera.
  ///
  /// In en, this message translates to:
  /// **'Camera'**
  String get verificationCamera;

  /// ID verification: continue to the selfie step.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get verificationNext;

  /// ID verification: app bar title of the selfie step.
  ///
  /// In en, this message translates to:
  /// **'Selfie'**
  String get verificationSelfieTitle;

  /// ID verification: instruction on the selfie step.
  ///
  /// In en, this message translates to:
  /// **'Take a clear selfie.'**
  String get verificationSelfieInstruction;

  /// ID verification: upload of the evidence failed.
  ///
  /// In en, this message translates to:
  /// **'We could not upload your evidence. Check the files and try again.'**
  String get verificationUploadFailed;

  /// ID verification: submit the ID and selfie.
  ///
  /// In en, this message translates to:
  /// **'Submit'**
  String get verificationSubmit;

  /// ID verification status screen: app bar title.
  ///
  /// In en, this message translates to:
  /// **'Verification Status'**
  String get verificationStatusTitle;

  /// ID verification status screen: retry loading.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get verificationRetry;

  /// ID verification status: verified (title).
  ///
  /// In en, this message translates to:
  /// **'Verified'**
  String get verificationStatusVerified;

  /// ID verification status: verified (message).
  ///
  /// In en, this message translates to:
  /// **'Your verification is complete.'**
  String get verificationStatusVerifiedMessage;

  /// ID verification status: rejected (title).
  ///
  /// In en, this message translates to:
  /// **'Rejected'**
  String get verificationStatusRejected;

  /// ID verification status: rejected, when the server gave no reason.
  ///
  /// In en, this message translates to:
  /// **'Please try again.'**
  String get verificationStatusRejectedFallback;

  /// ID verification status: pending (title).
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get verificationStatusPending;

  /// ID verification status: pending (message).
  ///
  /// In en, this message translates to:
  /// **'Review in progress.'**
  String get verificationStatusPendingMessage;

  /// ID verification status: not started (title).
  ///
  /// In en, this message translates to:
  /// **'Not Started'**
  String get verificationStatusNotStarted;

  /// ID verification status: not started (message).
  ///
  /// In en, this message translates to:
  /// **'Start verification from Settings.'**
  String get verificationStatusNotStartedMessage;

  /// SOS screen: app bar title.
  ///
  /// In en, this message translates to:
  /// **'Emergency SOS'**
  String get safetySosTitle;

  /// SOS screen: prefilled message for the safety team (the member can edit it).
  ///
  /// In en, this message translates to:
  /// **'I need immediate assistance. Please check on me.'**
  String get safetySosDefaultMessage;

  /// SOS screen: headline.
  ///
  /// In en, this message translates to:
  /// **'Activate an emergency alert'**
  String get safetySosHeadline;

  /// SOS screen: contact emergency services first.
  ///
  /// In en, this message translates to:
  /// **'If you are in immediate danger, contact local emergency services first. This alert is recorded for the safety team.'**
  String get safetySosIntro;

  /// SOS screen: urgency option (level 'high').
  ///
  /// In en, this message translates to:
  /// **'Urgent'**
  String get safetySosLevelUrgent;

  /// SOS screen: urgency option (level 'critical').
  ///
  /// In en, this message translates to:
  /// **'Critical'**
  String get safetySosLevelCritical;

  /// SOS screen: message field label.
  ///
  /// In en, this message translates to:
  /// **'Message for the safety team'**
  String get safetySosMessageLabel;

  /// SOS screen: button while the alert is being sent.
  ///
  /// In en, this message translates to:
  /// **'Activating…'**
  String get safetySosActivating;

  /// SOS screen: main button.
  ///
  /// In en, this message translates to:
  /// **'Activate SOS'**
  String get safetySosActivate;

  /// SOS screen: location permission note.
  ///
  /// In en, this message translates to:
  /// **'Location is requested only for this alert. You can continue if permission is denied.'**
  String get safetySosLocationNote;

  /// SOS screen: past alerts section title.
  ///
  /// In en, this message translates to:
  /// **'Alert history'**
  String get safetySosHistoryTitle;

  /// SOS screen: no past alerts.
  ///
  /// In en, this message translates to:
  /// **'No SOS alerts recorded.'**
  String get safetySosHistoryEmpty;

  /// SOS history row heading: urgency level and status.
  ///
  /// In en, this message translates to:
  /// **'{level} · {status}'**
  String safetySosHistoryHeading(String level, String status);

  /// SOS history: urgency level, shown in capitals.
  ///
  /// In en, this message translates to:
  /// **'LOW'**
  String get safetySosAlertLevelLow;

  /// SOS history: urgency level, shown in capitals.
  ///
  /// In en, this message translates to:
  /// **'MEDIUM'**
  String get safetySosAlertLevelMedium;

  /// SOS history: urgency level, shown in capitals.
  ///
  /// In en, this message translates to:
  /// **'HIGH'**
  String get safetySosAlertLevelHigh;

  /// SOS history: urgency level, shown in capitals.
  ///
  /// In en, this message translates to:
  /// **'CRITICAL'**
  String get safetySosAlertLevelCritical;

  /// SOS history: alert status, lower case.
  ///
  /// In en, this message translates to:
  /// **'open'**
  String get safetySosAlertStatusOpen;

  /// SOS history: alert status, lower case.
  ///
  /// In en, this message translates to:
  /// **'active'**
  String get safetySosAlertStatusActive;

  /// SOS history: alert status (seen by the safety team), lower case.
  ///
  /// In en, this message translates to:
  /// **'acknowledged'**
  String get safetySosAlertStatusAcknowledged;

  /// SOS history: alert status, lower case.
  ///
  /// In en, this message translates to:
  /// **'resolved'**
  String get safetySosAlertStatusResolved;

  /// SOS history row: date and that a location was attached.
  ///
  /// In en, this message translates to:
  /// **'{date} · location included'**
  String safetySosHistoryMetaWithLocation(String date);

  /// SOS history row: date and that no location was attached.
  ///
  /// In en, this message translates to:
  /// **'{date} · no location'**
  String safetySosHistoryMetaNoLocation(String date);

  /// SOS history row: resolution note written by the safety team.
  ///
  /// In en, this message translates to:
  /// **'Resolution: {note}'**
  String safetySosResolution(String note);

  /// SOS confirmation dialog: title.
  ///
  /// In en, this message translates to:
  /// **'Activate SOS now?'**
  String get safetySosConfirmTitle;

  /// SOS confirmation dialog: what happens.
  ///
  /// In en, this message translates to:
  /// **'This creates an emergency alert for the safety team and attempts to attach your current location.'**
  String get safetySosConfirmBody;

  /// SOS confirmation dialog: cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get safetySosCancel;

  /// SOS confirmation dialog: confirm button.
  ///
  /// In en, this message translates to:
  /// **'Activate'**
  String get safetySosConfirmActivate;

  /// SOS result dialog: title.
  ///
  /// In en, this message translates to:
  /// **'SOS alert activated'**
  String get safetySosActivatedTitle;

  /// SOS result dialog: alert recorded with location.
  ///
  /// In en, this message translates to:
  /// **'Your alert and current location were recorded.'**
  String get safetySosActivatedWithLocation;

  /// SOS result dialog: alert recorded without location.
  ///
  /// In en, this message translates to:
  /// **'Your alert was recorded without location. Location permission was unavailable or declined.'**
  String get safetySosActivatedWithoutLocation;

  /// SOS result dialog: close.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get safetySosDone;

  /// SOS screen: signed out while loading history.
  ///
  /// In en, this message translates to:
  /// **'Please sign in to view SOS history.'**
  String get safetySosSignInToView;

  /// SOS screen: history failed to load.
  ///
  /// In en, this message translates to:
  /// **'Unable to load SOS history.'**
  String get safetySosLoadFailed;

  /// SOS screen: signed out when activating.
  ///
  /// In en, this message translates to:
  /// **'Please sign in before activating SOS.'**
  String get safetySosSignInToActivate;

  /// SOS screen: sending the alert failed.
  ///
  /// In en, this message translates to:
  /// **'Unable to activate SOS.'**
  String get safetySosActivateFailed;

  /// Photo Themes: screen title.
  ///
  /// In en, this message translates to:
  /// **'Photo Themes'**
  String get photoThemesTitle;

  /// Photo Themes: shown when signed out.
  ///
  /// In en, this message translates to:
  /// **'Sign in to see photo themes.'**
  String get photoThemesSignIn;

  /// Photo Themes: hero title.
  ///
  /// In en, this message translates to:
  /// **'Show a little of your world'**
  String get photoThemesHeroTitle;

  /// Photo Themes: hero subtitle.
  ///
  /// In en, this message translates to:
  /// **'Pick a prompt, share one photo, and see how everyone else answered. It is an easy way to start a conversation.'**
  String get photoThemesHeroSubtitle;

  /// Photo Themes: title when themes fail to load.
  ///
  /// In en, this message translates to:
  /// **'Themes could not load'**
  String get photoThemesLoadFailed;

  /// Photo Themes: fallback error message.
  ///
  /// In en, this message translates to:
  /// **'Please check your connection.'**
  String get photoThemesCheckConnection;

  /// Photo Themes: title when the member cannot share yet.
  ///
  /// In en, this message translates to:
  /// **'You can look around'**
  String get photoThemesLookAround;

  /// Photo Themes: fallback eligibility message on the theme list.
  ///
  /// In en, this message translates to:
  /// **'Complete your profile with two approved photos to share your own.'**
  String get photoThemesEligibilityShareOwn;

  /// Photo Themes: empty state title.
  ///
  /// In en, this message translates to:
  /// **'New prompts are on the way'**
  String get photoThemesNewPromptsTitle;

  /// Photo Themes: empty state body.
  ///
  /// In en, this message translates to:
  /// **'Check back soon for something to share.'**
  String get photoThemesNewPromptsBody;

  /// Photo Themes: how many photos were shared for a theme.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{{count} shared} other{{count} shared}}'**
  String photoThemesSharedCount(int count);

  /// Photo Themes: pill/button once the member has shared.
  ///
  /// In en, this message translates to:
  /// **'You shared ✓'**
  String get photoThemesYouShared;

  /// Photo Themes: card call to action when no photos exist.
  ///
  /// In en, this message translates to:
  /// **'Be the first to share →'**
  String get photoThemesBeFirst;

  /// Photo Themes: card call to action.
  ///
  /// In en, this message translates to:
  /// **'See everyone’s photos →'**
  String get photoThemesSeeEveryone;

  /// Photo Themes: snack bar after sharing a photo.
  ///
  /// In en, this message translates to:
  /// **'Your photo is shared. Nice one!'**
  String get photoThemesSharedSnack;

  /// Photo Themes: fallback error when sharing fails.
  ///
  /// In en, this message translates to:
  /// **'Your photo could not be shared. Use a JPEG or PNG up to 10 MB.'**
  String get photoThemesShareFailed;

  /// Photo Themes: fallback eligibility message on a theme gallery.
  ///
  /// In en, this message translates to:
  /// **'Complete your profile with two approved photos to share.'**
  String get photoThemesEligibilityShare;

  /// Photo Themes: why the share button is disabled.
  ///
  /// In en, this message translates to:
  /// **'You have shared for this theme. Remove yours to share a new one.'**
  String get photoThemesAlreadyShared;

  /// Photo Themes: gallery title while the theme loads.
  ///
  /// In en, this message translates to:
  /// **'Photo Theme'**
  String get photoThemesThemeFallback;

  /// Photo Themes: share button tooltip.
  ///
  /// In en, this message translates to:
  /// **'Share a photo for this theme'**
  String get photoThemesShareTooltip;

  /// Photo Themes: share button label.
  ///
  /// In en, this message translates to:
  /// **'Share your photo'**
  String get photoThemesShareYourPhoto;

  /// Photo Themes: empty gallery title when the theme is unknown.
  ///
  /// In en, this message translates to:
  /// **'No photos yet'**
  String get photoThemesNoPhotosYet;

  /// Photo Themes: empty gallery title. {title} is the theme title from the server.
  ///
  /// In en, this message translates to:
  /// **'Be the first to share for “{title}”'**
  String photoThemesBeFirstFor(String title);

  /// Photo Themes: placeholder while the prompt loads.
  ///
  /// In en, this message translates to:
  /// **'Loading the prompt…'**
  String get photoThemesLoadingPrompt;

  /// Photo Themes: title when photos fail to load.
  ///
  /// In en, this message translates to:
  /// **'Photos could not load'**
  String get photoThemesPhotosLoadFailed;

  /// Photo Themes: empty gallery message.
  ///
  /// In en, this message translates to:
  /// **'Your photo could be the one that gets everyone talking.'**
  String get photoThemesEmptyMessage;

  /// Photo Themes: button when loading more photos failed.
  ///
  /// In en, this message translates to:
  /// **'More photos could not load. Reload'**
  String get photoThemesMoreFailed;

  /// Photo Themes: load more button.
  ///
  /// In en, this message translates to:
  /// **'Load more'**
  String get photoThemesLoadMore;

  /// Photo Themes: tooltip on a photo that failed to load.
  ///
  /// In en, this message translates to:
  /// **'Photo unavailable. Retry'**
  String get photoThemesPhotoUnavailable;

  /// Photo Themes: screen reader label for a photo tile. {name} is the member's name.
  ///
  /// In en, this message translates to:
  /// **'Open {name}’s photo'**
  String photoThemesOpenPhoto(String name);

  /// Photo Themes: author label for the member's own photo.
  ///
  /// In en, this message translates to:
  /// **'You'**
  String get photoThemesYou;

  /// Photo Themes: how a photo reaches other members' Today walls.
  ///
  /// In en, this message translates to:
  /// **'If members love it, your photo can reach their Today walls: 50 likes and 5 comments reach 50 walls, 100 likes and 10 comments reach 100. You can turn this off any time.'**
  String get photoThemesWallHelp;

  /// Photo Themes: confirm dialog title.
  ///
  /// In en, this message translates to:
  /// **'Remove your photo?'**
  String get photoThemesRemoveTitle;

  /// Photo Themes: confirm dialog message.
  ///
  /// In en, this message translates to:
  /// **'It disappears from this theme for everyone. You can share a new one afterwards.'**
  String get photoThemesRemoveMessage;

  /// Photo Themes: confirm dialog action.
  ///
  /// In en, this message translates to:
  /// **'Remove photo'**
  String get photoThemesRemoveAction;

  /// Photo Themes: fallback error when removal fails.
  ///
  /// In en, this message translates to:
  /// **'Your photo could not be removed.'**
  String get photoThemesRemoveFailed;

  /// Photo Themes: snack bar after turning wall reach on.
  ///
  /// In en, this message translates to:
  /// **'Your photo can now reach members’ walls when they love it.'**
  String get photoThemesReachOn;

  /// Photo Themes: snack bar after turning wall reach off.
  ///
  /// In en, this message translates to:
  /// **'Your photo is off every wall.'**
  String get photoThemesReachOff;

  /// Photo Themes: byline for the member's own photo.
  ///
  /// In en, this message translates to:
  /// **'Shared by you'**
  String get photoThemesSharedByYou;

  /// Photo Themes: byline. {name} is the member's name.
  ///
  /// In en, this message translates to:
  /// **'Shared by {name}'**
  String photoThemesSharedBy(String name);

  /// Photo Themes: the member-written alt text. {text} is user content.
  ///
  /// In en, this message translates to:
  /// **'Photo description: {text}'**
  String photoThemesPhotoDescription(String text);

  /// Photo Themes: switch title to allow reaching other members' walls.
  ///
  /// In en, this message translates to:
  /// **'Let it reach other members’ walls'**
  String get photoThemesReachSwitch;

  /// Photo Themes: reach card title before the photo is on any wall.
  ///
  /// In en, this message translates to:
  /// **'Members can carry this photo further'**
  String get photoThemesReachIdle;

  /// Photo Themes: reach card caption while the photo is on walls.
  ///
  /// In en, this message translates to:
  /// **'Members are seeing it on their Today walls now.'**
  String get photoThemesReachLive;

  /// Photo Themes: button to remove the member's own photo.
  ///
  /// In en, this message translates to:
  /// **'Remove my photo'**
  String get photoThemesRemoveMine;

  /// Photo Themes: report button.
  ///
  /// In en, this message translates to:
  /// **'Report'**
  String get photoThemesReport;

  /// Photo Themes: block button. {name} is the member's name.
  ///
  /// In en, this message translates to:
  /// **'Block {name}'**
  String photoThemesBlock(String name);

  /// Photo Themes: comment composer hint.
  ///
  /// In en, this message translates to:
  /// **'What does it make you think of?'**
  String get photoThemesCommentHint;

  /// Photo Themes: snack bar after approving a comment.
  ///
  /// In en, this message translates to:
  /// **'Approved. Everyone who can see this photo can see it now.'**
  String get photoThemesCommentApproved;

  /// Photo Themes: dialog title before sharing.
  ///
  /// In en, this message translates to:
  /// **'Tell us about it'**
  String get photoThemesDetailsTitle;

  /// Photo Themes: caption field label.
  ///
  /// In en, this message translates to:
  /// **'Caption'**
  String get photoThemesCaption;

  /// Photo Themes: playful example caption.
  ///
  /// In en, this message translates to:
  /// **'Pancakes, then nowhere to be.'**
  String get photoThemesCaptionHint;

  /// Photo Themes: alt text field label.
  ///
  /// In en, this message translates to:
  /// **'Describe the photo'**
  String get photoThemesDescribe;

  /// Photo Themes: alt text helper.
  ///
  /// In en, this message translates to:
  /// **'Helps members who use a screen reader.'**
  String get photoThemesDescribeHelper;

  /// Photo Themes: dialog share button.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get photoThemesShare;

  /// Today wall: title of the Photo Themes covers rail.
  ///
  /// In en, this message translates to:
  /// **'Covers on your wall'**
  String get photoThemesWallTitle;

  /// Today wall: caption of the Photo Themes covers rail.
  ///
  /// In en, this message translates to:
  /// **'Photos other members loved'**
  String get photoThemesWallCaption;

  /// Photo cover: all-caps masthead when the theme title is missing.
  ///
  /// In en, this message translates to:
  /// **'PHOTO THEMES'**
  String get photoThemesMasthead;

  /// Photo cover: all-caps byline. {name} is the member's first name, already upper-cased.
  ///
  /// In en, this message translates to:
  /// **'BY {name}'**
  String photoThemesByline(String name);

  /// Photo cover: screen reader label for the like count icon.
  ///
  /// In en, this message translates to:
  /// **'Likes'**
  String get photoThemesLikes;

  /// Photo cover: screen reader label for the comment count icon.
  ///
  /// In en, this message translates to:
  /// **'Comments'**
  String get photoThemesComments;

  /// Photo Themes: dialog cancel button.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get photoThemesCancel;

  /// Photo Themes: retry button.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get photoThemesTryAgain;

  /// Photo Themes: fallback error when a setting does not save.
  ///
  /// In en, this message translates to:
  /// **'That didn’t save. Please try again.'**
  String get photoThemesSaveFailed;

  /// Friend chat: shown in an empty conversation with a friend.
  ///
  /// In en, this message translates to:
  /// **'Say hello. Only the two of you can see this conversation.'**
  String get friendsChatEmpty;

  /// Friends: snackbar when the friend chat could not be opened.
  ///
  /// In en, this message translates to:
  /// **'Could not open the chat. Retry.'**
  String get friendsChatOpenFailed;

  /// Add friend button: confirm dialog title for cancelling my sent friend request.
  ///
  /// In en, this message translates to:
  /// **'Cancel your friend request?'**
  String get friendsCancelRequestTitle;

  /// Add friend button: confirm dialog body for cancelling a friend request to a named member.
  ///
  /// In en, this message translates to:
  /// **'{name} won’t see your request any more.'**
  String friendsCancelRequestBody(String name);

  /// Add friend button: confirm dialog body for cancelling a friend request when the member's name is unknown. (The English starts in lower case on purpose; it matches the existing UI text.)
  ///
  /// In en, this message translates to:
  /// **'this member won’t see your request any more.'**
  String get friendsCancelRequestBodyUnnamed;

  /// Add friend button: keep my sent friend request.
  ///
  /// In en, this message translates to:
  /// **'Keep it'**
  String get friendsKeepIt;

  /// Add friend button: confirm cancelling my sent friend request.
  ///
  /// In en, this message translates to:
  /// **'Cancel request'**
  String get friendsCancelRequest;

  /// Add friend button: snackbar when we became friends.
  ///
  /// In en, this message translates to:
  /// **'You and {name} are now friends.'**
  String friendsNowFriends(String name);

  /// Add friend button: snackbar when we became friends and the member's name is unknown.
  ///
  /// In en, this message translates to:
  /// **'You and this member are now friends.'**
  String get friendsNowFriendsUnnamed;

  /// Add friend button: snackbar after sending a friend request.
  ///
  /// In en, this message translates to:
  /// **'Friend request sent to {name}.'**
  String friendsRequestSentTo(String name);

  /// Add friend button: snackbar after sending a friend request when the member's name is unknown.
  ///
  /// In en, this message translates to:
  /// **'Friend request sent to this member.'**
  String get friendsRequestSentToUnnamed;

  /// Add friend button: snackbar after cancelling my friend request.
  ///
  /// In en, this message translates to:
  /// **'Request cancelled.'**
  String get friendsRequestCancelled;

  /// Add friend button: snackbar when the friend request could not be sent and the server gave no reason.
  ///
  /// In en, this message translates to:
  /// **'Could not send the request.'**
  String get friendsRequestFailed;

  /// Add friend tile: caption under Add friend.
  ///
  /// In en, this message translates to:
  /// **'Friends can message and plan things together'**
  String get friendsAddCaption;

  /// Add friend button: label once my request is pending.
  ///
  /// In en, this message translates to:
  /// **'Requested'**
  String get friendsRequested;

  /// Add friend tile: caption while my request to a named member is pending.
  ///
  /// In en, this message translates to:
  /// **'Waiting for {name}. Tap to cancel.'**
  String friendsWaitingFor(String name);

  /// Add friend tile: caption while my request is pending and the member's name is unknown.
  ///
  /// In en, this message translates to:
  /// **'Waiting for this member. Tap to cancel.'**
  String get friendsWaitingForUnnamed;

  /// Add friend button: accept the member's friend request.
  ///
  /// In en, this message translates to:
  /// **'Accept friend'**
  String get friendsAcceptFriend;

  /// Add friend tile: caption when a named member asked me to be friends.
  ///
  /// In en, this message translates to:
  /// **'{name} asked to be friends'**
  String friendsAskedToBeFriends(String name);

  /// Add friend tile: caption when a member whose name is unknown asked me to be friends. (The English starts in lower case on purpose; it matches the existing UI text.)
  ///
  /// In en, this message translates to:
  /// **'this member asked to be friends'**
  String get friendsAskedToBeFriendsUnnamed;

  /// Add friend button: label once we are friends; opens our chat.
  ///
  /// In en, this message translates to:
  /// **'Message'**
  String get friendsMessage;

  /// Add friend tile: caption once we are friends.
  ///
  /// In en, this message translates to:
  /// **'You’re friends. Open your chat.'**
  String get friendsYoureFriends;

  /// Vouch sheet: validation error when the vouch is too short.
  ///
  /// In en, this message translates to:
  /// **'Say a little more (at least {min} characters).'**
  String friendsVouchTooShort(int min);

  /// Vouch sheet: title.
  ///
  /// In en, this message translates to:
  /// **'Vouch for {name}'**
  String friendsVouchTitle(String name);

  /// Vouch sheet: explanation under the title.
  ///
  /// In en, this message translates to:
  /// **'A sentence or two about why someone would be lucky to meet them. They approve it before it shows on their profile, with your first name.'**
  String get friendsVouchBody;

  /// Vouch sheet: text field label.
  ///
  /// In en, this message translates to:
  /// **'Your vouch'**
  String get friendsVouchLabel;

  /// Vouch sheet: example text in the vouch field.
  ///
  /// In en, this message translates to:
  /// **'Kind, funny, and always shows up on time.'**
  String get friendsVouchHint;

  /// Vouch sheet: submit button.
  ///
  /// In en, this message translates to:
  /// **'Send vouch'**
  String get friendsVouchSend;

  /// Intro sheet: validation error when two different friends are not chosen.
  ///
  /// In en, this message translates to:
  /// **'Choose two different friends.'**
  String get friendsIntroChooseTwo;

  /// Intro sheet: title.
  ///
  /// In en, this message translates to:
  /// **'Introduce two friends'**
  String get friendsIntroSheetTitle;

  /// Intro sheet: explanation of how friend introductions work.
  ///
  /// In en, this message translates to:
  /// **'Both friends must allow introductions. Each controls their preview and decides privately. Share only a reason you have permission to mention. Their decisions and match outcome stay private.'**
  String get friendsIntroSheetBody;

  /// Intro sheet: shown when I have fewer than two accepted friends.
  ///
  /// In en, this message translates to:
  /// **'You need at least two accepted friends to make an intro.'**
  String get friendsIntroNeedTwo;

  /// Friend introductions: label of the first friend picker.
  ///
  /// In en, this message translates to:
  /// **'First friend'**
  String get friendsFirstFriend;

  /// Friend introductions: label of the second friend picker.
  ///
  /// In en, this message translates to:
  /// **'Second friend'**
  String get friendsSecondFriend;

  /// Intro sheet: optional message field label.
  ///
  /// In en, this message translates to:
  /// **'Why they should meet (optional)'**
  String get friendsIntroWhyLabel;

  /// Intro sheet: submit button.
  ///
  /// In en, this message translates to:
  /// **'Make the intro'**
  String get friendsIntroSubmit;

  /// Friends: error when friends could not be loaded and the server gave no reason.
  ///
  /// In en, this message translates to:
  /// **'Failed to load friends. Please try again.'**
  String get friendsLoadFailed;

  /// Friends: error when adding a friend failed and the server gave no reason.
  ///
  /// In en, this message translates to:
  /// **'Failed to add friend.'**
  String get friendsAddFailed;

  /// Friends: error when removing a friend failed and the server gave no reason.
  ///
  /// In en, this message translates to:
  /// **'Failed to remove friend.'**
  String get friendsRemoveFailed;

  /// Friends: error when answering a friend request failed and the server gave no reason.
  ///
  /// In en, this message translates to:
  /// **'Failed to respond to friend request.'**
  String get friendsRespondFailed;

  /// Friends: error when vouches and intros could not be loaded and the server gave no reason.
  ///
  /// In en, this message translates to:
  /// **'Unable to load vouches and intros.'**
  String get friendsSocialLoadFailed;

  /// Friends: error when a vouch could not be sent and the server gave no reason.
  ///
  /// In en, this message translates to:
  /// **'Unable to send this vouch.'**
  String get friendsVouchSendFailed;

  /// Friends: error when approving or hiding a vouch failed and the server gave no reason.
  ///
  /// In en, this message translates to:
  /// **'Unable to update this vouch.'**
  String get friendsVouchUpdateFailed;

  /// Friends: error when withdrawing a vouch failed and the server gave no reason.
  ///
  /// In en, this message translates to:
  /// **'Unable to withdraw this vouch.'**
  String get friendsVouchWithdrawFailed;

  /// Friends: error when an introduction could not be made and the server gave no reason.
  ///
  /// In en, this message translates to:
  /// **'Unable to make this intro.'**
  String get friendsIntroMakeFailed;

  /// Friends: error when answering an introduction failed and the server gave no reason.
  ///
  /// In en, this message translates to:
  /// **'Unable to answer this intro.'**
  String get friendsIntroAnswerFailed;

  /// Groups home: eyebrow above the page title.
  ///
  /// In en, this message translates to:
  /// **'GROUPS'**
  String get groupsEyebrow;

  /// Groups home: page title.
  ///
  /// In en, this message translates to:
  /// **'Find your people.'**
  String get groupsTitle;

  /// Groups home: subtitle under the page title.
  ///
  /// In en, this message translates to:
  /// **'Lifestyle communities anyone can join, and private groups just for your friends.'**
  String get groupsSubtitle;

  /// Groups: button and create-screen title to start a new group.
  ///
  /// In en, this message translates to:
  /// **'Start a group'**
  String get groupsStartGroup;

  /// Groups home: section header (uppercase) for pending group invitations.
  ///
  /// In en, this message translates to:
  /// **'INVITATIONS'**
  String get groupsInvitationsHeader;

  /// Groups home: caption under the invitations header.
  ///
  /// In en, this message translates to:
  /// **'Friends asked you to join.'**
  String get groupsInvitationsCaption;

  /// Groups: snackbar fallback when accepting/declining an invitation fails.
  ///
  /// In en, this message translates to:
  /// **'Your answer could not be saved.'**
  String get groupsAnswerFailed;

  /// Groups: snackbar after joining a group. {name} is the group name.
  ///
  /// In en, this message translates to:
  /// **'Welcome to {name}!'**
  String groupsWelcome(String name);

  /// Groups: snackbar after declining a group invitation.
  ///
  /// In en, this message translates to:
  /// **'Invitation declined.'**
  String get groupsInvitationDeclined;

  /// Groups home: section header (uppercase) for the member's groups.
  ///
  /// In en, this message translates to:
  /// **'YOUR GROUPS'**
  String get groupsYourGroupsHeader;

  /// Groups home: error title when the member's groups fail to load.
  ///
  /// In en, this message translates to:
  /// **'Your groups could not load'**
  String get groupsYourGroupsFailed;

  /// Groups home: error message fallback when a list fails to load.
  ///
  /// In en, this message translates to:
  /// **'Please check your connection.'**
  String get groupsErrorCheckConnection;

  /// Groups home: empty state title when the member has no groups.
  ///
  /// In en, this message translates to:
  /// **'No groups yet'**
  String get groupsEmptyTitle;

  /// Groups home: empty state message when the member has no groups.
  ///
  /// In en, this message translates to:
  /// **'Join a community below, or start a private group with your friends.'**
  String get groupsEmptyBody;

  /// Groups home: section header (uppercase) for discovering community groups by lifestyle category.
  ///
  /// In en, this message translates to:
  /// **'DISCOVER BY LIFESTYLE'**
  String get groupsDiscoverHeader;

  /// Groups home: caption under the discover header.
  ///
  /// In en, this message translates to:
  /// **'Community groups are open to everyone.'**
  String get groupsDiscoverCaption;

  /// Groups: error title when lifestyle categories fail to load.
  ///
  /// In en, this message translates to:
  /// **'Lifestyles could not load'**
  String get groupsLifestylesFailed;

  /// Groups home: filter chip showing every lifestyle category.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get groupsCategoryAll;

  /// Groups home: error title when community groups fail to load.
  ///
  /// In en, this message translates to:
  /// **'Groups could not load'**
  String get groupsDiscoverFailed;

  /// Groups home: empty state title when there are no community groups to join.
  ///
  /// In en, this message translates to:
  /// **'Nothing new to join'**
  String get groupsDiscoverEmptyTitle;

  /// Groups home: empty state title for a selected lifestyle category. {category} is the emoji and category title, e.g. '📚 Books'.
  ///
  /// In en, this message translates to:
  /// **'No {category} groups yet'**
  String groupsDiscoverEmptyCategoryTitle(String category);

  /// Groups home: empty state message inviting the member to start a community group.
  ///
  /// In en, this message translates to:
  /// **'Be the first: start a community group and invite your friends.'**
  String get groupsDiscoverEmptyBody;

  /// Groups home: empty state button to start a community group.
  ///
  /// In en, this message translates to:
  /// **'Start one'**
  String get groupsStartOne;

  /// Groups: snackbar fallback when joining a group fails.
  ///
  /// In en, this message translates to:
  /// **'You could not join just now.'**
  String get groupsJoinFailed;

  /// Groups: short button to join a group (on a card or invitation).
  ///
  /// In en, this message translates to:
  /// **'Join'**
  String get groupsJoin;

  /// Groups: screen-reader label of the Join button. {name} is the group name.
  ///
  /// In en, this message translates to:
  /// **'Join {name}'**
  String groupsJoinNamed(String name);

  /// Groups home: invitation card line. {name} is the friend who invited, {kind} the group kind ('Community group'), {members} the member count ('12 members').
  ///
  /// In en, this message translates to:
  /// **'{name} invited you · {kind} · {members}'**
  String groupsInvitedBy(String name, String kind, String members);

  /// Groups home: invitation card line when the inviter has no name. {kind} is the group kind, {members} the member count.
  ///
  /// In en, this message translates to:
  /// **'A friend invited you · {kind} · {members}'**
  String groupsInvitedByFriend(String kind, String members);

  /// Groups: button to decline a group invitation.
  ///
  /// In en, this message translates to:
  /// **'Decline'**
  String get groupsDecline;

  /// Groups: screen-reader label of the Decline button. {name} is the group name.
  ///
  /// In en, this message translates to:
  /// **'Decline {name}'**
  String groupsDeclineNamed(String name);

  /// Group chat: empty state text. {name} is the group name.
  ///
  /// In en, this message translates to:
  /// **'Say hello to the group. Everyone in {name} can see messages here.'**
  String groupsChatEmpty(String name);

  /// Group detail: friend picker title. {name} is the group name.
  ///
  /// In en, this message translates to:
  /// **'Invite friends to {name}'**
  String groupsInviteFriendsTo(String name);

  /// Group detail: friend picker confirm button.
  ///
  /// In en, this message translates to:
  /// **'Send invitations'**
  String get groupsSendInvitations;

  /// Group detail: snackbar fallback when invitations fail.
  ///
  /// In en, this message translates to:
  /// **'Invitations could not be sent.'**
  String get groupsInvitationsFailed;

  /// Group detail: snackbar after inviting one friend. {name} is the friend's name.
  ///
  /// In en, this message translates to:
  /// **'Invitation sent to {name}.'**
  String groupsInvitationSentTo(String name);

  /// Group detail: snackbar after inviting several friends.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 invitation sent.} other{{count} invitations sent.}}'**
  String groupsInvitationsSent(int count);

  /// Group detail: leave confirmation title. {name} is the group name.
  ///
  /// In en, this message translates to:
  /// **'Leave {name}?'**
  String groupsLeaveTitle(String name);

  /// Group detail: leave confirmation when the owner is the only member.
  ///
  /// In en, this message translates to:
  /// **'You are the only member, so the group and its chat will be deleted.'**
  String get groupsLeaveBodyAlone;

  /// Group detail: leave confirmation for the owner when others remain.
  ///
  /// In en, this message translates to:
  /// **'Ownership passes to your longest-standing moderator, or else member. You will lose access to the chat.'**
  String get groupsLeaveBodyOwner;

  /// Group detail: leave confirmation for a community group member.
  ///
  /// In en, this message translates to:
  /// **'You will lose access to the group chat. You can join again later.'**
  String get groupsLeaveBodyCommunity;

  /// Group detail: leave confirmation for a private group member.
  ///
  /// In en, this message translates to:
  /// **'You will lose access to the group chat. You will need a new invitation to come back.'**
  String get groupsLeaveBodyPrivate;

  /// Group detail: button and confirm action to leave a group.
  ///
  /// In en, this message translates to:
  /// **'Leave'**
  String get groupsLeave;

  /// Group detail: snackbar fallback when leaving fails.
  ///
  /// In en, this message translates to:
  /// **'You could not leave just now.'**
  String get groupsLeaveFailed;

  /// Group detail: snackbar fallback when uploading a cover photo fails.
  ///
  /// In en, this message translates to:
  /// **'Your cover photo could not be uploaded. Use a JPEG or PNG up to 10 MB.'**
  String get groupsCoverUploadFailed;

  /// Group detail: confirmation title for removing the cover photo.
  ///
  /// In en, this message translates to:
  /// **'Remove the cover photo?'**
  String get groupsRemoveCoverTitle;

  /// Group detail: confirmation message for removing the cover photo. {name} is the group name.
  ///
  /// In en, this message translates to:
  /// **'{name} will show its emoji cover again.'**
  String groupsRemoveCoverBody(String name);

  /// Groups: confirm action to remove a cover photo or a member.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get groupsRemove;

  /// Group detail: snackbar fallback when removing the cover photo fails.
  ///
  /// In en, this message translates to:
  /// **'The cover photo could not be removed.'**
  String get groupsRemoveCoverFailed;

  /// Group detail: snackbar after the cover photo is removed.
  ///
  /// In en, this message translates to:
  /// **'Cover photo removed.'**
  String get groupsCoverRemoved;

  /// Group detail: delete confirmation title. {name} is the group name.
  ///
  /// In en, this message translates to:
  /// **'Delete {name}?'**
  String groupsDeleteTitle(String name);

  /// Group detail: delete confirmation message.
  ///
  /// In en, this message translates to:
  /// **'The group, its invitations and its chat are removed for everyone. This cannot be undone.'**
  String get groupsDeleteBody;

  /// Group detail: owner menu item and confirm action to delete the group.
  ///
  /// In en, this message translates to:
  /// **'Delete group'**
  String get groupsDeleteGroup;

  /// Group detail: snackbar fallback when deleting the group fails.
  ///
  /// In en, this message translates to:
  /// **'The group could not be deleted.'**
  String get groupsDeleteFailed;

  /// Group detail: eyebrow (uppercase) while the group loads.
  ///
  /// In en, this message translates to:
  /// **'GROUP'**
  String get groupsDetailEyebrow;

  /// Group detail: page title while the group loads.
  ///
  /// In en, this message translates to:
  /// **'Group'**
  String get groupsDetailTitleFallback;

  /// Group detail: tooltip of the owner's menu button.
  ///
  /// In en, this message translates to:
  /// **'Owner tools'**
  String get groupsOwnerTools;

  /// Group detail: owner menu item and sheet title to edit the group.
  ///
  /// In en, this message translates to:
  /// **'Edit group'**
  String get groupsEditGroup;

  /// Group detail: owner menu item and button to add a cover photo.
  ///
  /// In en, this message translates to:
  /// **'Add cover photo'**
  String get groupsAddCoverPhoto;

  /// Group detail: owner menu item to change the cover photo.
  ///
  /// In en, this message translates to:
  /// **'Change cover photo'**
  String get groupsChangeCoverPhoto;

  /// Group detail: owner menu item to remove the cover photo.
  ///
  /// In en, this message translates to:
  /// **'Remove cover photo'**
  String get groupsRemoveCoverPhoto;

  /// Group detail: tooltip of the non-owner menu button.
  ///
  /// In en, this message translates to:
  /// **'More options'**
  String get groupsMoreOptions;

  /// Group detail: menu item to report the group.
  ///
  /// In en, this message translates to:
  /// **'Report group'**
  String get groupsReportGroup;

  /// Group detail: error title when the group cannot load.
  ///
  /// In en, this message translates to:
  /// **'This group is unavailable'**
  String get groupsUnavailableTitle;

  /// Group detail: error message fallback when the group cannot load.
  ///
  /// In en, this message translates to:
  /// **'It may have been deleted, or you may no longer have access.'**
  String get groupsUnavailableBody;

  /// Group detail: pill for a community group anyone can join.
  ///
  /// In en, this message translates to:
  /// **'Open to all'**
  String get groupsOpenToAll;

  /// Group detail: pill for a private group.
  ///
  /// In en, this message translates to:
  /// **'Private'**
  String get groupsPrivate;

  /// Group detail: pill when the member owns the group.
  ///
  /// In en, this message translates to:
  /// **'You run it'**
  String get groupsYouRunIt;

  /// Group detail: pill when the member moderates the group.
  ///
  /// In en, this message translates to:
  /// **'You moderate'**
  String get groupsYouModerate;

  /// Group detail: note for the owner while their cover photo is under review.
  ///
  /// In en, this message translates to:
  /// **'Only you can see this photo until it’s approved. Members see the emoji cover meanwhile.'**
  String get groupsCoverNotePending;

  /// Group detail: note for the owner when their last cover photo was rejected.
  ///
  /// In en, this message translates to:
  /// **'Your last cover photo wasn’t approved. Choose a different one.'**
  String get groupsCoverNoteRejected;

  /// Group detail: badge on a cover photo waiting for review.
  ///
  /// In en, this message translates to:
  /// **'Under review'**
  String get groupsCoverUnderReview;

  /// Group detail: button to change the cover photo.
  ///
  /// In en, this message translates to:
  /// **'Change cover'**
  String get groupsChangeCover;

  /// Group detail: button to remove the cover photo.
  ///
  /// In en, this message translates to:
  /// **'Remove cover'**
  String get groupsRemoveCover;

  /// Group detail: notice title when the group was removed by the trust team.
  ///
  /// In en, this message translates to:
  /// **'This group was removed after a review'**
  String get groupsRemovedTitle;

  /// Group detail: removed-group notice for the owner.
  ///
  /// In en, this message translates to:
  /// **'Members can’t chat, join or invite while it is removed. Your review notices explain the decision and let you appeal.'**
  String get groupsRemovedBodyOwner;

  /// Group detail: removed-group notice for members.
  ///
  /// In en, this message translates to:
  /// **'Members can’t chat, join or invite while it is removed. You can leave the group at any time.'**
  String get groupsRemovedBodyMember;

  /// Group detail: button and sheet title listing the group's members.
  ///
  /// In en, this message translates to:
  /// **'Members'**
  String get groupsMembers;

  /// Group detail: button to open the group chat.
  ///
  /// In en, this message translates to:
  /// **'Group chat'**
  String get groupsChatButton;

  /// Group detail: group chat button with the number of unread messages.
  ///
  /// In en, this message translates to:
  /// **'Group chat · {count} new'**
  String groupsChatButtonUnread(int count);

  /// Groups: button to invite friends (and picker title when creating a group).
  ///
  /// In en, this message translates to:
  /// **'Invite friends'**
  String get groupsInviteFriends;

  /// Group detail: section header (uppercase) above the member preview.
  ///
  /// In en, this message translates to:
  /// **'WHO’S HERE'**
  String get groupsWhosHere;

  /// Group detail: button to see every member.
  ///
  /// In en, this message translates to:
  /// **'See all'**
  String get groupsSeeAll;

  /// Group detail: label for the member themselves in the member preview.
  ///
  /// In en, this message translates to:
  /// **'You'**
  String get groupsYou;

  /// Group detail: invitation panel title. {name} is the group name.
  ///
  /// In en, this message translates to:
  /// **'You’re invited to join {name}.'**
  String groupsInvitedToJoin(String name);

  /// Group detail: button to join the group.
  ///
  /// In en, this message translates to:
  /// **'Join group'**
  String get groupsJoinGroup;

  /// Group detail: hint under the Join group button.
  ///
  /// In en, this message translates to:
  /// **'Members see who’s here and chat together.'**
  String get groupsJoinHint;

  /// Group detail: notice title when a community group cannot be joined.
  ///
  /// In en, this message translates to:
  /// **'You can’t join this group'**
  String get groupsCantJoinTitle;

  /// Group detail: notice message when a community group cannot be joined.
  ///
  /// In en, this message translates to:
  /// **'It may be full, or a moderator removed you.'**
  String get groupsCantJoinBody;

  /// Group detail: notice title for a private group without an invitation.
  ///
  /// In en, this message translates to:
  /// **'Invitation only'**
  String get groupsInvitationOnly;

  /// Group detail: notice message for a private group without an invitation.
  ///
  /// In en, this message translates to:
  /// **'A member can invite you to this private group.'**
  String get groupsInvitationOnlyBody;

  /// Group members sheet: owner action to promote a member.
  ///
  /// In en, this message translates to:
  /// **'Make moderator'**
  String get groupsMakeModerator;

  /// Group members sheet: owner action to demote a moderator.
  ///
  /// In en, this message translates to:
  /// **'Make member'**
  String get groupsMakeMember;

  /// Group members sheet: action to remove a member.
  ///
  /// In en, this message translates to:
  /// **'Remove from group'**
  String get groupsRemoveFromGroup;

  /// Group members sheet: confirmation title. {name} is the member's name.
  ///
  /// In en, this message translates to:
  /// **'Remove {name}?'**
  String groupsRemoveMemberTitle(String name);

  /// Group members sheet: confirmation message when removing someone from a community group.
  ///
  /// In en, this message translates to:
  /// **'They leave the group and its chat, and cannot rejoin by themselves.'**
  String get groupsRemoveMemberBodyCommunity;

  /// Group members sheet: confirmation message when removing someone from a private group.
  ///
  /// In en, this message translates to:
  /// **'They leave the group and its chat.'**
  String get groupsRemoveMemberBodyPrivate;

  /// Group members sheet: snackbar fallback when a role change fails.
  ///
  /// In en, this message translates to:
  /// **'That change could not be saved.'**
  String get groupsChangeFailed;

  /// Group members sheet: error title when members fail to load.
  ///
  /// In en, this message translates to:
  /// **'Members could not load'**
  String get groupsMembersFailed;

  /// Groups: generic error message fallback.
  ///
  /// In en, this message translates to:
  /// **'Please try again.'**
  String get groupsPleaseTryAgain;

  /// Group members sheet: the member's own row. {name} is their name.
  ///
  /// In en, this message translates to:
  /// **'{name} (you)'**
  String groupsMemberYou(String name);

  /// Groups: role label for the group owner.
  ///
  /// In en, this message translates to:
  /// **'Owner'**
  String get groupsRoleOwner;

  /// Groups: role label for a group moderator.
  ///
  /// In en, this message translates to:
  /// **'Moderator'**
  String get groupsRoleModerator;

  /// Groups: role label for a plain group member.
  ///
  /// In en, this message translates to:
  /// **'Member'**
  String get groupsRoleMember;

  /// Group members sheet: tooltip of a member's menu. {name} is the member's name.
  ///
  /// In en, this message translates to:
  /// **'Options for {name}'**
  String groupsMemberOptions(String name);

  /// Edit group sheet: error fallback when saving fails.
  ///
  /// In en, this message translates to:
  /// **'Your changes could not be saved.'**
  String get groupsEditFailed;

  /// Edit group sheet: save button while saving.
  ///
  /// In en, this message translates to:
  /// **'Saving…'**
  String get groupsSaving;

  /// Edit group sheet: save button.
  ///
  /// In en, this message translates to:
  /// **'Save changes'**
  String get groupsSaveChanges;

  /// Groups: label of the group name field.
  ///
  /// In en, this message translates to:
  /// **'Group name'**
  String get groupsNameLabel;

  /// Edit group sheet: label of the description field.
  ///
  /// In en, this message translates to:
  /// **'What is it about?'**
  String get groupsAboutLabel;

  /// Create group: label of the optional description field.
  ///
  /// In en, this message translates to:
  /// **'What is it about? (optional)'**
  String get groupsAboutOptionalLabel;

  /// Groups: label of the optional city field.
  ///
  /// In en, this message translates to:
  /// **'City (optional)'**
  String get groupsCityLabel;

  /// Groups: cover colour choice using the theme's primary colour.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get groupsCoverColorTheme;

  /// Groups: cover colour choice using the theme's accent colour.
  ///
  /// In en, this message translates to:
  /// **'Accent'**
  String get groupsCoverColorAccent;

  /// Groups: cover colour choice using the theme's warm colour.
  ///
  /// In en, this message translates to:
  /// **'Warm'**
  String get groupsCoverColorWarm;

  /// Edit group sheet: heading above the lifestyle category chips.
  ///
  /// In en, this message translates to:
  /// **'Lifestyle'**
  String get groupsLifestyleLabel;

  /// Create group: snackbar fallback when the cover upload fails after the group was created.
  ///
  /// In en, this message translates to:
  /// **'Your group is ready, but the cover photo could not be uploaded. Try again from the group.'**
  String get groupsCreateCoverUploadFailed;

  /// Create group: validation error when no lifestyle is chosen for a community group.
  ///
  /// In en, this message translates to:
  /// **'Pick a lifestyle for your community group.'**
  String get groupsCreatePickLifestyle;

  /// Create group: validation error when the name is shorter than 3 characters.
  ///
  /// In en, this message translates to:
  /// **'Give your group a name of at least 3 letters.'**
  String get groupsCreateNameTooShort;

  /// Create group: error fallback when creating fails.
  ///
  /// In en, this message translates to:
  /// **'Your group could not be created. Please try again.'**
  String get groupsCreateFailed;

  /// Create group: eyebrow (uppercase) above the title.
  ///
  /// In en, this message translates to:
  /// **'NEW GROUP'**
  String get groupsCreateEyebrow;

  /// Create group: subtitle without preselected friends.
  ///
  /// In en, this message translates to:
  /// **'Bring people together around what you love.'**
  String get groupsCreateSubtitle;

  /// Create group: subtitle when friends are preselected.
  ///
  /// In en, this message translates to:
  /// **'Turn your friends into a group.'**
  String get groupsCreateSubtitleFriends;

  /// Create group: section header (uppercase) for the group kind.
  ///
  /// In en, this message translates to:
  /// **'WHAT KIND'**
  String get groupsCreateKindHeader;

  /// Groups: kind label for a public community group.
  ///
  /// In en, this message translates to:
  /// **'Community group'**
  String get groupsKindCommunity;

  /// Groups: kind label for a private friends group.
  ///
  /// In en, this message translates to:
  /// **'Private group'**
  String get groupsKindPrivate;

  /// Create group: description of the community group option.
  ///
  /// In en, this message translates to:
  /// **'By lifestyle. Anyone can find and join it.'**
  String get groupsCreateCommunitySubtitle;

  /// Create group: description of the private group option.
  ///
  /// In en, this message translates to:
  /// **'Just friends. Only people you invite can join.'**
  String get groupsCreatePrivateSubtitle;

  /// Create group: section header (uppercase) for the lifestyle category.
  ///
  /// In en, this message translates to:
  /// **'LIFESTYLE'**
  String get groupsCreateLifestyleHeader;

  /// Create group: caption under the lifestyle header.
  ///
  /// In en, this message translates to:
  /// **'Where people will discover your group.'**
  String get groupsCreateLifestyleCaption;

  /// Create group: section header (uppercase) for name, description and city.
  ///
  /// In en, this message translates to:
  /// **'DETAILS'**
  String get groupsCreateDetailsHeader;

  /// Create group: example name for a community group (Indiranagar is a neighbourhood in Bengaluru).
  ///
  /// In en, this message translates to:
  /// **'Sunrise runners of Indiranagar'**
  String get groupsCreateNameHintCommunity;

  /// Create group: example name for a private friends group.
  ///
  /// In en, this message translates to:
  /// **'The Sunday brunch crew'**
  String get groupsCreateNameHintPrivate;

  /// Create group: section header (uppercase) for the cover.
  ///
  /// In en, this message translates to:
  /// **'COVER'**
  String get groupsCreateCoverHeader;

  /// Create group: screen-reader label of a cover emoji choice. {emoji} is the emoji.
  ///
  /// In en, this message translates to:
  /// **'Cover emoji {emoji}'**
  String groupsCoverEmojiSemantics(String emoji);

  /// Create group: heading for the optional cover photo.
  ///
  /// In en, this message translates to:
  /// **'Cover photo (optional)'**
  String get groupsCreateCoverPhotoOptional;

  /// Create group: hint that the photo is reviewed before members see it.
  ///
  /// In en, this message translates to:
  /// **'Members see the emoji until your photo is approved.'**
  String get groupsCreateCoverPhotoHint;

  /// Create group: button to choose a cover photo.
  ///
  /// In en, this message translates to:
  /// **'Add a cover photo'**
  String get groupsCreateAddCoverPhoto;

  /// Create group: button to choose a different cover photo.
  ///
  /// In en, this message translates to:
  /// **'Change photo'**
  String get groupsCreateChangePhoto;

  /// Create group: button to drop the chosen cover photo.
  ///
  /// In en, this message translates to:
  /// **'Remove photo'**
  String get groupsCreateRemovePhoto;

  /// Create group: section header (uppercase) for invitees.
  ///
  /// In en, this message translates to:
  /// **'FRIENDS'**
  String get groupsCreateFriendsHeader;

  /// Create group: caption when no friends are chosen yet.
  ///
  /// In en, this message translates to:
  /// **'Invite friends now, or later from the group.'**
  String get groupsCreateFriendsCaptionEmpty;

  /// Create group: caption when friends are chosen.
  ///
  /// In en, this message translates to:
  /// **'They’ll get an invitation to join.'**
  String get groupsCreateFriendsCaption;

  /// Groups: fallback name for a friend without a name.
  ///
  /// In en, this message translates to:
  /// **'Friend'**
  String get groupsFriendFallback;

  /// Create group: tooltip to remove a chosen friend. {name} is the friend's name.
  ///
  /// In en, this message translates to:
  /// **'Remove {name}'**
  String groupsRemoveInvitee(String name);

  /// Groups: button and picker title to choose friends.
  ///
  /// In en, this message translates to:
  /// **'Choose friends'**
  String get groupsChooseFriends;

  /// Create group: button to change the chosen friends.
  ///
  /// In en, this message translates to:
  /// **'Change friends'**
  String get groupsChangeFriends;

  /// Create group: create button while creating.
  ///
  /// In en, this message translates to:
  /// **'Creating…'**
  String get groupsCreating;

  /// Create group: create button.
  ///
  /// In en, this message translates to:
  /// **'Create group'**
  String get groupsCreateGroup;

  /// Group card: caption part when the group was removed after a review.
  ///
  /// In en, this message translates to:
  /// **'Removed after a review'**
  String get groupsCardRemoved;

  /// Group card: screen-reader label when the chat is muted. {name} is the group name, {details} the card caption.
  ///
  /// In en, this message translates to:
  /// **'{name}, {details}, notifications muted'**
  String groupsCardSemanticsMuted(String name, String details);

  /// Group card: screen-reader label of the muted icon.
  ///
  /// In en, this message translates to:
  /// **'Notifications muted'**
  String get groupsNotificationsMuted;

  /// Group card: screen-reader label of the unread badge.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 unread message} other{{count} unread messages}}'**
  String groupsUnreadMessages(int count);

  /// Cover picker: sheet title.
  ///
  /// In en, this message translates to:
  /// **'Cover photo'**
  String get groupsCoverSheetTitle;

  /// Cover picker: sheet subtitle about review and file limits.
  ///
  /// In en, this message translates to:
  /// **'Every photo is checked before other members can see it. Use a JPEG or PNG up to 10 MB.'**
  String get groupsCoverSheetBody;

  /// Cover picker: choose from the photo library.
  ///
  /// In en, this message translates to:
  /// **'Choose from your photos'**
  String get groupsCoverFromPhotos;

  /// Cover picker: take a photo with the camera.
  ///
  /// In en, this message translates to:
  /// **'Take a photo'**
  String get groupsCoverTakePhoto;

  /// Cover picker: snackbar when the photo is over 10 MB.
  ///
  /// In en, this message translates to:
  /// **'That photo is larger than 10 MB. Choose a smaller one.'**
  String get groupsCoverTooLarge;

  /// Cover picker: preview sheet title.
  ///
  /// In en, this message translates to:
  /// **'Preview your cover'**
  String get groupsCoverPreviewTitle;

  /// Cover picker: preview sheet subtitle explaining the banner crop.
  ///
  /// In en, this message translates to:
  /// **'Covers show as a wide banner, keeping the middle of your photo.'**
  String get groupsCoverPreviewBody;

  /// Groups: cancel button.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get groupsCancel;

  /// Cover picker: confirm the previewed photo.
  ///
  /// In en, this message translates to:
  /// **'Use this photo'**
  String get groupsCoverUseThisPhoto;

  /// Cover picker: screen-reader label of the previewed photo.
  ///
  /// In en, this message translates to:
  /// **'Your new cover photo'**
  String get groupsCoverPreviewSemantics;

  /// Cover upload: progress label once the bytes are sent.
  ///
  /// In en, this message translates to:
  /// **'Checking your cover photo…'**
  String get groupsCoverChecking;

  /// Cover upload: progress label. {percent} is 0–99.
  ///
  /// In en, this message translates to:
  /// **'Uploading cover photo… {percent}%'**
  String groupsCoverUploading(int percent);

  /// Cover upload: snackbar when the new cover awaits review.
  ///
  /// In en, this message translates to:
  /// **'Your cover is under review. Only you can see it until it’s approved.'**
  String get groupsCoverUploadedReview;

  /// Cover upload: snackbar when the new cover is live.
  ///
  /// In en, this message translates to:
  /// **'Cover photo updated.'**
  String get groupsCoverUpdated;

  /// Friend picker: subtitle explaining only accepted friends can be invited.
  ///
  /// In en, this message translates to:
  /// **'Only friends you’re connected with can be invited.'**
  String get groupsPickerSubtitle;

  /// Friend picker: default confirm button.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get groupsDone;

  /// Friend picker: search field label.
  ///
  /// In en, this message translates to:
  /// **'Search friends'**
  String get groupsSearchFriends;

  /// Friend picker: error title when friends fail to load.
  ///
  /// In en, this message translates to:
  /// **'Friends could not load'**
  String get groupsFriendsFailed;

  /// Friend picker: empty state title.
  ///
  /// In en, this message translates to:
  /// **'No friends yet'**
  String get groupsNoFriendsTitle;

  /// Friend picker: empty state message. 'Matches' is the app's Matches tab.
  ///
  /// In en, this message translates to:
  /// **'Add friends from Matches, profiles or rooms, then bring them into a group.'**
  String get groupsNoFriendsBody;

  /// Friend picker: a friend who is already in the group.
  ///
  /// In en, this message translates to:
  /// **'Already in this group'**
  String get groupsAlreadyMember;

  /// Friend picker: a friend who already has a pending invitation.
  ///
  /// In en, this message translates to:
  /// **'Invitation sent'**
  String get groupsInvitationSent;

  /// First-date activity label (id coffee).
  ///
  /// In en, this message translates to:
  /// **'Coffee'**
  String get todayActivityCoffee;

  /// First-date activity label (id walk).
  ///
  /// In en, this message translates to:
  /// **'A daytime walk'**
  String get todayActivityWalk;

  /// First-date activity label (id meal).
  ///
  /// In en, this message translates to:
  /// **'A meal'**
  String get todayActivityMeal;

  /// First-date activity label (id activity).
  ///
  /// In en, this message translates to:
  /// **'Something playful'**
  String get todayActivityPlayful;

  /// First-date activity label (id event).
  ///
  /// In en, this message translates to:
  /// **'An event'**
  String get todayActivityEvent;

  /// First-date activity label (id video_call).
  ///
  /// In en, this message translates to:
  /// **'A video hello'**
  String get todayActivityVideoCall;

  /// First-date activity label (id drinks).
  ///
  /// In en, this message translates to:
  /// **'Drinks'**
  String get todayActivityDrinks;

  /// First-date activity label (id other).
  ///
  /// In en, this message translates to:
  /// **'Something else'**
  String get todayActivityOther;

  /// Date budget label (id flexible); also the default.
  ///
  /// In en, this message translates to:
  /// **'Let’s decide together'**
  String get todayBudgetFlexible;

  /// Date budget label (id free).
  ///
  /// In en, this message translates to:
  /// **'Keep it free'**
  String get todayBudgetFree;

  /// Date budget label (id modest).
  ///
  /// In en, this message translates to:
  /// **'Keep it modest'**
  String get todayBudgetModest;

  /// Date budget label (id treat).
  ///
  /// In en, this message translates to:
  /// **'A little treat'**
  String get todayBudgetTreat;

  /// Dating rhythm screen: app bar title.
  ///
  /// In en, this message translates to:
  /// **'Your dating rhythm'**
  String get todayRhythmTitle;

  /// Dating rhythm screen: load error.
  ///
  /// In en, this message translates to:
  /// **'Unable to load your preferences.'**
  String get todayRhythmLoadFailed;

  /// Dating rhythm screen: snackbar after saving.
  ///
  /// In en, this message translates to:
  /// **'Your dating rhythm is saved.'**
  String get todayRhythmSaved;

  /// Dating rhythm screen: fallback save error.
  ///
  /// In en, this message translates to:
  /// **'Unable to save. Your choices are still here.'**
  String get todayRhythmSaveFailed;

  /// Dating rhythm screen: headline.
  ///
  /// In en, this message translates to:
  /// **'Make room for the way you date.'**
  String get todayRhythmHeadline;

  /// Dating rhythm screen: intro paragraph.
  ///
  /// In en, this message translates to:
  /// **'Choose what fits your life. Availability and introductions are optional, and you can change your mind.'**
  String get todayRhythmIntro;

  /// Dating rhythm screen: intent section title.
  ///
  /// In en, this message translates to:
  /// **'What are you open to?'**
  String get todayRhythmOpenTo;

  /// Dating rhythm: intent option (no answer).
  ///
  /// In en, this message translates to:
  /// **'Prefer not to say'**
  String get todayRhythmIntentNone;

  /// Dating rhythm: intent option (relationship).
  ///
  /// In en, this message translates to:
  /// **'A relationship'**
  String get todayRhythmIntentRelationship;

  /// Dating rhythm: intent option (exploring).
  ///
  /// In en, this message translates to:
  /// **'Finding my direction'**
  String get todayRhythmIntentExploring;

  /// Dating rhythm: intent option (casual).
  ///
  /// In en, this message translates to:
  /// **'Something casual'**
  String get todayRhythmIntentCasual;

  /// Dating rhythm screen: pace section title.
  ///
  /// In en, this message translates to:
  /// **'Your conversation pace'**
  String get todayRhythmPaceSection;

  /// Dating rhythm: pace option (no preference).
  ///
  /// In en, this message translates to:
  /// **'No preference'**
  String get todayRhythmPaceNone;

  /// Dating rhythm: pace option (slow).
  ///
  /// In en, this message translates to:
  /// **'A little slower'**
  String get todayRhythmPaceSlow;

  /// Dating rhythm: pace option (steady).
  ///
  /// In en, this message translates to:
  /// **'A steady conversation'**
  String get todayRhythmPaceSteady;

  /// Dating rhythm: pace option (frequent).
  ///
  /// In en, this message translates to:
  /// **'Frequent conversation'**
  String get todayRhythmPaceFrequent;

  /// Dating rhythm: slow-replies switch title.
  ///
  /// In en, this message translates to:
  /// **'Slow replies this week'**
  String get todayRhythmSlowWeek;

  /// Dating rhythm: slow-replies switch subtitle.
  ///
  /// In en, this message translates to:
  /// **'This status clears after seven days.'**
  String get todayRhythmSlowWeekHint;

  /// Dating rhythm: share-pace switch title.
  ///
  /// In en, this message translates to:
  /// **'Share this status with my matches'**
  String get todayRhythmSharePace;

  /// Dating rhythm: share-pace switch subtitle.
  ///
  /// In en, this message translates to:
  /// **'Only current matches can see your temporary status.'**
  String get todayRhythmSharePaceHint;

  /// Dating rhythm screen: first-date section title.
  ///
  /// In en, this message translates to:
  /// **'Your kind of first date'**
  String get todayRhythmFirstDate;

  /// Dating rhythm screen: note under the first-date activities.
  ///
  /// In en, this message translates to:
  /// **'Choose up to five. Shared preferences help explain your introductions.'**
  String get todayRhythmChooseFive;

  /// Dating rhythm screen: availability section title.
  ///
  /// In en, this message translates to:
  /// **'A little room in your week'**
  String get todayRhythmWeekSection;

  /// Dating rhythm: availability switch title.
  ///
  /// In en, this message translates to:
  /// **'Use my broad availability'**
  String get todayRhythmShareAvailability;

  /// Dating rhythm: availability switch subtitle.
  ///
  /// In en, this message translates to:
  /// **'Only genuine overlap is shown. Your full schedule is private. Turning this off deletes saved windows.'**
  String get todayRhythmShareAvailabilityHint;

  /// Dating rhythm: instructions above the availability chips.
  ///
  /// In en, this message translates to:
  /// **'Tap any morning, afternoon or evening that suits you. Times use this device’s local time and expire automatically.'**
  String get todayRhythmAvailabilityHint;

  /// Dating rhythm: availability slot (morning).
  ///
  /// In en, this message translates to:
  /// **'Morning'**
  String get todayRhythmMorning;

  /// Dating rhythm: availability slot (afternoon).
  ///
  /// In en, this message translates to:
  /// **'Afternoon'**
  String get todayRhythmAfternoon;

  /// Dating rhythm: availability slot (evening).
  ///
  /// In en, this message translates to:
  /// **'Evening'**
  String get todayRhythmEvening;

  /// Dating rhythm screen: friend introductions section title.
  ///
  /// In en, this message translates to:
  /// **'Introductions with your permission'**
  String get todayRhythmIntrosSection;

  /// Dating rhythm: friend introductions switch title.
  ///
  /// In en, this message translates to:
  /// **'Allow introductions from accepted friends'**
  String get todayRhythmFriendIntros;

  /// Dating rhythm: friend introductions switch subtitle.
  ///
  /// In en, this message translates to:
  /// **'Both people must opt in. Your friend receives no match or decline updates. A preview includes your name and age.'**
  String get todayRhythmFriendIntrosHint;

  /// Dating rhythm: include-photos switch title.
  ///
  /// In en, this message translates to:
  /// **'Include my profile photos'**
  String get todayRhythmIntroPhoto;

  /// Dating rhythm: include-photos switch subtitle.
  ///
  /// In en, this message translates to:
  /// **'Only the person receiving an introduction can see them.'**
  String get todayRhythmIntroPhotoHint;

  /// Dating rhythm: include-city switch title.
  ///
  /// In en, this message translates to:
  /// **'Include my city'**
  String get todayRhythmIntroCity;

  /// Dating rhythm: include-city switch subtitle.
  ///
  /// In en, this message translates to:
  /// **'Your exact location is never included.'**
  String get todayRhythmIntroCityHint;

  /// Dating rhythm: reload saved choices after an error.
  ///
  /// In en, this message translates to:
  /// **'Reload saved choices'**
  String get todayRhythmReload;

  /// Dating rhythm: save button while saving.
  ///
  /// In en, this message translates to:
  /// **'Saving…'**
  String get todayRhythmSaving;

  /// Dating rhythm: save button.
  ///
  /// In en, this message translates to:
  /// **'Save my rhythm'**
  String get todayRhythmSave;

  /// Dating rhythm: pause section title.
  ///
  /// In en, this message translates to:
  /// **'A break is always okay.'**
  String get todayRhythmBreakTitle;

  /// Dating rhythm: pause section body.
  ///
  /// In en, this message translates to:
  /// **'Pause new introductions whenever you need. Your existing conversations stay available.'**
  String get todayRhythmBreakBody;

  /// Dating rhythm: fallback error when pausing/resuming fails.
  ///
  /// In en, this message translates to:
  /// **'Unable to update your pause.'**
  String get todayRhythmPauseFailed;

  /// Dating rhythm: resume introductions button.
  ///
  /// In en, this message translates to:
  /// **'Resume introductions'**
  String get todayRhythmResume;

  /// Dating rhythm: pause introductions button.
  ///
  /// In en, this message translates to:
  /// **'Pause introductions'**
  String get todayRhythmPause;

  /// Chat connection card: title when the match is replying slowly.
  ///
  /// In en, this message translates to:
  /// **'Taking replies slowly this week'**
  String get datingConnectionSlowTitle;

  /// Chat connection card: subtitle when the match is replying slowly.
  ///
  /// In en, this message translates to:
  /// **'Your match is making room for a slower pace.'**
  String get datingConnectionSlowBody;

  /// Chat connection card: First Chapter status (your turn).
  ///
  /// In en, this message translates to:
  /// **'Your turn: add a surprise'**
  String get datingConnectionYourTurn;

  /// Chat connection card: First Chapter status (complete).
  ///
  /// In en, this message translates to:
  /// **'Your first chapter is ready'**
  String get datingConnectionComplete;

  /// Chat connection card: First Chapter status (waiting).
  ///
  /// In en, this message translates to:
  /// **'Your chapter has a beginning'**
  String get datingConnectionWaiting;

  /// Chat connection card: First Chapter status (not started).
  ///
  /// In en, this message translates to:
  /// **'Create your first chapter'**
  String get datingConnectionCreate;

  /// Chat connection card: First Chapter subtitle.
  ///
  /// In en, this message translates to:
  /// **'A beginning, a surprise, and a story you shape together.'**
  String get datingConnectionBody;

  /// Chemistry sheet: title.
  ///
  /// In en, this message translates to:
  /// **'A little chemistry'**
  String get chemistryTitle;

  /// Chemistry sheet: intro.
  ///
  /// In en, this message translates to:
  /// **'Pick something that feels like you. There are no right answers, and this never controls access to chat.'**
  String get chemistryIntro;

  /// Chemistry sheet: fallback error when an answer cannot be saved.
  ///
  /// In en, this message translates to:
  /// **'Unable to save your choice. Please try again.'**
  String get chemistrySaveFailed;

  /// Chemistry sheet: retry loading.
  ///
  /// In en, this message translates to:
  /// **'Try loading again'**
  String get chemistryRetry;

  /// Chemistry sheet: heading when both answers are revealed.
  ///
  /// In en, this message translates to:
  /// **'Both answers, together'**
  String get chemistryRevealedTitle;

  /// Chemistry sheet: your answer label.
  ///
  /// In en, this message translates to:
  /// **'You picked'**
  String get chemistryYouPicked;

  /// Chemistry sheet: your match's answer label.
  ///
  /// In en, this message translates to:
  /// **'Your match picked'**
  String get chemistryMatchPicked;

  /// Chemistry sheet: note under revealed answers.
  ///
  /// In en, this message translates to:
  /// **'A shared favourite or a happy difference—there’s something to talk about.'**
  String get chemistryRevealedBody;

  /// Chemistry sheet: waiting for the other answer.
  ///
  /// In en, this message translates to:
  /// **'Your answer is saved privately. Both answers appear here when you have both chosen.'**
  String get chemistryWaitingBody;

  /// Chemistry sheet: your saved answer while waiting.
  ///
  /// In en, this message translates to:
  /// **'Your choice: {choice}'**
  String chemistryYourChoice(String choice);

  /// Chemistry sheet: heading to start another moment.
  ///
  /// In en, this message translates to:
  /// **'Another moment, whenever you like'**
  String get chemistryAnotherMoment;

  /// Chemistry sheet: heading to choose a moment.
  ///
  /// In en, this message translates to:
  /// **'Choose a moment'**
  String get chemistryChooseMoment;

  /// Chemistry sheet: moment option (sunday).
  ///
  /// In en, this message translates to:
  /// **'Build a Sunday'**
  String get chemistryPromptSunday;

  /// Chemistry sheet: moment option (adventure).
  ///
  /// In en, this message translates to:
  /// **'Choose an adventure'**
  String get chemistryPromptAdventure;

  /// Chemistry sheet: moment option (first_date).
  ///
  /// In en, this message translates to:
  /// **'Your kind of first date'**
  String get chemistryPromptFirstDate;

  /// Chemistry sheet: open question (sunday).
  ///
  /// In en, this message translates to:
  /// **'Your ideal Sunday starts with…'**
  String get chemistryQuestionSunday;

  /// Chemistry sheet: open question (adventure).
  ///
  /// In en, this message translates to:
  /// **'A small adventure together…'**
  String get chemistryQuestionAdventure;

  /// Chemistry sheet: open question (first date).
  ///
  /// In en, this message translates to:
  /// **'For a first hello, you’d choose…'**
  String get chemistryQuestionFirstDate;

  /// Level & XP screen: notice while progression is frozen for a safety review.
  ///
  /// In en, this message translates to:
  /// **'Progression is paused while an account safety review is active.'**
  String get engagementLevelFrozen;

  /// Level & XP screen: notice that higher levels need verification and good standing.
  ///
  /// In en, this message translates to:
  /// **'Verify your profile and maintain a healthy account to unlock trust-gated levels.'**
  String get engagementLevelTrustGate;

  /// Level & XP screen: section title for the list of levels.
  ///
  /// In en, this message translates to:
  /// **'Level path'**
  String get engagementLevelPathTitle;

  /// Level & XP screen: subtitle of the level path section.
  ///
  /// In en, this message translates to:
  /// **'XP comes from meaningful activity. Purchases never increase your level.'**
  String get engagementLevelPathSubtitle;

  /// Level & XP screen: section title for rewards.
  ///
  /// In en, this message translates to:
  /// **'Rewards'**
  String get engagementLevelRewardsTitle;

  /// Level & XP screen: subtitle of the rewards section.
  ///
  /// In en, this message translates to:
  /// **'Earned rewards are cosmetic, convenience, or bounded visibility benefits.'**
  String get engagementLevelRewardsSubtitle;

  /// Level & XP screen: section title for the recent XP ledger.
  ///
  /// In en, this message translates to:
  /// **'Recent XP'**
  String get engagementLevelRecentTitle;

  /// Level & XP screen: subtitle of the recent XP section.
  ///
  /// In en, this message translates to:
  /// **'Your activity ledger is permanent and auditable.'**
  String get engagementLevelRecentSubtitle;

  /// Level & XP screen: level number label.
  ///
  /// In en, this message translates to:
  /// **'Level {level}'**
  String engagementLevelNumber(int level);

  /// Level & XP screen: an amount of experience points; xp may carry a + sign.
  ///
  /// In en, this message translates to:
  /// **'{xp} XP'**
  String engagementLevelXp(String xp);

  /// Level & XP screen: shown when the member is at the top level.
  ///
  /// In en, this message translates to:
  /// **'Highest level reached'**
  String get engagementLevelHighest;

  /// Level & XP screen: XP earned inside the current level and percent towards the next.
  ///
  /// In en, this message translates to:
  /// **'{xp} XP in this level · {percent}%'**
  String engagementLevelProgress(int xp, String percent);

  /// Level & XP screen: XP needed for a level and its reward summary (from the server).
  ///
  /// In en, this message translates to:
  /// **'{xp} XP · {summary}'**
  String engagementLevelThreshold(int xp, String summary);

  /// Level & XP screen: tooltip on levels that need trust requirements.
  ///
  /// In en, this message translates to:
  /// **'Trust-gated'**
  String get engagementLevelTrustGated;

  /// Level & XP screen: reward button when already claimed.
  ///
  /// In en, this message translates to:
  /// **'Claimed'**
  String get engagementLevelClaimed;

  /// Level & XP screen: button to claim an unlocked reward.
  ///
  /// In en, this message translates to:
  /// **'Claim'**
  String get engagementLevelClaim;

  /// Level & XP screen: reward button when the level is not reached.
  ///
  /// In en, this message translates to:
  /// **'Locked'**
  String get engagementLevelLocked;

  /// Level & XP screen: ledger line for an XP award without a multiplier.
  ///
  /// In en, this message translates to:
  /// **'Standard award'**
  String get engagementLevelStandardAward;

  /// Level & XP screen: ledger line for an XP award with a quality multiplier, e.g. 1.25×.
  ///
  /// In en, this message translates to:
  /// **'{multiplier}× quality weighting'**
  String engagementLevelQualityWeighting(String multiplier);

  /// Level & XP screen: empty XP ledger.
  ///
  /// In en, this message translates to:
  /// **'Complete meaningful activities to earn your first XP.'**
  String get engagementLevelEmptyLedger;

  /// Level & XP ledger: XP source 'profile_completed'.
  ///
  /// In en, this message translates to:
  /// **'Profile Completed'**
  String get engagementXpSourceProfileCompleted;

  /// Level & XP ledger: XP source 'daily_prompt_submitted'.
  ///
  /// In en, this message translates to:
  /// **'Daily Prompt Submitted'**
  String get engagementXpSourceDailyPromptSubmitted;

  /// Level & XP ledger: XP source 'mini_activity_completed'.
  ///
  /// In en, this message translates to:
  /// **'Mini Activity Completed'**
  String get engagementXpSourceMiniActivityCompleted;

  /// Level & XP ledger: XP source 'circle_challenge_submitted'.
  ///
  /// In en, this message translates to:
  /// **'Circle Challenge Submitted'**
  String get engagementXpSourceCircleChallengeSubmitted;

  /// Level & XP ledger: XP source 'voice_icebreaker_played'.
  ///
  /// In en, this message translates to:
  /// **'Voice Icebreaker Played'**
  String get engagementXpSourceVoiceIcebreakerPlayed;

  /// Level & XP ledger: XP source 'streak_3' (three-day streak bonus).
  ///
  /// In en, this message translates to:
  /// **'Streak 3'**
  String get engagementXpSourceStreak3;

  /// Level & XP ledger: XP source 'streak_7' (seven-day streak bonus).
  ///
  /// In en, this message translates to:
  /// **'Streak 7'**
  String get engagementXpSourceStreak7;

  /// Level & XP ledger: XP source 'streak_14' (fourteen-day streak bonus).
  ///
  /// In en, this message translates to:
  /// **'Streak 14'**
  String get engagementXpSourceStreak14;

  /// Level & XP ledger: XP source 'admin_adjustment' (audited manual correction).
  ///
  /// In en, this message translates to:
  /// **'Admin Adjustment'**
  String get engagementXpSourceAdminAdjustment;

  /// Level & XP: error when no one is signed in.
  ///
  /// In en, this message translates to:
  /// **'Sign in to view your level progress.'**
  String get engagementLevelSignIn;

  /// Level & XP: fallback error when progress fails to load.
  ///
  /// In en, this message translates to:
  /// **'Unable to load your progress right now.'**
  String get engagementLevelLoadFailed;

  /// Level & XP: fallback error when claiming a reward fails.
  ///
  /// In en, this message translates to:
  /// **'Unable to claim this reward right now.'**
  String get engagementLevelClaimFailed;

  /// Group Coffee Polls screen title.
  ///
  /// In en, this message translates to:
  /// **'Group Coffee Polls'**
  String get engagementCoffeeTitle;

  /// Group Coffee Polls: heading of the create form.
  ///
  /// In en, this message translates to:
  /// **'Create a lightweight group coffee poll'**
  String get engagementCoffeeCreateHeading;

  /// Group Coffee Polls: instructions under the create heading.
  ///
  /// In en, this message translates to:
  /// **'Add up to 3 participant user IDs (comma-separated) and at least one option.'**
  String get engagementCoffeeCreateHint;

  /// Group Coffee Polls: participants field label.
  ///
  /// In en, this message translates to:
  /// **'Participant user IDs (comma-separated)'**
  String get engagementCoffeeParticipantsLabel;

  /// Group Coffee Polls: deadline field label (ISO 8601 date-time).
  ///
  /// In en, this message translates to:
  /// **'Deadline ISO (optional)'**
  String get engagementCoffeeDeadlineLabel;

  /// Group Coffee Polls: heading of an option in the create form.
  ///
  /// In en, this message translates to:
  /// **'Option {number}'**
  String engagementCoffeeOptionNumber(int number);

  /// Group Coffee Polls: create button.
  ///
  /// In en, this message translates to:
  /// **'Create Poll'**
  String get engagementCoffeeCreate;

  /// Group Coffee Polls: optional user ID to act as when voting/finalizing.
  ///
  /// In en, this message translates to:
  /// **'Action user ID override (optional)'**
  String get engagementCoffeeActorLabel;

  /// Group Coffee Polls: no polls yet.
  ///
  /// In en, this message translates to:
  /// **'No polls found yet. Create one above.'**
  String get engagementCoffeeEmpty;

  /// Group Coffee Polls: poll card title with its id.
  ///
  /// In en, this message translates to:
  /// **'Poll {id}'**
  String engagementCoffeePollId(String id);

  /// Group Coffee Polls: poll status line; status is already localized.
  ///
  /// In en, this message translates to:
  /// **'Status: {status}'**
  String engagementCoffeeStatus(String status);

  /// Group Coffee Polls: status value for an open poll (lowercase).
  ///
  /// In en, this message translates to:
  /// **'open'**
  String get engagementCoffeeStatusOpen;

  /// Group Coffee Polls: status value for a finalized poll (lowercase).
  ///
  /// In en, this message translates to:
  /// **'finalized'**
  String get engagementCoffeeStatusFinalized;

  /// Group Coffee Polls: participant ids line.
  ///
  /// In en, this message translates to:
  /// **'Participants: {ids}'**
  String engagementCoffeeParticipants(String ids);

  /// Group Coffee Polls: one option with day, time window, neighborhood (all typed by members) and its vote count.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, other{{day} · {time} · {area} ({count} votes)}}'**
  String engagementCoffeeOptionSummary(
    String day,
    String time,
    String area,
    int count,
  );

  /// Group Coffee Polls: vote button.
  ///
  /// In en, this message translates to:
  /// **'Vote'**
  String get engagementCoffeeVote;

  /// Group Coffee Polls: finalize button.
  ///
  /// In en, this message translates to:
  /// **'Finalize Poll'**
  String get engagementCoffeeFinalize;

  /// Group Coffee Polls: day field label.
  ///
  /// In en, this message translates to:
  /// **'Day'**
  String get engagementCoffeeDayLabel;

  /// Group Coffee Polls: time window field label.
  ///
  /// In en, this message translates to:
  /// **'Time window'**
  String get engagementCoffeeTimeLabel;

  /// Group Coffee Polls: neighborhood field label.
  ///
  /// In en, this message translates to:
  /// **'Neighborhood'**
  String get engagementCoffeeAreaLabel;

  /// Group Coffee Polls: fallback error when polls fail to load.
  ///
  /// In en, this message translates to:
  /// **'Unable to load group polls right now.'**
  String get engagementCoffeeLoadFailed;

  /// Group Coffee Polls: fallback error when creating fails.
  ///
  /// In en, this message translates to:
  /// **'Unable to create group poll right now.'**
  String get engagementCoffeeCreateFailed;

  /// Group Coffee Polls: voting needs a user.
  ///
  /// In en, this message translates to:
  /// **'User ID is required to vote.'**
  String get engagementCoffeeVoteUserRequired;

  /// Group Coffee Polls: fallback error when voting fails.
  ///
  /// In en, this message translates to:
  /// **'Unable to vote right now.'**
  String get engagementCoffeeVoteFailed;

  /// Group Coffee Polls: finalizing needs a user.
  ///
  /// In en, this message translates to:
  /// **'User ID is required to finalize.'**
  String get engagementCoffeeFinalizeUserRequired;

  /// Group Coffee Polls: fallback error when finalizing fails.
  ///
  /// In en, this message translates to:
  /// **'Unable to finalize poll right now.'**
  String get engagementCoffeeFinalizeFailed;

  /// Daily Prompt screen: title when no prompt could be shown.
  ///
  /// In en, this message translates to:
  /// **'Daily prompt unavailable'**
  String get engagementDailyPromptUnavailable;

  /// Daily Prompt screen: hint when no prompt could be shown.
  ///
  /// In en, this message translates to:
  /// **'Pull to refresh or try again in a bit.'**
  String get engagementDailyPromptPullToRefresh;

  /// Daily Prompt screen: uppercase topic label for prompts about values.
  ///
  /// In en, this message translates to:
  /// **'VALUES'**
  String get engagementDailyPromptDomainValues;

  /// Daily Prompt screen: uppercase topic label for prompts about lifestyle.
  ///
  /// In en, this message translates to:
  /// **'LIFESTYLE'**
  String get engagementDailyPromptDomainLifestyle;

  /// Daily Prompt screen: uppercase topic label for prompts about relationship style.
  ///
  /// In en, this message translates to:
  /// **'RELATIONSHIP STYLE'**
  String get engagementDailyPromptDomainRelationshipStyle;

  /// Daily Prompt screen: card title for today's participation stats.
  ///
  /// In en, this message translates to:
  /// **'Compatibility Spark'**
  String get engagementDailyPromptSparkTitle;

  /// Daily Prompt screen: how many replied today and how many answered similarly.
  ///
  /// In en, this message translates to:
  /// **'{replied} replied today · {similar} similar answers'**
  String engagementDailyPromptSparkSummary(int replied, int similar);

  /// Daily Prompt screen: answer card title.
  ///
  /// In en, this message translates to:
  /// **'Your answer'**
  String get engagementDailyPromptYourAnswer;

  /// Daily Prompt screen: answer field hint.
  ///
  /// In en, this message translates to:
  /// **'Type your response in under 60 seconds.'**
  String get engagementDailyPromptHint;

  /// Daily Prompt screen: the answer can be edited until a time today (24-hour HH:mm).
  ///
  /// In en, this message translates to:
  /// **'Edit window open until {time}'**
  String engagementDailyPromptEditOpenUntil(String time);

  /// Daily Prompt screen: the answer can still be edited but the end time is unknown.
  ///
  /// In en, this message translates to:
  /// **'Edit window open until soon'**
  String get engagementDailyPromptEditOpenSoon;

  /// Daily Prompt screen: the answer can no longer be edited today.
  ///
  /// In en, this message translates to:
  /// **'Edit window closed for today.'**
  String get engagementDailyPromptEditClosed;

  /// Daily Prompt screen: marker that the answer was edited.
  ///
  /// In en, this message translates to:
  /// **'Edited'**
  String get engagementDailyPromptEdited;

  /// Daily Prompt screen: submit button before answering.
  ///
  /// In en, this message translates to:
  /// **'Submit Daily Answer'**
  String get engagementDailyPromptSubmit;

  /// Daily Prompt screen: submit button after answering.
  ///
  /// In en, this message translates to:
  /// **'Update Answer'**
  String get engagementDailyPromptUpdate;

  /// Daily Prompt screen: streak card title.
  ///
  /// In en, this message translates to:
  /// **'Streak Progress'**
  String get engagementDailyPromptStreakProgress;

  /// Daily Prompt screen: current streak pill; value is e.g. '3d'.
  ///
  /// In en, this message translates to:
  /// **'Current: {value}'**
  String engagementDailyPromptStatCurrent(String value);

  /// Daily Prompt screen: longest streak pill; value is e.g. '7d'.
  ///
  /// In en, this message translates to:
  /// **'Best: {value}'**
  String engagementDailyPromptStatBest(String value);

  /// Daily Prompt screen: next milestone pill; value is e.g. '7d' or 'Complete'.
  ///
  /// In en, this message translates to:
  /// **'Next: {value}'**
  String engagementDailyPromptStatNext(String value);

  /// Daily Prompt screen: short number of days in the streak pills (d = days).
  ///
  /// In en, this message translates to:
  /// **'{days}d'**
  String engagementDailyPromptDays(int days);

  /// Daily Prompt screen: next-milestone pill value when every milestone is reached.
  ///
  /// In en, this message translates to:
  /// **'Complete'**
  String get engagementDailyPromptComplete;

  /// Daily Prompt screen: a streak milestone was reached today.
  ///
  /// In en, this message translates to:
  /// **'Milestone unlocked: {days}-day streak'**
  String engagementDailyPromptMilestone(int days);

  /// Daily Prompt: fallback error when loading fails.
  ///
  /// In en, this message translates to:
  /// **'Unable to load daily prompt right now.'**
  String get engagementDailyPromptLoadFailed;

  /// Daily Prompt: tried to answer before the prompt loaded.
  ///
  /// In en, this message translates to:
  /// **'Daily prompt is not loaded yet.'**
  String get engagementDailyPromptNotLoaded;

  /// Daily Prompt: validation error, empty answer.
  ///
  /// In en, this message translates to:
  /// **'Please enter an answer first.'**
  String get engagementDailyPromptEnterAnswer;

  /// Daily Prompt: fallback error when submitting fails.
  ///
  /// In en, this message translates to:
  /// **'Unable to submit answer. Please try again.'**
  String get engagementDailyPromptSubmitFailed;

  /// Clubs: segment/filter label for book clubs and book lists.
  ///
  /// In en, this message translates to:
  /// **'Books'**
  String get clubsKindBooks;

  /// Clubs: segment/filter label for film clubs and film lists.
  ///
  /// In en, this message translates to:
  /// **'Films'**
  String get clubsKindFilms;

  /// Clubs screen: filter chip showing both book and film clubs.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get clubsFilterAll;

  /// Clubs: visibility choice for a list or review that only its author sees.
  ///
  /// In en, this message translates to:
  /// **'Only me'**
  String get clubsAudiencePrivate;

  /// Clubs: visibility choice for a list or review that friends can see.
  ///
  /// In en, this message translates to:
  /// **'Friends'**
  String get clubsAudienceFriends;

  /// Clubs: visibility choice for a list or review that every member of the Connect app can see. Keep the brand name Connect.
  ///
  /// In en, this message translates to:
  /// **'Connect community'**
  String get clubsAudienceCommunity;

  /// Clubs: role label for the member who runs the club.
  ///
  /// In en, this message translates to:
  /// **'Owner'**
  String get clubsRoleOwner;

  /// Clubs: role label for a club moderator.
  ///
  /// In en, this message translates to:
  /// **'Moderator'**
  String get clubsRoleModerator;

  /// Clubs: role label for an ordinary club member.
  ///
  /// In en, this message translates to:
  /// **'Member'**
  String get clubsRoleMember;

  /// Clubs: badge on a book club.
  ///
  /// In en, this message translates to:
  /// **'Book club'**
  String get clubsBadgeBookClub;

  /// Clubs: badge on a film club.
  ///
  /// In en, this message translates to:
  /// **'Film club'**
  String get clubsBadgeFilmClub;

  /// Clubs: badge on a member's list of books.
  ///
  /// In en, this message translates to:
  /// **'Book list'**
  String get clubsBadgeBookList;

  /// Clubs: badge on a member's list of films.
  ///
  /// In en, this message translates to:
  /// **'Film list'**
  String get clubsBadgeFilmList;

  /// Clubs: badge on a title that is a book.
  ///
  /// In en, this message translates to:
  /// **'Book'**
  String get clubsBadgeBook;

  /// Clubs: badge on a title that is a film.
  ///
  /// In en, this message translates to:
  /// **'Film'**
  String get clubsBadgeFilm;

  /// Clubs: generic word 'Club', used as an app bar title while a club loads and as a badge for an unknown kind.
  ///
  /// In en, this message translates to:
  /// **'Club'**
  String get clubsClub;

  /// Clubs: screen-reader label for a star rating, e.g. '4.5 out of 5 stars'. {rating} is already formatted with one decimal.
  ///
  /// In en, this message translates to:
  /// **'{rating} out of 5 stars'**
  String clubsStarsOutOfFive(String rating);

  /// Clubs: tooltip on each tappable star when rating a title.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 star} other{{count} stars}}'**
  String clubsStarCount(int count);

  /// Clubs: shown instead of a rating when nobody has rated a title.
  ///
  /// In en, this message translates to:
  /// **'No ratings yet'**
  String get clubsNoRatingsYet;

  /// Clubs: average rating and number of reviews, e.g. '4.3 · 17 reviews'. {average} is already formatted with one decimal.
  ///
  /// In en, this message translates to:
  /// **'{average} · {count, plural, =1{1 review} other{{count} reviews}}'**
  String clubsRatingSummary(String average, int count);

  /// Clubs: label for the current week's pick.
  ///
  /// In en, this message translates to:
  /// **'This week'**
  String get clubsWeekThis;

  /// Clubs: label for next week's pick.
  ///
  /// In en, this message translates to:
  /// **'Next week'**
  String get clubsWeekNext;

  /// Clubs: label for last week's pick.
  ///
  /// In en, this message translates to:
  /// **'Last week'**
  String get clubsWeekLast;

  /// Clubs: label for an older pick's week. {date} is the Monday that starts the week, as an ISO date (2026-09-28).
  ///
  /// In en, this message translates to:
  /// **'Week of {date}'**
  String clubsWeekOf(String date);

  /// Clubs screen: app bar title.
  ///
  /// In en, this message translates to:
  /// **'Book & Film Clubs'**
  String get clubsTitle;

  /// Clubs: tooltip of the button that opens the member's lists, and title of that screen.
  ///
  /// In en, this message translates to:
  /// **'My lists'**
  String get clubsMyLists;

  /// Clubs screen: tooltip of the floating button that starts a new club.
  ///
  /// In en, this message translates to:
  /// **'Start a book or film club'**
  String get clubsStartClubTooltip;

  /// Clubs screen: floating button label and title of the sheet that creates a club.
  ///
  /// In en, this message translates to:
  /// **'Start a club'**
  String get clubsStartClub;

  /// Clubs: shown when the member is signed out.
  ///
  /// In en, this message translates to:
  /// **'Sign in to see clubs.'**
  String get clubsSignInToSee;

  /// Clubs screen: headline of the intro card.
  ///
  /// In en, this message translates to:
  /// **'Read it. Watch it. Talk about it.'**
  String get clubsHeroTitle;

  /// Clubs screen: body of the intro card. A 'pick' is the one book or film a club follows each week.
  ///
  /// In en, this message translates to:
  /// **'Join a club, follow one pick a week and share what you thought. Great taste is a great conversation starter.'**
  String get clubsHeroSubtitle;

  /// Clubs screen: segment showing the clubs the member belongs to.
  ///
  /// In en, this message translates to:
  /// **'My clubs'**
  String get clubsScopeMine;

  /// Clubs screen: segment showing clubs to discover.
  ///
  /// In en, this message translates to:
  /// **'Discover'**
  String get clubsScopeDiscover;

  /// Clubs screen: title of the notice when clubs fail to load.
  ///
  /// In en, this message translates to:
  /// **'Clubs could not load'**
  String get clubsLoadErrorTitle;

  /// Clubs: fallback message when something fails to load.
  ///
  /// In en, this message translates to:
  /// **'Please check your connection.'**
  String get clubsCheckConnection;

  /// Clubs screen: notice title when the member cannot yet start or join clubs.
  ///
  /// In en, this message translates to:
  /// **'You can look around'**
  String get clubsLookAroundTitle;

  /// Clubs screen: explains what the member needs before starting or joining a club.
  ///
  /// In en, this message translates to:
  /// **'Complete your profile with two approved photos to start or join a club.'**
  String get clubsLookAroundMessage;

  /// Clubs screen: empty state title when the member is in no clubs.
  ///
  /// In en, this message translates to:
  /// **'Your first club is waiting'**
  String get clubsEmptyMineTitle;

  /// Clubs screen: empty state message when the member is in no clubs.
  ///
  /// In en, this message translates to:
  /// **'Find a club that reads or watches what you love, or start your own.'**
  String get clubsEmptyMineMessage;

  /// Clubs screen: empty state title when there are no clubs to discover.
  ///
  /// In en, this message translates to:
  /// **'No clubs here yet'**
  String get clubsEmptyDiscoverTitle;

  /// Clubs screen: empty state message when there are no clubs to discover.
  ///
  /// In en, this message translates to:
  /// **'Be the first: start a club and pick something great for this week.'**
  String get clubsEmptyDiscoverMessage;

  /// Clubs screen: button that switches to the Discover segment.
  ///
  /// In en, this message translates to:
  /// **'Discover clubs'**
  String get clubsDiscoverClubs;

  /// Clubs: how many members a club has.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 member} other{{count} members}}'**
  String clubsMemberCount(int count);

  /// Clubs: pill on a club card when the member owns the club.
  ///
  /// In en, this message translates to:
  /// **'You run it'**
  String get clubsYouRunIt;

  /// Clubs: pill on a club card when the member moderates the club.
  ///
  /// In en, this message translates to:
  /// **'You moderate'**
  String get clubsYouModerate;

  /// Clubs: pill on a club card when the member has joined it. Keep the check mark.
  ///
  /// In en, this message translates to:
  /// **'Joined ✓'**
  String get clubsJoined;

  /// Clubs: club card text when the club has no pick for this week.
  ///
  /// In en, this message translates to:
  /// **'No pick yet this week'**
  String get clubsNoPickThisWeek;

  /// Start a club sheet: validation error for a too-short club name.
  ///
  /// In en, this message translates to:
  /// **'Give your club a name of at least 3 letters.'**
  String get clubsNameTooShort;

  /// Start a club sheet: fallback error when creating fails.
  ///
  /// In en, this message translates to:
  /// **'Your club could not be created.'**
  String get clubsCreateFailed;

  /// Start a club sheet: label of the club name field.
  ///
  /// In en, this message translates to:
  /// **'Club name'**
  String get clubsNameLabel;

  /// Start a club sheet: example club name shown as a hint.
  ///
  /// In en, this message translates to:
  /// **'Sunday Slow Reads'**
  String get clubsNameHint;

  /// Start a club sheet: label of the optional description field.
  ///
  /// In en, this message translates to:
  /// **'What is your club about? (optional)'**
  String get clubsDescriptionLabel;

  /// Start a club sheet: button label while the club is being created.
  ///
  /// In en, this message translates to:
  /// **'Creating…'**
  String get clubsCreating;

  /// Start a club sheet: submit button.
  ///
  /// In en, this message translates to:
  /// **'Create club'**
  String get clubsCreateClub;

  /// Club detail: confirm dialog title for leaving a club. {name} is the club name.
  ///
  /// In en, this message translates to:
  /// **'Leave {name}?'**
  String clubsLeaveTitle(String name);

  /// Club detail: confirm dialog body for leaving a club.
  ///
  /// In en, this message translates to:
  /// **'You can rejoin later while the club is open.'**
  String get clubsLeaveMessage;

  /// Club detail: button and confirm action for leaving a club.
  ///
  /// In en, this message translates to:
  /// **'Leave club'**
  String get clubsLeaveClub;

  /// Club detail: snackbar after joining a club. {name} is the club name.
  ///
  /// In en, this message translates to:
  /// **'Welcome to {name}!'**
  String clubsWelcome(String name);

  /// Clubs: fallback error when joining, leaving or changing a member's role fails.
  ///
  /// In en, this message translates to:
  /// **'That change could not be saved.'**
  String get clubsChangeNotSaved;

  /// Club detail: tooltip of the overflow menu.
  ///
  /// In en, this message translates to:
  /// **'Club options'**
  String get clubsOptionsTooltip;

  /// Clubs: menu item, button and sheet title for the club's member list.
  ///
  /// In en, this message translates to:
  /// **'Members'**
  String get clubsMembers;

  /// Club detail: menu item to report a club.
  ///
  /// In en, this message translates to:
  /// **'Report club'**
  String get clubsReportClub;

  /// Club detail: title of the notice when the club fails to load.
  ///
  /// In en, this message translates to:
  /// **'This club could not load'**
  String get clubsDetailLoadErrorTitle;

  /// Club detail: fallback message when the club fails to load.
  ///
  /// In en, this message translates to:
  /// **'It may have closed. Please try again.'**
  String get clubsDetailLoadErrorMessage;

  /// Club detail: heading above the club's earlier weekly picks.
  ///
  /// In en, this message translates to:
  /// **'Earlier picks'**
  String get clubsEarlierPicks;

  /// Club detail: subtitle of an earlier pick, e.g. 'Last week · 3 posts'. {week} is a week label.
  ///
  /// In en, this message translates to:
  /// **'{week} · {count, plural, =1{1 post} other{{count} posts}}'**
  String clubsPickSubtitle(String week, int count);

  /// Club detail: tooltip of the button that opens an earlier pick's discussion.
  ///
  /// In en, this message translates to:
  /// **'Open the discussion'**
  String get clubsOpenDiscussion;

  /// Club detail: notice title for non-members instead of the discussion.
  ///
  /// In en, this message translates to:
  /// **'Join to see the discussion'**
  String get clubsJoinToSeeTitle;

  /// Club detail: notice message for non-members instead of the discussion.
  ///
  /// In en, this message translates to:
  /// **'Members talk about each pick together. Join the club to read along and add your thoughts.'**
  String get clubsJoinToSeeMessage;

  /// Club detail: pill with the member's own role, e.g. 'You: Owner'.
  ///
  /// In en, this message translates to:
  /// **'You: {role}'**
  String clubsYouRole(String role);

  /// Club detail: warning when moderators removed the club.
  ///
  /// In en, this message translates to:
  /// **'This club was removed by moderation.'**
  String get clubsRemovedByModeration;

  /// Club detail: button to join a club.
  ///
  /// In en, this message translates to:
  /// **'Join club'**
  String get clubsJoinClub;

  /// Club detail: this week's card when there is no pick and the viewer can set one.
  ///
  /// In en, this message translates to:
  /// **'No pick yet. Choose something great for everyone.'**
  String get clubsNoPickModerator;

  /// Club detail: this week's card when there is no pick and the viewer cannot set one.
  ///
  /// In en, this message translates to:
  /// **'No pick yet. Check back soon.'**
  String get clubsNoPickMember;

  /// Clubs: a member's note shown in quotation marks. Use the language's quotation marks.
  ///
  /// In en, this message translates to:
  /// **'“{note}”'**
  String clubsQuotedNote(String note);

  /// Club detail: how many posts this week's pick has in its discussion.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 post in the discussion} other{{count} posts in the discussion}}'**
  String clubsPostsInDiscussion(int count);

  /// Club detail: button for owners and moderators to set this week's pick.
  ///
  /// In en, this message translates to:
  /// **'Set this week’s pick'**
  String get clubsSetThisWeeksPick;

  /// Club detail: button that shows this week's discussion.
  ///
  /// In en, this message translates to:
  /// **'Discuss this pick'**
  String get clubsDiscussThisPick;

  /// Club discussion: fallback error when a post fails to send.
  ///
  /// In en, this message translates to:
  /// **'Your post could not be sent.'**
  String get clubsPostNotSent;

  /// Club discussion: heading, e.g. 'Discussion · Piranesi'. {title} is the book or film title.
  ///
  /// In en, this message translates to:
  /// **'Discussion · {title}'**
  String clubsDiscussionHeading(String title);

  /// Club discussion: notice title when posts fail to load.
  ///
  /// In en, this message translates to:
  /// **'The discussion could not load'**
  String get clubsDiscussionLoadError;

  /// Club discussion: empty state title.
  ///
  /// In en, this message translates to:
  /// **'Start the conversation'**
  String get clubsStartConversationTitle;

  /// Club discussion: empty state message.
  ///
  /// In en, this message translates to:
  /// **'What did you think so far? Your post could be the one that gets everyone talking.'**
  String get clubsStartConversationMessage;

  /// Club discussion: button that loads older posts.
  ///
  /// In en, this message translates to:
  /// **'Load more posts'**
  String get clubsLoadMorePosts;

  /// Club discussion: label of the post composer.
  ///
  /// In en, this message translates to:
  /// **'Add to the discussion'**
  String get clubsComposerLabel;

  /// Club discussion: hint in the post composer.
  ///
  /// In en, this message translates to:
  /// **'Favourite moment? Biggest surprise?'**
  String get clubsComposerHint;

  /// Clubs: switch marking a post or review as containing spoilers.
  ///
  /// In en, this message translates to:
  /// **'Contains spoilers'**
  String get clubsContainsSpoilers;

  /// Club discussion: explains what marking a post as a spoiler does.
  ///
  /// In en, this message translates to:
  /// **'Others tap to reveal it.'**
  String get clubsSpoilersSubtitle;

  /// Club discussion: send button label while posting.
  ///
  /// In en, this message translates to:
  /// **'Posting…'**
  String get clubsPosting;

  /// Club discussion: send button label.
  ///
  /// In en, this message translates to:
  /// **'Post'**
  String get clubsPost;

  /// Club discussion: confirm dialog title for deleting your own post.
  ///
  /// In en, this message translates to:
  /// **'Delete your post?'**
  String get clubsDeletePostTitle;

  /// Club discussion: confirm dialog body for deleting your own post.
  ///
  /// In en, this message translates to:
  /// **'It is removed from the discussion for everyone.'**
  String get clubsDeletePostMessage;

  /// Club discussion: fallback error when deleting, hiding or reporting a post fails.
  ///
  /// In en, this message translates to:
  /// **'That action could not be completed.'**
  String get clubsActionFailed;

  /// Club discussion: moderator action that hides a post from members.
  ///
  /// In en, this message translates to:
  /// **'Hide from members'**
  String get clubsHideFromMembers;

  /// Club discussion: moderator action that shows a hidden post again.
  ///
  /// In en, this message translates to:
  /// **'Show to members'**
  String get clubsShowToMembers;

  /// Club discussion: action to report someone else's post.
  ///
  /// In en, this message translates to:
  /// **'Report'**
  String get clubsReport;

  /// Club discussion: author name shown on the member's own posts.
  ///
  /// In en, this message translates to:
  /// **'You'**
  String get clubsYou;

  /// Club discussion: pill on a post hidden by moderators.
  ///
  /// In en, this message translates to:
  /// **'Hidden'**
  String get clubsHidden;

  /// Club discussion: tooltip of a post's overflow menu.
  ///
  /// In en, this message translates to:
  /// **'Post actions'**
  String get clubsPostActions;

  /// Club members sheet: owner action that promotes a member.
  ///
  /// In en, this message translates to:
  /// **'Make moderator'**
  String get clubsMakeModerator;

  /// Club members sheet: owner action that demotes a moderator to member.
  ///
  /// In en, this message translates to:
  /// **'Make member'**
  String get clubsMakeMember;

  /// Club members sheet: action that removes a member from the club.
  ///
  /// In en, this message translates to:
  /// **'Remove from club'**
  String get clubsRemoveFromClub;

  /// Club members sheet: confirm dialog title for removing a member. {name} is the member's name.
  ///
  /// In en, this message translates to:
  /// **'Remove {name}?'**
  String clubsRemoveMemberTitle(String name);

  /// Club members sheet: confirm dialog body for removing a member.
  ///
  /// In en, this message translates to:
  /// **'They leave the club and cannot rejoin. Their past posts stay in the discussion.'**
  String get clubsRemoveMemberMessage;

  /// Club members sheet: confirm action for removing a member.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get clubsRemove;

  /// Club members sheet: fallback error when the member list fails to load.
  ///
  /// In en, this message translates to:
  /// **'Members could not load.'**
  String get clubsMembersLoadError;

  /// Club members sheet: the viewer's own row, e.g. 'Priya (you)'.
  ///
  /// In en, this message translates to:
  /// **'{name} (you)'**
  String clubsMemberYou(String name);

  /// Club members sheet: tooltip of a member's action menu.
  ///
  /// In en, this message translates to:
  /// **'Actions for {name}'**
  String clubsMemberActions(String name);

  /// Set the weekly pick sheet: button and picker heading for film clubs.
  ///
  /// In en, this message translates to:
  /// **'Choose a film'**
  String get clubsChooseFilm;

  /// Set the weekly pick sheet: button and picker heading for book clubs.
  ///
  /// In en, this message translates to:
  /// **'Choose a book'**
  String get clubsChooseBook;

  /// Title picker: default heading.
  ///
  /// In en, this message translates to:
  /// **'Choose a title'**
  String get clubsChooseTitle;

  /// Set the weekly pick sheet: validation error when no title is chosen.
  ///
  /// In en, this message translates to:
  /// **'Choose a title first.'**
  String get clubsChooseTitleFirst;

  /// Set the weekly pick sheet: fallback error when saving fails.
  ///
  /// In en, this message translates to:
  /// **'The pick could not be saved.'**
  String get clubsPickNotSaved;

  /// Set the weekly pick sheet: title.
  ///
  /// In en, this message translates to:
  /// **'Set the weekly pick'**
  String get clubsSetWeeklyPick;

  /// Set the weekly pick sheet: button to choose a different title.
  ///
  /// In en, this message translates to:
  /// **'Change'**
  String get clubsChange;

  /// Set the weekly pick sheet: label of the optional note field.
  ///
  /// In en, this message translates to:
  /// **'A note for the club (optional)'**
  String get clubsPickNoteLabel;

  /// Set the weekly pick sheet: hint of the note field.
  ///
  /// In en, this message translates to:
  /// **'Why this one? Where to start?'**
  String get clubsPickNoteHint;

  /// Clubs: save button label while saving.
  ///
  /// In en, this message translates to:
  /// **'Saving…'**
  String get clubsSaving;

  /// Set the weekly pick sheet: submit button.
  ///
  /// In en, this message translates to:
  /// **'Save pick'**
  String get clubsSavePick;

  /// List editor: validation error when the list has no name.
  ///
  /// In en, this message translates to:
  /// **'Give your list a name.'**
  String get clubsListNameRequired;

  /// List editor: fallback error when saving fails.
  ///
  /// In en, this message translates to:
  /// **'Your list could not be saved.'**
  String get clubsListNotSaved;

  /// Clubs: list editor title and list menu item.
  ///
  /// In en, this message translates to:
  /// **'Edit list'**
  String get clubsEditList;

  /// Clubs: list editor title and buttons that create a list.
  ///
  /// In en, this message translates to:
  /// **'New list'**
  String get clubsNewList;

  /// List editor: label of the list name field.
  ///
  /// In en, this message translates to:
  /// **'List name'**
  String get clubsListNameLabel;

  /// List editor: example list name shown as a hint.
  ///
  /// In en, this message translates to:
  /// **'Books that changed my mind'**
  String get clubsListNameHint;

  /// Clubs: heading above the visibility choices for a list or review.
  ///
  /// In en, this message translates to:
  /// **'Who can see it'**
  String get clubsWhoCanSee;

  /// List editor: save button when renaming an existing list.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get clubsSave;

  /// List editor: submit button for a new list.
  ///
  /// In en, this message translates to:
  /// **'Create list'**
  String get clubsCreateList;

  /// List note dialog: title.
  ///
  /// In en, this message translates to:
  /// **'Your note'**
  String get clubsYourNote;

  /// List note dialog: label of the note field.
  ///
  /// In en, this message translates to:
  /// **'Why it is on this list'**
  String get clubsNoteLabel;

  /// List note dialog: save button.
  ///
  /// In en, this message translates to:
  /// **'Save note'**
  String get clubsSaveNote;

  /// My lists: tooltip of the floating button that creates a list.
  ///
  /// In en, this message translates to:
  /// **'Create a new list'**
  String get clubsCreateNewListTooltip;

  /// My lists: shown when the member is signed out.
  ///
  /// In en, this message translates to:
  /// **'Sign in to see your lists.'**
  String get clubsSignInToSeeLists;

  /// My lists: headline of the intro card.
  ///
  /// In en, this message translates to:
  /// **'Your shelf'**
  String get clubsShelfTitle;

  /// My lists: body of the intro card.
  ///
  /// In en, this message translates to:
  /// **'Keep track of what you loved and what is next. Share a list, or keep it just for you.'**
  String get clubsShelfSubtitle;

  /// My lists: notice title when lists fail to load.
  ///
  /// In en, this message translates to:
  /// **'Your lists could not load'**
  String get clubsListsLoadErrorTitle;

  /// My lists: empty state title.
  ///
  /// In en, this message translates to:
  /// **'Start your first list'**
  String get clubsFirstListTitle;

  /// My lists: empty state message.
  ///
  /// In en, this message translates to:
  /// **'Favourite films, books to read next, comfort rewatches: it is up to you.'**
  String get clubsFirstListMessage;

  /// My lists: title picker heading when adding to a list. {name} is the list name.
  ///
  /// In en, this message translates to:
  /// **'Add to {name}'**
  String clubsAddToNamed(String name);

  /// My lists: fallback error when adding a title fails.
  ///
  /// In en, this message translates to:
  /// **'It could not be added to this list.'**
  String get clubsAddToThisListFailed;

  /// My lists: confirm dialog title for deleting a list. {name} is the list name.
  ///
  /// In en, this message translates to:
  /// **'Delete {name}?'**
  String clubsDeleteListTitle(String name);

  /// My lists: confirm dialog body for deleting a list.
  ///
  /// In en, this message translates to:
  /// **'The list and its notes are removed. This cannot be undone.'**
  String get clubsDeleteListMessage;

  /// My lists: menu item and confirm action for deleting a list.
  ///
  /// In en, this message translates to:
  /// **'Delete list'**
  String get clubsDeleteList;

  /// My lists: fallback error when deleting a list fails.
  ///
  /// In en, this message translates to:
  /// **'The list could not be deleted. Reload and retry.'**
  String get clubsListDeleteFailed;

  /// My lists: fallback error when saving a note fails.
  ///
  /// In en, this message translates to:
  /// **'Your note could not be saved.'**
  String get clubsNoteNotSaved;

  /// My lists: fallback error when removing a title from a list fails.
  ///
  /// In en, this message translates to:
  /// **'It could not be removed.'**
  String get clubsRemoveFailed;

  /// My lists: tooltip of a list's overflow menu.
  ///
  /// In en, this message translates to:
  /// **'List options'**
  String get clubsListOptions;

  /// My lists: menu item that adds a book or film to a list.
  ///
  /// In en, this message translates to:
  /// **'Add a title'**
  String get clubsAddATitle;

  /// Clubs: how many books or films a list holds.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 title} other{{count} titles}}'**
  String clubsTitleCount(int count);

  /// My lists: text on an empty list. The quoted text must match the clubsAddATitle menu item.
  ///
  /// In en, this message translates to:
  /// **'Nothing here yet. Use “Add a title” from the list menu.'**
  String get clubsListEmpty;

  /// My lists: tooltip of a title's menu in a list. {title} is the book or film title.
  ///
  /// In en, this message translates to:
  /// **'Options for {title}'**
  String clubsItemOptions(String title);

  /// My lists: menu item to add a note to a title in a list.
  ///
  /// In en, this message translates to:
  /// **'Add a note'**
  String get clubsAddNote;

  /// My lists: menu item to edit a title's note in a list.
  ///
  /// In en, this message translates to:
  /// **'Edit note'**
  String get clubsEditNote;

  /// My lists: menu item to remove a title from a list.
  ///
  /// In en, this message translates to:
  /// **'Remove from list'**
  String get clubsRemoveFromList;

  /// Review sheet: validation error when no star is chosen.
  ///
  /// In en, this message translates to:
  /// **'Tap a star to rate it.'**
  String get clubsTapStarError;

  /// Review sheet: fallback error when saving fails.
  ///
  /// In en, this message translates to:
  /// **'Your review could not be saved.'**
  String get clubsReviewNotSaved;

  /// Clubs: review sheet title and button for a new review.
  ///
  /// In en, this message translates to:
  /// **'Write a review'**
  String get clubsWriteReview;

  /// Review sheet: title when editing an existing review.
  ///
  /// In en, this message translates to:
  /// **'Edit your review'**
  String get clubsEditYourReview;

  /// Review sheet: hint under the stars before a rating is chosen.
  ///
  /// In en, this message translates to:
  /// **'Tap a star to rate'**
  String get clubsTapStarToRate;

  /// Review sheet: the chosen rating, e.g. '4 out of 5'.
  ///
  /// In en, this message translates to:
  /// **'{rating} out of 5'**
  String clubsRatingOutOfFive(int rating);

  /// Review sheet: label of the optional review text.
  ///
  /// In en, this message translates to:
  /// **'What did you think? (optional)'**
  String get clubsReviewBodyLabel;

  /// Review sheet: submit button.
  ///
  /// In en, this message translates to:
  /// **'Save review'**
  String get clubsSaveReview;

  /// Add to a list sheet: snackbar after adding a title. {name} is the list name.
  ///
  /// In en, this message translates to:
  /// **'Added to {name}.'**
  String clubsAddedToList(String name);

  /// Add to a list sheet: fallback error when adding fails.
  ///
  /// In en, this message translates to:
  /// **'It could not be added to that list.'**
  String get clubsAddToThatListFailed;

  /// Clubs: button and sheet title for adding a title to one of the member's lists.
  ///
  /// In en, this message translates to:
  /// **'Add to a list'**
  String get clubsAddToAList;

  /// Add to a list sheet: fallback error when the member's lists fail to load.
  ///
  /// In en, this message translates to:
  /// **'Your lists could not load.'**
  String get clubsListsLoadError;

  /// Add to a list sheet: shown when the member has no film lists.
  ///
  /// In en, this message translates to:
  /// **'You have no film lists yet. Create one to start collecting.'**
  String get clubsNoFilmLists;

  /// Add to a list sheet: shown when the member has no book lists.
  ///
  /// In en, this message translates to:
  /// **'You have no book lists yet. Create one to start collecting.'**
  String get clubsNoBookLists;

  /// Title detail: app bar title while the book or film loads.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get clubsTitleFallback;

  /// Title detail: shown when the member is signed out.
  ///
  /// In en, this message translates to:
  /// **'Sign in to see reviews.'**
  String get clubsSignInToSeeReviews;

  /// Title detail: notice title when the book or film fails to load.
  ///
  /// In en, this message translates to:
  /// **'This title could not load'**
  String get clubsTitleLoadError;

  /// Title detail: heading above other members' reviews.
  ///
  /// In en, this message translates to:
  /// **'Reviews'**
  String get clubsReviews;

  /// Title detail: empty state title when nobody else reviewed the title.
  ///
  /// In en, this message translates to:
  /// **'No other reviews yet'**
  String get clubsNoOtherReviewsTitle;

  /// Title detail: empty state message when nobody else reviewed the title.
  ///
  /// In en, this message translates to:
  /// **'When members you can see share a review, it shows up here.'**
  String get clubsNoOtherReviewsMessage;

  /// Title detail: confirm dialog title for deleting your review.
  ///
  /// In en, this message translates to:
  /// **'Delete your review?'**
  String get clubsDeleteReviewTitle;

  /// Title detail: confirm dialog body for deleting your review.
  ///
  /// In en, this message translates to:
  /// **'Your rating and words are removed for everyone.'**
  String get clubsDeleteReviewMessage;

  /// Title detail: confirm action for deleting your review.
  ///
  /// In en, this message translates to:
  /// **'Delete review'**
  String get clubsDeleteReview;

  /// Title detail: fallback error when deleting your review fails.
  ///
  /// In en, this message translates to:
  /// **'Your review could not be deleted. Reload and retry.'**
  String get clubsReviewDeleteFailed;

  /// Title detail: heading of the card inviting the member to review.
  ///
  /// In en, this message translates to:
  /// **'What did you think?'**
  String get clubsWhatDidYouThink;

  /// Title detail: body of the card inviting the member to review.
  ///
  /// In en, this message translates to:
  /// **'Rate it and say why. You choose who sees it.'**
  String get clubsReviewPrompt;

  /// Title detail: heading of the member's own review.
  ///
  /// In en, this message translates to:
  /// **'Your review'**
  String get clubsYourReview;

  /// Title detail: pill on a review that contains spoilers.
  ///
  /// In en, this message translates to:
  /// **'Spoilers'**
  String get clubsSpoilers;

  /// Title detail: button to edit your review.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get clubsEdit;

  /// Title detail: tooltip of the button that reports another member's review.
  ///
  /// In en, this message translates to:
  /// **'Report this review'**
  String get clubsReportReview;

  /// Title picker: validation error when the new title's name is empty.
  ///
  /// In en, this message translates to:
  /// **'Enter the title.'**
  String get clubsEnterTitle;

  /// Title picker: validation error for an out-of-range release year.
  ///
  /// In en, this message translates to:
  /// **'Enter a year between 1450 and 2100.'**
  String get clubsYearRange;

  /// Title picker: fallback error when adding a new title fails.
  ///
  /// In en, this message translates to:
  /// **'The title could not be added.'**
  String get clubsTitleAddFailed;

  /// Title picker: label of the search field for films.
  ///
  /// In en, this message translates to:
  /// **'Search films'**
  String get clubsSearchFilms;

  /// Title picker: label of the search field for books.
  ///
  /// In en, this message translates to:
  /// **'Search books'**
  String get clubsSearchBooks;

  /// Title picker: helper text under the search field.
  ///
  /// In en, this message translates to:
  /// **'Type at least 2 letters'**
  String get clubsTypeTwoLetters;

  /// Title picker: fallback error when search fails.
  ///
  /// In en, this message translates to:
  /// **'Search is unavailable.'**
  String get clubsSearchUnavailable;

  /// Title picker: no film matched the search.
  ///
  /// In en, this message translates to:
  /// **'No films match. Add it below.'**
  String get clubsNoFilmsMatch;

  /// Title picker: no book matched the search.
  ///
  /// In en, this message translates to:
  /// **'No books match. Add it below.'**
  String get clubsNoBooksMatch;

  /// Title picker: button and heading for adding a film to the catalogue.
  ///
  /// In en, this message translates to:
  /// **'Add a new film'**
  String get clubsAddNewFilm;

  /// Title picker: button and heading for adding a book to the catalogue.
  ///
  /// In en, this message translates to:
  /// **'Add a new book'**
  String get clubsAddNewBook;

  /// Title picker: label of the new title's name field.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get clubsTitleFieldLabel;

  /// Title picker: label of the creator field for a film.
  ///
  /// In en, this message translates to:
  /// **'Director'**
  String get clubsDirector;

  /// Title picker: label of the creator field for a book.
  ///
  /// In en, this message translates to:
  /// **'Author'**
  String get clubsAuthor;

  /// Title picker: label of the optional release year field.
  ///
  /// In en, this message translates to:
  /// **'Year (optional)'**
  String get clubsYearOptional;

  /// Title picker: submit button label while adding.
  ///
  /// In en, this message translates to:
  /// **'Adding…'**
  String get clubsAdding;

  /// Title picker: submit button that adds a new title and chooses it.
  ///
  /// In en, this message translates to:
  /// **'Add and choose'**
  String get clubsAddAndChoose;

  /// Introducers: error when a permission change could not be saved and the server gave no reason.
  ///
  /// In en, this message translates to:
  /// **'We couldn’t save that. Refresh to check the latest permissions before trying again.'**
  String get friendsIntroducerSaveFailed;

  /// Introducers: confirm dialog title for removing someone's permission to introduce.
  ///
  /// In en, this message translates to:
  /// **'Remove permission for {name}?'**
  String friendsIntroducerRevokeTitle(String name);

  /// Introducers: confirm dialog body for removing permission.
  ///
  /// In en, this message translates to:
  /// **'New and unanswered introductions will stop. An existing mutual match stays between the two people.'**
  String get friendsIntroducerRevokeBody;

  /// Introducers: keep the permission (dialog cancel button).
  ///
  /// In en, this message translates to:
  /// **'Keep permission'**
  String get friendsIntroducerKeepPermission;

  /// Introducers: remove someone's permission to introduce (button and dialog confirm).
  ///
  /// In en, this message translates to:
  /// **'Remove permission'**
  String get friendsIntroducerRemovePermission;

  /// Introducers: notice after removing permission.
  ///
  /// In en, this message translates to:
  /// **'Permission removed.'**
  String get friendsIntroducerPermissionRemoved;

  /// Introducers screen (dating member): app bar title.
  ///
  /// In en, this message translates to:
  /// **'Your introducers'**
  String get friendsIntroducerMemberTitle;

  /// Introducer-only workspace: app bar title. Keep the brand name Connect.
  ///
  /// In en, this message translates to:
  /// **'Connect · Friends'**
  String get friendsIntroducerAppTitle;

  /// Introducers: tooltip of the refresh button.
  ///
  /// In en, this message translates to:
  /// **'Refresh permissions'**
  String get friendsIntroducerRefresh;

  /// Introducer-only workspace: tooltip of the account menu.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get friendsIntroducerAccount;

  /// Introducer-only workspace: account menu item for account and privacy.
  ///
  /// In en, this message translates to:
  /// **'Account & privacy'**
  String get friendsIntroducerAccountPrivacy;

  /// Introducer-only workspace: account menu item to sign out.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get friendsIntroducerSignOut;

  /// Introducers screen (dating member): hero headline.
  ///
  /// In en, this message translates to:
  /// **'Good friends. Your say.'**
  String get friendsIntroducerMemberHeadline;

  /// Introducer-only workspace: hero headline. Keep the line break.
  ///
  /// In en, this message translates to:
  /// **'You know them.\nYou see the possibility.'**
  String get friendsIntroducerHeadline;

  /// Introducers screen (dating member): hero explanation.
  ///
  /// In en, this message translates to:
  /// **'Invite someone you trust to introduce you. They can join without a dating profile. You decide who gets permission and what a preview shares.'**
  String get friendsIntroducerMemberIntro;

  /// Introducer-only workspace: hero explanation.
  ///
  /// In en, this message translates to:
  /// **'A little thoughtfulness can start something real. Bring together friends who have asked for your help.'**
  String get friendsIntroducerIntro;

  /// Introducers screen (dating member): title above the people I gave permission to.
  ///
  /// In en, this message translates to:
  /// **'People you choose'**
  String get friendsIntroducerMemberListTitle;

  /// Introducer-only workspace: title above the friends who gave me permission.
  ///
  /// In en, this message translates to:
  /// **'Your small circle'**
  String get friendsIntroducerListTitle;

  /// Introducers: shown when permissions could not be loaded.
  ///
  /// In en, this message translates to:
  /// **'We couldn’t load permissions. Nothing has been changed.'**
  String get friendsIntroducerLoadFailed;

  /// Introducers screen (dating member): no introducers yet.
  ///
  /// In en, this message translates to:
  /// **'No introducers yet. Share an invitation with one trusted friend to get started.'**
  String get friendsIntroducerMemberEmpty;

  /// Introducer-only workspace: no friends have given permission yet. Keep the brand name Connect.
  ///
  /// In en, this message translates to:
  /// **'Your circle starts with permission. Ask a friend on Connect for their invitation code.'**
  String get friendsIntroducerEmpty;

  /// Introducers screen (dating member): an introducer is waiting for my permission.
  ///
  /// In en, this message translates to:
  /// **'Wants your permission to introduce you.'**
  String get friendsIntroducerStatusPendingMember;

  /// Introducer-only workspace: waiting for my friend to approve me.
  ///
  /// In en, this message translates to:
  /// **'Waiting for your friend’s approval.'**
  String get friendsIntroducerStatusPending;

  /// Introducers: introductions are paused for this connection.
  ///
  /// In en, this message translates to:
  /// **'Introductions are paused.'**
  String get friendsIntroducerStatusPaused;

  /// Introducers: this connection has permission to suggest introductions.
  ///
  /// In en, this message translates to:
  /// **'Permission to suggest introductions.'**
  String get friendsIntroducerStatusActive;

  /// Introducers screen (dating member): what a suggested date sees. {extras} is 'photo', 'city', 'both' or 'none'.
  ///
  /// In en, this message translates to:
  /// **'{extras, select, photo{Preview shared with a suggested date: name and optional age, photo.} city{Preview shared with a suggested date: name and optional age, city.} both{Preview shared with a suggested date: name and optional age, photo, city.} other{Preview shared with a suggested date: name and optional age.}}'**
  String friendsIntroducerPreview(String extras);

  /// Introducers screen (dating member): note under a pending request. 'Dating rhythm' is the name of the settings screen.
  ///
  /// In en, this message translates to:
  /// **'Approving also turns on friend introductions. You can pause all introductions in Dating rhythm.'**
  String get friendsIntroducerApproveNote;

  /// Introducers screen (dating member): approve an introducer's request.
  ///
  /// In en, this message translates to:
  /// **'Allow introductions'**
  String get friendsIntroducerAllow;

  /// Introducers screen (dating member): notice after approving an introducer.
  ///
  /// In en, this message translates to:
  /// **'{name} now has your permission.'**
  String friendsIntroducerAllowed(String name);

  /// Introducers screen (dating member): decline a pending introducer request.
  ///
  /// In en, this message translates to:
  /// **'Decline request'**
  String get friendsIntroducerDecline;

  /// Introducer-only workspace: title above introductions I sent.
  ///
  /// In en, this message translates to:
  /// **'Thoughtfully sent'**
  String get friendsIntroducerSentTitle;

  /// Introducer-only workspace: explanation above introductions I sent.
  ///
  /// In en, this message translates to:
  /// **'Their answers stay between them. Both people must say yes before a match is made.'**
  String get friendsIntroducerSentBody;

  /// Introducer-only workspace: retry loading introductions I sent.
  ///
  /// In en, this message translates to:
  /// **'Reload sent introductions'**
  String get friendsIntroducerReloadSent;

  /// Introducer-only workspace: subtitle of an introduction I sent.
  ///
  /// In en, this message translates to:
  /// **'Sent · their decision is private'**
  String get friendsIntroducerSentSubtitle;

  /// Introducers screen (dating member): step 1 heading.
  ///
  /// In en, this message translates to:
  /// **'1. Choose the preview'**
  String get friendsIntroducerStepPreview;

  /// Introducers screen (dating member): explains what is shared in step 1.
  ///
  /// In en, this message translates to:
  /// **'A suggested date sees your name and age if you already show it. Your introducer sees only your name, never your profile or dating activity.'**
  String get friendsIntroducerPreviewBody;

  /// Introducers screen (dating member): switch to include my profile photo in the preview.
  ///
  /// In en, this message translates to:
  /// **'Include my profile photo'**
  String get friendsIntroducerIncludePhoto;

  /// Introducers screen (dating member): switch to include my city in the preview.
  ///
  /// In en, this message translates to:
  /// **'Include my city'**
  String get friendsIntroducerIncludeCity;

  /// Introducers screen (dating member): step 2 heading.
  ///
  /// In en, this message translates to:
  /// **'2. Invite one trusted friend'**
  String get friendsIntroducerStepInvite;

  /// Introducers screen (dating member): how the invitation code works. The quoted label is the welcome screen button for introducers.
  ///
  /// In en, this message translates to:
  /// **'The code works once and expires in 48 hours. Your friend joins through “Just here to introduce friends” on the welcome screen. You’ll approve their name here before anything can be shared.'**
  String get friendsIntroducerInviteBody;

  /// Introducers screen (dating member): notice after creating an invitation code.
  ///
  /// In en, this message translates to:
  /// **'Invitation ready. Any previous unused code no longer works.'**
  String get friendsIntroducerInviteReady;

  /// Introducers screen (dating member): create an invitation code.
  ///
  /// In en, this message translates to:
  /// **'Create invitation code'**
  String get friendsIntroducerCreateCode;

  /// Introducers screen (dating member): note above a created invitation code.
  ///
  /// In en, this message translates to:
  /// **'Share privately with your friend. To change this preview, cancel the unused invitation and create a new code.'**
  String get friendsIntroducerShareCode;

  /// Introducers screen (dating member): snackbar after copying the invitation code.
  ///
  /// In en, this message translates to:
  /// **'Invitation code copied'**
  String get friendsIntroducerCodeCopied;

  /// Introducers screen (dating member): copy the invitation code.
  ///
  /// In en, this message translates to:
  /// **'Copy code'**
  String get friendsIntroducerCopyCode;

  /// Introducers screen (dating member): notice after cancelling unused invitations.
  ///
  /// In en, this message translates to:
  /// **'Unused invitations cancelled.'**
  String get friendsIntroducerInvitesCancelled;

  /// Introducers screen (dating member): cancel unused invitations.
  ///
  /// In en, this message translates to:
  /// **'Cancel unused invitations'**
  String get friendsIntroducerCancelInvites;

  /// Introducers screen (dating member): open introduction preferences.
  ///
  /// In en, this message translates to:
  /// **'Manage all introduction preferences'**
  String get friendsIntroducerManagePrefs;

  /// Introducer-only workspace: heading above the invitation code field.
  ///
  /// In en, this message translates to:
  /// **'A friend invited you?'**
  String get friendsIntroducerRedeemTitle;

  /// Introducer-only workspace: explains the invitation code field.
  ///
  /// In en, this message translates to:
  /// **'Paste their private invitation code. They’ll confirm your name before you can introduce them.'**
  String get friendsIntroducerRedeemBody;

  /// Introducer-only workspace: invitation code field label.
  ///
  /// In en, this message translates to:
  /// **'Invitation code'**
  String get friendsIntroducerCodeLabel;

  /// Introducer-only workspace: error when the invitation code field is empty.
  ///
  /// In en, this message translates to:
  /// **'Enter the invitation code your friend shared.'**
  String get friendsIntroducerCodeMissing;

  /// Introducer-only workspace: notice after asking a friend for permission. 'Your introducers' is the name of the friend's screen.
  ///
  /// In en, this message translates to:
  /// **'Request sent. Your friend can now approve you in Your introducers.'**
  String get friendsIntroducerRequestSent;

  /// Introducer-only workspace: submit the invitation code.
  ///
  /// In en, this message translates to:
  /// **'Ask for permission'**
  String get friendsIntroducerAskPermission;

  /// Introducer-only workspace: shown until two friends have given permission.
  ///
  /// In en, this message translates to:
  /// **'Once two friends give permission, you can suggest an introduction here.'**
  String get friendsIntroducerNeedTwo;

  /// Introducer-only workspace: heading of the introduction composer.
  ///
  /// In en, this message translates to:
  /// **'See a possibility?'**
  String get friendsIntroducerComposerTitle;

  /// Introducer-only workspace: optional note field label.
  ///
  /// In en, this message translates to:
  /// **'Why you thought of them (optional)'**
  String get friendsIntroducerWhyLabel;

  /// Introducer-only workspace: helper text under the note field.
  ///
  /// In en, this message translates to:
  /// **'Both will see this. Keep private details out.'**
  String get friendsIntroducerWhyHelper;

  /// Introducer-only workspace: notice after suggesting an introduction.
  ///
  /// In en, this message translates to:
  /// **'Introduction sent. They can each decide in private.'**
  String get friendsIntroducerIntroSent;

  /// Introducer-only workspace: submit button of the introduction composer.
  ///
  /// In en, this message translates to:
  /// **'Suggest an introduction'**
  String get friendsIntroducerSuggest;

  /// Introducers: privacy note near the top of the screen.
  ///
  /// In en, this message translates to:
  /// **'Permission first. No public dating activity. No updates on who said yes or no.'**
  String get friendsIntroducerPrivacyNote;

  /// Plan sharing sheet: fallback error when the contact choices fail to load.
  ///
  /// In en, this message translates to:
  /// **'Unable to load sharing choices.'**
  String get planSharingLoadFailed;

  /// Plan sharing sheet: snackbar after saving with no contacts selected.
  ///
  /// In en, this message translates to:
  /// **'Your contact sharing is off.'**
  String get planSharingOffSnack;

  /// Plan sharing sheet: snackbar after sharing the plan with selected contacts.
  ///
  /// In en, this message translates to:
  /// **'Your selected contacts can now see this plan.'**
  String get planSharingSavedSnack;

  /// Plan sharing sheet: fallback error when saving the sharing choices fails.
  ///
  /// In en, this message translates to:
  /// **'Unable to save. Reload choices before trying again.'**
  String get planSharingSaveFailed;

  /// Plan sharing sheet: title.
  ///
  /// In en, this message translates to:
  /// **'Your plan. Your people.'**
  String get planSharingTitle;

  /// Plan sharing sheet: tooltip of the close button.
  ///
  /// In en, this message translates to:
  /// **'Close sharing'**
  String get planSharingCloseTooltip;

  /// Plan sharing sheet: intro. At most 10 trusted contacts can be chosen per plan.
  ///
  /// In en, this message translates to:
  /// **'Sharing with contacts starts off. Choose up to 10 trusted friends for this plan. Your date chooses their own contacts.'**
  String get planSharingIntro;

  /// Plan sharing sheet: shown when the member has no friends who can be chosen.
  ///
  /// In en, this message translates to:
  /// **'No eligible friends yet. Your plan is still available to you and your date.'**
  String get planSharingNoContacts;

  /// Plan sharing sheet: name shown for a contact whose name is missing.
  ///
  /// In en, this message translates to:
  /// **'A friend'**
  String get planSharingFriendFallback;

  /// Plan sharing sheet: preview heading when no contact is selected.
  ///
  /// In en, this message translates to:
  /// **'Preview · no contacts selected'**
  String get planSharingPreviewNone;

  /// Plan sharing sheet: preview heading with the number of selected contacts (1 or more).
  ///
  /// In en, this message translates to:
  /// **'{count, plural, other{Preview · {count} selected}}'**
  String planSharingPreviewCount(int count);

  /// Plan sharing sheet: preview text when no contact is selected.
  ///
  /// In en, this message translates to:
  /// **'Your friends will receive no plan or check-in updates from you.'**
  String get planSharingPreviewOffBody;

  /// Plan sharing sheet: preview text listing what selected contacts can see.
  ///
  /// In en, this message translates to:
  /// **'These contacts can see your date’s name, the time and place, plan status, and your check-in updates. They receive the current plan when you save.'**
  String get planSharingPreviewOnBody;

  /// Plan sharing sheet: privacy note under the preview.
  ///
  /// In en, this message translates to:
  /// **'Messages and private post-date feedback stay private. Removing a contact stops future updates and removes their in-app plan access. Updates already delivered to a device cannot be recalled.'**
  String get planSharingPrivacyNote;

  /// Plan sharing sheet: button to reload the contact choices after an error.
  ///
  /// In en, this message translates to:
  /// **'Reload sharing choices'**
  String get planSharingReload;

  /// Plan sharing sheet: save button label while saving.
  ///
  /// In en, this message translates to:
  /// **'Saving…'**
  String get planSharingSaving;

  /// Plan sharing sheet: save button when no contact is selected.
  ///
  /// In en, this message translates to:
  /// **'Keep contact sharing off'**
  String get planSharingKeepOff;

  /// Plan sharing sheet: save button when contacts are selected.
  ///
  /// In en, this message translates to:
  /// **'Share with selected contacts'**
  String get planSharingShareSelected;

  /// Plan sharing sheet: button that clears the selection.
  ///
  /// In en, this message translates to:
  /// **'Deselect everyone'**
  String get planSharingDeselectAll;

  /// Plan preferences summary: budget line; {budget} is a localised budget label.
  ///
  /// In en, this message translates to:
  /// **'Budget · {budget}'**
  String planBudgetLine(String budget);

  /// Plan preferences summary: atmosphere line; {atmospheres} is a ' · '-separated list of localised atmosphere labels.
  ///
  /// In en, this message translates to:
  /// **'Atmosphere · {atmospheres}'**
  String planAtmosphereLine(String atmospheres);

  /// Date plan atmosphere choice.
  ///
  /// In en, this message translates to:
  /// **'Quiet conversation'**
  String get planAtmosphereQuiet;

  /// Date plan atmosphere choice.
  ///
  /// In en, this message translates to:
  /// **'Relaxed & unhurried'**
  String get planAtmosphereRelaxed;

  /// Date plan atmosphere choice.
  ///
  /// In en, this message translates to:
  /// **'A lively setting'**
  String get planAtmosphereLively;

  /// Date plan atmosphere choice.
  ///
  /// In en, this message translates to:
  /// **'Outdoors'**
  String get planAtmosphereOutdoors;

  /// Date plan atmosphere choice.
  ///
  /// In en, this message translates to:
  /// **'Indoors'**
  String get planAtmosphereIndoors;

  /// Date plan accessibility preference.
  ///
  /// In en, this message translates to:
  /// **'Step-free access'**
  String get planAccessStepFree;

  /// Date plan accessibility preference.
  ///
  /// In en, this message translates to:
  /// **'Accessible toilet'**
  String get planAccessToilet;

  /// Date plan accessibility preference.
  ///
  /// In en, this message translates to:
  /// **'Seating available'**
  String get planAccessSeating;

  /// Date plan accessibility preference.
  ///
  /// In en, this message translates to:
  /// **'Low background noise'**
  String get planAccessLowNoise;

  /// Date plan accessibility preference.
  ///
  /// In en, this message translates to:
  /// **'Near public transport'**
  String get planAccessTransit;

  /// Date plan accessibility preference.
  ///
  /// In en, this message translates to:
  /// **'Captions for a video date'**
  String get planAccessCaptions;

  /// Plan preferences summary: heading above the accessibility preferences.
  ///
  /// In en, this message translates to:
  /// **'To make this comfortable'**
  String get planComfortHeading;

  /// Plan preferences summary: note under the accessibility preferences.
  ///
  /// In en, this message translates to:
  /// **'Preferences shared for this plan. Confirm these details with the venue or video service.'**
  String get planPreferencesDisclaimer;

  /// Propose plan sheet: error when sending failed and no server message is available.
  ///
  /// In en, this message translates to:
  /// **'Your plan could not be sent. Your choices are still here.'**
  String get planProposeErrorKept;

  /// Propose plan sheet: error when the plan being countered changed meanwhile.
  ///
  /// In en, this message translates to:
  /// **'This plan has changed. Close this sheet to review the conversation.'**
  String get planChangedError;

  /// Propose plan sheet: headline for a new plan.
  ///
  /// In en, this message translates to:
  /// **'A plan you both look forward to.'**
  String get planProposeHeadline;

  /// Propose plan sheet: headline when suggesting a change to a plan.
  ///
  /// In en, this message translates to:
  /// **'Shape this plan together'**
  String get planCounterHeadline;

  /// Propose plan sheet: lead text; {name} is the match's first name.
  ///
  /// In en, this message translates to:
  /// **'A suggestion for you and {name}. Nothing is agreed until the other person accepts this version.'**
  String planProposeLead(String name);

  /// Propose plan sheet: panel title for shared availability.
  ///
  /// In en, this message translates to:
  /// **'Find a little time together'**
  String get planFindTimeTitle;

  /// Propose plan sheet: explanation of shared availability.
  ///
  /// In en, this message translates to:
  /// **'Only overlapping times are shown when both of you choose to share availability. You can always suggest a time yourself.'**
  String get planFindTimeBody;

  /// Propose plan sheet: shared availability failed to load.
  ///
  /// In en, this message translates to:
  /// **'Shared times couldn’t load. Your manual time is still available.'**
  String get planSharedTimesFailed;

  /// Propose plan sheet: no overlapping availability.
  ///
  /// In en, this message translates to:
  /// **'No shared time suggestions right now. This does not mean either of you is unavailable.'**
  String get planSharedTimesEmpty;

  /// Propose plan sheet: button that reloads shared availability.
  ///
  /// In en, this message translates to:
  /// **'Refresh shared times'**
  String get planRefreshSharedTimes;

  /// Propose plan sheet: button that opens the member's availability settings.
  ///
  /// In en, this message translates to:
  /// **'Set my availability'**
  String get planSetAvailability;

  /// Propose plan sheet: panel title for picking a day and time.
  ///
  /// In en, this message translates to:
  /// **'When would feel right?'**
  String get planWhenTitle;

  /// Propose plan sheet: the time was picked by hand.
  ///
  /// In en, this message translates to:
  /// **'A time you’re suggesting'**
  String get planTimeSourceManual;

  /// Propose plan sheet: the time was picked from shared availability.
  ///
  /// In en, this message translates to:
  /// **'Selected from shared availability · checked again when sent'**
  String get planTimeSourceShared;

  /// Propose plan sheet: time-zone note; {timeZone} is the device's time zone abbreviation, {minutes} the plan duration.
  ///
  /// In en, this message translates to:
  /// **'{minutes, plural, other{Your device’s local time ({timeZone}). Duration: {minutes} minutes.}}'**
  String planLocalTimeNote(int minutes, String timeZone);

  /// Propose plan sheet: duration choice chip, in minutes.
  ///
  /// In en, this message translates to:
  /// **'{minutes} min'**
  String planDurationChip(int minutes);

  /// Propose plan sheet: panel title for the kind of date and place.
  ///
  /// In en, this message translates to:
  /// **'Something you would enjoy'**
  String get planEnjoyTitle;

  /// Propose plan sheet: hint of the area field.
  ///
  /// In en, this message translates to:
  /// **'A neighbourhood or public meeting area'**
  String get planAreaHint;

  /// Propose plan sheet: panel title for the budget.
  ///
  /// In en, this message translates to:
  /// **'What budget feels comfortable?'**
  String get planBudgetTitle;

  /// Propose plan sheet: explanation of the budget choice.
  ///
  /// In en, this message translates to:
  /// **'A starting point to agree together, not a price quote or a promise about who pays.'**
  String get planBudgetBody;

  /// Propose plan sheet: panel title for the atmosphere.
  ///
  /// In en, this message translates to:
  /// **'Set the atmosphere'**
  String get planAtmosphereTitle;

  /// Propose plan sheet: atmosphere instructions (at most three).
  ///
  /// In en, this message translates to:
  /// **'Choose up to three settings you would enjoy. Optional.'**
  String get planAtmosphereBody;

  /// Propose plan sheet: panel title for accessibility preferences.
  ///
  /// In en, this message translates to:
  /// **'Make it comfortable for both of you'**
  String get planComfortTitle;

  /// Propose plan sheet: explanation of the accessibility preferences.
  ///
  /// In en, this message translates to:
  /// **'Optional accessibility preferences. Selected choices are shared with your match when you send this plan. They are not added to your public profile or trusted-contact updates.'**
  String get planComfortBody;

  /// Propose plan sheet: note under the accessibility preferences.
  ///
  /// In en, this message translates to:
  /// **'You do not need to explain a diagnosis. These are requests to check with the venue or video service, not verified facilities.'**
  String get planComfortDisclaimer;

  /// Propose plan sheet: example hint in the note field.
  ///
  /// In en, this message translates to:
  /// **'Saturday afternoon, somewhere quieter?'**
  String get planNoteHint;

  /// Propose plan sheet: reminder above the send button.
  ///
  /// In en, this message translates to:
  /// **'Before sending, review the time and choices above. The other person can accept, decline or suggest a change.'**
  String get planReviewBeforeSending;

  /// Propose plan sheet: button that reloads the latest plan and discards edits.
  ///
  /// In en, this message translates to:
  /// **'Reload latest plan · discard edits'**
  String get planReloadLatest;

  /// Propose plan sheet: send button label while sending.
  ///
  /// In en, this message translates to:
  /// **'Sending…'**
  String get planSending;

  /// Propose plan sheet: send button when suggesting a change.
  ///
  /// In en, this message translates to:
  /// **'Send your suggestion'**
  String get planSendSuggestion;

  /// Debrief sheet: switch to share a mutual wish to meet again.
  ///
  /// In en, this message translates to:
  /// **'Share a second yes'**
  String get planSecondYesTitle;

  /// Debrief sheet: explanation of the second-yes switch.
  ///
  /// In en, this message translates to:
  /// **'Reveal that you want to meet again only if your match also says yes and agrees to share. Your other answers stay private.'**
  String get planSecondYesBody;

  /// Plan card: both members shared a second yes.
  ///
  /// In en, this message translates to:
  /// **'A second yes, from both of you'**
  String get planSecondYesHeadline;

  /// Plan card: body under the second-yes headline.
  ///
  /// In en, this message translates to:
  /// **'You both chose to share that you would like to meet again.'**
  String get planSecondYesCardBody;

  /// Plan card: button to plan another date after a second yes.
  ///
  /// In en, this message translates to:
  /// **'Plan another hello'**
  String get planAnotherHello;

  /// Plan card: button to counter-propose a plan.
  ///
  /// In en, this message translates to:
  /// **'Suggest a change'**
  String get planSuggestChange;

  /// Plan card: button opening the trusted-contact sharing sheet.
  ///
  /// In en, this message translates to:
  /// **'Choose who gets your updates'**
  String get planChooseUpdates;

  /// A member's own note shown in quotation marks (date plans and graduation); {note} is user-written text.
  ///
  /// In en, this message translates to:
  /// **'“{note}”'**
  String planQuotedNote(String note);

  /// Date plan status pill.
  ///
  /// In en, this message translates to:
  /// **'Declined'**
  String get planStatusDeclined;

  /// Date plan status pill.
  ///
  /// In en, this message translates to:
  /// **'Expired'**
  String get planStatusExpired;

  /// Date plan status pill.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get planStatusCompleted;

  /// Date plan status pill: the date did not take place.
  ///
  /// In en, this message translates to:
  /// **'Did not happen'**
  String get planStatusDidNotHappen;

  /// Date plan status pill: the members disagree whether the date happened.
  ///
  /// In en, this message translates to:
  /// **'Disputed'**
  String get planStatusDisputed;

  /// Plans screen: button opening the trusted-contact sharing sheet for a plan.
  ///
  /// In en, this message translates to:
  /// **'Manage your contact sharing'**
  String get plansManageSharing;

  /// Date plan error when a match's plans fail to load.
  ///
  /// In en, this message translates to:
  /// **'Unable to load date plans.'**
  String get plansLoadFailed;

  /// Plans screen error when the plan feeds fail to load.
  ///
  /// In en, this message translates to:
  /// **'Unable to load plans.'**
  String get plansFeedLoadFailed;

  /// Date plan error when accepting fails.
  ///
  /// In en, this message translates to:
  /// **'Unable to accept this plan.'**
  String get planAcceptFailed;

  /// Date plan error when declining fails.
  ///
  /// In en, this message translates to:
  /// **'Unable to decline this plan.'**
  String get planDeclineFailed;

  /// Date plan error when cancelling fails.
  ///
  /// In en, this message translates to:
  /// **'Unable to cancel this plan.'**
  String get planCancelFailed;

  /// Date plan error when the safety check-in fails.
  ///
  /// In en, this message translates to:
  /// **'Unable to check in right now.'**
  String get planCheckinFailed;

  /// Graduation banner and celebration: headline once both members confirmed leaving Connect together.
  ///
  /// In en, this message translates to:
  /// **'You found each other'**
  String get graduationFoundEachOther;

  /// Graduation banner: the match proposed leaving Connect together; {name} is their first name.
  ///
  /// In en, this message translates to:
  /// **'{name} wants to leave Connect together'**
  String graduationHeadlineDecide(String name);

  /// Graduation banner: waiting for the match to answer; {name} is their first name.
  ///
  /// In en, this message translates to:
  /// **'Waiting for {name}'**
  String graduationHeadlineWaiting(String name);

  /// Graduation banner: body once both confirmed.
  ///
  /// In en, this message translates to:
  /// **'You are both hidden from discovery. This chat stays open.'**
  String get graduationBodyConfirmed;

  /// Graduation banner: body when the viewer must confirm or decline.
  ///
  /// In en, this message translates to:
  /// **'Confirm and you both leave discovery. Your chat stays.'**
  String get graduationBodyDecide;

  /// Graduation banner: body while the viewer's proposal is waiting for an answer.
  ///
  /// In en, this message translates to:
  /// **'You asked to leave together. They can confirm or decline.'**
  String get graduationBodyWaiting;

  /// Graduation banner: button opening the celebration screen.
  ///
  /// In en, this message translates to:
  /// **'Celebrate'**
  String get graduationCelebrate;

  /// Graduation banner: button declining the proposal.
  ///
  /// In en, this message translates to:
  /// **'Not yet'**
  String get graduationNotYet;

  /// Graduation banner: button confirming the proposal.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get graduationConfirm;

  /// Graduation banner: the viewer chose to tell friends; they are told after the match confirms.
  ///
  /// In en, this message translates to:
  /// **'Your friends are told once they confirm.'**
  String get graduationFriendsToldOnConfirm;

  /// Graduation banner: the viewer chose not to tell friends.
  ///
  /// In en, this message translates to:
  /// **'Only the two of you know for now.'**
  String get graduationOnlyTwoOfYouForNow;

  /// Graduation banner: button withdrawing the viewer's proposal.
  ///
  /// In en, this message translates to:
  /// **'Withdraw'**
  String get graduationWithdraw;

  /// Propose graduation sheet: title; {name} is the match's first name.
  ///
  /// In en, this message translates to:
  /// **'Leave Connect with {name}?'**
  String graduationProposeTitle(String name);

  /// Propose graduation sheet: explanation; {name} is the match's first name. 'Privacy & Safety' is the settings screen name.
  ///
  /// In en, this message translates to:
  /// **'Once {name} confirms, you are both hidden from discovery. This chat stays open, and you can come back to discovery from Privacy & Safety at any time.'**
  String graduationProposeBody(String name);

  /// Propose graduation sheet: label of the optional note field.
  ///
  /// In en, this message translates to:
  /// **'A note for them (optional)'**
  String get graduationNoteLabel;

  /// Propose graduation sheet: hint of the note field.
  ///
  /// In en, this message translates to:
  /// **'Say why you are ready'**
  String get graduationNoteHint;

  /// Graduation: switch to tell the member's friends.
  ///
  /// In en, this message translates to:
  /// **'Tell my friends'**
  String get graduationTellFriends;

  /// Graduation: explanation of the tell-my-friends switch.
  ///
  /// In en, this message translates to:
  /// **'Your accepted friends hear you found someone. They are not told who.'**
  String get graduationTellFriendsBody;

  /// Propose graduation sheet: submit button.
  ///
  /// In en, this message translates to:
  /// **'Ask them'**
  String get graduationAskThem;

  /// Graduation celebration screen: app bar title (a matched pair leaving Connect together).
  ///
  /// In en, this message translates to:
  /// **'Graduation'**
  String get graduationTitle;

  /// Graduation celebration screen: body; {name} is the match's first name.
  ///
  /// In en, this message translates to:
  /// **'You and {name} are leaving Connect together. You are both hidden from discovery, and this chat stays open for as long as you like.'**
  String graduationCelebrationBody(String name);

  /// Graduation celebration: friends were notified.
  ///
  /// In en, this message translates to:
  /// **'Your friends have been told.'**
  String get graduationFriendsHaveBeenTold;

  /// Graduation celebration: the viewer chose to tell friends.
  ///
  /// In en, this message translates to:
  /// **'Your friends are told.'**
  String get graduationFriendsAreTold;

  /// Graduation celebration: the viewer chose not to tell friends.
  ///
  /// In en, this message translates to:
  /// **'Only the two of you know.'**
  String get graduationOnlyTwoOfYou;

  /// Graduation celebration: button that confirms and returns to the chat.
  ///
  /// In en, this message translates to:
  /// **'Confirm and go back'**
  String get graduationConfirmAndBack;

  /// Graduation celebration: button that returns to the app.
  ///
  /// In en, this message translates to:
  /// **'Back to Connect'**
  String get graduationBackToConnect;

  /// Graduation error when loading fails.
  ///
  /// In en, this message translates to:
  /// **'Unable to load graduation.'**
  String get graduationLoadFailed;

  /// Graduation error when proposing fails.
  ///
  /// In en, this message translates to:
  /// **'Unable to propose leaving together.'**
  String get graduationProposeFailed;

  /// Graduation error when confirming fails.
  ///
  /// In en, this message translates to:
  /// **'Unable to confirm right now.'**
  String get graduationConfirmFailed;

  /// Graduation error when declining fails.
  ///
  /// In en, this message translates to:
  /// **'Unable to decline right now.'**
  String get graduationDeclineFailed;

  /// Graduation error when withdrawing fails.
  ///
  /// In en, this message translates to:
  /// **'Unable to withdraw the proposal.'**
  String get graduationWithdrawFailed;

  /// Discovery pause error when the member's discovery status fails to load.
  ///
  /// In en, this message translates to:
  /// **'Unable to load discovery status.'**
  String get graduationPauseLoadFailed;

  /// Discovery pause error when pausing fails.
  ///
  /// In en, this message translates to:
  /// **'Unable to pause discovery.'**
  String get graduationPauseFailed;

  /// Discovery pause error when resuming fails.
  ///
  /// In en, this message translates to:
  /// **'Unable to resume discovery.'**
  String get graduationResumeFailed;

  /// Circle Challenges screen: no circles to show.
  ///
  /// In en, this message translates to:
  /// **'No circles available'**
  String get engagementCirclesEmptyTitle;

  /// Circle Challenges screen: hint when there are no circles.
  ///
  /// In en, this message translates to:
  /// **'Please pull to refresh.'**
  String get engagementCirclesPullToRefresh;

  /// Circle Challenges screen: pill when the member is in the circle.
  ///
  /// In en, this message translates to:
  /// **'Joined'**
  String get engagementCirclesJoined;

  /// Circle Challenges screen: pill when the member is not in the circle.
  ///
  /// In en, this message translates to:
  /// **'Not joined'**
  String get engagementCirclesNotJoined;

  /// Circle Challenges screen: participants in this week's challenge.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, other{{count} participants this week}}'**
  String engagementCirclesParticipants(int count);

  /// Circle Challenges screen: join button.
  ///
  /// In en, this message translates to:
  /// **'Join Circle'**
  String get engagementCirclesJoin;

  /// Circle Challenges screen: label of the weekly response field.
  ///
  /// In en, this message translates to:
  /// **'Weekly challenge response'**
  String get engagementCirclesResponseLabel;

  /// Circle Challenges screen: submit button.
  ///
  /// In en, this message translates to:
  /// **'Submit Entry'**
  String get engagementCirclesSubmit;

  /// Circle Challenges: topic shown when the server sends none.
  ///
  /// In en, this message translates to:
  /// **'Circle'**
  String get engagementCirclesTopicFallback;

  /// Circle Challenges: fallback error when loading fails.
  ///
  /// In en, this message translates to:
  /// **'Unable to load circles right now.'**
  String get engagementCirclesLoadFailed;

  /// Circle Challenges: fallback error when joining fails.
  ///
  /// In en, this message translates to:
  /// **'Unable to join circle right now.'**
  String get engagementCirclesJoinFailed;

  /// Circle Challenges: validation error, empty response.
  ///
  /// In en, this message translates to:
  /// **'Please enter your challenge response.'**
  String get engagementCirclesEnterResponse;

  /// Circle Challenges: fallback error when submitting fails.
  ///
  /// In en, this message translates to:
  /// **'Unable to submit challenge entry right now.'**
  String get engagementCirclesSubmitFailed;

  /// Match nudges screen title.
  ///
  /// In en, this message translates to:
  /// **'Match nudges'**
  String get engagementNudgesTitle;

  /// Match nudges screen: explanation card.
  ///
  /// In en, this message translates to:
  /// **'Send a gentle reminder to restart a quiet conversation. Daily limits and safety rules are enforced by the server.'**
  String get engagementNudgesIntro;

  /// Match nudges screen: no matches.
  ///
  /// In en, this message translates to:
  /// **'No matches available to nudge.'**
  String get engagementNudgesEmpty;

  /// Match nudges screen: status under a match after a nudge was sent.
  ///
  /// In en, this message translates to:
  /// **'Nudge sent in this session'**
  String get engagementNudgesSentInSession;

  /// Match nudges screen: status under a match that can be nudged.
  ///
  /// In en, this message translates to:
  /// **'Ready to send'**
  String get engagementNudgesReady;

  /// Match nudges screen: snackbar after sending a nudge.
  ///
  /// In en, this message translates to:
  /// **'Nudge sent to {name}.'**
  String engagementNudgesSentTo(String name);

  /// Match nudges screen: send button.
  ///
  /// In en, this message translates to:
  /// **'Nudge'**
  String get engagementNudgesAction;

  /// Match nudges: fallback error when sending fails.
  ///
  /// In en, this message translates to:
  /// **'Unable to send this nudge.'**
  String get engagementNudgesSendFailed;

  /// Trust Badges screen: section heading.
  ///
  /// In en, this message translates to:
  /// **'Earned Badges'**
  String get engagementTrustBadgesEarned;

  /// Trust Badges screen: no badges yet.
  ///
  /// In en, this message translates to:
  /// **'No badges yet. Complete activities to unlock trust badges.'**
  String get engagementTrustBadgesEmpty;

  /// Trust Badges screen: badge details; code and status come from the server, awardedAt is a timestamp. Keep the line break.
  ///
  /// In en, this message translates to:
  /// **'Code: {code}\nStatus: {status} • Awarded {awardedAt}'**
  String engagementTrustBadgesDetails(
    String code,
    String status,
    String awardedAt,
  );

  /// Trust Badges screen: section heading for history.
  ///
  /// In en, this message translates to:
  /// **'Recent History'**
  String get engagementTrustBadgesHistory;

  /// Trust Badges screen: no history yet.
  ///
  /// In en, this message translates to:
  /// **'No trust history available yet.'**
  String get engagementTrustBadgesHistoryEmpty;

  /// Trust Badges screen: milestone card when no data.
  ///
  /// In en, this message translates to:
  /// **'Milestone status unavailable.'**
  String get engagementTrustBadgesMilestoneUnavailable;

  /// Trust Badges screen: milestone card title.
  ///
  /// In en, this message translates to:
  /// **'Current Milestone'**
  String get engagementTrustBadgesCurrentMilestone;

  /// Trust Badges: fallback error when loading fails.
  ///
  /// In en, this message translates to:
  /// **'Failed to load trust badges. Please try again.'**
  String get engagementTrustBadgesLoadFailed;

  /// Trust Filters screen: switch title.
  ///
  /// In en, this message translates to:
  /// **'Enable trust filters'**
  String get engagementTrustFiltersEnable;

  /// Trust Filters screen: switch subtitle.
  ///
  /// In en, this message translates to:
  /// **'Hide profiles that do not meet your trust requirements'**
  String get engagementTrustFiltersEnableSubtitle;

  /// Trust Filters screen: slider label with the chosen minimum number of active badges.
  ///
  /// In en, this message translates to:
  /// **'Minimum active badges: {count}'**
  String engagementTrustFiltersMinimum(int count);

  /// Trust Filters screen: heading of required badges list.
  ///
  /// In en, this message translates to:
  /// **'Required badges'**
  String get engagementTrustFiltersRequired;

  /// Trust Filters screen: snackbar after saving.
  ///
  /// In en, this message translates to:
  /// **'Trust filters saved.'**
  String get engagementTrustFiltersSaved;

  /// Trust Filters screen: save button.
  ///
  /// In en, this message translates to:
  /// **'Save Trust Filters'**
  String get engagementTrustFiltersSave;

  /// Moderation appeal status 'submitted'.
  ///
  /// In en, this message translates to:
  /// **'Submitted'**
  String get engagementAppealStatusSubmitted;

  /// Moderation appeal status 'under_review'.
  ///
  /// In en, this message translates to:
  /// **'Under review'**
  String get engagementAppealStatusUnderReview;

  /// Moderation appeal status 'resolved_upheld': the original moderation decision stands.
  ///
  /// In en, this message translates to:
  /// **'Resolved (upheld)'**
  String get engagementAppealStatusResolvedUpheld;

  /// Moderation appeal status 'resolved_reversed': the original moderation decision was overturned.
  ///
  /// In en, this message translates to:
  /// **'Resolved (reversed)'**
  String get engagementAppealStatusResolvedReversed;

  /// Rooms: fallback error when leaving a room fails.
  ///
  /// In en, this message translates to:
  /// **'Could not leave this room. Please retry.'**
  String get engagementRoomsLeaveFailed;

  /// Rooms: fallback error when the presence heartbeat fails.
  ///
  /// In en, this message translates to:
  /// **'Lost touch with the room.'**
  String get engagementRoomsPresenceFailed;

  /// Rooms: fallback error when the people list fails to load.
  ///
  /// In en, this message translates to:
  /// **'Could not load who is here. Please retry.'**
  String get engagementRoomsMembersFailed;

  /// Rooms: fallback error when a moderation action fails.
  ///
  /// In en, this message translates to:
  /// **'That did not go through. Please retry.'**
  String get engagementRoomsModerationFailed;

  /// Rooms: fallback error when starting a room fails.
  ///
  /// In en, this message translates to:
  /// **'Could not start the room. Please retry.'**
  String get engagementRoomsCreateFailed;

  /// Rooms: fallback error when the room list fails to load.
  ///
  /// In en, this message translates to:
  /// **'Rooms are unavailable right now. Pull to retry.'**
  String get engagementRoomsLoadFailed;

  /// Generic button: save changes.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get commonSave;

  /// Generic destructive button: remove an item.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get commonRemove;

  /// App bar title of the Account & Data screen.
  ///
  /// In en, this message translates to:
  /// **'Account & Data'**
  String get accountTitle;

  /// Error when the account lifecycle status could not load.
  ///
  /// In en, this message translates to:
  /// **'Could not load your account status.'**
  String get accountLoadFailed;

  /// Countdown heading while account deletion is pending.
  ///
  /// In en, this message translates to:
  /// **'{days, plural, =1{Deletion in 1 day} other{Deletion in {days} days}}'**
  String accountDeletionIn(int days);

  /// Countdown heading when the deletion date has arrived.
  ///
  /// In en, this message translates to:
  /// **'Deletion is due'**
  String get accountDeletionDue;

  /// Explains the deletion grace period.
  ///
  /// In en, this message translates to:
  /// **'Your profile is hidden. You can still sign in and cancel until then — after that your data cannot be recovered.'**
  String get accountDeletionCountdownBody;

  /// Button: cancel the pending deletion and keep the account.
  ///
  /// In en, this message translates to:
  /// **'Keep my account'**
  String get accountKeepMyAccount;

  /// Snackbar after cancelling deletion.
  ///
  /// In en, this message translates to:
  /// **'Your account will not be deleted.'**
  String get accountNotDeletedSnack;

  /// Snackbar when cancelling deletion failed.
  ///
  /// In en, this message translates to:
  /// **'Could not cancel. Please try again.'**
  String get accountCancelFailed;

  /// Pause card title while the profile is hidden.
  ///
  /// In en, this message translates to:
  /// **'Your profile is hidden'**
  String get accountHiddenTitle;

  /// Pause card title when the profile is visible.
  ///
  /// In en, this message translates to:
  /// **'Take a break'**
  String get accountTakeBreakTitle;

  /// Pause card body while hidden.
  ///
  /// In en, this message translates to:
  /// **'Nobody can see or match with you. Your matches and messages are kept, and you can come back whenever you want.'**
  String get accountHiddenBody;

  /// Pause card body when visible.
  ///
  /// In en, this message translates to:
  /// **'Hide your profile from Discover without losing anything. You stay signed in and can switch back at any time.'**
  String get accountTakeBreakBody;

  /// Button: make the hidden profile visible again.
  ///
  /// In en, this message translates to:
  /// **'Unhide my profile'**
  String get accountUnhideProfile;

  /// Button: hide the profile.
  ///
  /// In en, this message translates to:
  /// **'Hide my profile'**
  String get accountHideProfile;

  /// Snackbar after unhiding the profile.
  ///
  /// In en, this message translates to:
  /// **'Your profile is visible again.'**
  String get accountVisibleAgainSnack;

  /// Snackbar after hiding the profile.
  ///
  /// In en, this message translates to:
  /// **'Your profile is now hidden.'**
  String get accountNowHiddenSnack;

  /// Snackbar when hiding/unhiding failed.
  ///
  /// In en, this message translates to:
  /// **'Could not update. Please try again.'**
  String get accountUpdateFailed;

  /// Export card title.
  ///
  /// In en, this message translates to:
  /// **'Download your data'**
  String get accountDownloadTitle;

  /// Export card body.
  ///
  /// In en, this message translates to:
  /// **'Get a copy of your profile, preferences, matches and the messages you sent. Messages other people wrote are not included.'**
  String get accountDownloadBody;

  /// Export button label while preparing.
  ///
  /// In en, this message translates to:
  /// **'Preparing…'**
  String get accountPreparing;

  /// Export button label.
  ///
  /// In en, this message translates to:
  /// **'Prepare my data'**
  String get accountPrepareData;

  /// Snackbar when the export failed.
  ///
  /// In en, this message translates to:
  /// **'Could not prepare your data. Please try again.'**
  String get accountPrepareFailed;

  /// Title of the dialog showing the exported data.
  ///
  /// In en, this message translates to:
  /// **'Your data'**
  String get accountYourData;

  /// Delete card title and button.
  ///
  /// In en, this message translates to:
  /// **'Delete my account'**
  String get accountDeleteTitle;

  /// Delete card body.
  ///
  /// In en, this message translates to:
  /// **'Your profile is hidden straight away and everything is erased after a grace period. You can cancel during that time by signing in. Afterwards nothing can be recovered.'**
  String get accountDeleteBody;

  /// Delete button label when deletion is pending.
  ///
  /// In en, this message translates to:
  /// **'Deletion already scheduled'**
  String get accountDeletionAlreadyScheduled;

  /// Delete confirmation dialog title.
  ///
  /// In en, this message translates to:
  /// **'Delete your account?'**
  String get accountDeleteConfirmTitle;

  /// Delete confirmation dialog body.
  ///
  /// In en, this message translates to:
  /// **'Your profile, photos, matches and messages will be erased and cannot be recovered.\n\nIf you just want a break, hiding your profile keeps everything and can be undone.'**
  String get accountDeleteConfirmBody;

  /// Delete dialog button: hide the profile instead of deleting.
  ///
  /// In en, this message translates to:
  /// **'Hide instead'**
  String get accountHideInstead;

  /// Snackbar after deletion was requested.
  ///
  /// In en, this message translates to:
  /// **'Deletion scheduled. You can cancel until then.'**
  String get accountDeletionScheduledSnack;

  /// App bar title of the Privacy & Safety screen.
  ///
  /// In en, this message translates to:
  /// **'Privacy & Safety'**
  String get privacyTitle;

  /// Switch title: show age on profile.
  ///
  /// In en, this message translates to:
  /// **'Show age'**
  String get privacyShowAge;

  /// Switch subtitle under Show age.
  ///
  /// In en, this message translates to:
  /// **'Control whether your age is visible'**
  String get privacyShowAgeSubtitle;

  /// Switch title: show exact distance.
  ///
  /// In en, this message translates to:
  /// **'Show exact distance'**
  String get privacyShowDistance;

  /// Switch subtitle under Show exact distance.
  ///
  /// In en, this message translates to:
  /// **'Show precise distance on your profile'**
  String get privacyShowDistanceSubtitle;

  /// Switch title: show online status.
  ///
  /// In en, this message translates to:
  /// **'Show online status'**
  String get privacyShowOnline;

  /// Switch subtitle under Show online status.
  ///
  /// In en, this message translates to:
  /// **'Allow others to see if you are online'**
  String get privacyShowOnlineSubtitle;

  /// Tile title: emergency SOS.
  ///
  /// In en, this message translates to:
  /// **'Emergency SOS'**
  String get privacyEmergencySos;

  /// Tile subtitle under Emergency SOS.
  ///
  /// In en, this message translates to:
  /// **'Activate an alert and review alert history'**
  String get privacyEmergencySosSubtitle;

  /// Tile/app bar title: emergency contacts.
  ///
  /// In en, this message translates to:
  /// **'Emergency Contacts'**
  String get privacyEmergencyContacts;

  /// Tile subtitle under Emergency Contacts.
  ///
  /// In en, this message translates to:
  /// **'Manage trusted emergency contacts'**
  String get privacyEmergencyContactsSubtitle;

  /// Tile/app bar title: blocked users.
  ///
  /// In en, this message translates to:
  /// **'Blocked Users'**
  String get privacyBlockedUsers;

  /// Tile subtitle under Blocked Users.
  ///
  /// In en, this message translates to:
  /// **'Review and unblock users'**
  String get privacyBlockedUsersSubtitle;

  /// Tile/app bar title: moderation appeals.
  ///
  /// In en, this message translates to:
  /// **'Moderation Appeals'**
  String get privacyModerationAppeals;

  /// Tile subtitle under Moderation Appeals.
  ///
  /// In en, this message translates to:
  /// **'Submit an appeal and track review status'**
  String get privacyModerationAppealsSubtitle;

  /// Switch title: let people find me in friend search.
  ///
  /// In en, this message translates to:
  /// **'Let people find me in friend search'**
  String get privacyFriendSearch;

  /// Subtitle when a privacy setting failed to load.
  ///
  /// In en, this message translates to:
  /// **'This setting could not load. Open this page again to retry.'**
  String get privacySettingLoadFailed;

  /// Explains friend-search visibility.
  ///
  /// In en, this message translates to:
  /// **'Members can find you by name or @username in Add friend. People you match or meet in rooms and groups can still add you.'**
  String get privacyFriendSearchSubtitle;

  /// Snackbar fallback when a privacy choice could not be saved.
  ///
  /// In en, this message translates to:
  /// **'Your choice could not be saved.'**
  String get privacyChoiceSaveFailed;

  /// Switch title: show my public writing on my profile.
  ///
  /// In en, this message translates to:
  /// **'Show my public writing on my profile'**
  String get privacyShowcase;

  /// Explains the profile showcase setting.
  ///
  /// In en, this message translates to:
  /// **'Members can see the chapters you share with the community and your photos on the wall on your profile. Private and friends-only chapters never appear.'**
  String get privacyShowcaseSubtitle;

  /// Switch title: share anonymous crash reports.
  ///
  /// In en, this message translates to:
  /// **'Share crash reports'**
  String get privacyCrashReports;

  /// Explains crash reports.
  ///
  /// In en, this message translates to:
  /// **'Anonymous crash and error reports help us fix problems. No messages, photos or account details are included.'**
  String get privacyCrashReportsSubtitle;

  /// Discovery tile subtitle after leaving Connect with a match.
  ///
  /// In en, this message translates to:
  /// **'You left Connect with your match. Nobody is dealt your card.'**
  String get privacyGraduatedReason;

  /// Discovery tile subtitle while paused.
  ///
  /// In en, this message translates to:
  /// **'Nobody is dealt your card until you resume.'**
  String get privacyPausedReason;

  /// Discovery tile subtitle while active.
  ///
  /// In en, this message translates to:
  /// **'You are shown to other members in discovery.'**
  String get privacyActiveReason;

  /// Discovery tile title while paused.
  ///
  /// In en, this message translates to:
  /// **'Discovery paused'**
  String get privacyDiscoveryPaused;

  /// Discovery tile title while active.
  ///
  /// In en, this message translates to:
  /// **'Discovery active'**
  String get privacyDiscoveryActive;

  /// Button: resume discovery.
  ///
  /// In en, this message translates to:
  /// **'Resume'**
  String get privacyResume;

  /// Button: pause discovery.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get privacyPause;

  /// Intro on the emergency contacts screen.
  ///
  /// In en, this message translates to:
  /// **'Add up to 3 trusted contacts. These contacts are used for safety workflows and SOS features in later phases.'**
  String get emergencyIntro;

  /// Empty state on emergency contacts.
  ///
  /// In en, this message translates to:
  /// **'No emergency contacts added yet.'**
  String get emergencyEmpty;

  /// Disabled add button label at the contact limit.
  ///
  /// In en, this message translates to:
  /// **'Maximum contacts added'**
  String get emergencyMaxReached;

  /// Button / dialog title: add an emergency contact.
  ///
  /// In en, this message translates to:
  /// **'Add Contact'**
  String get emergencyAddContact;

  /// Dialog title: edit an emergency contact.
  ///
  /// In en, this message translates to:
  /// **'Edit Contact'**
  String get emergencyEditContact;

  /// Validation snackbar for the contact form.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid name and phone number.'**
  String get emergencyInvalidInput;

  /// Snackbar after adding a contact.
  ///
  /// In en, this message translates to:
  /// **'Emergency contact added.'**
  String get emergencyAdded;

  /// Snackbar when adding a contact failed.
  ///
  /// In en, this message translates to:
  /// **'Failed to add contact. Please try again.'**
  String get emergencyAddFailed;

  /// Snackbar after updating a contact.
  ///
  /// In en, this message translates to:
  /// **'Emergency contact updated.'**
  String get emergencyUpdated;

  /// Snackbar when updating a contact failed.
  ///
  /// In en, this message translates to:
  /// **'Failed to update contact. Please try again.'**
  String get emergencyUpdateFailed;

  /// Dialog title: remove an emergency contact.
  ///
  /// In en, this message translates to:
  /// **'Remove Contact'**
  String get emergencyRemoveTitle;

  /// Dialog body confirming removal. {name} is the contact's name.
  ///
  /// In en, this message translates to:
  /// **'Remove {name} from emergency contacts?'**
  String emergencyRemoveBody(String name);

  /// Snackbar after removing a contact.
  ///
  /// In en, this message translates to:
  /// **'Emergency contact removed.'**
  String get emergencyRemoved;

  /// Snackbar when removing a contact failed.
  ///
  /// In en, this message translates to:
  /// **'Failed to remove contact. Please try again.'**
  String get emergencyRemoveFailed;

  /// Form field label: contact name.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get emergencyNameLabel;

  /// Form field label: phone number.
  ///
  /// In en, this message translates to:
  /// **'Phone Number'**
  String get emergencyPhoneLabel;

  /// Section title on the appeals screen.
  ///
  /// In en, this message translates to:
  /// **'Submit an appeal'**
  String get appealsSubmitTitle;

  /// Appeal form field label: reason.
  ///
  /// In en, this message translates to:
  /// **'Reason'**
  String get appealsReasonLabel;

  /// Appeal form hint: reason.
  ///
  /// In en, this message translates to:
  /// **'Why should this moderation decision be reviewed?'**
  String get appealsReasonHint;

  /// Appeal form field label: optional report ID.
  ///
  /// In en, this message translates to:
  /// **'Report ID (optional)'**
  String get appealsReportIdLabel;

  /// Appeal form field label: optional context.
  ///
  /// In en, this message translates to:
  /// **'Additional context (optional)'**
  String get appealsContextLabel;

  /// Button: submit the appeal.
  ///
  /// In en, this message translates to:
  /// **'Submit appeal'**
  String get appealsSubmit;

  /// Empty state on the appeals list.
  ///
  /// In en, this message translates to:
  /// **'No appeals submitted yet. Your submitted appeals will appear here with status updates.'**
  String get appealsEmpty;

  /// Appeal card meta line. {id} is the appeal ID.
  ///
  /// In en, this message translates to:
  /// **'Appeal ID: {id}'**
  String appealsIdLine(String id);

  /// Appeal card meta line with the review deadline (raw server value or '-').
  ///
  /// In en, this message translates to:
  /// **'SLA deadline: {deadline}'**
  String appealsSlaLine(String deadline);

  /// Appeal card meta line with the reviewer.
  ///
  /// In en, this message translates to:
  /// **'Reviewed by: {reviewer}'**
  String appealsReviewedBy(String reviewer);

  /// Validation: appeal reason required.
  ///
  /// In en, this message translates to:
  /// **'Reason is required.'**
  String get appealsReasonRequired;

  /// Snackbar after submitting an appeal.
  ///
  /// In en, this message translates to:
  /// **'Appeal submitted successfully.'**
  String get appealsSubmitted;

  /// Snackbar when submitting an appeal failed.
  ///
  /// In en, this message translates to:
  /// **'Failed to submit appeal. Please try again.'**
  String get appealsSubmitFailed;

  /// Empty state on the blocked users list.
  ///
  /// In en, this message translates to:
  /// **'You have not blocked any users.'**
  String get blockedEmpty;

  /// Button: unblock a member.
  ///
  /// In en, this message translates to:
  /// **'Unblock'**
  String get blockedUnblock;

  /// Dialog title: unblock a member.
  ///
  /// In en, this message translates to:
  /// **'Unblock User'**
  String get blockedUnblockTitle;

  /// Dialog body confirming unblock.
  ///
  /// In en, this message translates to:
  /// **'Unblock {name}?'**
  String blockedUnblockBody(String name);

  /// Snackbar after unblocking.
  ///
  /// In en, this message translates to:
  /// **'{name} has been unblocked.'**
  String blockedUnblockedSnack(String name);

  /// Snackbar when unblocking failed.
  ///
  /// In en, this message translates to:
  /// **'Failed to unblock user. Please try again.'**
  String get blockedUnblockFailed;

  /// About screen version line.
  ///
  /// In en, this message translates to:
  /// **'Version {version}'**
  String aboutVersion(String version);

  /// About screen description.
  ///
  /// In en, this message translates to:
  /// **'Trust-first dating app focused on authentic profiles, safe communication, and serious relationships.'**
  String get aboutDescription;

  /// About screen section header: technology stack.
  ///
  /// In en, this message translates to:
  /// **'Stack'**
  String get aboutStack;

  /// About screen stack line.
  ///
  /// In en, this message translates to:
  /// **'Flutter (Android-first)'**
  String get aboutStackFlutter;

  /// About screen stack line.
  ///
  /// In en, this message translates to:
  /// **'Go services + native PostgreSQL'**
  String get aboutStackGo;

  /// About screen stack line.
  ///
  /// In en, this message translates to:
  /// **'Riverpod state management'**
  String get aboutStackRiverpod;

  /// Overlay on spoiler content.
  ///
  /// In en, this message translates to:
  /// **'Spoiler — tap to reveal'**
  String get communitySpoiler;

  /// Fallback error when a community report failed.
  ///
  /// In en, this message translates to:
  /// **'Report could not be submitted.'**
  String get communityReportFailed;

  /// Snackbar after a community report.
  ///
  /// In en, this message translates to:
  /// **'Report submitted. Thank you.'**
  String get communityReportSubmitted;

  /// Confirm dialog title: block a member.
  ///
  /// In en, this message translates to:
  /// **'Block {name}?'**
  String communityBlockTitle(String name);

  /// Confirm dialog body: what blocking does.
  ///
  /// In en, this message translates to:
  /// **'You will stop seeing each other’s photos, club posts, reviews and lists. This also blocks contact through Connect.'**
  String get communityBlockBody;

  /// Confirm dialog button: block the member.
  ///
  /// In en, this message translates to:
  /// **'Block member'**
  String get communityBlockAction;

  /// Fallback error when blocking failed.
  ///
  /// In en, this message translates to:
  /// **'Could not block this member. Please retry.'**
  String get communityBlockFailed;

  /// Report sheet title.
  ///
  /// In en, this message translates to:
  /// **'Report'**
  String get reportSheetTitle;

  /// Report reason option.
  ///
  /// In en, this message translates to:
  /// **'Harassment'**
  String get reportReasonHarassment;

  /// Report reason option.
  ///
  /// In en, this message translates to:
  /// **'Inappropriate content'**
  String get reportReasonInappropriate;

  /// Report reason option.
  ///
  /// In en, this message translates to:
  /// **'Fraud / scam'**
  String get reportReasonFraud;

  /// Report reason option.
  ///
  /// In en, this message translates to:
  /// **'Fake profile'**
  String get reportReasonFake;

  /// Report sheet dropdown label.
  ///
  /// In en, this message translates to:
  /// **'Reason'**
  String get reportReasonLabel;

  /// Report sheet field label.
  ///
  /// In en, this message translates to:
  /// **'Description (optional)'**
  String get reportDescriptionLabel;

  /// Report sheet field hint.
  ///
  /// In en, this message translates to:
  /// **'Add context to help review your report'**
  String get reportDescriptionHint;

  /// Error when submitting a report failed.
  ///
  /// In en, this message translates to:
  /// **'Failed to submit report. Please try again.'**
  String get reportSubmitFailed;

  /// Report sheet submit button.
  ///
  /// In en, this message translates to:
  /// **'Submit report'**
  String get reportSubmit;

  /// Membership screen: app bar title.
  ///
  /// In en, this message translates to:
  /// **'Membership'**
  String get membershipTitle;

  /// Membership screen: heading above the plan catalog.
  ///
  /// In en, this message translates to:
  /// **'Choose your plan'**
  String get membershipChooseYourPlan;

  /// Membership screen: note under the plan heading when monthly billing is selected.
  ///
  /// In en, this message translates to:
  /// **'Pay by card. Renews automatically every month until you turn it off.'**
  String get membershipCycleNoteMonthly;

  /// Membership screen: note under the plan heading when yearly billing is selected.
  ///
  /// In en, this message translates to:
  /// **'Pay by card. Renews automatically every year until you turn it off.'**
  String get membershipCycleNoteYearly;

  /// Membership screen: shown when the server lists no paid plans.
  ///
  /// In en, this message translates to:
  /// **'No plans are on sale right now.'**
  String get membershipNoPlansOnSale;

  /// Membership screen: heading of the card payment history.
  ///
  /// In en, this message translates to:
  /// **'Payments'**
  String get membershipPaymentsTitle;

  /// Membership screen: empty payment history.
  ///
  /// In en, this message translates to:
  /// **'No card payments yet.'**
  String get membershipNoCardPayments;

  /// Membership screen: legal footnote about automatic renewal and card data.
  ///
  /// In en, this message translates to:
  /// **'Your plan renews automatically at the end of each billing period. Turn off auto-renew at any time; you keep your benefits until the period ends. Card details are handled by the payment provider and never stored in the app.'**
  String get membershipFooterNote;

  /// Membership: title of the dialog confirming a switch to another paid plan. plan is the server plan name.
  ///
  /// In en, this message translates to:
  /// **'Switch to {plan}?'**
  String membershipSwitchTitle(String plan);

  /// Membership: plan switch dialog body for an upgrade on monthly billing. price is the new monthly price.
  ///
  /// In en, this message translates to:
  /// **'Your card is charged now for the difference for the rest of this period, then {price} per month from the next renewal.'**
  String membershipSwitchUpgradeBodyMonthly(String price);

  /// Membership: plan switch dialog body for an upgrade on yearly billing. price is the new yearly price.
  ///
  /// In en, this message translates to:
  /// **'Your card is charged now for the difference for the rest of this period, then {price} per year from the next renewal.'**
  String membershipSwitchUpgradeBodyYearly(String price);

  /// Membership: plan switch dialog body for a downgrade on monthly billing. currentPlan is the plan being left; price the new monthly price.
  ///
  /// In en, this message translates to:
  /// **'Your plan changes now. Unused time on {currentPlan} is credited against your next renewal, then you pay {price} per month.'**
  String membershipSwitchDowngradeBodyMonthly(String currentPlan, String price);

  /// Membership: plan switch dialog body for a downgrade on yearly billing. currentPlan is the plan being left; price the new yearly price.
  ///
  /// In en, this message translates to:
  /// **'Your plan changes now. Unused time on {currentPlan} is credited against your next renewal, then you pay {price} per year.'**
  String membershipSwitchDowngradeBodyYearly(String currentPlan, String price);

  /// Membership: dismiss button in the subscribe and plan switch dialogs.
  ///
  /// In en, this message translates to:
  /// **'Not now'**
  String get membershipNotNow;

  /// Membership: confirm button in the plan switch dialog when the new plan costs more.
  ///
  /// In en, this message translates to:
  /// **'Upgrade'**
  String get membershipUpgrade;

  /// Membership: confirm button in the plan switch dialog when the new plan costs less.
  ///
  /// In en, this message translates to:
  /// **'Switch plan'**
  String get membershipSwitchPlan;

  /// Membership: snackbar after a successful plan switch.
  ///
  /// In en, this message translates to:
  /// **'You\'re on {plan} now.'**
  String membershipSwitchedSnack(String plan);

  /// Membership: snackbar after the card was replaced.
  ///
  /// In en, this message translates to:
  /// **'Your card has been updated.'**
  String get membershipCardUpdated;

  /// Membership: snackbar when the card update is not yet confirmed.
  ///
  /// In en, this message translates to:
  /// **'Card update not confirmed yet. Check its status before trying again.'**
  String get membershipCardUpdatePending;

  /// Membership: snackbar when the card update session expired or was cancelled.
  ///
  /// In en, this message translates to:
  /// **'This card update session has ended. Refresh to see your current card.'**
  String get membershipCardUpdateEnded;

  /// Membership: what the hosted checkout is for when the member replaces their card; fills {title} in 'Pay for {title}' and the web waiting sheet.
  ///
  /// In en, this message translates to:
  /// **'your card'**
  String get membershipCheckoutTitleCard;

  /// Membership: title of the dialog confirming auto-renew is turned off.
  ///
  /// In en, this message translates to:
  /// **'Turn off auto-renew?'**
  String get membershipAutoRenewOffTitle;

  /// Membership: auto-renew off dialog body. plan is the current plan name; date the formatted end of the paid period.
  ///
  /// In en, this message translates to:
  /// **'Your {plan} benefits stay active until {date}. After that you move to the Free plan and your card is not charged again.'**
  String membershipAutoRenewOffBodyDate(String plan, String date);

  /// Membership: auto-renew off dialog body when the period end date is unknown. plan is the current plan name.
  ///
  /// In en, this message translates to:
  /// **'Your {plan} benefits stay active until the end of the current period. After that you move to the Free plan and your card is not charged again.'**
  String membershipAutoRenewOffBodyPeriodEnd(String plan);

  /// Membership: cancel button in the auto-renew off dialog.
  ///
  /// In en, this message translates to:
  /// **'Keep renewing'**
  String get membershipKeepRenewing;

  /// Membership: destructive confirm button in the auto-renew off dialog.
  ///
  /// In en, this message translates to:
  /// **'Turn off'**
  String get membershipTurnOff;

  /// Membership: snackbar after auto-renew is turned back on.
  ///
  /// In en, this message translates to:
  /// **'Auto-renew is back on.'**
  String get membershipAutoRenewBackOn;

  /// Membership: snackbar after auto-renew is turned off.
  ///
  /// In en, this message translates to:
  /// **'Auto-renew is off. Your benefits continue until the period ends.'**
  String get membershipAutoRenewNowOff;

  /// Membership: title of the dialog confirming a new subscription.
  ///
  /// In en, this message translates to:
  /// **'Subscribe to {plan}'**
  String membershipSubscribeTitle(String plan);

  /// Membership: subscribe dialog body, live payments, monthly billing. price is the formatted monthly price.
  ///
  /// In en, this message translates to:
  /// **'{price} per month, charged to your card and renewed automatically until you turn auto-renew off. You will enter your card on the payment provider\'s secure page.'**
  String membershipSubscribeBodyMonthly(String price);

  /// Membership: subscribe dialog body, live payments, yearly billing. price is the formatted yearly price.
  ///
  /// In en, this message translates to:
  /// **'{price} per year, charged to your card and renewed automatically until you turn auto-renew off. You will enter your card on the payment provider\'s secure page.'**
  String membershipSubscribeBodyYearly(String price);

  /// Membership: subscribe dialog body in test mode (no real charge), monthly billing. price is the formatted monthly price.
  ///
  /// In en, this message translates to:
  /// **'Test checkout only — no real charge. {price} per month, simulated and renewed automatically until you turn auto-renew off. You will enter your card on the payment provider\'s secure page.'**
  String membershipSubscribeBodyTestMonthly(String price);

  /// Membership: subscribe dialog body in test mode (no real charge), yearly billing. price is the formatted yearly price.
  ///
  /// In en, this message translates to:
  /// **'Test checkout only — no real charge. {price} per year, simulated and renewed automatically until you turn auto-renew off. You will enter your card on the payment provider\'s secure page.'**
  String membershipSubscribeBodyTestYearly(String price);

  /// Membership: confirm button in the subscribe dialog; opens the hosted card page.
  ///
  /// In en, this message translates to:
  /// **'Continue to card'**
  String get membershipContinueToCard;

  /// Membership and wallet: snackbar when the provider has not confirmed the payment yet.
  ///
  /// In en, this message translates to:
  /// **'Payment is still being confirmed. Pull to refresh in a moment.'**
  String get paymentStillConfirming;

  /// Membership: snackbar when a subscription checkout expired or was cancelled.
  ///
  /// In en, this message translates to:
  /// **'This checkout session has ended. Refresh your payment history before trying again.'**
  String get membershipCheckoutEnded;

  /// Membership: snackbar when the payment account could not be re-read before resuming a checkout.
  ///
  /// In en, this message translates to:
  /// **'Unable to check the payment account. Please retry.'**
  String get membershipRecoverAccountUnavailable;

  /// Membership: snackbar when an unfinished checkout is no longer open after a refresh.
  ///
  /// In en, this message translates to:
  /// **'Payment account refreshed. This checkout is no longer open.'**
  String get membershipRecoverCheckoutClosed;

  /// Membership: snackbar when a resumed checkout is confirmed.
  ///
  /// In en, this message translates to:
  /// **'Confirmed. Your payment account is up to date.'**
  String get membershipRecoverConfirmed;

  /// Membership: snackbar when a resumed checkout is still awaiting confirmation.
  ///
  /// In en, this message translates to:
  /// **'Confirmation is still pending. You can check again here.'**
  String get membershipRecoverPending;

  /// Membership: snackbar when a resumed checkout has expired.
  ///
  /// In en, this message translates to:
  /// **'This checkout session has ended. Review your payment history before starting another.'**
  String get membershipRecoverEnded;

  /// Membership: headline of the sheet shown after a plan purchase is confirmed.
  ///
  /// In en, this message translates to:
  /// **'You\'re {plan} now'**
  String membershipCelebrateTitle(String plan);

  /// Membership: purchase confirmation sheet body in test mode.
  ///
  /// In en, this message translates to:
  /// **'Test payment confirmed; no real money was charged. Your test plan renews automatically. Manage auto-renew any time from this screen.'**
  String get membershipCelebrateBodyTest;

  /// Membership: purchase confirmation sheet body for a real payment.
  ///
  /// In en, this message translates to:
  /// **'Payment confirmed. Your plan renews automatically. Manage auto-renew any time from this screen.'**
  String get membershipCelebrateBody;

  /// Membership: button closing the purchase confirmation sheet.
  ///
  /// In en, this message translates to:
  /// **'Start exploring'**
  String get membershipStartExploring;

  /// Membership hero: small caption above the plan name for a paid member.
  ///
  /// In en, this message translates to:
  /// **'Your membership'**
  String get membershipYourMembership;

  /// Membership hero: small caption above the plan name for a free member.
  ///
  /// In en, this message translates to:
  /// **'Your plan'**
  String get membershipYourPlan;

  /// Membership hero: plan name shown when the member has no subscription record (the free tier).
  ///
  /// In en, this message translates to:
  /// **'Free'**
  String get membershipFreePlanName;

  /// Membership hero: price with a short monthly suffix, e.g. ₹199/mo.
  ///
  /// In en, this message translates to:
  /// **'{price}/mo'**
  String membershipPricePerMonthShort(String price);

  /// Membership hero: price with a short yearly suffix, e.g. ₹1999/yr.
  ///
  /// In en, this message translates to:
  /// **'{price}/yr'**
  String membershipPricePerYearShort(String price);

  /// Membership hero: shown when the card brand and last digits are unknown.
  ///
  /// In en, this message translates to:
  /// **'Card on file with the payment provider'**
  String get membershipCardOnFile;

  /// Membership: card label when the provider did not report a brand (shown before •••• 4242).
  ///
  /// In en, this message translates to:
  /// **'Card'**
  String get membershipCardBrandFallback;

  /// Membership and wallet: button label while the hosted checkout is opening.
  ///
  /// In en, this message translates to:
  /// **'Opening…'**
  String get paymentOpening;

  /// Membership hero: button to replace the card on file.
  ///
  /// In en, this message translates to:
  /// **'Update card'**
  String get membershipUpdateCard;

  /// Membership hero: renewal line when the last renewal charge failed.
  ///
  /// In en, this message translates to:
  /// **'Last payment failed. We will retry your card; benefits stay active for a few days.'**
  String get membershipLastPaymentFailed;

  /// Membership hero: next renewal date while auto-renew is on.
  ///
  /// In en, this message translates to:
  /// **'Renews on {date}'**
  String membershipRenewsOn(String date);

  /// Membership hero: renewal line when the renewal date is unknown.
  ///
  /// In en, this message translates to:
  /// **'Renews soon'**
  String get membershipRenewsSoon;

  /// Membership hero: end date while auto-renew is off.
  ///
  /// In en, this message translates to:
  /// **'Ends on {date} · auto-renew is off'**
  String membershipEndsOn(String date);

  /// Membership hero: end line when the end date is unknown and auto-renew is off.
  ///
  /// In en, this message translates to:
  /// **'Ends soon · auto-renew is off'**
  String get membershipEndsSoon;

  /// Membership hero: title of the auto-renew switch.
  ///
  /// In en, this message translates to:
  /// **'Auto-renew'**
  String get membershipAutoRenew;

  /// Membership hero: auto-renew switch subtitle when on.
  ///
  /// In en, this message translates to:
  /// **'Charged automatically each period.'**
  String get membershipAutoRenewOnSubtitle;

  /// Membership hero: auto-renew switch subtitle when off.
  ///
  /// In en, this message translates to:
  /// **'Off. Benefits end with the current period.'**
  String get membershipAutoRenewOffSubtitle;

  /// Membership hero: pitch shown to a member on the free tier.
  ///
  /// In en, this message translates to:
  /// **'Unlock more likes, messages and spotlight with a plan below. Pay by card, cancel any time.'**
  String get membershipFreeHeroBody;

  /// Membership hero: status chip for the free tier.
  ///
  /// In en, this message translates to:
  /// **'Free'**
  String get membershipStatusFree;

  /// Membership hero: status chip when a renewal charge failed.
  ///
  /// In en, this message translates to:
  /// **'Payment due'**
  String get membershipStatusPaymentDue;

  /// Membership hero: status chip when the plan ends at the period end.
  ///
  /// In en, this message translates to:
  /// **'Ending'**
  String get membershipStatusEnding;

  /// Membership hero: status chip for an active paid plan.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get membershipStatusActive;

  /// Membership: billing cycle toggle segment.
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get membershipCycleMonthly;

  /// Membership: billing cycle toggle segment.
  ///
  /// In en, this message translates to:
  /// **'Yearly'**
  String get membershipCycleYearly;

  /// Membership plan card: uppercase badge on the member's current plan.
  ///
  /// In en, this message translates to:
  /// **'YOUR PLAN'**
  String get membershipBadgeYourPlan;

  /// Membership plan card: uppercase badge on the highlighted plan.
  ///
  /// In en, this message translates to:
  /// **'MOST POPULAR'**
  String get membershipBadgeMostPopular;

  /// Membership plan card: caption under the price.
  ///
  /// In en, this message translates to:
  /// **'per month'**
  String get membershipPerMonth;

  /// Membership plan card: caption under the price.
  ///
  /// In en, this message translates to:
  /// **'per year'**
  String get membershipPerYear;

  /// Membership plan card: yearly saving versus twelve monthly payments.
  ///
  /// In en, this message translates to:
  /// **'Save {percent}%'**
  String membershipSavePercent(int percent);

  /// Membership plan card: daily like allowance pill.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 like/day} other{{count} likes/day}}'**
  String membershipQuotaLikesPerDay(int count);

  /// Membership plan card: daily message allowance pill.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 message/day} other{{count} messages/day}}'**
  String membershipQuotaMessagesPerDay(int count);

  /// Membership plan card and quota labels: unlimited daily likes.
  ///
  /// In en, this message translates to:
  /// **'Unlimited likes'**
  String get membershipQuotaUnlimitedLikes;

  /// Membership plan card and quota labels: unlimited daily messages.
  ///
  /// In en, this message translates to:
  /// **'Unlimited messages'**
  String get membershipQuotaUnlimitedMessages;

  /// Membership plan card: disabled button on the plan the member already has.
  ///
  /// In en, this message translates to:
  /// **'Your current plan'**
  String get membershipYourCurrentPlan;

  /// Membership plan card: button label while a plan switch is in flight.
  ///
  /// In en, this message translates to:
  /// **'Switching…'**
  String get membershipSwitching;

  /// Membership plan card: button label while the hosted checkout is being created.
  ///
  /// In en, this message translates to:
  /// **'Opening secure checkout…'**
  String get membershipOpeningSecureCheckout;

  /// Membership plan card: button to switch to this plan.
  ///
  /// In en, this message translates to:
  /// **'Switch to {plan}'**
  String membershipSwitchToPlan(String plan);

  /// Membership plan card: button starting a card subscription.
  ///
  /// In en, this message translates to:
  /// **'Subscribe with card'**
  String get membershipSubscribeWithCard;

  /// Membership plan card: note when a plan switch is blocked by an unpaid renewal.
  ///
  /// In en, this message translates to:
  /// **'Settle the outstanding payment on your current plan before switching.'**
  String get membershipSettleBeforeSwitch;

  /// Membership payment history: status of a charged-back payment.
  ///
  /// In en, this message translates to:
  /// **'Chargeback'**
  String get membershipPaymentChargeback;

  /// Membership payment history: status of a disputed payment.
  ///
  /// In en, this message translates to:
  /// **'Disputed'**
  String get membershipPaymentDisputed;

  /// Membership payment history: status of a fully refunded payment.
  ///
  /// In en, this message translates to:
  /// **'Refunded'**
  String get membershipPaymentRefunded;

  /// Membership payment history: status of a partly refunded payment.
  ///
  /// In en, this message translates to:
  /// **'Partly refunded'**
  String get membershipPaymentPartlyRefunded;

  /// Membership payment history: status of a failed payment.
  ///
  /// In en, this message translates to:
  /// **'Failed'**
  String get membershipPaymentFailed;

  /// Membership payment history: status of a successful payment.
  ///
  /// In en, this message translates to:
  /// **'Paid'**
  String get membershipPaymentPaid;

  /// Membership payment history: status of a payment not yet settled.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get membershipPaymentPending;

  /// Membership payment history: first charge of a new subscription.
  ///
  /// In en, this message translates to:
  /// **'First charge'**
  String get membershipPaymentReasonFirstCharge;

  /// Membership payment history: renewal charge.
  ///
  /// In en, this message translates to:
  /// **'Renewal'**
  String get membershipPaymentReasonRenewal;

  /// Membership payment history: charge from a plan change.
  ///
  /// In en, this message translates to:
  /// **'Plan change'**
  String get membershipPaymentReasonPlanChange;

  /// Membership payment history: coin pack purchase.
  ///
  /// In en, this message translates to:
  /// **'Coins'**
  String get membershipPaymentReasonCoins;

  /// Membership payment history: plan activated by the local development backend.
  ///
  /// In en, this message translates to:
  /// **'Local activation'**
  String get membershipPaymentReasonLocalActivation;

  /// Membership payment history: generic card payment.
  ///
  /// In en, this message translates to:
  /// **'Card payment'**
  String get membershipPaymentReasonCard;

  /// Membership payment history: payment of unknown kind.
  ///
  /// In en, this message translates to:
  /// **'Payment'**
  String get membershipPaymentReasonOther;

  /// Payment account card: mode chip for the local sandbox provider.
  ///
  /// In en, this message translates to:
  /// **'Local test · no real charge'**
  String get paymentModeSandbox;

  /// Payment account card: mode chip for Stripe test mode. Keep the brand Stripe.
  ///
  /// In en, this message translates to:
  /// **'Stripe test · no real charge'**
  String get paymentModeStripeTest;

  /// Payment account card: mode chip for real payments.
  ///
  /// In en, this message translates to:
  /// **'Live payments'**
  String get paymentModeLive;

  /// Payment account card: mode chip when payments are disabled.
  ///
  /// In en, this message translates to:
  /// **'Payments unavailable'**
  String get paymentModeUnavailable;

  /// Payment account card: title.
  ///
  /// In en, this message translates to:
  /// **'Your payment account'**
  String get paymentAccountTitle;

  /// Payment account card: name shown when the account has no display name.
  ///
  /// In en, this message translates to:
  /// **'Signed-in member'**
  String get paymentAccountSignedInMember;

  /// Payment account card: payment method heading when cards are accepted.
  ///
  /// In en, this message translates to:
  /// **'Credit or debit card'**
  String get paymentAccountCardTitle;

  /// Payment account card: payment method heading when card checkout is disabled.
  ///
  /// In en, this message translates to:
  /// **'Card checkout is unavailable'**
  String get paymentAccountCardUnavailableTitle;

  /// Payment account card: explanation when cards are accepted.
  ///
  /// In en, this message translates to:
  /// **'Use the hosted checkout to enter your card. Membership and payment history belong to this account.'**
  String get paymentAccountCardBody;

  /// Payment account card: explanation when card checkout is disabled.
  ///
  /// In en, this message translates to:
  /// **'You can keep using your existing account. New card payments are not enabled.'**
  String get paymentAccountCardUnavailableBody;

  /// Payment account card: test-mode hint. cardNumber is the provider's published test card number; never translate it.
  ///
  /// In en, this message translates to:
  /// **'For testing, use {cardNumber}, a future expiry and any three-digit CVC. Use test details only.'**
  String paymentAccountTestCardHint(String cardNumber);

  /// Payment account card: heading of an unfinished card update checkout.
  ///
  /// In en, this message translates to:
  /// **'Unfinished card update'**
  String get paymentAccountUnfinishedCardUpdate;

  /// Payment account card: heading of an unfinished checkout. plan is the plan code from the server.
  ///
  /// In en, this message translates to:
  /// **'Unfinished {plan} checkout'**
  String paymentAccountUnfinishedCheckout(String plan);

  /// Payment account card: hint under an unfinished checkout.
  ///
  /// In en, this message translates to:
  /// **'Check the latest status or continue the same checkout.'**
  String get paymentAccountPendingHint;

  /// Payment account card: button re-checking an unfinished checkout.
  ///
  /// In en, this message translates to:
  /// **'Check status'**
  String get paymentAccountCheckStatus;

  /// Payment account card: button reopening an unfinished checkout.
  ///
  /// In en, this message translates to:
  /// **'Resume checkout'**
  String get paymentAccountResumeCheckout;

  /// Checkout web view: app bar title. title is a plan name, 'your card' or a coin amount.
  ///
  /// In en, this message translates to:
  /// **'Pay for {title}'**
  String paymentCheckoutPayFor(String title);

  /// Checkout web view: tooltip of the close button.
  ///
  /// In en, this message translates to:
  /// **'Close checkout'**
  String get paymentCheckoutClose;

  /// Checkout web view: footer note under the provider page.
  ///
  /// In en, this message translates to:
  /// **'Card details are entered on the payment provider\'s secure page.'**
  String get paymentCheckoutSecureNote;

  /// Web checkout waiting sheet: headline while the provider page is open in another tab. title is a plan name, 'your card' or a coin amount.
  ///
  /// In en, this message translates to:
  /// **'Complete the checkout for {title} in the new tab'**
  String paymentCheckoutCompleteInNewTab(String title);

  /// Web checkout waiting sheet: explanation.
  ///
  /// In en, this message translates to:
  /// **'Your card details are entered on the payment provider\'s secure page. Come back here when it says the payment is complete.'**
  String get paymentCheckoutWaitingBody;

  /// Web checkout waiting sheet: button the member taps after paying.
  ///
  /// In en, this message translates to:
  /// **'Check confirmation'**
  String get paymentCheckoutCheckConfirmation;

  /// Web checkout waiting sheet: button leaving without confirming.
  ///
  /// In en, this message translates to:
  /// **'Back to account'**
  String get paymentCheckoutBackToAccount;

  /// Wallet screen: app bar title.
  ///
  /// In en, this message translates to:
  /// **'Wallet & Payments'**
  String get paymentWalletTitle;

  /// Wallet screen: banner in test payment mode.
  ///
  /// In en, this message translates to:
  /// **'Test payments · no real charge. Use test card details only.'**
  String get paymentWalletTestNote;

  /// Wallet screen: heading above coin packs.
  ///
  /// In en, this message translates to:
  /// **'Popular top-ups'**
  String get paymentWalletPopularTopUps;

  /// Wallet screen: note under the coin packs heading.
  ///
  /// In en, this message translates to:
  /// **'Pay by card on the secure checkout page. Coins land in your wallet as soon as the payment settles.'**
  String get paymentWalletTopUpsIntro;

  /// Wallet screen: shown when the server has no card payment provider.
  ///
  /// In en, this message translates to:
  /// **'Card payments are not enabled on this server yet.'**
  String get paymentWalletCardsDisabled;

  /// Wallet screen: shown when no coin packs are on sale.
  ///
  /// In en, this message translates to:
  /// **'No coin packs are on sale right now.'**
  String get paymentWalletNoPacks;

  /// Wallet screen: heading of the purchase history.
  ///
  /// In en, this message translates to:
  /// **'Wallet activity'**
  String get paymentWalletActivity;

  /// Wallet screen: empty purchase history.
  ///
  /// In en, this message translates to:
  /// **'No coin purchases yet.'**
  String get paymentWalletNoPurchases;

  /// Wallet screen: footnote. Keep the brand Connect.
  ///
  /// In en, this message translates to:
  /// **'Coins are used for gifts and boosts inside Connect. Purchases are final once settled; card details stay with the payment provider.'**
  String get paymentWalletFooter;

  /// Wallet: a coin amount, used for the balance and as the checkout title.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 coin} other{{count} coins}}'**
  String paymentCoinCount(int count);

  /// Wallet: snackbar after a coin purchase is credited.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 coin added to your wallet.} other{{count} coins added to your wallet.}}'**
  String paymentCoinsAdded(int count);

  /// Wallet coin pack card: unit under the big coin number (the number is shown separately above).
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{coin} other{coins}}'**
  String paymentPackCoinsUnit(int count);

  /// Wallet coin pack card: unit plus bonus under the big coin number. count is the total coins, bonus the extra coins included.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{coin · +{bonus} bonus} other{coins · +{bonus} bonus}}'**
  String paymentPackCoinsUnitBonus(int count, int bonus);

  /// Wallet: snackbar when a coin checkout expired or was cancelled.
  ///
  /// In en, this message translates to:
  /// **'This checkout session has ended. Review your payment history before trying again.'**
  String get paymentWalletCheckoutEnded;

  /// Wallet screen: caption above the coin balance. Glow is the wallet's name; keep it.
  ///
  /// In en, this message translates to:
  /// **'Glow wallet balance'**
  String get paymentWalletBalanceLabel;

  /// Wallet history: coins added by the support team.
  ///
  /// In en, this message translates to:
  /// **'Top-up from support'**
  String get paymentWalletSourceSupport;

  /// Wallet history: coins from a promotion.
  ///
  /// In en, this message translates to:
  /// **'Promotion'**
  String get paymentWalletSourcePromo;

  /// Wallet history: coins bought by card.
  ///
  /// In en, this message translates to:
  /// **'Coin purchase'**
  String get paymentWalletSourcePurchase;

  /// Membership: error when no member is signed in.
  ///
  /// In en, this message translates to:
  /// **'Please sign in to manage subscriptions.'**
  String get paymentErrorSignInSubscriptions;

  /// Wallet: error when no member is signed in.
  ///
  /// In en, this message translates to:
  /// **'Please sign in to manage your wallet.'**
  String get paymentErrorSignInWallet;

  /// Membership: fallback error when subscription details fail to load.
  ///
  /// In en, this message translates to:
  /// **'Unable to load subscription details.'**
  String get paymentErrorLoadSubscription;

  /// Wallet: fallback error when the wallet fails to load.
  ///
  /// In en, this message translates to:
  /// **'Unable to load your wallet.'**
  String get paymentErrorLoadWallet;

  /// Membership: fallback error when a subscription checkout cannot be created.
  ///
  /// In en, this message translates to:
  /// **'Unable to start checkout right now.'**
  String get paymentErrorStartCheckoutNow;

  /// Wallet: fallback error when a coin checkout cannot be created.
  ///
  /// In en, this message translates to:
  /// **'Unable to start checkout.'**
  String get paymentErrorStartCheckout;

  /// Membership and wallet: fallback error while polling a checkout fails.
  ///
  /// In en, this message translates to:
  /// **'Unable to confirm the payment yet.'**
  String get paymentErrorConfirmPayment;

  /// Membership: fallback error when auto-renew cannot be turned back on.
  ///
  /// In en, this message translates to:
  /// **'Unable to turn auto-renew back on.'**
  String get paymentErrorAutoRenewOn;

  /// Membership: fallback error when auto-renew cannot be turned off.
  ///
  /// In en, this message translates to:
  /// **'Unable to turn off auto-renew.'**
  String get paymentErrorAutoRenewOff;

  /// Membership: fallback error when a plan switch fails.
  ///
  /// In en, this message translates to:
  /// **'Unable to change plan.'**
  String get paymentErrorChangePlan;

  /// Membership: fallback error when a card update checkout cannot be created.
  ///
  /// In en, this message translates to:
  /// **'Unable to update the card.'**
  String get paymentErrorUpdateCard;

  /// Membership (debug sandbox only): fallback error when a simulated renewal event fails.
  ///
  /// In en, this message translates to:
  /// **'Sandbox simulation failed.'**
  String get paymentErrorSandboxFailed;

  /// Membership and wallet: error when the API cannot be reached.
  ///
  /// In en, this message translates to:
  /// **'Cannot reach the local service. Check that the API is running.'**
  String get paymentErrorUnreachable;

  /// Daily quota label: likes remaining today out of the plan's daily limit.
  ///
  /// In en, this message translates to:
  /// **'{limit, plural, =1{{remaining} of 1 like left today} other{{remaining} of {limit} likes left today}}'**
  String membershipQuotaLikesLeftToday(int remaining, int limit);

  /// Daily quota label: messages remaining today out of the plan's daily limit.
  ///
  /// In en, this message translates to:
  /// **'{limit, plural, =1{{remaining} of 1 message left today} other{{remaining} of {limit} messages left today}}'**
  String membershipQuotaMessagesLeftToday(int remaining, int limit);

  /// Daily limit reached: headline after the last like of the day. plan is the plan name from the server.
  ///
  /// In en, this message translates to:
  /// **'{limit, plural, =1{You\'ve used today\'s 1 like on {plan}} other{You\'ve used today\'s {limit} likes on {plan}}}'**
  String membershipLikeLimitHeadline(int limit, String plan);

  /// Daily limit reached: headline after the last message of the day. plan is the plan name from the server.
  ///
  /// In en, this message translates to:
  /// **'{limit, plural, =1{You\'ve used today\'s 1 message on {plan}} other{You\'ve used today\'s {limit} messages on {plan}}}'**
  String membershipMessageLimitHeadline(int limit, String plan);

  /// Daily limit: when the quota resets, as a local time such as 05:30.
  ///
  /// In en, this message translates to:
  /// **'Resets at {time}'**
  String membershipQuotaResetsAt(String time);

  /// Matches header pill: number of matches.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{{count} match} other{{count} matches}}'**
  String matchesCount(int count);

  /// Matches screen: subtitle in the Conversations view.
  ///
  /// In en, this message translates to:
  /// **'A little closer, one message at a time.'**
  String get matchesSubtitleConversations;

  /// Matches screen: subtitle in the Your matches view.
  ///
  /// In en, this message translates to:
  /// **'People you chose. Possibilities you shape together.'**
  String get matchesSubtitlePeople;

  /// Matches screen: search field hint in Conversations view.
  ///
  /// In en, this message translates to:
  /// **'Search conversations'**
  String get matchesSearchConversations;

  /// Matches screen: search field hint in Your matches view.
  ///
  /// In en, this message translates to:
  /// **'Search your matches'**
  String get matchesSearchMatches;

  /// Matches screen: chip showing all conversations.
  ///
  /// In en, this message translates to:
  /// **'All conversations'**
  String get matchesFilterAllConversations;

  /// Matches screen: chip showing only unread conversations, with how many are unread.
  ///
  /// In en, this message translates to:
  /// **'Unread · {count}'**
  String matchesFilterUnread(int count);

  /// Matches screen: loading message.
  ///
  /// In en, this message translates to:
  /// **'Loading matches...'**
  String get matchesLoading;

  /// Matches screen: title when matches could not be loaded.
  ///
  /// In en, this message translates to:
  /// **'Unable to load matches'**
  String get matchesLoadErrorTitle;

  /// Matches screen: retry button after a load error.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get matchesRetry;

  /// Matches screen: title when there are no matches.
  ///
  /// In en, this message translates to:
  /// **'No matches yet'**
  String get matchesEmptyTitle;

  /// Matches screen: empty state when trust filters hid matches. 'Discover' is the Discover tab.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, other{Trust filters hid {count} match(es). Try relaxing trust filters from Discover.}}'**
  String matchesTrustFilteredHint(int count);

  /// Matches screen: empty state hint. 'Today' is the Today tab.
  ///
  /// In en, this message translates to:
  /// **'Visit Today to discover someone you’d like to meet.'**
  String get matchesEmptyBody;

  /// Matches screen: no conversations match the search/filter.
  ///
  /// In en, this message translates to:
  /// **'No conversations here yet. Try another search or filter.'**
  String get matchesNoConversationResults;

  /// Matches screen: no matches match the name search.
  ///
  /// In en, this message translates to:
  /// **'No matches found. Try another name.'**
  String get matchesNoPeopleResults;

  /// Matches screen: view tab listing your matches.
  ///
  /// In en, this message translates to:
  /// **'Your matches'**
  String get matchesTabPeople;

  /// Matches screen: view tab listing conversations.
  ///
  /// In en, this message translates to:
  /// **'Conversations'**
  String get matchesTabConversations;

  /// Match options sheet: start a video call session.
  ///
  /// In en, this message translates to:
  /// **'Start call session'**
  String get matchesActionStartCall;

  /// Match options sheet: start a two-person mini activity.
  ///
  /// In en, this message translates to:
  /// **'Start an activity'**
  String get matchesActionStartActivity;

  /// Match options sheet and match card: propose a date plan.
  ///
  /// In en, this message translates to:
  /// **'Plan a date'**
  String get matchesActionPlanDate;

  /// Match options sheet: subtitle under 'Plan a date'.
  ///
  /// In en, this message translates to:
  /// **'Choose a time and what you want to share'**
  String get matchesActionPlanDateSubtitle;

  /// Snackbar after sending a date plan.
  ///
  /// In en, this message translates to:
  /// **'Plan sent to {name}.'**
  String matchesPlanSent(String name);

  /// Match options sheet: propose leaving the app together as a couple.
  ///
  /// In en, this message translates to:
  /// **'We found each other'**
  String get matchesActionGraduate;

  /// Match options sheet: subtitle under 'We found each other'. Connect is the brand.
  ///
  /// In en, this message translates to:
  /// **'Leave Connect together; your chat stays'**
  String get matchesActionGraduateSubtitle;

  /// Snackbar after asking a match to leave the app together.
  ///
  /// In en, this message translates to:
  /// **'Asked {name} to leave together. They can confirm from your chat.'**
  String matchesGraduationAsked(String name);

  /// Match options sheet: send a gentle nudge to the match.
  ///
  /// In en, this message translates to:
  /// **'Send a nudge'**
  String get matchesActionNudge;

  /// Snackbar after sending a nudge.
  ///
  /// In en, this message translates to:
  /// **'Nudge sent to {name}.'**
  String matchesNudgeSent(String name);

  /// Snackbar when a nudge could not be sent (fallback when the server gives no reason).
  ///
  /// In en, this message translates to:
  /// **'Unable to send this nudge.'**
  String get matchesNudgeFailed;

  /// Match options sheet and confirm button: end the match / close the conversation.
  ///
  /// In en, this message translates to:
  /// **'Close conversation'**
  String get matchesActionClose;

  /// Match options sheet: subtitle under 'Close conversation'.
  ///
  /// In en, this message translates to:
  /// **'Make space, without an explanation.'**
  String get matchesActionCloseSubtitle;

  /// Close conversation confirmation dialog title.
  ///
  /// In en, this message translates to:
  /// **'Close this conversation?'**
  String get matchesCloseDialogTitle;

  /// Close conversation confirmation dialog body.
  ///
  /// In en, this message translates to:
  /// **'It is okay if this connection is not for you. This ends the match. You do not need to send an explanation. Reporting remains a separate choice.'**
  String get matchesCloseDialogBody;

  /// Close conversation dialog: cancel button, keep the match.
  ///
  /// In en, this message translates to:
  /// **'Keep talking'**
  String get matchesCloseDialogKeep;

  /// Match options sheet: report the user.
  ///
  /// In en, this message translates to:
  /// **'Report'**
  String get matchesActionReport;

  /// Snackbar after a report was submitted.
  ///
  /// In en, this message translates to:
  /// **'Report submitted. Thank you.'**
  String get matchesReportSubmitted;

  /// Snackbar action after a report: open moderation appeals.
  ///
  /// In en, this message translates to:
  /// **'Appeal'**
  String get matchesReportAppeal;

  /// Prefilled reason in the moderation appeal form after reporting a match.
  ///
  /// In en, this message translates to:
  /// **'Review moderation outcome for report on user {userId}'**
  String matchesAppealReason(String userId);

  /// Match card: subtitle under the match's name.
  ///
  /// In en, this message translates to:
  /// **'You both chose to connect'**
  String get matchesBothChose;

  /// Match card: tooltip for the options button.
  ///
  /// In en, this message translates to:
  /// **'Match options for {name}'**
  String matchesOptionsTooltip(String name);

  /// Match card: chat button when there are unread messages.
  ///
  /// In en, this message translates to:
  /// **'Chat · {count} unread'**
  String matchesChatUnread(int count);

  /// Match card: open the chat.
  ///
  /// In en, this message translates to:
  /// **'Open chat'**
  String get matchesOpenChat;

  /// Match card: open First Chapter (feature name).
  ///
  /// In en, this message translates to:
  /// **'First Chapter'**
  String get matchesFirstChapter;

  /// Shown instead of a match's name when the server has none.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get matchesUnknownName;

  /// Conversation preview when no message has been sent yet.
  ///
  /// In en, this message translates to:
  /// **'Say hi 👋'**
  String get matchesSayHi;

  /// Conversation row: name used when the match's name is missing.
  ///
  /// In en, this message translates to:
  /// **'Your match'**
  String get matchesFallbackName;

  /// Conversation row: preview when there is no message yet.
  ///
  /// In en, this message translates to:
  /// **'Start your conversation'**
  String get matchesFallbackMessage;

  /// Conversation row: preview when the last message is a gift.
  ///
  /// In en, this message translates to:
  /// **'A little gift in your conversation'**
  String get matchesGiftPreview;

  /// Conversation row: tooltip for the options button.
  ///
  /// In en, this message translates to:
  /// **'Conversation options for {name}'**
  String matchesConversationOptionsTooltip(String name);

  /// Conversation row: last message less than a minute ago.
  ///
  /// In en, this message translates to:
  /// **'Now'**
  String get matchesTimeNow;

  /// Conversation row: last message N minutes ago (short).
  ///
  /// In en, this message translates to:
  /// **'{minutes}m ago'**
  String matchesTimeMinutesAgo(int minutes);

  /// Conversation row: last message N hours ago (short).
  ///
  /// In en, this message translates to:
  /// **'{hours}h ago'**
  String matchesTimeHoursAgo(int hours);

  /// Conversation row: last message earlier today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get matchesTimeToday;

  /// Conversation row: last message yesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get matchesTimeYesterday;

  /// New match screen: app bar title.
  ///
  /// In en, this message translates to:
  /// **'New Match'**
  String get matchesNewMatchTitle;

  /// New match screen: headline.
  ///
  /// In en, this message translates to:
  /// **'It\'s a match!'**
  String get matchesItsAMatch;

  /// New match screen: body text.
  ///
  /// In en, this message translates to:
  /// **'You and {name} liked each other'**
  String matchesLikedEachOther(String name);

  /// New match screen: open the chat.
  ///
  /// In en, this message translates to:
  /// **'Send Message'**
  String get matchesSendMessage;

  /// New match screen: close and keep browsing.
  ///
  /// In en, this message translates to:
  /// **'Keep Swiping'**
  String get matchesKeepSwiping;

  /// Matches error: user is not signed in.
  ///
  /// In en, this message translates to:
  /// **'Please login to see matches.'**
  String get matchesErrorLoginRequired;

  /// Matches error: loading failed (fallback when the server gives no reason).
  ///
  /// In en, this message translates to:
  /// **'Failed to load matches. Please try again.'**
  String get matchesErrorLoadFailed;

  /// Matches error: ending the match failed.
  ///
  /// In en, this message translates to:
  /// **'Failed to unmatch.'**
  String get matchesErrorUnmatchFailed;

  /// Matches error: marking messages as read failed.
  ///
  /// In en, this message translates to:
  /// **'Failed to mark as read.'**
  String get matchesErrorMarkReadFailed;

  /// Matching error: the signed-in user session is missing.
  ///
  /// In en, this message translates to:
  /// **'User session not available.'**
  String get matchesErrorSessionUnavailable;

  /// Trust badge name: answers profile prompts.
  ///
  /// In en, this message translates to:
  /// **'Prompt Completer'**
  String get matchesTrustBadgePromptCompleter;

  /// Trust badge name: communicates respectfully.
  ///
  /// In en, this message translates to:
  /// **'Respectful Communicator'**
  String get matchesTrustBadgeRespectful;

  /// Trust badge name: consistent profile.
  ///
  /// In en, this message translates to:
  /// **'Consistent Profile'**
  String get matchesTrustBadgeConsistent;

  /// Trust badge name: verified and active.
  ///
  /// In en, this message translates to:
  /// **'Verified & Active'**
  String get matchesTrustBadgeVerifiedActive;

  /// Trust filter error: loading failed (fallback).
  ///
  /// In en, this message translates to:
  /// **'Failed to load trust filters. Please try again.'**
  String get matchesTrustErrorLoad;

  /// Trust filter error: saving failed (fallback).
  ///
  /// In en, this message translates to:
  /// **'Failed to save trust filters. Please try again.'**
  String get matchesTrustErrorSave;

  /// Gesture timeline error: loading failed.
  ///
  /// In en, this message translates to:
  /// **'Failed to load timeline'**
  String get matchesGestureErrorLoad;

  /// Gesture error: gestures are locked until a pending conversation becomes a match.
  ///
  /// In en, this message translates to:
  /// **'Gestures unlock after this pending conversation becomes a real match.'**
  String get matchesGestureErrorPending;

  /// Gesture error: sending failed (fallback).
  ///
  /// In en, this message translates to:
  /// **'Failed to send gesture.'**
  String get matchesGestureErrorSend;

  /// Gesture error: accepting/declining failed.
  ///
  /// In en, this message translates to:
  /// **'Failed to update gesture status.'**
  String get matchesGestureErrorUpdate;

  /// Activity screen title: a two-minute this-or-that game for two matches.
  ///
  /// In en, this message translates to:
  /// **'2-Minute This-or-That'**
  String get matchesActivityTitle;

  /// Activity screen: tooltip to start a new session.
  ///
  /// In en, this message translates to:
  /// **'Start a new session'**
  String get matchesActivityRestartTooltip;

  /// Activity screen: heading naming the match you play with.
  ///
  /// In en, this message translates to:
  /// **'Complete this with {name}'**
  String matchesActivityCompleteWith(String name);

  /// Activity screen: instructions.
  ///
  /// In en, this message translates to:
  /// **'Answer all 8 rounds before time ends.'**
  String get matchesActivityInstructions;

  /// Activity screen: session status line; status is an already translated status word.
  ///
  /// In en, this message translates to:
  /// **'Status: {status}'**
  String matchesActivityStatus(String status);

  /// Activity session status word (lower case): in progress.
  ///
  /// In en, this message translates to:
  /// **'active'**
  String get matchesActivityStatusActive;

  /// Activity session status word (lower case): time ran out.
  ///
  /// In en, this message translates to:
  /// **'timed out'**
  String get matchesActivityStatusTimedOut;

  /// Activity session status word (lower case): time ran out before everyone finished.
  ///
  /// In en, this message translates to:
  /// **'partial timeout'**
  String get matchesActivityStatusPartialTimeout;

  /// Activity session status word (lower case): finished.
  ///
  /// In en, this message translates to:
  /// **'completed'**
  String get matchesActivityStatusCompleted;

  /// Activity screen: submit answers button.
  ///
  /// In en, this message translates to:
  /// **'Submit Responses'**
  String get matchesActivitySubmit;

  /// Activity screen: button shown when time ran out.
  ///
  /// In en, this message translates to:
  /// **'Time is up — Load Summary'**
  String get matchesActivityTimeUpLoad;

  /// Activity screen: you finished, waiting for the other person.
  ///
  /// In en, this message translates to:
  /// **'Responses sent. Waiting for the other participant to finish.'**
  String get matchesActivityWaiting;

  /// Activity screen: reload the summary.
  ///
  /// In en, this message translates to:
  /// **'Refresh Summary'**
  String get matchesActivityRefreshSummary;

  /// Activity screen: countdown; time is mm:ss.
  ///
  /// In en, this message translates to:
  /// **'Time left {time}'**
  String matchesActivityTimeLeft(String time);

  /// Activity screen: summary card title.
  ///
  /// In en, this message translates to:
  /// **'Activity Summary'**
  String get matchesActivitySummaryTitle;

  /// Activity summary: how many participants finished out of total.
  ///
  /// In en, this message translates to:
  /// **'Participants completed: {completed}/{total}'**
  String matchesActivityParticipantsCompleted(int completed, int total);

  /// Activity summary: placeholder until the summary is ready.
  ///
  /// In en, this message translates to:
  /// **'Summary will appear once available.'**
  String get matchesActivitySummaryPending;

  /// Activity summary: share the result into the chat.
  ///
  /// In en, this message translates to:
  /// **'Share Result to Chat'**
  String get matchesActivityShareResult;

  /// Chat message sent when sharing an activity result; status is a translated status word.
  ///
  /// In en, this message translates to:
  /// **'2-Min This-or-That result: {status} • {completed}/{total} completed'**
  String matchesActivityShareMessage(String status, int completed, int total);

  /// Chat message sent when sharing an activity result, with the server's insight text appended.
  ///
  /// In en, this message translates to:
  /// **'2-Min This-or-That result: {status} • {completed}/{total} completed • {insight}'**
  String matchesActivityShareMessageWithInsight(
    String status,
    int completed,
    int total,
    String insight,
  );

  /// Activity question card title: round number.
  ///
  /// In en, this message translates to:
  /// **'Round {number}'**
  String matchesActivityRound(int number);

  /// Activity error: could not start (fallback).
  ///
  /// In en, this message translates to:
  /// **'Unable to start activity right now. Please try again.'**
  String get matchesActivityErrorStart;

  /// Activity error: session not ready.
  ///
  /// In en, this message translates to:
  /// **'Session is not ready yet.'**
  String get matchesActivityErrorNotReady;

  /// Activity error: not all prompts answered.
  ///
  /// In en, this message translates to:
  /// **'Please answer all prompts before submitting.'**
  String get matchesActivityErrorAnswerAll;

  /// Activity notice: time ran out, loading the summary.
  ///
  /// In en, this message translates to:
  /// **'Time is up. Loading activity summary...'**
  String get matchesActivityErrorTimeUp;

  /// Activity error: submitting answers failed (fallback).
  ///
  /// In en, this message translates to:
  /// **'Failed to submit activity responses. Please try again.'**
  String get matchesActivityErrorSubmit;

  /// Activity error: summary not available yet (fallback).
  ///
  /// In en, this message translates to:
  /// **'Unable to fetch summary yet. Please try again.'**
  String get matchesActivityErrorSummary;

  /// This-or-that round 1: question.
  ///
  /// In en, this message translates to:
  /// **'Ideal first meetup?'**
  String get matchesActivityQ1Prompt;

  /// This-or-that round 1: first answer choice (question: Ideal first meetup?).
  ///
  /// In en, this message translates to:
  /// **'Coffee walk'**
  String get matchesActivityQ1OptionA;

  /// This-or-that round 1: second answer choice (question: Ideal first meetup?).
  ///
  /// In en, this message translates to:
  /// **'Bookstore browse'**
  String get matchesActivityQ1OptionB;

  /// This-or-that round 2: question.
  ///
  /// In en, this message translates to:
  /// **'Preferred weekend mood?'**
  String get matchesActivityQ2Prompt;

  /// This-or-that round 2: first answer choice (question: Preferred weekend mood?).
  ///
  /// In en, this message translates to:
  /// **'Stay in and recharge'**
  String get matchesActivityQ2OptionA;

  /// This-or-that round 2: second answer choice (question: Preferred weekend mood?).
  ///
  /// In en, this message translates to:
  /// **'Explore the city'**
  String get matchesActivityQ2OptionB;

  /// This-or-that round 3: question.
  ///
  /// In en, this message translates to:
  /// **'Best conversation setting?'**
  String get matchesActivityQ3Prompt;

  /// This-or-that round 3: first answer choice (question: Best conversation setting?).
  ///
  /// In en, this message translates to:
  /// **'Long walk'**
  String get matchesActivityQ3OptionA;

  /// This-or-that round 3: second answer choice (question: Best conversation setting?).
  ///
  /// In en, this message translates to:
  /// **'Cozy cafe corner'**
  String get matchesActivityQ3OptionB;

  /// This-or-that round 4: question.
  ///
  /// In en, this message translates to:
  /// **'How do you plan dates?'**
  String get matchesActivityQ4Prompt;

  /// This-or-that round 4: first answer choice (question: How do you plan dates?).
  ///
  /// In en, this message translates to:
  /// **'Spontaneous'**
  String get matchesActivityQ4OptionA;

  /// This-or-that round 4: second answer choice (question: How do you plan dates?).
  ///
  /// In en, this message translates to:
  /// **'Planned in advance'**
  String get matchesActivityQ4OptionB;

  /// This-or-that round 5: question.
  ///
  /// In en, this message translates to:
  /// **'Which matters more right now?'**
  String get matchesActivityQ5Prompt;

  /// This-or-that round 5: first answer choice (question: Which matters more right now?).
  ///
  /// In en, this message translates to:
  /// **'Consistency'**
  String get matchesActivityQ5OptionA;

  /// This-or-that round 5: second answer choice (question: Which matters more right now?).
  ///
  /// In en, this message translates to:
  /// **'Excitement'**
  String get matchesActivityQ5OptionB;

  /// This-or-that round 6: question.
  ///
  /// In en, this message translates to:
  /// **'Conflict style preference?'**
  String get matchesActivityQ6Prompt;

  /// This-or-that round 6: first answer choice (question: Conflict style preference?).
  ///
  /// In en, this message translates to:
  /// **'Resolve same day'**
  String get matchesActivityQ6OptionA;

  /// This-or-that round 6: second answer choice (question: Conflict style preference?).
  ///
  /// In en, this message translates to:
  /// **'Take space then revisit'**
  String get matchesActivityQ6OptionB;

  /// This-or-that round 7: question.
  ///
  /// In en, this message translates to:
  /// **'Shared activity pick?'**
  String get matchesActivityQ7Prompt;

  /// This-or-that round 7: first answer choice (question: Shared activity pick?).
  ///
  /// In en, this message translates to:
  /// **'Cook together'**
  String get matchesActivityQ7OptionA;

  /// This-or-that round 7: second answer choice (question: Shared activity pick?).
  ///
  /// In en, this message translates to:
  /// **'Workout together'**
  String get matchesActivityQ7OptionB;

  /// This-or-that round 8: question.
  ///
  /// In en, this message translates to:
  /// **'Pace preference?'**
  String get matchesActivityQ8Prompt;

  /// This-or-that round 8: first answer choice (question: Pace preference?).
  ///
  /// In en, this message translates to:
  /// **'Steady and intentional'**
  String get matchesActivityQ8OptionA;

  /// This-or-that round 8: second answer choice (question: Pace preference?).
  ///
  /// In en, this message translates to:
  /// **'Fast and energetic'**
  String get matchesActivityQ8OptionB;

  /// City pilot: a change could not be confirmed (fallback when the server gives no reason).
  ///
  /// In en, this message translates to:
  /// **'We couldn’t confirm that change. Refresh to check before trying again.'**
  String get cityPilotSaveFailed;

  /// City pilot: leave confirmation dialog title.
  ///
  /// In en, this message translates to:
  /// **'Leave the city pilot?'**
  String get cityPilotLeaveTitle;

  /// City pilot: leave confirmation dialog body.
  ///
  /// In en, this message translates to:
  /// **'Your pilot bookings will be cancelled and experience feedback removed. Your activity will stop contributing to current pilot results. Your matches and conversations stay. You cannot rejoin this pilot.'**
  String get cityPilotLeaveBody;

  /// City pilot leave dialog: cancel, stay in the pilot.
  ///
  /// In en, this message translates to:
  /// **'Stay in pilot'**
  String get cityPilotStay;

  /// City pilot: leave the pilot (button and dialog confirm).
  ///
  /// In en, this message translates to:
  /// **'Leave pilot'**
  String get cityPilotLeave;

  /// City pilot: notice after leaving.
  ///
  /// In en, this message translates to:
  /// **'You have left the pilot. Your matches stay with you.'**
  String get cityPilotLeftNotice;

  /// City pilot: booking dialog title; title is the experience name from the server.
  ///
  /// In en, this message translates to:
  /// **'Join {title}?'**
  String cityPilotJoinEventTitle(String title);

  /// City pilot: booking dialog body with safety terms; values come from the server.
  ///
  /// In en, this message translates to:
  /// **'This experience is free. Meet at the public venue, respect other people’s boundaries, and arrange your own travel. You can leave at any time.\n\nHost: {host}\nSafety contact: {safetyContact}\n\nAccessibility: {accessibility}\n\nFor immediate danger, contact local emergency services.'**
  String cityPilotBookingTerms(
    String host,
    String safetyContact,
    String accessibility,
  );

  /// City pilot booking dialog: accept terms and reserve.
  ///
  /// In en, this message translates to:
  /// **'Accept & reserve a place'**
  String get cityPilotAcceptReserve;

  /// City pilot: notice after reserving a place.
  ///
  /// In en, this message translates to:
  /// **'Your place is reserved. You can cancel here at any time.'**
  String get cityPilotReservedNotice;

  /// City pilot feedback dialog title.
  ///
  /// In en, this message translates to:
  /// **'How was the experience?'**
  String get cityPilotFeedbackTitle;

  /// City pilot feedback dialog intro.
  ///
  /// In en, this message translates to:
  /// **'Optional. Answers contribute to the pilot’s combined results. They aren’t shown to other members or the host.'**
  String get cityPilotFeedbackIntro;

  /// City pilot feedback: did you attend the experience?
  ///
  /// In en, this message translates to:
  /// **'Did you attend?'**
  String get cityPilotDidYouAttend;

  /// City pilot feedback: yes, I attended.
  ///
  /// In en, this message translates to:
  /// **'Yes, I went'**
  String get cityPilotAttendedYes;

  /// City pilot feedback: no, I could not attend.
  ///
  /// In en, this message translates to:
  /// **'I couldn’t make it'**
  String get cityPilotAttendedNo;

  /// City pilot feedback: optional question.
  ///
  /// In en, this message translates to:
  /// **'Was it worth your time? (optional)'**
  String get cityPilotWorthwhileQuestion;

  /// City pilot feedback: it was not worth it this time.
  ///
  /// In en, this message translates to:
  /// **'Not this time'**
  String get cityPilotNotThisTime;

  /// City pilot feedback dialog: skip without answering.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get cityPilotSkip;

  /// City pilot feedback dialog: submit.
  ///
  /// In en, this message translates to:
  /// **'Share feedback'**
  String get cityPilotShareFeedback;

  /// City pilot: notice after sending feedback.
  ///
  /// In en, this message translates to:
  /// **'Thank you. Your feedback has been recorded privately.'**
  String get cityPilotFeedbackThanks;

  /// City pilot: shown instead of a date/time that is not set yet.
  ///
  /// In en, this message translates to:
  /// **'Time to be confirmed'**
  String get cityPilotTimeTbc;

  /// City pilot screen title.
  ///
  /// In en, this message translates to:
  /// **'The city pilot'**
  String get cityPilotTitle;

  /// City pilot: refresh button tooltip.
  ///
  /// In en, this message translates to:
  /// **'Refresh pilot'**
  String get cityPilotRefreshTooltip;

  /// City pilot hero headline (two lines).
  ///
  /// In en, this message translates to:
  /// **'A little closer.\nA lot more real.'**
  String get cityPilotHeroTitle;

  /// City pilot hero body.
  ///
  /// In en, this message translates to:
  /// **'One city. A small community. More chances for a conversation to become a plan.'**
  String get cityPilotHeroBody;

  /// City pilot step 1 title.
  ///
  /// In en, this message translates to:
  /// **'Start with a conversation'**
  String get cityPilotStep1Title;

  /// City pilot step 1 body.
  ///
  /// In en, this message translates to:
  /// **'Meet at your pace through your existing introductions.'**
  String get cityPilotStep1Body;

  /// City pilot step 2 title.
  ///
  /// In en, this message translates to:
  /// **'Make room for a real date'**
  String get cityPilotStep2Title;

  /// City pilot step 2 body.
  ///
  /// In en, this message translates to:
  /// **'Shape a plan together. Share how it went only if you want to.'**
  String get cityPilotStep2Body;

  /// City pilot step 3 title.
  ///
  /// In en, this message translates to:
  /// **'Try something together'**
  String get cityPilotStep3Title;

  /// City pilot step 3 body.
  ///
  /// In en, this message translates to:
  /// **'Small, hosted experiences come after the first pilot review.'**
  String get cityPilotStep3Body;

  /// City pilot: accessibility label of the saving progress bar.
  ///
  /// In en, this message translates to:
  /// **'Saving pilot preference'**
  String get cityPilotSaving;

  /// City pilot: title when the pilot could not be loaded.
  ///
  /// In en, this message translates to:
  /// **'Your pilot is unavailable'**
  String get cityPilotUnavailableTitle;

  /// City pilot: body when the pilot could not be loaded.
  ///
  /// In en, this message translates to:
  /// **'Check your connection and refresh to see your latest participation and bookings.'**
  String get cityPilotUnavailableBody;

  /// City pilot: title when no pilot is open for the user's city.
  ///
  /// In en, this message translates to:
  /// **'Coming to a city near you'**
  String get cityPilotComingSoonTitle;

  /// City pilot: body when no pilot is open for the user's city.
  ///
  /// In en, this message translates to:
  /// **'There isn’t an open pilot for your profile city yet. When one opens, you can choose whether to take part. Your current dating experience carries on as usual.'**
  String get cityPilotComingSoonBody;

  /// City pilot panel title when the user has joined; city is from the server.
  ///
  /// In en, this message translates to:
  /// **'{city} · You’re part of it'**
  String cityPilotPanelTitleJoined(String city);

  /// City pilot panel title when the user has not joined; city is from the server.
  ///
  /// In en, this message translates to:
  /// **'{city} · City pilot'**
  String cityPilotPanelTitleOpen(String city);

  /// City pilot: when recruitment closes; date is a formatted date/time or 'Time to be confirmed'.
  ///
  /// In en, this message translates to:
  /// **'Recruitment closes {date} (your local time).'**
  String cityPilotRecruitmentCloses(String date);

  /// City pilot: pilot is paused.
  ///
  /// In en, this message translates to:
  /// **'New participation and bookings are paused. You can still leave or cancel.'**
  String get cityPilotPaused;

  /// City pilot: pilot has finished.
  ///
  /// In en, this message translates to:
  /// **'This pilot is complete. Thank you for being part of it.'**
  String get cityPilotCompleted;

  /// City pilot: what joining lets us measure (consent information).
  ///
  /// In en, this message translates to:
  /// **'Joining lets us count conversations, accepted plans and optional “did the date happen?” answers for new matches where both people joined this pilot. We use 7-day conversation and 28-day date windows. We don’t read message text or private feedback notes for the pilot.'**
  String get cityPilotMeasurement;

  /// City pilot: privacy information.
  ///
  /// In en, this message translates to:
  /// **'Participation stays private. There’s no public attendance list or dating score. Leaving excludes your activity from current pilot results and cancels pilot bookings. Previously reviewed combined results cannot be un-seen.'**
  String get cityPilotPrivacy;

  /// City pilot: consent checkbox label.
  ///
  /// In en, this message translates to:
  /// **'I agree to take part in this pilot and its outcome measurement.'**
  String get cityPilotConsent;

  /// City pilot: notice after joining.
  ///
  /// In en, this message translates to:
  /// **'You’re in. Keep meeting people at your own pace.'**
  String get cityPilotJoinedNotice;

  /// City pilot: join button.
  ///
  /// In en, this message translates to:
  /// **'Join the city pilot'**
  String get cityPilotJoin;

  /// City pilot: the user has already left this pilot.
  ///
  /// In en, this message translates to:
  /// **'You’ve left this pilot. Your matches and conversations are unchanged.'**
  String get cityPilotWithdrawn;

  /// City pilot: not accepting new members.
  ///
  /// In en, this message translates to:
  /// **'This pilot is not accepting new members right now.'**
  String get cityPilotNotAccepting;

  /// City pilot: heading above hosted experiences.
  ///
  /// In en, this message translates to:
  /// **'Small plans. Shared experiences.'**
  String get cityPilotExperiencesHeading;

  /// City pilot: no hosted experiences open yet.
  ///
  /// In en, this message translates to:
  /// **'Hosted experiences aren’t open yet. They’ll appear here after an outcome and safety review.'**
  String get cityPilotNoExperiences;

  /// City pilot experience card: times, price, venue and host (venue/host from the server).
  ///
  /// In en, this message translates to:
  /// **'{start} → {end}\nYour local time · Free\n{venue}\nHosted by {host}'**
  String cityPilotEventDetails(
    String start,
    String end,
    String venue,
    String host,
  );

  /// City pilot experience card: accessibility details from the server.
  ///
  /// In en, this message translates to:
  /// **'Accessibility · {details}'**
  String cityPilotAccessibility(String details);

  /// City pilot experience card: safety contact from the server.
  ///
  /// In en, this message translates to:
  /// **'Safety contact · {contact}'**
  String cityPilotSafetyContact(String contact);

  /// City pilot experience card: the experience was cancelled.
  ///
  /// In en, this message translates to:
  /// **'This experience has been cancelled. Please do not travel to the venue.'**
  String get cityPilotEventCancelled;

  /// City pilot experience card: your place is reserved.
  ///
  /// In en, this message translates to:
  /// **'Your place is reserved.'**
  String get cityPilotPlaceReserved;

  /// City pilot: notice after cancelling a booking.
  ///
  /// In en, this message translates to:
  /// **'Your booking is cancelled.'**
  String get cityPilotBookingCancelled;

  /// City pilot experience card: cancel your reservation.
  ///
  /// In en, this message translates to:
  /// **'Cancel my place'**
  String get cityPilotCancelPlace;

  /// City pilot experience card: reserve a free place.
  ///
  /// In en, this message translates to:
  /// **'Reserve a free place'**
  String get cityPilotReserveFree;

  /// City pilot experience card: open the optional feedback dialog.
  ///
  /// In en, this message translates to:
  /// **'Share optional feedback'**
  String get cityPilotShareOptionalFeedback;

  /// City pilot experience card: feedback already received.
  ///
  /// In en, this message translates to:
  /// **'Your feedback has been received. Thank you.'**
  String get cityPilotFeedbackReceived;

  /// Open Chapters: audience 'only me'.
  ///
  /// In en, this message translates to:
  /// **'Only me'**
  String get blogAudiencePrivate;

  /// Open Chapters: audience of accepted friends.
  ///
  /// In en, this message translates to:
  /// **'Friends'**
  String get blogAudienceFriends;

  /// Open Chapters: audience of signed-in community members.
  ///
  /// In en, this message translates to:
  /// **'Connect community'**
  String get blogAudienceCommunity;

  /// Open Chapters: no closing invitation.
  ///
  /// In en, this message translates to:
  /// **'No invitation'**
  String get blogInvitationNone;

  /// Open Chapters: closing invitation question.
  ///
  /// In en, this message translates to:
  /// **'What would your version look like?'**
  String get blogInvitationYourVersion;

  /// Open Chapters: closing invitation question.
  ///
  /// In en, this message translates to:
  /// **'What could you teach me about this?'**
  String get blogInvitationTeachMe;

  /// Open Chapters: closing invitation question.
  ///
  /// In en, this message translates to:
  /// **'What would you try next?'**
  String get blogInvitationWhatNext;

  /// Creator rewards: reward title.
  ///
  /// In en, this message translates to:
  /// **'Sharing a chapter'**
  String get blogRewardStoryPublishedTitle;

  /// Creator rewards: who earns it and when.
  ///
  /// In en, this message translates to:
  /// **'You, the first time a chapter is shared beyond Only me'**
  String get blogRewardStoryPublishedWho;

  /// Creator rewards: reward title.
  ///
  /// In en, this message translates to:
  /// **'Sharing a Photo Themes photo'**
  String get blogRewardPhotoSharedTitle;

  /// Creator rewards: who earns it and when.
  ///
  /// In en, this message translates to:
  /// **'You, for a photo you share in Photo Themes'**
  String get blogRewardPhotoSharedWho;

  /// Creator rewards: reward title.
  ///
  /// In en, this message translates to:
  /// **'A like on your chapter or photo'**
  String get blogRewardLikeReceivedTitle;

  /// Creator rewards: who earns it and when.
  ///
  /// In en, this message translates to:
  /// **'You, for each member who likes it'**
  String get blogRewardLikeReceivedWho;

  /// Creator rewards: reward title.
  ///
  /// In en, this message translates to:
  /// **'A comment you approve'**
  String get blogRewardCommentReceivedTitle;

  /// Creator rewards: who earns it and when.
  ///
  /// In en, this message translates to:
  /// **'You, when you approve a reader’s comment'**
  String get blogRewardCommentReceivedWho;

  /// Creator rewards: reward title.
  ///
  /// In en, this message translates to:
  /// **'Your comment is approved'**
  String get blogRewardCommentApprovedTitle;

  /// Creator rewards: who earns it and when.
  ///
  /// In en, this message translates to:
  /// **'You, when an author approves your comment'**
  String get blogRewardCommentApprovedWho;

  /// Creator rewards: reward title.
  ///
  /// In en, this message translates to:
  /// **'A new follower'**
  String get blogRewardSubscriberGainedTitle;

  /// Creator rewards: who earns it and when.
  ///
  /// In en, this message translates to:
  /// **'You, for each new member who follows your chapters'**
  String get blogRewardSubscriberGainedWho;

  /// Creator rewards: reward title.
  ///
  /// In en, this message translates to:
  /// **'Reaching more walls'**
  String get blogRewardWallTierTitle;

  /// Creator rewards: who earns it and when.
  ///
  /// In en, this message translates to:
  /// **'You, each time a chapter reaches a new wall tier'**
  String get blogRewardWallTierWho;

  /// Creator rewards: reward title.
  ///
  /// In en, this message translates to:
  /// **'Cover of the Week'**
  String get blogRewardCoverOfWeekTitle;

  /// Creator rewards: who earns it and when.
  ///
  /// In en, this message translates to:
  /// **'You, when your work is chosen as Cover of the Week'**
  String get blogRewardCoverOfWeekWho;

  /// Open Chapters: feed tab.
  ///
  /// In en, this message translates to:
  /// **'For you'**
  String get blogScopeForYou;

  /// Open Chapters: feed tab of highest-rated chapters.
  ///
  /// In en, this message translates to:
  /// **'Top rated'**
  String get blogScopeTopRated;

  /// Open Chapters: feed tab of writers the member follows.
  ///
  /// In en, this message translates to:
  /// **'Following'**
  String get blogScopeFollowing;

  /// Open Chapters: feed tab of the member's own chapters.
  ///
  /// In en, this message translates to:
  /// **'Mine'**
  String get blogScopeMine;

  /// Open Chapters: caption under the Mine tab.
  ///
  /// In en, this message translates to:
  /// **'Your drafts and published chapters. You choose the audience for each one.'**
  String get blogScopeCaptionMine;

  /// Open Chapters: caption under the Friends tab.
  ///
  /// In en, this message translates to:
  /// **'Chapters shared by your accepted Connect friends.'**
  String get blogScopeCaptionFriends;

  /// Open Chapters: caption under the Top rated tab.
  ///
  /// In en, this message translates to:
  /// **'Ranked by likes, approved comments and readers, from the last 30 days.'**
  String get blogScopeCaptionTop;

  /// Open Chapters: caption under the Following tab.
  ///
  /// In en, this message translates to:
  /// **'The newest chapters from writers you follow.'**
  String get blogScopeCaptionFollowing;

  /// Open Chapters: caption under the For you tab.
  ///
  /// In en, this message translates to:
  /// **'For eligible, signed-in Connect members. These chapters are not public on the web.'**
  String get blogScopeCaptionCommunity;

  /// Open Chapters: screen title.
  ///
  /// In en, this message translates to:
  /// **'Open Chapters'**
  String get blogTitle;

  /// Open Chapters: rewards tooltip and sheet title.
  ///
  /// In en, this message translates to:
  /// **'How rewards work'**
  String get blogRewardsTitle;

  /// Open Chapters: writers tooltip and screen title.
  ///
  /// In en, this message translates to:
  /// **'Writers you follow'**
  String get blogWritersTitle;

  /// Open Chapters: tooltip of the connections button.
  ///
  /// In en, this message translates to:
  /// **'Private responses, sharing and notices'**
  String get blogConnectionsTooltip;

  /// Open Chapters: shown when signed out.
  ///
  /// In en, this message translates to:
  /// **'Sign in to read and write chapters.'**
  String get blogSignInReadWrite;

  /// Open Chapters: headline with a line break.
  ///
  /// In en, this message translates to:
  /// **'A life worth\ngetting to know.'**
  String get blogHeroTitle;

  /// Open Chapters: introduction.
  ///
  /// In en, this message translates to:
  /// **'The story behind a photo. A small obsession. Something you’re still learning. Let your everyday life do the talking.'**
  String get blogHeroBody;

  /// Open Chapters: button to write a new chapter.
  ///
  /// In en, this message translates to:
  /// **'Write a chapter'**
  String get blogWriteChapter;

  /// Open Chapters: link/tab to private responses.
  ///
  /// In en, this message translates to:
  /// **'Private responses'**
  String get blogPrivateResponses;

  /// Open Chapters: link/tab to shared public links.
  ///
  /// In en, this message translates to:
  /// **'Shared links'**
  String get blogSharedLinks;

  /// Open Chapters: link/tab to moderation review notices.
  ///
  /// In en, this message translates to:
  /// **'Review notices'**
  String get blogReviewNotices;

  /// Open Chapters: topic filter for all topics.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get blogTopicAll;

  /// Open Chapters: fallback error when the feed fails.
  ///
  /// In en, this message translates to:
  /// **'Chapters could not load.'**
  String get blogFeedLoadFailed;

  /// Open Chapters: previous page button.
  ///
  /// In en, this message translates to:
  /// **'Previous page'**
  String get blogPreviousPage;

  /// Open Chapters: next page button.
  ///
  /// In en, this message translates to:
  /// **'More chapters'**
  String get blogMoreChapters;

  /// Open Chapters: empty state title for the Mine tab.
  ///
  /// In en, this message translates to:
  /// **'Your next chapter starts here.'**
  String get blogEmptyMineTitle;

  /// Open Chapters: empty state body for the Mine tab.
  ///
  /// In en, this message translates to:
  /// **'Start with a moment you would love someone to ask about. Your first draft is only for you.'**
  String get blogEmptyMineBody;

  /// Open Chapters: empty state title for Top rated.
  ///
  /// In en, this message translates to:
  /// **'When chapters move people, they rise here.'**
  String get blogEmptyTopTitle;

  /// Open Chapters: empty Top rated body with a topic filter.
  ///
  /// In en, this message translates to:
  /// **'Nothing has risen in this topic yet. Try All, or share a chapter of your own.'**
  String get blogEmptyTopFilteredBody;

  /// Open Chapters: empty Top rated body.
  ///
  /// In en, this message translates to:
  /// **'Chapters readers love from the last 30 days will appear here.'**
  String get blogEmptyTopBody;

  /// Open Chapters: empty Following title with a topic filter.
  ///
  /// In en, this message translates to:
  /// **'Nothing new in this topic yet.'**
  String get blogEmptyFollowingFilteredTitle;

  /// Open Chapters: empty Following title.
  ///
  /// In en, this message translates to:
  /// **'Writers you follow will appear here.'**
  String get blogEmptyFollowingTitle;

  /// Open Chapters: empty Following body. 'Follow their chapters' is the follow button label.
  ///
  /// In en, this message translates to:
  /// **'When a chapter speaks to you, open it and tap Follow their chapters. Their new chapters will gather here, so you never miss what they share next.'**
  String get blogEmptyFollowingBody;

  /// Open Chapters: empty feed title.
  ///
  /// In en, this message translates to:
  /// **'A little quiet here, for now.'**
  String get blogEmptyCommunityTitle;

  /// Open Chapters: empty feed body.
  ///
  /// In en, this message translates to:
  /// **'Chapters appear here when members choose to share with this audience.'**
  String get blogEmptyCommunityBody;

  /// Open Chapters: button from empty Following to Top rated.
  ///
  /// In en, this message translates to:
  /// **'Find writers in Top rated'**
  String get blogFindWritersTopRated;

  /// Open Chapters: tooltip on a chapter's rank.
  ///
  /// In en, this message translates to:
  /// **'Number {rank} in Top rated'**
  String blogRankTooltip(int rank);

  /// Open Chapters: title shown for a chapter without a title.
  ///
  /// In en, this message translates to:
  /// **'An untitled chapter'**
  String get blogUntitled;

  /// Open Chapters: excerpt shown for an empty draft.
  ///
  /// In en, this message translates to:
  /// **'A private draft, waiting for your words.'**
  String get blogDraftPlaceholder;

  /// Open Chapters: card link on the member's own chapter.
  ///
  /// In en, this message translates to:
  /// **'Read & edit →'**
  String get blogReadEdit;

  /// Open Chapters: card link.
  ///
  /// In en, this message translates to:
  /// **'Read chapter →'**
  String get blogReadChapter;

  /// Open Chapters: button on a photo that failed to load.
  ///
  /// In en, this message translates to:
  /// **'Photo unavailable · Retry'**
  String get blogPhotoUnavailableRetry;

  /// Open Chapters: retry button.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get blogTryAgain;

  /// Open Chapters: chapter page title.
  ///
  /// In en, this message translates to:
  /// **'A chapter'**
  String get blogDetailTitle;

  /// Open Chapters: chapter page when signed out.
  ///
  /// In en, this message translates to:
  /// **'Sign in to read chapters.'**
  String get blogSignInRead;

  /// Open Chapters: fallback error on the chapter page.
  ///
  /// In en, this message translates to:
  /// **'This chapter is unavailable or its audience has changed.'**
  String get blogDetailUnavailable;

  /// Open Chapters: button to respond privately to the author.
  ///
  /// In en, this message translates to:
  /// **'Respond privately'**
  String get blogRespondPrivately;

  /// Open Chapters: button to create a public preview.
  ///
  /// In en, this message translates to:
  /// **'Create a public preview'**
  String get blogCreatePublicPreview;

  /// Open Chapters: note on a chapter removed by moderation. 'Review notices' is the tab name.
  ///
  /// In en, this message translates to:
  /// **'Removed by moderation. Open Review notices to read the decision or request another review.'**
  String get blogRemovedByModerationNote;

  /// Open Chapters: edit button.
  ///
  /// In en, this message translates to:
  /// **'Edit chapter'**
  String get blogEditChapter;

  /// Open Chapters: delete button and confirm action.
  ///
  /// In en, this message translates to:
  /// **'Delete chapter'**
  String get blogDeleteChapter;

  /// Open Chapters: delete confirm title.
  ///
  /// In en, this message translates to:
  /// **'Delete this chapter?'**
  String get blogDeleteChapterTitle;

  /// Open Chapters: delete confirm message.
  ///
  /// In en, this message translates to:
  /// **'It will disappear from all audiences. This cannot be undone.'**
  String get blogDeleteChapterMessage;

  /// Open Chapters: fallback error when deletion is unconfirmed.
  ///
  /// In en, this message translates to:
  /// **'Could not confirm deletion. Reload the chapter before retrying.'**
  String get blogDeleteChapterFailed;

  /// Open Chapters: report button.
  ///
  /// In en, this message translates to:
  /// **'Report chapter'**
  String get blogReportChapter;

  /// Open Chapters: fallback error when a report fails.
  ///
  /// In en, this message translates to:
  /// **'Report could not be submitted.'**
  String get blogReportFailed;

  /// Open Chapters: block button on a chapter.
  ///
  /// In en, this message translates to:
  /// **'Block this member'**
  String get blogBlockThisMember;

  /// Open Chapters: block confirm title.
  ///
  /// In en, this message translates to:
  /// **'Block this member?'**
  String get blogBlockTitle;

  /// Open Chapters: block confirm message on a chapter.
  ///
  /// In en, this message translates to:
  /// **'You will no longer see each other’s chapters. This also blocks contact through Connect.'**
  String get blogBlockMessageChapter;

  /// Open Chapters: block confirm action and button.
  ///
  /// In en, this message translates to:
  /// **'Block member'**
  String get blogBlockMember;

  /// Open Chapters: fallback error when blocking from a chapter fails.
  ///
  /// In en, this message translates to:
  /// **'Could not block this member. Please retry.'**
  String get blogBlockRetryFailed;

  /// Open Chapters: cancel button in dialogs.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get blogCancel;

  /// Chapter editor: validation error before publishing.
  ///
  /// In en, this message translates to:
  /// **'Add a title and story before publishing.'**
  String get blogEditorMissingFields;

  /// Chapter editor: publish confirm title. {audience} is private, friends or community.
  ///
  /// In en, this message translates to:
  /// **'{audience, select, private{Publish to Only me?} friends{Publish to Friends?} community{Publish to Connect community?} other{Publish?}}'**
  String blogPublishConfirmTitle(String audience);

  /// Chapter editor: publish-to-friends confirm message.
  ///
  /// In en, this message translates to:
  /// **'Your accepted Connect friends can read the words and photos in this chapter. You can change the audience later.'**
  String get blogPublishFriendsBody;

  /// Chapter editor: publish-to-community confirm message.
  ///
  /// In en, this message translates to:
  /// **'Eligible, signed-in Connect members can read this chapter. It will not appear on the public web. You can change the audience later.'**
  String get blogPublishCommunityBody;

  /// Chapter editor: publish confirm action.
  ///
  /// In en, this message translates to:
  /// **'Publish chapter'**
  String get blogPublishChapter;

  /// Chapter editor: notice after saving privately.
  ///
  /// In en, this message translates to:
  /// **'Saved. Only you can read this chapter.'**
  String get blogSavedOnlyMe;

  /// Chapter editor: notice after publishing. {audience} is private, friends or community.
  ///
  /// In en, this message translates to:
  /// **'{audience, select, private{Published to Only me.} friends{Published to Friends.} community{Published to Connect community.} other{Published.}}'**
  String blogPublishedTo(String audience);

  /// Chapter editor: snack bar the first time a chapter is shared.
  ///
  /// In en, this message translates to:
  /// **'Shared. Readers’ likes and comments earn you XP.'**
  String get blogSharedSnack;

  /// Open Chapters: button to open the member's level screen.
  ///
  /// In en, this message translates to:
  /// **'See my level'**
  String get blogSeeMyLevel;

  /// Chapter editor: fallback error when a save cannot be confirmed.
  ///
  /// In en, this message translates to:
  /// **'We could not confirm the save.'**
  String get blogSaveUnconfirmed;

  /// Chapter editor: save error. {message} is a server or fallback error sentence.
  ///
  /// In en, this message translates to:
  /// **'{message} Your edits are still here. Check the saved version before continuing.'**
  String blogEditsStillHere(String message);

  /// Chapter editor: saved version sheet title. {audience} is the audience name.
  ///
  /// In en, this message translates to:
  /// **'Saved version · {audience}'**
  String blogSavedVersionTitle(String audience);

  /// Chapter editor: saved version sheet note.
  ///
  /// In en, this message translates to:
  /// **'Your current edits remain in the editor. Close this sheet to keep them, or replace them with this saved version.'**
  String get blogSavedVersionNote;

  /// Chapter editor: keep local edits.
  ///
  /// In en, this message translates to:
  /// **'Keep my edits for the next save'**
  String get blogKeepMyEdits;

  /// Chapter editor: replace local edits with the saved version.
  ///
  /// In en, this message translates to:
  /// **'Use saved version'**
  String get blogUseSavedVersion;

  /// Chapter editor: fallback error.
  ///
  /// In en, this message translates to:
  /// **'The saved version could not load. Your edits remain here.'**
  String get blogSavedVersionLoadFailed;

  /// Chapter editor: alt text dialog title.
  ///
  /// In en, this message translates to:
  /// **'Describe your photo'**
  String get blogDescribePhotoTitle;

  /// Chapter editor: alt text dialog explanation.
  ///
  /// In en, this message translates to:
  /// **'A short description makes your chapter accessible. Adding the photo saves your words as an Only me draft.'**
  String get blogDescribePhotoBody;

  /// Chapter editor: alt text field label.
  ///
  /// In en, this message translates to:
  /// **'What is in this photo?'**
  String get blogDescribePhotoLabel;

  /// Chapter editor: alt text dialog confirm.
  ///
  /// In en, this message translates to:
  /// **'Add to private draft'**
  String get blogAddToPrivateDraft;

  /// Chapter editor: notice after adding a photo.
  ///
  /// In en, this message translates to:
  /// **'Photo added to your private draft.'**
  String get blogPhotoAdded;

  /// Chapter editor: fallback error when adding a photo.
  ///
  /// In en, this message translates to:
  /// **'The photo could not be added. Use a JPEG or PNG up to 10 MB.'**
  String get blogPhotoAddFailed;

  /// Chapter editor: photo error. {message} is a server or fallback error sentence.
  ///
  /// In en, this message translates to:
  /// **'{message} Check the saved version before retrying.'**
  String blogCheckSavedBeforeRetrying(String message);

  /// Chapter editor: fallback error when photo removal is unconfirmed.
  ///
  /// In en, this message translates to:
  /// **'Could not confirm removal. Check the saved version.'**
  String get blogRemoveUnconfirmed;

  /// Chapter editor: shown to someone who is not the author.
  ///
  /// In en, this message translates to:
  /// **'Sign in as the author to edit this chapter.'**
  String get blogSignInAsAuthor;

  /// Chapter editor: leave confirm title.
  ///
  /// In en, this message translates to:
  /// **'Leave without saving?'**
  String get blogLeaveEditorTitle;

  /// Chapter editor: leave confirm message.
  ///
  /// In en, this message translates to:
  /// **'Your unsaved edits will be lost. Your last saved chapter will remain.'**
  String get blogLeaveEditorMessage;

  /// Chapter editor: leave confirm action.
  ///
  /// In en, this message translates to:
  /// **'Leave editor'**
  String get blogLeaveEditor;

  /// Chapter editor: app bar title in preview.
  ///
  /// In en, this message translates to:
  /// **'Chapter preview'**
  String get blogEditorPreviewTitle;

  /// Chapter editor: app bar title.
  ///
  /// In en, this message translates to:
  /// **'Your next chapter'**
  String get blogEditorTitle;

  /// Chapter editor: headline.
  ///
  /// In en, this message translates to:
  /// **'A little more you.'**
  String get blogEditorHeadline;

  /// Chapter editor: introduction.
  ///
  /// In en, this message translates to:
  /// **'Small stories are welcome. A meal you made. A place that changed your mind. The photo with a story behind it.'**
  String get blogEditorIntro;

  /// Chapter editor: chip before the first save.
  ///
  /// In en, this message translates to:
  /// **'Not saved · Only me by default'**
  String get blogNotSavedDefault;

  /// Chapter editor: chip showing the saved audience. {audience} is private, friends or community.
  ///
  /// In en, this message translates to:
  /// **'{audience, select, private{Saved for Only me} friends{Saved for Friends} community{Saved for Connect community} other{Saved}}'**
  String blogSavedFor(String audience);

  /// Chapter editor: leave preview.
  ///
  /// In en, this message translates to:
  /// **'Keep writing'**
  String get blogKeepWriting;

  /// Chapter editor: open preview.
  ///
  /// In en, this message translates to:
  /// **'Preview'**
  String get blogPreview;

  /// Chapter editor: button to compare with the saved version.
  ///
  /// In en, this message translates to:
  /// **'Check saved version'**
  String get blogCheckSavedVersion;

  /// Chapter editor: label in preview. {audience} is the audience name.
  ///
  /// In en, this message translates to:
  /// **'Preview · {audience} · Not yet saved'**
  String blogPreviewNotSaved(String audience);

  /// Chapter editor: preview placeholder for an empty story.
  ///
  /// In en, this message translates to:
  /// **'Your story will appear here.'**
  String get blogStoryPlaceholder;

  /// Chapter editor: title field label.
  ///
  /// In en, this message translates to:
  /// **'Chapter title'**
  String get blogChapterTitleLabel;

  /// Chapter editor: example title.
  ///
  /// In en, this message translates to:
  /// **'The Sunday I learned to slow down'**
  String get blogChapterTitleHint;

  /// Chapter editor: story field label.
  ///
  /// In en, this message translates to:
  /// **'Your story'**
  String get blogStoryLabel;

  /// Chapter editor: story field hint.
  ///
  /// In en, this message translates to:
  /// **'Start anywhere. Make it yours.'**
  String get blogStoryHint;

  /// Chapter editor: invitation dropdown label.
  ///
  /// In en, this message translates to:
  /// **'End with an invitation (optional)'**
  String get blogInvitationLabel;

  /// Chapter editor: invitation help text.
  ///
  /// In en, this message translates to:
  /// **'Leave a question that helps someone get to know you.'**
  String get blogInvitationHelp;

  /// Chapter editor: remove photo button.
  ///
  /// In en, this message translates to:
  /// **'Remove photo'**
  String get blogRemovePhoto;

  /// Chapter editor: add photo button.
  ///
  /// In en, this message translates to:
  /// **'Add a photo'**
  String get blogAddPhoto;

  /// Chapter editor: photo rules.
  ///
  /// In en, this message translates to:
  /// **'Up to 6 JPEG or PNG photos, 10 MB each. Photos need approval. Save as Only me before changing photos on a published chapter.'**
  String get blogPhotoRules;

  /// Chapter editor: audience section title.
  ///
  /// In en, this message translates to:
  /// **'Who is this chapter for?'**
  String get blogWhoFor;

  /// Chapter editor: explanation of 'Only me'.
  ///
  /// In en, this message translates to:
  /// **'Only you can read this chapter. Friends and matches cannot see it.'**
  String get blogAudiencePrivateHelp;

  /// Chapter editor: explanation of 'Friends'.
  ///
  /// In en, this message translates to:
  /// **'Only accepted Connect friends can read it. A match alone does not give access.'**
  String get blogAudienceFriendsHelp;

  /// Chapter editor: explanation of 'Connect community'.
  ///
  /// In en, this message translates to:
  /// **'Eligible signed-in members can read it. Complete your profile with two approved profile photos to publish here. This is not public web sharing.'**
  String get blogAudienceCommunityHelp;

  /// Chapter editor: featuring switch title.
  ///
  /// In en, this message translates to:
  /// **'Allow featuring'**
  String get blogAllowFeaturing;

  /// Chapter editor: featuring switch explanation.
  ///
  /// In en, this message translates to:
  /// **'If readers love it, your chapter can reach other members’ walls: 50 likes and 5 comments reach 50 walls, 100 likes and 10 comments reach 100. You can turn this off any time.'**
  String get blogAllowFeaturingHelp;

  /// Chapter editor: save button when the audience is Only me.
  ///
  /// In en, this message translates to:
  /// **'Save only for me'**
  String get blogSaveOnlyForMe;

  /// Chapter editor: publish button. {audience} is friends or community.
  ///
  /// In en, this message translates to:
  /// **'{audience, select, private{Publish to Only me} friends{Publish to Friends} community{Publish to Connect community} other{Publish}}'**
  String blogPublishTo(String audience);

  /// Chapter editor: secondary save button.
  ///
  /// In en, this message translates to:
  /// **'Save as Only me'**
  String get blogSaveAsOnlyMe;

  /// Chapter editor: footer note.
  ///
  /// In en, this message translates to:
  /// **'Your words are saved when you choose Save or Publish. Preview does not publish anything.'**
  String get blogSaveNote;

  /// Chapter editor: topic section title.
  ///
  /// In en, this message translates to:
  /// **'Topic (optional)'**
  String get blogTopicOptional;

  /// Chapter editor: topic help.
  ///
  /// In en, this message translates to:
  /// **'Help readers who care about this find your chapter.'**
  String get blogTopicHelp;

  /// Web workspace sidebar/directory label: 'Blog'.
  ///
  /// In en, this message translates to:
  /// **'Blog'**
  String get webDestBlog;

  /// Web workspace sidebar/directory label: 'First Chapter Studio'.
  ///
  /// In en, this message translates to:
  /// **'First Chapter Studio'**
  String get webDestFirstChapter;

  /// Web workspace sidebar/directory label: 'Dating preferences'.
  ///
  /// In en, this message translates to:
  /// **'Dating preferences'**
  String get webDestDatingPreferences;

  /// Web workspace sidebar/directory label: 'Edit profile'.
  ///
  /// In en, this message translates to:
  /// **'Edit profile'**
  String get webDestEditProfile;

  /// Web workspace sidebar/directory label: 'Profile photos'.
  ///
  /// In en, this message translates to:
  /// **'Profile photos'**
  String get webDestProfilePhotos;

  /// Web workspace sidebar/directory label: 'Liked you'.
  ///
  /// In en, this message translates to:
  /// **'Liked you'**
  String get webDestLikedYou;

  /// Web workspace sidebar/directory label: 'Notifications'.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get webDestNotifications;

  /// Web workspace sidebar/directory label: 'Daily prompt'.
  ///
  /// In en, this message translates to:
  /// **'Daily prompt'**
  String get webDestDailyPrompt;

  /// Web workspace sidebar/directory label: 'Levels & progress'.
  ///
  /// In en, this message translates to:
  /// **'Levels & progress'**
  String get webDestLevels;

  /// Web workspace sidebar/directory label: 'Trust badges'.
  ///
  /// In en, this message translates to:
  /// **'Trust badges'**
  String get webDestTrustBadges;

  /// Web workspace sidebar/directory label: 'Trust filters'.
  ///
  /// In en, this message translates to:
  /// **'Trust filters'**
  String get webDestTrustFilters;

  /// Web workspace sidebar/directory label: 'Icebreakers'.
  ///
  /// In en, this message translates to:
  /// **'Icebreakers'**
  String get webDestIcebreakers;

  /// Web workspace sidebar/directory label: 'Circle challenges'.
  ///
  /// In en, this message translates to:
  /// **'Circle challenges'**
  String get webDestCircleChallenges;

  /// Web workspace sidebar/directory label: 'Coffee polls'.
  ///
  /// In en, this message translates to:
  /// **'Coffee polls'**
  String get webDestCoffeePolls;

  /// Web workspace sidebar/directory label: 'Groups'.
  ///
  /// In en, this message translates to:
  /// **'Groups'**
  String get webDestGroups;

  /// Web workspace sidebar/directory label: 'Conversation rooms'.
  ///
  /// In en, this message translates to:
  /// **'Conversation rooms'**
  String get webDestRooms;

  /// Web workspace sidebar/directory label: 'Match nudges'.
  ///
  /// In en, this message translates to:
  /// **'Match nudges'**
  String get webDestMatchNudges;

  /// Web workspace sidebar/directory label: 'Friends'.
  ///
  /// In en, this message translates to:
  /// **'Friends'**
  String get webDestFriends;

  /// Web workspace sidebar/directory label: 'Date plans'.
  ///
  /// In en, this message translates to:
  /// **'Date plans'**
  String get webDestDatePlans;

  /// Web workspace sidebar/directory label: 'Call history'.
  ///
  /// In en, this message translates to:
  /// **'Call history'**
  String get webDestCallHistory;

  /// Web workspace sidebar/directory label: 'Membership'.
  ///
  /// In en, this message translates to:
  /// **'Membership'**
  String get webDestMembership;

  /// Web workspace sidebar/directory label: 'Verification'.
  ///
  /// In en, this message translates to:
  /// **'Verification'**
  String get webDestVerification;

  /// Web workspace sidebar/directory label: 'Privacy & safety'.
  ///
  /// In en, this message translates to:
  /// **'Privacy & safety'**
  String get webDestPrivacySafety;

  /// Web workspace sidebar/directory label: 'Account & data'.
  ///
  /// In en, this message translates to:
  /// **'Account & data'**
  String get webDestAccountData;

  /// Web workspace sidebar/directory label: 'Blocked members'.
  ///
  /// In en, this message translates to:
  /// **'Blocked members'**
  String get webDestBlockedMembers;

  /// Web workspace sidebar/directory label: 'Emergency contacts'.
  ///
  /// In en, this message translates to:
  /// **'Emergency contacts'**
  String get webDestEmergencyContacts;

  /// Web workspace sidebar/directory label: 'Moderation appeals'.
  ///
  /// In en, this message translates to:
  /// **'Moderation appeals'**
  String get webDestModerationAppeals;

  /// Web workspace sidebar/directory label: 'Notification preferences'.
  ///
  /// In en, this message translates to:
  /// **'Notification preferences'**
  String get webDestNotificationPreferences;

  /// Web workspace sidebar/directory label: 'Help & support'.
  ///
  /// In en, this message translates to:
  /// **'Help & support'**
  String get webDestHelpSupport;

  /// Web workspace sidebar/directory label: 'Explore'.
  ///
  /// In en, this message translates to:
  /// **'Explore'**
  String get webNavExplore;

  /// Web workspace sidebar/directory label: 'My profile'.
  ///
  /// In en, this message translates to:
  /// **'My profile'**
  String get webNavMyProfile;

  /// Web workspace sidebar/directory label: 'All features'.
  ///
  /// In en, this message translates to:
  /// **'All features'**
  String get webNavAllFeatures;

  /// Web workspace sidebar/directory label: 'More for you'.
  ///
  /// In en, this message translates to:
  /// **'More for you'**
  String get webNavMoreForYou;

  /// Web workspace sidebar/directory label: 'Preferences'.
  ///
  /// In en, this message translates to:
  /// **'Preferences'**
  String get webNavPreferences;

  /// Web workspace sidebar/directory label: 'Connect website'.
  ///
  /// In en, this message translates to:
  /// **'Connect website'**
  String get webNavWebsite;

  /// Web workspace sidebar/directory label: 'Sign out'.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get webNavSignOut;

  /// Web workspace: unknown route.
  ///
  /// In en, this message translates to:
  /// **'This page could not be found.'**
  String get webPageNotFound;

  /// Web workspace button: back to Discover.
  ///
  /// In en, this message translates to:
  /// **'Back to Discover'**
  String get webBackToDiscover;

  /// Web workspace top bar tagline.
  ///
  /// In en, this message translates to:
  /// **'Your pace. Your choice.'**
  String get webTagline;

  /// Shown when a feature is switched off. {label} is the feature name.
  ///
  /// In en, this message translates to:
  /// **'{label} isn\'t available yet.'**
  String webUnavailableTitle(String label);

  /// Shown when a feature is switched off.
  ///
  /// In en, this message translates to:
  /// **'It isn\'t part of this release of Connect.'**
  String get webUnavailableBody;

  /// Web feature directory heading.
  ///
  /// In en, this message translates to:
  /// **'Make this space yours.'**
  String get webDirectoryTitle;

  /// Web feature directory subtitle.
  ///
  /// In en, this message translates to:
  /// **'Your profile, conversations, community and controls — all in one place.'**
  String get webDirectorySubtitle;

  /// Web icebreaker page app bar title.
  ///
  /// In en, this message translates to:
  /// **'Conversation starters'**
  String get webIcebreakerTitle;

  /// Web icebreaker page headline.
  ///
  /// In en, this message translates to:
  /// **'A little inspiration for your next hello.'**
  String get webIcebreakerHeadline;

  /// Web icebreaker page explanation.
  ///
  /// In en, this message translates to:
  /// **'Voice recording and playback are not available yet. You can use these prompts in an eligible conversation.'**
  String get webIcebreakerBody;

  /// Web icebreaker page button.
  ///
  /// In en, this message translates to:
  /// **'Open my matches'**
  String get webIcebreakerOpenMatches;

  /// Web membership page headline.
  ///
  /// In en, this message translates to:
  /// **'A little more possibility.'**
  String get webMembershipHeadline;

  /// Web membership page intro.
  ///
  /// In en, this message translates to:
  /// **'Explore the current plans. Browser checkout is not available yet. No purchase or charge can be made from this page.'**
  String get webMembershipIntro;

  /// Web membership page: current plan. {plan} is the plan name from the server.
  ///
  /// In en, this message translates to:
  /// **'Your membership: {plan}'**
  String webMembershipCurrent(String plan);

  /// Web membership page: status line (raw server status).
  ///
  /// In en, this message translates to:
  /// **'Status: {status}'**
  String webMembershipStatus(String status);

  /// Billing cycle segment: monthly.
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get webMembershipMonthly;

  /// Billing cycle segment: yearly.
  ///
  /// In en, this message translates to:
  /// **'Yearly'**
  String get webMembershipYearly;

  /// Price label for a free plan.
  ///
  /// In en, this message translates to:
  /// **'Free'**
  String get webMembershipFree;

  /// Plan price per billing period. {price} is the formatted amount; {cycle} is 'yearly' or 'monthly'.
  ///
  /// In en, this message translates to:
  /// **'{price} / {cycle, select, yearly{year} other{month}}'**
  String webMembershipPrice(String price, String cycle);

  /// Web membership page footnote.
  ///
  /// In en, this message translates to:
  /// **'Catalogue prices are a preview. Membership never bypasses another person’s boundaries or conversation eligibility.'**
  String get webMembershipFootnote;

  /// Open Chapters: snack bar after copying a public link.
  ///
  /// In en, this message translates to:
  /// **'Link copied. Share it wherever you choose.'**
  String get blogLinkCopied;

  /// Open Chapters: dialog title showing the link when copying fails.
  ///
  /// In en, this message translates to:
  /// **'Your public link'**
  String get blogYourPublicLink;

  /// Public preview: fallback error when sharing is unconfirmed. 'Shared links' is a tab name.
  ///
  /// In en, this message translates to:
  /// **'Could not confirm sharing. Check Shared links before retrying.'**
  String get blogShareUnconfirmed;

  /// Open Chapters: shown when the signed-in member changed.
  ///
  /// In en, this message translates to:
  /// **'Sign in again to continue.'**
  String get blogSignInAgain;

  /// Public preview: title for a joint page.
  ///
  /// In en, this message translates to:
  /// **'A shared journal page'**
  String get blogSharedJournalPage;

  /// Public preview: title for a solo preview.
  ///
  /// In en, this message translates to:
  /// **'Your public preview'**
  String get blogYourPublicPreview;

  /// Public preview: joint headline.
  ///
  /// In en, this message translates to:
  /// **'A story you both choose to share.'**
  String get blogShareJointHeadline;

  /// Public preview: solo headline.
  ///
  /// In en, this message translates to:
  /// **'A small window into your world.'**
  String get blogShareSoloHeadline;

  /// Public preview: joint explanation.
  ///
  /// In en, this message translates to:
  /// **'Both authors must approve these exact words before the link works. Either person can withdraw it.'**
  String get blogShareJointBody;

  /// Public preview: solo explanation.
  ///
  /// In en, this message translates to:
  /// **'Anyone with the link can read the selected words and photos, without an account. Your full chapter stays in Connect.'**
  String get blogShareSoloBody;

  /// Public preview: privacy note.
  ///
  /// In en, this message translates to:
  /// **'No profile or account name is added. Your words and photos can still identify people or places. Publish only what you have permission to share.'**
  String get blogShareIdentityNote;

  /// Public preview: excerpt field label.
  ///
  /// In en, this message translates to:
  /// **'Exact excerpt from your chapter'**
  String get blogExcerptLabel;

  /// Public preview: checkbox to include a photo. {description} is the member-written photo description.
  ///
  /// In en, this message translates to:
  /// **'Include: {description}'**
  String blogIncludePhoto(String description);

  /// Public preview: approval checkbox.
  ///
  /// In en, this message translates to:
  /// **'I approve this exact public copy'**
  String get blogApproveCopy;

  /// Public preview: approval checkbox note.
  ///
  /// In en, this message translates to:
  /// **'Editing or hiding the source chapter invalidates the link. Saved copies outside Connect cannot be recalled.'**
  String get blogApproveCopyNote;

  /// Open Chapters: button label while saving.
  ///
  /// In en, this message translates to:
  /// **'Saving…'**
  String get blogSaving;

  /// Public preview: joint submit button.
  ///
  /// In en, this message translates to:
  /// **'Request the other author’s approval'**
  String get blogRequestOtherApproval;

  /// Public preview: solo submit button.
  ///
  /// In en, this message translates to:
  /// **'Create public link'**
  String get blogCreatePublicLink;

  /// Public preview: after approving a joint page.
  ///
  /// In en, this message translates to:
  /// **'Your approval is recorded. The link stays unavailable until the other author approves.'**
  String get blogJointApprovalRecorded;

  /// Public preview: after creating a solo link.
  ///
  /// In en, this message translates to:
  /// **'Your public copy is ready.'**
  String get blogPublicCopyReady;

  /// Public preview: copy link button.
  ///
  /// In en, this message translates to:
  /// **'Copy public link'**
  String get blogCopyPublicLink;

  /// Public preview: open the shared links tab.
  ///
  /// In en, this message translates to:
  /// **'Manage shared links'**
  String get blogManageSharedLinks;

  /// Open Chapters: how many members follow a writer.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 follower} other{{count} followers}}'**
  String blogFollowerCount(int count);

  /// Open Chapters: fallback error when unfollowing fails.
  ///
  /// In en, this message translates to:
  /// **'We couldn’t stop following just now. Please try again.'**
  String get blogUnfollowFailed;

  /// Open Chapters: fallback error when following fails.
  ///
  /// In en, this message translates to:
  /// **'We couldn’t follow this writer just now. Please try again.'**
  String get blogFollowFailed;

  /// Open Chapters: follow button label when already following.
  ///
  /// In en, this message translates to:
  /// **'Following'**
  String get blogFollowingButton;

  /// Open Chapters: follow button label.
  ///
  /// In en, this message translates to:
  /// **'Follow their chapters'**
  String get blogFollowTheirChapters;

  /// Creator rewards: introduction.
  ///
  /// In en, this message translates to:
  /// **'When what you share moves someone, it counts. Readers’ likes, approved comments and new followers earn you XP toward your level. Rewards come from what readers do, never from tapping, and each one is given only once.'**
  String get blogRewardsIntro;

  /// Creator rewards: daily XP limit. {cap} is a number.
  ///
  /// In en, this message translates to:
  /// **'Up to {cap} XP a day'**
  String blogRewardDailyCap(int cap);

  /// Creator rewards: XP for one reward. {xp} is a number.
  ///
  /// In en, this message translates to:
  /// **'+{xp} XP'**
  String blogRewardXp(int xp);

  /// Writers you follow: shown when signed out.
  ///
  /// In en, this message translates to:
  /// **'Sign in to see writers you follow.'**
  String get blogSignInWriters;

  /// Writers you follow: fallback error.
  ///
  /// In en, this message translates to:
  /// **'Writers you follow could not load.'**
  String get blogWritersLoadFailed;

  /// Writers you follow: empty title.
  ///
  /// In en, this message translates to:
  /// **'No writers yet.'**
  String get blogNoWriters;

  /// Writers you follow: empty body. 'Follow their chapters' is the button label and 'Following' the tab name.
  ///
  /// In en, this message translates to:
  /// **'When a chapter speaks to you, tap Follow their chapters on it. Their new chapters will gather in Following.'**
  String get blogNoWritersBody;

  /// Writers you follow: link to the latest chapter. {title} is the chapter title.
  ///
  /// In en, this message translates to:
  /// **'Latest: {title}'**
  String blogLatest(String title);

  /// Likes: fallback error when a reaction fails.
  ///
  /// In en, this message translates to:
  /// **'Your reaction didn’t go through. Please try again.'**
  String get blogReactionFailed;

  /// Likes: tooltip on the member's own item. {noun} is chapter or photo.
  ///
  /// In en, this message translates to:
  /// **'{noun, select, photo{You can’t like your own photo} other{You can’t like your own chapter}}'**
  String blogCannotLikeOwn(String noun);

  /// Likes: tooltip after reacting. {reaction} is the reaction name.
  ///
  /// In en, this message translates to:
  /// **'You reacted: {reaction}. Tap to take it back'**
  String blogYouReacted(String reaction);

  /// Likes: like button tooltip. {noun} is chapter or photo.
  ///
  /// In en, this message translates to:
  /// **'{noun, select, photo{Like this photo} other{Like this chapter}}'**
  String blogLikeThis(String noun);

  /// Likes: react button tooltip on the member's own item. {noun} is chapter or photo.
  ///
  /// In en, this message translates to:
  /// **'{noun, select, photo{You can’t react to your own photo} other{You can’t react to your own chapter}}'**
  String blogCannotReactOwn(String noun);

  /// Likes: react button tooltip listing example reactions.
  ///
  /// In en, this message translates to:
  /// **'React: I hear you, Me too, Sending a hug…'**
  String get blogReactTooltip;

  /// Comments: approved comment count.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 comment} other{{count} comments}}'**
  String blogCommentCount(int count);

  /// Comments: pending comments waiting for the author, shown after the count.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{· {count} waiting for you} other{· {count} waiting for you}}'**
  String blogWaitingForYou(int count);

  /// Open Chapters: 'Featured' marker chip.
  ///
  /// In en, this message translates to:
  /// **'Featured'**
  String get blogFeatured;

  /// Wall reach: what the next tier still needs. All values are numbers.
  ///
  /// In en, this message translates to:
  /// **'{likes, plural, =1{1 more like} other{{likes} more likes}} and {comments, plural, =1{1 more comment} other{{comments} more comments}} to reach {walls, plural, =1{1 wall} other{{walls} walls}}'**
  String blogTierNeedsBoth(int likes, int comments, int walls);

  /// Wall reach: likes still needed for the next tier.
  ///
  /// In en, this message translates to:
  /// **'{likes, plural, =1{1 more like} other{{likes} more likes}} to reach {walls, plural, =1{1 wall} other{{walls} walls}}'**
  String blogTierNeedsLikes(int likes, int walls);

  /// Wall reach: comments still needed for the next tier.
  ///
  /// In en, this message translates to:
  /// **'{comments, plural, =1{1 more comment} other{{comments} more comments}} to reach {walls, plural, =1{1 wall} other{{walls} walls}}'**
  String blogTierNeedsComments(int comments, int walls);

  /// Wall reach: the next tier is about to be reached.
  ///
  /// In en, this message translates to:
  /// **'{walls, plural, =1{Almost there: 1 wall are next} other{Almost there: {walls} walls are next}}'**
  String blogTierAlmostThere(int walls);

  /// Wall reach: how many walls an item is on.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{On 1 wall} other{On {count} walls}}'**
  String blogOnWalls(int count);

  /// Wall reach: screen reader label of the progress bar.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Progress toward 1 wall} other{Progress toward {count} walls}}'**
  String blogProgressToward(int count);

  /// Wall reach: card title before the chapter is on any wall.
  ///
  /// In en, this message translates to:
  /// **'Readers can carry this chapter further'**
  String get blogReachIdle;

  /// Wall reach: card caption while the chapter is on walls.
  ///
  /// In en, this message translates to:
  /// **'Members who loved stories like yours are reading it now.'**
  String get blogReachLive;

  /// Featured Stories: rail title.
  ///
  /// In en, this message translates to:
  /// **'Featured Stories'**
  String get blogFeaturedStories;

  /// Featured Stories: rail caption.
  ///
  /// In en, this message translates to:
  /// **'Stories other members loved, delivered to your wall.'**
  String get blogFeaturedCaption;

  /// Featured Stories: byline. {name} is the author's name.
  ///
  /// In en, this message translates to:
  /// **'by {name}'**
  String blogByAuthor(String name);

  /// Open Chapters: screen reader label for the like count icon.
  ///
  /// In en, this message translates to:
  /// **'Likes'**
  String get blogLikes;

  /// Open Chapters: comments heading and screen reader label.
  ///
  /// In en, this message translates to:
  /// **'Comments'**
  String get blogComments;

  /// Comments: composer hint on a chapter.
  ///
  /// In en, this message translates to:
  /// **'What stayed with you?'**
  String get blogCommentHint;

  /// Comments: snack bar after approving a comment on a chapter.
  ///
  /// In en, this message translates to:
  /// **'Approved. Everyone who can read this chapter can see it now.'**
  String get blogCommentApproved;

  /// Comments: notice and status after sending a comment.
  ///
  /// In en, this message translates to:
  /// **'Sent to the author for approval'**
  String get blogCommentSent;

  /// Comments: fallback error when sending fails.
  ///
  /// In en, this message translates to:
  /// **'Your comment didn’t send. Your words are still here, so you can try again.'**
  String get blogCommentSendFailed;

  /// Comments: snack bar after declining. {noun} is chapter or photo.
  ///
  /// In en, this message translates to:
  /// **'{noun, select, photo{Declined. It won’t appear on your photo.} other{Declined. It won’t appear on your chapter.}}'**
  String blogCommentDeclined(String noun);

  /// Comments: fallback error when a decision does not save.
  ///
  /// In en, this message translates to:
  /// **'That didn’t save. Please try again.'**
  String get blogSaveFailed;

  /// Comments: delete confirm title.
  ///
  /// In en, this message translates to:
  /// **'Delete this comment?'**
  String get blogDeleteCommentTitle;

  /// Comments: delete confirm message.
  ///
  /// In en, this message translates to:
  /// **'It will be removed for everyone. This can’t be undone.'**
  String get blogDeleteCommentMessage;

  /// Comments: delete action and menu item.
  ///
  /// In en, this message translates to:
  /// **'Delete comment'**
  String get blogDeleteComment;

  /// Comments: snack bar after deleting.
  ///
  /// In en, this message translates to:
  /// **'Comment deleted.'**
  String get blogCommentDeleted;

  /// Comments: fallback error when deletion fails.
  ///
  /// In en, this message translates to:
  /// **'The comment could not be deleted. Please try again.'**
  String get blogCommentDeleteFailed;

  /// Comments: note for the author.
  ///
  /// In en, this message translates to:
  /// **'New comments wait for your approval before anyone else sees them.'**
  String get blogCommentsAuthorNote;

  /// Comments: note for readers.
  ///
  /// In en, this message translates to:
  /// **'The author reads every comment first and chooses what to share.'**
  String get blogCommentsReaderNote;

  /// Comments: composer label.
  ///
  /// In en, this message translates to:
  /// **'Leave a comment'**
  String get blogLeaveComment;

  /// Comments: send button.
  ///
  /// In en, this message translates to:
  /// **'Send to the author'**
  String get blogSendToAuthor;

  /// Comments: fallback error when comments fail to load.
  ///
  /// In en, this message translates to:
  /// **'Comments could not load.'**
  String get blogCommentsLoadFailed;

  /// Comments: heading for comments awaiting the author.
  ///
  /// In en, this message translates to:
  /// **'Waiting for your approval'**
  String get blogWaitingApproval;

  /// Comments: empty state when the viewer can comment.
  ///
  /// In en, this message translates to:
  /// **'No comments yet. Say something kind to start the conversation.'**
  String get blogNoCommentsInvite;

  /// Comments: empty state.
  ///
  /// In en, this message translates to:
  /// **'No comments shared yet.'**
  String get blogNoCommentsShared;

  /// Comments: status of the viewer's declined comment.
  ///
  /// In en, this message translates to:
  /// **'The author chose not to share this one.'**
  String get blogCommentNotShared;

  /// Comments: author label for the viewer's own comment.
  ///
  /// In en, this message translates to:
  /// **'You'**
  String get blogYou;

  /// Comments: options menu tooltip.
  ///
  /// In en, this message translates to:
  /// **'Comment options'**
  String get blogCommentOptions;

  /// Comments: report menu item.
  ///
  /// In en, this message translates to:
  /// **'Report comment'**
  String get blogReportComment;

  /// Comments: approve button.
  ///
  /// In en, this message translates to:
  /// **'Approve'**
  String get blogApprove;

  /// Comments: decline button.
  ///
  /// In en, this message translates to:
  /// **'Decline'**
  String get blogDecline;

  /// Chapter connections: shown when signed out.
  ///
  /// In en, this message translates to:
  /// **'Sign in to continue.'**
  String get blogSignInContinue;

  /// Private response: screen title.
  ///
  /// In en, this message translates to:
  /// **'A private response'**
  String get blogPrivateResponseTitle;

  /// Private response: help text. {invitation} is the author's closing question.
  ///
  /// In en, this message translates to:
  /// **'{invitation}\n\nOnly the author receives this response. They can accept or decline an optional exchange. Up to five new responses per day, and one to the same author.'**
  String blogPrivateResponseHelp(String invitation);

  /// Private response: submit button.
  ///
  /// In en, this message translates to:
  /// **'Send private response'**
  String get blogSendPrivateResponse;

  /// Private response: fallback error.
  ///
  /// In en, this message translates to:
  /// **'Could not confirm the save. Your words are still here; retry or reload the saved exchange.'**
  String get blogTextSaveUnconfirmed;

  /// Private response: leave confirm title.
  ///
  /// In en, this message translates to:
  /// **'Leave without sending?'**
  String get blogLeaveUnsentTitle;

  /// Private response: leave confirm message.
  ///
  /// In en, this message translates to:
  /// **'Your unsent words will be discarded.'**
  String get blogLeaveUnsentMessage;

  /// Private response: leave confirm action.
  ///
  /// In en, this message translates to:
  /// **'Leave'**
  String get blogLeave;

  /// Private response: text field label.
  ///
  /// In en, this message translates to:
  /// **'In your own words'**
  String get blogOwnWordsLabel;

  /// Private response: submit button while sending.
  ///
  /// In en, this message translates to:
  /// **'Sending…'**
  String get blogSending;

  /// Chapter connections: fallback error.
  ///
  /// In en, this message translates to:
  /// **'Could not confirm the change. Refresh to check.'**
  String get blogChangeUnconfirmed;

  /// Chapter connections: screen title.
  ///
  /// In en, this message translates to:
  /// **'Your Chapter connections'**
  String get blogConnectionsTitle;

  /// Open Chapters: refresh tooltip.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get blogRefresh;

  /// Chapter connections: intro line.
  ///
  /// In en, this message translates to:
  /// **'Good stories leave room for someone else.'**
  String get blogConnectionsIntro;

  /// Chapter connections: fallback error.
  ///
  /// In en, this message translates to:
  /// **'Could not load your connections.'**
  String get blogConnectionsLoadFailed;

  /// Chapter connections: empty responses tab.
  ///
  /// In en, this message translates to:
  /// **'Responses to your chapters and the ones you send will appear here. Nothing needs an instant answer.'**
  String get blogResponsesEmpty;

  /// Chapter connections: empty shared links tab.
  ///
  /// In en, this message translates to:
  /// **'Your public previews and jointly approved links will appear here.'**
  String get blogPublicationsEmpty;

  /// Chapter connections: empty review notices tab.
  ///
  /// In en, this message translates to:
  /// **'No review notices to show.'**
  String get blogNoticesEmpty;

  /// Chapter connections: response status.
  ///
  /// In en, this message translates to:
  /// **'Your shared chapter is ready'**
  String get blogResponseRevealed;

  /// Chapter connections: response status.
  ///
  /// In en, this message translates to:
  /// **'A response for you'**
  String get blogResponseIncoming;

  /// Chapter connections: response status.
  ///
  /// In en, this message translates to:
  /// **'Sent · their choice, their pace'**
  String get blogResponseSent;

  /// Chapter connections: response status.
  ///
  /// In en, this message translates to:
  /// **'An exchange, at your pace'**
  String get blogResponseAccepted;

  /// Chapter connections: response status.
  ///
  /// In en, this message translates to:
  /// **'This exchange is closed'**
  String get blogResponseClosed;

  /// Chapter connections: open an exchange.
  ///
  /// In en, this message translates to:
  /// **'Open private exchange'**
  String get blogOpenExchange;

  /// Chapter connections: shared link status.
  ///
  /// In en, this message translates to:
  /// **'Live public copy'**
  String get blogPublicationLive;

  /// Chapter connections: shared link status.
  ///
  /// In en, this message translates to:
  /// **'Removed by moderation'**
  String get blogPublicationRemoved;

  /// Chapter connections: shared link status.
  ///
  /// In en, this message translates to:
  /// **'Requires both approvals and a current source chapter'**
  String get blogPublicationNeedsBoth;

  /// Chapter connections: shared link status.
  ///
  /// In en, this message translates to:
  /// **'Source changed · create a new preview to share again'**
  String get blogPublicationSourceChanged;

  /// Chapter connections: approve confirm title.
  ///
  /// In en, this message translates to:
  /// **'Approve this public copy?'**
  String get blogApprovePublicCopyTitle;

  /// Chapter connections: approve confirm message.
  ///
  /// In en, this message translates to:
  /// **'The exact words above will be available to anyone with the link. Both people can withdraw sharing. No names are added automatically, but the words may identify you.'**
  String get blogApprovePublicCopyMessage;

  /// Chapter connections: approve confirm action.
  ///
  /// In en, this message translates to:
  /// **'Approve public copy'**
  String get blogApprovePublicCopyAction;

  /// Chapter connections: approve button.
  ///
  /// In en, this message translates to:
  /// **'Approve exact public copy'**
  String get blogApproveExactPublicCopy;

  /// Chapter connections: copy link button.
  ///
  /// In en, this message translates to:
  /// **'Copy link'**
  String get blogCopyLink;

  /// Chapter connections: withdraw confirm title.
  ///
  /// In en, this message translates to:
  /// **'Withdraw this link?'**
  String get blogWithdrawLinkTitle;

  /// Chapter connections: withdraw confirm message.
  ///
  /// In en, this message translates to:
  /// **'The public copy will become unavailable. Copies already saved by someone else cannot be recalled.'**
  String get blogWithdrawLinkMessage;

  /// Chapter connections: withdraw action and button.
  ///
  /// In en, this message translates to:
  /// **'Withdraw link'**
  String get blogWithdrawLink;

  /// Chapter connections: label above the member's appeal.
  ///
  /// In en, this message translates to:
  /// **'Your appeal'**
  String get blogYourAppeal;

  /// Appeal: screen title.
  ///
  /// In en, this message translates to:
  /// **'Request another review'**
  String get blogRequestReview;

  /// Appeal: help text.
  ///
  /// In en, this message translates to:
  /// **'Explain what the reviewer should reconsider. Your appeal goes privately to the trust team. Removed content stays hidden during review.'**
  String get blogRequestReviewHelp;

  /// Appeal: submit button.
  ///
  /// In en, this message translates to:
  /// **'Submit appeal'**
  String get blogSubmitAppeal;

  /// Chapter connections: appeal button.
  ///
  /// In en, this message translates to:
  /// **'Appeal this decision'**
  String get blogAppealDecision;

  /// Chapter connections: previous page button.
  ///
  /// In en, this message translates to:
  /// **'Previous'**
  String get blogPrevious;

  /// Chapter connections: next page button.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get blogMore;

  /// Private exchange: fallback error.
  ///
  /// In en, this message translates to:
  /// **'Could not confirm this change. Refresh and retry.'**
  String get blogExchangeChangeFailed;

  /// Private exchange: screen title.
  ///
  /// In en, this message translates to:
  /// **'A private Chapter exchange'**
  String get blogExchangeTitle;

  /// Private exchange: fallback error.
  ///
  /// In en, this message translates to:
  /// **'This exchange is no longer available.'**
  String get blogExchangeUnavailable;

  /// Private exchange: headline. {name} is the other member's name.
  ///
  /// In en, this message translates to:
  /// **'With {name}'**
  String blogExchangeWith(String name);

  /// Private exchange: intro.
  ///
  /// In en, this message translates to:
  /// **'A response is an invitation, never an obligation. This exchange does not create a match or unlock chat.'**
  String get blogExchangeIntro;

  /// Private exchange: accept button.
  ///
  /// In en, this message translates to:
  /// **'Accept an exchange'**
  String get blogAcceptExchange;

  /// Private exchange: decline button.
  ///
  /// In en, this message translates to:
  /// **'Decline kindly'**
  String get blogDeclineKindly;

  /// Private exchange: after sending a response.
  ///
  /// In en, this message translates to:
  /// **'Your response has been sent. There is no countdown and no need to follow up.'**
  String get blogResponseSentNote;

  /// Private exchange: after a decline.
  ///
  /// In en, this message translates to:
  /// **'This exchange is closed. Make room for another connection at your own pace.'**
  String get blogExchangeClosedNote;

  /// Private exchange: section title.
  ///
  /// In en, this message translates to:
  /// **'One small story each.'**
  String get blogOneStoryEach;

  /// Private exchange: section explanation.
  ///
  /// In en, this message translates to:
  /// **'Add a tiny continuation, a memory, or your version of the moment. Both contributions appear together, only after both people submit.'**
  String get blogOneStoryEachBody;

  /// Contribution: screen title.
  ///
  /// In en, this message translates to:
  /// **'Your side of the chapter'**
  String get blogYourSideTitle;

  /// Contribution: help text.
  ///
  /// In en, this message translates to:
  /// **'Share up to 1,000 characters. Your partner cannot read this until they also contribute. Once submitted, the words cannot be edited; you can withdraw the exchange at any time.'**
  String get blogYourSideHelp;

  /// Contribution: submit button.
  ///
  /// In en, this message translates to:
  /// **'Submit my contribution'**
  String get blogSubmitContribution;

  /// Private exchange: open the contribution screen.
  ///
  /// In en, this message translates to:
  /// **'Add my contribution'**
  String get blogAddContribution;

  /// Private exchange: label above the member's contribution.
  ///
  /// In en, this message translates to:
  /// **'Your contribution'**
  String get blogYourContribution;

  /// Private exchange: label above the other member's contribution. {name} is their name.
  ///
  /// In en, this message translates to:
  /// **'{name}’s contribution'**
  String blogPartnerContribution(String name);

  /// Private exchange: open the date plan sheet.
  ///
  /// In en, this message translates to:
  /// **'Shape a date together'**
  String get blogShapeDate;

  /// Private exchange: prefilled, editable note for a date plan.
  ///
  /// In en, this message translates to:
  /// **'Inspired by our Chapter exchange.'**
  String get blogInspiredNote;

  /// Private exchange: open the First Chapter Studio.
  ///
  /// In en, this message translates to:
  /// **'Try First Chapter Studio'**
  String get blogTryStudio;

  /// Private exchange: why date planning is unavailable.
  ///
  /// In en, this message translates to:
  /// **'Date planning becomes available if you have an active match and your conversation is unlocked.'**
  String get blogDatePlanningUnavailable;

  /// Private exchange: propose a joint public page.
  ///
  /// In en, this message translates to:
  /// **'Propose a shared journal page'**
  String get blogProposeJournalPage;

  /// Private exchange: fallback error.
  ///
  /// In en, this message translates to:
  /// **'The source chapter is unavailable.'**
  String get blogSourceUnavailable;

  /// Private exchange: after submitting a contribution.
  ///
  /// In en, this message translates to:
  /// **'Your contribution is saved privately. The reveal happens when both of you are ready.'**
  String get blogContributionSaved;

  /// Private exchange: withdraw confirm title.
  ///
  /// In en, this message translates to:
  /// **'Withdraw this exchange?'**
  String get blogWithdrawExchangeTitle;

  /// Private exchange: withdraw confirm message.
  ///
  /// In en, this message translates to:
  /// **'The response and contributions will no longer be available to either of you. Joint public links will also stop working.'**
  String get blogWithdrawExchangeMessage;

  /// Private exchange: withdraw action and button.
  ///
  /// In en, this message translates to:
  /// **'Withdraw exchange'**
  String get blogWithdrawExchange;

  /// Private exchange: report button.
  ///
  /// In en, this message translates to:
  /// **'Report exchange'**
  String get blogReportExchange;

  /// Private exchange: block confirm message.
  ///
  /// In en, this message translates to:
  /// **'Contact and access to each other’s chapters will stop.'**
  String get blogBlockMessageExchange;

  /// Private exchange: fallback error when blocking fails.
  ///
  /// In en, this message translates to:
  /// **'Could not block this member.'**
  String get blogBlockFailed;

  /// Inbox app bar action: mark all notifications read.
  ///
  /// In en, this message translates to:
  /// **'Read all'**
  String get notificationsReadAll;

  /// Title used when a notification arrives without one.
  ///
  /// In en, this message translates to:
  /// **'Notification'**
  String get notificationsFallbackTitle;

  /// Fallback error when notifications could not load.
  ///
  /// In en, this message translates to:
  /// **'Unable to load notifications.'**
  String get notificationsLoadFailed;

  /// Fallback error when notification preferences could not be saved.
  ///
  /// In en, this message translates to:
  /// **'Unable to update notification preferences.'**
  String get notificationsPrefsUpdateFailed;

  /// Compact relative time in the inbox, minutes.
  ///
  /// In en, this message translates to:
  /// **'{count}m ago'**
  String notificationsAgoMinutes(int count);

  /// Compact relative time in the inbox, hours.
  ///
  /// In en, this message translates to:
  /// **'{count}h ago'**
  String notificationsAgoHours(int count);

  /// Compact relative time in the inbox, days.
  ///
  /// In en, this message translates to:
  /// **'{count}d ago'**
  String notificationsAgoDays(int count);

  /// Reaction picker eyebrow (all caps).
  ///
  /// In en, this message translates to:
  /// **'REACT'**
  String get wallsReactEyebrow;

  /// Reaction picker heading. noun is 'photo' or 'chapter'.
  ///
  /// In en, this message translates to:
  /// **'{noun, select, photo{How does this photo make you feel?} other{How does this chapter make you feel?}}'**
  String wallsReactQuestion(String noun);

  /// Reaction picker explanation.
  ///
  /// In en, this message translates to:
  /// **'Your reaction tells them they were heard. Every reaction counts as a like.'**
  String get wallsReactBody;

  /// Reaction picker button: remove my reaction.
  ///
  /// In en, this message translates to:
  /// **'Take my reaction back'**
  String get wallsReactRemove;

  /// Screen reader label for the reaction summary. {list} is e.g. '3 I hear you, 2 Me too'.
  ///
  /// In en, this message translates to:
  /// **'Reactions: {list}'**
  String wallsReactionsSemantics(String list);

  /// Empathy reaction label (wire id 'love').
  ///
  /// In en, this message translates to:
  /// **'Love this'**
  String get wallsReactionLove;

  /// Empathy reaction label (wire id 'hear_you').
  ///
  /// In en, this message translates to:
  /// **'I hear you'**
  String get wallsReactionHearYou;

  /// Empathy reaction label (wire id 'me_too').
  ///
  /// In en, this message translates to:
  /// **'Me too'**
  String get wallsReactionMeToo;

  /// Empathy reaction label (wire id 'with_you').
  ///
  /// In en, this message translates to:
  /// **'I’m with you'**
  String get wallsReactionWithYou;

  /// Empathy reaction label (wire id 'hug').
  ///
  /// In en, this message translates to:
  /// **'Sending a hug'**
  String get wallsReactionHug;

  /// Empathy reaction label (wire id 'proud').
  ///
  /// In en, this message translates to:
  /// **'Proud of you'**
  String get wallsReactionProud;

  /// Error when the Today wall is opened while signed out.
  ///
  /// In en, this message translates to:
  /// **'Sign in to see your wall.'**
  String get wallsSignInRequired;

  /// Celebration card headline: the member's photo is Cover of the Week.
  ///
  /// In en, this message translates to:
  /// **'Your photo is Cover of the Week'**
  String get celebrationCoverHeadline;

  /// Celebration card headline when work reached N walls. kind is 'photo' or 'chapter'.
  ///
  /// In en, this message translates to:
  /// **'{kind, select, photo{Your photo reached {reach} walls} other{Your chapter reached {reach} walls}}'**
  String celebrationReachHeadline(String kind, int reach);

  /// Celebration card line for Cover of the Week.
  ///
  /// In en, this message translates to:
  /// **'Members loved it. Everyone sees it on Today this week.'**
  String get celebrationCoverMessage;

  /// Celebration card line when work reached more walls.
  ///
  /// In en, this message translates to:
  /// **'Members loved it. It is now on their Today walls.'**
  String get celebrationReachMessage;

  /// The celebrated chapter or photo title in quotation marks.
  ///
  /// In en, this message translates to:
  /// **'“{title}”'**
  String celebrationQuotedTitle(String title);

  /// Accessibility label for the dismissible celebration overlay.
  ///
  /// In en, this message translates to:
  /// **'Celebration'**
  String get celebrationBarrier;

  /// Celebration card button: close.
  ///
  /// In en, this message translates to:
  /// **'Lovely'**
  String get celebrationLovely;

  /// Celebration card button: open the photo.
  ///
  /// In en, this message translates to:
  /// **'See photo'**
  String get celebrationSeePhoto;

  /// Celebration card button: open the chapter.
  ///
  /// In en, this message translates to:
  /// **'See chapter'**
  String get celebrationSeeChapter;

  /// XP gained pill on a reward burst.
  ///
  /// In en, this message translates to:
  /// **'+{xp} XP'**
  String rewardXpPill(int xp);

  /// Reward burst headline after claiming a reward.
  ///
  /// In en, this message translates to:
  /// **'Reward claimed'**
  String get rewardClaimedTitle;

  /// Reward burst subtitle: reward name and description.
  ///
  /// In en, this message translates to:
  /// **'{name} · {description}'**
  String rewardNameDescription(String name, String description);

  /// Screen reader phrase for XP gained.
  ///
  /// In en, this message translates to:
  /// **'plus {xp} XP'**
  String rewardPlusXpAnnouncement(int xp);

  /// Reward burst detail line: source and XP.
  ///
  /// In en, this message translates to:
  /// **'{source} +{xp} XP'**
  String rewardSourceXpLine(String source, int xp);

  /// Reward burst detail line when more rewards arrived.
  ///
  /// In en, this message translates to:
  /// **'and {count} more'**
  String rewardAndMore(int count);

  /// Reward burst detail line for a new badge. {badge} is the server badge name.
  ///
  /// In en, this message translates to:
  /// **'Badge: {badge}'**
  String rewardBadgeLine(String badge);

  /// Reward burst headline on level up.
  ///
  /// In en, this message translates to:
  /// **'Level {level} reached'**
  String rewardLevelReached(int level);

  /// Reward burst headline for new badges.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Badge earned} other{{count} badges earned}}'**
  String rewardBadgesEarned(int count);

  /// Reward burst headline on the first look of the day.
  ///
  /// In en, this message translates to:
  /// **'Your rewards today'**
  String get rewardYourRewardsToday;

  /// Reward burst headline for several new rewards.
  ///
  /// In en, this message translates to:
  /// **'{count} new rewards'**
  String rewardNewRewards(int count);

  /// Reward source name for 'story_published'.
  ///
  /// In en, this message translates to:
  /// **'Chapter published'**
  String get rewardSourceStoryPublished;

  /// Reward source name for 'photo_shared'.
  ///
  /// In en, this message translates to:
  /// **'Photo shared'**
  String get rewardSourcePhotoShared;

  /// Reward source name for 'like_received'.
  ///
  /// In en, this message translates to:
  /// **'A member liked your work'**
  String get rewardSourceLikeReceived;

  /// Reward source name for 'comment_received'.
  ///
  /// In en, this message translates to:
  /// **'New comment on your work'**
  String get rewardSourceCommentReceived;

  /// Reward source name for 'comment_approved'.
  ///
  /// In en, this message translates to:
  /// **'Your comment was approved'**
  String get rewardSourceCommentApproved;

  /// Reward source name for 'subscriber_gained'.
  ///
  /// In en, this message translates to:
  /// **'New subscriber'**
  String get rewardSourceSubscriberGained;

  /// Reward source name for 'wall_tier_reached'.
  ///
  /// In en, this message translates to:
  /// **'Wall tier reached'**
  String get rewardSourceWallTierReached;

  /// Reward source name for 'cover_of_week'.
  ///
  /// In en, this message translates to:
  /// **'Cover of the Week'**
  String get rewardSourceCoverOfWeek;

  /// Reward source name for 'daily_prompt_submitted'.
  ///
  /// In en, this message translates to:
  /// **'Daily prompt answered'**
  String get rewardSourceDailyPromptSubmitted;

  /// Line under a single reward headline for source 'story_published'.
  ///
  /// In en, this message translates to:
  /// **'Your chapter is out in the world.'**
  String get rewardLineStoryPublished;

  /// Line under a single reward headline for source 'photo_shared'.
  ///
  /// In en, this message translates to:
  /// **'Your photo joined the theme.'**
  String get rewardLinePhotoShared;

  /// Line under a single reward headline for source 'like_received'.
  ///
  /// In en, this message translates to:
  /// **'Someone loved what you shared.'**
  String get rewardLineLikeReceived;

  /// Line under a single reward headline for source 'comment_received'.
  ///
  /// In en, this message translates to:
  /// **'A reader joined the conversation.'**
  String get rewardLineCommentReceived;

  /// Line under a single reward headline for source 'subscriber_gained'.
  ///
  /// In en, this message translates to:
  /// **'Someone wants your next chapter.'**
  String get rewardLineSubscriberGained;

  /// Line under a single reward headline for source 'wall_tier_reached'.
  ///
  /// In en, this message translates to:
  /// **'Your work reached more walls.'**
  String get rewardLineWallTierReached;

  /// Line under a single reward headline for source 'cover_of_week'.
  ///
  /// In en, this message translates to:
  /// **'Everyone sees it on Today this week.'**
  String get rewardLineCoverOfWeek;

  /// Line under a single reward headline for source 'other'.
  ///
  /// In en, this message translates to:
  /// **'Earned for meaningful activity.'**
  String get rewardLineOther;

  /// Badge name used when the server sends none.
  ///
  /// In en, this message translates to:
  /// **'New badge'**
  String get rewardNewBadgeFallback;

  /// Name shown for a blocked member whose name is unavailable.
  ///
  /// In en, this message translates to:
  /// **'Unknown User'**
  String get blockedUnknownUser;

  /// One-line description of the 'bluerose' look (theme name stays untranslated).
  ///
  /// In en, this message translates to:
  /// **'Midnight velvet, sapphire roses and a platinum edge.'**
  String get themeTaglineBluerose;

  /// One-line description of the 'bluelotus' look (theme name stays untranslated).
  ///
  /// In en, this message translates to:
  /// **'Moonlit water, sapphire petals and a golden heart.'**
  String get themeTaglineBluelotus;

  /// Snack bar after tapping Message on a profile you have not matched with yet: a like was sent instead.
  ///
  /// In en, this message translates to:
  /// **'Love sent to {name}. You can chat as soon as they like you back.'**
  String discoverMessageLikeSent(String name);

  /// Notification inbox: snack bar when swiping a notification away failed on the server; the notification is put back.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t remove that notification. Try again.'**
  String get notificationsDismissFailed;

  /// Notification inbox: snack bar when 'Read all' failed on the server; the notifications stay unread.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t mark them all as read. Try again.'**
  String get notificationsReadAllFailed;

  /// Chapter page: snackbar after a report about the chapter was sent.
  ///
  /// In en, this message translates to:
  /// **'Report submitted. Thank you.'**
  String get blogReportSubmitted;

  /// Settings: heading of the Account section at the top (who is signed in, sign out).
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get settingsSectionAccount;

  /// Settings, Account section: which member is signed in on this device.
  ///
  /// In en, this message translates to:
  /// **'Signed in as @{username}'**
  String settingsSignedInAs(String username);

  /// Settings: button that signs the member out on this device (also the confirm button of the sign-out dialog).
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get settingsSignOut;

  /// Settings: subtitle under 'Sign out'.
  ///
  /// In en, this message translates to:
  /// **'End your session on this device'**
  String get settingsSignOutSubtitle;

  /// Settings: button that ends the member's sessions on every device, this one included.
  ///
  /// In en, this message translates to:
  /// **'Sign out of all devices'**
  String get settingsSignOutAllTitle;

  /// Settings: subtitle under 'Sign out of all devices'.
  ///
  /// In en, this message translates to:
  /// **'End every session, on every phone and browser'**
  String get settingsSignOutAllSubtitle;

  /// Settings: title of the dialog that confirms signing out on this device.
  ///
  /// In en, this message translates to:
  /// **'Sign out?'**
  String get settingsSignOutConfirmTitle;

  /// Settings: body of the dialog that confirms signing out on this device.
  ///
  /// In en, this message translates to:
  /// **'You\'ll need your username and password to sign in again on this device.'**
  String get settingsSignOutConfirmBody;

  /// Settings: title of the dialog that confirms signing out of all devices.
  ///
  /// In en, this message translates to:
  /// **'Sign out of all devices?'**
  String get settingsSignOutAllConfirmTitle;

  /// Settings: body of the dialog that confirms signing out of all devices.
  ///
  /// In en, this message translates to:
  /// **'This ends your session on every phone, tablet and browser, including this one. Anyone signed in to your account elsewhere will be signed out.'**
  String get settingsSignOutAllConfirmBody;

  /// Settings: confirm button of the 'Sign out of all devices?' dialog.
  ///
  /// In en, this message translates to:
  /// **'Sign out everywhere'**
  String get settingsSignOutAllConfirmAction;

  /// Settings: shown when the server could not end the other sessions; the member stays signed in.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t sign out your other devices. Check your connection and try again.'**
  String get settingsSignOutAllFailed;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>[
    'de',
    'en',
    'es',
    'fr',
    'it',
    'nl',
    'pl',
    'pt',
    'ru',
  ].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when language+country codes are specified.
  switch (locale.languageCode) {
    case 'en':
      {
        switch (locale.countryCode) {
          case 'GB':
            return AppLocalizationsEnGb();
        }
        break;
      }
  }

  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'fr':
      return AppLocalizationsFr();
    case 'it':
      return AppLocalizationsIt();
    case 'nl':
      return AppLocalizationsNl();
    case 'pl':
      return AppLocalizationsPl();
    case 'pt':
      return AppLocalizationsPt();
    case 'ru':
      return AppLocalizationsRu();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
