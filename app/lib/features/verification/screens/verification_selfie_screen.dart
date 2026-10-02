import '../../../core/platform/platform_photo.dart';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/theme/app_theme.dart';
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
                        child: Semantics(
                          label: 'qa.verification.selfie.gallery_button',
                          button: true,
                          child: OutlinedButton.icon(
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
                  if (state.hasError) ...[
                    Text(
                      l10n.verificationUploadFailed,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  Semantics(
                    label: 'qa.verification.selfie.submit_button',
                    button: true,
                    child: ElevatedButton(
                      onPressed: _selfie == null
                          ? null
                          : () {
                              unawaited(() async {
                                final submitted = await notifier.submit(
                                  idPhoto: widget.idPhoto,
                                  selfiePhoto: _selfie!,
                                );

                                if (!context.mounted || !submitted) return;
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
