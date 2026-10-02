import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

import '../../core/providers/api_client_provider.dart';
import '../../core/telemetry/client_error_reporter.dart';
import '../../core/utils/logger.dart';
import 'support_models.dart';

/// The member support API (`/v1/support/...`). The shared client's base URL
/// already ends in `/v1`.
class SupportApi {
  const SupportApi(this._dio);

  final Dio _dio;

  Future<SupportTicketList> listTickets({String status = 'all'}) =>
      _guard('list_tickets', () async {
        final response = await _dio.get<dynamic>(
          '/support/tickets',
          queryParameters: {'status': status, 'limit': 100},
        );
        return SupportTicketList.fromJson(_body(response));
      });

  /// Loads one ticket. The server marks agent replies read on this call.
  Future<SupportThread> getTicket(String ticketId) =>
      _guard('get_ticket', () async {
        final response = await _dio.get<dynamic>(
          '/support/tickets/${Uri.encodeComponent(ticketId)}',
        );
        return SupportThread.fromJson(_body(response));
      });

  Future<SupportCreateResult> createTicket({
    required String category,
    required String subject,
    required String description,
    required List<String> attachmentIds,
    required SupportDeviceContext device,
    required String idempotencyKey,
  }) => _guard('create_ticket', () async {
    final response = await _dio.post<dynamic>(
      '/support/tickets',
      data: {
        'category': category,
        'subject': subject,
        'description': description,
        'attachment_ids': attachmentIds,
        ...device.toJson(),
      },
      options: Options(headers: {'Idempotency-Key': idempotencyKey}),
    );
    final body = _body(response);
    return SupportCreateResult(
      thread: SupportThread.fromJson(body),
      duplicate: body['duplicate'] == true,
    );
  });

  /// Uploads a screenshot or PDF before it is linked to a ticket or reply.
  Future<SupportUpload> uploadAttachment({
    required Uint8List bytes,
    required String filename,
    required String contentType,
  }) => _guard('upload_attachment', () async {
    final response = await _dio.post<dynamic>(
      '/support/attachments',
      data: FormData.fromMap({
        'file': MultipartFile.fromBytes(
          bytes,
          filename: filename,
          contentType: DioMediaType.parse(contentType),
        ),
      }),
    );
    final attachment = _body(response)['attachment'];
    if (attachment is! Map) {
      throw const SupportException(message: 'Upload response was empty.');
    }
    return SupportUpload.fromJson(attachment.cast());
  });

  Future<({SupportTicket ticket, SupportMessage message})> reply(
    String ticketId, {
    required String body,
    required List<String> attachmentIds,
    required String idempotencyKey,
  }) => _guard('reply', () async {
    final response = await _dio.post<dynamic>(
      '/support/tickets/${Uri.encodeComponent(ticketId)}/messages',
      data: {'body': body, 'attachment_ids': attachmentIds},
      options: Options(headers: {'Idempotency-Key': idempotencyKey}),
    );
    final json = _body(response);
    return (
      ticket: SupportTicket.fromJson(_mapOf(json['ticket'])),
      message: SupportMessage.fromJson(_mapOf(json['message'])),
    );
  });

  Future<SupportTicket> close(String ticketId) =>
      _ticketAction('close', ticketId, const <String, dynamic>{});

  Future<SupportTicket> reopen(String ticketId, {String reason = ''}) =>
      _ticketAction('reopen', ticketId, {
        if (reason.trim().isNotEmpty) 'reason': reason.trim(),
      });

  Future<SupportTicket> rate(
    String ticketId, {
    required int rating,
    String comment = '',
  }) => _ticketAction('rating', ticketId, {
    'rating': rating,
    if (comment.trim().isNotEmpty) 'comment': comment.trim(),
  });

  /// Raw bytes of an attachment; the route needs the member's bearer token,
  /// so images cannot be loaded with a plain network image.
  Future<Uint8List> attachmentBytes(String ticketId, String attachmentId) =>
      _guard('attachment_bytes', () async {
        final response = await _dio.get<List<int>>(
          '/support/tickets/${Uri.encodeComponent(ticketId)}'
          '/attachments/${Uri.encodeComponent(attachmentId)}',
          options: Options(responseType: ResponseType.bytes),
        );
        return Uint8List.fromList(response.data ?? const <int>[]);
      });

  Future<SupportTicket> _ticketAction(
    String action,
    String ticketId,
    Map<String, dynamic> data,
  ) => _guard(action, () async {
    final response = await _dio.post<dynamic>(
      '/support/tickets/${Uri.encodeComponent(ticketId)}/$action',
      data: data,
      options: Options(headers: {'Idempotency-Key': const Uuid().v4()}),
    );
    return SupportTicket.fromJson(_mapOf(_body(response)['ticket']));
  });

  static Map<String, dynamic> _body(Response<dynamic> response) {
    final data = response.data;
    if (data is Map) {
      final body = data.cast<String, dynamic>();
      if (body['success'] == false) {
        throw SupportException(
          code: body['error_code']?.toString() ?? '',
          message: body['error']?.toString() ?? '',
          statusCode: response.statusCode,
        );
      }
      return body;
    }
    throw SupportException(
      message: 'Unexpected response.',
      statusCode: response.statusCode,
    );
  }

  static Map<String, dynamic> _mapOf(Object? value) =>
      value is Map ? value.cast<String, dynamic>() : const <String, dynamic>{};

  static Future<T> _guard<T>(String operation, Future<T> Function() run) async {
    try {
      return await run();
    } on DioException catch (error, stackTrace) {
      log.error('support_$operation failed', error, stackTrace);
      throw supportExceptionFromDio(error);
    }
  }
}

/// Maps a Dio failure to a [SupportException] carrying the server's code.
SupportException supportExceptionFromDio(DioException error) {
  final response = error.response;
  if (response == null) {
    return const SupportException(offline: true);
  }
  final data = response.data;
  if (data is Map) {
    final retry = data['retry_after_seconds'];
    return SupportException(
      code: data['error_code']?.toString() ?? '',
      message: data['error']?.toString() ?? '',
      statusCode: response.statusCode,
      retryAfterSeconds: retry is num ? retry.toInt() : null,
    );
  }
  return SupportException(statusCode: response.statusCode);
}

final supportApiProvider = Provider<SupportApi>(
  (ref) => SupportApi(ref.watch(apiClientProvider)),
);

/// The member's tickets and unread count, shared by the support centre and
/// "My tickets".
final supportTicketsProvider =
    AsyncNotifierProvider<SupportTicketsNotifier, SupportTicketList>(
      SupportTicketsNotifier.new,
    );

class SupportTicketsNotifier extends AsyncNotifier<SupportTicketList> {
  @override
  Future<SupportTicketList> build() =>
      ref.watch(supportApiProvider).listTickets();

  Future<void> refresh() async {
    state = const AsyncLoading<SupportTicketList>().copyWithPrevious(state);
    state = await AsyncValue.guard(
      () => ref.read(supportApiProvider).listTickets(),
    );
  }
}

/// An attachment's bytes, keyed by `ticketId/attachmentId`.
final supportAttachmentBytesProvider = FutureProvider.autoDispose
    .family<Uint8List, ({String ticketId, String attachmentId})>(
      (ref, key) => ref
          .watch(supportApiProvider)
          .attachmentBytes(key.ticketId, key.attachmentId),
    );

/// Device facts attached to a new ticket. Reuses the crash reporter's
/// non-identifying context (no device name or model is read).
SupportDeviceContext currentSupportDeviceContext(String localeTag) {
  final context = ClientErrorContext.current();
  final build = context.buildNumber;
  return SupportDeviceContext(
    appVersion: build.isEmpty
        ? context.appVersion
        : '${context.appVersion}+$build',
    platform: context.platform,
    osVersion: context.osVersion,
    locale: localeTag,
  );
}

/// Picks screenshots. A provider so tests can supply files without a plugin.
final supportImagePickerProvider = Provider<SupportImagePicker>(
  (ref) => const SupportImagePicker(),
);

class SupportImagePicker {
  const SupportImagePicker();

  /// Up to [max] images, re-encoded small (JPEG where the platform allows).
  Future<List<XFile>> pick(int max) async {
    if (max <= 0) {
      return const [];
    }
    final picker = ImagePicker();
    if (max == 1) {
      final file = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 2048,
        maxHeight: 2048,
      );
      return file == null ? const [] : [file];
    }
    final files = await picker.pickMultiImage(
      imageQuality: 85,
      maxWidth: 2048,
      maxHeight: 2048,
      limit: max,
    );
    return files.take(max).toList(growable: false);
  }
}

/// The content type of an image from its leading bytes, or null when it is
/// neither JPEG nor PNG.
String? sniffSupportImageType(Uint8List bytes) {
  if (bytes.length >= 3 &&
      bytes[0] == 0xFF &&
      bytes[1] == 0xD8 &&
      bytes[2] == 0xFF) {
    return 'image/jpeg';
  }
  if (bytes.length >= 8 &&
      bytes[0] == 0x89 &&
      bytes[1] == 0x50 &&
      bytes[2] == 0x4E &&
      bytes[3] == 0x47) {
    return 'image/png';
  }
  return null;
}
