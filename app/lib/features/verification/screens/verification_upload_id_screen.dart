import '../../../core/platform/platform_photo.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/theme/app_theme.dart';
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
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: AppTheme.contentMaxWidth,
            ),
            // Scrollable: the ID preview is a fixed 280pt block, so on a 568pt
            // phone the column is taller than the viewport once the app bar,
            // status bar and home indicator are accounted for. Centring a
            // non-scrolling column there clips the action buttons off-screen,
            // which strands the user mid-verification.
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Take or upload a clear photo of your government ID.',
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 280,
                    width: double.infinity,
                    child: _id != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: platformPhoto(_id!.path, fit: BoxFit.cover),
                          )
                        : const Center(child: Icon(Icons.badge, size: 72)),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Semantics(
                          label: 'qa.verification.id.gallery_button',
                          button: true,
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
                  Semantics(
                    label: 'qa.verification.id.next_button',
                    button: true,
                    child: ElevatedButton(
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
                      child: const Text('Next'),
                    ),
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
