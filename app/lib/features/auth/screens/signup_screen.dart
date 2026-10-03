import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/config/feature_flags.dart';
import '../../../core/platform/browser_context.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/glass_widgets.dart';
import '../../../core/widgets/qa_id.dart';
import '../../common/widgets/language_picker.dart';
import '../../../l10n/app_localizations.dart';
import '../auth_messages.dart';
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
    final l10n = AppLocalizations.of(context);

    if (!RegExp(
      r'^[A-Za-z0-9][A-Za-z0-9._]{1,28}[A-Za-z0-9]$',
    ).hasMatch(username)) {
      _snack(l10n.authErrorUsernameFormat);
      _usernameFocus.requestFocus();
      return;
    }
    final passwordBytes = utf8.encode(password).length;
    if (passwordBytes < 8 ||
        passwordBytes > 72 ||
        !RegExp('[A-Za-z]').hasMatch(password) ||
        !RegExp('[0-9]').hasMatch(password)) {
      _snack(l10n.authErrorPasswordFormat);
      _passwordFocus.requestFocus();
      return;
    }
    if (password != confirmation) {
      _snack(l10n.signupErrorPasswordMismatch);
      _confirmPasswordFocus.requestFocus();
      return;
    }
    if (name.length < 2) {
      _snack(l10n.signupErrorFullName);
      _nameFocus.requestFocus();
      return;
    }
    if (dob == null) {
      _snack(l10n.signupErrorDobMissing);
      return;
    }
    if (_ageInYears(dob) < 18) {
      _snack(l10n.signupErrorUnderage);
      return;
    }
    if (_ageInYears(dob) > 80) {
      _snack(l10n.signupErrorAgeRange);
      return;
    }
    final gender = _gender;
    if (!widget.introducer && gender == null) {
      _snack(l10n.signupErrorGenderMissing);
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
      helpText: AppLocalizations.of(context).signupDobPickerHelp,
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
    final l10n = AppLocalizations.of(context);

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
                    Row(
                      children: [
                        GoldBackButton(
                          key: const ValueKey('qa.signup.back'),
                          tooltip: l10n.signupBackTooltip,
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
                        const Spacer(),
                        const Flexible(flex: 4, child: LanguagePickerButton()),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (widget.introducer) ...[
                      Text(
                        l10n.signupIntroducerTitle,
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 12),
                      Text(l10n.signupIntroducerBody),
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
                            _FieldLabel(l10n.signupUsernameLabel),
                            const SizedBox(height: 8),
                            _SignupTextField(
                              fieldKey: const ValueKey(
                                'qa.signup.username_field',
                              ),
                              qaId: 'qa.signup.username_field',
                              controller: _usernameController,
                              focusNode: _usernameFocus,
                              enabled: !authState.isLoading,
                              autofocus: true,
                              textInputAction: TextInputAction.next,
                              autofillHints: const [AutofillHints.newUsername],
                              hint: l10n.signupUsernameHint,
                              icon: Icons.person_outline_rounded,
                              onSubmitted: (_) => _passwordFocus.requestFocus(),
                            ),
                            const SizedBox(height: 6),
                            _FieldHelp(l10n.signupUsernameHelp),
                            const SizedBox(height: 18),
                            _FieldLabel(l10n.signupPasswordLabel),
                            const SizedBox(height: 8),
                            _SignupTextField(
                              fieldKey: const ValueKey(
                                'qa.signup.password_field',
                              ),
                              qaId: 'qa.signup.password_field',
                              controller: _passwordController,
                              focusNode: _passwordFocus,
                              enabled: !authState.isLoading,
                              obscureText: _obscurePassword,
                              textInputAction: TextInputAction.next,
                              autofillHints: kEnableQaAutomation
                                  ? null
                                  : const [AutofillHints.newPassword],
                              hint: l10n.signupPasswordHint,
                              icon: Icons.password_rounded,
                              suffixIcon: _VisibilityButton(
                                key: const ValueKey(
                                  'qa.signup.password_visibility',
                                ),
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
                              qaId: 'qa.signup.confirm_password_field',
                              controller: _confirmPasswordController,
                              focusNode: _confirmPasswordFocus,
                              enabled: !authState.isLoading,
                              obscureText: _obscureConfirmation,
                              textInputAction: TextInputAction.next,
                              hint: l10n.signupConfirmPasswordHint,
                              icon: Icons.lock_outline_rounded,
                              suffixIcon: _VisibilityButton(
                                key: const ValueKey(
                                  'qa.signup.confirm_password_visibility',
                                ),
                                obscure: _obscureConfirmation,
                                onPressed: () => setState(
                                  () => _obscureConfirmation =
                                      !_obscureConfirmation,
                                ),
                              ),
                              onSubmitted: (_) => _nameFocus.requestFocus(),
                            ),
                            const SizedBox(height: 18),
                            _FieldLabel(l10n.signupNameLabel),
                            const SizedBox(height: 8),
                            _SignupTextField(
                              fieldKey: const ValueKey('qa.signup.name_field'),
                              qaId: 'qa.signup.name_field',
                              controller: _nameController,
                              focusNode: _nameFocus,
                              enabled: !authState.isLoading,
                              textCapitalization: TextCapitalization.words,
                              textInputAction: TextInputAction.done,
                              hint: l10n.signupNameHint,
                              icon: Icons.badge_outlined,
                            ),
                            const SizedBox(height: 18),
                            _FieldLabel(l10n.signupDobLabel),
                            const SizedBox(height: 8),
                            _DateOfBirthField(
                              value: _dateOfBirth,
                              enabled: !authState.isLoading,
                              onTap: _pickDateOfBirth,
                            ),
                            const SizedBox(height: 18),
                            if (!widget.introducer) ...[
                              _FieldLabel(l10n.signupGenderLabel),
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
                              _ErrorBanner(
                                message: localizedAuthMessage(
                                  l10n,
                                  authState.error!,
                                ),
                              ),
                            ],
                            const SizedBox(height: 22),
                            QaId(
                              'qa.signup.create_account_button',
                              child: SizedBox(
                                height: 56,
                                child: GlassButton(
                                  key: const ValueKey(
                                    'qa.signup.create_account_button',
                                  ),
                                  label: widget.introducer
                                      ? l10n.signupCreateFriendAccount
                                      : l10n.welcomeCreateAccount,
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
          AppLocalizations.of(context).signupTitle,
          style: Theme.of(context).textTheme.headlineMedium!.copyWith(
            fontWeight: FontWeight.w800,
            color: scheme.onSurface,
          ),
        ),
        const SizedBox(height: 7),
        Text(
          AppLocalizations.of(context).signupSubtitle,
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
    required this.qaId,
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
  final String qaId;
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
    // The field announces its hint; the automation id is an identifier.
    return QaId(
      qaId,
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
    final l10n = AppLocalizations.of(context);
    return QaId(
      'qa.signup.dob_field',
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
                  value == null
                      ? l10n.signupDobPlaceholder
                      : _displayDate(value!, Localizations.localeOf(context)),
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
    final l10n = AppLocalizations.of(context);
    return Row(
      children: [
        for (final option in [
          ('M', l10n.signupGenderMan),
          ('F', l10n.signupGenderWoman),
          ('Other', l10n.signupGenderOther),
        ]) ...[
          Expanded(
            child: Semantics(
              selected: value == option.$1,
              button: true,
              child: InkWell(
                key: ValueKey('qa.signup.gender.${option.$1}'),
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
  const _VisibilityButton({
    required this.obscure,
    required this.onPressed,
    super.key,
  });
  final bool obscure;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => IconButton(
    tooltip: obscure
        ? AppLocalizations.of(context).authShowPassword
        : AppLocalizations.of(context).authHidePassword,
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
        AppLocalizations.of(context).signupAlreadyHaveAccount,
        style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
      ),
      TextButton(
        key: const ValueKey('qa.signup.sign_in_link'),
        onPressed: enabled ? onTap : null,
        child: Text(AppLocalizations.of(context).authSignIn),
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

/// The member's own short date (en-US 3/14/1995, en-GB 14/03/1995,
/// de 14.3.1995). What is sent to the server stays ISO (see [_formatDate]).
String _displayDate(DateTime value, Locale locale) =>
    DateFormat.yMd(locale.toString()).format(value);
