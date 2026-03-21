class RoseGift {
  const RoseGift({
    required this.id,
    required this.name,
    required this.gifUrl,
    required this.priceCoins,
    required this.tier,
    required this.isLimited,
    this.iconKey,
    this.assetPath,
  });

  final String id;
  final String name;
  final String gifUrl;
  final String? iconKey;
  final String? assetPath;
  final int priceCoins;
  final String tier;
  final bool isLimited;

  bool get isFree => priceCoins <= 0;

  static final Map<String, RoseGift> phaseOneCatalogById = {
    for (final gift in phaseOneCatalog) gift.id: gift,
  };

  static String resolveAssetPathById(String? giftId) {
    final normalizedId = (giftId ?? '').trim();
    if (normalizedId.isEmpty) {
      return '';
    }
    return (phaseOneCatalogById[normalizedId]?.assetPath ?? '').trim();
  }

  static String resolvePreferredGifPathById(
    String? giftId, {
    String? fallbackUrl,
  }) {
    final assetPath = resolveAssetPathById(giftId);
    if (assetPath.isNotEmpty) {
      return assetPath;
    }
    return (fallbackUrl ?? '').trim();
  }

  static String resolveGifUrlById(String? giftId, {String? fallbackUrl}) {
    final normalizedId = (giftId ?? '').trim();
    if (normalizedId.isNotEmpty) {
      final matched = phaseOneCatalogById[normalizedId];
      if (matched != null && matched.gifUrl.isNotEmpty) {
        return matched.gifUrl;
      }
    }
    return (fallbackUrl ?? '').trim();
  }

  static const List<RoseGift> phaseOneCatalog = [
    RoseGift(
      id: 'rose_red_single',
      name: 'Single Red Rose',
      gifUrl: 'https://media.giphy.com/media/26xBwdIuRJiAIqHwA/giphy.gif',
      iconKey: 'rose_red',
      assetPath: 'assets/images/gifts/rose_red_single.gif',
      priceCoins: 0,
      tier: 'free',
      isLimited: false,
    ),
    RoseGift(
      id: 'rose_pink_soft',
      name: 'Pink Rose',
      gifUrl: 'https://media.giphy.com/media/fVtcfEXWQJQUbsF1sH/giphy.gif',
      iconKey: 'rose_pink',
      assetPath: 'assets/images/gifts/rose_pink_soft.gif',
      priceCoins: 0,
      tier: 'free',
      isLimited: false,
    ),
    RoseGift(
      id: 'rose_white_pure',
      name: 'White Rose',
      gifUrl: 'https://media.giphy.com/media/xT1XGzAnABSXy8DPCU/giphy.gif',
      iconKey: 'rose_white',
      assetPath: 'assets/images/gifts/rose_white_pure.gif',
      priceCoins: 0,
      tier: 'free',
      isLimited: false,
    ),
    RoseGift(
      id: 'rose_yellow_friendship',
      name: 'Yellow Rose',
      gifUrl: 'https://media.giphy.com/media/l0Iy5tjhyfU1xL9wQ/giphy.gif',
      iconKey: 'rose_yellow',
      assetPath: 'assets/images/gifts/rose_yellow_friendship.gif',
      priceCoins: 0,
      tier: 'free',
      isLimited: false,
    ),
    RoseGift(
      id: 'rose_lavender_crush',
      name: 'Lavender Rose',
      gifUrl: 'https://media.giphy.com/media/26xBukhL8Y5H9P9VS/giphy.gif',
      iconKey: 'rose_lavender',
      assetPath: 'assets/images/gifts/rose_lavender_crush.gif',
      priceCoins: 0,
      tier: 'free',
      isLimited: false,
    ),
    RoseGift(
      id: 'rose_blue_rare',
      name: 'Blue Rose',
      gifUrl: 'https://media.giphy.com/media/3oz8xAFtqoOUUrsh7W/giphy.gif',
      iconKey: 'rose_blue',
      assetPath: 'assets/images/gifts/rose_blue_rare.gif',
      priceCoins: 1,
      tier: 'premium_common',
      isLimited: false,
    ),
    RoseGift(
      id: 'rose_black_mystery',
      name: 'Black Rose',
      gifUrl: 'https://media.giphy.com/media/l0ExncehJzexFpRHq/giphy.gif',
      iconKey: 'rose_black',
      assetPath: 'assets/images/gifts/rose_black_mystery.gif',
      priceCoins: 1,
      tier: 'premium_common',
      isLimited: false,
    ),
    RoseGift(
      id: 'rose_sparkle',
      name: 'Sparkle Rose',
      gifUrl: 'https://media.giphy.com/media/3o7TKz9b9NQwQ2N8hW/giphy.gif',
      iconKey: 'rose_sparkle',
      assetPath: 'assets/images/gifts/rose_sparkle.gif',
      priceCoins: 3,
      tier: 'premium_rare',
      isLimited: false,
    ),
    RoseGift(
      id: 'rose_heart_petal',
      name: 'Heart-Petal Rose',
      gifUrl: 'https://media.giphy.com/media/l41YvpiA9uMWw5AMU/giphy.gif',
      iconKey: 'rose_heart',
      assetPath: 'assets/images/gifts/rose_heart_petal.gif',
      priceCoins: 3,
      tier: 'premium_rare',
      isLimited: false,
    ),
    RoseGift(
      id: 'rose_neon_glow',
      name: 'Neon Rose',
      gifUrl: 'https://media.giphy.com/media/l0Ex7d6Q5V3sz9N16/giphy.gif',
      iconKey: 'rose_neon',
      assetPath: 'assets/images/gifts/rose_neon_glow.gif',
      priceCoins: 3,
      tier: 'premium_rare',
      isLimited: false,
    ),
    RoseGift(
      id: 'rose_rain',
      name: 'Rose Rain',
      gifUrl: 'https://media.giphy.com/media/l41YB9N3dM2P8xTzG/giphy.gif',
      iconKey: 'rose_rain',
      assetPath: 'assets/images/gifts/rose_rain.gif',
      priceCoins: 5,
      tier: 'premium_epic',
      isLimited: false,
    ),
    RoseGift(
      id: 'rose_burning_flame',
      name: 'Burning Rose',
      gifUrl: 'https://media.giphy.com/media/3o6Zt481isNVuQI1l6/giphy.gif',
      iconKey: 'rose_burning',
      assetPath: 'assets/images/gifts/rose_burning_flame.gif',
      priceCoins: 5,
      tier: 'premium_epic',
      isLimited: false,
    ),
    RoseGift(
      id: 'rose_golden',
      name: 'Golden Rose',
      gifUrl: 'https://media.giphy.com/media/l0HlBO7eyXzSZkJri/giphy.gif',
      iconKey: 'rose_gold',
      assetPath: 'assets/images/gifts/rose_golden.gif',
      priceCoins: 8,
      tier: 'premium_legendary',
      isLimited: true,
    ),
    RoseGift(
      id: 'rose_crystal',
      name: 'Crystal Rose',
      gifUrl: 'https://media.giphy.com/media/3o7aD2saalBwwftBIY/giphy.gif',
      iconKey: 'rose_crystal',
      assetPath: 'assets/images/gifts/rose_crystal.gif',
      priceCoins: 10,
      tier: 'premium_legendary',
      isLimited: true,
    ),
    RoseGift(
      id: 'rose_bouquet_12',
      name: 'Rose Bouquet (12)',
      gifUrl: 'https://media.giphy.com/media/xTiTnMhJTwNHChdTZS/giphy.gif',
      iconKey: 'rose_bouquet',
      assetPath: 'assets/images/gifts/rose_bouquet_12.gif',
      priceCoins: 8,
      tier: 'premium_legendary',
      isLimited: true,
    ),
    RoseGift(
      id: 'rose_bouquet_24',
      name: 'Rose Bouquet (24)',
      gifUrl: 'https://media.giphy.com/media/26xBydxfjxsRQggh2/giphy.gif',
      iconKey: 'rose_bouquet',
      assetPath: 'assets/images/gifts/rose_bouquet_24.gif',
      priceCoins: 10,
      tier: 'premium_legendary',
      isLimited: true,
    ),
    RoseGift(
      id: 'rose_seasonal_weekly',
      name: 'Seasonal Limited Rose',
      gifUrl: 'https://media.giphy.com/media/l0MYAs5E2oIDCq9So/giphy.gif',
      iconKey: 'rose_seasonal',
      assetPath: 'assets/images/gifts/rose_seasonal_weekly.gif',
      priceCoins: 6,
      tier: 'seasonal_limited',
      isLimited: true,
    ),
  ];
}
