import 'package:flutter_test/flutter_test.dart';
import 'package:verified_dating_app/features/engagement/providers/moderation_appeals_provider.dart';

void main() {
  group('ModerationAppealItem', () {
    test('fromJson maps required and optional fields', () {
      final item = ModerationAppealItem.fromJson(<String, dynamic>{
        'id': 'apl-123',
        'user_id': 'user-1',
        'reason': 'Unfair moderation decision',
        'status': 'under_review',
        'sla_deadline_at': '2026-03-05T00:00:00Z',
        'created_at': '2026-03-03T00:00:00Z',
        'reviewed_by': 'admin-1',
      });

      expect(item.id, 'apl-123');
      expect(item.userId, 'user-1');
      expect(item.reason, 'Unfair moderation decision');
      expect(item.status, 'under_review');
      expect(item.slaDeadlineAt, '2026-03-05T00:00:00Z');
      expect(item.reviewedBy, 'admin-1');
    });

    test('fromJson uses safe defaults for missing fields', () {
      final item = ModerationAppealItem.fromJson(<String, dynamic>{});

      expect(item.id, '');
      expect(item.userId, '');
      expect(item.reason, '');
      expect(item.status, 'submitted');
      expect(item.slaDeadlineAt, '');
      expect(item.createdAt, '');
    });
  });

  group('appealStatusLabel', () {
    test('maps known statuses', () {
      expect(appealStatusLabel('submitted'), 'Submitted');
      expect(appealStatusLabel('under_review'), 'Under review');
      expect(appealStatusLabel('resolved_upheld'), 'Resolved (upheld)');
      expect(appealStatusLabel('resolved_reversed'), 'Resolved (reversed)');
    });

    test('returns original string for unknown statuses', () {
      expect(appealStatusLabel('custom_status'), 'custom_status');
    });
  });
}
