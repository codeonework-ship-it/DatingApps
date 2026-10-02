import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verified_dating_app/core/rich_text/rich_document.dart';
import 'package:verified_dating_app/core/rich_text/rich_document_view.dart';
import 'package:verified_dating_app/core/rich_text/rich_text_controller.dart';
import 'package:verified_dating_app/core/rich_text/rich_text_editor.dart';
import 'package:verified_dating_app/core/theme/app_theme.dart';
import 'package:verified_dating_app/l10n/app_localizations.dart';

Widget app(
  Widget child, {
  Locale? locale,
  double scale = 1,
  bool dark = false,
}) => MaterialApp(
  locale: locale,
  theme: ThemeData.light(useMaterial3: true),
  darkTheme: ThemeData.dark(useMaterial3: true),
  themeMode: dark ? ThemeMode.dark : ThemeMode.light,
  localizationsDelegates: const [
    AppLocalizations.delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ],
  supportedLocales: AppLocalizations.supportedLocales,
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(scale)),
    child: child!,
  ),
  home: Scaffold(
    body: SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: child,
    ),
  ),
);

final doc = RichDocument.tryParse({
  'version': 1,
  'style': 'classic',
  'blocks': [
    {
      'type': 'heading',
      'spans': [
        {'text': 'A heading'},
      ],
    },
    {
      'type': 'paragraph',
      'spans': [
        {'text': 'Plain '},
        {
          'text': 'loud',
          'marks': ['bold'],
        },
        {' text': 'ignored'},
        {
          'text': ' marked',
          'marks': ['highlight'],
        },
      ],
    },
    {
      'type': 'bullet',
      'spans': [
        {'text': 'An item'},
      ],
    },
    {'type': 'divider'},
    {
      'type': 'paragraph',
      'spans': [
        {
          'text': 'a link',
          'marks': ['link'],
          'href': 'https://books.example',
        },
      ],
    },
  ],
})!;

TextSpan? spanWithText(WidgetTester t, String text) {
  for (final rich in t.widgetList<RichText>(find.byType(RichText))) {
    TextSpan? found;
    rich.text.visitChildren((span) {
      if (span is TextSpan && span.text == text) {
        found = span;
        return false;
      }
      return true;
    });
    if (found != null) return found;
  }
  return null;
}

void main() {
  group('RichTextEditor', () {
    testWidgets('toolbar toggles marks and blocks on the selection', (t) async {
      final c = RichTextController();
      addTearDown(c.dispose);
      await t.pumpWidget(app(RichTextEditor(controller: c, label: 'Story')));
      await t.enterText(find.byType(TextField), 'Hello world');
      c.selection = const TextSelection(baseOffset: 6, extentOffset: 11);
      await t.pump();
      await t.tap(find.byKey(const ValueKey('rich.bold')));
      await t.pump();
      expect(c.document.blocks.single.spans.last.marks, {RichMark.bold});
      final bold = t.widget<IconButton>(
        find.byKey(const ValueKey('rich.bold')),
      );
      expect(bold.isSelected, isTrue);

      await t.tap(find.byKey(const ValueKey('rich.highlight')));
      await t.tap(find.byKey(const ValueKey('rich.bullet')));
      await t.pump();
      expect(c.text, '• Hello world');
      expect(c.document.blocks.single.type, RichBlockType.bullet);

      await t.tap(find.byKey(const ValueKey('rich.block_menu')));
      await t.pumpAndSettle();
      await t.tap(find.byKey(const ValueKey('rich.block.heading')).last);
      await t.pumpAndSettle();
      expect(c.document.blocks.single.type, RichBlockType.heading);

      await t.tap(find.byKey(const ValueKey('rich.align_menu')));
      await t.pumpAndSettle();
      await t.tap(find.byKey(const ValueKey('rich.align.center')).last);
      await t.pumpAndSettle();
      expect(c.document.blocks.single.align, RichAlign.center);

      await t.tap(find.byKey(const ValueKey('rich.undo')));
      await t.pump();
      expect(c.document.blocks.single.align, RichAlign.start);
      await t.tap(find.byKey(const ValueKey('rich.redo')));
      await t.pump();
      expect(c.document.blocks.single.align, RichAlign.center);
      expect(
        find.text(
          '2 words · Alignment and spacing show in Preview and for readers.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('keyboard shortcuts format text on web and desktop', (t) async {
      final c = RichTextController();
      addTearDown(c.dispose);
      await t.pumpWidget(app(RichTextEditor(controller: c, label: 'Story')));
      await t.enterText(find.byType(TextField), 'Shortcut');
      c.selection = const TextSelection(baseOffset: 0, extentOffset: 8);
      await t.pump();
      await t.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await t.sendKeyEvent(LogicalKeyboardKey.keyB);
      await t.sendKeyEvent(LogicalKeyboardKey.keyI);
      await t.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await t.pump();
      expect(c.activeMarks, {RichMark.bold, RichMark.italic});
      await t.sendKeyDownEvent(LogicalKeyboardKey.metaLeft);
      await t.sendKeyEvent(LogicalKeyboardKey.keyZ);
      await t.sendKeyUpEvent(LogicalKeyboardKey.metaLeft);
      await t.pump();
      expect(c.activeMarks, {RichMark.bold});
    });

    testWidgets('link dialog accepts https only', (t) async {
      final c = RichTextController();
      addTearDown(c.dispose);
      await t.pumpWidget(app(RichTextEditor(controller: c, label: 'Story')));
      await t.enterText(find.byType(TextField), 'my shop');
      await t.tap(find.byKey(const ValueKey('rich.link')));
      await t.pumpAndSettle();
      expect(
        find.text('Select the words you want to link first.'),
        findsOneWidget,
      );
      c.selection = const TextSelection(baseOffset: 3, extentOffset: 7);
      await t.tap(find.byKey(const ValueKey('rich.link')));
      await t.pumpAndSettle();
      await t.enterText(
        find.byKey(const ValueKey('rich.link.field')),
        'javascript:alert(1)',
      );
      await t.tap(find.byKey(const ValueKey('rich.link.apply')));
      await t.pumpAndSettle();
      expect(find.text('Use a complete https:// address.'), findsOneWidget);
      await t.enterText(
        find.byKey(const ValueKey('rich.link.field')),
        'https://shop.example',
      );
      await t.tap(find.byKey(const ValueKey('rich.link.apply')));
      await t.pumpAndSettle();
      expect(c.document.blocks.single.spans.last.href, 'https://shop.example');
    });

    testWidgets('style picker changes the live editor typeface', (t) async {
      final c = RichTextController(style: WritingStyle.modern);
      addTearDown(c.dispose);
      await t.pumpWidget(app(RichTextEditor(controller: c, label: 'Story')));
      await t.enterText(find.byType(TextField), 'Words');
      await t.pump();
      expect(
        t.widget<EditableText>(find.byType(EditableText)).style.fontFamily,
        AppTheme.uiFamily,
      );
      await t.ensureVisible(find.byKey(const ValueKey('rich.style.journal')));
      await t.tap(find.byKey(const ValueKey('rich.style.journal')));
      await t.pump();
      expect(c.style, WritingStyle.journal);
      final style = t.widget<EditableText>(find.byType(EditableText)).style;
      expect(style.fontFamily, AppTheme.displayFamily);
      expect(style.fontStyle, FontStyle.italic);
      expect(find.text('Warm italic, like a diary entry'), findsOneWidget);
    });

    testWidgets('localised toolbar (German)', (t) async {
      final c = RichTextController();
      addTearDown(c.dispose);
      await t.pumpWidget(
        app(
          RichTextEditor(controller: c, label: 'Story'),
          locale: const Locale('de'),
        ),
      );
      expect(find.byTooltip('Fett'), findsOneWidget);
      expect(find.text('Schreibstil'), findsOneWidget);
    });

    for (final width in [320.0, 1280.0]) {
      testWidgets('fits at ${width.toInt()}px with large text', (t) async {
        t.view.physicalSize = Size(width, 900);
        t.view.devicePixelRatio = 1;
        addTearDown(t.view.resetPhysicalSize);
        addTearDown(t.view.resetDevicePixelRatio);
        final c = RichTextController(document: doc);
        addTearDown(c.dispose);
        await t.pumpWidget(
          app(
            Column(
              children: [
                RichTextEditor(controller: c, label: 'Story'),
                RichDocumentView(document: doc),
              ],
            ),
            scale: 2,
          ),
        );
        await t.pumpAndSettle();
        expect(t.takeException(), isNull);
        for (final button in t.widgetList<IconButton>(
          find.byType(IconButton),
        )) {
          expect(
            t.getSize(find.byWidget(button)).height,
            greaterThanOrEqualTo(48),
          );
        }
      });
    }
  });

  group('RichDocumentView', () {
    testWidgets('renders formatting with semantic headings and safe links', (
      t,
    ) async {
      final handle = t.ensureSemantics();
      await t.pumpWidget(app(RichDocumentView(document: doc)));
      expect(find.text('A heading'), findsOneWidget);
      expect(
        t.getSemantics(find.text('A heading')),
        matchesSemantics(isHeader: true, label: 'A heading'),
      );
      expect(spanWithText(t, 'loud')!.style!.fontWeight, FontWeight.w700);
      final scheme = Theme.of(
        t.element(find.byType(RichDocumentView)),
      ).colorScheme;
      expect(
        spanWithText(t, ' marked')!.style!.backgroundColor,
        scheme.tertiaryContainer,
      );
      expect(find.text('•'), findsOneWidget);
      expect(find.bySemanticsLabel('Section break'), findsOneWidget);
      expect(find.byType(Divider), findsOneWidget);
      // Links ask before leaving the app.
      final link = spanWithText(t, 'a link')!;
      expect(link.recognizer, isNotNull);
      (link.recognizer! as dynamic).onTap();
      await t.pumpAndSettle();
      expect(find.text('Open this link?'), findsOneWidget);
      expect(
        find.textContaining('books.example opens outside Connect'),
        findsOneWidget,
      );
      await t.tap(find.text('Cancel'));
      await t.pumpAndSettle();
      handle.dispose();
    });

    testWidgets('highlight stays readable in dark themes', (t) async {
      await t.pumpWidget(app(RichDocumentView(document: doc), dark: true));
      final scheme = Theme.of(
        t.element(find.byType(RichDocumentView)),
      ).colorScheme;
      final style = spanWithText(t, ' marked')!.style!;
      expect(style.color, scheme.onTertiaryContainer);
      expect(style.backgroundColor, scheme.tertiaryContainer);
    });

    testWidgets('plain text without formatting renders unchanged', (t) async {
      const legacy = 'An older chapter.\n\nStill exactly the same.';
      const style = TextStyle(fontSize: 17, height: 1.65);
      await t.pumpWidget(
        app(
          const RichBody(document: null, plainText: legacy, legacyStyle: style),
        ),
      );
      final text = t.widget<SelectableText>(find.byType(SelectableText));
      expect(text.data, legacy);
      expect(text.style, style);
      expect(find.byType(RichDocumentView), findsNothing);
    });

    testWidgets('poetic style centres start-aligned blocks', (t) async {
      const poetic = RichDocument(
        style: WritingStyle.poetic,
        blocks: [
          RichBlock(RichBlockType.paragraph, spans: [RichSpan('Verse')]),
          RichBlock(
            RichBlockType.paragraph,
            align: RichAlign.end,
            spans: [RichSpan('Signed')],
          ),
        ],
      );
      await t.pumpWidget(app(const RichDocumentView(document: poetic)));
      final texts = t
          .widgetList<RichText>(find.byType(RichText))
          .where(
            (r) =>
                r.text.toPlainText() == 'Verse' ||
                r.text.toPlainText() == 'Signed',
          )
          .toList();
      expect(texts.first.textAlign, TextAlign.center);
      expect(texts.last.textAlign, TextAlign.end);
    });
  });
}
