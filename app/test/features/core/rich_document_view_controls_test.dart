// RichBody / RichDocumentView, the read-only renderer for chapters and
// stories: a link asks "Open this link?" before leaving the app (Cancel
// stays, Open link hands the address to the platform launcher), legacy plain
// text is selectable but never editable and never parsed as markup, and every
// reader-facing string follows the member's language.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verified_dating_app/core/rich_text/rich_document.dart';
import 'package:verified_dating_app/core/rich_text/rich_document_view.dart';
import 'package:verified_dating_app/l10n/app_localizations.dart';

import '../../support/qa_api.dart';

Widget _host(Widget child, {Locale? locale}) => MaterialApp(
  locale: locale,
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: Scaffold(
    body: SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: child,
    ),
  ),
);

RichDocument _linkDoc(String href) => RichDocument(
  style: WritingStyle.classic,
  blocks: [
    const RichBlock(RichBlockType.paragraph, spans: [RichSpan('Read more: ')]),
    RichBlock(
      RichBlockType.paragraph,
      spans: [
        RichSpan('the bookshop', marks: const {RichMark.link}, href: href),
      ],
    ),
    const RichBlock(RichBlockType.divider),
  ],
);

/// URLs handed to the platform's launcher.
List<String> _fakeLauncher() {
  final launched = <String>[];
  const channel = MethodChannel('plugins.flutter.io/url_launcher');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  messenger.setMockMethodCallHandler(channel, (call) async {
    if (call.method == 'launch') {
      launched.add((call.arguments as Map)['url'] as String);
      return true;
    }
    return true;
  });
  addTearDown(() => messenger.setMockMethodCallHandler(channel, null));
  return launched;
}

Future<void> _tapLink(WidgetTester tester) async {
  await tester.tapOnText(find.textRange.ofSubstring('the bookshop'));
  await tester.pumpAndSettle();
}

void main() {
  const href = 'https://books.example/shelf?id=7';

  testWidgets(
    'tapping a link asks first [case:core.rich_document_view.open_this_link.action]',
    (tester) async {
      final launched = _fakeLauncher();
      await tester.pumpWidget(
        _host(
          RichBody(
            document: _linkDoc(href),
            plainText: 'Read more: the bookshop',
            legacyStyle: null,
          ),
        ),
      );

      expect(find.byType(AlertDialog), findsNothing);
      await _tapLink(tester);

      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text('Open this link?'), findsOneWidget);
      // The dialog names the host the member is about to visit.
      expect(find.textContaining('books.example'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.byKey(const ValueKey('rich.open_link')), findsOneWidget);
      // Nothing is opened before the member decides.
      expect(launched, isEmpty);
    },
  );

  testWidgets(
    'Cancel closes the dialog and opens nothing [case:core.rich_document_view.cancel.action]',
    (tester) async {
      final launched = _fakeLauncher();
      await tester.pumpWidget(
        _host(
          RichBody(
            document: _linkDoc(href),
            plainText: 'Read more: the bookshop',
            legacyStyle: null,
          ),
        ),
      );
      await _tapLink(tester);

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsNothing);
      expect(launched, isEmpty);
      // The reader is still on the story.
      expect(find.textContaining('the bookshop', findRichText: true), findsOne);
    },
  );

  testWidgets(
    'Open link closes the dialog and launches the address [case:core.rich_document_view.rich_open_link.action]',
    (tester) async {
      final launched = _fakeLauncher();
      await tester.pumpWidget(
        _host(RichDocumentView(document: _linkDoc(href), selectable: false)),
      );
      await _tapLink(tester);

      await tester.tap(find.byKey(const ValueKey('rich.open_link')));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsNothing);
      expect(launched, [href]);

      // A second visit asks again rather than remembering the answer.
      await _tapLink(tester);
      expect(find.text('Open this link?'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('rich.open_link')));
      await tester.pumpAndSettle();
      expect(launched, [href, href]);
    },
  );

  testWidgets('legacy plain text is selectable but read-only '
      '[case:core.rich_document_view.selectabletext_input_input.action]', (
    tester,
  ) async {
    const story = 'Sunday walks by the river';
    await tester.pumpWidget(
      _host(
        const RichBody(
          document: null,
          plainText: story,
          legacyStyle: TextStyle(fontSize: 17),
        ),
      ),
    );

    expect(find.byType(SelectableText), findsOneWidget);
    final editable = tester.widget<EditableText>(find.byType(EditableText));
    expect(editable.readOnly, isTrue);

    // A long press selects a word, as a reader copying a line would.
    await tester.longPress(find.byType(SelectableText));
    await tester.pumpAndSettle();
    final state = tester.state<EditableTextState>(find.byType(EditableText));
    final selection = state.textEditingValue.selection;
    expect(selection.isCollapsed, isFalse);
    expect(selection.textInside(story), isNotEmpty);
    expect(story.contains(selection.textInside(story)), isTrue);
    // Selecting never changes the words.
    expect(state.textEditingValue.text, story);

    // With selection off the same words render as plain text.
    await tester.pumpWidget(
      _host(
        const RichBody(
          document: null,
          plainText: story,
          legacyStyle: null,
          selectable: false,
        ),
      ),
    );
    expect(find.byType(SelectableText), findsNothing);
    expect(find.text(story), findsOneWidget);
  });

  testWidgets(
    'unicode and markup-looking text survive unchanged; unsafe links never open '
    '[case:core.rich_document_view.selectabletext_input_input.validation]',
    (tester) async {
      final launched = _fakeLauncher();
      const tricky =
          'Café ☕ نعم 你好 👩🏽‍💻\n<b>not bold</b> <script>x</script> & [link](https://x.example)';
      await tester.pumpWidget(
        _host(
          const RichBody(document: null, plainText: tricky, legacyStyle: null),
        ),
      );
      final text = tester.widget<SelectableText>(find.byType(SelectableText));
      expect(text.data, tricky);
      expect(
        tester
            .state<EditableTextState>(find.byType(EditableText))
            .textEditingValue
            .text,
        tricky,
      );

      // A formatted document keeps the same words, and a span carrying an
      // unsafe address is shown as text but cannot open anything.
      for (final bad in [
        'javascript:alert(1)',
        'http://plain.example',
        'https://exa mple.example',
        '',
      ]) {
        await tester.pumpWidget(
          _host(
            RichDocumentView(
              document: RichDocument(
                style: WritingStyle.classic,
                blocks: [
                  RichBlock(
                    RichBlockType.paragraph,
                    spans: [
                      const RichSpan('Café ☕ 你好 '),
                      RichSpan(
                        'the bookshop',
                        marks: const {RichMark.link},
                        href: bad,
                      ),
                    ],
                  ),
                ],
              ),
              selectable: false,
            ),
          ),
        );
        expect(
          find.text('Café ☕ 你好 the bookshop', findRichText: true),
          findsOneWidget,
          reason: bad,
        );
        await _tapLink(tester);
        expect(find.byType(AlertDialog), findsNothing, reason: bad);
      }
      expect(launched, isEmpty);
    },
  );

  for (final locale in const [Locale('de'), Locale('fr')]) {
    testWidgets(
      'link dialog and section break follow the language (${locale.languageCode}) '
      '[case:core.rich_document_view.l10n]',
      (tester) async {
        final semantics = tester.ensureSemantics();
        final l = qaL10n(locale);
        final launched = _fakeLauncher();
        await tester.pumpWidget(
          _host(
            RichDocumentView(document: _linkDoc(href), selectable: false),
            locale: locale,
          ),
        );
        expect(find.bySemanticsLabel(l.richDivider), findsOneWidget);
        expect(find.bySemanticsLabel('Section break'), findsNothing);

        await _tapLink(tester);
        expect(find.text(l.richOpenLinkTitle), findsOneWidget);
        expect(find.text(l.richOpenLinkBody('books.example')), findsOneWidget);
        expect(find.text(l.richCancel), findsOneWidget);
        expect(find.text(l.richOpenLink), findsOneWidget);
        for (final english in ['Open this link?', 'Cancel', 'Open link']) {
          expect(find.text(english), findsNothing, reason: english);
        }

        await tester.tap(find.text(l.richCancel));
        await tester.pumpAndSettle();
        expect(find.byType(AlertDialog), findsNothing);
        expect(launched, isEmpty);
        semantics.dispose();
      },
    );
  }
}
