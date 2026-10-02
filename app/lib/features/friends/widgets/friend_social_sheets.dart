import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/layout/app_layout.dart';
import '../../../l10n/app_localizations.dart';
import '../providers/friend_social_provider.dart';
import '../providers/friends_provider.dart';

/// Write a vouch for an accepted friend. Resolves to true when sent.
Future<bool?> showVouchSheet({
  required BuildContext context,
  required FriendConnection friend,
}) => showModalBottomSheet<bool>(
  context: context,
  isScrollControlled: true,
  showDragHandle: true,
  useSafeArea: true,
  builder: (_) => _VouchSheet(friend: friend),
);

/// Introduce two accepted friends to each other. Resolves to true when made.
Future<bool?> showIntroSheet({
  required BuildContext context,
  required List<FriendConnection> friends,
  FriendConnection? preselected,
}) => showModalBottomSheet<bool>(
  context: context,
  isScrollControlled: true,
  showDragHandle: true,
  useSafeArea: true,
  builder: (_) => _IntroSheet(friends: friends, preselected: preselected),
);

class _VouchSheet extends ConsumerStatefulWidget {
  const _VouchSheet({required this.friend});

  final FriendConnection friend;

  @override
  ConsumerState<_VouchSheet> createState() => _VouchSheetState();
}

class _VouchSheetState extends ConsumerState<_VouchSheet> {
  final _text = TextEditingController();
  String? _error;
  bool _submitting = false;

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context);
    final text = _text.text.trim();
    if (text.length < 12) {
      setState(() => _error = l10n.friendsVouchTooShort(12));
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });
    final ok = await ref
        .read(friendSocialProvider.notifier)
        .writeVouch(forUserId: widget.friend.friendUserId, text: text);
    if (!mounted) {
      return;
    }
    if (!ok) {
      setState(() {
        _submitting = false;
        _error =
            ref.read(friendSocialProvider).errorText(l10n) ??
            l10n.friendsVouchSendFailed;
      });
      return;
    }
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              l10n.friendsVouchTitle(widget.friend.friendName),
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppLayout.space2),
            Text(
              l10n.friendsVouchBody,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppLayout.space4),
            TextField(
              key: const ValueKey('qa.friends.vouch_text'),
              controller: _text,
              maxLength: 200,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: l10n.friendsVouchLabel,
                hintText: l10n.friendsVouchHint,
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: AppLayout.space2),
              Text(
                _error!,
                key: const ValueKey('qa.friends.vouch_error'),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.error,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
            const SizedBox(height: AppLayout.space4),
            SizedBox(
              width: double.infinity,
              height: AppLayout.minTapTarget,
              child: FilledButton.icon(
                key: const ValueKey('qa.friends.vouch_submit'),
                onPressed: _submitting ? null : _submit,
                icon: const Icon(Icons.verified_outlined),
                label: Text(l10n.friendsVouchSend),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _IntroSheet extends ConsumerStatefulWidget {
  const _IntroSheet({required this.friends, this.preselected});

  final List<FriendConnection> friends;
  final FriendConnection? preselected;

  @override
  ConsumerState<_IntroSheet> createState() => _IntroSheetState();
}

class _IntroSheetState extends ConsumerState<_IntroSheet> {
  String? _first;
  String? _second;
  final _message = TextEditingController();
  String? _error;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _first = widget.preselected?.friendUserId;
  }

  @override
  void dispose() {
    _message.dispose();
    super.dispose();
  }

  List<FriendConnection> get _accepted =>
      widget.friends.where((f) => f.status == 'accepted').toList();

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context);
    final first = _first;
    final second = _second;
    if (first == null || second == null || first == second) {
      setState(() => _error = l10n.friendsIntroChooseTwo);
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });
    final ok = await ref
        .read(friendSocialProvider.notifier)
        .makeIntro(
          firstUserId: first,
          secondUserId: second,
          message: _message.text,
        );
    if (!mounted) {
      return;
    }
    if (!ok) {
      setState(() {
        _submitting = false;
        _error =
            ref.read(friendSocialProvider).errorText(l10n) ??
            l10n.friendsIntroMakeFailed;
      });
      return;
    }
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final accepted = _accepted;
    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              l10n.friendsIntroSheetTitle,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppLayout.space2),
            Text(
              l10n.friendsIntroSheetBody,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            if (accepted.length < 2) ...[
              const SizedBox(height: AppLayout.space4),
              Text(l10n.friendsIntroNeedTwo, style: theme.textTheme.bodyMedium),
            ] else ...[
              const SizedBox(height: AppLayout.space4),
              _FriendPicker(
                label: l10n.friendsFirstFriend,
                keyPrefix: 'qa.friends.intro_first',
                friends: accepted,
                selected: _first,
                exclude: _second,
                onChanged: (id) => setState(() => _first = id),
              ),
              const SizedBox(height: AppLayout.space3),
              _FriendPicker(
                label: l10n.friendsSecondFriend,
                keyPrefix: 'qa.friends.intro_second',
                friends: accepted,
                selected: _second,
                exclude: _first,
                onChanged: (id) => setState(() => _second = id),
              ),
              const SizedBox(height: AppLayout.space3),
              TextField(
                key: const ValueKey('qa.friends.intro_message'),
                controller: _message,
                maxLength: 200,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: l10n.friendsIntroWhyLabel,
                ),
              ),
            ],
            if (_error != null) ...[
              const SizedBox(height: AppLayout.space2),
              Text(
                _error!,
                key: const ValueKey('qa.friends.intro_error'),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.error,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
            const SizedBox(height: AppLayout.space4),
            SizedBox(
              width: double.infinity,
              height: AppLayout.minTapTarget,
              child: FilledButton.icon(
                key: const ValueKey('qa.friends.intro_submit'),
                onPressed: _submitting || accepted.length < 2 ? null : _submit,
                icon: const Icon(Icons.connect_without_contact_rounded),
                label: Text(l10n.friendsIntroSubmit),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FriendPicker extends StatelessWidget {
  const _FriendPicker({
    required this.label,
    required this.keyPrefix,
    required this.friends,
    required this.selected,
    required this.exclude,
    required this.onChanged,
  });

  final String label;
  final String keyPrefix;
  final List<FriendConnection> friends;
  final String? selected;
  final String? exclude;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: Theme.of(
          context,
        ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
      ),
      const SizedBox(height: AppLayout.space2),
      Wrap(
        spacing: AppLayout.space2,
        runSpacing: AppLayout.space2,
        children: [
          for (final friend in friends)
            if (friend.friendUserId != exclude)
              ChoiceChip(
                key: ValueKey('$keyPrefix.${friend.friendUserId}'),
                label: Text(friend.friendName),
                selected: selected == friend.friendUserId,
                onSelected: (_) => onChanged(friend.friendUserId),
              ),
        ],
      ),
    ],
  );
}
