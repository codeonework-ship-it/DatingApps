import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/glass_widgets.dart';

class AboutAppScreen extends StatelessWidget {
  const AboutAppScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('About')),
    body: PostLoginBackdrop(
      child: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: AppTheme.contentMaxWidth,
            ),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                GlassContainer(
                  padding: const EdgeInsets.all(20),
                  backgroundColor: Colors.white.withValues(alpha: 0.9),
                  blur: 12,
                  borderRadius: const BorderRadius.all(Radius.circular(20)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Verified Dating',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 8),
                      const Text('Version 1.0.0'),
                      const SizedBox(height: 16),
                      const Text(
                        'Trust-first dating app focused on authentic profiles, '
                        'safe communication, and serious relationships.',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                GlassContainer(
                  padding: const EdgeInsets.all(16),
                  backgroundColor: Colors.white.withValues(alpha: 0.9),
                  blur: 12,
                  borderRadius: const BorderRadius.all(Radius.circular(16)),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Stack'),
                      SizedBox(height: 8),
                      Text('Flutter (Android-first)'),
                      Text('Supabase Auth + Postgres + Storage'),
                      Text('Riverpod state management'),
                    ],
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
