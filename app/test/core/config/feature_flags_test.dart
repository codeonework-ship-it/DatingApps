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
      expect(kEnableQaAutomation, isA<bool>());
    });

    test('keeps QA automation helpers off unless a build opts in', () {
      // This flag gates automation-only surfaces — most visibly the "QA
      // Verification Upload" entry in Settings — so a default of `true` puts
      // them in front of real members. It previously defaulted to `true` and
      // this test asserted that, which locked the leak in place.
      //
      // The Appium runner opts in explicitly with
      // `--dart-define=ENABLE_QA_AUTOMATION=true`, so nothing in the suite
      // depends on the default.
      expect(kEnableQaAutomation, isFalse);
    });
  });
}
