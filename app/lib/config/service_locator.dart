/// Service locator setup using get_it
/// This file configures all dependencies for the application
library;

import 'package:get_it/get_it.dart';

final getIt = GetIt.instance;

/// Setup all dependencies
Future<void> setupServiceLocator() async {
  // TODO: Register repositories

  // TODO: Register use cases

  // TODO: Register providers/notifiers

  // TODO: Register external services (Supabase APIs, Dio, etc.)

  // Example:
  // getIt.registerSingleton<AuthRepository>(AuthRepositoryImpl());
  // getIt.registerSingleton<LoginUseCase>(LoginUseCase(getIt<AuthRepository>()));
}

/// Clear all dependencies (useful for testing)
Future<void> clearServiceLocator() async {
  await getIt.reset();
}
