import 'dart:ui';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verified_dating_app/core/i18n/app_l10n.dart';
import 'package:verified_dating_app/features/payment/providers/payment_error.dart';
import 'package:verified_dating_app/features/payment/screens/payment_l10n.dart';
import 'package:verified_dating_app/l10n/app_localizations_de.dart';

void main() {
  final request = RequestOptions(path: '/billing/checkout');

  test('a local failure keeps the English text and a translatable code', () {
    final failure = paymentFailure(
      const FormatException('Missing checkout'),
      PaymentErrorCode.startCheckoutNow,
    );
    expect(failure.message, 'Unable to start checkout right now.');
    expect(failure.code, PaymentErrorCode.startCheckoutNow);
    expect(
      paymentErrorText(AppLocalizationsDe(), failure.code, failure.message),
      'Der Checkout kann gerade nicht gestartet werden.',
    );
  });

  DioException serverError() => DioException(
    requestOptions: request,
    response: Response<dynamic>(
      requestOptions: request,
      statusCode: 409,
      data: {'error': 'a paid subscription is already live'},
    ),
  );

  test('in English a server message is shown as sent, without a code '
      '[case:l10n.payment_errors.server_text_english]', () {
    setCurrentAppLocale(const Locale('en'));
    addTearDown(() => setCurrentAppLocale(null));
    final failure = paymentFailure(
      serverError(),
      PaymentErrorCode.startCheckoutNow,
    );
    expect(failure.message, 'a paid subscription is already live');
    expect(failure.code, isNull);
  });

  test('in German unknown server text falls back to the translated fallback '
      '[case:l10n.payment_errors.server_text_german]', () {
    setCurrentAppLocale(const Locale('de'));
    addTearDown(() => setCurrentAppLocale(null));
    final failure = paymentFailure(
      serverError(),
      PaymentErrorCode.startCheckoutNow,
    );
    expect(failure.code, PaymentErrorCode.startCheckoutNow);
    expect(
      paymentErrorText(AppLocalizationsDe(), failure.code, failure.message),
      'Der Checkout kann gerade nicht gestartet werden.',
    );
  });

  test('an unreachable API maps to the unreachable code', () {
    final failure = paymentFailure(
      DioException(
        requestOptions: request,
        type: DioExceptionType.connectionError,
      ),
      PaymentErrorCode.loadWallet,
    );
    expect(failure.code, PaymentErrorCode.unreachable);
    expect(
      paymentErrorText(AppLocalizationsDe(), failure.code, failure.message),
      AppLocalizationsDe().networkOfflineTryAgain,
    );
  });
}
