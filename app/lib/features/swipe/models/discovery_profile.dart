import '../../../core/extensions/date_time_extensions.dart';

/// Lightweight profile model used for the discovery/swipe stack.
class DiscoveryProfile {
  const DiscoveryProfile({
    required this.id,
    required this.name,
    required this.dateOfBirth,
    required this.bio,
    required this.additionalInfo,
    required this.profession,
    required this.education,
    required this.instagramHandle,
    required this.hobbies,
    required this.favoriteSongs,
    required this.extraCurriculars,
    required this.intentTags,
    required this.languageTags,
    required this.isVerified,
    required this.photoUrls,
    this.publicAge,
    this.isSpotlight = false,
    this.spotlightTier,
    this.spotlightScore,
    this.spotlightReason,
    this.reasons = const <String>[],
    this.why,
    this.sharedActivities = const <String>[],
    this.availabilityOverlaps = false,
  });
  final String id;
  final String name;
  final DateTime? dateOfBirth;
  final int? publicAge;
  final String? bio;
  final String? additionalInfo;
  final String? profession;
  final String? education;
  final String? instagramHandle;
  final List<String> hobbies;
  final List<String> favoriteSongs;
  final List<String> extraCurriculars;
  final List<String> intentTags;
  final List<String> languageTags;
  final bool isVerified;
  final List<String> photoUrls;
  final bool isSpotlight;
  final String? spotlightTier;
  final double? spotlightScore;
  final String? spotlightReason;

  /// Explainability chips from the curated daily set catalogue
  /// ("Shares your intent", "Verified & active", ...). Empty for a candidate
  /// that is not in today's curated set.
  final List<String> reasons;

  /// One-line explanation shown under the chips; null when not curated.
  final String? why;

  /// Intersection of explicit dating preferences, supplied by the server.
  final List<String> sharedActivities;
  final bool availabilityOverlaps;

  int? get age => publicAge ?? dateOfBirth?.age;

  String get displayName => age == null ? name : '$name, $age';

  String get subtitle {
    final parts = <String>[];
    if (profession != null && profession!.trim().isNotEmpty) {
      parts.add(profession!.trim());
    } else if (education != null && education!.trim().isNotEmpty) {
      parts.add(education!.trim());
    }
    return parts.isEmpty ? ' ' : parts.join(' • ');
  }

  String get quickBio {
    final primary = (bio ?? '').trim();
    if (primary.isNotEmpty) {
      return primary;
    }
    final fallback = (additionalInfo ?? '').trim();
    return fallback;
  }

  List<String> get quickPreviewTags {
    final tags = <String>[];

    void addTag(String? value) {
      final normalized = (value ?? '').trim();
      if (normalized.isNotEmpty && !tags.contains(normalized)) {
        tags.add(normalized);
      }
    }

    void addAll(List<String> values) {
      for (final value in values) {
        addTag(value);
      }
    }

    addAll(intentTags);
    addAll(languageTags);
    addAll(hobbies);
    addAll(favoriteSongs);
    addAll(extraCurriculars);
    if ((instagramHandle ?? '').trim().isNotEmpty) {
      addTag('Instagram');
    }
    addTag(profession);
    addTag(education);

    return tags;
  }
}
