import 'package:flutter/material.dart';

import '../../../core/widgets/glass_widgets.dart';
import '../../../l10n/app_localizations.dart';
import '../../messaging/screens/chat_screen.dart';

class MatchNotificationScreen extends StatelessWidget {
  const MatchNotificationScreen({
    required this.matchId,
    required this.otherUserId,
    required this.otherUserName,
    required this.otherUserPhotoUrl,
    super.key,
    this.currentUserPhotoUrl,
  });
  final String matchId;
  final String otherUserId;
  final String otherUserName;
  final String otherUserPhotoUrl;
  final String? currentUserPhotoUrl;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.matchesNewMatchTitle)),
      body: PostLoginBackdrop(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Center(
              child: GlassContainer(
                padding: const EdgeInsets.all(20),
                backgroundColor: Theme.of(
                  context,
                ).colorScheme.surface.withValues(alpha: 0.9),
                blur: 12,
                borderRadius: const BorderRadius.all(Radius.circular(28)),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      l10n.matchesItsAMatch,
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _avatar(currentUserPhotoUrl),
                        const SizedBox(width: 12),
                        _avatar(otherUserPhotoUrl),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      l10n.matchesLikedEachOther(otherUserName),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: GlassButton(
                        label: l10n.matchesSendMessage,
                        onPressed: () {
                          Navigator.of(context).pushReplacement(
                            MaterialPageRoute<void>(
                              builder: (_) => ChatScreen(
                                matchId: matchId,
                                otherUserId: otherUserId,
                                userName: otherUserName,
                                userPhotoUrl: otherUserPhotoUrl,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(l10n.matchesKeepSwiping),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _avatar(String? url) => CircleAvatar(
    radius: 34,
    backgroundColor: Colors.grey.shade200,
    backgroundImage: url == null ? null : NetworkImage(url),
    child: url == null ? const Icon(Icons.person, size: 34) : null,
  );
}
