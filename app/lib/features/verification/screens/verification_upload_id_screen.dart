import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/glass_widgets.dart';
import '../providers/verification_provider.dart';
import 'verification_selfie_screen.dart';

class VerificationUploadIdScreen extends ConsumerStatefulWidget {
  const VerificationUploadIdScreen({super.key});

  @override
  ConsumerState<VerificationUploadIdScreen> createState() =>
      _VerificationUploadIdScreenState();
}

class _VerificationUploadIdScreenState
    extends ConsumerState<VerificationUploadIdScreen> {
  XFile? _id;

  @override
  Widget build(BuildContext context) {
    final notifier = ref.read(verificationNotifierProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Upload ID')),
      body: PostLoginBackdrop(
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
                  backgroundColor: Colors.white.withValues(alpha: 0.9),
                  blur: 12,
                  borderRadius: const BorderRadius.all(Radius.circular(24)),
                  child: Column(
                    children: [
                      const Text(
                        'Take or upload a clear photo of your government ID.',
                      ),
                      const SizedBox(height: 12),
                      if (_id != null)
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Image.file(
                              File(_id!.path),
                              fit: BoxFit.cover,
                            ),
                          ),
                        )
                      else
                        const Expanded(
                          child: Center(child: Icon(Icons.badge, size: 72)),
                        ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () async {
                                final picked = await notifier.pickIdPhoto(
                                  fromCamera: false,
                                );
                                if (picked != null) {
                                  setState(() => _id = picked);
                                }
                              },
                              icon: const Icon(Icons.photo_library),
                              label: const Text('Gallery'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () async {
                                final picked = await notifier.pickIdPhoto(
                                  fromCamera: true,
                                );
                                if (picked != null) {
                                  setState(() => _id = picked);
                                }
                              },
                              icon: const Icon(Icons.photo_camera),
                              label: const Text('Camera'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      GlassButton(
                        label: 'Next',
                        onPressed: _id == null
                            ? null
                            : () {
                                Navigator.of(context).push(
                                  MaterialPageRoute<void>(
                                    builder: (_) =>
                                        VerificationSelfieScreen(idPhoto: _id!),
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
  }
}
