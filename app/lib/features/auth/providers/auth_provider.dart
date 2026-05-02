import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/config/app_runtime_config.dart';
import '../../../core/config/feature_flags.dart';
import '../../../core/providers/api_client_provider.dart';
import '../../../core/utils/logger.dart';

part 'auth_provider.g.dart';

class SignupDraft {
  const SignupDraft({
    required this.phoneNumber,
    required this.name,
    required this.dateOfBirth,
    required this.gender,
  });

  final String phoneNumber;
  final String name;
  final String dateOfBirth;
  final String gender;
}

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
    this.isSignupFlow = false,
    this.pendingSignup,
  });
  final String? phoneNumber;
  final String? email;
  final String? otp;
  final bool isLoading;
  final String? error;
  final bool isOtpSent;
  final bool isAuthenticated;
  final String? userId;
  final bool isSignupFlow;
  final SignupDraft? pendingSignup;

  static const Object _unset = Object();

  AuthState copyWith({
    Object? phoneNumber = _unset,
    Object? email = _unset,
    Object? otp = _unset,
    Object? isLoading = _unset,
    Object? error = _unset,
    Object? isOtpSent = _unset,
    Object? isAuthenticated = _unset,
    Object? userId = _unset,
    Object? isSignupFlow = _unset,
    Object? pendingSignup = _unset,
  }) => AuthState(
    phoneNumber: identical(phoneNumber, _unset)
        ? this.phoneNumber
        : phoneNumber as String?,
    email: identical(email, _unset) ? this.email : email as String?,
    otp: identical(otp, _unset) ? this.otp : otp as String?,
    isLoading: identical(isLoading, _unset)
        ? this.isLoading
        : isLoading! as bool,
    error: identical(error, _unset) ? this.error : error as String?,
    isOtpSent: identical(isOtpSent, _unset)
        ? this.isOtpSent
        : isOtpSent! as bool,
    isAuthenticated: identical(isAuthenticated, _unset)
        ? this.isAuthenticated
        : isAuthenticated! as bool,
    userId: identical(userId, _unset) ? this.userId : userId as String?,
    isSignupFlow: identical(isSignupFlow, _unset)
        ? this.isSignupFlow
        : isSignupFlow! as bool,
    pendingSignup: identical(pendingSignup, _unset)
        ? this.pendingSignup
        : pendingSignup as SignupDraft?,
  );
}

/// Auth Provider
@riverpod
class AuthNotifier extends _$AuthNotifier {
  @override
  AuthState build() => const AuthState();

  /// Send OTP to mobile number
  Future<void> sendOtp(String mobileNumber) async {
    state = state.copyWith(
      isLoading: true,
      error: null,
      isSignupFlow: false,
      pendingSignup: null,
    );

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

      const shouldBypassOtp = kBypassOtpValidation;

      if (shouldBypassOtp) {
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
    } on Object catch (e, stackTrace) {
      log.error('Failed to send OTP', e, stackTrace);
      state = state.copyWith(
        error: 'Failed to send OTP. Please try again.',
        isLoading: false,
      );
    }
  }

  /// Send OTP for a new explicit signup. The account-domain user row is not
  /// bootstrapped until the OTP is verified successfully.
  Future<void> sendSignupOtp(SignupDraft signup) async {
    state = state.copyWith(
      isLoading: true,
      error: null,
      isSignupFlow: true,
      pendingSignup: signup,
    );

    try {
      final normalized = _normalizePhoneNumber(signup.phoneNumber);
      final transportEmail = _phoneToAuthEmail(normalized);
      if (!_isValidPhoneNumber(normalized)) {
        state = state.copyWith(
          error: 'Please enter a valid mobile number.',
          isLoading: false,
        );
        return;
      }

      if (kBypassOtpValidation) {
        final existing = await _signupPhoneAlreadyRegistered(transportEmail);
        if (existing) {
          state = state.copyWith(
            error:
                'An account already exists for this mobile number. Please sign in instead.',
            isLoading: false,
          );
          return;
        }
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
        pendingSignup: SignupDraft(
          phoneNumber: normalized,
          name: signup.name.trim(),
          dateOfBirth: signup.dateOfBirth.trim(),
          gender: signup.gender.trim(),
        ),
      );
    } on DioException catch (e, stackTrace) {
      log.error('Failed to send signup OTP', e, stackTrace);
      state = state.copyWith(
        error: _extractApiError(
          e,
          fallback: 'Failed to send OTP. Please try again.',
        ),
        isLoading: false,
      );
    } on Object catch (e, stackTrace) {
      log.error('Failed to send signup OTP', e, stackTrace);
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

      const shouldBypassOtp = kBypassOtpValidation;

      if (!shouldBypassOtp && !RegExp(r'^\d{6}$').hasMatch(otpToken)) {
        state = state.copyWith(
          error: 'Please enter a valid 6-digit OTP.',
          isLoading: false,
        );
        return;
      }

      if (shouldBypassOtp) {
        if (otpToken != kOtpBypassCode) {
          state = state.copyWith(
            error: 'Use 123456 as the temporary OTP.',
            isLoading: false,
          );
          return;
        }
        await Future<void>.delayed(const Duration(milliseconds: 150));
        final mockUserId = AppRuntimeConfig.mockUserIdForIdentifier(authEmail);
        state = state.copyWith(
          isAuthenticated: true,
          userId: mockUserId,
          isLoading: false,
          otp: otpToken,
          error: null,
          isSignupFlow: false,
          pendingSignup: null,
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
          isSignupFlow: false,
          pendingSignup: null,
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
        userId: data['user_id']?.toString(),
        isLoading: false,
        otp: otpToken,
        error: null,
        isSignupFlow: false,
        pendingSignup: null,
      );
      if ((state.userId ?? '').trim().isEmpty) {
        state = state.copyWith(
          isAuthenticated: false,
          userId: null,
          isLoading: false,
          error: 'Login failed. Backend response did not include a user id.',
        );
      }
    } on DioException catch (e, stackTrace) {
      log.error('Failed to verify OTP', e, stackTrace);
      state = state.copyWith(
        error: _extractApiError(e, fallback: 'Invalid OTP. Please try again.'),
        isLoading: false,
      );
    } on Object catch (e, stackTrace) {
      log.error('Failed to verify OTP', e, stackTrace);
      state = state.copyWith(
        error: 'Invalid OTP. Please try again.',
        isLoading: false,
      );
    }
  }

  /// Verify signup OTP and durably bootstrap the app-domain user/profile draft.
  Future<void> verifySignupOtp(String otp) async {
    state = state.copyWith(isLoading: true, error: null, isSignupFlow: true);

    try {
      final signup = state.pendingSignup;
      final otpToken = otp.trim();
      final authEmail = state.email;

      if (signup == null || authEmail == null || authEmail.isEmpty) {
        state = state.copyWith(
          error: 'Please enter your signup details first.',
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
        if (otpToken != kOtpBypassCode) {
          state = state.copyWith(
            error: 'Use 123456 as the temporary OTP.',
            isLoading: false,
          );
          return;
        }
        await Future<void>.delayed(const Duration(milliseconds: 150));
        final mockUserId = AppRuntimeConfig.mockUserIdForIdentifier(authEmail);
        await _tryBootstrapSignupProfile(userId: mockUserId, signup: signup);
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

      final dio = ref.read(apiClientProvider);
      final verifyResponse = await dio.post<dynamic>(
        '/auth/verify-otp',
        data: {'email': authEmail, 'phone': state.phoneNumber, 'otp': otpToken},
      );
      final verifyData =
          (verifyResponse.data as Map?)?.cast<String, dynamic>() ??
          <String, dynamic>{};
      if (verifyData['success'] != true) {
        state = state.copyWith(
          error:
              verifyData['error']?.toString() ??
              'Invalid OTP. Please try again.',
          isLoading: false,
        );
        return;
      }

      final userId = verifyData['user_id']?.toString() ?? '';
      if (userId.trim().isEmpty) {
        state = state.copyWith(
          error: 'Signup failed. Backend response did not include a user id.',
          isLoading: false,
        );
        return;
      }

      await _bootstrapSignupProfile(userId: userId, signup: signup);

      state = state.copyWith(
        isAuthenticated: true,
        userId: userId,
        isLoading: false,
        otp: otpToken,
        error: null,
      );
    } on DioException catch (e, stackTrace) {
      log.error('Failed to verify signup OTP', e, stackTrace);
      state = state.copyWith(
        error: _extractApiError(
          e,
          fallback: 'Signup failed. Please try again.',
        ),
        isLoading: false,
      );
    } on Object catch (e, stackTrace) {
      log.error('Failed to verify signup OTP', e, stackTrace);
      state = state.copyWith(
        error: 'Signup failed. Please try again.',
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

  /// Reset an in-progress unauthenticated auth flow when the user switches
  /// between sign-in and sign-up surfaces.
  void resetAuthFlow() {
    if (!state.isAuthenticated) {
      state = const AuthState();
    }
  }

  Future<void> _bootstrapSignupProfile({
    required String userId,
    required SignupDraft signup,
  }) async {
    if (kUseMockAuth) return;

    final dio = ref.read(apiClientProvider);
    await dio.post<dynamic>(
      '/auth/signup/bootstrap',
      data: {
        'user_id': userId,
        'phone': _normalizePhoneNumber(signup.phoneNumber),
        'name': signup.name.trim(),
        'date_of_birth': signup.dateOfBirth.trim(),
        'gender': signup.gender.trim(),
      },
    );
  }

  Future<void> _tryBootstrapSignupProfile({
    required String userId,
    required SignupDraft signup,
  }) async {
    try {
      await _bootstrapSignupProfile(userId: userId, signup: signup);
    } on DioException catch (e, stackTrace) {
      final status = e.response?.statusCode ?? 0;
      if (status == 404 ||
          status >= 500 ||
          e.type == DioExceptionType.connectionError) {
        log.warning(
          'Signup bootstrap unavailable during OTP bypass; continuing with local draft fallback: ${e.message}',
        );
        return;
      }
      log.error('Signup bootstrap failed during OTP bypass', e, stackTrace);
      rethrow;
    }
  }

  Future<bool> _signupPhoneAlreadyRegistered(String authEmail) async {
    if (kUseMockAuth) return false;
    try {
      final userId = AppRuntimeConfig.mockUserIdForIdentifier(authEmail);
      final dio = ref.read(apiClientProvider);
      final response = await dio.get<dynamic>('/profile/$userId/summary');
      final body =
          (response.data as Map?)?.cast<String, dynamic>() ??
          <String, dynamic>{};
      return body['found'] == true;
    } on DioException catch (e) {
      final status = e.response?.statusCode ?? 0;
      if (status == 404 ||
          status >= 500 ||
          e.type == DioExceptionType.connectionError) {
        return false;
      }
      return false;
    } on Object {
      return false;
    }
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
  if (data is Map && data['message'] != null) {
    return data['message'].toString();
  }
  return fallback;
}
