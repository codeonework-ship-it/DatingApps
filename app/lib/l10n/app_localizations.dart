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
