import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verified_dating_app/core/config/app_runtime_config.dart';

void main() {
  group('AppRuntimeConfig', () {
    test('uses safe defaults when env is empty', () {
      dotenv.testLoad(fileInput: '');

      expect(AppRuntimeConfig.appName, 'Connect');
      expect(AppRuntimeConfig.apiBaseUrl, 'http://10.0.2.2:8080/v1');
      expect(AppRuntimeConfig.apiTimeoutMs, 30000);
      expect(AppRuntimeConfig.themeMode, ThemeMode.light);
      expect(AppRuntimeConfig.supabaseUsersSchema, 'user_management');
      expect(AppRuntimeConfig.supabaseUsersTable, 'users');
    });

    test('parses dark and system theme modes from env', () {
      dotenv.testLoad(fileInput: 'APP_THEME_MODE=dark');
      expect(AppRuntimeConfig.themeMode, ThemeMode.dark);

      dotenv.testLoad(fileInput: 'APP_THEME_MODE=system');
      expect(AppRuntimeConfig.themeMode, ThemeMode.system);
    });

    test('falls back to default timeout on invalid values', () {
      dotenv.testLoad(fileInput: 'API_TIMEOUT_MS=-1');
      expect(AppRuntimeConfig.apiTimeoutMs, 30000);

      dotenv.testLoad(fileInput: 'API_TIMEOUT_MS=abc');
      expect(AppRuntimeConfig.apiTimeoutMs, 30000);
    });

    test('parses configurable supabase users table fq name', () {
      dotenv.testLoad(fileInput: 'SUPABASE_USERS_TABLE=public.users');
      expect(AppRuntimeConfig.supabaseUsersSchema, 'public');
      expect(AppRuntimeConfig.supabaseUsersTable, 'users');
    });

    test('generates deterministic mock user id from phone digits', () {
      dotenv.testLoad(fileInput: 'MOCK_USER_PREFIX=test-user');

      final userID = AppRuntimeConfig.mockUserIdForPhone('+91 98765-43210');
      expect(userID, 'test-user-543210');
    });
  });
}
