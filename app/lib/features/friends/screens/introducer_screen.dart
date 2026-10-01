import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_error_message.dart';
import '../../../core/providers/api_client_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../../common/screens/account_data_screen.dart';
import '../../intentional_dating/dating_rhythm.dart';
import '../providers/introducer_provider.dart';

/// Shared Android/web workspace. It intentionally has no member navigation,
/// discovery deck, public profiles or outcome counters.
class IntroducerScreen extends ConsumerStatefulWidget {
  const IntroducerScreen({super.key, this.memberControls = false});
  final bool memberControls;
  @override
  ConsumerState<IntroducerScreen> createState() => _IntroducerScreenState();
}

class _IntroducerScreenState extends ConsumerState<IntroducerScreen> {
  final _codeInput = TextEditingController();
  final _note = TextEditingController();
  bool _busy = false, _photo = false, _city = false;
  String? _code, _error, _notice, _first, _second;
  @override
  void dispose() {
    _codeInput.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<bool> _run(
    Future<void> Function(Dio dio) action,
    String notice,
  ) async {
    if (_busy) return false;
    setState(() {
      _busy = true;
      _error = null;
      _notice = null;
    });
    try {
      await action(ref.read(apiClientProvider));
      if (!mounted) return false;
      ref.invalidate(introducerConnectionsProvider);
      ref.invalidate(introducerReceiptsProvider);
      setState(() {
        _notice = notice;
        _first = null;
        _second = null;
      });
      return true;
    } on Object catch (e) {
      if (mounted)
        setState(
          () => _error = apiErrorMessage(
            e,
            fallback:
                'We couldn’t save that. Refresh to check the latest permissions before trying again.',
          ),
        );
      return false;
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _refresh() async {
    ref.invalidate(introducerConnectionsProvider);
    ref.invalidate(introducerReceiptsProvider);
    await ref.read(introducerConnectionsProvider.future);
  }

  Future<void> _revoke(IntroducerConnection c) async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Remove permission for ${c.name}?'),
        content: const Text(
          'New and unanswered introductions will stop. An existing mutual match stays between the two people.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep permission'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remove permission'),
          ),
        ],
      ),
    );
    if (yes == true)
      await _run((dio) async {
        await dio.delete<dynamic>('/introducer/connections/${c.id}');
      }, 'Permission removed.');
  }

  @override
  Widget build(BuildContext context) {
    final member = widget.memberControls;
    final connections = ref.watch(introducerConnectionsProvider);
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: colors.surface,
      appBar: AppBar(
        title: Text(member ? 'Your introducers' : 'Connect · Friends'),
        actions: [
          IconButton(
            tooltip: 'Refresh permissions',
            onPressed: _busy
                ? null
                : () async {
                    try {
                      await _refresh();
                    } on Object {
                      /* The provider displays the retry state. */
                    }
                  },
            icon: const Icon(Icons.refresh_rounded),
          ),
          if (!member)
            PopupMenuButton<String>(
              tooltip: 'Account',
              onSelected: (choice) {
                if (choice == 'logout') {
                  ref.read(authNotifierProvider.notifier).logout();
                } else {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const AccountDataScreen(),
                    ),
                  );
                }
              },
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'data', child: Text('Account & privacy')),
                PopupMenuItem(value: 'logout', child: Text('Sign out')),
              ],
            ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 820),
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Container(
                padding: const EdgeInsets.all(26),
                decoration: BoxDecoration(
                  color: colors.primaryContainer,
                  borderRadius: BorderRadius.circular(28),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.diversity_1_rounded,
                      size: 38,
                      color: colors.onPrimaryContainer,
                    ),
                    const SizedBox(height: 18),
                    Text(
                      member
                          ? 'Good friends. Your say.'
                          : 'You know them.\nYou see the possibility.',
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(color: colors.onPrimaryContainer),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      member
                          ? 'Invite someone you trust to introduce you. They can join without a dating profile. You decide who gets permission and what a preview shares.'
                          : 'A little thoughtfulness can start something real. Bring together friends who have asked for your help.',
                      style: TextStyle(
                        color: colors.onPrimaryContainer,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              const _PrivacyNote(),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Semantics(
                    liveRegion: true,
                    child: Text(_error!, style: TextStyle(color: colors.error)),
                  ),
                ),
              if (_notice != null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Semantics(liveRegion: true, child: Text(_notice!)),
                ),
              const SizedBox(height: 20),
              if (member) _memberInvitation(colors) else _redeemInvitation(),
              const SizedBox(height: 28),
              Text(
                member ? 'People you choose' : 'Your small circle',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 10),
              connections.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, _) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'We couldn’t load permissions. Nothing has been changed.',
                    ),
                    TextButton(
                      onPressed: () =>
                          ref.invalidate(introducerConnectionsProvider),
                      child: const Text('Try again'),
                    ),
                  ],
                ),
                data: (items) => Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (items.isEmpty)
                      Text(
                        member
                            ? 'No introducers yet. Share an invitation with one trusted friend to get started.'
                            : 'Your circle starts with permission. Ask a friend on Connect for their invitation code.',
                      ),
                    for (final c in items)
                      Card(
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        child: Padding(
                          padding: const EdgeInsets.all(18),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                c.name,
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                c.status == 'pending'
                                    ? (member
                                          ? 'Wants your permission to introduce you.'
                                          : 'Waiting for your friend’s approval.')
                                    : c.status == 'paused'
                                    ? 'Introductions are paused.'
                                    : 'Permission to suggest introductions.',
                              ),
                              if (member) ...[
                                const SizedBox(height: 6),
                                Text(
                                  'Preview shared with a suggested date: name and optional age${c.sharePhoto ? ', photo' : ''}${c.shareCity ? ', city' : ''}.',
                                ),
                                if (c.status == 'pending')
                                  const Padding(
                                    padding: EdgeInsets.only(top: 8),
                                    child: Text(
                                      'Approving also turns on friend introductions. You can pause all introductions in Dating rhythm.',
                                    ),
                                  ),
                              ],
                              Wrap(
                                spacing: 10,
                                children: [
                                  if (member && c.status == 'pending')
                                    FilledButton(
                                      onPressed: _busy
                                          ? null
                                          : () => _run((dio) async {
                                              await dio.post<dynamic>(
                                                '/introducer/connections/${c.id}/approve',
                                              );
                                            }, '${c.name} now has your permission.'),
                                      child: const Text('Allow introductions'),
                                    ),
                                  TextButton(
                                    onPressed: _busy ? null : () => _revoke(c),
                                    child: Text(
                                      c.status == 'pending'
                                          ? 'Decline request'
                                          : 'Remove permission',
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    if (!member)
                      _composer(
                        items.where((c) => c.status == 'active').toList(),
                      ),
                  ],
                ),
              ),
              if (!member) ...[
                const SizedBox(height: 28),
                Text(
                  'Thoughtfully sent',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Their answers stay between them. Both people must say yes before a match is made.',
                ),
                ref
                    .watch(introducerReceiptsProvider)
                    .when(
                      loading: () => const LinearProgressIndicator(),
                      error: (_, _) => TextButton(
                        onPressed: () =>
                            ref.invalidate(introducerReceiptsProvider),
                        child: const Text('Reload sent introductions'),
                      ),
                      data: (items) => Column(
                        children: [
                          for (final intro in items)
                            ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: const Icon(
                                Icons.mark_email_read_outlined,
                              ),
                              title: Text(
                                '${intro.firstName} + ${intro.secondName}',
                              ),
                              subtitle: const Text(
                                'Sent · their decision is private',
                              ),
                            ),
                        ],
                      ),
                    ),
              ],
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _memberInvitation(ColorScheme colors) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text(
        '1. Choose the preview',
        style: Theme.of(context).textTheme.titleLarge,
      ),
      const SizedBox(height: 8),
      const Text(
        'A suggested date sees your name and age if you already show it. Your introducer sees only your name, never your profile or dating activity.',
      ),
      SwitchListTile(
        contentPadding: EdgeInsets.zero,
        title: const Text('Include my profile photo'),
        value: _photo,
        onChanged: _busy || _code != null
            ? null
            : (v) => setState(() {
                _photo = v;
                _code = null;
              }),
      ),
      SwitchListTile(
        contentPadding: EdgeInsets.zero,
        title: const Text('Include my city'),
        value: _city,
        onChanged: _busy || _code != null
            ? null
            : (v) => setState(() {
                _city = v;
                _code = null;
              }),
      ),
      const SizedBox(height: 12),
      Text(
        '2. Invite one trusted friend',
        style: Theme.of(context).textTheme.titleLarge,
      ),
      const SizedBox(height: 8),
      const Text(
        'The code works once and expires in 48 hours. Your friend joins through “Just here to introduce friends” on the welcome screen. You’ll approve their name here before anything can be shared.',
      ),
      const SizedBox(height: 12),
      FilledButton.icon(
        onPressed: _busy
            ? null
            : () => _run((dio) async {
                final response = await dio.post<dynamic>(
                  '/introducer/invites',
                  data: {'share_photo': _photo, 'share_city': _city},
                );
                if (mounted)
                  setState(() => _code = response.data['code'] as String);
              }, 'Invitation ready. Any previous unused code no longer works.'),
        icon: const Icon(Icons.add_link),
        label: const Text('Create invitation code'),
      ),
      if (_code != null)
        Container(
          margin: const EdgeInsets.only(top: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(color: colors.outlineVariant),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Share privately with your friend. To change this preview, cancel the unused invitation and create a new code.',
              ),
              const SizedBox(height: 8),
              SelectableText(_code!),
              TextButton.icon(
                onPressed: () async {
                  await Clipboard.setData(ClipboardData(text: _code!));
                  if (mounted)
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Invitation code copied')),
                    );
                },
                icon: const Icon(Icons.copy),
                label: const Text('Copy code'),
              ),
            ],
          ),
        ),
      TextButton(
        onPressed: _busy
            ? null
            : () => _run((dio) async {
                await dio.delete<dynamic>('/introducer/invites');
                if (mounted) setState(() => _code = null);
              }, 'Unused invitations cancelled.'),
        child: const Text('Cancel unused invitations'),
      ),
      TextButton.icon(
        onPressed: () async {
          await openDatingRhythm(context);
          if (mounted) ref.invalidate(introducerConnectionsProvider);
        },
        icon: const Icon(Icons.tune),
        label: const Text('Manage all introduction preferences'),
      ),
    ],
  );

  Widget _redeemInvitation() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text(
        'A friend invited you?',
        style: Theme.of(context).textTheme.titleLarge,
      ),
      const SizedBox(height: 8),
      const Text(
        'Paste their private invitation code. They’ll confirm your name before you can introduce them.',
      ),
      const SizedBox(height: 14),
      TextField(
        controller: _codeInput,
        enabled: !_busy,
        autocorrect: false,
        decoration: const InputDecoration(
          labelText: 'Invitation code',
          border: OutlineInputBorder(),
        ),
      ),
      const SizedBox(height: 10),
      FilledButton(
        onPressed: _busy
            ? null
            : () async {
                if (_codeInput.text.trim().isEmpty) {
                  setState(
                    () => _error =
                        'Enter the invitation code your friend shared.',
                  );
                  return;
                }
                if (await _run(
                  (dio) async {
                    await dio.post<dynamic>(
                      '/introducer/redeem',
                      data: {'code': _codeInput.text.trim()},
                    );
                  },
                  'Request sent. Your friend can now approve you in Your introducers.',
                ))
                  _codeInput.clear();
              },
        child: const Text('Ask for permission'),
      ),
    ],
  );

  Widget _composer(List<IntroducerConnection> people) {
    if (people.length < 2)
      return const Padding(
        padding: EdgeInsets.only(top: 22),
        child: Text(
          'Once two friends give permission, you can suggest an introduction here.',
        ),
      );
    final first = people.any((c) => c.userId == _first) ? _first : null;
    final second = people.any((c) => c.userId == _second && c.userId != first)
        ? _second
        : null;
    return Padding(
      padding: const EdgeInsets.only(top: 26),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'See a possibility?',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            key: ValueKey('first-$first'),
            value: first,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'First friend'),
            items: [
              for (final c in people)
                DropdownMenuItem(value: c.userId, child: Text(c.name)),
            ],
            onChanged: _busy
                ? null
                : (v) => setState(() {
                    _first = v;
                    if (_second == v) _second = null;
                  }),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            key: ValueKey('second-$second'),
            value: second,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Second friend'),
            items: [
              for (final c in people.where((c) => c.userId != first))
                DropdownMenuItem(value: c.userId, child: Text(c.name)),
            ],
            onChanged: _busy ? null : (v) => setState(() => _second = v),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _note,
            enabled: !_busy,
            maxLength: 200,
            minLines: 2,
            maxLines: 4,
            decoration: const InputDecoration(
              labelText: 'Why you thought of them (optional)',
              helperText: 'Both will see this. Keep private details out.',
              helperMaxLines: 3,
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: _busy || first == null || second == null
                ? null
                : () async {
                    final id = ref.read(authNotifierProvider).userId;
                    if (await _run((dio) async {
                      await dio.post<dynamic>(
                        '/friends/$id/intros',
                        data: {
                          'first_user_id': first,
                          'second_user_id': second,
                          'message': _note.text.trim(),
                        },
                      );
                    }, 'Introduction sent. They can each decide in private.'))
                      _note.clear();
                  },
            icon: const Icon(Icons.favorite_border),
            label: const Text('Suggest an introduction'),
          ),
        ],
      ),
    );
  }
}

class _PrivacyNote extends StatelessWidget {
  const _PrivacyNote();
  @override
  Widget build(BuildContext context) => const Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(Icons.lock_outline, size: 20),
      SizedBox(width: 10),
      Expanded(
        child: Text(
          'Permission first. No public dating activity. No updates on who said yes or no.',
          style: TextStyle(height: 1.5),
        ),
      ),
    ],
  );
}
