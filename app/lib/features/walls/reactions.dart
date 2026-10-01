import 'package:flutter/foundation.dart';

/// One empathetic reaction a member can leave on a chapter or a photo.
/// Every reaction counts as one like for wall reach, ranking and rewards.
class EmpathyReaction {
  const EmpathyReaction(this.id, this.emoji, this.label);

  /// Wire value (`love`, `hear_you`, ...).
  final String id;
  final String emoji;

  /// What the reader is saying, e.g. "I hear you".
  final String label;
}

/// The reactions in picker order. `love` is the plain like.
const empathyReactions = <EmpathyReaction>[
  EmpathyReaction('love', '❤️', 'Love this'),
  EmpathyReaction('hear_you', '🫶', 'I hear you'),
  EmpathyReaction('me_too', '🙋', 'Me too'),
  EmpathyReaction('with_you', '🤝', 'I’m with you'),
  EmpathyReaction('hug', '🫂', 'Sending a hug'),
  EmpathyReaction('proud', '🌟', 'Proud of you'),
];

/// The reaction for [id], falling back to the plain like.
EmpathyReaction empathyReaction(String id) => empathyReactions.firstWhere(
  (r) => r.id == id,
  orElse: () => empathyReactions.first,
);

/// Reaction counts from a server payload (`reactions`), keeping known
/// reactions with a positive count.
Map<String, int> parseReactionCounts(Object? json) {
  if (json is! Map) return const {};
  final out = <String, int>{};
  for (final r in empathyReactions) {
    final n = json[r.id];
    final count = n is int ? n : (n is num ? n.toInt() : 0);
    if (count > 0) out[r.id] = count;
  }
  return out;
}

/// A member's like on one chapter or photo, with how they reacted and the
/// tally of everyone's reactions.
@immutable
class BlogLikeState {
  const BlogLikeState({
    required this.liked,
    required this.count,
    this.reaction = '',
    this.reactions = const {},
  });

  final bool liked;
  final int count;

  /// The member's reaction id; empty when not liked.
  final String reaction;

  /// Counts per reaction id, only positive counts.
  final Map<String, int> reactions;

  /// The state after liking ([like]) with [reaction] (null keeps the current
  /// reaction, or `love` for a new like), or after removing the like.
  BlogLikeState next({required bool like, String? reaction}) {
    final counts = {...reactions};
    void bump(String id, int by) {
      final value = (counts[id] ?? 0) + by;
      if (value > 0) {
        counts[id] = value;
      } else {
        counts.remove(id);
      }
    }

    final mine = this.reaction.isEmpty ? 'love' : this.reaction;
    if (!like) {
      if (!liked) return this;
      bump(mine, -1);
      return BlogLikeState(
        liked: false,
        count: count > 0 ? count - 1 : 0,
        reactions: counts,
      );
    }
    final chosen = reaction ?? (liked ? mine : 'love');
    if (liked) {
      if (chosen == mine) return this;
      bump(mine, -1);
      bump(chosen, 1);
      return BlogLikeState(
        liked: true,
        count: count,
        reaction: chosen,
        reactions: counts,
      );
    }
    bump(chosen, 1);
    return BlogLikeState(
      liked: true,
      count: count + 1,
      reaction: chosen,
      reactions: counts,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is BlogLikeState &&
      other.liked == liked &&
      other.count == count &&
      other.reaction == reaction &&
      mapEquals(other.reactions, reactions);

  @override
  int get hashCode => Object.hash(
    liked,
    count,
    reaction,
    Object.hashAllUnordered(
      reactions.entries.map((e) => '${e.key}:${e.value}'),
    ),
  );

  @override
  String toString() =>
      'BlogLikeState(liked: $liked, count: $count, reaction: $reaction, '
      'reactions: $reactions)';
}
