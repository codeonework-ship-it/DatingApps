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
      appBar: AppBar(title: const Text('A voice, a little closer')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                Text(
                  'Let your hello\nsound like you.',
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    fontFamily: AppTheme.displayFamily,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'An optional 20–45 second introduction, shared only in this conversation. Text is always welcome, too.',
                ),
                const SizedBox(height: 24),
                if (widget.matchId != null)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.lock_outline_rounded),
                    title: Text('You and ${_partnerName ?? 'your match'}'),
                    subtitle: const Text('Private to this conversation'),
                  )
                else if (matches!.isLoading)
                  const LinearProgressIndicator()
                else if (matches.error != null)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Your conversations couldn’t load.'),
                      TextButton(
                        onPressed: () => ref.invalidate(matchNotifierProvider),
                        child: const Text('Try again'),
                      ),
                    ],
                  )
                else if (matches.matches.isEmpty)
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: Text(
                        'When you have a match, you can share a voice introduction here. No rush.',
                      ),
                    ),
                  )
                else
                  DropdownButtonFormField<String>(
                    key: const ValueKey('qa.voice.conversation'),
                    isExpanded: true,
                    initialValue: matches.matches.any((m) => m.id == _matchId)
                        ? _matchId
                        : null,
                    decoration: const InputDecoration(
                      labelText: 'Who would you like to say hello to?',
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
                            'A small starting point',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 12),
                          if (state.isLoading && prompts.isEmpty)
                            const LinearProgressIndicator()
                          else
                            DropdownButtonFormField<String>(
                              isExpanded: true,
                              initialValue: promptId,
                              decoration: const InputDecoration(
                                labelText: 'Choose a prompt',
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
                            decoration: const InputDecoration(
                              labelText: 'Your words, in writing',
                              helperText:
                                  'Write what you say so they can read it, too. This is not automatic transcription.',
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
                                  ? 'Stop · ${_durationSeconds}s'
                                  : _recording == null
                                  ? 'Record your hello'
                                  : 'Record again · ${_durationSeconds}s',
                            ),
                          ),
                          if (_recording != null && !_isRecording) ...[
                            const SizedBox(height: 8),
                            Text(
                              _durationSeconds >= 20
                                  ? 'Recording ready. Check your transcript before sending.'
                                  : 'That was a little short. Record 20–45 seconds.',
                            ),
                            TextButton(
                              onPressed: state.isSubmitting
                                  ? null
                                  : () => setState(() {
                                      _recording = null;
                                      _durationSeconds = 0;
                                    }),
                              child: const Text('Discard recording'),
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
                                        const SnackBar(
                                          content: Text(
                                            'Introduction submitted. Approved recordings appear below.',
                                          ),
                                        ),
                                      );
                                    }
                                  },
                            child: Text(
                              state.isSubmitting
                                  ? 'Sending…'
                                  : 'Share your hello',
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Recordings are checked before they are shared. There is no autoplay.',
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Your voice introductions',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'The latest 20 approved recordings in this conversation. Transcripts are always available to read.',
                  ),
                  const SizedBox(height: 12),
                  ref
                      .watch(voiceIntroductionsProvider(_matchId!))
                      .when(
                        loading: () => const LinearProgressIndicator(),
                        error: (_, __) => Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Introductions couldn’t load. The conversation may no longer be available.',
                            ),
                            TextButton(
                              onPressed: () => ref.invalidate(
                                voiceIntroductionsProvider(_matchId!),
                              ),
                              child: const Text('Try again'),
                            ),
                          ],
                        ),
                        data: (items) => items.isEmpty
                            ? const Padding(
                                padding: EdgeInsets.symmetric(vertical: 20),
                                child: Text(
                                  'Nothing shared yet. A simple hello is a good beginning.',
                                ),
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
                                                  ? 'Your hello'
                                                  : 'A hello from ${_partnerName ?? 'your match'}',
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
                                            const Text('TRANSCRIPT'),
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
                                                    ? 'Stop playback'
                                                    : 'Listen · ${item.durationSeconds}s',
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
                      child: const Text('Reload prompts'),
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
            () => _recordingError =
                'Allow microphone access to record. You can still read transcripts without it.',
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
          () => _recordingError =
              'Unable to start recording. Check microphone access and try again.',
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
        _recordingError = 'The recording could not be saved. Please try again.';
      }
    });
  }
}
