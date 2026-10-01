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
}
