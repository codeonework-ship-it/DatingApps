import 'package:flutter/material.dart';

import '../i18n/app_l10n.dart';
import '../theme/app_theme.dart';
import 'glass_widgets.dart';

/// Shared screen scaffold that enforces Crystal Gold theme usage,
/// loading/error/empty states, and consistent layout across all screens.
///
/// Wraps every post-login screen with [PostLoginBackdrop] and provides
/// standard handlers for async data states. Pre-login screens use [bgGradient].
class ThemedScreenScaffold extends StatelessWidget {
  const ThemedScreenScaffold({
    required this.body,
    super.key,
    this.appBar,
    this.isPreLogin = false,
    this.isLoading = false,
    this.loadingMessage,
    this.errorMessage,
    this.onRetry,
    this.isEmpty = false,
    this.emptyIcon,
    this.emptyTitle,
    this.emptySubtitle,
    this.floatingActionButton,
    this.bottomNavigationBar,
    this.resizeToAvoidBottomInset = true,
    this.extendBody = false,
    this.padding,
    this.maxContentWidth = AppTheme.contentMaxWidth,
  });

  /// Main content widget. Shown only when not loading, no error, and not empty.
  final Widget body;

  /// Optional app bar.
  final PreferredSizeWidget? appBar;

  /// When true, paints the theme's flat ground without the post-login
  /// layout constraints. Otherwise uses [PostLoginBackdrop].
  final bool isPreLogin;

  /// When true, shows a centered loading indicator.
  final bool isLoading;

  /// Optional message shown below the loading indicator.
  final String? loadingMessage;

  /// When non-null, shows an error state with retry button.
  final String? errorMessage;

  /// Callback for the retry button in error state.
  final VoidCallback? onRetry;

  /// When true and no error/loading, shows the empty state.
  final bool isEmpty;

  /// Icon for the empty state.
  final IconData? emptyIcon;

  /// Title for the empty state.
  final String? emptyTitle;

  /// Subtitle for the empty state.
  final String? emptySubtitle;

  final Widget? floatingActionButton;
  final Widget? bottomNavigationBar;
  final bool resizeToAvoidBottomInset;
  final bool extendBody;
  final EdgeInsetsGeometry? padding;
  final double? maxContentWidth;

  @override
  Widget build(BuildContext context) {
    Widget content;

    if (isLoading) {
      content = _LoadingState(message: loadingMessage);
    } else if (errorMessage != null) {
      content = _ErrorState(message: errorMessage!, onRetry: onRetry);
    } else if (isEmpty) {
      content = _EmptyState(
        icon: emptyIcon ?? Icons.inbox_rounded,
        title: emptyTitle ?? l10nOrEnglish(context).commonNothingHereYet,
        subtitle: emptySubtitle,
      );
    } else {
      content = body;
    }

    final Widget backdrop;
    if (isPreLogin) {
      backdrop = Container(
        decoration: BoxDecoration(gradient: AppTheme.groundGradientOf(context)),
        child: content,
      );
    } else {
      backdrop = PostLoginBackdrop(
        padding: padding,
        maxContentWidth: maxContentWidth,
        child: content,
      );
    }

    return Scaffold(
      appBar: appBar,
      body: backdrop,
      floatingActionButton: floatingActionButton,
      bottomNavigationBar: bottomNavigationBar,
      resizeToAvoidBottomInset: resizeToAvoidBottomInset,
      extendBody: extendBody,
    );
  }
}

class _LoadingState extends StatelessWidget {
  const _LoadingState({this.message});
  final String? message;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 40,
            height: 40,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation<Color>(
                Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
          if (message != null) ...[
            const SizedBox(height: 16),
            Text(
              message!,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    ),
  );
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, this.onRetry});
  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: GlassContainer(
        padding: const EdgeInsets.all(24),
        backgroundColor: Theme.of(context).colorScheme.surface,
        blur: 14,
        crystalEffect: true,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline_rounded,
              color: Theme.of(context).colorScheme.error,
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              l10nOrEnglish(context).commonSomethingWentWrong,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 20),
              GlassButton(
                label: l10nOrEnglish(context).commonTryAgainTitle,
                onPressed: onRetry!,
              ),
            ],
          ],
        ),
      ),
    ),
  );
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.icon, required this.title, this.subtitle});
  final IconData icon;
  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            size: 64,
          ),
          const SizedBox(height: 16),
          Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Theme.of(context).colorScheme.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 8),
            Text(
              subtitle!,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    ),
  );
}
