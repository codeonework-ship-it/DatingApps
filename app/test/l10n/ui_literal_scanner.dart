// Source scanner behind hardcoded_strings_guard_test.dart.
//
// It lexes Dart source well enough to find string literals outside comments,
// then decides from the code right before each literal whether the literal is
// rendered to members:
//  * the first positional argument of Text / SelectableText / Tooltip-like
//    widgets (`Text('Hi')`, `const Text('Hi')`);
//  * a named argument whose name is one of [uiParams] (`title: 'Hi'`);
//  * either branch of a ternary, a `??` fallback or a `+` concatenation inside
//    those (`title: busy ? 'Saving' : 'Save'`).
// A literal counts as text when it has words: a space between letters, a
// capitalised word, or an apostrophe inside a word ("don't"). Single
// lower-case tokens ('long_term', 'auto') are codes and do not count.
//
// It also reports automation ids used as spoken labels (`label: 'qa.…'`,
// `semanticLabel: qaId`), raw exception text in UI (`Text(e.toString())`,
// `content: Text('$e')`) and dropdown items rendered raw
// (`DropdownMenuItem(value: item, child: Text(item))`).

/// Named arguments whose string value is shown or spoken.
const uiParams = <String>{
  'label',
  'labelText',
  'hint',
  'hintText',
  'helperText',
  'helpText',
  'tooltip',
  'title',
  'subtitle',
  'message',
  'semanticsLabel',
  'semanticLabel',
  'semanticsValue',
  'content',
  'caption',
  'action',
  'actionLabel',
  'body',
  'error',
  'errorText',
  'errorFormatText',
  'errorInvalidText',
  'fieldLabelText',
  'fieldHintText',
  'text',
  'heading',
  'description',
  'cta',
  'ctaLabel',
  'buttonLabel',
  'buttonText',
  'emptyText',
  'emptyTitle',
  'emptyMessage',
  'placeholder',
  'prefixText',
  'suffixText',
  'counterText',
  'cancelText',
  'confirmText',
  'saveText',
  'barrierLabel',
  'headline',
  'subtitleText',
  'titleText',
};

/// Widgets whose first positional argument is displayed text.
const _textWidgets = <String>{'Text', 'SelectableText', 'TextSpan'};

class UiLiteral {
  UiLiteral(this.kind, this.text, this.line);

  /// 'text', 'qa-label', 'raw-error' or 'raw-dropdown'.
  final String kind;
  final String text;
  final int line;

  @override
  String toString() => '$kind:$line: $text';
}

class _Literal {
  _Literal(this.start, this.end, this.value);
  final int start;
  final int end;
  final String value;
}

/// [source] with comments and string contents blanked (same length, so
/// offsets line up), plus the string literals found.
(String, List<_Literal>) _lex(String source) {
  final code = StringBuffer();
  final literals = <_Literal>[];
  var i = 0;
  final n = source.length;
  void blank(int from, int to) {
    for (var k = from; k < to; k++) {
      code.write(source[k] == '\n' ? '\n' : ' ');
    }
  }

  while (i < n) {
    final c = source[i];
    if (c == '/' && i + 1 < n && source[i + 1] == '/') {
      final end = source.indexOf('\n', i);
      final stop = end < 0 ? n : end;
      blank(i, stop);
      i = stop;
      continue;
    }
    if (c == '/' && i + 1 < n && source[i + 1] == '*') {
      var depth = 1;
      var j = i + 2;
      while (j < n && depth > 0) {
        if (source.startsWith('/*', j)) {
          depth++;
          j += 2;
        } else if (source.startsWith('*/', j)) {
          depth--;
          j += 2;
        } else {
          j++;
        }
      }
      blank(i, j);
      i = j;
      continue;
    }
    final raw =
        c == 'r' && i + 1 < n && (source[i + 1] == "'" || source[i + 1] == '"');
    if (c == "'" || c == '"' || raw) {
      final q0 = raw ? i + 1 : i;
      final quote = source[q0];
      final triple = source.startsWith(quote * 3, q0);
      final delim = triple ? quote * 3 : quote;
      var j = q0 + delim.length;
      final buf = StringBuffer();
      while (j < n) {
        if (!raw && source[j] == r'\') {
          buf.write(source.substring(j, j + 2 > n ? n : j + 2));
          j += 2;
          continue;
        }
        if (source.startsWith(delim, j)) {
          break;
        }
        if (!raw && source[j] == r'$' && j + 1 < n && source[j + 1] == '{') {
          // Interpolated expression: skip to the matching brace.
          var depth = 0;
          var k = j + 1;
          while (k < n) {
            if (source[k] == '{') depth++;
            if (source[k] == '}') {
              depth--;
              if (depth == 0) break;
            }
            k++;
          }
          buf.write(source.substring(j, k + 1 > n ? n : k + 1));
          j = k + 1;
          continue;
        }
        if (!triple && source[j] == '\n') {
          break; // unterminated: give up on this literal
        }
        buf.write(source[j]);
        j++;
      }
      final end = j + delim.length > n ? n : j + delim.length;
      literals.add(_Literal(i, end, buf.toString()));
      if (raw) {
        code.write('r');
      }
      code.write(quote);
      blank(raw ? i + 2 : i + 1, end - 1);
      code.write(quote);
      i = end;
      continue;
    }
    code.write(c);
    i++;
  }
  return (code.toString(), literals);
}

final _interpolation = RegExp(r'\$\{[^}]*\}|\$[A-Za-z_]\w*');

/// Whether a literal's content reads as words a member would see.
bool looksLikeText(String value) {
  final stripped = value.replaceAll(_interpolation, ' ').trim();
  if (stripped.isEmpty || value.startsWith('qa.')) {
    return false;
  }
  if (stripped.contains('://') || stripped.startsWith('assets/')) {
    return false;
  }
  final hasSpacedWords = RegExp(
    r'[A-Za-zÀ-ÿ]{2,}\s+[A-Za-zÀ-ÿ]',
  ).hasMatch(stripped);
  final capitalisedWord = RegExp(r'(^|\s)[A-Z][a-z]{2,}').hasMatch(stripped);
  final apostropheWord = RegExp(r"[A-Za-z]'[A-Za-z]").hasMatch(stripped);
  return hasSpacedWords || capitalisedWord || apostropheWord;
}

final _uiParamPattern = RegExp(r'^\s*([A-Za-z_]\w*)\s*:');
final _nextIsComparison = RegExp(r'^\s*(==|!=|\.)');

/// The literals in [source] that are rendered or spoken as UI text.
List<UiLiteral> scanUiLiterals(String source) {
  final (code, literals) = _lex(source);
  final out = <UiLiteral>[];
  int lineOf(int offset) =>
      '\n'.allMatches(code.substring(0, offset)).length + 1;

  for (final literal in literals) {
    // Walk back to the enclosing argument start at bracket depth 0.
    var depth = 0;
    var k = literal.start - 1;
    var opener = -1;
    while (k >= 0) {
      final ch = code[k];
      if (ch == ')' || ch == ']' || ch == '}') {
        depth++;
      } else if (ch == '(' || ch == '[' || ch == '{') {
        if (depth == 0) {
          opener = k;
          break;
        }
        depth--;
      } else if ((ch == ',' || ch == ';') && depth == 0) {
        opener = k;
        break;
      }
      k--;
    }
    if (opener < 0) {
      continue;
    }
    final segment = code.substring(opener + 1, literal.start);
    final before = segment.trimRight();
    final after = code.substring(
      literal.end,
      (literal.end + 4).clamp(0, code.length),
    );
    if (_nextIsComparison.hasMatch(after)) {
      continue;
    }
    // What directly precedes the literal must make it the value.
    final ok =
        before.isEmpty ||
        before.endsWith('?') ||
        before.endsWith('??') ||
        before.endsWith('+') ||
        before.endsWith(':') ||
        before.endsWith("'") ||
        before.endsWith('"') ||
        before.endsWith('=>');
    if (!ok || before.endsWith('==') || before.endsWith('!=')) {
      continue;
    }
    String? context;
    final param = _uiParamPattern.firstMatch(segment);
    if (param != null && code[opener] != '{' && code[opener] != '[') {
      if (uiParams.contains(param.group(1))) {
        context = param.group(1);
      }
    } else if (param == null && code[opener] == '(') {
      final head = code.substring(0, opener).trimRight();
      final widget = RegExp(r'([A-Za-z_]\w*)$').firstMatch(head)?.group(1);
      if (_textWidgets.contains(widget)) {
        context = widget;
      }
    }
    if (context == null) {
      continue;
    }
    if (literal.value.startsWith('qa.') &&
        const {
          'label',
          'semanticLabel',
          'semanticsLabel',
          'tooltip',
          'hintText',
          'message',
        }.contains(context)) {
      out.add(UiLiteral('qa-label', literal.value, lineOf(literal.start)));
      continue;
    }
    if (looksLikeText(literal.value)) {
      out.add(UiLiteral('text', literal.value, lineOf(literal.start)));
    }
  }

  // Automation ids passed as spoken labels through a variable.
  for (final m in RegExp(
    r'\b(label|semanticLabel|semanticsLabel)\s*:\s*(widget\.)?(qaId|qaKey|qa[A-Z]\w*)\b',
  ).allMatches(code)) {
    out.add(UiLiteral('qa-label', m.group(0)!, lineOf(m.start)));
  }
  // Raw exception text in UI.
  for (final m in RegExp(
    r'(Text\(\s*|\b(?:message|content|label|title|subtitle|errorText|text|body|error)\s*:\s*)(e|err|error|exception|ex)\.toString\(\)',
  ).allMatches(code)) {
    out.add(UiLiteral('raw-error', m.group(0)!, lineOf(m.start)));
  }
  for (final literal in literals) {
    if (!RegExp(
      r'^\$\{?(e|err|error|exception|ex)\}?$',
    ).hasMatch(literal.value.trim())) {
      continue;
    }
    final head = code.substring(0, literal.start).trimRight();
    if (RegExp(
      r'(Text\(|\b(?:message|content|label|title|subtitle|errorText|text|body)\s*:)\s*(const\s+)?$',
    ).hasMatch(head)) {
      out.add(UiLiteral('raw-error', literal.value, lineOf(literal.start)));
    }
  }
  // Dropdown items shown as their raw stored value.
  for (final m in RegExp(
    r'DropdownMenuItem(?:<[^>]*>)?\(\s*value:\s*(\w+)\s*,\s*child:\s*(?:const\s+)?Text\(\s*\1\s*[,)]',
  ).allMatches(code)) {
    out.add(
      UiLiteral(
        'raw-dropdown',
        m.group(0)!.replaceAll(RegExp(r'\s+'), ' '),
        lineOf(m.start),
      ),
    );
  }
  for (final m in RegExp(
    r'labelBuilder:\s*\((\w+)\)\s*=>\s*\1\s*[,)]',
  ).allMatches(code)) {
    out.add(
      UiLiteral(
        'raw-dropdown',
        m.group(0)!.replaceAll(RegExp(r'\s+'), ' '),
        lineOf(m.start),
      ),
    );
  }
  return out;
}
