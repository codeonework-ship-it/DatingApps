import '../../l10n/app_localizations.dart';
import 'models/rose_gift.dart';

/// The gift's name in the reader's language.
///
/// The server sends catalog names in English (and chat gift tokens carry that
/// name), so a known gift is resolved by its [id], or, when only the name is
/// known (older messages, error text), by the English catalog name. A gift
/// the app does not know keeps the [serverName] it came with.
String localizedGiftName(
  AppLocalizations l, {
  required String serverName,
  String? id,
}) {
  var key = (id ?? '').trim();
  if (!_giftNames.containsKey(key)) {
    key = _idByEnglishName[serverName.trim().toLowerCase()] ?? key;
  }
  final name = _giftNames[key];
  return name == null ? serverName : name(l);
}

final Map<String, String> _idByEnglishName = {
  for (final gift in RoseGift.phaseOneCatalog) gift.name.toLowerCase(): gift.id,
  // The server's catalog spells it the British way, as the app's does.
  'jewelry box': 'jewellery_box',
};

final Map<String, String Function(AppLocalizations)> _giftNames = {
  'rose_red_single': (l) => l.giftNameRoseRedSingle,
  'rose_pink_soft': (l) => l.giftNameRosePinkSoft,
  'rose_white_pure': (l) => l.giftNameRoseWhitePure,
  'rose_yellow_friendship': (l) => l.giftNameRoseYellowFriendship,
  'rose_lavender_crush': (l) => l.giftNameRoseLavenderCrush,
  'rose_blue_rare': (l) => l.giftNameRoseBlueRare,
  'rose_black_mystery': (l) => l.giftNameRoseBlackMystery,
  'rose_sparkle': (l) => l.giftNameRoseSparkle,
  'rose_heart_petal': (l) => l.giftNameRoseHeartPetal,
  'rose_neon_glow': (l) => l.giftNameRoseNeonGlow,
  'rose_rain': (l) => l.giftNameRoseRain,
  'rose_burning_flame': (l) => l.giftNameRoseBurningFlame,
  'rose_golden': (l) => l.giftNameRoseGolden,
  'rose_crystal': (l) => l.giftNameRoseCrystal,
  'rose_bouquet_12': (l) => l.giftNameRoseBouquet12,
  'rose_bouquet_24': (l) => l.giftNameRoseBouquet24,
  'rose_seasonal_weekly': (l) => l.giftNameRoseSeasonalWeekly,
  'chocolate_box': (l) => l.giftNameChocolateBox,
  'heart_balloon': (l) => l.giftNameHeartBalloon,
  'teddy_bear': (l) => l.giftNameTeddyBear,
  'flower_bouquet': (l) => l.giftNameFlowerBouquet,
  'jewellery_box': (l) => l.giftNameJewelleryBox,
  'champagne_toast': (l) => l.giftNameChampagneToast,
  'heart_explosion': (l) => l.giftNameHeartExplosion,
  'confetti_shower': (l) => l.giftNameConfettiShower,
  'fireworks_burst': (l) => l.giftNameFireworksBurst,
  'star_shower': (l) => l.giftNameStarShower,
  'golden_sparkle': (l) => l.giftNameGoldenSparkle,
  'rainbow_wave': (l) => l.giftNameRainbowWave,
  'coffee_date_invite': (l) => l.giftNameCoffeeDateInvite,
  'picnic_invite': (l) => l.giftNamePicnicInvite,
  'movie_night_invite': (l) => l.giftNameMovieNightInvite,
  'sunset_walk_invite': (l) => l.giftNameSunsetWalkInvite,
  'date_night_card': (l) => l.giftNameDateNightCard,
  'valentine_surprise': (l) => l.giftNameValentineSurprise,
  'exclusive_diamond_ring': (l) => l.giftNameDiamondRing,
  'exclusive_luxury_date': (l) => l.giftNameLuxuryDate,
};
