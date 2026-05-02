import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pinput/pinput.dart';

import '../../../core/config/feature_flags.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/glass_widgets.dart';
import '../providers/auth_provider.dart';
import 'welcome_screen.dart';

/// Auth screen — phone number entry + OTP verification.
///
/// Layout contract (no LayoutBuilder, no ValueListenableBuilder):
///   Scaffold → body: bgGradient → SafeArea → FadeTransition → Column
///     Expanded → SingleChildScrollView → content card
///     _BottomAction  (pinned, SafeArea bottom, RepaintBoundary isolated)
class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen>
    with SingleTickerProviderStateMixin {
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  final _phoneFocusNode = FocusNode();
  final _otpFocusNode = FocusNode();

  late final AnimationController _fadeCtrl;
  late final Animation<double> _fadeAnim;

  // OTP length tracked via addListener + setState so the Verify button's
  // enabled state update goes through the normal layout→paint pipeline.
  // This avoids the RenderPhysicalShape "not laid out" crash that
  // ValueListenableBuilder causes when firing mid-keyboard-animation.
  int _otpLength = 0;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
    );
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOutCubic);
    _fadeCtrl.forward();
    _otpController.addListener(_onOtpChanged);
  }

  void _onOtpChanged() {
    final len = _otpController.text.trim().length;
    if (len != _otpLength) setState(() => _otpLength = len);
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    _phoneController.dispose();
    _otpController
      ..removeListener(_onOtpChanged)
      ..dispose();
    _phoneFocusNode.dispose();
    _otpFocusNode.dispose();
    super.dispose();
  }

  // ─── actions ────────────────────────────────────────────────────────────────

  Future<void> _sendOtp(AuthNotifier notifier) async {
    final phone = _phoneController.text.trim();
    if (phone.isEmpty) {
      _snack('Please enter your mobile number.');
      return;
    }
    final cleaned = phone.replaceAll(RegExp(r'[\s\-]'), '');
    if (!RegExp(r'^\+?[0-9]{10,15}$').hasMatch(cleaned)) {
      _snack('Please enter a valid mobile number.');
      return;
    }
    await notifier.sendOtp(phone);
    if (!mounted) return;
    if (ref.read(authNotifierProvider).isOtpSent) {
      _otpController.clear();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _otpFocusNode.requestFocus();
      });
    }
  }

  Future<void> _verifyOtp(AuthNotifier notifier) async {
    final otp = _otpController.text.trim();
    if (otp.length != 6) {
      _snack('Please enter the 6-digit OTP.');
      return;
    }
    await notifier.verifyOtp(otp);
    if (!mounted) {
      return;
    }
    if (ref.read(authNotifierProvider).isAuthenticated) {
      FocusManager.instance.primaryFocus?.unfocus();
      Navigator.of(context).popUntil((route) => route.isFirst);
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

  // ─── build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final authNotifier = ref.read(authNotifierProvider.notifier);

    ref.listen<AuthState>(authNotifierProvider, (prev, next) {
      if (!(prev?.isAuthenticated ?? false) && next.isAuthenticated) {
        FocusManager.instance.primaryFocus?.unfocus();
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) Navigator.of(context).popUntil((r) => r.isFirst);
        });
      }
    });

    final isOtp = authState.isOtpSent;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: DecoratedBox(
        decoration: const BoxDecoration(gradient: AppTheme.bgGradient),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnim,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isCompactHeight = constraints.maxHeight < 720;
                final isTabletWidth = constraints.maxWidth >= 700;
                final horizontalPadding = isTabletWidth ? 32.0 : 24.0;
                final topPadding = isCompactHeight ? 12.0 : 24.0;
                final headerGap = isCompactHeight ? 18.0 : 32.0;

                return Column(
                  children: [
                    // ── scrollable content area ──────────────────────────────
                    Expanded(
                      child: SingleChildScrollView(
                        keyboardDismissBehavior:
                            ScrollViewKeyboardDismissBehavior.onDrag,
                        padding: EdgeInsets.fromLTRB(
                          horizontalPadding,
                          topPadding,
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
                                    tooltip: 'Back to welcome',
                                    onTap: () {
                                      authNotifier.resetAuthFlow();
                                      final navigator = Navigator.of(context);
                                      if (navigator.canPop()) {
                                        navigator.pop();
                                      } else {
                                        navigator.pushReplacement(
                                          MaterialPageRoute<void>(
                                            builder: (_) =>
                                                const WelcomeScreen(),
                                          ),
                                        );
                                      }
                                    },
                                  ),
                                ),
                                SizedBox(height: isCompactHeight ? 0 : 4),
                                _AuthHeader(isOtp: isOtp),
                                SizedBox(height: headerGap),
                                _AuthPane(
                                  child: isOtp
                                      ? _OtpStep(
                                          key: const ValueKey('otp-step'),
                                          authState: authState,
                                          authNotifier: authNotifier,
                                          phoneController: _phoneController,
                                          otpController: _otpController,
                                          otpFocusNode: _otpFocusNode,
                                          onVerify: () =>
                                              _verifyOtp(authNotifier),
                                          onResend: () =>
                                              _sendOtp(authNotifier),
                                          onPaste: _pasteOtp,
                                          onClear: () {
                                            _otpController.clear();
                                            authNotifier.clearError();
                                          },
                                        )
                                      : _PhoneStep(
                                          key: const ValueKey('phone-step'),
                                          authState: authState,
                                          authNotifier: authNotifier,
                                          phoneController: _phoneController,
                                          phoneFocusNode: _phoneFocusNode,
                                          onSend: () => _sendOtp(authNotifier),
                                        ),
                                ),
                                if (!isOtp) ...[
                                  const SizedBox(height: 20),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.lock_outline_rounded,
                                        size: 13,
                                        color: Colors.white.withValues(
                                          alpha: 0.5,
                                        ),
                                      ),
                                      const SizedBox(width: 5),
                                      Flexible(
                                        child: Text(
                                          'By continuing, you agree to our '
                                          'Terms & Privacy Policy.',
                                          textAlign: TextAlign.center,
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall
                                              ?.copyWith(
                                                color: Colors.white.withValues(
                                                  alpha: 0.55,
                                                ),
                                              ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),

                    // ── pinned bottom CTA ────────────────────────────────────
                    _AuthBottomAction(
                      isOtp: isOtp,
                      canVerify: _otpLength == 6,
                      isLoading: authState.isLoading,
                      onSend: () => _sendOtp(authNotifier),
                      onVerify: () => _verifyOtp(authNotifier),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// Sub-widgets
// =============================================================================

// ── header ────────────────────────────────────────────────────────────────────

class _AuthHeader extends StatelessWidget {
  const _AuthHeader({required this.isOtp});
  final bool isOtp;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // outer glow ring
        Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppTheme.crystalGoldSoft.withValues(alpha: 0.22),
                    AppTheme.crystalGoldDeep.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
            // mid ring
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppTheme.crystalGoldSoft.withValues(alpha: 0.28),
                  width: 1.0,
                ),
              ),
            ),
            // icon badge
            Container(
              width: 68,
              height: 68,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [Color(0xFFE2B84F), Color(0xFF6E5200)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.crystalGoldSoft.withValues(alpha: 0.45),
                    blurRadius: 20,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Icon(
                isOtp
                    ? Icons.mark_email_read_rounded
                    : Icons.verified_user_rounded,
                color: Colors.white,
                size: 30,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        GradientText(
          isOtp ? 'Verify' : 'Sign in',
          style: Theme.of(context).textTheme.displaySmall!.copyWith(
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
          gradient: const LinearGradient(
            colors: [Colors.white, Color(0xFFF4D97A)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          isOtp
              ? 'Enter the 6\u2011digit code we sent you'
              : 'Secure, private & verified',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Colors.white.withValues(alpha: 0.72),
            letterSpacing: 0.2,
          ),
        ),
      ],
    );
  }
}

// ── glass pane ────────────────────────────────────────────────────────────────

class _AuthPane extends StatelessWidget {
  const _AuthPane({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(28),
    child: BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.20),
            width: 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: AppTheme.crystalGoldDeep.withValues(alpha: 0.18),
              blurRadius: 32,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
        child: child,
      ),
    ),
  );
}

// ── phone step ────────────────────────────────────────────────────────────────

class _PhoneStep extends StatelessWidget {
  const _PhoneStep({
    super.key,
    required this.authState,
    required this.authNotifier,
    required this.phoneController,
    required this.phoneFocusNode,
    required this.onSend,
  });

  final AuthState authState;
  final AuthNotifier authNotifier;
  final TextEditingController phoneController;
  final FocusNode phoneFocusNode;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) => AutofillGroup(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _panelLabel(context, 'Mobile number'),
        const SizedBox(height: 6),
        _panelSubtitle(
          context,
          'We\u2019ll send a one\u2011time code to verify your number.',
        ),
        const SizedBox(height: 20),
        if (kUseMockAuth) ...[
          _tintBanner(
            context,
            icon: Icons.science_rounded,
            msg: 'Mock mode active \u2014 any number works.',
            color: AppTheme.crystalGoldSoft,
          ),
          const SizedBox(height: 12),
        ],
        _GlassTextField(
          controller: phoneController,
          focusNode: phoneFocusNode,
          autofocus: true,
          enabled: !authState.isLoading,
          keyboardType: TextInputType.phone,
          textInputAction: TextInputAction.done,
          autofillHints: const [AutofillHints.telephoneNumber],
          onSubmitted: (_) => onSend(),
          hint: '+91 98765 43210',
          prefixIcon: Icons.phone_iphone_rounded,
        ),
        if (authState.error != null) ...[
          const SizedBox(height: 14),
          _errorBanner(context, authState.error!),
        ],
      ],
    ),
  );
}

// ── otp step ──────────────────────────────────────────────────────────────────

class _OtpStep extends StatelessWidget {
  const _OtpStep({
    super.key,
    required this.authState,
    required this.authNotifier,
    required this.phoneController,
    required this.otpController,
    required this.otpFocusNode,
    required this.onVerify,
    required this.onResend,
    required this.onPaste,
    required this.onClear,
  });

  final AuthState authState;
  final AuthNotifier authNotifier;
  final TextEditingController phoneController;
  final TextEditingController otpController;
  final FocusNode otpFocusNode;
  final VoidCallback onVerify;
  final VoidCallback onResend;
  final VoidCallback onPaste;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final phone = phoneController.text.trim().isEmpty
        ? (authState.phoneNumber ?? 'your number')
        : phoneController.text.trim();

    final textScale = MediaQuery.textScalerOf(context).scale(1.0);
    final pinGap = textScale > 1.3 ? 36.0 : 24.0;

    const double sepW = 8.0;
    final screenW = MediaQuery.sizeOf(context).width;
    final cardW = math.min(AppTheme.contentMaxWidth, screenW - 48.0);
    final cardInnerW = (cardW - 48.0).clamp(0.0, double.infinity);
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
      color: AppTheme.crystalGoldDeep.withValues(alpha: 0.15),
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
      color: AppTheme.crystalGoldFog.withValues(alpha: 0.18),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(
        color: AppTheme.crystalGoldSoft.withValues(alpha: 0.55),
        width: 1.2,
      ),
    );
    const pinTextStyle = TextStyle(
      fontSize: 22,
      fontWeight: FontWeight.w700,
      color: Colors.white,
    );

    final defaultTheme = PinTheme(
      width: pinW,
      height: 54,
      textStyle: pinTextStyle,
      decoration: idleDeco,
    );
    final focusedTheme = PinTheme(
      width: pinW,
      height: 54,
      textStyle: pinTextStyle,
      decoration: focusDeco,
    );
    final submittedTheme = PinTheme(
      width: pinW,
      height: 54,
      textStyle: pinTextStyle,
      decoration: filledDeco,
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── phone badge ──
        _panelLabel(context, 'Code sent to'),
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
                Icon(
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
        SizedBox(height: pinGap),

        // ── pin boxes ──
        ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 64),
          child: Center(
            child: MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: TextScaler.noScaling),
              child: Pinput(
                controller: otpController,
                focusNode: otpFocusNode,
                autofocus: true,
                enabled: !authState.isLoading,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.done,
                autofillHints: const [AutofillHints.oneTimeCode],
                length: 6,
                separatorBuilder: (_) => SizedBox(width: sepW),
                defaultPinTheme: defaultTheme,
                focusedPinTheme: focusedTheme,
                submittedPinTheme: submittedTheme,
                onCompleted: (_) => onVerify(),
                onTapOutside: (_) =>
                    FocusManager.instance.primaryFocus?.unfocus(),
              ),
            ),
          ),
        ),

        if (authState.error != null) ...[
          const SizedBox(height: 16),
          _errorBanner(context, authState.error!),
        ],

        const SizedBox(height: 24),

        // ── action row ──
        Row(
          children: [
            _OtpActionChip(
              label: 'Paste',
              icon: Icons.content_paste_rounded,
              onPressed: onPaste,
            ),
            const SizedBox(width: 10),
            _OtpActionChip(
              label: 'Resend',
              icon: Icons.refresh_rounded,
              onPressed: onResend,
            ),
            const SizedBox(width: 10),
            _OtpActionChip(
              label: 'Clear',
              icon: Icons.backspace_outlined,
              onPressed: onClear,
            ),
          ],
        ),

        if (kBypassOtpValidation) ...[
          const SizedBox(height: 12),
          _tintBanner(
            context,
            icon: Icons.bug_report_rounded,
            msg: 'Pre-live shortcut: use 123456 as the OTP.',
            color: AppTheme.crystalGoldSoft,
          ),
        ],
        if (kUseMockAuth) ...[
          const SizedBox(height: 12),
          _tintBanner(
            context,
            icon: Icons.science_rounded,
            msg: 'Mock mode: any 6\u2011digit code works.',
            color: AppTheme.crystalGoldSoft,
          ),
        ],
      ],
    );
  }
}

// ── pinned bottom action ──────────────────────────────────────────────────────

/// Wrapped in RepaintBoundary so that AnimatedBuilder inside GlassButton does
/// not trigger a repaint of the scrollable content above it.
class _AuthBottomAction extends StatelessWidget {
  const _AuthBottomAction({
    required this.isOtp,
    required this.isLoading,
    required this.canVerify,
    required this.onSend,
    required this.onVerify,
  });

  final bool isOtp;
  final bool isLoading;
  final bool canVerify;
  final VoidCallback onSend;
  final VoidCallback onVerify;

  @override
  Widget build(BuildContext context) => RepaintBoundary(
    child: SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: AppTheme.contentMaxWidth,
            ),
            child: SizedBox(
              width: double.infinity,
              height: 56,
              child: isOtp
                  ? GlassButton(
                      key: const ValueKey('verify-btn'),
                      label: 'Verify & Continue',
                      icon: Icons.verified_user_rounded,
                      shinyEffect: true,
                      isLoading: isLoading,
                      onPressed: canVerify ? onVerify : null,
                    )
                  : GlassButton(
                      key: const ValueKey('send-btn'),
                      label: 'Send OTP',
                      icon: Icons.arrow_forward_rounded,
                      shinyEffect: true,
                      isLoading: isLoading,
                      onPressed: onSend,
                    ),
            ),
          ),
        ),
      ),
    ),
  );
}

// ── OTP action chip ──────────────────────────────────────────────────────────

class _OtpActionChip extends StatelessWidget {
  const _OtpActionChip({
    required this.label,
    required this.icon,
    required this.onPressed,
  });
  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => Expanded(
    child: GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 11),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: AppTheme.crystalGoldSoft),
            const SizedBox(width: 5),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: Colors.white.withValues(alpha: 0.85),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

// ── glass text field ─────────────────────────────────────────────────────────

class _GlassTextField extends StatelessWidget {
  const _GlassTextField({
    required this.controller,
    required this.hint,
    required this.prefixIcon,
    this.focusNode,
    this.autofocus = false,
    this.enabled = true,
    this.keyboardType,
    this.textInputAction,
    this.autofillHints,
    this.onSubmitted,
  });

  final TextEditingController controller;
  final FocusNode? focusNode;
  final bool autofocus;
  final bool enabled;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final Iterable<String>? autofillHints;
  final ValueChanged<String>? onSubmitted;
  final String hint;
  final IconData prefixIcon;

  @override
  Widget build(BuildContext context) => TextField(
    controller: controller,
    focusNode: focusNode,
    autofocus: autofocus,
    enabled: enabled,
    keyboardType: keyboardType,
    textInputAction: textInputAction,
    autofillHints: autofillHints,
    onSubmitted: onSubmitted,
    onTapOutside: (_) => FocusManager.instance.primaryFocus?.unfocus(),
    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
      color: Colors.white,
      fontWeight: FontWeight.w500,
    ),
    decoration: InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.38)),
      prefixIcon: Icon(prefixIcon, color: AppTheme.crystalGoldSoft, size: 20),
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
      disabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.10)),
      ),
    ),
  );
}

// =============================================================================
// Shared helpers
// =============================================================================

Widget _panelLabel(BuildContext context, String text) => Text(
  text,
  style: Theme.of(context).textTheme.labelLarge?.copyWith(
    fontWeight: FontWeight.w700,
    color: Colors.white.withValues(alpha: 0.9),
    letterSpacing: 0.4,
  ),
);

Widget _panelSubtitle(BuildContext context, String text) => Text(
  text,
  style: Theme.of(context).textTheme.bodySmall?.copyWith(
    color: Colors.white.withValues(alpha: 0.58),
    height: 1.45,
  ),
);

Widget _tintBanner(
  BuildContext context, {
  required IconData icon,
  required String msg,
  required Color color,
}) => Container(
  width: double.infinity,
  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
  decoration: BoxDecoration(
    color: color.withValues(alpha: 0.10),
    borderRadius: BorderRadius.circular(12),
    border: Border.all(color: color.withValues(alpha: 0.28)),
  ),
  child: Row(
    children: [
      Icon(icon, size: 15, color: color),
      const SizedBox(width: 8),
      Flexible(
        child: Text(
          msg,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    ],
  ),
);

Widget _errorBanner(BuildContext context, String msg) => Container(
  width: double.infinity,
  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
  decoration: BoxDecoration(
    color: AppTheme.errorRed.withValues(alpha: 0.12),
    borderRadius: BorderRadius.circular(12),
    border: Border.all(color: AppTheme.errorRed.withValues(alpha: 0.38)),
  ),
  child: Row(
    children: [
      Icon(Icons.error_outline_rounded, size: 15, color: AppTheme.errorRed),
      const SizedBox(width: 8),
      Flexible(
        child: Text(
          msg,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: AppTheme.errorRed),
        ),
      ),
    ],
  ),
);
