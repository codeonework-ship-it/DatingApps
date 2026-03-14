import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/glass_widgets.dart';
import '../../auth/providers/auth_provider.dart';
import '../../common/screens/moderation_appeals_screen.dart';
import '../../matching/screens/activity_session_screen.dart';
import '../../matching/providers/gesture_timeline_provider.dart';
import '../providers/message_provider.dart';
import '../widgets/message_bubble.dart';

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({
    super.key,
    required this.matchId,
    required this.otherUserId,
    required this.userName,
    required this.userPhotoUrl,
  });
  final String matchId;
  final String otherUserId;
  final String userName;
  final String userPhotoUrl;

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final messageState = ref.watch(messageNotifierProvider(widget.matchId));
    final messageNotifier = ref.read(
      messageNotifierProvider(widget.matchId).notifier,
    );
    final timelineState = ref.watch(gestureTimelineProvider(widget.matchId));
    final timelineNotifier = ref.read(
      gestureTimelineProvider(widget.matchId).notifier,
    );
    final currentUserId = ref.watch(authNotifierProvider).userId;

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        toolbarHeight: 70,
        leadingWidth: 50,
        leading: Padding(
          padding: const EdgeInsets.only(left: 8),
          child: Align(
            alignment: Alignment.centerLeft,
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: AppTheme.textDark),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.userName,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            Text(
              'Active now',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppTheme.successGreen),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.call, color: AppTheme.primaryRed),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.info, color: AppTheme.primaryRed),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Gesture Timeline',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: AppTheme.textDark,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () => _showGestureComposer(
                        context,
                        timelineNotifier,
                        widget.otherUserId,
                      ),
                      icon: const Icon(Icons.auto_awesome, size: 18),
                      label: const Text('Send Gesture'),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Align(
                  alignment: Alignment.centerRight,
                  child: OutlinedButton.icon(
                    onPressed: () => _openActivitySession(context),
                    icon: const Icon(Icons.timer_outlined, size: 18),
                    label: const Text('2-Min This-or-That'),
                  ),
                ),
                if (timelineState.isLoading)
                  const SizedBox(
                    height: 52,
                    child: Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppTheme.trustBlue,
                        ),
                      ),
                    ),
                  )
                else if (timelineState.items.isEmpty)
                  Text(
                    'No gestures yet. Send a thoughtful opener to start.',
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: AppTheme.textHint),
                  )
                else
                  SizedBox(
                    height: 136,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: timelineState.items.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 10),
                      itemBuilder: (context, index) {
                        final item = timelineState.items[index];
                        final canReview =
                            currentUserId != null &&
                            item.receiverUserId == currentUserId &&
                            item.status == 'sent';
                        return GlassContainer(
                          width: 286,
                          padding: const EdgeInsets.all(12),
                          backgroundColor: Colors.white,
                          blur: 0,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      item.gestureType.replaceAll('_', ' '),
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.copyWith(
                                            color: AppTheme.textDark,
                                            fontWeight: FontWeight.w700,
                                          ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Text(
                                    'Score ${item.effortScore}',
                                    style: Theme.of(context).textTheme.bodySmall
                                        ?.copyWith(color: AppTheme.trustBlue),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                item.contentText,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Status: ${item.status.replaceAll('_', ' ')}',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                              const Spacer(),
                              if (canReview)
                                Wrap(
                                  spacing: 6,
                                  children: [
                                    _decisionChip(
                                      label: 'Appreciate',
                                      color: AppTheme.successGreen,
                                      onTap: () =>
                                          timelineNotifier.decideGesture(
                                            gestureId: item.id,
                                            decision: 'appreciate',
                                          ),
                                    ),
                                    _decisionChip(
                                      label: 'Request Better',
                                      color: AppTheme.warningOrange,
                                      onTap: () =>
                                          timelineNotifier.decideGesture(
                                            gestureId: item.id,
                                            decision: 'request_better',
                                            reason:
                                                'Please add clearer effort.',
                                          ),
                                    ),
                                    _decisionChip(
                                      label: 'Decline',
                                      color: AppTheme.errorRed,
                                      onTap: () =>
                                          timelineNotifier.decideGesture(
                                            gestureId: item.id,
                                            decision: 'decline',
                                            reason: 'Not aligned yet.',
                                          ),
                                    ),
                                  ],
                                )
                              else
                                Text(
                                  item.createdAt.toLocal().toString().substring(
                                    0,
                                    16,
                                  ),
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(color: AppTheme.textHint),
                                ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                if (timelineState.error != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      timelineState.error!,
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: AppTheme.errorRed),
                    ),
                  ),
              ],
            ),
          ),

          // Messages List
          Expanded(
            child: messageState.isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppTheme.primaryRed,
                      ),
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    reverse: true,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    itemCount: messageState.messages.length,
                    itemBuilder: (context, index) {
                      final message = messageState.messages[index];
                      final isCurrentUser =
                          currentUserId != null &&
                          message.senderId == currentUserId;

                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: MessageBubble(
                          message: message.text,
                          isFromCurrentUser: isCurrentUser,
                          timestamp: message.createdAt,
                          isRead: message.readAt != null,
                        ),
                      );
                    },
                  ),
          ),

          // Typing Indicator
          if (messageState.isTyping)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  GlassContainer(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    backgroundColor: Colors.grey[100],
                    blur: 0,
                    child: Row(
                      children: [
                        for (int i = 0; i < 3; i++)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 2),
                            child: ScaleTransition(
                              scale: Tween<double>(begin: 0.8, end: 1).animate(
                                CurvedAnimation(
                                  parent: AlwaysStoppedAnimation<double>(
                                    (i * 0.1) % 1.0,
                                  ),
                                  curve: Curves.easeInOut,
                                ),
                              ),
                              child: Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppTheme.textHint,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'typing...',
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: AppTheme.textHint),
                  ),
                ],
              ),
            ),

          // Input Area
          if (messageState.isChatLocked)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: AppTheme.primaryRed.withValues(alpha: 0.08),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.lock_outline,
                        color: AppTheme.primaryRed,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          messageState.unlockPolicyVariant ==
                                  'allow_without_template'
                              ? 'Chat is temporarily locked. Complete the current unlock step to continue.'
                              : 'Complete and get quest approval to unlock chat.',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: AppTheme.primaryRed,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => _openActivitySession(context),
                      icon: const Icon(Icons.play_circle_outline),
                      label: const Text('Start 2-Min This-or-That'),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: () => _openAppealsFromChatLock(context),
                      icon: const Icon(Icons.gavel_outlined),
                      label: const Text('Appeal this decision'),
                    ),
                  ),
                ],
              ),
            ),
          Container(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 12,
              bottom: MediaQuery.of(context).viewInsets.bottom + 12,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                // Emoji/Attachment Button
                IconButton(
                  icon: const Icon(
                    Icons.add_circle_outline,
                    color: AppTheme.primaryRed,
                  ),
                  onPressed: messageState.isChatLocked ? null : () {},
                ),

                // Text Field
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    enabled: !messageState.isChatLocked,
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: const BorderSide(
                          color: AppTheme.primaryRed,
                          width: 1,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide(
                          color: Colors.grey[300]!,
                          width: 1,
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      suffixIcon: IconButton(
                        icon: const Icon(
                          Icons.emoji_emotions_outlined,
                          color: AppTheme.primaryRed,
                        ),
                        onPressed: () {},
                      ),
                    ),
                    maxLines: null,
                    textCapitalization: TextCapitalization.sentences,
                    onChanged: (value) {
                      messageNotifier.setTyping(value.isNotEmpty);
                    },
                  ),
                ),

                const SizedBox(width: 8),

                // Send Button
                GestureDetector(
                  onTap: () {
                    if (messageState.isChatLocked) {
                      return;
                    }
                    if (_messageController.text.isNotEmpty) {
                      messageNotifier.sendMessage(_messageController.text);
                      _messageController.clear();
                      messageNotifier.setTyping(false);
                    }
                  },
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: AppTheme.primaryGradient,
                    ),
                    child: const Icon(
                      Icons.send,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _decisionChip({
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
  );

  Future<void> _openActivitySession(BuildContext context) async {
    final sharedMessage = await Navigator.of(context).push<String>(
      MaterialPageRoute<String>(
        builder: (_) => ActivitySessionScreen(
          matchId: widget.matchId,
          otherUserId: widget.otherUserId,
          otherUserName: widget.userName,
          enableShareToChat: true,
        ),
      ),
    );
    if (!mounted || sharedMessage == null || sharedMessage.trim().isEmpty) {
      return;
    }
    await ref
        .read(messageNotifierProvider(widget.matchId).notifier)
        .sendMessage(sharedMessage.trim());
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Activity result shared to chat.')),
    );
  }

  void _openAppealsFromChatLock(BuildContext context) {
    final unlockState = ref
        .read(messageNotifierProvider(widget.matchId))
        .unlockState;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ModerationAppealsScreen(
          initialReason:
              'Chat lock review request for match ${widget.matchId} (state: ${unlockState ?? 'unknown'})',
        ),
      ),
    );
  }

  Future<void> _showGestureComposer(
    BuildContext context,
    GestureTimelineNotifier notifier,
    String receiverUserId,
  ) async {
    final controller = TextEditingController();
    var gestureType = 'thoughtful_opener';
    var tone = 'warm';

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 16,
              bottom: MediaQuery.of(context).viewInsets.bottom + 16,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Send Gesture',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: gestureType,
                  decoration: const InputDecoration(labelText: 'Type'),
                  items: const [
                    DropdownMenuItem(
                      value: 'thoughtful_opener',
                      child: Text('Thoughtful Opener'),
                    ),
                    DropdownMenuItem(
                      value: 'micro_card',
                      child: Text('Micro Card'),
                    ),
                    DropdownMenuItem(
                      value: 'challenge_token',
                      child: Text('Challenge Token'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setModalState(() => gestureType = value);
                    }
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: tone,
                  decoration: const InputDecoration(labelText: 'Tone'),
                  items: const [
                    DropdownMenuItem(value: 'warm', child: Text('Warm')),
                    DropdownMenuItem(value: 'neutral', child: Text('Neutral')),
                    DropdownMenuItem(value: 'direct', child: Text('Direct')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setModalState(() => tone = value);
                    }
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: controller,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    hintText: 'Write your effort gesture...',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      final content = controller.text.trim();
                      if (content.isEmpty) {
                        return;
                      }
                      await notifier.createGesture(
                        receiverUserId: receiverUserId,
                        gestureType: gestureType,
                        contentText: content,
                        tone: tone,
                      );
                      if (context.mounted) {
                        Navigator.of(context).pop();
                      }
                    },
                    child: const Text('Send'),
                  ),
                ),
              ],
            ),
          ),
      ),
    );
  }
}
