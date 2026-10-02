import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_error_message.dart';
import '../../../core/providers/api_client_provider.dart';
import '../../../l10n/app_localizations.dart';
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
    final failed = AppLocalizations.of(context).friendsIntroducerSaveFailed;
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
        setState(() => _error = apiErrorMessage(e, fallback: failed));
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
    final l10n = AppLocalizations.of(context);
    final yes = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.friendsIntroducerRevokeTitle(c.name)),
        content: Text(l10n.friendsIntroducerRevokeBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.friendsIntroducerKeepPermission),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.friendsIntroducerRemovePermission),
          ),
        ],
      ),
    );
    if (yes == true)
      await _run((dio) async {
        await dio.delete<dynamic>('/introducer/connections/${c.id}');
      }, l10n.friendsIntroducerPermissionRemoved);
  }

  @override
  Widget build(BuildContext context) {
    final member = widget.memberControls;
    final connections = ref.watch(introducerConnectionsProvider);
    final colors = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: colors.surface,
      appBar: AppBar(
        title: Text(
          member
              ? l10n.friendsIntroducerMemberTitle
              : l10n.friendsIntroducerAppTitle,
        ),
        actions: [
          IconButton(
            tooltip: l10n.friendsIntroducerRefresh,
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
              tooltip: l10n.friendsIntroducerAccount,
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
              itemBuilder: (_) => [
                PopupMenuItem(
                  value: 'data',
                  child: Text(l10n.friendsIntroducerAccountPrivacy),
                ),
                PopupMenuItem(
                  value: 'logout',
                  child: Text(l10n.friendsIntroducerSignOut),
                ),
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
                padding: const EdgeInsets.all(28),
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
                          ? l10n.friendsIntroducerMemberHeadline
                          : l10n.friendsIntroducerHeadline,
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(color: colors.onPrimaryContainer),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      member
                          ? l10n.friendsIntroducerMemberIntro
                          : l10n.friendsIntroducerIntro,
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
                member
                    ? l10n.friendsIntroducerMemberListTitle
                    : l10n.friendsIntroducerListTitle,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 10),
              connections.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, _) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.friendsIntroducerLoadFailed),
                    TextButton(
                      onPressed: () =>
                          ref.invalidate(introducerConnectionsProvider),
                      child: Text(l10n.chatTryAgain),
                    ),
                  ],
                ),
                data: (items) => Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (items.isEmpty)
                      Text(
                        member
                            ? l10n.friendsIntroducerMemberEmpty
                            : l10n.friendsIntroducerEmpty,
                      ),
                    for (final c in items)
                      Card(
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                c.name,
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: 6),
                              Text(_statusText(l10n, c)),
                              if (member) ...[
                                const SizedBox(height: 6),
                                Text(
                                  l10n.friendsIntroducerPreview(
                                    c.sharePhoto && c.shareCity
                                        ? 'both'
                                        : c.sharePhoto
                                        ? 'photo'
                                        : c.shareCity
                                        ? 'city'
                                        : 'none',
                                  ),
                                ),
                                if (c.status == 'pending')
                                  Padding(
                                    padding: const EdgeInsets.only(top: 8),
                                    child: Text(
                                      l10n.friendsIntroducerApproveNote,
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
                                          : () => _run(
                                              (dio) async {
                                                await dio.post<dynamic>(
                                                  '/introducer/connections/${c.id}/approve',
                                                );
                                              },
                                              l10n.friendsIntroducerAllowed(
                                                c.name,
                                              ),
                                            ),
                                      child: Text(l10n.friendsIntroducerAllow),
                                    ),
                                  TextButton(
                                    onPressed: _busy ? null : () => _revoke(c),
                                    child: Text(
                                      c.status == 'pending'
                                          ? l10n.friendsIntroducerDecline
                                          : _removeLabel(l10n),
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
                  l10n.friendsIntroducerSentTitle,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(l10n.friendsIntroducerSentBody),
                ref
                    .watch(introducerReceiptsProvider)
                    .when(
                      loading: () => const LinearProgressIndicator(),
                      error: (_, _) => TextButton(
                        onPressed: () =>
                            ref.invalidate(introducerReceiptsProvider),
                        child: Text(l10n.friendsIntroducerReloadSent),
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
                              subtitle: Text(
                                l10n.friendsIntroducerSentSubtitle,
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

  String _statusText(AppLocalizations l10n, IntroducerConnection c) =>
      switch (c.status) {
        'pending' when widget.memberControls =>
          l10n.friendsIntroducerStatusPendingMember,
        'pending' => l10n.friendsIntroducerStatusPending,
        'paused' => l10n.friendsIntroducerStatusPaused,
        _ => l10n.friendsIntroducerStatusActive,
      };

  String _removeLabel(AppLocalizations l10n) =>
      l10n.friendsIntroducerRemovePermission;

  Widget _memberInvitation(ColorScheme colors) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.friendsIntroducerStepPreview,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        Text(l10n.friendsIntroducerPreviewBody),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(l10n.friendsIntroducerIncludePhoto),
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
          title: Text(l10n.friendsIntroducerIncludeCity),
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
          l10n.friendsIntroducerStepInvite,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        Text(l10n.friendsIntroducerInviteBody),
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
                }, l10n.friendsIntroducerInviteReady),
          icon: const Icon(Icons.add_link),
          label: Text(l10n.friendsIntroducerCreateCode),
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
                Text(l10n.friendsIntroducerShareCode),
                const SizedBox(height: 8),
                SelectableText(_code!),
                TextButton.icon(
                  onPressed: () async {
                    await Clipboard.setData(ClipboardData(text: _code!));
                    if (mounted)
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(l10n.friendsIntroducerCodeCopied),
                        ),
                      );
                  },
                  icon: const Icon(Icons.copy),
                  label: Text(l10n.friendsIntroducerCopyCode),
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
                }, l10n.friendsIntroducerInvitesCancelled),
          child: Text(l10n.friendsIntroducerCancelInvites),
        ),
        TextButton.icon(
          onPressed: () async {
            await openDatingRhythm(context);
            if (mounted) ref.invalidate(introducerConnectionsProvider);
          },
          icon: const Icon(Icons.tune),
          label: Text(l10n.friendsIntroducerManagePrefs),
        ),
      ],
    );
  }

  Widget _redeemInvitation() {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.friendsIntroducerRedeemTitle,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        Text(l10n.friendsIntroducerRedeemBody),
        const SizedBox(height: 14),
        TextField(
          controller: _codeInput,
          enabled: !_busy,
          autocorrect: false,
          decoration: InputDecoration(
            labelText: l10n.friendsIntroducerCodeLabel,
            border: const OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 10),
        FilledButton(
          onPressed: _busy
              ? null
              : () async {
                  if (_codeInput.text.trim().isEmpty) {
                    setState(() => _error = l10n.friendsIntroducerCodeMissing);
                    return;
                  }
                  if (await _run((dio) async {
                    await dio.post<dynamic>(
                      '/introducer/redeem',
                      data: {'code': _codeInput.text.trim()},
                    );
                  }, l10n.friendsIntroducerRequestSent))
                    _codeInput.clear();
                },
          child: Text(l10n.friendsIntroducerAskPermission),
        ),
      ],
    );
  }

  Widget _composer(List<IntroducerConnection> people) {
    final l10n = AppLocalizations.of(context);
    if (people.length < 2)
      return Padding(
        padding: const EdgeInsets.only(top: 24),
        child: Text(l10n.friendsIntroducerNeedTwo),
      );
    final first = people.any((c) => c.userId == _first) ? _first : null;
    final second = people.any((c) => c.userId == _second && c.userId != first)
        ? _second
        : null;
    return Padding(
      padding: const EdgeInsets.only(top: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.friendsIntroducerComposerTitle,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            key: ValueKey('first-$first'),
            value: first,
            isExpanded: true,
            decoration: InputDecoration(labelText: l10n.friendsFirstFriend),
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
            decoration: InputDecoration(labelText: l10n.friendsSecondFriend),
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
            decoration: InputDecoration(
              labelText: l10n.friendsIntroducerWhyLabel,
              helperText: l10n.friendsIntroducerWhyHelper,
              helperMaxLines: 3,
              border: const OutlineInputBorder(),
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
                    }, l10n.friendsIntroducerIntroSent))
                      _note.clear();
                  },
            icon: const Icon(Icons.favorite_border),
            label: Text(l10n.friendsIntroducerSuggest),
          ),
        ],
      ),
    );
  }
}

class _PrivacyNote extends StatelessWidget {
  const _PrivacyNote();
  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Icon(Icons.lock_outline, size: 20),
      const SizedBox(width: 10),
      Expanded(
        child: Text(
          AppLocalizations.of(context).friendsIntroducerPrivacyNote,
          style: const TextStyle(height: 1.5),
        ),
      ),
    ],
  );
}
