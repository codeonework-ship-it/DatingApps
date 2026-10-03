import 'dart:ui' show Tristate;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verified_dating_app/core/widgets/glass_widgets.dart';
import 'package:verified_dating_app/core/widgets/qa_control.dart';
import 'package:verified_dating_app/l10n/app_localizations.dart';

// Regression (2026-10-03): GlassButton labelled itself and also showed the
// same text, so screen readers announced "Sign in Sign in" (and "Love Love",
// "Message Message" on the profile dock, where QaControl merges the node).
Future<void> _pump(WidgetTester tester, Widget button) => tester.pumpWidget(
  MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(
      body: Center(child: SizedBox(width: 240, child: button)),
    ),
  ),
);

void main() {
  testWidgets('a glass button is announced once, with its role and state', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    var taps = 0;
    await _pump(tester, GlassButton(label: 'Sign in', onPressed: () => taps++));
    final node = tester.getSemantics(find.byType(GlassButton));
    expect(node.label, 'Sign in');
    expect(node.getSemanticsData().flagsCollection.isButton, isTrue);
    expect(node.getSemanticsData().flagsCollection.isEnabled, Tristate.isTrue);
    expect(find.bySemanticsLabel('Sign in'), findsOneWidget);

    tester.semantics.tap(find.semantics.byLabel('Sign in'));
    expect(taps, 1);
    semantics.dispose();
  });

  testWidgets('merged under QaControl it is still announced once', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await _pump(
      tester,
      QaControl(
        id: 'qa.profile_detail.love_button',
        child: GlassButton(label: 'Love', onPressed: () {}),
      ),
    );
    final node = tester.getSemantics(
      find.bySemanticsIdentifier('qa.profile_detail.love_button'),
    );
    // What a screen reader hears is the merged data, not the node's own label.
    expect(node.getSemanticsData().label, 'Love');
    expect(find.bySemanticsLabel('Love'), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('while busy it says it is loading, once', (tester) async {
    final semantics = tester.ensureSemantics();
    await _pump(
      tester,
      GlassButton(label: 'Sign in', isLoading: true, onPressed: () {}),
    );
    final node = tester.getSemantics(find.byType(GlassButton));
    final en = lookupAppLocalizations(const Locale('en'));
    expect(node.label, en.commonLoadingLabel('Sign in'));
    expect('Sign in'.allMatches(node.label), hasLength(1));
    semantics.dispose();
  });

  testWidgets(
    'inside a card it stays its own button, apart from the card text',
    (tester) async {
      final semantics = tester.ensureSemantics();
      await _pump(
        tester,
        // A plan card in a scrolling list, as on the membership screen: a
        // list item is one node that absorbs descendants without a boundary.
        SizedBox(
          height: 400,
          child: ListView(
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Bronze'),
                  const Text('25 likes/day'),
                  GlassButton(label: 'Subscribe with card', onPressed: () {}),
                ],
              ),
            ],
          ),
        ),
      );
      final node = tester.getSemantics(find.byType(GlassButton));
      final data = node.getSemanticsData();
      expect(data.label, 'Subscribe with card');
      expect(data.flagsCollection.isButton, isTrue);
      // The card's own text stays a separate, non-button node.
      final card = tester.getSemantics(find.text('Bronze')).getSemanticsData();
      expect(card.label, contains('Bronze'));
      expect(card.label, isNot(contains('Subscribe')));
      expect(card.flagsCollection.isButton, isFalse);
      semantics.dispose();
    },
  );
}
