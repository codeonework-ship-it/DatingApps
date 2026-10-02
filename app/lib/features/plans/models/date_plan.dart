/// Date plans: a matched pair turns a conversation into a concrete plan, and
/// Sharing with trusted contacts is opt-in for each member and each plan. Mirrors `matching.match_date_plans`.
///
/// This file is pure Dart. The labels below are the en-US fallbacks; widgets
/// render the member's language through `date_plan_labels.dart`.
library;

import 'package:intl/intl.dart';

/// en-US venue labels, keyed by wire category. Widgets use
/// `datePlanVenueLabel` (date_plan_labels.dart) instead.
const Map<String, String> datePlanVenueLabels = <String, String>{
  'coffee': 'Coffee',
  'meal': 'A meal',
  'drinks': 'Drinks',
  'walk': 'A walk',
  'activity': 'An activity',
  'event': 'An event',
  'video_call': 'Video call',
  'other': 'Something else',
};

const List<String> datePlanVenueOrder = <String>[
  'coffee',
  'meal',
  'drinks',
  'walk',
  'activity',
  'event',
  'video_call',
  'other',
];

/// Which date plan request failed. Providers set it when the server sent no
/// message of its own, so widgets can show the fallback in the member's
/// language (`datePlanFailureMessage` in date_plan_labels.dart).
enum DatePlanFailure {
  load,
  feed,
  propose,
  accept,
  decline,
  cancel,
  checkin,
  debrief,
}

class DatePlanCheckin {
  const DatePlanCheckin({
    required this.userId,
    required this.status,
    required this.at,
    this.note = '',
  });

  factory DatePlanCheckin.fromJson(Map<String, dynamic> json) =>
      DatePlanCheckin(
        userId: json['user_id']?.toString() ?? '',
        status: json['status']?.toString() ?? '',
        at: _parseTime(json['at']),
        note: json['note']?.toString() ?? '',
      );

  final String userId;
  final String status;
  final DateTime at;
  final String note;

  bool get isSafe => status == 'safe';
}

/// One member's private post-date answers.
class DatePlanDebrief {
  const DatePlanDebrief({
    required this.happened,
    this.wouldMeetAgain,
    this.feltSafe,
    this.note = '',
    this.shareMutualInterest = false,
  });

  factory DatePlanDebrief.fromJson(Map<String, dynamic> json) =>
      DatePlanDebrief(
        happened: json['happened'] as bool? ?? false,
        shareMutualInterest: json['share_mutual_interest'] as bool? ?? false,
        wouldMeetAgain: json['would_meet_again'] as bool?,
        feltSafe: json['felt_safe'] as bool?,
        note: json['note']?.toString() ?? '',
      );

  final bool happened;
  final bool shareMutualInterest;
  final bool? wouldMeetAgain;
  final bool? feltSafe;
  final String note;
}

class DatePlan {
  const DatePlan({
    required this.id,
    required this.matchId,
    required this.proposerUserId,
    required this.inviteeUserId,
    required this.status,
    required this.windowStart,
    required this.windowEnd,
    required this.venueCategory,
    required this.checkinDueAt,
    required this.viewerRole,
    required this.partnerUserId,
    required this.partnerName,
    required this.nextAction,
    this.venueName = '',
    this.venueArea = '',
    this.note = '',
    this.proposerGroupIds = const <String>[],
    this.inviteeGroupIds = const <String>[],
    this.cancelReason = '',
    this.checkins = const <DatePlanCheckin>[],
    this.friendRecipients = 0,
    this.debrief,
    this.partnerDebriefed = false,
    this.resolvedStatus = '',
    this.lockVersion = 0,
    this.budgetPreference = 'flexible',
    this.atmospherePreferences = const <String>[],
    this.accessibilityPreferences = const <String>[],
    this.mutualSecondYes = false,
  });

  factory DatePlan.fromJson(Map<String, dynamic> json) => DatePlan(
    id: json['id']?.toString() ?? '',
    matchId: json['match_id']?.toString() ?? '',
    proposerUserId: json['proposer_user_id']?.toString() ?? '',
    inviteeUserId: json['invitee_user_id']?.toString() ?? '',
    status: json['status']?.toString() ?? 'proposed',
    windowStart: _parseTime(json['window_start']),
    windowEnd: _parseTime(json['window_end']),
    venueCategory: json['venue_category']?.toString() ?? 'other',
    venueName: json['venue_name']?.toString() ?? '',
    venueArea: json['venue_area']?.toString() ?? '',
    note: json['note']?.toString() ?? '',
    proposerGroupIds: _stringList(json['proposer_group_ids']),
    inviteeGroupIds: _stringList(json['invitee_group_ids']),
    checkinDueAt: _parseTime(json['checkin_due_at']),
    cancelReason: json['cancel_reason']?.toString() ?? '',
    viewerRole: json['viewer_role']?.toString() ?? 'observer',
    partnerUserId: json['partner_user_id']?.toString() ?? '',
    partnerName: json['partner_name']?.toString() ?? 'Your match',
    nextAction: json['next_action']?.toString() ?? 'none',
    checkins: (json['checkins'] as List<dynamic>? ?? const <dynamic>[])
        .whereType<Map<dynamic, dynamic>>()
        .map((row) => DatePlanCheckin.fromJson(row.cast<String, dynamic>()))
        .toList(),
    friendRecipients: (json['friend_recipients'] as num?)?.toInt() ?? 0,
    debrief: json['debrief'] is Map<dynamic, dynamic>
        ? DatePlanDebrief.fromJson(
            (json['debrief'] as Map<dynamic, dynamic>).cast<String, dynamic>(),
          )
        : null,
    partnerDebriefed: json['partner_debriefed'] as bool? ?? false,
    resolvedStatus: json['resolved_status']?.toString() ?? '',
    lockVersion: (json['lock_version'] as num?)?.toInt() ?? 0,
    budgetPreference: json['budget_preference']?.toString() ?? 'flexible',
    atmospherePreferences: _stringList(json['atmosphere_preferences']),
    accessibilityPreferences: _stringList(json['accessibility_preferences']),
    mutualSecondYes: json['mutual_second_yes'] as bool? ?? false,
  );

  final String id;
  final String matchId;
  final String proposerUserId;
  final String inviteeUserId;
  final String status;
  final DateTime windowStart;
  final DateTime windowEnd;
  final String venueCategory;
  final String venueName;
  final String venueArea;
  final String note;
  final List<String> proposerGroupIds;
  final List<String> inviteeGroupIds;
  final DateTime checkinDueAt;
  final String cancelReason;
  final String viewerRole;
  final String partnerUserId;
  final String partnerName;
  final String nextAction;
  final List<DatePlanCheckin> checkins;
  final int friendRecipients;
  final DatePlanDebrief? debrief;
  final bool partnerDebriefed;
  final String resolvedStatus;
  final int lockVersion;
  final String budgetPreference;
  final List<String> atmospherePreferences, accessibilityPreferences;
  final bool mutualSecondYes;

  bool get isOpen => status == 'proposed' || status == 'accepted';
  bool get isAccepted => status == 'accepted';
  bool get isProposed => status == 'proposed';
  bool get viewerIsInvitee => viewerRole == 'invitee';

  /// en-US venue label; widgets use `datePlanVenueLabel` for the member's
  /// language.
  String get venueLabel =>
      datePlanVenueLabels[venueCategory] ?? datePlanVenueLabels['other']!;

  /// One line, en-US: "Sat 28 Sep · 16:00–18:00 · Coffee · Indiranagar".
  /// Widgets use `localizedSummary` (date_plan_labels.dart).
  String get summary {
    final parts = <String>[
      describeDatePlanWindow(windowStart, windowEnd),
      venueLabel,
      if (venueName.isNotEmpty) venueName,
      if (venueArea.isNotEmpty) venueArea,
    ];
    return parts.join(' · ');
  }

  DatePlanCheckin? checkinFor(String userId) {
    for (final checkin in checkins) {
      if (checkin.userId == userId) {
        return checkin;
      }
    }
    return null;
  }
}

class DatePlanShareGroup {
  const DatePlanShareGroup({required this.id, required this.name});

  factory DatePlanShareGroup.fromJson(Map<String, dynamic> json) =>
      DatePlanShareGroup(
        id: json['id']?.toString() ?? '',
        name: json['name']?.toString() ?? 'Group',
      );

  final String id;
  final String name;
}

/// What `GET /matches/{id}/plans` returns.
class MatchPlansSnapshot {
  const MatchPlansSnapshot({
    this.plan,
    this.history = const <DatePlan>[],
    this.shareGroups = const <DatePlanShareGroup>[],
    this.canPropose = false,
    this.unlockState = '',
  });

  factory MatchPlansSnapshot.fromJson(Map<String, dynamic> json) {
    final open = json['plan'];
    return MatchPlansSnapshot(
      plan: open is Map<dynamic, dynamic>
          ? DatePlan.fromJson(open.cast<String, dynamic>())
          : null,
      history: (json['history'] as List<dynamic>? ?? const <dynamic>[])
          .whereType<Map<dynamic, dynamic>>()
          .map((row) => DatePlan.fromJson(row.cast<String, dynamic>()))
          .toList(),
      shareGroups: (json['share_groups'] as List<dynamic>? ?? const <dynamic>[])
          .whereType<Map<dynamic, dynamic>>()
          .map(
            (row) => DatePlanShareGroup.fromJson(row.cast<String, dynamic>()),
          )
          .toList(),
      canPropose: json['can_propose'] as bool? ?? false,
      unlockState: json['unlock_state']?.toString() ?? '',
    );
  }

  final DatePlan? plan;
  final List<DatePlan> history;
  final List<DatePlanShareGroup> shareGroups;
  final bool canPropose;
  final String unlockState;
}

/// A friend's plan as shown to the people they shared it with.
class FriendPlan {
  const FriendPlan({
    required this.planId,
    required this.friendUserId,
    required this.friendName,
    required this.partnerName,
    required this.status,
    required this.latestUpdate,
    required this.title,
    required this.description,
    required this.windowStart,
    required this.windowEnd,
    required this.venueCategory,
    required this.via,
    required this.updatedAt,
    this.venueArea = '',
    this.checkins = const <DatePlanCheckin>[],
  });

  factory FriendPlan.fromJson(Map<String, dynamic> json) => FriendPlan(
    planId: json['plan_id']?.toString() ?? '',
    friendUserId: json['friend_user_id']?.toString() ?? '',
    friendName: json['friend_name']?.toString() ?? 'A friend',
    partnerName: json['partner_name']?.toString() ?? 'a match',
    status: json['status']?.toString() ?? '',
    latestUpdate: json['latest_update']?.toString() ?? '',
    title: json['title']?.toString() ?? '',
    description: json['description']?.toString() ?? '',
    windowStart: _parseTime(json['window_start']),
    windowEnd: _parseTime(json['window_end']),
    venueCategory: json['venue_category']?.toString() ?? 'other',
    venueArea: json['venue_area']?.toString() ?? '',
    via: json['via']?.toString() ?? 'friend',
    updatedAt: _parseTime(json['updated_at']),
    checkins: (json['checkins'] as List<dynamic>? ?? const <dynamic>[])
        .whereType<Map<dynamic, dynamic>>()
        .map((row) => DatePlanCheckin.fromJson(row.cast<String, dynamic>()))
        .toList(),
  );

  final String planId;
  final String friendUserId;
  final String friendName;
  final String partnerName;
  final String status;
  final String latestUpdate;
  final String title;
  final String description;
  final DateTime windowStart;
  final DateTime windowEnd;
  final String venueCategory;
  final String venueArea;
  final String via;
  final DateTime updatedAt;
  final List<DatePlanCheckin> checkins;

  bool get needsHelp => latestUpdate == 'need_help';
  bool get missedCheckin => latestUpdate == 'checkin_missed';
  bool get checkedInSafe => checkins.any((c) => c.isSafe);
  String get venueLabel =>
      datePlanVenueLabels[venueCategory] ?? datePlanVenueLabels['other']!;
}

const List<String> _weekdays = <String>[
  'Mon',
  'Tue',
  'Wed',
  'Thu',
  'Fri',
  'Sat',
  'Sun',
];
const List<String> _months = <String>[
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

String _two(int value) => value.toString().padLeft(2, '0');

/// "Sat 28 Sep" in the viewer's local time.
///
/// With a [locale] (`Localizations.localeOf(context).toString()`) the day is
/// formatted with that locale's date symbols ("Sa. 28. Sep.", "сб 28 сент."),
/// which `flutter_localizations` loads for every supported locale. Without
/// one, or when the symbols are not loaded, it falls back to English.
String describeDatePlanDay(DateTime value, {String? locale}) {
  final local = value.toLocal();
  if (locale != null && locale.isNotEmpty) {
    try {
      return DateFormat('EEE d MMM', locale).format(local);
    } on Object {
      // Date symbols for this locale are not loaded: English fallback.
    }
  }
  return '${_weekdays[local.weekday - 1]} ${local.day} '
      '${_months[local.month - 1]}';
}

String describeDatePlanTime(DateTime value) {
  final local = value.toLocal();
  return '${_two(local.hour)}:${_two(local.minute)}';
}

/// "Sat 28 Sep · 16:00–18:00" in the viewer's local time; see
/// [describeDatePlanDay] for [locale].
String describeDatePlanWindow(DateTime start, DateTime end, {String? locale}) =>
    '${describeDatePlanDay(start, locale: locale)} · '
    '${describeDatePlanTime(start)}–${describeDatePlanTime(end)}';

DateTime _parseTime(Object? value) {
  final raw = value?.toString() ?? '';
  return DateTime.tryParse(raw)?.toUtc() ??
      DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
}

List<String> _stringList(Object? value) => (value as List<dynamic>? ?? const [])
    .map((item) => item.toString())
    .toList();
