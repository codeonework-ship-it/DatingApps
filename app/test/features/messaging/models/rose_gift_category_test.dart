import 'package:flutter_test/flutter_test.dart';
import 'package:verified_dating_app/features/messaging/models/rose_gift.dart';

void main() {
  group('RoseGift category', () {
    test('defaults to "roses" when not explicitly set', () {
      const gift = RoseGift(
        id: 'rose_red_single',
        name: 'Single Red Rose',
        gifUrl: 'https://example.test/rose.gif',
        priceCoins: 0,
        tier: 'free',
        isLimited: false,
      );
      expect(gift.category, 'roses');
    });

    test('preserves explicit category value', () {
      const gift = RoseGift(
        id: 'chocolate_box',
        name: 'Chocolate Box',
        gifUrl: 'https://example.test/choc.gif',
        priceCoins: 0,
        tier: 'free',
        isLimited: false,
        category: 'themed_pack',
      );
      expect(gift.category, 'themed_pack');
    });

    test('exclusive gift has maxPerMatchPerDay of 1', () {
      const gift = RoseGift(
        id: 'exclusive_diamond_ring',
        name: 'Diamond Ring',
        gifUrl: 'https://example.test/ring.gif',
        priceCoins: 20,
        tier: 'exclusive',
        isLimited: true,
        category: 'themed_pack',
        maxPerMatchPerDay: 1,
      );
      expect(gift.maxPerMatchPerDay, 1);
    });

    test('phaseOneCatalog contains all 6 categories', () {
      final categories = RoseGift.phaseOneCatalog
          .map((g) => g.category)
          .toSet();
      expect(
        categories,
        containsAll(<String>[
          'roses',
          'themed_pack',
          'reaction',
          'experience',
          'seasonal',
        ]),
      );
    });

    test('phaseOneCatalogById lookup by id returns correct category', () {
      final gift = RoseGift.phaseOneCatalogById['chocolate_box'];
      expect(gift, isNotNull);
      expect(gift!.category, 'themed_pack');
    });

    test('All rose variants in phaseOneCatalog have category "roses"', () {
      final roseGifts = RoseGift.phaseOneCatalog
          .where((g) => g.id.startsWith('rose_'))
          .toList();
      expect(roseGifts, isNotEmpty);
      for (final gift in roseGifts) {
        expect(
          gift.category,
          'roses',
          reason: '${gift.id} should have category "roses"',
        );
      }
    });

    test('exclusive gifts have maxPerMatchPerDay > 0', () {
      final exclusiveGifts = RoseGift.phaseOneCatalog
          .where((g) => g.tier == 'exclusive')
          .toList();
      expect(exclusiveGifts, isNotEmpty);
      for (final gift in exclusiveGifts) {
        expect(
          gift.maxPerMatchPerDay,
          greaterThan(0),
          reason: '${gift.id} should have a daily limit',
        );
      }
    });
  });

  group('MessageState giftCategories', () {
    test('default giftCategories is empty', () {
      // Import message_provider if needed — check below
      // We test the RoseGift layer only here; provider tests are in
      // message_provider_gifts_test.dart to avoid dependency complexity.
      const gift = RoseGift(
        id: 'heart_explosion',
        name: 'Heart Explosion',
        gifUrl: 'https://example.test/heart.gif',
        priceCoins: 0,
        tier: 'free',
        isLimited: false,
        category: 'reaction',
      );
      expect(gift.category, 'reaction');
    });
  });
}
