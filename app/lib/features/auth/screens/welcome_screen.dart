import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/connect_brand.dart';
import '../../../l10n/app_localizations.dart';
import 'auth_screen.dart';
import 'signup_screen.dart';

/// First screen. Follows the member's theme the way Today does: flat theme
/// ground, serif headline, one filled call to action.
///
/// Campaign photography is illustrative, never a member profile.
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) => AnnotatedRegion<SystemUiOverlayStyle>(
    value: Theme.of(context).brightness == Brightness.dark
        ? SystemUiOverlayStyle.light
        : SystemUiOverlayStyle.dark,
    child: Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        children: [
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final wide = constraints.maxWidth >= 720;
                return SingleChildScrollView(
                  padding: EdgeInsets.symmetric(
                    horizontal: wide ? 40 : 24,
                    vertical: 20,
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1040),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Row(
                            children: [
                              Expanded(
                                flex: 3,
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  alignment: Alignment.centerLeft,
                                  child: ConnectBrand(),
                                ),
                              ),
                              SizedBox(width: 16),
                              Expanded(flex: 2, child: _Tagline()),
                            ],
                          ),
                          SizedBox(height: wide ? 40 : 22),
                          if (wide)
                            const Row(
                              children: [
                                Expanded(child: _WelcomePhoto(height: 560)),
                                SizedBox(width: 48),
                                Expanded(child: _WelcomeInvitation(wide: true)),
                              ],
                            )
                          else ...[
                            _WelcomePhoto(
                              height: (constraints.maxHeight * .37).clamp(
                                200,
                                330,
                              ),
                            ),
                            const SizedBox(height: 26),
                            const _WelcomeInvitation(wide: false),
                          ],
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    ),
  );
}

class _Tagline extends StatelessWidget {
  const _Tagline();

  @override
  Widget build(BuildContext context) => Text(
    AppLocalizations.of(context).welcomeTagline,
    textAlign: TextAlign.right,
    style: AppTheme.technical(
      11,
      Theme.of(context).colorScheme.onSurfaceVariant,
      letterSpacing: 1.4,
    ).copyWith(fontWeight: FontWeight.w600),
  );
}

class _WelcomePhoto extends StatelessWidget {
  const _WelcomePhoto({required this.height});
  final double height;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: height,
    child: Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppTheme.radiusL),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppTheme.radiusL),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              'assets/images/connect-cafe.png',
              fit: BoxFit.cover,
              alignment: const Alignment(0, -.35),
              excludeFromSemantics: true,
            ),
            // Scrim at the foot so the white chip stays legible over the
            // photo in every theme.
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0x00120A18),
                    Color(0x00120A18),
                    Color(0x99120A18),
                  ],
                  stops: [0, 0.55, 1],
                ),
              ),
            ),
            Positioned.fill(
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(AppTheme.radiusL),
                    border: Border.all(
                      color: Theme.of(context).colorScheme.outlineVariant,
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 16,
              left: 16,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  // Dark glass so the white label holds contrast on any
                  // photo, and on the light ground before the photo loads.
                  color: Colors.black.withValues(alpha: 0.55),
                  borderRadius: const BorderRadius.all(Radius.circular(30)),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.22),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.north_east_rounded,
                        size: 15,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        AppLocalizations.of(context).welcomePhotoNote,
                        style: const TextStyle(
                          color: AppTheme.inkOnDark,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
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

class _WelcomeInvitation extends StatelessWidget {
  const _WelcomeInvitation({required this.wide});
  final bool wide;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final headline = AppTheme.display(
      wide ? 54 : 42,
      scheme.onSurface,
      height: 1.02,
      tracking: -0.015,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        RichText(
          text: TextSpan(
            style: headline,
            children: [
              TextSpan(text: l10n.welcomeHeadlineLead),
              WidgetSpan(
                alignment: PlaceholderAlignment.baseline,
                baseline: TextBaseline.alphabetic,
                child: Text(
                  l10n.welcomeHeadlineAccent,
                  style: headline.copyWith(
                    fontStyle: FontStyle.italic,
                    color: scheme.primary,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Text(
          l10n.welcomeBody,
          style: TextStyle(
            fontSize: 15,
            height: 1.5,
            color: scheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 26),
        Semantics(
          label: 'qa.welcome.signup_button',
          button: true,
          child: _EmberCta(
            key: const ValueKey('qa.welcome.signup_button'),
            label: l10n.welcomeCreateAccount,
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const SignupScreen()),
            ),
          ),
        ),
        TextButton.icon(
          key: const ValueKey('qa.welcome.introducer_button'),
          icon: const Icon(Icons.people_outline),
          label: Text(l10n.authWelcomeIntroducerLink),
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => const SignupScreen(introducer: true),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Semantics(
          label: 'qa.welcome.signin_button',
          button: true,
          child: TextButton(
            key: const ValueKey('qa.welcome.signin_button'),
            style: TextButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
              foregroundColor: scheme.onSurface,
            ),
            onPressed: () => Navigator.of(
              context,
            ).push(MaterialPageRoute<void>(builder: (_) => const AuthScreen())),
            child: RichText(
              text: TextSpan(
                style: TextStyle(
                  fontFamily: AppTheme.uiFamily,
                  fontSize: 14,
                  color: scheme.onSurfaceVariant,
                ),
                children: [
                  TextSpan(text: l10n.welcomeAlreadyMember),
                  TextSpan(
                    text: l10n.welcomeSignIn,
                    style: TextStyle(
                      color: scheme.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          l10n.welcomeFooter,
          textAlign: TextAlign.center,
          style: AppTheme.technical(
            10.5,
            scheme.onSurfaceVariant,
            letterSpacing: 1.2,
            weight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

/// The one filled button on the screen, in the theme's primary colour.
class _EmberCta extends StatelessWidget {
  const _EmberCta({required this.label, required this.onPressed, super.key});
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: Colors.transparent,
      child: Ink(
        decoration: BoxDecoration(
          color: scheme.primary,
          borderRadius: BorderRadius.circular(999),
        ),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(999),
          child: SizedBox(
            height: 58,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      label,
                      style: TextStyle(
                        fontFamily: AppTheme.uiFamily,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.2,
                        color: scheme.onPrimary,
                      ),
                    ),
                  ),
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: scheme.onPrimary.withValues(alpha: 0.18),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.arrow_forward_rounded,
                      color: scheme.onPrimary,
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
