import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_runtime_config.dart';
import '../../../core/providers/api_client_provider.dart';
import '../../../core/theme/theme_presets.dart';
import '../../../core/utils/logger.dart';
import '../../auth/providers/auth_provider.dart';

/// The member's chosen theme, stored server-side.
///
/// `MaterialApp.themeMode` previously read `AppRuntimeConfig.themeMode`, which
/// resolves a `--dart-define` at compile time. That makes the theme a property
/// of the build rather than of the member: nothing in the app could change it,
/// and it could not follow an account onto a second device.
///
/// `settings.theme` already existed on the server and round-trips
/// 'light' | 'dark' | 'auto', so this reads and writes that column rather than
/// introducing a parallel local-only preference that would immediately
/// disagree with it.
enum AppThemeChoice {
  light,
  dark,
  auto;

  static AppThemeChoice fromWire(Object? raw) {
    switch (raw?.toString().trim().toLowerCase()) {
      case 'dark':
        return AppThemeChoice.dark;
      case 'light':
        return AppThemeChoice.light;
      case 'auto':
      case 'system':
        return AppThemeChoice.auto;
      default:
        return _fromRuntimeDefault();
    }
  }

  static AppThemeChoice _fromRuntimeDefault() {
    switch (AppRuntimeConfig.themeMode) {
      case ThemeMode.dark:
        return AppThemeChoice.dark;
      case ThemeMode.system:
        return AppThemeChoice.auto;
      case ThemeMode.light:
        return AppThemeChoice.light;
    }
  }

  String get wireValue => switch (this) {
    AppThemeChoice.light => 'light',
    AppThemeChoice.dark => 'dark',
    AppThemeChoice.auto => 'auto',
  };

  ThemeMode get themeMode => switch (this) {
    AppThemeChoice.light => ThemeMode.light,
    AppThemeChoice.dark => ThemeMode.dark,
    AppThemeChoice.auto => ThemeMode.system,
  };

  String get label => switch (this) {
    AppThemeChoice.light => 'Light',
    AppThemeChoice.dark => 'Dark',
    AppThemeChoice.auto => 'Match device',
  };

  IconData get icon => switch (this) {
    AppThemeChoice.light => Icons.light_mode_rounded,
    AppThemeChoice.dark => Icons.dark_mode_rounded,
    AppThemeChoice.auto => Icons.brightness_auto_rounded,
  };
}

/// Preset ids that shipped before the looks were renamed for sale as theme
/// packs. A member who saved one keeps the same look under its new name, and
/// the next write persists the new id, so the old ones age out on their own.
const Map<String, String> _legacyPresetIds = {
  'transformers': 'forge',
  'tron': 'neongrid',
  'ironman': 'crimsonalloy',
  'digitronics': 'circuit',
  'starwars': 'deepfield',
};

/// What the member chose: a Light / Dark / Match-device mode for the classic
/// pair, and optionally a themed preset that fixes the look regardless of
/// mode. Stored in `settings.theme` as `mode` or `mode:preset`.
class AppThemeSelection {
  const AppThemeSelection({
    required this.mode,
    this.presetId = ThemePresets.classicId,
  });

  factory AppThemeSelection.fromWire(Object? raw) {
    final value = raw?.toString().trim().toLowerCase() ?? '';
    final parts = value.split(':');
    final mode = AppThemeChoice.fromWire(parts.first);
    final stored = parts.length > 1 ? parts[1] : ThemePresets.classicId;
    final presetId = _legacyPresetIds[stored] ?? stored;
    return AppThemeSelection(
      mode: mode,
      presetId: ThemePresets.byId(presetId) != null
          ? presetId
          : ThemePresets.classicId,
    );
  }

  final AppThemeChoice mode;
  final String presetId;

  bool get isClassic => presetId == ThemePresets.classicId;

  ThemePreset? get preset => isClassic ? null : ThemePresets.byId(presetId);

  String get wireValue =>
      isClassic ? mode.wireValue : '${mode.wireValue}:$presetId';

  /// Brightness the app runs in: the mode for the classic pair, the
  /// preset's own brightness otherwise.
  ThemeMode get themeMode => isClassic
      ? mode.themeMode
      : (preset!.isDark ? ThemeMode.dark : ThemeMode.light);

  ThemeData get lightTheme {
    final chosen = preset;
    return ThemePresets.themeFor(
      chosen != null && !chosen.isDark ? chosen : ThemePresets.realLife,
    );
  }

  ThemeData get darkTheme {
    final chosen = preset;
    return ThemePresets.themeFor(
      chosen != null && chosen.isDark ? chosen : ThemePresets.realLifeNight,
    );
  }

  AppThemeSelection copyWith({AppThemeChoice? mode, String? presetId}) =>
      AppThemeSelection(
        mode: mode ?? this.mode,
        presetId: presetId ?? this.presetId,
      );

  @override
  bool operator ==(Object other) =>
      other is AppThemeSelection &&
      other.mode == mode &&
      other.presetId == presetId;

  @override
  int get hashCode => Object.hash(mode, presetId);
}

class AppThemeNotifier extends StateNotifier<AppThemeSelection> {
  AppThemeNotifier(this._ref)
    : super(AppThemeSelection(mode: AppThemeChoice._fromRuntimeDefault()));

  final Ref _ref;
  final _log = AppLogger();

  String? get _userId {
    final id = _ref.read(authNotifierProvider).userId?.trim();
    return (id == null || id.isEmpty) ? null : id;
  }

  Future<void> _load() async {
    final userId = _userId;
    if (userId == null) {
      return;
    }
    try {
      final response = await _ref
          .read(apiClientProvider)
          .get<Map<String, dynamic>>('/settings/$userId');
      final settings = response.data?['settings'];
      if (settings is Map) {
        state = AppThemeSelection.fromWire(settings['theme']);
      }
    } on Object catch (e, stackTrace) {
      // A theme is never worth blocking startup for; keep the build default.
      _log.error('Failed to load theme preference', e, stackTrace);
    }
  }

  /// Pull the account's stored theme, once, after a session exists.
  ///
  /// Deliberately not called from the constructor. Reading a provider must not
  /// start network work as a side effect of being watched: `MaterialApp`
  /// watches this on the very first frame, so a constructor fetch fired before
  /// there was a session to fetch for and left an in-flight request hanging in
  /// widget tests. The gate calls this once it knows the member is signed in.
  Future<void> ensureLoaded() async {
    if (_loaded) {
      return;
    }
    _loaded = true;
    await _load();
  }

  bool _loaded = false;

  /// Light / Dark / Match device for the classic pair. Choosing a mode also
  /// returns to the classic look.
  Future<void> select(AppThemeChoice choice) =>
      _apply(AppThemeSelection(mode: choice));

  /// A themed preset, or [ThemePresets.classicId] to go back to the pair.
  Future<void> selectPreset(String presetId) =>
      _apply(state.copyWith(presetId: presetId));

  Future<void> _apply(AppThemeSelection choice) async {
    if (choice == state) {
      return;
    }
    final previous = state;
    // Repaint immediately: waiting on the network to recolour the whole app
    // makes the control feel broken.
    state = choice;

    final userId = _userId;
    if (userId == null) {
      return;
    }
    try {
      await _ref
          .read(apiClientProvider)
          .patch<Map<String, dynamic>>(
            '/settings/$userId',
            data: {'theme': choice.wireValue},
          );
    } on DioException catch (e, stackTrace) {
      _log.error('Failed to persist theme preference', e, stackTrace);
      // Roll back rather than leave the UI showing a theme the account does
      // not actually have — it would silently revert on the next launch.
      state = previous;
      rethrow;
    }
  }
}

final appThemeProvider =
    StateNotifierProvider<AppThemeNotifier, AppThemeSelection>(
      AppThemeNotifier.new,
    );

/// Whether this is the browser build. A provider so tests can exercise the
/// web theme lock without a browser.
final isWebBuildProvider = Provider<bool>((_) => kIsWeb);

/// Product decision (2026-09-27, reconfirmed the same day): the signed-in
/// browser app uses the default brand in light mode. The default brand now
/// uses the Real life palette. Member presets remain a mobile choice. The lock
/// lives here, not only in `main.dart`, so every MaterialApp picks it up.
final webThemeLockedProvider = Provider<bool>(
  (ref) => ref.watch(isWebBuildProvider),
);

final _webBrandTheme = ThemePresets.themeFor(ThemePresets.realLife);

final appThemeModeProvider = Provider<ThemeMode>(
  (ref) => ref.watch(webThemeLockedProvider)
      ? ThemeMode.light
      : ref.watch(appThemeProvider).themeMode,
);

final appLightThemeProvider = Provider<ThemeData>(
  (ref) => ref.watch(webThemeLockedProvider)
      ? _webBrandTheme
      : ref.watch(appThemeProvider).lightTheme,
);

final appDarkThemeProvider = Provider<ThemeData>(
  (ref) => ref.watch(webThemeLockedProvider)
      ? _webBrandTheme
      : ref.watch(appThemeProvider).darkTheme,
);
