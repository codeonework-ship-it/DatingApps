import 'dart:async';

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
                      padding: const EdgeInsets.all(22),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.94),
                        borderRadius: const BorderRadius.all(
                          Radius.circular(28),
                        ),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.72),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.crystalGoldDeep.withValues(
                              alpha: 0.18,
                            ),
                            blurRadius: 24,
                            offset: const Offset(0, 12),
                          ),
                        ],
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
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: AppTheme.crystalGoldFog.withValues(
                                alpha: 0.36,
                              ),
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: AppTheme.crystalGoldSoft.withValues(
                                  alpha: 0.34,
                                ),
                              ),
                            ),
                            child: Text(
                              'You can review the full policy details later '
                              'from settings, but acceptance is required '
                              'before using the app.',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ),
                          const SizedBox(height: 18),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: AppTheme.crystalGoldSoft.withValues(
                                  alpha: 0.34,
                                ),
                              ),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Checkbox(
                                  value: _accepted,
                                  activeColor: AppTheme.crystalGoldSoft,
                                  checkColor: AppTheme.textDark,
                                  onChanged: (value) {
                                    setState(() {
                                      _accepted = value ?? false;
                                    });
                                  },
                                ),
                                const Expanded(
                                  child: Padding(
                                    padding: EdgeInsets.only(top: 10),
                                    child: Text(
                                      'I agree to the Terms & Privacy Policy',
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 18),
                          GlassButton(
                            label: 'I Agree & Continue',
                            icon: Icons.check_circle_rounded,
                            shinyEffect: true,
                            isLoading: termsState.isLoading,
                            onPressed: !_accepted
                                ? null
                                : () {
                                    unawaited(
                                      ref
                                          .read(
                                            termsAcceptanceProvider.notifier,
                                          )
                                          .accept(),
                                    );
                                  },
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

  Widget _buildHeader(BuildContext context) => Column(
    children: [
      Container(
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            colors: [Color(0x99FFFFFF), Color(0x66F5D179)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(color: Colors.white.withValues(alpha: 0.45)),
        ),
        child: const Icon(Icons.gavel_rounded, color: Colors.white, size: 34),
      ),
      const SizedBox(height: 14),
      GradientText(
        'Terms & Conditions',
        style: Theme.of(context).textTheme.displaySmall!,
        gradient: const LinearGradient(
          colors: [Colors.white, Color(0xFFF8E2A8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      const SizedBox(height: 8),
      Text(
        'A quick review before you enter the app.',
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: Colors.white.withValues(alpha: 0.86),
        ),
      ),
    ],
  );

  Widget _termPoint(BuildContext context, String text) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 8,
          height: 8,
          margin: const EdgeInsets.only(top: 6),
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [AppTheme.crystalGoldSoft, AppTheme.crystalGoldDeep],
            ),
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
