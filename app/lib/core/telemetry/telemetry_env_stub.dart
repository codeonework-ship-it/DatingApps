/// Web and other targets without `dart:io`: never a `flutter test` run.
bool get isRunningUnderFlutterTest => false;

/// The browser does not expose a reliable OS version without user-agent
/// sniffing, which is not worth the fingerprinting surface.
String get operatingSystemVersion => '';
