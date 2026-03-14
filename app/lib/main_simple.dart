import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  runApp(const ProviderScope(child: DatingApp()));
}

class DatingApp extends StatelessWidget {
  const DatingApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    home: Scaffold(
      appBar: AppBar(title: const Text('Dating App')),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('🎉 App is Running!'),
            SizedBox(height: 20),
            Text('Basic layout test passed'),
          ],
        ),
      ),
    ),
  );
}
