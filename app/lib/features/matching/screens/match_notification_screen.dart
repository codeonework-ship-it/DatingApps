import 'package:flutter/material.dart';

import '../../../core/widgets/glass_widgets.dart';
import '../../messaging/screens/chat_screen.dart';

class MatchNotificationScreen extends StatelessWidget {
  const MatchNotificationScreen({
    required this.matchId, required this.otherUserId, required this.otherUserName, required this.otherUserPhotoUrl, super.key,
    this.currentUserPhotoUrl,
  });
  final String matchId;
  final String otherUserId;
  final String otherUserName;
  final String otherUserPhotoUrl;
  final String? currentUserPhotoUrl;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('New Match')),
    body: PostLoginBackdrop(
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Center(
            child: GlassContainer(
              padding: const EdgeInsets.all(20),
              backgroundColor: Colors.white.withValues(alpha: 0.9),
              blur: 12,
              borderRadius: const BorderRadius.all(Radius.circular(28)),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "It's a match!",
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
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
                    'You and $otherUserName liked each other',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: GlassButton(
                      label: 'Send Message',
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
                    child: const Text('Keep Swiping'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );

  Widget _avatar(String? url) => CircleAvatar(
    radius: 34,
    backgroundColor: Colors.grey.shade200,
    backgroundImage: url == null ? null : NetworkImage(url),
    child: url == null ? const Icon(Icons.person, size: 34) : null,
  );
}
