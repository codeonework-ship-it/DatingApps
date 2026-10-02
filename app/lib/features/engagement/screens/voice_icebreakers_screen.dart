import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/providers/auth_provider.dart';
import '../../matching/providers/match_provider.dart';
import '../engagement_l10n.dart';
import '../providers/voice_icebreaker_provider.dart';

class VoiceIcebreakersScreen extends ConsumerStatefulWidget {
  const VoiceIcebreakersScreen({
    super.key,
    this.matchId,
    this.receiverUserId,
    this.partnerName,
  });
  final String? matchId, receiverUserId, partnerName;
  @override
  ConsumerState<VoiceIcebreakersScreen> createState() =>
      _VoiceIcebreakersScreenState();
}

class _VoiceIcebreakersScreenState
    extends ConsumerState<VoiceIcebreakersScreen> {
  final _transcriptController = TextEditingController();
  final AudioRecorder _recorder = AudioRecorder();
  String? _matchId, _receiverId, _partnerName, _selectedPromptId;
  int _durationSeconds = 0;
  XFile? _recording;
  Timer? _recordingTimer;
  bool _isRecording = false;
  String? _recordingError;
  @override
  void initState() {
    super.initState();
    _matchId = widget.matchId;
    _receiverId = widget.receiverUserId;
    _partnerName = widget.partnerName;
  }

  @override
  void dispose() {
    _recordingTimer?.cancel();
    unawaited(_recorder.dispose());
    _transcriptController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = engagementL10n(context);
    final state = ref.watch(voiceIcebreakerProvider);
    final notifier = ref.read(voiceIcebreakerProvider.notifier);
    final matches = widget.matchId == null
        ? ref.watch(matchNotifierProvider)
        : null;
    final prompts = state.prompts;
    final promptId =
        _selectedPromptId ?? (prompts.isNotEmpty ? prompts.first.id : null);
    final locked = state.isSubmitting || _isRecording || _recording != null;
    return Scaffold(
      appBar: AppBar(title: Text(l.engagementVoiceAppBarTitle)),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                Text(
                  l.engagementVoiceHeadline,
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    fontFamily: AppTheme.displayFamily,
                  ),
                ),
                const SizedBox(height: 12),
                Text(l.engagementVoiceIntro),
                const SizedBox(height: 24),
                if (widget.matchId != null)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.lock_outline_rounded),
                    title: Text(
                      _partnerName == null
                          ? l.engagementVoiceYouAndYourMatch
                          : l.engagementVoiceYouAndName(_partnerName!),
                    ),
                    subtitle: Text(l.engagementVoicePrivate),
                  )
                else if (matches!.isLoading)
                  const LinearProgressIndicator()
                else if (matches.error != null)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l.engagementVoiceConversationsLoadFailed),
                      TextButton(
                        onPressed: () => ref.invalidate(matchNotifierProvider),
                        child: Text(l.chatTryAgain),
                      ),
                    ],
                  )
                else if (matches.matches.isEmpty)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Text(l.engagementVoiceNoMatches),
                    ),
                  )
                else
                  DropdownButtonFormField<String>(
                    key: const ValueKey('qa.voice.conversation'),
                    isExpanded: true,
                    initialValue: matches.matches.any((m) => m.id == _matchId)
                        ? _matchId
                        : null,
                    decoration: InputDecoration(
                      labelText: l.engagementVoicePickConversation,
                    ),
                    items: matches.matches
                        .map(
                          (m) => DropdownMenuItem(
                            value: m.id,
                            child: Text(m.userName),
                          ),
                        )
                        .toList(),
                    onChanged: locked
                        ? null
                        : (id) {
                            final m = matches.matches.firstWhere(
                              (m) => m.id == id,
                            );
                            setState(() {
                              _matchId = m.id;
                              _receiverId = m.userId;
                              _partnerName = m.userName;
                              _transcriptController.clear();
                            });
                          },
                  ),
                if (_matchId != null) ...[
                  const SizedBox(height: 20),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            l.engagementVoiceStartingPoint,
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 12),
                          if (state.isLoading && prompts.isEmpty)
                            const LinearProgressIndicator()
                          else
                            DropdownButtonFormField<String>(
                              isExpanded: true,
                              initialValue: promptId,
                              decoration: InputDecoration(
                                labelText: l.engagementVoiceChoosePrompt,
                              ),
                              items: prompts
                                  .map(
                                    (p) => DropdownMenuItem(
                                      value: p.id,
                                      child: Text(
                                        p.promptText,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  )
                                  .toList(),
                              onChanged: locked || prompts.isEmpty
                                  ? null
                                  : (v) =>
                                        setState(() => _selectedPromptId = v),
                            ),
                          const SizedBox(height: 16),
                          TextField(
                            key: const ValueKey('qa.voice.transcript'),
                            controller: _transcriptController,
                            minLines: 3,
                            maxLines: 6,
                            maxLength: 2000,
                            enabled: !state.isSubmitting && !_isRecording,
                            onChanged: (_) => setState(() {}),
                            decoration: InputDecoration(
                              labelText: l.engagementVoiceTranscriptLabel,
                              helperText: l.engagementVoiceTranscriptHelper,
                              helperMaxLines: 3,
                            ),
                          ),
                          const SizedBox(height: 12),
                          FilledButton.tonalIcon(
                            key: const ValueKey('qa.voice.recording_button'),
                            onPressed: state.isSubmitting || state.isPlaying
                                ? null
                                : _isRecording
                                ? _stopRecording
                                : _startRecording,
                            icon: Icon(
                              _isRecording
                                  ? Icons.stop_rounded
                                  : Icons.mic_none_rounded,
                            ),
                            label: Text(
                              _isRecording
                                  ? l.engagementVoiceStop(_durationSeconds)
                                  : _recording == null
                                  ? l.engagementVoiceRecord
                                  : l.engagementVoiceRecordAgain(
                                      _durationSeconds,
                                    ),
                            ),
                          ),
                          if (_recording != null && !_isRecording) ...[
                            const SizedBox(height: 8),
                            Text(
                              _durationSeconds >= 20
                                  ? l.engagementVoiceRecordingReady
                                  : l.engagementVoiceRecordingShort,
                            ),
                            TextButton(
                              onPressed: state.isSubmitting
                                  ? null
                                  : () => setState(() {
                                      _recording = null;
                                      _durationSeconds = 0;
                                    }),
                              child: Text(l.engagementVoiceDiscard),
                            ),
                          ],
                          if (_recordingError != null)
                            Text(
                              _recordingError!,
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.error,
                              ),
                            ),
                          const SizedBox(height: 16),
                          FilledButton(
                            onPressed:
                                state.isSubmitting ||
                                    _isRecording ||
                                    _receiverId == null ||
                                    promptId == null ||
                                    _recording == null ||
                                    _durationSeconds < 20 ||
                                    _durationSeconds > 45 ||
                                    _transcriptController.text.trim().isEmpty
                                ? null
                                : () async {
                                    await notifier.startAndSend(
                                      matchId: _matchId!,
                                      receiverUserId: _receiverId!,
                                      promptId: promptId,
                                      transcript: _transcriptController.text,
                                      durationSeconds: _durationSeconds,
                                      audioFile: _recording!,
                                    );
                                    if (!mounted) return;
                                    final result = ref.read(
                                      voiceIcebreakerProvider,
                                    );
                                    if (result.error == null &&
                                        result.lastItem != null) {
                                      setState(() {
                                        _recording = null;
                                        _durationSeconds = 0;
                                        _transcriptController.clear();
                                      });
                                      ref.invalidate(
                                        voiceIntroductionsProvider(_matchId!),
                                      );
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            l.engagementVoiceSubmitted,
                                          ),
                                        ),
                                      );
                                    }
                                  },
                            child: Text(
                              state.isSubmitting
                                  ? l.engagementVoiceSending
                                  : l.engagementVoiceShare,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(l.engagementVoiceCheckedNote),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    l.engagementVoiceYourIntros,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(l.engagementVoiceLatestNote),
                  const SizedBox(height: 12),
                  ref
                      .watch(voiceIntroductionsProvider(_matchId!))
                      .when(
                        loading: () => const LinearProgressIndicator(),
                        error: (_, __) => Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(l.engagementVoiceIntrosLoadFailed),
                            TextButton(
                              onPressed: () => ref.invalidate(
                                voiceIntroductionsProvider(_matchId!),
                              ),
                              child: Text(l.chatTryAgain),
                            ),
                          ],
                        ),
                        data: (items) => items.isEmpty
                            ? Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 20,
                                ),
                                child: Text(l.engagementVoiceNothingYet),
                              )
                            : Column(
                                children: [
                                  for (final item in items)
                                    Card(
                                      child: Padding(
                                        padding: const EdgeInsets.all(20),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              item.senderUserId ==
                                                      ref
                                                          .watch(
                                                            authNotifierProvider,
                                                          )
                                                          .userId
                                                  ? l.engagementVoiceYourHello
                                                  : _partnerName == null
                                                  ? l.engagementVoiceHelloFromYourMatch
                                                  : l.engagementVoiceHelloFromName(
                                                      _partnerName!,
                                                    ),
                                              style: Theme.of(
                                                context,
                                              ).textTheme.titleMedium,
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                              item.promptText,
                                              style: Theme.of(
                                                context,
                                              ).textTheme.labelLarge,
                                            ),
                                            const SizedBox(height: 12),
                                            Text(
                                              l.engagementVoiceTranscriptHeading,
                                            ),
                                            const SizedBox(height: 6),
                                            SelectableText(item.transcript),
                                            const SizedBox(height: 12),
                                            OutlinedButton.icon(
                                              onPressed:
                                                  state.isPlaying &&
                                                      state.lastItem?.id ==
                                                          item.id
                                                  ? notifier.stopPlaying
                                                  : state.isPlaying ||
                                                        _isRecording ||
                                                        state.isSubmitting
                                                  ? null
                                                  : () => notifier.play(item),
                                              icon: Icon(
                                                state.isPlaying &&
                                                        state.lastItem?.id ==
                                                            item.id
                                                    ? Icons.stop_rounded
                                                    : Icons.play_arrow_rounded,
                                              ),
                                              label: Text(
                                                state.isPlaying &&
                                                        state.lastItem?.id ==
                                                            item.id
                                                    ? l.engagementVoiceStopPlayback
                                                    : l.engagementVoiceListen(
                                                        item.durationSeconds,
                                                      ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                      ),
                ],
                if (state.error != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    state.error!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                  if (prompts.isEmpty)
                    TextButton(
                      onPressed: notifier.loadPrompts,
                      child: Text(l.engagementVoiceReloadPrompts),
                    ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _startRecording() async {
    setState(() {
      _recording = null;
      _durationSeconds = 0;
      _recordingError = null;
    });
    try {
      if (!await _recorder.hasPermission()) {
        if (mounted)
          setState(
            () => _recordingError = engagementL10n(
              context,
            ).engagementVoiceMicPermission,
          );
        return;
      }
      if (!mounted) return;
      final filename =
          'connect-voice-${DateTime.now().millisecondsSinceEpoch}.${kIsWeb ? 'webm' : 'm4a'}';
      final outputPath = kIsWeb
          ? filename
          : '${(await getTemporaryDirectory()).path}/$filename';
      await _recorder.start(
        RecordConfig(
          encoder: kIsWeb ? AudioEncoder.opus : AudioEncoder.aacLc,
          numChannels: 1,
          sampleRate: 48000,
          bitRate: 96000,
        ),
        path: outputPath,
      );
      if (!mounted) return;
      setState(() => _isRecording = true);
      _recordingTimer?.cancel();
      _recordingTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (!mounted) return;
        final next = _durationSeconds + 1;
        setState(() => _durationSeconds = next);
        if (next >= 45) unawaited(_stopRecording());
      });
    } on Object catch (_) {
      if (mounted) {
        setState(
          () => _recordingError = engagementL10n(
            context,
          ).engagementVoiceStartFailed,
        );
      }
    }
  }

  Future<void> _stopRecording() async {
    _recordingTimer?.cancel();
    String? outputPath;
    try {
      outputPath = await _recorder.stop();
    } catch (_) {
      outputPath = null;
    }
    if (!mounted) return;
    setState(() {
      _isRecording = false;
      _recording = outputPath == null ? null : XFile(outputPath);
      if (outputPath == null) {
        _recordingError = engagementL10n(context).engagementVoiceSaveFailed;
      }
    });
  }
}
