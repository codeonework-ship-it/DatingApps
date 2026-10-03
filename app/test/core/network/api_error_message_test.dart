import 'dart:ui';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verified_dating_app/core/i18n/app_l10n.dart';
import 'package:verified_dating_app/core/network/api_error_message.dart';
import 'package:verified_dating_app/l10n/app_localizations.dart';

final _request = RequestOptions(path: '/chat/m1/copilot/drafts');

DioException _server(int status, Map<String, dynamic> body) => DioException(
  requestOptions: _request,
  type: DioExceptionType.badResponse,
  response: Response<dynamic>(
    requestOptions: _request,
    statusCode: status,
    data: body,
  ),
);

void _useLocale(Locale locale) {
  setCurrentAppLocale(locale);
  addTearDown(() => setCurrentAppLocale(null));
}

void main() {
  final de = lookupAppLocalizations(const Locale('de'));
  final en = lookupAppLocalizations(const Locale('en'));

  test('a known error_code maps to the German message '
      '[case:l10n.api_errors.known_code_german]', () {
    _useLocale(const Locale('de'));
    final message = apiErrorMessage(
      _server(429, {
        'error': "you have used today's drafts; write this one yourself",
        'error_code': 'COPILOT_DAILY_LIMIT_REACHED',
      }),
      fallback: de.commonRetry,
    );
    expect(message, de.apiErrorCopilotDailyLimit);
    expect(message, isNot(contains('drafts')));
  });

  test('a known error_code is translated in English too, not the server text '
      '[case:l10n.api_errors.known_code_english]', () {
    _useLocale(const Locale('en'));
    expect(
      apiErrorMessage(
        _server(403, {
          'error': 'feature is not part of this release',
          'error_code': 'FEATURE_EXCLUDED_FROM_RELEASE',
        }),
        fallback: 'Fallback',
      ),
      en.apiErrorFeatureUnavailable,
    );
  });

  test('unknown server text in German falls back to the caller fallback '
      '[case:l10n.api_errors.unknown_text_german]', () {
    _useLocale(const Locale('de'));
    expect(
      apiErrorMessage(
        _server(409, {
          'error': 'You already reported this photo.',
          'error_code': 'CONFLICT',
        }),
        fallback: 'Konnte nicht gemeldet werden.',
      ),
      'Konnte nicht gemeldet werden.',
    );
  });

  test('English shows the server message, trimmed '
      '[case:l10n.api_errors.english_server_text]', () {
    _useLocale(const Locale('en', 'GB'));
    expect(
      apiErrorMessage(
        _server(409, {
          'error': '  You already reported this photo.  ',
          'error_code': 'CONFLICT',
        }),
        fallback: 'Could not report.',
      ),
      'You already reported this photo.',
    );
  });

  for (final technical in [
    'pq: duplicate key value violates unique constraint "blog_pkey"',
    'load profile failed: query rows: context deadline exceeded',
    'dial tcp 127.0.0.1:55433: connect: connection refused',
    'DioException [bad response]: null',
    'rpc error: code = Unavailable desc = upstream connect error',
    'json: cannot unmarshal string into Go struct field',
    'invalid %!s(MISSING) value',
    'for_user_id must be a uuid',
    '{"detail":"boom"}',
  ]) {
    test('technical server text in English uses the fallback: $technical '
        '[case:l10n.api_errors.technical_english]', () {
      _useLocale(const Locale('en'));
      expect(
        apiErrorMessage(
          _server(400, {'error': technical, 'error_code': 'BAD_REQUEST'}),
          fallback: 'Could not save.',
        ),
        'Could not save.',
      );
    });
  }

  test('a 5xx with technical text uses the fallback in English '
      '[case:l10n.api_errors.5xx_english]', () {
    _useLocale(const Locale('en'));
    expect(
      apiErrorMessage(
        _server(503, {
          'error': 'friend_social persistence is unavailable',
          'error_code': 'SERVICE_UNAVAILABLE',
        }),
        fallback: 'Could not load vouches.',
      ),
      'Could not load vouches.',
    );
  });

  test('TOO_MANY_REQUESTS without usable text maps to the generic wait message '
      '[case:l10n.api_errors.too_many_requests_german]', () {
    _useLocale(const Locale('de'));
    expect(
      apiErrorMessage(
        _server(429, {
          'error': 'rate limit exceeded',
          'error_code': 'TOO_MANY_REQUESTS',
        }),
        fallback: 'Fehler',
      ),
      de.apiErrorTooManyTries,
    );
  });

  test('a status-derived BAD_REQUEST keeps the caller fallback in German '
      '[case:l10n.api_errors.generic_code_keeps_fallback]', () {
    _useLocale(const Locale('de'));
    expect(
      apiErrorMessage(
        _server(400, {'error': 'Invalid cursor', 'error_code': 'BAD_REQUEST'}),
        fallback: 'Konnte nicht geladen werden.',
      ),
      'Konnte nicht geladen werden.',
    );
  });

  test('an empty fallback stays empty for unknown server text in German '
      '(callers use this to pick their own translated message) '
      '[case:l10n.api_errors.empty_fallback_german]', () {
    _useLocale(const Locale('de'));
    expect(
      apiErrorMessage(
        _server(409, {'error': 'date plan is no longer open'}),
        fallback: '',
      ),
      isEmpty,
    );
  });

  test('a connection failure maps to the translated offline message '
      '[case:l10n.api_errors.offline_german]', () {
    _useLocale(const Locale('de'));
    expect(
      apiErrorMessage(
        DioException(
          requestOptions: _request,
          type: DioExceptionType.connectionError,
        ),
        fallback: 'Fehler',
      ),
      de.networkOfflineTryAgain,
    );
  });

  test('a non-network error returns the fallback '
      '[case:l10n.api_errors.non_network_error]', () {
    _useLocale(const Locale('de'));
    expect(apiErrorMessage(StateError('boom'), fallback: 'Fehler'), 'Fehler');
  });

  test('currentAppLocaleIsEnglish follows the app locale '
      '[case:l10n.api_errors.locale_accessor]', () {
    _useLocale(const Locale('en', 'GB'));
    expect(currentAppLocaleIsEnglish(), isTrue);
    setCurrentAppLocale(const Locale('pl'));
    expect(currentAppLocaleIsEnglish(), isFalse);
  });

  test('friendly English sentences are not flagged as technical '
      '[case:l10n.api_errors.friendly_not_technical]', () {
    for (final friendly in [
      'You already reported this photo.',
      'Select a photo from your gallery to set as your cover.',
      'This room is full right now. Try again in a little while.',
    ]) {
      expect(looksLikeTechnicalErrorText(friendly), isFalse, reason: friendly);
    }
  });
}
