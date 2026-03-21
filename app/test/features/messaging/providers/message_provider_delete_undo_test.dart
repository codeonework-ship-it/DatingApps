import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verified_dating_app/features/auth/providers/auth_provider.dart';
import 'package:verified_dating_app/features/messaging/providers/message_provider.dart';

class _TestAuthNotifier extends AuthNotifier {
  @override
  AuthState build() =>
      const AuthState(isAuthenticated: true, userId: 'test-user-1');
}

void main() {
  group('MessageNotifier delete undo window', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer(
        overrides: [
          authNotifierProvider.overrideWith(_TestAuthNotifier.new),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    test('undo restores message before timer commit', () async {
      final provider = messageNotifierProvider('pending-match-undo');
      final sub = container.listen(provider, (_, __) {}, fireImmediately: true);
      final notifier = container.read(provider.notifier);

      await notifier.sendMessage('hello undo');
      final initial = container.read(provider).messages;
      expect(initial, hasLength(1));

      final target = initial.first;
      final requested = await notifier.requestDeleteMessageForEveryone(
        target,
        undoWindow: const Duration(milliseconds: 80),
      );

      expect(requested, isTrue);
      expect(container.read(provider).messages, isEmpty);
      expect(container.read(provider).pendingDeleteIds, contains(target.id));

      final restored = notifier.undoPendingDeleteMessage(target.id);
      expect(restored, isTrue);
      expect(container.read(provider).messages, hasLength(1));
      expect(container.read(provider).pendingDeleteIds, isEmpty);

      await Future<void>.delayed(const Duration(milliseconds: 120));
      expect(container.read(provider).messages, hasLength(1));
      expect(container.read(provider).pendingDeleteIds, isEmpty);
      sub.close();
    });

    test('timer commit finalizes delete when undo is not used', () async {
      final provider = messageNotifierProvider('pending-match-commit');
      final sub = container.listen(provider, (_, __) {}, fireImmediately: true);
      final notifier = container.read(provider.notifier);

      await notifier.sendMessage('hello commit');
      final initial = container.read(provider).messages;
      expect(initial, hasLength(1));

      final target = initial.first;
      final requested = await notifier.requestDeleteMessageForEveryone(
        target,
        undoWindow: const Duration(milliseconds: 50),
      );

      expect(requested, isTrue);
      expect(container.read(provider).messages, isEmpty);
      expect(container.read(provider).pendingDeleteIds, contains(target.id));

      await Future<void>.delayed(const Duration(milliseconds: 100));
      expect(container.read(provider).messages, isEmpty);
      expect(container.read(provider).pendingDeleteIds, isEmpty);
      expect(container.read(provider).error, isNull);
      expect(notifier.undoPendingDeleteMessage(target.id), isFalse);
      sub.close();
    });
  });
}
