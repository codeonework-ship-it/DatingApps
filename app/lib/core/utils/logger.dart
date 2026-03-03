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

class AppLogger {
  factory AppLogger() => _instance;

  AppLogger._internal();
  static final AppLogger _instance = AppLogger._internal();

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
