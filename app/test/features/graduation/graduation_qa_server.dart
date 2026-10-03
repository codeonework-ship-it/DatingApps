// A stateful fake BFF for one match's graduation, built on the recording
// QaApi (test/support/qa_api.dart): it answers the snapshot and applies every
// propose / decide / withdraw command to its own state, so tests assert both
// the exact request the app sent and what the screen shows afterwards.

import '../../support/qa_api.dart';

const gradMatchId = 'match-1';
const gradId = 'graduation-1';
const gradPartner = 'Arjun';
const gradNote = 'I think we found each other.';

const gradSnapshotPath = '/matches/$gradMatchId/graduation';
const gradProposePath = '/matches/$gradMatchId/graduation';
const gradDecisionPath = '/matches/$gradMatchId/graduation/$gradId/decision';
const gradWithdrawPath = '/matches/$gradMatchId/graduation/$gradId/withdraw';

/// A graduation row as the BFF returns it, seen by the signed-in member.
Map<String, dynamic> gradRow({
  String status = 'proposed',
  String viewerRole = 'partner',
  String nextAction = 'decide',
  String note = gradNote,
  bool shareWithFriends = false,
  int friendRecipients = 0,
}) => {
  'id': gradId,
  'match_id': gradMatchId,
  'proposer_user_id': viewerRole == 'proposer' ? 'me' : 'arjun-1',
  'partner_user_id': viewerRole == 'proposer' ? 'arjun-1' : 'me',
  'status': status,
  'note': note,
  'proposer_share_with_friends': true,
  'partner_share_with_friends': false,
  'created_at': '2026-09-27T10:00:00Z',
  'viewer_role': viewerRole,
  'other_user_id': 'arjun-1',
  'other_name': gradPartner,
  'share_with_friends': shareWithFriends,
  'next_action': nextAction,
  'friend_recipients': friendRecipients,
  'rewards': <Map<String, dynamic>>[],
};

/// The partner has been asked and decides.
Map<String, dynamic> gradDecide() => gradRow();

/// The member asked and waits for Arjun.
Map<String, dynamic> gradWaiting({bool share = true}) => gradRow(
  viewerRole: 'proposer',
  nextAction: 'await_decision',
  shareWithFriends: share,
);

/// Both confirmed; the member chose to tell friends and two were told.
Map<String, dynamic> gradConfirmed() => gradRow(
  status: 'confirmed',
  nextAction: 'celebrate',
  shareWithFriends: true,
  friendRecipients: 2,
);

class GradServer {
  GradServer({this.current}) {
    install();
  }

  final api = QaApi();

  /// The match's current graduation (null: nothing proposed).
  Map<String, dynamic>? current;

  Map<String, dynamic> get snapshot => {
    'match_id': gradMatchId,
    'graduation': current,
    'history': <dynamic>[],
    'graduated': current?['status'] == 'confirmed',
    'can_propose': current == null || current!['status'] != 'proposed',
    'unlock_state': 'conversation_unlocked',
    'discovery_paused': current?['status'] == 'confirmed',
  };

  /// (Re)installs the happy routes, e.g. after a test failed one of them.
  void install() {
    api
      ..clearRoutes()
      ..on('GET $gradSnapshotPath', (_) => qaOk(snapshot))
      ..on('POST $gradProposePath', (call) {
        current = gradRow(
          viewerRole: 'proposer',
          nextAction: 'await_decision',
          note: call.body['note']?.toString() ?? '',
          shareWithFriends: call.body['share_with_friends'] == true,
        );
        return QaReply(201, {'graduation': current});
      })
      ..on('POST /matches/$gradMatchId/graduation/*/decision', (call) {
        final confirm = call.body['decision'] == 'confirm';
        final share = call.body['share_with_friends'] == true;
        current = {
          ...?current,
          'status': confirm ? 'confirmed' : 'declined',
          'next_action': confirm ? 'celebrate' : 'propose',
          'share_with_friends': share,
          'friend_recipients': confirm && share ? 2 : 0,
        };
        return qaOk({'graduation': current});
      })
      ..on('POST /matches/$gradMatchId/graduation/*/withdraw', (_) {
        current = {
          ...?current,
          'status': 'withdrawn',
          'next_action': 'propose',
        };
        return qaOk({'graduation': current});
      });
  }
}
