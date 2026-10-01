/// Shared editable bounds; ages match the supported adult signup contract.
abstract final class PreferenceLimits {
  static const double minAge = 18;
  static const double maxAge = 80;
  static const double minDistanceKm = 1;
  static const double maxDistanceKm = 500;
  static const int ageDivisions = 62;
  static const int distanceDivisions = 499;
}
