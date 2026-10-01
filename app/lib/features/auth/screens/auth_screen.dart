import '../../../core/platform/browser_context.dart';
import 'package:flutter/foundation.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/feature_flags.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/glass_widgets.dart';
import '../../../core/widgets/connect_brand.dart';
import '../../../l10n/app_localizations.dart';
import '../../common/screens/main_navigation_screen.dart';
import '../providers/auth_provider.dart';
import 'account_recovery_screen.dart';
import 'welcome_screen.dart';

/// Username and password sign-in.
class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen>
    with SingleTickerProviderStateMixin {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _usernameFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();

  late final AnimationController _fadeController;
  late final Animation<double> _fadeAnimation;
  bool _obscurePassword = true;
  bool _hasCredentials = false;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOutCubic,
    );
    _fadeController.forward();
    _usernameController.addListener(_updateCredentialState);
    _passwordController.addListener(_updateCredentialState);
  }

  void _updateCredentialState() {
    final next =
        _usernameController.text.trim().isNotEmpty &&
        _passwordController.text.isNotEmpty;
    if (next != _hasCredentials && mounted) {
      setState(() => _hasCredentials = next);
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _usernameController
      ..removeListener(_updateCredentialState)
      ..dispose();
    _passwordController
      ..removeListener(_updateCredentialState)
      ..dispose();
    _usernameFocusNode.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  Future<void> _signIn(AuthNotifier notifier) async {
    final username = _usernameController.text.trim();
    final password = _passwordController.text;
    final l10n = AppLocalizations.of(context);
    if (username.isEmpty) {
      _showMessage(l10n.authEnterUsername);
      _usernameFocusNode.requestFocus();
      return;
    }
    if (password.isEmpty) {
      _showMessage(l10n.authEnterPassword);
      _passwordFocusNode.requestFocus();
      return;
    }

    await notifier.signIn(username: username, password: password);
    if (!mounted) {
      return;
    }
    if (ref.read(authNotifierProvider).isAuthenticated) {
      TextInput.finishAutofillContext();
      FocusManager.instance.primaryFocus?.unfocus();
      _leaveAuthenticatedScreen();
    }
  }

  void _leaveAuthenticatedScreen() {
    if (kIsWeb) {
      Navigator.of(context).popUntil((route) => route.isFirst);
      return; // The root auth gate owns browser transitions.
    }
    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.pop();
      return;
    }
    navigator.pushReplacement(
      MaterialPageRoute<void>(builder: (_) => const MainNavigationScreen()),
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  void _goBack(AuthNotifier notifier) {
    notifier.resetAuthFlow();
    final navigator = Navigator.of(context);
    if (kIsWeb) {
      navigator.popUntil((route) => route.isFirst);
      setWebRoute('/welcome');
      return;
    }
    if (navigator.canPop()) {
      navigator.pop();
    } else {
      navigator.pushReplacement(
        MaterialPageRoute<void>(builder: (_) => const WelcomeScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final authNotifier = ref.read(authNotifierProvider.notifier);
    final l10n = AppLocalizations.of(context);

    ref.listen<AuthState>(authNotifierProvider, (previous, next) {
      if (!(previous?.isAuthenticated ?? false) && next.isAuthenticated) {
        FocusManager.instance.primaryFocus?.unfocus();
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _leaveAuthenticatedScreen();
          }
        });
      }
    });

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: Theme.of(context).brightness == Brightness.dark
          ? SystemUiOverlayStyle.light
          : SystemUiOverlayStyle.dark,
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: DecoratedBox(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
          ),
          child: SafeArea(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final compact = constraints.maxHeight < 720;
                  final horizontalPadding = constraints.maxWidth >= 700
                      ? 32.0
                      : 24.0;
                  return Column(
                    children: [
                      Expanded(
                        child: SingleChildScrollView(
                          keyboardDismissBehavior:
                              ScrollViewKeyboardDismissBehavior.onDrag,
                          padding: EdgeInsets.fromLTRB(
                            horizontalPadding,
                            compact ? 12 : 24,
                            horizontalPadding,
                            16,
                          ),
                          child: Center(
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(
                                maxWidth: AppTheme.contentMaxWidth,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Align(
                                    alignment: Alignment.centerLeft,
                                    child: GoldBackButton(
                                      tooltip: l10n.authBackTooltip,
                                      onTap: () => _goBack(authNotifier),
                                    ),
                                  ),
                                  SizedBox(height: compact ? 4 : 12),
                                  const _AuthHeader(),
                                  SizedBox(height: compact ? 18 : 30),
                                  _AuthPane(
                                    child: _CredentialForm(
                                      authState: authState,
                                      usernameController: _usernameController,
                                      passwordController: _passwordController,
                                      usernameFocusNode: _usernameFocusNode,
                                      passwordFocusNode: _passwordFocusNode,
                                      obscurePassword: _obscurePassword,
                                      onTogglePassword: () => setState(
                                        () => _obscurePassword =
                                            !_obscurePassword,
                                      ),
                                      onSubmit: () => _signIn(authNotifier),
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  const _PrivacyNote(),
                                  const SizedBox(height: 8),
                                  Center(
                                    child: TextButton(
                                      key: const ValueKey(
                                        'qa.signin.cant_sign_in',
                                      ),
                                      onPressed: () =>
                                          Navigator.of(context).push(
                                            MaterialPageRoute<void>(
                                              builder: (_) =>
                                                  AccountRecoveryScreen(
                                                    initialUsername:
                                                        _usernameController
                                                            .text,
                                                  ),
                                            ),
                                          ),
                                      child: Text(l10n.authCantSignIn),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      _LoginAction(
                        isLoading: authState.isLoading,
                        enabled: _hasCredentials,
                        onPressed: () => _signIn(authNotifier),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AuthHeader extends StatelessWidget {
  const _AuthHeader();

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      const ConnectBrand(),
      const SizedBox(height: 40),
      Text(
        AppLocalizations.of(context).authHeadline,
        style: Theme.of(context).textTheme.displaySmall!.copyWith(
          color: Theme.of(context).colorScheme.onSurface,
          fontSize: 34,
          fontWeight: FontWeight.w700,
          letterSpacing: -1.2,
        ),
      ),
      const SizedBox(height: 8),
      Text(
        AppLocalizations.of(context).authSubtitle,
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    ],
  );
}

class _AuthPane extends StatelessWidget {
  const _AuthPane({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
    ),
    child: child,
  );
}

class _CredentialForm extends StatelessWidget {
  const _CredentialForm({
    required this.authState,
    required this.usernameController,
    required this.passwordController,
    required this.usernameFocusNode,
    required this.passwordFocusNode,
    required this.obscurePassword,
    required this.onTogglePassword,
    required this.onSubmit,
  });

  final AuthState authState;
  final TextEditingController usernameController;
  final TextEditingController passwordController;
  final FocusNode usernameFocusNode;
  final FocusNode passwordFocusNode;
  final bool obscurePassword;
  final VoidCallback onTogglePassword;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AutofillGroup(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.authWelcomeBack,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: Theme.of(context).colorScheme.onSurface,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            l10n.authNextHello,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          if (kUseMockAuth) ...[
            const SizedBox(height: 14),
            const _InfoBanner(
              message: 'Mock auth is active. Use any username and password.',
            ),
          ],
          const SizedBox(height: 20),
          _GlassTextField(
            fieldKey: const ValueKey('qa.signin.username_field'),
            semanticLabel: 'qa.signin.username_field',
            controller: usernameController,
            focusNode: usernameFocusNode,
            autofocus: false,
            enabled: !authState.isLoading,
            keyboardType: TextInputType.text,
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.username],
            onSubmitted: (_) => passwordFocusNode.requestFocus(),
            hint: l10n.authUsernameHint,
            prefixIcon: Icons.person_outline_rounded,
          ),
          const SizedBox(height: 14),
          _GlassTextField(
            fieldKey: const ValueKey('qa.signin.password_field'),
            semanticLabel: 'qa.signin.password_field',
            controller: passwordController,
            focusNode: passwordFocusNode,
            enabled: !authState.isLoading,
            obscureText: obscurePassword,
            textInputAction: TextInputAction.done,
            autofillHints: const [AutofillHints.password],
            onSubmitted: (_) => onSubmit(),
            hint: l10n.authPasswordHint,
            prefixIcon: Icons.password_rounded,
            suffixIcon: IconButton(
              tooltip: obscurePassword
                  ? l10n.authShowPassword
                  : l10n.authHidePassword,
              onPressed: onTogglePassword,
              icon: Icon(
                obscurePassword
                    ? Icons.visibility_rounded
                    : Icons.visibility_off_rounded,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          if (authState.error != null) ...[
            const SizedBox(height: 14),
            _ErrorBanner(message: authState.error!),
          ],
        ],
      ),
    );
  }
}

class _GlassTextField extends StatelessWidget {
  const _GlassTextField({
    required this.controller,
    required this.hint,
    required this.prefixIcon,
    required this.fieldKey,
    required this.semanticLabel,
    this.focusNode,
    this.autofocus = false,
    this.enabled = true,
    this.obscureText = false,
    this.keyboardType,
    this.textInputAction,
    this.autofillHints,
    this.onSubmitted,
    this.suffixIcon,
  });

  final TextEditingController controller;
  final Key fieldKey;
  final String semanticLabel;
  final FocusNode? focusNode;
  final bool autofocus;
  final bool enabled;
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final Iterable<String>? autofillHints;
  final ValueChanged<String>? onSubmitted;
  final String hint;
  final IconData prefixIcon;
  final Widget? suffixIcon;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      label: semanticLabel,
      textField: true,
      child: TextField(
        key: fieldKey,
        controller: controller,
        focusNode: focusNode,
        autofocus: autofocus,
        enabled: enabled,
        obscureText: obscureText,
        keyboardType: keyboardType,
        textInputAction: textInputAction,
        autofillHints: autofillHints,
        onSubmitted: onSubmitted,
        onTapOutside: (_) => FocusManager.instance.primaryFocus?.unfocus(),
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
          color: scheme.onSurface,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: scheme.onSurfaceVariant),
          prefixIcon: Icon(prefixIcon, color: scheme.primary, size: 20),
          suffixIcon: suffixIcon,
          filled: true,
          fillColor: scheme.surface,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: scheme.outlineVariant),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: scheme.outlineVariant),
          ),
          disabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: scheme.outlineVariant),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: scheme.primary, width: 1.6),
          ),
        ),
      ),
    );
  }
}

class _LoginAction extends StatelessWidget {
  const _LoginAction({
    required this.isLoading,
    required this.enabled,
    required this.onPressed,
  });

  final bool isLoading;
  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => SafeArea(
    top: false,
    child: Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: AppTheme.contentMaxWidth),
          child: SizedBox(
            width: double.infinity,
            height: 56,
            child: Semantics(
              label: 'qa.signin.login_button',
              button: true,
              child: GlassButton(
                key: const ValueKey('qa.signin.login_button'),
                label: AppLocalizations.of(context).authSignIn,
                icon: Icons.arrow_forward_rounded,
                isLoading: isLoading,
                onPressed: enabled && !isLoading ? onPressed : null,
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

class _PrivacyNote extends StatelessWidget {
  const _PrivacyNote();

  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Icon(
        Icons.lock_outline_rounded,
        size: 13,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
      const SizedBox(width: 5),
      Flexible(
        child: Text(
          AppLocalizations.of(context).authPrivacyNote,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    ],
  );
}

class _InfoBanner extends StatelessWidget {
  const _InfoBanner({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) => _Banner(
    icon: Icons.science_rounded,
    message: message,
    color: Theme.of(context).colorScheme.primary,
  );
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) => _Banner(
    icon: Icons.error_outline_rounded,
    message: message,
    color: Theme.of(context).colorScheme.error,
  );
}

class _Banner extends StatelessWidget {
  const _Banner({
    required this.icon,
    required this.message,
    required this.color,
  });

  final IconData icon;
  final String message;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.10),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: color.withValues(alpha: 0.32)),
    ),
    child: Row(
      children: [
        Icon(icon, size: 15, color: color),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            message,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    ),
  );
}
