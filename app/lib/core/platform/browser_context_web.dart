import 'dart:async';
import 'dart:convert';
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
void openWebsiteHome() {
  web.window.location.assign('/');
}
