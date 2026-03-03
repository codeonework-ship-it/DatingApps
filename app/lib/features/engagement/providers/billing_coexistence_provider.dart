import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/feature_flags.dart';
import '../../../core/providers/api_client_provider.dart';
import '../../../core/utils/logger.dart';

class MonetizedFeature {
  const MonetizedFeature({
    required this.featureCode,
    required this.category,
    required this.access,
    required this.requiresSubscription,
    required this.blocksCoreProgression,
    required this.description,
  });

  final String featureCode;
  final String category;
  final String access;
  final bool requiresSubscription;
  final bool blocksCoreProgression;
  final String description;
}

class BillingCoexistenceMatrix {
  const BillingCoexistenceMatrix({
    required this.matrixVersion,
    required this.coreProgressionNonBlocking,
    required this.coreProgressionFeatures,
    required this.monetizedFeatures,
  });

  final String matrixVersion;
  final bool coreProgressionNonBlocking;
  final List<String> coreProgressionFeatures;
  final List<MonetizedFeature> monetizedFeatures;
}

final billingCoexistenceMatrixProvider =
    FutureProvider<BillingCoexistenceMatrix>((ref) async {
      if (kUseMockAuth) {
        return const BillingCoexistenceMatrix(
          matrixVersion: '2026-03-03',
          coreProgressionNonBlocking: true,
          coreProgressionFeatures: <String>[
            'quest_unlock_workflow',
            'chat_after_unlock',
            'digital_gestures',
            'mini_activities',
          ],
          monetizedFeatures: <MonetizedFeature>[
            MonetizedFeature(
              featureCode: 'profile_boosts',
              category: 'visibility',
              access: 'premium_optional',
              requiresSubscription: true,
              blocksCoreProgression: false,
              description: 'Increase profile discovery reach.',
            ),
            MonetizedFeature(
              featureCode: 'advanced_analytics',
              category: 'insights',
              access: 'premium_optional',
              requiresSubscription: true,
              blocksCoreProgression: false,
              description: 'Enhanced engagement and trend insights.',
            ),
          ],
        );
      }

      try {
        final dio = ref.read(apiClientProvider);
        final response = await dio.get<Map<String, dynamic>>(
          '/billing/coexistence-matrix',
        );
        final body =
            (response.data as Map?)?.cast<String, dynamic>() ??
            <String, dynamic>{};
        final matrix =
            (body['coexistence_matrix'] as Map?)?.cast<String, dynamic>() ??
            <String, dynamic>{};

        final coreFeatures =
            ((matrix['core_progression_features'] as List?) ?? const [])
                .map((item) => item.toString())
                .where((item) => item.trim().isNotEmpty)
                .toList(growable: false);

        final monetized = ((matrix['monetized_features'] as List?) ?? const [])
            .whereType<Map<dynamic, dynamic>>()
            .map((entry) {
              final item = entry.cast<String, dynamic>();
              return MonetizedFeature(
                featureCode: item['feature_code']?.toString() ?? '',
                category: item['category']?.toString() ?? '',
                access: item['access']?.toString() ?? '',
                requiresSubscription: item['requires_subscription'] == true,
                blocksCoreProgression: item['blocks_core_progression'] == true,
                description: item['description']?.toString() ?? '',
              );
            })
            .where((item) => item.featureCode.isNotEmpty)
            .toList(growable: false);

        return BillingCoexistenceMatrix(
          matrixVersion: matrix['matrix_version']?.toString() ?? '',
          coreProgressionNonBlocking:
              matrix['core_progression_non_blocking'] == true,
          coreProgressionFeatures: coreFeatures,
          monetizedFeatures: monetized,
        );
      } on DioException catch (e, stackTrace) {
        log.error('Failed to load billing coexistence matrix', e, stackTrace);
        return const BillingCoexistenceMatrix(
          matrixVersion: '',
          coreProgressionNonBlocking: true,
          coreProgressionFeatures: <String>[],
          monetizedFeatures: <MonetizedFeature>[],
        );
      } catch (e, stackTrace) {
        log.error('Failed to load billing coexistence matrix', e, stackTrace);
        return const BillingCoexistenceMatrix(
          matrixVersion: '',
          coreProgressionNonBlocking: true,
          coreProgressionFeatures: <String>[],
          monetizedFeatures: <MonetizedFeature>[],
        );
      }
    });
