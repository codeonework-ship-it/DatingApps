import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'rich_document.dart';
import 'writing_styles.dart';

/// Inline formatting of one character. Immutable so runs compare cheaply.
@immutable
class _Inline {
  const _Inline(this.bits, [this.href]);

  factory _Inline.fromSpan(RichSpan s) {
    var bits = 0;
    for (final m in s.marks) {
      if (m != RichMark.link) {
        bits |= 1 << m.index;
      }
    }
    return _Inline(bits, s.marks.contains(RichMark.link) ? s.href : null);
  }
  static const plain = _Inline(0);

  /// Bit per [RichMark.index], except [RichMark.link], which is [href] != null.
  final int bits;
  final String? href;

  bool has(RichMark m) =>
      m == RichMark.link ? href != null : (bits & (1 << m.index)) != 0;

  Set<RichMark> get marks => {
    for (final m in RichMark.values)
      if (has(m)) m,
  };

  _Inline withMark(RichMark m, {required bool on}) {
    if (m == RichMark.link) {
      return on ? this : _Inline(bits);
    }
    return _Inline(on ? bits | (1 << m.index) : bits & ~(1 << m.index), href);
  }

  _Inline withHref(String? value) => _Inline(bits, value);

  @override
  bool operator ==(Object other) =>
      other is _Inline && other.bits == bits && other.href == href;
  @override
  int get hashCode => Object.hash(bits, href);
}

@immutable
class _Line {
  const _Line([
    this.type = RichBlockType.paragraph,
    this.align = RichAlign.start,
  ]);
  final RichBlockType type;
  final RichAlign align;
  _Line copyWith({RichBlockType? type, RichAlign? align}) =>
      _Line(type ?? this.type, align ?? this.align);

  bool get isList =>
      type == RichBlockType.bullet || type == RichBlockType.numbered;

  /// The format a new line gets after pressing Enter on this one.
  _Line get continuation => switch (type) {
    RichBlockType.heading ||
    RichBlockType.subheading => _Line(RichBlockType.paragraph, align),
    RichBlockType.divider => const _Line(),
    _ => this,
  };
}

class _Snapshot {
  _Snapshot(this.value, this.inline, this.lines, this.style);
  final TextEditingValue value;
  final List<_Inline> inline;
  final List<_Line> lines;
  final WritingStyle style;
}

final _numberedPrefix = RegExp(r'^(\d+)\. ');

/// A [TextEditingController] that keeps formatting alongside the text.
///
/// The editable text is exactly the plain text the server stores: one line per
/// block, list markers ("• ", "1. ") and dividers ("* * *") included. Inline
/// marks live in a parallel per-character list and line formats in a per-line
/// list; every text change (typing, IME, paste, undo) is diffed and both lists
/// are spliced to match. [buildTextSpan] paints the formatting. Pasted text is
/// always plain (control characters stripped) and adopts the formatting at the
/// cursor.
class RichTextController extends TextEditingController {
  RichTextController({
    RichDocument? document,
    WritingStyle style = defaultChapterStyle,
    this.bodyScale = 1,
  }) : _style = document?.style ?? style {
    load(document ?? RichDocument(style: _style, blocks: const []));
  }

  /// Multiplies the writing style's body size (story cards use larger text).
  final double bodyScale;

  WritingStyle _style;
  WritingStyle get style => _style;
  set style(WritingStyle value) {
    if (value == _style) {
      return;
    }
    _pushUndo(force: true);
    _style = value;
    notifyListeners();
  }

  var _inline = <_Inline>[];
  var _lines = <_Line>[const _Line()];
  _Inline? _pending;
  bool _internal = false;
  final _undo = <_Snapshot>[];
  final _redo = <_Snapshot>[];
  DateTime _lastPush = DateTime.fromMillisecondsSinceEpoch(0);
  static const _undoLimit = 100;

  bool get canUndo => _undo.isNotEmpty;
  bool get canRedo => _redo.isNotEmpty;

  /// Replaces everything (no undo entry). Used for initial and saved versions.
  void load(RichDocument document) {
    final text = StringBuffer();
    final inline = <_Inline>[];
    final lines = <_Line>[];
    var number = 0;
    for (var i = 0; i < document.blocks.length; i++) {
      final b = document.blocks[i];
      number = b.type == RichBlockType.numbered ? number + 1 : 0;
      if (i > 0) {
        text.write('\n');
        inline.add(_Inline.plain);
      }
      final prefix = richLinePrefix(b.type, number);
      text.write(prefix);
      inline.addAll(List.filled(prefix.length, _Inline.plain));
      if (b.type != RichBlockType.divider) {
        for (final s in b.spans) {
          text.write(s.text);
          inline.addAll(List.filled(s.text.length, _Inline.fromSpan(s)));
        }
      }
      lines.add(_Line(b.type, b.align));
    }
    if (lines.isEmpty) {
      lines.add(const _Line());
    }
    _style = document.style;
    _inline = inline;
    _lines = lines;
    _pending = null;
    _undo.clear();
    _redo.clear();
    _setInternal(
      TextEditingValue(
        text: text.toString(),
        selection: TextSelection.collapsed(offset: text.length),
      ),
    );
  }

  /// The document for saving. Its [RichDocument.plainText] equals [text].
  RichDocument get document {
    final blocks = <RichBlock>[];
    final t = text;
    var start = 0;
    for (var i = 0; i < _lines.length; i++) {
      final end = _lineEnd(t, start);
      final fmt = _lines[i];
      if (fmt.type == RichBlockType.divider) {
        blocks.add(const RichBlock(RichBlockType.divider));
      } else {
        final contentStart =
            start + _prefixLength(fmt, t.substring(start, end));
        final spans = <RichSpan>[];
        var runStart = contentStart;
        for (var j = contentStart; j <= end; j++) {
          if (j == end || _inline[j] != _inline[runStart]) {
            if (j > runStart) {
              final style = _inline[runStart];
              spans.add(
                RichSpan(
                  t.substring(runStart, j),
                  marks: style.marks,
                  href: style.href,
                ),
              );
            }
            runStart = j;
          }
        }
        blocks.add(RichBlock(fmt.type, align: fmt.align, spans: spans));
      }
      start = end + 1;
    }
    return RichDocument(style: _style, blocks: blocks);
  }

  // ---------------------------------------------------------------------------
  // Text changes from the framework (typing, IME, paste, enterText).

  @override
  set value(TextEditingValue newValue) {
    if (_internal) {
      super.value = newValue;
      return;
    }
    final old = super.value;
    if (newValue.text == old.text) {
      if (newValue.selection != old.selection) {
        _pending = null;
      }
      super.value = newValue.copyWith(
        selection: _clampSelection(old.selection, newValue.selection),
      );
      return;
    }
    _applyExternal(old, newValue);
  }

  void _applyExternal(TextEditingValue old, TextEditingValue next) {
    final o = old.text, n = next.text;
    final lo = o.length, ln = n.length, delta = ln - lo;
    final selEnd = next.selection.isValid
        ? next.selection.end.clamp(0, ln)
        : ln;
    var p = 0;
    final maxP = math.min(lo, ln);
    while (p < maxP && o.codeUnitAt(p) == n.codeUnitAt(p)) {
      p++;
    }
    // Disambiguate repeated characters with the caret (typing "a" after "a").
    p = math.min(p, math.max(0, delta > 0 ? selEnd - delta : selEnd));
    var s = 0;
    final maxS = math.min(lo, ln) - p;
    while (s < maxS && o.codeUnitAt(lo - 1 - s) == n.codeUnitAt(ln - 1 - s)) {
      s++;
    }
    final removedEnd = lo - s;
    final raw = n.substring(p, ln - s);
    final clean = raw
        .replaceAll('\r\n', '\n')
        .replaceAll(RegExp('[\r  ]'), '\n')
        .replaceAll(RegExp(r'[\u0000-\u0008\u000b-\u001f\u007f]'), '');
    int mapNext(int x) {
      if (x < 0) {
        return x;
      }
      if (x <= p) {
        return x;
      }
      if (x >= p + raw.length) {
        return x + clean.length - raw.length;
      }
      return p + clean.length;
    }

    final simpleTyping = clean.length == 1 && clean != '\n' && removedEnd == p;
    _pushUndo(force: !simpleTyping);
    _redo.clear();

    var selection = next.selection.isValid
        ? TextSelection(
            baseOffset: mapNext(next.selection.baseOffset),
            extentOffset: mapNext(next.selection.extentOffset),
          )
        : TextSelection.collapsed(offset: p + clean.length);

    // Enter on an empty list item ends the list instead of adding an item.
    if (clean == '\n' && removedEnd == p) {
      final line = _lineIndexAt(o, p);
      final start = _lineStartOf(o, line);
      final end = _lineEnd(o, start);
      final fmt = _lines[line];
      if (fmt.isList &&
          p == end &&
          _prefixLength(fmt, o.substring(start, end)) == end - start) {
        _lines[line] = fmt.copyWith(type: RichBlockType.paragraph);
        final t = _spliceText(o, start, end, '', const []);
        _pending = null;
        _finish(t, TextSelection.collapsed(offset: start), next.composing);
        return;
      }
    }

    final styleForInsert = _pending ?? _inheritAt(o, p);
    _pending = null;
    final (t, fresh) = _splice(
      o,
      p,
      removedEnd,
      clean,
      List.filled(clean.length, styleForInsert),
    );
    final normalised = _normalise(t, fresh, selection);
    selection = normalised.$2;
    _finish(
      normalised.$1,
      selection,
      normalised.$3 ? TextRange.empty : next.composing,
    );
  }

  void _finish(String t, TextSelection selection, TextRange composing) {
    final valid = composing.isValid && composing.end <= t.length;
    _setInternal(
      TextEditingValue(
        text: t,
        selection: selection,
        composing: valid ? composing : TextRange.empty,
      ),
    );
  }

  void _setInternal(TextEditingValue v) {
    _internal = true;
    try {
      final changed = super.value != v;
      super.value = v;
      if (!changed) {
        notifyListeners();
      }
    } finally {
      _internal = false;
    }
  }

  // ---------------------------------------------------------------------------
  // Model helpers.

  static int _lineEnd(String t, int start) {
    final i = t.indexOf('\n', start);
    return i < 0 ? t.length : i;
  }

  static int _lineIndexAt(String t, int offset) {
    var line = 0;
    for (var i = 0; i < offset && i < t.length; i++) {
      if (t.codeUnitAt(i) == 10) {
        line++;
      }
    }
    return line;
  }

  static int _lineStartOf(String t, int line) {
    var start = 0;
    for (var i = 0; i < line; i++) {
      start = _lineEnd(t, start) + 1;
    }
    return start;
  }

  /// Length of the list marker or divider text currently at the line start.
  static int _prefixLength(_Line fmt, String line) {
    switch (fmt.type) {
      case RichBlockType.bullet:
        return line.startsWith(richBulletPrefix) ? richBulletPrefix.length : 0;
      case RichBlockType.numbered:
        return _numberedPrefix.matchAsPrefix(line)?.end ?? 0;
      case RichBlockType.divider:
        return line.length;
      default:
        return 0;
    }
  }

  _Inline _inheritAt(String t, int p) {
    final line = _lineIndexAt(t, p);
    final start = _lineStartOf(t, line);
    final end = _lineEnd(t, start);
    final contentStart =
        start + _prefixLength(_lines[line], t.substring(start, end));
    final before = p > contentStart && p <= end ? _inline[p - 1] : null;
    final after = p >= contentStart && p < end ? _inline[p] : null;
    final base = before ?? after ?? _Inline.plain;
    // Typing at the edge of a link does not extend the link.
    if (base.href != null && before?.href != after?.href) {
      return base.withHref(null);
    }
    return base;
  }

  /// Replaces [start, end) with [ins], keeping inline and line lists in step.
  /// Returns the new text and the indices of lines created by the insertion.
  (String, Set<int>) _splice(
    String t,
    int start,
    int end,
    String ins,
    List<_Inline> styles, {
    List<_Line>? lineFormats,
  }) {
    final line = _lineIndexAt(t, start);
    final removedLines = '\n'.allMatches(t.substring(start, end)).length;
    final addedLines = '\n'.allMatches(ins).length;
    final base = _lines[line];
    final fresh = <int>{};
    List<_Line> formats;
    if (lineFormats != null) {
      formats = lineFormats;
    } else if (addedLines == 0) {
      formats = [base];
    } else if (start == _lineStartOf(t, line) && start < _lineEnd(t, start)) {
      // Enter at the very start of a line moves the whole line down.
      formats = [for (var i = 0; i < addedLines; i++) const _Line(), base];
    } else {
      formats = [base, for (var i = 0; i < addedLines; i++) base.continuation];
      for (var i = 1; i <= addedLines; i++) {
        fresh.add(line + i);
      }
    }
    _lines.replaceRange(line, line + removedLines + 1, formats);
    final result = _spliceText(t, start, end, ins, styles);
    return (result, fresh);
  }

  String _spliceText(
    String t,
    int start,
    int end,
    String ins,
    List<_Inline> styles,
  ) {
    _inline.replaceRange(start, end, styles);
    return t.replaceRange(start, end, ins);
  }

  static int _mapOffset(int x, int start, int end, int insLen) {
    if (x < 0 || x <= start) {
      return x;
    }
    if (x >= end) {
      return x + insLen - (end - start);
    }
    return start + insLen;
  }

  static TextSelection _mapSelection(
    TextSelection s,
    int start,
    int end,
    int insLen,
  ) => s.isValid
      ? TextSelection(
          baseOffset: _mapOffset(s.baseOffset, start, end, insLen),
          extentOffset: _mapOffset(s.extentOffset, start, end, insLen),
        )
      : s;

  /// Makes list markers, numbering and dividers match the line formats.
  /// Fresh list lines (from Enter) gain a marker; a damaged marker (the author
  /// deleted part of it) turns the line back into a paragraph.
  (String, TextSelection, bool) _normalise(
    String text,
    Set<int> fresh,
    TextSelection initial,
  ) {
    var t = text;
    var selection = initial;
    var changed = false;
    var start = 0;
    var number = 0;
    for (var i = 0; i < _lines.length; i++) {
      var end = _lineEnd(t, start);
      final line = t.substring(start, end);
      final fmt = _lines[i];
      number = fmt.type == RichBlockType.numbered ? number + 1 : 0;
      String? replaceWith;
      var replaceLength = 0;
      if (fmt.type == RichBlockType.bullet &&
          !line.startsWith(richBulletPrefix)) {
        if (fresh.contains(i)) {
          replaceWith = richBulletPrefix;
        } else {
          _lines[i] = fmt.copyWith(type: RichBlockType.paragraph);
          replaceLength = _damagedPrefix(line, richBulletPrefix);
          replaceWith = '';
        }
      } else if (fmt.type == RichBlockType.numbered) {
        final match = _numberedPrefix.matchAsPrefix(line);
        final expected = '$number. ';
        if (match != null) {
          if (match.group(0) != expected) {
            replaceWith = expected;
            replaceLength = match.end;
          }
        } else if (fresh.contains(i)) {
          replaceWith = expected;
        } else {
          _lines[i] = fmt.copyWith(type: RichBlockType.paragraph);
          replaceLength = _damagedPrefix(line, expected);
          replaceWith = '';
          number = 0;
        }
      } else if (fmt.type == RichBlockType.divider && line != richDividerText) {
        _lines[i] = const _Line();
      }
      if (replaceWith != null &&
          (replaceWith.isNotEmpty || replaceLength > 0)) {
        t = _spliceText(
          t,
          start,
          start + replaceLength,
          replaceWith,
          List.filled(replaceWith.length, _Inline.plain),
        );
        if (fresh.contains(i) &&
            selection.isCollapsed &&
            selection.baseOffset == start) {
          // Keep the caret after a marker added in front of it.
          selection = TextSelection.collapsed(
            offset: start + replaceWith.length,
          );
        } else {
          selection = _mapSelection(
            selection,
            start,
            start + replaceLength,
            replaceWith.length,
          );
        }
        end += replaceWith.length - replaceLength;
        changed = true;
      }
      start = end + 1;
    }
    return (t, selection, changed);
  }

  /// How many characters of a marker with one character deleted remain.
  static int _damagedPrefix(String line, String prefix) {
    for (var i = 0; i < prefix.length; i++) {
      final candidate = prefix.substring(0, i) + prefix.substring(i + 1);
      if (candidate.isNotEmpty && line.startsWith(candidate)) {
        return candidate.length;
      }
    }
    return 0;
  }

  /// Keeps a collapsed caret out of list markers so typing lands in the text.
  TextSelection _clampSelection(TextSelection old, TextSelection next) {
    if (!next.isValid || !next.isCollapsed) {
      return next;
    }
    final t = text;
    final offset = next.baseOffset.clamp(0, t.length);
    final line = _lineIndexAt(t, offset);
    if (line >= _lines.length || !_lines[line].isList) {
      return next;
    }
    final start = _lineStartOf(t, line);
    final contentStart =
        start +
        _prefixLength(_lines[line], t.substring(start, _lineEnd(t, start)));
    if (offset >= contentStart || offset < start) {
      return next;
    }
    // Arrow-left from the start of the text continues to the previous line.
    if (old.isCollapsed &&
        old.baseOffset == contentStart &&
        offset == contentStart - 1 &&
        start > 0) {
      return TextSelection.collapsed(offset: start - 1);
    }
    return TextSelection.collapsed(offset: contentStart);
  }

  // ---------------------------------------------------------------------------
  // Undo and redo (formatting included). The text field's own undo history only
  // knows text, so the editor routes Undo/Redo shortcuts here.

  void _pushUndo({bool force = false}) {
    final now = DateTime.now();
    if (!force && now.difference(_lastPush).inMilliseconds < 1000) {
      _lastPush = now;
      return;
    }
    _lastPush = force ? DateTime.fromMillisecondsSinceEpoch(0) : now;
    _undo.add(_snapshot());
    if (_undo.length > _undoLimit) {
      _undo.removeAt(0);
    }
  }

  _Snapshot _snapshot() =>
      _Snapshot(super.value, List.of(_inline), List.of(_lines), _style);

  void _restore(_Snapshot s) {
    _inline = List.of(s.inline);
    _lines = List.of(s.lines);
    _style = s.style;
    _pending = null;
    _setInternal(s.value.copyWith(composing: TextRange.empty));
  }

  void undo() {
    if (_undo.isEmpty) {
      return;
    }
    _redo.add(_snapshot());
    _restore(_undo.removeLast());
    _lastPush = DateTime.fromMillisecondsSinceEpoch(0);
  }

  void redo() {
    if (_redo.isEmpty) {
      return;
    }
    _undo.add(_snapshot());
    _restore(_redo.removeLast());
    _lastPush = DateTime.fromMillisecondsSinceEpoch(0);
  }

  // ---------------------------------------------------------------------------
  // Formatting commands (toolbar and keyboard shortcuts).

  TextSelection get _safeSelection {
    final s = selection;
    if (!s.isValid) {
      return TextSelection.collapsed(offset: text.length);
    }
    return TextSelection(
      baseOffset: s.baseOffset.clamp(0, text.length),
      extentOffset: s.extentOffset.clamp(0, text.length),
    );
  }

  /// Character indices that carry inline formatting in [start, end): not line
  /// breaks, list markers or divider text.
  Iterable<int> _contentIndices(int start, int end) sync* {
    final t = text;
    var lineStart = 0;
    for (var i = 0; i < _lines.length; i++) {
      final lineEnd = _lineEnd(t, lineStart);
      if (lineEnd >= start && lineStart <= end) {
        final contentStart =
            lineStart +
            _prefixLength(_lines[i], t.substring(lineStart, lineEnd));
        for (
          var j = math.max(start, contentStart);
          j < math.min(end, lineEnd);
          j++
        ) {
          yield j;
        }
      }
      if (lineStart > end) {
        break;
      }
      lineStart = lineEnd + 1;
    }
  }

  /// Marks active at the caret or shared by the whole selection.
  Set<RichMark> get activeMarks {
    final s = _safeSelection;
    if (s.isCollapsed) {
      return (_pending ?? _inheritAt(text, s.start)).marks;
    }
    final indices = _contentIndices(s.start, s.end).toList();
    if (indices.isEmpty) {
      return const {};
    }
    return {
      for (final m in RichMark.values)
        if (indices.every((i) => _inline[i].has(m))) m,
    };
  }

  /// The link under the caret or selection start, if any.
  String? get activeHref {
    final s = _safeSelection;
    if (s.isCollapsed) {
      final t = text;
      if (s.start < t.length && _inline[s.start].href != null) {
        return _inline[s.start].href;
      }
      return s.start > 0 ? _inline[s.start - 1].href : null;
    }
    final indices = _contentIndices(s.start, s.end).toList();
    final first = indices.isEmpty ? null : _inline[indices.first].href;
    return indices.every((i) => _inline[i].href == first) ? first : null;
  }

  /// Format of the line holding the selection start.
  RichBlockType get activeBlockType =>
      _lines[_lineIndexAt(text, _safeSelection.start)].type;
  RichAlign get activeAlign =>
      _lines[_lineIndexAt(text, _safeSelection.start)].align;

  void toggleMark(RichMark mark) {
    if (mark == RichMark.link) {
      // Adding a link needs an address (the editor asks); toggling removes it.
      if (activeHref != null) {
        setLink(null);
      }
      return;
    }
    final s = _safeSelection;
    final on = !activeMarks.contains(mark);
    if (s.isCollapsed) {
      _pending = (_pending ?? _inheritAt(text, s.start)).withMark(mark, on: on);
      notifyListeners();
      return;
    }
    _pushUndo(force: true);
    _redo.clear();
    for (final i in _contentIndices(s.start, s.end)) {
      _inline[i] = _inline[i].withMark(mark, on: on);
    }
    notifyListeners();
  }

  /// Links (or with null, unlinks) the selected text. With a collapsed caret
  /// inside a link, the whole link is changed.
  void setLink(String? href) {
    assert(
      href == null || isSafeRichHref(href),
      'links must be complete https addresses',
    );
    var s = _safeSelection;
    if (s.isCollapsed) {
      final current = activeHref;
      if (current == null) {
        return;
      }
      var a = s.start, b = s.start;
      while (a > 0 && _inline[a - 1].href == current) {
        a--;
      }
      while (b < text.length && _inline[b].href == current) {
        b++;
      }
      s = TextSelection(baseOffset: a, extentOffset: b);
    }
    _pushUndo(force: true);
    _redo.clear();
    for (final i in _contentIndices(s.start, s.end)) {
      _inline[i] = _inline[i].withHref(href);
    }
    notifyListeners();
  }

  /// Applies [type] to every line the selection touches; applying the type
  /// all those lines already have turns them back into paragraphs.
  void setBlockType(RichBlockType type) {
    if (type == RichBlockType.divider) {
      insertDivider();
      return;
    }
    final s = _safeSelection;
    var t = text;
    final first = _lineIndexAt(t, s.start), last = _lineIndexAt(t, s.end);
    final all = [for (var i = first; i <= last; i++) _lines[i].type];
    final target = all.every((v) => v == type) ? RichBlockType.paragraph : type;
    _pushUndo(force: true);
    _redo.clear();
    var selection = s;
    for (var i = last; i >= first; i--) {
      final start = _lineStartOf(t, i);
      final end = _lineEnd(t, start);
      final fmt = _lines[i];
      final old = _prefixLength(fmt, t.substring(start, end));
      final prefix = switch (target) {
        RichBlockType.bullet => richBulletPrefix,
        RichBlockType.numbered => '1. ',
        _ => '',
      };
      t = _spliceText(
        t,
        start,
        start + old,
        prefix,
        List.filled(prefix.length, _Inline.plain),
      );
      selection = _mapSelection(selection, start, start + old, prefix.length);
      if (selection.isCollapsed &&
          selection.baseOffset == start &&
          prefix.isNotEmpty) {
        selection = TextSelection.collapsed(offset: start + prefix.length);
      }
      _lines[i] = fmt.copyWith(type: target);
    }
    final normalised = _normalise(t, const {}, selection);
    _finish(normalised.$1, normalised.$2, TextRange.empty);
  }

  void setAlign(RichAlign align) {
    final s = _safeSelection;
    final t = text;
    _pushUndo(force: true);
    _redo.clear();
    for (var i = _lineIndexAt(t, s.start); i <= _lineIndexAt(t, s.end); i++) {
      if (_lines[i].type != RichBlockType.divider) {
        _lines[i] = _lines[i].copyWith(align: align);
      }
    }
    notifyListeners();
  }

  /// Adds a section break after the current line (or turns an empty line
  /// into one) and moves the caret to a paragraph below it.
  void insertDivider() {
    final s = _safeSelection;
    final t = text;
    final line = _lineIndexAt(t, s.end);
    final start = _lineStartOf(t, line);
    final end = _lineEnd(t, start);
    _pushUndo(force: true);
    _redo.clear();
    final isLast = line == _lines.length - 1;
    String next;
    int caret;
    if (start == end && _lines[line].type == RichBlockType.paragraph) {
      final ins = isLast ? '$richDividerText\n' : richDividerText;
      final (r, _) = _splice(
        t,
        start,
        end,
        ins,
        List.filled(ins.length, _Inline.plain),
        lineFormats: [
          const _Line(RichBlockType.divider),
          if (isLast) const _Line(),
        ],
      );
      next = r;
      caret = start + richDividerText.length + 1;
    } else {
      final ins = isLast ? '\n$richDividerText\n' : '\n$richDividerText';
      final (r, _) = _splice(
        t,
        end,
        end,
        ins,
        List.filled(ins.length, _Inline.plain),
        lineFormats: [
          _lines[line],
          const _Line(RichBlockType.divider),
          if (isLast) const _Line(),
        ],
      );
      next = r;
      caret = end + ins.length;
      if (!isLast) {
        caret = math.min(next.length, caret + 1);
      }
    }
    final normalised = _normalise(
      next,
      const {},
      TextSelection.collapsed(offset: caret),
    );
    _finish(normalised.$1, normalised.$2, TextRange.empty);
  }

  /// Removes inline marks from the selection and resets its lines to plain
  /// start-aligned paragraphs (dividers stay).
  void clearFormatting() {
    final s = _safeSelection;
    if (s.isCollapsed) {
      _pending = _Inline.plain;
    }
    _pushUndo(force: true);
    _redo.clear();
    for (final i in _contentIndices(s.start, s.end)) {
      _inline[i] = _Inline.plain;
    }
    final t = text;
    var selection = s;
    var next = t;
    for (var i = _lineIndexAt(t, s.end); i >= _lineIndexAt(t, s.start); i--) {
      final fmt = _lines[i];
      if (fmt.type == RichBlockType.divider) {
        continue;
      }
      final start = _lineStartOf(next, i);
      final old = _prefixLength(
        fmt,
        next.substring(start, _lineEnd(next, start)),
      );
      if (old > 0) {
        next = _spliceText(next, start, start + old, '', const []);
        selection = _mapSelection(selection, start, start + old, 0);
      }
      _lines[i] = const _Line();
    }
    final normalised = _normalise(next, const {}, selection);
    _finish(normalised.$1, normalised.$2, TextRange.empty);
  }

  // ---------------------------------------------------------------------------
  // Painting.

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    required bool withComposing,
    TextStyle? style,
  }) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final spec = WritingStyleSpec.of(_style);
    final body = (style ?? const TextStyle()).merge(
      spec.body(theme, scale: bodyScale),
    );
    final t = text;
    final composing = withComposing && value.isComposingRangeValid
        ? value.composing
        : TextRange.empty;
    final children = <InlineSpan>[];
    var start = 0;
    for (var i = 0; i < _lines.length && start <= t.length; i++) {
      final end = _lineEnd(t, start);
      final fmt = _lines[i];
      final lineStyle = switch (fmt.type) {
        RichBlockType.heading => body.merge(
          spec.heading(theme, scale: bodyScale),
        ),
        RichBlockType.subheading => body.merge(
          spec.heading(theme, sub: true, scale: bodyScale),
        ),
        RichBlockType.quote => body.copyWith(
          fontStyle: FontStyle.italic,
          color: colors.onSurfaceVariant,
        ),
        RichBlockType.callout => body.copyWith(
          backgroundColor: colors.secondaryContainer,
          color: colors.onSecondaryContainer,
        ),
        RichBlockType.divider => body.copyWith(
          color: colors.outline,
          letterSpacing: 4,
        ),
        _ => body,
      };
      final prefix = _prefixLength(fmt, t.substring(start, end));
      if (prefix > 0) {
        children.add(
          TextSpan(
            text: t.substring(start, start + prefix),
            style: fmt.type == RichBlockType.divider
                ? lineStyle
                : lineStyle.copyWith(
                    color: colors.primary,
                    fontWeight: FontWeight.w700,
                  ),
          ),
        );
      }
      var runStart = start + prefix;
      bool inComposing(int j) => j >= composing.start && j < composing.end;
      for (var j = runStart; j <= end; j++) {
        if (j == end ||
            _inline[j] != _inline[runStart] ||
            inComposing(j) != inComposing(runStart)) {
          if (j > runStart) {
            var spanStyle = applyRichMarks(
              lineStyle,
              _inline[runStart].marks,
              colors,
            );
            if (inComposing(runStart)) {
              spanStyle = spanStyle.copyWith(
                decoration: TextDecoration.underline,
              );
            }
            children.add(
              TextSpan(text: t.substring(runStart, j), style: spanStyle),
            );
          }
          runStart = j;
        }
      }
      if (end < t.length) {
        children.add(TextSpan(text: '\n', style: lineStyle));
      }
      start = end + 1;
    }
    return TextSpan(style: body, children: children);
  }
}
