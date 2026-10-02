import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

// Guards the app's localisation (2026-10-02): user-facing text lives in
// lib/l10n/*.arb, not in widgets. The scan finds string literals in the
// places that render text (Text(...), label:, title:, tooltip: ...).
//
// The baseline lists the remaining literals that are deliberate: look names,
// mock/demo data, debug-only screens and English constants that widgets
// translate when shown. A file may never gain literals; when you remove one,
// lower its count here. New user-facing text: add it with
// `python3 app/tool/l10n_add.py <batch.json>` (all 10 locales).
const _baseline = <String, int>{
  'lib/core/theme/theme_presets.dart': 17,
  'lib/features/auth/screens/auth_screen.dart': 1,
  'lib/features/auth/screens/signup_screen.dart': 1,
  'lib/features/common/screens/about_app_screen.dart': 1,
  'lib/features/common/screens/main_navigation_screen.dart': 4,
  'lib/features/engagement/providers/billing_coexistence_provider.dart': 2,
  'lib/features/engagement/providers/conversation_rooms_provider.dart': 2,
  'lib/features/engagement/providers/level_progression_provider.dart': 1,
  'lib/features/engagement/providers/trust_badges_provider.dart': 1,
  'lib/features/engagement/screens/group_coffee_polls_screen.dart': 4,
  'lib/features/first_chapter/comfort_cards_screen.dart': 1,
  'lib/features/friends/providers/friend_social_provider.dart': 3,
  'lib/features/friends/providers/friends_provider.dart': 2,
  'lib/features/matching/providers/activity_session_provider.dart': 8,
  'lib/features/matching/providers/trust_filter_provider.dart': 4,
  'lib/features/messaging/providers/message_provider.dart': 4,
  'lib/features/payment/screens/subscription_screen.dart': 1,
  'lib/features/plans/providers/plans_provider.dart': 2,
  'lib/features/profile/screens/setup/setup_photos_screen.dart': 1,
  'lib/features/support/support_api.dart': 2,
  'lib/features/swipe/models/discovery_notification_item.dart': 2,
  'lib/features/swipe/providers/swipe_provider.dart': 1,
  'lib/features/web/web_member_workspace.dart': 1,
  'lib/main.dart': 1,
  'lib/main_simple.dart': 2,
};

final _literal = RegExp(
  r'''(?:Text\(\s*|(?:label|labelText|hintText|helperText|tooltip|title|subtitle|message|semanticsLabel|semanticLabel|content|caption|action|body|errorText|text|heading|description|cta|emptyText)\s*:\s*)(?:const\s+Text\(\s*)?['"]([A-Z][^'"$\n]{2,}|[A-Z][^'"\n]*\$[^'"\n]*)['"]''',
);

void main() {
  test('no new hard-coded user-facing strings', () {
    final over = <String>[];
    for (final entity in Directory('lib').listSync(recursive: true)) {
      final path = entity.path;
      if (entity is! File ||
          !path.endsWith('.dart') ||
          path.startsWith('lib/l10n') ||
          path.endsWith('.g.dart') ||
          path.endsWith('.freezed.dart')) {
        continue;
      }
      final found = _literal.allMatches(entity.readAsStringSync()).toList();
      final allowed = _baseline[path] ?? 0;
      if (found.length > allowed) {
        over.add(
          '$path: ${found.length} (allowed $allowed): '
          '${found.map((m) => m.group(1)).join(' | ')}',
        );
      }
    }
    expect(over, isEmpty, reason: 'Move these strings into lib/l10n/*.arb');
  });

  test('every locale has every key', () {
    Set<String> keys(String locale) =>
        (jsonDecode(File('lib/l10n/app_$locale.arb').readAsStringSync())
                as Map<String, dynamic>)
            .keys
            .where((k) => !k.startsWith('@'))
            .toSet();
    final english = keys('en');
    for (final locale in const [
      'en_GB',
      'de',
      'fr',
      'ru',
      'es',
      'it',
      'pt',
      'nl',
      'pl',
    ]) {
      expect(english.difference(keys(locale)), isEmpty, reason: locale);
    }
  });
}
