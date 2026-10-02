import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/platform/browser_context.dart';
import '../../l10n/app_localizations.dart';
import '../engagement/providers/voice_icebreaker_provider.dart';

class WebIcebreakerPage extends ConsumerWidget {
  const WebIcebreakerPage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(voiceIcebreakerProvider);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.webIcebreakerTitle)),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Text(
                l10n.webIcebreakerHeadline,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 12),
              Text(l10n.webIcebreakerBody),
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
                child: Text(l10n.webIcebreakerOpenMatches),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
