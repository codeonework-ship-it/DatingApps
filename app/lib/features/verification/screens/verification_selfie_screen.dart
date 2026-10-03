import '../../../core/platform/platform_photo.dart';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/qa_control.dart';
import '../../../l10n/app_localizations.dart';
import '../providers/verification_provider.dart';
import 'verification_status_screen.dart';

class VerificationSelfieScreen extends ConsumerStatefulWidget {
  const VerificationSelfieScreen({required this.idPhoto, super.key});
  final XFile idPhoto;

  @override
  ConsumerState<VerificationSelfieScreen> createState() =>
      _VerificationSelfieScreenState();
}

class _VerificationSelfieScreenState
    extends ConsumerState<VerificationSelfieScreen> {
  XFile? _selfie;
  // One upload at a time: the button stayed live while sending, so a second
  // tap uploaded the evidence twice.
  bool _submitting = false;
  // Only a failed upload shows the upload error (not a failed status check).
  bool _submitFailed = false;

  @override
  Widget build(BuildContext context) {
    final notifier = ref.read(verificationNotifierProvider.notifier);
    final state = ref.watch(verificationNotifierProvider);
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.verificationSelfieTitle)),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: AppTheme.contentMaxWidth,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(l10n.verificationSelfieInstruction),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 280,
                    width: double.infinity,
                    child: _selfie != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: platformPhoto(
                              _selfie!.path,
                              fit: BoxFit.cover,
                            ),
                          )
                        : const Center(child: Icon(Icons.face, size: 72)),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: QaControl(
                          id: 'qa.verification.selfie.gallery_button',
                          child: OutlinedButton.icon(
                            key: const ValueKey(
                              'qa.verification.selfie.gallery_button',
                            ),
                            onPressed: () async {
                              final picked = await notifier.pickSelfie(
                                fromCamera: false,
                              );
                              if (picked != null) {
                                setState(() => _selfie = picked);
                              }
                            },
                            icon: const Icon(Icons.photo_library),
                            label: Text(l10n.verificationGallery),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          key: const ValueKey(
                            'qa.verification.selfie.camera_button',
                          ),
                          onPressed: () async {
                            final picked = await notifier.pickSelfie(
                              fromCamera: true,
                            );
                            if (picked != null) {
                              setState(() => _selfie = picked);
                            }
                          },
                          icon: const Icon(Icons.photo_camera),
                          label: Text(l10n.verificationCamera),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (_submitFailed) ...[
                    Text(
                      l10n.verificationUploadFailed,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  QaControl(
                    id: 'qa.verification.selfie.submit_button',
                    child: ElevatedButton(
                      key: const ValueKey(
                        'qa.verification.selfie.submit_button',
                      ),
                      onPressed: _selfie == null || _submitting
                          ? null
                          : () {
                              if (_submitting) {
                                return;
                              }
                              setState(() {
                                _submitting = true;
                                _submitFailed = false;
                              });
                              unawaited(() async {
                                final submitted = await notifier.submit(
                                  idPhoto: widget.idPhoto,
                                  selfiePhoto: _selfie!,
                                );

                                if (!context.mounted) {
                                  return;
                                }
                                if (!submitted) {
                                  setState(() {
                                    _submitting = false;
                                    _submitFailed = true;
                                  });
                                  return;
                                }
                                Navigator.of(context).pushReplacement(
                                  MaterialPageRoute<void>(
                                    builder: (_) =>
                                        const VerificationStatusScreen(),
                                  ),
                                );
                              }());
                            },
                      child: state.isLoading
                          ? const CircularProgressIndicator()
                          : Text(l10n.verificationSubmit),
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
