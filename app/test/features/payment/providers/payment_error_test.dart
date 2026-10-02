import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
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

  test('a server message is shown as sent, without a code', () {
    final failure = paymentFailure(
      DioException(
        requestOptions: request,
        response: Response<dynamic>(
          requestOptions: request,
          statusCode: 409,
          data: {'error': 'a paid subscription is already live'},
        ),
      ),
      PaymentErrorCode.startCheckoutNow,
    );
    expect(failure.message, 'a paid subscription is already live');
    expect(failure.code, isNull);
    expect(
      paymentErrorText(AppLocalizationsDe(), failure.code, failure.message),
      'a paid subscription is already live',
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
  });
}
