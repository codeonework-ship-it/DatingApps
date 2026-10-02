import '../../l10n/app_localizations.dart';
import 'providers/auth_provider.dart';

/// Shows an [AuthState.error] in the member's language.
///
/// The auth provider keeps its own messages as stable English codes (tests,
/// automation and the session-end listener compare against them). Those are
/// translated here; anything else came from the server and is shown as is.
String localizedAuthMessage(AppLocalizations l10n, String message) =>
    switch (message) {
      kSessionExpiredMessage => l10n.authErrorSessionExpired,
      kAuthSignInFailedMessage => l10n.authErrorSignInFailed,
      kAuthCreateAccountFailedMessage => l10n.authErrorCreateAccountFailed,
      kAuthCreateAccountGenericMessage => l10n.authErrorCreateAccountGeneric,
      kAuthInvalidCredentialsMessage => l10n.authErrorInvalidCredentials,
      kAuthUsernameFormatMessage => l10n.authErrorUsernameFormat,
      kAuthEnterPasswordMessage => l10n.authEnterPassword,
      kAuthPasswordFormatMessage => l10n.authErrorPasswordFormat,
      _ => message,
    };
