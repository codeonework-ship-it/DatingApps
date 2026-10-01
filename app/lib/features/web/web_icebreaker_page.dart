import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/platform/browser_context.dart';
import '../engagement/providers/voice_icebreaker_provider.dart';

class WebIcebreakerPage extends ConsumerWidget {
  const WebIcebreakerPage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(voiceIcebreakerProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Conversation starters')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Text(
                'A little inspiration for your next hello.',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 12),
              const Text(
                'Voice recording and playback are not available yet. You can use these prompts in an eligible conversation.',
              ),
              const SizedBox(height: 24),
              if (state.isLoading) const LinearProgressIndicator(),
              if (state.error != null) Text(state.error!),
              for (final prompt in state.prompts)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(prompt.promptText),
                  ),
                ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () => setWebRoute('/matches'),
                child: const Text('Open my matches'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
