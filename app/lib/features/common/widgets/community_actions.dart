import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_error_message.dart';
import '../../../core/providers/api_client_provider.dart';
import '../../../core/providers/safety_actions_provider.dart';
import '../../../l10n/app_localizations.dart';
import 'report_user_sheet.dart';

/// Asks before an action that cannot be undone. Resolves to false on dismiss.
Future<bool> confirmCommunityAction(
  BuildContext context, {
  required String title,
  required String message,
  required String action,
}) async =>
    await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(AppLocalizations.of(context).commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(action),
          ),
        ],
      ),
    ) ??
    false;

void showCommunitySnack(BuildContext context, String message) {
  if (!context.mounted) {
    return;
  }
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}

/// Reports a community item through the shared Open Chapters queue:
/// `POST /blog/reports/{kind}/{id}`.
///
/// Kinds used by member activities: `theme_entry`, `club`, `club_post`,
/// `review` and `list`.
Future<void> reportCommunityItem(
  BuildContext context,
  WidgetRef ref, {
  required String kind,
  required String id,
}) async {
  final l10n = AppLocalizations.of(context);
  final reportId = await showReportUserSheet(
    context: context,
    onSubmit: ({required reason, description}) async {
      try {
        final response = await ref
            .read(apiClientProvider)
            .post<dynamic>(
              '/blog/reports/$kind/$id',
              data: {'reason': reason, 'description': description ?? ''},
            );
        final data = response.data;
        final report = data is Map ? data['report'] : null;
        return report is Map ? report['id']?.toString() : null;
      } on Object catch (e) {
        throw Exception(
          apiErrorMessage(e, fallback: l10n.communityReportFailed),
        );
      }
    },
  );
  // The sheet closes on success; say so, as the other report flows do. A
  // failure message from an earlier try is replaced, not queued in front.
  if (reportId != null && context.mounted) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    showCommunitySnack(context, l10n.communityReportSubmitted);
  }
}

/// Confirms, then blocks [userId]. Resolves to true once the block is saved.
Future<bool> blockCommunityMember(
  BuildContext context,
  WidgetRef ref, {
  required String userId,
  required String name,
}) async {
  final l10n = AppLocalizations.of(context);
  final confirmed = await confirmCommunityAction(
    context,
    title: l10n.communityBlockTitle(name),
    message: l10n.communityBlockBody,
    action: l10n.communityBlockAction,
  );
  if (!confirmed) {
    return false;
  }
  try {
    await ref.read(safetyActionsProvider).blockUser(blockedUserId: userId);
    return true;
  } on Object catch (e) {
    if (context.mounted) {
      showCommunitySnack(
        context,
        apiErrorMessage(e, fallback: l10n.communityBlockFailed),
      );
    }
    return false;
  }
}
