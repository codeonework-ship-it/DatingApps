import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/glass_widgets.dart';
import '../providers/voice_icebreaker_provider.dart';

class VoiceIcebreakersScreen extends ConsumerStatefulWidget {
  const VoiceIcebreakersScreen({super.key});

  @override
  ConsumerState<VoiceIcebreakersScreen> createState() =>
      _VoiceIcebreakersScreenState();
}

class _VoiceIcebreakersScreenState
    extends ConsumerState<VoiceIcebreakersScreen> {
  final TextEditingController _matchController = TextEditingController();
  final TextEditingController _receiverController = TextEditingController();
  final TextEditingController _transcriptController = TextEditingController();
  final TextEditingController _playUserController = TextEditingController();

  int _durationSeconds = 30;
  String? _selectedPromptId;

  @override
  void dispose() {
    _matchController.dispose();
    _receiverController.dispose();
    _transcriptController.dispose();
    _playUserController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(voiceIcebreakerProvider);
    final notifier = ref.read(voiceIcebreakerProvider.notifier);

    final prompts = state.prompts;
    final effectivePromptId =
        _selectedPromptId ?? (prompts.isNotEmpty ? prompts.first.id : null);

    return Scaffold(
      appBar: AppBar(title: const Text('Guided Voice Icebreakers')),
      body: PostLoginBackdrop(
        child: SafeArea(
          child: RefreshIndicator(
            onRefresh: notifier.loadPrompts,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _card(
                  context,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Send one guided voice icebreaker',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Use a match id, receiver user id, pick a prompt, and submit transcript with duration (20–45 sec).',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.textGrey,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                _card(
                  context,
                  child: Column(
                    children: [
                      TextField(
                        controller: _matchController,
                        decoration: const InputDecoration(
                          labelText: 'Match ID',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _receiverController,
                        decoration: const InputDecoration(
                          labelText: 'Receiver User ID',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 10),
                      if (state.isLoading && prompts.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8),
                          child: CircularProgressIndicator(),
                        )
                      else
                        DropdownButtonFormField<String>(
                          initialValue: effectivePromptId,
                          items: prompts
                              .map(
                                (prompt) => DropdownMenuItem<String>(
                                  value: prompt.id,
                                  child: Text(prompt.promptText),
                                ),
                              )
                              .toList(growable: false),
                          onChanged: prompts.isEmpty
                              ? null
                              : (value) {
                                  setState(() {
                                    _selectedPromptId = value;
                                  });
                                },
                          decoration: const InputDecoration(
                            labelText: 'Guided prompt',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _transcriptController,
                        minLines: 3,
                        maxLines: 4,
                        decoration: const InputDecoration(
                          labelText: 'Transcript',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Text(
                            'Duration: ${_durationSeconds}s',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                      Slider(
                        value: _durationSeconds.toDouble(),
                        min: 20,
                        max: 45,
                        divisions: 25,
                        label: '$_durationSeconds',
                        onChanged: (value) {
                          setState(() {
                            _durationSeconds = value.round();
                          });
                        },
                      ),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed:
                              state.isSubmitting || effectivePromptId == null
                              ? null
                              : () => notifier.startAndSend(
                                  matchId: _matchController.text,
                                  receiverUserId: _receiverController.text,
                                  promptId: effectivePromptId,
                                  transcript: _transcriptController.text,
                                  durationSeconds: _durationSeconds,
                                ),
                          child: const Text('Send Voice Icebreaker'),
                        ),
                      ),
                    ],
                  ),
                ),
                if (state.lastItem != null) ...[
                  const SizedBox(height: 12),
                  _card(
                    context,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Latest icebreaker',
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 6),
                        Text('ID: ${state.lastItem!.id}'),
                        Text('Status: ${state.lastItem!.status}'),
                        Text('Play count: ${state.lastItem!.playCount}'),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _playUserController,
                          decoration: const InputDecoration(
                            labelText:
                                'User ID to mark playback (optional override)',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton(
                            onPressed: state.isSubmitting
                                ? null
                                : () => notifier.markPlayed(
                                    _playUserController.text,
                                  ),
                            child: const Text('Mark Played'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                if (state.error != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    state.error!,
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: AppTheme.errorRed),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _card(BuildContext context, {required Widget child}) => GlassContainer(
    padding: const EdgeInsets.all(14),
    backgroundColor: Colors.white.withValues(alpha: 0.82),
    blur: 12,
    crystalEffect: true,
    borderRadius: BorderRadius.circular(18),
    shadows: [
      BoxShadow(
        color: AppTheme.trustBlue.withValues(alpha: 0.11),
        blurRadius: 16,
        offset: const Offset(0, 8),
      ),
    ],
    child: child,
  );
}
