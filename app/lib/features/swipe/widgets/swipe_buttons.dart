import 'package:flutter/material.dart';
import 'dart:async';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/glass_widgets.dart';

class SwipeButtons extends StatefulWidget {
  const SwipeButtons({
    Key? key,
    required this.onPass,
    required this.onLike,
    required this.onSuperLike,
    required this.onMessage,
    required this.onUndo,
    required this.canUndo,
  }) : super(key: key);
  final Future<void> Function() onPass;
  final Future<void> Function() onLike;
  final Future<void> Function() onSuperLike;
  final Future<void> Function() onMessage;
  final VoidCallback onUndo;
  final bool canUndo;

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
      await controller.forward();
      await controller.reverse();
      await action();
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

  @override
  Widget build(BuildContext context) => GlassContainer(
    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
    backgroundColor: Colors.white.withValues(alpha: 0.62),
    blur: 14,
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        // Undo Button
        ScaleTransition(
          scale: Tween<double>(begin: 1.0, end: 0.85).animate(
            CurvedAnimation(parent: _undoController, curve: Curves.easeInOut),
          ),
          child: GestureDetector(
            onTap: _isBusy ? null : _onUndoPressed,
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(
                  alpha: widget.canUndo ? 0.72 : 0.45,
                ),
                border: Border.all(
                  color: AppTheme.trustBlue.withValues(alpha: 0.18),
                  width: 1.5,
                ),
              ),
              child: Icon(
                Icons.undo,
                color: widget.canUndo
                    ? AppTheme.textDark
                    : AppTheme.textHint.withValues(alpha: 0.8),
                size: 20,
              ),
            ),
          ),
        ),

        // Pass Button
        ScaleTransition(
          scale: Tween<double>(begin: 1.0, end: 0.85).animate(
            CurvedAnimation(parent: _passController, curve: Curves.easeInOut),
          ),
          child: GestureDetector(
            onTap: _isBusy ? null : () => unawaited(_onPassPressed()),
            child: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.78),
                border: Border.all(
                  color: AppTheme.trustBlue.withValues(alpha: 0.24),
                  width: 1.8,
                ),
              ),
              child: const Center(
                child: Icon(Icons.close, color: AppTheme.textDark, size: 28),
              ),
            ),
          ),
        ),

        // Super Like Button (center, larger)
        ScaleTransition(
          scale: Tween<double>(begin: 1.0, end: 0.9).animate(
            CurvedAnimation(parent: _likeController, curve: Curves.easeInOut),
          ),
          child: GestureDetector(
            onTap: _isBusy ? null : () => unawaited(_onLikePressed()),
            child: Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: AppTheme.primaryGradient,
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryRed.withValues(alpha: 0.4),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Center(
                child: Icon(Icons.favorite, color: Colors.white, size: 32),
              ),
            ),
          ),
        ),

        // Super Like Button
        ScaleTransition(
          scale: Tween<double>(begin: 1.0, end: 0.85).animate(
            CurvedAnimation(
              parent: _superLikeController,
              curve: Curves.easeInOut,
            ),
          ),
          child: GestureDetector(
            onTap: _isBusy ? null : () => unawaited(_onSuperLikePressed()),
            child: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.78),
                border: Border.all(
                  color: AppTheme.trustBlue.withValues(alpha: 0.22),
                  width: 1.8,
                ),
              ),
              child: Center(
                child: const Icon(
                  Icons.star,
                  color: AppTheme.warningOrange,
                  size: 28,
                ),
              ),
            ),
          ),
        ),

        // Message Button
        ScaleTransition(
          scale: Tween<double>(begin: 1.0, end: 0.85).animate(
            CurvedAnimation(
              parent: _messageController,
              curve: Curves.easeInOut,
            ),
          ),
          child: GestureDetector(
            onTap: _isBusy ? null : () => unawaited(_onMessagePressed()),
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.72),
                border: Border.all(
                  color: AppTheme.trustBlue.withValues(alpha: 0.18),
                  width: 1.5,
                ),
              ),
              child: const Icon(
                Icons.message,
                color: AppTheme.textDark,
                size: 20,
              ),
            ),
          ),
        ),
      ],
    ),
  );
}
