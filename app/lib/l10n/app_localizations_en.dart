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

  @override
  String get callsHistoryTitle => 'Call history';

  @override
  String get callsHistoryEmpty => 'No call sessions yet.';

  @override
  String callsHistoryMatch(String id) {
    return 'Match $id';
  }

  @override
  String get callsJoinLiveRoom => 'Join live room';

  @override
  String get callsActiveSession => 'Active call session';

  @override
  String callsEndedWithDuration(String duration) {
    return 'Ended · $duration';
  }

  @override
  String get callsSessionTitle => 'Call session';

  @override
  String get callsStarting => 'Starting secure session…';

  @override
  String get callsSessionActive => 'Session active';

  @override
  String get callsSessionUnavailable => 'Session unavailable';

  @override
  String get callsLiveRoomNote =>
      'The live room opens in a secure provider window. Use that room’s microphone, camera, and leave controls during the call.';

  @override
  String get callsEnd => 'End';

  @override
  String get callsErrorSignInHistory => 'Please sign in to view call history.';

  @override
  String get callsErrorSignInStart => 'Please sign in before starting a call.';

  @override
  String get callsErrorPermissions =>
      'Camera and microphone permissions are required for calls.';

  @override
  String get callsErrorLoadHistory => 'Unable to load call history.';

  @override
  String get callsErrorStart => 'Unable to start the call session.';

  @override
  String get callsErrorEnd => 'Unable to end the call.';

  @override
  String get callsErrorNotConfigured =>
      'Live call rooms are not configured for this environment.';

  @override
  String get callsErrorOpenRoom => 'Unable to open the live call room.';

  @override
  String get commonRetry => 'Retry';

  @override
  String get commonCancel => 'Cancel';

  @override
  String get commonClose => 'Close';

  @override
  String get commonCopy => 'Copy';

  @override
  String get commonDelete => 'Delete';

  @override
  String get commonBack => 'Back';

  @override
  String get commonApply => 'Apply';

  @override
  String get commonReset => 'Reset';

  @override
  String get commonOpen => 'Open';

  @override
  String get commonView => 'View';

  @override
  String get commonDismiss => 'Dismiss';

  @override
  String get commonAny => 'Any';

  @override
  String get commonSomethingWentWrong => 'Something went wrong';

  @override
  String get commonSomethingWentWrongTryAgain =>
      'Something went wrong. Please try again.';

  @override
  String get commonTryAgainTitle => 'Try Again';

  @override
  String get commonNothingHereYet => 'Nothing here yet';

  @override
  String commonLoadingLabel(String label) {
    return '$label, loading';
  }

  @override
  String commonDistanceKm(int distance) {
    return '$distance km';
  }

  @override
  String get navToday => 'Today';

  @override
  String get navOfflineBanner => 'Offline mode: Some data may be outdated.';

  @override
  String navWeakNetworkBanner(int mbps) {
    return 'Weak network detected. Use at least $mbps Mbps for smoother app performance.';
  }

  @override
  String get navIncomingCallTitle => 'Incoming call';

  @override
  String get navIncomingCallBody => 'A match is calling you.';

  @override
  String get navViewCallDetails => 'View call details';

  @override
  String get filterSheetTitle => 'Filter Matches';

  @override
  String get filterAgeRange => 'Age Range';

  @override
  String get filterProfileLifestyle => 'Profile & Lifestyle Filters';

  @override
  String get filterCountry => 'Country';

  @override
  String get filterState => 'State';

  @override
  String get filterCity => 'City';

  @override
  String get filterMotherTongue => 'Mother Tongue';

  @override
  String get filterReligion => 'Religion';

  @override
  String get filterRelationshipStatus => 'Relationship Status';

  @override
  String get filterSmoking => 'Smoking';

  @override
  String get filterDrinking => 'Drinking';

  @override
  String get filterPersonalityType => 'Personality Type';

  @override
  String get filterPartyLoverOnly => 'Party lover only';

  @override
  String get filterHookupsOnly => 'Hookups only';

  @override
  String get filterAdvancedBio => 'Advanced Bio Filters';

  @override
  String get filterAdvancedBioBody =>
      'Books, novels, songs, hobbies, location and extra-curricular tags can be managed in Settings → Dating Preferences.';

  @override
  String get filterOpenDatingPreferences => 'Open Dating Preferences';

  @override
  String get filterDistanceKm => 'Distance (km)';

  @override
  String get filterVerifiedOnlyTitle => 'Verified Only';

  @override
  String get filterVerifiedOnlyBody => 'Show only verified profiles';

  @override
  String get filterVerifiedOnlyChip => 'Verified only';

  @override
  String get filterPartyLoverChip => 'Party lover';

  @override
  String get filterHookupChip => 'Hookup only';

  @override
  String get filterEnableTrust => 'Enable trust-based filtering';

  @override
  String filterMinimumTrustBadges(int count) {
    return 'Minimum active trust badges: $count';
  }

  @override
  String filterSavedSnack(
    int minAge,
    int maxAge,
    int distance,
    String verified,
    String trust,
  ) {
    String _temp0 = intl.Intl.selectLogic(verified, {
      'true': ', verified only',
      'other': '',
    });
    String _temp1 = intl.Intl.selectLogic(trust, {
      'true': ', trust filter on',
      'other': ', trust filter off',
    });
    return 'Filters saved: $minAge-$maxAge yrs, $distance km$_temp0$_temp1';
  }

  @override
  String get optionNever => 'Never';

  @override
  String get optionOccasionally => 'Occasionally';

  @override
  String get optionSocially => 'Socially';

  @override
  String get optionRegularly => 'Regularly';

  @override
  String get optionSingle => 'Single';

  @override
  String get optionDivorced => 'Divorced';

  @override
  String get optionWidowed => 'Widowed';

  @override
  String get optionSeparated => 'Separated';

  @override
  String get optionComplicated => 'Complicated';

  @override
  String get optionIntrovert => 'Introvert';

  @override
  String get optionAmbivert => 'Ambivert';

  @override
  String get optionExtrovert => 'Extrovert';

  @override
  String get optionHighSchool => 'High School';

  @override
  String get optionBachelors => 'Bachelor\'s';

  @override
  String get optionMasters => 'Master\'s';

  @override
  String get optionPhd => 'PhD';

  @override
  String get optionOther => 'Other';

  @override
  String get optionPreferNotToSay => 'Prefer not to say';

  @override
  String get optionHindu => 'Hindu';

  @override
  String get optionMuslim => 'Muslim';

  @override
  String get optionChristian => 'Christian';

  @override
  String get optionSikh => 'Sikh';

  @override
  String get optionBuddhist => 'Buddhist';

  @override
  String get optionJain => 'Jain';

  @override
  String get optionJewish => 'Jewish';

  @override
  String get optionSpiritual => 'Spiritual';

  @override
  String get optionAgnostic => 'Agnostic';

  @override
  String get optionAtheist => 'Atheist';

  @override
  String get storiesNudgeTitle => 'Tell a little more of your story';

  @override
  String get storiesNudgeBodyUnknown =>
      'Short stories on your profile give people something real to say hello about.';

  @override
  String get storiesNudgeActionOpen => 'Open your stories';

  @override
  String get storiesNudgeBodyEmpty =>
      'Add a short story to your profile: a small joy, a weekend worth sharing. People read these before they say hello.';

  @override
  String get storiesNudgeActionFirst => 'Write your first story';

  @override
  String get storiesNudgeCompleteTitle => 'Your story is complete';

  @override
  String get storiesNudgeCompleteBody =>
      'All three stories are on your profile. Refresh one whenever life gives you a new one.';

  @override
  String get storiesNudgeActionEdit => 'Edit your stories';

  @override
  String storiesNudgeSharedTitle(int count, int max) {
    return '$count of $max stories shared';
  }

  @override
  String get storiesNudgeBodyMore =>
      'One more story gives people another way to start a conversation.';

  @override
  String storiesNudgeBodyLatest(String prompt) {
    return 'Latest: “$prompt”. One more gives people another way to start a conversation.';
  }

  @override
  String get storiesNudgeActionAdd => 'Add another story';

  @override
  String get storiesNudgeIdeas => 'Ideas to start with';

  @override
  String storiesProgressSemantics(int count, int max) {
    return '$count of $max stories written';
  }

  @override
  String get storiesPromptLittleJoy => 'A small thing I always make time for';

  @override
  String get storiesPromptWeekend => 'A weekend worth sharing';

  @override
  String get storiesPromptFirstHello => 'A first hello I would love';

  @override
  String get storiesPromptLearning => 'Something I am learning, just for me';

  @override
  String get storiesPromptCare => 'A small way I show I care';

  @override
  String get storiesScreenTitle => 'A little more you';

  @override
  String get storiesSignIn => 'Sign in to edit your stories.';

  @override
  String get storiesLoadFailed => 'Your stories couldn’t load.';

  @override
  String get storiesTryAgain => 'Try again';

  @override
  String get storiesIncomplete =>
      'Add words to each story and a description for each photo, or remove the unfinished story.';

  @override
  String get storiesPublished => 'Your profile stories are published.';

  @override
  String get storiesSavedPrivately =>
      'Saved privately. Your stories are hidden from other members.';

  @override
  String get storiesSaveUnconfirmed =>
      'We couldn’t confirm the save. Your edits are still here; reload saved stories to check.';

  @override
  String get storiesHeadline => 'Let someone meet\nthe everyday you.';

  @override
  String get storiesIntro =>
      'A small ritual, a story behind a photo, a first hello you would enjoy. Share up to three moments, in your own words.';

  @override
  String get storiesOptionalNote =>
      'Optional, with no score or completion requirement. Avoid contact details or precise locations you do not want to share.';

  @override
  String get storiesPublishSwitch => 'Show these stories on my profile';

  @override
  String get storiesPublishSwitchHint =>
      'Starts off. Visible to eligible members when your profile is published and available. You can hide them at any time.';

  @override
  String get storiesBackToEditing => 'Back to editing';

  @override
  String get storiesPreview => 'Preview my stories';

  @override
  String get storiesPreviewBanner => 'PREVIEW · THIS DOES NOT PUBLISH';

  @override
  String get storiesAdd => 'Add a story';

  @override
  String get storiesReloadDiscard => 'Reload saved stories · discard edits';

  @override
  String get storiesSaving => 'Saving…';

  @override
  String get storiesPublishButton => 'Publish stories';

  @override
  String get storiesSavePrivatelyButton => 'Save privately';

  @override
  String get storiesPolicyNote =>
      'Photos come from your approved profile gallery. Stories and photos remain subject to member reporting and safety policies.';

  @override
  String storiesMomentLabel(int number) {
    return 'MOMENT $number';
  }

  @override
  String storiesRemoveTooltip(int number) {
    return 'Remove story $number';
  }

  @override
  String get storiesPromptLabel => 'A starting point';

  @override
  String get storiesTextLabel => 'In your words';

  @override
  String get storiesTextHint => 'A real detail makes it yours.';

  @override
  String get storiesTextRequired => 'Add a few words, or remove this story.';

  @override
  String get storiesPhotoLabel => 'A photo, if you like';

  @override
  String get storiesWordsOnly => 'Words only';

  @override
  String storiesProfilePhoto(int number) {
    return 'Profile photo $number';
  }

  @override
  String get storiesPhotoDescriptionLabel => 'Describe this photo';

  @override
  String get storiesPhotoDescriptionHelper =>
      'Helps people using screen readers.';

  @override
  String get storiesPhotoDescriptionRequired =>
      'Add a short photo description.';

  @override
  String get storiesPhotoSemantics => 'Profile story photo';

  @override
  String get storiesSectionTitle => 'A little more me';

  @override
  String get storiesRetryLoad => 'Try loading stories again';

  @override
  String get authErrorSessionExpired =>
      'You were signed out. Please sign in again.';

  @override
  String get authErrorSignInFailed => 'Unable to sign in. Try again.';

  @override
  String get authErrorCreateAccountFailed =>
      'Unable to create account. Try again.';

  @override
  String get authErrorCreateAccountGeneric => 'Unable to create account.';

  @override
  String get authErrorInvalidCredentials => 'Invalid username or password.';

  @override
  String get authErrorUsernameFormat =>
      'Username must be 3–30 characters using letters, numbers, _ or .';

  @override
  String get authErrorPasswordFormat =>
      'Password must be 8–72 bytes with letters and numbers.';

  @override
  String get authWelcomeIntroducerLink => 'Just here to introduce friends';

  @override
  String get signupBackTooltip => 'Back';

  @override
  String get signupIntroducerTitle =>
      'Be the friend who brings people together.';

  @override
  String get signupIntroducerBody =>
      'A friend-only account. No dating profile, photos or swiping. Your age stays private; Connect is for adults 18–80.';

  @override
  String get signupTitle => 'Create your account';

  @override
  String get signupSubtitle => 'Choose a unique username and secure password';

  @override
  String get signupUsernameLabel => 'Unique username';

  @override
  String get signupUsernameHint => 'your_username';

  @override
  String get signupUsernameHelp =>
      '3–30 characters. Letters, numbers, underscore and dot.';

  @override
  String get signupPasswordLabel => 'Password';

  @override
  String get signupPasswordHint => 'At least 8 characters';

  @override
  String get signupConfirmPasswordHint => 'Confirm password';

  @override
  String get signupNameLabel => 'Full name';

  @override
  String get signupNameHint => 'Your name';

  @override
  String get signupDobLabel => 'Date of birth';

  @override
  String get signupDobPickerHelp => 'Select date of birth';

  @override
  String get signupDobPlaceholder => 'Select date';

  @override
  String get signupGenderLabel => 'I identify as';

  @override
  String get signupGenderMan => 'Man';

  @override
  String get signupGenderWoman => 'Woman';

  @override
  String get signupGenderOther => 'Other';

  @override
  String get signupCreateFriendAccount => 'Create friend account';

  @override
  String get signupAlreadyHaveAccount => 'Already have an account?';

  @override
  String get signupErrorPasswordMismatch => 'Passwords do not match.';

  @override
  String get signupErrorFullName => 'Please enter your full name.';

  @override
  String get signupErrorDobMissing => 'Please select your date of birth.';

  @override
  String get signupErrorUnderage => 'You must be at least 18 years old.';

  @override
  String get signupErrorAgeRange =>
      'Connect currently supports members aged 18–80.';

  @override
  String get signupErrorGenderMissing => 'Please choose how you identify.';

  @override
  String get authRecoveryEnterUsername => 'Enter your username.';

  @override
  String get authRecoveryEnterCode => 'Enter your recovery code.';

  @override
  String get authRecoveryPasswordRule =>
      'Use 8–72 characters with at least one letter and one number.';

  @override
  String get authRecoveryResetDone =>
      'Your password has been reset and every device has been signed out. Sign in with your new password.';

  @override
  String get authRecoveryAssistanceDone =>
      'If this username belongs to a Connect account, our safety team will review the request.';

  @override
  String get authRecoveryInvalidCode =>
      'That recovery code is not valid or has expired.';

  @override
  String get authRecoveryOffline =>
      'Could not reach Connect. Check your connection and try again.';

  @override
  String get authRecoverySendFailed =>
      'Could not send your request. Check your connection and try again.';

  @override
  String get authRecoveryBackToSignIn => 'Back to sign in';

  @override
  String get authRecoveryHaveCode => 'I have my code';

  @override
  String get authRecoveryLostCode => 'I lost my code';

  @override
  String get authRecoveryHaveCodeIntro =>
      'Use the recovery code you saved when you created your account, or one issued by our safety team.';

  @override
  String get authRecoveryLostCodeIntro =>
      'Tell us your username. We\'ll confirm your identity before issuing a recovery code. We never ask for your password.';

  @override
  String get authRecoveryUsernameLabel => 'Username';

  @override
  String get authRecoveryCodeLabel => 'Recovery code';

  @override
  String get authRecoveryNewPasswordLabel => 'New password';

  @override
  String get authRecoveryMessageLabel => 'Anything that helps us (optional)';

  @override
  String get authRecoveryMessageHint => 'For example, when you last signed in';

  @override
  String get authRecoverySending => 'Sending…';

  @override
  String get authRecoveryResetPassword => 'Reset password';

  @override
  String get authRecoveryAskForHelp => 'Ask for help';

  @override
  String get authTermsTitle => 'Terms and Conditions';

  @override
  String get authTermsSubtitle => 'A quick review before you enter the app.';

  @override
  String get authTermsIntro =>
      'Please review and accept our Terms and Privacy Policy to continue.';

  @override
  String get authTermsCommunityTitle => 'Community expectations';

  @override
  String get authTermsPointRespect => 'Be respectful and authentic.';

  @override
  String get authTermsPointNoHarassment =>
      'No harassment or fraudulent behavior.';

  @override
  String get authTermsPointPrivacy =>
      'You control your privacy settings and profile visibility.';

  @override
  String get authTermsPointReports =>
      'Reports are reviewed to keep the community safe.';

  @override
  String get authTermsPointViolations =>
      'Violations may result in suspension or account removal.';

  @override
  String get authTermsReviewLater =>
      'You can review the full policy details later from settings, but acceptance is required before using the app.';

  @override
  String get authTermsAgreeCheckbox => 'I agree to the Terms & Privacy Policy';

  @override
  String get authTermsAcceptButton => 'I Accept and Continue';

  @override
  String get authTermsSaveFailed =>
      'Could not save your agreement. Please check network and try again.';

  @override
  String discoverSuperLikeSent(String name) {
    return 'Super like sent to $name';
  }

  @override
  String get discoverMatchPlaceholderMessage => 'Say hi';

  @override
  String discoverChatNeedsMatch(String name) {
    return 'You can chat with $name after a real match is created.';
  }

  @override
  String get discoverDailyLimitTitle => 'You\'ve used today\'s likes';

  @override
  String get discoverDailyLimitBody =>
      'Come back tomorrow, or upgrade for more likes every day.';

  @override
  String discoverDailyLimitResetBody(String reset) {
    return '$reset. Upgrade for more likes every day.';
  }

  @override
  String get discoverSeePlans => 'See plans';

  @override
  String get discoverNotNow => 'Not now';

  @override
  String get discoverBackToToday => 'Back to Today';

  @override
  String get discoverExploreTitle => 'Explore';

  @override
  String get discoverSpotlightReviewed => 'Spotlight reviewed!';

  @override
  String get discoverAllReviewed => 'All reviewed!';

  @override
  String get discoverCuratedForYou => 'Curated for you';

  @override
  String get discoverTitle => 'Discover Matches';

  @override
  String get discoverTagline => 'A little curiosity. A real connection.';

  @override
  String get discoverMessages => 'Messages';

  @override
  String get discoverFilters => 'Filters';

  @override
  String get discoverYourDeck => 'Your deck';

  @override
  String get discoverStatReady => 'Ready';

  @override
  String get discoverStatLiked => 'Liked';

  @override
  String get discoverStatPassed => 'Passed';

  @override
  String get discoverEdit => 'Edit';

  @override
  String get discoverShowingEveryone => 'Showing everyone in your preferences.';

  @override
  String get discoverToday => 'Today';

  @override
  String get discoverTodaySubtitle => 'Five picks, refreshed every day.';

  @override
  String get discoverViewAll => 'View all';

  @override
  String get discoverMatchOnYourTerms => 'Match on your terms';

  @override
  String get discoverMatchOnYourTermsBody =>
      'Mutual interest creates a match. You can block or report anyone from their profile or conversation.';

  @override
  String get discoverErrorEyebrow => 'Connection paused';

  @override
  String get discoverErrorTitle => 'Unable to load profiles';

  @override
  String discoverTrustFilteredBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Trust filters hid $count profile(s). Try relaxing trust filters or refresh to rebuild your deck.',
    );
    return '$_temp0';
  }

  @override
  String get discoverDeckPreparingBody =>
      'Your curated deck is being prepared. Refresh to check for new verified profiles near you.';

  @override
  String get discoverCheckBackSoon => 'Check back soon';

  @override
  String get discoverNoSpotlightProfiles => 'No spotlight profiles';

  @override
  String get discoverNoProfiles => 'No profiles';

  @override
  String get discoverRefresh => 'Refresh';

  @override
  String get discoverPromisePrivate => 'Private';

  @override
  String get discoverPremium => 'Premium';

  @override
  String discoverNotificationsUnread(int count) {
    return 'Notifications, $count unread';
  }

  @override
  String get discoverLatestUnreadNotifications => 'Latest unread notifications';

  @override
  String get discoverNoUnreadNotifications => 'No unread notifications';

  @override
  String get discoverNotificationWhoReplied => 'Who replied me';

  @override
  String discoverNotificationRepliesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count new replies',
      one: '1 new reply',
    );
    return '$_temp0';
  }

  @override
  String get discoverNotificationWhoLiked => 'Who has liked me';

  @override
  String discoverNotificationLikesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count new likes',
      one: '1 new like',
    );
    return '$_temp0';
  }

  @override
  String get discoverViewMore => 'View more';

  @override
  String get discoverFitsYourWeek => 'Fits your week';

  @override
  String discoverTodayPicks(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count picks',
      one: '1 pick',
    );
    return '$_temp0';
  }

  @override
  String get discoverPickedForYouToday => 'Picked for you today.';

  @override
  String get discoverErrorLoginToDiscover =>
      'Please login to discover profiles.';

  @override
  String get discoverErrorLoadProfiles =>
      'Failed to load profiles. Please try again.';

  @override
  String get discoverErrorSessionUnavailable =>
      'User session not available. Please login again.';

  @override
  String get discoverErrorLikeRetry =>
      'Unable to like right now. Please try again.';

  @override
  String get discoverErrorLike => 'Unable to like right now.';

  @override
  String get discoverErrorPassRetry =>
      'Unable to pass right now. Please try again.';

  @override
  String get discoverErrorLoadLikedMe =>
      'Could not load who liked you. Please try again.';

  @override
  String get discoverErrorAnswerInFlight => 'Already sending your answer.';

  @override
  String get discoverErrorAnswer =>
      'Could not send your answer. Please try again.';

  @override
  String get firstChapterTopicPace => 'Communication pace';

  @override
  String get firstChapterTopicDates => 'Dating comfort';

  @override
  String get firstChapterTopicLanguage => 'Languages';

  @override
  String get firstChapterTopicFamily => 'Family involvement';

  @override
  String get firstChapterInMyWords => 'In my words';

  @override
  String firstChapterComfortOriginal(String language) {
    return 'Original · $language';
  }

  @override
  String firstChapterComfortMemberTranslation(String language) {
    return 'Member-provided translation · $language';
  }

  @override
  String get firstChapterComfortReloadSaved => 'Reload saved version';

  @override
  String get firstChapterComfortReloadCards => 'Reload comfort cards';

  @override
  String get firstChapterComfortHeadline => 'Your words. Your boundaries.';

  @override
  String get firstChapterComfortIntro =>
      'Optional context for people you have matched with. Nothing is inferred from your background. Write in the language that feels like you.';

  @override
  String get firstChapterComfortShareTitle =>
      'Share these cards with my matches';

  @override
  String get firstChapterComfortShareSubtitle =>
      'Off keeps every card private.';

  @override
  String get firstChapterComfortRemoveFromDraft => 'Remove from draft';

  @override
  String get firstChapterComfortTopicLabel => 'A little context about';

  @override
  String get firstChapterComfortOriginalLanguage => 'Original language';

  @override
  String get firstChapterComfortOwnWords => 'In your own words';

  @override
  String get firstChapterComfortOwnWordsHint =>
      'For example: I enjoy daytime dates and a little time to get comfortable.';

  @override
  String get firstChapterComfortTranslation => 'Your translation (optional)';

  @override
  String get firstChapterComfortTranslationLanguage =>
      'Translation language (if added)';

  @override
  String get firstChapterComfortTranslationNote =>
      'Translations are labelled as member-provided. Your original words are always preserved.';

  @override
  String get firstChapterComfortAddCard => 'Add / replace this card in draft';

  @override
  String get firstChapterComfortMissingFields =>
      'Add your words and language. A translation also needs its language.';

  @override
  String get firstChapterComfortUnaddedCard =>
      'Add your written card to the draft before saving.';

  @override
  String get firstChapterComfortSaveFailed =>
      'Your draft is still here. Reload to check the latest saved version before retrying.';

  @override
  String get firstChapterSaving => 'Saving…';

  @override
  String get firstChapterComfortSave => 'Save my choices';

  @override
  String get firstChapterYourMatch => 'your match';

  @override
  String get firstChapterSaveUnconfirmed =>
      'We could not confirm the save. Refresh to check before retrying.';

  @override
  String get firstChapterJointPreviewTitle => 'A story you both approve';

  @override
  String get firstChapterSoloPreviewTitle => 'Preview your public chapter';

  @override
  String firstChapterThenSurprise(String surprise) {
    return 'Then… $surprise';
  }

  @override
  String get firstChapterJointPreviewBody =>
      'Your approval is one half. The link works only after your partner also approves this exact card. Either of you can revoke it.';

  @override
  String get firstChapterSoloPreviewBody =>
      'Only this scene and your selected beginning are public. No names, photos, private chat, location or partner contribution. You can revoke the link.';

  @override
  String get firstChapterKeepPrivate => 'Keep private';

  @override
  String get firstChapterApproveMyHalf => 'Approve my half';

  @override
  String get firstChapterCreateShareLink => 'Create share link';

  @override
  String get firstChapterStudioTitle => 'First Chapter Studio';

  @override
  String get firstChapterRefresh => 'Refresh chapter';

  @override
  String get firstChapterHeroEyebrow => 'A SMALL ADVENTURE. TWO AUTHORS.';

  @override
  String get firstChapterHeroTitle => 'What happens\nnext is yours.';

  @override
  String get firstChapterHeroSolo =>
      'Make a scene. Pass it to a friend. Or create a first chapter with someone you have matched with.';

  @override
  String firstChapterHeroPair(String name) {
    return 'You and $name. One beginning, one unexpected turn, and a story you can make real.';
  }

  @override
  String get firstChapterHeroPace =>
      'Optional, at your pace. Chat is always a choice.';

  @override
  String get firstChapterLoadFailed => 'Your chapter could not be loaded.';

  @override
  String get firstChapterTryAgain => 'Try again';

  @override
  String get firstChapterStepChooseScene => '01 / Choose your scene';

  @override
  String get firstChapterStepWriteBeginning => '02 / Write the beginning';

  @override
  String get firstChapterStartOurChapter => 'Start our chapter';

  @override
  String get firstChapterPassTheChapter => 'Pass the Chapter';

  @override
  String get firstChapterYourFirstChapter => 'Your first chapter';

  @override
  String get firstChapterItBeginsWith => 'IT BEGINS WITH';

  @override
  String get firstChapterAndThen => 'AND THEN…';

  @override
  String firstChapterDateIdeaNote(String beginning, String surprise) {
    return '$beginning. Then $surprise.';
  }

  @override
  String get firstChapterMakeDateIdea => 'Make this a date idea';

  @override
  String get firstChapterDateIdeaHint =>
      'A suggestion to shape together. No date is booked or accepted automatically.';

  @override
  String get firstChapterYourTurn => 'Your turn: add a surprise.';

  @override
  String get firstChapterBeginningSaved =>
      'Your beginning is saved. Your match can add a surprise whenever they like. You can keep chatting.';

  @override
  String get firstChapterClose => 'Close this chapter';

  @override
  String get firstChapterGiveBackTitle => 'Stories that give back';

  @override
  String get firstChapterGiveBackBody =>
      'Your connection can inspire a new beginning. Share only this anonymous date idea, with both of your approvals.';

  @override
  String get firstChapterPreviewAnonymous => 'Preview our anonymous story';

  @override
  String get firstChapterGreenLightTitle => 'A private green light';

  @override
  String get firstChapterInTheirWords => 'In their words';

  @override
  String get firstChapterMakeRoomTitle => 'Make room for what matters to you';

  @override
  String get firstChapterMakeRoomSubtitle =>
      'Your pace, languages, dates and family expectations. Your words, shared only when you choose.';

  @override
  String get firstChapterCreateWithConnection => 'Create with a connection';

  @override
  String get firstChapterCreateTogether => 'Create a first chapter together';

  @override
  String get firstChapterMatchesAppearHere =>
      'Your mutual matches appear here. You can try and share a solo scene now.';

  @override
  String get firstChapterSharedChapters => 'Your shared chapters';

  @override
  String get firstChapterReloadShared => 'Reload shared chapters';

  @override
  String get firstChapterNothingPublic =>
      'Nothing public until you choose to share.';

  @override
  String get firstChapterGreenChat => 'Keep chatting';

  @override
  String get firstChapterGreenCall => 'Try a call';

  @override
  String get firstChapterGreenDate => 'Suggest a date';

  @override
  String get firstChapterGreenLightIntro =>
      'Only a shared choice is revealed. Nobody sees an unanswered request. Choices expire after seven days; clear them to withdraw.';

  @override
  String get firstChapterSavePrivately => 'Save privately';

  @override
  String get firstChapterGreenLightNone =>
      'Any shared next step will appear here.';

  @override
  String firstChapterGreenLightMutual(String choices) {
    return 'You both feel comfortable with: $choices';
  }

  @override
  String get firstChapterGreenLightNote =>
      'A green light is permission to suggest. A call or date still needs a separate agreement.';

  @override
  String get firstChapterLinkRevoked => 'Link revoked';

  @override
  String get firstChapterPublicScene => 'Public, anonymous scene';

  @override
  String get firstChapterPrivateUntilBoth => 'Private until both approve';

  @override
  String get firstChapterLinkCopied =>
      'Chapter link copied. Share it wherever you choose.';

  @override
  String get firstChapterCopyLink => 'Copy link';

  @override
  String get firstChapterApproveStory => 'Approve this exact story';

  @override
  String get firstChapterRevokeLink => 'Revoke link';

  @override
  String networkSlowResponse(int mbps) {
    return 'Weak network detected. Use at least $mbps Mbps for smoother chat, gifts, and gestures.';
  }

  @override
  String get networkOffline =>
      'No stable network connection. Reconnect to continue using the app.';

  @override
  String networkWeak(int mbps) {
    return 'Network is weak. Use at least $mbps Mbps for a smoother experience.';
  }

  @override
  String get networkCannotReachService =>
      'Cannot reach the local service. Check that the API is running.';

  @override
  String get gateCheckingTerms => 'Checking terms…';

  @override
  String get gateLoadingProfile => 'Loading your profile…';

  @override
  String get gateConnectionIssue => 'Connection issue';

  @override
  String get safetyReportFailed => 'Failed to report user';

  @override
  String get safetyBlockFailed => 'Failed to block user';

  @override
  String get safetyUnblockFailed => 'Failed to unblock user';

  @override
  String get safetyNotAuthenticated => 'Not authenticated';

  @override
  String get timeAgoJustNow => 'Just now';

  @override
  String timeAgoMinutes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count minutes ago',
      one: '1 minute ago',
    );
    return '$_temp0';
  }

  @override
  String timeAgoHours(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count hours ago',
      one: '1 hour ago',
    );
    return '$_temp0';
  }

  @override
  String timeAgoDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days ago',
      one: '1 day ago',
    );
    return '$_temp0';
  }

  @override
  String timeAgoWeeks(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count weeks ago',
      one: '1 week ago',
    );
    return '$_temp0';
  }

  @override
  String get themePreviewBarrier => 'Theme preview';

  @override
  String get themeNowShowing => 'NOW SHOWING';

  @override
  String get themeTaglineRealLife => 'Warm ivory, forest and apricot.';

  @override
  String get themeTaglineRealLifeNight => 'Forest, soft mint and candlelight.';

  @override
  String get themeTaglineDaylight =>
      'Cream, ink and a raspberry accent, like the website.';

  @override
  String get themeTaglineEmber =>
      'Plum-black night with ember and violet glow.';

  @override
  String get themeTaglineForge => 'Furnace red, steel blue, gunmetal chrome.';

  @override
  String get themeTaglineNeongrid =>
      'Black glass, cyan light-lines, amber pulse.';

  @override
  String get themeTaglineCrimsonalloy =>
      'Crimson lacquer, molten gold, midnight maroon.';

  @override
  String get themeTaglineCircuit =>
      'Circuit green, signal violet, carbon black.';

  @override
  String get themeTaglineDeepfield =>
      'Deep space, plasma blue and a flash of starlight gold.';

  @override
  String get themeTaglineLove => 'Blush, rose and a little gold.';

  @override
  String get themeTaglineRose => 'Velvet wine, rose red and a little gold.';

  @override
  String get themeTaglinePetal =>
      'Blush paper, drifting petals, a hint of sage.';

  @override
  String get themeTaglineSnow =>
      'Fresh snowfall, frosted glass and a ribbon of aurora.';

  @override
  String get themeTaglineGothic =>
      'Moonlit tracery, garnet, candle smoke and antique gold.';

  @override
  String get themeTaglineCalm =>
      'Low stimulation, high contrast. Still backdrop, no motion.';

  @override
  String get themeLooksTodayDescription =>
      'Warm ivory and forest by day. Soft mint and deep forest by night.';

  @override
  String get settingsEyebrow => 'SETTINGS';

  @override
  String get settingsHeaderSubtitle =>
      'Your look, your privacy and your account.';

  @override
  String get settingsThemeSection => 'Theme';

  @override
  String get settingsThemeSectionTitle => 'Make it yours';

  @override
  String get settingsThemeSectionCaption =>
      'Every screen follows the look you choose.';

  @override
  String get settingsSectionYourStory => 'Your story';

  @override
  String get settingsDatingRhythmTitle => 'Your dating rhythm';

  @override
  String get settingsDatingRhythmSubtitle =>
      'Intent, pace, availability and introduction privacy';

  @override
  String get settingsProfileStoriesTitle => 'Your profile stories';

  @override
  String get settingsProfileStoriesSubtitle =>
      'Small moments, your words, optional photos';

  @override
  String get settingsBlogTitle => 'Blog · Open Chapters';

  @override
  String get settingsBlogSubtitle =>
      'Your journal, your photos, your choice of audience';

  @override
  String get settingsLookPreviewEyebrow => 'TODAY';

  @override
  String get settingsLookPreviewHeadline => 'Something real.';

  @override
  String get friendsEyebrow => 'FRIENDS';

  @override
  String get friendsTitle => 'Your people';

  @override
  String get friendsSubtitle =>
      'Friends can message, plan and make groups together. Requests need a yes from both sides.';

  @override
  String get friendsBack => 'Back';

  @override
  String get friendsAddFriend => 'Add friend';

  @override
  String get friendsCreateGroup => 'Create a group';

  @override
  String get friendsSectionRequests => 'REQUESTS';

  @override
  String get friendsRequestsWaitingOnOthers => 'Waiting on others';

  @override
  String get friendsRequestsWaitingOnYou => 'Waiting on you';

  @override
  String get friendsRequestsCaption =>
      'Nothing is shared until both of you agree.';

  @override
  String get friendsSectionChats => 'CHATS';

  @override
  String get friendsChatsTitle => 'Conversations';

  @override
  String get friendsSectionIntros => 'INTROS';

  @override
  String get friendsIntrosTitle => 'Intros for you';

  @override
  String get friendsSectionVouches => 'VOUCHES';

  @override
  String get friendsVouchesPendingTitle => 'Vouches waiting for your approval';

  @override
  String friendsCountTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count friends',
      one: '1 friend',
      zero: 'No friends yet',
    );
    return '$_temp0';
  }

  @override
  String get friendsIntroduce => 'Introduce';

  @override
  String get friendsEmptyBody =>
      'Find people you know by name or username, or add someone from a match, a room or a group.';

  @override
  String get friendsSectionOnProfile => 'ON YOUR PROFILE';

  @override
  String get friendsVouchesOnProfileTitle => 'Vouches on your profile';

  @override
  String friendsQuoted(String text) {
    return '“$text”';
  }

  @override
  String friendsVouchedForYou(String name) {
    return '$name vouched for you';
  }

  @override
  String get friendsHideFromProfile => 'Hide from profile';

  @override
  String get friendsSectionMore => 'MORE';

  @override
  String get friendsMoreTitle => 'Plans and introductions';

  @override
  String get friendsPlansLinkTitle => 'Date plans shared with you';

  @override
  String get friendsPlansLinkSubtitle =>
      'Friends tell you when they plan a date and when they check in afterwards.';

  @override
  String get friendsInviteIntroducerTitle => 'Invite a friend who isn’t dating';

  @override
  String get friendsInviteIntroducerSubtitle =>
      'Choose who can introduce you. Review or withdraw permission anytime.';

  @override
  String get friendsIntroTermsTitle => 'Introductions, on your terms';

  @override
  String get friendsIntroTermsSubtitle =>
      'Choose whether friends can introduce you and what a preview shares.';

  @override
  String get friendsSectionActivity => 'ACTIVITY';

  @override
  String get friendsActivityTitle => 'With your friends';

  @override
  String friendsVouchSentSnack(String name) {
    return 'Vouch sent. $name approves it before it shows.';
  }

  @override
  String friendsRemoveTitle(String name) {
    return 'Remove $name?';
  }

  @override
  String get friendsRemoveBody =>
      'You’ll stop being friends and your friend chat closes. They aren’t told.';

  @override
  String get friendsRemoveFriend => 'Remove friend';

  @override
  String get friendsIntroMadeSnack =>
      'Intro made. Both friends will hear from you.';

  @override
  String get friendsAddSheetLabel => 'ADD FRIEND';

  @override
  String get friendsAddSheetTitle => 'Find someone you know';

  @override
  String get friendsAddSheetCaption =>
      'Search by name or @username. They choose whether to accept.';

  @override
  String get friendsSearchHiddenNote =>
      'You’re hidden from friend search, so others can’t find you here. Change this in Privacy & Safety.';

  @override
  String get friendsSearchLabel => 'Name or @username';

  @override
  String get friendsSearchHelper => 'Type at least 3 letters';

  @override
  String get friendsSearchFailed =>
      'Search is unavailable right now. Try again.';

  @override
  String friendsSearchNoResults(String query) {
    return 'No one found for “$query”.';
  }

  @override
  String get friendsNewGroupLabel => 'NEW GROUP';

  @override
  String get friendsNewGroupTitle => 'Who’s in?';

  @override
  String get friendsNewGroupCaption =>
      'Choose friends to invite. You can add more later.';

  @override
  String get friendsChooseFriends => 'Choose friends';

  @override
  String friendsCreateGroupWith(int count) {
    return 'Create a group with $count';
  }

  @override
  String get friendsSourceMatch => 'From your matches';

  @override
  String get friendsSourceProfile => 'Saw your profile';

  @override
  String get friendsSourceRoom => 'Met in a room';

  @override
  String get friendsSourceGroup => 'From a group';

  @override
  String get friendsSourceSearch => 'Found you by name';

  @override
  String get friendsWantsToBeFriends => 'Wants to be friends';

  @override
  String get friendsRequestSent => 'Request sent';

  @override
  String get friendsCancel => 'Cancel';

  @override
  String get friendsDecline => 'Decline';

  @override
  String get friendsAccept => 'Accept';

  @override
  String friendsMessageTooltip(String name) {
    return 'Message $name';
  }

  @override
  String friendsMessageTooltipUnread(String name, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Message $name, $count unread',
    );
    return '$_temp0';
  }

  @override
  String friendsMoreFor(String name) {
    return 'More for $name';
  }

  @override
  String get friendsMenuVouch => 'Vouch for them';

  @override
  String get friendsMenuIntro => 'Introduce to a friend';

  @override
  String friendsChatSemantics(String name, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Chat with $name, $count unread',
      zero: 'Chat with $name',
    );
    return '$_temp0';
  }

  @override
  String friendsChatSemanticsMuted(String name, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Chat with $name, $count unread, notifications muted',
      zero: 'Chat with $name, notifications muted',
    );
    return '$_temp0';
  }

  @override
  String friendsIntroHeadline(String introducer, String person) {
    return '$introducer thinks you should meet $person';
  }

  @override
  String friendsIntroHeadlineSomeone(String introducer) {
    return '$introducer thinks you should meet someone';
  }

  @override
  String friendsNameAge(String name, int age) {
    return '$name, $age';
  }

  @override
  String get friendsIntroNoThanks => 'No thanks';

  @override
  String get friendsIntroImIn => 'I\'m in';

  @override
  String get friendsVouchKeepPrivate => 'Keep private';

  @override
  String get friendsVouchShowOnProfile => 'Show on my profile';

  @override
  String get memberProfileNoData => 'No profile data found.';

  @override
  String get memberProfileSignInToView => 'Please login to view your profile.';

  @override
  String get memberProfileLoadFailed =>
      'Failed to load profile. Please try again.';

  @override
  String get memberProfileConnectionsTitle => 'Your connections';

  @override
  String get memberProfileConnectionsCaption =>
      'People you liked, matched and talk to.';

  @override
  String get memberProfileStatLiked => 'You liked';

  @override
  String get memberProfileStatMatches => 'Matches';

  @override
  String get memberProfileStatMessages => 'Messages';

  @override
  String memberProfileOpenStat(String label) {
    return 'Open $label';
  }

  @override
  String get memberProfileNoticedTitle => 'Who has noticed';

  @override
  String get memberProfileNoticedCaption =>
      'Likes and views from members near you.';

  @override
  String get memberProfileWhoLikedMe => 'Who Liked Me';

  @override
  String memberProfileWhoLikedMeCount(int count) {
    return 'Who Liked Me ($count)';
  }

  @override
  String get memberProfileWhoLikedMeSubtitle =>
      'Members who liked your profile.';

  @override
  String get memberProfileWhoViewedTitle => 'Who Viewed My Profile';

  @override
  String get memberProfileWhoViewedSubtitle => 'Recent visits to your profile.';

  @override
  String get memberProfileWhoViewedTooltip => 'Who viewed my profile';

  @override
  String get memberProfileRefreshTooltip => 'Refresh profile';

  @override
  String get memberProfilePreferencesTitle => 'Your preferences';

  @override
  String get memberProfilePrefSeeking => 'Seeking';

  @override
  String get memberProfilePrefDistance => 'Distance';

  @override
  String memberProfileWithinKm(int km) {
    return 'Within $km km';
  }

  @override
  String get profileViewersTitle => 'Viewed My Profile';

  @override
  String get profileViewersLoadFailed => 'Failed to load profile viewers.';

  @override
  String get profileViewersEmpty => 'No one has viewed your profile yet.';

  @override
  String get profileViewersViewedRecently => 'Viewed recently';

  @override
  String profileViewersViewedAt(String time) {
    return 'Viewed at $time';
  }

  @override
  String get profileMasterReligionParsi => 'Parsi';

  @override
  String get profileMasterReligionBahai => 'Bahai';

  @override
  String get profileMasterReligionTribal => 'Tribal / Indigenous';

  @override
  String get profileMasterWorkout1to2 => '1-2 times a week';

  @override
  String get profileMasterWorkout3to4 => '3-4 times a week';

  @override
  String get profileMasterWorkout5Plus => '5+ times a week';

  @override
  String get profileMasterWorkoutDaily => 'Daily';

  @override
  String get profileMasterDietNoPreference => 'No preference';

  @override
  String get profileMasterDietVegetarian => 'Vegetarian';

  @override
  String get profileMasterDietEggetarian => 'Eggetarian';

  @override
  String get profileMasterDietNonVegetarian => 'Non-vegetarian';

  @override
  String get profileMasterDietVegan => 'Vegan';

  @override
  String get profileMasterDietJain => 'Jain';

  @override
  String get profileMasterDietTypeBalanced => 'Balanced';

  @override
  String get profileMasterDietTypeHighProtein => 'High Protein';

  @override
  String get profileMasterDietTypeLowCarb => 'Low Carb';

  @override
  String get profileMasterDietTypeKeto => 'Keto';

  @override
  String get profileMasterDietTypeMediterranean => 'Mediterranean';

  @override
  String get profileMasterDietTypeIntermittentFasting => 'Intermittent Fasting';

  @override
  String get profileMasterSleepEarlyBird => 'Early bird';

  @override
  String get profileMasterSleepNightOwl => 'Night owl';

  @override
  String get profileMasterSleepFlexible => 'Flexible';

  @override
  String get profileMasterSleepShiftBased => 'Shift based';

  @override
  String get profileMasterTravelHomebody => 'Homebody';

  @override
  String get profileMasterTravelOccasional => 'Occasional traveler';

  @override
  String get profileMasterTravelFrequent => 'Frequent traveler';

  @override
  String get profileMasterTravelAdventure => 'Adventure seeker';

  @override
  String get profileMasterTravelLuxury => 'Luxury traveler';

  @override
  String get profileMasterTravelBackpacker => 'Backpacker';

  @override
  String get profileMasterPoliticsSimilar => 'Similar views only';

  @override
  String get profileMasterPoliticsOpen => 'Open to differences';

  @override
  String get profileMasterPoliticsNotDiscuss => 'Prefer not to discuss';

  @override
  String get profileMasterPoliticsNoStrong => 'No strong preference';

  @override
  String get profileMasterIntentLongTerm => 'Long term';

  @override
  String get profileMasterIntentMarriage => 'Marriage';

  @override
  String get profileMasterIntentNewFriends => 'New friends';

  @override
  String get chatBackToConversations => 'Back to conversations';

  @override
  String get chatOfflineBanner =>
      'You’re offline. Your draft will stay here while you reconnect.';

  @override
  String get chatVoiceHello => 'Share a voice hello · read & listen';

  @override
  String get chatLoadFailedTitle => 'Let’s reconnect.';

  @override
  String get chatLoadFailedBody =>
      'Your conversation couldn’t load. Try again.';

  @override
  String get chatConversationEnded => 'This conversation has ended.';

  @override
  String get chatUnlockStepRequired =>
      'Complete the current unlock step to continue this conversation.';

  @override
  String get chatGiftTrayTitle => 'A little something for them';

  @override
  String get chatCloseGifts => 'Close gifts';

  @override
  String get chatAllGifts => 'All gifts';

  @override
  String get chatNoGiftsInCollection =>
      'No gifts available in this collection.';

  @override
  String get chatAddCoins => 'Add coins';

  @override
  String get chatFreeGiftDaily => 'Free · 1 a day';

  @override
  String chatCoinCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count coins',
      one: '1 coin',
    );
    return '$_temp0';
  }

  @override
  String get chatSendingGift => 'Sending your gift…';

  @override
  String get chatOfflineGifts =>
      'You\'re offline. You can browse gifts and send once you reconnect.';

  @override
  String chatGiftConfirmTitle(String gift, String name) {
    return 'Send $gift to $name?';
  }

  @override
  String chatGiftNoteQuote(String note) {
    return '“$note”';
  }

  @override
  String chatGiftBalanceAfter(int balance, int remaining) {
    return '·  $balance → $remaining left';
  }

  @override
  String get chatGiftNoObligation =>
      'A gift is a gesture, never an obligation to reply or meet.';

  @override
  String chatGiftSendFor(String price) {
    return 'Send for $price';
  }

  @override
  String get chatNotNow => 'Not now';

  @override
  String get chatDeleteMessageTitle => 'Delete message?';

  @override
  String get chatDeleteMessageBody =>
      'This removes the message from both chat inboxes.';

  @override
  String get chatDeleteForEveryone => 'Delete for everyone';

  @override
  String get chatMessageDeletedSnack => 'Message deleted.';

  @override
  String get chatUndo => 'Undo';

  @override
  String get chatDeleteUndone => 'Delete undone.';

  @override
  String chatGiftReceivedFrom(String name) {
    return 'Gift received from $name';
  }

  @override
  String get chatGiftReceiverIntro => 'You decide what stays in your chat.';

  @override
  String get chatHideGift => 'Hide gift';

  @override
  String get chatHideGiftSubtitle => 'Remove it from your chat only.';

  @override
  String get chatReportAndHide => 'Report and hide';

  @override
  String get chatReportAndHideSubtitle =>
      'Send it to the safety team and remove it now.';

  @override
  String get chatGiftHidden => 'Gift hidden from your chat.';

  @override
  String get chatReportGiftTitle => 'Report this gift';

  @override
  String get chatReportGiftIntro =>
      'Choose a reason. The gift will be hidden immediately.';

  @override
  String get chatReportReasonLabel => 'Reason';

  @override
  String get chatReportReasonUnwanted => 'Unwanted gift';

  @override
  String get chatReportReasonHarassment => 'Harassment';

  @override
  String get chatReportReasonSexual => 'Sexual content';

  @override
  String get chatReportReasonScam => 'Scam or fraud';

  @override
  String get chatReportReasonOther => 'Something else';

  @override
  String get chatReportDetailsLabel => 'Add details (optional)';

  @override
  String get chatReportSubmit => 'Submit report and hide';

  @override
  String get chatGiftReported =>
      'Gift reported and hidden. Our safety team will review it.';

  @override
  String get chatQuickEmojis => 'Quick emojis';

  @override
  String chatWalletTooltip(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count coins',
      one: '1 coin',
    );
    return 'Your wallet · $_temp0';
  }

  @override
  String get chatDailyLimitReached => 'Daily message limit reached';

  @override
  String get chatDailyLimitFallback =>
      'Try again tomorrow or upgrade your plan.';

  @override
  String chatDailyLimitReset(String reset) {
    return '$reset · upgrade for more.';
  }

  @override
  String get chatSeePlans => 'See plans';

  @override
  String chatQuotaOnPlan(String quota, String plan) {
    return '$quota on $plan';
  }

  @override
  String get chatYourConversation => 'Your conversation';

  @override
  String get chatVerifiedHumans => 'Verified humans';

  @override
  String get chatVerifiedHumansShowsUp => 'Verified humans · Shows up';

  @override
  String discoverLikedBack(String name) {
    return 'You liked $name back';
  }

  @override
  String discoverPassedOn(String name) {
    return 'Passed on $name';
  }

  @override
  String get discoverLikedMeLoadFailedTitle => 'Could not load your likes';

  @override
  String get discoverLikedMeEmptyTitle => 'No new likes yet';

  @override
  String get discoverLikedMeEmptyBody =>
      'When someone likes you, they show up here. Like them back and it\'s a match.';

  @override
  String get discoverLikedMeIntro =>
      'They already like you. Like back to match, or pass. Passing is private.';

  @override
  String get discoverLikedMeTitle => 'Liked you';

  @override
  String discoverLikedMeTitleCount(int count) {
    return 'Liked you · $count';
  }

  @override
  String get discoverPass => 'Pass';

  @override
  String get discoverLikeBack => 'Like back';

  @override
  String get discoverLikedJustNow => 'Liked you just now';

  @override
  String discoverLikedMinutesAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Liked you $count minutes ago',
      one: 'Liked you 1 minute ago',
    );
    return '$_temp0';
  }

  @override
  String discoverLikedHoursAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Liked you $count hours ago',
      one: 'Liked you 1 hour ago',
    );
    return '$_temp0';
  }

  @override
  String discoverLikedDaysAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Liked you $count days ago',
      one: 'Liked you 1 day ago',
    );
    return '$_temp0';
  }

  @override
  String discoverLikedWeeksAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Liked you $count weeks ago',
      one: 'Liked you 1 week ago',
    );
    return '$_temp0';
  }

  @override
  String discoverLikedOnDate(String date) {
    return 'Liked you on $date';
  }

  @override
  String discoverLikedProfilesTitle(int count) {
    return 'Liked Profiles ($count)';
  }

  @override
  String get discoverNoLikedProfiles => 'No liked profiles yet';

  @override
  String get discoverLikedProfileFallback => 'Liked profile';

  @override
  String get discoverPassedProfilesTitle => 'Passed Profiles';

  @override
  String get discoverNoPassedProfiles => 'No passed profiles yet';

  @override
  String get discoverSavedForLater => 'Saved for later';

  @override
  String get discoverSpotlightFiltersTitle => 'Spotlight Filters';

  @override
  String get discoverVerifiedOnly => 'Verified only';

  @override
  String discoverAgeRange(int min, int max) {
    return 'Age range: $min - $max';
  }

  @override
  String get discoverSpotlightTitle => 'Spotlight Matches';

  @override
  String get discoverSpotlightSubtitle => 'Curated premium connections';

  @override
  String discoverPassedCount(int count) {
    return 'Passed ($count)';
  }

  @override
  String get discoverOpenChatsFromDiscover => 'Open chats from Discover';

  @override
  String get discoverNoNewNotifications => 'No new notifications';

  @override
  String get discoverNoSpotlightMatchFilters =>
      'No spotlight profiles match filters';

  @override
  String get discoverAllSpotlightReviewed => 'All spotlight profiles reviewed!';

  @override
  String get discoverSpotlightCheckBackLater =>
      'Check back later for new spotlight profiles';

  @override
  String get discoverReportSubmitted => 'Report submitted.';

  @override
  String get discoverAppeal => 'Appeal';

  @override
  String discoverAppealPrefill(String userId) {
    return 'Review moderation outcome for report on user $userId';
  }

  @override
  String get discoverProfileUnavailable =>
      'This profile is unavailable right now.';

  @override
  String get discoverGoBack => 'Go back';

  @override
  String get discoverPremiumView => 'Premium view';

  @override
  String get todayLabel => 'TODAY';

  @override
  String get todayRefreshTooltip => 'Refresh Today';

  @override
  String get todayDiscoveryPreferences => 'Discovery preferences';

  @override
  String get todayHeroTitle => 'A little hello.\nRoom for something real.';

  @override
  String get todayHeroSubtitle =>
      'A few thoughtful introductions, at your pace.';

  @override
  String get todaySectionPace => 'YOUR PACE';

  @override
  String get todayPaceTitle => 'What fits your week?';

  @override
  String get todayPaceBody =>
      'Your pace, your kind of first date, optional availability.';

  @override
  String get todaySetRhythm => 'Set your rhythm';

  @override
  String get todaySectionStory => 'YOUR STORY';

  @override
  String get todaySectionIntroductions => 'TODAY’S INTRODUCTIONS';

  @override
  String get todayIntroductionsTitle => 'A few people to get to know';

  @override
  String get todayIntroductionsCaption =>
      'Shared interests are a starting point. Chemistry is yours to discover.';

  @override
  String get todayPausedTitle => 'Take the time you need.';

  @override
  String get todayPausedBody =>
      'Introductions are paused. Your conversations are still here.';

  @override
  String get todayManageRhythm => 'Manage your rhythm';

  @override
  String get todayLoadingIntroductions => 'Loading introductions';

  @override
  String get todayFailedTitle => 'Your introductions are taking a moment.';

  @override
  String get todayFailedBody =>
      'We couldn’t load the latest information. Please try again.';

  @override
  String get todayTryAgain => 'Try again';

  @override
  String get todayEmptyTitle => 'A little breathing room.';

  @override
  String get todayEmptyBody =>
      'There are no new introductions for your preferences right now. You can adjust your rhythm or explore profiles.';

  @override
  String get todayExploreProfiles => 'Explore profiles';

  @override
  String get todayAllIntroductions => 'All introductions';

  @override
  String get todayBreatheTitle => 'A good connection has room to breathe.';

  @override
  String get todayBreatheBody =>
      'These are today’s introductions. There is no countdown, and no need to decide on everyone.';

  @override
  String get todayExploreMore => 'Explore more profiles';

  @override
  String get todayCommonGround => 'A LITTLE COMMON GROUND';

  @override
  String todayMeetName(String name) {
    return 'Meet $name';
  }

  @override
  String get todayFirstHelloCoffee =>
      'A first hello could be a coffee together.';

  @override
  String get todayFirstHelloWalk => 'A first hello could be a daytime walk.';

  @override
  String get todayFirstHelloMeal => 'A first hello could be a relaxed meal.';

  @override
  String get todayFirstHelloVideoCall =>
      'A first hello could be a video hello.';

  @override
  String get todayFirstHelloEvent =>
      'A first hello could be an event you both enjoy.';

  @override
  String get todayFirstHelloDrinks =>
      'A first hello could be a drink together.';

  @override
  String get todayFirstHelloOther =>
      'A first hello could be something you both enjoy.';

  @override
  String get todaySectionTalk => 'SOMETHING TO TALK ABOUT';

  @override
  String get todayTalkCaption =>
      'Stories, clubs and prompts that make a first hello easier.';

  @override
  String get todayBlogTitle => 'Blog · Open Chapters';

  @override
  String get todayBlogSubtitle => 'Read members’ stories and write your own.';

  @override
  String get todayBookClubsTitle => 'Book clubs';

  @override
  String get todayBookClubsSubtitle => 'One book a week, talked over together.';

  @override
  String get todayFilmClubsTitle => 'Film clubs';

  @override
  String get todayFilmClubsSubtitle => 'Watch the pick, then swap takes.';

  @override
  String get todayPhotoThemesTitle => 'Photo Themes';

  @override
  String get todayPhotoThemesSubtitle =>
      'One photo per prompt. See everyone’s.';

  @override
  String get todayChapterStudioTitle => 'First Chapter Studio';

  @override
  String get todayChapterStudioSubtitle => 'Begin a story together.';

  @override
  String get todayCoverFallbackLine => 'A photo members loved';

  @override
  String todayCoverSemantics(String name) {
    return 'Open the Cover of the Week by $name';
  }

  @override
  String get todayCoverTitle => 'COVER OF THE WEEK';

  @override
  String todayCoverBy(String name) {
    return 'BY $name';
  }

  @override
  String get todayLikes => 'Likes';

  @override
  String get todayComments => 'Comments';

  @override
  String get todayThisWeek => 'This week';

  @override
  String get todayWallLabel => 'FROM THE COMMUNITY';

  @override
  String get todayWallTitle => 'Today’s wall';

  @override
  String get todayWallCaption =>
      'Stories and photos members loved — new picks every day';

  @override
  String get todayWallPrevious => 'Previous pick';

  @override
  String get todayWallNext => 'Next pick';

  @override
  String get todayWallChapter => 'CHAPTER';

  @override
  String get todayWallUntitled => 'An untitled chapter';

  @override
  String todayWallBy(String name) {
    return 'by $name';
  }

  @override
  String get todayWallEmpty =>
      'Your wall fills up as members share stories and photos they love';

  @override
  String get todayWallWrite => 'Write a chapter';

  @override
  String get todayWallShare => 'Share a photo';

  @override
  String get profileSetupBackTooltip => 'Back';

  @override
  String profileSetupStepCounter(int current, int total) {
    return 'Step $current of $total';
  }

  @override
  String get profileSetupLoadErrorTitle => 'Could not load profile data.';

  @override
  String get profileSetupRetry => 'Retry';

  @override
  String get profileSetupEducationHighSchool => 'High School';

  @override
  String get profileSetupEducationBachelors => 'Bachelor\'s';

  @override
  String get profileSetupEducationMasters => 'Master\'s';

  @override
  String get profileSetupEducationPhd => 'PhD';

  @override
  String get profileSetupEducationOther => 'Other';

  @override
  String get profileSetupPreferNotToSay => 'Prefer not to say';

  @override
  String profileSetupIncomeBelow(String amount) {
    return 'Below $amount';
  }

  @override
  String get profileSetupFrequencyNever => 'Never';

  @override
  String get profileSetupFrequencySocially => 'Socially';

  @override
  String get profileSetupFrequencyOccasionally => 'Occasionally';

  @override
  String get profileSetupFrequencyRegularly => 'Regularly';

  @override
  String get profileSetupGenderMan => 'Man';

  @override
  String get profileSetupGenderWoman => 'Woman';

  @override
  String get profileSetupGenderOther => 'Other';

  @override
  String profileSetupBioTooShort(int min) {
    String _temp0 = intl.Intl.pluralLogic(
      min,
      locale: localeName,
      other: 'Bio must be at least $min characters.',
      one: 'Bio must be at least 1 character.',
    );
    return '$_temp0';
  }

  @override
  String get profileSetupSaveFailed => 'Failed to save — please try again.';

  @override
  String get profileSetupCouldNotSaveChanges =>
      'Could not save your changes. Please try again.';

  @override
  String get profileSetupAboutTitle => 'Make your profile shine';

  @override
  String get profileSetupAboutSubtitle =>
      'These details help find better matches.';

  @override
  String get profileSetupBioLabel => 'Bio';

  @override
  String profileSetupBioHint(int min) {
    String _temp0 = intl.Intl.pluralLogic(
      min,
      locale: localeName,
      other: 'Tell people about you (min $min chars)',
      one: 'Tell people about you (min 1 char)',
    );
    return '$_temp0';
  }

  @override
  String get profileSetupHeightLabel => 'Height (cm)';

  @override
  String get profileSetupHeightHint => 'Select height';

  @override
  String profileSetupHeightValue(int cm) {
    return '$cm cm';
  }

  @override
  String get profileSetupEducationLabel => 'Education';

  @override
  String get profileSetupEducationHint => 'Select education';

  @override
  String get profileSetupProfessionLabel => 'Profession';

  @override
  String get profileSetupProfessionHint => 'e.g. Software Engineer';

  @override
  String get profileSetupIncomeLabel => 'Income (optional)';

  @override
  String get profileSetupLifestyleTitle => 'Lifestyle';

  @override
  String get profileSetupDrinkingLabel => 'Drinking';

  @override
  String get profileSetupSmokingLabel => 'Smoking';

  @override
  String get profileSetupSelectHint => 'Select';

  @override
  String get profileSetupReligionOptionalLabel => 'Religion (optional)';

  @override
  String get profileSetupContinue => 'Continue';

  @override
  String get profileSetupSaveAbout => 'Save About';

  @override
  String get profileSetupPhotosSaved => 'Photos saved.';

  @override
  String profileSetupPhotosMaxReached(int max) {
    String _temp0 = intl.Intl.pluralLogic(
      max,
      locale: localeName,
      other: 'You can upload up to $max photos only.',
      one: 'You can upload up to 1 photo only.',
    );
    return '$_temp0';
  }

  @override
  String get profileSetupRemovePhotoTitle => 'Remove this photo?';

  @override
  String get profileSetupRemovePhotoBody =>
      'It will be removed from your profile and deleted from storage.';

  @override
  String get profileSetupCancel => 'Cancel';

  @override
  String get profileSetupRemove => 'Remove';

  @override
  String profileSetupPhotosMinRequired(int min) {
    String _temp0 = intl.Intl.pluralLogic(
      min,
      locale: localeName,
      other: 'Please upload at least $min photos to continue.',
      one: 'Please upload at least 1 photo to continue.',
    );
    return '$_temp0';
  }

  @override
  String get profileSetupPhotosTitle => 'Add your photos';

  @override
  String profileSetupPhotosSubtitle(int min) {
    String _temp0 = intl.Intl.pluralLogic(
      min,
      locale: localeName,
      other: 'Add at least $min photos to get matches',
      one: 'Add at least 1 photo to get matches',
    );
    return '$_temp0';
  }

  @override
  String get profileSetupChooseSource => 'Choose source';

  @override
  String get profileSetupGallery => 'Gallery';

  @override
  String get profileSetupCamera => 'Camera';

  @override
  String get profileSetupPhotoRequirements =>
      'JPEG, PNG, WebP or HEIC · 300×300 minimum · 10 MB each · 50 MB total';

  @override
  String profileSetupPhotosTipEmpty(int min) {
    String _temp0 = intl.Intl.pluralLogic(
      min,
      locale: localeName,
      other: 'Add at least $min photos to show different sides of you.',
      one: 'Add at least 1 photo to show different sides of you.',
    );
    return '$_temp0';
  }

  @override
  String profileSetupPhotosTipMore(int count) {
    return 'Add $count more photo(s) to unlock full matching.';
  }

  @override
  String get profileSetupPhotosTipDone =>
      'Great! You can reorder photos by dragging.';

  @override
  String get profileSetupYourPhotosHeading => 'Your photos  •  drag to reorder';

  @override
  String get profileSetupContinueToAbout => 'Continue to About';

  @override
  String get profileSetupSavePhotos => 'Save Photos';

  @override
  String get profileSetupPrimaryPhoto => 'Primary photo';

  @override
  String profileSetupPhotoNumber(int number) {
    return 'Photo $number';
  }

  @override
  String get profileSetupShownFirst => 'Shown first on your profile';

  @override
  String get profileSetupDragHandleHint => 'Drag handle to reorder';

  @override
  String get profileSetupAwaitingSafetyReview => 'Awaiting safety review';

  @override
  String get profileSetupSafetyCheckInProgress => 'Safety check in progress';

  @override
  String get profileSetupSetAsProfilePicture => 'Set as profile picture';

  @override
  String get profileSetupProfilePictureSelected => 'Profile picture selected';

  @override
  String get profileSetupRemovePhotoTooltip => 'Remove photo';

  @override
  String get profileSetupPhotoTooLarge =>
      'This photo is larger than the 10 MB limit.';

  @override
  String get profileSetupPhotoUnsupportedType =>
      'Use a JPEG, PNG, WebP, or HEIC photo.';

  @override
  String get profileSetupPhotoBadDimensions =>
      'Photo dimensions must be between 300×300 and 4096×4096.';

  @override
  String get profileSetupPhotoQuotaReached =>
      'Your profile photo quota has been reached.';

  @override
  String get profileSetupPhotoStorageFull =>
      'Photo storage is temporarily full. Please try again later.';

  @override
  String get profileSetupPhotoUpdateFailed =>
      'Photo update failed. Please try again.';

  @override
  String profileSetupPhotoMaxAllowed(int max) {
    String _temp0 = intl.Intl.pluralLogic(
      max,
      locale: localeName,
      other: 'Maximum $max photos are allowed.',
      one: 'Maximum 1 photo is allowed.',
    );
    return '$_temp0';
  }

  @override
  String get profileSetupPreferencesLoadFailed => 'Failed to load preferences';

  @override
  String get profileSetupOfflineBanner =>
      'Offline mode — some data may be outdated.';

  @override
  String get profileSetupYourPreferences => 'Your Preferences';

  @override
  String get profileSetupEditPreferencesTitle => 'Edit Preferences';

  @override
  String get profileSetupFinishAndFindMatches => 'Finish & Find Matches';

  @override
  String get profileSetupSavePreferences => 'Save Preferences';

  @override
  String get profileSetupSelectGenderPreference =>
      'Select at least one gender preference.';

  @override
  String get profileSetupFinishFailed =>
      'Could not finish setup. Please check your photos and preferences, then try again.';

  @override
  String get profileSetupPreferencesSaveFailed =>
      'Some preferences could not be saved right now.';

  @override
  String get profileSetupPreferencesSaved => 'Preferences saved.';

  @override
  String get profileSetupTabBasic => 'Basic';

  @override
  String get profileSetupTabAdvanced => 'Advanced';

  @override
  String get profileSetupLookingFor => 'I\'m looking for';

  @override
  String get profileSetupSeekingMen => 'Men';

  @override
  String get profileSetupSeekingWomen => 'Women';

  @override
  String get profileSetupSeekingOther => 'Other';

  @override
  String profileSetupAgeRangeTitle(int min, int max) {
    return 'Age range: $min – $max';
  }

  @override
  String profileSetupMaxDistanceTitle(int km) {
    return 'Max distance: $km km';
  }

  @override
  String profileSetupDistanceValue(int km) {
    return '$km km';
  }

  @override
  String get profileSetupRelationshipIntent => 'Relationship intent';

  @override
  String get profileSetupSeriousOnly => 'Serious relationship only';

  @override
  String get profileSetupSeriousOnlySubtitle =>
      'Show only users seeking commitment';

  @override
  String get profileSetupVerifiedOnly => 'Verified profiles only';

  @override
  String get profileSetupVerifiedOnlySubtitle =>
      'Filter to ID-verified accounts';

  @override
  String get profileSetupHookupsOnly => 'Hookups only';

  @override
  String get profileSetupHookupsOnlySubtitle => 'Show casual-only profiles';

  @override
  String get profileSetupLocation => 'Location';

  @override
  String get profileSetupCountry => 'Country';

  @override
  String get profileSetupStateRegion => 'State / Region';

  @override
  String get profileSetupCity => 'City';

  @override
  String get profileSetupBackgroundCulture => 'Background & culture';

  @override
  String get profileSetupReligionPreference => 'Religion preference';

  @override
  String get profileSetupMotherTongue => 'Mother tongue';

  @override
  String get profileSetupLanguage => 'Language';

  @override
  String get profileSetupDietPreference => 'Diet preference';

  @override
  String get profileSetupWorkoutFrequency => 'Workout frequency';

  @override
  String get profileSetupDietType => 'Diet type';

  @override
  String get profileSetupSleepSchedule => 'Sleep schedule';

  @override
  String get profileSetupTravelStyle => 'Travel style';

  @override
  String get profileSetupPoliticalComfortRange => 'Political comfort range';

  @override
  String get profileSetupInterestsPersonality => 'Interests & personality';

  @override
  String get profileSetupInstagramHandle => 'Instagram handle (without @)';

  @override
  String get profileSetupIntentTags =>
      'Intent tags (long-term, marriage, casual…)';

  @override
  String get profileSetupHobbiesField => 'Hobbies (comma-separated)';

  @override
  String get profileSetupFavouriteBooksField =>
      'Favourite books (comma-separated)';

  @override
  String get profileSetupFavouriteNovelsField =>
      'Favourite novels (comma-separated)';

  @override
  String get profileSetupFavouriteSongsField =>
      'Favourite songs (comma-separated)';

  @override
  String get profileSetupExtraCurricularField =>
      'Extra-curricular activities (comma-separated)';

  @override
  String get profileSetupAdditionalInformation => 'Additional information';

  @override
  String get profileSetupPetPreference => 'Pet preference';

  @override
  String get profileSetupDealBreakers => 'Deal-breakers';

  @override
  String get profileSetupTagsField => 'Tags (comma-separated)';

  @override
  String get profileSetupNameRequired => 'Name is required.';

  @override
  String get profileSetupDobRequired => 'Date of birth is required.';

  @override
  String profileSetupPhotosRequired(int min) {
    String _temp0 = intl.Intl.pluralLogic(
      min,
      locale: localeName,
      other: 'At least $min photos are required.',
      one: 'At least 1 photo is required.',
    );
    return '$_temp0';
  }

  @override
  String get profileSetupServerError => 'Server error';

  @override
  String get profileSetupNetworkError => 'Network error — please try again.';

  @override
  String get profileSetupGenericError =>
      'Something went wrong. Please try again.';

  @override
  String get profileSetupPreviewTitle => 'Preview your profile';

  @override
  String get profileSetupPreviewSubtitle => 'This is how others will see you.';

  @override
  String profileSetupNameAge(String name, int age) {
    return '$name, $age';
  }

  @override
  String profileSetupDrinksChip(String value) {
    return 'Drinks: $value';
  }

  @override
  String profileSetupSmokesChip(String value) {
    return 'Smokes: $value';
  }

  @override
  String get profileSetupCompleteProfile => 'Complete Profile';

  @override
  String profileSetupCompletionPercent(int percent) {
    return 'Profile completion: $percent%';
  }

  @override
  String get profileEditTitle => 'Edit Profile';

  @override
  String get profileEditRefreshTooltip => 'Refresh profile';

  @override
  String get profileEditAboutYou => 'About you';

  @override
  String get profileEditEditAbout => 'Edit about';

  @override
  String get profileEditName => 'Name';

  @override
  String get profileEditPhone => 'Phone';

  @override
  String get profileEditDateOfBirth => 'Date of birth';

  @override
  String get profileEditGender => 'Gender';

  @override
  String get profileEditHeight => 'Height';

  @override
  String get profileEditIncomeRange => 'Income range';

  @override
  String get profileEditLocationSocial => 'Location & social';

  @override
  String get profileEditEditPreferences => 'Edit preferences';

  @override
  String get profileEditState => 'State';

  @override
  String get profileEditInstagram => 'Instagram';

  @override
  String get profileEditDatingPreferences => 'Dating preferences';

  @override
  String get profileEditSeeking => 'Seeking';

  @override
  String get profileEditAgeRange => 'Age range';

  @override
  String profileEditAgeRangeValue(int min, int max) {
    return '$min–$max';
  }

  @override
  String get profileEditMaxDistance => 'Max distance';

  @override
  String get profileEditEducationFilter => 'Education filter';

  @override
  String get profileEditSeriousOnly => 'Serious only';

  @override
  String get profileEditVerifiedOnly => 'Verified only';

  @override
  String get profileEditHookupOnly => 'Hookup only';

  @override
  String get profileEditYes => 'Yes';

  @override
  String get profileEditNo => 'No';

  @override
  String get profileEditIntent => 'Intent';

  @override
  String get profileEditLanguages => 'Languages';

  @override
  String get profileEditDealBreakers => 'Deal breakers';

  @override
  String get profileEditReligion => 'Religion';

  @override
  String get profileEditPets => 'Pets';

  @override
  String get profileEditWorkout => 'Workout';

  @override
  String get profileEditPoliticsComfort => 'Politics comfort';

  @override
  String get profileEditInterestsDetails => 'Interests & details';

  @override
  String get profileEditHobbies => 'Hobbies';

  @override
  String get profileEditBooks => 'Books';

  @override
  String get profileEditNovels => 'Novels';

  @override
  String get profileEditSongs => 'Songs';

  @override
  String get profileEditExtraCurriculars => 'Extra curriculars';

  @override
  String get profileEditAdditionalInfo => 'Additional info';

  @override
  String get profileEditNotSet => 'Not set';

  @override
  String get profileEditLoadingTitle => 'Loading your saved profile';

  @override
  String get profileEditLoadingBody =>
      'Binding the information saved during account setup.';

  @override
  String get profileEditYourProfile => 'Your profile';

  @override
  String profileEditPercentComplete(int percent) {
    return '$percent% complete';
  }

  @override
  String get profileEditPhotoGallery => 'Photo gallery';

  @override
  String get profileEditManagePhotos => 'Manage photos';

  @override
  String get profileEditNoPhotos => 'No photos uploaded yet.';

  @override
  String get profileEditPrimaryBadge => 'Primary';

  @override
  String get engagementHubPromptLoading => 'Loading today\'s prompt';

  @override
  String get engagementHubPromptIntro =>
      'Answer one prompt daily and build your streak.';

  @override
  String engagementHubPromptRepliedToday(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count people replied today',
    );
    return '$_temp0';
  }

  @override
  String engagementHubPromptStreakSummary(int days, int similar) {
    return 'Streak ${days}d · $similar similar replies';
  }

  @override
  String get engagementHubBlogTitle => 'Blog · Open Chapters';

  @override
  String get engagementHubBlogSubtitle =>
      'Read stories, share photos and write your own.';

  @override
  String get engagementHubPhotoThemesTitle => 'Photo Themes';

  @override
  String get engagementHubPhotoThemesSubtitle =>
      'Share one photo per prompt and see everyone’s.';

  @override
  String get engagementHubClubsTitle => 'Book & Film Clubs';

  @override
  String get engagementHubClubsSubtitle =>
      'Follow a weekly pick, talk it over, rate it.';

  @override
  String get engagementHubCityPilotTitle => 'The City Pilot';

  @override
  String get engagementHubCityPilotSubtitle =>
      'A small community. Conversations that become plans.';

  @override
  String get engagementDailyPromptTitle => 'Daily Prompt Streak';

  @override
  String get engagementHubVoiceTitle => 'Guided Voice Icebreakers';

  @override
  String get engagementHubVoiceSubtitle =>
      'Send one guided 20-45s voice intro per match/day';

  @override
  String get engagementCirclesTitle => 'Local Circle Challenges';

  @override
  String get engagementHubCirclesSubtitle =>
      'Join a city circle and submit this week\'s entry';

  @override
  String get engagementHubCoffeeTitle => 'Group Coffee Poll';

  @override
  String get engagementHubCoffeeSubtitle =>
      'Create, vote, and finalize lightweight meetup polls';

  @override
  String get engagementHubGroupsTitle => 'Groups';

  @override
  String get engagementHubGroupsSubtitle =>
      'Lifestyle communities and private friend groups';

  @override
  String get engagementHubRoomsSubtitle =>
      'Live chat rooms: drop in, talk, make friends';

  @override
  String get engagementHubFriendsTitle => 'Friends & Introductions';

  @override
  String get engagementHubFriendsSubtitle =>
      'Invite a trusted friend, even if they aren’t dating';

  @override
  String get engagementLevelTitle => 'Level & XP';

  @override
  String get engagementHubLevelSubtitle =>
      'Track meaningful activity, level rewards, and trust gates';

  @override
  String get engagementHubPaywallFree => 'Core progression stays paywall-free.';

  @override
  String get engagementHubPolicyUpdating =>
      'Monetization policy is being updated.';

  @override
  String engagementHubPremiumAreas(String features) {
    return 'Optional premium areas: $features';
  }

  @override
  String get engagementHubEyebrow => 'ENGAGE';

  @override
  String get engagementHubTitle => 'Make something together.';

  @override
  String get engagementHubSubtitle =>
      'Build stronger matches with trust and shared activities.';

  @override
  String get engagementHubSectionCreate => 'CREATE & SHARE';

  @override
  String get engagementHubSectionCreateCaption =>
      'Stories, photos and clubs that start real conversations.';

  @override
  String get engagementHubSectionMeet => 'MEET PEOPLE';

  @override
  String get engagementHubSectionMeetCaption =>
      'Small groups, prompts and plans at your pace.';

  @override
  String get engagementHubSectionProgress => 'TRUST & PROGRESS';

  @override
  String get engagementHubSectionProgressCaption =>
      'Your level, your badges and who can find you.';

  @override
  String get engagementVoiceAppBarTitle => 'A voice, a little closer';

  @override
  String get engagementVoiceHeadline => 'Let your hello\nsound like you.';

  @override
  String get engagementVoiceIntro =>
      'An optional 20–45 second introduction, shared only in this conversation. Text is always welcome, too.';

  @override
  String engagementVoiceYouAndName(String name) {
    return 'You and $name';
  }

  @override
  String get engagementVoiceYouAndYourMatch => 'You and your match';

  @override
  String get engagementVoicePrivate => 'Private to this conversation';

  @override
  String get engagementVoiceConversationsLoadFailed =>
      'Your conversations couldn’t load.';

  @override
  String get engagementVoiceNoMatches =>
      'When you have a match, you can share a voice introduction here. No rush.';

  @override
  String get engagementVoicePickConversation =>
      'Who would you like to say hello to?';

  @override
  String get engagementVoiceStartingPoint => 'A small starting point';

  @override
  String get engagementVoiceChoosePrompt => 'Choose a prompt';

  @override
  String get engagementVoiceTranscriptLabel => 'Your words, in writing';

  @override
  String get engagementVoiceTranscriptHelper =>
      'Write what you say so they can read it, too. This is not automatic transcription.';

  @override
  String engagementVoiceStop(int seconds) {
    return 'Stop · ${seconds}s';
  }

  @override
  String get engagementVoiceRecord => 'Record your hello';

  @override
  String engagementVoiceRecordAgain(int seconds) {
    return 'Record again · ${seconds}s';
  }

  @override
  String get engagementVoiceRecordingReady =>
      'Recording ready. Check your transcript before sending.';

  @override
  String get engagementVoiceRecordingShort =>
      'That was a little short. Record 20–45 seconds.';

  @override
  String get engagementVoiceDiscard => 'Discard recording';

  @override
  String get engagementVoiceSubmitted =>
      'Introduction submitted. Approved recordings appear below.';

  @override
  String get engagementVoiceSending => 'Sending…';

  @override
  String get engagementVoiceShare => 'Share your hello';

  @override
  String get engagementVoiceCheckedNote =>
      'Recordings are checked before they are shared. There is no autoplay.';

  @override
  String get engagementVoiceYourIntros => 'Your voice introductions';

  @override
  String get engagementVoiceLatestNote =>
      'The latest 20 approved recordings in this conversation. Transcripts are always available to read.';

  @override
  String get engagementVoiceIntrosLoadFailed =>
      'Introductions couldn’t load. The conversation may no longer be available.';

  @override
  String get engagementVoiceNothingYet =>
      'Nothing shared yet. A simple hello is a good beginning.';

  @override
  String get engagementVoiceYourHello => 'Your hello';

  @override
  String engagementVoiceHelloFromName(String name) {
    return 'A hello from $name';
  }

  @override
  String get engagementVoiceHelloFromYourMatch => 'A hello from your match';

  @override
  String get engagementVoiceTranscriptHeading => 'TRANSCRIPT';

  @override
  String get engagementVoiceStopPlayback => 'Stop playback';

  @override
  String engagementVoiceListen(int seconds) {
    return 'Listen · ${seconds}s';
  }

  @override
  String get engagementVoiceReloadPrompts => 'Reload prompts';

  @override
  String get engagementVoiceMicPermission =>
      'Allow microphone access to record. You can still read transcripts without it.';

  @override
  String get engagementVoiceStartFailed =>
      'Unable to start recording. Check microphone access and try again.';

  @override
  String get engagementVoiceSaveFailed =>
      'The recording could not be saved. Please try again.';

  @override
  String get engagementVoicePromptsLoadFailed =>
      'Unable to load voice prompts right now.';

  @override
  String get engagementSessionUnavailable => 'User session not available.';

  @override
  String get engagementVoiceChooseConversation =>
      'Choose a conversation first.';

  @override
  String get engagementVoiceSelectPrompt => 'Please select a voice prompt.';

  @override
  String get engagementVoiceEnterTranscript => 'Please enter a transcript.';

  @override
  String get engagementVoiceSessionFailed =>
      'Unable to create voice icebreaker session.';

  @override
  String get engagementVoiceSendFailed =>
      'Unable to send voice icebreaker right now.';

  @override
  String get engagementVoicePlaybackUserRequired =>
      'User ID is required to mark playback.';

  @override
  String get engagementVoiceMarkPlaybackFailed =>
      'Unable to mark playback right now.';

  @override
  String get engagementVoicePlayFailed =>
      'Unable to play this recording right now.';

  @override
  String get chatStarterSmile => 'What made you smile today?';

  @override
  String get chatStarterSunday => 'Your ideal Sunday: go.';

  @override
  String get chatStarterCoffee => 'Coffee, a walk, or a little adventure?';

  @override
  String get chatWelcomeTitle => 'Every good story\nstarts with a hello.';

  @override
  String get chatWelcomePending =>
      'Your conversation will open when the match is confirmed.';

  @override
  String get chatWelcomeBody => 'No perfect opening line needed. Just be you.';

  @override
  String get chatInspirationEyebrow => 'A LITTLE INSPIRATION';

  @override
  String get chatAllConversations => 'All conversations';

  @override
  String get chatMakeConnectionEyebrow => 'MAKE A CONNECTION';

  @override
  String get chatLessSmallTalk => 'A little less small talk.';

  @override
  String get chatLessSmallTalkBody =>
      'Ask about the things that make them light up. Share something that feels like you.';

  @override
  String get chatFindTheWords => 'Find the words';

  @override
  String get chatSendJoy => 'Send a little joy';

  @override
  String get chatPaceTitle => 'Your pace. Your space.';

  @override
  String get chatPaceBody =>
      'Share only what feels comfortable. A good connection respects your boundaries.';

  @override
  String get chatWriteMessageHint => 'Write a message…';

  @override
  String get chatConversationPaused => 'Conversation paused';

  @override
  String get chatSendingMessageTooltip => 'Sending message';

  @override
  String get chatSendMessageTooltip => 'Send message';

  @override
  String get chatSendGiftTooltip => 'Send a gift';

  @override
  String get chatAddEmojiTooltip => 'Add an emoji';

  @override
  String get chatDraftedWithHelp => 'Drafted with help';

  @override
  String get chatHelpMeSayIt => 'Help me say it';

  @override
  String get chatEnterToSendHint =>
      'Enter to send · Shift + Enter for a new line';

  @override
  String get chatToday => 'Today';

  @override
  String get chatYesterday => 'Yesterday';

  @override
  String get chatGiftOptions => 'Gift options';

  @override
  String get chatStatusRead => 'Read';

  @override
  String get chatStatusDelivered => 'Delivered';

  @override
  String get chatStatusSent => 'Sent';

  @override
  String get chatGestureGiftHeading => 'Gesture + Rose Gift';

  @override
  String get chatGiftForYouHeading => 'A little something for you';

  @override
  String chatGiftTone(String tone) {
    return 'Tone: $tone';
  }

  @override
  String get chatFreeGift => 'Free gift';

  @override
  String get chatCopilotKindOpener => 'Opener';

  @override
  String get chatCopilotKindReply => 'Reply';

  @override
  String get chatCopilotKindDateIdea => 'Date idea';

  @override
  String get chatCopilotToneWarm => 'Warm';

  @override
  String get chatCopilotTonePlayful => 'Playful';

  @override
  String get chatCopilotToneDirect => 'Direct';

  @override
  String chatCopilotIntro(String name) {
    return 'A draft in your voice, from $name’s profile and your conversation. It is never sent for you, and if you send it as drafted they can see it was written with help.';
  }

  @override
  String chatCopilotDisclosure(String disclosure, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count drafts left today.',
      one: '1 draft left today.',
    );
    return '$disclosure $_temp0';
  }

  @override
  String get chatCopilotDraftIt => 'Draft it';

  @override
  String get chatCopilotTryAnother => 'Try another';

  @override
  String get chatCopilotUseAndEdit => 'Use and edit';

  @override
  String get chatCopilotEmpty => 'The copilot returned nothing.';

  @override
  String get chatCopilotUnavailable => 'The copilot is unavailable.';

  @override
  String get chatErrorMatchEnded => 'This match has ended.';

  @override
  String get chatErrorLoadMessages =>
      'Failed to load messages. Please try again.';

  @override
  String get chatErrorLockedQuest =>
      'Chat is locked until the quest is approved.';

  @override
  String get chatErrorSendFailed => 'Failed to send message.';

  @override
  String get chatErrorDeleteFailed => 'Failed to delete message.';

  @override
  String get chatErrorDeleteWindowExpired => 'Delete window expired (24h).';

  @override
  String get chatErrorOnlyReceivedGifts =>
      'Only received gifts can be managed.';

  @override
  String get chatErrorGiftGone => 'This gift is no longer available.';

  @override
  String get chatErrorGiftReportFailed =>
      'Could not report this gift. Please try again.';

  @override
  String get chatErrorGiftHideFailed =>
      'Could not hide this gift. Please try again.';

  @override
  String get chatErrorGiftsUnavailable =>
      'Rose gifts are currently unavailable.';

  @override
  String chatErrorNotEnoughCoins(String gift) {
    return 'Not enough coins to send $gift.';
  }

  @override
  String get chatErrorNotEnoughCoinsSelected =>
      'Not enough coins to send selected gift.';

  @override
  String get chatErrorWalletFrozen =>
      'Your coins are on hold while we review a refunded purchase. Free gifts are still available.';

  @override
  String get chatErrorGiftVelocity =>
      'You\'ve sent a lot of gifts in a short time. Please try again later.';

  @override
  String get chatErrorFreeGiftUsed =>
      'You\'ve sent today\'s free gift. A new one is available after midnight UTC.';

  @override
  String chatErrorGiftNotAvailable(String gift) {
    return '$gift is not available right now.';
  }

  @override
  String get chatErrorGiftNeedsActiveMatch =>
      'Gifts can only be sent in an active match.';

  @override
  String get chatErrorExclusiveGiftOnce =>
      'This exclusive gift can only be sent once today.';

  @override
  String get chatErrorGiftFailed => 'Failed to send gift.';

  @override
  String get chatErrorSessionUnavailable => 'User session not available.';

  @override
  String get chatErrorConversationUnavailable => 'Conversation unavailable.';

  @override
  String get verificationLandingTitle => 'Verify with confidence';

  @override
  String get verificationLandingBody =>
      'Upload a clear government identity document and a recent selfie. Files are sent as encrypted transport data and stored in a private evidence area.';

  @override
  String get verificationLandingDisclaimer =>
      'A review signal adds context to your profile. It never guarantees another person’s identity, intentions, or safety.';

  @override
  String get verificationViewVerifiedStatus => 'View verified status';

  @override
  String get verificationViewReviewStatus => 'View review status';

  @override
  String get verificationStartButton => 'Start secure verification';

  @override
  String get verificationUploadIdTitle => 'Upload ID';

  @override
  String get verificationUploadIdInstruction =>
      'Take or upload a clear photo of your government ID.';

  @override
  String get verificationGallery => 'Gallery';

  @override
  String get verificationCamera => 'Camera';

  @override
  String get verificationNext => 'Next';

  @override
  String get verificationSelfieTitle => 'Selfie';

  @override
  String get verificationSelfieInstruction => 'Take a clear selfie.';

  @override
  String get verificationUploadFailed =>
      'We could not upload your evidence. Check the files and try again.';

  @override
  String get verificationSubmit => 'Submit';

  @override
  String get verificationStatusTitle => 'Verification Status';

  @override
  String get verificationRetry => 'Retry';

  @override
  String get verificationStatusVerified => 'Verified';

  @override
  String get verificationStatusVerifiedMessage =>
      'Your verification is complete.';

  @override
  String get verificationStatusRejected => 'Rejected';

  @override
  String get verificationStatusRejectedFallback => 'Please try again.';

  @override
  String get verificationStatusPending => 'Pending';

  @override
  String get verificationStatusPendingMessage => 'Review in progress.';

  @override
  String get verificationStatusNotStarted => 'Not Started';

  @override
  String get verificationStatusNotStartedMessage =>
      'Start verification from Settings.';

  @override
  String get safetySosTitle => 'Emergency SOS';

  @override
  String get safetySosDefaultMessage =>
      'I need immediate assistance. Please check on me.';

  @override
  String get safetySosHeadline => 'Activate an emergency alert';

  @override
  String get safetySosIntro =>
      'If you are in immediate danger, contact local emergency services first. This alert is recorded for the safety team.';

  @override
  String get safetySosLevelUrgent => 'Urgent';

  @override
  String get safetySosLevelCritical => 'Critical';

  @override
  String get safetySosMessageLabel => 'Message for the safety team';

  @override
  String get safetySosActivating => 'Activating…';

  @override
  String get safetySosActivate => 'Activate SOS';

  @override
  String get safetySosLocationNote =>
      'Location is requested only for this alert. You can continue if permission is denied.';

  @override
  String get safetySosHistoryTitle => 'Alert history';

  @override
  String get safetySosHistoryEmpty => 'No SOS alerts recorded.';

  @override
  String safetySosHistoryHeading(String level, String status) {
    return '$level · $status';
  }

  @override
  String get safetySosAlertLevelLow => 'LOW';

  @override
  String get safetySosAlertLevelMedium => 'MEDIUM';

  @override
  String get safetySosAlertLevelHigh => 'HIGH';

  @override
  String get safetySosAlertLevelCritical => 'CRITICAL';

  @override
  String get safetySosAlertStatusOpen => 'open';

  @override
  String get safetySosAlertStatusActive => 'active';

  @override
  String get safetySosAlertStatusAcknowledged => 'acknowledged';

  @override
  String get safetySosAlertStatusResolved => 'resolved';

  @override
  String safetySosHistoryMetaWithLocation(String date) {
    return '$date · location included';
  }

  @override
  String safetySosHistoryMetaNoLocation(String date) {
    return '$date · no location';
  }

  @override
  String safetySosResolution(String note) {
    return 'Resolution: $note';
  }

  @override
  String get safetySosConfirmTitle => 'Activate SOS now?';

  @override
  String get safetySosConfirmBody =>
      'This creates an emergency alert for the safety team and attempts to attach your current location.';

  @override
  String get safetySosCancel => 'Cancel';

  @override
  String get safetySosConfirmActivate => 'Activate';

  @override
  String get safetySosActivatedTitle => 'SOS alert activated';

  @override
  String get safetySosActivatedWithLocation =>
      'Your alert and current location were recorded.';

  @override
  String get safetySosActivatedWithoutLocation =>
      'Your alert was recorded without location. Location permission was unavailable or declined.';

  @override
  String get safetySosDone => 'Done';

  @override
  String get safetySosSignInToView => 'Please sign in to view SOS history.';

  @override
  String get safetySosLoadFailed => 'Unable to load SOS history.';

  @override
  String get safetySosSignInToActivate =>
      'Please sign in before activating SOS.';

  @override
  String get safetySosActivateFailed => 'Unable to activate SOS.';

  @override
  String get photoThemesTitle => 'Photo Themes';

  @override
  String get photoThemesSignIn => 'Sign in to see photo themes.';

  @override
  String get photoThemesHeroTitle => 'Show a little of your world';

  @override
  String get photoThemesHeroSubtitle =>
      'Pick a prompt, share one photo, and see how everyone else answered. It is an easy way to start a conversation.';

  @override
  String get photoThemesLoadFailed => 'Themes could not load';

  @override
  String get photoThemesCheckConnection => 'Please check your connection.';

  @override
  String get photoThemesLookAround => 'You can look around';

  @override
  String get photoThemesEligibilityShareOwn =>
      'Complete your profile with two approved photos to share your own.';

  @override
  String get photoThemesNewPromptsTitle => 'New prompts are on the way';

  @override
  String get photoThemesNewPromptsBody =>
      'Check back soon for something to share.';

  @override
  String photoThemesSharedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count shared',
      one: '$count shared',
    );
    return '$_temp0';
  }

  @override
  String get photoThemesYouShared => 'You shared ✓';

  @override
  String get photoThemesBeFirst => 'Be the first to share →';

  @override
  String get photoThemesSeeEveryone => 'See everyone’s photos →';

  @override
  String get photoThemesSharedSnack => 'Your photo is shared. Nice one!';

  @override
  String get photoThemesShareFailed =>
      'Your photo could not be shared. Use a JPEG or PNG up to 10 MB.';

  @override
  String get photoThemesEligibilityShare =>
      'Complete your profile with two approved photos to share.';

  @override
  String get photoThemesAlreadyShared =>
      'You have shared for this theme. Remove yours to share a new one.';

  @override
  String get photoThemesThemeFallback => 'Photo Theme';

  @override
  String get photoThemesShareTooltip => 'Share a photo for this theme';

  @override
  String get photoThemesShareYourPhoto => 'Share your photo';

  @override
  String get photoThemesNoPhotosYet => 'No photos yet';

  @override
  String photoThemesBeFirstFor(String title) {
    return 'Be the first to share for “$title”';
  }

  @override
  String get photoThemesLoadingPrompt => 'Loading the prompt…';

  @override
  String get photoThemesPhotosLoadFailed => 'Photos could not load';

  @override
  String get photoThemesEmptyMessage =>
      'Your photo could be the one that gets everyone talking.';

  @override
  String get photoThemesMoreFailed => 'More photos could not load. Reload';

  @override
  String get photoThemesLoadMore => 'Load more';

  @override
  String get photoThemesPhotoUnavailable => 'Photo unavailable. Retry';

  @override
  String photoThemesOpenPhoto(String name) {
    return 'Open $name’s photo';
  }

  @override
  String get photoThemesYou => 'You';

  @override
  String get photoThemesWallHelp =>
      'If members love it, your photo can reach their Today walls: 50 likes and 5 comments reach 50 walls, 100 likes and 10 comments reach 100. You can turn this off any time.';

  @override
  String get photoThemesRemoveTitle => 'Remove your photo?';

  @override
  String get photoThemesRemoveMessage =>
      'It disappears from this theme for everyone. You can share a new one afterwards.';

  @override
  String get photoThemesRemoveAction => 'Remove photo';

  @override
  String get photoThemesRemoveFailed => 'Your photo could not be removed.';

  @override
  String get photoThemesReachOn =>
      'Your photo can now reach members’ walls when they love it.';

  @override
  String get photoThemesReachOff => 'Your photo is off every wall.';

  @override
  String get photoThemesSharedByYou => 'Shared by you';

  @override
  String photoThemesSharedBy(String name) {
    return 'Shared by $name';
  }

  @override
  String photoThemesPhotoDescription(String text) {
    return 'Photo description: $text';
  }

  @override
  String get photoThemesReachSwitch => 'Let it reach other members’ walls';

  @override
  String get photoThemesReachIdle => 'Members can carry this photo further';

  @override
  String get photoThemesReachLive =>
      'Members are seeing it on their Today walls now.';

  @override
  String get photoThemesRemoveMine => 'Remove my photo';

  @override
  String get photoThemesReport => 'Report';

  @override
  String photoThemesBlock(String name) {
    return 'Block $name';
  }

  @override
  String get photoThemesCommentHint => 'What does it make you think of?';

  @override
  String get photoThemesCommentApproved =>
      'Approved. Everyone who can see this photo can see it now.';

  @override
  String get photoThemesDetailsTitle => 'Tell us about it';

  @override
  String get photoThemesCaption => 'Caption';

  @override
  String get photoThemesCaptionHint => 'Pancakes, then nowhere to be.';

  @override
  String get photoThemesDescribe => 'Describe the photo';

  @override
  String get photoThemesDescribeHelper =>
      'Helps members who use a screen reader.';

  @override
  String get photoThemesShare => 'Share';

  @override
  String get photoThemesWallTitle => 'Covers on your wall';

  @override
  String get photoThemesWallCaption => 'Photos other members loved';

  @override
  String get photoThemesMasthead => 'PHOTO THEMES';

  @override
  String photoThemesByline(String name) {
    return 'BY $name';
  }

  @override
  String get photoThemesLikes => 'Likes';

  @override
  String get photoThemesComments => 'Comments';

  @override
  String get photoThemesCancel => 'Cancel';

  @override
  String get photoThemesTryAgain => 'Try again';

  @override
  String get photoThemesSaveFailed => 'That didn’t save. Please try again.';

  @override
  String get friendsChatEmpty =>
      'Say hello. Only the two of you can see this conversation.';

  @override
  String get friendsChatOpenFailed => 'Could not open the chat. Retry.';

  @override
  String get friendsCancelRequestTitle => 'Cancel your friend request?';

  @override
  String friendsCancelRequestBody(String name) {
    return '$name won’t see your request any more.';
  }

  @override
  String get friendsCancelRequestBodyUnnamed =>
      'this member won’t see your request any more.';

  @override
  String get friendsKeepIt => 'Keep it';

  @override
  String get friendsCancelRequest => 'Cancel request';

  @override
  String friendsNowFriends(String name) {
    return 'You and $name are now friends.';
  }

  @override
  String get friendsNowFriendsUnnamed => 'You and this member are now friends.';

  @override
  String friendsRequestSentTo(String name) {
    return 'Friend request sent to $name.';
  }

  @override
  String get friendsRequestSentToUnnamed =>
      'Friend request sent to this member.';

  @override
  String get friendsRequestCancelled => 'Request cancelled.';

  @override
  String get friendsRequestFailed => 'Could not send the request.';

  @override
  String get friendsAddCaption =>
      'Friends can message and plan things together';

  @override
  String get friendsRequested => 'Requested';

  @override
  String friendsWaitingFor(String name) {
    return 'Waiting for $name. Tap to cancel.';
  }

  @override
  String get friendsWaitingForUnnamed =>
      'Waiting for this member. Tap to cancel.';

  @override
  String get friendsAcceptFriend => 'Accept friend';

  @override
  String friendsAskedToBeFriends(String name) {
    return '$name asked to be friends';
  }

  @override
  String get friendsAskedToBeFriendsUnnamed =>
      'this member asked to be friends';

  @override
  String get friendsMessage => 'Message';

  @override
  String get friendsYoureFriends => 'You’re friends. Open your chat.';

  @override
  String friendsVouchTooShort(int min) {
    return 'Say a little more (at least $min characters).';
  }

  @override
  String friendsVouchTitle(String name) {
    return 'Vouch for $name';
  }

  @override
  String get friendsVouchBody =>
      'A sentence or two about why someone would be lucky to meet them. They approve it before it shows on their profile, with your first name.';

  @override
  String get friendsVouchLabel => 'Your vouch';

  @override
  String get friendsVouchHint => 'Kind, funny, and always shows up on time.';

  @override
  String get friendsVouchSend => 'Send vouch';

  @override
  String get friendsIntroChooseTwo => 'Choose two different friends.';

  @override
  String get friendsIntroSheetTitle => 'Introduce two friends';

  @override
  String get friendsIntroSheetBody =>
      'Both friends must allow introductions. Each controls their preview and decides privately. Share only a reason you have permission to mention. Their decisions and match outcome stay private.';

  @override
  String get friendsIntroNeedTwo =>
      'You need at least two accepted friends to make an intro.';

  @override
  String get friendsFirstFriend => 'First friend';

  @override
  String get friendsSecondFriend => 'Second friend';

  @override
  String get friendsIntroWhyLabel => 'Why they should meet (optional)';

  @override
  String get friendsIntroSubmit => 'Make the intro';

  @override
  String get friendsLoadFailed => 'Failed to load friends. Please try again.';

  @override
  String get friendsAddFailed => 'Failed to add friend.';

  @override
  String get friendsRemoveFailed => 'Failed to remove friend.';

  @override
  String get friendsRespondFailed => 'Failed to respond to friend request.';

  @override
  String get friendsSocialLoadFailed => 'Unable to load vouches and intros.';

  @override
  String get friendsVouchSendFailed => 'Unable to send this vouch.';

  @override
  String get friendsVouchUpdateFailed => 'Unable to update this vouch.';

  @override
  String get friendsVouchWithdrawFailed => 'Unable to withdraw this vouch.';

  @override
  String get friendsIntroMakeFailed => 'Unable to make this intro.';

  @override
  String get friendsIntroAnswerFailed => 'Unable to answer this intro.';

  @override
  String get groupsEyebrow => 'GROUPS';

  @override
  String get groupsTitle => 'Find your people.';

  @override
  String get groupsSubtitle =>
      'Lifestyle communities anyone can join, and private groups just for your friends.';

  @override
  String get groupsStartGroup => 'Start a group';

  @override
  String get groupsInvitationsHeader => 'INVITATIONS';

  @override
  String get groupsInvitationsCaption => 'Friends asked you to join.';

  @override
  String get groupsAnswerFailed => 'Your answer could not be saved.';

  @override
  String groupsWelcome(String name) {
    return 'Welcome to $name!';
  }

  @override
  String get groupsInvitationDeclined => 'Invitation declined.';

  @override
  String get groupsYourGroupsHeader => 'YOUR GROUPS';

  @override
  String get groupsYourGroupsFailed => 'Your groups could not load';

  @override
  String get groupsErrorCheckConnection => 'Please check your connection.';

  @override
  String get groupsEmptyTitle => 'No groups yet';

  @override
  String get groupsEmptyBody =>
      'Join a community below, or start a private group with your friends.';

  @override
  String get groupsDiscoverHeader => 'DISCOVER BY LIFESTYLE';

  @override
  String get groupsDiscoverCaption => 'Community groups are open to everyone.';

  @override
  String get groupsLifestylesFailed => 'Lifestyles could not load';

  @override
  String get groupsCategoryAll => 'All';

  @override
  String get groupsDiscoverFailed => 'Groups could not load';

  @override
  String get groupsDiscoverEmptyTitle => 'Nothing new to join';

  @override
  String groupsDiscoverEmptyCategoryTitle(String category) {
    return 'No $category groups yet';
  }

  @override
  String get groupsDiscoverEmptyBody =>
      'Be the first: start a community group and invite your friends.';

  @override
  String get groupsStartOne => 'Start one';

  @override
  String get groupsJoinFailed => 'You could not join just now.';

  @override
  String get groupsJoin => 'Join';

  @override
  String groupsJoinNamed(String name) {
    return 'Join $name';
  }

  @override
  String groupsInvitedBy(String name, String kind, String members) {
    return '$name invited you · $kind · $members';
  }

  @override
  String groupsInvitedByFriend(String kind, String members) {
    return 'A friend invited you · $kind · $members';
  }

  @override
  String get groupsDecline => 'Decline';

  @override
  String groupsDeclineNamed(String name) {
    return 'Decline $name';
  }

  @override
  String groupsChatEmpty(String name) {
    return 'Say hello to the group. Everyone in $name can see messages here.';
  }

  @override
  String groupsInviteFriendsTo(String name) {
    return 'Invite friends to $name';
  }

  @override
  String get groupsSendInvitations => 'Send invitations';

  @override
  String get groupsInvitationsFailed => 'Invitations could not be sent.';

  @override
  String groupsInvitationSentTo(String name) {
    return 'Invitation sent to $name.';
  }

  @override
  String groupsInvitationsSent(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count invitations sent.',
      one: '1 invitation sent.',
    );
    return '$_temp0';
  }

  @override
  String groupsLeaveTitle(String name) {
    return 'Leave $name?';
  }

  @override
  String get groupsLeaveBodyAlone =>
      'You are the only member, so the group and its chat will be deleted.';

  @override
  String get groupsLeaveBodyOwner =>
      'Ownership passes to your longest-standing moderator, or else member. You will lose access to the chat.';

  @override
  String get groupsLeaveBodyCommunity =>
      'You will lose access to the group chat. You can join again later.';

  @override
  String get groupsLeaveBodyPrivate =>
      'You will lose access to the group chat. You will need a new invitation to come back.';

  @override
  String get groupsLeave => 'Leave';

  @override
  String get groupsLeaveFailed => 'You could not leave just now.';

  @override
  String get groupsCoverUploadFailed =>
      'Your cover photo could not be uploaded. Use a JPEG or PNG up to 10 MB.';

  @override
  String get groupsRemoveCoverTitle => 'Remove the cover photo?';

  @override
  String groupsRemoveCoverBody(String name) {
    return '$name will show its emoji cover again.';
  }

  @override
  String get groupsRemove => 'Remove';

  @override
  String get groupsRemoveCoverFailed => 'The cover photo could not be removed.';

  @override
  String get groupsCoverRemoved => 'Cover photo removed.';

  @override
  String groupsDeleteTitle(String name) {
    return 'Delete $name?';
  }

  @override
  String get groupsDeleteBody =>
      'The group, its invitations and its chat are removed for everyone. This cannot be undone.';

  @override
  String get groupsDeleteGroup => 'Delete group';

  @override
  String get groupsDeleteFailed => 'The group could not be deleted.';

  @override
  String get groupsDetailEyebrow => 'GROUP';

  @override
  String get groupsDetailTitleFallback => 'Group';

  @override
  String get groupsOwnerTools => 'Owner tools';

  @override
  String get groupsEditGroup => 'Edit group';

  @override
  String get groupsAddCoverPhoto => 'Add cover photo';

  @override
  String get groupsChangeCoverPhoto => 'Change cover photo';

  @override
  String get groupsRemoveCoverPhoto => 'Remove cover photo';

  @override
  String get groupsMoreOptions => 'More options';

  @override
  String get groupsReportGroup => 'Report group';

  @override
  String get groupsUnavailableTitle => 'This group is unavailable';

  @override
  String get groupsUnavailableBody =>
      'It may have been deleted, or you may no longer have access.';

  @override
  String get groupsOpenToAll => 'Open to all';

  @override
  String get groupsPrivate => 'Private';

  @override
  String get groupsYouRunIt => 'You run it';

  @override
  String get groupsYouModerate => 'You moderate';

  @override
  String get groupsCoverNotePending =>
      'Only you can see this photo until it’s approved. Members see the emoji cover meanwhile.';

  @override
  String get groupsCoverNoteRejected =>
      'Your last cover photo wasn’t approved. Choose a different one.';

  @override
  String get groupsCoverUnderReview => 'Under review';

  @override
  String get groupsChangeCover => 'Change cover';

  @override
  String get groupsRemoveCover => 'Remove cover';

  @override
  String get groupsRemovedTitle => 'This group was removed after a review';

  @override
  String get groupsRemovedBodyOwner =>
      'Members can’t chat, join or invite while it is removed. Your review notices explain the decision and let you appeal.';

  @override
  String get groupsRemovedBodyMember =>
      'Members can’t chat, join or invite while it is removed. You can leave the group at any time.';

  @override
  String get groupsMembers => 'Members';

  @override
  String get groupsChatButton => 'Group chat';

  @override
  String groupsChatButtonUnread(int count) {
    return 'Group chat · $count new';
  }

  @override
  String get groupsInviteFriends => 'Invite friends';

  @override
  String get groupsWhosHere => 'WHO’S HERE';

  @override
  String get groupsSeeAll => 'See all';

  @override
  String get groupsYou => 'You';

  @override
  String groupsInvitedToJoin(String name) {
    return 'You’re invited to join $name.';
  }

  @override
  String get groupsJoinGroup => 'Join group';

  @override
  String get groupsJoinHint => 'Members see who’s here and chat together.';

  @override
  String get groupsCantJoinTitle => 'You can’t join this group';

  @override
  String get groupsCantJoinBody =>
      'It may be full, or a moderator removed you.';

  @override
  String get groupsInvitationOnly => 'Invitation only';

  @override
  String get groupsInvitationOnlyBody =>
      'A member can invite you to this private group.';

  @override
  String get groupsMakeModerator => 'Make moderator';

  @override
  String get groupsMakeMember => 'Make member';

  @override
  String get groupsRemoveFromGroup => 'Remove from group';

  @override
  String groupsRemoveMemberTitle(String name) {
    return 'Remove $name?';
  }

  @override
  String get groupsRemoveMemberBodyCommunity =>
      'They leave the group and its chat, and cannot rejoin by themselves.';

  @override
  String get groupsRemoveMemberBodyPrivate =>
      'They leave the group and its chat.';

  @override
  String get groupsChangeFailed => 'That change could not be saved.';

  @override
  String get groupsMembersFailed => 'Members could not load';

  @override
  String get groupsPleaseTryAgain => 'Please try again.';

  @override
  String groupsMemberYou(String name) {
    return '$name (you)';
  }

  @override
  String get groupsRoleOwner => 'Owner';

  @override
  String get groupsRoleModerator => 'Moderator';

  @override
  String get groupsRoleMember => 'Member';

  @override
  String groupsMemberOptions(String name) {
    return 'Options for $name';
  }

  @override
  String get groupsEditFailed => 'Your changes could not be saved.';

  @override
  String get groupsSaving => 'Saving…';

  @override
  String get groupsSaveChanges => 'Save changes';

  @override
  String get groupsNameLabel => 'Group name';

  @override
  String get groupsAboutLabel => 'What is it about?';

  @override
  String get groupsAboutOptionalLabel => 'What is it about? (optional)';

  @override
  String get groupsCityLabel => 'City (optional)';

  @override
  String get groupsCoverColorTheme => 'Theme';

  @override
  String get groupsCoverColorAccent => 'Accent';

  @override
  String get groupsCoverColorWarm => 'Warm';

  @override
  String get groupsLifestyleLabel => 'Lifestyle';

  @override
  String get groupsCreateCoverUploadFailed =>
      'Your group is ready, but the cover photo could not be uploaded. Try again from the group.';

  @override
  String get groupsCreatePickLifestyle =>
      'Pick a lifestyle for your community group.';

  @override
  String get groupsCreateNameTooShort =>
      'Give your group a name of at least 3 letters.';

  @override
  String get groupsCreateFailed =>
      'Your group could not be created. Please try again.';

  @override
  String get groupsCreateEyebrow => 'NEW GROUP';

  @override
  String get groupsCreateSubtitle =>
      'Bring people together around what you love.';

  @override
  String get groupsCreateSubtitleFriends => 'Turn your friends into a group.';

  @override
  String get groupsCreateKindHeader => 'WHAT KIND';

  @override
  String get groupsKindCommunity => 'Community group';

  @override
  String get groupsKindPrivate => 'Private group';

  @override
  String get groupsCreateCommunitySubtitle =>
      'By lifestyle. Anyone can find and join it.';

  @override
  String get groupsCreatePrivateSubtitle =>
      'Just friends. Only people you invite can join.';

  @override
  String get groupsCreateLifestyleHeader => 'LIFESTYLE';

  @override
  String get groupsCreateLifestyleCaption =>
      'Where people will discover your group.';

  @override
  String get groupsCreateDetailsHeader => 'DETAILS';

  @override
  String get groupsCreateNameHintCommunity => 'Sunrise runners of Indiranagar';

  @override
  String get groupsCreateNameHintPrivate => 'The Sunday brunch crew';

  @override
  String get groupsCreateCoverHeader => 'COVER';

  @override
  String groupsCoverEmojiSemantics(String emoji) {
    return 'Cover emoji $emoji';
  }

  @override
  String get groupsCreateCoverPhotoOptional => 'Cover photo (optional)';

  @override
  String get groupsCreateCoverPhotoHint =>
      'Members see the emoji until your photo is approved.';

  @override
  String get groupsCreateAddCoverPhoto => 'Add a cover photo';

  @override
  String get groupsCreateChangePhoto => 'Change photo';

  @override
  String get groupsCreateRemovePhoto => 'Remove photo';

  @override
  String get groupsCreateFriendsHeader => 'FRIENDS';

  @override
  String get groupsCreateFriendsCaptionEmpty =>
      'Invite friends now, or later from the group.';

  @override
  String get groupsCreateFriendsCaption => 'They’ll get an invitation to join.';

  @override
  String get groupsFriendFallback => 'Friend';

  @override
  String groupsRemoveInvitee(String name) {
    return 'Remove $name';
  }

  @override
  String get groupsChooseFriends => 'Choose friends';

  @override
  String get groupsChangeFriends => 'Change friends';

  @override
  String get groupsCreating => 'Creating…';

  @override
  String get groupsCreateGroup => 'Create group';

  @override
  String get groupsCardRemoved => 'Removed after a review';

  @override
  String groupsCardSemanticsMuted(String name, String details) {
    return '$name, $details, notifications muted';
  }

  @override
  String get groupsNotificationsMuted => 'Notifications muted';

  @override
  String groupsUnreadMessages(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count unread messages',
      one: '1 unread message',
    );
    return '$_temp0';
  }

  @override
  String get groupsCoverSheetTitle => 'Cover photo';

  @override
  String get groupsCoverSheetBody =>
      'Every photo is checked before other members can see it. Use a JPEG or PNG up to 10 MB.';

  @override
  String get groupsCoverFromPhotos => 'Choose from your photos';

  @override
  String get groupsCoverTakePhoto => 'Take a photo';

  @override
  String get groupsCoverTooLarge =>
      'That photo is larger than 10 MB. Choose a smaller one.';

  @override
  String get groupsCoverPreviewTitle => 'Preview your cover';

  @override
  String get groupsCoverPreviewBody =>
      'Covers show as a wide banner, keeping the middle of your photo.';

  @override
  String get groupsCancel => 'Cancel';

  @override
  String get groupsCoverUseThisPhoto => 'Use this photo';

  @override
  String get groupsCoverPreviewSemantics => 'Your new cover photo';

  @override
  String get groupsCoverChecking => 'Checking your cover photo…';

  @override
  String groupsCoverUploading(int percent) {
    return 'Uploading cover photo… $percent%';
  }

  @override
  String get groupsCoverUploadedReview =>
      'Your cover is under review. Only you can see it until it’s approved.';

  @override
  String get groupsCoverUpdated => 'Cover photo updated.';

  @override
  String get groupsPickerSubtitle =>
      'Only friends you’re connected with can be invited.';

  @override
  String get groupsDone => 'Done';

  @override
  String get groupsSearchFriends => 'Search friends';

  @override
  String get groupsFriendsFailed => 'Friends could not load';

  @override
  String get groupsNoFriendsTitle => 'No friends yet';

  @override
  String get groupsNoFriendsBody =>
      'Add friends from Matches, profiles or rooms, then bring them into a group.';

  @override
  String get groupsAlreadyMember => 'Already in this group';

  @override
  String get groupsInvitationSent => 'Invitation sent';

  @override
  String get todayActivityCoffee => 'Coffee';

  @override
  String get todayActivityWalk => 'A daytime walk';

  @override
  String get todayActivityMeal => 'A meal';

  @override
  String get todayActivityPlayful => 'Something playful';

  @override
  String get todayActivityEvent => 'An event';

  @override
  String get todayActivityVideoCall => 'A video hello';

  @override
  String get todayActivityDrinks => 'Drinks';

  @override
  String get todayActivityOther => 'Something else';

  @override
  String get todayBudgetFlexible => 'Let’s decide together';

  @override
  String get todayBudgetFree => 'Keep it free';

  @override
  String get todayBudgetModest => 'Keep it modest';

  @override
  String get todayBudgetTreat => 'A little treat';

  @override
  String get todayRhythmTitle => 'Your dating rhythm';

  @override
  String get todayRhythmLoadFailed => 'Unable to load your preferences.';

  @override
  String get todayRhythmSaved => 'Your dating rhythm is saved.';

  @override
  String get todayRhythmSaveFailed =>
      'Unable to save. Your choices are still here.';

  @override
  String get todayRhythmHeadline => 'Make room for the way you date.';

  @override
  String get todayRhythmIntro =>
      'Choose what fits your life. Availability and introductions are optional, and you can change your mind.';

  @override
  String get todayRhythmOpenTo => 'What are you open to?';

  @override
  String get todayRhythmIntentNone => 'Prefer not to say';

  @override
  String get todayRhythmIntentRelationship => 'A relationship';

  @override
  String get todayRhythmIntentExploring => 'Finding my direction';

  @override
  String get todayRhythmIntentCasual => 'Something casual';

  @override
  String get todayRhythmPaceSection => 'Your conversation pace';

  @override
  String get todayRhythmPaceNone => 'No preference';

  @override
  String get todayRhythmPaceSlow => 'A little slower';

  @override
  String get todayRhythmPaceSteady => 'A steady conversation';

  @override
  String get todayRhythmPaceFrequent => 'Frequent conversation';

  @override
  String get todayRhythmSlowWeek => 'Slow replies this week';

  @override
  String get todayRhythmSlowWeekHint => 'This status clears after seven days.';

  @override
  String get todayRhythmSharePace => 'Share this status with my matches';

  @override
  String get todayRhythmSharePaceHint =>
      'Only current matches can see your temporary status.';

  @override
  String get todayRhythmFirstDate => 'Your kind of first date';

  @override
  String get todayRhythmChooseFive =>
      'Choose up to five. Shared preferences help explain your introductions.';

  @override
  String get todayRhythmWeekSection => 'A little room in your week';

  @override
  String get todayRhythmShareAvailability => 'Use my broad availability';

  @override
  String get todayRhythmShareAvailabilityHint =>
      'Only genuine overlap is shown. Your full schedule is private. Turning this off deletes saved windows.';

  @override
  String get todayRhythmAvailabilityHint =>
      'Tap any morning, afternoon or evening that suits you. Times use this device’s local time and expire automatically.';

  @override
  String get todayRhythmMorning => 'Morning';

  @override
  String get todayRhythmAfternoon => 'Afternoon';

  @override
  String get todayRhythmEvening => 'Evening';

  @override
  String get todayRhythmIntrosSection => 'Introductions with your permission';

  @override
  String get todayRhythmFriendIntros =>
      'Allow introductions from accepted friends';

  @override
  String get todayRhythmFriendIntrosHint =>
      'Both people must opt in. Your friend receives no match or decline updates. A preview includes your name and age.';

  @override
  String get todayRhythmIntroPhoto => 'Include my profile photos';

  @override
  String get todayRhythmIntroPhotoHint =>
      'Only the person receiving an introduction can see them.';

  @override
  String get todayRhythmIntroCity => 'Include my city';

  @override
  String get todayRhythmIntroCityHint =>
      'Your exact location is never included.';

  @override
  String get todayRhythmReload => 'Reload saved choices';

  @override
  String get todayRhythmSaving => 'Saving…';

  @override
  String get todayRhythmSave => 'Save my rhythm';

  @override
  String get todayRhythmBreakTitle => 'A break is always okay.';

  @override
  String get todayRhythmBreakBody =>
      'Pause new introductions whenever you need. Your existing conversations stay available.';

  @override
  String get todayRhythmPauseFailed => 'Unable to update your pause.';

  @override
  String get todayRhythmResume => 'Resume introductions';

  @override
  String get todayRhythmPause => 'Pause introductions';

  @override
  String get datingConnectionSlowTitle => 'Taking replies slowly this week';

  @override
  String get datingConnectionSlowBody =>
      'Your match is making room for a slower pace.';

  @override
  String get datingConnectionYourTurn => 'Your turn: add a surprise';

  @override
  String get datingConnectionComplete => 'Your first chapter is ready';

  @override
  String get datingConnectionWaiting => 'Your chapter has a beginning';

  @override
  String get datingConnectionCreate => 'Create your first chapter';

  @override
  String get datingConnectionBody =>
      'A beginning, a surprise, and a story you shape together.';

  @override
  String get chemistryTitle => 'A little chemistry';

  @override
  String get chemistryIntro =>
      'Pick something that feels like you. There are no right answers, and this never controls access to chat.';

  @override
  String get chemistrySaveFailed =>
      'Unable to save your choice. Please try again.';

  @override
  String get chemistryRetry => 'Try loading again';

  @override
  String get chemistryRevealedTitle => 'Both answers, together';

  @override
  String get chemistryYouPicked => 'You picked';

  @override
  String get chemistryMatchPicked => 'Your match picked';

  @override
  String get chemistryRevealedBody =>
      'A shared favourite or a happy difference—there’s something to talk about.';

  @override
  String get chemistryWaitingBody =>
      'Your answer is saved privately. Both answers appear here when you have both chosen.';

  @override
  String chemistryYourChoice(String choice) {
    return 'Your choice: $choice';
  }

  @override
  String get chemistryAnotherMoment => 'Another moment, whenever you like';

  @override
  String get chemistryChooseMoment => 'Choose a moment';

  @override
  String get chemistryPromptSunday => 'Build a Sunday';

  @override
  String get chemistryPromptAdventure => 'Choose an adventure';

  @override
  String get chemistryPromptFirstDate => 'Your kind of first date';

  @override
  String get chemistryQuestionSunday => 'Your ideal Sunday starts with…';

  @override
  String get chemistryQuestionAdventure => 'A small adventure together…';

  @override
  String get chemistryQuestionFirstDate => 'For a first hello, you’d choose…';

  @override
  String get engagementLevelFrozen =>
      'Progression is paused while an account safety review is active.';

  @override
  String get engagementLevelTrustGate =>
      'Verify your profile and maintain a healthy account to unlock trust-gated levels.';

  @override
  String get engagementLevelPathTitle => 'Level path';

  @override
  String get engagementLevelPathSubtitle =>
      'XP comes from meaningful activity. Purchases never increase your level.';

  @override
  String get engagementLevelRewardsTitle => 'Rewards';

  @override
  String get engagementLevelRewardsSubtitle =>
      'Earned rewards are cosmetic, convenience, or bounded visibility benefits.';

  @override
  String get engagementLevelRecentTitle => 'Recent XP';

  @override
  String get engagementLevelRecentSubtitle =>
      'Your activity ledger is permanent and auditable.';

  @override
  String engagementLevelNumber(int level) {
    return 'Level $level';
  }

  @override
  String engagementLevelXp(String xp) {
    return '$xp XP';
  }

  @override
  String get engagementLevelHighest => 'Highest level reached';

  @override
  String engagementLevelProgress(int xp, String percent) {
    return '$xp XP in this level · $percent%';
  }

  @override
  String engagementLevelThreshold(int xp, String summary) {
    return '$xp XP · $summary';
  }

  @override
  String get engagementLevelTrustGated => 'Trust-gated';

  @override
  String get engagementLevelClaimed => 'Claimed';

  @override
  String get engagementLevelClaim => 'Claim';

  @override
  String get engagementLevelLocked => 'Locked';

  @override
  String get engagementLevelStandardAward => 'Standard award';

  @override
  String engagementLevelQualityWeighting(String multiplier) {
    return '$multiplier× quality weighting';
  }

  @override
  String get engagementLevelEmptyLedger =>
      'Complete meaningful activities to earn your first XP.';

  @override
  String get engagementXpSourceProfileCompleted => 'Profile Completed';

  @override
  String get engagementXpSourceDailyPromptSubmitted => 'Daily Prompt Submitted';

  @override
  String get engagementXpSourceMiniActivityCompleted =>
      'Mini Activity Completed';

  @override
  String get engagementXpSourceCircleChallengeSubmitted =>
      'Circle Challenge Submitted';

  @override
  String get engagementXpSourceVoiceIcebreakerPlayed =>
      'Voice Icebreaker Played';

  @override
  String get engagementXpSourceStreak3 => 'Streak 3';

  @override
  String get engagementXpSourceStreak7 => 'Streak 7';

  @override
  String get engagementXpSourceStreak14 => 'Streak 14';

  @override
  String get engagementXpSourceAdminAdjustment => 'Admin Adjustment';

  @override
  String get engagementLevelSignIn => 'Sign in to view your level progress.';

  @override
  String get engagementLevelLoadFailed =>
      'Unable to load your progress right now.';

  @override
  String get engagementLevelClaimFailed =>
      'Unable to claim this reward right now.';

  @override
  String get engagementCoffeeTitle => 'Group Coffee Polls';

  @override
  String get engagementCoffeeCreateHeading =>
      'Create a lightweight group coffee poll';

  @override
  String get engagementCoffeeCreateHint =>
      'Add up to 3 participant user IDs (comma-separated) and at least one option.';

  @override
  String get engagementCoffeeParticipantsLabel =>
      'Participant user IDs (comma-separated)';

  @override
  String get engagementCoffeeDeadlineLabel => 'Deadline ISO (optional)';

  @override
  String engagementCoffeeOptionNumber(int number) {
    return 'Option $number';
  }

  @override
  String get engagementCoffeeCreate => 'Create Poll';

  @override
  String get engagementCoffeeActorLabel => 'Action user ID override (optional)';

  @override
  String get engagementCoffeeEmpty => 'No polls found yet. Create one above.';

  @override
  String engagementCoffeePollId(String id) {
    return 'Poll $id';
  }

  @override
  String engagementCoffeeStatus(String status) {
    return 'Status: $status';
  }

  @override
  String get engagementCoffeeStatusOpen => 'open';

  @override
  String get engagementCoffeeStatusFinalized => 'finalized';

  @override
  String engagementCoffeeParticipants(String ids) {
    return 'Participants: $ids';
  }

  @override
  String engagementCoffeeOptionSummary(
    String day,
    String time,
    String area,
    int count,
  ) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$day · $time · $area ($count votes)',
    );
    return '$_temp0';
  }

  @override
  String get engagementCoffeeVote => 'Vote';

  @override
  String get engagementCoffeeFinalize => 'Finalize Poll';

  @override
  String get engagementCoffeeDayLabel => 'Day';

  @override
  String get engagementCoffeeTimeLabel => 'Time window';

  @override
  String get engagementCoffeeAreaLabel => 'Neighborhood';

  @override
  String get engagementCoffeeLoadFailed =>
      'Unable to load group polls right now.';

  @override
  String get engagementCoffeeCreateFailed =>
      'Unable to create group poll right now.';

  @override
  String get engagementCoffeeVoteUserRequired => 'User ID is required to vote.';

  @override
  String get engagementCoffeeVoteFailed => 'Unable to vote right now.';

  @override
  String get engagementCoffeeFinalizeUserRequired =>
      'User ID is required to finalize.';

  @override
  String get engagementCoffeeFinalizeFailed =>
      'Unable to finalize poll right now.';

  @override
  String get engagementDailyPromptUnavailable => 'Daily prompt unavailable';

  @override
  String get engagementDailyPromptPullToRefresh =>
      'Pull to refresh or try again in a bit.';

  @override
  String get engagementDailyPromptDomainValues => 'VALUES';

  @override
  String get engagementDailyPromptDomainLifestyle => 'LIFESTYLE';

  @override
  String get engagementDailyPromptDomainRelationshipStyle =>
      'RELATIONSHIP STYLE';

  @override
  String get engagementDailyPromptSparkTitle => 'Compatibility Spark';

  @override
  String engagementDailyPromptSparkSummary(int replied, int similar) {
    return '$replied replied today · $similar similar answers';
  }

  @override
  String get engagementDailyPromptYourAnswer => 'Your answer';

  @override
  String get engagementDailyPromptHint =>
      'Type your response in under 60 seconds.';

  @override
  String engagementDailyPromptEditOpenUntil(String time) {
    return 'Edit window open until $time';
  }

  @override
  String get engagementDailyPromptEditOpenSoon => 'Edit window open until soon';

  @override
  String get engagementDailyPromptEditClosed => 'Edit window closed for today.';

  @override
  String get engagementDailyPromptEdited => 'Edited';

  @override
  String get engagementDailyPromptSubmit => 'Submit Daily Answer';

  @override
  String get engagementDailyPromptUpdate => 'Update Answer';

  @override
  String get engagementDailyPromptStreakProgress => 'Streak Progress';

  @override
  String engagementDailyPromptStatCurrent(String value) {
    return 'Current: $value';
  }

  @override
  String engagementDailyPromptStatBest(String value) {
    return 'Best: $value';
  }

  @override
  String engagementDailyPromptStatNext(String value) {
    return 'Next: $value';
  }

  @override
  String engagementDailyPromptDays(int days) {
    return '${days}d';
  }

  @override
  String get engagementDailyPromptComplete => 'Complete';

  @override
  String engagementDailyPromptMilestone(int days) {
    return 'Milestone unlocked: $days-day streak';
  }

  @override
  String get engagementDailyPromptLoadFailed =>
      'Unable to load daily prompt right now.';

  @override
  String get engagementDailyPromptNotLoaded =>
      'Daily prompt is not loaded yet.';

  @override
  String get engagementDailyPromptEnterAnswer =>
      'Please enter an answer first.';

  @override
  String get engagementDailyPromptSubmitFailed =>
      'Unable to submit answer. Please try again.';

  @override
  String get clubsKindBooks => 'Books';

  @override
  String get clubsKindFilms => 'Films';

  @override
  String get clubsFilterAll => 'All';

  @override
  String get clubsAudiencePrivate => 'Only me';

  @override
  String get clubsAudienceFriends => 'Friends';

  @override
  String get clubsAudienceCommunity => 'Connect community';

  @override
  String get clubsRoleOwner => 'Owner';

  @override
  String get clubsRoleModerator => 'Moderator';

  @override
  String get clubsRoleMember => 'Member';

  @override
  String get clubsBadgeBookClub => 'Book club';

  @override
  String get clubsBadgeFilmClub => 'Film club';

  @override
  String get clubsBadgeBookList => 'Book list';

  @override
  String get clubsBadgeFilmList => 'Film list';

  @override
  String get clubsBadgeBook => 'Book';

  @override
  String get clubsBadgeFilm => 'Film';

  @override
  String get clubsClub => 'Club';

  @override
  String clubsStarsOutOfFive(String rating) {
    return '$rating out of 5 stars';
  }

  @override
  String clubsStarCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count stars',
      one: '1 star',
    );
    return '$_temp0';
  }

  @override
  String get clubsNoRatingsYet => 'No ratings yet';

  @override
  String clubsRatingSummary(String average, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count reviews',
      one: '1 review',
    );
    return '$average · $_temp0';
  }

  @override
  String get clubsWeekThis => 'This week';

  @override
  String get clubsWeekNext => 'Next week';

  @override
  String get clubsWeekLast => 'Last week';

  @override
  String clubsWeekOf(String date) {
    return 'Week of $date';
  }

  @override
  String get clubsTitle => 'Book & Film Clubs';

  @override
  String get clubsMyLists => 'My lists';

  @override
  String get clubsStartClubTooltip => 'Start a book or film club';

  @override
  String get clubsStartClub => 'Start a club';

  @override
  String get clubsSignInToSee => 'Sign in to see clubs.';

  @override
  String get clubsHeroTitle => 'Read it. Watch it. Talk about it.';

  @override
  String get clubsHeroSubtitle =>
      'Join a club, follow one pick a week and share what you thought. Great taste is a great conversation starter.';

  @override
  String get clubsScopeMine => 'My clubs';

  @override
  String get clubsScopeDiscover => 'Discover';

  @override
  String get clubsLoadErrorTitle => 'Clubs could not load';

  @override
  String get clubsCheckConnection => 'Please check your connection.';

  @override
  String get clubsLookAroundTitle => 'You can look around';

  @override
  String get clubsLookAroundMessage =>
      'Complete your profile with two approved photos to start or join a club.';

  @override
  String get clubsEmptyMineTitle => 'Your first club is waiting';

  @override
  String get clubsEmptyMineMessage =>
      'Find a club that reads or watches what you love, or start your own.';

  @override
  String get clubsEmptyDiscoverTitle => 'No clubs here yet';

  @override
  String get clubsEmptyDiscoverMessage =>
      'Be the first: start a club and pick something great for this week.';

  @override
  String get clubsDiscoverClubs => 'Discover clubs';

  @override
  String clubsMemberCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count members',
      one: '1 member',
    );
    return '$_temp0';
  }

  @override
  String get clubsYouRunIt => 'You run it';

  @override
  String get clubsYouModerate => 'You moderate';

  @override
  String get clubsJoined => 'Joined ✓';

  @override
  String get clubsNoPickThisWeek => 'No pick yet this week';

  @override
  String get clubsNameTooShort =>
      'Give your club a name of at least 3 letters.';

  @override
  String get clubsCreateFailed => 'Your club could not be created.';

  @override
  String get clubsNameLabel => 'Club name';

  @override
  String get clubsNameHint => 'Sunday Slow Reads';

  @override
  String get clubsDescriptionLabel => 'What is your club about? (optional)';

  @override
  String get clubsCreating => 'Creating…';

  @override
  String get clubsCreateClub => 'Create club';

  @override
  String clubsLeaveTitle(String name) {
    return 'Leave $name?';
  }

  @override
  String get clubsLeaveMessage =>
      'You can rejoin later while the club is open.';

  @override
  String get clubsLeaveClub => 'Leave club';

  @override
  String clubsWelcome(String name) {
    return 'Welcome to $name!';
  }

  @override
  String get clubsChangeNotSaved => 'That change could not be saved.';

  @override
  String get clubsOptionsTooltip => 'Club options';

  @override
  String get clubsMembers => 'Members';

  @override
  String get clubsReportClub => 'Report club';

  @override
  String get clubsDetailLoadErrorTitle => 'This club could not load';

  @override
  String get clubsDetailLoadErrorMessage =>
      'It may have closed. Please try again.';

  @override
  String get clubsEarlierPicks => 'Earlier picks';

  @override
  String clubsPickSubtitle(String week, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count posts',
      one: '1 post',
    );
    return '$week · $_temp0';
  }

  @override
  String get clubsOpenDiscussion => 'Open the discussion';

  @override
  String get clubsJoinToSeeTitle => 'Join to see the discussion';

  @override
  String get clubsJoinToSeeMessage =>
      'Members talk about each pick together. Join the club to read along and add your thoughts.';

  @override
  String clubsYouRole(String role) {
    return 'You: $role';
  }

  @override
  String get clubsRemovedByModeration => 'This club was removed by moderation.';

  @override
  String get clubsJoinClub => 'Join club';

  @override
  String get clubsNoPickModerator =>
      'No pick yet. Choose something great for everyone.';

  @override
  String get clubsNoPickMember => 'No pick yet. Check back soon.';

  @override
  String clubsQuotedNote(String note) {
    return '“$note”';
  }

  @override
  String clubsPostsInDiscussion(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count posts in the discussion',
      one: '1 post in the discussion',
    );
    return '$_temp0';
  }

  @override
  String get clubsSetThisWeeksPick => 'Set this week’s pick';

  @override
  String get clubsDiscussThisPick => 'Discuss this pick';

  @override
  String get clubsPostNotSent => 'Your post could not be sent.';

  @override
  String clubsDiscussionHeading(String title) {
    return 'Discussion · $title';
  }

  @override
  String get clubsDiscussionLoadError => 'The discussion could not load';

  @override
  String get clubsStartConversationTitle => 'Start the conversation';

  @override
  String get clubsStartConversationMessage =>
      'What did you think so far? Your post could be the one that gets everyone talking.';

  @override
  String get clubsLoadMorePosts => 'Load more posts';

  @override
  String get clubsComposerLabel => 'Add to the discussion';

  @override
  String get clubsComposerHint => 'Favourite moment? Biggest surprise?';

  @override
  String get clubsContainsSpoilers => 'Contains spoilers';

  @override
  String get clubsSpoilersSubtitle => 'Others tap to reveal it.';

  @override
  String get clubsPosting => 'Posting…';

  @override
  String get clubsPost => 'Post';

  @override
  String get clubsDeletePostTitle => 'Delete your post?';

  @override
  String get clubsDeletePostMessage =>
      'It is removed from the discussion for everyone.';

  @override
  String get clubsActionFailed => 'That action could not be completed.';

  @override
  String get clubsHideFromMembers => 'Hide from members';

  @override
  String get clubsShowToMembers => 'Show to members';

  @override
  String get clubsReport => 'Report';

  @override
  String get clubsYou => 'You';

  @override
  String get clubsHidden => 'Hidden';

  @override
  String get clubsPostActions => 'Post actions';

  @override
  String get clubsMakeModerator => 'Make moderator';

  @override
  String get clubsMakeMember => 'Make member';

  @override
  String get clubsRemoveFromClub => 'Remove from club';

  @override
  String clubsRemoveMemberTitle(String name) {
    return 'Remove $name?';
  }

  @override
  String get clubsRemoveMemberMessage =>
      'They leave the club and cannot rejoin. Their past posts stay in the discussion.';

  @override
  String get clubsRemove => 'Remove';

  @override
  String get clubsMembersLoadError => 'Members could not load.';

  @override
  String clubsMemberYou(String name) {
    return '$name (you)';
  }

  @override
  String clubsMemberActions(String name) {
    return 'Actions for $name';
  }

  @override
  String get clubsChooseFilm => 'Choose a film';

  @override
  String get clubsChooseBook => 'Choose a book';

  @override
  String get clubsChooseTitle => 'Choose a title';

  @override
  String get clubsChooseTitleFirst => 'Choose a title first.';

  @override
  String get clubsPickNotSaved => 'The pick could not be saved.';

  @override
  String get clubsSetWeeklyPick => 'Set the weekly pick';

  @override
  String get clubsChange => 'Change';

  @override
  String get clubsPickNoteLabel => 'A note for the club (optional)';

  @override
  String get clubsPickNoteHint => 'Why this one? Where to start?';

  @override
  String get clubsSaving => 'Saving…';

  @override
  String get clubsSavePick => 'Save pick';

  @override
  String get clubsListNameRequired => 'Give your list a name.';

  @override
  String get clubsListNotSaved => 'Your list could not be saved.';

  @override
  String get clubsEditList => 'Edit list';

  @override
  String get clubsNewList => 'New list';

  @override
  String get clubsListNameLabel => 'List name';

  @override
  String get clubsListNameHint => 'Books that changed my mind';

  @override
  String get clubsWhoCanSee => 'Who can see it';

  @override
  String get clubsSave => 'Save';

  @override
  String get clubsCreateList => 'Create list';

  @override
  String get clubsYourNote => 'Your note';

  @override
  String get clubsNoteLabel => 'Why it is on this list';

  @override
  String get clubsSaveNote => 'Save note';

  @override
  String get clubsCreateNewListTooltip => 'Create a new list';

  @override
  String get clubsSignInToSeeLists => 'Sign in to see your lists.';

  @override
  String get clubsShelfTitle => 'Your shelf';

  @override
  String get clubsShelfSubtitle =>
      'Keep track of what you loved and what is next. Share a list, or keep it just for you.';

  @override
  String get clubsListsLoadErrorTitle => 'Your lists could not load';

  @override
  String get clubsFirstListTitle => 'Start your first list';

  @override
  String get clubsFirstListMessage =>
      'Favourite films, books to read next, comfort rewatches: it is up to you.';

  @override
  String clubsAddToNamed(String name) {
    return 'Add to $name';
  }

  @override
  String get clubsAddToThisListFailed => 'It could not be added to this list.';

  @override
  String clubsDeleteListTitle(String name) {
    return 'Delete $name?';
  }

  @override
  String get clubsDeleteListMessage =>
      'The list and its notes are removed. This cannot be undone.';

  @override
  String get clubsDeleteList => 'Delete list';

  @override
  String get clubsListDeleteFailed =>
      'The list could not be deleted. Reload and retry.';

  @override
  String get clubsNoteNotSaved => 'Your note could not be saved.';

  @override
  String get clubsRemoveFailed => 'It could not be removed.';

  @override
  String get clubsListOptions => 'List options';

  @override
  String get clubsAddATitle => 'Add a title';

  @override
  String clubsTitleCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count titles',
      one: '1 title',
    );
    return '$_temp0';
  }

  @override
  String get clubsListEmpty =>
      'Nothing here yet. Use “Add a title” from the list menu.';

  @override
  String clubsItemOptions(String title) {
    return 'Options for $title';
  }

  @override
  String get clubsAddNote => 'Add a note';

  @override
  String get clubsEditNote => 'Edit note';

  @override
  String get clubsRemoveFromList => 'Remove from list';

  @override
  String get clubsTapStarError => 'Tap a star to rate it.';

  @override
  String get clubsReviewNotSaved => 'Your review could not be saved.';

  @override
  String get clubsWriteReview => 'Write a review';

  @override
  String get clubsEditYourReview => 'Edit your review';

  @override
  String get clubsTapStarToRate => 'Tap a star to rate';

  @override
  String clubsRatingOutOfFive(int rating) {
    return '$rating out of 5';
  }

  @override
  String get clubsReviewBodyLabel => 'What did you think? (optional)';

  @override
  String get clubsSaveReview => 'Save review';

  @override
  String clubsAddedToList(String name) {
    return 'Added to $name.';
  }

  @override
  String get clubsAddToThatListFailed => 'It could not be added to that list.';

  @override
  String get clubsAddToAList => 'Add to a list';

  @override
  String get clubsListsLoadError => 'Your lists could not load.';

  @override
  String get clubsNoFilmLists =>
      'You have no film lists yet. Create one to start collecting.';

  @override
  String get clubsNoBookLists =>
      'You have no book lists yet. Create one to start collecting.';

  @override
  String get clubsTitleFallback => 'Title';

  @override
  String get clubsSignInToSeeReviews => 'Sign in to see reviews.';

  @override
  String get clubsTitleLoadError => 'This title could not load';

  @override
  String get clubsReviews => 'Reviews';

  @override
  String get clubsNoOtherReviewsTitle => 'No other reviews yet';

  @override
  String get clubsNoOtherReviewsMessage =>
      'When members you can see share a review, it shows up here.';

  @override
  String get clubsDeleteReviewTitle => 'Delete your review?';

  @override
  String get clubsDeleteReviewMessage =>
      'Your rating and words are removed for everyone.';

  @override
  String get clubsDeleteReview => 'Delete review';

  @override
  String get clubsReviewDeleteFailed =>
      'Your review could not be deleted. Reload and retry.';

  @override
  String get clubsWhatDidYouThink => 'What did you think?';

  @override
  String get clubsReviewPrompt =>
      'Rate it and say why. You choose who sees it.';

  @override
  String get clubsYourReview => 'Your review';

  @override
  String get clubsSpoilers => 'Spoilers';

  @override
  String get clubsEdit => 'Edit';

  @override
  String get clubsReportReview => 'Report this review';

  @override
  String get clubsEnterTitle => 'Enter the title.';

  @override
  String get clubsYearRange => 'Enter a year between 1450 and 2100.';

  @override
  String get clubsTitleAddFailed => 'The title could not be added.';

  @override
  String get clubsSearchFilms => 'Search films';

  @override
  String get clubsSearchBooks => 'Search books';

  @override
  String get clubsTypeTwoLetters => 'Type at least 2 letters';

  @override
  String get clubsSearchUnavailable => 'Search is unavailable.';

  @override
  String get clubsNoFilmsMatch => 'No films match. Add it below.';

  @override
  String get clubsNoBooksMatch => 'No books match. Add it below.';

  @override
  String get clubsAddNewFilm => 'Add a new film';

  @override
  String get clubsAddNewBook => 'Add a new book';

  @override
  String get clubsTitleFieldLabel => 'Title';

  @override
  String get clubsDirector => 'Director';

  @override
  String get clubsAuthor => 'Author';

  @override
  String get clubsYearOptional => 'Year (optional)';

  @override
  String get clubsAdding => 'Adding…';

  @override
  String get clubsAddAndChoose => 'Add and choose';

  @override
  String get friendsIntroducerSaveFailed =>
      'We couldn’t save that. Refresh to check the latest permissions before trying again.';

  @override
  String friendsIntroducerRevokeTitle(String name) {
    return 'Remove permission for $name?';
  }

  @override
  String get friendsIntroducerRevokeBody =>
      'New and unanswered introductions will stop. An existing mutual match stays between the two people.';

  @override
  String get friendsIntroducerKeepPermission => 'Keep permission';

  @override
  String get friendsIntroducerRemovePermission => 'Remove permission';

  @override
  String get friendsIntroducerPermissionRemoved => 'Permission removed.';

  @override
  String get friendsIntroducerMemberTitle => 'Your introducers';

  @override
  String get friendsIntroducerAppTitle => 'Connect · Friends';

  @override
  String get friendsIntroducerRefresh => 'Refresh permissions';

  @override
  String get friendsIntroducerAccount => 'Account';

  @override
  String get friendsIntroducerAccountPrivacy => 'Account & privacy';

  @override
  String get friendsIntroducerSignOut => 'Sign out';

  @override
  String get friendsIntroducerMemberHeadline => 'Good friends. Your say.';

  @override
  String get friendsIntroducerHeadline =>
      'You know them.\nYou see the possibility.';

  @override
  String get friendsIntroducerMemberIntro =>
      'Invite someone you trust to introduce you. They can join without a dating profile. You decide who gets permission and what a preview shares.';

  @override
  String get friendsIntroducerIntro =>
      'A little thoughtfulness can start something real. Bring together friends who have asked for your help.';

  @override
  String get friendsIntroducerMemberListTitle => 'People you choose';

  @override
  String get friendsIntroducerListTitle => 'Your small circle';

  @override
  String get friendsIntroducerLoadFailed =>
      'We couldn’t load permissions. Nothing has been changed.';

  @override
  String get friendsIntroducerMemberEmpty =>
      'No introducers yet. Share an invitation with one trusted friend to get started.';

  @override
  String get friendsIntroducerEmpty =>
      'Your circle starts with permission. Ask a friend on Connect for their invitation code.';

  @override
  String get friendsIntroducerStatusPendingMember =>
      'Wants your permission to introduce you.';

  @override
  String get friendsIntroducerStatusPending =>
      'Waiting for your friend’s approval.';

  @override
  String get friendsIntroducerStatusPaused => 'Introductions are paused.';

  @override
  String get friendsIntroducerStatusActive =>
      'Permission to suggest introductions.';

  @override
  String friendsIntroducerPreview(String extras) {
    String _temp0 = intl.Intl.selectLogic(extras, {
      'photo':
          'Preview shared with a suggested date: name and optional age, photo.',
      'city':
          'Preview shared with a suggested date: name and optional age, city.',
      'both':
          'Preview shared with a suggested date: name and optional age, photo, city.',
      'other': 'Preview shared with a suggested date: name and optional age.',
    });
    return '$_temp0';
  }

  @override
  String get friendsIntroducerApproveNote =>
      'Approving also turns on friend introductions. You can pause all introductions in Dating rhythm.';

  @override
  String get friendsIntroducerAllow => 'Allow introductions';

  @override
  String friendsIntroducerAllowed(String name) {
    return '$name now has your permission.';
  }

  @override
  String get friendsIntroducerDecline => 'Decline request';

  @override
  String get friendsIntroducerSentTitle => 'Thoughtfully sent';

  @override
  String get friendsIntroducerSentBody =>
      'Their answers stay between them. Both people must say yes before a match is made.';

  @override
  String get friendsIntroducerReloadSent => 'Reload sent introductions';

  @override
  String get friendsIntroducerSentSubtitle =>
      'Sent · their decision is private';

  @override
  String get friendsIntroducerStepPreview => '1. Choose the preview';

  @override
  String get friendsIntroducerPreviewBody =>
      'A suggested date sees your name and age if you already show it. Your introducer sees only your name, never your profile or dating activity.';

  @override
  String get friendsIntroducerIncludePhoto => 'Include my profile photo';

  @override
  String get friendsIntroducerIncludeCity => 'Include my city';

  @override
  String get friendsIntroducerStepInvite => '2. Invite one trusted friend';

  @override
  String get friendsIntroducerInviteBody =>
      'The code works once and expires in 48 hours. Your friend joins through “Just here to introduce friends” on the welcome screen. You’ll approve their name here before anything can be shared.';

  @override
  String get friendsIntroducerInviteReady =>
      'Invitation ready. Any previous unused code no longer works.';

  @override
  String get friendsIntroducerCreateCode => 'Create invitation code';

  @override
  String get friendsIntroducerShareCode =>
      'Share privately with your friend. To change this preview, cancel the unused invitation and create a new code.';

  @override
  String get friendsIntroducerCodeCopied => 'Invitation code copied';

  @override
  String get friendsIntroducerCopyCode => 'Copy code';

  @override
  String get friendsIntroducerInvitesCancelled =>
      'Unused invitations cancelled.';

  @override
  String get friendsIntroducerCancelInvites => 'Cancel unused invitations';

  @override
  String get friendsIntroducerManagePrefs =>
      'Manage all introduction preferences';

  @override
  String get friendsIntroducerRedeemTitle => 'A friend invited you?';

  @override
  String get friendsIntroducerRedeemBody =>
      'Paste their private invitation code. They’ll confirm your name before you can introduce them.';

  @override
  String get friendsIntroducerCodeLabel => 'Invitation code';

  @override
  String get friendsIntroducerCodeMissing =>
      'Enter the invitation code your friend shared.';

  @override
  String get friendsIntroducerRequestSent =>
      'Request sent. Your friend can now approve you in Your introducers.';

  @override
  String get friendsIntroducerAskPermission => 'Ask for permission';

  @override
  String get friendsIntroducerNeedTwo =>
      'Once two friends give permission, you can suggest an introduction here.';

  @override
  String get friendsIntroducerComposerTitle => 'See a possibility?';

  @override
  String get friendsIntroducerWhyLabel => 'Why you thought of them (optional)';

  @override
  String get friendsIntroducerWhyHelper =>
      'Both will see this. Keep private details out.';

  @override
  String get friendsIntroducerIntroSent =>
      'Introduction sent. They can each decide in private.';

  @override
  String get friendsIntroducerSuggest => 'Suggest an introduction';

  @override
  String get friendsIntroducerPrivacyNote =>
      'Permission first. No public dating activity. No updates on who said yes or no.';

  @override
  String get planSharingLoadFailed => 'Unable to load sharing choices.';

  @override
  String get planSharingOffSnack => 'Your contact sharing is off.';

  @override
  String get planSharingSavedSnack =>
      'Your selected contacts can now see this plan.';

  @override
  String get planSharingSaveFailed =>
      'Unable to save. Reload choices before trying again.';

  @override
  String get planSharingTitle => 'Your plan. Your people.';

  @override
  String get planSharingCloseTooltip => 'Close sharing';

  @override
  String get planSharingIntro =>
      'Sharing with contacts starts off. Choose up to 10 trusted friends for this plan. Your date chooses their own contacts.';

  @override
  String get planSharingNoContacts =>
      'No eligible friends yet. Your plan is still available to you and your date.';

  @override
  String get planSharingFriendFallback => 'A friend';

  @override
  String get planSharingPreviewNone => 'Preview · no contacts selected';

  @override
  String planSharingPreviewCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Preview · $count selected',
    );
    return '$_temp0';
  }

  @override
  String get planSharingPreviewOffBody =>
      'Your friends will receive no plan or check-in updates from you.';

  @override
  String get planSharingPreviewOnBody =>
      'These contacts can see your date’s name, the time and place, plan status, and your check-in updates. They receive the current plan when you save.';

  @override
  String get planSharingPrivacyNote =>
      'Messages and private post-date feedback stay private. Removing a contact stops future updates and removes their in-app plan access. Updates already delivered to a device cannot be recalled.';

  @override
  String get planSharingReload => 'Reload sharing choices';

  @override
  String get planSharingSaving => 'Saving…';

  @override
  String get planSharingKeepOff => 'Keep contact sharing off';

  @override
  String get planSharingShareSelected => 'Share with selected contacts';

  @override
  String get planSharingDeselectAll => 'Deselect everyone';

  @override
  String planBudgetLine(String budget) {
    return 'Budget · $budget';
  }

  @override
  String planAtmosphereLine(String atmospheres) {
    return 'Atmosphere · $atmospheres';
  }

  @override
  String get planAtmosphereQuiet => 'Quiet conversation';

  @override
  String get planAtmosphereRelaxed => 'Relaxed & unhurried';

  @override
  String get planAtmosphereLively => 'A lively setting';

  @override
  String get planAtmosphereOutdoors => 'Outdoors';

  @override
  String get planAtmosphereIndoors => 'Indoors';

  @override
  String get planAccessStepFree => 'Step-free access';

  @override
  String get planAccessToilet => 'Accessible toilet';

  @override
  String get planAccessSeating => 'Seating available';

  @override
  String get planAccessLowNoise => 'Low background noise';

  @override
  String get planAccessTransit => 'Near public transport';

  @override
  String get planAccessCaptions => 'Captions for a video date';

  @override
  String get planComfortHeading => 'To make this comfortable';

  @override
  String get planPreferencesDisclaimer =>
      'Preferences shared for this plan. Confirm these details with the venue or video service.';

  @override
  String get planProposeErrorKept =>
      'Your plan could not be sent. Your choices are still here.';

  @override
  String get planChangedError =>
      'This plan has changed. Close this sheet to review the conversation.';

  @override
  String get planProposeHeadline => 'A plan you both look forward to.';

  @override
  String get planCounterHeadline => 'Shape this plan together';

  @override
  String planProposeLead(String name) {
    return 'A suggestion for you and $name. Nothing is agreed until the other person accepts this version.';
  }

  @override
  String get planFindTimeTitle => 'Find a little time together';

  @override
  String get planFindTimeBody =>
      'Only overlapping times are shown when both of you choose to share availability. You can always suggest a time yourself.';

  @override
  String get planSharedTimesFailed =>
      'Shared times couldn’t load. Your manual time is still available.';

  @override
  String get planSharedTimesEmpty =>
      'No shared time suggestions right now. This does not mean either of you is unavailable.';

  @override
  String get planRefreshSharedTimes => 'Refresh shared times';

  @override
  String get planSetAvailability => 'Set my availability';

  @override
  String get planWhenTitle => 'When would feel right?';

  @override
  String get planTimeSourceManual => 'A time you’re suggesting';

  @override
  String get planTimeSourceShared =>
      'Selected from shared availability · checked again when sent';

  @override
  String planLocalTimeNote(int minutes, String timeZone) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other:
          'Your device’s local time ($timeZone). Duration: $minutes minutes.',
    );
    return '$_temp0';
  }

  @override
  String planDurationChip(int minutes) {
    return '$minutes min';
  }

  @override
  String get planEnjoyTitle => 'Something you would enjoy';

  @override
  String get planAreaHint => 'A neighbourhood or public meeting area';

  @override
  String get planBudgetTitle => 'What budget feels comfortable?';

  @override
  String get planBudgetBody =>
      'A starting point to agree together, not a price quote or a promise about who pays.';

  @override
  String get planAtmosphereTitle => 'Set the atmosphere';

  @override
  String get planAtmosphereBody =>
      'Choose up to three settings you would enjoy. Optional.';

  @override
  String get planComfortTitle => 'Make it comfortable for both of you';

  @override
  String get planComfortBody =>
      'Optional accessibility preferences. Selected choices are shared with your match when you send this plan. They are not added to your public profile or trusted-contact updates.';

  @override
  String get planComfortDisclaimer =>
      'You do not need to explain a diagnosis. These are requests to check with the venue or video service, not verified facilities.';

  @override
  String get planNoteHint => 'Saturday afternoon, somewhere quieter?';

  @override
  String get planReviewBeforeSending =>
      'Before sending, review the time and choices above. The other person can accept, decline or suggest a change.';

  @override
  String get planReloadLatest => 'Reload latest plan · discard edits';

  @override
  String get planSending => 'Sending…';

  @override
  String get planSendSuggestion => 'Send your suggestion';

  @override
  String get planSecondYesTitle => 'Share a second yes';

  @override
  String get planSecondYesBody =>
      'Reveal that you want to meet again only if your match also says yes and agrees to share. Your other answers stay private.';

  @override
  String get planSecondYesHeadline => 'A second yes, from both of you';

  @override
  String get planSecondYesCardBody =>
      'You both chose to share that you would like to meet again.';

  @override
  String get planAnotherHello => 'Plan another hello';

  @override
  String get planSuggestChange => 'Suggest a change';

  @override
  String get planChooseUpdates => 'Choose who gets your updates';

  @override
  String planQuotedNote(String note) {
    return '“$note”';
  }

  @override
  String get planStatusDeclined => 'Declined';

  @override
  String get planStatusExpired => 'Expired';

  @override
  String get planStatusCompleted => 'Completed';

  @override
  String get planStatusDidNotHappen => 'Did not happen';

  @override
  String get planStatusDisputed => 'Disputed';

  @override
  String get plansManageSharing => 'Manage your contact sharing';

  @override
  String get plansLoadFailed => 'Unable to load date plans.';

  @override
  String get plansFeedLoadFailed => 'Unable to load plans.';

  @override
  String get planAcceptFailed => 'Unable to accept this plan.';

  @override
  String get planDeclineFailed => 'Unable to decline this plan.';

  @override
  String get planCancelFailed => 'Unable to cancel this plan.';

  @override
  String get planCheckinFailed => 'Unable to check in right now.';

  @override
  String get graduationFoundEachOther => 'You found each other';

  @override
  String graduationHeadlineDecide(String name) {
    return '$name wants to leave Connect together';
  }

  @override
  String graduationHeadlineWaiting(String name) {
    return 'Waiting for $name';
  }

  @override
  String get graduationBodyConfirmed =>
      'You are both hidden from discovery. This chat stays open.';

  @override
  String get graduationBodyDecide =>
      'Confirm and you both leave discovery. Your chat stays.';

  @override
  String get graduationBodyWaiting =>
      'You asked to leave together. They can confirm or decline.';

  @override
  String get graduationCelebrate => 'Celebrate';

  @override
  String get graduationNotYet => 'Not yet';

  @override
  String get graduationConfirm => 'Confirm';

  @override
  String get graduationFriendsToldOnConfirm =>
      'Your friends are told once they confirm.';

  @override
  String get graduationOnlyTwoOfYouForNow =>
      'Only the two of you know for now.';

  @override
  String get graduationWithdraw => 'Withdraw';

  @override
  String graduationProposeTitle(String name) {
    return 'Leave Connect with $name?';
  }

  @override
  String graduationProposeBody(String name) {
    return 'Once $name confirms, you are both hidden from discovery. This chat stays open, and you can come back to discovery from Privacy & Safety at any time.';
  }

  @override
  String get graduationNoteLabel => 'A note for them (optional)';

  @override
  String get graduationNoteHint => 'Say why you are ready';

  @override
  String get graduationTellFriends => 'Tell my friends';

  @override
  String get graduationTellFriendsBody =>
      'Your accepted friends hear you found someone. They are not told who.';

  @override
  String get graduationAskThem => 'Ask them';

  @override
  String get graduationTitle => 'Graduation';

  @override
  String graduationCelebrationBody(String name) {
    return 'You and $name are leaving Connect together. You are both hidden from discovery, and this chat stays open for as long as you like.';
  }

  @override
  String get graduationFriendsHaveBeenTold => 'Your friends have been told.';

  @override
  String get graduationFriendsAreTold => 'Your friends are told.';

  @override
  String get graduationOnlyTwoOfYou => 'Only the two of you know.';

  @override
  String get graduationConfirmAndBack => 'Confirm and go back';

  @override
  String get graduationBackToConnect => 'Back to Connect';

  @override
  String get graduationLoadFailed => 'Unable to load graduation.';

  @override
  String get graduationProposeFailed => 'Unable to propose leaving together.';

  @override
  String get graduationConfirmFailed => 'Unable to confirm right now.';

  @override
  String get graduationDeclineFailed => 'Unable to decline right now.';

  @override
  String get graduationWithdrawFailed => 'Unable to withdraw the proposal.';

  @override
  String get graduationPauseLoadFailed => 'Unable to load discovery status.';

  @override
  String get graduationPauseFailed => 'Unable to pause discovery.';

  @override
  String get graduationResumeFailed => 'Unable to resume discovery.';

  @override
  String get engagementCirclesEmptyTitle => 'No circles available';

  @override
  String get engagementCirclesPullToRefresh => 'Please pull to refresh.';

  @override
  String get engagementCirclesJoined => 'Joined';

  @override
  String get engagementCirclesNotJoined => 'Not joined';

  @override
  String engagementCirclesParticipants(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count participants this week',
    );
    return '$_temp0';
  }

  @override
  String get engagementCirclesJoin => 'Join Circle';

  @override
  String get engagementCirclesResponseLabel => 'Weekly challenge response';

  @override
  String get engagementCirclesSubmit => 'Submit Entry';

  @override
  String get engagementCirclesTopicFallback => 'Circle';

  @override
  String get engagementCirclesLoadFailed => 'Unable to load circles right now.';

  @override
  String get engagementCirclesJoinFailed => 'Unable to join circle right now.';

  @override
  String get engagementCirclesEnterResponse =>
      'Please enter your challenge response.';

  @override
  String get engagementCirclesSubmitFailed =>
      'Unable to submit challenge entry right now.';

  @override
  String get engagementNudgesTitle => 'Match nudges';

  @override
  String get engagementNudgesIntro =>
      'Send a gentle reminder to restart a quiet conversation. Daily limits and safety rules are enforced by the server.';

  @override
  String get engagementNudgesEmpty => 'No matches available to nudge.';

  @override
  String get engagementNudgesSentInSession => 'Nudge sent in this session';

  @override
  String get engagementNudgesReady => 'Ready to send';

  @override
  String engagementNudgesSentTo(String name) {
    return 'Nudge sent to $name.';
  }

  @override
  String get engagementNudgesAction => 'Nudge';

  @override
  String get engagementNudgesSendFailed => 'Unable to send this nudge.';

  @override
  String get engagementTrustBadgesEarned => 'Earned Badges';

  @override
  String get engagementTrustBadgesEmpty =>
      'No badges yet. Complete activities to unlock trust badges.';

  @override
  String engagementTrustBadgesDetails(
    String code,
    String status,
    String awardedAt,
  ) {
    return 'Code: $code\nStatus: $status • Awarded $awardedAt';
  }

  @override
  String get engagementTrustBadgesHistory => 'Recent History';

  @override
  String get engagementTrustBadgesHistoryEmpty =>
      'No trust history available yet.';

  @override
  String get engagementTrustBadgesMilestoneUnavailable =>
      'Milestone status unavailable.';

  @override
  String get engagementTrustBadgesCurrentMilestone => 'Current Milestone';

  @override
  String get engagementTrustBadgesLoadFailed =>
      'Failed to load trust badges. Please try again.';

  @override
  String get engagementTrustFiltersEnable => 'Enable trust filters';

  @override
  String get engagementTrustFiltersEnableSubtitle =>
      'Hide profiles that do not meet your trust requirements';

  @override
  String engagementTrustFiltersMinimum(int count) {
    return 'Minimum active badges: $count';
  }

  @override
  String get engagementTrustFiltersRequired => 'Required badges';

  @override
  String get engagementTrustFiltersSaved => 'Trust filters saved.';

  @override
  String get engagementTrustFiltersSave => 'Save Trust Filters';

  @override
  String get engagementAppealStatusSubmitted => 'Submitted';

  @override
  String get engagementAppealStatusUnderReview => 'Under review';

  @override
  String get engagementAppealStatusResolvedUpheld => 'Resolved (upheld)';

  @override
  String get engagementAppealStatusResolvedReversed => 'Resolved (reversed)';

  @override
  String get engagementRoomsLeaveFailed =>
      'Could not leave this room. Please retry.';

  @override
  String get engagementRoomsPresenceFailed => 'Lost touch with the room.';

  @override
  String get engagementRoomsMembersFailed =>
      'Could not load who is here. Please retry.';

  @override
  String get engagementRoomsModerationFailed =>
      'That did not go through. Please retry.';

  @override
  String get engagementRoomsCreateFailed =>
      'Could not start the room. Please retry.';

  @override
  String get engagementRoomsLoadFailed =>
      'Rooms are unavailable right now. Pull to retry.';

  @override
  String get commonSave => 'Save';

  @override
  String get commonRemove => 'Remove';

  @override
  String get accountTitle => 'Account & Data';

  @override
  String get accountLoadFailed => 'Could not load your account status.';

  @override
  String accountDeletionIn(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'Deletion in $days days',
      one: 'Deletion in 1 day',
    );
    return '$_temp0';
  }

  @override
  String get accountDeletionDue => 'Deletion is due';

  @override
  String get accountDeletionCountdownBody =>
      'Your profile is hidden. You can still sign in and cancel until then — after that your data cannot be recovered.';

  @override
  String get accountKeepMyAccount => 'Keep my account';

  @override
  String get accountNotDeletedSnack => 'Your account will not be deleted.';

  @override
  String get accountCancelFailed => 'Could not cancel. Please try again.';

  @override
  String get accountHiddenTitle => 'Your profile is hidden';

  @override
  String get accountTakeBreakTitle => 'Take a break';

  @override
  String get accountHiddenBody =>
      'Nobody can see or match with you. Your matches and messages are kept, and you can come back whenever you want.';

  @override
  String get accountTakeBreakBody =>
      'Hide your profile from Discover without losing anything. You stay signed in and can switch back at any time.';

  @override
  String get accountUnhideProfile => 'Unhide my profile';

  @override
  String get accountHideProfile => 'Hide my profile';

  @override
  String get accountVisibleAgainSnack => 'Your profile is visible again.';

  @override
  String get accountNowHiddenSnack => 'Your profile is now hidden.';

  @override
  String get accountUpdateFailed => 'Could not update. Please try again.';

  @override
  String get accountDownloadTitle => 'Download your data';

  @override
  String get accountDownloadBody =>
      'Get a copy of your profile, preferences, matches and the messages you sent. Messages other people wrote are not included.';

  @override
  String get accountPreparing => 'Preparing…';

  @override
  String get accountPrepareData => 'Prepare my data';

  @override
  String get accountPrepareFailed =>
      'Could not prepare your data. Please try again.';

  @override
  String get accountYourData => 'Your data';

  @override
  String get accountDeleteTitle => 'Delete my account';

  @override
  String get accountDeleteBody =>
      'Your profile is hidden straight away and everything is erased after a grace period. You can cancel during that time by signing in. Afterwards nothing can be recovered.';

  @override
  String get accountDeletionAlreadyScheduled => 'Deletion already scheduled';

  @override
  String get accountDeleteConfirmTitle => 'Delete your account?';

  @override
  String get accountDeleteConfirmBody =>
      'Your profile, photos, matches and messages will be erased and cannot be recovered.\n\nIf you just want a break, hiding your profile keeps everything and can be undone.';

  @override
  String get accountHideInstead => 'Hide instead';

  @override
  String get accountDeletionScheduledSnack =>
      'Deletion scheduled. You can cancel until then.';

  @override
  String get privacyTitle => 'Privacy & Safety';

  @override
  String get privacyShowAge => 'Show age';

  @override
  String get privacyShowAgeSubtitle => 'Control whether your age is visible';

  @override
  String get privacyShowDistance => 'Show exact distance';

  @override
  String get privacyShowDistanceSubtitle =>
      'Show precise distance on your profile';

  @override
  String get privacyShowOnline => 'Show online status';

  @override
  String get privacyShowOnlineSubtitle =>
      'Allow others to see if you are online';

  @override
  String get privacyEmergencySos => 'Emergency SOS';

  @override
  String get privacyEmergencySosSubtitle =>
      'Activate an alert and review alert history';

  @override
  String get privacyEmergencyContacts => 'Emergency Contacts';

  @override
  String get privacyEmergencyContactsSubtitle =>
      'Manage trusted emergency contacts';

  @override
  String get privacyBlockedUsers => 'Blocked Users';

  @override
  String get privacyBlockedUsersSubtitle => 'Review and unblock users';

  @override
  String get privacyModerationAppeals => 'Moderation Appeals';

  @override
  String get privacyModerationAppealsSubtitle =>
      'Submit an appeal and track review status';

  @override
  String get privacyFriendSearch => 'Let people find me in friend search';

  @override
  String get privacySettingLoadFailed =>
      'This setting could not load. Open this page again to retry.';

  @override
  String get privacyFriendSearchSubtitle =>
      'Members can find you by name or @username in Add friend. People you match or meet in rooms and groups can still add you.';

  @override
  String get privacyChoiceSaveFailed => 'Your choice could not be saved.';

  @override
  String get privacyShowcase => 'Show my public writing on my profile';

  @override
  String get privacyShowcaseSubtitle =>
      'Members can see the chapters you share with the community and your photos on the wall on your profile. Private and friends-only chapters never appear.';

  @override
  String get privacyCrashReports => 'Share crash reports';

  @override
  String get privacyCrashReportsSubtitle =>
      'Anonymous crash and error reports help us fix problems. No messages, photos or account details are included.';

  @override
  String get privacyGraduatedReason =>
      'You left Connect with your match. Nobody is dealt your card.';

  @override
  String get privacyPausedReason =>
      'Nobody is dealt your card until you resume.';

  @override
  String get privacyActiveReason =>
      'You are shown to other members in discovery.';

  @override
  String get privacyDiscoveryPaused => 'Discovery paused';

  @override
  String get privacyDiscoveryActive => 'Discovery active';

  @override
  String get privacyResume => 'Resume';

  @override
  String get privacyPause => 'Pause';

  @override
  String get emergencyIntro =>
      'Add up to 3 trusted contacts. These contacts are used for safety workflows and SOS features in later phases.';

  @override
  String get emergencyEmpty => 'No emergency contacts added yet.';

  @override
  String get emergencyMaxReached => 'Maximum contacts added';

  @override
  String get emergencyAddContact => 'Add Contact';

  @override
  String get emergencyEditContact => 'Edit Contact';

  @override
  String get emergencyInvalidInput => 'Enter a valid name and phone number.';

  @override
  String get emergencyAdded => 'Emergency contact added.';

  @override
  String get emergencyAddFailed => 'Failed to add contact. Please try again.';

  @override
  String get emergencyUpdated => 'Emergency contact updated.';

  @override
  String get emergencyUpdateFailed =>
      'Failed to update contact. Please try again.';

  @override
  String get emergencyRemoveTitle => 'Remove Contact';

  @override
  String emergencyRemoveBody(String name) {
    return 'Remove $name from emergency contacts?';
  }

  @override
  String get emergencyRemoved => 'Emergency contact removed.';

  @override
  String get emergencyRemoveFailed =>
      'Failed to remove contact. Please try again.';

  @override
  String get emergencyNameLabel => 'Name';

  @override
  String get emergencyPhoneLabel => 'Phone Number';

  @override
  String get appealsSubmitTitle => 'Submit an appeal';

  @override
  String get appealsReasonLabel => 'Reason';

  @override
  String get appealsReasonHint =>
      'Why should this moderation decision be reviewed?';

  @override
  String get appealsReportIdLabel => 'Report ID (optional)';

  @override
  String get appealsContextLabel => 'Additional context (optional)';

  @override
  String get appealsSubmit => 'Submit appeal';

  @override
  String get appealsEmpty =>
      'No appeals submitted yet. Your submitted appeals will appear here with status updates.';

  @override
  String appealsIdLine(String id) {
    return 'Appeal ID: $id';
  }

  @override
  String appealsSlaLine(String deadline) {
    return 'SLA deadline: $deadline';
  }

  @override
  String appealsReviewedBy(String reviewer) {
    return 'Reviewed by: $reviewer';
  }

  @override
  String get appealsReasonRequired => 'Reason is required.';

  @override
  String get appealsSubmitted => 'Appeal submitted successfully.';

  @override
  String get appealsSubmitFailed =>
      'Failed to submit appeal. Please try again.';

  @override
  String get blockedEmpty => 'You have not blocked any users.';

  @override
  String get blockedUnblock => 'Unblock';

  @override
  String get blockedUnblockTitle => 'Unblock User';

  @override
  String blockedUnblockBody(String name) {
    return 'Unblock $name?';
  }

  @override
  String blockedUnblockedSnack(String name) {
    return '$name has been unblocked.';
  }

  @override
  String get blockedUnblockFailed =>
      'Failed to unblock user. Please try again.';

  @override
  String aboutVersion(String version) {
    return 'Version $version';
  }

  @override
  String get aboutDescription =>
      'Trust-first dating app focused on authentic profiles, safe communication, and serious relationships.';

  @override
  String get aboutStack => 'Stack';

  @override
  String get aboutStackFlutter => 'Flutter (Android-first)';

  @override
  String get aboutStackGo => 'Go services + native PostgreSQL';

  @override
  String get aboutStackRiverpod => 'Riverpod state management';

  @override
  String get communitySpoiler => 'Spoiler — tap to reveal';

  @override
  String get communityReportFailed => 'Report could not be submitted.';

  @override
  String get communityReportSubmitted => 'Report submitted. Thank you.';

  @override
  String communityBlockTitle(String name) {
    return 'Block $name?';
  }

  @override
  String get communityBlockBody =>
      'You will stop seeing each other’s photos, club posts, reviews and lists. This also blocks contact through Connect.';

  @override
  String get communityBlockAction => 'Block member';

  @override
  String get communityBlockFailed =>
      'Could not block this member. Please retry.';

  @override
  String get reportSheetTitle => 'Report';

  @override
  String get reportReasonHarassment => 'Harassment';

  @override
  String get reportReasonInappropriate => 'Inappropriate content';

  @override
  String get reportReasonFraud => 'Fraud / scam';

  @override
  String get reportReasonFake => 'Fake profile';

  @override
  String get reportReasonLabel => 'Reason';

  @override
  String get reportDescriptionLabel => 'Description (optional)';

  @override
  String get reportDescriptionHint => 'Add context to help review your report';

  @override
  String get reportSubmitFailed => 'Failed to submit report. Please try again.';

  @override
  String get reportSubmit => 'Submit report';

  @override
  String get membershipTitle => 'Membership';

  @override
  String get membershipChooseYourPlan => 'Choose your plan';

  @override
  String get membershipCycleNoteMonthly =>
      'Pay by card. Renews automatically every month until you turn it off.';

  @override
  String get membershipCycleNoteYearly =>
      'Pay by card. Renews automatically every year until you turn it off.';

  @override
  String get membershipNoPlansOnSale => 'No plans are on sale right now.';

  @override
  String get membershipPaymentsTitle => 'Payments';

  @override
  String get membershipNoCardPayments => 'No card payments yet.';

  @override
  String get membershipFooterNote =>
      'Your plan renews automatically at the end of each billing period. Turn off auto-renew at any time; you keep your benefits until the period ends. Card details are handled by the payment provider and never stored in the app.';

  @override
  String membershipSwitchTitle(String plan) {
    return 'Switch to $plan?';
  }

  @override
  String membershipSwitchUpgradeBodyMonthly(String price) {
    return 'Your card is charged now for the difference for the rest of this period, then $price per month from the next renewal.';
  }

  @override
  String membershipSwitchUpgradeBodyYearly(String price) {
    return 'Your card is charged now for the difference for the rest of this period, then $price per year from the next renewal.';
  }

  @override
  String membershipSwitchDowngradeBodyMonthly(
    String currentPlan,
    String price,
  ) {
    return 'Your plan changes now. Unused time on $currentPlan is credited against your next renewal, then you pay $price per month.';
  }

  @override
  String membershipSwitchDowngradeBodyYearly(String currentPlan, String price) {
    return 'Your plan changes now. Unused time on $currentPlan is credited against your next renewal, then you pay $price per year.';
  }

  @override
  String get membershipNotNow => 'Not now';

  @override
  String get membershipUpgrade => 'Upgrade';

  @override
  String get membershipSwitchPlan => 'Switch plan';

  @override
  String membershipSwitchedSnack(String plan) {
    return 'You\'re on $plan now.';
  }

  @override
  String get membershipCardUpdated => 'Your card has been updated.';

  @override
  String get membershipCardUpdatePending =>
      'Card update not confirmed yet. Check its status before trying again.';

  @override
  String get membershipCardUpdateEnded =>
      'This card update session has ended. Refresh to see your current card.';

  @override
  String get membershipCheckoutTitleCard => 'your card';

  @override
  String get membershipAutoRenewOffTitle => 'Turn off auto-renew?';

  @override
  String membershipAutoRenewOffBodyDate(String plan, String date) {
    return 'Your $plan benefits stay active until $date. After that you move to the Free plan and your card is not charged again.';
  }

  @override
  String membershipAutoRenewOffBodyPeriodEnd(String plan) {
    return 'Your $plan benefits stay active until the end of the current period. After that you move to the Free plan and your card is not charged again.';
  }

  @override
  String get membershipKeepRenewing => 'Keep renewing';

  @override
  String get membershipTurnOff => 'Turn off';

  @override
  String get membershipAutoRenewBackOn => 'Auto-renew is back on.';

  @override
  String get membershipAutoRenewNowOff =>
      'Auto-renew is off. Your benefits continue until the period ends.';

  @override
  String membershipSubscribeTitle(String plan) {
    return 'Subscribe to $plan';
  }

  @override
  String membershipSubscribeBodyMonthly(String price) {
    return '$price per month, charged to your card and renewed automatically until you turn auto-renew off. You will enter your card on the payment provider\'s secure page.';
  }

  @override
  String membershipSubscribeBodyYearly(String price) {
    return '$price per year, charged to your card and renewed automatically until you turn auto-renew off. You will enter your card on the payment provider\'s secure page.';
  }

  @override
  String membershipSubscribeBodyTestMonthly(String price) {
    return 'Test checkout only — no real charge. $price per month, simulated and renewed automatically until you turn auto-renew off. You will enter your card on the payment provider\'s secure page.';
  }

  @override
  String membershipSubscribeBodyTestYearly(String price) {
    return 'Test checkout only — no real charge. $price per year, simulated and renewed automatically until you turn auto-renew off. You will enter your card on the payment provider\'s secure page.';
  }

  @override
  String get membershipContinueToCard => 'Continue to card';

  @override
  String get paymentStillConfirming =>
      'Payment is still being confirmed. Pull to refresh in a moment.';

  @override
  String get membershipCheckoutEnded =>
      'This checkout session has ended. Refresh your payment history before trying again.';

  @override
  String get membershipRecoverAccountUnavailable =>
      'Unable to check the payment account. Please retry.';

  @override
  String get membershipRecoverCheckoutClosed =>
      'Payment account refreshed. This checkout is no longer open.';

  @override
  String get membershipRecoverConfirmed =>
      'Confirmed. Your payment account is up to date.';

  @override
  String get membershipRecoverPending =>
      'Confirmation is still pending. You can check again here.';

  @override
  String get membershipRecoverEnded =>
      'This checkout session has ended. Review your payment history before starting another.';

  @override
  String membershipCelebrateTitle(String plan) {
    return 'You\'re $plan now';
  }

  @override
  String get membershipCelebrateBodyTest =>
      'Test payment confirmed; no real money was charged. Your test plan renews automatically. Manage auto-renew any time from this screen.';

  @override
  String get membershipCelebrateBody =>
      'Payment confirmed. Your plan renews automatically. Manage auto-renew any time from this screen.';

  @override
  String get membershipStartExploring => 'Start exploring';

  @override
  String get membershipYourMembership => 'Your membership';

  @override
  String get membershipYourPlan => 'Your plan';

  @override
  String get membershipFreePlanName => 'Free';

  @override
  String membershipPricePerMonthShort(String price) {
    return '$price/mo';
  }

  @override
  String membershipPricePerYearShort(String price) {
    return '$price/yr';
  }

  @override
  String get membershipCardOnFile => 'Card on file with the payment provider';

  @override
  String get membershipCardBrandFallback => 'Card';

  @override
  String get paymentOpening => 'Opening…';

  @override
  String get membershipUpdateCard => 'Update card';

  @override
  String get membershipLastPaymentFailed =>
      'Last payment failed. We will retry your card; benefits stay active for a few days.';

  @override
  String membershipRenewsOn(String date) {
    return 'Renews on $date';
  }

  @override
  String get membershipRenewsSoon => 'Renews soon';

  @override
  String membershipEndsOn(String date) {
    return 'Ends on $date · auto-renew is off';
  }

  @override
  String get membershipEndsSoon => 'Ends soon · auto-renew is off';

  @override
  String get membershipAutoRenew => 'Auto-renew';

  @override
  String get membershipAutoRenewOnSubtitle =>
      'Charged automatically each period.';

  @override
  String get membershipAutoRenewOffSubtitle =>
      'Off. Benefits end with the current period.';

  @override
  String get membershipFreeHeroBody =>
      'Unlock more likes, messages and spotlight with a plan below. Pay by card, cancel any time.';

  @override
  String get membershipStatusFree => 'Free';

  @override
  String get membershipStatusPaymentDue => 'Payment due';

  @override
  String get membershipStatusEnding => 'Ending';

  @override
  String get membershipStatusActive => 'Active';

  @override
  String get membershipCycleMonthly => 'Monthly';

  @override
  String get membershipCycleYearly => 'Yearly';

  @override
  String get membershipBadgeYourPlan => 'YOUR PLAN';

  @override
  String get membershipBadgeMostPopular => 'MOST POPULAR';

  @override
  String get membershipPerMonth => 'per month';

  @override
  String get membershipPerYear => 'per year';

  @override
  String membershipSavePercent(int percent) {
    return 'Save $percent%';
  }

  @override
  String membershipQuotaLikesPerDay(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count likes/day',
      one: '1 like/day',
    );
    return '$_temp0';
  }

  @override
  String membershipQuotaMessagesPerDay(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count messages/day',
      one: '1 message/day',
    );
    return '$_temp0';
  }

  @override
  String get membershipQuotaUnlimitedLikes => 'Unlimited likes';

  @override
  String get membershipQuotaUnlimitedMessages => 'Unlimited messages';

  @override
  String get membershipYourCurrentPlan => 'Your current plan';

  @override
  String get membershipSwitching => 'Switching…';

  @override
  String get membershipOpeningSecureCheckout => 'Opening secure checkout…';

  @override
  String membershipSwitchToPlan(String plan) {
    return 'Switch to $plan';
  }

  @override
  String get membershipSubscribeWithCard => 'Subscribe with card';

  @override
  String get membershipSettleBeforeSwitch =>
      'Settle the outstanding payment on your current plan before switching.';

  @override
  String get membershipPaymentChargeback => 'Chargeback';

  @override
  String get membershipPaymentDisputed => 'Disputed';

  @override
  String get membershipPaymentRefunded => 'Refunded';

  @override
  String get membershipPaymentPartlyRefunded => 'Partly refunded';

  @override
  String get membershipPaymentFailed => 'Failed';

  @override
  String get membershipPaymentPaid => 'Paid';

  @override
  String get membershipPaymentPending => 'Pending';

  @override
  String get membershipPaymentReasonFirstCharge => 'First charge';

  @override
  String get membershipPaymentReasonRenewal => 'Renewal';

  @override
  String get membershipPaymentReasonPlanChange => 'Plan change';

  @override
  String get membershipPaymentReasonCoins => 'Coins';

  @override
  String get membershipPaymentReasonLocalActivation => 'Local activation';

  @override
  String get membershipPaymentReasonCard => 'Card payment';

  @override
  String get membershipPaymentReasonOther => 'Payment';

  @override
  String get paymentModeSandbox => 'Local test · no real charge';

  @override
  String get paymentModeStripeTest => 'Stripe test · no real charge';

  @override
  String get paymentModeLive => 'Live payments';

  @override
  String get paymentModeUnavailable => 'Payments unavailable';

  @override
  String get paymentAccountTitle => 'Your payment account';

  @override
  String get paymentAccountSignedInMember => 'Signed-in member';

  @override
  String get paymentAccountCardTitle => 'Credit or debit card';

  @override
  String get paymentAccountCardUnavailableTitle =>
      'Card checkout is unavailable';

  @override
  String get paymentAccountCardBody =>
      'Use the hosted checkout to enter your card. Membership and payment history belong to this account.';

  @override
  String get paymentAccountCardUnavailableBody =>
      'You can keep using your existing account. New card payments are not enabled.';

  @override
  String paymentAccountTestCardHint(String cardNumber) {
    return 'For testing, use $cardNumber, a future expiry and any three-digit CVC. Use test details only.';
  }

  @override
  String get paymentAccountUnfinishedCardUpdate => 'Unfinished card update';

  @override
  String paymentAccountUnfinishedCheckout(String plan) {
    return 'Unfinished $plan checkout';
  }

  @override
  String get paymentAccountPendingHint =>
      'Check the latest status or continue the same checkout.';

  @override
  String get paymentAccountCheckStatus => 'Check status';

  @override
  String get paymentAccountResumeCheckout => 'Resume checkout';

  @override
  String paymentCheckoutPayFor(String title) {
    return 'Pay for $title';
  }

  @override
  String get paymentCheckoutClose => 'Close checkout';

  @override
  String get paymentCheckoutSecureNote =>
      'Card details are entered on the payment provider\'s secure page.';

  @override
  String paymentCheckoutCompleteInNewTab(String title) {
    return 'Complete the checkout for $title in the new tab';
  }

  @override
  String get paymentCheckoutWaitingBody =>
      'Your card details are entered on the payment provider\'s secure page. Come back here when it says the payment is complete.';

  @override
  String get paymentCheckoutCheckConfirmation => 'Check confirmation';

  @override
  String get paymentCheckoutBackToAccount => 'Back to account';

  @override
  String get paymentWalletTitle => 'Wallet & Payments';

  @override
  String get paymentWalletTestNote =>
      'Test payments · no real charge. Use test card details only.';

  @override
  String get paymentWalletPopularTopUps => 'Popular top-ups';

  @override
  String get paymentWalletTopUpsIntro =>
      'Pay by card on the secure checkout page. Coins land in your wallet as soon as the payment settles.';

  @override
  String get paymentWalletCardsDisabled =>
      'Card payments are not enabled on this server yet.';

  @override
  String get paymentWalletNoPacks => 'No coin packs are on sale right now.';

  @override
  String get paymentWalletActivity => 'Wallet activity';

  @override
  String get paymentWalletNoPurchases => 'No coin purchases yet.';

  @override
  String get paymentWalletFooter =>
      'Coins are used for gifts and boosts inside Connect. Purchases are final once settled; card details stay with the payment provider.';

  @override
  String paymentCoinCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count coins',
      one: '1 coin',
    );
    return '$_temp0';
  }

  @override
  String paymentCoinsAdded(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count coins added to your wallet.',
      one: '1 coin added to your wallet.',
    );
    return '$_temp0';
  }

  @override
  String paymentPackCoinsUnit(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'coins',
      one: 'coin',
    );
    return '$_temp0';
  }

  @override
  String paymentPackCoinsUnitBonus(int count, int bonus) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'coins · +$bonus bonus',
      one: 'coin · +$bonus bonus',
    );
    return '$_temp0';
  }

  @override
  String get paymentWalletCheckoutEnded =>
      'This checkout session has ended. Review your payment history before trying again.';

  @override
  String get paymentWalletBalanceLabel => 'Glow wallet balance';

  @override
  String get paymentWalletSourceSupport => 'Top-up from support';

  @override
  String get paymentWalletSourcePromo => 'Promotion';

  @override
  String get paymentWalletSourcePurchase => 'Coin purchase';

  @override
  String get paymentErrorSignInSubscriptions =>
      'Please sign in to manage subscriptions.';

  @override
  String get paymentErrorSignInWallet =>
      'Please sign in to manage your wallet.';

  @override
  String get paymentErrorLoadSubscription =>
      'Unable to load subscription details.';

  @override
  String get paymentErrorLoadWallet => 'Unable to load your wallet.';

  @override
  String get paymentErrorStartCheckoutNow =>
      'Unable to start checkout right now.';

  @override
  String get paymentErrorStartCheckout => 'Unable to start checkout.';

  @override
  String get paymentErrorConfirmPayment => 'Unable to confirm the payment yet.';

  @override
  String get paymentErrorAutoRenewOn => 'Unable to turn auto-renew back on.';

  @override
  String get paymentErrorAutoRenewOff => 'Unable to turn off auto-renew.';

  @override
  String get paymentErrorChangePlan => 'Unable to change plan.';

  @override
  String get paymentErrorUpdateCard => 'Unable to update the card.';

  @override
  String get paymentErrorSandboxFailed => 'Sandbox simulation failed.';

  @override
  String get paymentErrorUnreachable =>
      'Cannot reach the local service. Check that the API is running.';

  @override
  String membershipQuotaLikesLeftToday(int remaining, int limit) {
    String _temp0 = intl.Intl.pluralLogic(
      limit,
      locale: localeName,
      other: '$remaining of $limit likes left today',
      one: '$remaining of 1 like left today',
    );
    return '$_temp0';
  }

  @override
  String membershipQuotaMessagesLeftToday(int remaining, int limit) {
    String _temp0 = intl.Intl.pluralLogic(
      limit,
      locale: localeName,
      other: '$remaining of $limit messages left today',
      one: '$remaining of 1 message left today',
    );
    return '$_temp0';
  }

  @override
  String membershipLikeLimitHeadline(int limit, String plan) {
    String _temp0 = intl.Intl.pluralLogic(
      limit,
      locale: localeName,
      other: 'You\'ve used today\'s $limit likes on $plan',
      one: 'You\'ve used today\'s 1 like on $plan',
    );
    return '$_temp0';
  }

  @override
  String membershipMessageLimitHeadline(int limit, String plan) {
    String _temp0 = intl.Intl.pluralLogic(
      limit,
      locale: localeName,
      other: 'You\'ve used today\'s $limit messages on $plan',
      one: 'You\'ve used today\'s 1 message on $plan',
    );
    return '$_temp0';
  }

  @override
  String membershipQuotaResetsAt(String time) {
    return 'Resets at $time';
  }

  @override
  String matchesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count matches',
      one: '$count match',
    );
    return '$_temp0';
  }

  @override
  String get matchesSubtitleConversations =>
      'A little closer, one message at a time.';

  @override
  String get matchesSubtitlePeople =>
      'People you chose. Possibilities you shape together.';

  @override
  String get matchesSearchConversations => 'Search conversations';

  @override
  String get matchesSearchMatches => 'Search your matches';

  @override
  String get matchesFilterAllConversations => 'All conversations';

  @override
  String matchesFilterUnread(int count) {
    return 'Unread · $count';
  }

  @override
  String get matchesLoading => 'Loading matches...';

  @override
  String get matchesLoadErrorTitle => 'Unable to load matches';

  @override
  String get matchesRetry => 'Retry';

  @override
  String get matchesEmptyTitle => 'No matches yet';

  @override
  String matchesTrustFilteredHint(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Trust filters hid $count match(es). Try relaxing trust filters from Discover.',
    );
    return '$_temp0';
  }

  @override
  String get matchesEmptyBody =>
      'Visit Today to discover someone you’d like to meet.';

  @override
  String get matchesNoConversationResults =>
      'No conversations here yet. Try another search or filter.';

  @override
  String get matchesNoPeopleResults => 'No matches found. Try another name.';

  @override
  String get matchesTabPeople => 'Your matches';

  @override
  String get matchesTabConversations => 'Conversations';

  @override
  String get matchesActionStartCall => 'Start call session';

  @override
  String get matchesActionStartActivity => 'Start an activity';

  @override
  String get matchesActionPlanDate => 'Plan a date';

  @override
  String get matchesActionPlanDateSubtitle =>
      'Choose a time and what you want to share';

  @override
  String matchesPlanSent(String name) {
    return 'Plan sent to $name.';
  }

  @override
  String get matchesActionGraduate => 'We found each other';

  @override
  String get matchesActionGraduateSubtitle =>
      'Leave Connect together; your chat stays';

  @override
  String matchesGraduationAsked(String name) {
    return 'Asked $name to leave together. They can confirm from your chat.';
  }

  @override
  String get matchesActionNudge => 'Send a nudge';

  @override
  String matchesNudgeSent(String name) {
    return 'Nudge sent to $name.';
  }

  @override
  String get matchesNudgeFailed => 'Unable to send this nudge.';

  @override
  String get matchesActionClose => 'Close conversation';

  @override
  String get matchesActionCloseSubtitle =>
      'Make space, without an explanation.';

  @override
  String get matchesCloseDialogTitle => 'Close this conversation?';

  @override
  String get matchesCloseDialogBody =>
      'It is okay if this connection is not for you. This ends the match. You do not need to send an explanation. Reporting remains a separate choice.';

  @override
  String get matchesCloseDialogKeep => 'Keep talking';

  @override
  String get matchesActionReport => 'Report';

  @override
  String get matchesReportSubmitted => 'Report submitted. Thank you.';

  @override
  String get matchesReportAppeal => 'Appeal';

  @override
  String matchesAppealReason(String userId) {
    return 'Review moderation outcome for report on user $userId';
  }

  @override
  String get matchesBothChose => 'You both chose to connect';

  @override
  String matchesOptionsTooltip(String name) {
    return 'Match options for $name';
  }

  @override
  String matchesChatUnread(int count) {
    return 'Chat · $count unread';
  }

  @override
  String get matchesOpenChat => 'Open chat';

  @override
  String get matchesFirstChapter => 'First Chapter';

  @override
  String get matchesUnknownName => 'Unknown';

  @override
  String get matchesSayHi => 'Say hi 👋';

  @override
  String get matchesFallbackName => 'Your match';

  @override
  String get matchesFallbackMessage => 'Start your conversation';

  @override
  String get matchesGiftPreview => 'A little gift in your conversation';

  @override
  String matchesConversationOptionsTooltip(String name) {
    return 'Conversation options for $name';
  }

  @override
  String get matchesTimeNow => 'Now';

  @override
  String matchesTimeMinutesAgo(int minutes) {
    return '${minutes}m ago';
  }

  @override
  String matchesTimeHoursAgo(int hours) {
    return '${hours}h ago';
  }

  @override
  String get matchesTimeToday => 'Today';

  @override
  String get matchesTimeYesterday => 'Yesterday';

  @override
  String get matchesNewMatchTitle => 'New Match';

  @override
  String get matchesItsAMatch => 'It\'s a match!';

  @override
  String matchesLikedEachOther(String name) {
    return 'You and $name liked each other';
  }

  @override
  String get matchesSendMessage => 'Send Message';

  @override
  String get matchesKeepSwiping => 'Keep Swiping';

  @override
  String get matchesErrorLoginRequired => 'Please login to see matches.';

  @override
  String get matchesErrorLoadFailed =>
      'Failed to load matches. Please try again.';

  @override
  String get matchesErrorUnmatchFailed => 'Failed to unmatch.';

  @override
  String get matchesErrorMarkReadFailed => 'Failed to mark as read.';

  @override
  String get matchesErrorSessionUnavailable => 'User session not available.';

  @override
  String get matchesTrustBadgePromptCompleter => 'Prompt Completer';

  @override
  String get matchesTrustBadgeRespectful => 'Respectful Communicator';

  @override
  String get matchesTrustBadgeConsistent => 'Consistent Profile';

  @override
  String get matchesTrustBadgeVerifiedActive => 'Verified & Active';

  @override
  String get matchesTrustErrorLoad =>
      'Failed to load trust filters. Please try again.';

  @override
  String get matchesTrustErrorSave =>
      'Failed to save trust filters. Please try again.';

  @override
  String get matchesGestureErrorLoad => 'Failed to load timeline';

  @override
  String get matchesGestureErrorPending =>
      'Gestures unlock after this pending conversation becomes a real match.';

  @override
  String get matchesGestureErrorSend => 'Failed to send gesture.';

  @override
  String get matchesGestureErrorUpdate => 'Failed to update gesture status.';

  @override
  String get matchesActivityTitle => '2-Minute This-or-That';

  @override
  String get matchesActivityRestartTooltip => 'Start a new session';

  @override
  String matchesActivityCompleteWith(String name) {
    return 'Complete this with $name';
  }

  @override
  String get matchesActivityInstructions =>
      'Answer all 8 rounds before time ends.';

  @override
  String matchesActivityStatus(String status) {
    return 'Status: $status';
  }

  @override
  String get matchesActivityStatusActive => 'active';

  @override
  String get matchesActivityStatusTimedOut => 'timed out';

  @override
  String get matchesActivityStatusPartialTimeout => 'partial timeout';

  @override
  String get matchesActivityStatusCompleted => 'completed';

  @override
  String get matchesActivitySubmit => 'Submit Responses';

  @override
  String get matchesActivityTimeUpLoad => 'Time is up — Load Summary';

  @override
  String get matchesActivityWaiting =>
      'Responses sent. Waiting for the other participant to finish.';

  @override
  String get matchesActivityRefreshSummary => 'Refresh Summary';

  @override
  String matchesActivityTimeLeft(String time) {
    return 'Time left $time';
  }

  @override
  String get matchesActivitySummaryTitle => 'Activity Summary';

  @override
  String matchesActivityParticipantsCompleted(int completed, int total) {
    return 'Participants completed: $completed/$total';
  }

  @override
  String get matchesActivitySummaryPending =>
      'Summary will appear once available.';

  @override
  String get matchesActivityShareResult => 'Share Result to Chat';

  @override
  String matchesActivityShareMessage(String status, int completed, int total) {
    return '2-Min This-or-That result: $status • $completed/$total completed';
  }

  @override
  String matchesActivityShareMessageWithInsight(
    String status,
    int completed,
    int total,
    String insight,
  ) {
    return '2-Min This-or-That result: $status • $completed/$total completed • $insight';
  }

  @override
  String matchesActivityRound(int number) {
    return 'Round $number';
  }

  @override
  String get matchesActivityErrorStart =>
      'Unable to start activity right now. Please try again.';

  @override
  String get matchesActivityErrorNotReady => 'Session is not ready yet.';

  @override
  String get matchesActivityErrorAnswerAll =>
      'Please answer all prompts before submitting.';

  @override
  String get matchesActivityErrorTimeUp =>
      'Time is up. Loading activity summary...';

  @override
  String get matchesActivityErrorSubmit =>
      'Failed to submit activity responses. Please try again.';

  @override
  String get matchesActivityErrorSummary =>
      'Unable to fetch summary yet. Please try again.';

  @override
  String get matchesActivityQ1Prompt => 'Ideal first meetup?';

  @override
  String get matchesActivityQ1OptionA => 'Coffee walk';

  @override
  String get matchesActivityQ1OptionB => 'Bookstore browse';

  @override
  String get matchesActivityQ2Prompt => 'Preferred weekend mood?';

  @override
  String get matchesActivityQ2OptionA => 'Stay in and recharge';

  @override
  String get matchesActivityQ2OptionB => 'Explore the city';

  @override
  String get matchesActivityQ3Prompt => 'Best conversation setting?';

  @override
  String get matchesActivityQ3OptionA => 'Long walk';

  @override
  String get matchesActivityQ3OptionB => 'Cozy cafe corner';

  @override
  String get matchesActivityQ4Prompt => 'How do you plan dates?';

  @override
  String get matchesActivityQ4OptionA => 'Spontaneous';

  @override
  String get matchesActivityQ4OptionB => 'Planned in advance';

  @override
  String get matchesActivityQ5Prompt => 'Which matters more right now?';

  @override
  String get matchesActivityQ5OptionA => 'Consistency';

  @override
  String get matchesActivityQ5OptionB => 'Excitement';

  @override
  String get matchesActivityQ6Prompt => 'Conflict style preference?';

  @override
  String get matchesActivityQ6OptionA => 'Resolve same day';

  @override
  String get matchesActivityQ6OptionB => 'Take space then revisit';

  @override
  String get matchesActivityQ7Prompt => 'Shared activity pick?';

  @override
  String get matchesActivityQ7OptionA => 'Cook together';

  @override
  String get matchesActivityQ7OptionB => 'Workout together';

  @override
  String get matchesActivityQ8Prompt => 'Pace preference?';

  @override
  String get matchesActivityQ8OptionA => 'Steady and intentional';

  @override
  String get matchesActivityQ8OptionB => 'Fast and energetic';

  @override
  String get cityPilotSaveFailed =>
      'We couldn’t confirm that change. Refresh to check before trying again.';

  @override
  String get cityPilotLeaveTitle => 'Leave the city pilot?';

  @override
  String get cityPilotLeaveBody =>
      'Your pilot bookings will be cancelled and experience feedback removed. Your activity will stop contributing to current pilot results. Your matches and conversations stay. You cannot rejoin this pilot.';

  @override
  String get cityPilotStay => 'Stay in pilot';

  @override
  String get cityPilotLeave => 'Leave pilot';

  @override
  String get cityPilotLeftNotice =>
      'You have left the pilot. Your matches stay with you.';

  @override
  String cityPilotJoinEventTitle(String title) {
    return 'Join $title?';
  }

  @override
  String cityPilotBookingTerms(
    String host,
    String safetyContact,
    String accessibility,
  ) {
    return 'This experience is free. Meet at the public venue, respect other people’s boundaries, and arrange your own travel. You can leave at any time.\n\nHost: $host\nSafety contact: $safetyContact\n\nAccessibility: $accessibility\n\nFor immediate danger, contact local emergency services.';
  }

  @override
  String get cityPilotAcceptReserve => 'Accept & reserve a place';

  @override
  String get cityPilotReservedNotice =>
      'Your place is reserved. You can cancel here at any time.';

  @override
  String get cityPilotFeedbackTitle => 'How was the experience?';

  @override
  String get cityPilotFeedbackIntro =>
      'Optional. Answers contribute to the pilot’s combined results. They aren’t shown to other members or the host.';

  @override
  String get cityPilotDidYouAttend => 'Did you attend?';

  @override
  String get cityPilotAttendedYes => 'Yes, I went';

  @override
  String get cityPilotAttendedNo => 'I couldn’t make it';

  @override
  String get cityPilotWorthwhileQuestion =>
      'Was it worth your time? (optional)';

  @override
  String get cityPilotNotThisTime => 'Not this time';

  @override
  String get cityPilotSkip => 'Skip';

  @override
  String get cityPilotShareFeedback => 'Share feedback';

  @override
  String get cityPilotFeedbackThanks =>
      'Thank you. Your feedback has been recorded privately.';

  @override
  String get cityPilotTimeTbc => 'Time to be confirmed';

  @override
  String get cityPilotTitle => 'The city pilot';

  @override
  String get cityPilotRefreshTooltip => 'Refresh pilot';

  @override
  String get cityPilotHeroTitle => 'A little closer.\nA lot more real.';

  @override
  String get cityPilotHeroBody =>
      'One city. A small community. More chances for a conversation to become a plan.';

  @override
  String get cityPilotStep1Title => 'Start with a conversation';

  @override
  String get cityPilotStep1Body =>
      'Meet at your pace through your existing introductions.';

  @override
  String get cityPilotStep2Title => 'Make room for a real date';

  @override
  String get cityPilotStep2Body =>
      'Shape a plan together. Share how it went only if you want to.';

  @override
  String get cityPilotStep3Title => 'Try something together';

  @override
  String get cityPilotStep3Body =>
      'Small, hosted experiences come after the first pilot review.';

  @override
  String get cityPilotSaving => 'Saving pilot preference';

  @override
  String get cityPilotUnavailableTitle => 'Your pilot is unavailable';

  @override
  String get cityPilotUnavailableBody =>
      'Check your connection and refresh to see your latest participation and bookings.';

  @override
  String get cityPilotComingSoonTitle => 'Coming to a city near you';

  @override
  String get cityPilotComingSoonBody =>
      'There isn’t an open pilot for your profile city yet. When one opens, you can choose whether to take part. Your current dating experience carries on as usual.';

  @override
  String cityPilotPanelTitleJoined(String city) {
    return '$city · You’re part of it';
  }

  @override
  String cityPilotPanelTitleOpen(String city) {
    return '$city · City pilot';
  }

  @override
  String cityPilotRecruitmentCloses(String date) {
    return 'Recruitment closes $date (your local time).';
  }

  @override
  String get cityPilotPaused =>
      'New participation and bookings are paused. You can still leave or cancel.';

  @override
  String get cityPilotCompleted =>
      'This pilot is complete. Thank you for being part of it.';

  @override
  String get cityPilotMeasurement =>
      'Joining lets us count conversations, accepted plans and optional “did the date happen?” answers for new matches where both people joined this pilot. We use 7-day conversation and 28-day date windows. We don’t read message text or private feedback notes for the pilot.';

  @override
  String get cityPilotPrivacy =>
      'Participation stays private. There’s no public attendance list or dating score. Leaving excludes your activity from current pilot results and cancels pilot bookings. Previously reviewed combined results cannot be un-seen.';

  @override
  String get cityPilotConsent =>
      'I agree to take part in this pilot and its outcome measurement.';

  @override
  String get cityPilotJoinedNotice =>
      'You’re in. Keep meeting people at your own pace.';

  @override
  String get cityPilotJoin => 'Join the city pilot';

  @override
  String get cityPilotWithdrawn =>
      'You’ve left this pilot. Your matches and conversations are unchanged.';

  @override
  String get cityPilotNotAccepting =>
      'This pilot is not accepting new members right now.';

  @override
  String get cityPilotExperiencesHeading => 'Small plans. Shared experiences.';

  @override
  String get cityPilotNoExperiences =>
      'Hosted experiences aren’t open yet. They’ll appear here after an outcome and safety review.';

  @override
  String cityPilotEventDetails(
    String start,
    String end,
    String venue,
    String host,
  ) {
    return '$start → $end\nYour local time · Free\n$venue\nHosted by $host';
  }

  @override
  String cityPilotAccessibility(String details) {
    return 'Accessibility · $details';
  }

  @override
  String cityPilotSafetyContact(String contact) {
    return 'Safety contact · $contact';
  }

  @override
  String get cityPilotEventCancelled =>
      'This experience has been cancelled. Please do not travel to the venue.';

  @override
  String get cityPilotPlaceReserved => 'Your place is reserved.';

  @override
  String get cityPilotBookingCancelled => 'Your booking is cancelled.';

  @override
  String get cityPilotCancelPlace => 'Cancel my place';

  @override
  String get cityPilotReserveFree => 'Reserve a free place';

  @override
  String get cityPilotShareOptionalFeedback => 'Share optional feedback';

  @override
  String get cityPilotFeedbackReceived =>
      'Your feedback has been received. Thank you.';

  @override
  String get blogAudiencePrivate => 'Only me';

  @override
  String get blogAudienceFriends => 'Friends';

  @override
  String get blogAudienceCommunity => 'Connect community';

  @override
  String get blogInvitationNone => 'No invitation';

  @override
  String get blogInvitationYourVersion => 'What would your version look like?';

  @override
  String get blogInvitationTeachMe => 'What could you teach me about this?';

  @override
  String get blogInvitationWhatNext => 'What would you try next?';

  @override
  String get blogRewardStoryPublishedTitle => 'Sharing a chapter';

  @override
  String get blogRewardStoryPublishedWho =>
      'You, the first time a chapter is shared beyond Only me';

  @override
  String get blogRewardPhotoSharedTitle => 'Sharing a Photo Themes photo';

  @override
  String get blogRewardPhotoSharedWho =>
      'You, for a photo you share in Photo Themes';

  @override
  String get blogRewardLikeReceivedTitle => 'A like on your chapter or photo';

  @override
  String get blogRewardLikeReceivedWho => 'You, for each member who likes it';

  @override
  String get blogRewardCommentReceivedTitle => 'A comment you approve';

  @override
  String get blogRewardCommentReceivedWho =>
      'You, when you approve a reader’s comment';

  @override
  String get blogRewardCommentApprovedTitle => 'Your comment is approved';

  @override
  String get blogRewardCommentApprovedWho =>
      'You, when an author approves your comment';

  @override
  String get blogRewardSubscriberGainedTitle => 'A new follower';

  @override
  String get blogRewardSubscriberGainedWho =>
      'You, for each new member who follows your chapters';

  @override
  String get blogRewardWallTierTitle => 'Reaching more walls';

  @override
  String get blogRewardWallTierWho =>
      'You, each time a chapter reaches a new wall tier';

  @override
  String get blogRewardCoverOfWeekTitle => 'Cover of the Week';

  @override
  String get blogRewardCoverOfWeekWho =>
      'You, when your work is chosen as Cover of the Week';

  @override
  String get blogScopeForYou => 'For you';

  @override
  String get blogScopeTopRated => 'Top rated';

  @override
  String get blogScopeFollowing => 'Following';

  @override
  String get blogScopeMine => 'Mine';

  @override
  String get blogScopeCaptionMine =>
      'Your drafts and published chapters. You choose the audience for each one.';

  @override
  String get blogScopeCaptionFriends =>
      'Chapters shared by your accepted Connect friends.';

  @override
  String get blogScopeCaptionTop =>
      'Ranked by likes, approved comments and readers, from the last 30 days.';

  @override
  String get blogScopeCaptionFollowing =>
      'The newest chapters from writers you follow.';

  @override
  String get blogScopeCaptionCommunity =>
      'For eligible, signed-in Connect members. These chapters are not public on the web.';

  @override
  String get blogTitle => 'Open Chapters';

  @override
  String get blogRewardsTitle => 'How rewards work';

  @override
  String get blogWritersTitle => 'Writers you follow';

  @override
  String get blogConnectionsTooltip => 'Private responses, sharing and notices';

  @override
  String get blogSignInReadWrite => 'Sign in to read and write chapters.';

  @override
  String get blogHeroTitle => 'A life worth\ngetting to know.';

  @override
  String get blogHeroBody =>
      'The story behind a photo. A small obsession. Something you’re still learning. Let your everyday life do the talking.';

  @override
  String get blogWriteChapter => 'Write a chapter';

  @override
  String get blogPrivateResponses => 'Private responses';

  @override
  String get blogSharedLinks => 'Shared links';

  @override
  String get blogReviewNotices => 'Review notices';

  @override
  String get blogTopicAll => 'All';

  @override
  String get blogFeedLoadFailed => 'Chapters could not load.';

  @override
  String get blogPreviousPage => 'Previous page';

  @override
  String get blogMoreChapters => 'More chapters';

  @override
  String get blogEmptyMineTitle => 'Your next chapter starts here.';

  @override
  String get blogEmptyMineBody =>
      'Start with a moment you would love someone to ask about. Your first draft is only for you.';

  @override
  String get blogEmptyTopTitle => 'When chapters move people, they rise here.';

  @override
  String get blogEmptyTopFilteredBody =>
      'Nothing has risen in this topic yet. Try All, or share a chapter of your own.';

  @override
  String get blogEmptyTopBody =>
      'Chapters readers love from the last 30 days will appear here.';

  @override
  String get blogEmptyFollowingFilteredTitle =>
      'Nothing new in this topic yet.';

  @override
  String get blogEmptyFollowingTitle => 'Writers you follow will appear here.';

  @override
  String get blogEmptyFollowingBody =>
      'When a chapter speaks to you, open it and tap Follow their chapters. Their new chapters will gather here, so you never miss what they share next.';

  @override
  String get blogEmptyCommunityTitle => 'A little quiet here, for now.';

  @override
  String get blogEmptyCommunityBody =>
      'Chapters appear here when members choose to share with this audience.';

  @override
  String get blogFindWritersTopRated => 'Find writers in Top rated';

  @override
  String blogRankTooltip(int rank) {
    return 'Number $rank in Top rated';
  }

  @override
  String get blogUntitled => 'An untitled chapter';

  @override
  String get blogDraftPlaceholder => 'A private draft, waiting for your words.';

  @override
  String get blogReadEdit => 'Read & edit →';

  @override
  String get blogReadChapter => 'Read chapter →';

  @override
  String get blogPhotoUnavailableRetry => 'Photo unavailable · Retry';

  @override
  String get blogTryAgain => 'Try again';

  @override
  String get blogDetailTitle => 'A chapter';

  @override
  String get blogSignInRead => 'Sign in to read chapters.';

  @override
  String get blogDetailUnavailable =>
      'This chapter is unavailable or its audience has changed.';

  @override
  String get blogRespondPrivately => 'Respond privately';

  @override
  String get blogCreatePublicPreview => 'Create a public preview';

  @override
  String get blogRemovedByModerationNote =>
      'Removed by moderation. Open Review notices to read the decision or request another review.';

  @override
  String get blogEditChapter => 'Edit chapter';

  @override
  String get blogDeleteChapter => 'Delete chapter';

  @override
  String get blogDeleteChapterTitle => 'Delete this chapter?';

  @override
  String get blogDeleteChapterMessage =>
      'It will disappear from all audiences. This cannot be undone.';

  @override
  String get blogDeleteChapterFailed =>
      'Could not confirm deletion. Reload the chapter before retrying.';

  @override
  String get blogReportChapter => 'Report chapter';

  @override
  String get blogReportFailed => 'Report could not be submitted.';

  @override
  String get blogBlockThisMember => 'Block this member';

  @override
  String get blogBlockTitle => 'Block this member?';

  @override
  String get blogBlockMessageChapter =>
      'You will no longer see each other’s chapters. This also blocks contact through Connect.';

  @override
  String get blogBlockMember => 'Block member';

  @override
  String get blogBlockRetryFailed =>
      'Could not block this member. Please retry.';

  @override
  String get blogCancel => 'Cancel';

  @override
  String get blogEditorMissingFields =>
      'Add a title and story before publishing.';

  @override
  String blogPublishConfirmTitle(String audience) {
    String _temp0 = intl.Intl.selectLogic(audience, {
      'private': 'Publish to Only me?',
      'friends': 'Publish to Friends?',
      'community': 'Publish to Connect community?',
      'other': 'Publish?',
    });
    return '$_temp0';
  }

  @override
  String get blogPublishFriendsBody =>
      'Your accepted Connect friends can read the words and photos in this chapter. You can change the audience later.';

  @override
  String get blogPublishCommunityBody =>
      'Eligible, signed-in Connect members can read this chapter. It will not appear on the public web. You can change the audience later.';

  @override
  String get blogPublishChapter => 'Publish chapter';

  @override
  String get blogSavedOnlyMe => 'Saved. Only you can read this chapter.';

  @override
  String blogPublishedTo(String audience) {
    String _temp0 = intl.Intl.selectLogic(audience, {
      'private': 'Published to Only me.',
      'friends': 'Published to Friends.',
      'community': 'Published to Connect community.',
      'other': 'Published.',
    });
    return '$_temp0';
  }

  @override
  String get blogSharedSnack =>
      'Shared. Readers’ likes and comments earn you XP.';

  @override
  String get blogSeeMyLevel => 'See my level';

  @override
  String get blogSaveUnconfirmed => 'We could not confirm the save.';

  @override
  String blogEditsStillHere(String message) {
    return '$message Your edits are still here. Check the saved version before continuing.';
  }

  @override
  String blogSavedVersionTitle(String audience) {
    return 'Saved version · $audience';
  }

  @override
  String get blogSavedVersionNote =>
      'Your current edits remain in the editor. Close this sheet to keep them, or replace them with this saved version.';

  @override
  String get blogKeepMyEdits => 'Keep my edits for the next save';

  @override
  String get blogUseSavedVersion => 'Use saved version';

  @override
  String get blogSavedVersionLoadFailed =>
      'The saved version could not load. Your edits remain here.';

  @override
  String get blogDescribePhotoTitle => 'Describe your photo';

  @override
  String get blogDescribePhotoBody =>
      'A short description makes your chapter accessible. Adding the photo saves your words as an Only me draft.';

  @override
  String get blogDescribePhotoLabel => 'What is in this photo?';

  @override
  String get blogAddToPrivateDraft => 'Add to private draft';

  @override
  String get blogPhotoAdded => 'Photo added to your private draft.';

  @override
  String get blogPhotoAddFailed =>
      'The photo could not be added. Use a JPEG or PNG up to 10 MB.';

  @override
  String blogCheckSavedBeforeRetrying(String message) {
    return '$message Check the saved version before retrying.';
  }

  @override
  String get blogRemoveUnconfirmed =>
      'Could not confirm removal. Check the saved version.';

  @override
  String get blogSignInAsAuthor =>
      'Sign in as the author to edit this chapter.';

  @override
  String get blogLeaveEditorTitle => 'Leave without saving?';

  @override
  String get blogLeaveEditorMessage =>
      'Your unsaved edits will be lost. Your last saved chapter will remain.';

  @override
  String get blogLeaveEditor => 'Leave editor';

  @override
  String get blogEditorPreviewTitle => 'Chapter preview';

  @override
  String get blogEditorTitle => 'Your next chapter';

  @override
  String get blogEditorHeadline => 'A little more you.';

  @override
  String get blogEditorIntro =>
      'Small stories are welcome. A meal you made. A place that changed your mind. The photo with a story behind it.';

  @override
  String get blogNotSavedDefault => 'Not saved · Only me by default';

  @override
  String blogSavedFor(String audience) {
    String _temp0 = intl.Intl.selectLogic(audience, {
      'private': 'Saved for Only me',
      'friends': 'Saved for Friends',
      'community': 'Saved for Connect community',
      'other': 'Saved',
    });
    return '$_temp0';
  }

  @override
  String get blogKeepWriting => 'Keep writing';

  @override
  String get blogPreview => 'Preview';

  @override
  String get blogCheckSavedVersion => 'Check saved version';

  @override
  String blogPreviewNotSaved(String audience) {
    return 'Preview · $audience · Not yet saved';
  }

  @override
  String get blogStoryPlaceholder => 'Your story will appear here.';

  @override
  String get blogChapterTitleLabel => 'Chapter title';

  @override
  String get blogChapterTitleHint => 'The Sunday I learned to slow down';

  @override
  String get blogStoryLabel => 'Your story';

  @override
  String get blogStoryHint => 'Start anywhere. Make it yours.';

  @override
  String get blogInvitationLabel => 'End with an invitation (optional)';

  @override
  String get blogInvitationHelp =>
      'Leave a question that helps someone get to know you.';

  @override
  String get blogRemovePhoto => 'Remove photo';

  @override
  String get blogAddPhoto => 'Add a photo';

  @override
  String get blogPhotoRules =>
      'Up to 6 JPEG or PNG photos, 10 MB each. Photos need approval. Save as Only me before changing photos on a published chapter.';

  @override
  String get blogWhoFor => 'Who is this chapter for?';

  @override
  String get blogAudiencePrivateHelp =>
      'Only you can read this chapter. Friends and matches cannot see it.';

  @override
  String get blogAudienceFriendsHelp =>
      'Only accepted Connect friends can read it. A match alone does not give access.';

  @override
  String get blogAudienceCommunityHelp =>
      'Eligible signed-in members can read it. Complete your profile with two approved profile photos to publish here. This is not public web sharing.';

  @override
  String get blogAllowFeaturing => 'Allow featuring';

  @override
  String get blogAllowFeaturingHelp =>
      'If readers love it, your chapter can reach other members’ walls: 50 likes and 5 comments reach 50 walls, 100 likes and 10 comments reach 100. You can turn this off any time.';

  @override
  String get blogSaveOnlyForMe => 'Save only for me';

  @override
  String blogPublishTo(String audience) {
    String _temp0 = intl.Intl.selectLogic(audience, {
      'private': 'Publish to Only me',
      'friends': 'Publish to Friends',
      'community': 'Publish to Connect community',
      'other': 'Publish',
    });
    return '$_temp0';
  }

  @override
  String get blogSaveAsOnlyMe => 'Save as Only me';

  @override
  String get blogSaveNote =>
      'Your words are saved when you choose Save or Publish. Preview does not publish anything.';

  @override
  String get blogTopicOptional => 'Topic (optional)';

  @override
  String get blogTopicHelp =>
      'Help readers who care about this find your chapter.';

  @override
  String get webDestBlog => 'Blog';

  @override
  String get webDestFirstChapter => 'First Chapter Studio';

  @override
  String get webDestDatingPreferences => 'Dating preferences';

  @override
  String get webDestEditProfile => 'Edit profile';

  @override
  String get webDestProfilePhotos => 'Profile photos';

  @override
  String get webDestLikedYou => 'Liked you';

  @override
  String get webDestNotifications => 'Notifications';

  @override
  String get webDestDailyPrompt => 'Daily prompt';

  @override
  String get webDestLevels => 'Levels & progress';

  @override
  String get webDestTrustBadges => 'Trust badges';

  @override
  String get webDestTrustFilters => 'Trust filters';

  @override
  String get webDestIcebreakers => 'Icebreakers';

  @override
  String get webDestCircleChallenges => 'Circle challenges';

  @override
  String get webDestCoffeePolls => 'Coffee polls';

  @override
  String get webDestGroups => 'Groups';

  @override
  String get webDestRooms => 'Conversation rooms';

  @override
  String get webDestMatchNudges => 'Match nudges';

  @override
  String get webDestFriends => 'Friends';

  @override
  String get webDestDatePlans => 'Date plans';

  @override
  String get webDestCallHistory => 'Call history';

  @override
  String get webDestMembership => 'Membership';

  @override
  String get webDestVerification => 'Verification';

  @override
  String get webDestPrivacySafety => 'Privacy & safety';

  @override
  String get webDestAccountData => 'Account & data';

  @override
  String get webDestBlockedMembers => 'Blocked members';

  @override
  String get webDestEmergencyContacts => 'Emergency contacts';

  @override
  String get webDestModerationAppeals => 'Moderation appeals';

  @override
  String get webDestNotificationPreferences => 'Notification preferences';

  @override
  String get webDestHelpSupport => 'Help & support';

  @override
  String get webNavExplore => 'Explore';

  @override
  String get webNavMyProfile => 'My profile';

  @override
  String get webNavAllFeatures => 'All features';

  @override
  String get webNavMoreForYou => 'More for you';

  @override
  String get webNavPreferences => 'Preferences';

  @override
  String get webNavWebsite => 'Connect website';

  @override
  String get webNavSignOut => 'Sign out';

  @override
  String get webPageNotFound => 'This page could not be found.';

  @override
  String get webBackToDiscover => 'Back to Discover';

  @override
  String get webTagline => 'Your pace. Your choice.';

  @override
  String webUnavailableTitle(String label) {
    return '$label isn\'t available yet.';
  }

  @override
  String get webUnavailableBody => 'It isn\'t part of this release of Connect.';

  @override
  String get webDirectoryTitle => 'Make this space yours.';

  @override
  String get webDirectorySubtitle =>
      'Your profile, conversations, community and controls — all in one place.';

  @override
  String get webIcebreakerTitle => 'Conversation starters';

  @override
  String get webIcebreakerHeadline =>
      'A little inspiration for your next hello.';

  @override
  String get webIcebreakerBody =>
      'Voice recording and playback are not available yet. You can use these prompts in an eligible conversation.';

  @override
  String get webIcebreakerOpenMatches => 'Open my matches';

  @override
  String get webMembershipHeadline => 'A little more possibility.';

  @override
  String get webMembershipIntro =>
      'Explore the current plans. Browser checkout is not available yet. No purchase or charge can be made from this page.';

  @override
  String webMembershipCurrent(String plan) {
    return 'Your membership: $plan';
  }

  @override
  String webMembershipStatus(String status) {
    return 'Status: $status';
  }

  @override
  String get webMembershipMonthly => 'Monthly';

  @override
  String get webMembershipYearly => 'Yearly';

  @override
  String get webMembershipFree => 'Free';

  @override
  String webMembershipPrice(String price, String cycle) {
    String _temp0 = intl.Intl.selectLogic(cycle, {
      'yearly': 'year',
      'other': 'month',
    });
    return '$price / $_temp0';
  }

  @override
  String get webMembershipFootnote =>
      'Catalogue prices are a preview. Membership never bypasses another person’s boundaries or conversation eligibility.';

  @override
  String get blogLinkCopied => 'Link copied. Share it wherever you choose.';

  @override
  String get blogYourPublicLink => 'Your public link';

  @override
  String get blogShareUnconfirmed =>
      'Could not confirm sharing. Check Shared links before retrying.';

  @override
  String get blogSignInAgain => 'Sign in again to continue.';

  @override
  String get blogSharedJournalPage => 'A shared journal page';

  @override
  String get blogYourPublicPreview => 'Your public preview';

  @override
  String get blogShareJointHeadline => 'A story you both choose to share.';

  @override
  String get blogShareSoloHeadline => 'A small window into your world.';

  @override
  String get blogShareJointBody =>
      'Both authors must approve these exact words before the link works. Either person can withdraw it.';

  @override
  String get blogShareSoloBody =>
      'Anyone with the link can read the selected words and photos, without an account. Your full chapter stays in Connect.';

  @override
  String get blogShareIdentityNote =>
      'No profile or account name is added. Your words and photos can still identify people or places. Publish only what you have permission to share.';

  @override
  String get blogExcerptLabel => 'Exact excerpt from your chapter';

  @override
  String blogIncludePhoto(String description) {
    return 'Include: $description';
  }

  @override
  String get blogApproveCopy => 'I approve this exact public copy';

  @override
  String get blogApproveCopyNote =>
      'Editing or hiding the source chapter invalidates the link. Saved copies outside Connect cannot be recalled.';

  @override
  String get blogSaving => 'Saving…';

  @override
  String get blogRequestOtherApproval => 'Request the other author’s approval';

  @override
  String get blogCreatePublicLink => 'Create public link';

  @override
  String get blogJointApprovalRecorded =>
      'Your approval is recorded. The link stays unavailable until the other author approves.';

  @override
  String get blogPublicCopyReady => 'Your public copy is ready.';

  @override
  String get blogCopyPublicLink => 'Copy public link';

  @override
  String get blogManageSharedLinks => 'Manage shared links';

  @override
  String blogFollowerCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count followers',
      one: '1 follower',
    );
    return '$_temp0';
  }

  @override
  String get blogUnfollowFailed =>
      'We couldn’t stop following just now. Please try again.';

  @override
  String get blogFollowFailed =>
      'We couldn’t follow this writer just now. Please try again.';

  @override
  String get blogFollowingButton => 'Following';

  @override
  String get blogFollowTheirChapters => 'Follow their chapters';

  @override
  String get blogRewardsIntro =>
      'When what you share moves someone, it counts. Readers’ likes, approved comments and new followers earn you XP toward your level. Rewards come from what readers do, never from tapping, and each one is given only once.';

  @override
  String blogRewardDailyCap(int cap) {
    return 'Up to $cap XP a day';
  }

  @override
  String blogRewardXp(int xp) {
    return '+$xp XP';
  }

  @override
  String get blogSignInWriters => 'Sign in to see writers you follow.';

  @override
  String get blogWritersLoadFailed => 'Writers you follow could not load.';

  @override
  String get blogNoWriters => 'No writers yet.';

  @override
  String get blogNoWritersBody =>
      'When a chapter speaks to you, tap Follow their chapters on it. Their new chapters will gather in Following.';

  @override
  String blogLatest(String title) {
    return 'Latest: $title';
  }

  @override
  String get blogReactionFailed =>
      'Your reaction didn’t go through. Please try again.';

  @override
  String blogCannotLikeOwn(String noun) {
    String _temp0 = intl.Intl.selectLogic(noun, {
      'photo': 'You can’t like your own photo',
      'other': 'You can’t like your own chapter',
    });
    return '$_temp0';
  }

  @override
  String blogYouReacted(String reaction) {
    return 'You reacted: $reaction. Tap to take it back';
  }

  @override
  String blogLikeThis(String noun) {
    String _temp0 = intl.Intl.selectLogic(noun, {
      'photo': 'Like this photo',
      'other': 'Like this chapter',
    });
    return '$_temp0';
  }

  @override
  String blogCannotReactOwn(String noun) {
    String _temp0 = intl.Intl.selectLogic(noun, {
      'photo': 'You can’t react to your own photo',
      'other': 'You can’t react to your own chapter',
    });
    return '$_temp0';
  }

  @override
  String get blogReactTooltip => 'React: I hear you, Me too, Sending a hug…';

  @override
  String blogCommentCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count comments',
      one: '1 comment',
    );
    return '$_temp0';
  }

  @override
  String blogWaitingForYou(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '· $count waiting for you',
      one: '· $count waiting for you',
    );
    return '$_temp0';
  }

  @override
  String get blogFeatured => 'Featured';

  @override
  String blogTierNeedsBoth(int likes, int comments, int walls) {
    String _temp0 = intl.Intl.pluralLogic(
      likes,
      locale: localeName,
      other: '$likes more likes',
      one: '1 more like',
    );
    String _temp1 = intl.Intl.pluralLogic(
      comments,
      locale: localeName,
      other: '$comments more comments',
      one: '1 more comment',
    );
    String _temp2 = intl.Intl.pluralLogic(
      walls,
      locale: localeName,
      other: '$walls walls',
      one: '1 wall',
    );
    return '$_temp0 and $_temp1 to reach $_temp2';
  }

  @override
  String blogTierNeedsLikes(int likes, int walls) {
    String _temp0 = intl.Intl.pluralLogic(
      likes,
      locale: localeName,
      other: '$likes more likes',
      one: '1 more like',
    );
    String _temp1 = intl.Intl.pluralLogic(
      walls,
      locale: localeName,
      other: '$walls walls',
      one: '1 wall',
    );
    return '$_temp0 to reach $_temp1';
  }

  @override
  String blogTierNeedsComments(int comments, int walls) {
    String _temp0 = intl.Intl.pluralLogic(
      comments,
      locale: localeName,
      other: '$comments more comments',
      one: '1 more comment',
    );
    String _temp1 = intl.Intl.pluralLogic(
      walls,
      locale: localeName,
      other: '$walls walls',
      one: '1 wall',
    );
    return '$_temp0 to reach $_temp1';
  }

  @override
  String blogTierAlmostThere(int walls) {
    String _temp0 = intl.Intl.pluralLogic(
      walls,
      locale: localeName,
      other: 'Almost there: $walls walls are next',
      one: 'Almost there: 1 wall are next',
    );
    return '$_temp0';
  }

  @override
  String blogOnWalls(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'On $count walls',
      one: 'On 1 wall',
    );
    return '$_temp0';
  }

  @override
  String blogProgressToward(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Progress toward $count walls',
      one: 'Progress toward 1 wall',
    );
    return '$_temp0';
  }

  @override
  String get blogReachIdle => 'Readers can carry this chapter further';

  @override
  String get blogReachLive =>
      'Members who loved stories like yours are reading it now.';

  @override
  String get blogFeaturedStories => 'Featured Stories';

  @override
  String get blogFeaturedCaption =>
      'Stories other members loved, delivered to your wall.';

  @override
  String blogByAuthor(String name) {
    return 'by $name';
  }

  @override
  String get blogLikes => 'Likes';

  @override
  String get blogComments => 'Comments';

  @override
  String get blogCommentHint => 'What stayed with you?';

  @override
  String get blogCommentApproved =>
      'Approved. Everyone who can read this chapter can see it now.';

  @override
  String get blogCommentSent => 'Sent to the author for approval';

  @override
  String get blogCommentSendFailed =>
      'Your comment didn’t send. Your words are still here, so you can try again.';

  @override
  String blogCommentDeclined(String noun) {
    String _temp0 = intl.Intl.selectLogic(noun, {
      'photo': 'Declined. It won’t appear on your photo.',
      'other': 'Declined. It won’t appear on your chapter.',
    });
    return '$_temp0';
  }

  @override
  String get blogSaveFailed => 'That didn’t save. Please try again.';

  @override
  String get blogDeleteCommentTitle => 'Delete this comment?';

  @override
  String get blogDeleteCommentMessage =>
      'It will be removed for everyone. This can’t be undone.';

  @override
  String get blogDeleteComment => 'Delete comment';

  @override
  String get blogCommentDeleted => 'Comment deleted.';

  @override
  String get blogCommentDeleteFailed =>
      'The comment could not be deleted. Please try again.';

  @override
  String get blogCommentsAuthorNote =>
      'New comments wait for your approval before anyone else sees them.';

  @override
  String get blogCommentsReaderNote =>
      'The author reads every comment first and chooses what to share.';

  @override
  String get blogLeaveComment => 'Leave a comment';

  @override
  String get blogSendToAuthor => 'Send to the author';

  @override
  String get blogCommentsLoadFailed => 'Comments could not load.';

  @override
  String get blogWaitingApproval => 'Waiting for your approval';

  @override
  String get blogNoCommentsInvite =>
      'No comments yet. Say something kind to start the conversation.';

  @override
  String get blogNoCommentsShared => 'No comments shared yet.';

  @override
  String get blogCommentNotShared => 'The author chose not to share this one.';

  @override
  String get blogYou => 'You';

  @override
  String get blogCommentOptions => 'Comment options';

  @override
  String get blogReportComment => 'Report comment';

  @override
  String get blogApprove => 'Approve';

  @override
  String get blogDecline => 'Decline';

  @override
  String get blogSignInContinue => 'Sign in to continue.';

  @override
  String get blogPrivateResponseTitle => 'A private response';

  @override
  String blogPrivateResponseHelp(String invitation) {
    return '$invitation\n\nOnly the author receives this response. They can accept or decline an optional exchange. Up to five new responses per day, and one to the same author.';
  }

  @override
  String get blogSendPrivateResponse => 'Send private response';

  @override
  String get blogTextSaveUnconfirmed =>
      'Could not confirm the save. Your words are still here; retry or reload the saved exchange.';

  @override
  String get blogLeaveUnsentTitle => 'Leave without sending?';

  @override
  String get blogLeaveUnsentMessage => 'Your unsent words will be discarded.';

  @override
  String get blogLeave => 'Leave';

  @override
  String get blogOwnWordsLabel => 'In your own words';

  @override
  String get blogSending => 'Sending…';

  @override
  String get blogChangeUnconfirmed =>
      'Could not confirm the change. Refresh to check.';

  @override
  String get blogConnectionsTitle => 'Your Chapter connections';

  @override
  String get blogRefresh => 'Refresh';

  @override
  String get blogConnectionsIntro =>
      'Good stories leave room for someone else.';

  @override
  String get blogConnectionsLoadFailed => 'Could not load your connections.';

  @override
  String get blogResponsesEmpty =>
      'Responses to your chapters and the ones you send will appear here. Nothing needs an instant answer.';

  @override
  String get blogPublicationsEmpty =>
      'Your public previews and jointly approved links will appear here.';

  @override
  String get blogNoticesEmpty => 'No review notices to show.';

  @override
  String get blogResponseRevealed => 'Your shared chapter is ready';

  @override
  String get blogResponseIncoming => 'A response for you';

  @override
  String get blogResponseSent => 'Sent · their choice, their pace';

  @override
  String get blogResponseAccepted => 'An exchange, at your pace';

  @override
  String get blogResponseClosed => 'This exchange is closed';

  @override
  String get blogOpenExchange => 'Open private exchange';

  @override
  String get blogPublicationLive => 'Live public copy';

  @override
  String get blogPublicationRemoved => 'Removed by moderation';

  @override
  String get blogPublicationNeedsBoth =>
      'Requires both approvals and a current source chapter';

  @override
  String get blogPublicationSourceChanged =>
      'Source changed · create a new preview to share again';

  @override
  String get blogApprovePublicCopyTitle => 'Approve this public copy?';

  @override
  String get blogApprovePublicCopyMessage =>
      'The exact words above will be available to anyone with the link. Both people can withdraw sharing. No names are added automatically, but the words may identify you.';

  @override
  String get blogApprovePublicCopyAction => 'Approve public copy';

  @override
  String get blogApproveExactPublicCopy => 'Approve exact public copy';

  @override
  String get blogCopyLink => 'Copy link';

  @override
  String get blogWithdrawLinkTitle => 'Withdraw this link?';

  @override
  String get blogWithdrawLinkMessage =>
      'The public copy will become unavailable. Copies already saved by someone else cannot be recalled.';

  @override
  String get blogWithdrawLink => 'Withdraw link';

  @override
  String get blogYourAppeal => 'Your appeal';

  @override
  String get blogRequestReview => 'Request another review';

  @override
  String get blogRequestReviewHelp =>
      'Explain what the reviewer should reconsider. Your appeal goes privately to the trust team. Removed content stays hidden during review.';

  @override
  String get blogSubmitAppeal => 'Submit appeal';

  @override
  String get blogAppealDecision => 'Appeal this decision';

  @override
  String get blogPrevious => 'Previous';

  @override
  String get blogMore => 'More';

  @override
  String get blogExchangeChangeFailed =>
      'Could not confirm this change. Refresh and retry.';

  @override
  String get blogExchangeTitle => 'A private Chapter exchange';

  @override
  String get blogExchangeUnavailable => 'This exchange is no longer available.';

  @override
  String blogExchangeWith(String name) {
    return 'With $name';
  }

  @override
  String get blogExchangeIntro =>
      'A response is an invitation, never an obligation. This exchange does not create a match or unlock chat.';

  @override
  String get blogAcceptExchange => 'Accept an exchange';

  @override
  String get blogDeclineKindly => 'Decline kindly';

  @override
  String get blogResponseSentNote =>
      'Your response has been sent. There is no countdown and no need to follow up.';

  @override
  String get blogExchangeClosedNote =>
      'This exchange is closed. Make room for another connection at your own pace.';

  @override
  String get blogOneStoryEach => 'One small story each.';

  @override
  String get blogOneStoryEachBody =>
      'Add a tiny continuation, a memory, or your version of the moment. Both contributions appear together, only after both people submit.';

  @override
  String get blogYourSideTitle => 'Your side of the chapter';

  @override
  String get blogYourSideHelp =>
      'Share up to 1,000 characters. Your partner cannot read this until they also contribute. Once submitted, the words cannot be edited; you can withdraw the exchange at any time.';

  @override
  String get blogSubmitContribution => 'Submit my contribution';

  @override
  String get blogAddContribution => 'Add my contribution';

  @override
  String get blogYourContribution => 'Your contribution';

  @override
  String blogPartnerContribution(String name) {
    return '$name’s contribution';
  }

  @override
  String get blogShapeDate => 'Shape a date together';

  @override
  String get blogInspiredNote => 'Inspired by our Chapter exchange.';

  @override
  String get blogTryStudio => 'Try First Chapter Studio';

  @override
  String get blogDatePlanningUnavailable =>
      'Date planning becomes available if you have an active match and your conversation is unlocked.';

  @override
  String get blogProposeJournalPage => 'Propose a shared journal page';

  @override
  String get blogSourceUnavailable => 'The source chapter is unavailable.';

  @override
  String get blogContributionSaved =>
      'Your contribution is saved privately. The reveal happens when both of you are ready.';

  @override
  String get blogWithdrawExchangeTitle => 'Withdraw this exchange?';

  @override
  String get blogWithdrawExchangeMessage =>
      'The response and contributions will no longer be available to either of you. Joint public links will also stop working.';

  @override
  String get blogWithdrawExchange => 'Withdraw exchange';

  @override
  String get blogReportExchange => 'Report exchange';

  @override
  String get blogBlockMessageExchange =>
      'Contact and access to each other’s chapters will stop.';

  @override
  String get blogBlockFailed => 'Could not block this member.';

  @override
  String get notificationsReadAll => 'Read all';

  @override
  String get notificationsFallbackTitle => 'Notification';

  @override
  String get notificationsLoadFailed => 'Unable to load notifications.';

  @override
  String get notificationsPrefsUpdateFailed =>
      'Unable to update notification preferences.';

  @override
  String notificationsAgoMinutes(int count) {
    return '${count}m ago';
  }

  @override
  String notificationsAgoHours(int count) {
    return '${count}h ago';
  }

  @override
  String notificationsAgoDays(int count) {
    return '${count}d ago';
  }

  @override
  String get wallsReactEyebrow => 'REACT';

  @override
  String wallsReactQuestion(String noun) {
    String _temp0 = intl.Intl.selectLogic(noun, {
      'photo': 'How does this photo make you feel?',
      'other': 'How does this chapter make you feel?',
    });
    return '$_temp0';
  }

  @override
  String get wallsReactBody =>
      'Your reaction tells them they were heard. Every reaction counts as a like.';

  @override
  String get wallsReactRemove => 'Take my reaction back';

  @override
  String wallsReactionsSemantics(String list) {
    return 'Reactions: $list';
  }

  @override
  String get wallsReactionLove => 'Love this';

  @override
  String get wallsReactionHearYou => 'I hear you';

  @override
  String get wallsReactionMeToo => 'Me too';

  @override
  String get wallsReactionWithYou => 'I’m with you';

  @override
  String get wallsReactionHug => 'Sending a hug';

  @override
  String get wallsReactionProud => 'Proud of you';

  @override
  String get wallsSignInRequired => 'Sign in to see your wall.';

  @override
  String get celebrationCoverHeadline => 'Your photo is Cover of the Week';

  @override
  String celebrationReachHeadline(String kind, int reach) {
    String _temp0 = intl.Intl.selectLogic(kind, {
      'photo': 'Your photo reached $reach walls',
      'other': 'Your chapter reached $reach walls',
    });
    return '$_temp0';
  }

  @override
  String get celebrationCoverMessage =>
      'Members loved it. Everyone sees it on Today this week.';

  @override
  String get celebrationReachMessage =>
      'Members loved it. It is now on their Today walls.';

  @override
  String celebrationQuotedTitle(String title) {
    return '“$title”';
  }

  @override
  String get celebrationBarrier => 'Celebration';

  @override
  String get celebrationLovely => 'Lovely';

  @override
  String get celebrationSeePhoto => 'See photo';

  @override
  String get celebrationSeeChapter => 'See chapter';

  @override
  String rewardXpPill(int xp) {
    return '+$xp XP';
  }

  @override
  String get rewardClaimedTitle => 'Reward claimed';

  @override
  String rewardNameDescription(String name, String description) {
    return '$name · $description';
  }

  @override
  String rewardPlusXpAnnouncement(int xp) {
    return 'plus $xp XP';
  }

  @override
  String rewardSourceXpLine(String source, int xp) {
    return '$source +$xp XP';
  }

  @override
  String rewardAndMore(int count) {
    return 'and $count more';
  }

  @override
  String rewardBadgeLine(String badge) {
    return 'Badge: $badge';
  }

  @override
  String rewardLevelReached(int level) {
    return 'Level $level reached';
  }

  @override
  String rewardBadgesEarned(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count badges earned',
      one: 'Badge earned',
    );
    return '$_temp0';
  }

  @override
  String get rewardYourRewardsToday => 'Your rewards today';

  @override
  String rewardNewRewards(int count) {
    return '$count new rewards';
  }

  @override
  String get rewardSourceStoryPublished => 'Chapter published';

  @override
  String get rewardSourcePhotoShared => 'Photo shared';

  @override
  String get rewardSourceLikeReceived => 'A member liked your work';

  @override
  String get rewardSourceCommentReceived => 'New comment on your work';

  @override
  String get rewardSourceCommentApproved => 'Your comment was approved';

  @override
  String get rewardSourceSubscriberGained => 'New subscriber';

  @override
  String get rewardSourceWallTierReached => 'Wall tier reached';

  @override
  String get rewardSourceCoverOfWeek => 'Cover of the Week';

  @override
  String get rewardSourceDailyPromptSubmitted => 'Daily prompt answered';

  @override
  String get rewardLineStoryPublished => 'Your chapter is out in the world.';

  @override
  String get rewardLinePhotoShared => 'Your photo joined the theme.';

  @override
  String get rewardLineLikeReceived => 'Someone loved what you shared.';

  @override
  String get rewardLineCommentReceived => 'A reader joined the conversation.';

  @override
  String get rewardLineSubscriberGained => 'Someone wants your next chapter.';

  @override
  String get rewardLineWallTierReached => 'Your work reached more walls.';

  @override
  String get rewardLineCoverOfWeek => 'Everyone sees it on Today this week.';

  @override
  String get rewardLineOther => 'Earned for meaningful activity.';

  @override
  String get rewardNewBadgeFallback => 'New badge';

  @override
  String get blockedUnknownUser => 'Unknown User';

  @override
  String get themeTaglineBluerose =>
      'Midnight velvet, sapphire roses and a platinum edge.';

  @override
  String get themeTaglineBluelotus =>
      'Moonlit water, sapphire petals and a golden heart.';

  @override
  String discoverMessageLikeSent(String name) {
    return 'Love sent to $name. You can chat as soon as they like you back.';
  }

  @override
  String get notificationsDismissFailed =>
      'Couldn\'t remove that notification. Try again.';

  @override
  String get notificationsReadAllFailed =>
      'Couldn\'t mark them all as read. Try again.';

  @override
  String get blogReportSubmitted => 'Report submitted. Thank you.';

  @override
  String get settingsSectionAccount => 'Account';

  @override
  String settingsSignedInAs(String username) {
    return 'Signed in as @$username';
  }

  @override
  String get settingsSignOut => 'Sign out';

  @override
  String get settingsSignOutSubtitle => 'End your session on this device';

  @override
  String get settingsSignOutAllTitle => 'Sign out of all devices';

  @override
  String get settingsSignOutAllSubtitle =>
      'End every session, on every phone and browser';

  @override
  String get settingsSignOutConfirmTitle => 'Sign out?';

  @override
  String get settingsSignOutConfirmBody =>
      'You\'ll need your username and password to sign in again on this device.';

  @override
  String get settingsSignOutAllConfirmTitle => 'Sign out of all devices?';

  @override
  String get settingsSignOutAllConfirmBody =>
      'This ends your session on every phone, tablet and browser, including this one. Anyone signed in to your account elsewhere will be signed out.';

  @override
  String get settingsSignOutAllConfirmAction => 'Sign out everywhere';

  @override
  String get settingsSignOutAllFailed =>
      'Couldn\'t sign out your other devices. Check your connection and try again.';

  @override
  String get supportPaymentHelpLink => 'Payment problem? Contact support';

  @override
  String get supportReportHelpLink => 'Need more help? Contact support';

  @override
  String get supportSignedOutHelpLink =>
      'Something else wrong? Contact support';

  @override
  String get supportGuestSubtitle =>
      'Can’t sign in, or something else isn’t working? Tell us what happened and we’ll reply by email.';

  @override
  String get supportGuestEmailLabel => 'Your email';

  @override
  String get supportGuestEmailHint => 'We’ll reply to this address';

  @override
  String get supportGuestNameLabel => 'Your name (optional)';

  @override
  String get supportGuestEmailInvalid =>
      'Enter a valid email address so we can reply.';

  @override
  String get supportGuestSentTitle => 'Request sent';

  @override
  String supportGuestSentBody(String reference, String email) {
    return 'Thanks. Your reference is $reference. We’ll reply to $email.';
  }

  @override
  String get supportGuestUnavailableBody =>
      'Support requests can’t be sent from the app right now. For anything urgent, email support@connect.example.';

  @override
  String get supportDraftRestored => 'We kept your unsent request.';

  @override
  String get supportDraftDiscard => 'Discard draft';

  @override
  String get discoverActionUndo => 'Undo';

  @override
  String get discoverActionLike => 'Like';

  @override
  String get discoverActionSuperLike => 'Super like';

  @override
  String get navQaVerifyShortcut => 'Verify';

  @override
  String get chatMessageDeletedPlaceholder => 'Message deleted';

  @override
  String get chatGiftYouSentHeading => 'You sent a gift';

  @override
  String get commonMemberFallbackName => 'A member';

  @override
  String get giftNameRoseRedSingle => 'Single Red Rose';

  @override
  String get giftNameRosePinkSoft => 'Pink Rose';

  @override
  String get giftNameRoseWhitePure => 'White Rose';

  @override
  String get giftNameRoseYellowFriendship => 'Yellow Rose';

  @override
  String get giftNameRoseLavenderCrush => 'Lavender Rose';

  @override
  String get giftNameRoseBlueRare => 'Blue Rose';

  @override
  String get giftNameRoseBlackMystery => 'Black Rose';

  @override
  String get giftNameRoseSparkle => 'Sparkle Rose';

  @override
  String get giftNameRoseHeartPetal => 'Heart-Petal Rose';

  @override
  String get giftNameRoseNeonGlow => 'Neon Rose';

  @override
  String get giftNameRoseRain => 'Rose Rain';

  @override
  String get giftNameRoseBurningFlame => 'Burning Rose';

  @override
  String get giftNameRoseGolden => 'Golden Rose';

  @override
  String get giftNameRoseCrystal => 'Crystal Rose';

  @override
  String get giftNameRoseBouquet12 => 'Rose Bouquet (12)';

  @override
  String get giftNameRoseBouquet24 => 'Rose Bouquet (24)';

  @override
  String get giftNameRoseSeasonalWeekly => 'Seasonal Limited Rose';

  @override
  String get giftNameChocolateBox => 'Chocolate Box';

  @override
  String get giftNameHeartBalloon => 'Heart Balloon';

  @override
  String get giftNameTeddyBear => 'Teddy Bear';

  @override
  String get giftNameFlowerBouquet => 'Flower Bouquet';

  @override
  String get giftNameJewelleryBox => 'Jewelry Box';

  @override
  String get giftNameChampagneToast => 'Champagne Toast';

  @override
  String get giftNameHeartExplosion => 'Heart Explosion';

  @override
  String get giftNameConfettiShower => 'Confetti Shower';

  @override
  String get giftNameFireworksBurst => 'Fireworks Burst';

  @override
  String get giftNameStarShower => 'Star Shower';

  @override
  String get giftNameGoldenSparkle => 'Golden Sparkle';

  @override
  String get giftNameRainbowWave => 'Rainbow Wave';

  @override
  String get giftNameCoffeeDateInvite => 'Coffee Date Invite';

  @override
  String get giftNamePicnicInvite => 'Picnic Invite';

  @override
  String get giftNameMovieNightInvite => 'Movie Night Invite';

  @override
  String get giftNameSunsetWalkInvite => 'Sunset Walk Invite';

  @override
  String get giftNameDateNightCard => 'Date Night Card';

  @override
  String get giftNameValentineSurprise => 'Valentine\'s Surprise';

  @override
  String get giftNameDiamondRing => 'Diamond Ring';

  @override
  String get giftNameLuxuryDate => 'Luxury Date Experience';

  @override
  String get blogPublicationUnavailableTitle => 'Sharing unavailable';

  @override
  String get blogPublicationUnavailableExcerpt =>
      'The source changed or access was withdrawn. Withdraw this link.';

  @override
  String get blogNoticeKindPost => 'Post';

  @override
  String get blogNoticeKindResponse => 'Response';

  @override
  String get blogNoticeKindPublication => 'Public copy';

  @override
  String get blogNoticeKindThemeEntry => 'Theme photo';

  @override
  String get blogNoticeKindClub => 'Club';

  @override
  String get blogNoticeKindClubPost => 'Club post';

  @override
  String get blogNoticeKindReview => 'Review';

  @override
  String get blogNoticeKindList => 'List';

  @override
  String get blogNoticeKindComment => 'Comment';

  @override
  String get blogNoticeKindPhotoComment => 'Photo comment';

  @override
  String get blogNoticeKindChatMessage => 'Chat message';

  @override
  String get blogNoticeKindGroup => 'Group';

  @override
  String get blogNoticeKindOther => 'Content';

  @override
  String get blogNoticeStatusPending => 'Under review';

  @override
  String get blogNoticeStatusDismissed => 'No action taken';

  @override
  String get blogNoticeStatusRemoved => 'Removed';

  @override
  String get blogNoticeStatusRestored => 'Restored';

  @override
  String get engagementTrustMilestoneProfileDepth => 'Profile depth';

  @override
  String get engagementTrustMilestoneCommunication => 'Communication';

  @override
  String get engagementTrustMilestoneConsistency => 'Consistency';

  @override
  String get engagementTrustMilestonePromptCompletion => 'Prompts answered';

  @override
  String get engagementTrustMilestoneActivitySignals => 'Activity signals';

  @override
  String get engagementTrustMilestoneUnsafeSignals => 'Safety flags';

  @override
  String get engagementTrustMilestoneReportPenalty => 'Report penalty';

  @override
  String get engagementTrustMilestoneVerification => 'Verification consistent';

  @override
  String get engagementTrustMilestoneSafety => 'Safety';

  @override
  String engagementTrustMilestoneLine(String label, String value) {
    return '$label: $value';
  }

  @override
  String get networkOfflineTryAgain =>
      'Can\'t connect right now. Check your internet connection and try again.';

  @override
  String get apiErrorFeatureUnavailable =>
      'This feature isn\'t available right now.';

  @override
  String get apiErrorConversationUnavailable =>
      'This conversation is no longer available.';

  @override
  String get apiErrorMemberUnavailable => 'This member isn\'t available.';

  @override
  String get apiErrorChatLocked => 'Unlock this conversation first.';

  @override
  String get apiErrorCopilotDailyLimit =>
      'You\'ve used today\'s drafts. Write this one yourself.';

  @override
  String get apiErrorCopilotUnavailable =>
      'Drafting help isn\'t available right now.';

  @override
  String get apiErrorCopilotProfileUnavailable =>
      'Their profile isn\'t available right now.';

  @override
  String get apiErrorDatePlanAlreadyOpen =>
      'A date plan is already open for this match.';

  @override
  String get apiErrorDatePlanMatchInactive =>
      'Date plans need an active match.';

  @override
  String get apiErrorDatePlanNotOpen => 'This date plan is no longer open.';

  @override
  String get apiErrorDatePlanCheckInTooEarly =>
      'You can check in once the plan starts.';

  @override
  String get apiErrorDatePlanDebriefTooEarly =>
      'The debrief opens once the plan starts.';

  @override
  String get apiErrorSharedAvailabilityChanged =>
      'Shared availability has changed. Refresh the suggested times or pick a time yourself.';

  @override
  String get apiErrorGraduationAlreadyOpen =>
      'A graduation proposal is already open for this match.';

  @override
  String get apiErrorGraduationMatchInactive =>
      'Graduating needs an active match.';

  @override
  String get apiErrorGraduationNotOpen =>
      'This graduation proposal is no longer open.';

  @override
  String get apiErrorGraduationAlreadyConfirmed =>
      'You\'ve already graduated together.';

  @override
  String get apiErrorOutOfDate =>
      'This view is out of date. Refresh and try again.';

  @override
  String get apiErrorOutcomeUncertain =>
      'We couldn\'t confirm that. Refresh to check before trying again.';

  @override
  String get apiErrorInsufficientCoins =>
      'You don\'t have enough coins for this.';

  @override
  String get apiErrorChannelReadOnly => 'This chat is read-only right now.';

  @override
  String get apiErrorRoomFull =>
      'This room is full right now. Try again in a little while.';

  @override
  String get apiErrorRoomRemoved =>
      'A host removed you from this room. You can rejoin when this session ends.';

  @override
  String get apiErrorRoomNotJoined => 'You\'re not in this room.';

  @override
  String get apiErrorDailyMessageLimit =>
      'You\'ve used today\'s messages. Try again after the reset or upgrade your plan.';

  @override
  String get apiErrorDailyLikeLimit =>
      'You\'ve used today\'s likes. Try again after the reset or upgrade your plan.';

  @override
  String get apiErrorFriendRequired => 'You need to be friends first.';

  @override
  String get apiErrorVouchExists => 'You\'ve already vouched for them.';

  @override
  String get apiErrorIntroUnavailable => 'This intro isn\'t available anymore.';

  @override
  String get apiErrorIntroAlreadyOpen =>
      'An intro for these two is already open.';

  @override
  String get apiErrorIntroNotOpen => 'This intro is no longer open.';

  @override
  String get apiErrorTooManyTries =>
      'Too many tries. Wait a moment and try again.';

  @override
  String get apiErrorQuestCooldown =>
      'This quest is cooling down. Try again a little later.';

  @override
  String get apiErrorQuestSelfReview =>
      'Your match reviews your quest answer, not you.';

  @override
  String get apiErrorQuestNotParticipant =>
      'Only members of this match can take part in its quest.';

  @override
  String get apiErrorPaymentsUnavailable =>
      'Coin purchases aren\'t available right now.';

  @override
  String get apiErrorServiceBusy =>
      'The service is busy right now. Try again in a moment.';

  @override
  String get apiErrorSignInAgain => 'Please sign in again to continue.';

  @override
  String get friendsMemberFallback => 'A member';

  @override
  String get friendsActivityFallback => 'Activity';

  @override
  String get membershipPlanFallback => 'Plan';

  @override
  String get membershipSubscriptionFallback => 'Subscription';

  @override
  String engagementLevelRewardFallback(int level) {
    return 'Level $level reward';
  }

  @override
  String get engagementTrustBadgeUnknown => 'Unknown badge';

  @override
  String get firstChapterComfortDefaultLanguage => 'English';

  @override
  String paymentWalletBalanceCoins(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString coins',
      one: '1 coin',
    );
    return '$_temp0';
  }

  @override
  String get languageIntroSignedOut =>
      'Pick the language Connect uses. It changes right away, and when you sign in it\'s saved to your account.';

  @override
  String languagePickerButtonSemantics(String language) {
    return 'Language: $language. Change language';
  }

  @override
  String get authErrorUsernameTaken =>
      'That username is already taken. Try another one.';

  @override
  String get authErrorAccountSuspended =>
      'This account is suspended. Contact support if you think this is a mistake.';

  @override
  String get authErrorAccountLocked =>
      'Too many sign-in attempts. Try again in a few minutes.';

  @override
  String get authErrorTooManyRequests =>
      'Too many tries. Wait a moment and try again.';

  @override
  String get authErrorAccountTypeUnavailable =>
      'This kind of account isn\'t available right now.';

  @override
  String get authErrorNetwork =>
      'Can\'t connect right now. Check your internet connection and try again.';

  @override
  String get profileSetupReorderPhoto => 'Drag to reorder this photo';

  @override
  String get profileLanguageAssamese => 'Assamese';

  @override
  String get profileLanguageBengali => 'Bengali';

  @override
  String get profileLanguageBodo => 'Bodo';

  @override
  String get profileLanguageDogri => 'Dogri';

  @override
  String get profileLanguageEnglish => 'English';

  @override
  String get profileLanguageGujarati => 'Gujarati';

  @override
  String get profileLanguageHindi => 'Hindi';

  @override
  String get profileLanguageKannada => 'Kannada';

  @override
  String get profileLanguageKashmiri => 'Kashmiri';

  @override
  String get profileLanguageKonkani => 'Konkani';

  @override
  String get profileLanguageMaithili => 'Maithili';

  @override
  String get profileLanguageMalayalam => 'Malayalam';

  @override
  String get profileLanguageManipuri => 'Manipuri';

  @override
  String get profileLanguageMarathi => 'Marathi';

  @override
  String get profileLanguageNepali => 'Nepali';

  @override
  String get profileLanguageOdia => 'Odia';

  @override
  String get profileLanguagePunjabi => 'Punjabi';

  @override
  String get profileLanguageSanskrit => 'Sanskrit';

  @override
  String get profileLanguageSantali => 'Santali';

  @override
  String get profileLanguageSindhi => 'Sindhi';

  @override
  String get profileLanguageTamil => 'Tamil';

  @override
  String get profileLanguageTelugu => 'Telugu';

  @override
  String get profileLanguageUrdu => 'Urdu';

  @override
  String get profileCountryIndia => 'India';

  @override
  String get profileCountryUnitedKingdom => 'United Kingdom';

  @override
  String get profileCountryIreland => 'Ireland';

  @override
  String get profileCountryGermany => 'Germany';

  @override
  String get profileCountryAustria => 'Austria';

  @override
  String get profileMasterWorkoutSometimes => 'Sometimes';

  @override
  String get profileMasterWorkoutWeekly => 'Weekly';

  @override
  String get profileMasterTravelRoadTrips => 'Road trips';

  @override
  String get profileMasterTravelBackpacking => 'Backpacking';

  @override
  String get profileMasterTravelLuxuryShort => 'Luxury';

  @override
  String get profileMasterTravelStaycations => 'Staycations';

  @override
  String get profileMasterPoliticsSimilarShort => 'Similar';

  @override
  String get profileMasterPoliticsModerate => 'Moderate';

  @override
  String get profileMasterPoliticsAny => 'Any';
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

  @override
  String get callsHistoryTitle => 'Call history';

  @override
  String get callsHistoryEmpty => 'No call sessions yet.';

  @override
  String callsHistoryMatch(String id) {
    return 'Match $id';
  }

  @override
  String get callsJoinLiveRoom => 'Join live room';

  @override
  String get callsActiveSession => 'Active call session';

  @override
  String callsEndedWithDuration(String duration) {
    return 'Ended · $duration';
  }

  @override
  String get callsSessionTitle => 'Call session';

  @override
  String get callsStarting => 'Starting secure session…';

  @override
  String get callsSessionActive => 'Session active';

  @override
  String get callsSessionUnavailable => 'Session unavailable';

  @override
  String get callsLiveRoomNote =>
      'The live room opens in a secure provider window. Use that room’s microphone, camera, and leave controls during the call.';

  @override
  String get callsEnd => 'End';

  @override
  String get callsErrorSignInHistory => 'Please sign in to view call history.';

  @override
  String get callsErrorSignInStart => 'Please sign in before starting a call.';

  @override
  String get callsErrorPermissions =>
      'Camera and microphone permissions are required for calls.';

  @override
  String get callsErrorLoadHistory => 'Unable to load call history.';

  @override
  String get callsErrorStart => 'Unable to start the call session.';

  @override
  String get callsErrorEnd => 'Unable to end the call.';

  @override
  String get callsErrorNotConfigured =>
      'Live call rooms are not configured for this environment.';

  @override
  String get callsErrorOpenRoom => 'Unable to open the live call room.';

  @override
  String get commonRetry => 'Retry';

  @override
  String get commonCancel => 'Cancel';

  @override
  String get commonClose => 'Close';

  @override
  String get commonCopy => 'Copy';

  @override
  String get commonDelete => 'Delete';

  @override
  String get commonBack => 'Back';

  @override
  String get commonApply => 'Apply';

  @override
  String get commonReset => 'Reset';

  @override
  String get commonOpen => 'Open';

  @override
  String get commonView => 'View';

  @override
  String get commonDismiss => 'Dismiss';

  @override
  String get commonAny => 'Any';

  @override
  String get commonSomethingWentWrong => 'Something went wrong';

  @override
  String get commonSomethingWentWrongTryAgain =>
      'Something went wrong. Please try again.';

  @override
  String get commonTryAgainTitle => 'Try Again';

  @override
  String get commonNothingHereYet => 'Nothing here yet';

  @override
  String commonLoadingLabel(String label) {
    return '$label, loading';
  }

  @override
  String commonDistanceKm(int distance) {
    return '$distance km';
  }

  @override
  String get navToday => 'Today';

  @override
  String get navOfflineBanner => 'Offline mode: Some data may be outdated.';

  @override
  String navWeakNetworkBanner(int mbps) {
    return 'Weak network detected. Use at least $mbps Mbps for smoother app performance.';
  }

  @override
  String get navIncomingCallTitle => 'Incoming call';

  @override
  String get navIncomingCallBody => 'A match is calling you.';

  @override
  String get navViewCallDetails => 'View call details';

  @override
  String get filterSheetTitle => 'Filter Matches';

  @override
  String get filterAgeRange => 'Age Range';

  @override
  String get filterProfileLifestyle => 'Profile & Lifestyle Filters';

  @override
  String get filterCountry => 'Country';

  @override
  String get filterState => 'State';

  @override
  String get filterCity => 'City';

  @override
  String get filterMotherTongue => 'Mother Tongue';

  @override
  String get filterReligion => 'Religion';

  @override
  String get filterRelationshipStatus => 'Relationship Status';

  @override
  String get filterSmoking => 'Smoking';

  @override
  String get filterDrinking => 'Drinking';

  @override
  String get filterPersonalityType => 'Personality Type';

  @override
  String get filterPartyLoverOnly => 'Party lover only';

  @override
  String get filterHookupsOnly => 'Hookups only';

  @override
  String get filterAdvancedBio => 'Advanced Bio Filters';

  @override
  String get filterAdvancedBioBody =>
      'Books, novels, songs, hobbies, location and extra-curricular tags can be managed in Settings → Dating Preferences.';

  @override
  String get filterOpenDatingPreferences => 'Open Dating Preferences';

  @override
  String get filterDistanceKm => 'Distance (km)';

  @override
  String get filterVerifiedOnlyTitle => 'Verified Only';

  @override
  String get filterVerifiedOnlyBody => 'Show only verified profiles';

  @override
  String get filterVerifiedOnlyChip => 'Verified only';

  @override
  String get filterPartyLoverChip => 'Party lover';

  @override
  String get filterHookupChip => 'Hookup only';

  @override
  String get filterEnableTrust => 'Enable trust-based filtering';

  @override
  String filterMinimumTrustBadges(int count) {
    return 'Minimum active trust badges: $count';
  }

  @override
  String filterSavedSnack(
    int minAge,
    int maxAge,
    int distance,
    String verified,
    String trust,
  ) {
    String _temp0 = intl.Intl.selectLogic(verified, {
      'true': ', verified only',
      'other': '',
    });
    String _temp1 = intl.Intl.selectLogic(trust, {
      'true': ', trust filter on',
      'other': ', trust filter off',
    });
    return 'Filters saved: $minAge-$maxAge yrs, $distance km$_temp0$_temp1';
  }

  @override
  String get optionNever => 'Never';

  @override
  String get optionOccasionally => 'Occasionally';

  @override
  String get optionSocially => 'Socially';

  @override
  String get optionRegularly => 'Regularly';

  @override
  String get optionSingle => 'Single';

  @override
  String get optionDivorced => 'Divorced';

  @override
  String get optionWidowed => 'Widowed';

  @override
  String get optionSeparated => 'Separated';

  @override
  String get optionComplicated => 'Complicated';

  @override
  String get optionIntrovert => 'Introvert';

  @override
  String get optionAmbivert => 'Ambivert';

  @override
  String get optionExtrovert => 'Extrovert';

  @override
  String get optionHighSchool => 'High School';

  @override
  String get optionBachelors => 'Bachelor\'s';

  @override
  String get optionMasters => 'Master\'s';

  @override
  String get optionPhd => 'PhD';

  @override
  String get optionOther => 'Other';

  @override
  String get optionPreferNotToSay => 'Prefer not to say';

  @override
  String get optionHindu => 'Hindu';

  @override
  String get optionMuslim => 'Muslim';

  @override
  String get optionChristian => 'Christian';

  @override
  String get optionSikh => 'Sikh';

  @override
  String get optionBuddhist => 'Buddhist';

  @override
  String get optionJain => 'Jain';

  @override
  String get optionJewish => 'Jewish';

  @override
  String get optionSpiritual => 'Spiritual';

  @override
  String get optionAgnostic => 'Agnostic';

  @override
  String get optionAtheist => 'Atheist';

  @override
  String get storiesNudgeTitle => 'Tell a little more of your story';

  @override
  String get storiesNudgeBodyUnknown =>
      'Short stories on your profile give people something real to say hello about.';

  @override
  String get storiesNudgeActionOpen => 'Open your stories';

  @override
  String get storiesNudgeBodyEmpty =>
      'Add a short story to your profile: a small joy, a weekend worth sharing. People read these before they say hello.';

  @override
  String get storiesNudgeActionFirst => 'Write your first story';

  @override
  String get storiesNudgeCompleteTitle => 'Your story is complete';

  @override
  String get storiesNudgeCompleteBody =>
      'All three stories are on your profile. Refresh one whenever life gives you a new one.';

  @override
  String get storiesNudgeActionEdit => 'Edit your stories';

  @override
  String storiesNudgeSharedTitle(int count, int max) {
    return '$count of $max stories shared';
  }

  @override
  String get storiesNudgeBodyMore =>
      'One more story gives people another way to start a conversation.';

  @override
  String storiesNudgeBodyLatest(String prompt) {
    return 'Latest: “$prompt”. One more gives people another way to start a conversation.';
  }

  @override
  String get storiesNudgeActionAdd => 'Add another story';

  @override
  String get storiesNudgeIdeas => 'Ideas to start with';

  @override
  String storiesProgressSemantics(int count, int max) {
    return '$count of $max stories written';
  }

  @override
  String get storiesPromptLittleJoy => 'A small thing I always make time for';

  @override
  String get storiesPromptWeekend => 'A weekend worth sharing';

  @override
  String get storiesPromptFirstHello => 'A first hello I would love';

  @override
  String get storiesPromptLearning => 'Something I am learning, just for me';

  @override
  String get storiesPromptCare => 'A small way I show I care';

  @override
  String get storiesScreenTitle => 'A little more you';

  @override
  String get storiesSignIn => 'Sign in to edit your stories.';

  @override
  String get storiesLoadFailed => 'Your stories couldn’t load.';

  @override
  String get storiesTryAgain => 'Try again';

  @override
  String get storiesIncomplete =>
      'Add words to each story and a description for each photo, or remove the unfinished story.';

  @override
  String get storiesPublished => 'Your profile stories are published.';

  @override
  String get storiesSavedPrivately =>
      'Saved privately. Your stories are hidden from other members.';

  @override
  String get storiesSaveUnconfirmed =>
      'We couldn’t confirm the save. Your edits are still here; reload saved stories to check.';

  @override
  String get storiesHeadline => 'Let someone meet\nthe everyday you.';

  @override
  String get storiesIntro =>
      'A small ritual, a story behind a photo, a first hello you would enjoy. Share up to three moments, in your own words.';

  @override
  String get storiesOptionalNote =>
      'Optional, with no score or completion requirement. Avoid contact details or precise locations you do not want to share.';

  @override
  String get storiesPublishSwitch => 'Show these stories on my profile';

  @override
  String get storiesPublishSwitchHint =>
      'Starts off. Visible to eligible members when your profile is published and available. You can hide them at any time.';

  @override
  String get storiesBackToEditing => 'Back to editing';

  @override
  String get storiesPreview => 'Preview my stories';

  @override
  String get storiesPreviewBanner => 'PREVIEW · THIS DOES NOT PUBLISH';

  @override
  String get storiesAdd => 'Add a story';

  @override
  String get storiesReloadDiscard => 'Reload saved stories · discard edits';

  @override
  String get storiesSaving => 'Saving…';

  @override
  String get storiesPublishButton => 'Publish stories';

  @override
  String get storiesSavePrivatelyButton => 'Save privately';

  @override
  String get storiesPolicyNote =>
      'Photos come from your approved profile gallery. Stories and photos remain subject to member reporting and safety policies.';

  @override
  String storiesMomentLabel(int number) {
    return 'MOMENT $number';
  }

  @override
  String storiesRemoveTooltip(int number) {
    return 'Remove story $number';
  }

  @override
  String get storiesPromptLabel => 'A starting point';

  @override
  String get storiesTextLabel => 'In your words';

  @override
  String get storiesTextHint => 'A real detail makes it yours.';

  @override
  String get storiesTextRequired => 'Add a few words, or remove this story.';

  @override
  String get storiesPhotoLabel => 'A photo, if you like';

  @override
  String get storiesWordsOnly => 'Words only';

  @override
  String storiesProfilePhoto(int number) {
    return 'Profile photo $number';
  }

  @override
  String get storiesPhotoDescriptionLabel => 'Describe this photo';

  @override
  String get storiesPhotoDescriptionHelper =>
      'Helps people using screen readers.';

  @override
  String get storiesPhotoDescriptionRequired =>
      'Add a short photo description.';

  @override
  String get storiesPhotoSemantics => 'Profile story photo';

  @override
  String get storiesSectionTitle => 'A little more me';

  @override
  String get storiesRetryLoad => 'Try loading stories again';

  @override
  String get authErrorSessionExpired =>
      'You were signed out. Please sign in again.';

  @override
  String get authErrorSignInFailed => 'Unable to sign in. Try again.';

  @override
  String get authErrorCreateAccountFailed =>
      'Unable to create account. Try again.';

  @override
  String get authErrorCreateAccountGeneric => 'Unable to create account.';

  @override
  String get authErrorInvalidCredentials => 'Invalid username or password.';

  @override
  String get authErrorUsernameFormat =>
      'Username must be 3–30 characters using letters, numbers, _ or .';

  @override
  String get authErrorPasswordFormat =>
      'Password must be 8–72 bytes with letters and numbers.';

  @override
  String get authWelcomeIntroducerLink => 'Just here to introduce friends';

  @override
  String get signupBackTooltip => 'Back';

  @override
  String get signupIntroducerTitle =>
      'Be the friend who brings people together.';

  @override
  String get signupIntroducerBody =>
      'A friend-only account. No dating profile, photos or swiping. Your age stays private; Connect is for adults 18–80.';

  @override
  String get signupTitle => 'Create your account';

  @override
  String get signupSubtitle => 'Choose a unique username and secure password';

  @override
  String get signupUsernameLabel => 'Unique username';

  @override
  String get signupUsernameHint => 'your_username';

  @override
  String get signupUsernameHelp =>
      '3–30 characters. Letters, numbers, underscore and dot.';

  @override
  String get signupPasswordLabel => 'Password';

  @override
  String get signupPasswordHint => 'At least 8 characters';

  @override
  String get signupConfirmPasswordHint => 'Confirm password';

  @override
  String get signupNameLabel => 'Full name';

  @override
  String get signupNameHint => 'Your name';

  @override
  String get signupDobLabel => 'Date of birth';

  @override
  String get signupDobPickerHelp => 'Select date of birth';

  @override
  String get signupDobPlaceholder => 'Select date';

  @override
  String get signupGenderLabel => 'I identify as';

  @override
  String get signupGenderMan => 'Man';

  @override
  String get signupGenderWoman => 'Woman';

  @override
  String get signupGenderOther => 'Other';

  @override
  String get signupCreateFriendAccount => 'Create friend account';

  @override
  String get signupAlreadyHaveAccount => 'Already have an account?';

  @override
  String get signupErrorPasswordMismatch => 'Passwords do not match.';

  @override
  String get signupErrorFullName => 'Please enter your full name.';

  @override
  String get signupErrorDobMissing => 'Please select your date of birth.';

  @override
  String get signupErrorUnderage => 'You must be at least 18 years old.';

  @override
  String get signupErrorAgeRange =>
      'Connect currently supports members aged 18–80.';

  @override
  String get signupErrorGenderMissing => 'Please choose how you identify.';

  @override
  String get authRecoveryEnterUsername => 'Enter your username.';

  @override
  String get authRecoveryEnterCode => 'Enter your recovery code.';

  @override
  String get authRecoveryPasswordRule =>
      'Use 8–72 characters with at least one letter and one number.';

  @override
  String get authRecoveryResetDone =>
      'Your password has been reset and every device has been signed out. Sign in with your new password.';

  @override
  String get authRecoveryAssistanceDone =>
      'If this username belongs to a Connect account, our safety team will review the request.';

  @override
  String get authRecoveryInvalidCode =>
      'That recovery code is not valid or has expired.';

  @override
  String get authRecoveryOffline =>
      'Could not reach Connect. Check your connection and try again.';

  @override
  String get authRecoverySendFailed =>
      'Could not send your request. Check your connection and try again.';

  @override
  String get authRecoveryBackToSignIn => 'Back to sign in';

  @override
  String get authRecoveryHaveCode => 'I have my code';

  @override
  String get authRecoveryLostCode => 'I lost my code';

  @override
  String get authRecoveryHaveCodeIntro =>
      'Use the recovery code you saved when you created your account, or one issued by our safety team.';

  @override
  String get authRecoveryLostCodeIntro =>
      'Tell us your username. We\'ll confirm your identity before issuing a recovery code. We never ask for your password.';

  @override
  String get authRecoveryUsernameLabel => 'Username';

  @override
  String get authRecoveryCodeLabel => 'Recovery code';

  @override
  String get authRecoveryNewPasswordLabel => 'New password';

  @override
  String get authRecoveryMessageLabel => 'Anything that helps us (optional)';

  @override
  String get authRecoveryMessageHint => 'For example, when you last signed in';

  @override
  String get authRecoverySending => 'Sending…';

  @override
  String get authRecoveryResetPassword => 'Reset password';

  @override
  String get authRecoveryAskForHelp => 'Ask for help';

  @override
  String get authTermsTitle => 'Terms and Conditions';

  @override
  String get authTermsSubtitle => 'A quick review before you enter the app.';

  @override
  String get authTermsIntro =>
      'Please review and accept our Terms and Privacy Policy to continue.';

  @override
  String get authTermsCommunityTitle => 'Community expectations';

  @override
  String get authTermsPointRespect => 'Be respectful and authentic.';

  @override
  String get authTermsPointNoHarassment =>
      'No harassment or fraudulent behaviour.';

  @override
  String get authTermsPointPrivacy =>
      'You control your privacy settings and profile visibility.';

  @override
  String get authTermsPointReports =>
      'Reports are reviewed to keep the community safe.';

  @override
  String get authTermsPointViolations =>
      'Violations may result in suspension or account removal.';

  @override
  String get authTermsReviewLater =>
      'You can review the full policy details later from settings, but acceptance is required before using the app.';

  @override
  String get authTermsAgreeCheckbox => 'I agree to the Terms & Privacy Policy';

  @override
  String get authTermsAcceptButton => 'I Accept and Continue';

  @override
  String get authTermsSaveFailed =>
      'Could not save your agreement. Please check network and try again.';

  @override
  String discoverSuperLikeSent(String name) {
    return 'Super like sent to $name';
  }

  @override
  String get discoverMatchPlaceholderMessage => 'Say hi';

  @override
  String discoverChatNeedsMatch(String name) {
    return 'You can chat with $name after a real match is created.';
  }

  @override
  String get discoverDailyLimitTitle => 'You\'ve used today\'s likes';

  @override
  String get discoverDailyLimitBody =>
      'Come back tomorrow, or upgrade for more likes every day.';

  @override
  String discoverDailyLimitResetBody(String reset) {
    return '$reset. Upgrade for more likes every day.';
  }

  @override
  String get discoverSeePlans => 'See plans';

  @override
  String get discoverNotNow => 'Not now';

  @override
  String get discoverBackToToday => 'Back to Today';

  @override
  String get discoverExploreTitle => 'Explore';

  @override
  String get discoverSpotlightReviewed => 'Spotlight reviewed!';

  @override
  String get discoverAllReviewed => 'All reviewed!';

  @override
  String get discoverCuratedForYou => 'Curated for you';

  @override
  String get discoverTitle => 'Discover Matches';

  @override
  String get discoverTagline => 'A little curiosity. A real connection.';

  @override
  String get discoverMessages => 'Messages';

  @override
  String get discoverFilters => 'Filters';

  @override
  String get discoverYourDeck => 'Your deck';

  @override
  String get discoverStatReady => 'Ready';

  @override
  String get discoverStatLiked => 'Liked';

  @override
  String get discoverStatPassed => 'Passed';

  @override
  String get discoverEdit => 'Edit';

  @override
  String get discoverShowingEveryone => 'Showing everyone in your preferences.';

  @override
  String get discoverToday => 'Today';

  @override
  String get discoverTodaySubtitle => 'Five picks, refreshed every day.';

  @override
  String get discoverViewAll => 'View all';

  @override
  String get discoverMatchOnYourTerms => 'Match on your terms';

  @override
  String get discoverMatchOnYourTermsBody =>
      'Mutual interest creates a match. You can block or report anyone from their profile or conversation.';

  @override
  String get discoverErrorEyebrow => 'Connection paused';

  @override
  String get discoverErrorTitle => 'Unable to load profiles';

  @override
  String discoverTrustFilteredBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Trust filters hid $count profile(s). Try relaxing trust filters or refresh to rebuild your deck.',
    );
    return '$_temp0';
  }

  @override
  String get discoverDeckPreparingBody =>
      'Your curated deck is being prepared. Refresh to check for new verified profiles near you.';

  @override
  String get discoverCheckBackSoon => 'Check back soon';

  @override
  String get discoverNoSpotlightProfiles => 'No spotlight profiles';

  @override
  String get discoverNoProfiles => 'No profiles';

  @override
  String get discoverRefresh => 'Refresh';

  @override
  String get discoverPromisePrivate => 'Private';

  @override
  String get discoverPremium => 'Premium';

  @override
  String discoverNotificationsUnread(int count) {
    return 'Notifications, $count unread';
  }

  @override
  String get discoverLatestUnreadNotifications => 'Latest unread notifications';

  @override
  String get discoverNoUnreadNotifications => 'No unread notifications';

  @override
  String get discoverNotificationWhoReplied => 'Who replied me';

  @override
  String discoverNotificationRepliesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count new replies',
      one: '1 new reply',
    );
    return '$_temp0';
  }

  @override
  String get discoverNotificationWhoLiked => 'Who has liked me';

  @override
  String discoverNotificationLikesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count new likes',
      one: '1 new like',
    );
    return '$_temp0';
  }

  @override
  String get discoverViewMore => 'View more';

  @override
  String get discoverFitsYourWeek => 'Fits your week';

  @override
  String discoverTodayPicks(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count picks',
      one: '1 pick',
    );
    return '$_temp0';
  }

  @override
  String get discoverPickedForYouToday => 'Picked for you today.';

  @override
  String get discoverErrorLoginToDiscover =>
      'Please log in to discover profiles.';

  @override
  String get discoverErrorLoadProfiles =>
      'Failed to load profiles. Please try again.';

  @override
  String get discoverErrorSessionUnavailable =>
      'User session not available. Please log in again.';

  @override
  String get discoverErrorLikeRetry =>
      'Unable to like right now. Please try again.';

  @override
  String get discoverErrorLike => 'Unable to like right now.';

  @override
  String get discoverErrorPassRetry =>
      'Unable to pass right now. Please try again.';

  @override
  String get discoverErrorLoadLikedMe =>
      'Could not load who liked you. Please try again.';

  @override
  String get discoverErrorAnswerInFlight => 'Already sending your answer.';

  @override
  String get discoverErrorAnswer =>
      'Could not send your answer. Please try again.';

  @override
  String get firstChapterTopicPace => 'Communication pace';

  @override
  String get firstChapterTopicDates => 'Dating comfort';

  @override
  String get firstChapterTopicLanguage => 'Languages';

  @override
  String get firstChapterTopicFamily => 'Family involvement';

  @override
  String get firstChapterInMyWords => 'In my words';

  @override
  String firstChapterComfortOriginal(String language) {
    return 'Original · $language';
  }

  @override
  String firstChapterComfortMemberTranslation(String language) {
    return 'Member-provided translation · $language';
  }

  @override
  String get firstChapterComfortReloadSaved => 'Reload saved version';

  @override
  String get firstChapterComfortReloadCards => 'Reload comfort cards';

  @override
  String get firstChapterComfortHeadline => 'Your words. Your boundaries.';

  @override
  String get firstChapterComfortIntro =>
      'Optional context for people you have matched with. Nothing is inferred from your background. Write in the language that feels like you.';

  @override
  String get firstChapterComfortShareTitle =>
      'Share these cards with my matches';

  @override
  String get firstChapterComfortShareSubtitle =>
      'Off keeps every card private.';

  @override
  String get firstChapterComfortRemoveFromDraft => 'Remove from draft';

  @override
  String get firstChapterComfortTopicLabel => 'A little context about';

  @override
  String get firstChapterComfortOriginalLanguage => 'Original language';

  @override
  String get firstChapterComfortOwnWords => 'In your own words';

  @override
  String get firstChapterComfortOwnWordsHint =>
      'For example: I enjoy daytime dates and a little time to get comfortable.';

  @override
  String get firstChapterComfortTranslation => 'Your translation (optional)';

  @override
  String get firstChapterComfortTranslationLanguage =>
      'Translation language (if added)';

  @override
  String get firstChapterComfortTranslationNote =>
      'Translations are labelled as member-provided. Your original words are always preserved.';

  @override
  String get firstChapterComfortAddCard => 'Add / replace this card in draft';

  @override
  String get firstChapterComfortMissingFields =>
      'Add your words and language. A translation also needs its language.';

  @override
  String get firstChapterComfortUnaddedCard =>
      'Add your written card to the draft before saving.';

  @override
  String get firstChapterComfortSaveFailed =>
      'Your draft is still here. Reload to check the latest saved version before retrying.';

  @override
  String get firstChapterSaving => 'Saving…';

  @override
  String get firstChapterComfortSave => 'Save my choices';

  @override
  String get firstChapterYourMatch => 'your match';

  @override
  String get firstChapterSaveUnconfirmed =>
      'We could not confirm the save. Refresh to check before retrying.';

  @override
  String get firstChapterJointPreviewTitle => 'A story you both approve';

  @override
  String get firstChapterSoloPreviewTitle => 'Preview your public chapter';

  @override
  String firstChapterThenSurprise(String surprise) {
    return 'Then… $surprise';
  }

  @override
  String get firstChapterJointPreviewBody =>
      'Your approval is one half. The link works only after your partner also approves this exact card. Either of you can revoke it.';

  @override
  String get firstChapterSoloPreviewBody =>
      'Only this scene and your selected beginning are public. No names, photos, private chat, location or partner contribution. You can revoke the link.';

  @override
  String get firstChapterKeepPrivate => 'Keep private';

  @override
  String get firstChapterApproveMyHalf => 'Approve my half';

  @override
  String get firstChapterCreateShareLink => 'Create share link';

  @override
  String get firstChapterStudioTitle => 'First Chapter Studio';

  @override
  String get firstChapterRefresh => 'Refresh chapter';

  @override
  String get firstChapterHeroEyebrow => 'A SMALL ADVENTURE. TWO AUTHORS.';

  @override
  String get firstChapterHeroTitle => 'What happens\nnext is yours.';

  @override
  String get firstChapterHeroSolo =>
      'Make a scene. Pass it to a friend. Or create a first chapter with someone you have matched with.';

  @override
  String firstChapterHeroPair(String name) {
    return 'You and $name. One beginning, one unexpected turn, and a story you can make real.';
  }

  @override
  String get firstChapterHeroPace =>
      'Optional, at your pace. Chat is always a choice.';

  @override
  String get firstChapterLoadFailed => 'Your chapter could not be loaded.';

  @override
  String get firstChapterTryAgain => 'Try again';

  @override
  String get firstChapterStepChooseScene => '01 / Choose your scene';

  @override
  String get firstChapterStepWriteBeginning => '02 / Write the beginning';

  @override
  String get firstChapterStartOurChapter => 'Start our chapter';

  @override
  String get firstChapterPassTheChapter => 'Pass the Chapter';

  @override
  String get firstChapterYourFirstChapter => 'Your first chapter';

  @override
  String get firstChapterItBeginsWith => 'IT BEGINS WITH';

  @override
  String get firstChapterAndThen => 'AND THEN…';

  @override
  String firstChapterDateIdeaNote(String beginning, String surprise) {
    return '$beginning. Then $surprise.';
  }

  @override
  String get firstChapterMakeDateIdea => 'Make this a date idea';

  @override
  String get firstChapterDateIdeaHint =>
      'A suggestion to shape together. No date is booked or accepted automatically.';

  @override
  String get firstChapterYourTurn => 'Your turn: add a surprise.';

  @override
  String get firstChapterBeginningSaved =>
      'Your beginning is saved. Your match can add a surprise whenever they like. You can keep chatting.';

  @override
  String get firstChapterClose => 'Close this chapter';

  @override
  String get firstChapterGiveBackTitle => 'Stories that give back';

  @override
  String get firstChapterGiveBackBody =>
      'Your connection can inspire a new beginning. Share only this anonymous date idea, with both of your approvals.';

  @override
  String get firstChapterPreviewAnonymous => 'Preview our anonymous story';

  @override
  String get firstChapterGreenLightTitle => 'A private green light';

  @override
  String get firstChapterInTheirWords => 'In their words';

  @override
  String get firstChapterMakeRoomTitle => 'Make room for what matters to you';

  @override
  String get firstChapterMakeRoomSubtitle =>
      'Your pace, languages, dates and family expectations. Your words, shared only when you choose.';

  @override
  String get firstChapterCreateWithConnection => 'Create with a connection';

  @override
  String get firstChapterCreateTogether => 'Create a first chapter together';

  @override
  String get firstChapterMatchesAppearHere =>
      'Your mutual matches appear here. You can try and share a solo scene now.';

  @override
  String get firstChapterSharedChapters => 'Your shared chapters';

  @override
  String get firstChapterReloadShared => 'Reload shared chapters';

  @override
  String get firstChapterNothingPublic =>
      'Nothing public until you choose to share.';

  @override
  String get firstChapterGreenChat => 'Keep chatting';

  @override
  String get firstChapterGreenCall => 'Try a call';

  @override
  String get firstChapterGreenDate => 'Suggest a date';

  @override
  String get firstChapterGreenLightIntro =>
      'Only a shared choice is revealed. Nobody sees an unanswered request. Choices expire after seven days; clear them to withdraw.';

  @override
  String get firstChapterSavePrivately => 'Save privately';

  @override
  String get firstChapterGreenLightNone =>
      'Any shared next step will appear here.';

  @override
  String firstChapterGreenLightMutual(String choices) {
    return 'You both feel comfortable with: $choices';
  }

  @override
  String get firstChapterGreenLightNote =>
      'A green light is permission to suggest. A call or date still needs a separate agreement.';

  @override
  String get firstChapterLinkRevoked => 'Link revoked';

  @override
  String get firstChapterPublicScene => 'Public, anonymous scene';

  @override
  String get firstChapterPrivateUntilBoth => 'Private until both approve';

  @override
  String get firstChapterLinkCopied =>
      'Chapter link copied. Share it wherever you choose.';

  @override
  String get firstChapterCopyLink => 'Copy link';

  @override
  String get firstChapterApproveStory => 'Approve this exact story';

  @override
  String get firstChapterRevokeLink => 'Revoke link';

  @override
  String networkSlowResponse(int mbps) {
    return 'Weak network detected. Use at least $mbps Mbps for smoother chat, gifts, and gestures.';
  }

  @override
  String get networkOffline =>
      'No stable network connection. Reconnect to continue using the app.';

  @override
  String networkWeak(int mbps) {
    return 'Network is weak. Use at least $mbps Mbps for a smoother experience.';
  }

  @override
  String get networkCannotReachService =>
      'Cannot reach the local service. Check that the API is running.';

  @override
  String get gateCheckingTerms => 'Checking terms…';

  @override
  String get gateLoadingProfile => 'Loading your profile…';

  @override
  String get gateConnectionIssue => 'Connection issue';

  @override
  String get safetyReportFailed => 'Failed to report user';

  @override
  String get safetyBlockFailed => 'Failed to block user';

  @override
  String get safetyUnblockFailed => 'Failed to unblock user';

  @override
  String get safetyNotAuthenticated => 'Not authenticated';

  @override
  String get timeAgoJustNow => 'Just now';

  @override
  String timeAgoMinutes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count minutes ago',
      one: '1 minute ago',
    );
    return '$_temp0';
  }

  @override
  String timeAgoHours(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count hours ago',
      one: '1 hour ago',
    );
    return '$_temp0';
  }

  @override
  String timeAgoDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days ago',
      one: '1 day ago',
    );
    return '$_temp0';
  }

  @override
  String timeAgoWeeks(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count weeks ago',
      one: '1 week ago',
    );
    return '$_temp0';
  }

  @override
  String get themePreviewBarrier => 'Theme preview';

  @override
  String get themeNowShowing => 'NOW SHOWING';

  @override
  String get themeTaglineRealLife => 'Warm ivory, forest and apricot.';

  @override
  String get themeTaglineRealLifeNight => 'Forest, soft mint and candlelight.';

  @override
  String get themeTaglineDaylight =>
      'Cream, ink and a raspberry accent, like the website.';

  @override
  String get themeTaglineEmber =>
      'Plum-black night with ember and violet glow.';

  @override
  String get themeTaglineForge => 'Furnace red, steel blue, gunmetal chrome.';

  @override
  String get themeTaglineNeongrid =>
      'Black glass, cyan light-lines, amber pulse.';

  @override
  String get themeTaglineCrimsonalloy =>
      'Crimson lacquer, molten gold, midnight maroon.';

  @override
  String get themeTaglineCircuit =>
      'Circuit green, signal violet, carbon black.';

  @override
  String get themeTaglineDeepfield =>
      'Deep space, plasma blue and a flash of starlight gold.';

  @override
  String get themeTaglineLove => 'Blush, rose and a little gold.';

  @override
  String get themeTaglineRose => 'Velvet wine, rose red and a little gold.';

  @override
  String get themeTaglinePetal =>
      'Blush paper, drifting petals, a hint of sage.';

  @override
  String get themeTaglineSnow =>
      'Fresh snowfall, frosted glass and a ribbon of aurora.';

  @override
  String get themeTaglineGothic =>
      'Moonlit tracery, garnet, candle smoke and antique gold.';

  @override
  String get themeTaglineCalm =>
      'Low stimulation, high contrast. Still backdrop, no motion.';

  @override
  String get themeLooksTodayDescription =>
      'Warm ivory and forest by day. Soft mint and deep forest by night.';

  @override
  String get settingsEyebrow => 'SETTINGS';

  @override
  String get settingsHeaderSubtitle =>
      'Your look, your privacy and your account.';

  @override
  String get settingsThemeSection => 'Theme';

  @override
  String get settingsThemeSectionTitle => 'Make it yours';

  @override
  String get settingsThemeSectionCaption =>
      'Every screen follows the look you choose.';

  @override
  String get settingsSectionYourStory => 'Your story';

  @override
  String get settingsDatingRhythmTitle => 'Your dating rhythm';

  @override
  String get settingsDatingRhythmSubtitle =>
      'Intent, pace, availability and introduction privacy';

  @override
  String get settingsProfileStoriesTitle => 'Your profile stories';

  @override
  String get settingsProfileStoriesSubtitle =>
      'Small moments, your words, optional photos';

  @override
  String get settingsBlogTitle => 'Blog · Open Chapters';

  @override
  String get settingsBlogSubtitle =>
      'Your journal, your photos, your choice of audience';

  @override
  String get settingsLookPreviewEyebrow => 'TODAY';

  @override
  String get settingsLookPreviewHeadline => 'Something real.';

  @override
  String get friendsEyebrow => 'FRIENDS';

  @override
  String get friendsTitle => 'Your people';

  @override
  String get friendsSubtitle =>
      'Friends can message, plan and make groups together. Requests need a yes from both sides.';

  @override
  String get friendsBack => 'Back';

  @override
  String get friendsAddFriend => 'Add friend';

  @override
  String get friendsCreateGroup => 'Create a group';

  @override
  String get friendsSectionRequests => 'REQUESTS';

  @override
  String get friendsRequestsWaitingOnOthers => 'Waiting on others';

  @override
  String get friendsRequestsWaitingOnYou => 'Waiting on you';

  @override
  String get friendsRequestsCaption =>
      'Nothing is shared until both of you agree.';

  @override
  String get friendsSectionChats => 'CHATS';

  @override
  String get friendsChatsTitle => 'Conversations';

  @override
  String get friendsSectionIntros => 'INTROS';

  @override
  String get friendsIntrosTitle => 'Intros for you';

  @override
  String get friendsSectionVouches => 'VOUCHES';

  @override
  String get friendsVouchesPendingTitle => 'Vouches waiting for your approval';

  @override
  String friendsCountTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count friends',
      one: '1 friend',
      zero: 'No friends yet',
    );
    return '$_temp0';
  }

  @override
  String get friendsIntroduce => 'Introduce';

  @override
  String get friendsEmptyBody =>
      'Find people you know by name or username, or add someone from a match, a room or a group.';

  @override
  String get friendsSectionOnProfile => 'ON YOUR PROFILE';

  @override
  String get friendsVouchesOnProfileTitle => 'Vouches on your profile';

  @override
  String friendsQuoted(String text) {
    return '“$text”';
  }

  @override
  String friendsVouchedForYou(String name) {
    return '$name vouched for you';
  }

  @override
  String get friendsHideFromProfile => 'Hide from profile';

  @override
  String get friendsSectionMore => 'MORE';

  @override
  String get friendsMoreTitle => 'Plans and introductions';

  @override
  String get friendsPlansLinkTitle => 'Date plans shared with you';

  @override
  String get friendsPlansLinkSubtitle =>
      'Friends tell you when they plan a date and when they check in afterwards.';

  @override
  String get friendsInviteIntroducerTitle => 'Invite a friend who isn’t dating';

  @override
  String get friendsInviteIntroducerSubtitle =>
      'Choose who can introduce you. Review or withdraw permission anytime.';

  @override
  String get friendsIntroTermsTitle => 'Introductions, on your terms';

  @override
  String get friendsIntroTermsSubtitle =>
      'Choose whether friends can introduce you and what a preview shares.';

  @override
  String get friendsSectionActivity => 'ACTIVITY';

  @override
  String get friendsActivityTitle => 'With your friends';

  @override
  String friendsVouchSentSnack(String name) {
    return 'Vouch sent. $name approves it before it shows.';
  }

  @override
  String friendsRemoveTitle(String name) {
    return 'Remove $name?';
  }

  @override
  String get friendsRemoveBody =>
      'You’ll stop being friends and your friend chat closes. They aren’t told.';

  @override
  String get friendsRemoveFriend => 'Remove friend';

  @override
  String get friendsIntroMadeSnack =>
      'Intro made. Both friends will hear from you.';

  @override
  String get friendsAddSheetLabel => 'ADD FRIEND';

  @override
  String get friendsAddSheetTitle => 'Find someone you know';

  @override
  String get friendsAddSheetCaption =>
      'Search by name or @username. They choose whether to accept.';

  @override
  String get friendsSearchHiddenNote =>
      'You’re hidden from friend search, so others can’t find you here. Change this in Privacy & Safety.';

  @override
  String get friendsSearchLabel => 'Name or @username';

  @override
  String get friendsSearchHelper => 'Type at least 3 letters';

  @override
  String get friendsSearchFailed =>
      'Search is unavailable right now. Try again.';

  @override
  String friendsSearchNoResults(String query) {
    return 'No one found for “$query”.';
  }

  @override
  String get friendsNewGroupLabel => 'NEW GROUP';

  @override
  String get friendsNewGroupTitle => 'Who’s in?';

  @override
  String get friendsNewGroupCaption =>
      'Choose friends to invite. You can add more later.';

  @override
  String get friendsChooseFriends => 'Choose friends';

  @override
  String friendsCreateGroupWith(int count) {
    return 'Create a group with $count';
  }

  @override
  String get friendsSourceMatch => 'From your matches';

  @override
  String get friendsSourceProfile => 'Saw your profile';

  @override
  String get friendsSourceRoom => 'Met in a room';

  @override
  String get friendsSourceGroup => 'From a group';

  @override
  String get friendsSourceSearch => 'Found you by name';

  @override
  String get friendsWantsToBeFriends => 'Wants to be friends';

  @override
  String get friendsRequestSent => 'Request sent';

  @override
  String get friendsCancel => 'Cancel';

  @override
  String get friendsDecline => 'Decline';

  @override
  String get friendsAccept => 'Accept';

  @override
  String friendsMessageTooltip(String name) {
    return 'Message $name';
  }

  @override
  String friendsMessageTooltipUnread(String name, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Message $name, $count unread',
    );
    return '$_temp0';
  }

  @override
  String friendsMoreFor(String name) {
    return 'More for $name';
  }

  @override
  String get friendsMenuVouch => 'Vouch for them';

  @override
  String get friendsMenuIntro => 'Introduce to a friend';

  @override
  String friendsChatSemantics(String name, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Chat with $name, $count unread',
      zero: 'Chat with $name',
    );
    return '$_temp0';
  }

  @override
  String friendsChatSemanticsMuted(String name, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Chat with $name, $count unread, notifications muted',
      zero: 'Chat with $name, notifications muted',
    );
    return '$_temp0';
  }

  @override
  String friendsIntroHeadline(String introducer, String person) {
    return '$introducer thinks you should meet $person';
  }

  @override
  String friendsIntroHeadlineSomeone(String introducer) {
    return '$introducer thinks you should meet someone';
  }

  @override
  String friendsNameAge(String name, int age) {
    return '$name, $age';
  }

  @override
  String get friendsIntroNoThanks => 'No thanks';

  @override
  String get friendsIntroImIn => 'I\'m in';

  @override
  String get friendsVouchKeepPrivate => 'Keep private';

  @override
  String get friendsVouchShowOnProfile => 'Show on my profile';

  @override
  String get memberProfileNoData => 'No profile data found.';

  @override
  String get memberProfileSignInToView => 'Please log in to view your profile.';

  @override
  String get memberProfileLoadFailed =>
      'Failed to load profile. Please try again.';

  @override
  String get memberProfileConnectionsTitle => 'Your connections';

  @override
  String get memberProfileConnectionsCaption =>
      'People you liked, matched and talk to.';

  @override
  String get memberProfileStatLiked => 'You liked';

  @override
  String get memberProfileStatMatches => 'Matches';

  @override
  String get memberProfileStatMessages => 'Messages';

  @override
  String memberProfileOpenStat(String label) {
    return 'Open $label';
  }

  @override
  String get memberProfileNoticedTitle => 'Who has noticed';

  @override
  String get memberProfileNoticedCaption =>
      'Likes and views from members near you.';

  @override
  String get memberProfileWhoLikedMe => 'Who Liked Me';

  @override
  String memberProfileWhoLikedMeCount(int count) {
    return 'Who Liked Me ($count)';
  }

  @override
  String get memberProfileWhoLikedMeSubtitle =>
      'Members who liked your profile.';

  @override
  String get memberProfileWhoViewedTitle => 'Who Viewed My Profile';

  @override
  String get memberProfileWhoViewedSubtitle => 'Recent visits to your profile.';

  @override
  String get memberProfileWhoViewedTooltip => 'Who viewed my profile';

  @override
  String get memberProfileRefreshTooltip => 'Refresh profile';

  @override
  String get memberProfilePreferencesTitle => 'Your preferences';

  @override
  String get memberProfilePrefSeeking => 'Seeking';

  @override
  String get memberProfilePrefDistance => 'Distance';

  @override
  String memberProfileWithinKm(int km) {
    return 'Within $km km';
  }

  @override
  String get profileViewersTitle => 'Viewed My Profile';

  @override
  String get profileViewersLoadFailed => 'Failed to load profile viewers.';

  @override
  String get profileViewersEmpty => 'No one has viewed your profile yet.';

  @override
  String get profileViewersViewedRecently => 'Viewed recently';

  @override
  String profileViewersViewedAt(String time) {
    return 'Viewed at $time';
  }

  @override
  String get profileMasterReligionParsi => 'Parsi';

  @override
  String get profileMasterReligionBahai => 'Bahai';

  @override
  String get profileMasterReligionTribal => 'Tribal / Indigenous';

  @override
  String get profileMasterWorkout1to2 => '1-2 times a week';

  @override
  String get profileMasterWorkout3to4 => '3-4 times a week';

  @override
  String get profileMasterWorkout5Plus => '5+ times a week';

  @override
  String get profileMasterWorkoutDaily => 'Daily';

  @override
  String get profileMasterDietNoPreference => 'No preference';

  @override
  String get profileMasterDietVegetarian => 'Vegetarian';

  @override
  String get profileMasterDietEggetarian => 'Eggetarian';

  @override
  String get profileMasterDietNonVegetarian => 'Non-vegetarian';

  @override
  String get profileMasterDietVegan => 'Vegan';

  @override
  String get profileMasterDietJain => 'Jain';

  @override
  String get profileMasterDietTypeBalanced => 'Balanced';

  @override
  String get profileMasterDietTypeHighProtein => 'High Protein';

  @override
  String get profileMasterDietTypeLowCarb => 'Low Carb';

  @override
  String get profileMasterDietTypeKeto => 'Keto';

  @override
  String get profileMasterDietTypeMediterranean => 'Mediterranean';

  @override
  String get profileMasterDietTypeIntermittentFasting => 'Intermittent Fasting';

  @override
  String get profileMasterSleepEarlyBird => 'Early bird';

  @override
  String get profileMasterSleepNightOwl => 'Night owl';

  @override
  String get profileMasterSleepFlexible => 'Flexible';

  @override
  String get profileMasterSleepShiftBased => 'Shift based';

  @override
  String get profileMasterTravelHomebody => 'Homebody';

  @override
  String get profileMasterTravelOccasional => 'Occasional traveller';

  @override
  String get profileMasterTravelFrequent => 'Frequent traveller';

  @override
  String get profileMasterTravelAdventure => 'Adventure seeker';

  @override
  String get profileMasterTravelLuxury => 'Luxury traveller';

  @override
  String get profileMasterTravelBackpacker => 'Backpacker';

  @override
  String get profileMasterPoliticsSimilar => 'Similar views only';

  @override
  String get profileMasterPoliticsOpen => 'Open to differences';

  @override
  String get profileMasterPoliticsNotDiscuss => 'Prefer not to discuss';

  @override
  String get profileMasterPoliticsNoStrong => 'No strong preference';

  @override
  String get profileMasterIntentLongTerm => 'Long term';

  @override
  String get profileMasterIntentMarriage => 'Marriage';

  @override
  String get profileMasterIntentNewFriends => 'New friends';

  @override
  String get chatBackToConversations => 'Back to conversations';

  @override
  String get chatOfflineBanner =>
      'You’re offline. Your draft will stay here while you reconnect.';

  @override
  String get chatVoiceHello => 'Share a voice hello · read & listen';

  @override
  String get chatLoadFailedTitle => 'Let’s reconnect.';

  @override
  String get chatLoadFailedBody =>
      'Your conversation couldn’t load. Try again.';

  @override
  String get chatConversationEnded => 'This conversation has ended.';

  @override
  String get chatUnlockStepRequired =>
      'Complete the current unlock step to continue this conversation.';

  @override
  String get chatGiftTrayTitle => 'A little something for them';

  @override
  String get chatCloseGifts => 'Close gifts';

  @override
  String get chatAllGifts => 'All gifts';

  @override
  String get chatNoGiftsInCollection =>
      'No gifts available in this collection.';

  @override
  String get chatAddCoins => 'Add coins';

  @override
  String get chatFreeGiftDaily => 'Free · 1 a day';

  @override
  String chatCoinCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count coins',
      one: '1 coin',
    );
    return '$_temp0';
  }

  @override
  String get chatSendingGift => 'Sending your gift…';

  @override
  String get chatOfflineGifts =>
      'You\'re offline. You can browse gifts and send once you reconnect.';

  @override
  String chatGiftConfirmTitle(String gift, String name) {
    return 'Send $gift to $name?';
  }

  @override
  String chatGiftNoteQuote(String note) {
    return '“$note”';
  }

  @override
  String chatGiftBalanceAfter(int balance, int remaining) {
    return '·  $balance → $remaining left';
  }

  @override
  String get chatGiftNoObligation =>
      'A gift is a gesture, never an obligation to reply or meet.';

  @override
  String chatGiftSendFor(String price) {
    return 'Send for $price';
  }

  @override
  String get chatNotNow => 'Not now';

  @override
  String get chatDeleteMessageTitle => 'Delete message?';

  @override
  String get chatDeleteMessageBody =>
      'This removes the message from both chat inboxes.';

  @override
  String get chatDeleteForEveryone => 'Delete for everyone';

  @override
  String get chatMessageDeletedSnack => 'Message deleted.';

  @override
  String get chatUndo => 'Undo';

  @override
  String get chatDeleteUndone => 'Delete undone.';

  @override
  String chatGiftReceivedFrom(String name) {
    return 'Gift received from $name';
  }

  @override
  String get chatGiftReceiverIntro => 'You decide what stays in your chat.';

  @override
  String get chatHideGift => 'Hide gift';

  @override
  String get chatHideGiftSubtitle => 'Remove it from your chat only.';

  @override
  String get chatReportAndHide => 'Report and hide';

  @override
  String get chatReportAndHideSubtitle =>
      'Send it to the safety team and remove it now.';

  @override
  String get chatGiftHidden => 'Gift hidden from your chat.';

  @override
  String get chatReportGiftTitle => 'Report this gift';

  @override
  String get chatReportGiftIntro =>
      'Choose a reason. The gift will be hidden immediately.';

  @override
  String get chatReportReasonLabel => 'Reason';

  @override
  String get chatReportReasonUnwanted => 'Unwanted gift';

  @override
  String get chatReportReasonHarassment => 'Harassment';

  @override
  String get chatReportReasonSexual => 'Sexual content';

  @override
  String get chatReportReasonScam => 'Scam or fraud';

  @override
  String get chatReportReasonOther => 'Something else';

  @override
  String get chatReportDetailsLabel => 'Add details (optional)';

  @override
  String get chatReportSubmit => 'Submit report and hide';

  @override
  String get chatGiftReported =>
      'Gift reported and hidden. Our safety team will review it.';

  @override
  String get chatQuickEmojis => 'Quick emojis';

  @override
  String chatWalletTooltip(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count coins',
      one: '1 coin',
    );
    return 'Your wallet · $_temp0';
  }

  @override
  String get chatDailyLimitReached => 'Daily message limit reached';

  @override
  String get chatDailyLimitFallback =>
      'Try again tomorrow or upgrade your plan.';

  @override
  String chatDailyLimitReset(String reset) {
    return '$reset · upgrade for more.';
  }

  @override
  String get chatSeePlans => 'See plans';

  @override
  String chatQuotaOnPlan(String quota, String plan) {
    return '$quota on $plan';
  }

  @override
  String get chatYourConversation => 'Your conversation';

  @override
  String get chatVerifiedHumans => 'Verified humans';

  @override
  String get chatVerifiedHumansShowsUp => 'Verified humans · Shows up';

  @override
  String discoverLikedBack(String name) {
    return 'You liked $name back';
  }

  @override
  String discoverPassedOn(String name) {
    return 'Passed on $name';
  }

  @override
  String get discoverLikedMeLoadFailedTitle => 'Could not load your likes';

  @override
  String get discoverLikedMeEmptyTitle => 'No new likes yet';

  @override
  String get discoverLikedMeEmptyBody =>
      'When someone likes you, they show up here. Like them back and it\'s a match.';

  @override
  String get discoverLikedMeIntro =>
      'They already like you. Like back to match, or pass. Passing is private.';

  @override
  String get discoverLikedMeTitle => 'Liked you';

  @override
  String discoverLikedMeTitleCount(int count) {
    return 'Liked you · $count';
  }

  @override
  String get discoverPass => 'Pass';

  @override
  String get discoverLikeBack => 'Like back';

  @override
  String get discoverLikedJustNow => 'Liked you just now';

  @override
  String discoverLikedMinutesAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Liked you $count minutes ago',
      one: 'Liked you 1 minute ago',
    );
    return '$_temp0';
  }

  @override
  String discoverLikedHoursAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Liked you $count hours ago',
      one: 'Liked you 1 hour ago',
    );
    return '$_temp0';
  }

  @override
  String discoverLikedDaysAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Liked you $count days ago',
      one: 'Liked you 1 day ago',
    );
    return '$_temp0';
  }

  @override
  String discoverLikedWeeksAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Liked you $count weeks ago',
      one: 'Liked you 1 week ago',
    );
    return '$_temp0';
  }

  @override
  String discoverLikedOnDate(String date) {
    return 'Liked you on $date';
  }

  @override
  String discoverLikedProfilesTitle(int count) {
    return 'Liked Profiles ($count)';
  }

  @override
  String get discoverNoLikedProfiles => 'No liked profiles yet';

  @override
  String get discoverLikedProfileFallback => 'Liked profile';

  @override
  String get discoverPassedProfilesTitle => 'Passed Profiles';

  @override
  String get discoverNoPassedProfiles => 'No passed profiles yet';

  @override
  String get discoverSavedForLater => 'Saved for later';

  @override
  String get discoverSpotlightFiltersTitle => 'Spotlight Filters';

  @override
  String get discoverVerifiedOnly => 'Verified only';

  @override
  String discoverAgeRange(int min, int max) {
    return 'Age range: $min - $max';
  }

  @override
  String get discoverSpotlightTitle => 'Spotlight Matches';

  @override
  String get discoverSpotlightSubtitle => 'Curated premium connections';

  @override
  String discoverPassedCount(int count) {
    return 'Passed ($count)';
  }

  @override
  String get discoverOpenChatsFromDiscover => 'Open chats from Discover';

  @override
  String get discoverNoNewNotifications => 'No new notifications';

  @override
  String get discoverNoSpotlightMatchFilters =>
      'No spotlight profiles match filters';

  @override
  String get discoverAllSpotlightReviewed => 'All spotlight profiles reviewed!';

  @override
  String get discoverSpotlightCheckBackLater =>
      'Check back later for new spotlight profiles';

  @override
  String get discoverReportSubmitted => 'Report submitted.';

  @override
  String get discoverAppeal => 'Appeal';

  @override
  String discoverAppealPrefill(String userId) {
    return 'Review moderation outcome for report on user $userId';
  }

  @override
  String get discoverProfileUnavailable =>
      'This profile is unavailable right now.';

  @override
  String get discoverGoBack => 'Go back';

  @override
  String get discoverPremiumView => 'Premium view';

  @override
  String get todayLabel => 'TODAY';

  @override
  String get todayRefreshTooltip => 'Refresh Today';

  @override
  String get todayDiscoveryPreferences => 'Discovery preferences';

  @override
  String get todayHeroTitle => 'A little hello.\nRoom for something real.';

  @override
  String get todayHeroSubtitle =>
      'A few thoughtful introductions, at your pace.';

  @override
  String get todaySectionPace => 'YOUR PACE';

  @override
  String get todayPaceTitle => 'What fits your week?';

  @override
  String get todayPaceBody =>
      'Your pace, your kind of first date, optional availability.';

  @override
  String get todaySetRhythm => 'Set your rhythm';

  @override
  String get todaySectionStory => 'YOUR STORY';

  @override
  String get todaySectionIntroductions => 'TODAY’S INTRODUCTIONS';

  @override
  String get todayIntroductionsTitle => 'A few people to get to know';

  @override
  String get todayIntroductionsCaption =>
      'Shared interests are a starting point. Chemistry is yours to discover.';

  @override
  String get todayPausedTitle => 'Take the time you need.';

  @override
  String get todayPausedBody =>
      'Introductions are paused. Your conversations are still here.';

  @override
  String get todayManageRhythm => 'Manage your rhythm';

  @override
  String get todayLoadingIntroductions => 'Loading introductions';

  @override
  String get todayFailedTitle => 'Your introductions are taking a moment.';

  @override
  String get todayFailedBody =>
      'We couldn’t load the latest information. Please try again.';

  @override
  String get todayTryAgain => 'Try again';

  @override
  String get todayEmptyTitle => 'A little breathing room.';

  @override
  String get todayEmptyBody =>
      'There are no new introductions for your preferences right now. You can adjust your rhythm or explore profiles.';

  @override
  String get todayExploreProfiles => 'Explore profiles';

  @override
  String get todayAllIntroductions => 'All introductions';

  @override
  String get todayBreatheTitle => 'A good connection has room to breathe.';

  @override
  String get todayBreatheBody =>
      'These are today’s introductions. There is no countdown, and no need to decide on everyone.';

  @override
  String get todayExploreMore => 'Explore more profiles';

  @override
  String get todayCommonGround => 'A LITTLE COMMON GROUND';

  @override
  String todayMeetName(String name) {
    return 'Meet $name';
  }

  @override
  String get todayFirstHelloCoffee =>
      'A first hello could be a coffee together.';

  @override
  String get todayFirstHelloWalk => 'A first hello could be a daytime walk.';

  @override
  String get todayFirstHelloMeal => 'A first hello could be a relaxed meal.';

  @override
  String get todayFirstHelloVideoCall =>
      'A first hello could be a video hello.';

  @override
  String get todayFirstHelloEvent =>
      'A first hello could be an event you both enjoy.';

  @override
  String get todayFirstHelloDrinks =>
      'A first hello could be a drink together.';

  @override
  String get todayFirstHelloOther =>
      'A first hello could be something you both enjoy.';

  @override
  String get todaySectionTalk => 'SOMETHING TO TALK ABOUT';

  @override
  String get todayTalkCaption =>
      'Stories, clubs and prompts that make a first hello easier.';

  @override
  String get todayBlogTitle => 'Blog · Open Chapters';

  @override
  String get todayBlogSubtitle => 'Read members’ stories and write your own.';

  @override
  String get todayBookClubsTitle => 'Book clubs';

  @override
  String get todayBookClubsSubtitle => 'One book a week, talked over together.';

  @override
  String get todayFilmClubsTitle => 'Film clubs';

  @override
  String get todayFilmClubsSubtitle => 'Watch the pick, then swap takes.';

  @override
  String get todayPhotoThemesTitle => 'Photo Themes';

  @override
  String get todayPhotoThemesSubtitle =>
      'One photo per prompt. See everyone’s.';

  @override
  String get todayChapterStudioTitle => 'First Chapter Studio';

  @override
  String get todayChapterStudioSubtitle => 'Begin a story together.';

  @override
  String get todayCoverFallbackLine => 'A photo members loved';

  @override
  String todayCoverSemantics(String name) {
    return 'Open the Cover of the Week by $name';
  }

  @override
  String get todayCoverTitle => 'COVER OF THE WEEK';

  @override
  String todayCoverBy(String name) {
    return 'BY $name';
  }

  @override
  String get todayLikes => 'Likes';

  @override
  String get todayComments => 'Comments';

  @override
  String get todayThisWeek => 'This week';

  @override
  String get todayWallLabel => 'FROM THE COMMUNITY';

  @override
  String get todayWallTitle => 'Today’s wall';

  @override
  String get todayWallCaption =>
      'Stories and photos members loved — new picks every day';

  @override
  String get todayWallPrevious => 'Previous pick';

  @override
  String get todayWallNext => 'Next pick';

  @override
  String get todayWallChapter => 'CHAPTER';

  @override
  String get todayWallUntitled => 'An untitled chapter';

  @override
  String todayWallBy(String name) {
    return 'by $name';
  }

  @override
  String get todayWallEmpty =>
      'Your wall fills up as members share stories and photos they love';

  @override
  String get todayWallWrite => 'Write a chapter';

  @override
  String get todayWallShare => 'Share a photo';

  @override
  String get profileSetupBackTooltip => 'Back';

  @override
  String profileSetupStepCounter(int current, int total) {
    return 'Step $current of $total';
  }

  @override
  String get profileSetupLoadErrorTitle => 'Could not load profile data.';

  @override
  String get profileSetupRetry => 'Retry';

  @override
  String get profileSetupEducationHighSchool => 'High School';

  @override
  String get profileSetupEducationBachelors => 'Bachelor\'s';

  @override
  String get profileSetupEducationMasters => 'Master\'s';

  @override
  String get profileSetupEducationPhd => 'PhD';

  @override
  String get profileSetupEducationOther => 'Other';

  @override
  String get profileSetupPreferNotToSay => 'Prefer not to say';

  @override
  String profileSetupIncomeBelow(String amount) {
    return 'Below $amount';
  }

  @override
  String get profileSetupFrequencyNever => 'Never';

  @override
  String get profileSetupFrequencySocially => 'Socially';

  @override
  String get profileSetupFrequencyOccasionally => 'Occasionally';

  @override
  String get profileSetupFrequencyRegularly => 'Regularly';

  @override
  String get profileSetupGenderMan => 'Man';

  @override
  String get profileSetupGenderWoman => 'Woman';

  @override
  String get profileSetupGenderOther => 'Other';

  @override
  String profileSetupBioTooShort(int min) {
    String _temp0 = intl.Intl.pluralLogic(
      min,
      locale: localeName,
      other: 'Bio must be at least $min characters.',
      one: 'Bio must be at least 1 character.',
    );
    return '$_temp0';
  }

  @override
  String get profileSetupSaveFailed => 'Failed to save — please try again.';

  @override
  String get profileSetupCouldNotSaveChanges =>
      'Could not save your changes. Please try again.';

  @override
  String get profileSetupAboutTitle => 'Make your profile shine';

  @override
  String get profileSetupAboutSubtitle =>
      'These details help find better matches.';

  @override
  String get profileSetupBioLabel => 'Bio';

  @override
  String profileSetupBioHint(int min) {
    String _temp0 = intl.Intl.pluralLogic(
      min,
      locale: localeName,
      other: 'Tell people about you (min $min chars)',
      one: 'Tell people about you (min 1 char)',
    );
    return '$_temp0';
  }

  @override
  String get profileSetupHeightLabel => 'Height (cm)';

  @override
  String get profileSetupHeightHint => 'Select height';

  @override
  String profileSetupHeightValue(int cm) {
    return '$cm cm';
  }

  @override
  String get profileSetupEducationLabel => 'Education';

  @override
  String get profileSetupEducationHint => 'Select education';

  @override
  String get profileSetupProfessionLabel => 'Profession';

  @override
  String get profileSetupProfessionHint => 'e.g. Software Engineer';

  @override
  String get profileSetupIncomeLabel => 'Income (optional)';

  @override
  String get profileSetupLifestyleTitle => 'Lifestyle';

  @override
  String get profileSetupDrinkingLabel => 'Drinking';

  @override
  String get profileSetupSmokingLabel => 'Smoking';

  @override
  String get profileSetupSelectHint => 'Select';

  @override
  String get profileSetupReligionOptionalLabel => 'Religion (optional)';

  @override
  String get profileSetupContinue => 'Continue';

  @override
  String get profileSetupSaveAbout => 'Save About';

  @override
  String get profileSetupPhotosSaved => 'Photos saved.';

  @override
  String profileSetupPhotosMaxReached(int max) {
    String _temp0 = intl.Intl.pluralLogic(
      max,
      locale: localeName,
      other: 'You can upload up to $max photos only.',
      one: 'You can upload up to 1 photo only.',
    );
    return '$_temp0';
  }

  @override
  String get profileSetupRemovePhotoTitle => 'Remove this photo?';

  @override
  String get profileSetupRemovePhotoBody =>
      'It will be removed from your profile and deleted from storage.';

  @override
  String get profileSetupCancel => 'Cancel';

  @override
  String get profileSetupRemove => 'Remove';

  @override
  String profileSetupPhotosMinRequired(int min) {
    String _temp0 = intl.Intl.pluralLogic(
      min,
      locale: localeName,
      other: 'Please upload at least $min photos to continue.',
      one: 'Please upload at least 1 photo to continue.',
    );
    return '$_temp0';
  }

  @override
  String get profileSetupPhotosTitle => 'Add your photos';

  @override
  String profileSetupPhotosSubtitle(int min) {
    String _temp0 = intl.Intl.pluralLogic(
      min,
      locale: localeName,
      other: 'Add at least $min photos to get matches',
      one: 'Add at least 1 photo to get matches',
    );
    return '$_temp0';
  }

  @override
  String get profileSetupChooseSource => 'Choose source';

  @override
  String get profileSetupGallery => 'Gallery';

  @override
  String get profileSetupCamera => 'Camera';

  @override
  String get profileSetupPhotoRequirements =>
      'JPEG, PNG, WebP or HEIC · 300×300 minimum · 10 MB each · 50 MB total';

  @override
  String profileSetupPhotosTipEmpty(int min) {
    String _temp0 = intl.Intl.pluralLogic(
      min,
      locale: localeName,
      other: 'Add at least $min photos to show different sides of you.',
      one: 'Add at least 1 photo to show different sides of you.',
    );
    return '$_temp0';
  }

  @override
  String profileSetupPhotosTipMore(int count) {
    return 'Add $count more photo(s) to unlock full matching.';
  }

  @override
  String get profileSetupPhotosTipDone =>
      'Great! You can reorder photos by dragging.';

  @override
  String get profileSetupYourPhotosHeading => 'Your photos  •  drag to reorder';

  @override
  String get profileSetupContinueToAbout => 'Continue to About';

  @override
  String get profileSetupSavePhotos => 'Save Photos';

  @override
  String get profileSetupPrimaryPhoto => 'Primary photo';

  @override
  String profileSetupPhotoNumber(int number) {
    return 'Photo $number';
  }

  @override
  String get profileSetupShownFirst => 'Shown first on your profile';

  @override
  String get profileSetupDragHandleHint => 'Drag handle to reorder';

  @override
  String get profileSetupAwaitingSafetyReview => 'Awaiting safety review';

  @override
  String get profileSetupSafetyCheckInProgress => 'Safety check in progress';

  @override
  String get profileSetupSetAsProfilePicture => 'Set as profile picture';

  @override
  String get profileSetupProfilePictureSelected => 'Profile picture selected';

  @override
  String get profileSetupRemovePhotoTooltip => 'Remove photo';

  @override
  String get profileSetupPhotoTooLarge =>
      'This photo is larger than the 10 MB limit.';

  @override
  String get profileSetupPhotoUnsupportedType =>
      'Use a JPEG, PNG, WebP, or HEIC photo.';

  @override
  String get profileSetupPhotoBadDimensions =>
      'Photo dimensions must be between 300×300 and 4096×4096.';

  @override
  String get profileSetupPhotoQuotaReached =>
      'Your profile photo quota has been reached.';

  @override
  String get profileSetupPhotoStorageFull =>
      'Photo storage is temporarily full. Please try again later.';

  @override
  String get profileSetupPhotoUpdateFailed =>
      'Photo update failed. Please try again.';

  @override
  String profileSetupPhotoMaxAllowed(int max) {
    String _temp0 = intl.Intl.pluralLogic(
      max,
      locale: localeName,
      other: 'Maximum $max photos are allowed.',
      one: 'Maximum 1 photo is allowed.',
    );
    return '$_temp0';
  }

  @override
  String get profileSetupPreferencesLoadFailed => 'Failed to load preferences';

  @override
  String get profileSetupOfflineBanner =>
      'Offline mode — some data may be outdated.';

  @override
  String get profileSetupYourPreferences => 'Your Preferences';

  @override
  String get profileSetupEditPreferencesTitle => 'Edit Preferences';

  @override
  String get profileSetupFinishAndFindMatches => 'Finish & Find Matches';

  @override
  String get profileSetupSavePreferences => 'Save Preferences';

  @override
  String get profileSetupSelectGenderPreference =>
      'Select at least one gender preference.';

  @override
  String get profileSetupFinishFailed =>
      'Could not finish setup. Please check your photos and preferences, then try again.';

  @override
  String get profileSetupPreferencesSaveFailed =>
      'Some preferences could not be saved right now.';

  @override
  String get profileSetupPreferencesSaved => 'Preferences saved.';

  @override
  String get profileSetupTabBasic => 'Basic';

  @override
  String get profileSetupTabAdvanced => 'Advanced';

  @override
  String get profileSetupLookingFor => 'I\'m looking for';

  @override
  String get profileSetupSeekingMen => 'Men';

  @override
  String get profileSetupSeekingWomen => 'Women';

  @override
  String get profileSetupSeekingOther => 'Other';

  @override
  String profileSetupAgeRangeTitle(int min, int max) {
    return 'Age range: $min – $max';
  }

  @override
  String profileSetupMaxDistanceTitle(int km) {
    return 'Max distance: $km km';
  }

  @override
  String profileSetupDistanceValue(int km) {
    return '$km km';
  }

  @override
  String get profileSetupRelationshipIntent => 'Relationship intent';

  @override
  String get profileSetupSeriousOnly => 'Serious relationship only';

  @override
  String get profileSetupSeriousOnlySubtitle =>
      'Show only users seeking commitment';

  @override
  String get profileSetupVerifiedOnly => 'Verified profiles only';

  @override
  String get profileSetupVerifiedOnlySubtitle =>
      'Filter to ID-verified accounts';

  @override
  String get profileSetupHookupsOnly => 'Hookups only';

  @override
  String get profileSetupHookupsOnlySubtitle => 'Show casual-only profiles';

  @override
  String get profileSetupLocation => 'Location';

  @override
  String get profileSetupCountry => 'Country';

  @override
  String get profileSetupStateRegion => 'State / Region';

  @override
  String get profileSetupCity => 'City';

  @override
  String get profileSetupBackgroundCulture => 'Background & culture';

  @override
  String get profileSetupReligionPreference => 'Religion preference';

  @override
  String get profileSetupMotherTongue => 'Mother tongue';

  @override
  String get profileSetupLanguage => 'Language';

  @override
  String get profileSetupDietPreference => 'Diet preference';

  @override
  String get profileSetupWorkoutFrequency => 'Workout frequency';

  @override
  String get profileSetupDietType => 'Diet type';

  @override
  String get profileSetupSleepSchedule => 'Sleep schedule';

  @override
  String get profileSetupTravelStyle => 'Travel style';

  @override
  String get profileSetupPoliticalComfortRange => 'Political comfort range';

  @override
  String get profileSetupInterestsPersonality => 'Interests & personality';

  @override
  String get profileSetupInstagramHandle => 'Instagram handle (without @)';

  @override
  String get profileSetupIntentTags =>
      'Intent tags (long-term, marriage, casual…)';

  @override
  String get profileSetupHobbiesField => 'Hobbies (comma-separated)';

  @override
  String get profileSetupFavouriteBooksField =>
      'Favourite books (comma-separated)';

  @override
  String get profileSetupFavouriteNovelsField =>
      'Favourite novels (comma-separated)';

  @override
  String get profileSetupFavouriteSongsField =>
      'Favourite songs (comma-separated)';

  @override
  String get profileSetupExtraCurricularField =>
      'Extra-curricular activities (comma-separated)';

  @override
  String get profileSetupAdditionalInformation => 'Additional information';

  @override
  String get profileSetupPetPreference => 'Pet preference';

  @override
  String get profileSetupDealBreakers => 'Deal-breakers';

  @override
  String get profileSetupTagsField => 'Tags (comma-separated)';

  @override
  String get profileSetupNameRequired => 'Name is required.';

  @override
  String get profileSetupDobRequired => 'Date of birth is required.';

  @override
  String profileSetupPhotosRequired(int min) {
    String _temp0 = intl.Intl.pluralLogic(
      min,
      locale: localeName,
      other: 'At least $min photos are required.',
      one: 'At least 1 photo is required.',
    );
    return '$_temp0';
  }

  @override
  String get profileSetupServerError => 'Server error';

  @override
  String get profileSetupNetworkError => 'Network error — please try again.';

  @override
  String get profileSetupGenericError =>
      'Something went wrong. Please try again.';

  @override
  String get profileSetupPreviewTitle => 'Preview your profile';

  @override
  String get profileSetupPreviewSubtitle => 'This is how others will see you.';

  @override
  String profileSetupNameAge(String name, int age) {
    return '$name, $age';
  }

  @override
  String profileSetupDrinksChip(String value) {
    return 'Drinks: $value';
  }

  @override
  String profileSetupSmokesChip(String value) {
    return 'Smokes: $value';
  }

  @override
  String get profileSetupCompleteProfile => 'Complete Profile';

  @override
  String profileSetupCompletionPercent(int percent) {
    return 'Profile completion: $percent%';
  }

  @override
  String get profileEditTitle => 'Edit Profile';

  @override
  String get profileEditRefreshTooltip => 'Refresh profile';

  @override
  String get profileEditAboutYou => 'About you';

  @override
  String get profileEditEditAbout => 'Edit about';

  @override
  String get profileEditName => 'Name';

  @override
  String get profileEditPhone => 'Phone';

  @override
  String get profileEditDateOfBirth => 'Date of birth';

  @override
  String get profileEditGender => 'Gender';

  @override
  String get profileEditHeight => 'Height';

  @override
  String get profileEditIncomeRange => 'Income range';

  @override
  String get profileEditLocationSocial => 'Location & social';

  @override
  String get profileEditEditPreferences => 'Edit preferences';

  @override
  String get profileEditState => 'State';

  @override
  String get profileEditInstagram => 'Instagram';

  @override
  String get profileEditDatingPreferences => 'Dating preferences';

  @override
  String get profileEditSeeking => 'Seeking';

  @override
  String get profileEditAgeRange => 'Age range';

  @override
  String profileEditAgeRangeValue(int min, int max) {
    return '$min–$max';
  }

  @override
  String get profileEditMaxDistance => 'Max distance';

  @override
  String get profileEditEducationFilter => 'Education filter';

  @override
  String get profileEditSeriousOnly => 'Serious only';

  @override
  String get profileEditVerifiedOnly => 'Verified only';

  @override
  String get profileEditHookupOnly => 'Hookup only';

  @override
  String get profileEditYes => 'Yes';

  @override
  String get profileEditNo => 'No';

  @override
  String get profileEditIntent => 'Intent';

  @override
  String get profileEditLanguages => 'Languages';

  @override
  String get profileEditDealBreakers => 'Deal breakers';

  @override
  String get profileEditReligion => 'Religion';

  @override
  String get profileEditPets => 'Pets';

  @override
  String get profileEditWorkout => 'Workout';

  @override
  String get profileEditPoliticsComfort => 'Politics comfort';

  @override
  String get profileEditInterestsDetails => 'Interests & details';

  @override
  String get profileEditHobbies => 'Hobbies';

  @override
  String get profileEditBooks => 'Books';

  @override
  String get profileEditNovels => 'Novels';

  @override
  String get profileEditSongs => 'Songs';

  @override
  String get profileEditExtraCurriculars => 'Extra curriculars';

  @override
  String get profileEditAdditionalInfo => 'Additional info';

  @override
  String get profileEditNotSet => 'Not set';

  @override
  String get profileEditLoadingTitle => 'Loading your saved profile';

  @override
  String get profileEditLoadingBody =>
      'Binding the information saved during account setup.';

  @override
  String get profileEditYourProfile => 'Your profile';

  @override
  String profileEditPercentComplete(int percent) {
    return '$percent% complete';
  }

  @override
  String get profileEditPhotoGallery => 'Photo gallery';

  @override
  String get profileEditManagePhotos => 'Manage photos';

  @override
  String get profileEditNoPhotos => 'No photos uploaded yet.';

  @override
  String get profileEditPrimaryBadge => 'Primary';

  @override
  String get engagementHubPromptLoading => 'Loading today\'s prompt';

  @override
  String get engagementHubPromptIntro =>
      'Answer one prompt daily and build your streak.';

  @override
  String engagementHubPromptRepliedToday(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count people replied today',
    );
    return '$_temp0';
  }

  @override
  String engagementHubPromptStreakSummary(int days, int similar) {
    return 'Streak ${days}d · $similar similar replies';
  }

  @override
  String get engagementHubBlogTitle => 'Blog · Open Chapters';

  @override
  String get engagementHubBlogSubtitle =>
      'Read stories, share photos and write your own.';

  @override
  String get engagementHubPhotoThemesTitle => 'Photo Themes';

  @override
  String get engagementHubPhotoThemesSubtitle =>
      'Share one photo per prompt and see everyone’s.';

  @override
  String get engagementHubClubsTitle => 'Book & Film Clubs';

  @override
  String get engagementHubClubsSubtitle =>
      'Follow a weekly pick, talk it over, rate it.';

  @override
  String get engagementHubCityPilotTitle => 'The City Pilot';

  @override
  String get engagementHubCityPilotSubtitle =>
      'A small community. Conversations that become plans.';

  @override
  String get engagementDailyPromptTitle => 'Daily Prompt Streak';

  @override
  String get engagementHubVoiceTitle => 'Guided Voice Icebreakers';

  @override
  String get engagementHubVoiceSubtitle =>
      'Send one guided 20-45s voice intro per match/day';

  @override
  String get engagementCirclesTitle => 'Local Circle Challenges';

  @override
  String get engagementHubCirclesSubtitle =>
      'Join a city circle and submit this week\'s entry';

  @override
  String get engagementHubCoffeeTitle => 'Group Coffee Poll';

  @override
  String get engagementHubCoffeeSubtitle =>
      'Create, vote, and finalise lightweight meetup polls';

  @override
  String get engagementHubGroupsTitle => 'Groups';

  @override
  String get engagementHubGroupsSubtitle =>
      'Lifestyle communities and private friend groups';

  @override
  String get engagementHubRoomsSubtitle =>
      'Live chat rooms: drop in, talk, make friends';

  @override
  String get engagementHubFriendsTitle => 'Friends & Introductions';

  @override
  String get engagementHubFriendsSubtitle =>
      'Invite a trusted friend, even if they aren’t dating';

  @override
  String get engagementLevelTitle => 'Level & XP';

  @override
  String get engagementHubLevelSubtitle =>
      'Track meaningful activity, level rewards, and trust gates';

  @override
  String get engagementHubPaywallFree => 'Core progression stays paywall-free.';

  @override
  String get engagementHubPolicyUpdating =>
      'Monetisation policy is being updated.';

  @override
  String engagementHubPremiumAreas(String features) {
    return 'Optional premium areas: $features';
  }

  @override
  String get engagementHubEyebrow => 'ENGAGE';

  @override
  String get engagementHubTitle => 'Make something together.';

  @override
  String get engagementHubSubtitle =>
      'Build stronger matches with trust and shared activities.';

  @override
  String get engagementHubSectionCreate => 'CREATE & SHARE';

  @override
  String get engagementHubSectionCreateCaption =>
      'Stories, photos and clubs that start real conversations.';

  @override
  String get engagementHubSectionMeet => 'MEET PEOPLE';

  @override
  String get engagementHubSectionMeetCaption =>
      'Small groups, prompts and plans at your pace.';

  @override
  String get engagementHubSectionProgress => 'TRUST & PROGRESS';

  @override
  String get engagementHubSectionProgressCaption =>
      'Your level, your badges and who can find you.';

  @override
  String get engagementVoiceAppBarTitle => 'A voice, a little closer';

  @override
  String get engagementVoiceHeadline => 'Let your hello\nsound like you.';

  @override
  String get engagementVoiceIntro =>
      'An optional 20–45 second introduction, shared only in this conversation. Text is always welcome, too.';

  @override
  String engagementVoiceYouAndName(String name) {
    return 'You and $name';
  }

  @override
  String get engagementVoiceYouAndYourMatch => 'You and your match';

  @override
  String get engagementVoicePrivate => 'Private to this conversation';

  @override
  String get engagementVoiceConversationsLoadFailed =>
      'Your conversations couldn’t load.';

  @override
  String get engagementVoiceNoMatches =>
      'When you have a match, you can share a voice introduction here. No rush.';

  @override
  String get engagementVoicePickConversation =>
      'Who would you like to say hello to?';

  @override
  String get engagementVoiceStartingPoint => 'A small starting point';

  @override
  String get engagementVoiceChoosePrompt => 'Choose a prompt';

  @override
  String get engagementVoiceTranscriptLabel => 'Your words, in writing';

  @override
  String get engagementVoiceTranscriptHelper =>
      'Write what you say so they can read it, too. This is not automatic transcription.';

  @override
  String engagementVoiceStop(int seconds) {
    return 'Stop · ${seconds}s';
  }

  @override
  String get engagementVoiceRecord => 'Record your hello';

  @override
  String engagementVoiceRecordAgain(int seconds) {
    return 'Record again · ${seconds}s';
  }

  @override
  String get engagementVoiceRecordingReady =>
      'Recording ready. Check your transcript before sending.';

  @override
  String get engagementVoiceRecordingShort =>
      'That was a little short. Record 20–45 seconds.';

  @override
  String get engagementVoiceDiscard => 'Discard recording';

  @override
  String get engagementVoiceSubmitted =>
      'Introduction submitted. Approved recordings appear below.';

  @override
  String get engagementVoiceSending => 'Sending…';

  @override
  String get engagementVoiceShare => 'Share your hello';

  @override
  String get engagementVoiceCheckedNote =>
      'Recordings are checked before they are shared. There is no autoplay.';

  @override
  String get engagementVoiceYourIntros => 'Your voice introductions';

  @override
  String get engagementVoiceLatestNote =>
      'The latest 20 approved recordings in this conversation. Transcripts are always available to read.';

  @override
  String get engagementVoiceIntrosLoadFailed =>
      'Introductions couldn’t load. The conversation may no longer be available.';

  @override
  String get engagementVoiceNothingYet =>
      'Nothing shared yet. A simple hello is a good beginning.';

  @override
  String get engagementVoiceYourHello => 'Your hello';

  @override
  String engagementVoiceHelloFromName(String name) {
    return 'A hello from $name';
  }

  @override
  String get engagementVoiceHelloFromYourMatch => 'A hello from your match';

  @override
  String get engagementVoiceTranscriptHeading => 'TRANSCRIPT';

  @override
  String get engagementVoiceStopPlayback => 'Stop playback';

  @override
  String engagementVoiceListen(int seconds) {
    return 'Listen · ${seconds}s';
  }

  @override
  String get engagementVoiceReloadPrompts => 'Reload prompts';

  @override
  String get engagementVoiceMicPermission =>
      'Allow microphone access to record. You can still read transcripts without it.';

  @override
  String get engagementVoiceStartFailed =>
      'Unable to start recording. Check microphone access and try again.';

  @override
  String get engagementVoiceSaveFailed =>
      'The recording could not be saved. Please try again.';

  @override
  String get engagementVoicePromptsLoadFailed =>
      'Unable to load voice prompts right now.';

  @override
  String get engagementSessionUnavailable => 'User session not available.';

  @override
  String get engagementVoiceChooseConversation =>
      'Choose a conversation first.';

  @override
  String get engagementVoiceSelectPrompt => 'Please select a voice prompt.';

  @override
  String get engagementVoiceEnterTranscript => 'Please enter a transcript.';

  @override
  String get engagementVoiceSessionFailed =>
      'Unable to create voice icebreaker session.';

  @override
  String get engagementVoiceSendFailed =>
      'Unable to send voice icebreaker right now.';

  @override
  String get engagementVoicePlaybackUserRequired =>
      'User ID is required to mark playback.';

  @override
  String get engagementVoiceMarkPlaybackFailed =>
      'Unable to mark playback right now.';

  @override
  String get engagementVoicePlayFailed =>
      'Unable to play this recording right now.';

  @override
  String get chatStarterSmile => 'What made you smile today?';

  @override
  String get chatStarterSunday => 'Your ideal Sunday: go.';

  @override
  String get chatStarterCoffee => 'Coffee, a walk, or a little adventure?';

  @override
  String get chatWelcomeTitle => 'Every good story\nstarts with a hello.';

  @override
  String get chatWelcomePending =>
      'Your conversation will open when the match is confirmed.';

  @override
  String get chatWelcomeBody => 'No perfect opening line needed. Just be you.';

  @override
  String get chatInspirationEyebrow => 'A LITTLE INSPIRATION';

  @override
  String get chatAllConversations => 'All conversations';

  @override
  String get chatMakeConnectionEyebrow => 'MAKE A CONNECTION';

  @override
  String get chatLessSmallTalk => 'A little less small talk.';

  @override
  String get chatLessSmallTalkBody =>
      'Ask about the things that make them light up. Share something that feels like you.';

  @override
  String get chatFindTheWords => 'Find the words';

  @override
  String get chatSendJoy => 'Send a little joy';

  @override
  String get chatPaceTitle => 'Your pace. Your space.';

  @override
  String get chatPaceBody =>
      'Share only what feels comfortable. A good connection respects your boundaries.';

  @override
  String get chatWriteMessageHint => 'Write a message…';

  @override
  String get chatConversationPaused => 'Conversation paused';

  @override
  String get chatSendingMessageTooltip => 'Sending message';

  @override
  String get chatSendMessageTooltip => 'Send message';

  @override
  String get chatSendGiftTooltip => 'Send a gift';

  @override
  String get chatAddEmojiTooltip => 'Add an emoji';

  @override
  String get chatDraftedWithHelp => 'Drafted with help';

  @override
  String get chatHelpMeSayIt => 'Help me say it';

  @override
  String get chatEnterToSendHint =>
      'Enter to send · Shift + Enter for a new line';

  @override
  String get chatToday => 'Today';

  @override
  String get chatYesterday => 'Yesterday';

  @override
  String get chatGiftOptions => 'Gift options';

  @override
  String get chatStatusRead => 'Read';

  @override
  String get chatStatusDelivered => 'Delivered';

  @override
  String get chatStatusSent => 'Sent';

  @override
  String get chatGestureGiftHeading => 'Gesture + Rose Gift';

  @override
  String get chatGiftForYouHeading => 'A little something for you';

  @override
  String chatGiftTone(String tone) {
    return 'Tone: $tone';
  }

  @override
  String get chatFreeGift => 'Free gift';

  @override
  String get chatCopilotKindOpener => 'Opener';

  @override
  String get chatCopilotKindReply => 'Reply';

  @override
  String get chatCopilotKindDateIdea => 'Date idea';

  @override
  String get chatCopilotToneWarm => 'Warm';

  @override
  String get chatCopilotTonePlayful => 'Playful';

  @override
  String get chatCopilotToneDirect => 'Direct';

  @override
  String chatCopilotIntro(String name) {
    return 'A draft in your voice, from $name’s profile and your conversation. It is never sent for you, and if you send it as drafted they can see it was written with help.';
  }

  @override
  String chatCopilotDisclosure(String disclosure, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count drafts left today.',
      one: '1 draft left today.',
    );
    return '$disclosure $_temp0';
  }

  @override
  String get chatCopilotDraftIt => 'Draft it';

  @override
  String get chatCopilotTryAnother => 'Try another';

  @override
  String get chatCopilotUseAndEdit => 'Use and edit';

  @override
  String get chatCopilotEmpty => 'The copilot returned nothing.';

  @override
  String get chatCopilotUnavailable => 'The copilot is unavailable.';

  @override
  String get chatErrorMatchEnded => 'This match has ended.';

  @override
  String get chatErrorLoadMessages =>
      'Failed to load messages. Please try again.';

  @override
  String get chatErrorLockedQuest =>
      'Chat is locked until the quest is approved.';

  @override
  String get chatErrorSendFailed => 'Failed to send message.';

  @override
  String get chatErrorDeleteFailed => 'Failed to delete message.';

  @override
  String get chatErrorDeleteWindowExpired => 'Delete window expired (24h).';

  @override
  String get chatErrorOnlyReceivedGifts =>
      'Only received gifts can be managed.';

  @override
  String get chatErrorGiftGone => 'This gift is no longer available.';

  @override
  String get chatErrorGiftReportFailed =>
      'Could not report this gift. Please try again.';

  @override
  String get chatErrorGiftHideFailed =>
      'Could not hide this gift. Please try again.';

  @override
  String get chatErrorGiftsUnavailable =>
      'Rose gifts are currently unavailable.';

  @override
  String chatErrorNotEnoughCoins(String gift) {
    return 'Not enough coins to send $gift.';
  }

  @override
  String get chatErrorNotEnoughCoinsSelected =>
      'Not enough coins to send selected gift.';

  @override
  String get chatErrorWalletFrozen =>
      'Your coins are on hold while we review a refunded purchase. Free gifts are still available.';

  @override
  String get chatErrorGiftVelocity =>
      'You\'ve sent a lot of gifts in a short time. Please try again later.';

  @override
  String get chatErrorFreeGiftUsed =>
      'You\'ve sent today\'s free gift. A new one is available after midnight UTC.';

  @override
  String chatErrorGiftNotAvailable(String gift) {
    return '$gift is not available right now.';
  }

  @override
  String get chatErrorGiftNeedsActiveMatch =>
      'Gifts can only be sent in an active match.';

  @override
  String get chatErrorExclusiveGiftOnce =>
      'This exclusive gift can only be sent once today.';

  @override
  String get chatErrorGiftFailed => 'Failed to send gift.';

  @override
  String get chatErrorSessionUnavailable => 'User session not available.';

  @override
  String get chatErrorConversationUnavailable => 'Conversation unavailable.';

  @override
  String get verificationLandingTitle => 'Verify with confidence';

  @override
  String get verificationLandingBody =>
      'Upload a clear government identity document and a recent selfie. Files are sent as encrypted transport data and stored in a private evidence area.';

  @override
  String get verificationLandingDisclaimer =>
      'A review signal adds context to your profile. It never guarantees another person’s identity, intentions, or safety.';

  @override
  String get verificationViewVerifiedStatus => 'View verified status';

  @override
  String get verificationViewReviewStatus => 'View review status';

  @override
  String get verificationStartButton => 'Start secure verification';

  @override
  String get verificationUploadIdTitle => 'Upload ID';

  @override
  String get verificationUploadIdInstruction =>
      'Take or upload a clear photo of your government ID.';

  @override
  String get verificationGallery => 'Gallery';

  @override
  String get verificationCamera => 'Camera';

  @override
  String get verificationNext => 'Next';

  @override
  String get verificationSelfieTitle => 'Selfie';

  @override
  String get verificationSelfieInstruction => 'Take a clear selfie.';

  @override
  String get verificationUploadFailed =>
      'We could not upload your evidence. Check the files and try again.';

  @override
  String get verificationSubmit => 'Submit';

  @override
  String get verificationStatusTitle => 'Verification Status';

  @override
  String get verificationRetry => 'Retry';

  @override
  String get verificationStatusVerified => 'Verified';

  @override
  String get verificationStatusVerifiedMessage =>
      'Your verification is complete.';

  @override
  String get verificationStatusRejected => 'Rejected';

  @override
  String get verificationStatusRejectedFallback => 'Please try again.';

  @override
  String get verificationStatusPending => 'Pending';

  @override
  String get verificationStatusPendingMessage => 'Review in progress.';

  @override
  String get verificationStatusNotStarted => 'Not Started';

  @override
  String get verificationStatusNotStartedMessage =>
      'Start verification from Settings.';

  @override
  String get safetySosTitle => 'Emergency SOS';

  @override
  String get safetySosDefaultMessage =>
      'I need immediate assistance. Please check on me.';

  @override
  String get safetySosHeadline => 'Activate an emergency alert';

  @override
  String get safetySosIntro =>
      'If you are in immediate danger, contact local emergency services first. This alert is recorded for the safety team.';

  @override
  String get safetySosLevelUrgent => 'Urgent';

  @override
  String get safetySosLevelCritical => 'Critical';

  @override
  String get safetySosMessageLabel => 'Message for the safety team';

  @override
  String get safetySosActivating => 'Activating…';

  @override
  String get safetySosActivate => 'Activate SOS';

  @override
  String get safetySosLocationNote =>
      'Location is requested only for this alert. You can continue if permission is denied.';

  @override
  String get safetySosHistoryTitle => 'Alert history';

  @override
  String get safetySosHistoryEmpty => 'No SOS alerts recorded.';

  @override
  String safetySosHistoryHeading(String level, String status) {
    return '$level · $status';
  }

  @override
  String get safetySosAlertLevelLow => 'LOW';

  @override
  String get safetySosAlertLevelMedium => 'MEDIUM';

  @override
  String get safetySosAlertLevelHigh => 'HIGH';

  @override
  String get safetySosAlertLevelCritical => 'CRITICAL';

  @override
  String get safetySosAlertStatusOpen => 'open';

  @override
  String get safetySosAlertStatusActive => 'active';

  @override
  String get safetySosAlertStatusAcknowledged => 'acknowledged';

  @override
  String get safetySosAlertStatusResolved => 'resolved';

  @override
  String safetySosHistoryMetaWithLocation(String date) {
    return '$date · location included';
  }

  @override
  String safetySosHistoryMetaNoLocation(String date) {
    return '$date · no location';
  }

  @override
  String safetySosResolution(String note) {
    return 'Resolution: $note';
  }

  @override
  String get safetySosConfirmTitle => 'Activate SOS now?';

  @override
  String get safetySosConfirmBody =>
      'This creates an emergency alert for the safety team and attempts to attach your current location.';

  @override
  String get safetySosCancel => 'Cancel';

  @override
  String get safetySosConfirmActivate => 'Activate';

  @override
  String get safetySosActivatedTitle => 'SOS alert activated';

  @override
  String get safetySosActivatedWithLocation =>
      'Your alert and current location were recorded.';

  @override
  String get safetySosActivatedWithoutLocation =>
      'Your alert was recorded without location. Location permission was unavailable or declined.';

  @override
  String get safetySosDone => 'Done';

  @override
  String get safetySosSignInToView => 'Please sign in to view SOS history.';

  @override
  String get safetySosLoadFailed => 'Unable to load SOS history.';

  @override
  String get safetySosSignInToActivate =>
      'Please sign in before activating SOS.';

  @override
  String get safetySosActivateFailed => 'Unable to activate SOS.';

  @override
  String get photoThemesTitle => 'Photo Themes';

  @override
  String get photoThemesSignIn => 'Sign in to see photo themes.';

  @override
  String get photoThemesHeroTitle => 'Show a little of your world';

  @override
  String get photoThemesHeroSubtitle =>
      'Pick a prompt, share one photo, and see how everyone else answered. It is an easy way to start a conversation.';

  @override
  String get photoThemesLoadFailed => 'Themes could not load';

  @override
  String get photoThemesCheckConnection => 'Please check your connection.';

  @override
  String get photoThemesLookAround => 'You can look around';

  @override
  String get photoThemesEligibilityShareOwn =>
      'Complete your profile with two approved photos to share your own.';

  @override
  String get photoThemesNewPromptsTitle => 'New prompts are on the way';

  @override
  String get photoThemesNewPromptsBody =>
      'Check back soon for something to share.';

  @override
  String photoThemesSharedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count shared',
      one: '$count shared',
    );
    return '$_temp0';
  }

  @override
  String get photoThemesYouShared => 'You shared ✓';

  @override
  String get photoThemesBeFirst => 'Be the first to share →';

  @override
  String get photoThemesSeeEveryone => 'See everyone’s photos →';

  @override
  String get photoThemesSharedSnack => 'Your photo is shared. Nice one!';

  @override
  String get photoThemesShareFailed =>
      'Your photo could not be shared. Use a JPEG or PNG up to 10 MB.';

  @override
  String get photoThemesEligibilityShare =>
      'Complete your profile with two approved photos to share.';

  @override
  String get photoThemesAlreadyShared =>
      'You have shared for this theme. Remove yours to share a new one.';

  @override
  String get photoThemesThemeFallback => 'Photo Theme';

  @override
  String get photoThemesShareTooltip => 'Share a photo for this theme';

  @override
  String get photoThemesShareYourPhoto => 'Share your photo';

  @override
  String get photoThemesNoPhotosYet => 'No photos yet';

  @override
  String photoThemesBeFirstFor(String title) {
    return 'Be the first to share for “$title”';
  }

  @override
  String get photoThemesLoadingPrompt => 'Loading the prompt…';

  @override
  String get photoThemesPhotosLoadFailed => 'Photos could not load';

  @override
  String get photoThemesEmptyMessage =>
      'Your photo could be the one that gets everyone talking.';

  @override
  String get photoThemesMoreFailed => 'More photos could not load. Reload';

  @override
  String get photoThemesLoadMore => 'Load more';

  @override
  String get photoThemesPhotoUnavailable => 'Photo unavailable. Retry';

  @override
  String photoThemesOpenPhoto(String name) {
    return 'Open $name’s photo';
  }

  @override
  String get photoThemesYou => 'You';

  @override
  String get photoThemesWallHelp =>
      'If members love it, your photo can reach their Today walls: 50 likes and 5 comments reach 50 walls, 100 likes and 10 comments reach 100. You can turn this off any time.';

  @override
  String get photoThemesRemoveTitle => 'Remove your photo?';

  @override
  String get photoThemesRemoveMessage =>
      'It disappears from this theme for everyone. You can share a new one afterwards.';

  @override
  String get photoThemesRemoveAction => 'Remove photo';

  @override
  String get photoThemesRemoveFailed => 'Your photo could not be removed.';

  @override
  String get photoThemesReachOn =>
      'Your photo can now reach members’ walls when they love it.';

  @override
  String get photoThemesReachOff => 'Your photo is off every wall.';

  @override
  String get photoThemesSharedByYou => 'Shared by you';

  @override
  String photoThemesSharedBy(String name) {
    return 'Shared by $name';
  }

  @override
  String photoThemesPhotoDescription(String text) {
    return 'Photo description: $text';
  }

  @override
  String get photoThemesReachSwitch => 'Let it reach other members’ walls';

  @override
  String get photoThemesReachIdle => 'Members can carry this photo further';

  @override
  String get photoThemesReachLive =>
      'Members are seeing it on their Today walls now.';

  @override
  String get photoThemesRemoveMine => 'Remove my photo';

  @override
  String get photoThemesReport => 'Report';

  @override
  String photoThemesBlock(String name) {
    return 'Block $name';
  }

  @override
  String get photoThemesCommentHint => 'What does it make you think of?';

  @override
  String get photoThemesCommentApproved =>
      'Approved. Everyone who can see this photo can see it now.';

  @override
  String get photoThemesDetailsTitle => 'Tell us about it';

  @override
  String get photoThemesCaption => 'Caption';

  @override
  String get photoThemesCaptionHint => 'Pancakes, then nowhere to be.';

  @override
  String get photoThemesDescribe => 'Describe the photo';

  @override
  String get photoThemesDescribeHelper =>
      'Helps members who use a screen reader.';

  @override
  String get photoThemesShare => 'Share';

  @override
  String get photoThemesWallTitle => 'Covers on your wall';

  @override
  String get photoThemesWallCaption => 'Photos other members loved';

  @override
  String get photoThemesMasthead => 'PHOTO THEMES';

  @override
  String photoThemesByline(String name) {
    return 'BY $name';
  }

  @override
  String get photoThemesLikes => 'Likes';

  @override
  String get photoThemesComments => 'Comments';

  @override
  String get photoThemesCancel => 'Cancel';

  @override
  String get photoThemesTryAgain => 'Try again';

  @override
  String get photoThemesSaveFailed => 'That didn’t save. Please try again.';

  @override
  String get friendsChatEmpty =>
      'Say hello. Only the two of you can see this conversation.';

  @override
  String get friendsChatOpenFailed => 'Could not open the chat. Retry.';

  @override
  String get friendsCancelRequestTitle => 'Cancel your friend request?';

  @override
  String friendsCancelRequestBody(String name) {
    return '$name won’t see your request any more.';
  }

  @override
  String get friendsCancelRequestBodyUnnamed =>
      'this member won’t see your request any more.';

  @override
  String get friendsKeepIt => 'Keep it';

  @override
  String get friendsCancelRequest => 'Cancel request';

  @override
  String friendsNowFriends(String name) {
    return 'You and $name are now friends.';
  }

  @override
  String get friendsNowFriendsUnnamed => 'You and this member are now friends.';

  @override
  String friendsRequestSentTo(String name) {
    return 'Friend request sent to $name.';
  }

  @override
  String get friendsRequestSentToUnnamed =>
      'Friend request sent to this member.';

  @override
  String get friendsRequestCancelled => 'Request cancelled.';

  @override
  String get friendsRequestFailed => 'Could not send the request.';

  @override
  String get friendsAddCaption =>
      'Friends can message and plan things together';

  @override
  String get friendsRequested => 'Requested';

  @override
  String friendsWaitingFor(String name) {
    return 'Waiting for $name. Tap to cancel.';
  }

  @override
  String get friendsWaitingForUnnamed =>
      'Waiting for this member. Tap to cancel.';

  @override
  String get friendsAcceptFriend => 'Accept friend';

  @override
  String friendsAskedToBeFriends(String name) {
    return '$name asked to be friends';
  }

  @override
  String get friendsAskedToBeFriendsUnnamed =>
      'this member asked to be friends';

  @override
  String get friendsMessage => 'Message';

  @override
  String get friendsYoureFriends => 'You’re friends. Open your chat.';

  @override
  String friendsVouchTooShort(int min) {
    return 'Say a little more (at least $min characters).';
  }

  @override
  String friendsVouchTitle(String name) {
    return 'Vouch for $name';
  }

  @override
  String get friendsVouchBody =>
      'A sentence or two about why someone would be lucky to meet them. They approve it before it shows on their profile, with your first name.';

  @override
  String get friendsVouchLabel => 'Your vouch';

  @override
  String get friendsVouchHint => 'Kind, funny, and always shows up on time.';

  @override
  String get friendsVouchSend => 'Send vouch';

  @override
  String get friendsIntroChooseTwo => 'Choose two different friends.';

  @override
  String get friendsIntroSheetTitle => 'Introduce two friends';

  @override
  String get friendsIntroSheetBody =>
      'Both friends must allow introductions. Each controls their preview and decides privately. Share only a reason you have permission to mention. Their decisions and match outcome stay private.';

  @override
  String get friendsIntroNeedTwo =>
      'You need at least two accepted friends to make an intro.';

  @override
  String get friendsFirstFriend => 'First friend';

  @override
  String get friendsSecondFriend => 'Second friend';

  @override
  String get friendsIntroWhyLabel => 'Why they should meet (optional)';

  @override
  String get friendsIntroSubmit => 'Make the intro';

  @override
  String get friendsLoadFailed => 'Failed to load friends. Please try again.';

  @override
  String get friendsAddFailed => 'Failed to add friend.';

  @override
  String get friendsRemoveFailed => 'Failed to remove friend.';

  @override
  String get friendsRespondFailed => 'Failed to respond to friend request.';

  @override
  String get friendsSocialLoadFailed => 'Unable to load vouches and intros.';

  @override
  String get friendsVouchSendFailed => 'Unable to send this vouch.';

  @override
  String get friendsVouchUpdateFailed => 'Unable to update this vouch.';

  @override
  String get friendsVouchWithdrawFailed => 'Unable to withdraw this vouch.';

  @override
  String get friendsIntroMakeFailed => 'Unable to make this intro.';

  @override
  String get friendsIntroAnswerFailed => 'Unable to answer this intro.';

  @override
  String get groupsEyebrow => 'GROUPS';

  @override
  String get groupsTitle => 'Find your people.';

  @override
  String get groupsSubtitle =>
      'Lifestyle communities anyone can join, and private groups just for your friends.';

  @override
  String get groupsStartGroup => 'Start a group';

  @override
  String get groupsInvitationsHeader => 'INVITATIONS';

  @override
  String get groupsInvitationsCaption => 'Friends asked you to join.';

  @override
  String get groupsAnswerFailed => 'Your answer could not be saved.';

  @override
  String groupsWelcome(String name) {
    return 'Welcome to $name!';
  }

  @override
  String get groupsInvitationDeclined => 'Invitation declined.';

  @override
  String get groupsYourGroupsHeader => 'YOUR GROUPS';

  @override
  String get groupsYourGroupsFailed => 'Your groups could not load';

  @override
  String get groupsErrorCheckConnection => 'Please check your connection.';

  @override
  String get groupsEmptyTitle => 'No groups yet';

  @override
  String get groupsEmptyBody =>
      'Join a community below, or start a private group with your friends.';

  @override
  String get groupsDiscoverHeader => 'DISCOVER BY LIFESTYLE';

  @override
  String get groupsDiscoverCaption => 'Community groups are open to everyone.';

  @override
  String get groupsLifestylesFailed => 'Lifestyles could not load';

  @override
  String get groupsCategoryAll => 'All';

  @override
  String get groupsDiscoverFailed => 'Groups could not load';

  @override
  String get groupsDiscoverEmptyTitle => 'Nothing new to join';

  @override
  String groupsDiscoverEmptyCategoryTitle(String category) {
    return 'No $category groups yet';
  }

  @override
  String get groupsDiscoverEmptyBody =>
      'Be the first: start a community group and invite your friends.';

  @override
  String get groupsStartOne => 'Start one';

  @override
  String get groupsJoinFailed => 'You could not join just now.';

  @override
  String get groupsJoin => 'Join';

  @override
  String groupsJoinNamed(String name) {
    return 'Join $name';
  }

  @override
  String groupsInvitedBy(String name, String kind, String members) {
    return '$name invited you · $kind · $members';
  }

  @override
  String groupsInvitedByFriend(String kind, String members) {
    return 'A friend invited you · $kind · $members';
  }

  @override
  String get groupsDecline => 'Decline';

  @override
  String groupsDeclineNamed(String name) {
    return 'Decline $name';
  }

  @override
  String groupsChatEmpty(String name) {
    return 'Say hello to the group. Everyone in $name can see messages here.';
  }

  @override
  String groupsInviteFriendsTo(String name) {
    return 'Invite friends to $name';
  }

  @override
  String get groupsSendInvitations => 'Send invitations';

  @override
  String get groupsInvitationsFailed => 'Invitations could not be sent.';

  @override
  String groupsInvitationSentTo(String name) {
    return 'Invitation sent to $name.';
  }

  @override
  String groupsInvitationsSent(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count invitations sent.',
      one: '1 invitation sent.',
    );
    return '$_temp0';
  }

  @override
  String groupsLeaveTitle(String name) {
    return 'Leave $name?';
  }

  @override
  String get groupsLeaveBodyAlone =>
      'You are the only member, so the group and its chat will be deleted.';

  @override
  String get groupsLeaveBodyOwner =>
      'Ownership passes to your longest-standing moderator, or else member. You will lose access to the chat.';

  @override
  String get groupsLeaveBodyCommunity =>
      'You will lose access to the group chat. You can join again later.';

  @override
  String get groupsLeaveBodyPrivate =>
      'You will lose access to the group chat. You will need a new invitation to come back.';

  @override
  String get groupsLeave => 'Leave';

  @override
  String get groupsLeaveFailed => 'You could not leave just now.';

  @override
  String get groupsCoverUploadFailed =>
      'Your cover photo could not be uploaded. Use a JPEG or PNG up to 10 MB.';

  @override
  String get groupsRemoveCoverTitle => 'Remove the cover photo?';

  @override
  String groupsRemoveCoverBody(String name) {
    return '$name will show its emoji cover again.';
  }

  @override
  String get groupsRemove => 'Remove';

  @override
  String get groupsRemoveCoverFailed => 'The cover photo could not be removed.';

  @override
  String get groupsCoverRemoved => 'Cover photo removed.';

  @override
  String groupsDeleteTitle(String name) {
    return 'Delete $name?';
  }

  @override
  String get groupsDeleteBody =>
      'The group, its invitations and its chat are removed for everyone. This cannot be undone.';

  @override
  String get groupsDeleteGroup => 'Delete group';

  @override
  String get groupsDeleteFailed => 'The group could not be deleted.';

  @override
  String get groupsDetailEyebrow => 'GROUP';

  @override
  String get groupsDetailTitleFallback => 'Group';

  @override
  String get groupsOwnerTools => 'Owner tools';

  @override
  String get groupsEditGroup => 'Edit group';

  @override
  String get groupsAddCoverPhoto => 'Add cover photo';

  @override
  String get groupsChangeCoverPhoto => 'Change cover photo';

  @override
  String get groupsRemoveCoverPhoto => 'Remove cover photo';

  @override
  String get groupsMoreOptions => 'More options';

  @override
  String get groupsReportGroup => 'Report group';

  @override
  String get groupsUnavailableTitle => 'This group is unavailable';

  @override
  String get groupsUnavailableBody =>
      'It may have been deleted, or you may no longer have access.';

  @override
  String get groupsOpenToAll => 'Open to all';

  @override
  String get groupsPrivate => 'Private';

  @override
  String get groupsYouRunIt => 'You run it';

  @override
  String get groupsYouModerate => 'You moderate';

  @override
  String get groupsCoverNotePending =>
      'Only you can see this photo until it’s approved. Members see the emoji cover meanwhile.';

  @override
  String get groupsCoverNoteRejected =>
      'Your last cover photo wasn’t approved. Choose a different one.';

  @override
  String get groupsCoverUnderReview => 'Under review';

  @override
  String get groupsChangeCover => 'Change cover';

  @override
  String get groupsRemoveCover => 'Remove cover';

  @override
  String get groupsRemovedTitle => 'This group was removed after a review';

  @override
  String get groupsRemovedBodyOwner =>
      'Members can’t chat, join or invite while it is removed. Your review notices explain the decision and let you appeal.';

  @override
  String get groupsRemovedBodyMember =>
      'Members can’t chat, join or invite while it is removed. You can leave the group at any time.';

  @override
  String get groupsMembers => 'Members';

  @override
  String get groupsChatButton => 'Group chat';

  @override
  String groupsChatButtonUnread(int count) {
    return 'Group chat · $count new';
  }

  @override
  String get groupsInviteFriends => 'Invite friends';

  @override
  String get groupsWhosHere => 'WHO’S HERE';

  @override
  String get groupsSeeAll => 'See all';

  @override
  String get groupsYou => 'You';

  @override
  String groupsInvitedToJoin(String name) {
    return 'You’re invited to join $name.';
  }

  @override
  String get groupsJoinGroup => 'Join group';

  @override
  String get groupsJoinHint => 'Members see who’s here and chat together.';

  @override
  String get groupsCantJoinTitle => 'You can’t join this group';

  @override
  String get groupsCantJoinBody =>
      'It may be full, or a moderator removed you.';

  @override
  String get groupsInvitationOnly => 'Invitation only';

  @override
  String get groupsInvitationOnlyBody =>
      'A member can invite you to this private group.';

  @override
  String get groupsMakeModerator => 'Make moderator';

  @override
  String get groupsMakeMember => 'Make member';

  @override
  String get groupsRemoveFromGroup => 'Remove from group';

  @override
  String groupsRemoveMemberTitle(String name) {
    return 'Remove $name?';
  }

  @override
  String get groupsRemoveMemberBodyCommunity =>
      'They leave the group and its chat, and cannot rejoin by themselves.';

  @override
  String get groupsRemoveMemberBodyPrivate =>
      'They leave the group and its chat.';

  @override
  String get groupsChangeFailed => 'That change could not be saved.';

  @override
  String get groupsMembersFailed => 'Members could not load';

  @override
  String get groupsPleaseTryAgain => 'Please try again.';

  @override
  String groupsMemberYou(String name) {
    return '$name (you)';
  }

  @override
  String get groupsRoleOwner => 'Owner';

  @override
  String get groupsRoleModerator => 'Moderator';

  @override
  String get groupsRoleMember => 'Member';

  @override
  String groupsMemberOptions(String name) {
    return 'Options for $name';
  }

  @override
  String get groupsEditFailed => 'Your changes could not be saved.';

  @override
  String get groupsSaving => 'Saving…';

  @override
  String get groupsSaveChanges => 'Save changes';

  @override
  String get groupsNameLabel => 'Group name';

  @override
  String get groupsAboutLabel => 'What is it about?';

  @override
  String get groupsAboutOptionalLabel => 'What is it about? (optional)';

  @override
  String get groupsCityLabel => 'City (optional)';

  @override
  String get groupsCoverColorTheme => 'Theme';

  @override
  String get groupsCoverColorAccent => 'Accent';

  @override
  String get groupsCoverColorWarm => 'Warm';

  @override
  String get groupsLifestyleLabel => 'Lifestyle';

  @override
  String get groupsCreateCoverUploadFailed =>
      'Your group is ready, but the cover photo could not be uploaded. Try again from the group.';

  @override
  String get groupsCreatePickLifestyle =>
      'Pick a lifestyle for your community group.';

  @override
  String get groupsCreateNameTooShort =>
      'Give your group a name of at least 3 letters.';

  @override
  String get groupsCreateFailed =>
      'Your group could not be created. Please try again.';

  @override
  String get groupsCreateEyebrow => 'NEW GROUP';

  @override
  String get groupsCreateSubtitle =>
      'Bring people together around what you love.';

  @override
  String get groupsCreateSubtitleFriends => 'Turn your friends into a group.';

  @override
  String get groupsCreateKindHeader => 'WHAT KIND';

  @override
  String get groupsKindCommunity => 'Community group';

  @override
  String get groupsKindPrivate => 'Private group';

  @override
  String get groupsCreateCommunitySubtitle =>
      'By lifestyle. Anyone can find and join it.';

  @override
  String get groupsCreatePrivateSubtitle =>
      'Just friends. Only people you invite can join.';

  @override
  String get groupsCreateLifestyleHeader => 'LIFESTYLE';

  @override
  String get groupsCreateLifestyleCaption =>
      'Where people will discover your group.';

  @override
  String get groupsCreateDetailsHeader => 'DETAILS';

  @override
  String get groupsCreateNameHintCommunity => 'Sunrise runners of Indiranagar';

  @override
  String get groupsCreateNameHintPrivate => 'The Sunday brunch crew';

  @override
  String get groupsCreateCoverHeader => 'COVER';

  @override
  String groupsCoverEmojiSemantics(String emoji) {
    return 'Cover emoji $emoji';
  }

  @override
  String get groupsCreateCoverPhotoOptional => 'Cover photo (optional)';

  @override
  String get groupsCreateCoverPhotoHint =>
      'Members see the emoji until your photo is approved.';

  @override
  String get groupsCreateAddCoverPhoto => 'Add a cover photo';

  @override
  String get groupsCreateChangePhoto => 'Change photo';

  @override
  String get groupsCreateRemovePhoto => 'Remove photo';

  @override
  String get groupsCreateFriendsHeader => 'FRIENDS';

  @override
  String get groupsCreateFriendsCaptionEmpty =>
      'Invite friends now, or later from the group.';

  @override
  String get groupsCreateFriendsCaption => 'They’ll get an invitation to join.';

  @override
  String get groupsFriendFallback => 'Friend';

  @override
  String groupsRemoveInvitee(String name) {
    return 'Remove $name';
  }

  @override
  String get groupsChooseFriends => 'Choose friends';

  @override
  String get groupsChangeFriends => 'Change friends';

  @override
  String get groupsCreating => 'Creating…';

  @override
  String get groupsCreateGroup => 'Create group';

  @override
  String get groupsCardRemoved => 'Removed after a review';

  @override
  String groupsCardSemanticsMuted(String name, String details) {
    return '$name, $details, notifications muted';
  }

  @override
  String get groupsNotificationsMuted => 'Notifications muted';

  @override
  String groupsUnreadMessages(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count unread messages',
      one: '1 unread message',
    );
    return '$_temp0';
  }

  @override
  String get groupsCoverSheetTitle => 'Cover photo';

  @override
  String get groupsCoverSheetBody =>
      'Every photo is checked before other members can see it. Use a JPEG or PNG up to 10 MB.';

  @override
  String get groupsCoverFromPhotos => 'Choose from your photos';

  @override
  String get groupsCoverTakePhoto => 'Take a photo';

  @override
  String get groupsCoverTooLarge =>
      'That photo is larger than 10 MB. Choose a smaller one.';

  @override
  String get groupsCoverPreviewTitle => 'Preview your cover';

  @override
  String get groupsCoverPreviewBody =>
      'Covers show as a wide banner, keeping the middle of your photo.';

  @override
  String get groupsCancel => 'Cancel';

  @override
  String get groupsCoverUseThisPhoto => 'Use this photo';

  @override
  String get groupsCoverPreviewSemantics => 'Your new cover photo';

  @override
  String get groupsCoverChecking => 'Checking your cover photo…';

  @override
  String groupsCoverUploading(int percent) {
    return 'Uploading cover photo… $percent%';
  }

  @override
  String get groupsCoverUploadedReview =>
      'Your cover is under review. Only you can see it until it’s approved.';

  @override
  String get groupsCoverUpdated => 'Cover photo updated.';

  @override
  String get groupsPickerSubtitle =>
      'Only friends you’re connected with can be invited.';

  @override
  String get groupsDone => 'Done';

  @override
  String get groupsSearchFriends => 'Search friends';

  @override
  String get groupsFriendsFailed => 'Friends could not load';

  @override
  String get groupsNoFriendsTitle => 'No friends yet';

  @override
  String get groupsNoFriendsBody =>
      'Add friends from Matches, profiles or rooms, then bring them into a group.';

  @override
  String get groupsAlreadyMember => 'Already in this group';

  @override
  String get groupsInvitationSent => 'Invitation sent';

  @override
  String get todayActivityCoffee => 'Coffee';

  @override
  String get todayActivityWalk => 'A daytime walk';

  @override
  String get todayActivityMeal => 'A meal';

  @override
  String get todayActivityPlayful => 'Something playful';

  @override
  String get todayActivityEvent => 'An event';

  @override
  String get todayActivityVideoCall => 'A video hello';

  @override
  String get todayActivityDrinks => 'Drinks';

  @override
  String get todayActivityOther => 'Something else';

  @override
  String get todayBudgetFlexible => 'Let’s decide together';

  @override
  String get todayBudgetFree => 'Keep it free';

  @override
  String get todayBudgetModest => 'Keep it modest';

  @override
  String get todayBudgetTreat => 'A little treat';

  @override
  String get todayRhythmTitle => 'Your dating rhythm';

  @override
  String get todayRhythmLoadFailed => 'Unable to load your preferences.';

  @override
  String get todayRhythmSaved => 'Your dating rhythm is saved.';

  @override
  String get todayRhythmSaveFailed =>
      'Unable to save. Your choices are still here.';

  @override
  String get todayRhythmHeadline => 'Make room for the way you date.';

  @override
  String get todayRhythmIntro =>
      'Choose what fits your life. Availability and introductions are optional, and you can change your mind.';

  @override
  String get todayRhythmOpenTo => 'What are you open to?';

  @override
  String get todayRhythmIntentNone => 'Prefer not to say';

  @override
  String get todayRhythmIntentRelationship => 'A relationship';

  @override
  String get todayRhythmIntentExploring => 'Finding my direction';

  @override
  String get todayRhythmIntentCasual => 'Something casual';

  @override
  String get todayRhythmPaceSection => 'Your conversation pace';

  @override
  String get todayRhythmPaceNone => 'No preference';

  @override
  String get todayRhythmPaceSlow => 'A little slower';

  @override
  String get todayRhythmPaceSteady => 'A steady conversation';

  @override
  String get todayRhythmPaceFrequent => 'Frequent conversation';

  @override
  String get todayRhythmSlowWeek => 'Slow replies this week';

  @override
  String get todayRhythmSlowWeekHint => 'This status clears after seven days.';

  @override
  String get todayRhythmSharePace => 'Share this status with my matches';

  @override
  String get todayRhythmSharePaceHint =>
      'Only current matches can see your temporary status.';

  @override
  String get todayRhythmFirstDate => 'Your kind of first date';

  @override
  String get todayRhythmChooseFive =>
      'Choose up to five. Shared preferences help explain your introductions.';

  @override
  String get todayRhythmWeekSection => 'A little room in your week';

  @override
  String get todayRhythmShareAvailability => 'Use my broad availability';

  @override
  String get todayRhythmShareAvailabilityHint =>
      'Only genuine overlap is shown. Your full schedule is private. Turning this off deletes saved windows.';

  @override
  String get todayRhythmAvailabilityHint =>
      'Tap any morning, afternoon or evening that suits you. Times use this device’s local time and expire automatically.';

  @override
  String get todayRhythmMorning => 'Morning';

  @override
  String get todayRhythmAfternoon => 'Afternoon';

  @override
  String get todayRhythmEvening => 'Evening';

  @override
  String get todayRhythmIntrosSection => 'Introductions with your permission';

  @override
  String get todayRhythmFriendIntros =>
      'Allow introductions from accepted friends';

  @override
  String get todayRhythmFriendIntrosHint =>
      'Both people must opt in. Your friend receives no match or decline updates. A preview includes your name and age.';

  @override
  String get todayRhythmIntroPhoto => 'Include my profile photos';

  @override
  String get todayRhythmIntroPhotoHint =>
      'Only the person receiving an introduction can see them.';

  @override
  String get todayRhythmIntroCity => 'Include my city';

  @override
  String get todayRhythmIntroCityHint =>
      'Your exact location is never included.';

  @override
  String get todayRhythmReload => 'Reload saved choices';

  @override
  String get todayRhythmSaving => 'Saving…';

  @override
  String get todayRhythmSave => 'Save my rhythm';

  @override
  String get todayRhythmBreakTitle => 'A break is always okay.';

  @override
  String get todayRhythmBreakBody =>
      'Pause new introductions whenever you need. Your existing conversations stay available.';

  @override
  String get todayRhythmPauseFailed => 'Unable to update your pause.';

  @override
  String get todayRhythmResume => 'Resume introductions';

  @override
  String get todayRhythmPause => 'Pause introductions';

  @override
  String get datingConnectionSlowTitle => 'Taking replies slowly this week';

  @override
  String get datingConnectionSlowBody =>
      'Your match is making room for a slower pace.';

  @override
  String get datingConnectionYourTurn => 'Your turn: add a surprise';

  @override
  String get datingConnectionComplete => 'Your first chapter is ready';

  @override
  String get datingConnectionWaiting => 'Your chapter has a beginning';

  @override
  String get datingConnectionCreate => 'Create your first chapter';

  @override
  String get datingConnectionBody =>
      'A beginning, a surprise, and a story you shape together.';

  @override
  String get chemistryTitle => 'A little chemistry';

  @override
  String get chemistryIntro =>
      'Pick something that feels like you. There are no right answers, and this never controls access to chat.';

  @override
  String get chemistrySaveFailed =>
      'Unable to save your choice. Please try again.';

  @override
  String get chemistryRetry => 'Try loading again';

  @override
  String get chemistryRevealedTitle => 'Both answers, together';

  @override
  String get chemistryYouPicked => 'You picked';

  @override
  String get chemistryMatchPicked => 'Your match picked';

  @override
  String get chemistryRevealedBody =>
      'A shared favourite or a happy difference—there’s something to talk about.';

  @override
  String get chemistryWaitingBody =>
      'Your answer is saved privately. Both answers appear here when you have both chosen.';

  @override
  String chemistryYourChoice(String choice) {
    return 'Your choice: $choice';
  }

  @override
  String get chemistryAnotherMoment => 'Another moment, whenever you like';

  @override
  String get chemistryChooseMoment => 'Choose a moment';

  @override
  String get chemistryPromptSunday => 'Build a Sunday';

  @override
  String get chemistryPromptAdventure => 'Choose an adventure';

  @override
  String get chemistryPromptFirstDate => 'Your kind of first date';

  @override
  String get chemistryQuestionSunday => 'Your ideal Sunday starts with…';

  @override
  String get chemistryQuestionAdventure => 'A small adventure together…';

  @override
  String get chemistryQuestionFirstDate => 'For a first hello, you’d choose…';

  @override
  String get engagementLevelFrozen =>
      'Progression is paused while an account safety review is active.';

  @override
  String get engagementLevelTrustGate =>
      'Verify your profile and maintain a healthy account to unlock trust-gated levels.';

  @override
  String get engagementLevelPathTitle => 'Level path';

  @override
  String get engagementLevelPathSubtitle =>
      'XP comes from meaningful activity. Purchases never increase your level.';

  @override
  String get engagementLevelRewardsTitle => 'Rewards';

  @override
  String get engagementLevelRewardsSubtitle =>
      'Earned rewards are cosmetic, convenience, or bounded visibility benefits.';

  @override
  String get engagementLevelRecentTitle => 'Recent XP';

  @override
  String get engagementLevelRecentSubtitle =>
      'Your activity ledger is permanent and auditable.';

  @override
  String engagementLevelNumber(int level) {
    return 'Level $level';
  }

  @override
  String engagementLevelXp(String xp) {
    return '$xp XP';
  }

  @override
  String get engagementLevelHighest => 'Highest level reached';

  @override
  String engagementLevelProgress(int xp, String percent) {
    return '$xp XP in this level · $percent%';
  }

  @override
  String engagementLevelThreshold(int xp, String summary) {
    return '$xp XP · $summary';
  }

  @override
  String get engagementLevelTrustGated => 'Trust-gated';

  @override
  String get engagementLevelClaimed => 'Claimed';

  @override
  String get engagementLevelClaim => 'Claim';

  @override
  String get engagementLevelLocked => 'Locked';

  @override
  String get engagementLevelStandardAward => 'Standard award';

  @override
  String engagementLevelQualityWeighting(String multiplier) {
    return '$multiplier× quality weighting';
  }

  @override
  String get engagementLevelEmptyLedger =>
      'Complete meaningful activities to earn your first XP.';

  @override
  String get engagementXpSourceProfileCompleted => 'Profile Completed';

  @override
  String get engagementXpSourceDailyPromptSubmitted => 'Daily Prompt Submitted';

  @override
  String get engagementXpSourceMiniActivityCompleted =>
      'Mini Activity Completed';

  @override
  String get engagementXpSourceCircleChallengeSubmitted =>
      'Circle Challenge Submitted';

  @override
  String get engagementXpSourceVoiceIcebreakerPlayed =>
      'Voice Icebreaker Played';

  @override
  String get engagementXpSourceStreak3 => 'Streak 3';

  @override
  String get engagementXpSourceStreak7 => 'Streak 7';

  @override
  String get engagementXpSourceStreak14 => 'Streak 14';

  @override
  String get engagementXpSourceAdminAdjustment => 'Admin Adjustment';

  @override
  String get engagementLevelSignIn => 'Sign in to view your level progress.';

  @override
  String get engagementLevelLoadFailed =>
      'Unable to load your progress right now.';

  @override
  String get engagementLevelClaimFailed =>
      'Unable to claim this reward right now.';

  @override
  String get engagementCoffeeTitle => 'Group Coffee Polls';

  @override
  String get engagementCoffeeCreateHeading =>
      'Create a lightweight group coffee poll';

  @override
  String get engagementCoffeeCreateHint =>
      'Add up to 3 participant user IDs (comma-separated) and at least one option.';

  @override
  String get engagementCoffeeParticipantsLabel =>
      'Participant user IDs (comma-separated)';

  @override
  String get engagementCoffeeDeadlineLabel => 'Deadline ISO (optional)';

  @override
  String engagementCoffeeOptionNumber(int number) {
    return 'Option $number';
  }

  @override
  String get engagementCoffeeCreate => 'Create Poll';

  @override
  String get engagementCoffeeActorLabel => 'Action user ID override (optional)';

  @override
  String get engagementCoffeeEmpty => 'No polls found yet. Create one above.';

  @override
  String engagementCoffeePollId(String id) {
    return 'Poll $id';
  }

  @override
  String engagementCoffeeStatus(String status) {
    return 'Status: $status';
  }

  @override
  String get engagementCoffeeStatusOpen => 'open';

  @override
  String get engagementCoffeeStatusFinalized => 'finalised';

  @override
  String engagementCoffeeParticipants(String ids) {
    return 'Participants: $ids';
  }

  @override
  String engagementCoffeeOptionSummary(
    String day,
    String time,
    String area,
    int count,
  ) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$day · $time · $area ($count votes)',
    );
    return '$_temp0';
  }

  @override
  String get engagementCoffeeVote => 'Vote';

  @override
  String get engagementCoffeeFinalize => 'Finalise Poll';

  @override
  String get engagementCoffeeDayLabel => 'Day';

  @override
  String get engagementCoffeeTimeLabel => 'Time window';

  @override
  String get engagementCoffeeAreaLabel => 'Neighbourhood';

  @override
  String get engagementCoffeeLoadFailed =>
      'Unable to load group polls right now.';

  @override
  String get engagementCoffeeCreateFailed =>
      'Unable to create group poll right now.';

  @override
  String get engagementCoffeeVoteUserRequired => 'User ID is required to vote.';

  @override
  String get engagementCoffeeVoteFailed => 'Unable to vote right now.';

  @override
  String get engagementCoffeeFinalizeUserRequired =>
      'User ID is required to finalise.';

  @override
  String get engagementCoffeeFinalizeFailed =>
      'Unable to finalise poll right now.';

  @override
  String get engagementDailyPromptUnavailable => 'Daily prompt unavailable';

  @override
  String get engagementDailyPromptPullToRefresh =>
      'Pull to refresh or try again in a bit.';

  @override
  String get engagementDailyPromptDomainValues => 'VALUES';

  @override
  String get engagementDailyPromptDomainLifestyle => 'LIFESTYLE';

  @override
  String get engagementDailyPromptDomainRelationshipStyle =>
      'RELATIONSHIP STYLE';

  @override
  String get engagementDailyPromptSparkTitle => 'Compatibility Spark';

  @override
  String engagementDailyPromptSparkSummary(int replied, int similar) {
    return '$replied replied today · $similar similar answers';
  }

  @override
  String get engagementDailyPromptYourAnswer => 'Your answer';

  @override
  String get engagementDailyPromptHint =>
      'Type your response in under 60 seconds.';

  @override
  String engagementDailyPromptEditOpenUntil(String time) {
    return 'Edit window open until $time';
  }

  @override
  String get engagementDailyPromptEditOpenSoon => 'Edit window open until soon';

  @override
  String get engagementDailyPromptEditClosed => 'Edit window closed for today.';

  @override
  String get engagementDailyPromptEdited => 'Edited';

  @override
  String get engagementDailyPromptSubmit => 'Submit Daily Answer';

  @override
  String get engagementDailyPromptUpdate => 'Update Answer';

  @override
  String get engagementDailyPromptStreakProgress => 'Streak Progress';

  @override
  String engagementDailyPromptStatCurrent(String value) {
    return 'Current: $value';
  }

  @override
  String engagementDailyPromptStatBest(String value) {
    return 'Best: $value';
  }

  @override
  String engagementDailyPromptStatNext(String value) {
    return 'Next: $value';
  }

  @override
  String engagementDailyPromptDays(int days) {
    return '${days}d';
  }

  @override
  String get engagementDailyPromptComplete => 'Complete';

  @override
  String engagementDailyPromptMilestone(int days) {
    return 'Milestone unlocked: $days-day streak';
  }

  @override
  String get engagementDailyPromptLoadFailed =>
      'Unable to load daily prompt right now.';

  @override
  String get engagementDailyPromptNotLoaded =>
      'Daily prompt is not loaded yet.';

  @override
  String get engagementDailyPromptEnterAnswer =>
      'Please enter an answer first.';

  @override
  String get engagementDailyPromptSubmitFailed =>
      'Unable to submit answer. Please try again.';

  @override
  String get clubsKindBooks => 'Books';

  @override
  String get clubsKindFilms => 'Films';

  @override
  String get clubsFilterAll => 'All';

  @override
  String get clubsAudiencePrivate => 'Only me';

  @override
  String get clubsAudienceFriends => 'Friends';

  @override
  String get clubsAudienceCommunity => 'Connect community';

  @override
  String get clubsRoleOwner => 'Owner';

  @override
  String get clubsRoleModerator => 'Moderator';

  @override
  String get clubsRoleMember => 'Member';

  @override
  String get clubsBadgeBookClub => 'Book club';

  @override
  String get clubsBadgeFilmClub => 'Film club';

  @override
  String get clubsBadgeBookList => 'Book list';

  @override
  String get clubsBadgeFilmList => 'Film list';

  @override
  String get clubsBadgeBook => 'Book';

  @override
  String get clubsBadgeFilm => 'Film';

  @override
  String get clubsClub => 'Club';

  @override
  String clubsStarsOutOfFive(String rating) {
    return '$rating out of 5 stars';
  }

  @override
  String clubsStarCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count stars',
      one: '1 star',
    );
    return '$_temp0';
  }

  @override
  String get clubsNoRatingsYet => 'No ratings yet';

  @override
  String clubsRatingSummary(String average, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count reviews',
      one: '1 review',
    );
    return '$average · $_temp0';
  }

  @override
  String get clubsWeekThis => 'This week';

  @override
  String get clubsWeekNext => 'Next week';

  @override
  String get clubsWeekLast => 'Last week';

  @override
  String clubsWeekOf(String date) {
    return 'Week of $date';
  }

  @override
  String get clubsTitle => 'Book & Film Clubs';

  @override
  String get clubsMyLists => 'My lists';

  @override
  String get clubsStartClubTooltip => 'Start a book or film club';

  @override
  String get clubsStartClub => 'Start a club';

  @override
  String get clubsSignInToSee => 'Sign in to see clubs.';

  @override
  String get clubsHeroTitle => 'Read it. Watch it. Talk about it.';

  @override
  String get clubsHeroSubtitle =>
      'Join a club, follow one pick a week and share what you thought. Great taste is a great conversation starter.';

  @override
  String get clubsScopeMine => 'My clubs';

  @override
  String get clubsScopeDiscover => 'Discover';

  @override
  String get clubsLoadErrorTitle => 'Clubs could not load';

  @override
  String get clubsCheckConnection => 'Please check your connection.';

  @override
  String get clubsLookAroundTitle => 'You can look around';

  @override
  String get clubsLookAroundMessage =>
      'Complete your profile with two approved photos to start or join a club.';

  @override
  String get clubsEmptyMineTitle => 'Your first club is waiting';

  @override
  String get clubsEmptyMineMessage =>
      'Find a club that reads or watches what you love, or start your own.';

  @override
  String get clubsEmptyDiscoverTitle => 'No clubs here yet';

  @override
  String get clubsEmptyDiscoverMessage =>
      'Be the first: start a club and pick something great for this week.';

  @override
  String get clubsDiscoverClubs => 'Discover clubs';

  @override
  String clubsMemberCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count members',
      one: '1 member',
    );
    return '$_temp0';
  }

  @override
  String get clubsYouRunIt => 'You run it';

  @override
  String get clubsYouModerate => 'You moderate';

  @override
  String get clubsJoined => 'Joined ✓';

  @override
  String get clubsNoPickThisWeek => 'No pick yet this week';

  @override
  String get clubsNameTooShort =>
      'Give your club a name of at least 3 letters.';

  @override
  String get clubsCreateFailed => 'Your club could not be created.';

  @override
  String get clubsNameLabel => 'Club name';

  @override
  String get clubsNameHint => 'Sunday Slow Reads';

  @override
  String get clubsDescriptionLabel => 'What is your club about? (optional)';

  @override
  String get clubsCreating => 'Creating…';

  @override
  String get clubsCreateClub => 'Create club';

  @override
  String clubsLeaveTitle(String name) {
    return 'Leave $name?';
  }

  @override
  String get clubsLeaveMessage =>
      'You can rejoin later while the club is open.';

  @override
  String get clubsLeaveClub => 'Leave club';

  @override
  String clubsWelcome(String name) {
    return 'Welcome to $name!';
  }

  @override
  String get clubsChangeNotSaved => 'That change could not be saved.';

  @override
  String get clubsOptionsTooltip => 'Club options';

  @override
  String get clubsMembers => 'Members';

  @override
  String get clubsReportClub => 'Report club';

  @override
  String get clubsDetailLoadErrorTitle => 'This club could not load';

  @override
  String get clubsDetailLoadErrorMessage =>
      'It may have closed. Please try again.';

  @override
  String get clubsEarlierPicks => 'Earlier picks';

  @override
  String clubsPickSubtitle(String week, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count posts',
      one: '1 post',
    );
    return '$week · $_temp0';
  }

  @override
  String get clubsOpenDiscussion => 'Open the discussion';

  @override
  String get clubsJoinToSeeTitle => 'Join to see the discussion';

  @override
  String get clubsJoinToSeeMessage =>
      'Members talk about each pick together. Join the club to read along and add your thoughts.';

  @override
  String clubsYouRole(String role) {
    return 'You: $role';
  }

  @override
  String get clubsRemovedByModeration => 'This club was removed by moderation.';

  @override
  String get clubsJoinClub => 'Join club';

  @override
  String get clubsNoPickModerator =>
      'No pick yet. Choose something great for everyone.';

  @override
  String get clubsNoPickMember => 'No pick yet. Check back soon.';

  @override
  String clubsQuotedNote(String note) {
    return '“$note”';
  }

  @override
  String clubsPostsInDiscussion(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count posts in the discussion',
      one: '1 post in the discussion',
    );
    return '$_temp0';
  }

  @override
  String get clubsSetThisWeeksPick => 'Set this week’s pick';

  @override
  String get clubsDiscussThisPick => 'Discuss this pick';

  @override
  String get clubsPostNotSent => 'Your post could not be sent.';

  @override
  String clubsDiscussionHeading(String title) {
    return 'Discussion · $title';
  }

  @override
  String get clubsDiscussionLoadError => 'The discussion could not load';

  @override
  String get clubsStartConversationTitle => 'Start the conversation';

  @override
  String get clubsStartConversationMessage =>
      'What did you think so far? Your post could be the one that gets everyone talking.';

  @override
  String get clubsLoadMorePosts => 'Load more posts';

  @override
  String get clubsComposerLabel => 'Add to the discussion';

  @override
  String get clubsComposerHint => 'Favourite moment? Biggest surprise?';

  @override
  String get clubsContainsSpoilers => 'Contains spoilers';

  @override
  String get clubsSpoilersSubtitle => 'Others tap to reveal it.';

  @override
  String get clubsPosting => 'Posting…';

  @override
  String get clubsPost => 'Post';

  @override
  String get clubsDeletePostTitle => 'Delete your post?';

  @override
  String get clubsDeletePostMessage =>
      'It is removed from the discussion for everyone.';

  @override
  String get clubsActionFailed => 'That action could not be completed.';

  @override
  String get clubsHideFromMembers => 'Hide from members';

  @override
  String get clubsShowToMembers => 'Show to members';

  @override
  String get clubsReport => 'Report';

  @override
  String get clubsYou => 'You';

  @override
  String get clubsHidden => 'Hidden';

  @override
  String get clubsPostActions => 'Post actions';

  @override
  String get clubsMakeModerator => 'Make moderator';

  @override
  String get clubsMakeMember => 'Make member';

  @override
  String get clubsRemoveFromClub => 'Remove from club';

  @override
  String clubsRemoveMemberTitle(String name) {
    return 'Remove $name?';
  }

  @override
  String get clubsRemoveMemberMessage =>
      'They leave the club and cannot rejoin. Their past posts stay in the discussion.';

  @override
  String get clubsRemove => 'Remove';

  @override
  String get clubsMembersLoadError => 'Members could not load.';

  @override
  String clubsMemberYou(String name) {
    return '$name (you)';
  }

  @override
  String clubsMemberActions(String name) {
    return 'Actions for $name';
  }

  @override
  String get clubsChooseFilm => 'Choose a film';

  @override
  String get clubsChooseBook => 'Choose a book';

  @override
  String get clubsChooseTitle => 'Choose a title';

  @override
  String get clubsChooseTitleFirst => 'Choose a title first.';

  @override
  String get clubsPickNotSaved => 'The pick could not be saved.';

  @override
  String get clubsSetWeeklyPick => 'Set the weekly pick';

  @override
  String get clubsChange => 'Change';

  @override
  String get clubsPickNoteLabel => 'A note for the club (optional)';

  @override
  String get clubsPickNoteHint => 'Why this one? Where to start?';

  @override
  String get clubsSaving => 'Saving…';

  @override
  String get clubsSavePick => 'Save pick';

  @override
  String get clubsListNameRequired => 'Give your list a name.';

  @override
  String get clubsListNotSaved => 'Your list could not be saved.';

  @override
  String get clubsEditList => 'Edit list';

  @override
  String get clubsNewList => 'New list';

  @override
  String get clubsListNameLabel => 'List name';

  @override
  String get clubsListNameHint => 'Books that changed my mind';

  @override
  String get clubsWhoCanSee => 'Who can see it';

  @override
  String get clubsSave => 'Save';

  @override
  String get clubsCreateList => 'Create list';

  @override
  String get clubsYourNote => 'Your note';

  @override
  String get clubsNoteLabel => 'Why it is on this list';

  @override
  String get clubsSaveNote => 'Save note';

  @override
  String get clubsCreateNewListTooltip => 'Create a new list';

  @override
  String get clubsSignInToSeeLists => 'Sign in to see your lists.';

  @override
  String get clubsShelfTitle => 'Your shelf';

  @override
  String get clubsShelfSubtitle =>
      'Keep track of what you loved and what is next. Share a list, or keep it just for you.';

  @override
  String get clubsListsLoadErrorTitle => 'Your lists could not load';

  @override
  String get clubsFirstListTitle => 'Start your first list';

  @override
  String get clubsFirstListMessage =>
      'Favourite films, books to read next, comfort rewatches: it is up to you.';

  @override
  String clubsAddToNamed(String name) {
    return 'Add to $name';
  }

  @override
  String get clubsAddToThisListFailed => 'It could not be added to this list.';

  @override
  String clubsDeleteListTitle(String name) {
    return 'Delete $name?';
  }

  @override
  String get clubsDeleteListMessage =>
      'The list and its notes are removed. This cannot be undone.';

  @override
  String get clubsDeleteList => 'Delete list';

  @override
  String get clubsListDeleteFailed =>
      'The list could not be deleted. Reload and retry.';

  @override
  String get clubsNoteNotSaved => 'Your note could not be saved.';

  @override
  String get clubsRemoveFailed => 'It could not be removed.';

  @override
  String get clubsListOptions => 'List options';

  @override
  String get clubsAddATitle => 'Add a title';

  @override
  String clubsTitleCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count titles',
      one: '1 title',
    );
    return '$_temp0';
  }

  @override
  String get clubsListEmpty =>
      'Nothing here yet. Use “Add a title” from the list menu.';

  @override
  String clubsItemOptions(String title) {
    return 'Options for $title';
  }

  @override
  String get clubsAddNote => 'Add a note';

  @override
  String get clubsEditNote => 'Edit note';

  @override
  String get clubsRemoveFromList => 'Remove from list';

  @override
  String get clubsTapStarError => 'Tap a star to rate it.';

  @override
  String get clubsReviewNotSaved => 'Your review could not be saved.';

  @override
  String get clubsWriteReview => 'Write a review';

  @override
  String get clubsEditYourReview => 'Edit your review';

  @override
  String get clubsTapStarToRate => 'Tap a star to rate';

  @override
  String clubsRatingOutOfFive(int rating) {
    return '$rating out of 5';
  }

  @override
  String get clubsReviewBodyLabel => 'What did you think? (optional)';

  @override
  String get clubsSaveReview => 'Save review';

  @override
  String clubsAddedToList(String name) {
    return 'Added to $name.';
  }

  @override
  String get clubsAddToThatListFailed => 'It could not be added to that list.';

  @override
  String get clubsAddToAList => 'Add to a list';

  @override
  String get clubsListsLoadError => 'Your lists could not load.';

  @override
  String get clubsNoFilmLists =>
      'You have no film lists yet. Create one to start collecting.';

  @override
  String get clubsNoBookLists =>
      'You have no book lists yet. Create one to start collecting.';

  @override
  String get clubsTitleFallback => 'Title';

  @override
  String get clubsSignInToSeeReviews => 'Sign in to see reviews.';

  @override
  String get clubsTitleLoadError => 'This title could not load';

  @override
  String get clubsReviews => 'Reviews';

  @override
  String get clubsNoOtherReviewsTitle => 'No other reviews yet';

  @override
  String get clubsNoOtherReviewsMessage =>
      'When members you can see share a review, it shows up here.';

  @override
  String get clubsDeleteReviewTitle => 'Delete your review?';

  @override
  String get clubsDeleteReviewMessage =>
      'Your rating and words are removed for everyone.';

  @override
  String get clubsDeleteReview => 'Delete review';

  @override
  String get clubsReviewDeleteFailed =>
      'Your review could not be deleted. Reload and retry.';

  @override
  String get clubsWhatDidYouThink => 'What did you think?';

  @override
  String get clubsReviewPrompt =>
      'Rate it and say why. You choose who sees it.';

  @override
  String get clubsYourReview => 'Your review';

  @override
  String get clubsSpoilers => 'Spoilers';

  @override
  String get clubsEdit => 'Edit';

  @override
  String get clubsReportReview => 'Report this review';

  @override
  String get clubsEnterTitle => 'Enter the title.';

  @override
  String get clubsYearRange => 'Enter a year between 1450 and 2100.';

  @override
  String get clubsTitleAddFailed => 'The title could not be added.';

  @override
  String get clubsSearchFilms => 'Search films';

  @override
  String get clubsSearchBooks => 'Search books';

  @override
  String get clubsTypeTwoLetters => 'Type at least 2 letters';

  @override
  String get clubsSearchUnavailable => 'Search is unavailable.';

  @override
  String get clubsNoFilmsMatch => 'No films match. Add it below.';

  @override
  String get clubsNoBooksMatch => 'No books match. Add it below.';

  @override
  String get clubsAddNewFilm => 'Add a new film';

  @override
  String get clubsAddNewBook => 'Add a new book';

  @override
  String get clubsTitleFieldLabel => 'Title';

  @override
  String get clubsDirector => 'Director';

  @override
  String get clubsAuthor => 'Author';

  @override
  String get clubsYearOptional => 'Year (optional)';

  @override
  String get clubsAdding => 'Adding…';

  @override
  String get clubsAddAndChoose => 'Add and choose';

  @override
  String get friendsIntroducerSaveFailed =>
      'We couldn’t save that. Refresh to check the latest permissions before trying again.';

  @override
  String friendsIntroducerRevokeTitle(String name) {
    return 'Remove permission for $name?';
  }

  @override
  String get friendsIntroducerRevokeBody =>
      'New and unanswered introductions will stop. An existing mutual match stays between the two people.';

  @override
  String get friendsIntroducerKeepPermission => 'Keep permission';

  @override
  String get friendsIntroducerRemovePermission => 'Remove permission';

  @override
  String get friendsIntroducerPermissionRemoved => 'Permission removed.';

  @override
  String get friendsIntroducerMemberTitle => 'Your introducers';

  @override
  String get friendsIntroducerAppTitle => 'Connect · Friends';

  @override
  String get friendsIntroducerRefresh => 'Refresh permissions';

  @override
  String get friendsIntroducerAccount => 'Account';

  @override
  String get friendsIntroducerAccountPrivacy => 'Account & privacy';

  @override
  String get friendsIntroducerSignOut => 'Sign out';

  @override
  String get friendsIntroducerMemberHeadline => 'Good friends. Your say.';

  @override
  String get friendsIntroducerHeadline =>
      'You know them.\nYou see the possibility.';

  @override
  String get friendsIntroducerMemberIntro =>
      'Invite someone you trust to introduce you. They can join without a dating profile. You decide who gets permission and what a preview shares.';

  @override
  String get friendsIntroducerIntro =>
      'A little thoughtfulness can start something real. Bring together friends who have asked for your help.';

  @override
  String get friendsIntroducerMemberListTitle => 'People you choose';

  @override
  String get friendsIntroducerListTitle => 'Your small circle';

  @override
  String get friendsIntroducerLoadFailed =>
      'We couldn’t load permissions. Nothing has been changed.';

  @override
  String get friendsIntroducerMemberEmpty =>
      'No introducers yet. Share an invitation with one trusted friend to get started.';

  @override
  String get friendsIntroducerEmpty =>
      'Your circle starts with permission. Ask a friend on Connect for their invitation code.';

  @override
  String get friendsIntroducerStatusPendingMember =>
      'Wants your permission to introduce you.';

  @override
  String get friendsIntroducerStatusPending =>
      'Waiting for your friend’s approval.';

  @override
  String get friendsIntroducerStatusPaused => 'Introductions are paused.';

  @override
  String get friendsIntroducerStatusActive =>
      'Permission to suggest introductions.';

  @override
  String friendsIntroducerPreview(String extras) {
    String _temp0 = intl.Intl.selectLogic(extras, {
      'photo':
          'Preview shared with a suggested date: name and optional age, photo.',
      'city':
          'Preview shared with a suggested date: name and optional age, city.',
      'both':
          'Preview shared with a suggested date: name and optional age, photo, city.',
      'other': 'Preview shared with a suggested date: name and optional age.',
    });
    return '$_temp0';
  }

  @override
  String get friendsIntroducerApproveNote =>
      'Approving also turns on friend introductions. You can pause all introductions in Dating rhythm.';

  @override
  String get friendsIntroducerAllow => 'Allow introductions';

  @override
  String friendsIntroducerAllowed(String name) {
    return '$name now has your permission.';
  }

  @override
  String get friendsIntroducerDecline => 'Decline request';

  @override
  String get friendsIntroducerSentTitle => 'Thoughtfully sent';

  @override
  String get friendsIntroducerSentBody =>
      'Their answers stay between them. Both people must say yes before a match is made.';

  @override
  String get friendsIntroducerReloadSent => 'Reload sent introductions';

  @override
  String get friendsIntroducerSentSubtitle =>
      'Sent · their decision is private';

  @override
  String get friendsIntroducerStepPreview => '1. Choose the preview';

  @override
  String get friendsIntroducerPreviewBody =>
      'A suggested date sees your name and age if you already show it. Your introducer sees only your name, never your profile or dating activity.';

  @override
  String get friendsIntroducerIncludePhoto => 'Include my profile photo';

  @override
  String get friendsIntroducerIncludeCity => 'Include my city';

  @override
  String get friendsIntroducerStepInvite => '2. Invite one trusted friend';

  @override
  String get friendsIntroducerInviteBody =>
      'The code works once and expires in 48 hours. Your friend joins through “Just here to introduce friends” on the welcome screen. You’ll approve their name here before anything can be shared.';

  @override
  String get friendsIntroducerInviteReady =>
      'Invitation ready. Any previous unused code no longer works.';

  @override
  String get friendsIntroducerCreateCode => 'Create invitation code';

  @override
  String get friendsIntroducerShareCode =>
      'Share privately with your friend. To change this preview, cancel the unused invitation and create a new code.';

  @override
  String get friendsIntroducerCodeCopied => 'Invitation code copied';

  @override
  String get friendsIntroducerCopyCode => 'Copy code';

  @override
  String get friendsIntroducerInvitesCancelled =>
      'Unused invitations cancelled.';

  @override
  String get friendsIntroducerCancelInvites => 'Cancel unused invitations';

  @override
  String get friendsIntroducerManagePrefs =>
      'Manage all introduction preferences';

  @override
  String get friendsIntroducerRedeemTitle => 'A friend invited you?';

  @override
  String get friendsIntroducerRedeemBody =>
      'Paste their private invitation code. They’ll confirm your name before you can introduce them.';

  @override
  String get friendsIntroducerCodeLabel => 'Invitation code';

  @override
  String get friendsIntroducerCodeMissing =>
      'Enter the invitation code your friend shared.';

  @override
  String get friendsIntroducerRequestSent =>
      'Request sent. Your friend can now approve you in Your introducers.';

  @override
  String get friendsIntroducerAskPermission => 'Ask for permission';

  @override
  String get friendsIntroducerNeedTwo =>
      'Once two friends give permission, you can suggest an introduction here.';

  @override
  String get friendsIntroducerComposerTitle => 'See a possibility?';

  @override
  String get friendsIntroducerWhyLabel => 'Why you thought of them (optional)';

  @override
  String get friendsIntroducerWhyHelper =>
      'Both will see this. Keep private details out.';

  @override
  String get friendsIntroducerIntroSent =>
      'Introduction sent. They can each decide in private.';

  @override
  String get friendsIntroducerSuggest => 'Suggest an introduction';

  @override
  String get friendsIntroducerPrivacyNote =>
      'Permission first. No public dating activity. No updates on who said yes or no.';

  @override
  String get planSharingLoadFailed => 'Unable to load sharing choices.';

  @override
  String get planSharingOffSnack => 'Your contact sharing is off.';

  @override
  String get planSharingSavedSnack =>
      'Your selected contacts can now see this plan.';

  @override
  String get planSharingSaveFailed =>
      'Unable to save. Reload choices before trying again.';

  @override
  String get planSharingTitle => 'Your plan. Your people.';

  @override
  String get planSharingCloseTooltip => 'Close sharing';

  @override
  String get planSharingIntro =>
      'Sharing with contacts starts off. Choose up to 10 trusted friends for this plan. Your date chooses their own contacts.';

  @override
  String get planSharingNoContacts =>
      'No eligible friends yet. Your plan is still available to you and your date.';

  @override
  String get planSharingFriendFallback => 'A friend';

  @override
  String get planSharingPreviewNone => 'Preview · no contacts selected';

  @override
  String planSharingPreviewCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Preview · $count selected',
    );
    return '$_temp0';
  }

  @override
  String get planSharingPreviewOffBody =>
      'Your friends will receive no plan or check-in updates from you.';

  @override
  String get planSharingPreviewOnBody =>
      'These contacts can see your date’s name, the time and place, plan status, and your check-in updates. They receive the current plan when you save.';

  @override
  String get planSharingPrivacyNote =>
      'Messages and private post-date feedback stay private. Removing a contact stops future updates and removes their in-app plan access. Updates already delivered to a device cannot be recalled.';

  @override
  String get planSharingReload => 'Reload sharing choices';

  @override
  String get planSharingSaving => 'Saving…';

  @override
  String get planSharingKeepOff => 'Keep contact sharing off';

  @override
  String get planSharingShareSelected => 'Share with selected contacts';

  @override
  String get planSharingDeselectAll => 'Deselect everyone';

  @override
  String planBudgetLine(String budget) {
    return 'Budget · $budget';
  }

  @override
  String planAtmosphereLine(String atmospheres) {
    return 'Atmosphere · $atmospheres';
  }

  @override
  String get planAtmosphereQuiet => 'Quiet conversation';

  @override
  String get planAtmosphereRelaxed => 'Relaxed & unhurried';

  @override
  String get planAtmosphereLively => 'A lively setting';

  @override
  String get planAtmosphereOutdoors => 'Outdoors';

  @override
  String get planAtmosphereIndoors => 'Indoors';

  @override
  String get planAccessStepFree => 'Step-free access';

  @override
  String get planAccessToilet => 'Accessible toilet';

  @override
  String get planAccessSeating => 'Seating available';

  @override
  String get planAccessLowNoise => 'Low background noise';

  @override
  String get planAccessTransit => 'Near public transport';

  @override
  String get planAccessCaptions => 'Captions for a video date';

  @override
  String get planComfortHeading => 'To make this comfortable';

  @override
  String get planPreferencesDisclaimer =>
      'Preferences shared for this plan. Confirm these details with the venue or video service.';

  @override
  String get planProposeErrorKept =>
      'Your plan could not be sent. Your choices are still here.';

  @override
  String get planChangedError =>
      'This plan has changed. Close this sheet to review the conversation.';

  @override
  String get planProposeHeadline => 'A plan you both look forward to.';

  @override
  String get planCounterHeadline => 'Shape this plan together';

  @override
  String planProposeLead(String name) {
    return 'A suggestion for you and $name. Nothing is agreed until the other person accepts this version.';
  }

  @override
  String get planFindTimeTitle => 'Find a little time together';

  @override
  String get planFindTimeBody =>
      'Only overlapping times are shown when both of you choose to share availability. You can always suggest a time yourself.';

  @override
  String get planSharedTimesFailed =>
      'Shared times couldn’t load. Your manual time is still available.';

  @override
  String get planSharedTimesEmpty =>
      'No shared time suggestions right now. This does not mean either of you is unavailable.';

  @override
  String get planRefreshSharedTimes => 'Refresh shared times';

  @override
  String get planSetAvailability => 'Set my availability';

  @override
  String get planWhenTitle => 'When would feel right?';

  @override
  String get planTimeSourceManual => 'A time you’re suggesting';

  @override
  String get planTimeSourceShared =>
      'Selected from shared availability · checked again when sent';

  @override
  String planLocalTimeNote(int minutes, String timeZone) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other:
          'Your device’s local time ($timeZone). Duration: $minutes minutes.',
    );
    return '$_temp0';
  }

  @override
  String planDurationChip(int minutes) {
    return '$minutes min';
  }

  @override
  String get planEnjoyTitle => 'Something you would enjoy';

  @override
  String get planAreaHint => 'A neighbourhood or public meeting area';

  @override
  String get planBudgetTitle => 'What budget feels comfortable?';

  @override
  String get planBudgetBody =>
      'A starting point to agree together, not a price quote or a promise about who pays.';

  @override
  String get planAtmosphereTitle => 'Set the atmosphere';

  @override
  String get planAtmosphereBody =>
      'Choose up to three settings you would enjoy. Optional.';

  @override
  String get planComfortTitle => 'Make it comfortable for both of you';

  @override
  String get planComfortBody =>
      'Optional accessibility preferences. Selected choices are shared with your match when you send this plan. They are not added to your public profile or trusted-contact updates.';

  @override
  String get planComfortDisclaimer =>
      'You do not need to explain a diagnosis. These are requests to check with the venue or video service, not verified facilities.';

  @override
  String get planNoteHint => 'Saturday afternoon, somewhere quieter?';

  @override
  String get planReviewBeforeSending =>
      'Before sending, review the time and choices above. The other person can accept, decline or suggest a change.';

  @override
  String get planReloadLatest => 'Reload latest plan · discard edits';

  @override
  String get planSending => 'Sending…';

  @override
  String get planSendSuggestion => 'Send your suggestion';

  @override
  String get planSecondYesTitle => 'Share a second yes';

  @override
  String get planSecondYesBody =>
      'Reveal that you want to meet again only if your match also says yes and agrees to share. Your other answers stay private.';

  @override
  String get planSecondYesHeadline => 'A second yes, from both of you';

  @override
  String get planSecondYesCardBody =>
      'You both chose to share that you would like to meet again.';

  @override
  String get planAnotherHello => 'Plan another hello';

  @override
  String get planSuggestChange => 'Suggest a change';

  @override
  String get planChooseUpdates => 'Choose who gets your updates';

  @override
  String planQuotedNote(String note) {
    return '“$note”';
  }

  @override
  String get planStatusDeclined => 'Declined';

  @override
  String get planStatusExpired => 'Expired';

  @override
  String get planStatusCompleted => 'Completed';

  @override
  String get planStatusDidNotHappen => 'Did not happen';

  @override
  String get planStatusDisputed => 'Disputed';

  @override
  String get plansManageSharing => 'Manage your contact sharing';

  @override
  String get plansLoadFailed => 'Unable to load date plans.';

  @override
  String get plansFeedLoadFailed => 'Unable to load plans.';

  @override
  String get planAcceptFailed => 'Unable to accept this plan.';

  @override
  String get planDeclineFailed => 'Unable to decline this plan.';

  @override
  String get planCancelFailed => 'Unable to cancel this plan.';

  @override
  String get planCheckinFailed => 'Unable to check in right now.';

  @override
  String get graduationFoundEachOther => 'You found each other';

  @override
  String graduationHeadlineDecide(String name) {
    return '$name wants to leave Connect together';
  }

  @override
  String graduationHeadlineWaiting(String name) {
    return 'Waiting for $name';
  }

  @override
  String get graduationBodyConfirmed =>
      'You are both hidden from discovery. This chat stays open.';

  @override
  String get graduationBodyDecide =>
      'Confirm and you both leave discovery. Your chat stays.';

  @override
  String get graduationBodyWaiting =>
      'You asked to leave together. They can confirm or decline.';

  @override
  String get graduationCelebrate => 'Celebrate';

  @override
  String get graduationNotYet => 'Not yet';

  @override
  String get graduationConfirm => 'Confirm';

  @override
  String get graduationFriendsToldOnConfirm =>
      'Your friends are told once they confirm.';

  @override
  String get graduationOnlyTwoOfYouForNow =>
      'Only the two of you know for now.';

  @override
  String get graduationWithdraw => 'Withdraw';

  @override
  String graduationProposeTitle(String name) {
    return 'Leave Connect with $name?';
  }

  @override
  String graduationProposeBody(String name) {
    return 'Once $name confirms, you are both hidden from discovery. This chat stays open, and you can come back to discovery from Privacy & Safety at any time.';
  }

  @override
  String get graduationNoteLabel => 'A note for them (optional)';

  @override
  String get graduationNoteHint => 'Say why you are ready';

  @override
  String get graduationTellFriends => 'Tell my friends';

  @override
  String get graduationTellFriendsBody =>
      'Your accepted friends hear you found someone. They are not told who.';

  @override
  String get graduationAskThem => 'Ask them';

  @override
  String get graduationTitle => 'Graduation';

  @override
  String graduationCelebrationBody(String name) {
    return 'You and $name are leaving Connect together. You are both hidden from discovery, and this chat stays open for as long as you like.';
  }

  @override
  String get graduationFriendsHaveBeenTold => 'Your friends have been told.';

  @override
  String get graduationFriendsAreTold => 'Your friends are told.';

  @override
  String get graduationOnlyTwoOfYou => 'Only the two of you know.';

  @override
  String get graduationConfirmAndBack => 'Confirm and go back';

  @override
  String get graduationBackToConnect => 'Back to Connect';

  @override
  String get graduationLoadFailed => 'Unable to load graduation.';

  @override
  String get graduationProposeFailed => 'Unable to propose leaving together.';

  @override
  String get graduationConfirmFailed => 'Unable to confirm right now.';

  @override
  String get graduationDeclineFailed => 'Unable to decline right now.';

  @override
  String get graduationWithdrawFailed => 'Unable to withdraw the proposal.';

  @override
  String get graduationPauseLoadFailed => 'Unable to load discovery status.';

  @override
  String get graduationPauseFailed => 'Unable to pause discovery.';

  @override
  String get graduationResumeFailed => 'Unable to resume discovery.';

  @override
  String get engagementCirclesEmptyTitle => 'No circles available';

  @override
  String get engagementCirclesPullToRefresh => 'Please pull to refresh.';

  @override
  String get engagementCirclesJoined => 'Joined';

  @override
  String get engagementCirclesNotJoined => 'Not joined';

  @override
  String engagementCirclesParticipants(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count participants this week',
    );
    return '$_temp0';
  }

  @override
  String get engagementCirclesJoin => 'Join Circle';

  @override
  String get engagementCirclesResponseLabel => 'Weekly challenge response';

  @override
  String get engagementCirclesSubmit => 'Submit Entry';

  @override
  String get engagementCirclesTopicFallback => 'Circle';

  @override
  String get engagementCirclesLoadFailed => 'Unable to load circles right now.';

  @override
  String get engagementCirclesJoinFailed => 'Unable to join circle right now.';

  @override
  String get engagementCirclesEnterResponse =>
      'Please enter your challenge response.';

  @override
  String get engagementCirclesSubmitFailed =>
      'Unable to submit challenge entry right now.';

  @override
  String get engagementNudgesTitle => 'Match nudges';

  @override
  String get engagementNudgesIntro =>
      'Send a gentle reminder to restart a quiet conversation. Daily limits and safety rules are enforced by the server.';

  @override
  String get engagementNudgesEmpty => 'No matches available to nudge.';

  @override
  String get engagementNudgesSentInSession => 'Nudge sent in this session';

  @override
  String get engagementNudgesReady => 'Ready to send';

  @override
  String engagementNudgesSentTo(String name) {
    return 'Nudge sent to $name.';
  }

  @override
  String get engagementNudgesAction => 'Nudge';

  @override
  String get engagementNudgesSendFailed => 'Unable to send this nudge.';

  @override
  String get engagementTrustBadgesEarned => 'Earned Badges';

  @override
  String get engagementTrustBadgesEmpty =>
      'No badges yet. Complete activities to unlock trust badges.';

  @override
  String engagementTrustBadgesDetails(
    String code,
    String status,
    String awardedAt,
  ) {
    return 'Code: $code\nStatus: $status • Awarded $awardedAt';
  }

  @override
  String get engagementTrustBadgesHistory => 'Recent History';

  @override
  String get engagementTrustBadgesHistoryEmpty =>
      'No trust history available yet.';

  @override
  String get engagementTrustBadgesMilestoneUnavailable =>
      'Milestone status unavailable.';

  @override
  String get engagementTrustBadgesCurrentMilestone => 'Current Milestone';

  @override
  String get engagementTrustBadgesLoadFailed =>
      'Failed to load trust badges. Please try again.';

  @override
  String get engagementTrustFiltersEnable => 'Enable trust filters';

  @override
  String get engagementTrustFiltersEnableSubtitle =>
      'Hide profiles that do not meet your trust requirements';

  @override
  String engagementTrustFiltersMinimum(int count) {
    return 'Minimum active badges: $count';
  }

  @override
  String get engagementTrustFiltersRequired => 'Required badges';

  @override
  String get engagementTrustFiltersSaved => 'Trust filters saved.';

  @override
  String get engagementTrustFiltersSave => 'Save Trust Filters';

  @override
  String get engagementAppealStatusSubmitted => 'Submitted';

  @override
  String get engagementAppealStatusUnderReview => 'Under review';

  @override
  String get engagementAppealStatusResolvedUpheld => 'Resolved (upheld)';

  @override
  String get engagementAppealStatusResolvedReversed => 'Resolved (reversed)';

  @override
  String get engagementRoomsLeaveFailed =>
      'Could not leave this room. Please retry.';

  @override
  String get engagementRoomsPresenceFailed => 'Lost touch with the room.';

  @override
  String get engagementRoomsMembersFailed =>
      'Could not load who is here. Please retry.';

  @override
  String get engagementRoomsModerationFailed =>
      'That did not go through. Please retry.';

  @override
  String get engagementRoomsCreateFailed =>
      'Could not start the room. Please retry.';

  @override
  String get engagementRoomsLoadFailed =>
      'Rooms are unavailable right now. Pull to retry.';

  @override
  String get commonSave => 'Save';

  @override
  String get commonRemove => 'Remove';

  @override
  String get accountTitle => 'Account & Data';

  @override
  String get accountLoadFailed => 'Could not load your account status.';

  @override
  String accountDeletionIn(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'Deletion in $days days',
      one: 'Deletion in 1 day',
    );
    return '$_temp0';
  }

  @override
  String get accountDeletionDue => 'Deletion is due';

  @override
  String get accountDeletionCountdownBody =>
      'Your profile is hidden. You can still sign in and cancel until then — after that your data cannot be recovered.';

  @override
  String get accountKeepMyAccount => 'Keep my account';

  @override
  String get accountNotDeletedSnack => 'Your account will not be deleted.';

  @override
  String get accountCancelFailed => 'Could not cancel. Please try again.';

  @override
  String get accountHiddenTitle => 'Your profile is hidden';

  @override
  String get accountTakeBreakTitle => 'Take a break';

  @override
  String get accountHiddenBody =>
      'Nobody can see or match with you. Your matches and messages are kept, and you can come back whenever you want.';

  @override
  String get accountTakeBreakBody =>
      'Hide your profile from Discover without losing anything. You stay signed in and can switch back at any time.';

  @override
  String get accountUnhideProfile => 'Unhide my profile';

  @override
  String get accountHideProfile => 'Hide my profile';

  @override
  String get accountVisibleAgainSnack => 'Your profile is visible again.';

  @override
  String get accountNowHiddenSnack => 'Your profile is now hidden.';

  @override
  String get accountUpdateFailed => 'Could not update. Please try again.';

  @override
  String get accountDownloadTitle => 'Download your data';

  @override
  String get accountDownloadBody =>
      'Get a copy of your profile, preferences, matches and the messages you sent. Messages other people wrote are not included.';

  @override
  String get accountPreparing => 'Preparing…';

  @override
  String get accountPrepareData => 'Prepare my data';

  @override
  String get accountPrepareFailed =>
      'Could not prepare your data. Please try again.';

  @override
  String get accountYourData => 'Your data';

  @override
  String get accountDeleteTitle => 'Delete my account';

  @override
  String get accountDeleteBody =>
      'Your profile is hidden straight away and everything is erased after a grace period. You can cancel during that time by signing in. Afterwards nothing can be recovered.';

  @override
  String get accountDeletionAlreadyScheduled => 'Deletion already scheduled';

  @override
  String get accountDeleteConfirmTitle => 'Delete your account?';

  @override
  String get accountDeleteConfirmBody =>
      'Your profile, photos, matches and messages will be erased and cannot be recovered.\n\nIf you just want a break, hiding your profile keeps everything and can be undone.';

  @override
  String get accountHideInstead => 'Hide instead';

  @override
  String get accountDeletionScheduledSnack =>
      'Deletion scheduled. You can cancel until then.';

  @override
  String get privacyTitle => 'Privacy & Safety';

  @override
  String get privacyShowAge => 'Show age';

  @override
  String get privacyShowAgeSubtitle => 'Control whether your age is visible';

  @override
  String get privacyShowDistance => 'Show exact distance';

  @override
  String get privacyShowDistanceSubtitle =>
      'Show precise distance on your profile';

  @override
  String get privacyShowOnline => 'Show online status';

  @override
  String get privacyShowOnlineSubtitle =>
      'Allow others to see if you are online';

  @override
  String get privacyEmergencySos => 'Emergency SOS';

  @override
  String get privacyEmergencySosSubtitle =>
      'Activate an alert and review alert history';

  @override
  String get privacyEmergencyContacts => 'Emergency Contacts';

  @override
  String get privacyEmergencyContactsSubtitle =>
      'Manage trusted emergency contacts';

  @override
  String get privacyBlockedUsers => 'Blocked Users';

  @override
  String get privacyBlockedUsersSubtitle => 'Review and unblock users';

  @override
  String get privacyModerationAppeals => 'Moderation Appeals';

  @override
  String get privacyModerationAppealsSubtitle =>
      'Submit an appeal and track review status';

  @override
  String get privacyFriendSearch => 'Let people find me in friend search';

  @override
  String get privacySettingLoadFailed =>
      'This setting could not load. Open this page again to retry.';

  @override
  String get privacyFriendSearchSubtitle =>
      'Members can find you by name or @username in Add friend. People you match or meet in rooms and groups can still add you.';

  @override
  String get privacyChoiceSaveFailed => 'Your choice could not be saved.';

  @override
  String get privacyShowcase => 'Show my public writing on my profile';

  @override
  String get privacyShowcaseSubtitle =>
      'Members can see the chapters you share with the community and your photos on the wall on your profile. Private and friends-only chapters never appear.';

  @override
  String get privacyCrashReports => 'Share crash reports';

  @override
  String get privacyCrashReportsSubtitle =>
      'Anonymous crash and error reports help us fix problems. No messages, photos or account details are included.';

  @override
  String get privacyGraduatedReason =>
      'You left Connect with your match. Nobody is dealt your card.';

  @override
  String get privacyPausedReason =>
      'Nobody is dealt your card until you resume.';

  @override
  String get privacyActiveReason =>
      'You are shown to other members in discovery.';

  @override
  String get privacyDiscoveryPaused => 'Discovery paused';

  @override
  String get privacyDiscoveryActive => 'Discovery active';

  @override
  String get privacyResume => 'Resume';

  @override
  String get privacyPause => 'Pause';

  @override
  String get emergencyIntro =>
      'Add up to 3 trusted contacts. These contacts are used for safety workflows and SOS features in later phases.';

  @override
  String get emergencyEmpty => 'No emergency contacts added yet.';

  @override
  String get emergencyMaxReached => 'Maximum contacts added';

  @override
  String get emergencyAddContact => 'Add Contact';

  @override
  String get emergencyEditContact => 'Edit Contact';

  @override
  String get emergencyInvalidInput => 'Enter a valid name and phone number.';

  @override
  String get emergencyAdded => 'Emergency contact added.';

  @override
  String get emergencyAddFailed => 'Failed to add contact. Please try again.';

  @override
  String get emergencyUpdated => 'Emergency contact updated.';

  @override
  String get emergencyUpdateFailed =>
      'Failed to update contact. Please try again.';

  @override
  String get emergencyRemoveTitle => 'Remove Contact';

  @override
  String emergencyRemoveBody(String name) {
    return 'Remove $name from emergency contacts?';
  }

  @override
  String get emergencyRemoved => 'Emergency contact removed.';

  @override
  String get emergencyRemoveFailed =>
      'Failed to remove contact. Please try again.';

  @override
  String get emergencyNameLabel => 'Name';

  @override
  String get emergencyPhoneLabel => 'Phone Number';

  @override
  String get appealsSubmitTitle => 'Submit an appeal';

  @override
  String get appealsReasonLabel => 'Reason';

  @override
  String get appealsReasonHint =>
      'Why should this moderation decision be reviewed?';

  @override
  String get appealsReportIdLabel => 'Report ID (optional)';

  @override
  String get appealsContextLabel => 'Additional context (optional)';

  @override
  String get appealsSubmit => 'Submit appeal';

  @override
  String get appealsEmpty =>
      'No appeals submitted yet. Your submitted appeals will appear here with status updates.';

  @override
  String appealsIdLine(String id) {
    return 'Appeal ID: $id';
  }

  @override
  String appealsSlaLine(String deadline) {
    return 'SLA deadline: $deadline';
  }

  @override
  String appealsReviewedBy(String reviewer) {
    return 'Reviewed by: $reviewer';
  }

  @override
  String get appealsReasonRequired => 'Reason is required.';

  @override
  String get appealsSubmitted => 'Appeal submitted successfully.';

  @override
  String get appealsSubmitFailed =>
      'Failed to submit appeal. Please try again.';

  @override
  String get blockedEmpty => 'You have not blocked any users.';

  @override
  String get blockedUnblock => 'Unblock';

  @override
  String get blockedUnblockTitle => 'Unblock User';

  @override
  String blockedUnblockBody(String name) {
    return 'Unblock $name?';
  }

  @override
  String blockedUnblockedSnack(String name) {
    return '$name has been unblocked.';
  }

  @override
  String get blockedUnblockFailed =>
      'Failed to unblock user. Please try again.';

  @override
  String aboutVersion(String version) {
    return 'Version $version';
  }

  @override
  String get aboutDescription =>
      'Trust-first dating app focused on authentic profiles, safe communication, and serious relationships.';

  @override
  String get aboutStack => 'Stack';

  @override
  String get aboutStackFlutter => 'Flutter (Android-first)';

  @override
  String get aboutStackGo => 'Go services + native PostgreSQL';

  @override
  String get aboutStackRiverpod => 'Riverpod state management';

  @override
  String get communitySpoiler => 'Spoiler — tap to reveal';

  @override
  String get communityReportFailed => 'Report could not be submitted.';

  @override
  String get communityReportSubmitted => 'Report submitted. Thank you.';

  @override
  String communityBlockTitle(String name) {
    return 'Block $name?';
  }

  @override
  String get communityBlockBody =>
      'You will stop seeing each other’s photos, club posts, reviews and lists. This also blocks contact through Connect.';

  @override
  String get communityBlockAction => 'Block member';

  @override
  String get communityBlockFailed =>
      'Could not block this member. Please retry.';

  @override
  String get reportSheetTitle => 'Report';

  @override
  String get reportReasonHarassment => 'Harassment';

  @override
  String get reportReasonInappropriate => 'Inappropriate content';

  @override
  String get reportReasonFraud => 'Fraud / scam';

  @override
  String get reportReasonFake => 'Fake profile';

  @override
  String get reportReasonLabel => 'Reason';

  @override
  String get reportDescriptionLabel => 'Description (optional)';

  @override
  String get reportDescriptionHint => 'Add context to help review your report';

  @override
  String get reportSubmitFailed => 'Failed to submit report. Please try again.';

  @override
  String get reportSubmit => 'Submit report';

  @override
  String get membershipTitle => 'Membership';

  @override
  String get membershipChooseYourPlan => 'Choose your plan';

  @override
  String get membershipCycleNoteMonthly =>
      'Pay by card. Renews automatically every month until you turn it off.';

  @override
  String get membershipCycleNoteYearly =>
      'Pay by card. Renews automatically every year until you turn it off.';

  @override
  String get membershipNoPlansOnSale => 'No plans are on sale right now.';

  @override
  String get membershipPaymentsTitle => 'Payments';

  @override
  String get membershipNoCardPayments => 'No card payments yet.';

  @override
  String get membershipFooterNote =>
      'Your plan renews automatically at the end of each billing period. Turn off auto-renew at any time; you keep your benefits until the period ends. Card details are handled by the payment provider and never stored in the app.';

  @override
  String membershipSwitchTitle(String plan) {
    return 'Switch to $plan?';
  }

  @override
  String membershipSwitchUpgradeBodyMonthly(String price) {
    return 'Your card is charged now for the difference for the rest of this period, then $price per month from the next renewal.';
  }

  @override
  String membershipSwitchUpgradeBodyYearly(String price) {
    return 'Your card is charged now for the difference for the rest of this period, then $price per year from the next renewal.';
  }

  @override
  String membershipSwitchDowngradeBodyMonthly(
    String currentPlan,
    String price,
  ) {
    return 'Your plan changes now. Unused time on $currentPlan is credited against your next renewal, then you pay $price per month.';
  }

  @override
  String membershipSwitchDowngradeBodyYearly(String currentPlan, String price) {
    return 'Your plan changes now. Unused time on $currentPlan is credited against your next renewal, then you pay $price per year.';
  }

  @override
  String get membershipNotNow => 'Not now';

  @override
  String get membershipUpgrade => 'Upgrade';

  @override
  String get membershipSwitchPlan => 'Switch plan';

  @override
  String membershipSwitchedSnack(String plan) {
    return 'You\'re on $plan now.';
  }

  @override
  String get membershipCardUpdated => 'Your card has been updated.';

  @override
  String get membershipCardUpdatePending =>
      'Card update not confirmed yet. Check its status before trying again.';

  @override
  String get membershipCardUpdateEnded =>
      'This card update session has ended. Refresh to see your current card.';

  @override
  String get membershipCheckoutTitleCard => 'your card';

  @override
  String get membershipAutoRenewOffTitle => 'Turn off auto-renew?';

  @override
  String membershipAutoRenewOffBodyDate(String plan, String date) {
    return 'Your $plan benefits stay active until $date. After that you move to the Free plan and your card is not charged again.';
  }

  @override
  String membershipAutoRenewOffBodyPeriodEnd(String plan) {
    return 'Your $plan benefits stay active until the end of the current period. After that you move to the Free plan and your card is not charged again.';
  }

  @override
  String get membershipKeepRenewing => 'Keep renewing';

  @override
  String get membershipTurnOff => 'Turn off';

  @override
  String get membershipAutoRenewBackOn => 'Auto-renew is back on.';

  @override
  String get membershipAutoRenewNowOff =>
      'Auto-renew is off. Your benefits continue until the period ends.';

  @override
  String membershipSubscribeTitle(String plan) {
    return 'Subscribe to $plan';
  }

  @override
  String membershipSubscribeBodyMonthly(String price) {
    return '$price per month, charged to your card and renewed automatically until you turn auto-renew off. You will enter your card on the payment provider\'s secure page.';
  }

  @override
  String membershipSubscribeBodyYearly(String price) {
    return '$price per year, charged to your card and renewed automatically until you turn auto-renew off. You will enter your card on the payment provider\'s secure page.';
  }

  @override
  String membershipSubscribeBodyTestMonthly(String price) {
    return 'Test checkout only — no real charge. $price per month, simulated and renewed automatically until you turn auto-renew off. You will enter your card on the payment provider\'s secure page.';
  }

  @override
  String membershipSubscribeBodyTestYearly(String price) {
    return 'Test checkout only — no real charge. $price per year, simulated and renewed automatically until you turn auto-renew off. You will enter your card on the payment provider\'s secure page.';
  }

  @override
  String get membershipContinueToCard => 'Continue to card';

  @override
  String get paymentStillConfirming =>
      'Payment is still being confirmed. Pull to refresh in a moment.';

  @override
  String get membershipCheckoutEnded =>
      'This checkout session has ended. Refresh your payment history before trying again.';

  @override
  String get membershipRecoverAccountUnavailable =>
      'Unable to check the payment account. Please retry.';

  @override
  String get membershipRecoverCheckoutClosed =>
      'Payment account refreshed. This checkout is no longer open.';

  @override
  String get membershipRecoverConfirmed =>
      'Confirmed. Your payment account is up to date.';

  @override
  String get membershipRecoverPending =>
      'Confirmation is still pending. You can check again here.';

  @override
  String get membershipRecoverEnded =>
      'This checkout session has ended. Review your payment history before starting another.';

  @override
  String membershipCelebrateTitle(String plan) {
    return 'You\'re $plan now';
  }

  @override
  String get membershipCelebrateBodyTest =>
      'Test payment confirmed; no real money was charged. Your test plan renews automatically. Manage auto-renew any time from this screen.';

  @override
  String get membershipCelebrateBody =>
      'Payment confirmed. Your plan renews automatically. Manage auto-renew any time from this screen.';

  @override
  String get membershipStartExploring => 'Start exploring';

  @override
  String get membershipYourMembership => 'Your membership';

  @override
  String get membershipYourPlan => 'Your plan';

  @override
  String get membershipFreePlanName => 'Free';

  @override
  String membershipPricePerMonthShort(String price) {
    return '$price/mo';
  }

  @override
  String membershipPricePerYearShort(String price) {
    return '$price/yr';
  }

  @override
  String get membershipCardOnFile => 'Card on file with the payment provider';

  @override
  String get membershipCardBrandFallback => 'Card';

  @override
  String get paymentOpening => 'Opening…';

  @override
  String get membershipUpdateCard => 'Update card';

  @override
  String get membershipLastPaymentFailed =>
      'Last payment failed. We will retry your card; benefits stay active for a few days.';

  @override
  String membershipRenewsOn(String date) {
    return 'Renews on $date';
  }

  @override
  String get membershipRenewsSoon => 'Renews soon';

  @override
  String membershipEndsOn(String date) {
    return 'Ends on $date · auto-renew is off';
  }

  @override
  String get membershipEndsSoon => 'Ends soon · auto-renew is off';

  @override
  String get membershipAutoRenew => 'Auto-renew';

  @override
  String get membershipAutoRenewOnSubtitle =>
      'Charged automatically each period.';

  @override
  String get membershipAutoRenewOffSubtitle =>
      'Off. Benefits end with the current period.';

  @override
  String get membershipFreeHeroBody =>
      'Unlock more likes, messages and spotlight with a plan below. Pay by card, cancel any time.';

  @override
  String get membershipStatusFree => 'Free';

  @override
  String get membershipStatusPaymentDue => 'Payment due';

  @override
  String get membershipStatusEnding => 'Ending';

  @override
  String get membershipStatusActive => 'Active';

  @override
  String get membershipCycleMonthly => 'Monthly';

  @override
  String get membershipCycleYearly => 'Yearly';

  @override
  String get membershipBadgeYourPlan => 'YOUR PLAN';

  @override
  String get membershipBadgeMostPopular => 'MOST POPULAR';

  @override
  String get membershipPerMonth => 'per month';

  @override
  String get membershipPerYear => 'per year';

  @override
  String membershipSavePercent(int percent) {
    return 'Save $percent%';
  }

  @override
  String membershipQuotaLikesPerDay(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count likes/day',
      one: '1 like/day',
    );
    return '$_temp0';
  }

  @override
  String membershipQuotaMessagesPerDay(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count messages/day',
      one: '1 message/day',
    );
    return '$_temp0';
  }

  @override
  String get membershipQuotaUnlimitedLikes => 'Unlimited likes';

  @override
  String get membershipQuotaUnlimitedMessages => 'Unlimited messages';

  @override
  String get membershipYourCurrentPlan => 'Your current plan';

  @override
  String get membershipSwitching => 'Switching…';

  @override
  String get membershipOpeningSecureCheckout => 'Opening secure checkout…';

  @override
  String membershipSwitchToPlan(String plan) {
    return 'Switch to $plan';
  }

  @override
  String get membershipSubscribeWithCard => 'Subscribe with card';

  @override
  String get membershipSettleBeforeSwitch =>
      'Settle the outstanding payment on your current plan before switching.';

  @override
  String get membershipPaymentChargeback => 'Chargeback';

  @override
  String get membershipPaymentDisputed => 'Disputed';

  @override
  String get membershipPaymentRefunded => 'Refunded';

  @override
  String get membershipPaymentPartlyRefunded => 'Partly refunded';

  @override
  String get membershipPaymentFailed => 'Failed';

  @override
  String get membershipPaymentPaid => 'Paid';

  @override
  String get membershipPaymentPending => 'Pending';

  @override
  String get membershipPaymentReasonFirstCharge => 'First charge';

  @override
  String get membershipPaymentReasonRenewal => 'Renewal';

  @override
  String get membershipPaymentReasonPlanChange => 'Plan change';

  @override
  String get membershipPaymentReasonCoins => 'Coins';

  @override
  String get membershipPaymentReasonLocalActivation => 'Local activation';

  @override
  String get membershipPaymentReasonCard => 'Card payment';

  @override
  String get membershipPaymentReasonOther => 'Payment';

  @override
  String get paymentModeSandbox => 'Local test · no real charge';

  @override
  String get paymentModeStripeTest => 'Stripe test · no real charge';

  @override
  String get paymentModeLive => 'Live payments';

  @override
  String get paymentModeUnavailable => 'Payments unavailable';

  @override
  String get paymentAccountTitle => 'Your payment account';

  @override
  String get paymentAccountSignedInMember => 'Signed-in member';

  @override
  String get paymentAccountCardTitle => 'Credit or debit card';

  @override
  String get paymentAccountCardUnavailableTitle =>
      'Card checkout is unavailable';

  @override
  String get paymentAccountCardBody =>
      'Use the hosted checkout to enter your card. Membership and payment history belong to this account.';

  @override
  String get paymentAccountCardUnavailableBody =>
      'You can keep using your existing account. New card payments are not enabled.';

  @override
  String paymentAccountTestCardHint(String cardNumber) {
    return 'For testing, use $cardNumber, a future expiry and any three-digit CVC. Use test details only.';
  }

  @override
  String get paymentAccountUnfinishedCardUpdate => 'Unfinished card update';

  @override
  String paymentAccountUnfinishedCheckout(String plan) {
    return 'Unfinished $plan checkout';
  }

  @override
  String get paymentAccountPendingHint =>
      'Check the latest status or continue the same checkout.';

  @override
  String get paymentAccountCheckStatus => 'Check status';

  @override
  String get paymentAccountResumeCheckout => 'Resume checkout';

  @override
  String paymentCheckoutPayFor(String title) {
    return 'Pay for $title';
  }

  @override
  String get paymentCheckoutClose => 'Close checkout';

  @override
  String get paymentCheckoutSecureNote =>
      'Card details are entered on the payment provider\'s secure page.';

  @override
  String paymentCheckoutCompleteInNewTab(String title) {
    return 'Complete the checkout for $title in the new tab';
  }

  @override
  String get paymentCheckoutWaitingBody =>
      'Your card details are entered on the payment provider\'s secure page. Come back here when it says the payment is complete.';

  @override
  String get paymentCheckoutCheckConfirmation => 'Check confirmation';

  @override
  String get paymentCheckoutBackToAccount => 'Back to account';

  @override
  String get paymentWalletTitle => 'Wallet & Payments';

  @override
  String get paymentWalletTestNote =>
      'Test payments · no real charge. Use test card details only.';

  @override
  String get paymentWalletPopularTopUps => 'Popular top-ups';

  @override
  String get paymentWalletTopUpsIntro =>
      'Pay by card on the secure checkout page. Coins land in your wallet as soon as the payment settles.';

  @override
  String get paymentWalletCardsDisabled =>
      'Card payments are not enabled on this server yet.';

  @override
  String get paymentWalletNoPacks => 'No coin packs are on sale right now.';

  @override
  String get paymentWalletActivity => 'Wallet activity';

  @override
  String get paymentWalletNoPurchases => 'No coin purchases yet.';

  @override
  String get paymentWalletFooter =>
      'Coins are used for gifts and boosts inside Connect. Purchases are final once settled; card details stay with the payment provider.';

  @override
  String paymentCoinCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count coins',
      one: '1 coin',
    );
    return '$_temp0';
  }

  @override
  String paymentCoinsAdded(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count coins added to your wallet.',
      one: '1 coin added to your wallet.',
    );
    return '$_temp0';
  }

  @override
  String paymentPackCoinsUnit(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'coins',
      one: 'coin',
    );
    return '$_temp0';
  }

  @override
  String paymentPackCoinsUnitBonus(int count, int bonus) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'coins · +$bonus bonus',
      one: 'coin · +$bonus bonus',
    );
    return '$_temp0';
  }

  @override
  String get paymentWalletCheckoutEnded =>
      'This checkout session has ended. Review your payment history before trying again.';

  @override
  String get paymentWalletBalanceLabel => 'Glow wallet balance';

  @override
  String get paymentWalletSourceSupport => 'Top-up from support';

  @override
  String get paymentWalletSourcePromo => 'Promotion';

  @override
  String get paymentWalletSourcePurchase => 'Coin purchase';

  @override
  String get paymentErrorSignInSubscriptions =>
      'Please sign in to manage subscriptions.';

  @override
  String get paymentErrorSignInWallet =>
      'Please sign in to manage your wallet.';

  @override
  String get paymentErrorLoadSubscription =>
      'Unable to load subscription details.';

  @override
  String get paymentErrorLoadWallet => 'Unable to load your wallet.';

  @override
  String get paymentErrorStartCheckoutNow =>
      'Unable to start checkout right now.';

  @override
  String get paymentErrorStartCheckout => 'Unable to start checkout.';

  @override
  String get paymentErrorConfirmPayment => 'Unable to confirm the payment yet.';

  @override
  String get paymentErrorAutoRenewOn => 'Unable to turn auto-renew back on.';

  @override
  String get paymentErrorAutoRenewOff => 'Unable to turn off auto-renew.';

  @override
  String get paymentErrorChangePlan => 'Unable to change plan.';

  @override
  String get paymentErrorUpdateCard => 'Unable to update the card.';

  @override
  String get paymentErrorSandboxFailed => 'Sandbox simulation failed.';

  @override
  String get paymentErrorUnreachable =>
      'Cannot reach the local service. Check that the API is running.';

  @override
  String membershipQuotaLikesLeftToday(int remaining, int limit) {
    String _temp0 = intl.Intl.pluralLogic(
      limit,
      locale: localeName,
      other: '$remaining of $limit likes left today',
      one: '$remaining of 1 like left today',
    );
    return '$_temp0';
  }

  @override
  String membershipQuotaMessagesLeftToday(int remaining, int limit) {
    String _temp0 = intl.Intl.pluralLogic(
      limit,
      locale: localeName,
      other: '$remaining of $limit messages left today',
      one: '$remaining of 1 message left today',
    );
    return '$_temp0';
  }

  @override
  String membershipLikeLimitHeadline(int limit, String plan) {
    String _temp0 = intl.Intl.pluralLogic(
      limit,
      locale: localeName,
      other: 'You\'ve used today\'s $limit likes on $plan',
      one: 'You\'ve used today\'s 1 like on $plan',
    );
    return '$_temp0';
  }

  @override
  String membershipMessageLimitHeadline(int limit, String plan) {
    String _temp0 = intl.Intl.pluralLogic(
      limit,
      locale: localeName,
      other: 'You\'ve used today\'s $limit messages on $plan',
      one: 'You\'ve used today\'s 1 message on $plan',
    );
    return '$_temp0';
  }

  @override
  String membershipQuotaResetsAt(String time) {
    return 'Resets at $time';
  }

  @override
  String matchesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count matches',
      one: '$count match',
    );
    return '$_temp0';
  }

  @override
  String get matchesSubtitleConversations =>
      'A little closer, one message at a time.';

  @override
  String get matchesSubtitlePeople =>
      'People you chose. Possibilities you shape together.';

  @override
  String get matchesSearchConversations => 'Search conversations';

  @override
  String get matchesSearchMatches => 'Search your matches';

  @override
  String get matchesFilterAllConversations => 'All conversations';

  @override
  String matchesFilterUnread(int count) {
    return 'Unread · $count';
  }

  @override
  String get matchesLoading => 'Loading matches...';

  @override
  String get matchesLoadErrorTitle => 'Unable to load matches';

  @override
  String get matchesRetry => 'Retry';

  @override
  String get matchesEmptyTitle => 'No matches yet';

  @override
  String matchesTrustFilteredHint(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Trust filters hid $count match(es). Try relaxing trust filters from Discover.',
    );
    return '$_temp0';
  }

  @override
  String get matchesEmptyBody =>
      'Visit Today to discover someone you’d like to meet.';

  @override
  String get matchesNoConversationResults =>
      'No conversations here yet. Try another search or filter.';

  @override
  String get matchesNoPeopleResults => 'No matches found. Try another name.';

  @override
  String get matchesTabPeople => 'Your matches';

  @override
  String get matchesTabConversations => 'Conversations';

  @override
  String get matchesActionStartCall => 'Start call session';

  @override
  String get matchesActionStartActivity => 'Start an activity';

  @override
  String get matchesActionPlanDate => 'Plan a date';

  @override
  String get matchesActionPlanDateSubtitle =>
      'Choose a time and what you want to share';

  @override
  String matchesPlanSent(String name) {
    return 'Plan sent to $name.';
  }

  @override
  String get matchesActionGraduate => 'We found each other';

  @override
  String get matchesActionGraduateSubtitle =>
      'Leave Connect together; your chat stays';

  @override
  String matchesGraduationAsked(String name) {
    return 'Asked $name to leave together. They can confirm from your chat.';
  }

  @override
  String get matchesActionNudge => 'Send a nudge';

  @override
  String matchesNudgeSent(String name) {
    return 'Nudge sent to $name.';
  }

  @override
  String get matchesNudgeFailed => 'Unable to send this nudge.';

  @override
  String get matchesActionClose => 'Close conversation';

  @override
  String get matchesActionCloseSubtitle =>
      'Make space, without an explanation.';

  @override
  String get matchesCloseDialogTitle => 'Close this conversation?';

  @override
  String get matchesCloseDialogBody =>
      'It is okay if this connection is not for you. This ends the match. You do not need to send an explanation. Reporting remains a separate choice.';

  @override
  String get matchesCloseDialogKeep => 'Keep talking';

  @override
  String get matchesActionReport => 'Report';

  @override
  String get matchesReportSubmitted => 'Report submitted. Thank you.';

  @override
  String get matchesReportAppeal => 'Appeal';

  @override
  String matchesAppealReason(String userId) {
    return 'Review moderation outcome for report on user $userId';
  }

  @override
  String get matchesBothChose => 'You both chose to connect';

  @override
  String matchesOptionsTooltip(String name) {
    return 'Match options for $name';
  }

  @override
  String matchesChatUnread(int count) {
    return 'Chat · $count unread';
  }

  @override
  String get matchesOpenChat => 'Open chat';

  @override
  String get matchesFirstChapter => 'First Chapter';

  @override
  String get matchesUnknownName => 'Unknown';

  @override
  String get matchesSayHi => 'Say hi 👋';

  @override
  String get matchesFallbackName => 'Your match';

  @override
  String get matchesFallbackMessage => 'Start your conversation';

  @override
  String get matchesGiftPreview => 'A little gift in your conversation';

  @override
  String matchesConversationOptionsTooltip(String name) {
    return 'Conversation options for $name';
  }

  @override
  String get matchesTimeNow => 'Now';

  @override
  String matchesTimeMinutesAgo(int minutes) {
    return '${minutes}m ago';
  }

  @override
  String matchesTimeHoursAgo(int hours) {
    return '${hours}h ago';
  }

  @override
  String get matchesTimeToday => 'Today';

  @override
  String get matchesTimeYesterday => 'Yesterday';

  @override
  String get matchesNewMatchTitle => 'New Match';

  @override
  String get matchesItsAMatch => 'It\'s a match!';

  @override
  String matchesLikedEachOther(String name) {
    return 'You and $name liked each other';
  }

  @override
  String get matchesSendMessage => 'Send Message';

  @override
  String get matchesKeepSwiping => 'Keep Swiping';

  @override
  String get matchesErrorLoginRequired => 'Please log in to see matches.';

  @override
  String get matchesErrorLoadFailed =>
      'Failed to load matches. Please try again.';

  @override
  String get matchesErrorUnmatchFailed => 'Failed to unmatch.';

  @override
  String get matchesErrorMarkReadFailed => 'Failed to mark as read.';

  @override
  String get matchesErrorSessionUnavailable => 'User session not available.';

  @override
  String get matchesTrustBadgePromptCompleter => 'Prompt Completer';

  @override
  String get matchesTrustBadgeRespectful => 'Respectful Communicator';

  @override
  String get matchesTrustBadgeConsistent => 'Consistent Profile';

  @override
  String get matchesTrustBadgeVerifiedActive => 'Verified & Active';

  @override
  String get matchesTrustErrorLoad =>
      'Failed to load trust filters. Please try again.';

  @override
  String get matchesTrustErrorSave =>
      'Failed to save trust filters. Please try again.';

  @override
  String get matchesGestureErrorLoad => 'Failed to load timeline';

  @override
  String get matchesGestureErrorPending =>
      'Gestures unlock after this pending conversation becomes a real match.';

  @override
  String get matchesGestureErrorSend => 'Failed to send gesture.';

  @override
  String get matchesGestureErrorUpdate => 'Failed to update gesture status.';

  @override
  String get matchesActivityTitle => '2-Minute This-or-That';

  @override
  String get matchesActivityRestartTooltip => 'Start a new session';

  @override
  String matchesActivityCompleteWith(String name) {
    return 'Complete this with $name';
  }

  @override
  String get matchesActivityInstructions =>
      'Answer all 8 rounds before time ends.';

  @override
  String matchesActivityStatus(String status) {
    return 'Status: $status';
  }

  @override
  String get matchesActivityStatusActive => 'active';

  @override
  String get matchesActivityStatusTimedOut => 'timed out';

  @override
  String get matchesActivityStatusPartialTimeout => 'partial timeout';

  @override
  String get matchesActivityStatusCompleted => 'completed';

  @override
  String get matchesActivitySubmit => 'Submit Responses';

  @override
  String get matchesActivityTimeUpLoad => 'Time is up — Load Summary';

  @override
  String get matchesActivityWaiting =>
      'Responses sent. Waiting for the other participant to finish.';

  @override
  String get matchesActivityRefreshSummary => 'Refresh Summary';

  @override
  String matchesActivityTimeLeft(String time) {
    return 'Time left $time';
  }

  @override
  String get matchesActivitySummaryTitle => 'Activity Summary';

  @override
  String matchesActivityParticipantsCompleted(int completed, int total) {
    return 'Participants completed: $completed/$total';
  }

  @override
  String get matchesActivitySummaryPending =>
      'Summary will appear once available.';

  @override
  String get matchesActivityShareResult => 'Share Result to Chat';

  @override
  String matchesActivityShareMessage(String status, int completed, int total) {
    return '2-Min This-or-That result: $status • $completed/$total completed';
  }

  @override
  String matchesActivityShareMessageWithInsight(
    String status,
    int completed,
    int total,
    String insight,
  ) {
    return '2-Min This-or-That result: $status • $completed/$total completed • $insight';
  }

  @override
  String matchesActivityRound(int number) {
    return 'Round $number';
  }

  @override
  String get matchesActivityErrorStart =>
      'Unable to start activity right now. Please try again.';

  @override
  String get matchesActivityErrorNotReady => 'Session is not ready yet.';

  @override
  String get matchesActivityErrorAnswerAll =>
      'Please answer all prompts before submitting.';

  @override
  String get matchesActivityErrorTimeUp =>
      'Time is up. Loading activity summary...';

  @override
  String get matchesActivityErrorSubmit =>
      'Failed to submit activity responses. Please try again.';

  @override
  String get matchesActivityErrorSummary =>
      'Unable to fetch summary yet. Please try again.';

  @override
  String get matchesActivityQ1Prompt => 'Ideal first meetup?';

  @override
  String get matchesActivityQ1OptionA => 'Coffee walk';

  @override
  String get matchesActivityQ1OptionB => 'Bookstore browse';

  @override
  String get matchesActivityQ2Prompt => 'Preferred weekend mood?';

  @override
  String get matchesActivityQ2OptionA => 'Stay in and recharge';

  @override
  String get matchesActivityQ2OptionB => 'Explore the city';

  @override
  String get matchesActivityQ3Prompt => 'Best conversation setting?';

  @override
  String get matchesActivityQ3OptionA => 'Long walk';

  @override
  String get matchesActivityQ3OptionB => 'Cosy cafe corner';

  @override
  String get matchesActivityQ4Prompt => 'How do you plan dates?';

  @override
  String get matchesActivityQ4OptionA => 'Spontaneous';

  @override
  String get matchesActivityQ4OptionB => 'Planned in advance';

  @override
  String get matchesActivityQ5Prompt => 'Which matters more right now?';

  @override
  String get matchesActivityQ5OptionA => 'Consistency';

  @override
  String get matchesActivityQ5OptionB => 'Excitement';

  @override
  String get matchesActivityQ6Prompt => 'Conflict style preference?';

  @override
  String get matchesActivityQ6OptionA => 'Resolve same day';

  @override
  String get matchesActivityQ6OptionB => 'Take space then revisit';

  @override
  String get matchesActivityQ7Prompt => 'Shared activity pick?';

  @override
  String get matchesActivityQ7OptionA => 'Cook together';

  @override
  String get matchesActivityQ7OptionB => 'Workout together';

  @override
  String get matchesActivityQ8Prompt => 'Pace preference?';

  @override
  String get matchesActivityQ8OptionA => 'Steady and intentional';

  @override
  String get matchesActivityQ8OptionB => 'Fast and energetic';

  @override
  String get cityPilotSaveFailed =>
      'We couldn’t confirm that change. Refresh to check before trying again.';

  @override
  String get cityPilotLeaveTitle => 'Leave the city pilot?';

  @override
  String get cityPilotLeaveBody =>
      'Your pilot bookings will be cancelled and experience feedback removed. Your activity will stop contributing to current pilot results. Your matches and conversations stay. You cannot rejoin this pilot.';

  @override
  String get cityPilotStay => 'Stay in pilot';

  @override
  String get cityPilotLeave => 'Leave pilot';

  @override
  String get cityPilotLeftNotice =>
      'You have left the pilot. Your matches stay with you.';

  @override
  String cityPilotJoinEventTitle(String title) {
    return 'Join $title?';
  }

  @override
  String cityPilotBookingTerms(
    String host,
    String safetyContact,
    String accessibility,
  ) {
    return 'This experience is free. Meet at the public venue, respect other people’s boundaries, and arrange your own travel. You can leave at any time.\n\nHost: $host\nSafety contact: $safetyContact\n\nAccessibility: $accessibility\n\nFor immediate danger, contact local emergency services.';
  }

  @override
  String get cityPilotAcceptReserve => 'Accept & reserve a place';

  @override
  String get cityPilotReservedNotice =>
      'Your place is reserved. You can cancel here at any time.';

  @override
  String get cityPilotFeedbackTitle => 'How was the experience?';

  @override
  String get cityPilotFeedbackIntro =>
      'Optional. Answers contribute to the pilot’s combined results. They aren’t shown to other members or the host.';

  @override
  String get cityPilotDidYouAttend => 'Did you attend?';

  @override
  String get cityPilotAttendedYes => 'Yes, I went';

  @override
  String get cityPilotAttendedNo => 'I couldn’t make it';

  @override
  String get cityPilotWorthwhileQuestion =>
      'Was it worth your time? (optional)';

  @override
  String get cityPilotNotThisTime => 'Not this time';

  @override
  String get cityPilotSkip => 'Skip';

  @override
  String get cityPilotShareFeedback => 'Share feedback';

  @override
  String get cityPilotFeedbackThanks =>
      'Thank you. Your feedback has been recorded privately.';

  @override
  String get cityPilotTimeTbc => 'Time to be confirmed';

  @override
  String get cityPilotTitle => 'The city pilot';

  @override
  String get cityPilotRefreshTooltip => 'Refresh pilot';

  @override
  String get cityPilotHeroTitle => 'A little closer.\nA lot more real.';

  @override
  String get cityPilotHeroBody =>
      'One city. A small community. More chances for a conversation to become a plan.';

  @override
  String get cityPilotStep1Title => 'Start with a conversation';

  @override
  String get cityPilotStep1Body =>
      'Meet at your pace through your existing introductions.';

  @override
  String get cityPilotStep2Title => 'Make room for a real date';

  @override
  String get cityPilotStep2Body =>
      'Shape a plan together. Share how it went only if you want to.';

  @override
  String get cityPilotStep3Title => 'Try something together';

  @override
  String get cityPilotStep3Body =>
      'Small, hosted experiences come after the first pilot review.';

  @override
  String get cityPilotSaving => 'Saving pilot preference';

  @override
  String get cityPilotUnavailableTitle => 'Your pilot is unavailable';

  @override
  String get cityPilotUnavailableBody =>
      'Check your connection and refresh to see your latest participation and bookings.';

  @override
  String get cityPilotComingSoonTitle => 'Coming to a city near you';

  @override
  String get cityPilotComingSoonBody =>
      'There isn’t an open pilot for your profile city yet. When one opens, you can choose whether to take part. Your current dating experience carries on as usual.';

  @override
  String cityPilotPanelTitleJoined(String city) {
    return '$city · You’re part of it';
  }

  @override
  String cityPilotPanelTitleOpen(String city) {
    return '$city · City pilot';
  }

  @override
  String cityPilotRecruitmentCloses(String date) {
    return 'Recruitment closes $date (your local time).';
  }

  @override
  String get cityPilotPaused =>
      'New participation and bookings are paused. You can still leave or cancel.';

  @override
  String get cityPilotCompleted =>
      'This pilot is complete. Thank you for being part of it.';

  @override
  String get cityPilotMeasurement =>
      'Joining lets us count conversations, accepted plans and optional “did the date happen?” answers for new matches where both people joined this pilot. We use 7-day conversation and 28-day date windows. We don’t read message text or private feedback notes for the pilot.';

  @override
  String get cityPilotPrivacy =>
      'Participation stays private. There’s no public attendance list or dating score. Leaving excludes your activity from current pilot results and cancels pilot bookings. Previously reviewed combined results cannot be un-seen.';

  @override
  String get cityPilotConsent =>
      'I agree to take part in this pilot and its outcome measurement.';

  @override
  String get cityPilotJoinedNotice =>
      'You’re in. Keep meeting people at your own pace.';

  @override
  String get cityPilotJoin => 'Join the city pilot';

  @override
  String get cityPilotWithdrawn =>
      'You’ve left this pilot. Your matches and conversations are unchanged.';

  @override
  String get cityPilotNotAccepting =>
      'This pilot is not accepting new members right now.';

  @override
  String get cityPilotExperiencesHeading => 'Small plans. Shared experiences.';

  @override
  String get cityPilotNoExperiences =>
      'Hosted experiences aren’t open yet. They’ll appear here after an outcome and safety review.';

  @override
  String cityPilotEventDetails(
    String start,
    String end,
    String venue,
    String host,
  ) {
    return '$start → $end\nYour local time · Free\n$venue\nHosted by $host';
  }

  @override
  String cityPilotAccessibility(String details) {
    return 'Accessibility · $details';
  }

  @override
  String cityPilotSafetyContact(String contact) {
    return 'Safety contact · $contact';
  }

  @override
  String get cityPilotEventCancelled =>
      'This experience has been cancelled. Please do not travel to the venue.';

  @override
  String get cityPilotPlaceReserved => 'Your place is reserved.';

  @override
  String get cityPilotBookingCancelled => 'Your booking is cancelled.';

  @override
  String get cityPilotCancelPlace => 'Cancel my place';

  @override
  String get cityPilotReserveFree => 'Reserve a free place';

  @override
  String get cityPilotShareOptionalFeedback => 'Share optional feedback';

  @override
  String get cityPilotFeedbackReceived =>
      'Your feedback has been received. Thank you.';

  @override
  String get blogAudiencePrivate => 'Only me';

  @override
  String get blogAudienceFriends => 'Friends';

  @override
  String get blogAudienceCommunity => 'Connect community';

  @override
  String get blogInvitationNone => 'No invitation';

  @override
  String get blogInvitationYourVersion => 'What would your version look like?';

  @override
  String get blogInvitationTeachMe => 'What could you teach me about this?';

  @override
  String get blogInvitationWhatNext => 'What would you try next?';

  @override
  String get blogRewardStoryPublishedTitle => 'Sharing a chapter';

  @override
  String get blogRewardStoryPublishedWho =>
      'You, the first time a chapter is shared beyond Only me';

  @override
  String get blogRewardPhotoSharedTitle => 'Sharing a Photo Themes photo';

  @override
  String get blogRewardPhotoSharedWho =>
      'You, for a photo you share in Photo Themes';

  @override
  String get blogRewardLikeReceivedTitle => 'A like on your chapter or photo';

  @override
  String get blogRewardLikeReceivedWho => 'You, for each member who likes it';

  @override
  String get blogRewardCommentReceivedTitle => 'A comment you approve';

  @override
  String get blogRewardCommentReceivedWho =>
      'You, when you approve a reader’s comment';

  @override
  String get blogRewardCommentApprovedTitle => 'Your comment is approved';

  @override
  String get blogRewardCommentApprovedWho =>
      'You, when an author approves your comment';

  @override
  String get blogRewardSubscriberGainedTitle => 'A new follower';

  @override
  String get blogRewardSubscriberGainedWho =>
      'You, for each new member who follows your chapters';

  @override
  String get blogRewardWallTierTitle => 'Reaching more walls';

  @override
  String get blogRewardWallTierWho =>
      'You, each time a chapter reaches a new wall tier';

  @override
  String get blogRewardCoverOfWeekTitle => 'Cover of the Week';

  @override
  String get blogRewardCoverOfWeekWho =>
      'You, when your work is chosen as Cover of the Week';

  @override
  String get blogScopeForYou => 'For you';

  @override
  String get blogScopeTopRated => 'Top rated';

  @override
  String get blogScopeFollowing => 'Following';

  @override
  String get blogScopeMine => 'Mine';

  @override
  String get blogScopeCaptionMine =>
      'Your drafts and published chapters. You choose the audience for each one.';

  @override
  String get blogScopeCaptionFriends =>
      'Chapters shared by your accepted Connect friends.';

  @override
  String get blogScopeCaptionTop =>
      'Ranked by likes, approved comments and readers, from the last 30 days.';

  @override
  String get blogScopeCaptionFollowing =>
      'The newest chapters from writers you follow.';

  @override
  String get blogScopeCaptionCommunity =>
      'For eligible, signed-in Connect members. These chapters are not public on the web.';

  @override
  String get blogTitle => 'Open Chapters';

  @override
  String get blogRewardsTitle => 'How rewards work';

  @override
  String get blogWritersTitle => 'Writers you follow';

  @override
  String get blogConnectionsTooltip => 'Private responses, sharing and notices';

  @override
  String get blogSignInReadWrite => 'Sign in to read and write chapters.';

  @override
  String get blogHeroTitle => 'A life worth\ngetting to know.';

  @override
  String get blogHeroBody =>
      'The story behind a photo. A small obsession. Something you’re still learning. Let your everyday life do the talking.';

  @override
  String get blogWriteChapter => 'Write a chapter';

  @override
  String get blogPrivateResponses => 'Private responses';

  @override
  String get blogSharedLinks => 'Shared links';

  @override
  String get blogReviewNotices => 'Review notices';

  @override
  String get blogTopicAll => 'All';

  @override
  String get blogFeedLoadFailed => 'Chapters could not load.';

  @override
  String get blogPreviousPage => 'Previous page';

  @override
  String get blogMoreChapters => 'More chapters';

  @override
  String get blogEmptyMineTitle => 'Your next chapter starts here.';

  @override
  String get blogEmptyMineBody =>
      'Start with a moment you would love someone to ask about. Your first draft is only for you.';

  @override
  String get blogEmptyTopTitle => 'When chapters move people, they rise here.';

  @override
  String get blogEmptyTopFilteredBody =>
      'Nothing has risen in this topic yet. Try All, or share a chapter of your own.';

  @override
  String get blogEmptyTopBody =>
      'Chapters readers love from the last 30 days will appear here.';

  @override
  String get blogEmptyFollowingFilteredTitle =>
      'Nothing new in this topic yet.';

  @override
  String get blogEmptyFollowingTitle => 'Writers you follow will appear here.';

  @override
  String get blogEmptyFollowingBody =>
      'When a chapter speaks to you, open it and tap Follow their chapters. Their new chapters will gather here, so you never miss what they share next.';

  @override
  String get blogEmptyCommunityTitle => 'A little quiet here, for now.';

  @override
  String get blogEmptyCommunityBody =>
      'Chapters appear here when members choose to share with this audience.';

  @override
  String get blogFindWritersTopRated => 'Find writers in Top rated';

  @override
  String blogRankTooltip(int rank) {
    return 'Number $rank in Top rated';
  }

  @override
  String get blogUntitled => 'An untitled chapter';

  @override
  String get blogDraftPlaceholder => 'A private draft, waiting for your words.';

  @override
  String get blogReadEdit => 'Read & edit →';

  @override
  String get blogReadChapter => 'Read chapter →';

  @override
  String get blogPhotoUnavailableRetry => 'Photo unavailable · Retry';

  @override
  String get blogTryAgain => 'Try again';

  @override
  String get blogDetailTitle => 'A chapter';

  @override
  String get blogSignInRead => 'Sign in to read chapters.';

  @override
  String get blogDetailUnavailable =>
      'This chapter is unavailable or its audience has changed.';

  @override
  String get blogRespondPrivately => 'Respond privately';

  @override
  String get blogCreatePublicPreview => 'Create a public preview';

  @override
  String get blogRemovedByModerationNote =>
      'Removed by moderation. Open Review notices to read the decision or request another review.';

  @override
  String get blogEditChapter => 'Edit chapter';

  @override
  String get blogDeleteChapter => 'Delete chapter';

  @override
  String get blogDeleteChapterTitle => 'Delete this chapter?';

  @override
  String get blogDeleteChapterMessage =>
      'It will disappear from all audiences. This cannot be undone.';

  @override
  String get blogDeleteChapterFailed =>
      'Could not confirm deletion. Reload the chapter before retrying.';

  @override
  String get blogReportChapter => 'Report chapter';

  @override
  String get blogReportFailed => 'Report could not be submitted.';

  @override
  String get blogBlockThisMember => 'Block this member';

  @override
  String get blogBlockTitle => 'Block this member?';

  @override
  String get blogBlockMessageChapter =>
      'You will no longer see each other’s chapters. This also blocks contact through Connect.';

  @override
  String get blogBlockMember => 'Block member';

  @override
  String get blogBlockRetryFailed =>
      'Could not block this member. Please retry.';

  @override
  String get blogCancel => 'Cancel';

  @override
  String get blogEditorMissingFields =>
      'Add a title and story before publishing.';

  @override
  String blogPublishConfirmTitle(String audience) {
    String _temp0 = intl.Intl.selectLogic(audience, {
      'private': 'Publish to Only me?',
      'friends': 'Publish to Friends?',
      'community': 'Publish to Connect community?',
      'other': 'Publish?',
    });
    return '$_temp0';
  }

  @override
  String get blogPublishFriendsBody =>
      'Your accepted Connect friends can read the words and photos in this chapter. You can change the audience later.';

  @override
  String get blogPublishCommunityBody =>
      'Eligible, signed-in Connect members can read this chapter. It will not appear on the public web. You can change the audience later.';

  @override
  String get blogPublishChapter => 'Publish chapter';

  @override
  String get blogSavedOnlyMe => 'Saved. Only you can read this chapter.';

  @override
  String blogPublishedTo(String audience) {
    String _temp0 = intl.Intl.selectLogic(audience, {
      'private': 'Published to Only me.',
      'friends': 'Published to Friends.',
      'community': 'Published to Connect community.',
      'other': 'Published.',
    });
    return '$_temp0';
  }

  @override
  String get blogSharedSnack =>
      'Shared. Readers’ likes and comments earn you XP.';

  @override
  String get blogSeeMyLevel => 'See my level';

  @override
  String get blogSaveUnconfirmed => 'We could not confirm the save.';

  @override
  String blogEditsStillHere(String message) {
    return '$message Your edits are still here. Check the saved version before continuing.';
  }

  @override
  String blogSavedVersionTitle(String audience) {
    return 'Saved version · $audience';
  }

  @override
  String get blogSavedVersionNote =>
      'Your current edits remain in the editor. Close this sheet to keep them, or replace them with this saved version.';

  @override
  String get blogKeepMyEdits => 'Keep my edits for the next save';

  @override
  String get blogUseSavedVersion => 'Use saved version';

  @override
  String get blogSavedVersionLoadFailed =>
      'The saved version could not load. Your edits remain here.';

  @override
  String get blogDescribePhotoTitle => 'Describe your photo';

  @override
  String get blogDescribePhotoBody =>
      'A short description makes your chapter accessible. Adding the photo saves your words as an Only me draft.';

  @override
  String get blogDescribePhotoLabel => 'What is in this photo?';

  @override
  String get blogAddToPrivateDraft => 'Add to private draft';

  @override
  String get blogPhotoAdded => 'Photo added to your private draft.';

  @override
  String get blogPhotoAddFailed =>
      'The photo could not be added. Use a JPEG or PNG up to 10 MB.';

  @override
  String blogCheckSavedBeforeRetrying(String message) {
    return '$message Check the saved version before retrying.';
  }

  @override
  String get blogRemoveUnconfirmed =>
      'Could not confirm removal. Check the saved version.';

  @override
  String get blogSignInAsAuthor =>
      'Sign in as the author to edit this chapter.';

  @override
  String get blogLeaveEditorTitle => 'Leave without saving?';

  @override
  String get blogLeaveEditorMessage =>
      'Your unsaved edits will be lost. Your last saved chapter will remain.';

  @override
  String get blogLeaveEditor => 'Leave editor';

  @override
  String get blogEditorPreviewTitle => 'Chapter preview';

  @override
  String get blogEditorTitle => 'Your next chapter';

  @override
  String get blogEditorHeadline => 'A little more you.';

  @override
  String get blogEditorIntro =>
      'Small stories are welcome. A meal you made. A place that changed your mind. The photo with a story behind it.';

  @override
  String get blogNotSavedDefault => 'Not saved · Only me by default';

  @override
  String blogSavedFor(String audience) {
    String _temp0 = intl.Intl.selectLogic(audience, {
      'private': 'Saved for Only me',
      'friends': 'Saved for Friends',
      'community': 'Saved for Connect community',
      'other': 'Saved',
    });
    return '$_temp0';
  }

  @override
  String get blogKeepWriting => 'Keep writing';

  @override
  String get blogPreview => 'Preview';

  @override
  String get blogCheckSavedVersion => 'Check saved version';

  @override
  String blogPreviewNotSaved(String audience) {
    return 'Preview · $audience · Not yet saved';
  }

  @override
  String get blogStoryPlaceholder => 'Your story will appear here.';

  @override
  String get blogChapterTitleLabel => 'Chapter title';

  @override
  String get blogChapterTitleHint => 'The Sunday I learned to slow down';

  @override
  String get blogStoryLabel => 'Your story';

  @override
  String get blogStoryHint => 'Start anywhere. Make it yours.';

  @override
  String get blogInvitationLabel => 'End with an invitation (optional)';

  @override
  String get blogInvitationHelp =>
      'Leave a question that helps someone get to know you.';

  @override
  String get blogRemovePhoto => 'Remove photo';

  @override
  String get blogAddPhoto => 'Add a photo';

  @override
  String get blogPhotoRules =>
      'Up to 6 JPEG or PNG photos, 10 MB each. Photos need approval. Save as Only me before changing photos on a published chapter.';

  @override
  String get blogWhoFor => 'Who is this chapter for?';

  @override
  String get blogAudiencePrivateHelp =>
      'Only you can read this chapter. Friends and matches cannot see it.';

  @override
  String get blogAudienceFriendsHelp =>
      'Only accepted Connect friends can read it. A match alone does not give access.';

  @override
  String get blogAudienceCommunityHelp =>
      'Eligible signed-in members can read it. Complete your profile with two approved profile photos to publish here. This is not public web sharing.';

  @override
  String get blogAllowFeaturing => 'Allow featuring';

  @override
  String get blogAllowFeaturingHelp =>
      'If readers love it, your chapter can reach other members’ walls: 50 likes and 5 comments reach 50 walls, 100 likes and 10 comments reach 100. You can turn this off any time.';

  @override
  String get blogSaveOnlyForMe => 'Save only for me';

  @override
  String blogPublishTo(String audience) {
    String _temp0 = intl.Intl.selectLogic(audience, {
      'private': 'Publish to Only me',
      'friends': 'Publish to Friends',
      'community': 'Publish to Connect community',
      'other': 'Publish',
    });
    return '$_temp0';
  }

  @override
  String get blogSaveAsOnlyMe => 'Save as Only me';

  @override
  String get blogSaveNote =>
      'Your words are saved when you choose Save or Publish. Preview does not publish anything.';

  @override
  String get blogTopicOptional => 'Topic (optional)';

  @override
  String get blogTopicHelp =>
      'Help readers who care about this find your chapter.';

  @override
  String get webDestBlog => 'Blog';

  @override
  String get webDestFirstChapter => 'First Chapter Studio';

  @override
  String get webDestDatingPreferences => 'Dating preferences';

  @override
  String get webDestEditProfile => 'Edit profile';

  @override
  String get webDestProfilePhotos => 'Profile photos';

  @override
  String get webDestLikedYou => 'Liked you';

  @override
  String get webDestNotifications => 'Notifications';

  @override
  String get webDestDailyPrompt => 'Daily prompt';

  @override
  String get webDestLevels => 'Levels & progress';

  @override
  String get webDestTrustBadges => 'Trust badges';

  @override
  String get webDestTrustFilters => 'Trust filters';

  @override
  String get webDestIcebreakers => 'Icebreakers';

  @override
  String get webDestCircleChallenges => 'Circle challenges';

  @override
  String get webDestCoffeePolls => 'Coffee polls';

  @override
  String get webDestGroups => 'Groups';

  @override
  String get webDestRooms => 'Conversation rooms';

  @override
  String get webDestMatchNudges => 'Match nudges';

  @override
  String get webDestFriends => 'Friends';

  @override
  String get webDestDatePlans => 'Date plans';

  @override
  String get webDestCallHistory => 'Call history';

  @override
  String get webDestMembership => 'Membership';

  @override
  String get webDestVerification => 'Verification';

  @override
  String get webDestPrivacySafety => 'Privacy & safety';

  @override
  String get webDestAccountData => 'Account & data';

  @override
  String get webDestBlockedMembers => 'Blocked members';

  @override
  String get webDestEmergencyContacts => 'Emergency contacts';

  @override
  String get webDestModerationAppeals => 'Moderation appeals';

  @override
  String get webDestNotificationPreferences => 'Notification preferences';

  @override
  String get webDestHelpSupport => 'Help & support';

  @override
  String get webNavExplore => 'Explore';

  @override
  String get webNavMyProfile => 'My profile';

  @override
  String get webNavAllFeatures => 'All features';

  @override
  String get webNavMoreForYou => 'More for you';

  @override
  String get webNavPreferences => 'Preferences';

  @override
  String get webNavWebsite => 'Connect website';

  @override
  String get webNavSignOut => 'Sign out';

  @override
  String get webPageNotFound => 'This page could not be found.';

  @override
  String get webBackToDiscover => 'Back to Discover';

  @override
  String get webTagline => 'Your pace. Your choice.';

  @override
  String webUnavailableTitle(String label) {
    return '$label isn\'t available yet.';
  }

  @override
  String get webUnavailableBody => 'It isn\'t part of this release of Connect.';

  @override
  String get webDirectoryTitle => 'Make this space yours.';

  @override
  String get webDirectorySubtitle =>
      'Your profile, conversations, community and controls — all in one place.';

  @override
  String get webIcebreakerTitle => 'Conversation starters';

  @override
  String get webIcebreakerHeadline =>
      'A little inspiration for your next hello.';

  @override
  String get webIcebreakerBody =>
      'Voice recording and playback are not available yet. You can use these prompts in an eligible conversation.';

  @override
  String get webIcebreakerOpenMatches => 'Open my matches';

  @override
  String get webMembershipHeadline => 'A little more possibility.';

  @override
  String get webMembershipIntro =>
      'Explore the current plans. Browser checkout is not available yet. No purchase or charge can be made from this page.';

  @override
  String webMembershipCurrent(String plan) {
    return 'Your membership: $plan';
  }

  @override
  String webMembershipStatus(String status) {
    return 'Status: $status';
  }

  @override
  String get webMembershipMonthly => 'Monthly';

  @override
  String get webMembershipYearly => 'Yearly';

  @override
  String get webMembershipFree => 'Free';

  @override
  String webMembershipPrice(String price, String cycle) {
    String _temp0 = intl.Intl.selectLogic(cycle, {
      'yearly': 'year',
      'other': 'month',
    });
    return '$price / $_temp0';
  }

  @override
  String get webMembershipFootnote =>
      'Catalogue prices are a preview. Membership never bypasses another person’s boundaries or conversation eligibility.';

  @override
  String get blogLinkCopied => 'Link copied. Share it wherever you choose.';

  @override
  String get blogYourPublicLink => 'Your public link';

  @override
  String get blogShareUnconfirmed =>
      'Could not confirm sharing. Check Shared links before retrying.';

  @override
  String get blogSignInAgain => 'Sign in again to continue.';

  @override
  String get blogSharedJournalPage => 'A shared journal page';

  @override
  String get blogYourPublicPreview => 'Your public preview';

  @override
  String get blogShareJointHeadline => 'A story you both choose to share.';

  @override
  String get blogShareSoloHeadline => 'A small window into your world.';

  @override
  String get blogShareJointBody =>
      'Both authors must approve these exact words before the link works. Either person can withdraw it.';

  @override
  String get blogShareSoloBody =>
      'Anyone with the link can read the selected words and photos, without an account. Your full chapter stays in Connect.';

  @override
  String get blogShareIdentityNote =>
      'No profile or account name is added. Your words and photos can still identify people or places. Publish only what you have permission to share.';

  @override
  String get blogExcerptLabel => 'Exact excerpt from your chapter';

  @override
  String blogIncludePhoto(String description) {
    return 'Include: $description';
  }

  @override
  String get blogApproveCopy => 'I approve this exact public copy';

  @override
  String get blogApproveCopyNote =>
      'Editing or hiding the source chapter invalidates the link. Saved copies outside Connect cannot be recalled.';

  @override
  String get blogSaving => 'Saving…';

  @override
  String get blogRequestOtherApproval => 'Request the other author’s approval';

  @override
  String get blogCreatePublicLink => 'Create public link';

  @override
  String get blogJointApprovalRecorded =>
      'Your approval is recorded. The link stays unavailable until the other author approves.';

  @override
  String get blogPublicCopyReady => 'Your public copy is ready.';

  @override
  String get blogCopyPublicLink => 'Copy public link';

  @override
  String get blogManageSharedLinks => 'Manage shared links';

  @override
  String blogFollowerCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count followers',
      one: '1 follower',
    );
    return '$_temp0';
  }

  @override
  String get blogUnfollowFailed =>
      'We couldn’t stop following just now. Please try again.';

  @override
  String get blogFollowFailed =>
      'We couldn’t follow this writer just now. Please try again.';

  @override
  String get blogFollowingButton => 'Following';

  @override
  String get blogFollowTheirChapters => 'Follow their chapters';

  @override
  String get blogRewardsIntro =>
      'When what you share moves someone, it counts. Readers’ likes, approved comments and new followers earn you XP toward your level. Rewards come from what readers do, never from tapping, and each one is given only once.';

  @override
  String blogRewardDailyCap(int cap) {
    return 'Up to $cap XP a day';
  }

  @override
  String blogRewardXp(int xp) {
    return '+$xp XP';
  }

  @override
  String get blogSignInWriters => 'Sign in to see writers you follow.';

  @override
  String get blogWritersLoadFailed => 'Writers you follow could not load.';

  @override
  String get blogNoWriters => 'No writers yet.';

  @override
  String get blogNoWritersBody =>
      'When a chapter speaks to you, tap Follow their chapters on it. Their new chapters will gather in Following.';

  @override
  String blogLatest(String title) {
    return 'Latest: $title';
  }

  @override
  String get blogReactionFailed =>
      'Your reaction didn’t go through. Please try again.';

  @override
  String blogCannotLikeOwn(String noun) {
    String _temp0 = intl.Intl.selectLogic(noun, {
      'photo': 'You can’t like your own photo',
      'other': 'You can’t like your own chapter',
    });
    return '$_temp0';
  }

  @override
  String blogYouReacted(String reaction) {
    return 'You reacted: $reaction. Tap to take it back';
  }

  @override
  String blogLikeThis(String noun) {
    String _temp0 = intl.Intl.selectLogic(noun, {
      'photo': 'Like this photo',
      'other': 'Like this chapter',
    });
    return '$_temp0';
  }

  @override
  String blogCannotReactOwn(String noun) {
    String _temp0 = intl.Intl.selectLogic(noun, {
      'photo': 'You can’t react to your own photo',
      'other': 'You can’t react to your own chapter',
    });
    return '$_temp0';
  }

  @override
  String get blogReactTooltip => 'React: I hear you, Me too, Sending a hug…';

  @override
  String blogCommentCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count comments',
      one: '1 comment',
    );
    return '$_temp0';
  }

  @override
  String blogWaitingForYou(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '· $count waiting for you',
      one: '· $count waiting for you',
    );
    return '$_temp0';
  }

  @override
  String get blogFeatured => 'Featured';

  @override
  String blogTierNeedsBoth(int likes, int comments, int walls) {
    String _temp0 = intl.Intl.pluralLogic(
      likes,
      locale: localeName,
      other: '$likes more likes',
      one: '1 more like',
    );
    String _temp1 = intl.Intl.pluralLogic(
      comments,
      locale: localeName,
      other: '$comments more comments',
      one: '1 more comment',
    );
    String _temp2 = intl.Intl.pluralLogic(
      walls,
      locale: localeName,
      other: '$walls walls',
      one: '1 wall',
    );
    return '$_temp0 and $_temp1 to reach $_temp2';
  }

  @override
  String blogTierNeedsLikes(int likes, int walls) {
    String _temp0 = intl.Intl.pluralLogic(
      likes,
      locale: localeName,
      other: '$likes more likes',
      one: '1 more like',
    );
    String _temp1 = intl.Intl.pluralLogic(
      walls,
      locale: localeName,
      other: '$walls walls',
      one: '1 wall',
    );
    return '$_temp0 to reach $_temp1';
  }

  @override
  String blogTierNeedsComments(int comments, int walls) {
    String _temp0 = intl.Intl.pluralLogic(
      comments,
      locale: localeName,
      other: '$comments more comments',
      one: '1 more comment',
    );
    String _temp1 = intl.Intl.pluralLogic(
      walls,
      locale: localeName,
      other: '$walls walls',
      one: '1 wall',
    );
    return '$_temp0 to reach $_temp1';
  }

  @override
  String blogTierAlmostThere(int walls) {
    String _temp0 = intl.Intl.pluralLogic(
      walls,
      locale: localeName,
      other: 'Almost there: $walls walls are next',
      one: 'Almost there: 1 wall are next',
    );
    return '$_temp0';
  }

  @override
  String blogOnWalls(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'On $count walls',
      one: 'On 1 wall',
    );
    return '$_temp0';
  }

  @override
  String blogProgressToward(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Progress towards $count walls',
      one: 'Progress towards 1 wall',
    );
    return '$_temp0';
  }

  @override
  String get blogReachIdle => 'Readers can carry this chapter further';

  @override
  String get blogReachLive =>
      'Members who loved stories like yours are reading it now.';

  @override
  String get blogFeaturedStories => 'Featured Stories';

  @override
  String get blogFeaturedCaption =>
      'Stories other members loved, delivered to your wall.';

  @override
  String blogByAuthor(String name) {
    return 'by $name';
  }

  @override
  String get blogLikes => 'Likes';

  @override
  String get blogComments => 'Comments';

  @override
  String get blogCommentHint => 'What stayed with you?';

  @override
  String get blogCommentApproved =>
      'Approved. Everyone who can read this chapter can see it now.';

  @override
  String get blogCommentSent => 'Sent to the author for approval';

  @override
  String get blogCommentSendFailed =>
      'Your comment didn’t send. Your words are still here, so you can try again.';

  @override
  String blogCommentDeclined(String noun) {
    String _temp0 = intl.Intl.selectLogic(noun, {
      'photo': 'Declined. It won’t appear on your photo.',
      'other': 'Declined. It won’t appear on your chapter.',
    });
    return '$_temp0';
  }

  @override
  String get blogSaveFailed => 'That didn’t save. Please try again.';

  @override
  String get blogDeleteCommentTitle => 'Delete this comment?';

  @override
  String get blogDeleteCommentMessage =>
      'It will be removed for everyone. This can’t be undone.';

  @override
  String get blogDeleteComment => 'Delete comment';

  @override
  String get blogCommentDeleted => 'Comment deleted.';

  @override
  String get blogCommentDeleteFailed =>
      'The comment could not be deleted. Please try again.';

  @override
  String get blogCommentsAuthorNote =>
      'New comments wait for your approval before anyone else sees them.';

  @override
  String get blogCommentsReaderNote =>
      'The author reads every comment first and chooses what to share.';

  @override
  String get blogLeaveComment => 'Leave a comment';

  @override
  String get blogSendToAuthor => 'Send to the author';

  @override
  String get blogCommentsLoadFailed => 'Comments could not load.';

  @override
  String get blogWaitingApproval => 'Waiting for your approval';

  @override
  String get blogNoCommentsInvite =>
      'No comments yet. Say something kind to start the conversation.';

  @override
  String get blogNoCommentsShared => 'No comments shared yet.';

  @override
  String get blogCommentNotShared => 'The author chose not to share this one.';

  @override
  String get blogYou => 'You';

  @override
  String get blogCommentOptions => 'Comment options';

  @override
  String get blogReportComment => 'Report comment';

  @override
  String get blogApprove => 'Approve';

  @override
  String get blogDecline => 'Decline';

  @override
  String get blogSignInContinue => 'Sign in to continue.';

  @override
  String get blogPrivateResponseTitle => 'A private response';

  @override
  String blogPrivateResponseHelp(String invitation) {
    return '$invitation\n\nOnly the author receives this response. They can accept or decline an optional exchange. Up to five new responses per day, and one to the same author.';
  }

  @override
  String get blogSendPrivateResponse => 'Send private response';

  @override
  String get blogTextSaveUnconfirmed =>
      'Could not confirm the save. Your words are still here; retry or reload the saved exchange.';

  @override
  String get blogLeaveUnsentTitle => 'Leave without sending?';

  @override
  String get blogLeaveUnsentMessage => 'Your unsent words will be discarded.';

  @override
  String get blogLeave => 'Leave';

  @override
  String get blogOwnWordsLabel => 'In your own words';

  @override
  String get blogSending => 'Sending…';

  @override
  String get blogChangeUnconfirmed =>
      'Could not confirm the change. Refresh to check.';

  @override
  String get blogConnectionsTitle => 'Your Chapter connections';

  @override
  String get blogRefresh => 'Refresh';

  @override
  String get blogConnectionsIntro =>
      'Good stories leave room for someone else.';

  @override
  String get blogConnectionsLoadFailed => 'Could not load your connections.';

  @override
  String get blogResponsesEmpty =>
      'Responses to your chapters and the ones you send will appear here. Nothing needs an instant answer.';

  @override
  String get blogPublicationsEmpty =>
      'Your public previews and jointly approved links will appear here.';

  @override
  String get blogNoticesEmpty => 'No review notices to show.';

  @override
  String get blogResponseRevealed => 'Your shared chapter is ready';

  @override
  String get blogResponseIncoming => 'A response for you';

  @override
  String get blogResponseSent => 'Sent · their choice, their pace';

  @override
  String get blogResponseAccepted => 'An exchange, at your pace';

  @override
  String get blogResponseClosed => 'This exchange is closed';

  @override
  String get blogOpenExchange => 'Open private exchange';

  @override
  String get blogPublicationLive => 'Live public copy';

  @override
  String get blogPublicationRemoved => 'Removed by moderation';

  @override
  String get blogPublicationNeedsBoth =>
      'Requires both approvals and a current source chapter';

  @override
  String get blogPublicationSourceChanged =>
      'Source changed · create a new preview to share again';

  @override
  String get blogApprovePublicCopyTitle => 'Approve this public copy?';

  @override
  String get blogApprovePublicCopyMessage =>
      'The exact words above will be available to anyone with the link. Both people can withdraw sharing. No names are added automatically, but the words may identify you.';

  @override
  String get blogApprovePublicCopyAction => 'Approve public copy';

  @override
  String get blogApproveExactPublicCopy => 'Approve exact public copy';

  @override
  String get blogCopyLink => 'Copy link';

  @override
  String get blogWithdrawLinkTitle => 'Withdraw this link?';

  @override
  String get blogWithdrawLinkMessage =>
      'The public copy will become unavailable. Copies already saved by someone else cannot be recalled.';

  @override
  String get blogWithdrawLink => 'Withdraw link';

  @override
  String get blogYourAppeal => 'Your appeal';

  @override
  String get blogRequestReview => 'Request another review';

  @override
  String get blogRequestReviewHelp =>
      'Explain what the reviewer should reconsider. Your appeal goes privately to the trust team. Removed content stays hidden during review.';

  @override
  String get blogSubmitAppeal => 'Submit appeal';

  @override
  String get blogAppealDecision => 'Appeal this decision';

  @override
  String get blogPrevious => 'Previous';

  @override
  String get blogMore => 'More';

  @override
  String get blogExchangeChangeFailed =>
      'Could not confirm this change. Refresh and retry.';

  @override
  String get blogExchangeTitle => 'A private Chapter exchange';

  @override
  String get blogExchangeUnavailable => 'This exchange is no longer available.';

  @override
  String blogExchangeWith(String name) {
    return 'With $name';
  }

  @override
  String get blogExchangeIntro =>
      'A response is an invitation, never an obligation. This exchange does not create a match or unlock chat.';

  @override
  String get blogAcceptExchange => 'Accept an exchange';

  @override
  String get blogDeclineKindly => 'Decline kindly';

  @override
  String get blogResponseSentNote =>
      'Your response has been sent. There is no countdown and no need to follow up.';

  @override
  String get blogExchangeClosedNote =>
      'This exchange is closed. Make room for another connection at your own pace.';

  @override
  String get blogOneStoryEach => 'One small story each.';

  @override
  String get blogOneStoryEachBody =>
      'Add a tiny continuation, a memory, or your version of the moment. Both contributions appear together, only after both people submit.';

  @override
  String get blogYourSideTitle => 'Your side of the chapter';

  @override
  String get blogYourSideHelp =>
      'Share up to 1,000 characters. Your partner cannot read this until they also contribute. Once submitted, the words cannot be edited; you can withdraw the exchange at any time.';

  @override
  String get blogSubmitContribution => 'Submit my contribution';

  @override
  String get blogAddContribution => 'Add my contribution';

  @override
  String get blogYourContribution => 'Your contribution';

  @override
  String blogPartnerContribution(String name) {
    return '$name’s contribution';
  }

  @override
  String get blogShapeDate => 'Shape a date together';

  @override
  String get blogInspiredNote => 'Inspired by our Chapter exchange.';

  @override
  String get blogTryStudio => 'Try First Chapter Studio';

  @override
  String get blogDatePlanningUnavailable =>
      'Date planning becomes available if you have an active match and your conversation is unlocked.';

  @override
  String get blogProposeJournalPage => 'Propose a shared journal page';

  @override
  String get blogSourceUnavailable => 'The source chapter is unavailable.';

  @override
  String get blogContributionSaved =>
      'Your contribution is saved privately. The reveal happens when both of you are ready.';

  @override
  String get blogWithdrawExchangeTitle => 'Withdraw this exchange?';

  @override
  String get blogWithdrawExchangeMessage =>
      'The response and contributions will no longer be available to either of you. Joint public links will also stop working.';

  @override
  String get blogWithdrawExchange => 'Withdraw exchange';

  @override
  String get blogReportExchange => 'Report exchange';

  @override
  String get blogBlockMessageExchange =>
      'Contact and access to each other’s chapters will stop.';

  @override
  String get blogBlockFailed => 'Could not block this member.';

  @override
  String get notificationsReadAll => 'Read all';

  @override
  String get notificationsFallbackTitle => 'Notification';

  @override
  String get notificationsLoadFailed => 'Unable to load notifications.';

  @override
  String get notificationsPrefsUpdateFailed =>
      'Unable to update notification preferences.';

  @override
  String notificationsAgoMinutes(int count) {
    return '${count}m ago';
  }

  @override
  String notificationsAgoHours(int count) {
    return '${count}h ago';
  }

  @override
  String notificationsAgoDays(int count) {
    return '${count}d ago';
  }

  @override
  String get wallsReactEyebrow => 'REACT';

  @override
  String wallsReactQuestion(String noun) {
    String _temp0 = intl.Intl.selectLogic(noun, {
      'photo': 'How does this photo make you feel?',
      'other': 'How does this chapter make you feel?',
    });
    return '$_temp0';
  }

  @override
  String get wallsReactBody =>
      'Your reaction tells them they were heard. Every reaction counts as a like.';

  @override
  String get wallsReactRemove => 'Take my reaction back';

  @override
  String wallsReactionsSemantics(String list) {
    return 'Reactions: $list';
  }

  @override
  String get wallsReactionLove => 'Love this';

  @override
  String get wallsReactionHearYou => 'I hear you';

  @override
  String get wallsReactionMeToo => 'Me too';

  @override
  String get wallsReactionWithYou => 'I’m with you';

  @override
  String get wallsReactionHug => 'Sending a hug';

  @override
  String get wallsReactionProud => 'Proud of you';

  @override
  String get wallsSignInRequired => 'Sign in to see your wall.';

  @override
  String get celebrationCoverHeadline => 'Your photo is Cover of the Week';

  @override
  String celebrationReachHeadline(String kind, int reach) {
    String _temp0 = intl.Intl.selectLogic(kind, {
      'photo': 'Your photo reached $reach walls',
      'other': 'Your chapter reached $reach walls',
    });
    return '$_temp0';
  }

  @override
  String get celebrationCoverMessage =>
      'Members loved it. Everyone sees it on Today this week.';

  @override
  String get celebrationReachMessage =>
      'Members loved it. It is now on their Today walls.';

  @override
  String celebrationQuotedTitle(String title) {
    return '“$title”';
  }

  @override
  String get celebrationBarrier => 'Celebration';

  @override
  String get celebrationLovely => 'Lovely';

  @override
  String get celebrationSeePhoto => 'See photo';

  @override
  String get celebrationSeeChapter => 'See chapter';

  @override
  String rewardXpPill(int xp) {
    return '+$xp XP';
  }

  @override
  String get rewardClaimedTitle => 'Reward claimed';

  @override
  String rewardNameDescription(String name, String description) {
    return '$name · $description';
  }

  @override
  String rewardPlusXpAnnouncement(int xp) {
    return 'plus $xp XP';
  }

  @override
  String rewardSourceXpLine(String source, int xp) {
    return '$source +$xp XP';
  }

  @override
  String rewardAndMore(int count) {
    return 'and $count more';
  }

  @override
  String rewardBadgeLine(String badge) {
    return 'Badge: $badge';
  }

  @override
  String rewardLevelReached(int level) {
    return 'Level $level reached';
  }

  @override
  String rewardBadgesEarned(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count badges earned',
      one: 'Badge earned',
    );
    return '$_temp0';
  }

  @override
  String get rewardYourRewardsToday => 'Your rewards today';

  @override
  String rewardNewRewards(int count) {
    return '$count new rewards';
  }

  @override
  String get rewardSourceStoryPublished => 'Chapter published';

  @override
  String get rewardSourcePhotoShared => 'Photo shared';

  @override
  String get rewardSourceLikeReceived => 'A member liked your work';

  @override
  String get rewardSourceCommentReceived => 'New comment on your work';

  @override
  String get rewardSourceCommentApproved => 'Your comment was approved';

  @override
  String get rewardSourceSubscriberGained => 'New subscriber';

  @override
  String get rewardSourceWallTierReached => 'Wall tier reached';

  @override
  String get rewardSourceCoverOfWeek => 'Cover of the Week';

  @override
  String get rewardSourceDailyPromptSubmitted => 'Daily prompt answered';

  @override
  String get rewardLineStoryPublished => 'Your chapter is out in the world.';

  @override
  String get rewardLinePhotoShared => 'Your photo joined the theme.';

  @override
  String get rewardLineLikeReceived => 'Someone loved what you shared.';

  @override
  String get rewardLineCommentReceived => 'A reader joined the conversation.';

  @override
  String get rewardLineSubscriberGained => 'Someone wants your next chapter.';

  @override
  String get rewardLineWallTierReached => 'Your work reached more walls.';

  @override
  String get rewardLineCoverOfWeek => 'Everyone sees it on Today this week.';

  @override
  String get rewardLineOther => 'Earned for meaningful activity.';

  @override
  String get rewardNewBadgeFallback => 'New badge';

  @override
  String get blockedUnknownUser => 'Unknown User';

  @override
  String get themeTaglineBluerose =>
      'Midnight velvet, sapphire roses and a platinum edge.';

  @override
  String get themeTaglineBluelotus =>
      'Moonlit water, sapphire petals and a golden heart.';

  @override
  String discoverMessageLikeSent(String name) {
    return 'Love sent to $name. You can chat as soon as they like you back.';
  }

  @override
  String get notificationsDismissFailed =>
      'Couldn\'t remove that notification. Try again.';

  @override
  String get notificationsReadAllFailed =>
      'Couldn\'t mark them all as read. Try again.';

  @override
  String get blogReportSubmitted => 'Report submitted. Thank you.';

  @override
  String get settingsSectionAccount => 'Account';

  @override
  String settingsSignedInAs(String username) {
    return 'Signed in as @$username';
  }

  @override
  String get settingsSignOut => 'Sign out';

  @override
  String get settingsSignOutSubtitle => 'End your session on this device';

  @override
  String get settingsSignOutAllTitle => 'Sign out of all devices';

  @override
  String get settingsSignOutAllSubtitle =>
      'End every session, on every phone and browser';

  @override
  String get settingsSignOutConfirmTitle => 'Sign out?';

  @override
  String get settingsSignOutConfirmBody =>
      'You\'ll need your username and password to sign in again on this device.';

  @override
  String get settingsSignOutAllConfirmTitle => 'Sign out of all devices?';

  @override
  String get settingsSignOutAllConfirmBody =>
      'This ends your session on every phone, tablet and browser, including this one. Anyone signed in to your account elsewhere will be signed out.';

  @override
  String get settingsSignOutAllConfirmAction => 'Sign out everywhere';

  @override
  String get settingsSignOutAllFailed =>
      'Couldn\'t sign out your other devices. Check your connection and try again.';

  @override
  String get supportPaymentHelpLink => 'Payment problem? Contact support';

  @override
  String get supportReportHelpLink => 'Need more help? Contact support';

  @override
  String get supportSignedOutHelpLink =>
      'Something else wrong? Contact support';

  @override
  String get supportGuestSubtitle =>
      'Can’t sign in, or something else isn’t working? Tell us what happened and we’ll reply by email.';

  @override
  String get supportGuestEmailLabel => 'Your email';

  @override
  String get supportGuestEmailHint => 'We’ll reply to this address';

  @override
  String get supportGuestNameLabel => 'Your name (optional)';

  @override
  String get supportGuestEmailInvalid =>
      'Enter a valid email address so we can reply.';

  @override
  String get supportGuestSentTitle => 'Request sent';

  @override
  String supportGuestSentBody(String reference, String email) {
    return 'Thanks. Your reference is $reference. We’ll reply to $email.';
  }

  @override
  String get supportGuestUnavailableBody =>
      'Support requests can’t be sent from the app right now. For anything urgent, email support@connect.example.';

  @override
  String get supportDraftRestored => 'We kept your unsent request.';

  @override
  String get supportDraftDiscard => 'Discard draft';

  @override
  String get discoverActionUndo => 'Undo';

  @override
  String get discoverActionLike => 'Like';

  @override
  String get discoverActionSuperLike => 'Super like';

  @override
  String get navQaVerifyShortcut => 'Verify';

  @override
  String get chatMessageDeletedPlaceholder => 'Message deleted';

  @override
  String get chatGiftYouSentHeading => 'You sent a gift';

  @override
  String get commonMemberFallbackName => 'A member';

  @override
  String get giftNameRoseRedSingle => 'Single Red Rose';

  @override
  String get giftNameRosePinkSoft => 'Pink Rose';

  @override
  String get giftNameRoseWhitePure => 'White Rose';

  @override
  String get giftNameRoseYellowFriendship => 'Yellow Rose';

  @override
  String get giftNameRoseLavenderCrush => 'Lavender Rose';

  @override
  String get giftNameRoseBlueRare => 'Blue Rose';

  @override
  String get giftNameRoseBlackMystery => 'Black Rose';

  @override
  String get giftNameRoseSparkle => 'Sparkle Rose';

  @override
  String get giftNameRoseHeartPetal => 'Heart-Petal Rose';

  @override
  String get giftNameRoseNeonGlow => 'Neon Rose';

  @override
  String get giftNameRoseRain => 'Rose Rain';

  @override
  String get giftNameRoseBurningFlame => 'Burning Rose';

  @override
  String get giftNameRoseGolden => 'Golden Rose';

  @override
  String get giftNameRoseCrystal => 'Crystal Rose';

  @override
  String get giftNameRoseBouquet12 => 'Rose Bouquet (12)';

  @override
  String get giftNameRoseBouquet24 => 'Rose Bouquet (24)';

  @override
  String get giftNameRoseSeasonalWeekly => 'Seasonal Limited Rose';

  @override
  String get giftNameChocolateBox => 'Chocolate Box';

  @override
  String get giftNameHeartBalloon => 'Heart Balloon';

  @override
  String get giftNameTeddyBear => 'Teddy Bear';

  @override
  String get giftNameFlowerBouquet => 'Flower Bouquet';

  @override
  String get giftNameJewelleryBox => 'Jewellery Box';

  @override
  String get giftNameChampagneToast => 'Champagne Toast';

  @override
  String get giftNameHeartExplosion => 'Heart Explosion';

  @override
  String get giftNameConfettiShower => 'Confetti Shower';

  @override
  String get giftNameFireworksBurst => 'Fireworks Burst';

  @override
  String get giftNameStarShower => 'Star Shower';

  @override
  String get giftNameGoldenSparkle => 'Golden Sparkle';

  @override
  String get giftNameRainbowWave => 'Rainbow Wave';

  @override
  String get giftNameCoffeeDateInvite => 'Coffee Date Invite';

  @override
  String get giftNamePicnicInvite => 'Picnic Invite';

  @override
  String get giftNameMovieNightInvite => 'Film Night Invite';

  @override
  String get giftNameSunsetWalkInvite => 'Sunset Walk Invite';

  @override
  String get giftNameDateNightCard => 'Date Night Card';

  @override
  String get giftNameValentineSurprise => 'Valentine\'s Surprise';

  @override
  String get giftNameDiamondRing => 'Diamond Ring';

  @override
  String get giftNameLuxuryDate => 'Luxury Date Experience';

  @override
  String get blogPublicationUnavailableTitle => 'Sharing unavailable';

  @override
  String get blogPublicationUnavailableExcerpt =>
      'The source changed or access was withdrawn. Withdraw this link.';

  @override
  String get blogNoticeKindPost => 'Post';

  @override
  String get blogNoticeKindResponse => 'Response';

  @override
  String get blogNoticeKindPublication => 'Public copy';

  @override
  String get blogNoticeKindThemeEntry => 'Theme photo';

  @override
  String get blogNoticeKindClub => 'Club';

  @override
  String get blogNoticeKindClubPost => 'Club post';

  @override
  String get blogNoticeKindReview => 'Review';

  @override
  String get blogNoticeKindList => 'List';

  @override
  String get blogNoticeKindComment => 'Comment';

  @override
  String get blogNoticeKindPhotoComment => 'Photo comment';

  @override
  String get blogNoticeKindChatMessage => 'Chat message';

  @override
  String get blogNoticeKindGroup => 'Group';

  @override
  String get blogNoticeKindOther => 'Content';

  @override
  String get blogNoticeStatusPending => 'Under review';

  @override
  String get blogNoticeStatusDismissed => 'No action taken';

  @override
  String get blogNoticeStatusRemoved => 'Removed';

  @override
  String get blogNoticeStatusRestored => 'Restored';

  @override
  String get engagementTrustMilestoneProfileDepth => 'Profile depth';

  @override
  String get engagementTrustMilestoneCommunication => 'Communication';

  @override
  String get engagementTrustMilestoneConsistency => 'Consistency';

  @override
  String get engagementTrustMilestonePromptCompletion => 'Prompts answered';

  @override
  String get engagementTrustMilestoneActivitySignals => 'Activity signals';

  @override
  String get engagementTrustMilestoneUnsafeSignals => 'Safety flags';

  @override
  String get engagementTrustMilestoneReportPenalty => 'Report penalty';

  @override
  String get engagementTrustMilestoneVerification => 'Verification consistent';

  @override
  String get engagementTrustMilestoneSafety => 'Safety';

  @override
  String engagementTrustMilestoneLine(String label, String value) {
    return '$label: $value';
  }

  @override
  String get networkOfflineTryAgain =>
      'Can\'t connect right now. Check your internet connection and try again.';

  @override
  String get apiErrorFeatureUnavailable =>
      'This feature isn\'t available right now.';

  @override
  String get apiErrorConversationUnavailable =>
      'This conversation is no longer available.';

  @override
  String get apiErrorMemberUnavailable => 'This member isn\'t available.';

  @override
  String get apiErrorChatLocked => 'Unlock this conversation first.';

  @override
  String get apiErrorCopilotDailyLimit =>
      'You\'ve used today\'s drafts. Write this one yourself.';

  @override
  String get apiErrorCopilotUnavailable =>
      'Drafting help isn\'t available right now.';

  @override
  String get apiErrorCopilotProfileUnavailable =>
      'Their profile isn\'t available right now.';

  @override
  String get apiErrorDatePlanAlreadyOpen =>
      'A date plan is already open for this match.';

  @override
  String get apiErrorDatePlanMatchInactive =>
      'Date plans need an active match.';

  @override
  String get apiErrorDatePlanNotOpen => 'This date plan is no longer open.';

  @override
  String get apiErrorDatePlanCheckInTooEarly =>
      'You can check in once the plan starts.';

  @override
  String get apiErrorDatePlanDebriefTooEarly =>
      'The debrief opens once the plan starts.';

  @override
  String get apiErrorSharedAvailabilityChanged =>
      'Shared availability has changed. Refresh the suggested times or pick a time yourself.';

  @override
  String get apiErrorGraduationAlreadyOpen =>
      'A graduation proposal is already open for this match.';

  @override
  String get apiErrorGraduationMatchInactive =>
      'Graduating needs an active match.';

  @override
  String get apiErrorGraduationNotOpen =>
      'This graduation proposal is no longer open.';

  @override
  String get apiErrorGraduationAlreadyConfirmed =>
      'You\'ve already graduated together.';

  @override
  String get apiErrorOutOfDate =>
      'This view is out of date. Refresh and try again.';

  @override
  String get apiErrorOutcomeUncertain =>
      'We couldn\'t confirm that. Refresh to check before trying again.';

  @override
  String get apiErrorInsufficientCoins =>
      'You don\'t have enough coins for this.';

  @override
  String get apiErrorChannelReadOnly => 'This chat is read-only right now.';

  @override
  String get apiErrorRoomFull =>
      'This room is full right now. Try again in a little while.';

  @override
  String get apiErrorRoomRemoved =>
      'A host removed you from this room. You can rejoin when this session ends.';

  @override
  String get apiErrorRoomNotJoined => 'You\'re not in this room.';

  @override
  String get apiErrorDailyMessageLimit =>
      'You\'ve used today\'s messages. Try again after the reset or upgrade your plan.';

  @override
  String get apiErrorDailyLikeLimit =>
      'You\'ve used today\'s likes. Try again after the reset or upgrade your plan.';

  @override
  String get apiErrorFriendRequired => 'You need to be friends first.';

  @override
  String get apiErrorVouchExists => 'You\'ve already vouched for them.';

  @override
  String get apiErrorIntroUnavailable => 'This intro isn\'t available anymore.';

  @override
  String get apiErrorIntroAlreadyOpen =>
      'An intro for these two is already open.';

  @override
  String get apiErrorIntroNotOpen => 'This intro is no longer open.';

  @override
  String get apiErrorTooManyTries =>
      'Too many tries. Wait a moment and try again.';

  @override
  String get apiErrorQuestCooldown =>
      'This quest is cooling down. Try again a little later.';

  @override
  String get apiErrorQuestSelfReview =>
      'Your match reviews your quest answer, not you.';

  @override
  String get apiErrorQuestNotParticipant =>
      'Only members of this match can take part in its quest.';

  @override
  String get apiErrorPaymentsUnavailable =>
      'Coin purchases aren\'t available right now.';

  @override
  String get apiErrorServiceBusy =>
      'The service is busy right now. Try again in a moment.';

  @override
  String get apiErrorSignInAgain => 'Please sign in again to continue.';

  @override
  String get friendsMemberFallback => 'A member';

  @override
  String get friendsActivityFallback => 'Activity';

  @override
  String get membershipPlanFallback => 'Plan';

  @override
  String get membershipSubscriptionFallback => 'Subscription';

  @override
  String engagementLevelRewardFallback(int level) {
    return 'Level $level reward';
  }

  @override
  String get engagementTrustBadgeUnknown => 'Unknown badge';

  @override
  String get firstChapterComfortDefaultLanguage => 'English';

  @override
  String paymentWalletBalanceCoins(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString coins',
      one: '1 coin',
    );
    return '$_temp0';
  }

  @override
  String get languageIntroSignedOut =>
      'Pick the language Connect uses. It changes right away, and when you sign in it\'s saved to your account.';

  @override
  String languagePickerButtonSemantics(String language) {
    return 'Language: $language. Change language';
  }

  @override
  String get authErrorUsernameTaken =>
      'That username is already taken. Try another one.';

  @override
  String get authErrorAccountSuspended =>
      'This account is suspended. Contact support if you think this is a mistake.';

  @override
  String get authErrorAccountLocked =>
      'Too many sign-in attempts. Try again in a few minutes.';

  @override
  String get authErrorTooManyRequests =>
      'Too many tries. Wait a moment and try again.';

  @override
  String get authErrorAccountTypeUnavailable =>
      'This kind of account isn\'t available right now.';

  @override
  String get authErrorNetwork =>
      'Can\'t connect right now. Check your internet connection and try again.';

  @override
  String get profileSetupReorderPhoto => 'Drag to reorder this photo';

  @override
  String get profileLanguageAssamese => 'Assamese';

  @override
  String get profileLanguageBengali => 'Bengali';

  @override
  String get profileLanguageBodo => 'Bodo';

  @override
  String get profileLanguageDogri => 'Dogri';

  @override
  String get profileLanguageEnglish => 'English';

  @override
  String get profileLanguageGujarati => 'Gujarati';

  @override
  String get profileLanguageHindi => 'Hindi';

  @override
  String get profileLanguageKannada => 'Kannada';

  @override
  String get profileLanguageKashmiri => 'Kashmiri';

  @override
  String get profileLanguageKonkani => 'Konkani';

  @override
  String get profileLanguageMaithili => 'Maithili';

  @override
  String get profileLanguageMalayalam => 'Malayalam';

  @override
  String get profileLanguageManipuri => 'Manipuri';

  @override
  String get profileLanguageMarathi => 'Marathi';

  @override
  String get profileLanguageNepali => 'Nepali';

  @override
  String get profileLanguageOdia => 'Odia';

  @override
  String get profileLanguagePunjabi => 'Punjabi';

  @override
  String get profileLanguageSanskrit => 'Sanskrit';

  @override
  String get profileLanguageSantali => 'Santali';

  @override
  String get profileLanguageSindhi => 'Sindhi';

  @override
  String get profileLanguageTamil => 'Tamil';

  @override
  String get profileLanguageTelugu => 'Telugu';

  @override
  String get profileLanguageUrdu => 'Urdu';

  @override
  String get profileCountryIndia => 'India';

  @override
  String get profileCountryUnitedKingdom => 'United Kingdom';

  @override
  String get profileCountryIreland => 'Ireland';

  @override
  String get profileCountryGermany => 'Germany';

  @override
  String get profileCountryAustria => 'Austria';

  @override
  String get profileMasterWorkoutSometimes => 'Sometimes';

  @override
  String get profileMasterWorkoutWeekly => 'Weekly';

  @override
  String get profileMasterTravelRoadTrips => 'Road trips';

  @override
  String get profileMasterTravelBackpacking => 'Backpacking';

  @override
  String get profileMasterTravelLuxuryShort => 'Luxury';

  @override
  String get profileMasterTravelStaycations => 'Staycations';

  @override
  String get profileMasterPoliticsSimilarShort => 'Similar';

  @override
  String get profileMasterPoliticsModerate => 'Moderate';

  @override
  String get profileMasterPoliticsAny => 'Any';
}
