import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/feature_flags.dart';
import '../../../core/providers/api_client_provider.dart';
import '../../../core/utils/logger.dart';
import '../../../l10n/app_localizations.dart';
import '../../auth/providers/auth_provider.dart';
import '../../celebrations/reward_ledger.dart';
import '../engagement_l10n.dart';
import '../../../core/network/api_error_message.dart';

// Names below are the server's; they are empty when it sent none and the
// screen then shows "Level 3" / "Level 3 reward" in the member's language.
class LevelDefinition {
  const LevelDefinition({
    required this.level,
    required this.name,
    required this.thresholdXp,
    required this.trustGate,
    required this.rewardSummary,
  });

  factory LevelDefinition.fromJson(Map<String, dynamic> json) =>
      LevelDefinition(
        level: (json['level'] as num?)?.toInt() ?? 1,
        name: json['name']?.toString() ?? '',
        thresholdXp: (json['threshold_xp'] as num?)?.toInt() ?? 0,
        trustGate: json['trust_gate'] == true,
        rewardSummary: json['reward_summary']?.toString() ?? '',
      );

  final int level;
  final String name;
  final int thresholdXp;
  final bool trustGate;
  final String rewardSummary;
}

class LevelReward {
  const LevelReward({
    required this.key,
    required this.level,
    required this.name,
    required this.description,
    required this.type,
    required this.trustRequired,
    required this.claimed,
  });

  factory LevelReward.fromJson(Map<String, dynamic> json) => LevelReward(
    key: json['reward_key']?.toString() ?? '',
    level: (json['level'] as num?)?.toInt() ?? 1,
    name: json['name']?.toString() ?? '',
    description: json['description']?.toString() ?? '',
    type: json['reward_type']?.toString() ?? 'feature',
    trustRequired: json['trust_required'] == true,
    claimed: json['claimed'] == true,
  );

  final String key;
  final int level;
  final String name;
  final String description;
  final String type;
  final bool trustRequired;
  final bool claimed;
}

class XPEntry {
  const XPEntry({
    required this.sequence,
    required this.source,
    required this.awardedXp,
    required this.multiplier,
    required this.occurredAt,
  });

  factory XPEntry.fromJson(Map<String, dynamic> json) => XPEntry(
    sequence: (json['sequence'] as num?)?.toInt() ?? 0,
    source: json['source']?.toString() ?? 'activity',
    awardedXp: (json['awarded_xp'] as num?)?.toInt() ?? 0,
    multiplier: (json['multiplier'] as num?)?.toDouble() ?? 1,
    occurredAt: DateTime.tryParse(json['occurred_at']?.toString() ?? ''),
  );

  final int sequence;
  final String source;
  final int awardedXp;
  final double multiplier;
  final DateTime? occurredAt;
}

class LevelProgressionView {
  const LevelProgressionView({
    required this.totalXp,
    required this.currentLevel,
    required this.levelName,
    required this.currentLevelXp,
    required this.nextLevelXp,
    required this.progressPercent,
    required this.trustGateSatisfied,
    required this.frozen,
    required this.projectionLagSeconds,
    required this.levels,
    required this.rewards,
  });

  factory LevelProgressionView.fromJson(Map<String, dynamic> json) =>
      LevelProgressionView(
        totalXp: (json['total_xp'] as num?)?.toInt() ?? 0,
        currentLevel: (json['current_level'] as num?)?.toInt() ?? 1,
        levelName: json['level_name']?.toString() ?? '',
        currentLevelXp: (json['current_level_xp'] as num?)?.toInt() ?? 0,
        nextLevelXp: (json['next_level_xp'] as num?)?.toInt(),
        progressPercent: (json['progress_percent'] as num?)?.toDouble() ?? 0,
        trustGateSatisfied: json['trust_gate_satisfied'] != false,
        frozen: json['progression_frozen'] == true,
        projectionLagSeconds:
            (json['projection_lag_seconds'] as num?)?.toDouble() ?? 0,
        levels: ((json['levels'] as List?) ?? const <dynamic>[])
            .whereType<Map<dynamic, dynamic>>()
            .map((item) => LevelDefinition.fromJson(item.cast()))
            .toList(growable: false),
        rewards: ((json['rewards'] as List?) ?? const <dynamic>[])
            .whereType<Map<dynamic, dynamic>>()
            .map((item) => LevelReward.fromJson(item.cast()))
            .toList(growable: false),
      );

  final int totalXp;
  final int currentLevel;
  final String levelName;
  final int currentLevelXp;
  final int? nextLevelXp;
  final double progressPercent;
  final bool trustGateSatisfied;
  final bool frozen;
  final double projectionLagSeconds;
  final List<LevelDefinition> levels;
  final List<LevelReward> rewards;
}

class LevelProgressionState {
  const LevelProgressionState({
    this.isLoading = false,
    this.claimingReward,
    this.error,
    this.view,
    this.ledger = const <XPEntry>[],
  });

  final bool isLoading;
  final String? claimingReward;
  final String? error;
  final LevelProgressionView? view;
  final List<XPEntry> ledger;

  LevelProgressionState copyWith({
    bool? isLoading,
    String? claimingReward,
    bool clearClaimingReward = false,
    String? error,
    bool clearError = false,
    LevelProgressionView? view,
    List<XPEntry>? ledger,
  }) => LevelProgressionState(
    isLoading: isLoading ?? this.isLoading,
    claimingReward: clearClaimingReward
        ? null
        : (claimingReward ?? this.claimingReward),
    error: clearError ? null : (error ?? this.error),
    view: view ?? this.view,
    ledger: ledger ?? this.ledger,
  );
}

class LevelProgressionNotifier extends StateNotifier<LevelProgressionState> {
  LevelProgressionNotifier(this._ref) : super(const LevelProgressionState()) {
    Future<void>.microtask(load);
  }

  final Ref _ref;

  AppLocalizations get _l => engagementL10nFor(_ref);

  Future<void> load() async {
    final userId = _currentUserId();
    if (userId == null) {
      state = state.copyWith(error: _l.engagementLevelSignIn);
      return;
    }
    state = state.copyWith(isLoading: true, clearError: true);
    if (kUseMockAuth) {
      state = state.copyWith(
        isLoading: false,
        view: _mockView,
        ledger: const <XPEntry>[
          XPEntry(
            sequence: 3,
            source: 'daily_prompt_submitted',
            awardedXp: 20,
            multiplier: 1,
            occurredAt: null,
          ),
        ],
      );
      return;
    }
    try {
      final dio = _ref.read(apiClientProvider);
      final responses = await Future.wait([
        dio.get<Map<String, dynamic>>('/progression/$userId'),
        dio.get<Map<String, dynamic>>(
          '/progression/$userId/ledger',
          queryParameters: const {'limit': 30},
        ),
      ]);
      final progressionBody =
          (responses.first.data as Map?)?.cast<String, dynamic>() ?? const {};
      final ledgerBody =
          (responses.last.data as Map?)?.cast<String, dynamic>() ?? const {};
      final progression =
          (progressionBody['progression'] as Map?)?.cast<String, dynamic>() ??
          const <String, dynamic>{};
      final entries = ((ledgerBody['entries'] as List?) ?? const <dynamic>[])
          .whereType<Map<dynamic, dynamic>>()
          .map((item) => XPEntry.fromJson(item.cast()))
          .toList(growable: false);
      final view = LevelProgressionView.fromJson(progression);
      state = state.copyWith(isLoading: false, view: view, ledger: entries);
      // Lets the reward burst host celebrate new XP, a level-up or the XP a
      // claimed reward brought, the moment this screen shows it.
      _ref.read(rewardSnapshotReportsProvider.notifier).state = RewardSnapshot(
        ledger: entries,
        level: view.currentLevel,
        levelName: view.levelName,
      );
    } on DioException catch (error, stackTrace) {
      log.error('Failed to load level progression', error, stackTrace);
      state = state.copyWith(
        isLoading: false,
        error: _apiError(error, _l.engagementLevelLoadFailed),
      );
    } on Object catch (error, stackTrace) {
      log.error('Failed to load level progression', error, stackTrace);
      state = state.copyWith(
        isLoading: false,
        error: _l.engagementLevelLoadFailed,
      );
    }
  }

  Future<bool> claimReward(String rewardKey) async {
    final userId = _currentUserId();
    if (userId == null || rewardKey.trim().isEmpty) {
      return false;
    }
    state = state.copyWith(claimingReward: rewardKey, clearError: true);
    if (kUseMockAuth) {
      state = state.copyWith(clearClaimingReward: true);
      return true;
    }
    try {
      await _ref
          .read(apiClientProvider)
          .post<Map<String, dynamic>>(
            '/progression/$userId/rewards/claim',
            data: <String, dynamic>{'reward_key': rewardKey},
          );
      state = state.copyWith(clearClaimingReward: true);
      await load();
      return true;
    } on DioException catch (error, stackTrace) {
      log.error('Failed to claim level reward', error, stackTrace);
      state = state.copyWith(
        clearClaimingReward: true,
        error: _apiError(error, _l.engagementLevelClaimFailed),
      );
      return false;
    }
  }

  String? _currentUserId() {
    final value = _ref.read(authNotifierProvider).userId?.trim() ?? '';
    return value.isEmpty ? null : value;
  }
}

String _apiError(DioException error, String fallback) =>
    serverErrorMessage(error, fallback: fallback);

const _mockView = LevelProgressionView(
  totalXp: 320,
  currentLevel: 3,
  levelName: 'Reliable Participant',
  currentLevelXp: 70,
  nextLevelXp: 500,
  progressPercent: 28,
  trustGateSatisfied: true,
  frozen: false,
  projectionLagSeconds: 0,
  levels: <LevelDefinition>[
    LevelDefinition(
      level: 1,
      name: 'Onboarded',
      thresholdXp: 0,
      trustGate: false,
      rewardSummary: 'Base progression profile',
    ),
    LevelDefinition(
      level: 2,
      name: 'Active Starter',
      thresholdXp: 100,
      trustGate: false,
      rewardSummary: 'Starter profile accent',
    ),
    LevelDefinition(
      level: 3,
      name: 'Reliable Participant',
      thresholdXp: 250,
      trustGate: false,
      rewardSummary: 'Weekly visibility micro-boost',
    ),
    LevelDefinition(
      level: 4,
      name: 'Conversation Builder',
      thresholdXp: 500,
      trustGate: false,
      rewardSummary: 'Advanced icebreaker suggestions',
    ),
    LevelDefinition(
      level: 5,
      name: 'Trust Builder',
      thresholdXp: 900,
      trustGate: true,
      rewardSummary: 'Compatible-prompt priority',
    ),
  ],
  rewards: <LevelReward>[
    LevelReward(
      key: 'starter_accent',
      level: 2,
      name: 'Starter accent',
      description: 'A profile accent earned through activity.',
      type: 'cosmetic',
      trustRequired: false,
      claimed: false,
    ),
  ],
);

final levelProgressionProvider =
    StateNotifierProvider<LevelProgressionNotifier, LevelProgressionState>((
      ref,
    ) {
      // Per member: rebuilt when someone else signs in on this device.
      watchSignedInUserId(ref);
      return LevelProgressionNotifier(ref);
    });
