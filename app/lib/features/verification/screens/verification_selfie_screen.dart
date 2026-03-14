import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/glass_widgets.dart';
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

    return Scaffold(
      appBar: AppBar(title: const Text('Selfie')),
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
                  child: LayoutBuilder(
                    builder: (context, constraints) => SingleChildScrollView(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: constraints.maxHeight,
                        ),
                        child: Column(
                          children: [
                            const Text('Take a clear selfie.'),
                            const SizedBox(height: 12),
                            SizedBox(
                              height: 280,
                              width: double.infinity,
                              child: _selfie != null
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(16),
                                      child: Image.file(
                                        File(_selfie!.path),
                                        fit: BoxFit.cover,
                                      ),
                                    )
                                  : const Center(
                                      child: Icon(Icons.face, size: 72),
                                    ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
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
                                    label: const Text('Gallery'),
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
                                    label: const Text('Camera'),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            GlassButton(
                              label: 'Submit',
                              isLoading: state.isLoading,
                              onPressed: _selfie == null
                                  ? null
                                  : () {
                                      unawaited(() async {
                                        await notifier.submit(
                                          idPhoto: widget.idPhoto,
                                          selfiePhoto: _selfie!,
                                        );

                                        if (!context.mounted) return;
                                        Navigator.of(context).pushReplacement(
                                          MaterialPageRoute<void>(
                                            builder: (_) =>
                                                const VerificationStatusScreen(),
                                          ),
                                        );
                                      }());
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
          ),
        ),
      ),
    );
  }
}
