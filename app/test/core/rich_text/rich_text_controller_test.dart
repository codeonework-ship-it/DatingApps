import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verified_dating_app/core/rich_text/rich_document.dart';
import 'package:verified_dating_app/core/rich_text/rich_text_controller.dart';

/// Types [inserted] at the caret, the way a keyboard or IME would.
void type(RichTextController c, String inserted) {
  final s = c.selection;
  final text = c.text.replaceRange(s.start, s.end, inserted);
  c.value = TextEditingValue(
    text: text,
    selection: TextSelection.collapsed(offset: s.start + inserted.length),
  );
}

/// Backspace at the caret.
void backspace(RichTextController c) {
  final s = c.selection;
  final at = s.isCollapsed ? s.start - 1 : s.start;
  c.value = TextEditingValue(
    text: c.text.replaceRange(at, s.end, ''),
    selection: TextSelection.collapsed(offset: at),
  );
}

void select(RichTextController c, int start, int end) =>
    c.selection = TextSelection(baseOffset: start, extentOffset: end);

final fixture = <String, dynamic>{
  'version': 1,
  'style': 'journal',
  'blocks': [
    {
      'type': 'heading',
      'spans': [
        {'text': 'Sunday'},
      ],
    },
    {
      'type': 'paragraph',
      'align': 'center',
      'spans': [
        {'text': 'Coffee, '},
        {
          'text': 'a bookshop',
          'marks': ['bold', 'italic'],
        },
        {'text': ' and a walk.'},
      ],
    },
    {'type': 'paragraph'},
    {
      'type': 'bullet',
      'spans': [
        {'text': 'Oat latte'},
      ],
    },
    {
      'type': 'numbered',
      'spans': [
        {'text': 'Wake'},
      ],
    },
    {
      'type': 'numbered',
      'spans': [
        {
          'text': 'Read',
          'marks': ['highlight'],
        },
      ],
    },
    {'type': 'divider'},
    {
      'type': 'quote',
      'spans': [
        {'text': 'Slow is fine.'},
      ],
    },
    {
      'type': 'callout',
      'spans': [
        {
          'text': 'Shop',
          'marks': ['underline', 'link'],
          'href': 'https://books.example/shop',
        },
      ],
    },
  ],
};

const fixturePlain =
    'Sunday\nCoffee, a bookshop and a walk.\n\n• Oat latte\n1. Wake\n2. Read\n* * *\nSlow is fine.\nShop';

void main() {
  group('RichDocument', () {
    test('derives the same plain text as the server', () {
      final doc = RichDocument.tryParse(fixture)!;
      expect(doc.plainText, fixturePlain);
      expect(doc.style, WritingStyle.journal);
      expect(doc.isFormatted, isTrue);
      expect(doc.wordCount, 15);
    });

    test('legacy plain text becomes paragraphs and round-trips exactly', () {
      const legacy = 'First line\n\n  indented • not a list\n1. not numbered';
      final doc = RichDocument.fromPlainText(legacy);
      expect(doc.plainText, legacy);
      expect(doc.isFormatted, isFalse);
      expect(
        doc.blocks.every((b) => b.type == RichBlockType.paragraph),
        isTrue,
      );
    });

    test('reading is defensive about unknown or unsafe input', () {
      expect(RichDocument.tryParse('<p>html</p>'), isNull);
      expect(
        RichDocument.tryParse({'version': 2, 'blocks': <dynamic>[]}),
        isNull,
      );
      final doc = RichDocument.tryParse({
        'version': 1,
        'style': 'unknown',
        'blocks': [
          {
            'type': 'marquee',
            'spans': [
              {
                'text': 'click',
                'marks': ['link', 'blink'],
                'href': 'javascript:alert(1)',
              },
            ],
          },
        ],
      })!;
      expect(doc.style, defaultChapterStyle);
      expect(doc.blocks.single.type, RichBlockType.paragraph);
      expect(doc.blocks.single.spans.single.marks, isEmpty);
      expect(doc.blocks.single.spans.single.href, isNull);
    });

    test('only complete https links are safe', () {
      expect(isSafeRichHref('https://example.com/a?b=1'), isTrue);
      for (final bad in [
        'http://example.com',
        'javascript:alert(1)',
        'data:text/html,x',
        '//example.com',
        'https://user:pw@example.com',
        ' https://example.com',
        'https://',
      ]) {
        expect(isSafeRichHref(bad), isFalse, reason: bad);
      }
    });
  });

  group('RichTextController', () {
    test('load and save round-trip formatting; text is the body', () {
      final c = RichTextController(document: RichDocument.tryParse(fixture));
      expect(c.text, fixturePlain);
      expect(c.style, WritingStyle.journal);
      expect(c.document.toJson(), RichDocument.tryParse(fixture)!.toJson());
      expect(c.document.plainText, c.text);
    });

    test('bold toggles on a selection and for upcoming typing', () {
      final c = RichTextController();
      type(c, 'Hello world');
      select(c, 6, 11);
      c.toggleMark(RichMark.bold);
      expect(c.activeMarks, {RichMark.bold});
      var spans = c.document.blocks.single.spans;
      expect(spans.map((s) => s.text), ['Hello ', 'world']);
      expect(spans.last.marks, {RichMark.bold});
      c.toggleMark(RichMark.bold);
      expect(c.document.blocks.single.spans.single.marks, isEmpty);

      c.selection = TextSelection.collapsed(offset: c.text.length);
      c.toggleMark(RichMark.italic);
      type(c, '!');
      type(c, '?');
      spans = c.document.blocks.single.spans;
      expect(spans.last.text, '!?');
      expect(spans.last.marks, {RichMark.italic});
    });

    test('typing repeats of the same letter keeps formatting where typed', () {
      final c = RichTextController();
      type(c, 'aa');
      select(c, 0, 1);
      c.toggleMark(RichMark.bold);
      c.selection = const TextSelection.collapsed(offset: 1);
      type(c, 'a');
      final spans = c.document.blocks.single.spans;
      expect(spans.first.text, 'aa');
      expect(spans.first.marks, {RichMark.bold});
    });

    test('lists: markers, continuation, exit and renumbering', () {
      final c = RichTextController();
      type(c, 'Milk');
      c.setBlockType(RichBlockType.bullet);
      expect(c.text, '• Milk');
      type(c, '\nEggs');
      expect(c.text, '• Milk\n• Eggs');
      type(c, '\n');
      expect(c.text, '• Milk\n• Eggs\n• ');
      // Enter on an empty item ends the list.
      type(c, '\n');
      expect(c.text, '• Milk\n• Eggs\n');
      expect(c.document.blocks.last.type, RichBlockType.paragraph);

      final n = RichTextController();
      type(n, 'One\nTwo\nThree');
      select(n, 0, n.text.length);
      n.setBlockType(RichBlockType.numbered);
      expect(n.text, '1. One\n2. Two\n3. Three');
      // Removing the first line renumbers the rest.
      select(n, 0, 7);
      type(n, '');
      expect(n.text, '1. Two\n2. Three');
      // Applying the same list again turns lines back into paragraphs.
      select(n, 0, n.text.length);
      n.setBlockType(RichBlockType.numbered);
      expect(n.text, 'Two\nThree');
    });

    test('backspace at the start of a list item removes the marker', () {
      final c = RichTextController();
      type(c, 'Tea');
      c.setBlockType(RichBlockType.bullet);
      c.selection = const TextSelection.collapsed(offset: 2);
      backspace(c);
      expect(c.text, 'Tea');
      expect(c.document.blocks.single.type, RichBlockType.paragraph);
    });

    test('caret cannot land inside a list marker', () {
      final c = RichTextController();
      type(c, 'Tea');
      c.setBlockType(RichBlockType.bullet);
      c.selection = const TextSelection.collapsed(offset: 0);
      expect(c.selection.baseOffset, 2);
    });

    test('headings end at Enter; divider adds a section break', () {
      final c = RichTextController();
      type(c, 'Title');
      c.setBlockType(RichBlockType.heading);
      type(c, '\nBody');
      expect(c.document.blocks.map((b) => b.type), [
        RichBlockType.heading,
        RichBlockType.paragraph,
      ]);
      c.insertDivider();
      expect(c.text, 'Title\nBody\n* * *\n');
      expect(c.document.blocks[2].type, RichBlockType.divider);
      type(c, 'After');
      expect(c.document.plainText, 'Title\nBody\n* * *\nAfter');
      // Typing into a divider turns it back into text.
      c.selection = const TextSelection.collapsed(offset: 16);
      type(c, '!');
      expect(c.document.blocks[2].type, RichBlockType.paragraph);
    });

    test('alignment, links and clear formatting', () {
      final c = RichTextController();
      type(c, 'Visit the shop');
      select(c, 10, 14);
      c.setLink('https://books.example');
      c.setAlign(RichAlign.center);
      var block = c.document.blocks.single;
      expect(block.align, RichAlign.center);
      expect(block.spans.last.href, 'https://books.example');
      expect(block.spans.last.marks, {RichMark.link});
      // Typing right after a link does not extend it.
      c.selection = TextSelection.collapsed(offset: c.text.length);
      type(c, '!');
      expect(c.document.blocks.single.spans.last.text, '!');
      expect(c.document.blocks.single.spans.last.href, isNull);
      select(c, 0, c.text.length);
      c.clearFormatting();
      block = c.document.blocks.single;
      expect(block.spans.single.marks, isEmpty);
      expect(block.align, RichAlign.start);
    });

    test('undo and redo restore text and formatting', () {
      final c = RichTextController();
      type(c, 'Plain');
      select(c, 0, 5);
      c.toggleMark(RichMark.bold);
      c.style = WritingStyle.poetic;
      expect(c.canUndo, isTrue);
      c.undo();
      expect(c.style, WritingStyle.modern);
      expect(c.document.blocks.single.spans.single.marks, {RichMark.bold});
      c.undo();
      expect(c.document.blocks.single.spans.single.marks, isEmpty);
      c.redo();
      expect(c.document.blocks.single.spans.single.marks, {RichMark.bold});
    });

    test('paste arrives as plain text without control characters', () {
      final c = RichTextController();
      type(c, 'A');
      select(c, 0, 1);
      c.toggleMark(RichMark.bold);
      c.selection = const TextSelection.collapsed(offset: 1);
      type(c, 'b\r\nc\u0007d');
      expect(c.text, 'Ab\ncd');
      expect(c.document.blocks.length, 2);
      expect(c.document.plainText, c.text);
    });
  });
}
