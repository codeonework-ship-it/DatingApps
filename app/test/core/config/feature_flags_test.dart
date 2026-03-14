import 'package:flutter_test/flutter_test.dart';
import 'package:verified_dating_app/core/config/feature_flags.dart';

void main() {
  group('feature flags', () {
    test('defines capability flags for Story 7.2 rollout', () {
      expect(kFeatureEngagementUnlockMvp, isA<bool>());
      expect(kFeatureDigitalGestures, isA<bool>());
      expect(kFeatureMiniActivities, isA<bool>());
      expect(kFeatureTrustBadges, isA<bool>());
      expect(kFeatureConversationRooms, isA<bool>());
    });

    test('defines auth/discovery mock controls', () {
      expect(kUseMockAuth, isA<bool>());
      expect(kUseMockDiscoveryData, isA<bool>());
      expect(kBypassOtpValidation, isA<bool>());
    });

    test('keeps OTP bypass disabled by default', () {
      expect(kBypassOtpValidation, isFalse);
    });
  });
}
