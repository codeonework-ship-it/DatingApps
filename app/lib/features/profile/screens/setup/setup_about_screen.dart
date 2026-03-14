import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/glass_widgets.dart';
import '../../providers/profile_setup_provider.dart';
import 'setup_preferences_screen.dart';

class SetupAboutScreen extends ConsumerStatefulWidget {
  const SetupAboutScreen({super.key});

  @override
  ConsumerState<SetupAboutScreen> createState() => _SetupAboutScreenState();
}

class _SetupAboutScreenState extends ConsumerState<SetupAboutScreen> {
  final _bioController = TextEditingController();
  final _professionController = TextEditingController();
  int? _height;
  String? _education;
  String? _income;
  var _didInitialize = false;

  @override
  void dispose() {
    _bioController.dispose();
    _professionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final draftAsync = ref.watch(profileSetupNotifierProvider);

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
          _bioController.text = draft.bio;
          _professionController.text = draft.profession ?? '';
          _height = draft.heightCm;
          _education = draft.education;
          _income = draft.incomeRange;
          _didInitialize = true;
        }

        return Scaffold(
          appBar: AppBar(title: const Text('About You')),
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
                          TextField(
                            controller: _bioController,
                            maxLength: ValidationConstants.maxBioLength,
                            maxLines: 6,
                            decoration: const InputDecoration(
                              labelText: 'Bio',
                              hintText: 'Tell people about you (min 10 chars)',
                            ),
                          ),
                          const SizedBox(height: 12),
                          DropdownButtonFormField<int>(
                            initialValue: _height,
                            decoration: const InputDecoration(
                              labelText: 'Height (cm)',
                            ),
                            items: [
                              for (var h = 150; h <= 210; h++)
                                DropdownMenuItem(value: h, child: Text('$h')),
                            ],
                            onChanged: (v) => setState(() => _height = v),
                          ),
                          const SizedBox(height: 12),
                          DropdownButtonFormField<String>(
                            initialValue: _education,
                            decoration: const InputDecoration(
                              labelText: 'Education',
                            ),
                            items: const [
                              DropdownMenuItem(
                                value: 'High School',
                                child: Text('High School'),
                              ),
                              DropdownMenuItem(
                                value: "Bachelor's",
                                child: Text("Bachelor's"),
                              ),
                              DropdownMenuItem(
                                value: "Master's",
                                child: Text("Master's"),
                              ),
                              DropdownMenuItem(
                                value: 'PhD',
                                child: Text('PhD'),
                              ),
                              DropdownMenuItem(
                                value: 'Other',
                                child: Text('Other'),
                              ),
                            ],
                            onChanged: (v) => setState(() => _education = v),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _professionController,
                            decoration: const InputDecoration(
                              labelText: 'Profession',
                            ),
                          ),
                          const SizedBox(height: 12),
                          DropdownButtonFormField<String>(
                            initialValue: _income,
                            decoration: const InputDecoration(
                              labelText: 'Income (optional)',
                            ),
                            items: const [
                              DropdownMenuItem(
                                value: null,
                                child: Text('Prefer not to say'),
                              ),
                              DropdownMenuItem(
                                value: '0-5L',
                                child: Text('0-5L'),
                              ),
                              DropdownMenuItem(
                                value: '5-10L',
                                child: Text('5-10L'),
                              ),
                              DropdownMenuItem(
                                value: '10-20L',
                                child: Text('10-20L'),
                              ),
                              DropdownMenuItem(
                                value: '20L+',
                                child: Text('20L+'),
                              ),
                            ],
                            onChanged: (v) => setState(() => _income = v),
                          ),
                          const Spacer(),
                          GlassButton(
                            label: 'Next',
                            onPressed: () async {
                              final bio = _bioController.text.trim();
                              if (bio.length <
                                  ValidationConstants.minBioLength) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Bio must be at least 10 characters.',
                                    ),
                                  ),
                                );
                                return;
                              }

                              await ref
                                  .read(profileSetupNotifierProvider.notifier)
                                  .saveAbout(
                                    bio: bio,
                                    heightCm: _height,
                                    education: _education,
                                    profession:
                                        _professionController.text
                                            .trim()
                                            .isEmpty
                                        ? null
                                        : _professionController.text.trim(),
                                    incomeRange: _income,
                                  );

                              if (!context.mounted) return;
                              Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) => const SetupPreferencesScreen(
                                    isSetupFlow: true,
                                  ),
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
