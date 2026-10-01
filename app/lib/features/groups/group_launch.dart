import 'package:flutter/material.dart';

import 'create_group_screen.dart';
import 'group_detail_screen.dart';
import 'groups_screen.dart';

/// A friend offered as a group invitee.
typedef GroupInvitee = ({String userId, String name, String photoUrl});

/// Opens the create-group flow with [invitees] already selected, so a member
/// can turn friends into a community group or a private group.
///
/// Shared entry point used by the Friends screen. With friends preselected
/// the flow starts as a private group (just friends); the member can switch
/// to a community group by lifestyle. [kind] (`community` or `private`) and
/// [category] (a lifestyle slug) preselect those choices.
Future<void> openCreateGroup(
  BuildContext context, {
  List<GroupInvitee> invitees = const [],
  String? kind,
  String category = '',
}) => Navigator.of(context).push<void>(
  MaterialPageRoute(
    builder: (_) => CreateGroupScreen(
      invitees: invitees,
      initialKind: kind,
      initialCategory: category,
    ),
  ),
);

/// Opens the Groups home (your groups, invitations, discover by lifestyle).
Future<void> openGroups(BuildContext context) => Navigator.of(
  context,
).push<void>(MaterialPageRoute(builder: (_) => const GroupsScreen()));

/// Opens one group.
Future<void> openGroup(BuildContext context, String groupId) =>
    Navigator.of(context).push<void>(
      MaterialPageRoute(builder: (_) => GroupDetailScreen(groupId: groupId)),
    );
