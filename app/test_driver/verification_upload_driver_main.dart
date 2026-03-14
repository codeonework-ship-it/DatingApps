import 'package:flutter/material.dart';
import 'package:flutter_driver/driver_extension.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:verified_dating_app/core/theme/app_theme.dart';
import 'package:verified_dating_app/features/verification/screens/verification_upload_id_screen.dart';

void main() {
  enableFlutterDriverExtension();
  runApp(
    ProviderScope(
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: const VerificationUploadIdScreen(),
      ),
    ),
  );
}
