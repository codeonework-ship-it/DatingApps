import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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

    return Scaffold(
      appBar: AppBar(title: const Text('User Agreement')),
      body: CrystalScaffold(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: GlassContainer(
              padding: const EdgeInsets.all(20),
              backgroundColor: Colors.white.withValues(alpha: 0.9),
              blur: 12,
              borderRadius: const BorderRadius.all(Radius.circular(24)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'User Agreement',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Text(
                        'Please review and accept our Terms and Privacy Policy to continue.\n\n'
                        'Key points:\n'
                        '- Be respectful and authentic.\n'
                        '- No harassment or fraudulent behavior.\n'
                        '- You control your privacy settings.\n'
                        '- Reports are reviewed to keep the community safe.\n'
                        '- Violations may result in suspension or account removal.\n\n'
                        'By continuing, you consent to phone verification, profile moderation, '
                        'and processing described in our Terms and Privacy Policy.',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Checkbox(
                        value: _accepted,
                        onChanged: (v) =>
                            setState(() => _accepted = v ?? false),
                      ),
                      const Expanded(
                        child: Text('I agree to the Terms & Privacy Policy'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  GlassButton(
                    label: 'I Agree & Continue',
                    isLoading: termsState.isLoading,
                    onPressed: _accepted
                        ? () {
                            unawaited(
                              ref
                                  .read(termsAcceptanceProvider.notifier)
                                  .accept(),
                            );
                          }
                        : null,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
