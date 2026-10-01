import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../core/network/api_error_message.dart';
import '../../core/widgets/connect_page.dart';
import '../../core/widgets/glass_widgets.dart';
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
      title: 'Invite friends',
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
        showCommunitySnack(context, groupCoverUploadedMessage(updated));
      }
    } on Object catch (e) {
      if (mounted) {
        showCommunitySnack(
          context,
          apiErrorMessage(
            e,
            fallback:
                'Your group is ready, but the cover photo could not be '
                'uploaded. Try again from the group.',
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => uploadingCover = false);
      }
    }
  }

  Future<void> create() async {
    final trimmed = name.text.trim();
    if (kind == 'community' && category.isEmpty) {
      setState(() => error = 'Pick a lifestyle for your community group.');
      return;
    }
    if (trimmed.length < 3) {
      setState(() => error = 'Give your group a name of at least 3 letters.');
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
          () => error = apiErrorMessage(
            e,
            fallback: 'Your group could not be created. Please try again.',
          ),
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
                        eyebrow: 'NEW GROUP',
                        title: 'Start a group',
                        subtitle: invitees.isEmpty
                            ? 'Bring people together around what you love.'
                            : 'Turn your friends into a group.',
                      ),
                      section(
                        'WHAT KIND',
                        null,
                        Column(
                          children: [
                            _KindOption(
                              icon: Icons.public_rounded,
                              title: 'Community group',
                              subtitle:
                                  'By lifestyle. Anyone can find and join it.',
                              selected: kind == 'community',
                              onTap: () => setState(() => kind = 'community'),
                            ),
                            const SizedBox(height: ConnectMetrics.cardGap),
                            _KindOption(
                              icon: Icons.lock_outline_rounded,
                              title: 'Private group',
                              subtitle:
                                  'Just friends. Only people you invite can '
                                  'join.',
                              selected: kind == 'private',
                              onTap: () => setState(() => kind = 'private'),
                            ),
                          ],
                        ),
                      ),
                      if (kind == 'community')
                        section(
                          'LIFESTYLE',
                          'Where people will discover your group.',
                          categories.when(
                            loading: () => const Padding(
                              padding: EdgeInsets.all(16),
                              child: Center(child: CircularProgressIndicator()),
                            ),
                            error: (e, _) => GroupNotice(
                              icon: Icons.cloud_off_outlined,
                              title: 'Lifestyles could not load',
                              message: apiErrorMessage(
                                e,
                                fallback: 'Please try again.',
                              ),
                              actionLabel: 'Try again',
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
                        'DETAILS',
                        null,
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            TextField(
                              controller: name,
                              maxLength: 60,
                              textCapitalization: TextCapitalization.words,
                              decoration: InputDecoration(
                                labelText: 'Group name',
                                hintText: kind == 'community'
                                    ? 'Sunrise runners of Indiranagar'
                                    : 'The Sunday brunch crew',
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextField(
                              controller: description,
                              maxLength: 500,
                              minLines: 2,
                              maxLines: 5,
                              textCapitalization: TextCapitalization.sentences,
                              decoration: const InputDecoration(
                                labelText: 'What is it about? (optional)',
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextField(
                              controller: city,
                              maxLength: 60,
                              textCapitalization: TextCapitalization.words,
                              decoration: const InputDecoration(
                                labelText: 'City (optional)',
                              ),
                            ),
                          ],
                        ),
                      ),
                      section(
                        'COVER',
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
                                        for (final entry
                                            in groupCoverColors.entries)
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
                                      label: 'Cover emoji $e',
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
                                'Cover photo (optional)',
                                style: theme.textTheme.titleSmall?.copyWith(
                                  color: colors.onSurface,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Members see the emoji until your photo is '
                                'approved.',
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
                                            ? 'Add a cover photo'
                                            : 'Change photo',
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
                                        child: const Text('Remove photo'),
                                      ),
                                  ],
                                ),
                            ],
                          ),
                        ),
                      ),
                      section(
                        'FRIENDS',
                        invitees.isEmpty
                            ? 'Invite friends now, or later from the group.'
                            : 'They’ll get an invitation to join.',
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
                                        f.name.isEmpty ? 'Friend' : f.name,
                                      ),
                                      deleteButtonTooltipMessage:
                                          'Remove ${f.name}',
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
                                    ? 'Choose friends'
                                    : 'Change friends',
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
                        label: Text(busy ? 'Creating…' : 'Create group'),
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
