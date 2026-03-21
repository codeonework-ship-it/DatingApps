import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/glass_widgets.dart';
import '../models/rose_gift.dart';
import 'rose_gift_glyph.dart';

class MessageBubble extends StatelessWidget {
  const MessageBubble({
    required this.message,
    required this.isFromCurrentUser,
    required this.timestamp,
    required this.isDelivered,
    required this.isRead,
    super.key,
  });
  final String message;
  final bool isFromCurrentUser;
  final DateTime timestamp;
  final bool isDelivered;
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
  Widget build(BuildContext context) {
    final resolvedMessage = _resolveMessageContent(message);
    final maxWidthFactor = _maxWidthFactorForType(resolvedMessage.layoutType);

    return Align(
      alignment: isFromCurrentUser
          ? Alignment.centerRight
          : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * maxWidthFactor,
        ),
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
              child: _buildContent(context, resolvedMessage),
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
                    _buildDeliveryIcon(),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  _ResolvedMessageContent _resolveMessageContent(String raw) {
    final gestureMatch = RegExp(r'\[gesture_gift:[^\]]+\]').firstMatch(raw);
    if (gestureMatch != null) {
      final gestureToken = gestureMatch.group(0);
      if (gestureToken != null) {
        final parsedGestureGift = _parseGestureGiftMessage(gestureToken);
        if (parsedGestureGift != null) {
          return _ResolvedMessageContent(
            layoutType: _MessageLayoutType.gestureGift,
            plainText: _stripTokenFromMessage(raw, gestureMatch),
            gestureGift: parsedGestureGift,
          );
        }
      }
    }

    final giftMatch = RegExp(r'\[gift:[^\]]+\]').firstMatch(raw);
    if (giftMatch != null) {
      final giftToken = giftMatch.group(0);
      if (giftToken != null) {
        final parsedGift = _parseGiftMessage(giftToken);
        if (parsedGift != null) {
          return _ResolvedMessageContent(
            layoutType: _MessageLayoutType.gift,
            plainText: _stripTokenFromMessage(raw, giftMatch),
            gift: parsedGift,
          );
        }
      }
    }

    return _ResolvedMessageContent(
      layoutType: _MessageLayoutType.plain,
      plainText: raw,
    );
  }

  String _stripTokenFromMessage(String raw, RegExpMatch tokenMatch) {
    final before = raw.substring(0, tokenMatch.start).trimRight();
    final after = raw.substring(tokenMatch.end).trimLeft();
    if (before.isEmpty) {
      return after;
    }
    if (after.isEmpty) {
      return before;
    }
    return '$before\n$after';
  }

  double _maxWidthFactorForType(_MessageLayoutType type) {
    switch (type) {
      case _MessageLayoutType.gestureGift:
        return 0.82;
      case _MessageLayoutType.gift:
        return 0.76;
      case _MessageLayoutType.plain:
        return 0.68;
    }
  }

  Widget _buildDeliveryIcon() {
    if (isRead) {
      return const Icon(Icons.done_all, size: 14, color: AppTheme.successGreen);
    }
    if (isDelivered) {
      return const Icon(Icons.done_all, size: 14, color: AppTheme.textHint);
    }
    return const Icon(Icons.done, size: 14, color: AppTheme.textHint);
  }

  Widget _buildContent(
    BuildContext context,
    _ResolvedMessageContent resolvedMessage,
  ) {
    final gestureGift = resolvedMessage.gestureGift;
    final gift = resolvedMessage.gift;
    final plainText = resolvedMessage.plainText.trim();
    final textColor = isFromCurrentUser ? Colors.white : AppTheme.textDark;
    if (gestureGift != null) {
      return ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 250),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (plainText.isNotEmpty) ...[
              Text(
                plainText,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: textColor,
                  height: 1.42,
                ),
              ),
              const SizedBox(height: 12),
            ],
            _buildPill(context, label: 'Gesture + Rose Gift', color: textColor),
            const SizedBox(height: 14),
            _buildMessageSection(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: textColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.auto_awesome_rounded,
                          size: 18,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _humanizeGestureType(gestureGift.gestureType),
                              style: Theme.of(context).textTheme.titleSmall
                                  ?.copyWith(
                                    color: textColor,
                                    fontWeight: FontWeight.w800,
                                  ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Tone: ${_titleCase(gestureGift.tone)}',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: textColor.withValues(alpha: 0.82),
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    gestureGift.gestureText,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: textColor,
                      height: 1.45,
                    ),
                  ),
                ],
              ),
              color: textColor,
            ),
            const SizedBox(height: 14),
            _buildMessageSection(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      RoseGiftGlyph(
                        iconKey: gestureGift.giftIcon,
                        giftId: gestureGift.giftId,
                        giftName: gestureGift.giftName,
                        size: 22,
                        iconSize: 14,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          gestureGift.giftName,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: textColor,
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                      ),
                      Text(
                        gestureGift.giftPrice > 0
                            ? '${gestureGift.giftPrice} coins'
                            : 'Free gift',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: textColor.withValues(alpha: 0.86),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildGiftPreview(
                    giftName: gestureGift.giftName,
                    giftUrl: gestureGift.giftUrl,
                    giftId: gestureGift.giftId,
                    giftIcon: gestureGift.giftIcon,
                  ),
                ],
              ),
              color: textColor,
            ),
          ],
        ),
      );
    }

    if (gift == null) {
      return Text(
        plainText,
        style: Theme.of(
          context,
        ).textTheme.bodyMedium?.copyWith(color: textColor),
      );
    }

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 250),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (plainText.isNotEmpty) ...[
            Text(
              plainText,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: textColor,
                height: 1.42,
              ),
            ),
            const SizedBox(height: 12),
          ],
          _buildPill(context, label: 'Rose Gift', color: textColor),
          const SizedBox(height: 12),
          _buildGiftPreview(
            giftName: gift.name,
            giftUrl: gift.url,
            giftId: gift.id,
            giftIcon: gift.iconKey,
          ),
          const SizedBox(height: 10),
          Text(
            gift.name,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: textColor,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            gift.price > 0 ? '${gift.price} coins' : 'Free gift',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: textColor.withValues(alpha: 0.9),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPill(
    BuildContext context, {
    required String label,
    required Color color,
  }) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(999),
    ),
    child: Text(
      label,
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
        color: color,
        fontWeight: FontWeight.w800,
      ),
    ),
  );

  Widget _buildMessageSection({required Widget child, required Color color}) =>
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: color.withValues(alpha: 0.1)),
        ),
        child: child,
      );

  Widget _buildGiftPreview({
    required String giftName,
    required String giftUrl,
    required String? giftId,
    required String? giftIcon,
  }) {
    final resolvedAssetPath = RoseGift.resolveAssetPathById(giftId);
    final resolvedGifUrl = RoseGift.resolvePreferredGifPathById(
      giftId,
      fallbackUrl: giftUrl,
    );

    Widget buildGlyphFallback() => Container(
      width: 220,
      height: 142,
      color: Colors.white.withValues(alpha: 0.3),
      child: Center(
        child: RoseGiftGlyph(
          iconKey: giftIcon,
          giftId: giftId,
          giftName: giftName,
          size: 48,
        ),
      ),
    );

    if (resolvedGifUrl.isEmpty && resolvedAssetPath.isEmpty) {
      return buildGlyphFallback();
    }

    Widget buildNetworkPreview() {
      if (resolvedGifUrl.isEmpty || resolvedGifUrl == resolvedAssetPath) {
        return buildGlyphFallback();
      }
      return Image.network(
        resolvedGifUrl,
        width: 220,
        height: 142,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => buildGlyphFallback(),
      );
    }

    final preview = resolvedAssetPath.isNotEmpty
        ? Image.asset(
            resolvedAssetPath,
            width: 220,
            height: 142,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => buildNetworkPreview(),
          )
        : buildNetworkPreview();

    return ClipRRect(borderRadius: BorderRadius.circular(16), child: preview);
  }

  _GiftPayload? _parseGiftMessage(String raw) {
    if (!raw.startsWith('[gift:') || !raw.endsWith(']')) {
      return null;
    }
    final body = raw.substring(6, raw.length - 1);
    final segments = body.split('|');
    final values = <String, String>{};
    for (final segment in segments) {
      final idx = segment.indexOf('=');
      if (idx <= 0 || idx >= segment.length - 1) {
        continue;
      }
      final key = segment.substring(0, idx).trim();
      final value = segment.substring(idx + 1).trim();
      values[key] = value;
    }

    final name = values['name'];
    if (name == null || name.isEmpty) {
      return null;
    }
    final id = values['id'];
    final url = RoseGift.resolvePreferredGifPathById(
      id,
      fallbackUrl: values['url'],
    );
    final iconKey = values['icon'];
    final price = int.tryParse(values['price'] ?? '0') ?? 0;
    return _GiftPayload(
      id: id,
      iconKey: iconKey,
      name: name,
      url: url,
      price: price,
    );
  }

  _GestureGiftPayload? _parseGestureGiftMessage(String raw) {
    if (!raw.startsWith('[gesture_gift:') || !raw.endsWith(']')) {
      return null;
    }

    final body = raw.substring(14, raw.length - 1);
    final segments = body.split('|');
    final values = <String, String>{};
    for (final segment in segments) {
      final idx = segment.indexOf('=');
      if (idx <= 0 || idx >= segment.length - 1) {
        continue;
      }
      final key = segment.substring(0, idx).trim();
      final value = segment.substring(idx + 1).trim();
      values[key] = value;
    }

    final gestureType = values['gesture_type'];
    final gestureText = values['gesture_text'];
    final tone = values['tone'];
    final giftName = values['gift_name'];
    final giftUrl = values['gift_url'];
    if (gestureType == null ||
        gestureText == null ||
        tone == null ||
        giftName == null ||
        giftUrl == null) {
      return null;
    }

    return _GestureGiftPayload(
      gestureType: gestureType,
      gestureText: gestureText,
      tone: tone,
      giftId: values['gift_id'],
      giftIcon: values['gift_icon'],
      giftName: giftName,
      giftUrl: giftUrl,
      giftPrice: int.tryParse(values['gift_price'] ?? '0') ?? 0,
    );
  }

  String _humanizeGestureType(String raw) =>
      _titleCase(raw.replaceAll('_', ' '));

  String _titleCase(String value) => value
      .split(' ')
      .where((part) => part.isNotEmpty)
      .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
      .join(' ');
}

class _ResolvedMessageContent {
  const _ResolvedMessageContent({
    required this.layoutType,
    required this.plainText,
    this.gift,
    this.gestureGift,
  });

  final _MessageLayoutType layoutType;
  final String plainText;
  final _GiftPayload? gift;
  final _GestureGiftPayload? gestureGift;
}

class _GiftPayload {
  const _GiftPayload({
    required this.id,
    required this.iconKey,
    required this.name,
    required this.url,
    required this.price,
  });

  final String? id;
  final String? iconKey;
  final String name;
  final String url;
  final int price;
}

class _GestureGiftPayload {
  const _GestureGiftPayload({
    required this.gestureType,
    required this.gestureText,
    required this.tone,
    required this.giftId,
    required this.giftIcon,
    required this.giftName,
    required this.giftUrl,
    required this.giftPrice,
  });

  final String gestureType;
  final String gestureText;
  final String tone;
  final String? giftId;
  final String? giftIcon;
  final String giftName;
  final String giftUrl;
  final int giftPrice;
}

enum _MessageLayoutType { plain, gift, gestureGift }
