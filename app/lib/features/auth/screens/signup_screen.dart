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

  DateTime? _dob;
  String _gender = 'F';
  int _otpLength = 0;

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
    if (!kBypassOtpValidation && otp.length != 6) {
      _snack('Please enter the 6-digit OTP.');
      return;
    }
    await notifier.verifySignupOtp(
      otp.isEmpty && kBypassOtpValidation ? '000000' : otp,
    );
  }

  Future<void> _pickDob() async {
    final now = DateTime.now();
    final initial = _dob ?? DateTime(now.year - 25, now.month, now.day);
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(now.year - 80),
      lastDate: DateTime(now.year - 18, now.month, now.day),
      helpText: 'Select date of birth',
    );
    if (picked != null) {
      setState(() => _dob = picked);
    }
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
      body: CrystalScaffold(
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: const EdgeInsets.fromLTRB(24, 18, 24, 16),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                        maxWidth: AppTheme.contentMaxWidth,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _SignupHeader(isOtp: isOtp),
                          const SizedBox(height: 24),
                          GlassContainer(
                            padding: const EdgeInsets.fromLTRB(22, 24, 22, 22),
                            borderRadius: BorderRadius.circular(28),
                            backgroundColor: Colors.white.withValues(
                              alpha: 0.09,
                            ),
                            child: AnimatedSwitcher(
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
                                      dob: _dob,
                                      gender: _gender,
                                      isLoading: authState.isLoading,
                                      error: authState.error,
                                      onDobTap: _pickDob,
                                      onGenderChanged: (value) =>
                                          setState(() => _gender = value),
                                      onSubmit: () =>
                                          _sendSignupOtp(authNotifier),
                                    ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextButton(
                            onPressed: authState.isLoading
                                ? null
                                : () {
                                    authNotifier.resetAuthFlow();
                                    Navigator.of(context).pushReplacement(
                                      MaterialPageRoute<void>(
                                        builder: (_) => const AuthScreen(),
                                      ),
                                    );
                                  },
                            child: Text(
                              'Already have an account? Sign in',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.84),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                        maxWidth: AppTheme.contentMaxWidth,
                      ),
                      child: SizedBox(
                        height: 56,
                        width: double.infinity,
                        child: GlassButton(
                          label: isOtp ? 'Verify & Create Account' : 'Send OTP',
                          icon: isOtp
                              ? Icons.verified_user_rounded
                              : Icons.arrow_forward_rounded,
                          shinyEffect: true,
                          isLoading: authState.isLoading,
                          textColor: AppTheme.textDark,
                          fontWeight: FontWeight.w800,
                          onPressed: isOtp
                              ? (kBypassOtpValidation || _otpLength == 6
                                    ? () => _verifySignupOtp(authNotifier)
                                    : null)
                              : () => _sendSignupOtp(authNotifier),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
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
    required this.dob,
    required this.gender,
    required this.isLoading,
    required this.error,
    required this.onDobTap,
    required this.onGenderChanged,
    required this.onSubmit,
    super.key,
  });

  final TextEditingController phoneController;
  final TextEditingController nameController;
  final FocusNode phoneFocusNode;
  final FocusNode nameFocusNode;
  final DateTime? dob;
  final String gender;
  final bool isLoading;
  final String? error;
  final VoidCallback onDobTap;
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
          autofocus: true,
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
        _SignupTapField(
          value: dob == null ? 'Select your date of birth' : _formatDate(dob!),
          icon: Icons.cake_outlined,
          onTap: isLoading ? null : onDobTap,
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
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      _signupLabel(context, 'Code sent to'),
      const SizedBox(height: 8),
      Text(
        phone,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          color: AppTheme.crystalGoldSoft,
          fontWeight: FontWeight.w800,
        ),
      ),
      const SizedBox(height: 24),
      Pinput(
        controller: controller,
        focusNode: focusNode,
        enabled: !isLoading,
        autofocus: true,
        length: 6,
        keyboardType: TextInputType.number,
        onCompleted: (_) => onVerify(),
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
    ],
  );
}

class _SignupTextField extends StatelessWidget {
  const _SignupTextField({
    required this.controller,
    required this.hint,
    required this.icon,
    this.focusNode,
    this.enabled = true,
    this.autofocus = false,
    this.keyboardType,
    this.textInputAction,
    this.textCapitalization = TextCapitalization.none,
    this.onSubmitted,
  });

  final TextEditingController controller;
  final FocusNode? focusNode;
  final bool enabled;
  final bool autofocus;
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
    autofocus: autofocus,
    keyboardType: keyboardType,
    textInputAction: textInputAction,
    textCapitalization: textCapitalization,
    onSubmitted: onSubmitted,
    onTapOutside: (_) => FocusManager.instance.primaryFocus?.unfocus(),
    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
    decoration: _signupInputDecoration(hint, icon),
  );
}

class _SignupTapField extends StatelessWidget {
  const _SignupTapField({required this.value, required this.icon, this.onTap});
  final String value;
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    borderRadius: BorderRadius.circular(16),
    onTap: onTap,
    child: InputDecorator(
      decoration: _signupInputDecoration(value, icon),
      child: Text(
        value,
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.9),
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
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
            ? AppTheme.crystalGoldSoft.withValues(alpha: 0.18)
            : Colors.white.withValues(alpha: 0.08),
        border: Border.all(
          color: selected
              ? AppTheme.crystalGoldSoft
              : Colors.white.withValues(alpha: 0.18),
        ),
      ),
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: selected ? 1 : 0.74),
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
          color: Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
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
      hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.38)),
      prefixIcon: Icon(icon, color: AppTheme.crystalGoldSoft, size: 20),
      filled: true,
      fillColor: Colors.white.withValues(alpha: 0.09),
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.22)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.22)),
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
