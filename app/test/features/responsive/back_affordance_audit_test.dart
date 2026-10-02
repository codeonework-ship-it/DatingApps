import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verified_dating_app/core/theme/app_theme.dart';
import 'package:verified_dating_app/l10n/app_localizations.dart';

import 'screen_matrix_harness.dart';

/// Screens that are never pushed on top of another one: entry points and
/// the main tabs. Everything else is opened from somewhere and must show a
/// way back.
const _roots = {
  'WelcomeScreen',
  'WebEntryScreen',
  'AuthScreen',
  'MainNavigationScreen',
  'HomeDiscoveryScreen',
  'MatchesListScreen',
  'EngagementHubScreen',
  'ProfileViewScreen',
  'SettingsScreen',
  'ProfileSetupEntryScreen',
};

/// Screens without a back/close control, and why that is fine.
const _exempt = {
  // A gate shown in place of the app until the terms are accepted; its way
  // out is "Sign out" (qa.terms.sign_out), checked below.
  'UserAgreementScreen',
  // Has a close button in its AppBar, but the platform WebView cannot
  // render in widget tests, so the screen never finishes building here.
  'CheckoutWebViewScreen',
};

/// True when the pushed screen shows a visible back or close control.
bool _hasBackAffordance(WidgetTester tester, BuildContext context) {
  final strings = MaterialLocalizations.of(context);
  final labels = {
    strings.backButtonTooltip,
    strings.closeButtonTooltip,
    'Back',
    'Close',
  };
  final icons = <IconData>{
    Icons.arrow_back,
    Icons.arrow_back_rounded,
    Icons.arrow_back_ios,
    Icons.arrow_back_ios_new,
    Icons.arrow_back_ios_new_rounded,
    Icons.close,
    Icons.close_rounded,
    Icons.chevron_left,
    Icons.chevron_left_rounded,
  };
  if (find.byType(BackButton).hitTestable().evaluate().isNotEmpty ||
      find.byType(CloseButton).hitTestable().evaluate().isNotEmpty ||
      find.byType(BackButtonIcon).hitTestable().evaluate().isNotEmpty) {
    return true;
  }
  for (final element in find.byType(IconButton).hitTestable().evaluate()) {
    final button = element.widget as IconButton;
    final icon = button.icon;
    if (labels.contains(button.tooltip) ||
        (icon is Icon && icons.contains(icon.icon))) {
      return true;
    }
  }
  for (final element in find.byType(Tooltip).hitTestable().evaluate()) {
    if (labels.contains((element.widget as Tooltip).message)) {
      return true;
    }
  }
  return find
      .byWidgetPredicate(
        (w) =>
            w is Semantics &&
            (w.properties.label == 'Back' ||
                w.properties.label == strings.backButtonTooltip),
      )
      .evaluate()
      .isNotEmpty;
}

void main() {
  final screens = buildScreenMatrix();

  for (final entry in screens.entries) {
    if (_roots.contains(entry.key)) {
      continue;
    }
    testWidgets('${entry.key} shows a way back when pushed', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final navigator = GlobalKey<NavigatorState>();
      await tester.pumpWidget(
        ProviderScope(
          overrides: screenMatrixOverrides(),
          child: MaterialApp(
            navigatorKey: navigator,
            theme: AppTheme.lightTheme,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const Scaffold(body: Text('launcher')),
          ),
        ),
      );
      navigator.currentState!.push(
        MaterialPageRoute<void>(builder: (_) => entry.value()),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));
      final context = navigator.currentState!.context;
      // Ignore unrelated runtime noise from fixture data; this audit is
      // only about navigation.
      tester.takeException();
      if (entry.key == 'UserAgreementScreen') {
        expect(
          find.byKey(const ValueKey('qa.terms.sign_out')),
          findsOneWidget,
          reason: 'the terms gate needs a way out',
        );
      } else if (!_exempt.contains(entry.key)) {
        expect(
          _hasBackAffordance(tester, context),
          isTrue,
          reason: '${entry.key} has no back or close button when pushed',
        );
      }
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 1));
    });
  }
}
