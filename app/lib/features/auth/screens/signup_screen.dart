import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/feature_flags.dart';
import '../../../core/platform/browser_context.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/glass_widgets.dart';
import '../providers/auth_provider.dart';
import 'auth_screen.dart';

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key, this.introducer = false});
  final bool introducer;

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _nameController = TextEditingController();
  final _usernameFocus = FocusNode();
  final _passwordFocus = FocusNode();
  final _confirmPasswordFocus = FocusNode();
  final _nameFocus = FocusNode();

  DateTime? _dateOfBirth;
  String? _gender;
  bool _obscurePassword = true;
  bool _obscureConfirmation = true;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _nameController.dispose();
    _usernameFocus.dispose();
    _passwordFocus.dispose();
    _confirmPasswordFocus.dispose();
    _nameFocus.dispose();
    super.dispose();
  }

  Future<void> _createAccount(AuthNotifier notifier) async {
    final username = _usernameController.text.trim();
    final password = _passwordController.text;
    final confirmation = _confirmPasswordController.text;
    final name = _nameController.text.trim();
    final dob = _dateOfBirth;

    if (!RegExp(
      r'^[A-Za-z0-9][A-Za-z0-9._]{1,28}[A-Za-z0-9]$',
    ).hasMatch(username)) {
      _snack('Username must be 3–30 characters using letters, numbers, _ or .');
      _usernameFocus.requestFocus();
      return;
    }
    final passwordBytes = utf8.encode(password).length;
    if (passwordBytes < 8 ||
        passwordBytes > 72 ||
        !RegExp('[A-Za-z]').hasMatch(password) ||
        !RegExp('[0-9]').hasMatch(password)) {
      _snack('Password must be 8–72 bytes with letters and numbers.');
      _passwordFocus.requestFocus();
      return;
    }
    if (password != confirmation) {
      _snack('Passwords do not match.');
      _confirmPasswordFocus.requestFocus();
      return;
    }
    if (name.length < 2) {
      _snack('Please enter your full name.');
      _nameFocus.requestFocus();
      return;
    }
    if (dob == null) {
      _snack('Please select your date of birth.');
      return;
    }
    if (_ageInYears(dob) < 18) {
      _snack('You must be at least 18 years old.');
      return;
    }
    if (_ageInYears(dob) > 80) {
      _snack('Connect currently supports members aged 18–80.');
      return;
    }
    final gender = _gender;
    if (!widget.introducer && gender == null) {
      _snack('Please choose how you identify.');
      return;
    }

    await notifier.signUp(
      signup: SignupDraft(
        username: username,
        name: name,
        dateOfBirth: _formatDate(dob),
        gender: gender ?? '',
        accountKind: widget.introducer ? 'introducer' : 'dating',
      ),
      password: password,
    );
    if (mounted && ref.read(authNotifierProvider).isAuthenticated) {
      TextInput.finishAutofillContext();
      FocusManager.instance.primaryFocus?.unfocus();
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  Future<void> _pickDateOfBirth() async {
    final now = DateTime.now();
    final selected = await showDatePicker(
      context: context,
      initialDate: _dateOfBirth ?? DateTime(now.year - 25),
      firstDate: DateTime(now.year - 80),
      lastDate: DateTime(now.year - 18, now.month, now.day),
      helpText: 'Select date of birth',
    );
    if (selected != null && mounted) {
      setState(() => _dateOfBirth = selected);
    }
  }

  void _snack(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final notifier = ref.read(authNotifierProvider.notifier);

    ref.listen<AuthState>(authNotifierProvider, (previous, next) {
      if (!(previous?.isAuthenticated ?? false) && next.isAuthenticated) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            Navigator.of(context).popUntil((route) => route.isFirst);
          }
        });
      }
    });

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: DecoratedBox(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
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
                        tooltip: 'Back',
                        onTap: () {
                          notifier.resetAuthFlow();
                          if (kIsWeb) {
                            Navigator.of(
                              context,
                            ).popUntil((route) => route.isFirst);
                            setWebRoute('/welcome');
                          } else {
                            Navigator.of(context).maybePop();
                          }
                        },
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (widget.introducer) ...[
                      Text(
                        'Be the friend who brings people together.',
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'A friend-only account. No dating profile, photos or swiping. Your age stays private; Connect is for adults 18–80.',
                      ),
                    ] else
                      const _SignupHeader(),
                    const SizedBox(height: 24),
                    _SignupPane(
                      child: AutofillGroup(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (kUseMockAuth) ...[
                              const _InfoBanner(
                                message:
                                    'Mock auth is active for local '
                                    'development.',
                              ),
                              const SizedBox(height: 16),
                            ],
                            const _FieldLabel('Unique username'),
                            const SizedBox(height: 8),
                            _SignupTextField(
                              fieldKey: const ValueKey(
                                'qa.signup.username_field',
                              ),
                              semanticLabel: 'qa.signup.username_field',
                              controller: _usernameController,
                              focusNode: _usernameFocus,
                              enabled: !authState.isLoading,
                              autofocus: true,
                              textInputAction: TextInputAction.next,
                              autofillHints: const [AutofillHints.newUsername],
                              hint: 'your_username',
                              icon: Icons.person_outline_rounded,
                              onSubmitted: (_) => _passwordFocus.requestFocus(),
                            ),
                            const SizedBox(height: 6),
                            const _FieldHelp(
                              '3–30 characters. Letters, numbers, underscore '
                              'and dot.',
                            ),
                            const SizedBox(height: 18),
                            const _FieldLabel('Password'),
                            const SizedBox(height: 8),
                            _SignupTextField(
                              fieldKey: const ValueKey(
                                'qa.signup.password_field',
                              ),
                              semanticLabel: 'qa.signup.password_field',
                              controller: _passwordController,
                              focusNode: _passwordFocus,
                              enabled: !authState.isLoading,
                              obscureText: _obscurePassword,
                              textInputAction: TextInputAction.next,
                              autofillHints: kEnableQaAutomation
                                  ? null
                                  : const [AutofillHints.newPassword],
                              hint: 'At least 8 characters',
                              icon: Icons.password_rounded,
                              suffixIcon: _VisibilityButton(
                                obscure: _obscurePassword,
                                onPressed: () => setState(
                                  () => _obscurePassword = !_obscurePassword,
                                ),
                              ),
                              onSubmitted: (_) =>
                                  _confirmPasswordFocus.requestFocus(),
                            ),
                            const SizedBox(height: 14),
                            _SignupTextField(
                              fieldKey: const ValueKey(
                                'qa.signup.confirm_password_field',
                              ),
                              semanticLabel: 'qa.signup.confirm_password_field',
                              controller: _confirmPasswordController,
                              focusNode: _confirmPasswordFocus,
                              enabled: !authState.isLoading,
                              obscureText: _obscureConfirmation,
                              textInputAction: TextInputAction.next,
                              hint: 'Confirm password',
                              icon: Icons.lock_outline_rounded,
                              suffixIcon: _VisibilityButton(
                                obscure: _obscureConfirmation,
                                onPressed: () => setState(
                                  () => _obscureConfirmation =
                                      !_obscureConfirmation,
                                ),
                              ),
                              onSubmitted: (_) => _nameFocus.requestFocus(),
                            ),
                            const SizedBox(height: 18),
                            const _FieldLabel('Full name'),
                            const SizedBox(height: 8),
                            _SignupTextField(
                              fieldKey: const ValueKey('qa.signup.name_field'),
                              semanticLabel: 'qa.signup.name_field',
                              controller: _nameController,
                              focusNode: _nameFocus,
                              enabled: !authState.isLoading,
                              textCapitalization: TextCapitalization.words,
                              textInputAction: TextInputAction.done,
                              hint: 'Your name',
                              icon: Icons.badge_outlined,
                            ),
                            const SizedBox(height: 18),
                            const _FieldLabel('Date of birth'),
                            const SizedBox(height: 8),
                            _DateOfBirthField(
                              value: _dateOfBirth,
                              enabled: !authState.isLoading,
                              onTap: _pickDateOfBirth,
                            ),
                            const SizedBox(height: 18),
                            if (!widget.introducer) ...[
                              const _FieldLabel('I identify as'),
                              const SizedBox(height: 10),
                              _GenderSelector(
                                value: _gender,
                                onChanged: authState.isLoading
                                    ? null
                                    : (value) =>
                                          setState(() => _gender = value),
                              ),
                            ],
                            if (authState.error != null) ...[
                              const SizedBox(height: 16),
                              _ErrorBanner(message: authState.error!),
                            ],
                            const SizedBox(height: 22),
                            Semantics(
                              label: 'qa.signup.create_account_button',
                              button: true,
                              child: SizedBox(
                                height: 56,
                                child: GlassButton(
                                  key: const ValueKey(
                                    'qa.signup.create_account_button',
                                  ),
                                  label: widget.introducer
                                      ? 'Create friend account'
                                      : 'Create account',
                                  icon: Icons.person_add_alt_1_rounded,
                                  shinyEffect: true,
                                  isLoading: authState.isLoading,
                                  onPressed: authState.isLoading
                                      ? null
                                      : () => _createAccount(notifier),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    _SigninLink(
                      enabled: !authState.isLoading,
                      onTap: () {
                        notifier.resetAuthFlow();
                        if (kIsWeb) {
                          Navigator.of(
                            context,
                          ).popUntil((route) => route.isFirst);
                          setWebRoute('/signin');
                          return;
                        }
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute<void>(
                            builder: (_) => const AuthScreen(),
                          ),
                        );
                      },
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
}

class _SignupHeader extends StatelessWidget {
  const _SignupHeader();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: scheme.primary,
          ),
          child: Icon(
            Icons.person_add_alt_1_rounded,
            color: scheme.onPrimary,
            size: 32,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Create your account',
          style: Theme.of(context).textTheme.headlineMedium!.copyWith(
            fontWeight: FontWeight.w800,
            color: scheme.onSurface,
          ),
        ),
        const SizedBox(height: 7),
        Text(
          'Choose a unique username and secure password',
          textAlign: TextAlign.center,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
        ),
      ],
    );
  }
}

class _SignupPane extends StatelessWidget {
  const _SignupPane({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
    ),
    child: child,
  );
}

class _SignupTextField extends StatelessWidget {
  const _SignupTextField({
    required this.controller,
    required this.hint,
    required this.icon,
    required this.fieldKey,
    required this.semanticLabel,
    this.focusNode,
    this.enabled = true,
    this.autofocus = false,
    this.obscureText = false,
    this.textInputAction,
    this.textCapitalization = TextCapitalization.none,
    this.autofillHints,
    this.onSubmitted,
    this.suffixIcon,
  });

  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final Key fieldKey;
  final String semanticLabel;
  final FocusNode? focusNode;
  final bool enabled;
  final bool autofocus;
  final bool obscureText;
  final TextInputAction? textInputAction;
  final TextCapitalization textCapitalization;
  final Iterable<String>? autofillHints;
  final ValueChanged<String>? onSubmitted;
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
        enabled: enabled,
        autofocus: autofocus,
        obscureText: obscureText,
        textInputAction: textInputAction,
        textCapitalization: textCapitalization,
        autofillHints: autofillHints,
        onSubmitted: onSubmitted,
        onTapOutside: (_) => FocusManager.instance.primaryFocus?.unfocus(),
        style: TextStyle(color: scheme.onSurface),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: scheme.onSurfaceVariant),
          prefixIcon: Icon(icon, color: scheme.primary),
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

class _DateOfBirthField extends StatelessWidget {
  const _DateOfBirthField({
    required this.value,
    required this.enabled,
    required this.onTap,
  });

  final DateTime? value;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      label: 'qa.signup.dob_field',
      button: true,
      child: InkWell(
        key: const ValueKey('qa.signup.dob_field'),
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            color: scheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: scheme.outlineVariant),
          ),
          child: Row(
            children: [
              Icon(Icons.cake_outlined, color: scheme.primary),
              const SizedBox(width: 12),
              // Expanded, not a bare Text beside a Spacer: the label is the
              // only part that can give, and a formatted date is longer than
              // the "Select date" placeholder this was sized against.
              Expanded(
                child: Text(
                  value == null ? 'Select date' : _displayDate(value!),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: value == null
                        ? scheme.onSurfaceVariant
                        : scheme.onSurface,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.calendar_month_rounded, color: scheme.primary),
            ],
          ),
        ),
      ),
    );
  }
}

class _GenderSelector extends StatelessWidget {
  const _GenderSelector({required this.value, required this.onChanged});

  final String? value;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        for (final option in const [
          ('M', 'Man'),
          ('F', 'Woman'),
          ('Other', 'Other'),
        ]) ...[
          Expanded(
            child: Semantics(
              selected: value == option.$1,
              button: true,
              child: InkWell(
                onTap: onChanged == null ? null : () => onChanged!(option.$1),
                borderRadius: BorderRadius.circular(14),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: value == option.$1
                        ? scheme.primaryContainer
                        : scheme.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: value == option.$1
                          ? scheme.primary
                          : scheme.outlineVariant,
                    ),
                  ),
                  child: Text(
                    option.$2,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: value == option.$1
                          ? scheme.onPrimaryContainer
                          : scheme.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (option.$1 != 'Other') const SizedBox(width: 8),
        ],
      ],
    );
  }
}

class _VisibilityButton extends StatelessWidget {
  const _VisibilityButton({required this.obscure, required this.onPressed});
  final bool obscure;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => IconButton(
    tooltip: obscure ? 'Show password' : 'Hide password',
    onPressed: onPressed,
    icon: Icon(
      obscure ? Icons.visibility_rounded : Icons.visibility_off_rounded,
      color: Theme.of(context).colorScheme.onSurfaceVariant,
    ),
  );
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: Theme.of(context).textTheme.labelLarge?.copyWith(
      color: Theme.of(context).colorScheme.onSurface,
      fontWeight: FontWeight.w700,
    ),
  );
}

class _FieldHelp extends StatelessWidget {
  const _FieldHelp(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: Theme.of(context).textTheme.bodySmall?.copyWith(
      color: Theme.of(context).colorScheme.onSurfaceVariant,
    ),
  );
}

class _SigninLink extends StatelessWidget {
  const _SigninLink({required this.enabled, required this.onTap});
  final bool enabled;
  final VoidCallback onTap;

  @override
  // Wrap rather than Row: the prompt and the action are a sentence, and a
  // sentence should reflow. As a fixed Row this overflowed on every phone
  // width once the button's own padding was counted — and neither half can be
  // ellipsised without losing the meaning.
  Widget build(BuildContext context) => Wrap(
    alignment: WrapAlignment.center,
    crossAxisAlignment: WrapCrossAlignment.center,
    children: [
      Text(
        'Already have an account?',
        style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
      ),
      TextButton(
        onPressed: enabled ? onTap : null,
        child: const Text('Sign in'),
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
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: color.withValues(alpha: 0.32)),
    ),
    child: Row(
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            message,
            style: TextStyle(color: color, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    ),
  );
}

int _ageInYears(DateTime dob) {
  final now = DateTime.now();
  var age = now.year - dob.year;
  if (now.month < dob.month || (now.month == dob.month && now.day < dob.day)) {
    age--;
  }
  return age;
}

String _formatDate(DateTime value) =>
    '${value.year.toString().padLeft(4, '0')}-'
    '${value.month.toString().padLeft(2, '0')}-'
    '${value.day.toString().padLeft(2, '0')}';

String _displayDate(DateTime value) =>
    '${value.day.toString().padLeft(2, '0')}/'
    '${value.month.toString().padLeft(2, '0')}/${value.year}';
