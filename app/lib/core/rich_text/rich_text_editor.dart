import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'rich_document.dart';
import 'rich_text_controller.dart';
import 'rich_text_l10n.dart';
import 'toolbar_focus_guard.dart';
import 'writing_styles.dart';

/// Formatting toolbar, text field, word count and writing-style picker for a
/// [RichTextController]. Used by the chapter editor and profile stories.
///
/// Keyboard shortcuts (Ctrl on Windows/Linux/web, ⌘ on Apple): B bold,
/// I italic, U underline, Shift+X strikethrough, Shift+H highlight, K link,
/// Alt+1/Alt+2 heading/subheading, Shift+7/Shift+8 numbered/bulleted list,
/// \ clear formatting, Z undo, Shift+Z or Y redo.
class RichTextEditor extends StatefulWidget {
  const RichTextEditor({
    required this.controller,
    required this.label,
    super.key,
    this.hint,
    this.maxLength,
    this.minLines = 8,
    this.maxLines = 18,
    this.enabled = true,
    this.keyPrefix = 'rich',
    this.fieldKey,
    this.validator,
    this.showStylePicker = true,
  });

  final RichTextController controller;
  final String label;
  final String? hint;
  final int? maxLength, minLines, maxLines;
  final bool enabled, showStylePicker;

  /// Prefix for widget keys (`$keyPrefix.bold`, `$keyPrefix.style.poetic`...).
  final String keyPrefix;
  final Key? fieldKey;
  final FormFieldValidator<String>? validator;

  @override
  State<RichTextEditor> createState() => _RichTextEditorState();
}

class _RichTextEditorState extends State<RichTextEditor> {
  final focus = FocusNode(debugLabel: 'rich-text');
  // The field's built-in history only knows text; ours includes formatting.
  final ignoredUndo = UndoHistoryController();

  RichTextController get c => widget.controller;

  @override
  void dispose() {
    focus.dispose();
    ignoredUndo.dispose();
    super.dispose();
  }

  void run(VoidCallback command) {
    if (!widget.enabled) {
      return;
    }
    command();
    focus.requestFocus();
    holdTextFocusAfterToolbarPress(_reconnectInput);
  }

  // The browser lost the story's input while the framework still has it
  // focused: close and reopen the input so typing reaches the story again.
  void _reconnectInput() {
    if (!mounted || !focus.hasFocus) {
      return;
    }
    focus.unfocus(disposition: UnfocusDisposition.previouslyFocusedChild);
    WidgetsBinding.instance
      ..addPostFrameCallback((_) {
        if (mounted && widget.enabled) {
          focus.requestFocus();
        }
      })
      ..scheduleFrame();
  }

  Future<void> editLink() async {
    if (!widget.enabled) {
      return;
    }
    final l = richL10n(context);
    final current = c.activeHref;
    if (current == null && c.selection.isCollapsed) {
      ScaffoldMessenger.maybeOf(context)
        ?..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(l.richLinkNeedsSelection)));
      return;
    }
    // Remember the selection: the dialog takes focus.
    final selection = c.selection;
    final result = await showDialog<String>(
      context: context,
      builder: (_) => _LinkDialog(
        initial: current ?? 'https://',
        canRemove: current != null,
      ),
    );
    if (result == null || !mounted) {
      return;
    }
    c.selection = selection;
    run(() => c.setLink(result.isEmpty ? null : result));
  }

  Map<ShortcutActivator, VoidCallback> get shortcuts {
    final bindings = <ShortcutActivator, VoidCallback>{};
    void bind(
      LogicalKeyboardKey key,
      VoidCallback action, {
      bool shift = false,
      bool alt = false,
    }) {
      bindings[SingleActivator(key, control: true, shift: shift, alt: alt)] =
          action;
      bindings[SingleActivator(key, meta: true, shift: shift, alt: alt)] =
          action;
    }

    bind(LogicalKeyboardKey.keyB, () => run(() => c.toggleMark(RichMark.bold)));
    bind(
      LogicalKeyboardKey.keyI,
      () => run(() => c.toggleMark(RichMark.italic)),
    );
    bind(
      LogicalKeyboardKey.keyU,
      () => run(() => c.toggleMark(RichMark.underline)),
    );
    bind(
      LogicalKeyboardKey.keyX,
      () => run(() => c.toggleMark(RichMark.strikethrough)),
      shift: true,
    );
    bind(
      LogicalKeyboardKey.keyH,
      () => run(() => c.toggleMark(RichMark.highlight)),
      shift: true,
    );
    bind(LogicalKeyboardKey.keyK, editLink);
    bind(
      LogicalKeyboardKey.digit1,
      () => run(() => c.setBlockType(RichBlockType.heading)),
      alt: true,
    );
    bind(
      LogicalKeyboardKey.digit2,
      () => run(() => c.setBlockType(RichBlockType.subheading)),
      alt: true,
    );
    bind(
      LogicalKeyboardKey.digit7,
      () => run(() => c.setBlockType(RichBlockType.numbered)),
      shift: true,
    );
    bind(
      LogicalKeyboardKey.digit8,
      () => run(() => c.setBlockType(RichBlockType.bullet)),
      shift: true,
    );
    bind(LogicalKeyboardKey.backslash, () => run(c.clearFormatting));
    bind(LogicalKeyboardKey.keyZ, () => run(c.undo));
    bind(LogicalKeyboardKey.keyZ, () => run(c.redo), shift: true);
    bind(LogicalKeyboardKey.keyY, () => run(c.redo));
    return bindings;
  }

  @override
  Widget build(BuildContext context) {
    final l = richL10n(context);
    final theme = Theme.of(context);
    return ListenableBuilder(
      listenable: c,
      builder: (context, _) {
        final spec = WritingStyleSpec.of(c.style);
        final words = c.document.wordCount;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // On web and desktop a tap outside a text field unfocuses it;
            // the toolbar belongs to the field so formatting keeps the
            // cursor in the story.
            TextFieldTapRegion(child: _Toolbar(editor: this)),
            const SizedBox(height: 8),
            CallbackShortcuts(
              bindings: shortcuts,
              child: TextFormField(
                key: widget.fieldKey,
                controller: c,
                focusNode: focus,
                undoController: ignoredUndo,
                enabled: widget.enabled,
                minLines: widget.minLines,
                maxLines: widget.maxLines,
                maxLength: widget.maxLength,
                validator: widget.validator,
                keyboardType: TextInputType.multiline,
                textCapitalization: TextCapitalization.sentences,
                style: spec.body(theme, scale: c.bodyScale),
                decoration: InputDecoration(
                  labelText: widget.label,
                  alignLabelWithHint: true,
                  hintText: widget.hint,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${l.richWordCount(words)} · ${l.richAlignmentNote}',
              key: ValueKey('${widget.keyPrefix}.word_count'),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            if (widget.showStylePicker) ...[
              const SizedBox(height: 16),
              WritingStylePicker(
                keyPrefix: widget.keyPrefix,
                selected: c.style,
                enabled: widget.enabled,
                onChanged: (style) => c.style = style,
              ),
            ],
          ],
        );
      },
    );
  }
}

/// Choice of writing style; each chip previews its own typeface.
class WritingStylePicker extends StatelessWidget {
  const WritingStylePicker({
    required this.selected,
    required this.onChanged,
    super.key,
    this.enabled = true,
    this.keyPrefix = 'rich',
  });
  final WritingStyle selected;
  final ValueChanged<WritingStyle> onChanged;
  final bool enabled;
  final String keyPrefix;

  @override
  Widget build(BuildContext context) {
    final l = richL10n(context);
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l.richWritingStyle, style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final style in WritingStyle.values)
              ChoiceChip(
                key: ValueKey('$keyPrefix.style.${style.name}'),
                selected: style == selected,
                onSelected: enabled ? (_) => onChanged(style) : null,
                label: Text(
                  writingStyleName(l, style),
                  style: WritingStyleSpec.of(
                    style,
                  ).body(theme).copyWith(fontSize: 16, height: 1.2),
                ),
                tooltip: writingStyleDescription(l, style),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          writingStyleDescription(l, selected),
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _Toolbar extends StatelessWidget {
  const _Toolbar({required this.editor});
  final _RichTextEditorState editor;

  @override
  Widget build(BuildContext context) {
    final l = richL10n(context);
    final c = editor.c;
    final p = editor.widget.keyPrefix;
    final enabled = editor.widget.enabled;
    final marks = c.activeMarks;
    final block = c.activeBlockType;
    final colors = Theme.of(context).colorScheme;

    Widget toggle(
      String key,
      IconData icon,
      String tooltip,
      VoidCallback onPressed, {
      required bool active,
    }) => Semantics(
      toggled: active,
      child: IconButton(
        key: ValueKey('$p.$key'),
        tooltip: tooltip,
        isSelected: active,
        onPressed: enabled ? onPressed : null,
        style: IconButton.styleFrom(
          minimumSize: const Size(48, 48),
          backgroundColor: active ? colors.secondaryContainer : null,
          foregroundColor: active ? colors.onSecondaryContainer : null,
        ),
        icon: Icon(icon),
      ),
    );

    Widget action(String key, IconData icon, String tooltip, VoidCallback? f) =>
        IconButton(
          key: ValueKey('$p.$key'),
          tooltip: tooltip,
          onPressed: enabled ? f : null,
          style: IconButton.styleFrom(minimumSize: const Size(48, 48)),
          icon: Icon(icon),
        );

    Widget gap() => const SizedBox(
      height: 32,
      child: VerticalDivider(width: 12, indent: 4, endIndent: 4),
    );

    final blockLabels = <RichBlockType, (String, IconData)>{
      RichBlockType.paragraph: (l.richParagraph, Icons.notes_rounded),
      RichBlockType.heading: (l.richHeading, Icons.title_rounded),
      RichBlockType.subheading: (l.richSubheading, Icons.text_fields_rounded),
      RichBlockType.quote: (l.richQuote, Icons.format_quote_rounded),
      RichBlockType.callout: (l.richCallout, Icons.lightbulb_outline_rounded),
    };
    final alignLabels = <RichAlign, (String, IconData)>{
      RichAlign.start: (l.richAlignStart, Icons.format_align_left_rounded),
      RichAlign.center: (l.richAlignCenter, Icons.format_align_center_rounded),
      RichAlign.end: (l.richAlignEnd, Icons.format_align_right_rounded),
    };
    final currentBlock =
        blockLabels[block] ?? blockLabels[RichBlockType.paragraph]!;
    final currentAlign = alignLabels[c.activeAlign]!;

    return Semantics(
      container: true,
      label: l.richFormattingToolbar,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            action(
              'undo',
              Icons.undo_rounded,
              l.richUndo,
              c.canUndo ? () => editor.run(c.undo) : null,
            ),
            action(
              'redo',
              Icons.redo_rounded,
              l.richRedo,
              c.canRedo ? () => editor.run(c.redo) : null,
            ),
            gap(),
            toggle(
              'bold',
              Icons.format_bold_rounded,
              l.richBold,
              () => editor.run(() => c.toggleMark(RichMark.bold)),
              active: marks.contains(RichMark.bold),
            ),
            toggle(
              'italic',
              Icons.format_italic_rounded,
              l.richItalic,
              () => editor.run(() => c.toggleMark(RichMark.italic)),
              active: marks.contains(RichMark.italic),
            ),
            toggle(
              'underline',
              Icons.format_underlined_rounded,
              l.richUnderline,
              () => editor.run(() => c.toggleMark(RichMark.underline)),
              active: marks.contains(RichMark.underline),
            ),
            toggle(
              'strikethrough',
              Icons.format_strikethrough_rounded,
              l.richStrikethrough,
              () => editor.run(() => c.toggleMark(RichMark.strikethrough)),
              active: marks.contains(RichMark.strikethrough),
            ),
            toggle(
              'highlight',
              Icons.border_color_outlined,
              l.richHighlight,
              () => editor.run(() => c.toggleMark(RichMark.highlight)),
              active: marks.contains(RichMark.highlight),
            ),
            toggle(
              'link',
              Icons.link_rounded,
              l.richLink,
              editor.editLink,
              active: c.activeHref != null,
            ),
            gap(),
            PopupMenuButton<RichBlockType>(
              key: ValueKey('$p.block_menu'),
              tooltip: l.richTextStyleMenu,
              enabled: enabled,
              icon: Icon(currentBlock.$2),
              style: IconButton.styleFrom(minimumSize: const Size(48, 48)),
              onSelected: (type) => editor.run(() => c.setBlockType(type)),
              itemBuilder: (_) => [
                for (final e in blockLabels.entries)
                  CheckedPopupMenuItem(
                    key: ValueKey('$p.block.${e.key.name}'),
                    value: e.key,
                    checked: e.key == block,
                    child: Text(e.value.$1),
                  ),
              ],
            ),
            toggle(
              'bullet',
              Icons.format_list_bulleted_rounded,
              l.richBulletList,
              () => editor.run(() => c.setBlockType(RichBlockType.bullet)),
              active: block == RichBlockType.bullet,
            ),
            toggle(
              'numbered',
              Icons.format_list_numbered_rounded,
              l.richNumberedList,
              () => editor.run(() => c.setBlockType(RichBlockType.numbered)),
              active: block == RichBlockType.numbered,
            ),
            action(
              'divider',
              Icons.horizontal_rule_rounded,
              l.richDivider,
              () => editor.run(c.insertDivider),
            ),
            PopupMenuButton<RichAlign>(
              key: ValueKey('$p.align_menu'),
              tooltip: l.richAlignMenu,
              enabled: enabled,
              icon: Icon(currentAlign.$2),
              style: IconButton.styleFrom(minimumSize: const Size(48, 48)),
              onSelected: (align) => editor.run(() => c.setAlign(align)),
              itemBuilder: (_) => [
                for (final e in alignLabels.entries)
                  CheckedPopupMenuItem(
                    key: ValueKey('$p.align.${e.key.name}'),
                    value: e.key,
                    checked: e.key == c.activeAlign,
                    child: Text(e.value.$1),
                  ),
              ],
            ),
            gap(),
            action(
              'clear',
              Icons.format_clear_rounded,
              l.richClearFormatting,
              () => editor.run(c.clearFormatting),
            ),
          ],
        ),
      ),
    );
  }
}

class _LinkDialog extends StatefulWidget {
  const _LinkDialog({required this.initial, required this.canRemove});
  final String initial;
  final bool canRemove;
  @override
  State<_LinkDialog> createState() => _LinkDialogState();
}

class _LinkDialogState extends State<_LinkDialog> {
  late final field = TextEditingController(text: widget.initial);
  String? error;

  @override
  void dispose() {
    field.dispose();
    super.dispose();
  }

  void submit() {
    final value = field.text.trim();
    if (!isSafeRichHref(value)) {
      setState(() => error = richL10n(context).richLinkInvalid);
      return;
    }
    Navigator.pop(context, value);
  }

  @override
  Widget build(BuildContext context) {
    final l = richL10n(context);
    return AlertDialog(
      title: Text(l.richLinkTitle),
      content: TextField(
        key: const ValueKey('rich.link.field'),
        controller: field,
        autofocus: true,
        keyboardType: TextInputType.url,
        autocorrect: false,
        maxLength: 2048,
        decoration: InputDecoration(
          labelText: l.richLinkField,
          errorText: error,
        ),
        onSubmitted: (_) => submit(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l.richCancel),
        ),
        if (widget.canRemove)
          TextButton(
            key: const ValueKey('rich.link.remove'),
            onPressed: () => Navigator.pop(context, ''),
            child: Text(l.richLinkRemove),
          ),
        FilledButton(
          key: const ValueKey('rich.link.apply'),
          onPressed: submit,
          child: Text(l.richLinkApply),
        ),
      ],
    );
  }
}
