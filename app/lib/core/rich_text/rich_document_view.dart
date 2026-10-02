import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'rich_document.dart';
import 'rich_text_l10n.dart';
import 'writing_styles.dart';

/// Shows a formatted [document], or [plainText] exactly as before when there
/// is no formatting (legacy chapters and stories, older clients).
class RichBody extends StatelessWidget {
  const RichBody({
    required this.document,
    required this.plainText,
    required this.legacyStyle,
    super.key,
    this.scale = 1,
    this.selectable = true,
  });
  final RichDocument? document;
  final String plainText;

  /// The style plain text always used on this surface.
  final TextStyle? legacyStyle;
  final double scale;
  final bool selectable;

  @override
  Widget build(BuildContext context) {
    final doc = document;
    if (doc == null) {
      return selectable
          ? SelectableText(plainText, style: legacyStyle)
          : Text(plainText, style: legacyStyle);
    }
    return RichDocumentView(
      document: doc,
      scale: scale,
      selectable: selectable,
    );
  }
}

/// Read-only renderer for a [RichDocument], used wherever chapters and stories
/// are read. Text is always rendered as text (never parsed as markup), headings
/// are semantic headers, links open only after confirmation, and every colour
/// comes from the theme's [ColorScheme].
class RichDocumentView extends StatefulWidget {
  const RichDocumentView({
    required this.document,
    super.key,
    this.scale = 1,
    this.selectable = true,
  });
  final RichDocument document;
  final double scale;
  final bool selectable;

  @override
  State<RichDocumentView> createState() => _RichDocumentViewState();
}

class _RichDocumentViewState extends State<RichDocumentView> {
  final _recognizers = <TapGestureRecognizer>[];

  void _disposeRecognizers() {
    for (final r in _recognizers) {
      r.dispose();
    }
    _recognizers.clear();
  }

  @override
  void dispose() {
    _disposeRecognizers();
    super.dispose();
  }

  Future<void> _open(String href) async {
    final uri = Uri.tryParse(href);
    if (uri == null || !isSafeRichHref(href)) {
      return;
    }
    final l = richL10n(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l.richOpenLinkTitle),
        content: Text(l.richOpenLinkBody(uri.host)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l.richCancel),
          ),
          FilledButton(
            key: const ValueKey('rich.open_link'),
            onPressed: () => Navigator.pop(context, true),
            child: Text(l.richOpenLink),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  InlineSpan _spans(RichBlock block, TextStyle base, ColorScheme colors) =>
      TextSpan(
        style: base,
        children: [
          for (final s in block.spans)
            TextSpan(
              text: s.text,
              style: applyRichMarks(base, s.marks, colors),
              recognizer: s.href == null
                  ? null
                  : (TapGestureRecognizer()..onTap = () => _open(s.href!)),
              mouseCursor: s.href == null ? null : SystemMouseCursors.click,
            ),
        ],
      );

  @override
  Widget build(BuildContext context) {
    _disposeRecognizers();
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final l = richL10n(context);
    final spec = WritingStyleSpec.of(widget.document.style);
    final body = spec.body(theme, scale: widget.scale);
    final gap = spec.blockGap;
    final half = gap / 2;
    final children = <Widget>[];
    var number = 0;
    for (final block in widget.document.blocks) {
      number = block.type == RichBlockType.numbered ? number + 1 : 0;
      final align = spec.align(block.align);
      Widget text(TextStyle style) {
        final span = _spans(block, style, colors);
        for (final child in (span as TextSpan).children!) {
          final r = (child as TextSpan).recognizer;
          if (r is TapGestureRecognizer) {
            _recognizers.add(r);
          }
        }
        return Text.rich(span, textAlign: align);
      }

      children.add(switch (block.type) {
        RichBlockType.heading || RichBlockType.subheading => Padding(
          padding: EdgeInsets.only(top: gap, bottom: half),
          child: Semantics(
            header: true,
            child: text(
              spec.heading(
                theme,
                sub: block.type == RichBlockType.subheading,
                scale: widget.scale,
              ),
            ),
          ),
        ),
        RichBlockType.quote => Container(
          margin: EdgeInsets.symmetric(vertical: half),
          padding: const EdgeInsetsDirectional.only(start: 16),
          decoration: BoxDecoration(
            border: BorderDirectional(
              start: BorderSide(color: colors.primary, width: 4),
            ),
          ),
          child: text(
            body.copyWith(
              fontStyle: FontStyle.italic,
              color: colors.onSurfaceVariant,
            ),
          ),
        ),
        RichBlockType.callout => Container(
          margin: EdgeInsets.symmetric(vertical: half),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colors.secondaryContainer,
            borderRadius: BorderRadius.circular(12),
          ),
          child: text(body.copyWith(color: colors.onSecondaryContainer)),
        ),
        RichBlockType.bullet || RichBlockType.numbered => Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 32 * widget.scale,
              child: Text(
                block.type == RichBlockType.bullet ? '•' : '$number.',
                style: body.copyWith(
                  color: colors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Expanded(child: text(body)),
          ],
        ),
        RichBlockType.divider => Padding(
          padding: EdgeInsets.symmetric(vertical: gap),
          child: Semantics(
            label: l.richDivider,
            child: Center(
              child: SizedBox(
                width: 96,
                child: Divider(color: colors.outlineVariant, thickness: 1),
              ),
            ),
          ),
        ),
        RichBlockType.paragraph => SizedBox(
          width: double.infinity,
          child: text(body),
        ),
      });
    }
    final column = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: children,
    );
    return widget.selectable ? SelectionArea(child: column) : column;
  }
}
