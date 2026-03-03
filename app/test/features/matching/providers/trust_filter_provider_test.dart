import 'package:flutter_test/flutter_test.dart';
import 'package:verified_dating_app/features/matching/providers/trust_filter_provider.dart';

void main() {
  group('TrustFilterState', () {
    test('hasActiveFilter false when disabled', () {
      const state = TrustFilterState(
        enabled: false,
        minimumActiveBadges: 2,
        requiredBadgeCodes: <String>['verified_active'],
      );

      expect(state.hasActiveFilter, isFalse);
    });

    test('hasActiveFilter true when enabled with minimum badges', () {
      const state = TrustFilterState(enabled: true, minimumActiveBadges: 1);

      expect(state.hasActiveFilter, isTrue);
    });

    test('hasActiveFilter true when enabled with required badges', () {
      const state = TrustFilterState(
        enabled: true,
        requiredBadgeCodes: <String>['respectful_communicator'],
      );

      expect(state.hasActiveFilter, isTrue);
    });

    test('hasActiveFilter false when enabled but no criteria selected', () {
      const state = TrustFilterState(enabled: true, minimumActiveBadges: 0);

      expect(state.hasActiveFilter, isFalse);
    });

    test('copyWith clearError removes failure message', () {
      const errored = TrustFilterState(error: 'save failed');
      final updated = errored.copyWith(clearError: true);

      expect(errored.error, isNotNull);
      expect(updated.error, isNull);
    });

    test('copyWith replaces trust criteria values', () {
      const initial = TrustFilterState(enabled: false);
      final updated = initial.copyWith(
        enabled: true,
        minimumActiveBadges: 2,
        requiredBadgeCodes: <String>['verified_active'],
      );

      expect(updated.enabled, isTrue);
      expect(updated.minimumActiveBadges, 2);
      expect(updated.requiredBadgeCodes, <String>['verified_active']);
    });
  });
}
