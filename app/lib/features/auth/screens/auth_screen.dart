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
  final _emailController = TextEditingController();
  final _otpController = TextEditingController();
  final _emailFocusNode = FocusNode();
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
    _emailController.dispose();
    _otpController.dispose();
    _emailFocusNode.dispose();
    _otpFocusNode.dispose();
    super.dispose();
  }

  Future<void> _sendOtp(AuthNotifier authNotifier) async {
    final mobileNumber = _emailController.text.trim();
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
    if (!mounted) return;

    final currentState = ref.read(authNotifierProvider);
    if (currentState.isOtpSent) {
      _otpController.clear();
      _otpFocusNode.requestFocus();
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

    ref.listen<AuthState>(authNotifierProvider, (previous, next) {
      final wasAuthenticated = previous?.isAuthenticated ?? false;
      if (!wasAuthenticated && next.isAuthenticated) {
        FocusManager.instance.primaryFocus?.unfocus();
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          Navigator.of(context).popUntil((route) => route.isFirst);
        });
      }
    });

    final isOtpStep = authState.isOtpSent;

    return Scaffold(
      body: CrystalScaffold(
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: LayoutBuilder(
              builder: (context, constraints) => SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 20,
                ),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight - 40,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 12),
                      _buildHeader(context),
                      const SizedBox(height: 26),
                      GlassContainer(
                        padding: const EdgeInsets.all(22),
                        borderRadius: BorderRadius.circular(26),
                        blur: AppTheme.glassBlurThick,
                        opacity: AppTheme.glassLayerThickOpacity,
                        backgroundColor: Colors.white.withValues(alpha: 0.88),
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 220),
                          switchInCurve: Curves.easeOut,
                          switchOutCurve: Curves.easeIn,
                          child: isOtpStep
                              ? _buildOtpStep(context, authState, authNotifier)
                              : _buildPhoneStep(
                                  context,
                                  authState,
                                  authNotifier,
                                ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Padding(
                        padding: const EdgeInsets.only(top: 18),
                        child: Text(
                          'By continuing, you agree to our Terms and Privacy Policy.',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: Colors.white.withValues(alpha: 0.8),
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
    );
  }

  Widget _buildHeader(BuildContext context) => Column(
    children: [
      Container(
        width: 70,
        height: 70,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            colors: [Color(0x99FFFFFF), Color(0x66D6EBFF)],
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
          colors: [Colors.white, Color(0xFFD9EEFF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      const SizedBox(height: 6),
      Text(
        'Secure sign in with your mobile number',
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
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Enter mobile number',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        Text(
          'We will send a one-time password to your mobile number for verification.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 18),
        if (kUseMockAuth) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: AppTheme.trustBlue.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppTheme.trustBlue.withValues(alpha: 0.24),
              ),
            ),
            child: Text(
              'Mock mode active: enter any mobile number to continue.',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppTheme.trustBlue),
            ),
          ),
          const SizedBox(height: 14),
        ],
        _glassFieldShell(
          child: TextField(
            controller: _emailController,
            focusNode: _emailFocusNode,
            keyboardType: TextInputType.phone,
            textInputAction: TextInputAction.done,
            autofillHints: const [AutofillHints.telephoneNumber],
            style: Theme.of(context).textTheme.bodyLarge,
            decoration: const InputDecoration(
              hintText: '+91 9876543210',
              prefixIcon: Icon(Icons.phone_iphone_rounded),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 16,
              ),
            ),
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
          isLoading: authState.isLoading,
          onPressed: () => _sendOtp(authNotifier),
          backgroundColor: AppTheme.trustBlue,
        ),
      ],
    ),
  );

  Widget _buildOtpStep(
    BuildContext context,
    AuthState authState,
    AuthNotifier authNotifier,
  ) {
    final targetPhone = _emailController.text.trim().isEmpty
        ? (authState.email ?? 'your mobile number')
        : _emailController.text.trim();

    return KeyedSubtree(
      key: const ValueKey('otp-step'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Enter verification code',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'Code sent to $targetPhone',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 16),
          _glassFieldShell(
            child: TextField(
              controller: _otpController,
              focusNode: _otpFocusNode,
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.done,
              maxLength: 6,
              autofillHints: const [AutofillHints.oneTimeCode],
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              onChanged: (_) => setState(() {}),
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                letterSpacing: 10,
                fontWeight: FontWeight.w700,
              ),
              decoration: const InputDecoration(
                hintText: '••••••',
                counterText: '',
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 14,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                Icons.mark_email_read_rounded,
                size: 14,
                color: AppTheme.trustBlue.withValues(alpha: 0.8),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Use the OTP received via SMS or paste from clipboard.',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: AppTheme.trustBlue),
                ),
              ),
            ],
          ),
          if (authState.error != null) ...[
            const SizedBox(height: 14),
            _errorBanner(context, authState.error!),
          ],
          const SizedBox(height: 14),
          Row(
            children: [
              TextButton.icon(
                onPressed: _pasteOtp,
                icon: const Icon(Icons.content_paste_rounded, size: 18),
                label: const Text('Paste OTP'),
              ),
              const SizedBox(width: 8),
              TextButton(
                onPressed: () => _sendOtp(authNotifier),
                child: const Text('Resend'),
              ),
              const Spacer(),
              TextButton(
                onPressed: () {
                  _otpController.clear();
                  authNotifier.clearError();
                  setState(() {});
                },
                child: const Text('Clear'),
              ),
            ],
          ),
          if (kBypassOtpValidation) ...[
            const SizedBox(height: 6),
            Text(
              'Temporary OTP bypass is enabled for development.',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppTheme.trustBlue),
            ),
          ],
          const SizedBox(height: 6),
          if (kUseMockAuth) ...[
            Text(
              'Mock mode active: any 6-digit OTP is valid.',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppTheme.trustBlue),
            ),
            const SizedBox(height: 8),
          ],
          GlassButton(
            label: 'Verify & Continue',
            icon: Icons.verified_user_rounded,
            isLoading: authState.isLoading,
            onPressed: (kBypassOtpValidation || _otpController.text.length == 6)
                ? () => _verifyOtp(authNotifier)
                : null,
            backgroundColor: AppTheme.trustBlue,
          ),
          const SizedBox(height: 8),
          Center(
            child: TextButton(
              onPressed: () {
                _otpController.clear();
                authNotifier.backToIdentifierEntry();
                setState(_emailFocusNode.requestFocus);
              },
              child: const Text('Change mobile number'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _glassFieldShell({required Widget child}) => GlassContainer(
    padding: EdgeInsets.zero,
    blur: AppTheme.glassBlurRegular,
    opacity: AppTheme.glassLayerRegularOpacity,
    borderRadius: BorderRadius.circular(16),
    backgroundColor: Colors.white.withValues(alpha: 0.72),
    border: Border.all(color: Colors.white.withValues(alpha: 0.45)),
    child: child,
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
