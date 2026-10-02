import '../../l10n/app_localizations.dart';
import 'providers/call_provider.dart';

/// The call error to show in the reader's language: the localized message
/// for a known failure, otherwise the server's own text.
String? callErrorText(AppLocalizations l, CallState state) =>
    switch (state.errorKind) {
      CallErrorKind.signInForHistory => l.callsErrorSignInHistory,
      CallErrorKind.signInToCall => l.callsErrorSignInStart,
      CallErrorKind.permissions => l.callsErrorPermissions,
      CallErrorKind.loadHistory => l.callsErrorLoadHistory,
      CallErrorKind.start => l.callsErrorStart,
      CallErrorKind.end => l.callsErrorEnd,
      CallErrorKind.notConfigured => l.callsErrorNotConfigured,
      CallErrorKind.openRoom => l.callsErrorOpenRoom,
      null => state.error,
    };
