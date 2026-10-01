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
      final response = await dio.get<Map<String, dynamic>>(
        '/verification/$userId',
      );
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

  Future<bool> submit({
    required XFile idPhoto,
    required XFile selfiePhoto,
  }) async {
    final auth = ref.read(authNotifierProvider);
    final userId = auth.userId;
    if (userId == null) return false;

    state = const AsyncLoading();

    if (kUseMockAuth) {
      state = const AsyncData(
        VerificationState(status: 'pending', rejectionReason: null),
      );
      return true;
    }

    final dio = ref.read(apiClientProvider);
    try {
      final idBytes = await idPhoto.readAsBytes();
      final selfieBytes = await selfiePhoto.readAsBytes();
      final response = await dio.post<Map<String, dynamic>>(
        '/verification/$userId/submit',
        data: FormData.fromMap({
          'id_document': MultipartFile.fromBytes(
            idBytes,
            filename: _uploadFilename(idPhoto, 'identity-document.jpg'),
          ),
          'selfie': MultipartFile.fromBytes(
            selfieBytes,
            filename: _uploadFilename(selfiePhoto, 'selfie.jpg'),
          ),
        }),
      );
      final data = (response.data as Map?)?.cast<String, dynamic>() ?? const {};
      state = AsyncData(
        VerificationState(
          status: data['status']?.toString() ?? 'pending',
          rejectionReason: data['rejection_reason']?.toString(),
        ),
      );
      return true;
    } on DioException catch (e, stackTrace) {
      log.error('Verification submit failed', e, stackTrace);
      state = AsyncError(e, stackTrace);
      return false;
    } on Object catch (e, stackTrace) {
      log.error('Unable to read verification evidence', e, stackTrace);
      state = AsyncError(e, stackTrace);
      return false;
    }
  }
}

String _uploadFilename(XFile file, String fallback) {
  final normalized = file.name.trim();
  return normalized.isEmpty ? fallback : normalized;
}
