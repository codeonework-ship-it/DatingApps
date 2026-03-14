import 'package:flutter_driver/driver_extension.dart';

import 'package:verified_dating_app/main.dart' as app;

Future<void> main() async {
  enableFlutterDriverExtension();
  await app.main();
}
