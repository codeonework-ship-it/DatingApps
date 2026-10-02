/// The formatted-writing model shared by Open Chapters and profile stories.
///
/// It mirrors the server's constrained block model
/// (backend/internal/bff/mobile/rich_text.go): never HTML, one block per line
/// of the plain text. [RichDocument.plainText] derives exactly the text the
/// server stores in `body`, so search, excerpts, wall cards and older clients
/// read the same words. See documents/RICH_TEXT_WRITING_STYLES_2026-10-01.md.
library;

/// Line-level formatting. Unknown server values read as [paragraph].
enum RichBlockType {
  paragraph,
  heading,
  subheading,
  quote,
  bullet,
  numbered,
  divider,
  callout,
}

enum RichAlign { start, center, end }

/// Inline formatting. The order is the canonical order the server stores.
enum RichMark { bold, italic, underline, strikethrough, highlight, link }

/// A per-document look the author picks. Each maps to bundled fonts only.
enum WritingStyle { classic, modern, journal, typewriter, poetic }

const richBulletPrefix = '• ';
const richDividerText = '* * *';

/// Default style for chapters: matches how plain chapters always rendered.
const WritingStyle defaultChapterStyle = WritingStyle.modern;

/// Default style for profile stories: matches the existing story card.
const WritingStyle defaultStoryStyle = WritingStyle.classic;

T? _byName<T extends Enum>(List<T> values, Object? name) {
  for (final v in values) {
    if (v.name == name) {
      return v;
    }
  }
  return null;
}

WritingStyle writingStyleFromName(Object? name, {WritingStyle? fallback}) =>
    _byName(WritingStyle.values, name) ?? fallback ?? defaultChapterStyle;

/// Only absolute https links to a named host, without credentials or spaces.
/// The server enforces the same rule; this keeps the editor honest.
bool isSafeRichHref(String raw) {
  if (raw.isEmpty || raw.length > 2048 || raw.trim() != raw) {
    return false;
  }
  if (RegExp(r'[\s\u0000-\u001f\u007f]').hasMatch(raw)) {
    return false;
  }
  final uri = Uri.tryParse(raw);
  return uri != null &&
      uri.scheme.toLowerCase() == 'https' &&
      uri.host.isNotEmpty &&
      uri.userInfo.isEmpty;
}

class RichSpan {
  const RichSpan(this.text, {this.marks = const {}, this.href});
  final String text;
  final Set<RichMark> marks;

  /// Set only together with [RichMark.link].
  final String? href;

  Map<String, dynamic> toJson() => {
    'text': text,
    if (marks.isNotEmpty)
      'marks': [
        for (final m in RichMark.values)
          if (marks.contains(m)) m.name,
      ],
    if (href != null && marks.contains(RichMark.link)) 'href': href,
  };
}

class RichBlock {
  const RichBlock(
    this.type, {
    this.align = RichAlign.start,
    this.spans = const [],
  });
  final RichBlockType type;
  final RichAlign align;
  final List<RichSpan> spans;

  String get text => spans.map((s) => s.text).join();

  Map<String, dynamic> toJson() => {
    'type': type.name,
    if (align != RichAlign.start && type != RichBlockType.divider)
      'align': align.name,
    if (type != RichBlockType.divider && spans.isNotEmpty)
      'spans': [
        for (final s in spans)
          if (s.text.isNotEmpty) s.toJson(),
      ],
  };
}

/// The plain-text marker a block contributes before its own text. [number] is
/// the 1-based position in a run of consecutive numbered blocks.
String richLinePrefix(RichBlockType type, int number) => switch (type) {
  RichBlockType.bullet => richBulletPrefix,
  RichBlockType.numbered => '$number. ',
  RichBlockType.divider => richDividerText,
  _ => '',
};

class RichDocument {
  const RichDocument({required this.style, required this.blocks});

  /// One paragraph per line, so legacy plain text round-trips unchanged.
  factory RichDocument.fromPlainText(
    String text, {
    WritingStyle style = defaultChapterStyle,
  }) => RichDocument(
    style: style,
    blocks: [
      if (text.isNotEmpty)
        for (final line in text.replaceAll('\r\n', '\n').split('\n'))
          RichBlock(
            RichBlockType.paragraph,
            spans: line.isEmpty ? const [] : [RichSpan(line)],
          ),
    ],
  );

  final WritingStyle style;
  final List<RichBlock> blocks;

  /// Reads a server document. Returns null for anything that is not a
  /// version-1 document so callers fall back to the plain text. Unknown block
  /// types or marks from a newer server degrade to plain paragraphs and text.
  static RichDocument? tryParse(Object? json, {WritingStyle? fallbackStyle}) {
    if (json is! Map || json['version'] != 1 || json['blocks'] is! List) {
      return null;
    }
    final blocks = <RichBlock>[];
    for (final raw in json['blocks'] as List) {
      if (raw is! Map) {
        continue;
      }
      final type =
          _byName(RichBlockType.values, raw['type']) ?? RichBlockType.paragraph;
      final align = _byName(RichAlign.values, raw['align']) ?? RichAlign.start;
      final spans = <RichSpan>[];
      if (type != RichBlockType.divider && raw['spans'] is List) {
        for (final s in raw['spans'] as List) {
          if (s is! Map || s['text'] is! String) {
            continue;
          }
          final text = (s['text'] as String).replaceAll(
            RegExp(r'[\n\r  ]'),
            ' ',
          );
          if (text.isEmpty) {
            continue;
          }
          final marks = <RichMark>{
            if (s['marks'] is List)
              for (final m in s['marks'] as List) ?_byName(RichMark.values, m),
          };
          var href = s['href'] is String ? s['href'] as String : null;
          if (href == null || !isSafeRichHref(href)) {
            href = null;
            marks.remove(RichMark.link);
          }
          if (!marks.contains(RichMark.link)) {
            href = null;
          }
          spans.add(RichSpan(text, marks: marks, href: href));
        }
      }
      blocks.add(RichBlock(type, align: align, spans: spans));
    }
    return RichDocument(
      style: writingStyleFromName(
        json['style'],
        fallback: fallbackStyle ?? defaultChapterStyle,
      ),
      blocks: blocks,
    );
  }

  /// The text the server stores in `body`: one line per block, list markers
  /// included, dividers as "* * *". Not trimmed.
  String get plainText {
    final lines = <String>[];
    var number = 0;
    for (final b in blocks) {
      number = b.type == RichBlockType.numbered ? number + 1 : 0;
      lines.add(richLinePrefix(b.type, number) + b.text);
    }
    return lines.join('\n');
  }

  /// Whether the document has any formatting beyond plain paragraphs.
  bool get isFormatted =>
      blocks.any(
        (b) => b.type != RichBlockType.paragraph || b.align != RichAlign.start,
      ) ||
      blocks.any((b) => b.spans.any((s) => s.marks.isNotEmpty));

  /// Words in the author's own text (list markers and dividers excluded).
  int get wordCount => blocks.fold(
    0,
    (sum, b) =>
        sum +
        RegExp(
          r"[\p{L}\p{N}][\p{L}\p{N}'’\-]*",
          unicode: true,
        ).allMatches(b.text).length,
  );

  Map<String, dynamic> toJson() => {
    'version': 1,
    'style': style.name,
    'blocks': [for (final b in blocks) b.toJson()],
  };
}
