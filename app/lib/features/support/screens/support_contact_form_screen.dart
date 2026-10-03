import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../support_api.dart';
import '../support_models.dart';
import '../widgets/support_widgets.dart';

/// Contact support without an account (`POST /support/contact`): for people
/// who cannot sign in, or hit a problem before they have an account.
///
/// The team replies by email to the address given; nothing here creates,
/// finds or links an account. While requests are switched off the server
/// answers `FEATURE_DISABLED` and the form explains that, keeping what was
/// typed.
class SupportContactFormScreen extends ConsumerStatefulWidget {
  const SupportContactFormScreen({super.key, this.initialCategory});

  final String? initialCategory;

  @override
  ConsumerState<SupportContactFormScreen> createState() =>
      _SupportContactFormScreenState();
}

class _SupportContactFormScreenState
    extends ConsumerState<SupportContactFormScreen> {
  static final _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  final _email = TextEditingController();
  final _name = TextEditingController();
  final _subject = TextEditingController();
  final _description = TextEditingController();
  late String? _category = supportCategories.contains(widget.initialCategory)
      ? widget.initialCategory
      : null;
  bool _busy = false;
  bool _unavailable = false;
  String? _error;
  String? _reference;

  @override
  void dispose() {
    _email.dispose();
    _name.dispose();
    _subject.dispose();
    _description.dispose();
    super.dispose();
  }

  String? _validate(AppLocalizations l10n) {
    final email = _email.text.trim();
    final subject = _subject.text.trim();
    final description = _description.text.trim();
    if (!_emailPattern.hasMatch(email) || email.length > 254) {
      return l10n.supportGuestEmailInvalid;
    }
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
      _unavailable = false;
    });
    try {
      final reference = await ref
          .read(supportApiProvider)
          .contact(
            email: _email.text.trim(),
            name: _name.text.trim(),
            category: _category!,
            subject: _subject.text.trim(),
            description: _description.text.trim(),
            locale: Localizations.localeOf(context).toLanguageTag(),
          );
      if (mounted) {
        setState(() => _reference = reference);
      }
    } on SupportException catch (error) {
      if (mounted) {
        setState(() {
          // Everything typed stays in the fields.
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
    final reference = _reference;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.supportFormTitle)),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: reference != null
                  ? [
                      SupportNotice(
                        key: const Key('support_guest_done'),
                        icon: Icons.mark_email_read_outlined,
                        title: l10n.supportGuestSentTitle,
                        message: l10n.supportGuestSentBody(
                          reference,
                          _email.text.trim(),
                        ),
                      ),
                      const SizedBox(height: 24),
                      FilledButton(
                        key: const Key('support_guest_back'),
                        onPressed: () => Navigator.of(context).maybePop(),
                        child: Text(l10n.authRecoveryBackToSignIn),
                      ),
                    ]
                  : [
                      Text(
                        l10n.supportGuestSubtitle,
                        style: theme.textTheme.bodyLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        l10n.supportFormSubtitle,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                      if (_unavailable) ...[
                        const SizedBox(height: 16),
                        SupportNotice(
                          key: const Key('support_guest_unavailable'),
                          icon: Icons.support_agent_rounded,
                          title: l10n.supportUnavailableTitle,
                          message: l10n.supportGuestUnavailableBody,
                        ),
                      ],
                      const SizedBox(height: 20),
                      TextField(
                        key: const Key('support_guest_email'),
                        controller: _email,
                        keyboardType: TextInputType.emailAddress,
                        autofillHints: const [AutofillHints.email],
                        textInputAction: TextInputAction.next,
                        decoration: InputDecoration(
                          labelText: l10n.supportGuestEmailLabel,
                          hintText: l10n.supportGuestEmailHint,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        key: const Key('support_guest_name'),
                        controller: _name,
                        maxLength: 100,
                        autofillHints: const [AutofillHints.name],
                        textInputAction: TextInputAction.next,
                        decoration: InputDecoration(
                          labelText: l10n.supportGuestNameLabel,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        l10n.supportFormCategoryLabel,
                        style: theme.textTheme.titleSmall,
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final key in supportCategories)
                            ChoiceChip(
                              key: Key('support_guest_category_$key'),
                              avatar: Icon(supportCategoryIcon(key), size: 18),
                              label: Text(supportCategoryLabel(l10n, key)),
                              selected: _category == key,
                              materialTapTargetSize:
                                  MaterialTapTargetSize.padded,
                              onSelected: (_) =>
                                  setState(() => _category = key),
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        key: const Key('support_guest_subject'),
                        controller: _subject,
                        maxLength: SupportLimits.subjectMax,
                        textCapitalization: TextCapitalization.sentences,
                        textInputAction: TextInputAction.next,
                        decoration: InputDecoration(
                          labelText: l10n.supportFormSubjectLabel,
                          hintText: l10n.supportFormSubjectHint,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        key: const Key('support_guest_description'),
                        controller: _description,
                        minLines: 4,
                        maxLines: 10,
                        maxLength: SupportLimits.bodyMax,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: InputDecoration(
                          labelText: l10n.supportFormDescriptionLabel,
                          hintText: l10n.supportFormDescriptionHint,
                          alignLabelWithHint: true,
                        ),
                      ),
                      if (_error != null) ...[
                        const SizedBox(height: 12),
                        Semantics(
                          liveRegion: true,
                          child: Text(
                            _error!,
                            key: const Key('support_guest_error'),
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: colors.error,
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 20),
                      FilledButton.icon(
                        key: const Key('support_guest_submit'),
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
        ),
      ),
    );
  }
}
