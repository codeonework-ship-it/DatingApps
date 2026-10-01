import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_error_message.dart';
import '../../../core/permissions/device_permission_service.dart';
import '../../../core/providers/api_client_provider.dart';
import '../../auth/providers/auth_provider.dart';

class SosAlert {
  const SosAlert({
    required this.id,
    required this.userId,
    required this.emergencyLevel,
    required this.status,
    required this.triggeredAt,
    this.matchId,
    this.message,
    this.latitude,
    this.longitude,
    this.resolvedAt,
    this.resolutionNote,
  });

  factory SosAlert.fromJson(Map<String, dynamic> json) => SosAlert(
    id: json['id']?.toString() ?? '',
    userId: json['user_id']?.toString() ?? '',
    matchId: _optionalText(json['match_id']),
    emergencyLevel: json['emergency_level']?.toString() ?? 'high',
    message: _optionalText(json['message']),
    latitude: (json['latitude'] as num?)?.toDouble(),
    longitude: (json['longitude'] as num?)?.toDouble(),
    status: json['status']?.toString() ?? 'active',
    triggeredAt:
        DateTime.tryParse(json['triggered_at']?.toString() ?? '') ??
        DateTime.now(),
    resolvedAt: DateTime.tryParse(json['resolved_at']?.toString() ?? ''),
    resolutionNote: _optionalText(json['resolution_note']),
  );

  final String id;
  final String userId;
  final String? matchId;
  final String emergencyLevel;
  final String? message;
  final double? latitude;
  final double? longitude;
  final String status;
  final DateTime triggeredAt;
  final DateTime? resolvedAt;
  final String? resolutionNote;

  bool get hasLocation =>
      latitude != null &&
      longitude != null &&
      (latitude!.abs() > .000001 || longitude!.abs() > .000001);
}

String? _optionalText(Object? value) {
  final text = value?.toString().trim() ?? '';
  return text.isEmpty ? null : text;
}

class SosState {
  const SosState({
    this.alerts = const [],
    this.isLoading = false,
    this.isSending = false,
    this.error,
    this.lastAlertIncludedLocation,
  });

  final List<SosAlert> alerts;
  final bool isLoading;
  final bool isSending;
  final String? error;
  final bool? lastAlertIncludedLocation;

  SosState copyWith({
    List<SosAlert>? alerts,
    bool? isLoading,
    bool? isSending,
    Object? error = _unset,
    Object? lastAlertIncludedLocation = _unset,
  }) => SosState(
    alerts: alerts ?? this.alerts,
    isLoading: isLoading ?? this.isLoading,
    isSending: isSending ?? this.isSending,
    error: identical(error, _unset) ? this.error : error as String?,
    lastAlertIncludedLocation: identical(lastAlertIncludedLocation, _unset)
        ? this.lastAlertIncludedLocation
        : lastAlertIncludedLocation as bool?,
  );

  static const Object _unset = Object();
}

class SosNotifier extends StateNotifier<SosState> {
  SosNotifier(this.ref) : super(const SosState());

  final Ref ref;

  String? get _userId => ref.read(authNotifierProvider).userId;

  Future<void> loadAlerts() async {
    final userId = _userId;
    if (userId == null) {
      state = state.copyWith(error: 'Please sign in to view SOS history.');
      return;
    }
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await ref
          .read(apiClientProvider)
          .get<dynamic>(
            '/safety/sos/$userId',
            queryParameters: const {'limit': 100},
          );
      final body = (response.data as Map?)?.cast<String, dynamic>() ?? {};
      final alerts = ((body['alerts'] as List?) ?? const [])
          .whereType<Map<Object?, Object?>>()
          .map((row) => SosAlert.fromJson(row.cast<String, dynamic>()))
          .toList();
      state = state.copyWith(alerts: alerts, isLoading: false, error: null);
    } on Object catch (error) {
      state = state.copyWith(
        isLoading: false,
        error: apiErrorMessage(error, fallback: 'Unable to load SOS history.'),
      );
    }
  }

  Future<SosAlert?> activate({
    required String emergencyLevel,
    required String message,
    String? matchId,
  }) async {
    final userId = _userId;
    if (userId == null) {
      state = state.copyWith(error: 'Please sign in before activating SOS.');
      return null;
    }
    state = state.copyWith(
      isSending: true,
      error: null,
      lastAlertIncludedLocation: null,
    );

    SosCoordinates? coordinates;
    try {
      coordinates = await ref
          .read(devicePermissionServiceProvider)
          .currentSosCoordinates();
    } on Object {
      coordinates = null;
    }

    try {
      final response = await ref
          .read(apiClientProvider)
          .post<dynamic>(
            '/safety/sos',
            data: {
              'user_id': userId,
              if (matchId != null && matchId.trim().isNotEmpty)
                'match_id': matchId.trim(),
              'emergency_level': emergencyLevel,
              'message': message.trim(),
              'latitude': coordinates?.latitude ?? 0,
              'longitude': coordinates?.longitude ?? 0,
            },
          );
      final body = (response.data as Map?)?.cast<String, dynamic>() ?? {};
      final raw = (body['alert'] as Map?)?.cast<String, dynamic>();
      if (raw == null) throw const FormatException('Missing SOS alert');
      final alert = SosAlert.fromJson(raw);
      state = state.copyWith(
        alerts: [alert, ...state.alerts.where((item) => item.id != alert.id)],
        isSending: false,
        error: null,
        lastAlertIncludedLocation: coordinates != null,
      );
      return alert;
    } on Object catch (error) {
      state = state.copyWith(
        isSending: false,
        error: apiErrorMessage(error, fallback: 'Unable to activate SOS.'),
      );
      return null;
    }
  }
}

final sosProvider = StateNotifierProvider<SosNotifier, SosState>(
  (ref) => SosNotifier(ref),
);
