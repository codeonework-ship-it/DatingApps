// The literals hardcoded_strings_guard_test.dart allows, one entry per
// occurrence, each with the reason it may stay. Only true exceptions belong
// here: brand names, mock/demo data, debug or sandbox-only surfaces and
// English message codes that a screen translates when it shows them.
// Never baseline a qa id used as a label, raw error text or a raw dropdown
// item. Delete an entry as soon as its literal is gone (the test fails on
// stale entries).

class BaselineEntry {
  const BaselineEntry(this.file, this.text, this.reason, {this.kind = 'text'});
  final String file;
  final String text;
  final String reason;
  final String kind;
}

const _brandLook =
    'Look name: a product name kept in every language (the taglines are '
    'translated by localizedPresetTagline).';
const _mockAuthBanner =
    'Banner shown only when kUseMockAuth (local development builds).';
const _mockData =
    'Mock/demo data returned only when kUseMockAuth; never shown for a real '
    'account.';
const _chatCode =
    'English message code kept in MessageState.error for logs and tests; the '
    'chat screen translates it (localizeChatError, chat_error_l10n.dart).';
const _callCode =
    'English diagnostic kept in CallState.error; the screen shows the '
    'translated text for errorKind (call_l10n.dart).';
const _profileCode =
    'English diagnostic kept in ProfileState.error; the screen shows the '
    'translated text for ProfileLoadIssue (profile_view_screen.dart).';
const _activityDefaults =
    'Default activity question data; the screen shows '
    'localizedActivityQuestion(id), not this text.';
const _trustBadgeDefaults =
    'Default badge list; screens show localizedTrustBadgeLabel(code), not '
    'this label.';
const _placeName =
    'A Bengaluru neighbourhood prefilled as an example area: a place name.';
const _sandboxOnly =
    'Sandbox payment-provider controls, shown only when the provider is '
    '"sandbox" (QA builds).';
const _internalException =
    'Exception message for logs; the screen shows a translated failure.';
const _debugEntryPoint =
    'main_simple.dart is a layout smoke-test entry point, not the app.';

const hardcodedStringsBaseline = <BaselineEntry>[
  BaselineEntry('lib/core/theme/theme_presets.dart', 'Today', _brandLook),
  BaselineEntry(
    'lib/core/theme/theme_presets.dart',
    'Today · evening',
    _brandLook,
  ),
  BaselineEntry('lib/core/theme/theme_presets.dart', 'Daylight', _brandLook),
  BaselineEntry(
    'lib/core/theme/theme_presets.dart',
    'Afterdark Ember',
    _brandLook,
  ),
  BaselineEntry('lib/core/theme/theme_presets.dart', 'Forge', _brandLook),
  BaselineEntry('lib/core/theme/theme_presets.dart', 'Neon Grid', _brandLook),
  BaselineEntry(
    'lib/core/theme/theme_presets.dart',
    'Crimson Alloy',
    _brandLook,
  ),
  BaselineEntry('lib/core/theme/theme_presets.dart', 'Circuit', _brandLook),
  BaselineEntry('lib/core/theme/theme_presets.dart', 'Deep Field', _brandLook),
  BaselineEntry('lib/core/theme/theme_presets.dart', 'Love', _brandLook),
  BaselineEntry('lib/core/theme/theme_presets.dart', 'Rose', _brandLook),
  BaselineEntry('lib/core/theme/theme_presets.dart', 'Blue Rose', _brandLook),
  BaselineEntry('lib/core/theme/theme_presets.dart', 'Blue Lotus', _brandLook),
  BaselineEntry('lib/core/theme/theme_presets.dart', 'Petal', _brandLook),
  BaselineEntry('lib/core/theme/theme_presets.dart', 'Snow', _brandLook),
  BaselineEntry('lib/core/theme/theme_presets.dart', 'Gothic', _brandLook),
  BaselineEntry('lib/core/theme/theme_presets.dart', 'Calm', _brandLook),
  BaselineEntry(
    'lib/features/auth/screens/auth_screen.dart',
    'Mock auth is active. Use any username and password.',
    _mockAuthBanner,
  ),
  BaselineEntry(
    'lib/features/auth/screens/signup_screen.dart',
    'Mock auth is active for local ',
    _mockAuthBanner,
  ),
  BaselineEntry(
    'lib/features/calls/providers/call_provider.dart',
    'Please sign in to view call history.',
    _callCode,
  ),
  BaselineEntry(
    'lib/features/calls/providers/call_provider.dart',
    'Please sign in before starting a call.',
    _callCode,
  ),
  BaselineEntry(
    'lib/features/calls/providers/call_provider.dart',
    'Camera and microphone permissions are required for calls.',
    _callCode,
  ),
  BaselineEntry(
    'lib/features/calls/providers/call_provider.dart',
    'Live call rooms are not configured for this environment.',
    _callCode,
  ),
  BaselineEntry(
    'lib/features/calls/providers/call_provider.dart',
    'Unable to open the live call room.',
    _callCode,
  ),
  BaselineEntry(
    'lib/features/engagement/providers/billing_coexistence_provider.dart',
    'Increase profile discovery reach.',
    _mockData,
  ),
  BaselineEntry(
    'lib/features/engagement/providers/billing_coexistence_provider.dart',
    'Enhanced engagement and trend insights.',
    _mockData,
  ),
  BaselineEntry(
    'lib/features/engagement/providers/conversation_rooms_provider.dart',
    'Can\'t sleep? Neither can we. Slow, honest conversation for ',
    _mockData,
  ),
  BaselineEntry(
    'lib/features/engagement/providers/conversation_rooms_provider.dart',
    'night owls.',
    _mockData,
  ),
  BaselineEntry(
    'lib/features/engagement/providers/conversation_rooms_provider.dart',
    'What you\'re reading, and the one you press on everyone.',
    _mockData,
  ),
  BaselineEntry(
    'lib/features/engagement/providers/level_progression_provider.dart',
    'A profile accent earned through activity.',
    _mockData,
  ),
  BaselineEntry(
    'lib/features/engagement/providers/trust_badges_provider.dart',
    'Respectful Communicator',
    _mockData,
  ),
  BaselineEntry(
    'lib/features/engagement/screens/group_coffee_polls_screen.dart',
    'Indiranagar',
    _placeName,
  ),
  BaselineEntry(
    'lib/features/engagement/screens/group_coffee_polls_screen.dart',
    'Koramangala',
    _placeName,
  ),
  BaselineEntry(
    'lib/features/friends/providers/friend_social_provider.dart',
    'Warm, curious and always the first to show up.',
    _mockData,
  ),
  BaselineEntry(
    'lib/features/friends/providers/friend_social_provider.dart',
    'You two would get on.',
    _mockData,
  ),
  BaselineEntry(
    'lib/features/friends/providers/friend_social_provider.dart',
    'Warm, curious and always the first to show up.',
    _mockData,
  ),
  BaselineEntry(
    'lib/features/friends/providers/friends_provider.dart',
    'Plan a Friend Catch-up',
    _mockData,
  ),
  BaselineEntry(
    'lib/features/friends/providers/friends_provider.dart',
    'Share one weekly highlight and one goal for next week.',
    _mockData,
  ),
  BaselineEntry(
    'lib/features/matching/providers/activity_session_provider.dart',
    'Round 1',
    _activityDefaults,
  ),
  BaselineEntry(
    'lib/features/matching/providers/activity_session_provider.dart',
    'Round 2',
    _activityDefaults,
  ),
  BaselineEntry(
    'lib/features/matching/providers/activity_session_provider.dart',
    'Round 3',
    _activityDefaults,
  ),
  BaselineEntry(
    'lib/features/matching/providers/activity_session_provider.dart',
    'Round 4',
    _activityDefaults,
  ),
  BaselineEntry(
    'lib/features/matching/providers/activity_session_provider.dart',
    'Round 5',
    _activityDefaults,
  ),
  BaselineEntry(
    'lib/features/matching/providers/activity_session_provider.dart',
    'Round 6',
    _activityDefaults,
  ),
  BaselineEntry(
    'lib/features/matching/providers/activity_session_provider.dart',
    'Round 7',
    _activityDefaults,
  ),
  BaselineEntry(
    'lib/features/matching/providers/activity_session_provider.dart',
    'Round 8',
    _activityDefaults,
  ),
  BaselineEntry(
    'lib/features/matching/providers/trust_filter_provider.dart',
    'Prompt Completer',
    _trustBadgeDefaults,
  ),
  BaselineEntry(
    'lib/features/matching/providers/trust_filter_provider.dart',
    'Respectful Communicator',
    _trustBadgeDefaults,
  ),
  BaselineEntry(
    'lib/features/matching/providers/trust_filter_provider.dart',
    'Consistent Profile',
    _trustBadgeDefaults,
  ),
  BaselineEntry(
    'lib/features/matching/providers/trust_filter_provider.dart',
    'Verified & Active',
    _trustBadgeDefaults,
  ),
  BaselineEntry(
    'lib/features/messaging/providers/copilot_provider.dart',
    'Want to turn this into a coffee this week? I can propose a ',
    _mockData,
  ),
  BaselineEntry(
    'lib/features/messaging/providers/copilot_provider.dart',
    'time here.',
    _mockData,
  ),
  BaselineEntry(
    'lib/features/messaging/providers/copilot_provider.dart',
    'Hi! I noticed bouldering on your profile. What got you ',
    _mockData,
  ),
  BaselineEntry(
    'lib/features/messaging/providers/message_provider.dart',
    'This match has ended.',
    _chatCode,
  ),
  BaselineEntry(
    'lib/features/messaging/providers/message_provider.dart',
    'Failed to load messages. Please try again.',
    _chatCode,
  ),
  BaselineEntry(
    'lib/features/messaging/providers/message_provider.dart',
    'Failed to load messages. Please try again.',
    _chatCode,
  ),
  BaselineEntry(
    'lib/features/messaging/providers/message_provider.dart',
    'This match has ended.',
    _chatCode,
  ),
  BaselineEntry(
    'lib/features/messaging/providers/message_provider.dart',
    'Chat is locked until the quest is approved.',
    _chatCode,
  ),
  BaselineEntry(
    'lib/features/messaging/providers/message_provider.dart',
    'Failed to send message.',
    _chatCode,
  ),
  BaselineEntry(
    'lib/features/messaging/providers/message_provider.dart',
    'Failed to send message.',
    _chatCode,
  ),
  BaselineEntry(
    'lib/features/messaging/providers/message_provider.dart',
    'Failed to delete message.',
    _chatCode,
  ),
  BaselineEntry(
    'lib/features/messaging/providers/message_provider.dart',
    'Failed to delete message.',
    _chatCode,
  ),
  BaselineEntry(
    'lib/features/messaging/providers/message_provider.dart',
    'Delete window expired (24h).',
    _chatCode,
  ),
  BaselineEntry(
    'lib/features/messaging/providers/message_provider.dart',
    'Failed to delete message.',
    _chatCode,
  ),
  BaselineEntry(
    'lib/features/messaging/providers/message_provider.dart',
    'Failed to delete message.',
    _chatCode,
  ),
  BaselineEntry(
    'lib/features/messaging/providers/message_provider.dart',
    'Only received gifts can be managed.',
    _chatCode,
  ),
  BaselineEntry(
    'lib/features/messaging/providers/message_provider.dart',
    'This gift is no longer available.',
    _chatCode,
  ),
  BaselineEntry(
    'lib/features/messaging/providers/message_provider.dart',
    'Could not report this gift. Please try again.',
    _chatCode,
  ),
  BaselineEntry(
    'lib/features/messaging/providers/message_provider.dart',
    'Could not hide this gift. Please try again.',
    _chatCode,
  ),
  BaselineEntry(
    'lib/features/messaging/providers/message_provider.dart',
    'Could not report this gift. Please try again.',
    _chatCode,
  ),
  BaselineEntry(
    'lib/features/messaging/providers/message_provider.dart',
    'Could not hide this gift. Please try again.',
    _chatCode,
  ),
  BaselineEntry(
    'lib/features/messaging/providers/message_provider.dart',
    'Rose gifts are currently unavailable.',
    _chatCode,
  ),
  BaselineEntry(
    'lib/features/messaging/providers/message_provider.dart',
    'Not enough coins to send \${gift.name}.',
    _chatCode,
  ),
  BaselineEntry(
    'lib/features/messaging/providers/message_provider.dart',
    'Not enough coins to send \${gift.name}.',
    _chatCode,
  ),
  BaselineEntry(
    'lib/features/messaging/providers/message_provider.dart',
    'Chat is locked until the quest is approved.',
    _chatCode,
  ),
  BaselineEntry(
    'lib/features/messaging/providers/message_provider.dart',
    'Your coins are on hold while we review a refunded purchase. ',
    _chatCode,
  ),
  BaselineEntry(
    'lib/features/messaging/providers/message_provider.dart',
    'Free gifts are still available.',
    _chatCode,
  ),
  BaselineEntry(
    'lib/features/messaging/providers/message_provider.dart',
    'You\'ve sent a lot of gifts in a short time. Please try again ',
    _chatCode,
  ),
  BaselineEntry(
    'lib/features/messaging/providers/message_provider.dart',
    'You\'ve sent today\'s free gift. A new one is available ',
    _chatCode,
  ),
  BaselineEntry(
    'lib/features/messaging/providers/message_provider.dart',
    'after midnight UTC.',
    _chatCode,
  ),
  BaselineEntry(
    'lib/features/messaging/providers/message_provider.dart',
    '\${gift.name} is not available right now.',
    _chatCode,
  ),
  BaselineEntry(
    'lib/features/messaging/providers/message_provider.dart',
    'Gifts can only be sent in an active match.',
    _chatCode,
  ),
  BaselineEntry(
    'lib/features/messaging/providers/message_provider.dart',
    'This exclusive gift can only be sent once today.',
    _chatCode,
  ),
  BaselineEntry(
    'lib/features/messaging/providers/message_provider.dart',
    'Failed to send gift.',
    _chatCode,
  ),
  BaselineEntry(
    'lib/features/messaging/providers/message_provider.dart',
    'Failed to send gift.',
    _chatCode,
  ),
  BaselineEntry(
    'lib/features/messaging/providers/message_provider.dart',
    'User session not available.',
    _chatCode,
  ),
  BaselineEntry(
    'lib/features/messaging/providers/message_provider.dart',
    'Hey! Great to match with you.',
    _mockData,
  ),
  BaselineEntry(
    'lib/features/messaging/providers/message_provider.dart',
    'Nice to meet you too!',
    _mockData,
  ),
  BaselineEntry(
    'lib/features/messaging/providers/message_provider.dart',
    'How was your weekend?',
    _mockData,
  ),
  BaselineEntry(
    'lib/features/payment/screens/subscription_screen.dart',
    'SANDBOX · advance the renewal clock',
    _sandboxOnly,
  ),
  BaselineEntry(
    'lib/features/plans/providers/plans_provider.dart',
    'Meera has a date with Dev',
    _mockData,
  ),
  BaselineEntry(
    'lib/features/plans/providers/plans_provider.dart',
    'Coffee · Koramangala',
    _mockData,
  ),
  BaselineEntry(
    'lib/features/profile/providers/profile_provider.dart',
    'Please login to view your profile.',
    _profileCode,
  ),
  BaselineEntry(
    'lib/features/profile/providers/profile_provider.dart',
    'No profile data found.',
    _profileCode,
  ),
  BaselineEntry(
    'lib/features/profile/providers/profile_provider.dart',
    'Failed to load profile. Please try again.',
    _profileCode,
  ),
  BaselineEntry(
    'lib/features/support/support_api.dart',
    'Upload response was empty.',
    _internalException,
  ),
  BaselineEntry(
    'lib/features/support/support_api.dart',
    'Unexpected response.',
    _internalException,
  ),
  BaselineEntry(
    'lib/features/swipe/providers/swipe_provider.dart',
    'Swipe request failed',
    _internalException,
  ),
  BaselineEntry('lib/main_simple.dart', 'Dating App', _debugEntryPoint),
  BaselineEntry('lib/main_simple.dart', '🎉 App is Running!', _debugEntryPoint),
  BaselineEntry(
    'lib/main_simple.dart',
    'Basic layout test passed',
    _debugEntryPoint,
  ),
];
