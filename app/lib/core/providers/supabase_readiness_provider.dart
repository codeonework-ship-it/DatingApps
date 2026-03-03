import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/app_runtime_config.dart';
import 'supabase_client_provider.dart';

class SupabaseReadiness {
  const SupabaseReadiness({
    required this.reachable,
    required this.schemaReady,
    this.message,
  });
  final bool reachable;
  final bool schemaReady;
  final String? message;

  bool get isReadyForPhaseOne => reachable && schemaReady;
}

final supabaseReadinessProvider =
    AsyncNotifierProvider<SupabaseReadinessNotifier, SupabaseReadiness>(
      SupabaseReadinessNotifier.new,
    );

class SupabaseReadinessNotifier extends AsyncNotifier<SupabaseReadiness> {
  @override
  Future<SupabaseReadiness> build() async => check();

  Future<SupabaseReadiness> check() async {
    final supabase = ref.read(supabaseClientProvider);
    final schema = AppRuntimeConfig.supabaseUsersSchema;
    final table = AppRuntimeConfig.supabaseUsersTable;
    final fqTable = '$schema.$table';

    try {
      await supabase.schema(schema).from(table).select('id').limit(1);
      return const SupabaseReadiness(reachable: true, schemaReady: true);
    } on PostgrestException catch (e) {
      final message = e.message.toLowerCase();

      if (e.code == 'PGRST106' || message.contains('invalid schema')) {
        return const SupabaseReadiness(
          reachable: true,
          schemaReady: false,
          message:
              'Supabase connected, but required schemas are not exposed. In Supabase Dashboard -> API -> Exposed schemas, add: user_management, matching, safety.',
        );
      }

      if ((e.code == 'PGRST205' ||
              message.contains('does not exist') ||
              message.contains('could not find the table')) &&
          (message.contains(fqTable.toLowerCase()) ||
              message.contains('public.$fqTable'.toLowerCase()) ||
              message.contains('users'))) {
        return const SupabaseReadiness(
          reachable: true,
          schemaReady: false,
          message:
              'Supabase connected, but Phase 1 tables are missing. Run scripts/complete_database_schema_all_phases.sql first.',
        );
      }

      if (e.code == '42501' || message.contains('permission denied')) {
        return const SupabaseReadiness(
          reachable: true,
          schemaReady: true,
          message: 'Supabase reachable (RLS-protected response).',
        );
      }

      return SupabaseReadiness(
        reachable: false,
        schemaReady: false,
        message: 'Supabase API error: ${e.message}',
      );
    } on SocketException catch (e) {
      return SupabaseReadiness(
        reachable: false,
        schemaReady: false,
        message: 'Network error: ${e.message}',
      );
    } catch (e) {
      return SupabaseReadiness(
        reachable: false,
        schemaReady: false,
        message: 'Unable to connect to Supabase: $e',
      );
    }
  }
}
