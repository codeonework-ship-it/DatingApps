/// Application Routing Configuration
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/screens/auth_screen.dart';
import '../features/common/screens/main_navigation_screen.dart';
import '../features/matching/screens/matches_list_screen.dart';
import '../features/messaging/screens/chat_screen.dart';
import '../features/profile/screens/profile_view_screen.dart';
import '../features/swipe/screens/home_discovery_screen.dart';

/// Route paths
class RoutePaths {
  static const String splash = '/splash';
  static const String login = '/login';
  static const String register = '/register';
  static const String onboarding = '/onboarding';
  static const String home = '/home';
  static const String swipe = '/swipe';
  static const String matches = '/matches';
  static const String profile = '/profile';
  static const String verification = '/verification';
  static const String messaging = '/messaging';
  static const String chat = '/chat';
  static const String notFound = '/notfound';
}

/// Router configuration
GoRouter createRouter() => GoRouter(
  initialLocation: RoutePaths.login,
  errorBuilder: (context, state) => const Scaffold(body: Center(child: Text('Route not found'))),
  routes: [
    GoRoute(
      path: RoutePaths.login,
      name: 'login',
      builder: (context, state) => const AuthScreen(),
    ),
    GoRoute(
      path: RoutePaths.home,
      name: 'home',
      builder: (context, state) => const MainNavigationScreen(),
    ),
    GoRoute(
      path: RoutePaths.swipe,
      name: 'swipe',
      builder: (context, state) => const HomeDiscoveryScreen(),
    ),
    GoRoute(
      path: RoutePaths.matches,
      name: 'matches',
      builder: (context, state) => const MatchesListScreen(),
    ),
    GoRoute(
      path: RoutePaths.profile,
      name: 'profile',
      builder: (context, state) => const ProfileViewScreen(),
    ),
    GoRoute(
      path: RoutePaths.chat,
      name: 'chat',
      builder: (context, state) {
        final extra = state.extra;
        if (extra is Map<String, dynamic>) {
          final matchId = extra['matchId']?.toString();
          final otherUserId = extra['otherUserId']?.toString();
          final userName = extra['userName']?.toString();
          final userPhotoUrl = extra['userPhotoUrl']?.toString();
          if (matchId != null &&
              otherUserId != null &&
              userName != null &&
              userPhotoUrl != null) {
            return ChatScreen(
              matchId: matchId,
              otherUserId: otherUserId,
              userName: userName,
              userPhotoUrl: userPhotoUrl,
            );
          }
        }

        return const Scaffold(
          body: Center(child: Text('Missing chat parameters')),
        );
      },
    ),
    GoRoute(
      path: RoutePaths.notFound,
      name: 'notFound',
      builder: (context, state) =>
          const Scaffold(body: Center(child: Text('Route not found'))),
    ),
  ],
);
