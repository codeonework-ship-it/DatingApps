import 'dart:collection';

import 'package:flutter/foundation.dart';

import 'pii_scrubber.dart';

/// Wire categories accepted by `POST /v1/client/errors`.
enum BreadcrumbCategory { navigation, api, lifecycle, ui }

/// One step the member took shortly before an error. Breadcrumbs carry route
/// templates and status codes only: never ids, query strings or bodies.
@immutable
class Breadcrumb {
  const Breadcrumb({
    required this.at,
    required this.category,
    required this.message,
  });

  static const int maxMessageLength = 200;

  final DateTime at;
  final BreadcrumbCategory category;
  final String message;

  Map<String, Object?> toJson() => <String, Object?>{
    'at': at.toUtc().toIso8601String(),
    'category': category.name,
    'message': message,
  };

  static Breadcrumb? tryParse(Object? raw) {
    if (raw is! Map) {
      return null;
    }
    final at = DateTime.tryParse(raw['at']?.toString() ?? '');
    final category = BreadcrumbCategory.values.where(
      (c) => c.name == raw['category'],
    );
    final message = raw['message']?.toString() ?? '';
    if (at == null || category.isEmpty || message.isEmpty) {
      return null;
    }
    return Breadcrumb(at: at, category: category.first, message: message);
  }
}

/// Ring buffer holding the most recent breadcrumbs.
class BreadcrumbBuffer {
  BreadcrumbBuffer({this.capacity = 20});

  final int capacity;
  final ListQueue<Breadcrumb> _items = ListQueue<Breadcrumb>();

  void add(Breadcrumb breadcrumb) {
    _items.add(breadcrumb);
    while (_items.length > capacity) {
      _items.removeFirst();
    }
  }

  List<Breadcrumb> snapshot() => List<Breadcrumb>.unmodifiable(_items);

  void clear() => _items.clear();

  int get length => _items.length;
}

/// `GET /profile/<id> -> 200`, or `-> ERR` when no response arrived.
///
/// [path] may be relative (`/profile/42?x=1`) or absolute
/// (`https://host/v1/profile/42`); only the templated path is kept.
String apiBreadcrumbMessage(String method, String path, int? status) {
  var rawPath = path;
  if (rawPath.contains('://')) {
    rawPath = Uri.tryParse(rawPath)?.path ?? '';
  }
  if (!rawPath.startsWith('/')) {
    rawPath = '/$rawPath';
  }
  final template = PiiScrubber.routeTemplate(rawPath);
  final verb = method.toUpperCase();
  final outcome = status?.toString() ?? 'ERR';
  return clampBreadcrumb('$verb $template -> $outcome');
}

String clampBreadcrumb(String message) =>
    message.length > Breadcrumb.maxMessageLength
    ? message.substring(0, Breadcrumb.maxMessageLength)
    : message;
