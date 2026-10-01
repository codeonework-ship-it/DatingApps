import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/app_runtime_config.dart';
import 'api_client_provider.dart';

class RuntimeFeatureFlags {
  const RuntimeFeatureFlags(this.values);

  factory RuntimeFeatureFlags.fromApi(dynamic payload) {
    final root = payload is Map
        ? payload.cast<String, dynamic>()
        : const <String, dynamic>{};
    final rows = root['flags'];
    final values = <String, bool>{...defaults.values};
    if (rows is List) {
      for (final row in rows) {
        if (row is! Map) {
          continue;
        }
        final key = row['key']?.toString().trim() ?? '';
        final value = row['value_bool'];
        if (key.isNotEmpty && value is bool) {
          values[key] = value;
        }
      }
    }
    return RuntimeFeatureFlags(Map.unmodifiable(values));
  }

  static const _allOn = <String, bool>{
    'gifts_enabled': true,
    'voice_icebreakers_enabled': true,
    'rooms_enabled': true,
    'calls_enabled': true,
    'billing_enabled': true,
    'quest_workflow_v2_enabled': true,
    'circles_enabled': true,
    'daily_prompts_enabled': true,
    'match_nudges_enabled': true,
    'group_coffee_polls_enabled': true,
    'safety_sos_enabled': true,
    'level_progression_enabled': true,
    'activity_sessions_enabled': true,
    'identity_verification_enabled': true,
    'digital_gestures_enabled': true,
    'intentional_dating_enabled': true,
    'date_plans_enabled': true,
    'graduation_enabled': true,
    'friend_intros_enabled': true,
    'copilot_enabled': true,
    'curated_daily_set_enabled': true,
    'photo_themes_enabled': true,
    'clubs_enabled': true,
    'social_chat_enabled': true,
    'groups_enabled': true,
  };

  /// Capabilities the first-release contract excludes. Mirrors the backend's
  /// `config.FirstReleaseExcludedFlags`; the server reports these off in
  /// production-like environments and rejects their commands.
  static const releaseExcludedKeys = <String>{
    'intentional_dating_enabled',
    'billing_enabled',
    'gifts_enabled',
    'quest_workflow_v2_enabled',
    'calls_enabled',
    'voice_icebreakers_enabled',
    'identity_verification_enabled',
    'level_progression_enabled',
  };

  /// Flags before the server has answered. A local build shows everything; any
  /// other build keeps release-excluded surfaces hidden until the server says
  /// otherwise, so a slow or failed first fetch never exposes them.
  static RuntimeFeatureFlags get defaults =>
      AppRuntimeConfig.apiEnvironment == 'local'
      ? const RuntimeFeatureFlags(_allOn)
      : RuntimeFeatureFlags(
          Map.unmodifiable(<String, bool>{
            ..._allOn,
            for (final key in releaseExcludedKeys) key: false,
          }),
        );

  final Map<String, bool> values;

  bool enabled(String key, {bool fallback = false}) => values[key] ?? fallback;
}

/// Polling keeps operator changes visible without restarting the application.
/// The last safe/default state is retained through transient local API errors.
final runtimeFeatureFlagsProvider = StreamProvider<RuntimeFeatureFlags>((ref) {
  final controller = StreamController<RuntimeFeatureFlags>();
  var last = RuntimeFeatureFlags.defaults;

  Future<void> refresh() async {
    try {
      final response = await ref
          .read(apiClientProvider)
          .get<dynamic>('/config/flags');
      last = RuntimeFeatureFlags.fromApi(response.data);
    } on Object {
      // Runtime controls must fail safely and must not break navigation.
    }
    if (!controller.isClosed) {
      controller.add(last);
    }
  }

  unawaited(refresh());
  final timer = Timer.periodic(
    const Duration(seconds: 15),
    (_) => unawaited(refresh()),
  );
  ref.onDispose(() {
    timer.cancel();
    unawaited(controller.close());
  });
  return controller.stream;
});
