import 'package:flutter/material.dart' hide Title;
import 'package:intl/intl.dart';

import '../../l10n/app_localizations.dart';
import 'clubs_data.dart';

/// "Books" or "Films" for a club or list kind.
String clubKindLabel(AppLocalizations l10n, String kind) =>
    kind == 'film' ? l10n.clubsKindFilms : l10n.clubsKindBooks;

/// Who can see a list or review; unknown values read as "Only me".
String clubAudienceLabel(AppLocalizations l10n, String audience) =>
    switch (audience) {
      'friends' => l10n.clubsAudienceFriends,
      'community' => l10n.clubsAudienceCommunity,
      _ => l10n.clubsAudiencePrivate,
    };

/// A member's club role; unknown values read as "Member".
String clubRoleLabel(AppLocalizations l10n, String role) => switch (role) {
  'owner' => l10n.clubsRoleOwner,
  'moderator' => l10n.clubsRoleModerator,
  _ => l10n.clubsRoleMember,
};

/// An average rating with one decimal in the reader's locale ("4.3", "4,3").
String formatClubRating(AppLocalizations l10n, double rating) =>
    NumberFormat('0.0', l10n.localeName).format(rating);

/// Books and films are told apart by icon and words, with a colour accent on
/// top, so the difference never depends on colour alone.
IconData kindIcon(String kind) =>
    kind == 'film' ? Icons.movie_outlined : Icons.menu_book_rounded;

Color kindAccent(ColorScheme scheme, String kind) =>
    kind == 'film' ? scheme.secondary : scheme.tertiary;

Color onKindAccent(ColorScheme scheme, String kind) =>
    kind == 'film' ? scheme.onSecondary : scheme.onTertiary;

Color kindTint(ColorScheme scheme, String kind) =>
    kind == 'film' ? scheme.secondaryContainer : scheme.tertiaryContainer;

LinearGradient kindGradient(ColorScheme scheme, String kind) => LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [kindTint(scheme, kind), scheme.primaryContainer],
);

/// "Book club" or "Film club" with its icon.
class KindBadge extends StatelessWidget {
  const KindBadge({required this.kind, super.key, this.suffix = 'club'});
  final String kind;

  /// 'club', 'list' or '' for the bare kind ("Book").
  final String suffix;

  String _label(AppLocalizations l10n) => switch ((kind, suffix)) {
    ('book', 'club') => l10n.clubsBadgeBookClub,
    ('film', 'club') => l10n.clubsBadgeFilmClub,
    ('book', 'list') => l10n.clubsBadgeBookList,
    ('film', 'list') => l10n.clubsBadgeFilmList,
    ('book', _) => l10n.clubsBadgeBook,
    ('film', _) => l10n.clubsBadgeFilm,
    _ => l10n.clubsClub,
  };

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final accent = kindAccent(scheme, kind);
    final label = _label(AppLocalizations.of(context));
    return DecoratedBox(
      decoration: BoxDecoration(
        color: accent,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(kindIcon(kind), size: 16, color: onKindAccent(scheme, kind)),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                label,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: onKindAccent(scheme, kind),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A round icon disc in the kind's accent colour.
class KindDisc extends StatelessWidget {
  const KindDisc({required this.kind, super.key, this.size = 48});
  final String kind;
  final double size;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: kindAccent(scheme, kind),
        shape: BoxShape.circle,
      ),
      child: Icon(
        kindIcon(kind),
        color: onKindAccent(scheme, kind),
        size: size * 0.5,
      ),
    );
  }
}

/// Five stars. With [onChanged] each star is a 48dp button.
class StarRating extends StatelessWidget {
  const StarRating({
    required this.rating,
    super.key,
    this.onChanged,
    this.size = 20,
  });
  final double rating;
  final ValueChanged<int>? onChanged;
  final double size;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.tertiary;
    final l10n = AppLocalizations.of(context);
    IconData iconFor(int star) => rating >= star
        ? Icons.star_rounded
        : rating >= star - 0.5
        ? Icons.star_half_rounded
        : Icons.star_outline_rounded;
    if (onChanged == null) {
      return Semantics(
        label: l10n.clubsStarsOutOfFive(formatClubRating(l10n, rating)),
        child: ExcludeSemantics(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var star = 1; star <= 5; star++)
                Icon(iconFor(star), size: size, color: color),
            ],
          ),
        ),
      );
    }
    return Wrap(
      children: [
        for (var star = 1; star <= 5; star++)
          IconButton(
            tooltip: l10n.clubsStarCount(star),
            isSelected: rating >= star,
            constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
            onPressed: () => onChanged!(star),
            icon: Icon(iconFor(star), size: 36, color: color),
          ),
      ],
    );
  }
}

/// "★★★★☆ 4.2 · 3 reviews", or a nudge when nobody has rated it yet.
class RatingSummary extends StatelessWidget {
  const RatingSummary({required this.title, super.key});
  final Title title;

  @override
  Widget build(BuildContext context) {
    final average = title.averageRating;
    final text = Theme.of(context).textTheme.bodyMedium;
    final l10n = AppLocalizations.of(context);
    if (average == null || title.reviewCount == 0) {
      return Text(l10n.clubsNoRatingsYet, style: text);
    }
    return Wrap(
      spacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        StarRating(rating: average),
        Text(
          l10n.clubsRatingSummary(
            formatClubRating(l10n, average),
            title.reviewCount,
          ),
          style: text,
        ),
      ],
    );
  }
}

/// A short readable label for a pick's week, e.g. "Week of 2026-09-28".
String weekLabel(AppLocalizations l10n, String weekStart) {
  final now = DateTime.now();
  if (weekStart == mondayOf(now)) {
    return l10n.clubsWeekThis;
  }
  if (weekStart == mondayOf(now.add(const Duration(days: 7)))) {
    return l10n.clubsWeekNext;
  }
  if (weekStart == mondayOf(now.subtract(const Duration(days: 7)))) {
    return l10n.clubsWeekLast;
  }
  return l10n.clubsWeekOf(weekStart);
}

/// A pill such as "This week" used on the current pick.
class WeekPill extends StatelessWidget {
  const WeekPill({required this.label, super.key});
  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.primary,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.event_outlined, size: 16, color: scheme.onPrimary),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                label,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: scheme.onPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A modal sheet body with a title, scrollable content and safe padding.
class SheetFrame extends StatelessWidget {
  const SheetFrame({required this.title, required this.children, super.key});
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
    child: SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    ),
  );
}

Future<T?> showClubSheet<T>(BuildContext context, Widget child) =>
    showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) => child,
    );
