import 'package:flutter/material.dart';
import 'dart:async';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/glass_widgets.dart';

class SwipeButtons extends StatefulWidget {
  const SwipeButtons({
    super.key,
    required this.onPass,
    required this.onLike,
    required this.onSuperLike,
    required this.onMessage,
    required this.onUndo,
    required this.canUndo,
    this.isSpotlightContext = false,
  });
  final Future<void> Function() onPass;
  final Future<void> Function() onLike;
  final Future<void> Function() onSuperLike;
  final Future<void> Function() onMessage;
  final VoidCallback onUndo;
  final bool canUndo;
  final bool isSpotlightContext;

  @override
  State<SwipeButtons> createState() => _SwipeButtonsState();
}

class _SwipeButtonsState extends State<SwipeButtons>
    with TickerProviderStateMixin {
  late AnimationController _passController;
  late AnimationController _likeController;
  late AnimationController _superLikeController;
  late AnimationController _messageController;
  late AnimationController _undoController;
  bool _isBusy = false;
  bool _isLikeHovered = false;

  @override
  void initState() {
    super.initState();
    _passController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _likeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _superLikeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _messageController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _undoController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _passController.dispose();
    _likeController.dispose();
    _superLikeController.dispose();
    _messageController.dispose();
    _undoController.dispose();
    super.dispose();
  }

  Future<void> _runAction(
    AnimationController controller,
    Future<void> Function() action,
  ) async {
    if (_isBusy) return;
    setState(() => _isBusy = true);
    try {
      await action();
      if (!mounted) return;
      await controller.forward(from: 0);
      await controller.reverse();
    } finally {
      if (mounted) {
        setState(() => _isBusy = false);
      }
    }
  }

  Future<void> _onPassPressed() async {
    await _runAction(_passController, widget.onPass);
  }

  Future<void> _onLikePressed() async {
    await _runAction(_likeController, widget.onLike);
  }

  Future<void> _onSuperLikePressed() async {
    await _runAction(_superLikeController, widget.onSuperLike);
  }

  Future<void> _onMessagePressed() async {
    await _runAction(_messageController, widget.onMessage);
  }

  void _onUndoPressed() {
    if (widget.canUndo) {
      _undoController.forward().then((_) {
        _undoController.reverse();
        widget.onUndo();
      });
    }
  }

  /// Automation handle for [control]: the full Spotlight screen has its own
  /// `qa.spotlight.*` handles so it never shares ids with the Discover deck
  /// underneath it.
  String _qa(String control) =>
      '${widget.isSpotlightContext ? 'qa.spotlight' : 'qa.discovery'}.$control';

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return GlassContainer(
      // The action targets are deliberately fixed at 56-60pt for thumb reach,
      // so the container padding is what gives on a narrow phone rather than
      // the buttons shrinking below a comfortable tap size.
      padding: EdgeInsets.symmetric(
        vertical: 12,
        horizontal: MediaQuery.sizeOf(context).width < 400 ? 4 : 16,
      ),
      backgroundColor: scheme.surface.withValues(alpha: 0.62),
      blur: 14,
      // Five fixed targets — 56 + 60 + 72 + 60 + 56 = 304pt — cannot fit a
      // 320pt phone once gutters and container padding are taken, at any
      // padding. Scaling the whole bar keeps the proportions and the spacing
      // rhythm, and at its worst (320pt) the factor is ~0.96, so every target
      // stays far above the 48pt minimum. Shrinking individual buttons instead
      // would put the smallest ones under that floor.
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            // Undo Button
            ScaleTransition(
              scale: Tween<double>(begin: 1, end: 0.85).animate(
                CurvedAnimation(
                  parent: _undoController,
                  curve: Curves.easeInOut,
                ),
              ),
              child: Semantics(
                label: _qa('undo_button'),
                button: true,
                enabled: widget.canUndo && !_isBusy,
                child: GestureDetector(
                  key: ValueKey(_qa('undo_button')),
                  onTap: _isBusy ? null : _onUndoPressed,
                  child: Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: scheme.surface.withValues(
                        alpha: widget.canUndo ? 0.72 : 0.45,
                      ),
                      border: Border.all(
                        color: scheme.outlineVariant,
                        width: 1.5,
                      ),
                    ),
                    child: Icon(
                      Icons.undo,
                      color: widget.canUndo
                          ? scheme.onSurface
                          : scheme.onSurfaceVariant.withValues(alpha: 0.8),
                      size: 20,
                    ),
                  ),
                ),
              ),
            ),

            // Pass Button
            ScaleTransition(
              scale: Tween<double>(begin: 1, end: 0.85).animate(
                CurvedAnimation(
                  parent: _passController,
                  curve: Curves.easeInOut,
                ),
              ),
              child: Semantics(
                label: _qa('pass_button'),
                button: true,
                enabled: !_isBusy,
                child: GestureDetector(
                  key: ValueKey(_qa('pass_button')),
                  onTap: _isBusy ? null : () => unawaited(_onPassPressed()),
                  child: Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: scheme.surface.withValues(alpha: 0.78),
                      border: Border.all(
                        color: scheme.outlineVariant,
                        width: 1.8,
                      ),
                    ),
                    child: Center(
                      child: Icon(
                        Icons.close,
                        color: scheme.onSurface,
                        size: 28,
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Like Button (center, larger)
            ScaleTransition(
              scale: Tween<double>(begin: 1, end: 0.9).animate(
                CurvedAnimation(
                  parent: _likeController,
                  curve: Curves.easeInOut,
                ),
              ),
              child: MouseRegion(
                onEnter: (_) => setState(() => _isLikeHovered = true),
                onExit: (_) => setState(() => _isLikeHovered = false),
                child: Semantics(
                  label: _qa('like_button'),
                  button: true,
                  enabled: !_isBusy,
                  child: GestureDetector(
                    key: ValueKey(_qa('like_button')),
                    onTap: _isBusy ? null : () => unawaited(_onLikePressed()),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 220),
                      curve: Curves.easeOutCubic,
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _isLikeHovered
                            ? Color.lerp(scheme.primary, scheme.onPrimary, 0.12)
                            : scheme.primary,
                        border: widget.isSpotlightContext
                            ? Border.all(
                                color: Colors.white.withValues(alpha: 0.78),
                                width: 1.1,
                              )
                            : null,
                        boxShadow: [
                          if (widget.isSpotlightContext)
                            BoxShadow(
                              color: Colors.white.withValues(
                                alpha: _isLikeHovered ? 0.24 : 0.16,
                              ),
                              blurRadius: _isLikeHovered ? 30 : 24,
                              spreadRadius: _isLikeHovered ? 2 : 1,
                              offset: const Offset(0, 6),
                            ),
                        ],
                      ),
                      child: Center(
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            if (widget.isSpotlightContext)
                              Container(
                                width: 60,
                                height: 60,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: RadialGradient(
                                    colors: [
                                      Colors.white.withValues(alpha: 0.22),
                                      Colors.transparent,
                                    ],
                                    stops: const [0.0, 0.78],
                                  ),
                                ),
                              ),
                            if (widget.isSpotlightContext)
                              Icon(
                                Icons.favorite,
                                color: Colors.white.withValues(alpha: 0.3),
                                size: 54,
                              ),
                            Icon(
                              Icons.favorite,
                              color: scheme.onPrimary,
                              size: 47,
                            ),
                            if (widget.isSpotlightContext)
                              Positioned(
                                top: 16,
                                right: 18,
                                child: Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.92),
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.white.withValues(
                                          alpha: 0.74,
                                        ),
                                        blurRadius: 8,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Super Like Button
            ScaleTransition(
              scale: Tween<double>(begin: 1, end: 0.85).animate(
                CurvedAnimation(
                  parent: _superLikeController,
                  curve: Curves.easeInOut,
                ),
              ),
              child: Semantics(
                label: _qa('superlike_button'),
                button: true,
                enabled: !_isBusy,
                child: GestureDetector(
                  key: ValueKey(_qa('superlike_button')),
                  onTap: _isBusy
                      ? null
                      : () => unawaited(_onSuperLikePressed()),
                  child: Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: scheme.surface.withValues(alpha: 0.78),
                      border: Border.all(
                        color: scheme.outlineVariant,
                        width: 1.8,
                      ),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.star,
                        color: AppTheme.warningOrange,
                        size: 28,
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Message Button
            ScaleTransition(
              scale: Tween<double>(begin: 1, end: 0.85).animate(
                CurvedAnimation(
                  parent: _messageController,
                  curve: Curves.easeInOut,
                ),
              ),
              child: Semantics(
                label: _qa('message_button'),
                button: true,
                enabled: !_isBusy,
                child: GestureDetector(
                  key: ValueKey(_qa('message_button')),
                  onTap: _isBusy ? null : () => unawaited(_onMessagePressed()),
                  child: Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: scheme.surface.withValues(alpha: 0.72),
                      border: Border.all(
                        color: scheme.outlineVariant,
                        width: 1.5,
                      ),
                    ),
                    child: Icon(
                      Icons.message,
                      color: scheme.onSurface,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
