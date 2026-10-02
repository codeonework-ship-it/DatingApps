import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verified_dating_app/core/providers/api_client_provider.dart';
import 'package:verified_dating_app/core/theme/app_theme.dart';
import 'package:verified_dating_app/features/auth/providers/auth_provider.dart';
import 'package:verified_dating_app/features/groups/create_group_screen.dart';
import 'package:verified_dating_app/features/groups/group_detail_screen.dart';
import 'package:verified_dating_app/features/groups/groups_screen.dart';
import 'package:verified_dating_app/l10n/app_localizations.dart';

/// The Groups screens with data loaded (the screen matrix only sees their
/// empty and error states) against Flutter's tap-target, label and contrast
/// guidelines, at the reference phone size, in both shipped themes.

class _Auth extends AuthNotifier {
  @override
  AuthState build() => const AuthState(isAuthenticated: true, userId: 'me');
}

Map<String, Object?> _group(String id, String kind, String role) => {
  'id': id,
  'kind': kind,
  'name': kind == 'community' ? 'Koramangala readers' : 'Brunch crew',
  'category_slug': kind == 'community' ? 'books' : '',
  'category_title': kind == 'community' ? 'Books' : '',
  'category_emoji': kind == 'community' ? '📚' : '',
  'cover_color': 'tertiary',
  'description': 'One book a month, long talks after.',
  'city': 'Bengaluru',
  'member_count': 3,
  'member_cap': 200,
  'my_role': role,
  'channel_id': role.isEmpty ? '' : 'c1',
  'unread_count': role.isEmpty ? 0 : 2,
  'can_join': role.isEmpty,
  'can_invite': role.isNotEmpty,
  'can_manage': role == 'owner',
  if (role.isNotEmpty)
    'members_preview': [
      {'user_id': 'me', 'name': 'Priya', 'role': role, 'is_me': true},
      {'user_id': 'f1', 'name': 'Asha', 'role': 'moderator'},
      {'user_id': 'f2', 'name': 'Dev', 'role': 'member'},
    ],
};

Object? _respond(RequestOptions r) {
  switch (r.path) {
    case '/engagement/group-categories':
      return {
        'categories': [
          {'slug': 'books', 'title': 'Books', 'emoji': '📚', 'group_count': 2},
          {'slug': 'music', 'title': 'Music', 'emoji': '🎶'},
          {'slug': 'pets', 'title': 'Pets', 'emoji': '🐾'},
        ],
      };
    case '/engagement/group-invites':
      return {
        'invites': [
          {
            'id': 'i1',
            'inviter_name': 'Asha',
            'group': _group('p1', 'private', ''),
          },
        ],
      };
    case '/engagement/groups':
      return {
        'groups': r.queryParameters['scope'] == 'mine'
            ? [_group('g1', 'community', 'owner')]
            : [_group('g2', 'community', '')],
      };
    case '/engagement/groups/g1':
      // The owner's cover photo is waiting for review: banner, scrim
      // caption, "Under review" badge and the cover actions.
      return {
        'group': {
          ..._group('g1', 'community', 'owner'),
          'cover_photo_id': 'cv1',
          'cover_photo_url': '/v1/engagement/groups/g1/cover?v=cv1',
          'cover_photo_status': 'pending',
        },
      };
  }
  return <String, Object?>{};
}

void main() {
  final dio = Dio()
    ..interceptors.add(
      InterceptorsWrapper(
        onRequest: (r, h) => h.resolve(
          Response<dynamic>(
            requestOptions: r,
            statusCode: 200,
            data: _respond(r),
          ),
        ),
      ),
    );

  final screens = <String, Widget Function()>{
    'GroupsScreen': GroupsScreen.new,
    'GroupDetailScreen': () => const GroupDetailScreen(groupId: 'g1'),
    'CreateGroupScreen': () => const CreateGroupScreen(
      invitees: [(userId: 'f1', name: 'Asha', photoUrl: '')],
      initialKind: 'community',
    ),
  };
  final themes = {'light': AppTheme.lightTheme, 'dark': AppTheme.darkTheme};
  for (final MapEntry(key: themeLabel, value: theme) in themes.entries) {
    for (final MapEntry(key: label, value: build) in screens.entries) {
      testWidgets('$label meets accessibility guidelines [$themeLabel]', (
        tester,
      ) async {
        tester.view.physicalSize = const Size(360, 780);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        final semantics = tester.ensureSemantics();
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              authNotifierProvider.overrideWith(_Auth.new),
              apiClientProvider.overrideWithValue(dio),
            ],
            child: MaterialApp(
              theme: theme,
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: build(),
            ),
          ),
        );
        for (var i = 0; i < 6; i++) {
          await tester.pump(const Duration(milliseconds: 50));
        }
        await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
        await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
        await expectLater(tester, meetsGuideline(textContrastGuideline));
        semantics.dispose();
      });
    }
  }
}
