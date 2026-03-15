import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/glass_widgets.dart';
import '../../providers/preference_master_data_provider.dart';
import '../../providers/profile_setup_provider.dart';
import 'setup_preview_screen.dart';

class SetupLifestyleScreen extends ConsumerStatefulWidget {
  const SetupLifestyleScreen({super.key});

  @override
  ConsumerState<SetupLifestyleScreen> createState() =>
      _SetupLifestyleScreenState();
}

class _SetupLifestyleScreenState extends ConsumerState<SetupLifestyleScreen> {
  String _drinking = 'Never';
  String _smoking = 'Never';
  String? _religion;
  var _didInitialize = false;

  @override
  Widget build(BuildContext context) {
    final draftAsync = ref.watch(profileSetupNotifierProvider);
    final masterData = ref
        .watch(preferenceMasterDataProvider)
        .maybeWhen(data: (data) => data, orElse: PreferenceMasterData.empty);
    final religionOptions = <String?>[null, ...masterData.religions];

    return draftAsync.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (_, _) => Scaffold(
        body: Center(
          child: TextButton(
            onPressed: () => ref.invalidate(profileSetupNotifierProvider),
            child: const Text('Retry'),
          ),
        ),
      ),
      data: (draft) {
        if (!_didInitialize) {
          _drinking = draft.drinking;
          _smoking = draft.smoking;
          _religion = draft.religion;
          _didInitialize = true;
        }

        return Scaffold(
          appBar: AppBar(title: const Text('Lifestyle')),
          body: Container(
            decoration: const BoxDecoration(gradient: AppTheme.bgGradient),
            child: SafeArea(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: AppTheme.contentMaxWidth,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: GlassContainer(
                      padding: const EdgeInsets.all(16),
                      backgroundColor: Colors.white.withValues(alpha: 0.95),
                      blur: 10,
                      borderRadius: const BorderRadius.all(Radius.circular(24)),
                      child: Column(
                        children: [
                          DropdownButtonFormField<String>(
                            initialValue: _drinking,
                            decoration: const InputDecoration(
                              labelText: 'Drinking',
                            ),
                            items: const [
                              DropdownMenuItem(
                                value: 'Never',
                                child: Text('Never'),
                              ),
                              DropdownMenuItem(
                                value: 'Socially',
                                child: Text('Socially'),
                              ),
                              DropdownMenuItem(
                                value: 'Regularly',
                                child: Text('Regularly'),
                              ),
                            ],
                            onChanged: (v) =>
                                setState(() => _drinking = v ?? 'Never'),
                          ),
                          const SizedBox(height: 12),
                          DropdownButtonFormField<String>(
                            initialValue: _smoking,
                            decoration: const InputDecoration(
                              labelText: 'Smoking',
                            ),
                            items: const [
                              DropdownMenuItem(
                                value: 'Never',
                                child: Text('Never'),
                              ),
                              DropdownMenuItem(
                                value: 'Socially',
                                child: Text('Socially'),
                              ),
                              DropdownMenuItem(
                                value: 'Regularly',
                                child: Text('Regularly'),
                              ),
                            ],
                            onChanged: (v) =>
                                setState(() => _smoking = v ?? 'Never'),
                          ),
                          const SizedBox(height: 12),
                          DropdownButtonFormField<String>(
                            initialValue: _religion,
                            decoration: const InputDecoration(
                              labelText: 'Religion (optional)',
                            ),
                            items: religionOptions
                                .map(
                                  (value) => DropdownMenuItem<String>(
                                    value: value,
                                    child: Text(value ?? 'Prefer not to say'),
                                  ),
                                )
                                .toList(growable: false),
                            onChanged: (v) => setState(() => _religion = v),
                          ),
                          const Spacer(),
                          GlassButton(
                            label: 'Next',
                            shinyEffect: true,
                            onPressed: () async {
                              await ref
                                  .read(profileSetupNotifierProvider.notifier)
                                  .saveLifestyle(
                                    drinking: _drinking,
                                    smoking: _smoking,
                                    religion: _religion,
                                  );

                              if (!context.mounted) return;
                              Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) => const SetupPreviewScreen(),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
