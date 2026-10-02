// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get navDiscover => 'Discover';

  @override
  String get navMatches => 'Matches';

  @override
  String get navEngage => 'Engage';

  @override
  String get navProfile => 'Profile';

  @override
  String get navSettings => 'Settings';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsSectionProfile => 'Profile';

  @override
  String get settingsEditProfileTitle => 'Edit Profile';

  @override
  String get settingsEditProfileSubtitle => 'Update your information';

  @override
  String get settingsPhotosTitle => 'Photos';

  @override
  String get settingsPhotosSubtitle => 'Manage your photos';

  @override
  String get settingsSectionPreferences => 'Preferences';

  @override
  String get settingsAppearanceTitle => 'Appearance';

  @override
  String get settingsAppearanceSubtitle => 'Saved to your account';

  @override
  String get settingsThemeLight => 'Light';

  @override
  String get settingsThemeDark => 'Dark';

  @override
  String get settingsThemeMatchDevice => 'Match device';

  @override
  String get settingsLooksTitle => 'Looks';

  @override
  String get settingsLooksClassicDescription =>
      'Warm ivory and forest by day. Soft mint and deep forest by night.';

  @override
  String get settingsLooksClassicLabel => 'Today';

  @override
  String get settingsThemeSaveFailed =>
      'Could not save your theme. Please try again.';

  @override
  String get settingsLanguageTitle => 'Language';

  @override
  String get settingsLanguageSubtitle => 'Choose the app language';

  @override
  String get settingsDatingPreferencesTitle => 'Dating Preferences';

  @override
  String get settingsDatingPreferencesSubtitle => 'Age, location, interests';

  @override
  String get settingsAccountDataTitle => 'Account & Data';

  @override
  String get settingsAccountDataSubtitle =>
      'Hide, download or delete your account';

  @override
  String get settingsNotificationsTitle => 'Notifications';

  @override
  String get settingsNotificationsSubtitle => 'Push & email notifications';

  @override
  String get settingsSectionEngagement => 'Engagement';

  @override
  String get settingsTrustBadgesTitle => 'Trust Badges';

  @override
  String get settingsTrustBadgesSubtitle =>
      'See earned badges and trust history';

  @override
  String get settingsTrustFiltersTitle => 'Trust Filters';

  @override
  String get settingsTrustFiltersSubtitle =>
      'Control trust requirements for discovery';

  @override
  String get settingsConversationRoomsTitle => 'Conversation Rooms';

  @override
  String get settingsConversationRoomsSubtitle =>
      'Browse, join, leave, and moderate rooms';

  @override
  String get settingsFriendsTitle => 'Friends & Connections';

  @override
  String get settingsFriendsSubtitle => 'Build and maintain friend connections';

  @override
  String get settingsCallHistoryTitle => 'Call History';

  @override
  String get settingsCallHistorySubtitle => 'Review durable call sessions';

  @override
  String get settingsMatchNudgesTitle => 'Match Nudges';

  @override
  String get settingsMatchNudgesSubtitle => 'Restart quiet conversations';

  @override
  String get settingsSubscriptionsTitle => 'Subscriptions';

  @override
  String get settingsSubscriptionsSubtitle =>
      'Plans, entitlement status, and payments';

  @override
  String get settingsSectionApp => 'App';

  @override
  String get settingsPrivacySafetyTitle => 'Privacy & Safety';

  @override
  String get settingsPrivacySafetySubtitle => 'Manage your privacy settings';

  @override
  String get settingsGovernmentVerificationTitle => 'Government Verification';

  @override
  String get settingsGovernmentVerificationSubtitle =>
      'View identity verification status';

  @override
  String get settingsQaVerificationUploadTitle => 'QA Verification Upload';

  @override
  String get settingsQaVerificationUploadSubtitle =>
      'Automation-only ID and selfie flow';

  @override
  String get settingsHelpSupportTitle => 'Help & Support';

  @override
  String get settingsHelpSupportSubtitle => 'FAQ and contact support';

  @override
  String get settingsAboutTitle => 'About';

  @override
  String get settingsAboutSubtitle => 'App details and stack';

  @override
  String get settingsLogout => 'Logout';

  @override
  String get languageTitle => 'Language';

  @override
  String get languageIntro =>
      'Pick the language Connect uses. Your choice is saved to your account and applies on every device you sign in on.';

  @override
  String get languageUseDevice => 'Use device language';

  @override
  String get languageUseDeviceSubtitle =>
      'Follows your phone\'s language setting';

  @override
  String get languageSaveFailed =>
      'Could not save your language. Please try again.';

  @override
  String get notificationsTitle => 'Notifications';

  @override
  String get notificationsInboxTitle => 'Notification inbox';

  @override
  String get notificationsInboxCaughtUp => 'You are all caught up';

  @override
  String notificationsInboxUnread(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count unread',
      one: '1 unread',
    );
    return '$_temp0';
  }

  @override
  String get notificationsInAppTitle => 'In-app notifications';

  @override
  String get notificationsInAppSubtitle =>
      'Show notifications while using the app';

  @override
  String get notificationsPushTitle => 'Push notifications';

  @override
  String get notificationsPushSubtitle =>
      'Allow delivery when the app is in background';

  @override
  String get notificationsNewMatchesTitle => 'New matches';

  @override
  String get notificationsNewMatchesSubtitle => 'Get notified when you match';

  @override
  String get notificationsNewMessagesTitle => 'New messages';

  @override
  String get notificationsNewMessagesSubtitle =>
      'Get notified for chat messages';

  @override
  String get notificationsLikesTitle => 'Likes';

  @override
  String get notificationsLikesSubtitle =>
      'Get notified when someone likes you';

  @override
  String get notificationsMatchNudgesTitle => 'Match nudges';

  @override
  String get notificationsMatchNudgesSubtitle =>
      'Get notified when a match nudges you';

  @override
  String get notificationsIncomingCallsTitle => 'Incoming calls';

  @override
  String get notificationsIncomingCallsSubtitle => 'Show incoming call alerts';

  @override
  String get notificationsSafetyTitle => 'Safety updates';

  @override
  String get notificationsSafetySubtitle =>
      'Receive important safety status updates';

  @override
  String get notificationsFriendPlansTitle => 'Friends\' date plans';

  @override
  String get notificationsFriendPlansSubtitle =>
      'Know when a friend plans a date or checks in';

  @override
  String get welcomeTagline => 'Made for real life.';

  @override
  String get welcomePhotoNote => 'Offline is the goal.';

  @override
  String get welcomeHeadlineLead => 'A good story\nstarts with ';

  @override
  String get welcomeHeadlineAccent => 'hello.';

  @override
  String get welcomeBody =>
      'Find someone who feels like your kind of person. Take it from there.';

  @override
  String get welcomeCreateAccount => 'Create account';

  @override
  String get welcomeAlreadyMember => 'Already a member? ';

  @override
  String get welcomeSignIn => 'Sign in';

  @override
  String get welcomeFooter => '18+  ·  Your pace. Your choice.';

  @override
  String get authBackTooltip => 'Back to welcome';

  @override
  String get authHeadline => 'Good to see you.';

  @override
  String get authSubtitle => 'Use your username and password to continue';

  @override
  String get authWelcomeBack => 'Welcome back';

  @override
  String get authNextHello => 'Your next hello is waiting.';

  @override
  String get authUsernameHint => 'username';

  @override
  String get authPasswordHint => 'Password';

  @override
  String get authShowPassword => 'Show password';

  @override
  String get authHidePassword => 'Hide password';

  @override
  String get authCantSignIn => 'Can\'t sign in?';

  @override
  String get authSignIn => 'Sign in';

  @override
  String get authPrivacyNote =>
      'Your password is sent only when you sign in and is never stored in the app.';

  @override
  String get authEnterUsername => 'Please enter your username.';

  @override
  String get authEnterPassword => 'Please enter your password.';

  @override
  String get commonYes => 'Yes';

  @override
  String get commonNo => 'No';

  @override
  String get planVenueCoffee => 'Coffee';

  @override
  String get planVenueMeal => 'A meal';

  @override
  String get planVenueDrinks => 'Drinks';

  @override
  String get planVenueWalk => 'A walk';

  @override
  String get planVenueActivity => 'An activity';

  @override
  String get planVenueEvent => 'An event';

  @override
  String get planVenueVideoCall => 'Video call';

  @override
  String get planVenueOther => 'Something else';

  @override
  String planProposeTitle(String name) {
    return 'Plan a date with $name';
  }

  @override
  String get planProposeSubtitle =>
      'Shape a first hello together. Contact sharing starts off.';

  @override
  String get planProposeButton => 'Propose';

  @override
  String planHeadlineProposed(String name) {
    return '$name proposed a date';
  }

  @override
  String planHeadlineWaiting(String name) {
    return 'Waiting for $name';
  }

  @override
  String get planHeadlineUpcoming => 'It is a plan';

  @override
  String get planHeadlineCheckin => 'How did it go?';

  @override
  String get planHeadlineDebrief => 'How was it?';

  @override
  String get planHeadlineDebriefComplete => 'Debrief complete';

  @override
  String planHeadlineWaitingDebrief(String name) {
    return 'Waiting for $name\'s debrief';
  }

  @override
  String get planHeadlineCheckedInSafe => 'You checked in safe';

  @override
  String get planHeadlineFriendsAlerted => 'Your request for help is recorded';

  @override
  String get planHeadlineDefault => 'Plan';

  @override
  String get planStatusProposed => 'Proposed';

  @override
  String get planStatusConfirmed => 'Confirmed';

  @override
  String get planDebriefButton => 'Ten-second debrief';

  @override
  String get planDecline => 'Decline';

  @override
  String get planAccept => 'Accept';

  @override
  String get planFriendsKnowAccepted =>
      'Choose trusted contacts to share your updates.';

  @override
  String get planFriendsKnowProposed =>
      'Contact sharing is optional for each plan.';

  @override
  String get planCancel => 'Cancel plan';

  @override
  String get planNeedHelp => 'I need help';

  @override
  String get planImSafe => 'I\'m safe';

  @override
  String get planCancelDialogTitle => 'Cancel this plan?';

  @override
  String planCancelDialogBody(String name) {
    return '$name and everyone you shared it with will be told.';
  }

  @override
  String get planKeepIt => 'Keep it';

  @override
  String get planProposeIntro =>
      'This starts between you and your date. After proposing, choose trusted contacts if you want to share plan and check-in updates.';

  @override
  String get planSectionWhen => 'When';

  @override
  String get planSectionWhat => 'What';

  @override
  String get planSectionGroups => 'Trusted contacts';

  @override
  String planDurationHours(int hours) {
    return '$hours h';
  }

  @override
  String get planPlaceLabel => 'Place (optional)';

  @override
  String get planPlaceHint => 'A public place works best';

  @override
  String get planAreaLabel => 'Area or neighborhood';

  @override
  String get planNoteLabel => 'Note for them (optional)';

  @override
  String get planFutureTimeError => 'Pick a time in the future.';

  @override
  String get planProposeFailed => 'Unable to propose this plan.';

  @override
  String get planSendButton => 'Send the plan';

  @override
  String get planAcceptTitle => 'Accept the plan?';

  @override
  String get planAcceptIntro =>
      'Accept this plan with your date. Choose trusted contacts afterwards if you want to share your updates.';

  @override
  String get planAcceptButton => 'Accept plan';

  @override
  String debriefTitle(String name) {
    return 'How was it with $name?';
  }

  @override
  String get debriefIntro =>
      'Your answers are private. When you both confirm the date happened, it counts toward your Shows Up badge.';

  @override
  String get debriefHappened => 'Did the date happen?';

  @override
  String get debriefMeetAgain => 'Would you meet again?';

  @override
  String get debriefFeltSafe => 'Did you feel safe?';

  @override
  String get debriefNoteLabel => 'Anything to add? (optional)';

  @override
  String get debriefMissingHappened => 'Tell us whether the date happened.';

  @override
  String get debriefSaveFailed => 'Unable to save your debrief.';

  @override
  String get debriefSave => 'Save debrief';

  @override
  String get debriefUnsafeTitle => 'Sorry that did not feel safe';

  @override
  String debriefUnsafeBody(String name) {
    return 'Your answer is noted for our safety team. Do you also want to report $name?';
  }

  @override
  String get debriefNotNow => 'Not now';

  @override
  String get debriefReport => 'Report';

  @override
  String get plansTitle => 'Date plans';

  @override
  String get plansTabMine => 'Mine';

  @override
  String get plansTabFriends => 'Friends';

  @override
  String get plansEmptyMineTitle => 'No plans yet';

  @override
  String get plansEmptyMineBody =>
      'Propose a date from a conversation. You choose whether to share plan and check-in updates with trusted contacts.';

  @override
  String plansWith(String name) {
    return 'With $name';
  }

  @override
  String get plansNextDecide => 'Waiting for your answer';

  @override
  String plansNextAwait(String name) {
    return 'Waiting for $name';
  }

  @override
  String get plansNextUpcoming => 'Confirmed. Your time together is planned.';

  @override
  String get plansNextCheckin => 'Check in after your date';

  @override
  String get plansNextDebrief => 'Tell us how it went';

  @override
  String get plansNextCancelled => 'Canceled';

  @override
  String get plansNextDone => 'Done';

  @override
  String get plansEmptyFriendsTitle => 'Nothing shared yet';

  @override
  String get plansEmptyFriendsBody =>
      'Plans appear here when friends explicitly choose to share with you.';

  @override
  String get plansViaGroup => 'Shared with you';

  @override
  String get plansViaFriend => 'Trusted contact';

  @override
  String plansFriendNeedsHelp(String name) {
    return '$name asked for help. Reach out now.';
  }

  @override
  String plansFriendMissedCheckin(String name) {
    return '$name has not checked in yet.';
  }

  @override
  String plansFriendCheckedInSafe(String name, String via) {
    return '$name checked in safe · $via';
  }

  @override
  String plansFriendStatusLine(String via, String status) {
    return '$via · $status';
  }

  @override
  String get plansStatusWordProposed => 'proposed';

  @override
  String get plansStatusWordConfirmed => 'confirmed';

  @override
  String get plansStatusWordCancelled => 'canceled';

  @override
  String get plansStatusWordHappened => 'happened';

  @override
  String get chatEmptyDefault =>
      'Say hello. Messages appear here for everyone in this conversation.';

  @override
  String get chatNotSentRetry => 'Not sent. Tap the message to retry.';

  @override
  String get chatRetrySend => 'Try sending again';

  @override
  String get chatCopyText => 'Copy text';

  @override
  String get chatDeleteMine => 'Delete my message';

  @override
  String get chatRemoveMessage => 'Remove message';

  @override
  String get chatReportMessage => 'Report message';

  @override
  String get chatThisMember => 'This member';

  @override
  String get chatMember => 'Member';

  @override
  String get chatCopied => 'Copied.';

  @override
  String get chatDeleteFailed => 'Could not delete. Please retry.';

  @override
  String get chatSubtitleFriends => 'Friends';

  @override
  String chatMemberCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count members',
      one: '1 member',
    );
    return '$_temp0';
  }

  @override
  String get chatReconnecting =>
      'Reconnecting. New messages may take a moment.';

  @override
  String get chatUnavailable =>
      'This conversation is unavailable. You may no longer be a member.';

  @override
  String get chatTryAgain => 'Try again';

  @override
  String get chatStatusNotSent => 'Not sent · tap and hold to retry';

  @override
  String get chatStatusSending => 'Sending…';

  @override
  String get chatMessageRemoved => 'Message removed';

  @override
  String chatSemanticsYouAt(String time) {
    return 'You at $time';
  }

  @override
  String chatSemanticsMemberAt(String name, String time) {
    return '$name at $time';
  }

  @override
  String chatAboutMember(String name) {
    return 'About $name';
  }

  @override
  String get chatComposerHint => 'Write a message';

  @override
  String get chatMutedComposerHint => 'You can’t post right now';

  @override
  String get chatSend => 'Send';

  @override
  String chatRoomMutedUntil(String when) {
    return 'You’re muted in this room until $when. You can still read along.';
  }

  @override
  String get chatRoomMuted =>
      'You’re muted in this room. You can still read along.';

  @override
  String chatReadOnlyUntil(String when) {
    return 'You can read this conversation but can’t post until $when.';
  }

  @override
  String get chatReadOnly =>
      'You can read this conversation but can’t post right now.';

  @override
  String get chatMuteTooltip => 'Mute notifications';

  @override
  String get chatMutedTooltip => 'Notifications muted';

  @override
  String get chatMuteSheetTitle => 'Mute notifications';

  @override
  String get chatMuteSheetBody =>
      'Messages still arrive here, just without notifications.';

  @override
  String get chatMuteOneHour => 'For 1 hour';

  @override
  String get chatMuteEightHours => 'For 8 hours';

  @override
  String get chatMuteOneWeek => 'For 1 week';

  @override
  String get chatMuteForever => 'Until I turn it back on';

  @override
  String get chatUnmute => 'Turn notifications back on';

  @override
  String chatMutedUntilLabel(String when) {
    return 'Muted until $when';
  }

  @override
  String get chatMutedIndefinitely =>
      'Muted until you turn notifications back on.';

  @override
  String get chatMuteDone => 'Notifications muted.';

  @override
  String get chatUnmuteDone => 'Notifications are back on.';

  @override
  String get chatMuteFailed => 'Could not change notifications. Please retry.';

  @override
  String get roomsClosedSnack => 'This room has closed.';

  @override
  String get roomsChatNotOpen => 'This room’s chat isn’t open yet.';

  @override
  String get roomsJoinFailed => 'Could not join this room. Please retry.';

  @override
  String get roomsStartRoom => 'Start a room';

  @override
  String get roomsEyebrow => 'LIVE CHAT';

  @override
  String get roomsTitle => 'Rooms';

  @override
  String get roomsSubtitle =>
      'Drop into a conversation. If you click with someone, add them as a friend.';

  @override
  String get roomsSectionRooms => 'ROOMS';

  @override
  String get roomsSectionYours => 'YOUR ROOMS';

  @override
  String get roomsYoursCaption => 'Rooms you’re in. Tap to pick up the chat.';

  @override
  String get roomsSectionLive => 'LIVE NOW';

  @override
  String get roomsLiveTitle => 'Where people are talking';

  @override
  String get roomsSectionBrowse => 'BROWSE';

  @override
  String get roomsBrowseTitle => 'Find your room';

  @override
  String get roomsBrowseCaption =>
      'Always open. Pick a topic, say hi, and see who you click with.';

  @override
  String get roomsNoFriendsHere =>
      'None of your friends are in a room here right now.';

  @override
  String get roomsNoRoomsInTopic => 'No rooms in this topic yet.';

  @override
  String get roomsSectionComingUp => 'COMING UP';

  @override
  String get roomsComingUpCaption =>
      'Rooms members are hosting. Join early to save a spot.';

  @override
  String get roomsCategoryAll => 'All';

  @override
  String get roomsCategoryTalk => 'Talk';

  @override
  String get roomsCategoryInterests => 'Interests';

  @override
  String get roomsCategoryActive => 'Out & about';

  @override
  String get roomsCategoryCity => 'Your city';

  @override
  String get roomsFriendsHereChip => 'Friends here';

  @override
  String get roomsQuiet => 'Quiet right now. Be the first to say hello.';

  @override
  String roomsPeopleCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count people',
      one: '1 person',
    );
    return '$_temp0';
  }

  @override
  String roomsRoomCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count rooms',
      one: '1 room',
    );
    return '$_temp0';
  }

  @override
  String roomsChattingIn(String people, String rooms) {
    return '$people chatting in $rooms';
  }

  @override
  String roomsHereNow(int count) {
    return '$count here now';
  }

  @override
  String roomsInTheRoom(int count) {
    return '$count in the room';
  }

  @override
  String roomsFriendsHere(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count friends here',
      one: '1 friend here',
    );
    return '$_temp0';
  }

  @override
  String get roomsHostedByYou => 'Hosted by you';

  @override
  String roomsHostedBy(String name) {
    return 'Hosted by $name';
  }

  @override
  String get roomsActionOpen => 'Open';

  @override
  String get roomsActionFull => 'Full';

  @override
  String get roomsActionJoin => 'Join';

  @override
  String roomsStartsAt(String time) {
    return 'Starts $time';
  }

  @override
  String roomsStartsOn(String day, String time) {
    return 'Starts $day $time';
  }

  @override
  String get roomsStartNameTooShort =>
      'Give the room a name of at least 3 letters.';

  @override
  String get roomsStartIntro =>
      'You host it: you can warn, mute or remove people, and close it when you’re done. One room at a time.';

  @override
  String get roomsStartNameLabel => 'Room name';

  @override
  String get roomsStartNameHint => 'Sunday book swap';

  @override
  String get roomsStartAboutLabel => 'What’s it about? (optional)';

  @override
  String get roomsStartTopic => 'Topic';

  @override
  String get roomsStartHowLong => 'How long';

  @override
  String get roomsLength30Min => '30 min';

  @override
  String get roomsLength1Hour => '1 hour';

  @override
  String get roomsLength2Hours => '2 hours';

  @override
  String get roomsStartNow => 'Start now';

  @override
  String get roomsRoleHost => 'Host';

  @override
  String get roomsRoleModerator => 'Moderator';

  @override
  String get roomsRoomFallback => 'Room';

  @override
  String roomsChatEmpty(String room) {
    return 'You’re in. Say hello: everyone in $room sees what you write here.';
  }

  @override
  String get roomsPeopleTooltip => 'People in this room';

  @override
  String roomsLeaveTitle(String room) {
    return 'Leave $room?';
  }

  @override
  String get roomsLeaveBody =>
      'You’ll stop seeing this room’s messages. You can come back any time it’s open.';

  @override
  String get roomsLeaveAction => 'Leave room';

  @override
  String get roomsLeaveFailed => 'Could not leave. Please retry.';

  @override
  String roomsCloseTitle(String room) {
    return 'Close $room?';
  }

  @override
  String get roomsCloseBody =>
      'The chat ends for everyone in the room. This can’t be undone.';

  @override
  String get roomsCloseAction => 'Close room';

  @override
  String get roomsCloseFailed => 'Could not close. Please retry.';

  @override
  String get roomsMenuTooltip => 'Room options';

  @override
  String get roomsMenuPeople => 'People here';

  @override
  String get roomsMenuModerate => 'Moderate';

  @override
  String roomsModerateTitle(String room) {
    return 'Moderate $room';
  }

  @override
  String get roomsModerateIntro =>
      'Tap someone to warn, mute or remove them. Muted members can still read; removed members can rejoin when the session ends.';

  @override
  String get roomsPeopleIntro =>
      'Click with someone? Add them as a friend to keep talking after the room.';

  @override
  String get roomsMembersLoadFailed => 'Could not load who is here.';

  @override
  String get roomsStatusFriend => 'Friend';

  @override
  String get roomsStatusHereNow => 'Here now';

  @override
  String get roomsStatusInRoom => 'In the room';

  @override
  String get roomsStatusGone => 'No longer in the room';

  @override
  String roomsStatusMutedUntil(String time) {
    return 'Muted until $time';
  }

  @override
  String roomsYouSuffix(String name) {
    return '$name (you)';
  }

  @override
  String roomsRemoveTitle(String name) {
    return 'Remove $name from the room?';
  }

  @override
  String roomsRemoveBodyAlwaysOn(String name) {
    return '$name leaves the chat now and can come back after 24 hours.';
  }

  @override
  String roomsRemoveBodyHosted(String name) {
    return '$name leaves the chat now and can’t rejoin until this room ends.';
  }

  @override
  String roomsWarnTitle(String name) {
    return 'Warn $name?';
  }

  @override
  String roomsWarnBody(String name) {
    return '$name gets a private reminder to keep the conversation kind and on topic.';
  }

  @override
  String get roomsRemoveAction => 'Remove';

  @override
  String get roomsWarnAction => 'Send warning';

  @override
  String roomsRemovedDone(String name) {
    return '$name was removed from the room.';
  }

  @override
  String roomsWarnedDone(String name) {
    return 'Warning sent to $name.';
  }

  @override
  String get roomsModerationFailed => 'That did not go through. Retry.';

  @override
  String roomsBlockedDone(String name) {
    return 'You blocked $name. You won’t see each other’s messages here.';
  }

  @override
  String get roomsReport => 'Report';

  @override
  String get roomsBlock => 'Block';

  @override
  String get roomsModerateEyebrow => 'MODERATE';

  @override
  String get roomsWarn => 'Warn';

  @override
  String get roomsRemoveFromRoom => 'Remove from room';

  @override
  String get roomsMute => 'Mute';

  @override
  String get roomsUnmute => 'Unmute';

  @override
  String roomsMuteSheetTitle(String name) {
    return 'Mute $name?';
  }

  @override
  String roomsMuteSheetBody(String name) {
    return '$name can still read the chat but can’t post until the mute ends. They’ll get a private note.';
  }

  @override
  String get roomsMuteTenMinutes => 'For 10 minutes';

  @override
  String get roomsMuteOneHour => 'For 1 hour';

  @override
  String get roomsMuteUntilEnd => 'Until the room ends';

  @override
  String get roomsMuteOneDay => 'For 24 hours';

  @override
  String roomsMutedDone(String name) {
    return '$name is muted.';
  }

  @override
  String roomsUnmutedDone(String name) {
    return '$name can post again.';
  }

  @override
  String get richFormattingToolbar => 'Formatting';

  @override
  String get richUndo => 'Undo';

  @override
  String get richRedo => 'Redo';

  @override
  String get richBold => 'Bold';

  @override
  String get richItalic => 'Italic';

  @override
  String get richUnderline => 'Underline';

  @override
  String get richStrikethrough => 'Strikethrough';

  @override
  String get richHighlight => 'Highlight';

  @override
  String get richLink => 'Link';

  @override
  String get richTextStyleMenu => 'Text style';

  @override
  String get richParagraph => 'Paragraph';

  @override
  String get richHeading => 'Heading';

  @override
  String get richSubheading => 'Subheading';

  @override
  String get richQuote => 'Quote';

  @override
  String get richCallout => 'Callout';

  @override
  String get richBulletList => 'Bulleted list';

  @override
  String get richNumberedList => 'Numbered list';

  @override
  String get richDivider => 'Section break';

  @override
  String get richAlignMenu => 'Alignment';

  @override
  String get richAlignStart => 'Align to start';

  @override
  String get richAlignCenter => 'Center';

  @override
  String get richAlignEnd => 'Align to end';

  @override
  String get richClearFormatting => 'Clear formatting';

  @override
  String get richWritingStyle => 'Writing style';

  @override
  String get richStyleClassic => 'Classic';

  @override
  String get richStyleClassicHint => 'Elegant serif, like a printed page';

  @override
  String get richStyleModern => 'Modern';

  @override
  String get richStyleModernHint => 'Clean and easy to read';

  @override
  String get richStyleJournal => 'Journal';

  @override
  String get richStyleJournalHint => 'Warm italic, like a diary entry';

  @override
  String get richStyleTypewriter => 'Typewriter';

  @override
  String get richStyleTypewriterHint => 'Squared letters with extra spacing';

  @override
  String get richStylePoetic => 'Poetic';

  @override
  String get richStylePoeticHint => 'Centered lines with room to breathe';

  @override
  String richWordCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count words',
      one: '1 word',
    );
    return '$_temp0';
  }

  @override
  String get richAlignmentNote =>
      'Alignment and spacing show in Preview and for readers.';

  @override
  String get richLinkTitle => 'Add a link';

  @override
  String get richLinkField => 'Web address';

  @override
  String get richLinkInvalid => 'Use a complete https:// address.';

  @override
  String get richLinkApply => 'Add link';

  @override
  String get richLinkRemove => 'Remove link';

  @override
  String get richLinkNeedsSelection =>
      'Select the words you want to link first.';

  @override
  String get richCancel => 'Cancel';

  @override
  String get richOpenLinkTitle => 'Open this link?';

  @override
  String richOpenLinkBody(String host) {
    return '$host opens outside Connect. Only open links you trust.';
  }

  @override
  String get richOpenLink => 'Open link';

  @override
  String get supportCentreEyebrow => 'HELP & SUPPORT';

  @override
  String get supportCentreTitle => 'How can we help?';

  @override
  String get supportCentreSubtitle =>
      'Find a quick answer, or ask our team. Every request and reply stays in one private conversation.';

  @override
  String get supportContactSection => 'CONTACT US';

  @override
  String get supportContactTitle => 'Contact support';

  @override
  String get supportContactSubtitle =>
      'Tell us what happened. We reply here and let you know.';

  @override
  String get supportMyTicketsTitle => 'My tickets';

  @override
  String get supportMyTicketsSubtitle => 'Follow your requests and our replies';

  @override
  String supportOpenRequests(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count open requests',
      one: '1 open request',
    );
    return '$_temp0';
  }

  @override
  String supportUnreadReplies(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count new replies',
      one: '1 new reply',
    );
    return '$_temp0';
  }

  @override
  String get supportQuickAnswersSection => 'QUICK ANSWERS';

  @override
  String get supportFaqLoginTitle => 'Login';

  @override
  String get supportFaqLoginBody =>
      'Sign in with your unique username and password.';

  @override
  String get supportFaqVerificationTitle => 'Verification';

  @override
  String get supportFaqVerificationBody =>
      'Identity verification is optional while the provider is paused.';

  @override
  String get supportFaqAbuseTitle => 'Abuse';

  @override
  String get supportFaqAbuseBody =>
      'Use Report on a profile or conversation for faster safety triage.';

  @override
  String get supportFaqBillingTitle => 'Billing';

  @override
  String get supportFaqBillingBody =>
      'Include the transaction reference, never your card details.';

  @override
  String get supportEmergencyNote =>
      'If someone is in immediate danger, contact local emergency services. Support tickets do not replace emergency help.';

  @override
  String get supportUnavailableTitle =>
      'Support requests are not available right now';

  @override
  String get supportUnavailableBody =>
      'The answers on this page still work. For anything urgent, email support@connect.example.';

  @override
  String get supportBackToHelp => 'Back to Help & Support';

  @override
  String get supportFormEyebrow => 'NEW REQUEST';

  @override
  String get supportFormTitle => 'Contact support';

  @override
  String get supportFormSubtitle =>
      'Give us enough detail to act. Never include a password, recovery code, card number or identity document.';

  @override
  String get supportFormCategorySection => 'TOPIC';

  @override
  String get supportFormCategoryLabel => 'What do you need help with?';

  @override
  String get supportCategoryAccountLogin => 'Account & login';

  @override
  String get supportCategoryVerification => 'Verification';

  @override
  String get supportCategoryPaymentsBilling => 'Payments & billing';

  @override
  String get supportCategorySafetyHarassment => 'Safety & harassment';

  @override
  String get supportCategoryMatchesChat => 'Matches & chat';

  @override
  String get supportCategoryTechnical => 'Technical problem or bug';

  @override
  String get supportCategoryFeatureRequest => 'Feature request';

  @override
  String get supportCategoryPrivacyData => 'Privacy & data request';

  @override
  String get supportCategoryOther => 'Other';

  @override
  String get supportSafetyNote =>
      'If you or someone else is in immediate danger, use SOS in the app or call your local emergency services. Safety requests are prioritized, but a ticket is not an emergency line.';

  @override
  String get supportOpenSos => 'Open SOS';

  @override
  String get supportFormDetailsSection => 'DETAILS';

  @override
  String get supportFormSubjectLabel => 'Subject';

  @override
  String get supportFormSubjectHint => 'Briefly describe the issue';

  @override
  String get supportFormDescriptionLabel => 'What happened?';

  @override
  String get supportFormDescriptionHint =>
      'What you did, what you expected and what happened instead';

  @override
  String get supportFormScreenshotsSection => 'SCREENSHOTS';

  @override
  String supportFormScreenshotsCaption(int max) {
    return 'Optional. Up to $max images.';
  }

  @override
  String get supportAddScreenshot => 'Add screenshot';

  @override
  String supportRemoveAttachment(String name) {
    return 'Remove $name';
  }

  @override
  String get supportAttachmentUploading => 'Uploading';

  @override
  String get supportRetryUpload => 'Retry upload';

  @override
  String supportFormDeviceNote(String version) {
    return 'We’ll include your app version ($version), platform, system version and language to help us troubleshoot.';
  }

  @override
  String get supportSubmit => 'Send request';

  @override
  String get supportErrorCategoryRequired => 'Choose a topic.';

  @override
  String supportErrorSubjectLength(int min, int max) {
    return 'Use $min to $max characters for the subject.';
  }

  @override
  String get supportErrorDescriptionRequired => 'Describe what happened.';

  @override
  String supportErrorDescriptionTooLong(int max) {
    return 'Keep it under $max characters.';
  }

  @override
  String get supportErrorUploadsPending =>
      'Wait for your screenshots to finish uploading, or remove any that failed.';

  @override
  String supportCreatedSnack(String reference) {
    return 'Request $reference sent. We’ll reply here.';
  }

  @override
  String supportDuplicateSnack(String reference) {
    return 'You already sent this request, so we opened it: $reference.';
  }

  @override
  String supportErrorRateLimited(int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other:
          'You’ve sent several requests in a short time. Try again in $minutes minutes.',
      one:
          'You’ve sent several requests in a short time. Try again in 1 minute.',
    );
    return '$_temp0';
  }

  @override
  String get supportErrorRateLimitedGeneric =>
      'You’ve sent several requests in a short time. Please try again later.';

  @override
  String get supportErrorTooManyOpen =>
      'You already have 10 open requests. Close one you no longer need, or wait for our replies.';

  @override
  String get supportErrorTicketClosed =>
      'This request is closed and can no longer be reopened. Please start a new request.';

  @override
  String get supportErrorReopenWindowPassed =>
      'The time to reopen this request has passed. Please start a new request.';

  @override
  String get supportErrorAlreadyRated => 'You’ve already rated this request.';

  @override
  String get supportErrorNotResolved =>
      'You can rate a request once it’s resolved.';

  @override
  String get supportErrorAttachmentType =>
      'Only JPEG or PNG images and PDF files can be attached.';

  @override
  String get supportErrorAttachmentTooLarge =>
      'That file is too large. Images can be up to 8 MB.';

  @override
  String get supportErrorOffline =>
      'Can’t reach Connect right now. Check your connection and try again.';

  @override
  String get supportErrorNotFound => 'We couldn’t find this request.';

  @override
  String get supportErrorGeneric => 'Something went wrong. Please try again.';

  @override
  String get supportTryAgain => 'Try again';

  @override
  String get supportTicketsEyebrow => 'SUPPORT';

  @override
  String get supportTicketsTitle => 'My tickets';

  @override
  String get supportTicketsSubtitle => 'Your requests and our replies.';

  @override
  String get supportTicketsActiveSection => 'ACTIVE';

  @override
  String get supportTicketsClosedSection => 'RESOLVED & CLOSED';

  @override
  String get supportTicketsEmptyTitle => 'No requests yet';

  @override
  String get supportTicketsEmptyBody =>
      'When you contact support, your request and our replies appear here.';

  @override
  String get supportTicketsLoadErrorTitle => 'Your requests couldn’t load';

  @override
  String supportTicketUpdated(String when) {
    return 'Updated $when';
  }

  @override
  String get supportNewTicket => 'New request';

  @override
  String get supportStatusOpen => 'Open';

  @override
  String get supportStatusWaitingForYou => 'Waiting for you';

  @override
  String get supportStatusOnHold => 'On hold';

  @override
  String get supportStatusResolved => 'Resolved';

  @override
  String get supportStatusClosed => 'Closed';

  @override
  String supportStatusSemantics(String status) {
    return 'Status: $status';
  }

  @override
  String get supportThreadAgentName => 'Connect Support';

  @override
  String get supportThreadYou => 'You';

  @override
  String supportTicketMeta(String category, String date) {
    return '$category · Opened $date';
  }

  @override
  String get supportBannerOpen =>
      'We have your request. Our team will reply here and let you know.';

  @override
  String get supportBannerWaiting =>
      'Support replied and is waiting for your answer.';

  @override
  String get supportBannerOnHold =>
      'Your request is paused while we look into it. We’ll update you here.';

  @override
  String get supportBannerResolved =>
      'Marked as resolved. Reply to reopen it; otherwise it closes automatically after 7 days.';

  @override
  String supportBannerClosedUntil(String date) {
    return 'This request is closed. You can reopen it until $date.';
  }

  @override
  String get supportBannerClosed => 'This request is closed.';

  @override
  String supportBannerMerged(String reference) {
    return 'This request was merged into $reference. The conversation continues there.';
  }

  @override
  String get supportReplyHint => 'Write a reply';

  @override
  String get supportReplyDisabledHint => 'Replies are closed for this request';

  @override
  String get supportSendReply => 'Send reply';

  @override
  String get supportAttachScreenshot => 'Attach screenshot';

  @override
  String get supportCloseTicket => 'Close request';

  @override
  String get supportCloseConfirmTitle => 'Close this request?';

  @override
  String get supportCloseConfirmBody =>
      'Close it if your problem is solved. You can reopen it for 14 days.';

  @override
  String get supportCancel => 'Cancel';

  @override
  String get supportClosedSnack => 'Request closed.';

  @override
  String get supportReopen => 'Reopen request';

  @override
  String get supportReopenedSnack => 'Request reopened.';

  @override
  String get supportRateTitle => 'How did we do?';

  @override
  String get supportRateCaption => 'Rate your experience with this request.';

  @override
  String supportRateStar(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count stars',
      one: '1 star',
    );
    return '$_temp0';
  }

  @override
  String get supportRateCommentLabel => 'Anything to add? (optional)';

  @override
  String get supportRateSubmit => 'Send rating';

  @override
  String get supportRatedTitle => 'Thanks for your feedback';

  @override
  String supportRatedValue(int rating) {
    return 'You rated this $rating out of 5.';
  }

  @override
  String get supportRatingSnack => 'Thanks for rating your experience.';

  @override
  String supportAttachmentImage(String name) {
    return 'Screenshot $name';
  }

  @override
  String get supportAttachmentLoadFailed => 'Couldn’t load attachment';

  @override
  String get supportThreadLoadErrorTitle => 'This request couldn’t load';

  @override
  String get chemistryCardEntry => 'A little chemistry?';

  @override
  String get memberProfileIntroducing => 'Introducing';

  @override
  String get memberProfileStarring => 'Starring';

  @override
  String get memberProfileVerified => 'Verified';

  @override
  String memberProfilePhotoLabel(String name, int index, int count) {
    return '$name, photo $index of $count';
  }

  @override
  String get memberProfileNoPhoto => 'No photo yet';

  @override
  String get memberProfileViewPhotoHint => 'view full screen';

  @override
  String get memberProfileCloseGallery => 'Close photos';

  @override
  String get memberProfilePhotos => 'Photos';

  @override
  String memberProfileMorePhotos(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count more photos',
      one: '1 more photo',
    );
    return '$_temp0';
  }

  @override
  String get memberProfileSceneAbout => 'About';

  @override
  String get memberProfileSceneStories => 'Stories';

  @override
  String get memberProfileSceneStoriesTitle => 'A little more me';

  @override
  String get memberProfileSceneInterests => 'Interests';

  @override
  String get memberProfileSceneBasics => 'The basics';

  @override
  String get memberProfileSceneLifestyle => 'Lifestyle';

  @override
  String get memberProfileSceneTrust => 'Trust';

  @override
  String get memberProfileReadMore => 'Read more';

  @override
  String get memberProfileReadLess => 'Read less';

  @override
  String get memberProfileHobbies => 'Hobbies';

  @override
  String get memberProfileActivities => 'Activities';

  @override
  String get memberProfileSongs => 'On repeat';

  @override
  String get memberProfileBooks => 'Books & novels';

  @override
  String get memberProfileLookingFor => 'Looking for';

  @override
  String get memberProfileLanguages => 'Languages';

  @override
  String get memberProfileDealBreakers => 'Deal breakers';

  @override
  String get memberProfileInCommon => 'In common';

  @override
  String get memberProfileFactHeight => 'Height';

  @override
  String memberProfileHeightCm(int cm) {
    return '$cm cm';
  }

  @override
  String get memberProfileFactWork => 'Work';

  @override
  String get memberProfileFactEducation => 'Education';

  @override
  String get memberProfileFactLivesIn => 'Lives in';

  @override
  String get memberProfileFactMotherTongue => 'Mother tongue';

  @override
  String get memberProfileFactReligion => 'Religion';

  @override
  String get memberProfileFactPersonality => 'Personality';

  @override
  String get memberProfileFactRelationship => 'Relationship';

  @override
  String get memberProfileFactInstagram => 'Instagram';

  @override
  String get memberProfileFactDrinking => 'Drinking';

  @override
  String get memberProfileFactSmoking => 'Smoking';

  @override
  String get memberProfileFactWorkout => 'Workout';

  @override
  String get memberProfileFactDiet => 'Diet';

  @override
  String get memberProfileFactDietType => 'Diet type';

  @override
  String get memberProfileFactSleep => 'Sleep';

  @override
  String get memberProfileFactTravel => 'Travel';

  @override
  String get memberProfileFactPets => 'Pets';

  @override
  String get memberProfileFactPolitics => 'Politics';

  @override
  String get memberProfileFactOpenToCasual => 'Open to casual';

  @override
  String get memberProfileFactPartyLover => 'Loves a party';

  @override
  String get memberProfileVerifiedTitle => 'Verified profile';

  @override
  String get memberProfileVerifiedBody => 'Identity verification completed.';

  @override
  String get memberProfileVouchesTitle => 'Vouched for by friends';

  @override
  String get memberProfileSpotlight => 'Spotlight';

  @override
  String get memberProfileFreeWhenYouAre => 'Free when you are';

  @override
  String get memberProfileMessage => 'Message';

  @override
  String get memberProfileLove => 'Love';

  @override
  String get memberProfileReport => 'Report';

  @override
  String get memberProfileOwnerTitle => 'This is how you appear';

  @override
  String get memberProfileOwnerCaption =>
      'Members see your profile just like this.';

  @override
  String memberProfileCompleteness(int percent) {
    return 'Profile $percent% complete';
  }

  @override
  String get memberProfileCompletenessHint =>
      'Add photos, stories and details to stand out.';

  @override
  String get memberProfileCompletenessDone => 'Your profile is complete.';

  @override
  String get memberProfileToolEdit => 'Edit profile';

  @override
  String get memberProfileToolPhotos => 'Edit photos';

  @override
  String get memberProfileToolStories => 'Your stories';

  @override
  String get memberProfileToolViewers => 'Who viewed you';

  @override
  String get memberProfileBehindTheScenes => 'Behind the scenes';

  @override
  String get memberProfileOnlyYou => 'Only you can see this.';

  @override
  String get memberProfileMine => 'My profile';

  @override
  String get profileShowcaseLabel => 'Writing & moments';

  @override
  String get profileShowcaseTitleOther => 'In their own words';

  @override
  String get profileShowcaseTitleSelf => 'Your public writing & photos';

  @override
  String get profileShowcaseChapters => 'Chapters';

  @override
  String get profileShowcasePhotos => 'Wall photos';

  @override
  String get profileShowcaseReadAll => 'Read all their chapters';

  @override
  String get profileShowcaseHiddenTitle => 'Only you can see this';

  @override
  String get profileShowcaseHiddenBody =>
      'Your public chapters and wall photos are hidden from your profile. Turn this on to let members see them here.';

  @override
  String get profileShowcaseShownBody =>
      'Members can see these on your profile. Only chapters shared with the community and photos on the wall appear.';

  @override
  String get profileShowcaseSwitch => 'Show on my profile';

  @override
  String get profileShowcaseSaveFailed => 'Your choice could not be saved.';
}

/// The translations for English, as used in the United Kingdom (`en_GB`).
class AppLocalizationsEnGb extends AppLocalizationsEn {
  AppLocalizationsEnGb() : super('en_GB');

  @override
  String get navDiscover => 'Discover';

  @override
  String get navMatches => 'Matches';

  @override
  String get navEngage => 'Engage';

  @override
  String get navProfile => 'Profile';

  @override
  String get navSettings => 'Settings';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsSectionProfile => 'Profile';

  @override
  String get settingsEditProfileTitle => 'Edit Profile';

  @override
  String get settingsEditProfileSubtitle => 'Update your information';

  @override
  String get settingsPhotosTitle => 'Photos';

  @override
  String get settingsPhotosSubtitle => 'Manage your photos';

  @override
  String get settingsSectionPreferences => 'Preferences';

  @override
  String get settingsAppearanceTitle => 'Appearance';

  @override
  String get settingsAppearanceSubtitle => 'Saved to your account';

  @override
  String get settingsThemeLight => 'Light';

  @override
  String get settingsThemeDark => 'Dark';

  @override
  String get settingsThemeMatchDevice => 'Match device';

  @override
  String get settingsLooksTitle => 'Looks';

  @override
  String get settingsLooksClassicDescription =>
      'Warm ivory and forest by day. Soft mint and deep forest by night.';

  @override
  String get settingsLooksClassicLabel => 'Today';

  @override
  String get settingsThemeSaveFailed =>
      'Could not save your theme. Please try again.';

  @override
  String get settingsLanguageTitle => 'Language';

  @override
  String get settingsLanguageSubtitle => 'Choose the app language';

  @override
  String get settingsDatingPreferencesTitle => 'Dating Preferences';

  @override
  String get settingsDatingPreferencesSubtitle => 'Age, location, interests';

  @override
  String get settingsAccountDataTitle => 'Account & Data';

  @override
  String get settingsAccountDataSubtitle =>
      'Hide, download or delete your account';

  @override
  String get settingsNotificationsTitle => 'Notifications';

  @override
  String get settingsNotificationsSubtitle => 'Push & email notifications';

  @override
  String get settingsSectionEngagement => 'Engagement';

  @override
  String get settingsTrustBadgesTitle => 'Trust Badges';

  @override
  String get settingsTrustBadgesSubtitle =>
      'See earned badges and trust history';

  @override
  String get settingsTrustFiltersTitle => 'Trust Filters';

  @override
  String get settingsTrustFiltersSubtitle =>
      'Control trust requirements for discovery';

  @override
  String get settingsConversationRoomsTitle => 'Conversation Rooms';

  @override
  String get settingsConversationRoomsSubtitle =>
      'Browse, join, leave, and moderate rooms';

  @override
  String get settingsFriendsTitle => 'Friends & Connections';

  @override
  String get settingsFriendsSubtitle => 'Build and maintain friend connections';

  @override
  String get settingsCallHistoryTitle => 'Call History';

  @override
  String get settingsCallHistorySubtitle => 'Review durable call sessions';

  @override
  String get settingsMatchNudgesTitle => 'Match Nudges';

  @override
  String get settingsMatchNudgesSubtitle => 'Restart quiet conversations';

  @override
  String get settingsSubscriptionsTitle => 'Subscriptions';

  @override
  String get settingsSubscriptionsSubtitle =>
      'Plans, entitlement status, and payments';

  @override
  String get settingsSectionApp => 'App';

  @override
  String get settingsPrivacySafetyTitle => 'Privacy & Safety';

  @override
  String get settingsPrivacySafetySubtitle => 'Manage your privacy settings';

  @override
  String get settingsGovernmentVerificationTitle => 'Government Verification';

  @override
  String get settingsGovernmentVerificationSubtitle =>
      'View identity verification status';

  @override
  String get settingsQaVerificationUploadTitle => 'QA Verification Upload';

  @override
  String get settingsQaVerificationUploadSubtitle =>
      'Automation-only ID and selfie flow';

  @override
  String get settingsHelpSupportTitle => 'Help & Support';

  @override
  String get settingsHelpSupportSubtitle => 'FAQ and contact support';

  @override
  String get settingsAboutTitle => 'About';

  @override
  String get settingsAboutSubtitle => 'App details and stack';

  @override
  String get settingsLogout => 'Logout';

  @override
  String get languageTitle => 'Language';

  @override
  String get languageIntro =>
      'Pick the language Connect uses. Your choice is saved to your account and applies on every device you sign in on.';

  @override
  String get languageUseDevice => 'Use device language';

  @override
  String get languageUseDeviceSubtitle =>
      'Follows your phone\'s language setting';

  @override
  String get languageSaveFailed =>
      'Could not save your language. Please try again.';

  @override
  String get notificationsTitle => 'Notifications';

  @override
  String get notificationsInboxTitle => 'Notification inbox';

  @override
  String get notificationsInboxCaughtUp => 'You are all caught up';

  @override
  String notificationsInboxUnread(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count unread',
      one: '1 unread',
    );
    return '$_temp0';
  }

  @override
  String get notificationsInAppTitle => 'In-app notifications';

  @override
  String get notificationsInAppSubtitle =>
      'Show notifications while using the app';

  @override
  String get notificationsPushTitle => 'Push notifications';

  @override
  String get notificationsPushSubtitle =>
      'Allow delivery when the app is in background';

  @override
  String get notificationsNewMatchesTitle => 'New matches';

  @override
  String get notificationsNewMatchesSubtitle => 'Get notified when you match';

  @override
  String get notificationsNewMessagesTitle => 'New messages';

  @override
  String get notificationsNewMessagesSubtitle =>
      'Get notified for chat messages';

  @override
  String get notificationsLikesTitle => 'Likes';

  @override
  String get notificationsLikesSubtitle =>
      'Get notified when someone likes you';

  @override
  String get notificationsMatchNudgesTitle => 'Match nudges';

  @override
  String get notificationsMatchNudgesSubtitle =>
      'Get notified when a match nudges you';

  @override
  String get notificationsIncomingCallsTitle => 'Incoming calls';

  @override
  String get notificationsIncomingCallsSubtitle => 'Show incoming call alerts';

  @override
  String get notificationsSafetyTitle => 'Safety updates';

  @override
  String get notificationsSafetySubtitle =>
      'Receive important safety status updates';

  @override
  String get notificationsFriendPlansTitle => 'Friends\' date plans';

  @override
  String get notificationsFriendPlansSubtitle =>
      'Know when a friend plans a date or checks in';

  @override
  String get welcomeTagline => 'Made for real life.';

  @override
  String get welcomePhotoNote => 'Offline is the goal.';

  @override
  String get welcomeHeadlineLead => 'A good story\nstarts with ';

  @override
  String get welcomeHeadlineAccent => 'hello.';

  @override
  String get welcomeBody =>
      'Find someone who feels like your kind of person. Take it from there.';

  @override
  String get welcomeCreateAccount => 'Create account';

  @override
  String get welcomeAlreadyMember => 'Already a member? ';

  @override
  String get welcomeSignIn => 'Sign in';

  @override
  String get welcomeFooter => '18+  ·  Your pace. Your choice.';

  @override
  String get authBackTooltip => 'Back to welcome';

  @override
  String get authHeadline => 'Good to see you.';

  @override
  String get authSubtitle => 'Use your username and password to continue';

  @override
  String get authWelcomeBack => 'Welcome back';

  @override
  String get authNextHello => 'Your next hello is waiting.';

  @override
  String get authUsernameHint => 'username';

  @override
  String get authPasswordHint => 'Password';

  @override
  String get authShowPassword => 'Show password';

  @override
  String get authHidePassword => 'Hide password';

  @override
  String get authCantSignIn => 'Can\'t sign in?';

  @override
  String get authSignIn => 'Sign in';

  @override
  String get authPrivacyNote =>
      'Your password is sent only when you sign in and is never stored in the app.';

  @override
  String get authEnterUsername => 'Please enter your username.';

  @override
  String get authEnterPassword => 'Please enter your password.';

  @override
  String get commonYes => 'Yes';

  @override
  String get commonNo => 'No';

  @override
  String get planVenueCoffee => 'Coffee';

  @override
  String get planVenueMeal => 'A meal';

  @override
  String get planVenueDrinks => 'Drinks';

  @override
  String get planVenueWalk => 'A walk';

  @override
  String get planVenueActivity => 'An activity';

  @override
  String get planVenueEvent => 'An event';

  @override
  String get planVenueVideoCall => 'Video call';

  @override
  String get planVenueOther => 'Something else';

  @override
  String planProposeTitle(String name) {
    return 'Plan a date with $name';
  }

  @override
  String get planProposeSubtitle =>
      'Shape a first hello together. Contact sharing starts off.';

  @override
  String get planProposeButton => 'Propose';

  @override
  String planHeadlineProposed(String name) {
    return '$name proposed a date';
  }

  @override
  String planHeadlineWaiting(String name) {
    return 'Waiting for $name';
  }

  @override
  String get planHeadlineUpcoming => 'It is a plan';

  @override
  String get planHeadlineCheckin => 'How did it go?';

  @override
  String get planHeadlineDebrief => 'How was it?';

  @override
  String get planHeadlineDebriefComplete => 'Debrief complete';

  @override
  String planHeadlineWaitingDebrief(String name) {
    return 'Waiting for $name\'s debrief';
  }

  @override
  String get planHeadlineCheckedInSafe => 'You checked in safe';

  @override
  String get planHeadlineFriendsAlerted => 'Your request for help is recorded';

  @override
  String get planHeadlineDefault => 'Plan';

  @override
  String get planStatusProposed => 'Proposed';

  @override
  String get planStatusConfirmed => 'Confirmed';

  @override
  String get planDebriefButton => 'Ten-second debrief';

  @override
  String get planDecline => 'Decline';

  @override
  String get planAccept => 'Accept';

  @override
  String get planFriendsKnowAccepted =>
      'Choose trusted contacts to share your updates.';

  @override
  String get planFriendsKnowProposed =>
      'Contact sharing is optional for each plan.';

  @override
  String get planCancel => 'Cancel plan';

  @override
  String get planNeedHelp => 'I need help';

  @override
  String get planImSafe => 'I\'m safe';

  @override
  String get planCancelDialogTitle => 'Cancel this plan?';

  @override
  String planCancelDialogBody(String name) {
    return '$name and everyone you shared it with will be told.';
  }

  @override
  String get planKeepIt => 'Keep it';

  @override
  String get planProposeIntro =>
      'This starts between you and your date. After proposing, choose trusted contacts if you want to share plan and check-in updates.';

  @override
  String get planSectionWhen => 'When';

  @override
  String get planSectionWhat => 'What';

  @override
  String get planSectionGroups => 'Trusted contacts';

  @override
  String planDurationHours(int hours) {
    return '$hours h';
  }

  @override
  String get planPlaceLabel => 'Place (optional)';

  @override
  String get planPlaceHint => 'A public place works best';

  @override
  String get planAreaLabel => 'Area or neighbourhood';

  @override
  String get planNoteLabel => 'Note for them (optional)';

  @override
  String get planFutureTimeError => 'Pick a time in the future.';

  @override
  String get planProposeFailed => 'Unable to propose this plan.';

  @override
  String get planSendButton => 'Send the plan';

  @override
  String get planAcceptTitle => 'Accept the plan?';

  @override
  String get planAcceptIntro =>
      'Accept this plan with your date. Choose trusted contacts afterwards if you want to share your updates.';

  @override
  String get planAcceptButton => 'Accept plan';

  @override
  String debriefTitle(String name) {
    return 'How was it with $name?';
  }

  @override
  String get debriefIntro =>
      'Your answers are private. When you both confirm the date happened, it counts towards your Shows Up badge.';

  @override
  String get debriefHappened => 'Did the date happen?';

  @override
  String get debriefMeetAgain => 'Would you meet again?';

  @override
  String get debriefFeltSafe => 'Did you feel safe?';

  @override
  String get debriefNoteLabel => 'Anything to add? (optional)';

  @override
  String get debriefMissingHappened => 'Tell us whether the date happened.';

  @override
  String get debriefSaveFailed => 'Unable to save your debrief.';

  @override
  String get debriefSave => 'Save debrief';

  @override
  String get debriefUnsafeTitle => 'Sorry that did not feel safe';

  @override
  String debriefUnsafeBody(String name) {
    return 'Your answer is noted for our safety team. Do you also want to report $name?';
  }

  @override
  String get debriefNotNow => 'Not now';

  @override
  String get debriefReport => 'Report';

  @override
  String get plansTitle => 'Date plans';

  @override
  String get plansTabMine => 'Mine';

  @override
  String get plansTabFriends => 'Friends';

  @override
  String get plansEmptyMineTitle => 'No plans yet';

  @override
  String get plansEmptyMineBody =>
      'Propose a date from a conversation. You choose whether to share plan and check-in updates with trusted contacts.';

  @override
  String plansWith(String name) {
    return 'With $name';
  }

  @override
  String get plansNextDecide => 'Waiting for your answer';

  @override
  String plansNextAwait(String name) {
    return 'Waiting for $name';
  }

  @override
  String get plansNextUpcoming => 'Confirmed. Your time together is planned.';

  @override
  String get plansNextCheckin => 'Check in after your date';

  @override
  String get plansNextDebrief => 'Tell us how it went';

  @override
  String get plansNextCancelled => 'Cancelled';

  @override
  String get plansNextDone => 'Done';

  @override
  String get plansEmptyFriendsTitle => 'Nothing shared yet';

  @override
  String get plansEmptyFriendsBody =>
      'Plans appear here when friends explicitly choose to share with you.';

  @override
  String get plansViaGroup => 'Shared with you';

  @override
  String get plansViaFriend => 'Trusted contact';

  @override
  String plansFriendNeedsHelp(String name) {
    return '$name asked for help. Reach out now.';
  }

  @override
  String plansFriendMissedCheckin(String name) {
    return '$name has not checked in yet.';
  }

  @override
  String plansFriendCheckedInSafe(String name, String via) {
    return '$name checked in safe · $via';
  }

  @override
  String plansFriendStatusLine(String via, String status) {
    return '$via · $status';
  }

  @override
  String get plansStatusWordProposed => 'proposed';

  @override
  String get plansStatusWordConfirmed => 'confirmed';

  @override
  String get plansStatusWordCancelled => 'cancelled';

  @override
  String get plansStatusWordHappened => 'happened';

  @override
  String get chatEmptyDefault =>
      'Say hello. Messages appear here for everyone in this conversation.';

  @override
  String get chatNotSentRetry => 'Not sent. Tap the message to retry.';

  @override
  String get chatRetrySend => 'Try sending again';

  @override
  String get chatCopyText => 'Copy text';

  @override
  String get chatDeleteMine => 'Delete my message';

  @override
  String get chatRemoveMessage => 'Remove message';

  @override
  String get chatReportMessage => 'Report message';

  @override
  String get chatThisMember => 'This member';

  @override
  String get chatMember => 'Member';

  @override
  String get chatCopied => 'Copied.';

  @override
  String get chatDeleteFailed => 'Could not delete. Please retry.';

  @override
  String get chatSubtitleFriends => 'Friends';

  @override
  String chatMemberCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count members',
      one: '1 member',
    );
    return '$_temp0';
  }

  @override
  String get chatReconnecting =>
      'Reconnecting. New messages may take a moment.';

  @override
  String get chatUnavailable =>
      'This conversation is unavailable. You may no longer be a member.';

  @override
  String get chatTryAgain => 'Try again';

  @override
  String get chatStatusNotSent => 'Not sent · tap and hold to retry';

  @override
  String get chatStatusSending => 'Sending…';

  @override
  String get chatMessageRemoved => 'Message removed';

  @override
  String chatSemanticsYouAt(String time) {
    return 'You at $time';
  }

  @override
  String chatSemanticsMemberAt(String name, String time) {
    return '$name at $time';
  }

  @override
  String chatAboutMember(String name) {
    return 'About $name';
  }

  @override
  String get chatComposerHint => 'Write a message';

  @override
  String get chatMutedComposerHint => 'You can’t post right now';

  @override
  String get chatSend => 'Send';

  @override
  String chatRoomMutedUntil(String when) {
    return 'You’re muted in this room until $when. You can still read along.';
  }

  @override
  String get chatRoomMuted =>
      'You’re muted in this room. You can still read along.';

  @override
  String chatReadOnlyUntil(String when) {
    return 'You can read this conversation but can’t post until $when.';
  }

  @override
  String get chatReadOnly =>
      'You can read this conversation but can’t post right now.';

  @override
  String get chatMuteTooltip => 'Mute notifications';

  @override
  String get chatMutedTooltip => 'Notifications muted';

  @override
  String get chatMuteSheetTitle => 'Mute notifications';

  @override
  String get chatMuteSheetBody =>
      'Messages still arrive here, just without notifications.';

  @override
  String get chatMuteOneHour => 'For 1 hour';

  @override
  String get chatMuteEightHours => 'For 8 hours';

  @override
  String get chatMuteOneWeek => 'For 1 week';

  @override
  String get chatMuteForever => 'Until I turn it back on';

  @override
  String get chatUnmute => 'Turn notifications back on';

  @override
  String chatMutedUntilLabel(String when) {
    return 'Muted until $when';
  }

  @override
  String get chatMutedIndefinitely =>
      'Muted until you turn notifications back on.';

  @override
  String get chatMuteDone => 'Notifications muted.';

  @override
  String get chatUnmuteDone => 'Notifications are back on.';

  @override
  String get chatMuteFailed => 'Could not change notifications. Please retry.';

  @override
  String get roomsClosedSnack => 'This room has closed.';

  @override
  String get roomsChatNotOpen => 'This room’s chat isn’t open yet.';

  @override
  String get roomsJoinFailed => 'Could not join this room. Please retry.';

  @override
  String get roomsStartRoom => 'Start a room';

  @override
  String get roomsEyebrow => 'LIVE CHAT';

  @override
  String get roomsTitle => 'Rooms';

  @override
  String get roomsSubtitle =>
      'Drop into a conversation. If you click with someone, add them as a friend.';

  @override
  String get roomsSectionRooms => 'ROOMS';

  @override
  String get roomsSectionYours => 'YOUR ROOMS';

  @override
  String get roomsYoursCaption => 'Rooms you’re in. Tap to pick up the chat.';

  @override
  String get roomsSectionLive => 'LIVE NOW';

  @override
  String get roomsLiveTitle => 'Where people are talking';

  @override
  String get roomsSectionBrowse => 'BROWSE';

  @override
  String get roomsBrowseTitle => 'Find your room';

  @override
  String get roomsBrowseCaption =>
      'Always open. Pick a topic, say hi, and see who you click with.';

  @override
  String get roomsNoFriendsHere =>
      'None of your friends are in a room here right now.';

  @override
  String get roomsNoRoomsInTopic => 'No rooms in this topic yet.';

  @override
  String get roomsSectionComingUp => 'COMING UP';

  @override
  String get roomsComingUpCaption =>
      'Rooms members are hosting. Join early to save a spot.';

  @override
  String get roomsCategoryAll => 'All';

  @override
  String get roomsCategoryTalk => 'Talk';

  @override
  String get roomsCategoryInterests => 'Interests';

  @override
  String get roomsCategoryActive => 'Out & about';

  @override
  String get roomsCategoryCity => 'Your city';

  @override
  String get roomsFriendsHereChip => 'Friends here';

  @override
  String get roomsQuiet => 'Quiet right now. Be the first to say hello.';

  @override
  String roomsPeopleCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count people',
      one: '1 person',
    );
    return '$_temp0';
  }

  @override
  String roomsRoomCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count rooms',
      one: '1 room',
    );
    return '$_temp0';
  }

  @override
  String roomsChattingIn(String people, String rooms) {
    return '$people chatting in $rooms';
  }

  @override
  String roomsHereNow(int count) {
    return '$count here now';
  }

  @override
  String roomsInTheRoom(int count) {
    return '$count in the room';
  }

  @override
  String roomsFriendsHere(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count friends here',
      one: '1 friend here',
    );
    return '$_temp0';
  }

  @override
  String get roomsHostedByYou => 'Hosted by you';

  @override
  String roomsHostedBy(String name) {
    return 'Hosted by $name';
  }

  @override
  String get roomsActionOpen => 'Open';

  @override
  String get roomsActionFull => 'Full';

  @override
  String get roomsActionJoin => 'Join';

  @override
  String roomsStartsAt(String time) {
    return 'Starts $time';
  }

  @override
  String roomsStartsOn(String day, String time) {
    return 'Starts $day $time';
  }

  @override
  String get roomsStartNameTooShort =>
      'Give the room a name of at least 3 letters.';

  @override
  String get roomsStartIntro =>
      'You host it: you can warn, mute or remove people, and close it when you’re done. One room at a time.';

  @override
  String get roomsStartNameLabel => 'Room name';

  @override
  String get roomsStartNameHint => 'Sunday book swap';

  @override
  String get roomsStartAboutLabel => 'What’s it about? (optional)';

  @override
  String get roomsStartTopic => 'Topic';

  @override
  String get roomsStartHowLong => 'How long';

  @override
  String get roomsLength30Min => '30 min';

  @override
  String get roomsLength1Hour => '1 hour';

  @override
  String get roomsLength2Hours => '2 hours';

  @override
  String get roomsStartNow => 'Start now';

  @override
  String get roomsRoleHost => 'Host';

  @override
  String get roomsRoleModerator => 'Moderator';

  @override
  String get roomsRoomFallback => 'Room';

  @override
  String roomsChatEmpty(String room) {
    return 'You’re in. Say hello: everyone in $room sees what you write here.';
  }

  @override
  String get roomsPeopleTooltip => 'People in this room';

  @override
  String roomsLeaveTitle(String room) {
    return 'Leave $room?';
  }

  @override
  String get roomsLeaveBody =>
      'You’ll stop seeing this room’s messages. You can come back any time it’s open.';

  @override
  String get roomsLeaveAction => 'Leave room';

  @override
  String get roomsLeaveFailed => 'Could not leave. Please retry.';

  @override
  String roomsCloseTitle(String room) {
    return 'Close $room?';
  }

  @override
  String get roomsCloseBody =>
      'The chat ends for everyone in the room. This can’t be undone.';

  @override
  String get roomsCloseAction => 'Close room';

  @override
  String get roomsCloseFailed => 'Could not close. Please retry.';

  @override
  String get roomsMenuTooltip => 'Room options';

  @override
  String get roomsMenuPeople => 'People here';

  @override
  String get roomsMenuModerate => 'Moderate';

  @override
  String roomsModerateTitle(String room) {
    return 'Moderate $room';
  }

  @override
  String get roomsModerateIntro =>
      'Tap someone to warn, mute or remove them. Muted members can still read; removed members can rejoin when the session ends.';

  @override
  String get roomsPeopleIntro =>
      'Click with someone? Add them as a friend to keep talking after the room.';

  @override
  String get roomsMembersLoadFailed => 'Could not load who is here.';

  @override
  String get roomsStatusFriend => 'Friend';

  @override
  String get roomsStatusHereNow => 'Here now';

  @override
  String get roomsStatusInRoom => 'In the room';

  @override
  String get roomsStatusGone => 'No longer in the room';

  @override
  String roomsStatusMutedUntil(String time) {
    return 'Muted until $time';
  }

  @override
  String roomsYouSuffix(String name) {
    return '$name (you)';
  }

  @override
  String roomsRemoveTitle(String name) {
    return 'Remove $name from the room?';
  }

  @override
  String roomsRemoveBodyAlwaysOn(String name) {
    return '$name leaves the chat now and can come back after 24 hours.';
  }

  @override
  String roomsRemoveBodyHosted(String name) {
    return '$name leaves the chat now and can’t rejoin until this room ends.';
  }

  @override
  String roomsWarnTitle(String name) {
    return 'Warn $name?';
  }

  @override
  String roomsWarnBody(String name) {
    return '$name gets a private reminder to keep the conversation kind and on topic.';
  }

  @override
  String get roomsRemoveAction => 'Remove';

  @override
  String get roomsWarnAction => 'Send warning';

  @override
  String roomsRemovedDone(String name) {
    return '$name was removed from the room.';
  }

  @override
  String roomsWarnedDone(String name) {
    return 'Warning sent to $name.';
  }

  @override
  String get roomsModerationFailed => 'That did not go through. Retry.';

  @override
  String roomsBlockedDone(String name) {
    return 'You blocked $name. You won’t see each other’s messages here.';
  }

  @override
  String get roomsReport => 'Report';

  @override
  String get roomsBlock => 'Block';

  @override
  String get roomsModerateEyebrow => 'MODERATE';

  @override
  String get roomsWarn => 'Warn';

  @override
  String get roomsRemoveFromRoom => 'Remove from room';

  @override
  String get roomsMute => 'Mute';

  @override
  String get roomsUnmute => 'Unmute';

  @override
  String roomsMuteSheetTitle(String name) {
    return 'Mute $name?';
  }

  @override
  String roomsMuteSheetBody(String name) {
    return '$name can still read the chat but can’t post until the mute ends. They’ll get a private note.';
  }

  @override
  String get roomsMuteTenMinutes => 'For 10 minutes';

  @override
  String get roomsMuteOneHour => 'For 1 hour';

  @override
  String get roomsMuteUntilEnd => 'Until the room ends';

  @override
  String get roomsMuteOneDay => 'For 24 hours';

  @override
  String roomsMutedDone(String name) {
    return '$name is muted.';
  }

  @override
  String roomsUnmutedDone(String name) {
    return '$name can post again.';
  }

  @override
  String get richFormattingToolbar => 'Formatting';

  @override
  String get richUndo => 'Undo';

  @override
  String get richRedo => 'Redo';

  @override
  String get richBold => 'Bold';

  @override
  String get richItalic => 'Italic';

  @override
  String get richUnderline => 'Underline';

  @override
  String get richStrikethrough => 'Strikethrough';

  @override
  String get richHighlight => 'Highlight';

  @override
  String get richLink => 'Link';

  @override
  String get richTextStyleMenu => 'Text style';

  @override
  String get richParagraph => 'Paragraph';

  @override
  String get richHeading => 'Heading';

  @override
  String get richSubheading => 'Subheading';

  @override
  String get richQuote => 'Quote';

  @override
  String get richCallout => 'Callout';

  @override
  String get richBulletList => 'Bulleted list';

  @override
  String get richNumberedList => 'Numbered list';

  @override
  String get richDivider => 'Section break';

  @override
  String get richAlignMenu => 'Alignment';

  @override
  String get richAlignStart => 'Align to start';

  @override
  String get richAlignCenter => 'Centre';

  @override
  String get richAlignEnd => 'Align to end';

  @override
  String get richClearFormatting => 'Clear formatting';

  @override
  String get richWritingStyle => 'Writing style';

  @override
  String get richStyleClassic => 'Classic';

  @override
  String get richStyleClassicHint => 'Elegant serif, like a printed page';

  @override
  String get richStyleModern => 'Modern';

  @override
  String get richStyleModernHint => 'Clean and easy to read';

  @override
  String get richStyleJournal => 'Journal';

  @override
  String get richStyleJournalHint => 'Warm italic, like a diary entry';

  @override
  String get richStyleTypewriter => 'Typewriter';

  @override
  String get richStyleTypewriterHint => 'Squared letters with extra spacing';

  @override
  String get richStylePoetic => 'Poetic';

  @override
  String get richStylePoeticHint => 'Centred lines with room to breathe';

  @override
  String richWordCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count words',
      one: '1 word',
    );
    return '$_temp0';
  }

  @override
  String get richAlignmentNote =>
      'Alignment and spacing show in Preview and for readers.';

  @override
  String get richLinkTitle => 'Add a link';

  @override
  String get richLinkField => 'Web address';

  @override
  String get richLinkInvalid => 'Use a complete https:// address.';

  @override
  String get richLinkApply => 'Add link';

  @override
  String get richLinkRemove => 'Remove link';

  @override
  String get richLinkNeedsSelection =>
      'Select the words you want to link first.';

  @override
  String get richCancel => 'Cancel';

  @override
  String get richOpenLinkTitle => 'Open this link?';

  @override
  String richOpenLinkBody(String host) {
    return '$host opens outside Connect. Only open links you trust.';
  }

  @override
  String get richOpenLink => 'Open link';

  @override
  String get supportCentreEyebrow => 'HELP & SUPPORT';

  @override
  String get supportCentreTitle => 'How can we help?';

  @override
  String get supportCentreSubtitle =>
      'Find a quick answer, or ask our team. Every request and reply stays in one private conversation.';

  @override
  String get supportContactSection => 'CONTACT US';

  @override
  String get supportContactTitle => 'Contact support';

  @override
  String get supportContactSubtitle =>
      'Tell us what happened. We reply here and let you know.';

  @override
  String get supportMyTicketsTitle => 'My tickets';

  @override
  String get supportMyTicketsSubtitle => 'Follow your requests and our replies';

  @override
  String supportOpenRequests(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count open requests',
      one: '1 open request',
    );
    return '$_temp0';
  }

  @override
  String supportUnreadReplies(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count new replies',
      one: '1 new reply',
    );
    return '$_temp0';
  }

  @override
  String get supportQuickAnswersSection => 'QUICK ANSWERS';

  @override
  String get supportFaqLoginTitle => 'Login';

  @override
  String get supportFaqLoginBody =>
      'Sign in with your unique username and password.';

  @override
  String get supportFaqVerificationTitle => 'Verification';

  @override
  String get supportFaqVerificationBody =>
      'Identity verification is optional while the provider is paused.';

  @override
  String get supportFaqAbuseTitle => 'Abuse';

  @override
  String get supportFaqAbuseBody =>
      'Use Report on a profile or conversation for faster safety triage.';

  @override
  String get supportFaqBillingTitle => 'Billing';

  @override
  String get supportFaqBillingBody =>
      'Include the transaction reference, never your card details.';

  @override
  String get supportEmergencyNote =>
      'If someone is in immediate danger, contact local emergency services. Support tickets do not replace emergency help.';

  @override
  String get supportUnavailableTitle =>
      'Support requests are not available right now';

  @override
  String get supportUnavailableBody =>
      'The answers on this page still work. For anything urgent, email support@connect.example.';

  @override
  String get supportBackToHelp => 'Back to Help & Support';

  @override
  String get supportFormEyebrow => 'NEW REQUEST';

  @override
  String get supportFormTitle => 'Contact support';

  @override
  String get supportFormSubtitle =>
      'Give us enough detail to act. Never include a password, recovery code, card number or identity document.';

  @override
  String get supportFormCategorySection => 'TOPIC';

  @override
  String get supportFormCategoryLabel => 'What do you need help with?';

  @override
  String get supportCategoryAccountLogin => 'Account & login';

  @override
  String get supportCategoryVerification => 'Verification';

  @override
  String get supportCategoryPaymentsBilling => 'Payments & billing';

  @override
  String get supportCategorySafetyHarassment => 'Safety & harassment';

  @override
  String get supportCategoryMatchesChat => 'Matches & chat';

  @override
  String get supportCategoryTechnical => 'Technical problem or bug';

  @override
  String get supportCategoryFeatureRequest => 'Feature request';

  @override
  String get supportCategoryPrivacyData => 'Privacy & data request';

  @override
  String get supportCategoryOther => 'Other';

  @override
  String get supportSafetyNote =>
      'If you or someone else is in immediate danger, use SOS in the app or call your local emergency services. Safety requests are prioritised, but a ticket is not an emergency line.';

  @override
  String get supportOpenSos => 'Open SOS';

  @override
  String get supportFormDetailsSection => 'DETAILS';

  @override
  String get supportFormSubjectLabel => 'Subject';

  @override
  String get supportFormSubjectHint => 'Briefly describe the issue';

  @override
  String get supportFormDescriptionLabel => 'What happened?';

  @override
  String get supportFormDescriptionHint =>
      'What you did, what you expected and what happened instead';

  @override
  String get supportFormScreenshotsSection => 'SCREENSHOTS';

  @override
  String supportFormScreenshotsCaption(int max) {
    return 'Optional. Up to $max images.';
  }

  @override
  String get supportAddScreenshot => 'Add screenshot';

  @override
  String supportRemoveAttachment(String name) {
    return 'Remove $name';
  }

  @override
  String get supportAttachmentUploading => 'Uploading';

  @override
  String get supportRetryUpload => 'Retry upload';

  @override
  String supportFormDeviceNote(String version) {
    return 'We’ll include your app version ($version), platform, system version and language to help us troubleshoot.';
  }

  @override
  String get supportSubmit => 'Send request';

  @override
  String get supportErrorCategoryRequired => 'Choose a topic.';

  @override
  String supportErrorSubjectLength(int min, int max) {
    return 'Use $min to $max characters for the subject.';
  }

  @override
  String get supportErrorDescriptionRequired => 'Describe what happened.';

  @override
  String supportErrorDescriptionTooLong(int max) {
    return 'Keep it under $max characters.';
  }

  @override
  String get supportErrorUploadsPending =>
      'Wait for your screenshots to finish uploading, or remove any that failed.';

  @override
  String supportCreatedSnack(String reference) {
    return 'Request $reference sent. We’ll reply here.';
  }

  @override
  String supportDuplicateSnack(String reference) {
    return 'You already sent this request, so we opened it: $reference.';
  }

  @override
  String supportErrorRateLimited(int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other:
          'You’ve sent several requests in a short time. Try again in $minutes minutes.',
      one:
          'You’ve sent several requests in a short time. Try again in 1 minute.',
    );
    return '$_temp0';
  }

  @override
  String get supportErrorRateLimitedGeneric =>
      'You’ve sent several requests in a short time. Please try again later.';

  @override
  String get supportErrorTooManyOpen =>
      'You already have 10 open requests. Close one you no longer need, or wait for our replies.';

  @override
  String get supportErrorTicketClosed =>
      'This request is closed and can no longer be reopened. Please start a new request.';

  @override
  String get supportErrorReopenWindowPassed =>
      'The time to reopen this request has passed. Please start a new request.';

  @override
  String get supportErrorAlreadyRated => 'You’ve already rated this request.';

  @override
  String get supportErrorNotResolved =>
      'You can rate a request once it’s resolved.';

  @override
  String get supportErrorAttachmentType =>
      'Only JPEG or PNG images and PDF files can be attached.';

  @override
  String get supportErrorAttachmentTooLarge =>
      'That file is too large. Images can be up to 8 MB.';

  @override
  String get supportErrorOffline =>
      'Can’t reach Connect right now. Check your connection and try again.';

  @override
  String get supportErrorNotFound => 'We couldn’t find this request.';

  @override
  String get supportErrorGeneric => 'Something went wrong. Please try again.';

  @override
  String get supportTryAgain => 'Try again';

  @override
  String get supportTicketsEyebrow => 'SUPPORT';

  @override
  String get supportTicketsTitle => 'My tickets';

  @override
  String get supportTicketsSubtitle => 'Your requests and our replies.';

  @override
  String get supportTicketsActiveSection => 'ACTIVE';

  @override
  String get supportTicketsClosedSection => 'RESOLVED & CLOSED';

  @override
  String get supportTicketsEmptyTitle => 'No requests yet';

  @override
  String get supportTicketsEmptyBody =>
      'When you contact support, your request and our replies appear here.';

  @override
  String get supportTicketsLoadErrorTitle => 'Your requests couldn’t load';

  @override
  String supportTicketUpdated(String when) {
    return 'Updated $when';
  }

  @override
  String get supportNewTicket => 'New request';

  @override
  String get supportStatusOpen => 'Open';

  @override
  String get supportStatusWaitingForYou => 'Waiting for you';

  @override
  String get supportStatusOnHold => 'On hold';

  @override
  String get supportStatusResolved => 'Resolved';

  @override
  String get supportStatusClosed => 'Closed';

  @override
  String supportStatusSemantics(String status) {
    return 'Status: $status';
  }

  @override
  String get supportThreadAgentName => 'Connect Support';

  @override
  String get supportThreadYou => 'You';

  @override
  String supportTicketMeta(String category, String date) {
    return '$category · Opened $date';
  }

  @override
  String get supportBannerOpen =>
      'We have your request. Our team will reply here and let you know.';

  @override
  String get supportBannerWaiting =>
      'Support replied and is waiting for your answer.';

  @override
  String get supportBannerOnHold =>
      'Your request is paused while we look into it. We’ll update you here.';

  @override
  String get supportBannerResolved =>
      'Marked as resolved. Reply to reopen it; otherwise it closes automatically after 7 days.';

  @override
  String supportBannerClosedUntil(String date) {
    return 'This request is closed. You can reopen it until $date.';
  }

  @override
  String get supportBannerClosed => 'This request is closed.';

  @override
  String supportBannerMerged(String reference) {
    return 'This request was merged into $reference. The conversation continues there.';
  }

  @override
  String get supportReplyHint => 'Write a reply';

  @override
  String get supportReplyDisabledHint => 'Replies are closed for this request';

  @override
  String get supportSendReply => 'Send reply';

  @override
  String get supportAttachScreenshot => 'Attach screenshot';

  @override
  String get supportCloseTicket => 'Close request';

  @override
  String get supportCloseConfirmTitle => 'Close this request?';

  @override
  String get supportCloseConfirmBody =>
      'Close it if your problem is solved. You can reopen it for 14 days.';

  @override
  String get supportCancel => 'Cancel';

  @override
  String get supportClosedSnack => 'Request closed.';

  @override
  String get supportReopen => 'Reopen request';

  @override
  String get supportReopenedSnack => 'Request reopened.';

  @override
  String get supportRateTitle => 'How did we do?';

  @override
  String get supportRateCaption => 'Rate your experience with this request.';

  @override
  String supportRateStar(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count stars',
      one: '1 star',
    );
    return '$_temp0';
  }

  @override
  String get supportRateCommentLabel => 'Anything to add? (optional)';

  @override
  String get supportRateSubmit => 'Send rating';

  @override
  String get supportRatedTitle => 'Thanks for your feedback';

  @override
  String supportRatedValue(int rating) {
    return 'You rated this $rating out of 5.';
  }

  @override
  String get supportRatingSnack => 'Thanks for rating your experience.';

  @override
  String supportAttachmentImage(String name) {
    return 'Screenshot $name';
  }

  @override
  String get supportAttachmentLoadFailed => 'Couldn’t load attachment';

  @override
  String get supportThreadLoadErrorTitle => 'This request couldn’t load';

  @override
  String get chemistryCardEntry => 'A little chemistry?';

  @override
  String get memberProfileIntroducing => 'Introducing';

  @override
  String get memberProfileStarring => 'Starring';

  @override
  String get memberProfileVerified => 'Verified';

  @override
  String memberProfilePhotoLabel(String name, int index, int count) {
    return '$name, photo $index of $count';
  }

  @override
  String get memberProfileNoPhoto => 'No photo yet';

  @override
  String get memberProfileViewPhotoHint => 'view full screen';

  @override
  String get memberProfileCloseGallery => 'Close photos';

  @override
  String get memberProfilePhotos => 'Photos';

  @override
  String memberProfileMorePhotos(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count more photos',
      one: '1 more photo',
    );
    return '$_temp0';
  }

  @override
  String get memberProfileSceneAbout => 'About';

  @override
  String get memberProfileSceneStories => 'Stories';

  @override
  String get memberProfileSceneStoriesTitle => 'A little more me';

  @override
  String get memberProfileSceneInterests => 'Interests';

  @override
  String get memberProfileSceneBasics => 'The basics';

  @override
  String get memberProfileSceneLifestyle => 'Lifestyle';

  @override
  String get memberProfileSceneTrust => 'Trust';

  @override
  String get memberProfileReadMore => 'Read more';

  @override
  String get memberProfileReadLess => 'Read less';

  @override
  String get memberProfileHobbies => 'Hobbies';

  @override
  String get memberProfileActivities => 'Activities';

  @override
  String get memberProfileSongs => 'On repeat';

  @override
  String get memberProfileBooks => 'Books & novels';

  @override
  String get memberProfileLookingFor => 'Looking for';

  @override
  String get memberProfileLanguages => 'Languages';

  @override
  String get memberProfileDealBreakers => 'Deal breakers';

  @override
  String get memberProfileInCommon => 'In common';

  @override
  String get memberProfileFactHeight => 'Height';

  @override
  String memberProfileHeightCm(int cm) {
    return '$cm cm';
  }

  @override
  String get memberProfileFactWork => 'Work';

  @override
  String get memberProfileFactEducation => 'Education';

  @override
  String get memberProfileFactLivesIn => 'Lives in';

  @override
  String get memberProfileFactMotherTongue => 'Mother tongue';

  @override
  String get memberProfileFactReligion => 'Religion';

  @override
  String get memberProfileFactPersonality => 'Personality';

  @override
  String get memberProfileFactRelationship => 'Relationship';

  @override
  String get memberProfileFactInstagram => 'Instagram';

  @override
  String get memberProfileFactDrinking => 'Drinking';

  @override
  String get memberProfileFactSmoking => 'Smoking';

  @override
  String get memberProfileFactWorkout => 'Workout';

  @override
  String get memberProfileFactDiet => 'Diet';

  @override
  String get memberProfileFactDietType => 'Diet type';

  @override
  String get memberProfileFactSleep => 'Sleep';

  @override
  String get memberProfileFactTravel => 'Travel';

  @override
  String get memberProfileFactPets => 'Pets';

  @override
  String get memberProfileFactPolitics => 'Politics';

  @override
  String get memberProfileFactOpenToCasual => 'Open to casual';

  @override
  String get memberProfileFactPartyLover => 'Loves a party';

  @override
  String get memberProfileVerifiedTitle => 'Verified profile';

  @override
  String get memberProfileVerifiedBody => 'Identity verification completed.';

  @override
  String get memberProfileVouchesTitle => 'Vouched for by friends';

  @override
  String get memberProfileSpotlight => 'Spotlight';

  @override
  String get memberProfileFreeWhenYouAre => 'Free when you are';

  @override
  String get memberProfileMessage => 'Message';

  @override
  String get memberProfileLove => 'Love';

  @override
  String get memberProfileReport => 'Report';

  @override
  String get memberProfileOwnerTitle => 'This is how you appear';

  @override
  String get memberProfileOwnerCaption =>
      'Members see your profile just like this.';

  @override
  String memberProfileCompleteness(int percent) {
    return 'Profile $percent% complete';
  }

  @override
  String get memberProfileCompletenessHint =>
      'Add photos, stories and details to stand out.';

  @override
  String get memberProfileCompletenessDone => 'Your profile is complete.';

  @override
  String get memberProfileToolEdit => 'Edit profile';

  @override
  String get memberProfileToolPhotos => 'Edit photos';

  @override
  String get memberProfileToolStories => 'Your stories';

  @override
  String get memberProfileToolViewers => 'Who viewed you';

  @override
  String get memberProfileBehindTheScenes => 'Behind the scenes';

  @override
  String get memberProfileOnlyYou => 'Only you can see this.';

  @override
  String get memberProfileMine => 'My profile';

  @override
  String get profileShowcaseLabel => 'Writing & moments';

  @override
  String get profileShowcaseTitleOther => 'In their own words';

  @override
  String get profileShowcaseTitleSelf => 'Your public writing & photos';

  @override
  String get profileShowcaseChapters => 'Chapters';

  @override
  String get profileShowcasePhotos => 'Wall photos';

  @override
  String get profileShowcaseReadAll => 'Read all their chapters';

  @override
  String get profileShowcaseHiddenTitle => 'Only you can see this';

  @override
  String get profileShowcaseHiddenBody =>
      'Your public chapters and wall photos are hidden from your profile. Turn this on to let members see them here.';

  @override
  String get profileShowcaseShownBody =>
      'Members can see these on your profile. Only chapters shared with the community and photos on the wall appear.';

  @override
  String get profileShowcaseSwitch => 'Show on my profile';

  @override
  String get profileShowcaseSaveFailed => 'Your choice couldn\'t be saved.';
}
