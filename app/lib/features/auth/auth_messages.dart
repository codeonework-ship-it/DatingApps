import '../../l10n/app_localizations.dart';
import 'providers/auth_provider.dart';

/// Shows an [AuthState.error] in the member's language.
///
/// The auth provider keeps its messages as stable English codes
/// ([kAuthMessageCodes]; tests, automation and the session-end listener
/// compare against them) and maps every server reply to one of them
/// (`authMessageCodeForServerError`). Those codes are translated here.
/// Anything else is never shown raw: it reads as the generic failure.
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
      kAuthUsernameTakenMessage => l10n.authErrorUsernameTaken,
      kAuthAccountSuspendedMessage => l10n.authErrorAccountSuspended,
      kAuthAccountLockedMessage => l10n.authErrorAccountLocked,
      kAuthTooManyRequestsMessage => l10n.authErrorTooManyRequests,
      kAuthAccountTypeUnavailableMessage =>
        l10n.authErrorAccountTypeUnavailable,
      kAuthAgeRangeMessage => l10n.signupErrorAgeRange,
      kAuthNetworkMessage => l10n.authErrorNetwork,
      _ => l10n.commonSomethingWentWrongTryAgain,
    };
