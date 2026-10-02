import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/glass_widgets.dart';
import '../../../l10n/app_localizations.dart';
import '../providers/terms_provider.dart';

class UserAgreementScreen extends ConsumerStatefulWidget {
  const UserAgreementScreen({super.key});

  @override
  ConsumerState<UserAgreementScreen> createState() =>
      _UserAgreementScreenState();
}

class _UserAgreementScreenState extends ConsumerState<UserAgreementScreen> {
  bool _accepted = false;

  @override
  Widget build(BuildContext context) {
    final termsState = ref.watch(termsAcceptanceProvider);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final scheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: CrystalScaffold(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(16, 16, 16, 24 + bottomInset),
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: AppTheme.contentMaxWidth,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildHeader(context),
                    const SizedBox(height: 22),
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: scheme.surface,
                        borderRadius: const BorderRadius.all(
                          Radius.circular(20),
                        ),
                        border: Border.all(color: scheme.outlineVariant),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.authTermsIntro,
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                          const SizedBox(height: 18),
                          Text(
                            l10n.authTermsCommunityTitle,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 12),
                          _termPoint(context, l10n.authTermsPointRespect),
                          _termPoint(context, l10n.authTermsPointNoHarassment),
                          _termPoint(context, l10n.authTermsPointPrivacy),
                          _termPoint(context, l10n.authTermsPointReports),
                          _termPoint(context, l10n.authTermsPointViolations),
                          const SizedBox(height: 18),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: scheme.primaryContainer,
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: Text(
                              l10n.authTermsReviewLater,
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(color: scheme.onPrimaryContainer),
                            ),
                          ),
                          const SizedBox(height: 18),
                          Semantics(
                            label: 'qa.terms.accept_checkbox',
                            button: true,
                            checked: _accepted,
                            child: InkWell(
                              key: const ValueKey('qa.terms.accept_checkbox'),
                              onTap: () {
                                setState(() {
                                  _accepted = !_accepted;
                                });
                              },
                              borderRadius: BorderRadius.circular(18),
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.fromLTRB(
                                  12,
                                  12,
                                  12,
                                  8,
                                ),
                                decoration: BoxDecoration(
                                  color: scheme.surface,
                                  borderRadius: BorderRadius.circular(18),
                                  border: Border.all(
                                    color: _accepted
                                        ? scheme.primary
                                        : scheme.outlineVariant,
                                    width: _accepted ? 1.5 : 1.0,
                                  ),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Checkbox(
                                      key: const ValueKey(
                                        'qa.terms.accept_checkbox_input',
                                      ),
                                      value: _accepted,
                                      activeColor: scheme.primary,
                                      checkColor: scheme.onPrimary,
                                      onChanged: (value) {
                                        setState(() {
                                          _accepted = value ?? false;
                                        });
                                      },
                                    ),
                                    Expanded(
                                      child: Padding(
                                        padding: const EdgeInsets.only(
                                          top: 4,
                                          bottom: 4,
                                        ),
                                        child: Text(
                                          l10n.authTermsAgreeCheckbox,
                                          style: TextStyle(
                                            color: scheme.onSurface,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 18),
                          Semantics(
                            label: 'qa.terms.continue_button',
                            button: true,
                            child: GlassButton(
                              key: const ValueKey('qa.terms.continue_button'),
                              label: l10n.authTermsAcceptButton,
                              icon: Icons.check_circle_rounded,
                              shinyEffect: true,
                              isLoading: termsState.isLoading,
                              onPressed: !_accepted
                                  ? null
                                  : () async {
                                      final saved = await ref
                                          .read(
                                            termsAcceptanceProvider.notifier,
                                          )
                                          .accept();
                                      if (!context.mounted) {
                                        return;
                                      }
                                      if (!saved) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              l10n.authTermsSaveFailed,
                                            ),
                                          ),
                                        );
                                        return;
                                      }
                                      // Do not force a profile-setup route here.
                                      // The root app gate decides the next screen:
                                      // existing sign-in users go to Discover,
                                      // while new sign-up users continue setup if
                                      // their profile is incomplete.
                                    },
                            ),
                          ),
                        ],
                      ),
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

  Widget _buildHeader(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: scheme.primaryContainer,
          ),
          child: Icon(
            Icons.gavel_rounded,
            color: scheme.onPrimaryContainer,
            size: 34,
          ),
        ),
        const SizedBox(height: 14),
        Text(
          AppLocalizations.of(context).authTermsTitle,
          style: Theme.of(
            context,
          ).textTheme.displaySmall!.copyWith(color: scheme.onSurface),
        ),
        const SizedBox(height: 8),
        Text(
          AppLocalizations.of(context).authTermsSubtitle,
          textAlign: TextAlign.center,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
        ),
      ],
    );
  }

  Widget _termPoint(BuildContext context, String text) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 8,
          height: 8,
          margin: const EdgeInsets.only(top: 8),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(text, style: Theme.of(context).textTheme.bodyMedium),
        ),
      ],
    ),
  );
}
