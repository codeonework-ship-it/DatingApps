import 'dart:async';
import 'dart:js_interop';

import 'package:web/web.dart' as web;

void Function()? _reclaim;
var _armedUntil = DateTime.fromMillisecondsSinceEpoch(0);
var _installed = false;

/// With web accessibility on, each toolbar button is a real, focusable
/// browser element. Pressing one moves the browser's focus off the story's
/// hidden input; the framework puts it back, but the engine then hands the
/// browser's focus to the Flutter view while the framework still believes the
/// story is focused, so the next keystrokes go nowhere. If that happens just
/// after a toolbar press, [reclaim] runs so the story can reconnect its input.
///
/// A press can also leave the browser's focus on the button itself (WEB-14:
/// the second toolbar press in a row) with no focusin to react to, so once
/// the press has settled [reclaim] also runs if no text input has the focus.
void holdTextFocusAfterToolbarPress(void Function() reclaim) {
  _install();
  _reclaim = reclaim;
  final armedUntil = DateTime.now().add(const Duration(milliseconds: 500));
  _armedUntil = armedUntil;
  Timer(const Duration(milliseconds: 120), () {
    // Superseded by a newer press, or already handled by the focusin path.
    if (!identical(_reclaim, reclaim) || _armedUntil != armedUntil) {
      return;
    }
    if (_textInputHasFocus()) {
      return;
    }
    // Stay armed: the engine may still hand focus to the Flutter view.
    reclaim();
  });
}

bool _textInputHasFocus() {
  final tag = web.document.activeElement?.tagName;
  return tag == 'TEXTAREA' || tag == 'INPUT';
}

void _install() {
  if (_installed) {
    return;
  }
  _installed = true;
  web.document.addEventListener(
    'focusin',
    ((web.Event event) {
      final target = event.target;
      if (target == null || !target.isA<web.Element>()) {
        return;
      }
      final reclaim = _reclaim;
      if (reclaim == null ||
          (target as web.Element).tagName != 'FLUTTER-VIEW' ||
          DateTime.now().isAfter(_armedUntil)) {
        return;
      }
      _armedUntil = DateTime.fromMillisecondsSinceEpoch(0);
      _reclaim = null;
      Timer.run(reclaim);
    }).toJS,
    true.toJS,
  );
}
