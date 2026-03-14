import 'dart:async';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/config/app_runtime_config.dart';
import 'core/config/feature_flags.dart';
import 'core/theme/app_theme.dart';
import 'core/utils/logger.dart';
import 'features/auth/providers/auth_provider.dart';
import 'features/auth/providers/terms_provider.dart';
import 'features/auth/screens/user_agreement_screen.dart';
import 'features/auth/screens/welcome_screen.dart';
import 'features/common/screens/main_navigation_screen.dart';
import 'features/profile/providers/profile_completion_provider.dart';
import 'features/profile/screens/setup/profile_setup_entry_screen.dart';

Future<void> _bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();

  if ((kUseMockAuth || kUseMockDiscoveryData) && kReleaseMode) {
    throw StateError(
      'USE_MOCK_AUTH/USE_MOCK_DISCOVERY_DATA are not allowed in release builds.',
    );
  }

  var envLoaded = true;
  try {
    await dotenv.load(fileName: '.env.local');
  } catch (_) {
    try {
      await dotenv.load(fileName: '.env');
    } catch (_) {
      envLoaded = false;
    }
  }

  if (!kUseMockAuth) {
    final supabaseUrl = AppRuntimeConfig.supabaseUrl;
    final supabaseAnonKey = AppRuntimeConfig.supabaseAnonKey;
    final hasSupabaseConfig =
        supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;
    if (hasSupabaseConfig) {
      await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);
    } else if (envLoaded) {
      log.warning(
        'SUPABASE_URL/SUPABASE_ANON_KEY not set. Running backend-only mode.',
      );
    }
  }
}

Future<void> main() async {
  FlutterError.onError = (details) {
    log.critical(
      'flutter_framework_exception',
      details.exception,
      details.stack,
      <String, dynamic>{
        'library': details.library,
        'context': details.context?.toDescription(),
      },
    );
    FlutterError.presentError(details);
  };

  PlatformDispatcher.instance.onError = (error, stackTrace) {
    log.critical('platform_dispatcher_exception', error, stackTrace);
    return true;
  };

  await runZonedGuarded(
    () async {
      await _bootstrap();
      runApp(const ProviderScope(child: DatingApp()));
    },
    (error, stackTrace) {
      log.critical('uncaught_zone_exception', error, stackTrace);
    },
  );
}

class DatingApp extends ConsumerWidget {
  const DatingApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => MaterialApp(
    title: AppRuntimeConfig.appName,
    debugShowCheckedModeBanner: false,
    theme: AppTheme.lightTheme,
    darkTheme: AppTheme.darkTheme,
    themeMode: AppRuntimeConfig.themeMode,
    home: const _AppGate(),
  );
}

class _AppGate extends ConsumerWidget {
  const _AppGate();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authNotifierProvider);
    if (!authState.isAuthenticated) {
      return const WelcomeScreen();
    }

    final termsAccepted = ref.watch(termsAcceptanceProvider);
    return termsAccepted.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (_, _) => Scaffold(
        body: Center(
          child: TextButton(
            onPressed: () => ref.invalidate(termsAcceptanceProvider),
            child: const Text('Retry'),
          ),
        ),
      ),
      data: (accepted) {
        if (!accepted) {
          return const UserAgreementScreen();
        }

        final completion = ref.watch(profileCompletionProvider);
        return completion.when(
          loading: () =>
              const Scaffold(body: Center(child: CircularProgressIndicator())),
          error: (error, _) => _SupabaseConnectionIssue(
            message: error.toString(),
            onRetry: () => ref.invalidate(profileCompletionProvider),
          ),
          data: (c) {
            if (!c.isComplete) {
              return const ProfileSetupEntryScreen();
            }
            return const MainNavigationScreen();
          },
        );
      },
    );
  }
}

class _SupabaseConnectionIssue extends StatelessWidget {
  const _SupabaseConnectionIssue({
    required this.message,
    required this.onRetry,
  });
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off, size: 40),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            ElevatedButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    ),
  );
}
