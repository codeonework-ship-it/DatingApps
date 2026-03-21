import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum NetworkQualityStatus { healthy, unstable, offline }

class NetworkQualityState {
  const NetworkQualityState({
    this.status = NetworkQualityStatus.healthy,
    this.message,
    this.lastLatencyMs,
  });

  final NetworkQualityStatus status;
  final String? message;
  final int? lastLatencyMs;

  NetworkQualityState copyWith({
    NetworkQualityStatus? status,
    String? message,
    int? lastLatencyMs,
  }) => NetworkQualityState(
    status: status ?? this.status,
    message: message,
    lastLatencyMs: lastLatencyMs ?? this.lastLatencyMs,
  );
}

class NetworkQualityNotifier extends StateNotifier<NetworkQualityState> {
  NetworkQualityNotifier() : super(const NetworkQualityState());

  static const int minimumSmoothBandwidthMbps = 5;
  static const int unstableLatencyThresholdMs = 2200;

  void reportSuccess(int durationMs) {
    if (durationMs >= unstableLatencyThresholdMs) {
      state = NetworkQualityState(
        status: NetworkQualityStatus.unstable,
        lastLatencyMs: durationMs,
        message:
            'Weak network detected. Use at least '
            '$minimumSmoothBandwidthMbps Mbps for smoother '
            'chat, gifts, and gestures.',
      );
      return;
    }

    if (state.status != NetworkQualityStatus.healthy ||
        state.lastLatencyMs != durationMs) {
      state = NetworkQualityState(
        status: NetworkQualityStatus.healthy,
        lastLatencyMs: durationMs,
      );
    }
  }

  void reportFailure(DioException error) {
    final offline =
        error.type == DioExceptionType.connectionError ||
        error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        _looksOffline(error.message);

    state = NetworkQualityState(
      status: offline
          ? NetworkQualityStatus.offline
          : NetworkQualityStatus.unstable,
      message: offline
          ? 'No stable network connection. Reconnect to continue using the app.'
          : 'Network is weak. Use at least '
                '$minimumSmoothBandwidthMbps Mbps for a '
                'smoother experience.',
    );
  }

  bool _looksOffline(String? message) {
    final text = (message ?? '').toLowerCase();
    return text.contains('socketexception') ||
        text.contains('network is unreachable') ||
        text.contains('failed host lookup');
  }
}

final networkQualityProvider =
    StateNotifierProvider<NetworkQualityNotifier, NetworkQualityState>(
      (ref) => NetworkQualityNotifier(),
    );
