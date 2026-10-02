import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/app_localizations.dart';
import '../i18n/app_l10n.dart';

enum NetworkQualityStatus { healthy, unstable, offline }

/// Which advisory a non-healthy [NetworkQualityState] carries, so widgets
/// can show it in the member's language
/// ([NetworkQualityState.localizedMessage]).
enum NetworkQualityNotice { slowResponses, offline, weakNetwork }

class NetworkQualityState {
  const NetworkQualityState({
    this.status = NetworkQualityStatus.healthy,
    this.message,
    this.lastLatencyMs,
    this.notice,
  });

  final NetworkQualityStatus status;

  /// The advisory in the language current when it was raised. Widgets should
  /// prefer [localizedMessage].
  final String? message;
  final int? lastLatencyMs;
  final NetworkQualityNotice? notice;

  /// [message] in the language of [l10n], or null when there is no advisory.
  String? localizedMessage(AppLocalizations l10n) {
    const mbps = NetworkQualityNotifier.minimumSmoothBandwidthMbps;
    return switch (notice) {
      NetworkQualityNotice.slowResponses => l10n.networkSlowResponse(mbps),
      NetworkQualityNotice.offline => l10n.networkOffline,
      NetworkQualityNotice.weakNetwork => l10n.networkWeak(mbps),
      null => message,
    };
  }

  NetworkQualityState copyWith({
    NetworkQualityStatus? status,
    String? message,
    int? lastLatencyMs,
    NetworkQualityNotice? notice,
  }) => NetworkQualityState(
    status: status ?? this.status,
    message: message,
    lastLatencyMs: lastLatencyMs ?? this.lastLatencyMs,
    notice: notice,
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
        notice: NetworkQualityNotice.slowResponses,
        message: currentAppL10n().networkSlowResponse(
          minimumSmoothBandwidthMbps,
        ),
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
      notice: offline
          ? NetworkQualityNotice.offline
          : NetworkQualityNotice.weakNetwork,
      message: offline
          ? currentAppL10n().networkOffline
          : currentAppL10n().networkWeak(minimumSmoothBandwidthMbps),
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
