import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/feature_flags.dart';
import '../../../core/providers/api_client_provider.dart';
import '../../../core/utils/logger.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/profile_models.dart';

final emergencyContactsProvider =
    AsyncNotifierProvider<EmergencyContactsNotifier, List<EmergencyContact>>(
      EmergencyContactsNotifier.new,
    );

class EmergencyContactsNotifier extends AsyncNotifier<List<EmergencyContact>> {
  @override
  Future<List<EmergencyContact>> build() async {
    final userId = ref.watch(authNotifierProvider).userId;
    if (userId == null) {
      throw StateError('Not authenticated');
    }
    return _fetchContacts(userId);
  }

  Future<void> refresh() async {
    final userId = _requireUserId();
    state = AsyncData(await _fetchContacts(userId));
  }

  Future<void> addContact({
    required String name,
    required String phoneNumber,
  }) async {
    final userId = _requireUserId();
    final previous = state.valueOrNull ?? await future;

    if (previous.length >= 3) {
      throw StateError('You can add up to 3 emergency contacts only.');
    }

    if (kUseMockAuth) {
      final next = [
        ...previous,
        EmergencyContact(
          id: 'contact-${DateTime.now().millisecondsSinceEpoch}',
          userId: userId,
          name: name.trim(),
          phoneNumber: phoneNumber.trim(),
          ordering: previous.length + 1,
          addedAt: DateTime.now(),
        ),
      ];
      state = AsyncData(next);
      return;
    }

    try {
      final dio = ref.read(apiClientProvider);
      final response = await dio.post(
        '/emergency-contacts/$userId',
        data: {'name': name.trim(), 'phone_number': phoneNumber.trim()},
      );
      state = AsyncData(_contactsFromApi(userId, response.data));
    } catch (e, stackTrace) {
      log.error('Failed to add emergency contact', e, stackTrace);
      state = AsyncData(previous);
      rethrow;
    }
  }

  Future<void> updateContact({
    required String contactId,
    required String name,
    required String phoneNumber,
  }) async {
    final userId = _requireUserId();
    final previous = state.valueOrNull ?? await future;

    if (kUseMockAuth) {
      final updated = previous
          .map(
            (contact) => contact.id == contactId
                ? contact.copyWith(
                    name: name.trim(),
                    phoneNumber: phoneNumber.trim(),
                  )
                : contact,
          )
          .toList();
      state = AsyncData(updated);
      return;
    }

    try {
      final dio = ref.read(apiClientProvider);
      final response = await dio.put(
        '/emergency-contacts/$userId/$contactId',
        data: {'name': name.trim(), 'phone_number': phoneNumber.trim()},
      );
      state = AsyncData(_contactsFromApi(userId, response.data));
    } catch (e, stackTrace) {
      log.error('Failed to update emergency contact', e, stackTrace);
      state = AsyncData(previous);
      rethrow;
    }
  }

  Future<void> removeContact(String contactId) async {
    final userId = _requireUserId();
    final previous = state.valueOrNull ?? await future;

    if (kUseMockAuth) {
      final remaining = previous
          .where((contact) => contact.id != contactId)
          .toList();
      final normalized = <EmergencyContact>[];
      for (var i = 0; i < remaining.length; i++) {
        normalized.add(remaining[i].copyWith(ordering: i + 1));
      }
      state = AsyncData(normalized);
      return;
    }

    try {
      final dio = ref.read(apiClientProvider);
      final response = await dio.delete(
        '/emergency-contacts/$userId/$contactId',
      );
      state = AsyncData(_contactsFromApi(userId, response.data));
    } catch (e, stackTrace) {
      log.error('Failed to remove emergency contact', e, stackTrace);
      state = AsyncData(previous);
      rethrow;
    }
  }

  Future<List<EmergencyContact>> _fetchContacts(String userId) async {
    if (kUseMockAuth) {
      return state.valueOrNull ?? const <EmergencyContact>[];
    }

    final dio = ref.read(apiClientProvider);
    try {
      final response = await dio.get('/emergency-contacts/$userId');
      return _contactsFromApi(userId, response.data);
    } on DioException catch (e, stackTrace) {
      log.error('Failed to fetch emergency contacts', e, stackTrace);
      return state.valueOrNull ?? const <EmergencyContact>[];
    }
  }

  List<EmergencyContact> _contactsFromApi(String userId, dynamic data) {
    final root = (data as Map?)?.cast<String, dynamic>() ?? const {};
    final raw = (root['contacts'] as List?)?.cast<dynamic>() ?? const [];

    return raw.whereType<Map>().map((entry) {
      final item = entry.cast<String, dynamic>();
      return EmergencyContact(
        id: item['id']?.toString() ?? '',
        userId: userId,
        name: item['name']?.toString() ?? '',
        phoneNumber: item['phone_number']?.toString() ?? '',
        ordering: item['ordering'] as int? ?? 1,
        addedAt:
            DateTime.tryParse(item['added_at']?.toString() ?? '') ??
            DateTime.now(),
      );
    }).toList();
  }

  String _requireUserId() {
    final userId = ref.read(authNotifierProvider).userId;
    if (userId == null) {
      throw StateError('Not authenticated');
    }
    return userId;
  }
}
