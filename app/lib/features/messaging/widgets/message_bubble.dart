import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/glass_widgets.dart';

class MessageBubble extends StatelessWidget {
  const MessageBubble({
    Key? key,
    required this.message,
    required this.isFromCurrentUser,
    required this.timestamp,
    required this.isRead,
  }) : super(key: key);
  final String message;
  final bool isFromCurrentUser;
  final DateTime timestamp;
  final bool isRead;

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final messageDate = DateTime(time.year, time.month, time.day);

    if (messageDate == today) {
      return '${time.hour}:${time.minute.toString().padLeft(2, '0')}';
    } else if (messageDate == yesterday) {
      return 'Yesterday';
    } else {
      return '${time.month}/${time.day}';
    }
  }

  @override
  Widget build(BuildContext context) => Align(
    alignment: isFromCurrentUser ? Alignment.centerRight : Alignment.centerLeft,
    child: Column(
      crossAxisAlignment: isFromCurrentUser
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      children: [
        GlassContainer(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          backgroundColor: isFromCurrentUser
              ? AppTheme.primaryRed.withValues(alpha: 0.9)
              : AppTheme.glassContainer,
          blur: isFromCurrentUser ? 10 : 15,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: isFromCurrentUser
                ? const Radius.circular(16)
                : Radius.zero,
            bottomRight: isFromCurrentUser
                ? Radius.zero
                : const Radius.circular(16),
          ),
          border: Border.all(
            color: isFromCurrentUser
                ? AppTheme.primaryRed.withValues(alpha: 0.5)
                : Colors.white.withValues(alpha: 0.2),
            width: 1,
          ),
          shadows: [
            BoxShadow(
              color: isFromCurrentUser
                  ? AppTheme.primaryRed.withValues(alpha: 0.2)
                  : Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
          child: Text(
            message,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: isFromCurrentUser ? Colors.white : AppTheme.textDark,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _formatTime(timestamp),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.textHint,
                  fontSize: 11,
                ),
              ),
              if (isFromCurrentUser) ...[
                const SizedBox(width: 4),
                Icon(
                  isRead ? Icons.done_all : Icons.done,
                  size: 14,
                  color: isRead ? AppTheme.primaryRed : AppTheme.textHint,
                ),
              ],
            ],
          ),
        ),
      ],
    ),
  );
}
