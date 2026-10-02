import 'package:dio/dio.dart';
import 'package:flutter/semantics.dart';
import 'core/auth/auth_session_store.dart';
import 'core/platform/browser_context.dart';
import 'features/web/web_entry_screen.dart';
import 'features/friends/screens/introducer_screen.dart';
import 'features/web/web_member_workspace.dart';
import 'dart:async';
import 'dart:ui';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/config/app_runtime_config.dart';
import 'core/config/feature_flags.dart';
import 'core/i18n/app_l10n.dart';
import 'core/i18n/app_locale_provider.dart';
import 'core/network/api_error_message.dart';
import 'core/notifications/push_notification_service.dart';
import 'core/telemetry/client_error_navigator_observer.dart';
import 'core/telemetry/client_error_reporter.dart';
import 'features/common/providers/app_theme_provider.dart';
import 'core/utils/logger.dart';
import 'features/auth/providers/auth_provider.dart';
import 'features/auth/providers/session_end_listener.dart';
import 'features/auth/providers/terms_provider.dart';
import 'features/auth/screens/user_agreement_screen.dart';
import 'features/auth/screens/welcome_screen.dart';
import 'features/common/screens/main_navigation_screen.dart';
import 'features/profile/providers/profile_completion_provider.dart';
import 'features/profile/screens/setup/profile_setup_entry_screen.dart';
import 'l10n/app_localizations.dart';

Future<void> _bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();

  if ((kUseMockAuth || kUseMockDiscoveryData) && kReleaseMode) {
    throw StateError(
      'USE_MOCK_AUTH/USE_MOCK_DISCOVERY_DATA are not allowed in release builds.',
    );
  }

  if (kIsWeb) return;
  try {
    await dotenv.load(fileName: '.env.local');
  } on Object catch (_) {
    try {
      await dotenv.load(fileName: '.env');
    } on Object catch (_) {}
  }
}

Future<void> _restorePersistedSession() async {
  final saved = kIsWeb
      ? readBrowserSession()
      : await AuthSessionStore.instance.readNative();
  final refresh = saved?['refresh_token']?.toString();
  if (refresh == null || refresh.isEmpty) {
    return;
  }
  try {
    final dio = Dio(
      BaseOptions(
        baseUrl: AppRuntimeConfig.apiBaseUrl,
        connectTimeout: const Duration(seconds: 8),
        receiveTimeout: const Duration(seconds: 8),
      ),
    );
    final response = await dio.post<dynamic>(
      '/auth/refresh',
      data: {'refresh_token': refresh},
    );
    final data = (response.data as Map).cast<String, dynamic>();
    if (data['success'] != true ||
        data['user_id'] == null ||
        data['access_token'] == null ||
        data['refresh_token'] == null) {
      AuthSessionStore.instance.clear();
      return;
    }
    final store = AuthSessionStore.instance;
    store.update(
      accessToken: data['access_token'].toString(),
      refreshToken: data['refresh_token'].toString(),
    );
    store.identify(
      userId: data['user_id'].toString(),
      username: saved?['username']?.toString() ?? '',
      isNewAccount: data['signup_required'] != false,
      accountKind: data['account_kind']?.toString() ?? 'dating',
    );
    store.restored = true;
    await store.persistNative();
  } on DioException catch (error) {
    if (error.response?.statusCode == 400 ||
        error.response?.statusCode == 401) {
      AuthSessionStore.instance.clear();
    }
  } on Object {
    AuthSessionStore.instance.clear();
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
  // Self-hosted crash reporting wraps both handlers above (they still run).
  ClientErrorReporter.instance.installErrorHooks();

  await runZonedGuarded(
    () async {
      await _bootstrap();
      if (kIsWeb) {
        // Keep browser keyboard/screen-reader semantics available from launch.
        SemanticsBinding.instance.ensureSemantics();
      }
      await _restorePersistedSession();
      // Loads the crash-report opt-in and sends reports left by a last crash.
      unawaited(ClientErrorReporter.instance.start());
      // The member's language applies from the first frame, before sign-in.
      final cachedLocale = await readCachedAppLocale();
      if (!kIsWeb &&
          (defaultTargetPlatform == TargetPlatform.android ||
              defaultTargetPlatform == TargetPlatform.iOS)) {
        FirebaseMessaging.onBackgroundMessage(
          pushNotificationBackgroundHandler,
        );
      }
      runApp(
        ProviderScope(
          overrides: [
            appLocaleProvider.overrideWith(
              (ref) => AppLocaleNotifier(ref, initial: cachedLocale),
            ),
          ],
          child: const DatingApp(),
        ),
      );
    },
    (error, stackTrace) {
      log.critical('uncaught_zone_exception', error, stackTrace);
      ClientErrorReporter.instance.recordError(
        error,
        stackTrace,
        source: ClientErrorSource.zone,
        fatal: true,
      );
    },
  );
}

class DatingApp extends ConsumerWidget {
  const DatingApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(appThemeModeProvider);
    // null follows the device; a chosen locale resolves against
    // AppLocalizations.supportedLocales (en-US lands on the `en` template).
    final locale = ref.watch(appLocaleProvider);
    setCurrentAppLocale(locale);
    if (kIsWeb) {
      return MaterialApp.router(
        title: 'Connect',
        debugShowCheckedModeBanner: false,
        theme: ref.watch(appLightThemeProvider),
        darkTheme: ref.watch(appDarkThemeProvider),
        themeMode: mode,
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routerDelegate: _webRouter,
        routeInformationParser: _WebRouteParser(),
      );
    }
    return MaterialApp(
      title: AppRuntimeConfig.appName,
      debugShowCheckedModeBanner: false,
      theme: ref.watch(appLightThemeProvider),
      darkTheme: ref.watch(appDarkThemeProvider),
      themeMode: mode,
      // Changing looks morphs the palette (colours lerp) instead of cutting.
      themeAnimationStyle: const AnimationStyle(
        duration: Duration(milliseconds: 450),
        curve: Curves.easeInOut,
      ),
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      navigatorObservers: [clientErrorNavigatorObserver],
      home: const _AppGate(),
    );
  }
}

final _webRouter = _WebRouterDelegate();

class _WebRouteParser extends RouteInformationParser<String> {
  @override
  Future<String> parseRouteInformation(RouteInformation info) async =>
      info.uri.path;
  @override
  RouteInformation restoreRouteInformation(String path) =>
      RouteInformation(uri: Uri.parse(path));
}

class _WebRouterDelegate extends RouterDelegate<String>
    with ChangeNotifier, PopNavigatorRouterDelegateMixin<String> {
  _WebRouterDelegate() {
    _subscription = webRouteChanges.listen((_) => notifyListeners());
  }
  late final StreamSubscription<void> _subscription;
  @override
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  @override
  String get currentConfiguration => currentWebRoute();
  @override
  Future<void> setNewRoutePath(String path) async {
    // Screens such as a chapter are pushed on top of the workspace without
    // their own URL. The browser's back button must close that screen first
    // (honouring unsaved-work guards) instead of switching the page hidden
    // underneath it, so the member stays where they were.
    final navigator = navigatorKey.currentState;
    if (navigator != null && navigator.canPop()) {
      await navigator.maybePop();
      notifyListeners();
      return;
    }
    setWebRoute(path);
  }

  @override
  Widget build(BuildContext context) => Navigator(
    key: navigatorKey,
    pages: const [
      MaterialPage<void>(
        key: ValueKey('connect-root'),
        canPop: false,
        child: _AppGate(),
      ),
    ],
    onDidRemovePage: (_) {},
  );
  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

class _AppGate extends ConsumerWidget {
  const _AppGate();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    listenForSessionEnd(ref, context);
    final authState = ref.watch(authNotifierProvider);
    if (!authState.isAuthenticated) {
      return kIsWeb ? const WebEntryScreen() : const WelcomeScreen();
    }

    // Now that a session exists, adopt the account's stored theme and
    // language. Scheduled off-frame because they can update provider state,
    // which must not happen during a build.
    Future<void>.microtask(() async {
      await ref.read(appThemeProvider.notifier).ensureLoaded();
      await ref.read(appLocaleProvider.notifier).ensureLoaded();
    });

    if (!authState.isNewAccount && !authState.isIntroducer) {
      return kIsWeb ? const WebMemberWorkspace() : const MainNavigationScreen();
    }

    final termsAccepted = ref.watch(termsAcceptanceProvider);
    return termsAccepted.when(
      loading: () => _GateLoadingScreen(
        message: AppLocalizations.of(context).gateCheckingTerms,
      ),
      error: (_, _) => Scaffold(
        body: Center(
          child: TextButton(
            onPressed: () => ref.invalidate(termsAcceptanceProvider),
            child: Text(AppLocalizations.of(context).commonRetry),
          ),
        ),
      ),
      data: (accepted) {
        if (!accepted) {
          return const UserAgreementScreen();
        }

        if (authState.isIntroducer) {
          if (kIsWeb && currentWebRoute() != '/introducer') {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (ref.read(authNotifierProvider).isIntroducer) {
                setWebRoute('/introducer');
              }
            });
          }
          return const IntroducerScreen();
        }
        final completion = ref.watch(profileCompletionProvider);
        return completion.when(
          loading: () => _GateLoadingScreen(
            message: AppLocalizations.of(context).gateLoadingProfile,
          ),
          error: (error, _) => _BackendConnectionIssue(
            // Never the raw exception: a localized reason (server text is
            // shown as sent, by policy).
            message: apiErrorMessage(
              error,
              fallback: AppLocalizations.of(
                context,
              ).commonSomethingWentWrongTryAgain,
            ),
            onRetry: () => ref.invalidate(profileCompletionProvider),
          ),
          data: (c) {
            if (!c.isComplete) {
              return const ProfileSetupEntryScreen();
            }
            return kIsWeb
                ? const WebMemberWorkspace()
                : const MainNavigationScreen();
          },
        );
      },
    );
  }
}

/// Branded loading screen used during gate transitions so the user never
/// sees a bare white scaffold between screens.
class _GateLoadingScreen extends StatelessWidget {
  const _GateLoadingScreen({this.message});
  final String? message;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 36,
              height: 36,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(colors.primary),
              ),
            ),
            if (message != null) ...[
              const SizedBox(height: 16),
              Text(
                message!,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _BackendConnectionIssue extends StatelessWidget {
  const _BackendConnectionIssue({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.wifi_off_rounded,
                size: 48,
                color: colors.onSurfaceVariant,
              ),
              const SizedBox(height: 16),
              Text(
                AppLocalizations.of(context).gateConnectionIssue,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: colors.onSurface,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant),
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: onRetry,
                child: Text(AppLocalizations.of(context).commonRetry),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
