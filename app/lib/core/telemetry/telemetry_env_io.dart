import 'dart:io' show Platform;

/// True inside `flutter test`, which sets `FLUTTER_TEST` for the test
/// process. Crash reporting never runs there unless a test opts in.
bool get isRunningUnderFlutterTest =>
    Platform.environment.containsKey('FLUTTER_TEST');

/// Operating system version string, e.g. `Version 17.4 (Build 21E213)`.
String get operatingSystemVersion => Platform.operatingSystemVersion;
