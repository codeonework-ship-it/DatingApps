import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/config/app_runtime_config.dart';
import '../../../core/config/feature_flags.dart';
import '../../../core/providers/api_client_provider.dart';
import '../../../core/utils/logger.dart';

part 'auth_provider.g.dart';

/// Auth State
class AuthState {
  const AuthState({
    this.phoneNumber,
    this.email,
    this.otp,
    this.isLoading = false,
    this.error,
    this.isOtpSent = false,
    this.isAuthenticated = false,
    this.userId,
  });
  final String? phoneNumber;
  final String? email;
  final String? otp;
  final bool isLoading;
  final String? error;
  final bool isOtpSent;
  final bool isAuthenticated;
  final String? userId;

  AuthState copyWith({
    String? phoneNumber,
    String? email,
    String? otp,
    bool? isLoading,
    String? error,
    bool? isOtpSent,
    bool? isAuthenticated,
    String? userId,
  }) => AuthState(
    phoneNumber: phoneNumber ?? this.phoneNumber,
    email: email ?? this.email,
    otp: otp ?? this.otp,
    isLoading: isLoading ?? this.isLoading,
    error: error ?? this.error,
    isOtpSent: isOtpSent ?? this.isOtpSent,
    isAuthenticated: isAuthenticated ?? this.isAuthenticated,
    userId: userId ?? this.userId,
  );
}

/// Auth Provider
@riverpod
class AuthNotifier extends _$AuthNotifier {
  @override
  AuthState build() => const AuthState();

  /// Send OTP to mobile number
  Future<void> sendOtp(String mobileNumber) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final normalized = _normalizePhoneNumber(mobileNumber);
      final transportEmail = _phoneToAuthEmail(normalized);
      if (normalized.isEmpty) {
        state = state.copyWith(
          error: 'Please enter your mobile number.',
          isLoading: false,
        );
        return;
      }

      if (!_isValidPhoneNumber(normalized)) {
        state = state.copyWith(
          error: 'Please enter a valid mobile number.',
          isLoading: false,
        );
        return;
      }

      if (kBypassOtpValidation) {
        await Future<void>.delayed(const Duration(milliseconds: 150));
      } else if (kUseMockAuth) {
        await Future<void>.delayed(const Duration(milliseconds: 300));
      } else {
        final dio = ref.read(apiClientProvider);
        try {
          await dio.post<dynamic>(
            '/auth/send-otp',
            data: {'email': transportEmail, 'phone': normalized},
          );
        } on DioException catch (e) {
          final message = _extractApiError(e, fallback: '').toLowerCase();
          final needsEmailOnlyRetry =
              message.contains('valid email is required') ||
              message.contains('email is required');
          if (!needsEmailOnlyRetry) {
            rethrow;
          }

          await dio.post<dynamic>(
            '/auth/send-otp',
            data: {'email': transportEmail},
          );
        }
      }

      state = state.copyWith(
        phoneNumber: normalized,
        email: transportEmail,
        isOtpSent: true,
        isLoading: false,
        error: null,
      );
    } on DioException catch (e, stackTrace) {
      log.error('Failed to send OTP', e, stackTrace);
      state = state.copyWith(
        error: _extractApiError(
          e,
          fallback: 'Failed to send OTP. Please try again.',
        ),
        isLoading: false,
      );
    } catch (e, stackTrace) {
      log.error('Failed to send OTP', e, stackTrace);
      state = state.copyWith(
        error: 'Failed to send OTP. Please try again.',
        isLoading: false,
      );
    }
  }

  /// Verify OTP
  Future<void> verifyOtp(String otp) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final otpToken = otp.trim();
      final authEmail = state.email;

      if (authEmail == null || authEmail.isEmpty) {
        state = state.copyWith(
          error: 'Please enter your mobile number first.',
          isLoading: false,
        );
        return;
      }

      if (!kBypassOtpValidation && !RegExp(r'^\d{6}$').hasMatch(otpToken)) {
        state = state.copyWith(
          error: 'Please enter a valid 6-digit OTP.',
          isLoading: false,
        );
        return;
      }

      if (kBypassOtpValidation) {
        await Future<void>.delayed(const Duration(milliseconds: 150));
        final mockUserId = AppRuntimeConfig.mockUserIdForIdentifier(authEmail);
        state = state.copyWith(
          isAuthenticated: true,
          userId: mockUserId,
          isLoading: false,
          otp: otpToken,
          error: null,
        );
        return;
      }

      if (kUseMockAuth) {
        await Future<void>.delayed(const Duration(milliseconds: 300));
        final mockUserId = AppRuntimeConfig.mockUserIdForIdentifier(authEmail);
        state = state.copyWith(
          isAuthenticated: true,
          userId: mockUserId,
          isLoading: false,
          otp: otpToken,
          error: null,
        );
        return;
      }

      final dio = ref.read(apiClientProvider);
      final response = await dio.post<dynamic>(
        '/auth/verify-otp',
        data: {'email': authEmail, 'phone': state.phoneNumber, 'otp': otpToken},
      );
      final data =
          (response.data as Map?)?.cast<String, dynamic>() ??
          <String, dynamic>{};
      final success = data['success'] == true;
      if (!success) {
        state = state.copyWith(
          error: data['error']?.toString() ?? 'Invalid OTP. Please try again.',
          isLoading: false,
        );
        return;
      }

      state = state.copyWith(
        isAuthenticated: true,
        userId:
            data['user_id']?.toString() ?? AppRuntimeConfig.mockFallbackUserId,
        isLoading: false,
        otp: otpToken,
        error: null,
      );
    } on DioException catch (e, stackTrace) {
      log.error('Failed to verify OTP', e, stackTrace);
      state = state.copyWith(
        error: _extractApiError(e, fallback: 'Invalid OTP. Please try again.'),
        isLoading: false,
      );
    } catch (e, stackTrace) {
      log.error('Failed to verify OTP', e, stackTrace);
      state = state.copyWith(
        error: 'Invalid OTP. Please try again.',
        isLoading: false,
      );
    }
  }

  /// Logout
  Future<void> logout() async {
    state = const AuthState();
  }

  /// Clear error
  void clearError() {
    state = state.copyWith(error: null);
  }

  /// Move back to phone-entry step from OTP step.
  void backToIdentifierEntry() {
    state = state.copyWith(isOtpSent: false, error: null, isLoading: false);
  }
}

String _normalizePhoneNumber(String input) {
  final compact = input.trim().replaceAll(RegExp(r'\s+|-'), '');
  if (compact.startsWith('+')) {
    final digits = compact.substring(1).replaceAll(RegExp(r'[^0-9]'), '');
    return '+$digits';
  }
  return compact.replaceAll(RegExp(r'[^0-9]'), '');
}

bool _isValidPhoneNumber(String input) =>
    RegExp(r'^\+?[0-9]{10,15}$').hasMatch(input);

String _phoneToAuthEmail(String normalizedPhone) {
  final localPart = normalizedPhone.replaceAll(RegExp(r'[^0-9]'), '');
  return 'mobile_$localPart@phone.local';
}

String _extractApiError(DioException e, {required String fallback}) {
  final data = e.response?.data;
  if (data is Map && data['error'] != null) {
    return data['error'].toString();
  }
  return fallback;
}
