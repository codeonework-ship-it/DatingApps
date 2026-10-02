import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/providers/api_client_provider.dart';
import '../../../l10n/app_localizations.dart';
import '../../auth/providers/auth_provider.dart';

/// Today's like and message allowance for the member's plan.
///
/// Read from the backend, which counts durable rows over the UTC day; the
/// app never tracks quotas locally. A 429 from `/swipe` or a message send
/// carries the same fields and is parsed with [DailyLimit.fromRefusal].
class DailyQuota {
  const DailyQuota({
    required this.limit,
    required this.used,
    required this.remaining,
    required this.unlimited,
    required this.resetsAt,
  });

  factory DailyQuota.fromJson(Map<String, dynamic> json) => DailyQuota(
    limit: (json['limit'] as num?)?.toInt() ?? -1,
    used: (json['used'] as num?)?.toInt() ?? 0,
    remaining: (json['remaining'] as num?)?.toInt() ?? -1,
    unlimited: json['unlimited'] == true || (json['limit'] as num?) == -1,
    resetsAt:
        DateTime.tryParse(json['resets_at']?.toString() ?? '') ??
        DateTime.now().toUtc(),
  );

  final int limit;
  final int used;
  final int remaining;
  final bool unlimited;
  final DateTime resetsAt;

  bool get exhausted => !unlimited && remaining <= 0;

  String label(String noun) =>
      unlimited ? 'Unlimited $noun' : '$remaining of $limit $noun left today';

  /// Translated [label] for the like allowance.
  String likesLabel(AppLocalizations l10n) => unlimited
      ? l10n.membershipQuotaUnlimitedLikes
      : l10n.membershipQuotaLikesLeftToday(remaining, limit);

  /// Translated [label] for the message allowance.
  String messagesLabel(AppLocalizations l10n) => unlimited
      ? l10n.membershipQuotaUnlimitedMessages
      : l10n.membershipQuotaMessagesLeftToday(remaining, limit);
}

class Entitlements {
  const Entitlements({
    required this.planId,
    required this.planName,
    required this.enforced,
    required this.likes,
    required this.messages,
  });

  factory Entitlements.fromJson(Map<String, dynamic> json) => Entitlements(
    planId: json['plan_id']?.toString() ?? 'free',
    planName: json['plan_name']?.toString() ?? 'Free',
    enforced: json['enforced'] == true,
    likes: DailyQuota.fromJson(
      (json['likes'] as Map?)?.cast<String, dynamic>() ?? const {},
    ),
    messages: DailyQuota.fromJson(
      (json['messages'] as Map?)?.cast<String, dynamic>() ?? const {},
    ),
  );

  final String planId;
  final String planName;
  final bool enforced;
  final DailyQuota likes;
  final DailyQuota messages;
}

/// The structured 429 the backend answers when a quota is used up.
class DailyLimit {
  const DailyLimit({
    required this.kind,
    required this.planName,
    required this.limit,
    required this.used,
    required this.resetsAt,
    required this.message,
  });

  /// Returns null when [body] is not a daily-limit refusal.
  static DailyLimit? fromRefusal(Object? body) {
    final map = (body as Map?)?.cast<String, dynamic>();
    final code = map?['error_code']?.toString() ?? '';
    if (map == null ||
        !code.startsWith('DAILY_') ||
        !code.endsWith('_LIMIT_REACHED')) {
      return null;
    }
    return DailyLimit(
      kind: code == 'DAILY_LIKE_LIMIT_REACHED' ? 'like' : 'message',
      planName: map['plan_name']?.toString() ?? 'Free',
      limit: (map['limit'] as num?)?.toInt() ?? 0,
      used: (map['used'] as num?)?.toInt() ?? 0,
      resetsAt:
          DateTime.tryParse(map['resets_at']?.toString() ?? '') ??
          DateTime.now().toUtc(),
      message: map['error']?.toString() ?? 'Daily limit reached.',
    );
  }

  final String kind;
  final String planName;
  final int limit;
  final int used;
  final DateTime resetsAt;
  final String message;

  String get headline => kind == 'like'
      ? "You've used today's $limit likes on $planName"
      : "You've used today's $limit messages on $planName";

  String get resetLabel {
    final local = resetsAt.toLocal();
    final h = local.hour.toString().padLeft(2, '0');
    final m = local.minute.toString().padLeft(2, '0');
    return 'Resets at $h:$m';
  }

  /// Translated [headline].
  String localizedHeadline(AppLocalizations l10n) => kind == 'like'
      ? l10n.membershipLikeLimitHeadline(limit, planName)
      : l10n.membershipMessageLimitHeadline(limit, planName);

  /// Translated [resetLabel]; [localeName] is
  /// `Localizations.localeOf(context).toString()`.
  String localizedResetLabel(AppLocalizations l10n, String localeName) =>
      l10n.membershipQuotaResetsAt(
        DateFormat.Hm(localeName).format(resetsAt.toLocal()),
      );
}

final entitlementsProvider = FutureProvider.autoDispose<Entitlements?>((
  ref,
) async {
  final userId = ref.watch(authNotifierProvider.select((a) => a.userId));
  if (userId == null || userId.isEmpty) {
    return null;
  }
  final response = await ref
      .read(apiClientProvider)
      .get<dynamic>('/billing/entitlements/$userId');
  final body = (response.data as Map?)?.cast<String, dynamic>() ?? const {};
  return Entitlements.fromJson(body);
});
