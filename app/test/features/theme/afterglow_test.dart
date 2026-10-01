import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dio/dio.dart';
import 'package:verified_dating_app/core/theme/app_theme.dart';
import 'package:verified_dating_app/core/providers/api_client_provider.dart';
import 'package:verified_dating_app/features/auth/providers/auth_provider.dart';
import 'package:verified_dating_app/features/auth/screens/welcome_screen.dart';
import 'package:verified_dating_app/features/auth/screens/auth_screen.dart';
import 'package:verified_dating_app/features/profile/providers/profile_setup_provider.dart';
import 'package:verified_dating_app/features/profile/screens/setup/setup_preferences_screen.dart';
import 'package:verified_dating_app/features/common/screens/settings_screen.dart';
import 'package:verified_dating_app/features/swipe/screens/home_discovery_screen.dart';
import 'package:verified_dating_app/features/swipe/providers/swipe_provider.dart';
import 'package:verified_dating_app/features/engagement/providers/daily_prompt_provider.dart';
import 'package:verified_dating_app/l10n/app_localizations.dart';
import '../../support/qa_profile_fixtures.dart';

class _Draft extends ProfileSetupNotifier {
  @override
  Future<ProfileDraft> build() async => qaProfileDraft();
}

class _Auth extends AuthNotifier {
  @override
  AuthState build() => const AuthState(
    userId: 'design-member',
    isAuthenticated: true,
    username: 'design_member',
  );
}

class _Swipe extends SwipeNotifier {
  @override
  SwipeState build() => const SwipeState(isLoading: false);
}

class _Daily extends DailyPromptNotifier {
  _Daily(super.ref);
  @override
  Future<void> load() async {
    state = const DailyPromptState(isLoading: false);
  }
}

void main() {
  test(
    'Connect Studio primary and secondary labels meet normal text contrast',
    () {
      double ratio(Color a, Color b) {
        final x = a.computeLuminance(), y = b.computeLuminance();
        return ((x > y ? x : y) + .05) / ((x > y ? y : x) + .05);
      }

      for (final theme in [AppTheme.lightTheme, AppTheme.darkTheme]) {
        final c = theme.colorScheme;
        expect(ratio(c.primary, c.onPrimary), greaterThanOrEqualTo(4.5));
        expect(ratio(c.surface, c.onSurfaceVariant), greaterThanOrEqualTo(4.5));
      }
    },
  );
  if (!const bool.fromEnvironment('QA_CAPTURE_DESIGN')) return;
  setUpAll(() async {
    final icons = FontLoader('MaterialIcons')
      ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
    await icons.load();
    for (final family in ['Figtree']) {
      final loader = FontLoader(family);
      for (final weight in ['Regular']) {
        loader.addFont(
          rootBundle.load(
            'assets/fonts/${family.replaceAll(' ', '')}-$weight.ttf',
          ),
        );
      }
      await loader.load();
    }
  });
  final scenes = <String, Widget>{
    'welcome': const WelcomeScreen(),
    'welcome-small': const WelcomeScreen(),
    'welcome-tablet': const WelcomeScreen(),
    'discovery': const HomeDiscoveryScreen(),
    'login': const AuthScreen(),
    'preferences': const SetupPreferencesScreen(isSetupFlow: false),
    'settings': const SettingsScreen(),
  };
  for (final entry in scenes.entries) {
    for (final dark in [false, true]) {
      testWidgets('capture ${entry.key} ${dark ? 'dark' : 'light'}', (
        tester,
      ) async {
        tester.view.physicalSize = entry.key == 'welcome-tablet'
            ? const Size(1024, 900)
            : entry.key == 'welcome-small'
            ? const Size(320, 568)
            : const Size(390, 844);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final key = GlobalKey();
        final dio = Dio()
          ..interceptors.add(
            InterceptorsWrapper(
              onRequest: (o, h) => h.resolve(
                Response(
                  requestOptions: o,
                  statusCode: 200,
                  data: <String, dynamic>{},
                ),
              ),
            ),
          );
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              apiClientProvider.overrideWithValue(dio),
              swipeNotifierProvider.overrideWith(_Swipe.new),
              dailyPromptProvider.overrideWith(_Daily.new),
              profileSetupNotifierProvider.overrideWith(_Draft.new),
              if (entry.key != 'login')
                authNotifierProvider.overrideWith(_Auth.new),
            ],
            child: MaterialApp(
              theme: dark ? AppTheme.darkTheme : AppTheme.lightTheme,
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: RepaintBoundary(key: key, child: entry.value),
            ),
          ),
        );
        if (entry.key.startsWith('welcome')) {
          await tester.runAsync(
            () => precacheImage(
              const AssetImage('assets/images/connect-cafe.png'),
              key.currentContext!,
            ),
          );
        }
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 700));
        expect(tester.takeException(), isNull);
        final boundary =
            key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
        await tester.runAsync(() async {
          final image = await boundary.toImage(pixelRatio: 2);
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          final file = File(
            '../qa/results/2026-09-26-connect-studio/${entry.key}-${dark ? 'dark' : 'light'}.png',
          );
          await file.parent.create(recursive: true);
          await file.writeAsBytes(bytes!.buffer.asUint8List());
          image.dispose();
        });
      });
    }
  }
}
