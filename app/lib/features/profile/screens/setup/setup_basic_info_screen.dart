import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/glass_widgets.dart';
import '../../providers/profile_setup_provider.dart';
import 'setup_photos_screen.dart';

class SetupBasicInfoScreen extends ConsumerStatefulWidget {
  const SetupBasicInfoScreen({super.key});

  @override
  ConsumerState<SetupBasicInfoScreen> createState() =>
      _SetupBasicInfoScreenState();
}

class _SetupBasicInfoScreenState extends ConsumerState<SetupBasicInfoScreen> {
  final _nameController = TextEditingController();
  DateTime? _dob;
  String _gender = 'M';
  var _didInitialize = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final draftAsync = ref.watch(profileSetupNotifierProvider);

    return draftAsync.when(
      loading: () => Scaffold(
        appBar: AppBar(title: const Text('Basic Info')),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (_, _) => Scaffold(
        appBar: AppBar(title: const Text('Basic Info')),
        body: Center(
          child: TextButton(
            onPressed: () => ref.invalidate(profileSetupNotifierProvider),
            child: const Text('Retry'),
          ),
        ),
      ),
      data: (draft) {
        if (!_didInitialize) {
          _nameController.text = draft.name;
          _dob = draft.dateOfBirth;
          _gender = draft.gender;
          _didInitialize = true;
        }

        return Scaffold(
          appBar: AppBar(title: const Text('Basic Info')),
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
                      padding: const EdgeInsets.all(20),
                      backgroundColor: Colors.white.withValues(alpha: 0.95),
                      blur: 10,
                      borderRadius: const BorderRadius.all(Radius.circular(24)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Basic Info',
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _nameController,
                            decoration: const InputDecoration(
                              labelText: 'Name',
                            ),
                          ),
                          const SizedBox(height: 12),
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text('Date of birth'),
                            subtitle: Text(
                              _dob == null
                                  ? 'Select'
                                  : '${_dob!.year}-${_dob!.month.toString().padLeft(2, '0')}-${_dob!.day.toString().padLeft(2, '0')}',
                            ),
                            trailing: const Icon(Icons.calendar_today),
                            onTap: () async {
                              final now = DateTime.now();
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: DateTime(now.year - 24, 1, 1),
                                firstDate: DateTime(now.year - 80, 1, 1),
                                lastDate: DateTime(now.year - 18, 12, 31),
                              );
                              if (picked != null) setState(() => _dob = picked);
                            },
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Gender',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            children: [
                              _genderChip('M', 'Male'),
                              _genderChip('F', 'Female'),
                              _genderChip('Other', 'Other'),
                            ],
                          ),
                          const Spacer(),
                          GlassButton(
                            label: 'Next',
                            onPressed: () async {
                              final name = _nameController.text.trim();
                              if (name.length <
                                  ValidationConstants.minNameLength) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Name must be at least 2 characters.',
                                    ),
                                  ),
                                );
                                return;
                              }
                              if (_dob == null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Please select your date of birth.',
                                    ),
                                  ),
                                );
                                return;
                              }

                              await ref
                                  .read(profileSetupNotifierProvider.notifier)
                                  .saveBasicInfo(
                                    name: name,
                                    dateOfBirth: _dob!,
                                    gender: _gender,
                                  );

                              if (!context.mounted) return;
                              Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) => const SetupPhotosScreen(),
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

  Widget _genderChip(String value, String label) {
    final selected = _gender == value;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => setState(() => _gender = value),
    );
  }
}
