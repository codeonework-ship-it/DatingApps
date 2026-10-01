import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/glass_widgets.dart';
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
                            'Please review and accept our Terms and '
                            'Privacy Policy to continue.',
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                          const SizedBox(height: 18),
                          Text(
                            'Community expectations',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 12),
                          _termPoint(context, 'Be respectful and authentic.'),
                          _termPoint(
                            context,
                            'No harassment or fraudulent behavior.',
                          ),
                          _termPoint(
                            context,
                            'You control your privacy settings and '
                            'profile visibility.',
                          ),
                          _termPoint(
                            context,
                            'Reports are reviewed to keep the community safe.',
                          ),
                          _termPoint(
                            context,
                            'Violations may result in suspension or '
                            'account removal.',
                          ),
                          const SizedBox(height: 18),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: scheme.primaryContainer,
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: Text(
                              'You can review the full policy details later '
                              'from settings, but acceptance is required '
                              'before using the app.',
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
                                          'I agree to the Terms & Privacy Policy',
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
                              label: 'I Accept and Continue',
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
                                          const SnackBar(
                                            content: Text(
                                              'Could not save your agreement. Please check network and try again.',
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
          'Terms and Conditions',
          style: Theme.of(
            context,
          ).textTheme.displaySmall!.copyWith(color: scheme.onSurface),
        ),
        const SizedBox(height: 8),
        Text(
          'A quick review before you enter the app.',
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
