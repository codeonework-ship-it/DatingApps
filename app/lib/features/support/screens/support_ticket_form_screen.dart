import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/widgets/connect_page.dart';
import '../../../core/widgets/glass_widgets.dart';
import '../../../l10n/app_localizations.dart';
import '../../safety/screens/sos_screen.dart';
import '../support_api.dart';
import '../support_models.dart';
import '../widgets/support_widgets.dart';
import 'support_ticket_thread_screen.dart';

/// Raise a support request: a topic, a subject, a description and optional
/// screenshots. App version, platform, OS version and language are attached
/// automatically.
class SupportTicketFormScreen extends ConsumerStatefulWidget {
  const SupportTicketFormScreen({super.key, this.initialCategory});

  final String? initialCategory;

  @override
  ConsumerState<SupportTicketFormScreen> createState() =>
      _SupportTicketFormScreenState();
}

class _SupportTicketFormScreenState
    extends ConsumerState<SupportTicketFormScreen> {
  final _subject = TextEditingController();
  final _description = TextEditingController();
  late final SupportAttachmentTray _tray;
  late String? _category = supportCategories.contains(widget.initialCategory)
      ? widget.initialCategory
      : null;

  /// One key per request: kept when the network drops so a retry is
  /// recognised by the server, replaced once the server has answered.
  String _idempotencyKey = const Uuid().v4();
  bool _busy = false;
  bool _unavailable = false;
  String? _error;

  /// Set when an unsent request from an earlier visit was put back.
  bool _restored = false;
  late final SupportDraftStore _drafts;

  @override
  void initState() {
    super.initState();
    _tray = SupportAttachmentTray(
      ref.read(supportApiProvider),
      lookupAppLocalizations(const Locale('en')),
    );
    _drafts = ref.read(supportDraftProvider.notifier);
    final draft = ref.read(supportDraftProvider);
    if (draft != null) {
      _subject.text = draft.subject;
      _description.text = draft.description;
      _category ??= draft.category;
      _restored = true;
    }
    _subject.addListener(_keepDraft);
    _description.addListener(_keepDraft);
  }

  /// Keeps what is typed so leaving the form (or a failed send) loses
  /// nothing. Screenshots are not kept: they are re-picked in seconds.
  void _keepDraft() => _drafts.save(
    SupportDraft(
      category: _category,
      subject: _subject.text,
      description: _description.text,
    ),
  );

  void _discardDraft() {
    _subject.clear();
    _description.clear();
    _drafts.clear();
    setState(() {
      _category = null;
      _restored = false;
      _error = null;
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _tray.useLocalizations(AppLocalizations.of(context));
  }

  @override
  void dispose() {
    _subject.dispose();
    _description.dispose();
    _tray.dispose();
    super.dispose();
  }

  Future<void> _addScreenshots() async {
    final files = await ref
        .read(supportImagePickerProvider)
        .pick(_tray.remaining);
    if (files.isNotEmpty && mounted) {
      await _tray.addFiles(files);
    }
  }

  String? _validate(AppLocalizations l10n) {
    final subject = _subject.text.trim();
    final description = _description.text.trim();
    if (_category == null) {
      return l10n.supportErrorCategoryRequired;
    }
    if (subject.length < SupportLimits.subjectMin ||
        subject.length > SupportLimits.subjectMax) {
      return l10n.supportErrorSubjectLength(
        SupportLimits.subjectMin,
        SupportLimits.subjectMax,
      );
    }
    if (description.isEmpty) {
      return l10n.supportErrorDescriptionRequired;
    }
    if (description.length > SupportLimits.bodyMax) {
      return l10n.supportErrorDescriptionTooLong(SupportLimits.bodyMax);
    }
    if (_tray.uploading || _tray.hasFailures) {
      return l10n.supportErrorUploadsPending;
    }
    return null;
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context);
    final invalid = _validate(l10n);
    if (invalid != null) {
      setState(() => _error = invalid);
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    final locale = Localizations.localeOf(context).toLanguageTag();
    try {
      final result = await ref
          .read(supportApiProvider)
          .createTicket(
            category: _category!,
            subject: _subject.text.trim(),
            description: _description.text.trim(),
            attachmentIds: _tray.uploadIds,
            device: currentSupportDeviceContext(locale),
            idempotencyKey: _idempotencyKey,
          );
      _subject.removeListener(_keepDraft);
      _description.removeListener(_keepDraft);
      _drafts.clear();
      ref.invalidate(supportTicketsProvider);
      if (!mounted) {
        return;
      }
      final ticket = result.thread.ticket;
      final messenger = ScaffoldMessenger.of(context);
      // Not awaited: the future only completes when the thread is closed.
      unawaited(
        Navigator.of(context).pushReplacement(
          MaterialPageRoute<void>(
            builder: (_) => SupportTicketThreadScreen(
              ticketId: ticket.id,
              initialThread: result.thread,
            ),
          ),
        ),
      );
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            result.duplicate
                ? l10n.supportDuplicateSnack(ticket.reference)
                : l10n.supportCreatedSnack(ticket.reference),
          ),
        ),
      );
    } on SupportException catch (error) {
      if (!error.offline) {
        _idempotencyKey = const Uuid().v4();
      }
      if (mounted) {
        setState(() {
          _unavailable = error.featureDisabled;
          _error = error.featureDisabled
              ? null
              : supportErrorMessage(l10n, error);
        });
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    // The server's list when it answers; the app's own until then.
    final categories =
        ref.watch(supportCategoriesProvider).valueOrNull ?? supportCategories;

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

    final header = ConnectPageHeader(
      leading: const BackButton(),
      eyebrow: l10n.supportFormEyebrow,
      title: l10n.supportFormTitle,
      subtitle: _unavailable ? null : l10n.supportFormSubtitle,
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
                    children: _unavailable
                        ? [
                            header,
                            const SizedBox(height: ConnectMetrics.sectionGap),
                            SupportUnavailablePanel(
                              action: TextButton(
                                onPressed: () => Navigator.of(context).pop(),
                                child: Text(l10n.supportBackToHelp),
                              ),
                            ),
                          ]
                        : [
                            header,
                            if (_restored) ...[
                              const SizedBox(height: ConnectMetrics.cardGap),
                              SupportNotice(
                                key: const Key('support_draft_restored'),
                                icon: Icons.edit_note_rounded,
                                title: l10n.supportDraftRestored,
                                message: l10n.supportFormSubtitle,
                                action: TextButton(
                                  key: const Key('support_draft_discard'),
                                  onPressed: _discardDraft,
                                  child: Text(l10n.supportDraftDiscard),
                                ),
                              ),
                            ],
                            section(
                              l10n.supportFormCategorySection,
                              l10n.supportFormCategoryLabel,
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  for (final key in categories)
                                    ChoiceChip(
                                      key: Key('support_category_$key'),
                                      avatar: Icon(
                                        supportCategoryIcon(key),
                                        size: 18,
                                      ),
                                      label: Text(
                                        supportCategoryLabel(l10n, key),
                                      ),
                                      selected: _category == key,
                                      materialTapTargetSize:
                                          MaterialTapTargetSize.padded,
                                      onSelected: (_) {
                                        setState(() => _category = key);
                                        _keepDraft();
                                      },
                                    ),
                                ],
                              ),
                            ),
                            if (_category == supportSafetyCategory) ...[
                              const SizedBox(height: ConnectMetrics.cardGap),
                              SupportNotice(
                                key: const Key('support_safety_note'),
                                icon: Icons.emergency_outlined,
                                title: l10n.supportCategorySafetyHarassment,
                                message: l10n.supportSafetyNote,
                                action: TextButton.icon(
                                  onPressed: () => Navigator.of(context).push(
                                    MaterialPageRoute<void>(
                                      builder: (_) => const SosScreen(),
                                    ),
                                  ),
                                  icon: const Icon(Icons.sos_outlined),
                                  label: Text(l10n.supportOpenSos),
                                ),
                              ),
                            ],
                            section(
                              l10n.supportFormDetailsSection,
                              null,
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  TextField(
                                    key: const Key('support_subject'),
                                    controller: _subject,
                                    maxLength: SupportLimits.subjectMax,
                                    textCapitalization:
                                        TextCapitalization.sentences,
                                    textInputAction: TextInputAction.next,
                                    decoration: InputDecoration(
                                      labelText: l10n.supportFormSubjectLabel,
                                      hintText: l10n.supportFormSubjectHint,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  TextField(
                                    key: const Key('support_description'),
                                    controller: _description,
                                    minLines: 5,
                                    maxLines: 12,
                                    maxLength: SupportLimits.bodyMax,
                                    textCapitalization:
                                        TextCapitalization.sentences,
                                    decoration: InputDecoration(
                                      labelText:
                                          l10n.supportFormDescriptionLabel,
                                      hintText: l10n.supportFormDescriptionHint,
                                      alignLabelWithHint: true,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            section(
                              l10n.supportFormScreenshotsSection,
                              l10n.supportFormScreenshotsCaption(
                                SupportLimits.attachmentsPerMessage,
                              ),
                              ListenableBuilder(
                                listenable: _tray,
                                builder: (context, _) => Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    SupportDraftAttachments(tray: _tray),
                                    if (_tray.items.isNotEmpty)
                                      const SizedBox(height: 12),
                                    OutlinedButton.icon(
                                      key: const Key('support_add_screenshot'),
                                      onPressed: _busy || _tray.remaining <= 0
                                          ? null
                                          : _addScreenshots,
                                      icon: const Icon(
                                        Icons.add_photo_alternate_outlined,
                                      ),
                                      label: Text(l10n.supportAddScreenshot),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: ConnectMetrics.sectionGap),
                            Text(
                              l10n.supportFormDeviceNote(
                                currentSupportDeviceContext('').appVersion,
                              ),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colors.onSurfaceVariant,
                              ),
                            ),
                            if (_error != null) ...[
                              const SizedBox(height: 12),
                              Semantics(
                                liveRegion: true,
                                child: Text(
                                  _error!,
                                  key: const Key('support_form_error'),
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: colors.error,
                                  ),
                                ),
                              ),
                            ],
                            const SizedBox(height: 16),
                            FilledButton.icon(
                              key: const Key('submit_support_ticket'),
                              style: FilledButton.styleFrom(
                                minimumSize: const Size.fromHeight(48),
                              ),
                              onPressed: _busy ? null : _submit,
                              icon: _busy
                                  ? const SizedBox.square(
                                      dimension: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(Icons.send_rounded),
                              label: Text(l10n.supportSubmit),
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
