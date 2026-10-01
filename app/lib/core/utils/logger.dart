import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';

const String _correlationZoneKey = 'correlation_id';

class CorrelationContext {
  CorrelationContext._();

  static String current() {
    final value = Zone.current[_correlationZoneKey];
    if (value is String) {
      return value;
    }
    return '';
  }

  static String generate() {
    final now = DateTime.now().microsecondsSinceEpoch.toRadixString(16);
    final rand = Random().nextInt(0x7fffffff).toRadixString(16);
    return '$now-$rand';
  }

  static T runWithId<T>(String correlationId, T Function() body) =>
      runZoned(body, zoneValues: {_correlationZoneKey: correlationId});
}

/// Structured app logger.
///
/// Debug builds print every level. Profile and release builds print WARN and
/// above only, so routine request/response chatter never reaches device logs.
class AppLogger {
  factory AppLogger() => _instance;

  AppLogger._internal();
  static final AppLogger _instance = AppLogger._internal();

  /// Receives handled errors passed to [error] together with an exception.
  /// Installed by the self-hosted crash reporter; kept as a callback so the
  /// logger has no dependency on it (and cannot recurse into it).
  static void Function(String message, Object error, StackTrace? stackTrace)?
  errorSink;

  void debug(
    String message, [
    dynamic error,
    StackTrace? stackTrace,
    Map<String, dynamic>? fields,
    String? correlationId,
  ]) {
    _log('DEBUG', message, error, stackTrace, fields, correlationId);
  }

  void info(
    String message, [
    dynamic error,
    StackTrace? stackTrace,
    Map<String, dynamic>? fields,
    String? correlationId,
  ]) {
    _log('INFO', message, error, stackTrace, fields, correlationId);
  }

  void warning(
    String message, [
    dynamic error,
    StackTrace? stackTrace,
    Map<String, dynamic>? fields,
    String? correlationId,
  ]) {
    _log('WARN', message, error, stackTrace, fields, correlationId);
  }

  void error(
    String message, [
    dynamic error,
    StackTrace? stackTrace,
    Map<String, dynamic>? fields,
    String? correlationId,
  ]) {
    _log('ERROR', message, error, stackTrace, fields, correlationId);
    final sink = errorSink;
    if (sink != null && error != null) {
      try {
        sink(message, error as Object, stackTrace);
      } on Object {
        // Reporting must never break the caller.
      }
    }
  }

  void critical(
    String message, [
    dynamic error,
    StackTrace? stackTrace,
    Map<String, dynamic>? fields,
    String? correlationId,
  ]) {
    _log('CRITICAL', message, error, stackTrace, fields, correlationId);
  }

  void _log(
    String level,
    String message,
    dynamic error,
    StackTrace? stackTrace,
    Map<String, dynamic>? fields,
    String? correlationId,
  ) {
    if (!kDebugMode && (level == 'DEBUG' || level == 'INFO')) {
      return;
    }
    final payload = <String, dynamic>{
      'timestamp': DateTime.now().toUtc().toIso8601String(),
      'level': level,
      'message': message,
    };

    final resolvedCorrelationId =
        correlationId ??
        fields?['correlation_id']?.toString() ??
        CorrelationContext.current();
    if (resolvedCorrelationId.isNotEmpty) {
      payload['correlation_id'] = resolvedCorrelationId;
    }
    if (fields != null && fields.isNotEmpty) {
      payload['fields'] = fields;
    }
    if (error != null) {
      payload['error'] = error.toString();
    }
    if (stackTrace != null) {
      payload['stack_trace'] = stackTrace.toString();
    }

    debugPrint(jsonEncode(payload));
  }
}

AppLogger get log => AppLogger();
