// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'message_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$messageNotifierHash() => r'ca88e07d0e736efd5238ae2370b79a07f6d1aab2';

/// Copied from Dart SDK
class _SystemHash {
  _SystemHash._();

  static int combine(int hash, int value) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + value);
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
    return hash ^ (hash >> 6);
  }

  static int finish(int hash) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
    // ignore: parameter_assignments
    hash = hash ^ (hash >> 11);
    return 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
  }
}

abstract class _$MessageNotifier
    extends BuildlessAutoDisposeNotifier<MessageState> {
  late final String matchId;

  MessageState build(String matchId);
}

/// Message Provider for specific match
///
/// Copied from [MessageNotifier].
@ProviderFor(MessageNotifier)
const messageNotifierProvider = MessageNotifierFamily();

/// Message Provider for specific match
///
/// Copied from [MessageNotifier].
class MessageNotifierFamily extends Family<MessageState> {
  /// Message Provider for specific match
  ///
  /// Copied from [MessageNotifier].
  const MessageNotifierFamily();

  /// Message Provider for specific match
  ///
  /// Copied from [MessageNotifier].
  MessageNotifierProvider call(String matchId) {
    return MessageNotifierProvider(matchId);
  }

  @override
  MessageNotifierProvider getProviderOverride(
    covariant MessageNotifierProvider provider,
  ) {
    return call(provider.matchId);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'messageNotifierProvider';
}

/// Message Provider for specific match
///
/// Copied from [MessageNotifier].
class MessageNotifierProvider
    extends AutoDisposeNotifierProviderImpl<MessageNotifier, MessageState> {
  /// Message Provider for specific match
  ///
  /// Copied from [MessageNotifier].
  MessageNotifierProvider(String matchId)
    : this._internal(
        () => MessageNotifier()..matchId = matchId,
        from: messageNotifierProvider,
        name: r'messageNotifierProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$messageNotifierHash,
        dependencies: MessageNotifierFamily._dependencies,
        allTransitiveDependencies:
            MessageNotifierFamily._allTransitiveDependencies,
        matchId: matchId,
      );

  MessageNotifierProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.matchId,
  }) : super.internal();

  final String matchId;

  @override
  MessageState runNotifierBuild(covariant MessageNotifier notifier) {
    return notifier.build(matchId);
  }

  @override
  Override overrideWith(MessageNotifier Function() create) {
    return ProviderOverride(
      origin: this,
      override: MessageNotifierProvider._internal(
        () => create()..matchId = matchId,
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        matchId: matchId,
      ),
    );
  }

  @override
  AutoDisposeNotifierProviderElement<MessageNotifier, MessageState>
  createElement() {
    return _MessageNotifierProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is MessageNotifierProvider && other.matchId == matchId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, matchId.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin MessageNotifierRef on AutoDisposeNotifierProviderRef<MessageState> {
  /// The parameter `matchId` of this provider.
  String get matchId;
}

class _MessageNotifierProviderElement
    extends AutoDisposeNotifierProviderElement<MessageNotifier, MessageState>
    with MessageNotifierRef {
  _MessageNotifierProviderElement(super.provider);

  @override
  String get matchId => (origin as MessageNotifierProvider).matchId;
}

// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
