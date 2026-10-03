import '../../../core/platform/platform_photo.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/qa_control.dart';
import '../../../l10n/app_localizations.dart';
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
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.verificationUploadIdTitle)),
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
                  Text(l10n.verificationUploadIdInstruction),
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
                        child: QaControl(
                          id: 'qa.verification.id.gallery_button',
                          child: OutlinedButton.icon(
                            key: const ValueKey(
                              'qa.verification.id.gallery_button',
                            ),
                            onPressed: () async {
                              final picked = await notifier.pickIdPhoto(
                                fromCamera: false,
                              );
                              if (picked != null) {
                                setState(() => _id = picked);
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
                            'qa.verification.id.camera_button',
                          ),
                          onPressed: () async {
                            final picked = await notifier.pickIdPhoto(
                              fromCamera: true,
                            );
                            if (picked != null) {
                              setState(() => _id = picked);
                            }
                          },
                          icon: const Icon(Icons.photo_camera),
                          label: Text(l10n.verificationCamera),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  QaControl(
                    id: 'qa.verification.id.next_button',
                    child: ElevatedButton(
                      key: const ValueKey('qa.verification.id.next_button'),
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
                      child: Text(l10n.verificationNext),
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
