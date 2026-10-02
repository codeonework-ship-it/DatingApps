// Dead-control detector: finds every enabled, hit-testable control a screen
// shows, taps it in a fresh pump of that screen, and records what observably
// happened. A control with no observable effect is a dead control.
//
// Used by `dead_control_audit_test.dart`; see that file for the workflow.
//
// What counts as an effect (anything a member could notice):
//   * a request to the fake API (method + path + body),
//   * a route change (push / pop / replace / remove, incl. dialogs, sheets,
//     menus) or a result popped to the opener,
//   * a switch of the app's main tab (a tab screen opening another tab),
//   * a platform call that leaves the app or changes the device (URL launch,
//     share, picker, clipboard, permission, ...; haptics and system chrome do
//     not count),
//   * keyboard / focus moving,
//   * a change in what is on screen: text, colours, opacity, scroll
//     position, a field's text or obscuring (show / hide password), or
//     checked / selected / toggled / expanded state.
// Things that change on their own (clocks, spinners, carousels, polling) are
// measured over an idle window before the tap and subtracted.

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' show CheckedState, Tristate;

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:verified_dating_app/core/theme/app_theme.dart';
import 'package:verified_dating_app/features/common/screens/main_navigation_screen.dart'
    show mainNavigationIndexProvider;
import 'package:verified_dating_app/l10n/app_localizations.dart';

import '../../support/qa_api.dart' show qaFlags;
import 'screen_matrix_harness.dart';

// ─── Files ──────────────────────────────────────────────────────────────────

/// Generated inventory of every audited control (one test per entry).
const deadControlManifestPath =
    'test/features/responsive/dead_control_manifest.json';

/// Controls that are inert by design, with a one-line reason each.
const deadControlAllowlistPath =
    'test/features/responsive/dead_control_allowlist.json';

/// Confirmed dead controls (product bugs awaiting a fix). Their audit tests
/// are skipped until the entry is removed.
const deadControlsPath = '../qa/catalog/dead_controls.json';

/// The QA catalog (case ids for test names).
const featureCatalogPath = '../qa/catalog/feature_catalog.json';

/// Where update mode writes the full probe report for triage.
const deadControlReportPath = 'build/dead_control_report.json';

/// The command that regenerates the manifest.
const deadControlUpdateCommand =
    'cd app && flutter test test/features/responsive/dead_control_audit_test.dart '
    '--dart-define=DEAD_CONTROL_UPDATE=true';

/// Separator between the steps of a path (opener › control).
const pathSeparator = ' › ';

/// The phone the audit runs on.
const auditViewSize = Size(430, 932);

/// Effects are awaited for [_windowSteps] x [_step] after a tap; the idle
/// window that measures background change before the tap is as long.
const _windowSteps = 4;
const _trace = bool.fromEnvironment('DEAD_CONTROL_TRACE');
const _step = Duration(milliseconds: 300);

// ─── Source locations ───────────────────────────────────────────────────────

/// A widget's creation location inside the app's own `lib/`.
class SourceLoc {
  const SourceLoc(this.file, this.line);

  /// Path relative to the app package, e.g. `lib/features/x/y_screen.dart`.
  final String file;
  final int line;

  String get basename => file.split('/').last;

  /// Shared building blocks rather than a feature's own code.
  bool get isShared => file.startsWith('lib/core/');

  @override
  String toString() => '$file:$line';
}

final String _libRoot = '${Directory.current.path}/lib/';
final Expando<Object> _locCache = Expando<Object>('creationLocation');

/// True when `flutter test` tracks widget creation (the default).
bool get widgetCreationTracked =>
    WidgetInspectorService.instance.isWidgetCreationTracked();

/// Where [widget] was constructed, when that was in the app's own code.
SourceLoc? appCreationLocation(Widget widget) {
  final cached = _locCache[widget];
  if (cached != null) {
    return cached is SourceLoc ? cached : null;
  }
  SourceLoc? result;
  final json = widget.toDiagnosticsNode().toJsonMap(
    InspectorSerializationDelegate(
      service: WidgetInspectorService.instance,
      subtreeDepth: 0,
    ),
  );
  final raw = json['creationLocation'];
  if (raw is Map) {
    var file = raw['file']?.toString() ?? '';
    if (file.startsWith('file://')) {
      file = Uri.parse(file).toFilePath();
    }
    if (file.startsWith(_libRoot)) {
      result = SourceLoc(
        'lib/${file.substring(_libRoot.length)}',
        (raw['line'] as num?)?.toInt() ?? 0,
      );
    }
  }
  _locCache[widget] = result ?? false;
  return result;
}

// ─── Controls ───────────────────────────────────────────────────────────────

/// One interactive control on screen.
class LiveControl {
  LiveControl({
    required this.element,
    required this.kind,
    required this.label,
    required this.qaKey,
    required this.source,
    required this.ownSource,
    required this.sourceChain,
    required this.callSiteType,
    this.disabled = false,
  });

  /// Announced as disabled (`Semantics(enabled: false)`) although its handler
  /// is set: a dimmed control that is inert by design in this state.
  final bool disabled;

  final Element element;

  /// The control's widget type (`IconButton`, `InkWell`, `Tab`, ...).
  final String kind;

  /// What a member reads: tooltip, semantics label, text, or icon name.
  final String label;

  /// `qa.*` automation key (ValueKey or Semantics label/identifier), if any.
  final String? qaKey;

  /// Where the feature code builds this control (call site).
  final SourceLoc? source;

  /// Where the control widget itself was constructed.
  final SourceLoc? ownSource;

  /// App source locations from the control up to its route (for catalog
  /// matching).
  final List<SourceLoc> sourceChain;

  /// The feature-level widget that builds this control (e.g. `GlassButton`).
  final String callSiteType;

  /// Stable identity used by the manifest: kind, key-or-label, call-site file
  /// and an occurrence number for repeats.
  late String identity;

  bool get isSlider => kind == 'Slider' || kind == 'RangeSlider';

  String describe() =>
      '$kind "${label.isEmpty ? '(no label)' : label}"'
      '${qaKey == null ? '' : ' [$qaKey]'}'
      '${source == null ? '' : ' at $source'}';
}

/// Widgets whose own children are the tap targets (one control per item).
bool _isContainerControl(Widget w) => switch (w) {
  BottomNavigationBar(:final onTap) => onTap != null,
  NavigationBar(:final onDestinationSelected) => onDestinationSelected != null,
  TabBar() => true,
  // Read the callback dynamically: its static type depends on T, so a typed
  // pattern on SegmentedButton<dynamic> throws a cast error for, say, a
  // SegmentedButton<AppThemeChoice> (which hung the audit on Settings).
  // ignore: avoid_dynamic_calls
  SegmentedButton() => (w as dynamic).onSelectionChanged != null,
  _ => false,
};

String _containerItemKind(Widget w) => switch (w) {
  BottomNavigationBar() => 'BottomNavigationBarItem',
  NavigationBar() => 'NavigationDestination',
  TabBar() => 'Tab',
  SegmentedButton() => 'ButtonSegment',
  _ => 'Item',
};

/// The control kind of an app-built [w], or null when it is not an enabled
/// interactive control.
String? controlKind(Widget w) {
  switch (w) {
    case IconButton(:final onPressed):
      return onPressed == null ? null : 'IconButton';
    case FilledButton():
      return w.enabled ? 'FilledButton' : null;
    case OutlinedButton():
      return w.enabled ? 'OutlinedButton' : null;
    case ElevatedButton():
      return w.enabled ? 'ElevatedButton' : null;
    case TextButton():
      return w.enabled ? 'TextButton' : null;
    case ButtonStyleButton():
      return w.enabled ? 'ButtonStyleButton' : null;
    case FloatingActionButton(:final onPressed):
      return onPressed == null ? null : 'FloatingActionButton';
    case SwitchListTile(:final onChanged):
      return onChanged == null ? null : 'SwitchListTile';
    case CheckboxListTile(:final onChanged):
      return onChanged == null ? null : 'CheckboxListTile';
    // Generic widgets: their callbacks' static types depend on T, so read
    // them dynamically (a typed pattern throws a cast error, e.g. for a
    // DropdownButton<int>).
    case RadioListTile():
      // ignore: avoid_dynamic_calls
      return (w as dynamic).onChanged == null ? null : 'RadioListTile';
    case ListTile(:final onTap, :final enabled):
      return onTap == null || !enabled ? null : 'ListTile';
    case ExpansionTile(:final enabled):
      return enabled ? 'ExpansionTile' : null;
    case Switch(:final onChanged):
      return onChanged == null ? null : 'Switch';
    case Checkbox(:final onChanged):
      return onChanged == null ? null : 'Checkbox';
    case ChoiceChip(:final onSelected, :final isEnabled):
      return onSelected == null || !isEnabled ? null : 'ChoiceChip';
    case FilterChip(:final onSelected, :final isEnabled):
      return onSelected == null || !isEnabled ? null : 'FilterChip';
    case ActionChip(:final onPressed):
      return onPressed == null ? null : 'ActionChip';
    case InputChip(:final onPressed, :final onSelected, :final isEnabled):
      return (onPressed == null && onSelected == null) || !isEnabled
          ? null
          : 'InputChip';
    case PopupMenuButton(:final enabled):
      return enabled ? 'PopupMenuButton' : null;
    case PopupMenuItem(:final enabled):
      return enabled ? 'PopupMenuItem' : null;
    case DropdownButton():
      // ignore: avoid_dynamic_calls
      return (w as dynamic).onChanged == null ? null : 'DropdownButton';
    case DropdownButtonFormField():
      // ignore: avoid_dynamic_calls
      return (w as dynamic).onChanged == null
          ? null
          : 'DropdownButtonFormField';
    case DropdownMenuItem(:final enabled):
      return enabled ? 'DropdownMenuItem' : null;
    case Slider(:final onChanged):
      return onChanged == null ? null : 'Slider';
    case RangeSlider(:final onChanged):
      return onChanged == null ? null : 'RangeSlider';
    case InkResponse(:final onTap):
      // InkWell is an InkResponse.
      return onTap == null ? null : (w is InkWell ? 'InkWell' : 'InkResponse');
    case GestureDetector(:final onTap, :final onTapUp):
      return onTap == null && onTapUp == null ? null : 'GestureDetector';
  }
  if (_isContainerControl(w)) {
    return w.runtimeType.toString().split('<').first;
  }
  return null;
}

final Map<int, String> _knownIcons = {
  for (final (name, icon) in <(String, IconData)>[
    ('arrow_back', Icons.arrow_back),
    ('arrow_back', Icons.arrow_back_rounded),
    ('arrow_back_ios', Icons.arrow_back_ios),
    ('arrow_back_ios_new', Icons.arrow_back_ios_new),
    ('arrow_back_ios_new', Icons.arrow_back_ios_new_rounded),
    ('close', Icons.close),
    ('close', Icons.close_rounded),
    ('more_vert', Icons.more_vert),
    ('more_vert', Icons.more_vert_rounded),
    ('more_horiz', Icons.more_horiz),
    ('more_horiz', Icons.more_horiz_rounded),
    ('favorite', Icons.favorite),
    ('favorite', Icons.favorite_rounded),
    ('favorite_border', Icons.favorite_border),
    ('favorite_border', Icons.favorite_border_rounded),
    ('send', Icons.send),
    ('send', Icons.send_rounded),
    ('add', Icons.add),
    ('add', Icons.add_rounded),
    ('edit', Icons.edit),
    ('edit', Icons.edit_rounded),
    ('edit_outlined', Icons.edit_outlined),
    ('delete', Icons.delete),
    ('delete_outline', Icons.delete_outline),
    ('delete_outline', Icons.delete_outline_rounded),
    ('refresh', Icons.refresh),
    ('refresh', Icons.refresh_rounded),
    ('search', Icons.search),
    ('search', Icons.search_rounded),
    ('settings', Icons.settings),
    ('settings', Icons.settings_rounded),
    ('settings_outlined', Icons.settings_outlined),
    ('share', Icons.share),
    ('share', Icons.share_rounded),
    ('tune', Icons.tune),
    ('tune', Icons.tune_rounded),
    ('filter_list', Icons.filter_list),
    ('notifications', Icons.notifications),
    ('notifications_none', Icons.notifications_none),
    ('notifications_outlined', Icons.notifications_outlined),
    ('chevron_right', Icons.chevron_right),
    ('chevron_right', Icons.chevron_right_rounded),
    ('chevron_left', Icons.chevron_left),
    ('chevron_left', Icons.chevron_left_rounded),
    ('expand_more', Icons.expand_more),
    ('expand_less', Icons.expand_less),
    ('info_outline', Icons.info_outline),
    ('info_outline', Icons.info_outline_rounded),
    ('help_outline', Icons.help_outline),
    ('camera_alt', Icons.camera_alt),
    ('camera_alt', Icons.camera_alt_rounded),
    ('photo_library', Icons.photo_library),
    ('photo_library', Icons.photo_library_rounded),
    ('mic', Icons.mic),
    ('mic', Icons.mic_rounded),
    ('play_arrow', Icons.play_arrow),
    ('play_arrow', Icons.play_arrow_rounded),
    ('pause', Icons.pause),
    ('pause', Icons.pause_rounded),
    ('stop', Icons.stop),
    ('call', Icons.call),
    ('call_end', Icons.call_end),
    ('videocam', Icons.videocam),
    ('flag', Icons.flag),
    ('flag_outlined', Icons.flag_outlined),
    ('block', Icons.block),
    ('star', Icons.star),
    ('star', Icons.star_rounded),
    ('undo', Icons.undo),
    ('undo', Icons.undo_rounded),
    ('check', Icons.check),
    ('check', Icons.check_rounded),
    ('copy', Icons.copy),
    ('copy', Icons.copy_rounded),
    ('visibility', Icons.visibility),
    ('visibility_off', Icons.visibility_off),
    ('emoji_emotions', Icons.emoji_emotions_outlined),
    ('attach_file', Icons.attach_file),
    ('image', Icons.image_outlined),
    ('chat_bubble_outline', Icons.chat_bubble_outline),
    ('chat_bubble_outline', Icons.chat_bubble_outline_rounded),
    ('history', Icons.history),
    ('history', Icons.history_rounded),
    ('person_add', Icons.person_add),
    ('person_add', Icons.person_add_alt_1_rounded),
    ('logout', Icons.logout),
    ('logout', Icons.logout_rounded),
  ])
    icon.codePoint: name,
};

String _normalizeLabel(String label) => label
    .replaceAll(RegExp(r'\d+'), '#')
    .replaceAll(RegExp(r'\s+'), ' ')
    .trim();

/// The private-use range Material icon glyphs live in.
bool _isIconGlyph(int rune) =>
    (rune >= 0xE000 && rune <= 0xF8FF) || rune >= 0xF0000;

String _plainText(String text) =>
    String.fromCharCodes(text.runes.where((r) => !_isIconGlyph(r))).trim();

/// Visible texts under [element], in paint order.
List<String> _textsUnder(Element element) {
  final texts = <String>[];
  void visit(Element e) {
    final w = e.widget;
    if (w is RichText) {
      final t = _plainText(w.text.toPlainText());
      if (t.isNotEmpty) texts.add(t);
      return;
    }
    if (w is EditableText) {
      return;
    }
    e.visitChildElements(visit);
  }

  visit(element);
  return texts;
}

/// The first icon under [element] (name when known, else its code point).
String? _iconUnder(Element element) {
  String? found;
  void visit(Element e) {
    if (found != null) return;
    final w = e.widget;
    if (w is Icon && w.icon != null) {
      final cp = w.icon!.codePoint;
      found = _knownIcons[cp] ?? 'icon U+${cp.toRadixString(16)}';
      return;
    }
    e.visitChildElements(visit);
  }

  visit(element);
  return found;
}

String? _qaFrom(Widget w) {
  final key = w.key;
  if (key is ValueKey<String> && key.value.startsWith('qa.')) {
    return key.value;
  }
  if (w is Semantics) {
    final label = w.properties.label;
    if (label != null && label.startsWith('qa.')) return label;
    final id = w.properties.identifier;
    if (id != null && id.startsWith('qa.')) return id;
  }
  return null;
}

String? _semanticsLabelFrom(Widget w) {
  if (w is Semantics) {
    final label = w.properties.label;
    if (label != null && label.trim().isNotEmpty && !label.startsWith('qa.')) {
      return label.trim();
    }
  }
  return null;
}

String? _tooltipFrom(Widget w) => switch (w) {
  IconButton(:final tooltip) => tooltip,
  FloatingActionButton(:final tooltip) => tooltip,
  PopupMenuButton(:final tooltip) => tooltip,
  Tooltip(:final message) => message,
  _ => null,
};

/// Elements from [element] (inclusive) up to, but not into, the first
/// ancestor that lays out several children (that would belong to siblings).
List<Element> _ownAncestors(Element element, {int limit = 10}) {
  final out = <Element>[element];
  var stop = false;
  element.visitAncestorElements((ancestor) {
    if (stop || out.length > limit) return false;
    if (ancestor is MultiChildRenderObjectElement) return false;
    if (ancestor.widget is Overlay || ancestor.widget is Navigator) {
      return false;
    }
    out.add(ancestor);
    if (controlKind(ancestor.widget) != null) stop = true;
    return true;
  });
  return out;
}

/// Finds the descendants of [element] up to depth [maxDepth] that satisfy
/// [test], stopping below any nested control.
String? _firstDescendant(
  Element element,
  String? Function(Widget) test, {
  int maxDepth = 12,
}) {
  String? found;
  void visit(Element e, int depth) {
    if (found != null || depth > maxDepth) return;
    if (depth > 0 && controlKind(e.widget) != null) return;
    found = test(e.widget);
    if (found != null) return;
    e.visitChildElements((c) => visit(c, depth + 1));
  }

  visit(element, 0);
  return found;
}

LiveControl _describeControl(
  Element element,
  String kind, {
  Element? container,
}) {
  final widget = element.widget;
  final own = _ownAncestors(container ?? element);

  String? qaKey;
  String? tooltip;
  String? semanticsLabel;
  var disabled = false;
  for (final e in own) {
    final w = e.widget;
    if (w is Semantics && w.properties.enabled == false) disabled = true;
    qaKey ??= _qaFrom(e.widget);
    tooltip ??= _tooltipFrom(e.widget);
    semanticsLabel ??= _semanticsLabelFrom(e.widget);
  }
  qaKey ??= _firstDescendant(element, _qaFrom);
  semanticsLabel ??= _firstDescendant(element, _semanticsLabelFrom);
  tooltip ??= _firstDescendant(element, _tooltipFrom, maxDepth: 4);
  final texts = _textsUnder(element);
  final textLabel = texts.take(2).join(' · ');
  final icon = _iconUnder(element);

  // Source: the control's own location and the feature code that built it.
  final chain = <SourceLoc>[];
  SourceLoc? callSite;
  var callSiteType = widget.runtimeType.toString().split('<').first;
  void consider(Element e) {
    final loc = appCreationLocation(e.widget);
    if (loc == null) return;
    if (chain.isEmpty || chain.last.toString() != loc.toString()) {
      chain.add(loc);
    }
    if (callSite == null && !loc.isShared) {
      callSite = loc;
      callSiteType = e.widget.runtimeType.toString().split('<').first;
    }
  }

  consider(element);
  if (container != null) consider(container);
  (container ?? element).visitAncestorElements((ancestor) {
    if (ancestor.widget is Navigator || ancestor.widget is Overlay) {
      return false;
    }
    consider(ancestor);
    return chain.length < 40;
  });
  final ownSource =
      appCreationLocation(widget) ??
      (container == null ? null : appCreationLocation(container.widget));

  var label =
      tooltip ??
      semanticsLabel ??
      (textLabel.isEmpty ? null : textLabel) ??
      (icon == null ? null : 'icon $icon') ??
      '';
  if (label.length > 60) label = '${label.substring(0, 57)}...';
  return LiveControl(
    element: element,
    kind: kind,
    label: label,
    qaKey: qaKey,
    source: callSite ?? ownSource,
    ownSource: ownSource,
    sourceChain: chain,
    callSiteType: callSiteType,
    disabled: disabled,
  );
}

/// Every enabled interactive control under [root] (a route's subtree), in
/// tree order, with stable identities.
List<LiveControl> discoverControls(Element root) {
  final found = <LiveControl>[];
  void visit(Element e) {
    final w = e.widget;
    if (w is Offstage && w.offstage) return;
    if (w is Visibility && !w.visible) return;
    if (w is TickerMode && !w.enabled) return;
    final loc = appCreationLocation(w);
    if (_isContainerControl(w) && loc != null) {
      final itemKind = _containerItemKind(w);
      void items(Element c) {
        final iw = c.widget;
        final isItem =
            (iw is InkResponse && iw.onTap != null) ||
            (iw is ButtonStyleButton && iw.enabled);
        if (isItem) {
          found.add(_describeControl(c, itemKind, container: e));
          return;
        }
        c.visitChildElements(items);
      }

      e.visitChildElements(items);
      return;
    }
    if (loc != null) {
      final kind = controlKind(w);
      // The selected item a closed dropdown shows is the dropdown itself.
      final insideDropdownButton =
          kind == 'DropdownMenuItem' && _insideClosedDropdown(e);
      if (kind != null && !insideDropdownButton) {
        final control = _describeControl(e, kind);
        if (!control.disabled) found.add(control);
      }
    }
    e.visitChildElements(visit);
  }

  visit(root);

  // Stable identities, numbered when the same control repeats.
  final seen = <String, int>{};
  for (final c in found) {
    final key = c.qaKey ?? _normalizeLabel(c.label);
    final file = c.source?.basename ?? '?';
    final base = '${c.kind}|$key|$file';
    final n = (seen[base] ?? 0) + 1;
    seen[base] = n;
    c.identity = n == 1 ? base : '$base#$n';
  }
  return found;
}

bool _insideClosedDropdown(Element e) {
  var inside = false;
  e.visitAncestorElements((a) {
    final type = a.widget.runtimeType.toString();
    if (type.startsWith('DropdownButton<') ||
        type.startsWith('DropdownButtonFormField<')) {
      inside = true;
      return false;
    }
    if (a.widget is Navigator || a.widget is Overlay) return false;
    return true;
  });
  return inside;
}

// ─── Tap targeting ──────────────────────────────────────────────────────────

RenderBox? _boxOf(Element e) {
  final ro = e.renderObject;
  if (ro is RenderBox && ro.attached && ro.hasSize) return ro;
  return null;
}

Rect? _globalRect(Element e) {
  final box = _boxOf(e);
  if (box == null || box.size.isEmpty) return null;
  return box.localToGlobal(Offset.zero) & box.size;
}

/// A point where a tap reaches [control] first (no other control on top), or
/// null when the control is covered or off screen.
Offset? findTapPoint(WidgetTester tester, LiveControl control) {
  final rect = _globalRect(control.element);
  if (rect == null) return null;
  final view = tester.view;
  final screen = Offset.zero & (view.physicalSize / view.devicePixelRatio);
  final visible = rect.intersect(screen);
  if (visible.width < 1 || visible.height < 1) return null;

  final target = control.element.renderObject;
  final others = <RenderObject, LiveControl>{};
  final root = _routeRootOf(control.element);
  if (root != null) {
    for (final other in discoverControls(root)) {
      final ro = other.element.renderObject;
      if (ro != null) others[ro] = other;
    }
  }
  final points = <Offset>[visible.center];
  if (control.isSlider) {
    points
      ..clear()
      ..add(Offset(visible.left + visible.width * 0.8, visible.center.dy))
      ..add(Offset(visible.left + visible.width * 0.2, visible.center.dy));
  }
  final inner = visible.deflate(1);
  if (!inner.isEmpty) {
    for (var i = 1; i <= 5; i++) {
      for (var j = 1; j <= 5; j++) {
        points.add(
          Offset(
            inner.left + inner.width * j / 6,
            inner.top + inner.height * i / 6,
          ),
        );
      }
    }
  }
  for (final point in points) {
    final result = HitTestResult();
    RendererBinding.instance.hitTestInView(result, point, view.viewId);
    for (final entry in result.path) {
      final t = entry.target;
      if (t == target) return point;
      if (t is RenderObject && others.containsKey(t)) break;
    }
  }
  return null;
}

Element? _routeRootOf(Element element) {
  Element? root;
  element.visitAncestorElements((a) {
    if (a.widget is Overlay || a.widget is Navigator) return false;
    root = a;
    return true;
  });
  return root;
}

// ─── Fingerprint ────────────────────────────────────────────────────────────

String _decorationKey(Decoration d) {
  if (d is BoxDecoration) {
    return 'box ${d.color} ${d.gradient} ${d.border} ${d.boxShadow?.length}';
  }
  if (d is ShapeDecoration) {
    return 'shape ${d.color} ${d.gradient} ${d.shape.runtimeType}';
  }
  return d.runtimeType.toString();
}

/// What is on screen, keyed by the render object (or semantics node) that
/// shows it: visible text, editable text (and whether it is obscured),
/// decoration, fill, opacity, scroll offset, painter, and checked / selected
/// / toggled / expanded state.
typedef Snapshot = Map<Object, String>;

Snapshot fingerprint() {
  final out = <Object, String>{};

  void visit(RenderObject ro) {
    final line = switch (ro) {
      RenderParagraph() =>
        'text "${ro.text.toPlainText()}" ${ro.text.style?.color}',
      // obscureText: a show/hide password toggle changes only this (the
      // eye icon's glyph sits under ExcludeSemantics, which this walk skips).
      RenderEditable() =>
        'edit "${ro.text?.toPlainText()}" ${ro.hasFocus} '
            'obscured:${ro.obscureText}',
      RenderDecoratedBox() => 'deco ${_decorationKey(ro.decoration)}',
      RenderPhysicalModel() => 'model ${ro.color} ${ro.elevation}',
      RenderPhysicalShape() => 'fill ${ro.color} ${ro.elevation}',
      RenderOpacity() => 'opacity ${ro.opacity.toStringAsFixed(2)}',
      RenderAnimatedOpacity() =>
        'opacity ${ro.opacity.value.toStringAsFixed(2)}',
      RenderViewportBase() =>
        'scroll ${ro.offset.hasPixels ? ro.offset.pixels.round() : -1}',
      RenderCustomPaint() =>
        'paint ${ro.painter.runtimeType} ${ro.foregroundPainter.runtimeType}',
      _ => null,
    };
    if (line != null) out[ro] = line;
    ro.visitChildrenForSemantics(visit);
  }

  for (final view in RendererBinding.instance.renderViews) {
    view.visitChildrenForSemantics(visit);
    final semantics = view.owner?.semanticsOwner?.rootSemanticsNode;
    if (semantics == null) continue;
    void walk(SemanticsNode node) {
      final d = node.getSemanticsData();
      final f = d.flagsCollection;
      final stateful =
          d.value.isNotEmpty ||
          f.isChecked != CheckedState.none ||
          f.isSelected != Tristate.none ||
          f.isToggled != Tristate.none ||
          f.isExpanded != Tristate.none;
      if (stateful) {
        out['semantics#${node.id}'] =
            'state "${d.label}" = "${d.value}" ${f.isChecked} '
            'selected:${f.isSelected} toggled:${f.isToggled} '
            'expanded:${f.isExpanded}';
      }
      node.visitChildren((child) {
        walk(child);
        return true;
      });
    }

    walk(semantics);
  }
  return out;
}

/// What changes on screen by itself: objects whose value changed, and
/// values that came and went, between consecutive idle snapshots.
class Noise {
  final keys = <Object>{};
  final values = <String>{};

  void learn(Snapshot a, Snapshot b) {
    for (final e in a.entries) {
      final other = b[e.key];
      if (other == null) {
        values.add(e.value);
      } else if (other != e.value) {
        keys.add(e.key);
      }
    }
    for (final e in b.entries) {
      if (!a.containsKey(e.key)) values.add(e.value);
    }
  }
}

/// Visible changes from [before] to [after], ignoring [noise]. Objects that
/// were rebuilt with the same content do not count.
List<String> screenChanges(Snapshot before, Snapshot after, Noise noise) {
  final changes = <String>[];
  final gone = <String, int>{};
  final fresh = <String, int>{};
  for (final e in before.entries) {
    final now = after[e.key];
    if (now == null) {
      gone[e.value] = (gone[e.value] ?? 0) + 1;
    } else if (now != e.value && !noise.keys.contains(e.key)) {
      changes.add('${e.value} → $now');
    }
  }
  for (final e in after.entries) {
    if (!before.containsKey(e.key)) {
      fresh[e.value] = (fresh[e.value] ?? 0) + 1;
    }
  }
  for (final e in fresh.entries) {
    if (e.value > (gone[e.key] ?? 0) && !noise.values.contains(e.key)) {
      changes.add('+${e.key}');
    }
  }
  for (final e in gone.entries) {
    if (e.value > (fresh[e.key] ?? 0) && !noise.values.contains(e.key)) {
      changes.add('-${e.key}');
    }
  }
  return changes;
}

// ─── Recording ──────────────────────────────────────────────────────────────

/// One thing that happened after a tap.
class AuditEvent {
  AuditEvent(this.kind, this.detail);

  /// `api`, `push`, `pop`, `replace`, `remove`, `result`, `channel`, `tab`.
  final String kind;
  final String detail;

  @override
  String toString() => '$kind: $detail';
}

/// Records a switch of the app's main tab. A screen that lives in a tab
/// (Profile) opens another tab (Matches) by setting the selected index
/// instead of pushing a route; in the app that switches the visible tab, but
/// here the screen is pushed alone, so the switch itself is the effect.
class _AuditTabObserver extends ProviderObserver {
  _AuditTabObserver(this.log);

  final List<AuditEvent> log;

  @override
  void didUpdateProvider(
    ProviderBase<Object?> provider,
    Object? previousValue,
    Object? newValue,
    ProviderContainer container,
  ) {
    if (provider == mainNavigationIndexProvider && previousValue != newValue) {
      log.add(AuditEvent('tab', 'main tab $previousValue -> $newValue'));
    }
  }
}

class _AuditObserver extends NavigatorObserver {
  _AuditObserver(this.log);

  final List<AuditEvent> log;
  final routes = <Route<dynamic>>[];

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    routes.add(route);
    log.add(AuditEvent('push', describeRoute(route)));
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    routes.remove(route);
    log.add(AuditEvent('pop', describeRoute(route)));
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    routes.remove(route);
    log.add(AuditEvent('remove', describeRoute(route)));
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    final i = oldRoute == null ? -1 : routes.indexOf(oldRoute);
    if (newRoute != null) {
      if (i >= 0) {
        routes[i] = newRoute;
      } else {
        routes.add(newRoute);
      }
    }
    log.add(
      AuditEvent(
        'replace',
        '${oldRoute == null ? '?' : describeRoute(oldRoute)} -> '
            '${newRoute == null ? '?' : describeRoute(newRoute)}',
      ),
    );
  }
}

/// `MaterialPageRoute<void>` plus the screen it shows, when built.
String describeRoute(Route<dynamic> route) {
  final type = route.runtimeType.toString();
  final content = route is ModalRoute ? routeContentName(route) : null;
  return content == null ? type : '$type ($content)';
}

/// The first app widget a route shows (its screen, sheet or dialog class).
String? routeContentName(ModalRoute<dynamic> route) {
  final context = route.subtreeContext;
  if (context is! Element || !context.mounted) return null;
  String? name;
  void visit(Element e) {
    if (name != null) return;
    final w = e.widget;
    final loc = appCreationLocation(w);
    if (loc != null) {
      final type = w.runtimeType.toString().split('<').first;
      if (!type.startsWith('_') ||
          type.endsWith('Sheet') ||
          type.endsWith('Dialog')) {
        name = type;
        return;
      }
    }
    e.visitChildElements(visit);
  }

  visit(context);
  return name;
}

/// Platform channels and methods that are not effects a member notices.
bool _isNoiseChannel(String channel, String method) {
  const noiseChannels = {
    'flutter/navigation',
    'flutter/mousecursor',
    'flutter/accessibility',
    'flutter/system',
    'flutter/lifecycle',
    'flutter/keyevent',
    'flutter/keydata',
    'flutter/restoration',
    'flutter/spellcheck',
    'flutter/undomanager',
    'flutter/contextmenu',
    'flutter/scribe',
    'flutter/processtext',
    'flutter/backgesture',
    'flutter/settings',
    'flutter/localization',
    'flutter/isolate',
    'flutter/deferredcomponent',
    'flutter/assets',
    'flutter/sensitivecontent',
  };
  if (noiseChannels.contains(channel)) return true;
  if (channel == 'flutter/platform') {
    return method.startsWith('HapticFeedback') ||
        method.startsWith('SystemSound') ||
        method.startsWith('SystemChrome') ||
        method == 'Clipboard.getData' ||
        method == 'Clipboard.hasStrings' ||
        method == 'SystemNavigator.routeInformationUpdated';
  }
  if (channel == 'flutter/textinput') {
    // Keyboard shown or hidden is an effect; editing chatter is not.
    return !(method == 'TextInput.show' ||
        method == 'TextInput.setClient' ||
        method == 'TextInput.hide' ||
        method == 'TextInput.clearClient');
  }
  final m = method.split('.').last.toLowerCase();
  return m.startsWith('get') ||
      m.startsWith('read') ||
      m.startsWith('check') ||
      m.startsWith('has') ||
      m.startsWith('is') ||
      m.startsWith('contains') ||
      m.startsWith('canlaunch') ||
      m == 'listen' ||
      m == 'cancel' ||
      m == 'init' ||
      m == 'initialize' ||
      m == 'disposeall';
}

String _decodeMethod(String channel, ByteData? message) {
  if (message == null) return channel;
  for (final codec in const <MethodCodec>[
    StandardMethodCodec(),
    JSONMethodCodec(),
  ]) {
    try {
      return codec.decodeMethodCall(message).method;
    } on Object {
      // Not this codec.
    }
  }
  // Pigeon channels carry the method in the channel name.
  return channel.split('.').last;
}

// ─── Session ────────────────────────────────────────────────────────────────

/// What a probe saw.
class ProbeResult {
  ProbeResult({
    required this.found,
    this.control,
    this.reachable = false,
    this.effects = const [],
    this.errors = const [],
    this.popupOpened = false,
    this.available = const [],
    this.missingStep,
    this.poppedResult,
  });

  final bool found;
  final LiveControl? control;
  final bool reachable;
  final List<String> effects;
  final List<String> errors;

  /// The tap opened a dialog, sheet or menu (its controls can be audited).
  final bool popupOpened;

  /// Identities on screen when a step was not found (for the message).
  final List<String> available;
  final String? missingStep;
  final String? poppedResult;

  bool get dead => found && reachable && effects.isEmpty;
}

/// One fresh pump of a screen pushed over a launcher, with recorders.
///
/// Everything the app runs (builds, timers, tap handlers) runs inside a
/// guarded zone so an app error is recorded against the tap instead of
/// aborting the test; framework-reported errors are recorded the same way.
class AuditSession {
  AuditSession._(this.tester, this.screen);

  final WidgetTester tester;
  final String screen;
  final log = <AuditEvent>[];
  final errors = <String>[];
  late final _AuditObserver _observer = _AuditObserver(log);
  final _navigator = GlobalKey<NavigatorState>();
  SemanticsHandle? _semantics;
  FlutterExceptionHandler? _previousOnError;
  Object? screenResult;
  bool screenPopped = false;
  bool _closed = false;
  static int _pointer = 900000;

  /// Pumps [build] as a pushed screen with offline fixtures.
  static Future<AuditSession> open(
    WidgetTester tester,
    String screen,
    Widget Function() build,
  ) async {
    final session = AuditSession._(tester, screen);
    try {
      await session._open(build);
    } on Object {
      await session.close();
      rethrow;
    }
    return session;
  }

  void _record(Object error) {
    final text = error.toString().split('\n').first;
    errors.add(text.length > 200 ? '${text.substring(0, 200)}…' : text);
  }

  /// Runs [body] in a zone whose uncaught errors are recorded, not fatal.
  Future<void> _guarded(Future<void> Function() body) {
    final done = Completer<void>();
    runZonedGuarded(() {
      body().then(
        (_) {
          if (!done.isCompleted) done.complete();
        },
        onError: (Object error, StackTrace _) {
          _record(error);
          if (!done.isCompleted) done.complete();
        },
      );
    }, (error, _) => _record(error));
    return done.future;
  }

  Future<void> _open(Widget Function() build) async {
    tester.view.physicalSize = auditViewSize;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    SharedPreferences.setMockInitialValues(<String, Object>{});
    _semantics = tester.ensureSemantics();
    _previousOnError = FlutterError.onError;
    FlutterError.onError = (details) => _record(details.exception);
    final messenger = tester.binding.defaultBinaryMessenger;
    messenger.allMessagesHandler = (channel, handler, message) {
      final method = _decodeMethod(channel, message);
      if (!_isNoiseChannel(channel, method)) {
        log.add(AuditEvent('channel', '$channel $method'));
      }
      if (handler != null) return handler(message);
      return messenger.delegate.send(channel, message);
    };

    await _guarded(() async {
      await tester.pumpWidget(
        ProviderScope(
          observers: [_AuditTabObserver(log)],
          overrides: [
            ...screenMatrixOverrides(
              onRequest: (o) => log.add(AuditEvent('api', _describeRequest(o))),
              fixtures: true,
            ),
            qaFlags(),
          ],
          child: MaterialApp(
            navigatorKey: _navigator,
            navigatorObservers: [_observer],
            theme: AppTheme.lightTheme,
            locale: const Locale('en'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const Scaffold(body: Center(child: Text('launcher'))),
          ),
        ),
      );
      unawaited(
        _navigator.currentState!
            .push<Object?>(MaterialPageRoute<Object?>(builder: (_) => build()))
            .then((value) {
              screenPopped = true;
              screenResult = value;
              log.add(AuditEvent('result', '$value'));
            }),
      );
      await tester.pump();
    });
    await _settle();
  }

  Future<void> _pump(Duration duration) =>
      _guarded(() => tester.pump(duration));

  Future<void> _settle([int steps = 3]) async {
    for (var i = 0; i < steps; i++) {
      await _pump(_step);
    }
  }

  /// Taps at [point] with a raw touch (down + up) inside the guarded zone.
  Future<void> _tap(Offset point) async {
    final pointer = _pointer++;
    await _guarded(() async {
      tester.binding.handlePointerEvent(
        PointerDownEvent(pointer: pointer, position: point),
      );
      await tester.pump(const Duration(milliseconds: 20));
      tester.binding.handlePointerEvent(
        PointerUpEvent(pointer: pointer, position: point),
      );
      await tester.pump();
    });
  }

  /// The route on top of the navigator.
  ModalRoute<dynamic>? get topRoute {
    for (final r in _observer.routes.reversed) {
      if (r is ModalRoute && r.isActive) return r;
    }
    return null;
  }

  /// Controls on the top route.
  List<LiveControl> controls() {
    final context = topRoute?.subtreeContext;
    if (context is! Element || !context.mounted) return const [];
    return discoverControls(context);
  }

  /// Taps the control at [path] (openers first) and records its effects.
  Future<ProbeResult> probe(List<String> path) async {
    if (_trace) {
      debugPrint('[dead-control] $screen probe ${path.join(pathSeparator)}');
    }
    for (var step = 0; step < path.length; step++) {
      final id = path[step];
      final live = controls();
      final control = live.where((c) => c.identity == id).firstOrNull;
      if (control == null) {
        return ProbeResult(
          found: false,
          available: [for (final c in live) c.identity],
          missingStep: id,
        );
      }
      final point = await _reach(control);
      final last = step == path.length - 1;
      if (point == null) {
        return ProbeResult(found: true, control: control, reachable: false);
      }
      if (!last) {
        final before = _observer.routes.length;
        await _tap(point);
        await _settle();
        if (_observer.routes.length <= before) {
          return ProbeResult(
            found: false,
            missingStep: '$id (did not open a dialog or sheet)',
          );
        }
        continue;
      }
      return _measure(control, point);
    }
    throw StateError('empty path');
  }

  /// Scrolls [control] into view and finds where to tap it.
  Future<Offset?> _reach(LiveControl control) async {
    var point = findTapPoint(tester, control);
    if (point != null) return point;
    if (!control.element.mounted) return null;
    var scrolled = false;
    await _guarded(() async {
      await Scrollable.ensureVisible(control.element, alignment: 0.5);
      scrolled = true;
    });
    if (!scrolled) return null;
    await _pump(_step);
    if (!control.element.mounted) return null;
    point = findTapPoint(tester, control);
    return point;
  }

  Future<ProbeResult> _measure(LiveControl control, Offset point) async {
    // Idle window: what changes without any input.
    final idleMark = log.length;
    final noise = Noise();
    var last = fingerprint();
    for (var i = 0; i < _windowSteps; i++) {
      await _pump(_step);
      final next = fingerprint();
      noise.learn(last, next);
      last = next;
    }
    final before = last;
    final idleEvents = {
      for (final e in log.sublist(idleMark)) '${e.kind} ${e.detail}',
    };
    final focusBefore = FocusManager.instance.primaryFocus;
    final routesBefore = _observer.routes.length;
    final errorMark = errors.length;

    final mark = log.length;
    await _tap(point);
    for (var i = 0; i < _windowSteps; i++) {
      await _pump(_step);
    }
    final after = fingerprint();

    final effects = <String>[];
    var popupOpened = false;
    for (final e in log.sublist(mark)) {
      final line = '${e.kind} ${e.detail}';
      if (e.kind == 'api' &&
          e.detail.startsWith('GET ') &&
          idleEvents.contains(line)) {
        continue;
      }
      if (e.kind == 'channel' && idleEvents.contains(line)) continue;
      effects.add(e.toString());
    }
    if (_observer.routes.length > routesBefore) {
      final top = _observer.routes.last;
      popupOpened = top is PopupRoute;
    }
    final focusAfter = FocusManager.instance.primaryFocus;
    if (!identical(focusBefore, focusAfter)) {
      bool isEditing(FocusNode? node) {
        final context = node?.context;
        if (context == null || !context.mounted) return false;
        return context.widget is EditableText ||
            context.findAncestorWidgetOfExactType<EditableText>() != null;
      }

      final editing = isEditing(focusAfter);
      if (editing || isEditing(focusBefore)) {
        effects.add('focus: ${editing ? 'text field focused' : 'unfocused'}');
      }
    }
    final changes = screenChanges(before, after, noise);
    if (changes.isNotEmpty) {
      String clip(String s) => s.length > 90 ? '${s.substring(0, 90)}…' : s;
      final shown = changes.take(3).map(clip).toList();
      final more = changes.length - shown.length;
      effects.add(
        'ui: ${shown.join(' | ')}${more > 0 ? ' (+$more more)' : ''}',
      );
    }
    return ProbeResult(
      found: true,
      control: control,
      reachable: true,
      effects: effects,
      errors: errors.sublist(errorMark),
      popupOpened: popupOpened,
      poppedResult: screenPopped ? '$screenResult' : null,
    );
  }

  /// Disposes the app and restores global hooks.
  Future<void> close() async {
    if (_closed) return;
    await _guarded(() async {
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 30));
    });
    _closed = true;
    tester.binding.defaultBinaryMessenger.allMessagesHandler = null;
    FlutterError.onError = _previousOnError;
    _semantics?.dispose();
  }
}

String _describeRequest(RequestOptions o) {
  final body = o.data;
  var text = '${o.method} ${o.path}';
  if (body != null && body is! FormData) {
    var json = '';
    try {
      json = jsonEncode(body);
    } on Object {
      json = body.toString();
    }
    if (json.length > 120) json = '${json.substring(0, 120)}…';
    if (json.isNotEmpty && json != '{}' && json != 'null') text = '$text $json';
  }
  return text;
}

// ─── Manifest, allowlist, known dead controls ──────────────────────────────

/// One audited control in the manifest.
class ManifestEntry {
  ManifestEntry({
    required this.screen,
    required this.path,
    required this.label,
    required this.kind,
    required this.qaKey,
    required this.source,
    required this.caseId,
    required this.effects,
    this.openerLabel,
  });

  factory ManifestEntry.fromJson(String screen, Map<String, dynamic> json) =>
      ManifestEntry(
        screen: screen,
        path: (json['path'] as List).cast<String>(),
        label: json['label'] as String? ?? '',
        kind: json['kind'] as String? ?? '',
        qaKey: json['key'] as String?,
        source: json['source'] as String?,
        caseId: json['case'] as String?,
        effects: (json['effects'] as List? ?? const []).cast<String>(),
        openerLabel: json['opener'] as String?,
      );

  final String screen;
  final List<String> path;
  final String label;
  final String kind;
  final String? qaKey;
  final String? source;
  final String? caseId;
  final List<String> effects;
  final String? openerLabel;

  String get control => path.join(pathSeparator);

  Map<String, dynamic> toJson() => {
    'path': path,
    'label': label,
    'kind': kind,
    'key': qaKey,
    'source': source,
    'case': caseId,
    if (openerLabel != null) 'opener': openerLabel,
    'effects': effects,
  };

  /// `<Screen>: <control> has an effect [case:<id>]`.
  String testName({int occurrence = 1}) {
    final what = label.isEmpty ? kind : label;
    final prefix = openerLabel == null ? '' : '$openerLabel$pathSeparator';
    final n = occurrence > 1 ? ' (#$occurrence)' : '';
    final tag = caseId == null ? '' : ' [case:$caseId]';
    return '$screen: $prefix$what$n has an effect$tag';
  }
}

Map<String, List<ManifestEntry>> readManifest() {
  final file = File(deadControlManifestPath);
  if (!file.existsSync()) return {};
  final json = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
  final screens = json['screens'] as Map<String, dynamic>? ?? {};
  return {
    for (final e in screens.entries)
      e.key: [
        for (final c in (e.value as List).cast<Map<String, dynamic>>())
          ManifestEntry.fromJson(e.key, c),
      ],
  };
}

void writeManifest(Map<String, List<ManifestEntry>> screens) {
  final sorted = screens.keys.toList()..sort();
  final json = {
    'generated_by': 'dead_control_audit_test.dart (update mode)',
    'update_with': deadControlUpdateCommand,
    'note':
        'One audit test per entry. path = control identities (opener first); '
        'effects = what the tap did when this file was generated.',
    'screens': {
      for (final s in sorted) s: [for (final e in screens[s]!) e.toJson()],
    },
  };
  File(
    deadControlManifestPath,
  ).writeAsStringSync('${const JsonEncoder.withIndent(' ').convert(json)}\n');
}

/// `(screen, control)` → reason, for allowlisted or known-dead controls.
Map<(String, String), String> readControlList(String path, String field) {
  final file = File(path);
  if (!file.existsSync()) return {};
  final decoded = jsonDecode(file.readAsStringSync());
  final list = decoded is Map
      ? (decoded['controls'] as List? ?? const [])
      : decoded as List;
  return {
    for (final item in list.cast<Map<String, dynamic>>())
      (item['screen'] as String, item['control'] as String):
          item[field]?.toString() ?? '',
  };
}

// ─── Catalog matching ───────────────────────────────────────────────────────

class _CatalogControl {
  _CatalogControl(this.json, this.caseIds);
  final Map<String, dynamic> json;
  final Set<String> caseIds;
  String get id => json['id'] as String;
  String? get qaKey => json['qa_key'] as String?;
  String get label => json['label'] as String? ?? '';
  List<String> get altLabels =>
      (json['alt_labels'] as List? ?? const []).cast<String>();
  String get type => json['type'] as String? ?? '';
  String get widget => json['widget'] as String? ?? '';
  String? get sourceFile => (json['source'] as String?)?.split(':').first;
  int? get sourceLine =>
      int.tryParse((json['source'] as String?)?.split(':').last ?? '');
}

/// Matches live controls to catalog cases (`<feature>.<control>.action`).
class CatalogIndex {
  CatalogIndex._(this._byFile);

  static CatalogIndex load() {
    final byFile = <String, List<_CatalogControl>>{};
    final file = File(featureCatalogPath);
    if (file.existsSync()) {
      final json = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
      for (final feature
          in (json['features'] as List).cast<Map<String, dynamic>>()) {
        final cases = {
          for (final c
              in (feature['cases'] as List? ?? const [])
                  .cast<Map<String, dynamic>>())
            c['id'] as String,
        };
        for (final c
            in (feature['controls'] as List? ?? const [])
                .cast<Map<String, dynamic>>()) {
          final control = _CatalogControl(c, cases);
          final source = control.sourceFile;
          if (source == null || control.type == 'field') continue;
          // Catalog paths are repo-relative (`app/lib/...`).
          final rel = source.startsWith('app/') ? source.substring(4) : source;
          byFile.putIfAbsent(rel, () => []).add(control);
        }
      }
    }
    return CatalogIndex._(byFile);
  }

  final Map<String, List<_CatalogControl>> _byFile;

  static String _stripIconStyle(String icon) =>
      icon.replaceAll(RegExp(r'_(rounded|outlined|outline|sharp)$'), '');

  static bool _labelMatches(String pattern, String live) {
    if (pattern.isEmpty || live.isEmpty) return false;
    final p = pattern.toLowerCase().trim();
    final l = live.toLowerCase().trim();
    if (p == l) return true;
    // `Passed ({count})` matches `Passed (3)`.
    final regex = RegExp(
      '^${RegExp.escape(p).replaceAll(RegExp(r'\\\{[^}]*\\\}|\{[^}]*\}'), '.+')}\$',
    );
    if (regex.hasMatch(l)) return true;
    // `Back (icon arrow_back_rounded)` names the icon after the label.
    final icon = RegExp(r'\(icon ([a-z0-9_]+)\)').firstMatch(p)?.group(1);
    if (icon != null &&
        l.startsWith('icon ') &&
        _stripIconStyle(l.substring(5)) == _stripIconStyle(icon)) {
      return true;
    }
    final bare = p.replaceAll(RegExp(r'\s*\(icon [^)]*\)'), '').trim();
    return bare.isNotEmpty && (bare == l || l.startsWith('$bare ·'));
  }

  /// The `.action` case for [control], when one matches.
  ///
  /// A `qa.*` key or the visible label identifies a catalog control; source
  /// lines only break ties (they drift as files are edited, and a composite
  /// widget's call line is shared by all of its callbacks).
  String? caseFor(LiveControl control) {
    _CatalogControl? best;
    var bestScore = 0;
    final files = {for (final s in control.sourceChain) s.file};
    final near = control.sourceChain.take(3).toList();
    for (final file in files) {
      for (final c in _byFile[file] ?? const <_CatalogControl>[]) {
        var score = 0;
        if (c.qaKey != null && c.qaKey == control.qaKey) score += 100;
        if (_labelMatches(c.label, control.label) ||
            c.altLabels.any((a) => _labelMatches(a, control.label))) {
          score += 50;
        }
        final line = c.sourceLine;
        if (line != null) {
          var lineScore = 0;
          for (final s in near) {
            if (s.file != file) continue;
            final d = (s.line - line).abs();
            if (d <= 1) {
              lineScore = 20;
            } else if (d <= 4 && lineScore < 10) {
              lineScore = 10;
            }
          }
          score += lineScore;
        }
        final widget = c.widget.split(' ').first;
        if (widget == control.callSiteType || widget == control.kind) {
          score += 5;
        }
        if (score > bestScore) {
          bestScore = score;
          best = c;
        }
      }
    }
    if (best == null || bestScore < 50) return null;
    final caseId = '${best.id}.action';
    return best.caseIds.contains(caseId) ? caseId : null;
  }
}
