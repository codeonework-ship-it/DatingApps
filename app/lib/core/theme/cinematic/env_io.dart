import 'dart:io' show Platform;

/// True inside `flutter test`, which sets `FLUTTER_TEST` for the test
/// process. Ambient motion stays off there so `pumpAndSettle` can settle.
bool get isRunningUnderFlutterTest =>
    Platform.environment.containsKey('FLUTTER_TEST');
