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
    this.isSpotlight = false,
    this.spotlightTier,
    this.spotlightScore,
    this.spotlightReason,
  });
  final String id;
  final String name;
  final DateTime dateOfBirth;
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

  int get age => dateOfBirth.age;

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
