import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/feature_flags.dart';
import '../../../core/network/api_error_message.dart';
import '../../../core/providers/api_client_provider.dart';
import '../../../core/utils/logger.dart';
import '../../auth/providers/auth_provider.dart';

/// A copilot draft: text in the member's own voice, never sent by the app.
class CopilotDraft {
  const CopilotDraft({
    required this.id,
    required this.kind,
    required this.tone,
    required this.text,
    required this.provider,
    required this.disclosure,
    required this.remainingToday,
  });

  factory CopilotDraft.fromJson(Map<String, dynamic> json) => CopilotDraft(
    id: json['draft_id']?.toString() ?? '',
    kind: json['kind']?.toString() ?? 'opener',
    tone: json['tone']?.toString() ?? 'warm',
    text: json['text']?.toString() ?? '',
    provider: json['provider']?.toString() ?? '',
    disclosure: json['disclosure']?.toString() ?? '',
    remainingToday: (json['drafts_remaining_today'] as num?)?.toInt() ?? 0,
  );

  final String id;
  final String kind;
  final String tone;
  final String text;
  final String provider;
  final String disclosure;
  final int remainingToday;
}

/// A local copilot failure the sheet shows in the reader's language.
enum CopilotFailure { empty, unavailable }

class CopilotException implements Exception {
  const CopilotException(this.message, {this.failure});

  final String message;

  /// Set when [message] is the app's own fallback rather than server text.
  final CopilotFailure? failure;

  @override
  String toString() => message;
}

/// Asks the BFF for a draft. Throws [CopilotException] with a member-facing
/// message on failure.
class CopilotClient {
  const CopilotClient(this.ref);

  final Ref ref;

  Future<CopilotDraft> draft({
    required String matchId,
    required String kind,
    String tone = 'warm',
  }) async {
    if (kUseMockAuth) {
      return CopilotDraft(
        id: 'mock-draft',
        kind: kind,
        tone: tone,
        text: kind == 'plan_idea'
            ? 'Want to turn this into a coffee this week? I can propose a '
                  'time here.'
            : 'Hi! I noticed bouldering on your profile. What got you '
                  'started?',
        provider: 'template',
        disclosure:
            'Say it in your own words. If you send it as drafted, they will '
            'see it was written with help.',
        remainingToday: 9,
      );
    }
    try {
      final response = await ref
          .read(apiClientProvider)
          .post<dynamic>(
            '/matches/$matchId/copilot/draft',
            data: <String, dynamic>{'kind': kind, 'tone': tone},
          );
      final body = (response.data as Map?)?.cast<String, dynamic>() ?? {};
      final draft = body['draft'];
      if (draft is! Map<dynamic, dynamic>) {
        throw const CopilotException(
          'The copilot returned nothing.',
          failure: CopilotFailure.empty,
        );
      }
      return CopilotDraft.fromJson(draft.cast<String, dynamic>());
    } on CopilotException {
      rethrow;
    } on Object catch (error) {
      log.error('Copilot draft failed', error);
      throw CopilotException(
        apiErrorMessage(error, fallback: 'The copilot is unavailable.'),
        failure: apiErrorMessage(error, fallback: '').isEmpty
            ? CopilotFailure.unavailable
            : null,
      );
    }
  }
}

final copilotClientProvider = Provider<CopilotClient>(CopilotClient.new);

/// Verified-human state of a conversation.
class ConversationTrust {
  const ConversationTrust({
    required this.humanVerified,
    required this.partnerVerified,
    required this.viewerVerified,
    required this.partnerBadges,
    required this.assistedMessages,
  });

  factory ConversationTrust.fromJson(Map<String, dynamic> json) =>
      ConversationTrust(
        humanVerified: json['human_verified'] as bool? ?? false,
        partnerVerified: json['partner_verified'] as bool? ?? false,
        viewerVerified: json['viewer_verified'] as bool? ?? false,
        partnerBadges:
            (json['partner_badges'] as List<dynamic>? ?? const <dynamic>[])
                .map((item) => item.toString())
                .toList(),
        assistedMessages: (json['assisted_messages'] as num?)?.toInt() ?? 0,
      );

  final bool humanVerified;
  final bool partnerVerified;
  final bool viewerVerified;
  final List<String> partnerBadges;
  final int assistedMessages;

  bool get partnerShowsUp => partnerBadges.contains('shows_up');
}

final conversationTrustProvider =
    FutureProvider.family<ConversationTrust?, String>((ref, matchId) async {
      // Per member: never show the previous member's conversation.
      watchSignedInUserId(ref);
      if (matchId.isEmpty || matchId.startsWith('pending-')) {
        return null;
      }
      if (kUseMockAuth) {
        return const ConversationTrust(
          humanVerified: true,
          partnerVerified: true,
          viewerVerified: true,
          partnerBadges: <String>['shows_up'],
          assistedMessages: 0,
        );
      }
      try {
        final response = await ref
            .read(apiClientProvider)
            .get<dynamic>('/matches/$matchId/trust');
        final body = (response.data as Map?)?.cast<String, dynamic>() ?? {};
        final trust = body['trust'];
        if (trust is! Map<dynamic, dynamic>) {
          return null;
        }
        return ConversationTrust.fromJson(trust.cast<String, dynamic>());
      } on Object catch (error) {
        log.error('Conversation trust load failed', error);
        return null;
      }
    });
