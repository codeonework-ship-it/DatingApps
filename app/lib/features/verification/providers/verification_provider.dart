import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/config/feature_flags.dart';
import '../../../core/providers/api_client_provider.dart';
import '../../../core/utils/logger.dart';
import '../../auth/providers/auth_provider.dart';

part 'verification_provider.g.dart';

class VerificationState {
  const VerificationState({
    required this.status,
    required this.rejectionReason,
  });
  final String? status; // pending | verified | rejected | expired
  final String? rejectionReason;
}

@riverpod
class VerificationNotifier extends _$VerificationNotifier {
  final _picker = ImagePicker();

  @override
  Future<VerificationState> build() async {
    final auth = ref.watch(authNotifierProvider);
    final userId = auth.userId;
    if (userId == null) {
      return const VerificationState(status: null, rejectionReason: null);
    }

    if (kUseMockAuth) {
      return const VerificationState(status: null, rejectionReason: null);
    }

    final dio = ref.read(apiClientProvider);
    try {
      final response = await dio.get('/verification/$userId');
      final data = (response.data as Map?)?.cast<String, dynamic>() ?? const {};
      return VerificationState(
        status: data['status']?.toString(),
        rejectionReason: data['rejection_reason']?.toString(),
      );
    } on DioException catch (e, stackTrace) {
      log.error('Failed to fetch verification state', e, stackTrace);
      return const VerificationState(status: null, rejectionReason: null);
    }
  }

  Future<XFile?> pickIdPhoto({required bool fromCamera}) => _picker.pickImage(
    source: fromCamera ? ImageSource.camera : ImageSource.gallery,
    imageQuality: 85,
  );

  Future<XFile?> pickSelfie({required bool fromCamera}) => _picker.pickImage(
    source: fromCamera ? ImageSource.camera : ImageSource.gallery,
    imageQuality: 85,
  );

  Future<void> submit({
    required XFile idPhoto,
    required XFile selfiePhoto,
  }) async {
    final auth = ref.read(authNotifierProvider);
    final userId = auth.userId;
    if (userId == null) return;

    state = const AsyncLoading();

    if (kUseMockAuth) {
      state = const AsyncData(
        VerificationState(status: 'pending', rejectionReason: null),
      );
      return;
    }

    final dio = ref.read(apiClientProvider);
    try {
      final response = await dio.post(
        '/verification/$userId/submit',
        data: {
          'id_photo_ref': idPhoto.path,
          'selfie_photo_ref': selfiePhoto.path,
        },
      );
      final data = (response.data as Map?)?.cast<String, dynamic>() ?? const {};
      state = AsyncData(
        VerificationState(
          status: data['status']?.toString() ?? 'pending',
          rejectionReason: data['rejection_reason']?.toString(),
        ),
      );
    } on DioException catch (e, stackTrace) {
      log.error('Verification submit failed', e, stackTrace);
      state = AsyncError(e, stackTrace);
    }
  }
}
