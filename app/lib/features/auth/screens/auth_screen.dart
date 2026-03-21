import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/feature_flags.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/glass_widgets.dart';
import '../providers/auth_provider.dart';

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

  late final AnimationController _fadeController;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 520),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOutCubic,
    );
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _phoneController.dispose();
    _otpController.dispose();
    _phoneFocusNode.dispose();
    _otpFocusNode.dispose();
    super.dispose();
  }

  Future<void> _sendOtp(AuthNotifier authNotifier) async {
    final mobileNumber = _phoneController.text.trim();
    if (mobileNumber.isEmpty) {
      _showSnack('Please enter your mobile number.');
      return;
    }
    if (!RegExp(
      r'^\+?[0-9]{10,15}$',
    ).hasMatch(mobileNumber.replaceAll(RegExp(r'\s+|-'), ''))) {
      _showSnack('Please enter a valid mobile number.');
      return;
    }

    await authNotifier.sendOtp(mobileNumber);
    if (!mounted) {
      return;
    }

    final currentState = ref.read(authNotifierProvider);
    if (currentState.isOtpSent) {
      _otpController.clear();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }
        _otpFocusNode.requestFocus();
      });
    }
  }

  Future<void> _verifyOtp(AuthNotifier authNotifier) async {
    final otp = _otpController.text.trim();
    if (!kBypassOtpValidation && otp.length != 6) {
      _showSnack('Please enter the 6-digit OTP.');
      return;
    }
    await authNotifier.verifyOtp(
      otp.isEmpty && kBypassOtpValidation ? '000000' : otp,
    );
  }

  Future<void> _pasteOtp() async {
    final data = await Clipboard.getData('text/plain');
    final raw = data?.text ?? '';
    final digits = raw.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) {
      _showSnack('No OTP found in clipboard.');
      return;
    }
    _otpController.text = digits.substring(
      0,
      digits.length >= 6 ? 6 : digits.length,
    );
    _otpController.selection = TextSelection.collapsed(
      offset: _otpController.text.length,
    );
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final authNotifier = ref.read(authNotifierProvider.notifier);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    ref.listen<AuthState>(authNotifierProvider, (previous, next) {
      final wasAuthenticated = previous?.isAuthenticated ?? false;
      if (!wasAuthenticated && next.isAuthenticated) {
        FocusManager.instance.primaryFocus?.unfocus();
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) {
            return;
          }
          Navigator.of(context).popUntil((route) => route.isFirst);
        });
      }
    });

    final isOtpStep = authState.isOtpSent;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: CrystalScaffold(
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Center(
              child: SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: EdgeInsets.fromLTRB(20, 20, 20, 24 + bottomInset),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: AppTheme.contentMaxWidth,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 8),
                      _buildHeader(context),
                      const SizedBox(height: 24),
                      Container(
                        padding: const EdgeInsets.all(22),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.94),
                          borderRadius: BorderRadius.circular(28),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.72),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.crystalGoldDeep.withValues(
                                alpha: 0.18,
                              ),
                              blurRadius: 24,
                              offset: const Offset(0, 12),
                            ),
                          ],
                        ),
                        child: isOtpStep
                            ? _buildOtpStep(context, authState, authNotifier)
                            : _buildPhoneStep(context, authState, authNotifier),
                      ),
                      const SizedBox(height: 18),
                      if (!isOtpStep)
                        Text(
                          'By continuing, you agree to our Terms and '
                          'Privacy Policy.',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: Colors.white.withValues(alpha: 0.84),
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
    );
  }

  Widget _buildHeader(BuildContext context) => Column(
    children: [
      Container(
        width: 74,
        height: 74,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            colors: [Color(0xAAFFFFFF), Color(0x66F0D58A)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(color: Colors.white.withValues(alpha: 0.45)),
        ),
        child: const Icon(Icons.shield_rounded, color: Colors.white, size: 34),
      ),
      const SizedBox(height: 14),
      GradientText(
        'Connect',
        style: Theme.of(context).textTheme.displayMedium!,
        gradient: const LinearGradient(
          colors: [Colors.white, Color(0xFFF8E3AA)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      const SizedBox(height: 6),
      Text(
        'Secure sign in with your mobile number.',
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: Colors.white.withValues(alpha: 0.9),
        ),
      ),
    ],
  );

  Widget _buildPhoneStep(
    BuildContext context,
    AuthState authState,
    AuthNotifier authNotifier,
  ) => KeyedSubtree(
    key: const ValueKey('phone-step'),
    child: AutofillGroup(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(context, 'Enter mobile number'),
          const SizedBox(height: 8),
          _sectionSubtitle(
            context,
            'We will send a one-time password to your mobile number for '
            'verification.',
          ),
          const SizedBox(height: 18),
          if (kUseMockAuth) ...[
            _infoBanner(
              context,
              'Mock mode active: enter any mobile number to continue.',
            ),
            const SizedBox(height: 14),
          ],
          TextField(
            controller: _phoneController,
            focusNode: _phoneFocusNode,
            autofocus: true,
            enabled: !authState.isLoading,
            keyboardType: TextInputType.phone,
            textInputAction: TextInputAction.done,
            enableInteractiveSelection: false,
            autofillHints: const [AutofillHints.telephoneNumber],
            onSubmitted: (_) => _sendOtp(authNotifier),
            onTapOutside: (_) => FocusManager.instance.primaryFocus?.unfocus(),
            style: Theme.of(context).textTheme.bodyLarge,
            decoration: _fieldDecoration(
              context,
              hintText: '+91 9876543210',
              prefixIcon: Icons.phone_iphone_rounded,
            ),
          ),
          if (authState.error != null) ...[
            const SizedBox(height: 14),
            _errorBanner(context, authState.error!),
          ],
          const SizedBox(height: 18),
          GlassButton(
            label: 'Send OTP to Mobile',
            icon: Icons.arrow_forward_rounded,
            shinyEffect: true,
            isLoading: authState.isLoading,
            onPressed: () => _sendOtp(authNotifier),
          ),
        ],
      ),
    ),
  );

  Widget _buildOtpStep(
    BuildContext context,
    AuthState authState,
    AuthNotifier authNotifier,
  ) {
    final targetPhone = _phoneController.text.trim().isEmpty
        ? (authState.phoneNumber ?? 'your mobile number')
        : _phoneController.text.trim();

    return KeyedSubtree(
      key: const ValueKey('otp-step'),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(context, 'Enter verification code'),
          const SizedBox(height: 8),
          _sectionSubtitle(context, 'Code sent to $targetPhone'),
          const SizedBox(height: 18),
          TextField(
            controller: _otpController,
            focusNode: _otpFocusNode,
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.done,
            enableInteractiveSelection: false,
            textAlign: TextAlign.center,
            autofillHints: const [AutofillHints.oneTimeCode],
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(6),
            ],
            onSubmitted: (_) => _verifyOtp(authNotifier),
            onTapOutside: (_) {
              FocusManager.instance.primaryFocus?.unfocus();
            },
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              letterSpacing: 8,
              fontWeight: FontWeight.w700,
            ),
            decoration: _fieldDecoration(
              context,
              hintText: '••••••',
              prefixIcon: Icons.lock_outline_rounded,
            ).copyWith(counterText: ''),
          ),
          const SizedBox(height: 10),
          Text(
            'Use the OTP received via SMS or paste it from the clipboard.',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppTheme.trustBlue),
          ),
          if (authState.error != null) ...[
            const SizedBox(height: 14),
            _errorBanner(context, authState.error!),
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _otpQuickAction(
                  context,
                  label: 'Paste OTP',
                  icon: Icons.content_paste_rounded,
                  onPressed: _pasteOtp,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _otpQuickAction(
                  context,
                  label: 'Resend',
                  icon: Icons.refresh_rounded,
                  onPressed: () => _sendOtp(authNotifier),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _otpQuickAction(
                  context,
                  label: 'Clear',
                  icon: Icons.close_rounded,
                  onPressed: () {
                    _otpController.clear();
                    authNotifier.clearError();
                  },
                ),
              ),
            ],
          ),
          if (kBypassOtpValidation) ...[
            const SizedBox(height: 8),
            _infoBanner(
              context,
              'Temporary OTP bypass is enabled for development.',
            ),
          ],
          if (kUseMockAuth) ...[
            const SizedBox(height: 8),
            _infoBanner(context, 'Mock mode active: any 6-digit OTP is valid.'),
          ],
          const SizedBox(height: 18),
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: _otpController,
            builder: (context, value, child) {
              final canVerify =
                  kBypassOtpValidation || value.text.trim().length == 6;
              return GlassButton(
                label: 'Verify & Continue',
                icon: Icons.verified_user_rounded,
                shinyEffect: true,
                isLoading: authState.isLoading,
                onPressed: canVerify ? () => _verifyOtp(authNotifier) : null,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _otpQuickAction(
    BuildContext context, {
    required String label,
    required IconData icon,
    required VoidCallback onPressed,
  }) => TextButton(
    onPressed: onPressed,
    style: Theme.of(context).textButtonTheme.style?.copyWith(
      padding: const WidgetStatePropertyAll<EdgeInsetsGeometry>(
        EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      ),
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
    ),
    child: FittedBox(
      fit: BoxFit.scaleDown,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 16),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    ),
  );

  Widget _sectionTitle(BuildContext context, String text) =>
      Text(text, style: Theme.of(context).textTheme.titleLarge);

  Widget _sectionSubtitle(BuildContext context, String text) =>
      Text(text, style: Theme.of(context).textTheme.bodyMedium);

  Widget _infoBanner(BuildContext context, String message) => Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    decoration: BoxDecoration(
      color: AppTheme.crystalGoldFog.withValues(alpha: 0.35),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(
        color: AppTheme.crystalGoldSoft.withValues(alpha: 0.3),
      ),
    ),
    child: Text(
      message,
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
        color: AppTheme.crystalGoldDeep,
        fontWeight: FontWeight.w600,
      ),
    ),
  );

  InputDecoration _fieldDecoration(
    BuildContext context, {
    required String hintText,
    required IconData prefixIcon,
  }) => InputDecoration(
    hintText: hintText,
    prefixIcon: Icon(prefixIcon, color: AppTheme.crystalGoldDeep),
    filled: true,
    fillColor: Colors.white.withValues(alpha: 0.96),
    contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(18),
      borderSide: BorderSide(
        color: AppTheme.crystalGoldSoft.withValues(alpha: 0.4),
      ),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(18),
      borderSide: BorderSide(
        color: AppTheme.crystalGoldSoft.withValues(alpha: 0.42),
      ),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(18),
      borderSide: const BorderSide(color: AppTheme.crystalGoldDeep, width: 1.4),
    ),
  );

  Widget _errorBanner(BuildContext context, String message) => Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    decoration: BoxDecoration(
      color: AppTheme.errorRed.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: AppTheme.errorRed.withValues(alpha: 0.35)),
    ),
    child: Text(
      message,
      style: Theme.of(
        context,
      ).textTheme.bodySmall?.copyWith(color: AppTheme.errorRed),
    ),
  );
}
