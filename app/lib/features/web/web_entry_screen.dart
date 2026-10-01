import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/platform/browser_context.dart';
import '../auth/screens/auth_screen.dart';
import '../auth/screens/signup_screen.dart';
import '../auth/screens/welcome_screen.dart';

class WebEntryScreen extends StatefulWidget {
  const WebEntryScreen({super.key});
  @override
  State<WebEntryScreen> createState() => _WebEntryScreenState();
}

class _WebEntryScreenState extends State<WebEntryScreen> {
  late StreamSubscription<void> _routes;
  @override
  void initState() {
    super.initState();
    _routes = webRouteChanges.listen((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _routes.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final path = currentWebRoute();
    if (path == '/introducer/signup')
      return const SignupScreen(introducer: true);
    if (path == '/signup') return const SignupScreen();
    if (path == '/' || path == '/welcome') return const WelcomeScreen();
    return const AuthScreen();
  }
}
