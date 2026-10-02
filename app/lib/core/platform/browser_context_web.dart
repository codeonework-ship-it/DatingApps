import 'dart:async';
import 'dart:convert';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'package:web/web.dart' as web;

const _key = 'connect.session.v1';
Map<String, dynamic>? readBrowserSession() {
  try {
    final raw = web.window.sessionStorage.getItem(_key);
    return raw == null
        ? null
        : (jsonDecode(raw) as Map).cast<String, dynamic>();
  } on Object {
    return null;
  }
}

void writeBrowserSession(Map<String, dynamic>? data) {
  try {
    if (data == null) {
      web.window.sessionStorage.removeItem(_key);
    } else {
      web.window.sessionStorage.setItem(_key, jsonEncode(data));
    }
  } on Object {
    /* Private browsing may refuse storage; in-memory auth still works. */
  }
}

String _route = Uri.base.fragment.startsWith('/')
    ? Uri.base.fragment.split('?').first
    : '/';
final _routeChanges = StreamController<void>.broadcast();
String currentWebRoute() => _route;
void setWebRoute(String route) {
  if (route == _route) return;
  _route = route;
  _routeChanges.add(null);
}

Stream<void> get webRouteChanges => _routeChanges.stream;

/// Steps back one browser history entry when that entry belongs to this app,
/// like the browser's own Back button; the route it lands on arrives through
/// [webRouteChanges]. Flutter's router tags every entry it owns with a
/// `serialCount` that starts at 0 on the page the app was opened on, so 0
/// means anything earlier is another site or page (a deep link): returns
/// `false` without navigating and the caller picks an in-app fallback.
bool webHistoryBack() {
  try {
    final state = web.window.history.state;
    if (state == null || !state.isA<JSObject>()) return false;
    final serial = (state as JSObject)['serialCount'];
    if (serial == null ||
        !serial.isA<JSNumber>() ||
        (serial as JSNumber).toDartDouble < 1) {
      return false;
    }
    web.window.history.back();
    return true;
  } on Object {
    return false;
  }
}

void openWebsiteHome() {
  web.window.location.assign('/');
}
