import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

import 'breadcrumbs.dart';
import 'client_error_reporter.dart';
import 'pii_scrubber.dart';

/// Records navigation breadcrumbs and the current screen for crash reports.
///
/// Only route templates are kept: a route's `settings.name` with ids and the
/// query string removed, or, for the unnamed `MaterialPageRoute`s this app
/// mostly pushes, the screen widget's type name (e.g. `SettingsScreen`).
/// Route arguments are never read.
///
/// A navigator observer can be attached to only one navigator at a time;
/// create one per navigator.
class ClientErrorNavigatorObserver extends NavigatorObserver {
  ClientErrorNavigatorObserver({ClientErrorReporter? reporter})
    : _reporter = reporter;

  final ClientErrorReporter? _reporter;
  final Expando<String> _names = Expando<String>('client_error_route_name');

  ClientErrorReporter get _target => _reporter ?? ClientErrorReporter.instance;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      _withName(route, (name) => _record('push', name));

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _record('pop', templateFor(route), screen: _screenOf(previousRoute));
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    if (newRoute == null) {
      return;
    }
    _withName(newRoute, (name) => _record('replace', name));
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _record('remove', templateFor(route), screen: _target.currentScreen);
  }

  /// The privacy-safe name used for [route].
  String templateFor(Route<dynamic>? route) {
    if (route == null) {
      return '';
    }
    final name = route.settings.name;
    if (name != null && name.isNotEmpty) {
      return PiiScrubber.routeTemplate(name);
    }
    return _names[route] ?? _kindOf(route);
  }

  String? _screenOf(Route<dynamic>? route) =>
      route == null ? null : templateFor(route);

  void _record(String action, String name, {String? screen}) {
    final target = _target;
    if (!target.isCapturing) {
      return;
    }
    target
      ..currentScreen = screen ?? name
      ..addBreadcrumb(BreadcrumbCategory.navigation, '$action $name');
  }

  /// Calls [then] with the route's name, waiting one frame for unnamed routes
  /// so the screen widget exists and its type can be read.
  void _withName(Route<dynamic> route, void Function(String name) then) {
    if (!_target.isCapturing) {
      return;
    }
    final named = route.settings.name;
    if ((named != null && named.isNotEmpty) || route is! ModalRoute) {
      then(templateFor(route));
      return;
    }
    SchedulerBinding.instance.addPostFrameCallback((_) {
      final context = route.subtreeContext;
      final found = context == null ? null : _screenWidgetName(context);
      if (found != null) {
        _names[route] = found;
      }
      then(templateFor(route));
    });
  }

  static final RegExp _screenSuffix = RegExp(
    r'(Screen|Page|Sheet|Dialog|Workspace|View)$',
  );

  /// Finds the first descendant widget whose type looks like a screen.
  static String? _screenWidgetName(BuildContext context) {
    String? found;
    var visited = 0;
    void visit(Element element, int depth) {
      if (found != null || visited > 60 || depth > 12) {
        return;
      }
      visited++;
      var type = element.widget.runtimeType.toString();
      final generic = type.indexOf('<');
      if (generic > 0) {
        type = type.substring(0, generic);
      }
      if (_screenSuffix.hasMatch(type)) {
        found = type;
        return;
      }
      element.visitChildren((child) => visit(child, depth + 1));
    }

    context.visitChildElements((child) => visit(child, 0));
    return found == null ? null : clampBreadcrumb(found!);
  }

  static String _kindOf(Route<dynamic> route) {
    if (route is PopupRoute) {
      return 'popup';
    }
    if (route is PageRoute) {
      return 'page';
    }
    return 'route';
  }
}

/// Observer for the app's root navigator (attach to one navigator only).
final ClientErrorNavigatorObserver clientErrorNavigatorObserver =
    ClientErrorNavigatorObserver();
