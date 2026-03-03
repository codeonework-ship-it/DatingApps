# Verified Dating App - Developer Guide

## 🎯 Project Overview

**Verified Dating App** is a trust-first dating platform built with Flutter, designed for serious relationships with enterprise-grade coding standards.

### Key Features
- ✅ Multi-layer identity verification (eKYC)
- ✅ Women-first safety infrastructure
- ✅ Video calling with liveness detection
- ✅ Real-time messaging
- ✅ Behavior pattern detection
- ✅ SOS emergency feature

---

## 🏗️ Architecture

This project follows **Clean Architecture** with strict separation of concerns:

- **Presentation Layer**: UI, pages, widgets, state management
- **Domain Layer**: Business logic, use cases, entities
- **Data Layer**: Repositories, models, data sources (API, local DB)

See [ARCHITECTURE.md](../ARCHITECTURE.md) for detailed documentation.

---

## 📋 Coding Standards

### 1. **Linting & Analysis**

All code must pass strict linting rules (enforced by `analysis_options.yaml`).

```bash
# Analyze code
flutter analyze

# Format code
dart format --line-length=80 lib/

# Run with strict rules
dart analyze --fatal-hints --fatal-warnings
```

**Non-negotiable Rules:**
- ✅ Always declare return types: `String getValue()` not `getValue()`
- ✅ Use const constructors wherever possible
- ✅ No print() statements - use `AppLogger.log.info()`
- ✅ Proper null safety - no unnecessary nullable types
- ✅ Avoid shadowing variables

### 2. **Naming Conventions**

| Type | Convention | Example |
|------|-----------|---------|
| Files | snake_case | `user_repository.dart` |
| Classes | PascalCase | `UserRepository` |
| Methods/Variables | camelCase | `getUserProfile()`, `isVerified` |
| Constants | camelCase | `maxRetries = 3` |
| Enums | PascalCase | `enum UserStatus { active, inactive }` |
| Private | Leading _ | `_privateMethod()`, `_count` |

### 3. **Documentation**

Every public API must have dartdoc comments:

```dart
/// Fetches user profile by ID.
///
/// Returns the user profile if found, otherwise throws [UserNotFoundException].
///
/// Parameters:
///   - [userId]: The unique identifier of the user
///
/// Example:
///   ```dart
///   final user = await repository.getUserProfile('user123');
///   ```
Future<UserEntity> getUserProfile(String userId) async { ... }
```

### 4. **Error Handling**

```dart
// ❌ Bad
try {
  return await api.fetchUser();
} catch (e) {
  print(e);
  return null;
}

// ✅ Good
try {
  return await api.fetchUser();
} catch (e, stackTrace) {
  log.error('Failed to fetch user', e, stackTrace);
  throw UserException(message: 'Failed to load user profile');
}
```

### 5. **Immutability**

Always use immutable data classes:

```dart
// ✅ Good - Using Freezed
@freezed
class User with _$User {
  const factory User({
    required String id,
    required String name,
    required String email,
  }) = _User;

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
}
```

### 6. **Testing**

- Write tests for all use cases and repositories
- Test coverage should be > 80%
- Mock all external dependencies

```bash
# Run tests
flutter test

# Run tests with coverage
flutter test --coverage

# Generate coverage report
lcov --remove coverage/lcov.info '**/generated/*' -o coverage/lcov.info
```

---

## 🚀 Setup & Getting Started

### Prerequisites
- Flutter 3.11.0 or higher
- Dart 3.11.0 or higher
- iOS: Xcode 14+ (for testing on Mac)
- Android: Android Studio 2022.1+ or Android SDK Command-line tools

### Installation

1. **Get dependencies**
   ```bash
   cd app
   flutter pub get
   ```

2. **Generate code (models, routes)**
   ```bash
   flutter pub run build_runner build
   ```

3. **Run the app**
   ```bash
   # Android emulator
   flutter run -d emulator-5554

   # Web
   flutter run -d chrome

   # macOS
   flutter run -d macos
   ```

---

## 📦 Core Dependencies

### State Management
- **Riverpod**: Async state management

### Networking
- **Supabase PostgREST/Realtime APIs**: Primary data + realtime access
- **Dio**: Optional HTTP client for custom backend/edge APIs

### Database
- **Supabase PostgreSQL**: Primary remote database
- **Hive**: Local database
- **SQLite**: Structured data

### Authentication
- **Supabase Auth**: Phone OTP authentication

### UI
- **Flutter SVG**: Vector graphics
- **Cached Network Image**: Image caching

### Code Generation
- **Freezed**: Immutable models
- **JSON Serializable**: JSON parsing

### Logging
- **Logger**: Structured logging

---

## 🏃 Development Workflow

### 1. Create a New Feature

```bash
# Create feature structure
mkdir -p lib/features/my_feature/{data,domain,presentation}

# Domain: Define business rules
lib/features/my_feature/domain/
├── entities/my_entity.dart
├── repositories/my_repository.dart
└── usecases/my_usecase.dart

# Data: Implement the contract
lib/features/my_feature/data/
├── datasources/my_datasource.dart
├── models/my_model.dart
└── repositories/my_repository_impl.dart

# Presentation: UI
lib/features/my_feature/presentation/
├── pages/my_page.dart
├── widgets/my_widget.dart
└── providers/my_provider.dart
```

### 2. Before Committing

```bash
# 1. Format code
dart format --line-length=80 lib/

# 2. Run analyzer
flutter analyze

# 3. Run tests
flutter test

# 4. Check for unused imports
dart run dart_code_metrics:metrics check-unused-files lib/

# 5. Check code coverage
flutter test --coverage
```

### 3. Git Workflow

```bash
# Create feature branch
git checkout -b feature/auth-login

# Make changes, ensure all checks pass
flutter analyze
flutter test
dart format --line-length=80 lib/

# Commit with clear message
git commit -m "feat(auth): implement login with OTP verification"

# Push and create PR
git push -u origin feature/auth-login
```

---

## 🐛 Debugging

### Enable Debug Logging
```dart
// In main.dart
import 'core/utils/logger.dart';

void main() {
  log.debug('Debug message');
  log.info('Info message');
  log.warning('Warning message');
  log.error('Error message', exception);
}
```

### Use Flutter DevTools
```bash
flutter pub global activate devtools
flutter pub global run devtools

# Then run app
flutter run
```

### Inspect Widget Tree
```bash
# In app
Ctrl+P (or Cmd+P on Mac) → search "widget tree"
```

---

## 📱 Building for Production

### Android
```bash
# Build APK
flutter build apk --release

# Build Bundle (for Play Store)
flutter build appbundle --release
```

### iOS
```bash
# Build IPA
flutter build ios --release
```

### Web
```bash
# Build web
flutter build web --release
```

---

## 🔐 Security Checklist

- [ ] No hardcoded API keys or secrets (use environment variables)
- [ ] All network calls use HTTPS
- [ ] Sensitive data stored in secure storage
- [ ] Input validation on all user inputs
- [ ] API rate limiting implemented
- [ ] No sensitive logs in production
- [ ] Regular dependency updates for security patches

---

## 📊 Performance Guidelines

- **Target FPS**: 60 FPS (59+ acceptable)
- **Initial load**: < 2 seconds
- **List scroll**: Smooth, no dropped frames
- **Memory**: Monitor with DevTools
- **Build size**: Keep app size < 50MB

Use Flutter DevTools to profile:
```bash
flutter run --profile
```

---

## 🤝 Contributing

1. Follow the [Coding Standards](#-coding-standards)
2. Write tests for new code
3. Ensure `flutter analyze` passes with 0 issues
4. Document your code with dartdoc
5. Create clear commit messages
6. Submit PR with description

---

## 📚 Learning Resources

- [Flutter Documentation](https://flutter.dev/docs)
- [Dart Language Tour](https://dart.dev/guides/language/language-tour)
- [Clean Architecture](https://resocoder.com/flutter-clean-architecture)
- [Effective Dart](https://dart.dev/guides/language/effective-dart)
- [Riverpod Documentation](https://riverpod.dev)

---

## ❓ FAQ

**Q: How should Flutter talk to the database?**
A: Use Supabase APIs (Auth, PostgREST, Realtime, Storage) and keep DB interaction inside providers/repositories.

**Q: How do I handle errors properly?**
A: Create custom exceptions in domain layer, return Failure objects, or use Either type from dartz package.

**Q: Can I use print() for debugging?**
A: No, use `log.debug()`, `log.info()`, `log.error()` instead. Print is removed in release builds.

**Q: How do I add a new dependency?**
A: Update `pubspec.yaml`, run `flutter pub get`, then implement with proper patterns.

---

## 📞 Support

For questions or issues:
1. Check [ARCHITECTURE.md](../ARCHITECTURE.md)
2. Review existing code examples
3. Check Flutter/Dart documentation
4. Ask in team chat/PR discussions

---

**Last Updated**: February 2026  
**Version**: 1.0.0
