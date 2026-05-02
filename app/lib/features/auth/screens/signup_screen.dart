import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pinput/pinput.dart';

import '../../../core/config/feature_flags.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/glass_widgets.dart';
import '../providers/auth_provider.dart';
import 'auth_screen.dart';

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _phoneController = TextEditingController();
  final _nameController = TextEditingController();
  final _otpController = TextEditingController();
  final _phoneFocusNode = FocusNode();
  final _nameFocusNode = FocusNode();
  final _otpFocusNode = FocusNode();

  int? _dobDay;
  int? _dobMonth;
  int? _dobYear;
  String _gender = 'F';
  int _otpLength = 0;

  DateTime? get _dob {
    final day = _dobDay;
    final month = _dobMonth;
    final year = _dobYear;
    if (day == null || month == null || year == null) {
      return null;
    }
    return DateTime(year, month, day);
  }

  @override
  void initState() {
    super.initState();
    _otpController.addListener(_onOtpChanged);
  }

  void _onOtpChanged() {
    final len = _otpController.text.trim().length;
    if (len != _otpLength) {
      setState(() => _otpLength = len);
    }
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _nameController.dispose();
    _otpController
      ..removeListener(_onOtpChanged)
      ..dispose();
    _phoneFocusNode.dispose();
    _nameFocusNode.dispose();
    _otpFocusNode.dispose();
    super.dispose();
  }

  Future<void> _sendSignupOtp(AuthNotifier notifier) async {
    final phone = _phoneController.text.trim();
    final name = _nameController.text.trim();
    final dob = _dob;

    if (phone.isEmpty) {
      _snack('Please enter your mobile number.');
      return;
    }
    if (!RegExp(r'^\+?[0-9\s\-]{10,18}$').hasMatch(phone)) {
      _snack('Please enter a valid mobile number.');
      return;
    }
    if (name.length < 2) {
      _snack('Please enter your full name.');
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

    await notifier.sendSignupOtp(
      SignupDraft(
        phoneNumber: phone,
        name: name,
        dateOfBirth: _formatDate(dob),
        gender: _gender,
      ),
    );
    if (!mounted) {
      return;
    }
    if (ref.read(authNotifierProvider).isOtpSent) {
      _otpController.clear();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _otpFocusNode.requestFocus();
        }
      });
    }
  }

  Future<void> _verifySignupOtp(AuthNotifier notifier) async {
    final otp = _otpController.text.trim();
    if (otp.length != 6) {
      _snack('Please enter the 6-digit OTP.');
      return;
    }
    await notifier.verifySignupOtp(otp);
  }

  void _setDobPart({int? day, int? month, int? year}) {
    final nextYear = year ?? _dobYear;
    final nextMonth = month ?? _dobMonth;
    var nextDay = day ?? _dobDay;

    if (nextYear != null && nextMonth != null && nextDay != null) {
      final maxDay = DateUtils.getDaysInMonth(nextYear, nextMonth);
      if (nextDay > maxDay) {
        nextDay = maxDay;
      }
    }

    setState(() {
      _dobDay = nextDay;
      _dobMonth = nextMonth;
      _dobYear = nextYear;
    });
  }

  Future<void> _pasteOtp() async {
    final data = await Clipboard.getData('text/plain');
    final digits = (data?.text ?? '').replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) {
      _snack('No OTP found in clipboard.');
      return;
    }
    final trimmed = digits.length > 6 ? digits.substring(0, 6) : digits;
    _otpController.value = TextEditingValue(
      text: trimmed,
      selection: TextSelection.collapsed(offset: trimmed.length),
    );
  }

  void _snack(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final authNotifier = ref.read(authNotifierProvider.notifier);
    final isOtp = authState.isOtpSent && authState.isSignupFlow;

    ref.listen<AuthState>(authNotifierProvider, (prev, next) {
      if (!(prev?.isAuthenticated ?? false) && next.isAuthenticated) {
        FocusManager.instance.primaryFocus?.unfocus();
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            Navigator.of(context).popUntil((r) => r.isFirst);
          }
        });
      }
    });

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: DecoratedBox(
        decoration: const BoxDecoration(gradient: AppTheme.bgGradient),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final minHeight = constraints.maxHeight - 32;

              return SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 18),
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: minHeight < 0 ? 0 : minHeight,
                      maxWidth: AppTheme.contentMaxWidth,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _SignupTopBar(
                          isOtp: isOtp,
                          onBack: () {
                            if (isOtp) {
                              authNotifier.backToIdentifierEntry();
                              return;
                            }
                            authNotifier.resetAuthFlow();
                            Navigator.of(context).maybePop();
                          },
                        ),
                        const SizedBox(height: 16),
                        _SignupHeader(isOtp: isOtp),
                        const SizedBox(height: 18),
                        GlassContainer(
                          padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
                          borderRadius: BorderRadius.circular(28),
                          backgroundColor: const Color(
                            0xFF3A2707,
                          ).withValues(alpha: 0.56),
                          border: Border.all(
                            color: AppTheme.pureGoldHighlight.withValues(
                              alpha: 0.34,
                            ),
                          ),
                          shadows: [
                            BoxShadow(
                              color: AppTheme.crystalGoldDeep.withValues(
                                alpha: 0.22,
                              ),
                              blurRadius: 32,
                              offset: const Offset(0, 12),
                            ),
                            BoxShadow(
                              color: AppTheme.crystalGoldSoft.withValues(
                                alpha: 0.10,
                              ),
                              blurRadius: 26,
                              offset: const Offset(0, 4),
                            ),
                            BoxShadow(
                              color: AppTheme.pureGoldBright.withValues(
                                alpha: 0.16,
                              ),
                              blurRadius: 36,
                              offset: const Offset(0, 6),
                            ),
                          ],
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _SignupProgressStrip(isOtp: isOtp),
                              const SizedBox(height: 18),
                              AnimatedSwitcher(
                                duration: const Duration(milliseconds: 220),
                                child: isOtp
                                    ? _SignupOtpStep(
                                        key: const ValueKey('signup-otp'),
                                        phone:
                                            authState.phoneNumber ??
                                            _phoneController.text,
                                        controller: _otpController,
                                        focusNode: _otpFocusNode,
                                        isLoading: authState.isLoading,
                                        error: authState.error,
                                        onVerify: () =>
                                            _verifySignupOtp(authNotifier),
                                        onResend: () =>
                                            _sendSignupOtp(authNotifier),
                                        onPaste: _pasteOtp,
                                        onClear: () {
                                          _otpController.clear();
                                          authNotifier.clearError();
                                        },
                                      )
                                    : _SignupBasicsStep(
                                        key: const ValueKey('signup-basics'),
                                        phoneController: _phoneController,
                                        nameController: _nameController,
                                        phoneFocusNode: _phoneFocusNode,
                                        nameFocusNode: _nameFocusNode,
                                        dobDay: _dobDay,
                                        dobMonth: _dobMonth,
                                        dobYear: _dobYear,
                                        gender: _gender,
                                        isLoading: authState.isLoading,
                                        error: authState.error,
                                        onDobDayChanged: (value) =>
                                            _setDobPart(day: value),
                                        onDobMonthChanged: (value) =>
                                            _setDobPart(month: value),
                                        onDobYearChanged: (value) =>
                                            _setDobPart(year: value),
                                        onGenderChanged: (value) =>
                                            setState(() => _gender = value),
                                        onSubmit: () =>
                                            _sendSignupOtp(authNotifier),
                                      ),
                              ),
                              const SizedBox(height: 18),
                              GlassButton(
                                label: isOtp
                                    ? 'Verify & Create Account'
                                    : 'Send OTP',
                                icon: isOtp
                                    ? Icons.verified_user_rounded
                                    : Icons.arrow_forward_rounded,
                                shinyEffect: true,
                                isLoading: authState.isLoading,
                                textColor: AppTheme.textDark,
                                fontWeight: FontWeight.w900,
                                onPressed: isOtp
                                    ? (_otpLength == 6
                                          ? () => _verifySignupOtp(authNotifier)
                                          : null)
                                    : () => _sendSignupOtp(authNotifier),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                        _SignupSigninLink(
                          enabled: !authState.isLoading,
                          onTap: () {
                            authNotifier.resetAuthFlow();
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
              );
            },
          ),
        ),
      ),
    );
  }
}

class _SignupTopBar extends StatelessWidget {
  const _SignupTopBar({required this.isOtp, required this.onBack});
  final bool isOtp;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      GoldBackButton(onTap: onBack, tooltip: 'Back to welcome'),
      const SizedBox(width: 12),
      Expanded(
        child: Text(
          isOtp ? 'Step 2 of 2 • Verify' : 'Step 1 of 2 • Account basics',
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: Colors.white.withValues(alpha: 0.82),
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    ],
  );
}

class _SignupProgressStrip extends StatelessWidget {
  const _SignupProgressStrip({required this.isOtp});
  final bool isOtp;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      const Expanded(
        child: _SignupProgressPill(
          icon: Icons.badge_rounded,
          label: 'Basics',
          active: true,
        ),
      ),
      const SizedBox(width: 8),
      Expanded(
        child: _SignupProgressPill(
          icon: Icons.sms_rounded,
          label: 'OTP',
          active: isOtp,
        ),
      ),
      const SizedBox(width: 8),
      const Expanded(
        child: _SignupProgressPill(
          icon: Icons.auto_awesome_rounded,
          label: 'Profile',
          active: false,
        ),
      ),
    ],
  );
}

class _SignupProgressPill extends StatelessWidget {
  const _SignupProgressPill({
    required this.icon,
    required this.label,
    required this.active,
  });
  final IconData icon;
  final String label;
  final bool active;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 9),
    decoration: BoxDecoration(
      color: active
          ? AppTheme.pureGoldBright.withValues(alpha: 0.30)
          : const Color(0xFF1D1302).withValues(alpha: 0.34),
      borderRadius: BorderRadius.circular(999),
      border: Border.all(
        color: active
            ? AppTheme.pureGoldHighlight.withValues(alpha: 0.52)
            : Colors.white.withValues(alpha: 0.13),
      ),
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          icon,
          size: 14,
          color: active
              ? AppTheme.pureGoldHighlight
              : Colors.white.withValues(alpha: 0.56),
        ),
        const SizedBox(width: 5),
        Flexible(
          child: Text(
            label,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: active
                  ? AppTheme.pureGoldHighlight
                  : Colors.white.withValues(alpha: 0.62),
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    ),
  );
}

class _SignupSigninLink extends StatelessWidget {
  const _SignupSigninLink({required this.enabled, required this.onTap});
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: enabled ? onTap : null,
    child: Opacity(
      opacity: enabled ? 1 : 0.5,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFF1D1302).withValues(alpha: 0.50),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: AppTheme.pureGoldHighlight.withValues(alpha: 0.38),
          ),
          boxShadow: [
            BoxShadow(
              color: AppTheme.crystalGoldSoft.withValues(alpha: 0.10),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.login_rounded,
              color: AppTheme.pureGoldHighlight,
              size: 18,
            ),
            const SizedBox(width: 8),
            Text(
              'Already have an account? Sign in',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _SignupHeader extends StatelessWidget {
  const _SignupHeader({required this.isOtp});
  final bool isOtp;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Container(
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            colors: [Color(0xFFE2B84F), Color(0xFF6E5200)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: AppTheme.crystalGoldSoft.withValues(alpha: 0.42),
              blurRadius: 22,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Icon(
          isOtp ? Icons.mark_email_read_rounded : Icons.person_add_alt_1,
          color: Colors.white,
          size: 32,
        ),
      ),
      const SizedBox(height: 18),
      GradientText(
        isOtp ? 'Verify Account' : 'Create Account',
        style: Theme.of(context).textTheme.displaySmall!.copyWith(
          fontWeight: FontWeight.w800,
          letterSpacing: -0.5,
        ),
        gradient: const LinearGradient(
          colors: [Colors.white, Color(0xFFF4D97A)],
        ),
      ),
      const SizedBox(height: 8),
      Text(
        isOtp
            ? 'Enter the 6-digit code to finish account creation.'
            : 'Start with your verified number and basic profile details.',
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: Colors.white.withValues(alpha: 0.72),
          height: 1.4,
        ),
      ),
    ],
  );
}

class _SignupBasicsStep extends StatelessWidget {
  const _SignupBasicsStep({
    required this.phoneController,
    required this.nameController,
    required this.phoneFocusNode,
    required this.nameFocusNode,
    required this.dobDay,
    required this.dobMonth,
    required this.dobYear,
    required this.gender,
    required this.isLoading,
    required this.error,
    required this.onDobDayChanged,
    required this.onDobMonthChanged,
    required this.onDobYearChanged,
    required this.onGenderChanged,
    required this.onSubmit,
    super.key,
  });

  final TextEditingController phoneController;
  final TextEditingController nameController;
  final FocusNode phoneFocusNode;
  final FocusNode nameFocusNode;
  final int? dobDay;
  final int? dobMonth;
  final int? dobYear;
  final String gender;
  final bool isLoading;
  final String? error;
  final ValueChanged<int?> onDobDayChanged;
  final ValueChanged<int?> onDobMonthChanged;
  final ValueChanged<int?> onDobYearChanged;
  final ValueChanged<String> onGenderChanged;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) => AutofillGroup(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _signupLabel(context, 'Mobile number'),
        const SizedBox(height: 8),
        _SignupTextField(
          controller: phoneController,
          focusNode: phoneFocusNode,
          enabled: !isLoading,
          keyboardType: TextInputType.phone,
          textInputAction: TextInputAction.next,
          hint: '+91 98765 43210',
          icon: Icons.phone_iphone_rounded,
        ),
        const SizedBox(height: 18),
        _signupLabel(context, 'Full name'),
        const SizedBox(height: 8),
        _SignupTextField(
          controller: nameController,
          focusNode: nameFocusNode,
          enabled: !isLoading,
          textCapitalization: TextCapitalization.words,
          textInputAction: TextInputAction.done,
          hint: 'Your name',
          icon: Icons.badge_outlined,
          onSubmitted: (_) => onSubmit(),
        ),
        const SizedBox(height: 18),
        _signupLabel(context, 'Date of birth'),
        const SizedBox(height: 8),
        _DobDropdowns(
          day: dobDay,
          month: dobMonth,
          year: dobYear,
          enabled: !isLoading,
          onDayChanged: onDobDayChanged,
          onMonthChanged: onDobMonthChanged,
          onYearChanged: onDobYearChanged,
        ),
        const SizedBox(height: 18),
        _signupLabel(context, 'I identify as'),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _GenderPill(
                label: 'Man',
                emoji: '♂️',
                selected: gender == 'M',
                onTap: () => onGenderChanged('M'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _GenderPill(
                label: 'Woman',
                emoji: '♀️',
                selected: gender == 'F',
                onTap: () => onGenderChanged('F'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _GenderPill(
                label: 'Other',
                emoji: '✨',
                selected: gender == 'Other',
                onTap: () => onGenderChanged('Other'),
              ),
            ),
          ],
        ),
        if (error != null) ...[
          const SizedBox(height: 16),
          _signupError(context, error!),
        ],
        const SizedBox(height: 14),
        _signupHint(
          context,
          'We only use these basics to create your account safely. '
          'You can complete photos, bio, and preferences next.',
        ),
      ],
    ),
  );
}

class _SignupOtpStep extends StatelessWidget {
  const _SignupOtpStep({
    required this.phone,
    required this.controller,
    required this.focusNode,
    required this.isLoading,
    required this.error,
    required this.onVerify,
    required this.onResend,
    required this.onPaste,
    required this.onClear,
    super.key,
  });

  final String phone;
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isLoading;
  final String? error;
  final VoidCallback onVerify;
  final VoidCallback onResend;
  final VoidCallback onPaste;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    const sepW = 8;
    final screenW = MediaQuery.sizeOf(context).width;
    final cardW = math.min(AppTheme.contentMaxWidth, screenW - 48.0);
    final cardInnerW = (cardW - 36.0).clamp(0.0, double.infinity);
    final availableForPins = (cardInnerW - 5 * sepW).clamp(
      0.0,
      double.infinity,
    );
    final slotW = availableForPins / 6.0;
    final pinW = slotW >= 12.0 ? slotW.clamp(12.0, 52.0) : slotW;

    final idleDeco = BoxDecoration(
      color: Colors.white.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(
        color: Colors.white.withValues(alpha: 0.22),
        width: 1.2,
      ),
    );
    final focusDeco = BoxDecoration(
      color: AppTheme.crystalGoldDeep.withValues(alpha: 0.18),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: AppTheme.crystalGoldSoft, width: 1.8),
      boxShadow: [
        BoxShadow(
          color: AppTheme.crystalGoldSoft.withValues(alpha: 0.30),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ],
    );
    final filledDeco = BoxDecoration(
      color: AppTheme.crystalGoldFog.withValues(alpha: 0.16),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(
        color: AppTheme.crystalGoldSoft.withValues(alpha: 0.55),
        width: 1.2,
      ),
    );
    const pinTextStyle = TextStyle(
      fontSize: 22,
      fontWeight: FontWeight.w800,
      color: Colors.white,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _signupLabel(context, 'Code sent to'),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerLeft,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: AppTheme.crystalGoldSoft.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(40),
              border: Border.all(
                color: AppTheme.crystalGoldSoft.withValues(alpha: 0.38),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.phone_iphone_rounded,
                  size: 15,
                  color: AppTheme.crystalGoldSoft,
                ),
                const SizedBox(width: 7),
                Text(
                  phone,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        Center(
          child: Pinput(
            controller: controller,
            focusNode: focusNode,
            enabled: !isLoading,
            autofocus: false,
            length: 6,
            keyboardType: TextInputType.number,
            separatorBuilder: (_) => SizedBox(width: sepW.toDouble()),
            defaultPinTheme: PinTheme(
              width: pinW,
              height: 54,
              textStyle: pinTextStyle,
              decoration: idleDeco,
            ),
            focusedPinTheme: PinTheme(
              width: pinW,
              height: 54,
              textStyle: pinTextStyle,
              decoration: focusDeco,
            ),
            submittedPinTheme: PinTheme(
              width: pinW,
              height: 54,
              textStyle: pinTextStyle,
              decoration: filledDeco,
            ),
            onCompleted: (_) => onVerify(),
          ),
        ),
        if (error != null) ...[
          const SizedBox(height: 16),
          _signupError(context, error!),
        ],
        const SizedBox(height: 20),
        Row(
          children: [
            _OtpLink(label: 'Paste', icon: Icons.content_paste, onTap: onPaste),
            const SizedBox(width: 8),
            _OtpLink(label: 'Resend', icon: Icons.refresh, onTap: onResend),
            const SizedBox(width: 8),
            _OtpLink(label: 'Clear', icon: Icons.backspace, onTap: onClear),
          ],
        ),
        if (kBypassOtpValidation) ...[
          const SizedBox(height: 12),
          _signupHint(context, 'Pre-live shortcut: use 123456 as the OTP.'),
        ],
      ],
    );
  }
}

class _SignupTextField extends StatelessWidget {
  const _SignupTextField({
    required this.controller,
    required this.hint,
    required this.icon,
    this.focusNode,
    this.enabled = true,
    this.keyboardType,
    this.textInputAction,
    this.textCapitalization = TextCapitalization.none,
    this.onSubmitted,
  });

  final TextEditingController controller;
  final FocusNode? focusNode;
  final bool enabled;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final TextCapitalization textCapitalization;
  final ValueChanged<String>? onSubmitted;
  final String hint;
  final IconData icon;

  @override
  Widget build(BuildContext context) => TextField(
    controller: controller,
    focusNode: focusNode,
    enabled: enabled,
    keyboardType: keyboardType,
    textInputAction: textInputAction,
    textCapitalization: textCapitalization,
    onSubmitted: onSubmitted,
    onTapOutside: (_) => FocusManager.instance.primaryFocus?.unfocus(),
    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
      color: AppTheme.pureGoldHighlight,
      fontWeight: FontWeight.w800,
      letterSpacing: 0.1,
    ),
    decoration: _signupInputDecoration(hint, icon),
  );
}

class _DobDropdowns extends StatelessWidget {
  const _DobDropdowns({
    required this.day,
    required this.month,
    required this.year,
    required this.enabled,
    required this.onDayChanged,
    required this.onMonthChanged,
    required this.onYearChanged,
  });

  final int? day;
  final int? month;
  final int? year;
  final bool enabled;
  final ValueChanged<int?> onDayChanged;
  final ValueChanged<int?> onMonthChanged;
  final ValueChanged<int?> onYearChanged;

  static const _months = <String>[
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final minYear = now.year - 80;
    final maxYear = now.year - 18;
    final effectiveYear = year ?? maxYear;
    final effectiveMonth = month ?? 1;
    final maxDay = DateUtils.getDaysInMonth(effectiveYear, effectiveMonth);
    final safeDay = day != null && day! <= maxDay ? day : null;

    return MediaQuery(
      data: MediaQuery.of(context).copyWith(textScaler: TextScaler.noScaling),
      child: Row(
        children: [
          Expanded(
            flex: 10,
            child: _DobDropdown(
              value: safeDay,
              hint: 'Date',
              icon: Icons.calendar_today_rounded,
              enabled: enabled,
              items: List<int>.generate(maxDay, (index) => index + 1),
              labelFor: (value) => value.toString().padLeft(2, '0'),
              onChanged: onDayChanged,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 11,
            child: _DobDropdown(
              value: month,
              hint: 'Month',
              icon: Icons.date_range_rounded,
              enabled: enabled,
              items: List<int>.generate(12, (index) => index + 1),
              labelFor: (value) => _months[value - 1],
              onChanged: onMonthChanged,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 12,
            child: _DobDropdown(
              value: year,
              hint: 'Year',
              icon: Icons.event_available_rounded,
              enabled: enabled,
              items: List<int>.generate(
                maxYear - minYear + 1,
                (index) => maxYear - index,
              ),
              labelFor: (value) => value.toString(),
              onChanged: onYearChanged,
            ),
          ),
        ],
      ),
    );
  }
}

class _DobDropdown extends StatelessWidget {
  const _DobDropdown({
    required this.value,
    required this.hint,
    required this.icon,
    required this.enabled,
    required this.items,
    required this.labelFor,
    required this.onChanged,
  });

  final int? value;
  final String hint;
  final IconData icon;
  final bool enabled;
  final List<int> items;
  final String Function(int value) labelFor;
  final ValueChanged<int?> onChanged;

  @override
  Widget build(BuildContext context) => DropdownButtonFormField<int>(
    initialValue: value,
    isExpanded: true,
    menuMaxHeight: 280,
    dropdownColor: const Color(0xFF3A2707),
    iconEnabledColor: AppTheme.pureGoldHighlight,
    iconDisabledColor: Colors.white.withValues(alpha: 0.34),
    style: const TextStyle(
      color: AppTheme.pureGoldHighlight,
      fontWeight: FontWeight.w800,
      fontSize: 13,
    ),
    icon: const Icon(
      Icons.keyboard_arrow_down_rounded,
      size: 18,
      color: AppTheme.pureGoldHighlight,
    ),
    decoration: _signupInputDecoration(hint, icon).copyWith(
      contentPadding: const EdgeInsets.only(left: 9, right: 2),
      prefixIconConstraints: const BoxConstraints(minWidth: 24),
      prefixIcon: Icon(icon, color: AppTheme.crystalGoldSoft, size: 15),
    ),
    hint: Text(
      hint,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        color: AppTheme.pureGoldHighlight.withValues(alpha: 0.66),
        fontWeight: FontWeight.w800,
        fontSize: 13,
      ),
    ),
    selectedItemBuilder: (context) => items
        .map(
          (value) => Align(
            alignment: Alignment.centerLeft,
            child: Text(
              labelFor(value),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        )
        .toList(),
    items: items
        .map(
          (value) => DropdownMenuItem<int>(
            value: value,
            child: Text(labelFor(value), overflow: TextOverflow.ellipsis),
          ),
        )
        .toList(),
    onChanged: enabled ? onChanged : null,
  );
}

class _GenderPill extends StatelessWidget {
  const _GenderPill({
    required this.label,
    required this.emoji,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final String emoji;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: selected
            ? AppTheme.pureGoldBright.withValues(alpha: 0.34)
            : const Color(0xFF1D1302).withValues(alpha: 0.30),
        border: Border.all(
          color: selected
              ? AppTheme.pureGoldBright
              : AppTheme.pureGoldHighlight.withValues(alpha: 0.24),
        ),
        boxShadow: selected
            ? [
                BoxShadow(
                  color: AppTheme.pureGoldBright.withValues(alpha: 0.20),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ]
            : null,
      ),
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: selected
                  ? AppTheme.pureGoldHighlight
                  : Colors.white.withValues(alpha: 0.76),
              fontWeight: FontWeight.w800,
              fontSize: 12,
            ),
          ),
        ],
      ),
    ),
  );
}

class _OtpLink extends StatelessWidget {
  const _OtpLink({
    required this.label,
    required this.icon,
    required this.onTap,
  });
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Expanded(
    child: GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 11),
        decoration: BoxDecoration(
          color: const Color(0xFF1D1302).withValues(alpha: 0.30),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: AppTheme.pureGoldHighlight.withValues(alpha: 0.22),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 14, color: AppTheme.crystalGoldSoft),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.86),
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

InputDecoration _signupInputDecoration(String hint, IconData icon) =>
    InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(
        color: AppTheme.pureGoldHighlight.withValues(alpha: 0.48),
        fontWeight: FontWeight.w800,
      ),
      prefixIcon: Icon(icon, color: AppTheme.crystalGoldSoft, size: 20),
      filled: true,
      fillColor: const Color(0xFF1D1302).withValues(alpha: 0.34),
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(
          color: AppTheme.pureGoldHighlight.withValues(alpha: 0.22),
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(
          color: AppTheme.pureGoldHighlight.withValues(alpha: 0.28),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(
          color: AppTheme.crystalGoldSoft,
          width: 1.6,
        ),
      ),
    );

Widget _signupLabel(BuildContext context, String text) => Text(
  text,
  style: Theme.of(context).textTheme.labelLarge?.copyWith(
    color: Colors.white.withValues(alpha: 0.9),
    fontWeight: FontWeight.w800,
    letterSpacing: 0.3,
  ),
);

Widget _signupHint(BuildContext context, String text) => Text(
  text,
  style: Theme.of(context).textTheme.bodySmall?.copyWith(
    color: Colors.white.withValues(alpha: 0.58),
    height: 1.42,
  ),
);

Widget _signupError(BuildContext context, String msg) => Container(
  width: double.infinity,
  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
  decoration: BoxDecoration(
    color: AppTheme.errorRed.withValues(alpha: 0.12),
    borderRadius: BorderRadius.circular(12),
    border: Border.all(color: AppTheme.errorRed.withValues(alpha: 0.38)),
  ),
  child: Text(
    msg,
    style: Theme.of(
      context,
    ).textTheme.bodySmall?.copyWith(color: AppTheme.errorRed),
  ),
);

int _ageInYears(DateTime dob) {
  final now = DateTime.now();
  var age = now.year - dob.year;
  if (DateTime(now.year, dob.month, dob.day).isAfter(now)) {
    age--;
  }
  return age;
}

String _formatDate(DateTime date) {
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return '${date.year}-$month-$day';
}
