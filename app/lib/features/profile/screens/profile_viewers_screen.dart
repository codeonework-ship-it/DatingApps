import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/widgets/glass_widgets.dart';
import '../../../l10n/app_localizations.dart';
import '../providers/profile_viewers_provider.dart';

class ProfileViewersScreen extends ConsumerWidget {
  const ProfileViewersScreen({super.key});

  /// The visit time in the member's locale; text the app cannot parse is
  /// shown as the server sent it.
  static String _visitTime(BuildContext context, String raw) {
    final parsed = DateTime.tryParse(raw.trim());
    if (parsed == null) {
      return raw;
    }
    final locale = Localizations.localeOf(context).toString();
    return DateFormat.yMMMd(locale).add_jm().format(parsed.toLocal());
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final viewersAsync = ref.watch(profileViewersProvider);
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.profileViewersTitle),
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
      ),
      body: PostLoginBackdrop(
        child: viewersAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) => Center(
            child: GlassContainer(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(l10n.profileViewersLoadFailed),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () => ref.invalidate(profileViewersProvider),
                    child: Text(l10n.commonRetry),
                  ),
                ],
              ),
            ),
          ),
          data: (viewers) {
            if (viewers.isEmpty) {
              return Center(
                child: GlassContainer(
                  padding: const EdgeInsets.all(16),
                  child: Text(l10n.profileViewersEmpty),
                ),
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
              itemCount: viewers.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final item = viewers[index];
                final subtitle = item.viewedAt.trim().isEmpty
                    ? l10n.profileViewersViewedRecently
                    : l10n.profileViewersViewedAt(
                        _visitTime(context, item.viewedAt),
                      );

                return GlassContainer(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: Theme.of(
                          context,
                        ).colorScheme.primaryContainer,
                        backgroundImage: item.photoUrl.isNotEmpty
                            ? NetworkImage(item.photoUrl)
                            : null,
                        child: item.photoUrl.isEmpty
                            ? Icon(
                                Icons.person,
                                color: Theme.of(
                                  context,
                                ).colorScheme.onPrimaryContainer,
                              )
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.name.isEmpty ? item.userId : item.name,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              subtitle,
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
