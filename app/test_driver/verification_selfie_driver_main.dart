import 'package:flutter/material.dart';
import 'package:flutter_driver/driver_extension.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import 'package:verified_dating_app/core/theme/app_theme.dart';
import 'package:verified_dating_app/features/verification/screens/verification_selfie_screen.dart';

void main() {
  enableFlutterDriverExtension();
  runApp(
    ProviderScope(
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: VerificationSelfieScreen(idPhoto: XFile('dummy-id.jpg')),
      ),
    ),
  );
}
