import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../core/network/api_error_message.dart';
import '../../core/widgets/connect_page.dart';
import '../../core/widgets/glass_widgets.dart';
import '../../l10n/app_localizations.dart';
import '../common/widgets/community_actions.dart';
import 'friend_picker.dart';
import 'group_cover_picker.dart';
import 'group_detail_screen.dart';
import 'group_launch.dart';
import 'group_widgets.dart';
import 'groups_data.dart';

/// Emoji offered for a group cover, after the category's own.
const _coverEmoji = <String>[
  '✨',
  '🫶',
  '🌿',
  '☕',
  '🎉',
  '🌅',
  '🔥',
  '🌈',
  '🎲',
  '🍕',
];

/// Starts a community group (by lifestyle, anyone can join) or a private
/// group (just friends). [invitees] arrive preselected, e.g. from Friends.
class CreateGroupScreen extends ConsumerStatefulWidget {
  const CreateGroupScreen({
    super.key,
    this.invitees = const [],
    this.initialKind,
    this.initialCategory = '',
  });
  final List<GroupInvitee> invitees;

  /// `community` or `private`; private by default when friends are
  /// preselected, community otherwise.
  final String? initialKind;
  final String initialCategory;

  @override
  ConsumerState<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends ConsumerState<CreateGroupScreen> {
  final name = TextEditingController();
  final description = TextEditingController();
  final city = TextEditingController();

  /// One id per attempt so a retried create never makes two groups.
  final groupId = const Uuid().v4();
  late String kind =
      widget.initialKind ?? (widget.invitees.isEmpty ? 'community' : 'private');
  late String category = widget.initialCategory;
  late final List<GroupInvitee> invitees = [...widget.invitees];
  String coverEmoji = '';
  String coverColor = 'primary';

  /// An optional cover photo, uploaded right after the group is created.
  PickedGroupCover? coverPhoto;
  double? coverProgress;
  bool uploadingCover = false;
  bool busy = false;
  String? error;

  @override
  void dispose() {
    name.dispose();
    description.dispose();
    city.dispose();
    super.dispose();
  }

  Future<void> chooseFriends() async {
    final picked = await pickGroupFriends(
      context,
      selected: invitees,
      title: AppLocalizations.of(context).groupsInviteFriends,
    );
    if (picked != null && mounted) {
      setState(() {
        invitees
          ..clear()
          ..addAll(picked);
      });
    }
  }

  Future<void> chooseCoverPhoto() async {
    final picked = await pickGroupCover(context, ref);
    if (picked != null && mounted) {
      setState(() => coverPhoto = picked);
    }
  }

  /// Uploads the chosen photo to the new group. The group exists either way;
  /// a failed upload only leaves it on its emoji cover.
  Future<void> uploadCoverPhoto(String id, PickedGroupCover photo) async {
    final l10n = AppLocalizations.of(context);
    setState(() {
      uploadingCover = true;
      coverProgress = null;
    });
    try {
      final updated = await groupsApi(ref).uploadCover(
        id,
        bytes: photo.bytes,
        filename: photo.filename,
        onProgress: (p) {
          if (mounted) {
            setState(() => coverProgress = p);
          }
        },
      );
      if (mounted) {
        showCommunitySnack(context, groupCoverUploadedMessage(l10n, updated));
      }
    } on Object catch (e) {
      if (mounted) {
        showCommunitySnack(
          context,
          apiErrorMessage(e, fallback: l10n.groupsCreateCoverUploadFailed),
        );
      }
    } finally {
      if (mounted) {
        setState(() => uploadingCover = false);
      }
    }
  }

  Future<void> create() async {
    final l10n = AppLocalizations.of(context);
    final trimmed = name.text.trim();
    if (kind == 'community' && category.isEmpty) {
      setState(() => error = l10n.groupsCreatePickLifestyle);
      return;
    }
    if (trimmed.length < 3) {
      setState(() => error = l10n.groupsCreateNameTooShort);
      return;
    }
    setState(() {
      busy = true;
      error = null;
    });
    try {
      final group = await groupsApi(ref).create(
        groupId: groupId,
        kind: kind,
        name: trimmed,
        categorySlug: kind == 'community' ? category : '',
        description: description.text.trim(),
        city: city.text.trim(),
        coverEmoji: coverEmoji,
        coverColor: coverColor,
        inviteeIds: [for (final f in invitees) f.userId],
      );
      if (!mounted) {
        return;
      }
      final photo = coverPhoto;
      if (photo != null) {
        await uploadCoverPhoto(group.id, photo);
        if (!mounted) {
          return;
        }
      }
      invalidateGroups(ref);
      await Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => GroupDetailScreen(groupId: group.id),
        ),
      );
    } on Object catch (e) {
      if (mounted) {
        setState(
          () => error = apiErrorMessage(e, fallback: l10n.groupsCreateFailed),
        );
      }
    } finally {
      if (mounted) {
        setState(() => busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final l10n = AppLocalizations.of(context);
    final categories = ref.watch(groupCategoriesProvider);
    final categoryEmoji =
        categories.valueOrNull
            ?.where((c) => c.slug == category)
            .map((c) => c.emoji)
            .firstOrNull ??
        '';
    final emojiChoices = [
      if (kind == 'community' && categoryEmoji.isNotEmpty) categoryEmoji,
      for (final e in _coverEmoji)
        if (e != categoryEmoji) e,
    ];
    final shownEmoji = coverEmoji.isNotEmpty
        ? coverEmoji
        : (kind == 'community' && categoryEmoji.isNotEmpty
              ? categoryEmoji
              : (kind == 'community' ? '✨' : '🫶'));

    Widget section(String label, String? caption, Widget child) => Padding(
      padding: const EdgeInsets.only(top: ConnectMetrics.sectionGap),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ConnectSectionHeader(label: label, caption: caption),
          const SizedBox(height: ConnectMetrics.cardGap),
          child,
        ],
      ),
    );

    return Scaffold(
      body: PostLoginBackdrop(
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, box) {
              final gutter = ConnectMetrics.gutterFor(box.maxWidth);
              return Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 720),
                  child: ListView(
                    padding: EdgeInsets.fromLTRB(gutter, 12, gutter, 48),
                    children: [
                      ConnectPageHeader(
                        leading: const BackButton(),
                        eyebrow: l10n.groupsCreateEyebrow,
                        title: l10n.groupsStartGroup,
                        subtitle: invitees.isEmpty
                            ? l10n.groupsCreateSubtitle
                            : l10n.groupsCreateSubtitleFriends,
                      ),
                      section(
                        l10n.groupsCreateKindHeader,
                        null,
                        Column(
                          children: [
                            _KindOption(
                              icon: Icons.public_rounded,
                              title: l10n.groupsKindCommunity,
                              subtitle: l10n.groupsCreateCommunitySubtitle,
                              selected: kind == 'community',
                              onTap: () => setState(() => kind = 'community'),
                            ),
                            const SizedBox(height: ConnectMetrics.cardGap),
                            _KindOption(
                              icon: Icons.lock_outline_rounded,
                              title: l10n.groupsKindPrivate,
                              subtitle: l10n.groupsCreatePrivateSubtitle,
                              selected: kind == 'private',
                              onTap: () => setState(() => kind = 'private'),
                            ),
                          ],
                        ),
                      ),
                      if (kind == 'community')
                        section(
                          l10n.groupsCreateLifestyleHeader,
                          l10n.groupsCreateLifestyleCaption,
                          categories.when(
                            loading: () => const Padding(
                              padding: EdgeInsets.all(16),
                              child: Center(child: CircularProgressIndicator()),
                            ),
                            error: (e, _) => GroupNotice(
                              icon: Icons.cloud_off_outlined,
                              title: l10n.groupsLifestylesFailed,
                              message: apiErrorMessage(
                                e,
                                fallback: l10n.groupsPleaseTryAgain,
                              ),
                              actionLabel: l10n.chatTryAgain,
                              onAction: () =>
                                  ref.invalidate(groupCategoriesProvider),
                            ),
                            data: (list) => Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                for (final c in list)
                                  ChoiceChip(
                                    label: Text('${c.emoji}  ${c.title}'),
                                    selected: category == c.slug,
                                    onSelected: (_) =>
                                        setState(() => category = c.slug),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      section(
                        l10n.groupsCreateDetailsHeader,
                        null,
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            TextField(
                              controller: name,
                              maxLength: 60,
                              textCapitalization: TextCapitalization.words,
                              decoration: InputDecoration(
                                labelText: l10n.groupsNameLabel,
                                hintText: kind == 'community'
                                    ? l10n.groupsCreateNameHintCommunity
                                    : l10n.groupsCreateNameHintPrivate,
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextField(
                              controller: description,
                              maxLength: 500,
                              minLines: 2,
                              maxLines: 5,
                              textCapitalization: TextCapitalization.sentences,
                              decoration: InputDecoration(
                                labelText: l10n.groupsAboutOptionalLabel,
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextField(
                              controller: city,
                              maxLength: 60,
                              textCapitalization: TextCapitalization.words,
                              decoration: InputDecoration(
                                labelText: l10n.groupsCityLabel,
                              ),
                            ),
                          ],
                        ),
                      ),
                      section(
                        l10n.groupsCreateCoverHeader,
                        null,
                        ConnectPanel(
                          padding: const EdgeInsets.all(ConnectMetrics.padding),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  GroupCover(
                                    emoji: shownEmoji,
                                    color: coverColor,
                                    size: 64,
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Wrap(
                                      spacing: 8,
                                      runSpacing: 8,
                                      children: [
                                        for (final entry in groupCoverColors(
                                          l10n,
                                        ).entries)
                                          ChoiceChip(
                                            label: Text(entry.value),
                                            selected: coverColor == entry.key,
                                            onSelected: (_) => setState(
                                              () => coverColor = entry.key,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Wrap(
                                spacing: 4,
                                runSpacing: 4,
                                children: [
                                  for (final e in emojiChoices)
                                    Semantics(
                                      selected: shownEmoji == e,
                                      button: true,
                                      label: l10n.groupsCoverEmojiSemantics(e),
                                      child: ExcludeSemantics(
                                        child: InkWell(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          onTap: () =>
                                              setState(() => coverEmoji = e),
                                          child: Container(
                                            width: 48,
                                            height: 48,
                                            alignment: Alignment.center,
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              border: Border.all(
                                                color: shownEmoji == e
                                                    ? colors.primary
                                                    : colors.outlineVariant,
                                                width: shownEmoji == e ? 2 : 1,
                                              ),
                                            ),
                                            child: Text(
                                              e,
                                              style: const TextStyle(
                                                fontSize: 22,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                l10n.groupsCreateCoverPhotoOptional,
                                style: theme.textTheme.titleSmall?.copyWith(
                                  color: colors.onSurface,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                l10n.groupsCreateCoverPhotoHint,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: colors.onSurfaceVariant,
                                ),
                              ),
                              const SizedBox(height: 8),
                              if (coverPhoto != null) ...[
                                GroupCoverPreview(
                                  key: const ValueKey(
                                    'groups.create.coverPreview',
                                  ),
                                  bytes: coverPhoto!.bytes,
                                ),
                                const SizedBox(height: 8),
                              ],
                              if (uploadingCover)
                                GroupCoverProgress(progress: coverProgress)
                              else
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: [
                                    OutlinedButton.icon(
                                      key: const ValueKey(
                                        'groups.create.cover',
                                      ),
                                      onPressed: busy ? null : chooseCoverPhoto,
                                      style: OutlinedButton.styleFrom(
                                        minimumSize: const Size(48, 48),
                                      ),
                                      icon: const Icon(
                                        Icons.add_photo_alternate_outlined,
                                      ),
                                      label: Text(
                                        coverPhoto == null
                                            ? l10n.groupsCreateAddCoverPhoto
                                            : l10n.groupsCreateChangePhoto,
                                      ),
                                    ),
                                    if (coverPhoto != null)
                                      TextButton(
                                        onPressed: busy
                                            ? null
                                            : () => setState(
                                                () => coverPhoto = null,
                                              ),
                                        style: TextButton.styleFrom(
                                          minimumSize: const Size(48, 48),
                                        ),
                                        child: Text(
                                          l10n.groupsCreateRemovePhoto,
                                        ),
                                      ),
                                  ],
                                ),
                            ],
                          ),
                        ),
                      ),
                      section(
                        l10n.groupsCreateFriendsHeader,
                        invitees.isEmpty
                            ? l10n.groupsCreateFriendsCaptionEmpty
                            : l10n.groupsCreateFriendsCaption,
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (invitees.isNotEmpty) ...[
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  for (final f in invitees)
                                    InputChip(
                                      avatar: GroupAvatar(
                                        name: f.name,
                                        photoUrl: f.photoUrl,
                                        radius: 12,
                                      ),
                                      label: Text(
                                        f.name.isEmpty
                                            ? l10n.groupsFriendFallback
                                            : f.name,
                                      ),
                                      deleteButtonTooltipMessage: l10n
                                          .groupsRemoveInvitee(f.name),
                                      onDeleted: () =>
                                          setState(() => invitees.remove(f)),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 12),
                            ],
                            OutlinedButton.icon(
                              onPressed: busy ? null : chooseFriends,
                              style: OutlinedButton.styleFrom(
                                minimumSize: const Size(48, 48),
                              ),
                              icon: const Icon(Icons.person_add_alt_rounded),
                              label: Text(
                                invitees.isEmpty
                                    ? l10n.groupsChooseFriends
                                    : l10n.groupsChangeFriends,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (error != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 16),
                          child: Text(
                            error!,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: colors.error,
                            ),
                          ),
                        ),
                      const SizedBox(height: 24),
                      FilledButton.icon(
                        onPressed: busy ? null : create,
                        style: FilledButton.styleFrom(
                          minimumSize: const Size.fromHeight(52),
                        ),
                        icon: const Icon(Icons.celebration_outlined),
                        label: Text(
                          busy ? l10n.groupsCreating : l10n.groupsCreateGroup,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _KindOption extends StatelessWidget {
  const _KindOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });
  final IconData icon;
  final String title, subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final radius = BorderRadius.circular(ConnectMetrics.cardRadius);
    return Semantics(
      selected: selected,
      inMutuallyExclusiveGroup: true,
      button: true,
      label: '$title. $subtitle',
      child: ExcludeSemantics(
        child: Material(
          color: Colors.transparent,
          child: Ink(
            decoration: BoxDecoration(
              color: selected ? colors.primaryContainer : colors.surface,
              borderRadius: radius,
              border: Border.all(
                color: selected ? colors.primary : colors.outlineVariant,
                width: selected ? 2 : 1,
              ),
            ),
            child: InkWell(
              borderRadius: radius,
              onTap: onTap,
              child: Padding(
                padding: const EdgeInsets.all(ConnectMetrics.padding),
                child: Row(
                  children: [
                    Icon(
                      icon,
                      color: selected
                          ? colors.onPrimaryContainer
                          : colors.primary,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: selected
                                  ? colors.onPrimaryContainer
                                  : colors.onSurface,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            subtitle,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: selected
                                  ? colors.onPrimaryContainer
                                  : colors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      selected
                          ? Icons.radio_button_checked_rounded
                          : Icons.radio_button_unchecked_rounded,
                      color: selected
                          ? colors.onPrimaryContainer
                          : colors.onSurfaceVariant,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
