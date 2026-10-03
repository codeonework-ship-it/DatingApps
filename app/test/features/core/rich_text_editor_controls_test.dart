// RichTextEditor, the formatting editor behind chapters and profile stories:
// typing builds the saved document, the link dialog adds / changes / removes
// a link only for complete https addresses, the Text style and Alignment
// menus and the writing-style chips change the document, and every label
// follows the member's language. Assertions read the controller's document,
// the exact value the hosts save.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verified_dating_app/core/rich_text/rich_document.dart';
import 'package:verified_dating_app/core/rich_text/rich_text_controller.dart';
import 'package:verified_dating_app/core/rich_text/rich_text_editor.dart';
import 'package:verified_dating_app/l10n/app_localizations.dart';

import '../../support/qa_api.dart';

const _field = ValueKey('story.field');
const _linkButton = ValueKey('rich.link');
const _linkField = ValueKey('rich.link.field');
const _apply = ValueKey('rich.link.apply');
const _remove = ValueKey('rich.link.remove');

Widget _host(
  RichTextController c, {
  Locale? locale,
  int? maxLength,
  FormFieldValidator<String>? validator,
  GlobalKey<FormState>? form,
}) => MaterialApp(
  locale: locale,
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: Scaffold(
    body: SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: form,
        child: RichTextEditor(
          controller: c,
          label: 'Story',
          fieldKey: _field,
          maxLength: maxLength,
          validator: validator,
        ),
      ),
    ),
  ),
);

Future<RichTextController> _pump(
  WidgetTester tester, {
  Locale? locale,
  int? maxLength,
  FormFieldValidator<String>? validator,
  GlobalKey<FormState>? form,
}) async {
  tester.view.physicalSize = const Size(900, 1400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final c = RichTextController();
  addTearDown(c.dispose);
  await tester.pumpWidget(
    _host(
      c,
      locale: locale,
      maxLength: maxLength,
      validator: validator,
      form: form,
    ),
  );
  return c;
}

/// Types [text], selects [start]..[end] (as a drag over the words would) and
/// opens the link dialog.
Future<void> _openLinkDialog(
  WidgetTester tester,
  RichTextController c, {
  String text = 'Visit my shop today',
  int start = 9,
  int end = 13,
}) async {
  if (c.text != text) {
    await tester.enterText(find.byKey(_field), text);
  }
  c.selection = TextSelection(baseOffset: start, extentOffset: end);
  await tester.pump();
  await tester.tap(find.byKey(_linkButton));
  await tester.pumpAndSettle();
}

/// The linked spans of the saved document.
List<RichSpan> _links(RichTextController c) => [
  for (final b in c.document.blocks)
    for (final s in b.spans)
      if (s.href != null) s,
];

void main() {
  testWidgets('the link button opens the Add link dialog for the selection '
      '[case:core.rich_text_editor.showdialog_open.action]', (tester) async {
    final c = await _pump(tester);
    await _openLinkDialog(tester, c);

    expect(find.byType(AlertDialog), findsOneWidget);
    expect(find.text('Add a link'), findsOneWidget);
    final field = tester.widget<TextField>(find.byKey(_linkField));
    expect(field.controller!.text, 'https://');
    expect(find.byKey(_apply), findsOneWidget);
    // Nothing to remove on a new link.
    expect(find.byKey(_remove), findsNothing);
  });

  testWidgets('Add link closes the dialog and links the selected words '
      '[case:core.rich_text_editor.rich_link_apply.action]', (tester) async {
    final c = await _pump(tester);
    await _openLinkDialog(tester, c);
    await tester.enterText(find.byKey(_linkField), 'https://shop.example/a');
    await tester.tap(find.byKey(_apply));
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsNothing);
    final links = _links(c);
    expect(links, hasLength(1));
    expect(links.single.text, 'shop');
    expect(links.single.href, 'https://shop.example/a');
    expect(links.single.marks, contains(RichMark.link));
    expect(c.document.plainText, 'Visit my shop today');
    // The toolbar shows the link as active under the selection.
    expect(
      tester.widget<IconButton>(find.byKey(_linkButton)).isSelected,
      isTrue,
    );
  });

  testWidgets('pressing Enter in Web address submits it '
      '[case:core.rich_text_editor.rich_link_field_submitted.action]', (
    tester,
  ) async {
    final c = await _pump(tester);
    await _openLinkDialog(tester, c);
    await tester.enterText(find.byKey(_linkField), 'https://shop.example');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsNothing);
    expect(_links(c).single.href, 'https://shop.example');
    expect(_links(c).single.text, 'shop');
  });

  testWidgets(
    'Web address rejects unsafe or incomplete addresses and keeps valid unicode '
    '[case:core.rich_text_editor.rich_link_field_submitted.validation]',
    (tester) async {
      final c = await _pump(tester);
      await _openLinkDialog(tester, c);

      for (final bad in [
        '',
        '   ',
        'javascript:alert(1)',
        'http://shop.example',
        'https://shop .example',
        'https://user:pw@shop.example',
        'shop.example',
      ]) {
        await tester.enterText(find.byKey(_linkField), bad);
        await tester.testTextInput.receiveAction(TextInputAction.done);
        await tester.pumpAndSettle();
        expect(find.byType(AlertDialog), findsOneWidget, reason: bad);
        expect(
          find.text('Use a complete https:// address.'),
          findsOneWidget,
          reason: bad,
        );
        expect(_links(c), isEmpty, reason: bad);
      }
      // The Add link button applies the same rule.
      await tester.enterText(find.byKey(_linkField), 'javascript:alert(1)');
      await tester.tap(find.byKey(_apply));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(_links(c), isEmpty);

      // A valid address with non-ASCII path text is kept exactly.
      const unicode = 'https://bücher.example/straße?q=café';
      await tester.enterText(find.byKey(_linkField), '  $unicode ');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsNothing);
      expect(_links(c).single.href, unicode);
      expect(c.document.plainText, 'Visit my shop today');
    },
  );

  testWidgets('Cancel closes the dialog and leaves the text unlinked '
      '[case:core.rich_text_editor.cancel.action]', (tester) async {
    final c = await _pump(tester);
    await _openLinkDialog(tester, c);
    await tester.enterText(find.byKey(_linkField), 'https://shop.example');
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsNothing);
    expect(_links(c), isEmpty);
    expect(c.document.plainText, 'Visit my shop today');
  });

  testWidgets('Remove link closes the dialog and unlinks the words '
      '[case:core.rich_text_editor.rich_link_remove.action]', (tester) async {
    final c = await _pump(tester);
    await _openLinkDialog(tester, c);
    await tester.enterText(find.byKey(_linkField), 'https://shop.example');
    await tester.tap(find.byKey(_apply));
    await tester.pumpAndSettle();
    expect(_links(c), hasLength(1));

    // Caret inside the link: the dialog edits that link.
    c.selection = const TextSelection.collapsed(offset: 11);
    await tester.pump();
    await tester.tap(find.byKey(_linkButton));
    await tester.pumpAndSettle();
    expect(
      tester.widget<TextField>(find.byKey(_linkField)).controller!.text,
      'https://shop.example',
    );
    expect(find.byKey(_remove), findsOneWidget);

    await tester.tap(find.byKey(_remove));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsNothing);
    expect(_links(c), isEmpty);
    expect(c.document.plainText, 'Visit my shop today');
  });

  testWidgets('typing builds the saved document and word count '
      '[case:core.rich_text_editor.textformfield_input_input.action]', (
    tester,
  ) async {
    final c = await _pump(tester);
    await tester.enterText(find.byKey(_field), 'First line\nSecond line here');
    await tester.pump();

    final doc = c.document;
    expect(doc.plainText, 'First line\nSecond line here');
    expect(doc.blocks, hasLength(2));
    expect(doc.blocks.first.text, 'First line');
    expect(doc.blocks.last.text, 'Second line here');
    expect(find.textContaining('5 words'), findsOneWidget);
  });

  testWidgets(
    'the editor keeps unicode, enforces its limit and shows the host message '
    '[case:core.rich_text_editor.textformfield_input_input.validation]',
    (tester) async {
      final form = GlobalKey<FormState>();
      final c = await _pump(
        tester,
        maxLength: 40,
        form: form,
        validator: (v) =>
            (v ?? '').trim().isEmpty ? 'Write a few words first.' : null,
      );

      // Empty / whitespace-only: the host's message, nothing saved.
      await tester.enterText(find.byKey(_field), '   ');
      expect(form.currentState!.validate(), isFalse);
      await tester.pump();
      expect(find.text('Write a few words first.'), findsOneWidget);

      // Emoji, accents and RTL text survive into the document unchanged.
      const unicode = 'Café ☕ نعم 你好 👩🏽‍💻';
      await tester.enterText(find.byKey(_field), unicode);
      expect(form.currentState!.validate(), isTrue);
      await tester.pump();
      expect(find.text('Write a few words first.'), findsNothing);
      expect(c.document.plainText, unicode);
      expect(c.document.blocks.single.spans.single.text, unicode);

      // Markup is stored as text, never as formatting.
      await tester.enterText(find.byKey(_field), '<b>hi</b>');
      expect(c.document.blocks.single.spans.single.text, '<b>hi</b>');
      expect(c.document.blocks.single.spans.single.marks, isEmpty);

      // Too long: the field stops at its limit.
      await tester.enterText(find.byKey(_field), 'x' * 60);
      await tester.pump();
      expect(c.text.length, 40);
      expect(c.document.plainText, 'x' * 40);
    },
  );

  testWidgets('Text style menu changes the line type '
      '[case:core.rich_text_editor.x_block_menu.action]', (tester) async {
    final c = await _pump(tester);
    await tester.enterText(find.byKey(_field), 'A title\nBody');
    c.selection = const TextSelection.collapsed(offset: 2);
    await tester.pump();

    await tester.tap(find.byKey(const ValueKey('rich.block_menu')));
    await tester.pumpAndSettle();
    expect(find.text('Heading'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('rich.block.heading')).last);
    await tester.pumpAndSettle();
    expect(c.document.blocks.first.type, RichBlockType.heading);
    expect(c.document.blocks.last.type, RichBlockType.paragraph);

    await tester.tap(find.byKey(const ValueKey('rich.block_menu')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('rich.block.quote')).last);
    await tester.pumpAndSettle();
    expect(c.document.blocks.first.type, RichBlockType.quote);
    expect(c.document.plainText, 'A title\nBody');
  });

  testWidgets('Alignment menu aligns the line '
      '[case:core.rich_text_editor.x_align_menu.action]', (tester) async {
    final c = await _pump(tester);
    await tester.enterText(find.byKey(_field), 'Centre me\nLeave me');
    c.selection = const TextSelection.collapsed(offset: 3);
    await tester.pump();

    await tester.tap(find.byKey(const ValueKey('rich.align_menu')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('rich.align.center')).last);
    await tester.pumpAndSettle();
    expect(c.document.blocks.first.align, RichAlign.center);
    expect(c.document.blocks.last.align, RichAlign.start);

    await tester.tap(find.byKey(const ValueKey('rich.align_menu')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('rich.align.end')).last);
    await tester.pumpAndSettle();
    expect(c.document.blocks.first.align, RichAlign.end);
    expect(c.document.toJson()['blocks'][0]['align'], 'end');
  });

  testWidgets('writing style chips change the document style '
      '[case:core.rich_text_editor.x_style_x.action]', (tester) async {
    final c = await _pump(tester);
    await tester.enterText(find.byKey(_field), 'Words');
    await tester.pump();
    expect(c.style, defaultChapterStyle);

    for (final style in [WritingStyle.poetic, WritingStyle.typewriter]) {
      final chip = find.byKey(ValueKey('rich.style.${style.name}'));
      await tester.ensureVisible(chip);
      await tester.tap(chip);
      await tester.pump();
      expect(c.style, style);
      expect(c.document.style, style);
      expect(tester.widget<ChoiceChip>(chip).selected, isTrue);
    }
    expect(c.document.toJson()['style'], 'typewriter');
  });

  for (final locale in const [Locale('de'), Locale('fr')]) {
    testWidgets(
      'toolbar, menus and link dialog follow the language (${locale.languageCode}) '
      '[case:core.rich_text_editor.l10n]',
      (tester) async {
        final l = qaL10n(locale);
        final c = await _pump(tester, locale: locale);

        for (final tip in [
          l.richBold,
          l.richItalic,
          l.richLink,
          l.richTextStyleMenu,
          l.richAlignMenu,
          l.richClearFormatting,
        ]) {
          expect(find.byTooltip(tip), findsOneWidget, reason: tip);
        }
        expect(find.text(l.richWritingStyle), findsOneWidget);
        for (final english in ['Bold', 'Italic', 'Text style', 'Alignment']) {
          expect(find.byTooltip(english), findsNothing, reason: english);
        }
        expect(find.text('Writing style'), findsNothing);

        await tester.tap(find.byKey(const ValueKey('rich.block_menu')));
        await tester.pumpAndSettle();
        expect(find.text(l.richHeading), findsOneWidget);
        expect(find.text('Heading'), findsNothing);
        await tester.tap(find.byKey(const ValueKey('rich.block.heading')).last);
        await tester.pumpAndSettle();

        // Link without a selection: localized hint.
        await tester.tap(find.byKey(_linkButton));
        await tester.pump();
        expect(qaSnackText(tester), l.richLinkNeedsSelection);

        await _openLinkDialog(tester, c, text: 'Mon café', start: 4, end: 8);
        // (German uses the same words for the title and the button.)
        expect(
          find.descendant(
            of: find.byType(AlertDialog),
            matching: find.text(l.richLinkTitle),
          ),
          findsWidgets,
        );
        expect(find.text(l.richLinkField), findsOneWidget);
        expect(
          find.descendant(
            of: find.byKey(_apply),
            matching: find.text(l.richLinkApply),
          ),
          findsOneWidget,
        );
        expect(find.text(l.richCancel), findsOneWidget);
        await tester.enterText(find.byKey(_linkField), 'javascript:x');
        await tester.tap(find.byKey(_apply));
        await tester.pumpAndSettle();
        expect(find.text(l.richLinkInvalid), findsOneWidget);
        for (final english in [
          'Add a link',
          'Add link',
          'Cancel',
          'Use a complete https:// address.',
        ]) {
          expect(find.text(english), findsNothing, reason: english);
        }
        await tester.tap(find.text(l.richCancel));
        await tester.pumpAndSettle();
        expect(find.byType(AlertDialog), findsNothing);
      },
    );
  }
}
